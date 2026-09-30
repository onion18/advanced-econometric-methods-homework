# R -> LaTeX tables and PDF figures -> Overleaf

dir.create("tables", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)

# Open the file supplied for the current assignment here.
# Replace the example variable names and specification below.

# Example model:
# fit <- lm(y ~ x1 + x2, data = dat)

# Example LaTeX table generated from an estimated model. Replace unexplained
# coefficient names with reader-friendly labels before exporting the table.
# table_tex <- knitr::kable(
#   coef(summary(fit)),
#   format = "latex",
#   booktabs = TRUE,
#   digits = 3
# )
# writeLines(table_tex, "tables/table_main.tex")

# Example PDF figure:
# pdf("figures/figure_main.pdf", width = 6.5, height = 4.5)
# plot(dat$x1, dat$y,
#      xlab = "Years of education",
#      ylab = "Hourly wage (US dollars)",
#      main = "Education and hourly wages")
# abline(fit, col = "steelblue", lwd = 2)
# dev.off()

# Rerun this script whenever the analysis changes, then upload the new
# .tex tables and .pdf figures to the Overleaf project.
