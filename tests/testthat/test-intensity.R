# Tests for Intensity extraction and analysis
#
# NOTE: These tests are for the DEPRECATED S3 API.
# The S3 API (extract_intensity, etc.) is deprecated in favor of R6.
# Tests are skipped. Use R6 API: sound$to_intensity(), intensity$get_value(), etc.

skip("S3 API deprecated - use R6 API instead (sound$to_intensity(), intensity$get_*())")

test_that("extract_intensity works with basic input", {
  # Create a simple sound
  sound <- generate_sine_wave(440, duration = 0.1, sampling_rate = 16000)
  
  # Extract intensity
  intensity <- extract_intensity(sound, minimum_pitch = 100)
  
  # Check structure
  expect_s3_class(intensity, "Intensity")
  expect_type(intensity, "list")
  expect_true("values" %in% names(intensity))
  expect_true("n_frames" %in% names(intensity))
  expect_true("minimum_pitch" %in% names(intensity))
  
  # Check values data.frame
  expect_s3_class(intensity$values, "data.frame")
  expect_s3_class(df, "data.table")
  expect_true("time" %in% names(intensity$values))
  expect_true("intensity_db" %in% names(intensity$values))
  
  # Check that we got some measurements
  expect_gt(nrow(intensity$values), 0)
  expect_gt(intensity$n_frames, 0)
})

test_that("extract_intensity parameter validation works", {
  sound <- generate_sine_wave(440, duration = 0.1, sampling_rate = 16000)
  
  # Invalid minimum_pitch
  expect_error(
    extract_intensity(sound, minimum_pitch = 0),
    "minimum_pitch.*positive"
  )
  
  expect_error(
    extract_intensity(sound, minimum_pitch = -50),
    "minimum_pitch.*positive"
  )
  
  # Invalid time_step
  expect_error(
    extract_intensity(sound, time_step = -0.01),
    "time_step.*non-negative"
  )
  
  # Invalid subtract_mean
  expect_error(
    extract_intensity(sound, subtract_mean = "yes"),
    "subtract_mean.*logical"
  )
  
  # Invalid sound object
  expect_error(
    extract_intensity(list(foo = "bar")),
    "must be a praat_sound"
  )
})

test_that("extract_intensity with subtract_mean works", {
  sound <- generate_sine_wave(440, duration = 0.2, sampling_rate = 16000)
  
  # With mean subtraction (default)
  intensity_relative <- extract_intensity(sound, minimum_pitch = 100, 
                                         subtract_mean = TRUE)
  
  # Without mean subtraction
  intensity_absolute <- extract_intensity(sound, minimum_pitch = 100, 
                                         subtract_mean = FALSE)
  
  expect_s3_class(intensity_relative, "Intensity")
  expect_s3_class(intensity_absolute, "Intensity")
  
  # Relative should have mean close to 0
  mean_relative <- mean(intensity_relative$values$intensity_db, na.rm = TRUE)
  expect_lt(abs(mean_relative), 1e-10)
  
  # Absolute should have mean > 0 (positive dB SPL)
  mean_absolute <- mean(intensity_absolute$values$intensity_db, na.rm = TRUE)
  expect_gt(mean_absolute, 0)
})

test_that("get_intensity_at_time works", {
  sound <- generate_sine_wave(440, duration = 0.2, sampling_rate = 16000)
  intensity <- extract_intensity(sound, minimum_pitch = 100)
  
  # Get intensity at middle of signal
  int_mid <- get_intensity_at_time(intensity, time = 0.1)
  
  # Should return a single numeric value
  expect_type(int_mid, "double")
  expect_length(int_mid, 1)
  
  # Get with interpolation
  int_interp <- get_intensity_at_time(intensity, time = 0.1, interpolate = TRUE)
  expect_type(int_interp, "double")
  expect_length(int_interp, 1)
  
  # At edges
  int_start <- get_intensity_at_time(intensity, time = 0.0, interpolate = TRUE)
  int_end <- get_intensity_at_time(intensity, time = 0.2, interpolate = TRUE)
  
  expect_type(int_start, "double")
  expect_type(int_end, "double")
})

test_that("get_intensity_at_time validation works", {
  sound <- generate_sine_wave(440, duration = 0.1, sampling_rate = 16000)
  intensity <- extract_intensity(sound, minimum_pitch = 100)
  
  # Invalid intensity object
  expect_error(
    get_intensity_at_time(list(foo = "bar"), time = 0.05),
    "must be a praat_intensity"
  )
})

test_that("get_mean_intensity works", {
  sound <- generate_sine_wave(440, duration = 0.2, sampling_rate = 16000)
  intensity <- extract_intensity(sound, minimum_pitch = 100, subtract_mean = TRUE)
  
  # Get mean (should be ~0 with subtract_mean = TRUE)
  mean_int <- get_mean_intensity(intensity)
  
  expect_type(mean_int, "double")
  expect_length(mean_int, 1)
  expect_lt(abs(mean_int), 1e-10)
  
  # With time range
  mean_int_range <- get_mean_intensity(intensity, time_range = c(0.05, 0.15))
  expect_type(mean_int_range, "double")
  expect_length(mean_int_range, 1)
})

test_that("get_min_intensity works", {
  sound <- generate_sine_wave(440, duration = 0.2, sampling_rate = 16000)
  intensity <- extract_intensity(sound, minimum_pitch = 100)
  
  min_int <- get_min_intensity(intensity)
  
  expect_type(min_int, "double")
  expect_length(min_int, 1)
  
  # With time range
  min_int_range <- get_min_intensity(intensity, time_range = c(0.05, 0.15))
  expect_type(min_int_range, "double")
  expect_length(min_int_range, 1)
})

test_that("get_max_intensity works", {
  sound <- generate_sine_wave(440, duration = 0.2, sampling_rate = 16000)
  intensity <- extract_intensity(sound, minimum_pitch = 100)
  
  max_int <- get_max_intensity(intensity)
  
  expect_type(max_int, "double")
  expect_length(max_int, 1)
  
  # With time range
  max_int_range <- get_max_intensity(intensity, time_range = c(0.05, 0.15))
  expect_type(max_int_range, "double")
  expect_length(max_int_range, 1)
})

test_that("get_sd_intensity works", {
  sound <- generate_sine_wave(440, duration = 0.2, sampling_rate = 16000)
  intensity <- extract_intensity(sound, minimum_pitch = 100)
  
  sd_int <- get_sd_intensity(intensity)
  
  expect_type(sd_int, "double")
  expect_length(sd_int, 1)
  expect_gte(sd_int, 0)  # SD should be non-negative
  
  # With time range
  sd_int_range <- get_sd_intensity(intensity, time_range = c(0.05, 0.15))
  expect_type(sd_int_range, "double")
  expect_length(sd_int_range, 1)
  expect_gte(sd_int_range, 0)
})

test_that("intensity statistics validation works", {
  sound <- generate_sine_wave(440, duration = 0.1, sampling_rate = 16000)
  intensity <- extract_intensity(sound, minimum_pitch = 100)
  
  # Invalid intensity object
  expect_error(
    get_mean_intensity(list(foo = "bar")),
    "must be a praat_intensity"
  )
  
  expect_error(
    get_min_intensity(list(foo = "bar")),
    "must be a praat_intensity"
  )
  
  expect_error(
    get_max_intensity(list(foo = "bar")),
    "must be a praat_intensity"
  )
  
  expect_error(
    get_sd_intensity(list(foo = "bar")),
    "must be a praat_intensity"
  )
})

test_that("intensity S3 methods work", {
  sound <- generate_sine_wave(440, duration = 0.1, sampling_rate = 16000)
  intensity <- extract_intensity(sound, minimum_pitch = 100)
  
  # print method
  expect_output(print(intensity), "Praat Intensity")
  expect_output(print(intensity), "Number of frames")
  
  # summary method
  expect_output(summary(intensity), "Intensity statistics")
  
  # as.data.frame method
  df <- as.data.frame(intensity)
  expect_s3_class(df, "data.frame")
  expect_s3_class(df, "data.table")
  expect_true("time" %in% names(df))
  expect_true("intensity_db" %in% names(df))
})

test_that("is_praat_intensity works", {
  sound <- generate_sine_wave(440, duration = 0.1, sampling_rate = 16000)
  intensity <- extract_intensity(sound, minimum_pitch = 100)
  
  expect_true(is_praat_intensity(intensity))
  expect_false(is_praat_intensity(sound))
  expect_false(is_praat_intensity(list(foo = "bar")))
  expect_false(is_praat_intensity(NULL))
})

test_that("intensity extraction handles edge cases", {
  # Very short sound
  sound_short <- generate_sine_wave(440, duration = 0.01, sampling_rate = 16000)
  intensity_short <- extract_intensity(sound_short, minimum_pitch = 100)
  
  expect_s3_class(intensity_short, "Intensity")
  expect_gt(nrow(intensity_short$values), 0)
  
  # Silent sound (all zeros)
  sound_silent <- create_sound(rep(0, 1600), sampling_rate = 16000)
  intensity_silent <- extract_intensity(sound_silent, minimum_pitch = 100)
  
  expect_s3_class(intensity_silent, "Intensity")
  # Should handle gracefully (may have NA or very low values)
})

test_that("intensity extraction with different minimum_pitch", {
  sound <- generate_sine_wave(440, duration = 0.2, sampling_rate = 16000)
  
  # Different minimum pitch values
  intensity_low <- extract_intensity(sound, minimum_pitch = 50)
  intensity_mid <- extract_intensity(sound, minimum_pitch = 100)
  intensity_high <- extract_intensity(sound, minimum_pitch = 200)
  
  expect_s3_class(intensity_low, "Intensity")
  expect_s3_class(intensity_mid, "Intensity")
  expect_s3_class(intensity_high, "Intensity")
  
  # Lower minimum_pitch means larger window, fewer frames
  expect_lt(intensity_low$n_frames, intensity_high$n_frames)
  
  # Check window lengths
  expect_gt(intensity_low$window_length, intensity_high$window_length)
})

test_that("intensity varies with amplitude", {
  # Create sounds with different amplitudes
  sound_quiet <- generate_sine_wave(440, duration = 0.1, 
                                   amplitude = 0.1, sampling_rate = 16000)
  sound_loud <- generate_sine_wave(440, duration = 0.1, 
                                  amplitude = 0.9, sampling_rate = 16000)
  
  intensity_quiet <- extract_intensity(sound_quiet, minimum_pitch = 100, 
                                      subtract_mean = FALSE)
  intensity_loud <- extract_intensity(sound_loud, minimum_pitch = 100, 
                                     subtract_mean = FALSE)
  
  mean_quiet <- get_mean_intensity(intensity_quiet)
  mean_loud <- get_mean_intensity(intensity_loud)
  
  # Louder sound should have higher intensity
  expect_gt(mean_loud, mean_quiet)
  
  # Difference should be roughly 20 * log10(0.9 / 0.1) ≈ 19 dB
  diff_db <- mean_loud - mean_quiet
  expect_gt(diff_db, 15)  # At least 15 dB difference
  expect_lt(diff_db, 25)  # At most 25 dB difference
})

test_that("intensity auto time_step works", {
  sound <- generate_sine_wave(440, duration = 0.2, sampling_rate = 16000)
  
  # With auto time step (0)
  intensity_auto <- extract_intensity(sound, minimum_pitch = 100, time_step = 0)
  
  # With manual time step
  intensity_manual <- extract_intensity(sound, minimum_pitch = 100, time_step = 0.01)
  
  expect_s3_class(intensity_auto, "Intensity")
  expect_s3_class(intensity_manual, "Intensity")
  
  # Auto should calculate time_step = 0.8 / minimum_pitch = 0.008
  expect_equal(intensity_auto$time_step, 0.8 / 100)
  expect_equal(intensity_manual$time_step, 0.01)
})
