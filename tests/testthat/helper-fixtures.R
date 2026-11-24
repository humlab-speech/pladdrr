# Audio fixtures live in tests/testthat/fixtures/ and are excluded from the
# built tarball (.Rbuildignore) to keep it small; tests that need one skip
# when it is absent. They are FLAC, decoded natively.
fixture_path <- function(...) {
  path <- testthat::test_path("fixtures", ...)
  testthat::skip_if_not(file.exists(path), "audio fixture not shipped in tarball")
  path
}
