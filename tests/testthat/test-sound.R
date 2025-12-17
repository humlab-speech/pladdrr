# Tests for Sound class via Rcpp module
context("Sound class tests")

test_that("Sound module is loaded", {
  expect_true(exists("praat"))
  expect_true("Sound" %in% names(praat))
})

test_that("Sound can be created from file path", {
  skip("Requires actual Praat integration")
  # When implemented with real Praat:
  # snd <- praat$Sound$new("test.wav")
  # expect_s4_class(snd, "Rcpp_PraatSound")
})

test_that("Sound properties are accessible", {
  skip("Requires actual Praat integration")
  # When implemented:
  # snd <- praat$Sound$new("test.wav")
  # expect_type(snd$duration, "double")
  # expect_type(snd$sample_rate, "double")
  # expect_gt(snd$duration, 0)
})

test_that("Sound to_pitch method works", {
  skip("Requires actual Praat integration")
  # When implemented:
  # snd <- praat$Sound$new("test.wav")
  # pitch <- snd$to_pitch()
  # expect_s4_class(pitch, "Rcpp_PraatPitch")
})

test_that("Rcpp module approach is faster than R6", {
  skip("Requires actual benchmarking")
  # This test would compare execution time of:
  # - Rcpp module method calls
  # - Equivalent R6 wrapper calls
  # Expected: module calls should be 2-5x faster
})

test_that("Memory usage is efficient", {
  skip("Requires actual memory profiling")
  # This test would verify:
  # - No unnecessary data copying
  # - Proper cleanup via C++ destructors
  # - Reference semantics working correctly
})
