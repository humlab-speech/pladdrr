#' @srrstats {G5.0} Tests compare against Praat itself on fixed signals (`tests/testthat/test-praat-faithfulness.R`, `tests/testthat/test-fidelity-fingerprint.R`) and against synthetic signals with known properties (`tests/testthat/test-parameter-recovery.R`).
#' @srrstats {G5.3} For a clean voiced vowel the sample values, intensity, spectrum, MFCC and spectrogram data frames, pitch (voiced frames), the first three formants, harmonicity and the jitter/shimmer batch contain no NA, NaN or Inf (`tests/testthat/test-return-values-defined.R`); undefined output for unvoiced or silent input is intentional and documented (`vignettes/terminology.Rmd`).
#' @srrstats {G5.4} Correctness is tested against Praat 6.4.x as oracle in `tests/testthat/test-praat-faithfulness.R` (19 routines, per-routine tolerances recorded in `inst/agents/FAITHFULNESS_REPORT.md`) and against stored fingerprints in `tests/testthat/test-fidelity-fingerprint.R`.
#' @srrstats {G5.4b} pladdrr is a new implementation of existing Praat methods; the previous implementation (the Praat application) is the oracle, with oracle versions recorded in `inst/agents/FAITHFULNESS_REPORT.md`.

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

# Caveats that belong in the generated report; kept here so a regeneration does
# not drop them.
report_caveats <- c(
    "**Non-determinism caveat (CPPS row above):** the tolerance reported for",
    "`CPPS (calculate_cpps_ultra)` reflects the deterministic fast/default",
    "trend-fit path (`fit_method = \"robust\"`, Siegel). Praat's own",
    "`fit_method = \"robust slow\"` (Theil-Sen) trend fit is **not**",
    "deterministic — a documented upstream Praat defect — and samples",
    "randomly: ~0.8 dB spread across identical runs of the same input, with",
    "occasional extreme outliers around `1e290`. pladdrr reproduces that",
    "non-determinism faithfully when `\"robust slow\"` is requested (see",
    "`AGENT_GUIDE.md` v4.9.19 entry and `PRAAT_MODIFICATIONS.md` v4.9.19).",
    "Do not read the row above as evidence that the robust-slow path is",
    "bit-reproducible — it is not, in Praat or in pladdrr.",
    "",
    "**Oracle version (CPPS row above):** the CPPS row agrees with Praat 6.4.47 to",
    "0.003 dB. Against Praat 6.4.27 the same pipeline differs by about +0.13 dB:",
    "Praat rewrote its CPP-to-CPPS post-processing between those releases",
    "(`max(raw) - trend` became `max(raw - trend)`, and the robust trend estimator",
    "changed), so a gap of that size against an older oracle is a version",
    "difference, not a pladdrr defect. Say which Praat produced a reference number.",
    "",
    "**Oracle version (FormantPath rows):** the 2026-11 external review ran this",
    "registry against Praat 6.4.27 and found the mean F1 / F2 rows off by 0.138 Hz /",
    "0.0256 Hz, with identical frame count and step; it attributed that to the",
    "candidate-grid origin (0 in 6.4.27, 0.0275 s in the 6.4.47 code vendored here).",
    "Those figures were not reproduced against 6.4.27 here; against 6.4.47 the rows",
    "pass. Treat a gap of that size against an older oracle as a version difference,",
    "and do not widen the tolerance for it: the same tolerance guards real drift.",
    "",
    "**MFCC rows:** Praat's `To MFCC` takes (first filter, distance, max) where",
    "`Sound$to_mfcc()` takes (`f1_mel`, `fmax_mel`, `df_mel`). The frame-count row",
    "passed while the two were crossed, so the coefficient row exists to catch a",
    "wrong mapping; against 6.4.47 the coefficients agree to about 2.5e-10.",
    "",
    "**Platform caveat (Intensity row above):** on Apple Silicon the reference",
    "Praat application and pladdrr can differ by ~2e-6 dB in an energy-averaged",
    "Intensity mean at the default time step (measured against Praat 6.4.47 with",
    "byte-identical input: 87.415718735 vs 87.415720871; every other step size",
    "tried agrees to all printed digits, and the 2026-11 audit found Linux x86-64 agreeing against Praat 6.4.27). Frame centres",
    "`x1 + (i-1)*dx` land exactly on a rounding boundary of",
    "`Sampled_xToNearestIndex` for the default grid, and a fused multiply-add",
    "changes the chosen centre sample in 5 of the 117 frames (reproduced with",
    "`math.fma`). pladdrr disables floating-point contraction on purpose",
    "(`#pragma STDC FP_CONTRACT OFF` in `melder.h`), so it follows the non-fused",
    "result. That the app is built with contraction is inferred from the simulation,",
    "not from its build flags. Treat differences of this size on a frame grid that",
    "hits exact sample boundaries as a platform artifact, not a pladdrr defect;",
    "the 1e-05 tolerance above already covers it."
)

praat_version_string <- function() {
  v <- tryCatch(system2(PRAAT_EXEC, "--version", stdout = TRUE, stderr = FALSE)[1],
    error = function(e) NA_character_)
  if (is.na(v) || !nzchar(v)) "Praat (version unknown)" else v
}

write_reports <- function(rows) {
  # One row per routine. A routine that returns several values (MFCC
  # coefficients, formant tracks) reports its first value and `n_values`; |Δ| is
  # the largest over all of them. Expanding to one row per value repeated that
  # maximum on every row, so a single bad value looked like many and the failure
  # message below printed it once per element.
  one_row <- function(r) {
    first <- function(x) if (length(x)) as.numeric(x)[1] else NA_real_
    data.frame(name = r$name, status = r$status, n_values = length(r$pladdrr),
      praat = first(r$praat), pladdrr = first(r$pladdrr), diff = r$diff,
      tolerance = r$tolerance, stringsAsFactors = FALSE)
  }
  df <- do.call(rbind, lapply(rows, one_row))
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
      "A routine with several values shows its first value; |Δ| is the largest",
      "over all of them (`n` = number of values).",
      "",
      "| Routine | Status | n | Praat | pladdrr | |Δ| | Tolerance |",
      "|---------|--------|---|-------|---------|------|-----------|"
    )
    for (i in seq_len(nrow(df))) {
      lines <- c(lines, sprintf("| %s | %s | %d | %s | %s | %s | %s |",
                                df$name[i], df$status[i], df$n_values[i],
                                format(df$praat[i]), format(df$pladdrr[i]),
                                format(df$diff[i]), format(df$tolerance[i])))
    }
    lines <- c(lines, "", report_caveats,
      "", sprintf("_Oracle: %s on %s (%s)._", praat_version_string(),
        Sys.info()[["sysname"]], R.version$platform))
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
