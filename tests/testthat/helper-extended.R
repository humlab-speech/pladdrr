#' @srrstats {G5.5} Every test file that draws random numbers sets a seed (`withr::local_seed()` or `set.seed()`); the deterministic analyses are independent of the RNG state (`tests/testthat/test-noise-susceptibility.R`).
#' @srrstats {G5.10} `PLADDRR_EXTENDED_TESTS=true` switches on timing, large-fixture and compile-at-test-time tests (`skip_if_not_extended()` in `tests/testthat/helper-extended.R`); CI wiring in `.github/workflows/R-CMD-check.yaml`.
#' @srrstats {G5.12} Platform, memory, runtime and artefact notes are in `.github/CONTRIBUTING.md`, section 'Extended tests'.

# Extended tests: timing assertions, multi-hour-of-audio fixtures and tests that
# compile C++ at test time. They run in the common testthat framework but only
# when PLADDRR_EXTENDED_TESTS=true (rOpenSci G5.10). CI turns the flag on for
# commits whose message contains "run-extended", for the weekly schedule and for
# the coverage runs; see .github/CONTRIBUTING.md ("Extended tests").
skip_if_not_extended <- function() {
  if (!identical(tolower(Sys.getenv("PLADDRR_EXTENDED_TESTS")), "true")) {
    testthat::skip("Extended tests off (set PLADDRR_EXTENDED_TESTS=true)")
  }
}
