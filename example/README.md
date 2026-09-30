# Filled template examples

Each folder is a self-contained project. Run it with that folder as the working directory.

```text
/
├─ data/        original data
├─ code/        R scripts or do-files
├─ output/      tables, figures, logs, and other outputs
└─ report/      qmd, Rmd, tex, and related files
```

| Route | Example source | Compiled PDF |
|---|---|---|
| R + Quarto | `r_quarto/report/replication_template.qmd` | `r_quarto/report/replication_template.pdf` |
| R + R Markdown | `r_markdown/report/replication_template.Rmd` | `r_markdown/report/replication_template.pdf` |
| R + Overleaf | `r_overleaf/code/analysis.R`, then `r_overleaf/report/report.tex` | `r_overleaf/report/report.pdf` |
| Stata + Overleaf | `stata_overleaf/code/analysis.do`, then `stata_overleaf/report/report.tex` | `stata_overleaf/report/report.pdf` |
| Stata + putpdf | `stata_putpdf/code/replication_template.do` | `stata_putpdf/output/replication_report.pdf` |

The Overleaf routes first run their analysis script to write figures and tables into `output/`, then compile the `.tex` report. The Stata + putpdf route writes the PDF directly into `output/`. The Stata examples were checked with Stata 18.

In each regression table, the first row names the outcome variable (`Bill length (mm)`).

The sample ID and name are placeholders. Replace them with your own before submitting a report.
