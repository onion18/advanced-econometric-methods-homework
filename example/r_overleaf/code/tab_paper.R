## tab_paper.R ---------------------------------------------------------------
## Publication-ready tables for empirical economics papers.
## Vendored from the `research-tables` skill -- copy this file into the project
## (e.g. code/tab_paper.R) so the analysis runs for a collaborator without the skill.
##
## Requires: modelsummary, tinytable, insight.  Optional: fixest, plm, estimatr.
##
## Entry points
##   tab_setup()          once per session: number formatting + outcome-mean support
##   tab_reg()            regression table from a NAMED list of fitted models
##   tab_reg_versions()   paper version + slide version from the same models
##   tab_desc()           descriptive-statistics table (the "Table 1")
##   tab_balance()        treatment vs control balance table
##   save_tab()           write .tex (bare tabular, ready to \input) / .html / .png
##
## Every function returns a tinytable object, so you can keep piping tinytable
## verbs -- group_tt(), style_tt() -- before saving.
##
## The design rule behind this file: the input is always fitted MODEL OBJECTS or
## a data frame, never numbers you typed. If a coefficient reaches the paper
## without passing through this file, the workflow is broken.

# --- internals ---------------------------------------------------------------

.tab_classes <- c(
  "fixest", "fixest_multi", "plm", "lm", "glm", "felm",
  "ivreg", "iv_robust", "lm_robust", "negbin", "polr", "rq", "gam"
)

#' Mean of the dependent variable, across model types.
#' insight::get_response() covers lm/glm/fixest/plm/ivreg/...; the model.frame
#' fallback catches the rest. Binary factors are coerced to 0/1 so that the mean
#' is the base rate, which is the number a reader actually wants.
.tab_ymean <- function(x) {
  y <- tryCatch(insight::get_response(x), error = function(e) NULL)
  if (is.null(y)) {
    y <- tryCatch(stats::model.response(stats::model.frame(x)),
                  error = function(e) NULL)
  }
  if (is.null(y)) return(NA_real_)
  if (is.data.frame(y)) y <- y[[1L]]
  if (is.matrix(y)) y <- y[, 1L]
  if (is.factor(y) || is.character(y)) y <- as.numeric(as.factor(y)) - 1
  if (is.logical(y)) y <- as.numeric(y)
  if (!is.numeric(y)) return(NA_real_)
  mean(y, na.rm = TRUE)
}

#' Which variables a model absorbs as fixed effects.
#' fixest records them directly; for plm they follow from the estimator and the
#' panel index, so a within model gets the same Yes/No rows a feols model would.
.tab_fe_vars <- function(m) {
  if (inherits(m, "fixest")) {
    return(if (is.null(m$fixef_vars)) character(0) else m$fixef_vars)
  }
  if (inherits(m, "plm")) {
    if (!identical(m$args$model, "within")) return(character(0))
    idx <- names(attr(m$model, "index"))
    if (length(idx) < 2) return(character(0))
    return(switch(m$args$effect,
                  individual = idx[1],
                  time       = idx[2],
                  twoways    = idx[1:2],
                  character(0)))
  }
  character(0)
}

.tab_fe_rows <- function(models) {
  unique(unlist(lapply(models, .tab_fe_vars), use.names = FALSE))
}

#' Extra goodness-of-fit entries: the outcome mean for every model type, plus
#' fixed-effect markers for plm (fixest supplies its own "FE: x" entries).
.glance_tab <- function(x, ...) {
  out <- data.frame(row.names = 1L)
  m <- tryCatch(.tab_ymean(x), error = function(e) NA_real_)
  if (is.finite(m)) out[["ymean"]] <- m
  if (inherits(x, "plm")) {
    for (v in tryCatch(.tab_fe_vars(x), error = function(e) character(0))) {
      out[[paste0("FE: ", v)]] <- "X"
    }
  }
  if (!ncol(out)) return(data.frame())
  out
}

#' Build the SE note from what the models actually used, so the note cannot
#' drift away from the estimation code.
.tab_se_note <- function(models, latex) {
  types <- vapply(models, function(m) {
    g <- tryCatch(modelsummary::get_gof(m), error = function(e) NULL)
    if (is.null(g) || is.null(g[["vcov.type"]])) NA_character_ else as.character(g[["vcov.type"]][1])
  }, character(1))
  types <- unique(types[!is.na(types)])
  if (length(types) != 1L) return(NULL)
  t1 <- types
  if (grepl("^by: ", t1)) {
    v <- sub("^by: ", "", t1)
    v <- gsub("_", if (latex) "\\\\_" else "_", v)
    return(sprintf("Standard errors clustered by %s in parentheses.", v))
  }
  if (grepl("^IID$", t1, ignore.case = TRUE)) {
    return("Standard errors in parentheses (homoskedastic).")
  }
  sprintf("%s standard errors in parentheses.", t1)
}

.tab_is_latex <- function(output) isTRUE(grepl("latex|tex", output, ignore.case = TRUE))

#' Significance legend, written by hand.
#' modelsummary's own stars note routes "< 0.1" through siunitx \num{}, which
#' fails unless the document loads siunitx. tab_setup() switches that note off
#' and we emit a portable one instead.
.tab_stars_note <- function(stars, latex) {
  if (is.null(stars) || isFALSE(stars) || !length(stars)) return(NULL)
  if (isTRUE(stars)) stars <- c("+" = 0.1, "*" = 0.05, "**" = 0.01, "***" = 0.001)
  stars <- sort(stars, decreasing = TRUE)
  parts <- if (latex) {
    sprintf("%s $p<%s$", names(stars), formatC(stars, format = "fg"))
  } else {
    sprintf("%s p < %s", names(stars), formatC(stars, format = "fg"))
  }
  paste0(paste(parts, collapse = ", "), ".")
}

# --- setup -------------------------------------------------------------------

#' Configure modelsummary for paper output and enable the outcome-mean row.
#'
#' The outcome mean is not a built-in goodness-of-fit statistic, so it has to be
#' attached through modelsummary's documented `glance_custom` extension point.
#' Call this once, near the top of the table script.
tab_setup <- function() {
  for (p in c("modelsummary", "tinytable", "insight")) {
    if (!requireNamespace(p, quietly = TRUE)) {
      stop("tab_paper.R needs the '", p, "' package. install.packages('", p, "')")
    }
  }
  # A bare booktabs table, not siunitx \num{} wrappers.
  options(modelsummary_format_numeric_latex = "plain")
  options(modelsummary_factory_default = "tinytable")
  # We write our own significance legend; see .tab_stars_note().
  options(modelsummary_stars_note = FALSE)
  for (cl in .tab_classes) {
    try(
      registerS3method("glance_custom", cl, .glance_tab,
                       envir = asNamespace("modelsummary")),
      silent = TRUE
    )
  }
  invisible(TRUE)
}

# --- regression tables -------------------------------------------------------

#' Regression table from a named list of fitted models.
#'
#' @param models Named list of fitted models. THE NAMES BECOME THE COLUMN
#'   HEADERS, so naming them is the same act as deciding what each column
#'   changes ("Baseline", "+ Controls", "Municipality FE"). Unnamed lists fall
#'   back to (1), (2), ... with a warning.
#' @param coefs Named character vector: `c(varname = "Display label")`. Selects,
#'   reorders and renames in one step; everything else is dropped. Leave NULL to
#'   show all coefficients except the intercept.
#' @param ymean Add the mean of the dependent variable (default TRUE).
#' @param fe Add one Yes/No row per fixest fixed effect (default TRUE).
#' @param gof Which fit statistics to append after N: "r2" picks within-R2 when
#'   the model has fixed effects and R2 otherwise. Use character(0) for none.
#' @param vcov Passed to modelsummary. REQUIRED for plm if you want anything
#'   other than iid standard errors -- see references/r-recipes.md.
#' @param notes Character vector of table notes. An SE note is derived from the
#'   models themselves and prepended unless `se_note = FALSE`.
#' @param slide Strip to the live-talk version: 2 digits, no R2, no intercept.
#' @param out File stem, e.g. "output/tab2_main". Writes "<out>.tex".
#' @param output modelsummary output format; "latex" by default.
tab_reg <- function(models,
                    coefs   = NULL,
                    ymean   = TRUE,
                    fe      = TRUE,
                    gof     = c("r2"),
                    digits  = 3,
                    stars   = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
                    vcov    = NULL,
                    notes   = NULL,
                    title   = NULL,
                    se_note = TRUE,
                    slide   = FALSE,
                    out     = NULL,
                    output  = "latex",
                    escape  = NULL,
                    ...) {
  if (!is.list(models) || inherits(models, "lm") || inherits(models, "fixest")) {
    models <- list(models)
  }
  if (is.null(names(models)) || any(!nzchar(names(models)))) {
    warning("tab_reg(): models are unnamed, falling back to (1), (2), ... ",
            "Name them after what each column changes -- that is the column logic ",
            "the reader is looking for.", call. = FALSE)
    names(models) <- sprintf("(%d)", seq_along(models))
  }

  latex <- .tab_is_latex(output)
  if (is.null(escape)) escape <- !latex
  if (slide) {
    digits <- min(digits, 2)
    gof <- character(0)
  }

  ## coefficients
  args <- list(models = models, output = output, escape = escape,
               fmt = digits, stars = stars)
  if (!is.null(coefs)) {
    args$coef_map <- coefs
  } else {
    args$coef_omit <- "Intercept"
  }
  if (!is.null(vcov)) args$vcov <- vcov

  ## goodness-of-fit rows, in reading order:
  ## outcome mean -> fixed effects -> N -> fit statistic
  gm <- list()
  if (isTRUE(ymean)) {
    gm <- c(gm, list(list(raw = "ymean", clean = "Outcome mean", fmt = digits)))
  }
  if (isTRUE(fe)) {
    for (v in .tab_fe_rows(models)) {
      lbl <- gsub("_", if (latex && !escape) "\\\\_" else "_", v)
      gm <- c(gm, list(list(raw = paste0("FE: ", v),
                            clean = paste0("FE: ", lbl), fmt = 0)))
    }
  }
  gm <- c(gm, list(list(raw = "nobs", clean = "N", fmt = 0)))
  if ("r2" %in% gof) {
    r2lab <- if (latex && !escape) "R$^2$" else "R²"
    # fixest exposes the within R2 as its own statistic; for a plm within model
    # the reported r.squared already IS the within R2 (verified against
    # fixest::r2(., "wr2") on the same specification). Reporting the
    # FE-inflated total R2 for either would flatter the fit.
    fx_fe  <- any(vapply(models, function(m)
      inherits(m, "fixest") && length(.tab_fe_vars(m)) > 0, logical(1)))
    plm_wi <- any(vapply(models, function(m)
      inherits(m, "plm") && identical(m$args$model, "within"), logical(1)))
    if (fx_fe && plm_wi) {
      message("tab_reg(): the table mixes fixest and plm fixed-effects models, ",
              "which report the within R2 under different names. Check the R2 ",
              "row, or split the table.")
    }
    if (fx_fe) {
      gm <- c(gm, list(list(raw = "r2.within",
                            clean = paste0("Within ", r2lab), fmt = 3)))
    } else if (plm_wi) {
      gm <- c(gm, list(list(raw = "r.squared",
                            clean = paste0("Within ", r2lab), fmt = 3)))
    } else {
      gm <- c(gm, list(list(raw = "r.squared", clean = r2lab, fmt = 3)))
    }
  }
  for (g in setdiff(gof, "r2")) {
    gm <- c(gm, list(list(raw = g, clean = g, fmt = 3)))
  }
  args$gof_map <- gm

  ## notes: SE first, then the user's, then the significance legend
  n <- character(0)
  if (isTRUE(se_note)) n <- c(n, .tab_se_note(models, latex && !escape))
  n <- c(n, notes, .tab_stars_note(stars, latex && !escape))
  if (length(n)) args$notes <- as.list(n)
  if (!is.null(title)) args$title <- title

  tt <- do.call(modelsummary::modelsummary, c(args, list(...)))
  if (!is.null(out)) save_tab(tt, out, latex = latex)
  tt
}

#' Paper version and slide version of the same table, from the same models.
#'
#' Writes "<out>.tex" and "<out>_slide.tex". Maintaining two versions by hand is
#' how the numbers in a talk drift away from the numbers in the paper.
tab_reg_versions <- function(models, out, ...) {
  paper <- tab_reg(models, slide = FALSE, out = out, ...)
  slide <- tab_reg(models, slide = TRUE, out = paste0(out, "_slide"), ...)
  invisible(list(paper = paper, slide = slide))
}

# --- descriptive tables ------------------------------------------------------

#' Descriptive statistics table.
#'
#' @param data A data frame.
#' @param vars Named character vector `c(varname = "Display label")`, or a plain
#'   character vector of column names. Defaults to every numeric column, which
#'   is fine for exploration and rarely right for the paper.
#' @param by Optional grouping column name; produces one block of statistics per
#'   group (treatment vs control, pre vs post).
#' @param stats Which statistics, from modelsummary's vocabulary.
tab_desc <- function(data,
                     vars   = NULL,
                     by     = NULL,
                     stats  = c("Mean", "SD", "Min", "Median", "Max", "N"),
                     digits = 2,
                     notes  = NULL,
                     title  = NULL,
                     out    = NULL,
                     output = "latex",
                     escape = NULL,
                     ...) {
  stopifnot(is.data.frame(data))
  latex <- .tab_is_latex(output)
  if (is.null(escape)) escape <- !latex

  if (is.null(vars)) {
    vars <- names(data)[vapply(data, is.numeric, logical(1))]
    if (!is.null(by)) vars <- setdiff(vars, by)
  }
  # Same convention as coef_map: names are columns, values are display labels.
  cols <- if (is.null(names(vars))) unname(vars) else names(vars)
  labs <- if (is.null(names(vars))) unname(vars) else unname(vars)
  missing <- setdiff(c(cols, by), names(data))
  if (length(missing)) {
    stop("tab_desc(): column(s) not in data: ", paste(missing, collapse = ", "))
  }
  # Rename the columns up front rather than renaming inside the formula:
  # datasummary's `(Label = var)` syntax is fragile once labels carry
  # punctuation, and this keeps the formula to plain backticked symbols.
  d <- data[, c(cols, by), drop = FALSE]
  names(d) <- c(labs, by)
  lhs <- paste(sprintf("`%s`", labs), collapse = " + ")
  rhs <- paste(stats, collapse = " + ")
  if (!is.null(by)) {
    if (!is.factor(d[[by]])) d[[by]] <- factor(d[[by]])
    rhs <- sprintf("`%s` * (%s)", by, rhs)
  }
  f <- stats::as.formula(paste(lhs, "~", rhs))

  args <- list(formula = f, data = d, output = output, escape = escape,
               fmt = digits)
  if (length(notes)) args$notes <- as.list(notes)
  if (!is.null(title)) args$title <- title

  tt <- do.call(modelsummary::datasummary, c(args, list(...)))
  if (!is.null(out)) save_tab(tt, out, latex = latex)
  tt
}

#' Covariate balance table (treatment vs control).
#'
#' A long balance table is usually harder to read than a Love plot -- see the
#' research-viz skill. This function says so when the table gets long.
tab_balance <- function(data,
                        treat,
                        vars   = NULL,
                        dinm   = TRUE,
                        digits = 2,
                        notes  = NULL,
                        title  = NULL,
                        out    = NULL,
                        output = "latex",
                        escape = NULL,
                        ...) {
  stopifnot(is.data.frame(data), is.character(treat), length(treat) == 1L)
  latex <- .tab_is_latex(output)
  if (is.null(escape)) escape <- !latex

  if (is.null(vars)) {
    vars <- setdiff(names(data)[vapply(data, function(z) is.numeric(z) ||
                                         is.logical(z), logical(1))], treat)
  }
  if (length(vars) > 12) {
    message("tab_balance(): ", length(vars), " covariates. Past roughly a dozen ",
            "rows a Love plot reads better than a balance table -- consider the ",
            "research-viz skill instead.")
  }
  cols <- if (is.null(names(vars))) unname(vars) else names(vars)
  missing <- setdiff(c(cols, treat), names(data))
  if (length(missing)) {
    stop("tab_balance(): column(s) not in data: ", paste(missing, collapse = ", "))
  }
  d <- data[, c(treat, cols), drop = FALSE]
  names(d) <- c(treat, unname(vars))
  if (!is.factor(d[[treat]])) d[[treat]] <- factor(d[[treat]])

  args <- list(formula = stats::as.formula(paste("~", sprintf("`%s`", treat))),
               data = d, output = output, escape = escape, fmt = digits,
               dinm = dinm)
  if (length(notes)) args$notes <- as.list(notes)
  if (!is.null(title)) args$title <- title

  tt <- do.call(modelsummary::datasummary_balance, c(args, list(...)))
  if (!is.null(out)) save_tab(tt, out, latex = latex)
  tt
}

# --- export ------------------------------------------------------------------

#' Write a table to disk.
#'
#' For LaTeX the surrounding float is stripped, so the file is a bare
#' `talltblr` you \input{} inside your own table environment -- caption, label
#' and placement stay in the paper source where they belong. The table body
#' still uses tabularray, so the document preamble needs:
#'
#'   \usepackage{tabularray}
#'   \UseTblrLibrary{booktabs}
#'
#' Pass `float = TRUE` for a self-contained table environment instead, or
#' `plain = TRUE` for a dependency-free `tabular` (which drops the notes).
#'
#' @param x A tinytable object.
#' @param out File stem without extension, e.g. "output/tab2_main".
#' @param formats Any of "tex", "html", "md", "png". PNG needs webshot2.
#' @param minus Replace the hyphen in negative numbers with a true minus sign
#'   ($-$) in LaTeX output. A hyphen is a word-division mark, not a sign, and it
#'   sets too short and too high next to digits.
save_tab <- function(x, out, formats = "tex", latex = TRUE,
                     float = FALSE, plain = FALSE, minus = TRUE) {
  d <- dirname(out)
  if (!identical(d, ".")) dir.create(d, recursive = TRUE, showWarnings = FALSE)
  written <- character(0)
  for (fmt in formats) {
    path <- paste0(out, ".", fmt)
    obj <- x
    if (fmt == "tex") {
      obj <- tryCatch(
        if (plain) {
          tinytable::theme_latex(obj, environment = "tabular",
                                 environment_table = float)
        } else {
          tinytable::theme_latex(obj, environment_table = float)
        },
        error = function(e) {
          # tinytable < 0.6 used the theme_tt("tabular") spelling
          tryCatch(tinytable::theme_tt(obj, "tabular"), error = function(e2) obj)
        }
      )
    }
    if (fmt == "png" && !requireNamespace("webshot2", quietly = TRUE)) {
      message("save_tab(): PNG output needs webshot2; skipping ", path)
      next
    }
    ok <- tryCatch({
      tinytable::save_tt(obj, path, overwrite = TRUE)
      TRUE
    }, error = function(e) {
      message("save_tab(): could not write ", path, ": ", conditionMessage(e))
      FALSE
    })
    if (ok) {
      if (fmt == "tex") {
        txt <- readLines(path, warn = FALSE)
        orig <- txt
        # Belt and braces: no stray siunitx \num{} should reach the paper, since
        # the vendored table is meant to compile without loading siunitx.
        txt <- gsub("\\\\num\\{([^{}]*)\\}", "\\1", txt)
        if (isTRUE(minus)) {
          # Only body rows -- they are the lines that end in \\. The tabularray
          # option lines carry hyphens too (colspec={1-4}, l=-0.5) and must not
          # be touched.
          body <- grepl("\\\\\\\\\\s*$", txt)
          txt[body] <- gsub("(^|[&({ ])-(?=[0-9.])", "\\1$-$",
                            txt[body], perl = TRUE)
        }
        if (!identical(txt, orig)) writeLines(txt, path)
      }
      written <- c(written, path)
    }
  }
  if (length(written)) message("Wrote: ", paste(written, collapse = ", "))
  invisible(written)
}
