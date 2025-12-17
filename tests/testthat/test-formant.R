# Tests for Formant class via Rcpp module
context("Formant class tests")

test_that("Formant module is accessible", {
  expect_true("Formant" %in% names(praat))
})

test_that("Formant analysis works", {
  skip("Requires actual Praat integration")
  # When implemented:
  # snd <- praat$Sound$new("test.wav")
  # formant <- snd$to_formant()
  # expect_s4_class(formant, "Rcpp_PraatFormant")
})

test_that("Formant values can be extracted", {
  skip("Requires actual Praat integration")
  # When implemented:
  # snd <- praat$Sound$new("test.wav")
  # formant <- snd$to_formant()
  # f1 <- formant$get_value_at_time(1, 0.5)
  # f2 <- formant$get_value_at_time(2, 0.5)
  # expect_gt(f1, 0)
  # expect_gt(f2, f1)  # F2 should be higher than F1
})

test_that("Formant data frame export works", {
  skip("Requires actual Praat integration")
  # When implemented:
  # snd <- praat$Sound$new("test.wav")
  # formant <- snd$to_formant()
  # df <- formant$get_values()
  # expect_s3_class(df, "data.frame")
  # expect_true("F1" %in% names(df))
  # expect_true("F2" %in% names(df))
})
