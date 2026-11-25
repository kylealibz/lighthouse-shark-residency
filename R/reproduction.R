reproduce_residency <- function(path = "data/table-1.tsv") {
  sharks <- read.table(path, header = TRUE)
  stopifnot(nrow(sharks) == 77, !anyDuplicated(sharks$id),
            all(sharks$ri >= 0 & sharks$ri <= 1))
  sharks$sex <- factor(sharks$sex, levels = c("F", "M"))
  fit <- glm(ri ~ length_cm + sex, family = gaussian(), data = sharks)
  table <- summary(fit)$coefficients
  critical <- qt(0.975, df.residual(fit))
  intervals <- cbind(table[, 1] - critical * table[, 2],
                     table[, 1] + critical * table[, 2])
  published <- c(0.1331, 0.0009, -0.1088)
  coefficients <- data.frame(term = rownames(table), estimate = table[, 1],
    standard_error = table[, 2], statistic = table[, 3], p_value = table[, 4],
    lower = intervals[, 1], upper = intervals[, 2], published,
    difference = table[, 1] - published, row.names = NULL)
  summary <- do.call(rbind, lapply(split(sharks, sharks$sex), function(d) {
    data.frame(sex = d$sex[1], sharks = nrow(d), mean_ri = mean(d$ri),
               sd_ri = sd(d$ri), mean_ri_max = mean(d$ri_max))
  }))
  list(sharks = sharks, fit = fit, coefficients = coefficients, summary = summary)
}

