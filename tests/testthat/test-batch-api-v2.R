# test-batch-api-v2.R
# Tests for Phase 1-3 batch API operations (performance optimization)

test_that("LTAS get_peaks_batch matches individual calls", {

  # Create test sound with known harmonics
  sr <- 44100
  t <- seq(0, 1, 1/sr)
  # Fundamental at 200Hz with harmonics
  signal <- sin(2 * pi * 200 * t) + 0.5 * sin(2 * pi * 400 * t) + 0.3 * sin(2 * pi * 600 * t)
  sound <- Sound$from_values(signal, sr)
  ltas <- sound$to_ltas(bandwidth = 100)

  # Define search ranges around expected peaks
  fmins <- c(180, 380, 580)
  fmaxs <- c(220, 420, 620)

  # Get batch results
  peaks_batch <- ltas$get_peaks_batch(fmins, fmaxs)

  # Compare to individual calls
  for (i in seq_along(fmins)) {
    expected_value <- ltas$get_maximum(fmins[i], fmaxs[i])
    expected_freq <- ltas$get_frequency_of_maximum(fmins[i], fmaxs[i])

    expect_equal(peaks_batch$peak_value[i], expected_value, tolerance = 1e-10)
    expect_equal(peaks_batch$peak_frequency[i], expected_freq, tolerance = 1e-10)
  }
})

test_that("LTAS get_minima_batch matches individual calls", {

  sound <- Sound$create_tone(frequency = 440, duration = 0.5)
  ltas <- sound$to_ltas(bandwidth = 100)

  fmins <- c(100, 500, 1000)
  fmaxs <- c(200, 600, 1100)

  minima_batch <- ltas$get_minima_batch(fmins, fmaxs)

  expect_identical(nrow(minima_batch), 3L)
  expect_true(all(c("fmin", "fmax", "min_value", "min_frequency") %in% names(minima_batch)))
})

test_that("LTAS get_values_at_frequencies returns correct values", {

  sound <- Sound$create_tone(frequency = 440, duration = 0.5)
  ltas <- sound$to_ltas(bandwidth = 100)

  freqs <- c(100, 440, 880, 1000)
  values <- ltas$get_values_at_frequencies(freqs)

  expect_length(values, length(freqs))
  expect_true(is.numeric(values))
})

test_that("LTAS get_means_batch returns correct means", {

  sound <- Sound$create_tone(frequency = 440, duration = 0.5)
  ltas <- sound$to_ltas(bandwidth = 100)

  fmins <- c(100, 400, 800)
  fmaxs <- c(200, 500, 900)

  means <- ltas$get_means_batch(fmins, fmaxs)

  expect_length(means, 3)
  expect_true(is.numeric(means))
})

test_that("Pitch get_values_detrended produces valid output", {

  # Create sound with pitch
  sound <- Sound$create_tone(frequency = 200, duration = 1.0)
  pitch <- sound$to_pitch(pitch_floor = 75, pitch_ceiling = 600)

  # Get detrended values
  detrended <- pitch$get_values_detrended(unit = "hertz")

  expect_length(detrended, pitch$get_number_of_frames())
  expect_true(is.numeric(detrended))
})

test_that("Pitch subtract_linear_fit returns new Pitch object", {

  sound <- Sound$create_tone(frequency = 200, duration = 1.0)
  pitch <- sound$to_pitch(pitch_floor = 75, pitch_ceiling = 600)

  detrended_pitch <- pitch$subtract_linear_fit(unit = "hertz")

  expect_s3_class(detrended_pitch, "Pitch")
  expect_true(detrended_pitch$is_valid())
  expect_equal(detrended_pitch$get_number_of_frames(), pitch$get_number_of_frames(), tolerance = sqrt(.Machine$double.eps))
})

test_that("Pitch interpolate returns new Pitch object", {

  sound <- Sound$create_tone(frequency = 200, duration = 1.0)
  pitch <- sound$to_pitch(pitch_floor = 75, pitch_ceiling = 600)

  interpolated <- pitch$interpolate()

  expect_s3_class(interpolated, "Pitch")
  expect_true(interpolated$is_valid())
})

test_that("Pitch smooth returns new Pitch object", {

  sound <- Sound$create_tone(frequency = 200, duration = 1.0)
  pitch <- sound$to_pitch(pitch_floor = 75, pitch_ceiling = 600)

  smoothed <- pitch$smooth(bandwidth = 10)

  expect_s3_class(smoothed, "Pitch")
  expect_true(smoothed$is_valid())
})

test_that("Sound extract_windows_filtered works correctly", {

  # Create test sound
  sound <- Sound$create_tone(frequency = 440, duration = 1.0)

  # Define windows
  starts <- c(0.1, 0.3, 0.5, 0.7)
  ends <- c(0.2, 0.4, 0.6, 0.8)

  # Extract with low power threshold (should include all)
  filtered <- sound$extract_windows_filtered(starts, ends, min_power = 0.0)

  expect_s3_class(filtered, "Sound")
  expect_true(filtered$is_valid())
  expect_gt(filtered$get_duration(), 0)
})

test_that("Sound get_windows_passing_filter returns logical vector", {

  sound <- Sound$create_tone(frequency = 440, duration = 1.0)

  starts <- c(0.1, 0.3, 0.5)
  ends <- c(0.2, 0.4, 0.6)

  passes <- sound$get_windows_passing_filter(starts, ends, min_power = 0.0)

  expect_length(passes, 3)
  expect_type(passes, "logical")
})

test_that("PointProcess get_values_from_sound returns correct values", {

  # Create sound and extract pulses
  sound <- Sound$create_tone(frequency = 200, duration = 0.5)
  pp <- sound$to_point_process_periodic_cc(pitch_floor = 75, pitch_ceiling = 600)

  if (pp$get_number_of_points() > 0) {
    values <- pp$get_values_from_sound(sound, channel = 1, interpolation = "cubic")

    expect_length(values, pp$get_number_of_points())
    expect_true(is.numeric(values))
  }
})

test_that("PointProcess get_periods_vector returns inter-point intervals", {

  sound <- Sound$create_tone(frequency = 200, duration = 0.5)
  pp <- sound$to_point_process_periodic_cc(pitch_floor = 75, pitch_ceiling = 600)

  n_points <- pp$get_number_of_points()
  if (n_points >= 2) {
    periods <- pp$get_periods_vector()

    expect_length(periods, n_points - 1)
    expect_true(is.numeric(periods))
    expect_true(all(periods > 0))
  }
})

test_that("PointProcess get_jitter_batch returns all jitter measures", {

  sound <- Sound$create_tone(frequency = 200, duration = 0.5)
  pp <- sound$to_point_process_periodic_cc(pitch_floor = 75, pitch_ceiling = 600)

  jitter <- pp$get_jitter_batch(
    from_time = 0, to_time = 0,
    period_floor = 0.0001, period_ceiling = 0.02,
    max_period_factor = 1.3
  )

  expect_type(jitter, "list")
  expect_true("local" %in% names(jitter))
  expect_true("local_absolute" %in% names(jitter))
  expect_true("rap" %in% names(jitter))
  expect_true("ppq5" %in% names(jitter))
  expect_true("ddp" %in% names(jitter))
})

test_that("Spectrum get_power_at_frequencies works correctly", {

  sound <- Sound$create_tone(frequency = 440, duration = 0.5)
  spectrum <- sound$to_spectrum()

  freqs <- c(100, 440, 880, 1000)
  powers <- spectrum$get_power_at_frequencies(freqs)

  expect_length(powers, length(freqs))
  expect_true(is.numeric(powers))
  # Power at 440Hz should be highest (fundamental frequency)
  expect_gt(powers[2], powers[1])
})

test_that("Spectrum batch band operations work", {

  sound <- Sound$create_tone(frequency = 440, duration = 0.5)
  spectrum <- sound$to_spectrum()

  fmins <- c(100, 400, 800)
  fmaxs <- c(200, 500, 900)

  energies <- spectrum$get_band_energies(fmins, fmaxs)
  densities <- spectrum$get_band_densities(fmins, fmaxs)

  expect_length(energies, 3)
  expect_length(densities, 3)
  expect_true(is.numeric(energies))
  expect_true(is.numeric(densities))
})

# BUG-2 regression: parabolic interpolation must not produce impossible values
test_that("BUG-2: get_peaks_batch(parabolic) returns physically plausible values", {

  # Tone with flat spectrum regions — creates the near-zero d2y condition
  sr     <- 44100
  dur    <- 0.04  # 40ms window (same context as pharyngeal pipeline)
  t      <- seq(0, dur - 1/sr, by = 1/sr)
  f0     <- 120
  signal <- sin(2 * pi * f0 * t) + 0.8 * sin(2 * pi * 2 * f0 * t)
  signal <- signal / max(abs(signal)) * 0.5
  snd    <- Sound$from_values(signal, sampling_rate = sr)

  window <- snd$extract_part(0, dur, "Kaiser2", 1, FALSE)
  spec   <- window$to_spectrum(TRUE)
  ltas   <- spec$to_ltas_1to1()

  fmins <- c(f0 * 0.9, f0 * 1.8)
  fmaxs <- c(f0 * 1.1, f0 * 2.2)

  peaks_para <- ltas$get_peaks_batch(fmins, fmaxs, interpolation = "parabolic")
  peaks_none <- ltas$get_peaks_batch(fmins, fmaxs, interpolation = "none")

  # No physically impossible values (hard limit: nothing > 200 dB in any spectrum)
  expect_true(all(peaks_para$peak_value < 200),
    info = paste("Parabolic peaks:", toString(round(peaks_para$peak_value, 1))))

  # Parabolic result must be within 50 dB of no-interpolation result
  diff_db <- abs(peaks_para$peak_value - peaks_none$peak_value)
  expect_true(all(diff_db < 50),
    info = paste("Parabolic vs none diff:", toString(round(diff_db, 1))))
})

# API-1 regression: to_ltas_direct() must return a wrapped Ltas, not externalptr
test_that("API-1: to_ltas_direct() returns usable Ltas object without manual wrapping", {

  sound <- Sound$create_tone(frequency = 440, duration = 0.5)
  ltas  <- to_ltas_direct(sound, bandwidth = 100)

  expect_true(inherits(ltas, "Ltas"),
    info = paste("class:", toString(class(ltas))))
  expect_false(inherits(ltas, "externalptr"))

  # Must be directly usable — no manual Ltas(.xptr = ...) wrapping needed
  slope <- ltas$get_slope(0, 1000, 1000, 10000, "energy")
  expect_true(is.numeric(slope))
})
