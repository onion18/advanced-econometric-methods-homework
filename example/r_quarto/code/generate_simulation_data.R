# Recreate the simulation CSVs in data/. Run from the project root, or with Rscript.
script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(script_arg)) {
  script_dir <- dirname(normalizePath(sub("^--file=", "", script_arg[[1]])))
  setwd(dirname(script_dir))
}
if (!file.exists("data") && dir.exists("../data")) {
  setwd("..")
}

dir.create("data", showWarnings = FALSE)

set.seed(1101)
x <- runif(100, 0, 10)
scatter <- data.frame(x = x, y = 5 + 2 * x + rnorm(100, sd = 4))
write.csv(scatter, "data/scatter_simulation.csv", row.names = FALSE)

set.seed(1102)
unit_id <- rep(1:120, each = 10)
period <- rep(-5:4, times = 120)
treated <- as.integer(unit_id <= 60)
unit_effect <- rep(rnorm(120, sd = 1.8), each = 10)
time_effect <- 0.35 * period
treatment_effect <- treated * ifelse(period >= 0, 0.5 * pmin(period + 1, 4), 0)
event_study <- data.frame(
  unit_id,
  period,
  treated,
  y = unit_effect + time_effect + treatment_effect + rnorm(length(period))
)
write.csv(event_study, "data/event_study_simulation.csv", row.names = FALSE)
