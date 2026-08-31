# Per-routine faithfulness audit: pladdrr DSP output vs Praat-native output.
#
# Design principle 1 (faithfulness) is the first-ranked goal. This file runs an
# extensible registry of routines, generates a Praat-native reference by
# invoking /Applications/Praat.app/Contents/MacOS/Praat in --run mode, then
# compares against the pladdrr equivalent at a per-routine tolerance.
#
# Output side-effects (only when the suite actually runs end-to-end):
#   <tempdir>/faithfulness_report.csv
#   <tempdir>/FAITHFULNESS_REPORT.md
# Set PLADDRR_FAITHFULNESS_OUTDIR=<repo root> to regenerate the committed
# tests/faithfulness_report.csv and inst/agents/FAITHFULNESS_REPORT.md instead.
#
# Skipped on CRAN and whenever Praat is not installed locally.

library(testthat)

PRAAT_EXEC <- Sys.getenv("PLADDRR_PRAAT_EXEC",
  unset = "/Applications/Praat.app/Contents/MacOS/Praat")

skip_if_no_praat <- function() {
  testthat::skip_if_not(file.exists(PRAAT_EXEC),
                        "Praat not available — skipping faithfulness audit")
  testthat::skip_if(identical(Sys.getenv("NOT_CRAN"), ""),
                    "NOT_CRAN not set — skipping faithfulness audit")
}

resolve_fixture <- function(rel) {
  # Try package-internal extdata first (works installed and during
  #  devtools::test()),
  # fall back to the in-tree inst/ path.
  candidate <- system.file(rel, package = "pladdrr")
  if (nzchar(candidate) && file.exists(candidate)) return(candidate)
  in_tree <- file.path("..", "..", "inst", rel)
  if (file.exists(in_tree)) return(normalizePath(in_tree))
  NA_character_
}

run_praat <- function(script_text, path) {
  script <- gsub("{path}", path, script_text, fixed = TRUE)
  tf <- tempfile(fileext = ".praat")
  on.exit(unlink(tf), add = TRUE)
  writeLines(script, tf)
  out <- suppressWarnings(system2(PRAAT_EXEC,
                                  args = c("--utf8", "--run", tf),
                                  stdout = TRUE, stderr = TRUE))
  if (!is.null(attr(out, "status")) && attr(out, "status") != 0) {
    stop("Praat oracle failed:\n", paste(out, collapse = "\n"))
  }
  out
}

abs_max_diff <- function(a, b) {
  if (length(a) != length(b)) return(Inf)
  if (anyNA(a) || anyNA(b)) {
    # Both NA at same positions == match; otherwise diff is Inf.
    if (identical(is.na(a), is.na(b))) {
      ok <- !is.na(a)
      if (!any(ok)) return(0)
      return(max(abs(a[ok] - b[ok])))
    }
    return(Inf)
  }
  max(abs(a - b))
}

audit_routine <- function(r) {
  path <- resolve_fixture(r$fixture)
  if (is.na(path)) {
    return(list(name = r$name, status = "no-fixture",
                praat = NA_real_, pladdrr = NA_real_,
                diff = NA_real_, tolerance = r$tolerance))
  }
  praat_lines <- tryCatch(run_praat(r$praat_script, path),
                          error = function(e) e)
  if (inherits(praat_lines, "error")) {
    return(
      list(name = r$name,
        status = paste0("praat-error: ", conditionMessage(praat_lines)),
                praat = NA_real_, pladdrr = NA_real_,
                diff = NA_real_, tolerance = r$tolerance))
  }
  praat_val <- tryCatch(r$parse_praat(praat_lines),
                        error = function(e) NA_real_)
  pladdrr_val <- tryCatch(r$pladdrr(path),
                          error = function(e) {
                            message("pladdrr error in ", r$name, ": ",
                              conditionMessage(e))
                            NA_real_
                          })
  diff <- abs_max_diff(as.numeric(praat_val), as.numeric(pladdrr_val))
  status <- if (is.finite(diff) && diff <= r$tolerance) "pass" else "fail"
  list(name = r$name, status = status,
       praat = as.numeric(praat_val), pladdrr = as.numeric(pladdrr_val),
       diff = diff, tolerance = r$tolerance)
}

write_reports <- function(rows) {
  df <- do.call(rbind, lapply(rows, as.data.frame, stringsAsFactors = FALSE))
  # Never write into the source tree from a test run: that makes `R CMD check`
  # mutate tracked files and shows up as spurious VCS churn. Default to
  # tempdir(); set PLADDRR_FAITHFULNESS_OUTDIR to regenerate the committed
  # report deliberately, e.g.
  #   PLADDRR_FAITHFULNESS_OUTDIR=$PWD Rscript -e 'testthat::test_file(...)'
  out_dir <- Sys.getenv("PLADDRR_FAITHFULNESS_OUTDIR", unset = "")
  writing_to_repo <- nzchar(out_dir)
  if (!writing_to_repo) out_dir <- tempdir()

  csv_path <- if (writing_to_repo) {
    file.path(out_dir, "tests", "faithfulness_report.csv")
  } else {
    file.path(out_dir, "faithfulness_report.csv")
  }
  dir.create(dirname(csv_path), recursive = TRUE, showWarnings = FALSE)
  write.csv(df, csv_path, row.names = FALSE)

  md_path <- if (writing_to_repo) {
    file.path(out_dir, "inst", "agents", "FAITHFULNESS_REPORT.md")
  } else {
    file.path(out_dir, "FAITHFULNESS_REPORT.md")
  }
  if (dir.exists(dirname(md_path))) {
    lines <- c(
      "# Faithfulness Report (pladdrr vs Praat)",
      "",
      sprintf("_Generated: %s_", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
      "",
      "Each row is one Praat DSP routine. Praat output is the oracle; pladdrr",
      "is checked against it at the documented tolerance. `pass` = within",
      "tolerance, `fail` = drift (open an issue or document the rationale).",
      "",
      "| Routine | Status | Praat | pladdrr | |Δ| | Tolerance |",
      "|---------|--------|-------|---------|------|-----------|"
    )
    for (i in seq_len(nrow(df))) {
      lines <- c(lines, sprintf("| %s | %s | %s | %s | %s | %s |",
                                df$name[i], df$status[i],
                                format(df$praat[i]), format(df$pladdrr[i]),
                                format(df$diff[i]), format(df$tolerance[i])))
    }
    writeLines(lines, md_path)
  }
  invisible(df)
}

test_that("pladdrr DSP routines match Praat within tolerance", {
  skip_if_no_praat()
  source(file.path("faithfulness", "routines.R"), local = TRUE)
  results <- lapply(FAITHFULNESS_ROUTINES, audit_routine)
  df <- write_reports(results)
  fails <- df[df$status == "fail", , drop = FALSE]
  if (nrow(fails) > 0) {
    msg <- paste(sprintf("  - %s: |Δ|=%g tol=%g",
                         fails$name, fails$diff, fails$tolerance),
                 collapse = "\n")
    fail(paste0("Faithfulness regressions:\n", msg))
  } else {
    succeed()
  }
})
