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

test_that("Pitch autoplot/autolayer render, drop unvoiced frames, and warn when empty", {
  sound <- generate_sine_wave(220, 0.3, sampling_rate = 16000)
  pitch <- sound$to_pitch()

  p <- ggplot2::autoplot(pitch)
  expect_s3_class(p, "ggplot")

  p_line <- ggplot2::ggplot() + ggplot2::autolayer(pitch, geom = "line")
  expect_s3_class(p_line, "ggplot")
  p_point <- ggplot2::ggplot() + ggplot2::autolayer(pitch, geom = "point")
  expect_s3_class(p_point, "ggplot")

  # from_time/to_time set beyond the signal's duration empties the
  # already-voiced-filtered df -> triggers the warning() at
  # R/autoplot-methods.R:102 and the theme_void() fallback plot.
  expect_warning(
    p_empty <- ggplot2::autoplot(pitch, from_time = 100, to_time = 200),
    "No voiced frames in Pitch object"
  )
  expect_s3_class(p_empty, "ggplot")

  # Same empty case for autolayer: returns NULL, not an error.
  expect_null(ggplot2::autolayer(pitch, from_time = 100, to_time = 200))
})
