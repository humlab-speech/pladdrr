#' srr_stats
#'
#' Standards compliance record for the rOpenSci statistical-software review
#' (General Standards plus Time Series). Tags are kept together in this file
#' with pointers to where each standard is addressed, rather than scattered
#' through the sources. `@srrstats` = addressed, `@srrstatsTODO` = open or
#' partial (the text says which), `@srrstatsNA` = not applicable (see the
#' `NA_standards` block). Unreviewed: the Unsupervised and EDA categories,
#' pending the editors' view on scope (see `dev/ropensci-stats-plan.md`).
#'
#' @srrstatsVerbose TRUE
#'
#' @srrstatsTODO {G1.5} PARTIAL. `inst/benchmarks/` holds scripts for the performance claims in the vignettes; no associated publication yet, so the scripts are not tied to one.
#' @srrstatsTODO {G1.6} OPEN. `inst/benchmarks/04_parselmouth_comparison.R` compares with Python's parselmouth; no R-package comparison (speakr, rPraat) exists.
#' @srrstatsTODO {G2.0} PARTIAL. Scalar parameters are checked by the validators in `R/validators.R` (`.check_string`, `.check_flag`, `.check_pitch_range`, `.check_positive_count`, ...) and raise `pladdrr_input_error`; the file-listing, pair/batch and pitch batch/direct functions that `autotest` showed accepting length-2 or wrongly typed arguments now validate (`tests/testthat/test-argument-validation.R`). The rest of the exported functions have not been audited one by one (`dev/ropensci-autotest-findings.md` lists the remaining mutation diagnostics).
#' @srrstatsTODO {G2.0a} PARTIAL. Length expectations are documented in `@param` for validated parameters; not yet uniform.
#' @srrstatsTODO {G2.1} PARTIAL. As G2.0.
#' @srrstatsTODO {G2.1a} PARTIAL. As G2.0a.
#' @srrstatsTODO {G2.2} PARTIAL. Checked for the validated parameters; `autotest` results (`dev/autotest/`) show where multivariate input is still accepted.
#' @srrstatsTODO {G5.2} PARTIAL. About 700 `expect_error`/`expect_warning` calls, and every message reachable without removing a dependency or breaking the installation is triggered by a test (see G5.2b).
#' @srrstatsTODO {G5.2b} PARTIAL. 193 of the 230 literal messages that had no matching test fragment are now covered: 134 by tests (`tests/testthat/test-error-messages-*.R`) and 59 by removing dead `requireNamespace("ggplot2")` guards for a package that is in Imports. `dev/message-baseline.txt` lists the remaining 37, all of which need a precondition that is awkward to build in-process: a package from Suggests being absent (patchwork, gridExtra, RcppXPtrUtils, parallel), an install that is broken (`pitch_module not available`), a build without CLAPACK, empty Excitation/FormantGrid/MFCC/DTW/Matrix/BarkSpectrogram objects, or the attach banner. A ratchet test stops the list growing.
#' @srrstatsTODO {TS1.2} PARTIAL. See G2.0; class validation of object arguments exists in most wrappers (`inherits(x, "Sound")`) but is not uniform.
#' @srrstatsTODO {TS2.4} PARTIAL. The one run-time check is on the analysis window: `sound$to_pitch_ac()`, `to_pitch_cc()`, `to_harmonicity_cc()` and `to_intensity()` stop with a `pladdrr_input_error` that names the duration the window needs when the signal is shorter (`.check_window_fits()` in `R/validators.R`, `tests/testthat/test-edge-conditions.R`). No test of stationarity of the signal itself; `vignettes/terminology.Rmd` advises on window and pitch-floor choice.
#' @srrstatsTODO {TS2.4a} PARTIAL. See TS2.4: a diagnostic exists for too-short signals, not for non-stationary ones.
#' @srrstatsTODO {TS2.4b} PARTIAL. `vignettes/terminology.Rmd` advises on choosing windows; no transformation routines are provided.
#' @srrstatsTODO {TS4.1} OPEN. `units` attributes of vector input are dropped (TS1.7), so they are not carried into return values.
#' @srrstatsTODO {TS4.2} PARTIAL. `@return` is documented for exported functions; the class of every return value is not stated uniformly.
#' @srrstatsTODO {TS4.3} PARTIAL. Time is in seconds and frequency in hertz throughout (`vignettes/terminology.Rmd`); individual return values do not always repeat the unit.
#'
#' @noRd
NULL

#' NA_standards
#'
#' @srrstatsNA {G2.4d} pladdrr has no factor parameters.
#' @srrstatsNA {G2.4e} pladdrr has no factor parameters.
#' @srrstatsNA {G2.5} pladdrr has no factor parameters.
#' @srrstatsNA {G2.7} pladdrr's inputs are Praat objects and numeric vectors, not tabular data; data frames appear only as outputs (`as.data.frame()` methods) and as file/parameter lists in the batch functions.
#' @srrstatsNA {G2.8} No tabular input to convert; see G2.7.
#' @srrstatsNA {G2.9} No tabular input conversion takes place; see G2.7.
#' @srrstatsNA {G2.10} No tabular input; see G2.7.
#' @srrstatsNA {G2.11} No tabular input; see G2.7.
#' @srrstatsNA {G2.12} No tabular input; see G2.7.
#' @srrstatsNA {G2.14b} By design pladdrr never ignores missing samples and carries on: it errors (G2.14a). Praat has no missing-sample type.
#' @srrstatsNA {G2.14c} By design pladdrr does not impute: imputation is the caller's decision and would change the signal being measured (`vignettes/terminology.Rmd`).
#' @srrstatsNA {G3.1} No covariance computation is exposed with a choice of method; PCA and Discriminant delegate to Praat's own routines.
#' @srrstatsNA {G3.1a} See G3.1.
#' @srrstatsNA {G5.4c} A reference implementation (the Praat application) is available, so stored published values are not needed.
#' @srrstatsNA {G5.11} No test downloads data; all fixtures are in the repository.
#' @srrstatsNA {G5.11a} See G5.11.
#' @srrstatsNA {TS1.8} Time is in seconds relative to the start of the signal; no calendar systems are used.
#' @srrstatsNA {TS2.1b} Missing samples are an error rather than analysed as irregular data; see G2.14b.
#' @srrstatsNA {TS2.1c} No imputation; see G2.14c.
#' @srrstatsNA {TS2.5} No auto-covariance matrices are constructed or accepted (autocorrelation pitch is internal to Praat).
#' @srrstatsNA {TS2.6} See TS2.5.
#' @srrstatsNA {TS3.0} pladdrr performs analysis, not forecasting (LPC prediction is an analysis model, not a forecast).
#' @srrstatsNA {TS3.1} See TS3.0.
#' @srrstatsNA {TS3.2} See TS3.0.
#' @srrstatsNA {TS3.3} See TS3.0.
#' @srrstatsNA {TS3.3a} See TS3.0.
#' @srrstatsNA {TS3.3b} See TS3.0.
#' @srrstatsNA {TS4.0a} Results are not returned in the input's class; see TS4.0b.
#' @srrstatsNA {TS4.4} No forecasting or stationarity-inducing transformations are implemented.
#' @srrstatsNA {TS4.5} See TS4.4.
#' @srrstatsNA {TS4.5a} See TS4.4.
#' @srrstatsNA {TS4.5b} See TS4.4.
#' @srrstatsNA {TS4.5c} See TS4.4.
#' @srrstatsNA {TS4.6} No forecasting.
#' @srrstatsNA {TS4.6a} No forecasting.
#' @srrstatsNA {TS4.6b} No forecasting.
#' @srrstatsNA {TS4.6c} No forecasting.
#' @srrstatsNA {TS4.7} No forecasting.
#' @srrstatsNA {TS4.7a} No forecasting.
#' @srrstatsNA {TS4.7b} No forecasting.
#' @srrstatsNA {TS4.7c} No forecasting.
#' @srrstatsNA {TS5.6} No forecasting.
#' @srrstatsNA {TS5.7} No forecasting.
#' @srrstatsNA {TS5.8} No forecasting.
#'
#' @noRd
NULL
