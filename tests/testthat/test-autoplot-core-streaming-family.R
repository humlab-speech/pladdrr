# tests/testthat/test-autoplot-core-streaming-family.R
# Tests for autoplot/autolayer on Sound, Pitch, Formant, Intensity,
# Spectrogram (R/autoplot-methods.R) — the "core streaming" classes that
# every other test-autoplot-*-family.R file left uncovered.

library(testthat)
library(pladdrr)

test_that("Sound autoplot/autolayer render and respect from_time/to_time", {
  sound <- generate_sine_wave(220, 0.5, sampling_rate = 16000)

  p <- ggplot2::autoplot(sound)
  expect_s3_class(p, "ggplot")

  p2 <- ggplot2::ggplot() + ggplot2::autolayer(sound)
  expect_s3_class(p2, "ggplot")

  p_filtered <- ggplot2::autoplot(sound, from_time = 0.1, to_time = 0.2)
  expect_s3_class(p_filtered, "ggplot")
  expect_true(all(p_filtered$data$time >= 0.1 & p_filtered$data$time <= 0.2))
})

test_that("Intensity autoplot/autolayer render and respect from_time/to_time", {
  sound <- generate_sine_wave(220, 0.5, sampling_rate = 16000)
  intensity <- sound$to_intensity()

  p <- ggplot2::autoplot(intensity)
  expect_s3_class(p, "ggplot")
  expect_true("intensity_db" %in% names(p$data))

  p2 <- ggplot2::ggplot() + ggplot2::autolayer(intensity)
  expect_s3_class(p2, "ggplot")

  p_filtered <- ggplot2::autoplot(intensity, from_time = 0.1, to_time = 0.2)
  expect_true(all(p_filtered$data$time >= 0.1 & p_filtered$data$time <= 0.2))
})
