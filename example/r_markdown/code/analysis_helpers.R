scatter_data <- read.csv("data/scatter_simulation.csv")
event_data <- read.csv("data/event_study_simulation.csv")
penguins <- read.csv("data/penguins.csv", na.strings = c("", "NA"))

event_times <- c(-5:-2, 0:4)
event_vars <- paste0("event_", ifelse(event_times < 0, paste0("m", abs(event_times)), paste0("p", event_times)))
for (j in seq_along(event_times)) {
  event_data[[event_vars[j]]] <- as.integer(event_data$treated == 1 & event_data$period == event_times[j])
}
event_fit <- lm(
  as.formula(paste("y ~ factor(unit_id) + factor(period) +", paste(event_vars, collapse = " + "))),
  data = event_data
)
event_coef <- coef(summary(event_fit))[event_vars, , drop = FALSE]
event_results <- data.frame(
  event_time = event_times,
  estimate = event_coef[, "Estimate"],
  lower = event_coef[, "Estimate"] - 1.96 * event_coef[, "Std. Error"],
  upper = event_coef[, "Estimate"] + 1.96 * event_coef[, "Std. Error"]
)

penguins_clean <- subset(penguins, !is.na(sex))
measure_vars <- c("bill_length_mm", "bill_depth_mm", "flipper_length_mm", "body_mass_g")
penguin_summary <- aggregate(
  penguins_clean[measure_vars],
  by = penguins_clean[c("species", "sex")],
  FUN = function(x) mean(x, na.rm = TRUE)
)
penguin_summary <- penguin_summary[order(penguin_summary$species, penguin_summary$sex), ]

source("code/tab_paper.R")
tab_setup()
penguin_regression <- lm(
  bill_length_mm ~ species + sex + flipper_length_mm,
  data = penguins,
  na.action = na.omit
)
penguin_regression_coefs <- c(
  "speciesChinstrap" = "Chinstrap vs. Adelie",
  "speciesGentoo" = "Gentoo vs. Adelie",
  "sexmale" = "Male vs. female",
  "flipper_length_mm" = "Flipper length (mm)"
)
penguin_regression_notes <- paste(
  "Outcome: bill length (mm). Complete cases only; omitted categories are Adelie and female.",
  "Conventional OLS standard errors in parentheses."
)

penguin_regression_table <- function(output = "markdown", out = NULL) {
  tab_reg(
    models = list("Bill length (mm)" = penguin_regression),
    coefs = penguin_regression_coefs,
    notes = penguin_regression_notes,
    title = "OLS: bill length and penguin characteristics",
    output = output,
    out = out
  )
}

theme_colors <- c("#107895", "#9a2515", "#e64173")
species_colors <- setNames(theme_colors, levels(factor(penguins$species)))

plot_scatter <- function() {
  plot(scatter_data$x, scatter_data$y, pch = 19, col = "#107895",
       xlab = "Simulated predictor (X)", ylab = "Simulated outcome (Y)",
       main = "Simulated outcome and predictor")
  abline(lm(y ~ x, data = scatter_data), col = "#9a2515", lwd = 2)
}

plot_event_study <- function() {
  plot(event_results$event_time, event_results$estimate, type = "n",
       ylim = range(event_results$lower, event_results$upper, 0),
       xlab = "Event time (periods relative to treatment)",
       ylab = "Estimated effect on outcome",
       main = "Event-study estimates from simulated data", xaxt = "n")
  axis(1, at = -5:4)
  abline(h = 0, col = "grey55", lty = 2)
  abline(v = -0.5, col = "grey55", lty = 3)
  segments(event_results$event_time, event_results$lower,
           event_results$event_time, event_results$upper, col = "#107895")
  points(event_results$event_time, event_results$estimate, pch = 19, col = "#107895")
}

plot_penguins <- function() {
  dat <- subset(penguins, !is.na(sex) & !is.na(flipper_length_mm) &
                  !is.na(bill_length_mm) & !is.na(body_mass_g))
  oldpar <- par(no.readonly = TRUE)
  on.exit(par(oldpar))
  par(mfrow = c(2, 2), mar = c(4, 4, 2.5, 1), oma = c(0, 0, 2, 0))
  for (sx in c("male", "female")) {
    d <- dat[dat$sex == sx, ]
    plot(d$flipper_length_mm, d$bill_length_mm,
         col = species_colors[d$species], pch = 19,
         xlab = "Flipper length (mm)", ylab = "Bill length (mm)",
         main = paste("Sex:", sx))
  }
  plot(dat$flipper_length_mm, dat$body_mass_g,
       col = species_colors[dat$species], pch = 19,
       xlab = "Flipper length (mm)", ylab = "Body mass (g)",
       main = "Body mass and flipper length")
  plot(NA, xlim = range(dat$flipper_length_mm), ylim = c(0, 0.09),
       xlab = "Flipper length (mm)", ylab = "Density", main = "Flipper length distribution")
  for (sp in levels(factor(dat$species))) {
    lines(density(dat$flipper_length_mm[dat$species == sp]), col = species_colors[sp], lwd = 2)
  }
  legend("topright", legend = names(species_colors), col = species_colors,
         lwd = 2, pch = 19, bty = "n", cex = 0.8)
  mtext("Palmer Penguins", outer = TRUE, font = 2, cex = 1.1)
}

write_penguin_table_tex <- function(path = "output/tables/table_penguin_summary.tex") {
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  show <- penguin_summary
  show$species <- as.character(show$species)
  show$sex <- tools::toTitleCase(as.character(show$sex))
  rows <- apply(show, 1, function(z) paste0(
    z["species"], " & ", z["sex"], " & ",
    paste(sprintf("%.1f", as.numeric(z[measure_vars])), collapse = " & "), " \\\\"
  ))
  writeLines(c(
    "\\begin{tabular}{llrrrr}", "\\toprule",
    "Species & Sex & Bill length (mm) & Bill depth (mm) & Flipper length (mm) & Body mass (g) \\\\ ",
    "\\midrule", rows, "\\bottomrule", "\\end{tabular}"
  ), path)
}

generate_outputs <- function() {
  dir.create("output/figures", showWarnings = FALSE, recursive = TRUE)
  dir.create("output/tables", showWarnings = FALSE, recursive = TRUE)
  pdf("output/figures/scatter.pdf", width = 6, height = 4); plot_scatter(); dev.off()
  pdf("output/figures/event_study.pdf", width = 6, height = 4); plot_event_study(); dev.off()
  pdf("output/figures/penguins.pdf", width = 8, height = 6); plot_penguins(); dev.off()
  write_penguin_table_tex()
  reg_table <- penguin_regression_table(output = "latex")
  save_tab(reg_table, "output/tables/table_penguin_regression", plain = TRUE)
}
