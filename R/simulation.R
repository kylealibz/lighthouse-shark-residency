# These are hypothetical receiver zones, with no real receiver locations.
simulate_outages <- function(reps = 500L, days = 365L, seed = 76823L) {
  set.seed(seed)
  n <- 77L
  female <- seq_len(n) <= 39L
  # Sex-specific means and individual variation are scenario inputs.
  mu <- ifelse(female, 0.28, 0.16)
  primary_zone <- ifelse(female, 0.75, 0.25)
  name <- c("Full coverage", "Scattered array outage", "Midyear array outage",
            "End-of-year array outage", "One zone offline all year")
  outage_days <- floor(days * 0.2)
  runs <- lapply(seq_len(reps), function(iteration) {
    p <- rbeta(n, 12 * mu, 12 * (1 - mu))
    present <- matrix(FALSE, n, days)
    present[, 1] <- runif(n) < p
    for (day in 2:days) {
      # With probability 0.7 retain yesterday's state. This keeps p
      # stationary while creating runs of presence and absence.
      present[, day] <- runif(n) < (0.7 * present[, day - 1] + 0.3 * p)
    }
    # A day qualifies if at least two pings reach the active receiver.
    heard <- present & matrix(rpois(n * days, 4) >= 2L, n)
    zone_one <- matrix(runif(n * days), n) < primary_zone
    full <- rowMeans(heard)
    actual <- rowMeans(present)
    gap <- list(integer(), sample.int(days, outage_days),
                seq.int(floor((days - outage_days) / 2) + 1L, length.out = outage_days),
                tail(seq_len(days), outage_days), integer())
    do.call(rbind, lapply(seq_along(name), function(i) {
      recorded <- heard
      recorded[, gap[[i]]] <- FALSE
      if (i == 5L) recorded[zone_one] <- FALSE
      counted <- rowSums(recorded)
      # Find each individual's last day with a qualifying detection.
      last <- max.col(recorded[, days:1, drop = FALSE], ties.method = "first")
      last <- days + 1L - last
      stopifnot(all(counted <= rowSums(heard)))
      metrics <- list("Fixed window" = counted / days,
                      "Operational days" = counted / (days - length(gap[[i]])),
                      "Last detection" = ifelse(counted > 0, counted / last, NA_real_))
      reference <- list("Fixed window" = full, "Operational days" = full,
                        "Last detection" = ifelse(full > 0,
                          rowSums(heard) / (days + 1L -
                            max.col(heard[, days:1, drop = FALSE], ties.method = "first")),
                          NA_real_))
      do.call(rbind, lapply(names(metrics), function(method) {
        x <- metrics[[method]]
        baseline <- reference[[method]]
        valid <- is.finite(x) & is.finite(baseline)
        f <- valid & female
        m <- valid & !female
        gap_x <- mean(x[f]) - mean(x[m])
        gap_full <- mean(baseline[f]) - mean(baseline[m])
        data.frame(iteration, scenario = name[i], method,
          retained_sharks = sum(valid), mean_index = mean(x[valid]),
          mean_error_vs_latent = mean(x[valid] - actual[valid]),
          mean_shift_vs_full = mean(x[valid] - baseline[valid]),
          individual_rmse_vs_full = sqrt(mean((x[valid] - baseline[valid])^2)),
          female_minus_male = gap_x, gap_shift_vs_full = gap_x - gap_full)
      }))
    }))
  })
  replicates <- do.call(rbind, runs)
  summary <- do.call(rbind, lapply(split(replicates, list(replicates$scenario, replicates$method)), function(x) {
    data.frame(scenario = x$scenario[1], method = x$method[1],
      mean_index = mean(x$mean_index), mean_error_vs_latent = mean(x$mean_error_vs_latent),
      mean_shift_vs_full = mean(x$mean_shift_vs_full),
      shift_p025 = unname(quantile(x$mean_shift_vs_full, .025)),
      shift_p975 = unname(quantile(x$mean_shift_vs_full, .975)),
      individual_rmse_vs_full = mean(x$individual_rmse_vs_full),
      female_minus_male = mean(x$female_minus_male),
      gap_shift_vs_full = mean(x$gap_shift_vs_full),
      reversal_fraction = mean(x$female_minus_male < 0),
      mean_retained_sharks = mean(x$retained_sharks))
  }))
  rownames(summary) <- NULL
  list(replicates = replicates, summary = summary)
}
