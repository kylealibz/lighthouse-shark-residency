save_plot <- function(path, draw) {
  png(path, width = 1440, height = 850, res = 145)
  on.exit(dev.off())
  draw()
}

plot_residency <- function(result) {
  old <- par(mar = c(5, 5, 4, 2))
  on.exit(par(old))
  d <- result$sharks
  palette <- c(F = "#087E8B", M = "#BA562C")
  plot(100 * ri ~ length_cm, d, pch = 19, col = palette[as.character(d$sex)],
       xlab = "Total length (cm)", ylab = "Published residency index (%)",
       main = "Caribbean reef shark residency at Lighthouse Reef", bty = "l")
  for (group in levels(d$sex)) {
    lengths <- range(d$length_cm[d$sex == group])
    model <- predict(result$fit, newdata = data.frame(length_cm = lengths, sex = group))
    lines(lengths, 100 * model, col = palette[group], lwd = 2)
  }
  legend("topleft", c("Female", "Male"), col = palette, pch = 19, lty = 1, bty = "n")
}

plot_outages <- function(summary, metric = c("bias", "gap")) {
  metric <- match.arg(metric)
  old <- par(mar = c(5, 11, 4, 2))
  on.exit(par(old))
  scenarios <- rev(c("Full coverage", "Scattered array outage", "Midyear array outage",
                     "End-of-year array outage", "One zone offline all year"))
  methods <- c("Fixed window", "Operational days", "Last detection")
  palette <- c("#244B77", "#087E8B", "#BA562C")
  column <- if (metric == "bias") "mean_shift_vs_full" else "female_minus_male"
  x <- 100 * summary[[column]]
  interval <- 100 * c(summary$shift_p025, summary$shift_p975)
  limits <- if (metric == "bias") range(x, interval, 0) else range(x, 0)
  plot(NA, xlim = extendrange(limits, f = .15), ylim = c(.6, 6.15),
       yaxt = "n", xlab = if (metric == "bias") "Change from full coverage (percentage points)"
       else "Female minus male residency (percentage points)",
       ylab = "", bty = "l", main = if (metric == "bias") "How outages shift residency estimates"
       else "A spatial outage can reverse the apparent sex difference")
  axis(2, at = 1:5, labels = scenarios, las = 1, cex.axis = .81)
  abline(v = 0, lty = 2, col = "gray60")
  for (i in seq_along(methods)) {
    d <- summary[summary$method == methods[i], ]
    y <- match(d$scenario, scenarios) + (i - 2) * .17
    if (metric == "bias") {
      segments(100 * d$shift_p025, y, 100 * d$shift_p975, y, col = palette[i], lwd = 1.5)
    }
    points(100 * d[[column]], y, pch = 18 + i, col = palette[i], cex = 1.15)
  }
  legend("top", legend = methods, col = palette, pch = 19:21,
         horiz = TRUE, bty = "n", cex = .8)
}
