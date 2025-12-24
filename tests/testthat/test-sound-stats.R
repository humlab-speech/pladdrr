# test-sound-stats.R - Tests for sound statistics functions
#
# These tests verify that statistical functions compute correct values
#
# NOTE: These tests are for the DEPRECATED S3 API.
# The S3 API (sound_mean, sound_rms, etc.) is deprecated in favor of R6.
# Tests are skipped. Use R6 API: sound$get_rms(), sound$get_energy(), etc.

skip("S3 API deprecated - use R6 API instead (sound$get_*() methods)")

test_that("sound_mean() computes correct mean", {
  values <- c(-1.0, -0.5, 0.0, 0.5, 1.0)
  sound <- create_sound(values, sampling_rate = 1000)

  mean_val <- sound_mean(sound)

  expect_type(mean_val, "double")
  expect_length(mean_val, 1)
  expect_equal(mean_val, mean(values), tolerance = 1e-10)
  expect_equal(mean_val, 0.0, tolerance = 1e-10)
})

test_that("sound_mean() handles all-zero sound", {
  sound <- create_sound(rep(0, 1000), sampling_rate = 1000)

  mean_val <- sound_mean(sound)

  expect_equal(mean_val, 0.0, tolerance = 1e-10)
})

test_that("sound_min() computes correct minimum", {
  values <- c(0.5, -0.3, 1.0, -0.8, 0.2)
  sound <- create_sound(values, sampling_rate = 1000)

  min_val <- sound_min(sound)

  expect_type(min_val, "double")
  expect_length(min_val, 1)
  expect_equal(min_val, min(values), tolerance = 1e-10)
  expect_equal(min_val, -0.8, tolerance = 1e-10)
})

test_that("sound_max() computes correct maximum", {
  values <- c(0.5, -0.3, 1.0, -0.8, 0.2)
  sound <- create_sound(values, sampling_rate = 1000)

  max_val <- sound_max(sound)

  expect_type(max_val, "double")
  expect_length(max_val, 1)
  expect_equal(max_val, max(values), tolerance = 1e-10)
  expect_equal(max_val, 1.0, tolerance = 1e-10)
})

test_that("sound_rms() computes correct RMS value", {
  values <- c(0.5, -0.5, 1.0, -1.0)
  sound <- create_sound(values, sampling_rate = 1000)

  rms_val <- sound_rms(sound)

  # RMS = sqrt(mean(x^2))
  expected_rms <- sqrt(mean(values^2))

  expect_type(rms_val, "double")
  expect_length(rms_val, 1)
  expect_equal(rms_val, expected_rms, tolerance = 1e-10)
})

test_that("sound_rms() for sine wave matches theoretical value", {
  # For a sine wave with amplitude A, RMS = A/sqrt(2)
  amplitude <- 1.0
  sound <- generate_sine_wave(440, 1.0, amplitude = amplitude)

  rms_val <- sound_rms(sound)

  expected_rms <- amplitude / sqrt(2)
  # Allow some tolerance due to discrete sampling
  expect_equal(rms_val, expected_rms, tolerance = 0.01)
})

test_that("sound_rms() for zero signal is zero", {
  sound <- create_sound(rep(0, 1000), sampling_rate = 1000)

  rms_val <- sound_rms(sound)

  expect_equal(rms_val, 0.0, tolerance = 1e-10)
})

test_that("statistics functions validate input", {
  not_a_sound <- list(foo = "bar")

  expect_error(sound_mean(not_a_sound), "praat_sound")
  expect_error(sound_min(not_a_sound), "praat_sound")
  expect_error(sound_max(not_a_sound), "praat_sound")
  expect_error(sound_rms(not_a_sound), "praat_sound")
})

test_that("sound_statistics() returns comprehensive statistics list", {
  values <- c(-1.0, -0.5, 0.0, 0.5, 1.0)
  sound <- create_sound(values, sampling_rate = 1000)

  stats <- sound_statistics(sound)

  # Check structure
  expect_type(stats, "list")
  expect_named(stats, c("mean", "min", "max", "rms", "duration",
                       "n_samples", "sampling_rate"))

  # Check values
  expect_equal(stats$mean, mean(values), tolerance = 1e-10)
  expect_equal(stats$min, min(values), tolerance = 1e-10)
  expect_equal(stats$max, max(values), tolerance = 1e-10)
  expect_equal(stats$rms, sqrt(mean(values^2)), tolerance = 1e-10)
  expect_equal(stats$duration, sound$duration, tolerance = 1e-10)
  expect_equal(stats$n_samples, sound$n_samples)
  expect_equal(stats$sampling_rate, sound$sampling_rate)
})

test_that("sound_statistics() works with generated sounds", {
  sound <- generate_sine_wave(440, 0.5, sampling_rate = 22050)

  stats <- sound_statistics(sound)

  # All statistics should be present and finite
  expect_true(all(sapply(stats, is.finite)))

  # Mean should be near zero for centered sine wave
  expect_equal(stats$mean, 0.0, tolerance = 0.01)

  # Min and max should be roughly symmetric for sine wave
  expect_equal(abs(stats$min), stats$max, tolerance = 0.01)

  # Duration and sampling rate should match input
  expect_equal(stats$duration, 0.5, tolerance = 1e-6)
  expect_equal(stats$sampling_rate, 22050)
})

test_that("sound_statistics() handles edge cases", {
  # Single sample
  sound_single <- create_sound(c(0.5), sampling_rate = 1000)
  stats_single <- sound_statistics(sound_single)
  expect_equal(stats_single$mean, 0.5)
  expect_equal(stats_single$min, 0.5)
  expect_equal(stats_single$max, 0.5)
  expect_equal(stats_single$rms, 0.5)

  # All zeros
  sound_zero <- create_sound(rep(0, 100), sampling_rate = 1000)
  stats_zero <- sound_statistics(sound_zero)
  expect_equal(stats_zero$mean, 0.0, tolerance = 1e-10)
  expect_equal(stats_zero$min, 0.0, tolerance = 1e-10)
  expect_equal(stats_zero$max, 0.0, tolerance = 1e-10)
  expect_equal(stats_zero$rms, 0.0, tolerance = 1e-10)

  # Constant non-zero
  sound_const <- create_sound(rep(0.7, 100), sampling_rate = 1000)
  stats_const <- sound_statistics(sound_const)
  expect_equal(stats_const$mean, 0.7, tolerance = 1e-10)
  expect_equal(stats_const$min, 0.7, tolerance = 1e-10)
  expect_equal(stats_const$max, 0.7, tolerance = 1e-10)
  expect_equal(stats_const$rms, 0.7, tolerance = 1e-10)
})

test_that("sound_statistics() validates input", {
  not_a_sound <- list(foo = "bar")

  expect_error(sound_statistics(not_a_sound), "praat_sound")
  expect_error(sound_statistics(NULL))
})

test_that("statistics match between individual functions and sound_statistics()", {
  sound <- generate_noise(0.5, seed = 42)

  stats <- sound_statistics(sound)
  mean_val <- sound_mean(sound)
  min_val <- sound_min(sound)
  max_val <- sound_max(sound)
  rms_val <- sound_rms(sound)

  # Individual functions should match stats list
  expect_equal(stats$mean, mean_val)
  expect_equal(stats$min, min_val)
  expect_equal(stats$max, max_val)
  expect_equal(stats$rms, rms_val)
})
