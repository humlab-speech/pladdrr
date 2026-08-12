# test-autoplot-streaming-family.R
library(testthat)
library(pladdrr)

test_that("Electroglottogram autoplot/autolayer/as.data.frame work", {
  skip_if_not(file.exists(test_path("fixtures/speech_sample.wav")))
  sound <- Sound(test_path("fixtures/speech_sample.wav"))
  # Electroglottogram has no direct sound$to_electroglottogram(); the R6
  # constructor itself points to the real factory (R/electroglottogram-wrapper.R:152).
  egg <- sound$extract_electroglottogram()
  df <- as.data.frame(egg)
  expect_s3_class(df, "data.frame")
  expect_s3_class(ggplot2::autoplot(egg), "ggplot")
})

test_that("LongSound as.data.frame errors with actionable guidance, does not silently return wrong data", {
  skip_if_not(file.exists(test_path("fixtures/speech_sample.wav")))
  # LongSound is opened via longsound_open(path), not LongSound(path) directly
  # (R/longsound-wrapper.R:162; LongSound(.xptr=NULL) itself just errors
  # "Use LongSound$open() to create a LongSound from a file").
  ls_obj <- longsound_open(test_path("fixtures/speech_sample.wav"))
  expect_error(as.data.frame(ls_obj), "extract_part")
})

test_that("LongSound autoplot streams a windowed extract rather than erroring outright", {
  skip_if_not(file.exists(test_path("fixtures/speech_sample.wav")))
  ls_obj <- longsound_open(test_path("fixtures/speech_sample.wav"))
  p <- ggplot2::autoplot(ls_obj, from_time = 0, to_time = 0.1)
  expect_s3_class(p, "ggplot")
})
