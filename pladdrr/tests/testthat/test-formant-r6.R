# Tests for Formant R6 class
library(testthat)
library(pladdrr)

# Helper function to create a test sound
create_test_sound <- function() {
  # Create a simple vowel-like sound for testing
  duration <- 0.5
  sr <- 16000
  n_samples <- duration * sr
  t <- seq(0, duration, length.out = n_samples)
  
  # Simulate vowel with formants
  # F1 = 700 Hz, F2 = 1220 Hz, F3 = 2600 Hz (approximates /a/)
  f0 <- 120  # fundamental frequency
  signal <- sin(2 * pi * f0 * t)
  
  # Add formant resonances (simplified)
  signal <- signal + 0.5 * sin(2 * pi * 700 * t)  # F1
  signal <- signal + 0.3 * sin(2 * pi * 1220 * t)  # F2
  signal <- signal + 0.2 * sin(2 * pi * 2600 * t)  # F3
  
  # Normalize
  signal <- signal / max(abs(signal)) * 0.5
  
  # Create Sound object
  Sound$from_values(signal, sampling_rate = sr)
}

test_that("Formant object creation from Sound works", {
  skip_if_not(require("pladdrr"), message = "speaker package not available")
  
  sound <- create_test_sound()
  
  # Test to_formant_burg
  formant <- sound$to_formant_burg(
    time_step = 0.01,
    max_formants = 5,
    max_frequency = 5500,
    window_length = 0.025,
    pre_emphasis_from = 50
  )
  
  expect_s3_class(formant, "Formant")
  expect_s3_class(formant, "PraatObject")
  expect_s3_class(formant, "R6")
})

test_that("Formant object creation via to_formant_keepall works", {
  skip_if_not(require("pladdrr"), message = "speaker package not available")
  
  sound <- create_test_sound()
  
  formant <- sound$to_formant_keepall(
    time_step = 0.01,
    max_formants = 5,
    max_frequency = 5500
  )
  
  expect_s3_class(formant, "Formant")
  expect_s3_class(formant, "PraatObject")
})

test_that("Formant query methods return valid values", {
  skip_if_not(require("pladdrr"), message = "speaker package not available")
  
  sound <- create_test_sound()
  formant <- sound$to_formant_burg()
  
  # Test time domain queries
  n_frames <- formant$get_number_of_frames()
  expect_type(n_frames, "integer")
  expect_true(n_frames > 0)
  
  time_step <- formant$get_time_step()
  expect_type(time_step, "double")
  expect_true(time_step > 0)
  
  min_formants <- formant$get_min_num_formants()
  expect_type(min_formants, "integer")
  expect_true(min_formants >= 0)
  
  max_formants <- formant$get_max_num_formants()
  expect_type(max_formants, "integer")
  expect_true(max_formants >= min_formants)
})

test_that("Formant value queries work", {
  skip_if_not(require("pladdrr"), message = "speaker package not available")
  
  sound <- create_test_sound()
  formant <- sound$to_formant_burg(max_frequency = 5500)
  
  # Get F1 at middle of sound
  f1 <- formant$get_value_at_time(1, 0.25, unit = "hertz")
  expect_type(f1, "double")
  # F1 for /a/ should be around 700 Hz (allow wide range due to synthesis)
  expect_true(is.na(f1) || (f1 > 300 && f1 < 1500))
  
  # Get F2 at middle of sound
  f2 <- formant$get_value_at_time(2, 0.25, unit = "hertz")
  expect_type(f2, "double")
  expect_true(is.na(f2) || (f2 > f1 || is.na(f1)))  # F2 should be higher than F1
  
  # Get bandwidth
  b1 <- formant$get_bandwidth_at_time(1, 0.25, unit = "hertz")
  expect_type(b1, "double")
})

test_that("Formant statistics methods work", {
  skip_if_not(require("pladdrr"), message = "speaker package not available")
  
  sound <- create_test_sound()
  formant <- sound$to_formant_burg()
  
  # Test mean
  f1_mean <- formant$get_mean(1, from_time = 0, to_time = 0, unit = "hertz")
  expect_type(f1_mean, "double")
  expect_true(is.na(f1_mean) || f1_mean > 0)
  
  # Test standard deviation
  f1_sd <- formant$get_standard_deviation(1, from_time = 0, to_time = 0, unit = "hertz")
  expect_type(f1_sd, "double")
  expect_true(is.na(f1_sd) || f1_sd >= 0)
  
  # Test quantile
  f1_median <- formant$get_quantile(1, 0.5, from_time = 0, to_time = 0, unit = "hertz")
  expect_type(f1_median, "double")
  
  # Test minimum/maximum
  f1_min <- formant$get_minimum(1, from_time = 0, to_time = 0, unit = "hertz")
  f1_max <- formant$get_maximum(1, from_time = 0, to_time = 0, unit = "hertz")
  expect_type(f1_min, "double")
  expect_type(f1_max, "double")
  
  if (!is.na(f1_min) && !is.na(f1_max)) {
    expect_true(f1_max >= f1_min)
  }
})

test_that("Formant time of min/max methods work", {
  skip_if_not(require("pladdrr"), message = "speaker package not available")
  
  sound <- create_test_sound()
  formant <- sound$to_formant_burg()
  
  t_min <- formant$get_time_of_minimum(1, from_time = 0, to_time = 0, unit = "hertz")
  t_max <- formant$get_time_of_maximum(1, from_time = 0, to_time = 0, unit = "hertz")
  
  expect_type(t_min, "double")
  expect_type(t_max, "double")
  
  # Times should be within sound duration
  if (!is.na(t_min)) {
    expect_true(t_min >= 0 && t_min <= 0.5)
  }
  if (!is.na(t_max)) {
    expect_true(t_max >= 0 && t_max <= 0.5)
  }
})

test_that("Formant export to data frame works", {
  skip_if_not(require("pladdrr"), message = "speaker package not available")
  
  sound <- create_test_sound()
  formant <- sound$to_formant_burg(max_formants = 5)
  
  df <- formant$as_data_frame(max_formants = 5)
  
  expect_s3_class(df, "data.frame")
  expect_true("time" %in% names(df))
  expect_true("F1" %in% names(df))
  expect_true("F2" %in% names(df))
  expect_true("B1" %in% names(df))  # Bandwidth
  expect_true("B2" %in% names(df))
  
  expect_true(nrow(df) > 0)
  expect_true(all(df$time >= 0))
  
  # Check that formant frequencies are in reasonable ranges (or NA)
  f1_values <- df$F1[!is.na(df$F1)]
  if (length(f1_values) > 0) {
    expect_true(all(f1_values > 0 && f1_values < 2000))
  }
})

test_that("Formant save method works", {
  skip_if_not(require("pladdrr"), message = "speaker package not available")
  
  sound <- create_test_sound()
  formant <- sound$to_formant_burg()
  
  temp_file <- tempfile(fileext = ".Formant")
  
  # Test save
  result <- formant$save(temp_file)
  expect_true(file.exists(temp_file))
  expect_identical(result, formant)  # Should return self for chaining
  
  # Clean up
  unlink(temp_file)
})

test_that("Formant print method works", {
  skip_if_not(require("pladdrr"), message = "speaker package not available")
  
  sound <- create_test_sound()
  formant <- sound$to_formant_burg()
  
  # Capture print output
  output <- capture.output(formant$print())
  
  expect_true(any(grepl("Praat Formant", output)))
  expect_true(any(grepl("Number of frames", output)))
  expect_true(any(grepl("Time step", output)))
})

test_that("Formant unit parameter works (hertz vs bark)", {
  skip_if_not(require("pladdrr"), message = "speaker package not available")
  
  sound <- create_test_sound()
  formant <- sound$to_formant_burg()
  
  # Get value in hertz
  f1_hz <- formant$get_value_at_time(1, 0.25, unit = "hertz")
  
  # Get value in bark
  f1_bark <- formant$get_value_at_time(1, 0.25, unit = "bark")
  
  # Both should be numeric
  expect_type(f1_hz, "double")
  expect_type(f1_bark, "double")
  
  # Bark values should be different from Hz (unless both NA)
  if (!is.na(f1_hz) && !is.na(f1_bark)) {
    expect_true(f1_hz != f1_bark)
    # Bark should be smaller than Hz for typical formant frequencies
    expect_true(f1_bark < f1_hz)
  }
})

test_that("Formant works with different max_formants settings", {
  skip_if_not(require("pladdrr"), message = "speaker package not available")
  
  sound <- create_test_sound()
  
  # Test with 3 formants
  formant3 <- sound$to_formant_burg(max_formants = 3)
  expect_s3_class(formant3, "Formant")
  
  # Test with 7 formants
  formant7 <- sound$to_formant_burg(max_formants = 7)
  expect_s3_class(formant7, "Formant")
  
  # More formants should potentially give higher max_num_formants
  max3 <- formant3$get_max_num_formants()
  max7 <- formant7$get_max_num_formants()
  
  expect_type(max3, "integer")
  expect_type(max7, "integer")
})

test_that("Formant interpolation parameter works", {
  skip_if_not(require("pladdrr"), message = "speaker package not available")
  
  sound <- create_test_sound()
  formant <- sound$to_formant_burg()
  
  # Get minimum with and without interpolation
  f1_min_no_interp <- formant$get_minimum(1, interpolate = FALSE)
  f1_min_interp <- formant$get_minimum(1, interpolate = TRUE)
  
  expect_type(f1_min_no_interp, "double")
  expect_type(f1_min_interp, "double")
  
  # Both should be valid (or both NA)
  if (!is.na(f1_min_no_interp) && !is.na(f1_min_interp)) {
    # Interpolated might be slightly different
    expect_true(abs(f1_min_interp - f1_min_no_interp) < 100)  # Within 100 Hz
  }
})

test_that("Deprecated S3 functions still work with warnings", {
  skip_if_not(require("pladdrr"), message = "speaker package not available")
  
  # Create old-style sound object (if still supported)
  # This test may need adjustment based on actual S3 support
  # For now, just test that the functions exist and are documented as deprecated
  
  # Check that deprecated functions exist
  expect_true(exists("extract_formants"))
  expect_true(exists("get_formant_at_time"))
  expect_true(exists("get_mean_formant"))
})
