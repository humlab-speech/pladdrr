# test-sound-extract-part-windows.R
# Tests for Sound$extract_part() window shape support

test_that("extract_part accepts all window shape names", {
  # Create a simple tone
  sound <- Sound$create_tone(frequency = 440, duration = 1.0, sampling_rate = 16000)
  
  # All window shapes should work without error
  window_shapes <- c(
    "rectangular", "triangular", "parabolic",
    "hanning", "hamming",
    "gaussian1", "gaussian2", "gaussian3", "gaussian4", "gaussian5",
    "kaiser1", "kaiser2"
  )
  
  for (shape in window_shapes) {
    expect_no_error(sound$extract_part(0.2, 0.8, window_shape = shape))
  }
})

test_that("extract_part with gaussian2 and relative_width=2.0 works", {
  sound <- Sound$create_tone(frequency = 440, duration = 1.0, sampling_rate = 16000)
  
  # Gaussian2 with relative_width=2.0 (common for spectral analysis)
  expect_no_error(
    part <- sound$extract_part(0.3, 0.7, window_shape = "gaussian2", relative_width = 2.0)
  )
  
  # Should return a valid Sound object
  expect_s3_class(part, "Sound")
})

test_that("extract_part with kaiser2 and relative_width=2.0 works", {
  sound <- Sound$create_tone(frequency = 440, duration = 1.0, sampling_rate = 16000)
  
  # Kaiser2 with relative_width=2.0 (used in Praat's accurate pitch tracking)
  expect_no_error(
    part <- sound$extract_part(0.3, 0.7, window_shape = "kaiser2", relative_width = 2.0)
  )
  
  # Should return a valid Sound object
  expect_s3_class(part, "Sound")
})

test_that("extract_part with window applies tapering", {
  sound <- Sound$create_tone(frequency = 440, duration = 1.0, sampling_rate = 16000)
  
  # Extract with rectangular (no taper)
  rect <- sound$extract_part(0.2, 0.8, window_shape = "rectangular")
  
  # Extract with hanning (with taper)
  hann <- sound$extract_part(0.2, 0.8, window_shape = "hanning")
  
  # Both should have same duration
  expect_equal(rect$get_duration(), hann$get_duration(), tolerance = 1e-6)
  
  # But different RMS due to tapering
  rect_rms <- rect$get_rms(0, rect$get_duration())
  hann_rms <- hann$get_rms(0, hann$get_duration())
  
  # Hanning window should reduce RMS
  expect_lt(hann_rms, rect_rms)
})

test_that("extract_part preserve_times parameter works", {
  sound <- Sound$create_tone(frequency = 440, duration = 1.0, sampling_rate = 16000)
  
  # Without preserve_times (default: FALSE)
  part_shifted <- sound$extract_part(0.3, 0.7, preserve_times = FALSE)
  expect_equal(part_shifted$get_start_time(), 0.0, tolerance = 1e-6)
  
  # With preserve_times (TRUE)
  part_preserved <- sound$extract_part(0.3, 0.7, preserve_times = TRUE)
  expect_equal(part_preserved$get_start_time(), 0.3, tolerance = 1e-6)
  expect_equal(part_preserved$get_end_time(), 0.7, tolerance = 1e-6)
})

test_that("extract_parts_batch works with window shapes", {
  sound <- Sound$create_tone(frequency = 440, duration = 1.0, sampling_rate = 16000)
  
  start_times <- c(0.1, 0.3, 0.5)
  end_times <- c(0.2, 0.4, 0.6)
  
  # Should work with gaussian1
  expect_no_error(
    parts <- sound$extract_parts_batch(start_times, end_times, window_shape = "gaussian1")
  )
  
  expect_length(parts, 3)
  expect_true(all(sapply(parts, function(p) inherits(p, "Sound"))))
})

test_that("sound_extract_parts function works with window shapes", {
  sound <- Sound$create_tone(frequency = 440, duration = 1.0, sampling_rate = 16000)
  
  start_times <- c(0.1, 0.3, 0.5)
  end_times <- c(0.2, 0.4, 0.6)
  
  # Should work with kaiser2 and relative_width=2.0
  expect_no_error(
    parts <- sound_extract_parts(
      sound, start_times, end_times,
      window_shape = "kaiser2",
      relative_width = 2.0
    )
  )
  
  expect_length(parts, 3)
  expect_true(all(sapply(parts, function(p) inherits(p, "Sound"))))
})
