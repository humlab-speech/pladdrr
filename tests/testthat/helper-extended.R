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
