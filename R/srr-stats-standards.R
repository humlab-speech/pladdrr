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
#' @srrstats {G1.0} Primary references for each algorithm family, with DOIs checked against Crossref, are in `R/pladdrr-references.R` (`?pladdrr-references`), linked from `?pladdrr`.
#' @srrstats {G1.1} README section 'Other similar packages' states that pladdrr is, to the authors' knowledge, the first R package to compile Praat's algorithms in-process, that it reproduces rather than improves Praat's methods, and lists Praat scripting, parselmouth, speakr, rPraat, PraatR and wrassp.
#' @srrstats {G1.2} Life-cycle statement in `.github/CONTRIBUTING.md`, section 'Life cycle'.
#' @srrstats {G1.3} `vignettes/terminology.Rmd` defines each measure the package returns (F0, HNR, intensity, formants, jitter, shimmer, CPP/CPPS, AVQI) and the missing/undefined-value conventions. pladdrr performs no statistical inference, so there are no hypothesis-test or interval terms to define.
#' @srrstats {G2.15} The base statistics calls in `R/` (`mean`, `sd`, `median`, `quantile` in `R/s3-methods.R`, `R/sound-stats.R`) run on vectors that are either filtered for undefined values first (`voiced_freqs`, `valid_freqs`, `valid_intensities`) or are sample values that `Sound$from_values()` has already checked to be finite. Praat-side aggregates (`get_mean()` and friends) skip undefined frames themselves (`vignettes/terminology.Rmd`).
#' @srrstats {TS1.6} Irregularly spaced objects (PitchTier and the other tiers, PointProcess) keep their points in time order on insertion, because Praat inserts in sorted order. Tested in `tests/testthat/test-edge-conditions.R` (`PitchTier` filled out of order).
#' @srrstats {TS5.1} Time-domain `autoplot()` methods label the horizontal axis "Time (s)" (37 plot constructors; tested for Sound, Pitch, Formant, Intensity, Spectrogram, Harmonicity and PointProcess in `tests/testthat/test-plot-axes.R`).
#' @srrstats {TS5.2} Time is on the horizontal axis by default in those methods (`test-plot-axes.R`).
#' @srrstats {TS5.3} The unit (seconds, hertz, dB) is part of every axis label (`test-plot-axes.R`).
#' @srrstats {TS5.4} Frequency axes show non-negative hertz ("Frequency (Hz)"); no axis spans [-pi, pi] (`test-plot-axes.R`).
#' @srrstats {TS5.5} `autoplot.Pitch(connect_gaps = FALSE)` breaks the line at unvoiced frames; the default (`TRUE`) joins across them. Tested in `test-plot-axes.R`.
#' @srrstats {G5.1} Test signals are either synthesised by exported generators (`generate_sine_wave()`, `generate_noise()`, `sound_create_pure_tone()`, `klattgrid_create_from_vowel()`) or ship in `inst/`; `?pladdrr-test-data` lists the files and how the tests use them.
#' @srrstats {G5.7} Accuracy as a function of data size: `tests/testthat/test-parameter-recovery.R` shows the F0 error of a noisy tone falling with recording length (3 s versus 0.3 s, 8 seeds), and harmonicity tracking the injected SNR over 0-30 dB. Timing scaling is in the extended tier.
#' @srrstats {G1.4a} All 149 hand-written internal functions of the form `.name <- function` carry roxygen blocks with `@noRd` (listed by `Rscript dev/internal-docs.R`); generated `R/RcppExports.R` is exempt, and the R6 method tables are documented through their class pages.
#' @srrstats {G3.0} Exact floating-point comparisons are limited to (a) sentinel and boundary values typed by the caller (`0` = default / whole range, `-1` balance, `1` multiplier) and (b) division-by-zero guards, where a tolerance would change the result. Each site in the package's own C++ is annotated `// G3.0: exact - ...` (`rg "G3.0: exact" src`), R-level sentinels use `identical(x, 0)`, and the vendored Praat sources, which compare exactly in many places, are left untouched on purpose (`inst/agents/PRAAT_MODIFICATIONS.md`).
#' @srrstats {G1.4} All exported functions and classes are documented with roxygen2 (`Config/roxygen2/version: 8.1.0`, 328 Rd files).
#' @srrstats {G2.3} Character parameters that select an option are matched with `match.arg()` or an explicit `switch()` (see `R/validators.R`, `.pitch_unit_code`, `.window_shape_code`, `.ltas_unit_code`).
#' @srrstats {G2.3a} `match.arg()` is used 87 times in `R/`; option lookups that map to Praat integer codes use `switch()` with an explicit error or documented default.
#' @srrstats {G2.4} Values crossing into C++ are converted explicitly (`as.integer()`, `as.numeric()`, `as.character()`) at the R6 wrapper boundary, for example in `R/sound-wrapper.R`, `R/pitch-wrapper.R`.
#' @srrstats {G2.4a} Integer arguments are passed through `as.integer()` in the wrappers (e.g. channel and tier numbers).
#' @srrstats {G2.4b} Continuous arguments are passed through `as.numeric()` (e.g. times in `LongSound$save_part()`).
#' @srrstats {G2.4c} Paths and names are converted with `as.character()`, not `paste()`.
#' @srrstats {G2.6} `Sound$from_values()` accepts integer, `units` and `ts` vectors (classed vectors keep their numbers; a `ts` supplies `sampling_rate` and `start_time`). Tested in `tests/testthat/test-edge-conditions.R`.
#' @srrstats {G2.13} Input samples are checked in `Sound$from_values()` (`.check_finite_samples()` in `R/validators.R`): NA, NaN and Inf are a `pladdrr_input_error`. Tested in `tests/testthat/test-edge-conditions.R`.
#' @srrstats {G2.14} The package's policy is documented in `vignettes/terminology.Rmd` ('Missing and undefined values'): input NA is an error, undefined output is NaN, imputation is left to the caller.
#' @srrstats {G2.14a} Error on missing input: `.check_finite_samples()`; `tests/testthat/test-edge-conditions.R`.
#' @srrstats {G2.16} Inf and -Inf input are rejected (`.check_finite_samples()`); undefined output values are NaN, documented in `vignettes/terminology.Rmd`; aggregates skip undefined frames.
#' @srrstats {G4.0} All 27 `save()`/`write` methods route the path through `.ensure_suffix()` (`R/validators.R`): the format's suffix is appended when none is given. Tested in `tests/testthat/test-output-suffix.R`, including a static check that no `.cpp$save` call bypasses the helper.
#' @srrstats {G5.0} Tests compare against Praat itself on fixed signals (`tests/testthat/test-praat-faithfulness.R`, `tests/testthat/test-fidelity-fingerprint.R`) and against synthetic signals with known properties (`tests/testthat/test-parameter-recovery.R`).
#' @srrstats {G5.2a} Every literal condition message in `R/` is unique, enforced by `tests/testthat/test-message-uniqueness.R` (parser-based audit in `dev/audit-messages.R`).
#' @srrstats {G5.4} Correctness is tested against Praat 6.4.x as oracle in `tests/testthat/test-praat-faithfulness.R` (19 routines, per-routine tolerances recorded in `inst/agents/FAITHFULNESS_REPORT.md`) and against stored fingerprints in `tests/testthat/test-fidelity-fingerprint.R`.
#' @srrstats {G5.4a} Scalar-versus-SIMD and R-versus-C++ paths are compared in `tests/testthat/test-simd-accuracy.R` and related `*-simd-*` test files.
#' @srrstats {G5.4b} pladdrr is a new implementation of existing Praat methods; the previous implementation (the Praat application) is the oracle, with oracle versions recorded in `inst/agents/FAITHFULNESS_REPORT.md`.
#' @srrstats {G5.5} Every test file that draws random numbers sets a seed (`withr::local_seed()` or `set.seed()`); the deterministic analyses are independent of the RNG state (`tests/testthat/test-noise-susceptibility.R`).
#' @srrstats {G5.6} `tests/testthat/test-parameter-recovery.R`: F0 of pure tones (80-440 Hz), formants of Klatt-synthesised vowels, intensity of sines at known amplitude, and harmonicity against injected SNR.
#' @srrstats {G5.6a} Tolerances are stated in the file header with the measured worst-case error they were set from.
#' @srrstats {G5.6b} The noise-driven recovery test runs under three seeds.
#' @srrstats {G5.8} `tests/testthat/test-edge-conditions.R`: a matrix of degenerate inputs against five core analyses.
#' @srrstats {G5.8a} Zero-length input is rejected at construction (`test-edge-conditions.R`).
#' @srrstats {G5.8b} Character and complex input are rejected (`test-edge-conditions.R`).
#' @srrstats {G5.8c} All-NA, NaN, Inf (rejected), silent, constant (DC) and clipped signals (`test-edge-conditions.R`).
#' @srrstats {G5.8d} Signals shorter than the analysis window, non-finite and out-of-range parameters (`test-edge-conditions.R`).
#' @srrstats {G5.9} `tests/testthat/test-noise-susceptibility.R`.
#' @srrstats {G5.9a} Machine-epsilon-scale noise leaves pitch, intensity, formants and HNR unchanged within tolerance.
#' @srrstats {G5.9b} Deterministic analyses are identical under different RNG seeds (`test-noise-susceptibility.R`); Praat's own `fit_method = "robust slow"` CPPS fit is non-deterministic upstream and documented as such (`vignettes/terminology.Rmd`, `inst/agents/FAITHFULNESS_REPORT.md`).
#' @srrstats {G5.10} `PLADDRR_EXTENDED_TESTS=true` switches on timing, large-fixture and compile-at-test-time tests (`skip_if_not_extended()` in `tests/testthat/helper-extended.R`); CI wiring in `.github/workflows/R-CMD-check.yaml`.
#' @srrstats {G5.12} Platform, memory, runtime and artefact notes are in `.github/CONTRIBUTING.md`, section 'Extended tests'.
#' @srrstats {TS1.0} Analyses take `Sound`, `Pitch`, `Formant`, ... objects that carry their time axis; `Sound$from_values()` requires an explicit `sampling_rate` (and `start_time`) for vector input.
#' @srrstats {TS1.1} Accepted input classes for sample data are documented in `?sound_from_values`, which covers numeric, integer, `units` and `ts` input.
#' @srrstats {TS1.3} Vector input enters through `sound_from_values()`, which validates and converts it to the single internal representation (a Sound pointer).
#' @srrstats {TS1.4} A `ts` argument's start and frequency are carried into `start_time` and `sampling_rate` (`tests/testthat/test-edge-conditions.R`).
#' @srrstats {TS1.5} A Sound's time axis is regular by construction (`xmin + (i - 1) * dx`).
#' @srrstats {TS1.7} `units` vectors are accepted; their values are used as given and the units are not interpreted (`?sound_from_values`).
#' @srrstats {TS2.0} Sample data are regular and explicit: NaN/NA samples are rejected at input (G2.13).
#' @srrstats {TS2.1} See G2.14: input missing values are an error.
#' @srrstats {TS2.1a} Error on missing data (`.check_finite_samples()`).
#' @srrstats {TS2.2} The stationarity assumption within an analysis window is documented in `vignettes/terminology.Rmd` ('Signals and time').
#' @srrstats {TS2.3} As TS2.2.
#' @srrstats {TS4.0} Return values are unique, class-defined objects (`Pitch`, `Formant`, `Intensity`, `Harmonicity`, ...), each with `as.data.frame()` methods.
#' @srrstats {TS4.0b} As TS4.0: results are in dedicated classes, not in the input's class.
#' @srrstats {TS5.0} `plot()` and `autoplot()` methods exist for the time-sampled classes (`R/plotting-methods.R`, `R/autoplot-methods.R`).
#' @srrstatsTODO {G1.5} PARTIAL. `inst/benchmarks/` holds scripts for the performance claims in the vignettes; no associated publication yet, so the scripts are not tied to one.
#' @srrstatsTODO {G1.6} OPEN. `inst/benchmarks/04_parselmouth_comparison.R` compares with Python's parselmouth; no R-package comparison (speakr, rPraat) exists.
#' @srrstatsTODO {G2.0} PARTIAL. Scalar parameters are checked by the validators in `R/validators.R` (`.check_string`, `.check_flag`, `.check_pitch_range`, `.check_positive_count`, ...) and raise `pladdrr_input_error`; the file-listing, pair/batch and pitch batch/direct functions that `autotest` showed accepting length-2 or wrongly typed arguments now validate (`tests/testthat/test-argument-validation.R`). The rest of the exported functions have not been audited one by one (`dev/ropensci-autotest-findings.md` lists the remaining mutation diagnostics).
#' @srrstatsTODO {G2.0a} PARTIAL. Length expectations are documented in `@param` for validated parameters; not yet uniform.
#' @srrstatsTODO {G2.1} PARTIAL. As G2.0.
#' @srrstatsTODO {G2.1a} PARTIAL. As G2.0a.
#' @srrstatsTODO {G2.2} PARTIAL. Checked for the validated parameters; `autotest` results (`dev/autotest/`) show where multivariate input is still accepted.
#' @srrstats {G2.3b} Unit, window-shape, averaging-method and format names are lower-cased before lookup (`.pitch_unit_code`, `.window_shape_code`, `.ltas_unit_code`, `.intensity_avg_code`, `Sound$save(format=)`); parameters that list their choices as a vector use `match.arg()` and are case-sensitive. `vignettes/terminology.Rmd`, section 'Option strings', states both.
#' @srrstatsTODO {G5.2} PARTIAL. About 700 `expect_error`/`expect_warning` calls, and every message reachable without removing a dependency or breaking the installation is triggered by a test (see G5.2b).
#' @srrstatsTODO {G5.2b} PARTIAL. 193 of the 230 literal messages that had no matching test fragment are now covered: 134 by tests (`tests/testthat/test-error-messages-*.R`) and 59 by removing dead `requireNamespace("ggplot2")` guards for a package that is in Imports. `dev/message-baseline.txt` lists the remaining 37, all of which need a precondition that is awkward to build in-process: a package from Suggests being absent (patchwork, gridExtra, RcppXPtrUtils, parallel), an install that is broken (`pitch_module not available`), a build without CLAPACK, empty Excitation/FormantGrid/MFCC/DTW/Matrix/BarkSpectrogram objects, or the attach banner. A ratchet test stops the list growing.
#' @srrstatsTODO {G5.3} PARTIAL. `tests/testthat/test-nan-guards.R` covers several analyses; undefined (NaN) output is intended for unvoiced frames and is documented.
#' @srrstatsTODO {TS1.2} PARTIAL. See G2.0; class validation of object arguments exists in most wrappers (`inherits(x, "Sound")`) but is not uniform.
#' @srrstatsTODO {TS2.4} OPEN. No run-time stationarity diagnostics; the vignette advises on window and pitch-floor choice.
#' @srrstatsTODO {TS2.4a} OPEN. No diagnostic messages or warnings for non-stationary input.
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
