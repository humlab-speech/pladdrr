# Tests for Pitch class via Rcpp module
context("Pitch class tests")

test_that("Pitch module is accessible", {
  expect_true("Pitch" %in% names(praat))
})

test_that("Pitch methods are defined", {
  # Verify that Pitch class has expected methods
  pitch_class <- praat$Pitch
  expect_true(is(pitch_class, "refObjectGenerator"))
})

test_that("Pitch statistics can be computed", {
  skip("Requires actual Praat integration")
  # When implemented:
  # snd <- praat$Sound$new("test.wav")
  # pitch <- snd$to_pitch()
  # mean_pitch <- pitch$get_mean()
  # expect_type(mean_pitch, "double")
  # expect_gt(mean_pitch, 0)
})

test_that("Pitch values at specific times", {
  skip("Requires actual Praat integration")
  # When implemented:
  # snd <- praat$Sound$new("test.wav")
  # pitch <- snd$to_pitch()
  # val <- pitch$get_value_at_time(0.5)
  # expect_type(val, "double")
})
