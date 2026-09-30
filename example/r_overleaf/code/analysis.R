# Generate figures and tables in output/. Run from the project root, or with Rscript.
script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(script_arg)) {
  script_dir <- dirname(normalizePath(sub("^--file=", "", script_arg[[1]])))
  setwd(dirname(script_dir))
}
if (!file.exists("data/penguins.csv") && file.exists("../data/penguins.csv")) {
  setwd("..")
}

source("code/analysis_helpers.R")
generate_outputs()
