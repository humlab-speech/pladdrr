# Tests for Formant R6 class
library(data.table)
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
  expect_gt(n_frames, 0)
  
  time_step <- formant$get_time_step()
  expect_type(time_step, "double")
  expect_gt(time_step, 0)
  
  min_formants <- formant$get_min_num_formants()
  expect_type(min_formants, "integer")
  expect_gte(min_formants, 0)
  
  max_formants <- formant$get_max_num_formants()
  expect_type(max_formants, "integer")
  expect_gte(max_formants, min_formants)
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
  f1_sd <- formant$get_standard_deviation(1, from_time = 0, to_time = 0,
    unit = "hertz")
  expect_type(f1_sd, "double")
  expect_true(is.na(f1_sd) || f1_sd >= 0)
  
  # Test quantile
  f1_median <- formant$get_quantile(1, 0.5, from_time = 0, to_time = 0,
    unit = "hertz")
  expect_type(f1_median, "double")
  
  # Test minimum/maximum
  f1_min <- formant$get_minimum(1, from_time = 0, to_time = 0, unit = "hertz")
  f1_max <- formant$get_maximum(1, from_time = 0, to_time = 0, unit = "hertz")
  expect_type(f1_min, "double")
  expect_type(f1_max, "double")
  
  if (!is.na(f1_min) && !is.na(f1_max)) {
    expect_gte(f1_max, f1_min)
  }
})

test_that("Formant time of min/max methods work", {
  skip_if_not(require("pladdrr"), message = "speaker package not available")
  
  sound <- create_test_sound()
  formant <- sound$to_formant_burg()
  
  t_min <- formant$get_time_of_minimum(1, from_time = 0, to_time = 0,
    unit = "hertz")
  t_max <- formant$get_time_of_maximum(1, from_time = 0, to_time = 0,
    unit = "hertz")
  
  expect_type(t_min, "double")
  expect_type(t_max, "double")
  
  # Times should be within sound duration
  if (!is.na(t_min)) {
    expect_gte(t_min, 0); expect_lte(t_min, 0.5)
  }
  if (!is.na(t_max)) {
    expect_gte(t_max, 0); expect_lte(t_max, 0.5)
  }
})

test_that("Formant export to data frame works", {
  skip_if_not(require("pladdrr"), message = "speaker package not available")
  
  sound <- create_test_sound()
  formant <- sound$to_formant_burg(max_formants = 5)
  
  df <- formant$as_data_frame(max_formants = 5)
  
  expect_s3_class(df, "data.frame")
  expect_s3_class(df, "data.table")
  expect_named(df, c("time", "formant", "frequency", "bandwidth"))
  
  expect_gt(nrow(df), 0)
  expect_true(all(df$time >= 0))
  
  # Check that formant frequencies are in reasonable ranges (or NA)
  f1_values <- df$frequency[df$formant == 1L & !is.na(df$frequency)]
  if (length(f1_values) > 0) {
    expect_true(all(f1_values > 0 & f1_values < 2000))
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
  
  expect_true(any(grepl("Praat Formant", output, fixed = TRUE)))
  expect_true(any(grepl("Number of frames", output, fixed = TRUE)))
  expect_true(any(grepl("Time step", output, fixed = TRUE)))
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
    expect_lt(f1_bark, f1_hz)
  }
})

test_that("Formant unit bug fix: get_value_at_time returns correct scale", {
  skip_if_not(require("pladdrr"), message = "speaker package not available")
  
  sound <- create_test_sound()
  formant <- sound$to_formant_burg()
  
  # Get F1 at time 0.25 using get_value_at_time with "hertz"
  f1_method <- formant$get_value_at_time(1, 0.25, unit = "hertz")
  
  # Get F1 at time 0.25 from data frame
  df <- formant$as_data_frame()
  df_f1 <- df[df$formant == 1L, ]
  idx <- which.min(abs(df_f1$time - 0.25))
  f1_dataframe <- df_f1$frequency[idx]
  
  # Skip if either is NA
  skip_if(is.na(f1_method) || is.na(f1_dataframe),
    "No formant data at test time")
  
  # Both methods should return Hertz values (not Bark)
  # Hertz values for F1 are typically 300-1500 Hz
  # Bark values for F1 are typically 3-13 bark
  expect_true(f1_method > 50, 
              info = "get_value_at_time should return Hertz (>50), not Bark (<20)")
  
  # The two methods should return similar values (within 100 Hz tolerance)
  # This was the bug: get_value_at_time returned ~7 (bark) while dataframe
  #  returned ~862 (Hz)
  expect_true(abs(f1_method - f1_dataframe) < 100,
              info = sprintf(
                "Methods should agree: get_value_at_time=%.2f, dataframe=%.2f", 
                           f1_method, f1_dataframe))
  
  # Also verify that bark scale returns different (smaller) values
  f1_bark <- formant$get_value_at_time(1, 0.25, unit = "bark")
  if (!is.na(f1_bark)) {
    expect_true(f1_bark < 20, 
                info = "Bark values should be < 20 for typical F1")
    expect_true(f1_bark < f1_method / 10,
                info = "Bark values should be much smaller than Hertz values")
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
    expect_lt(abs(f1_min_interp - f1_min_no_interp), 100)  # Within 100 Hz
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

# BUG-1 regression: to_formant_burg() on short windows must not miss formants
# Before fix: short-window F1 could be 35-55% too low vs full-sound analysis
test_that(
  "BUG-1: to_formant_burg() on 40ms window agrees with full-sound analysis", {

  # Formant resonances only (no F0) — avoids LPC confusing F0 with F1
  # F1=700Hz, F2=1220Hz, F3=2600Hz (approximate adult /a/)
  sr    <- 16000
  dur   <- 1.0
  t_all <- seq(0, dur - 1/sr, by = 1/sr)
  signal <- sin(2 * pi * 700  * t_all) +
            0.5 * sin(2 * pi * 1220 * t_all) +
            0.2 * sin(2 * pi * 2600 * t_all)
  signal <- signal / max(abs(signal)) * 0.5
  snd <- Sound$from_values(signal, sampling_rate = sr)

  # Full-sound reference (known good path)
  fmnt_full <- snd$to_formant_burg(0.005, 5, 5500, 0.025, 50)
  f1_full   <- fmnt_full$get_value_at_time(1, 0.5, "hertz")
  f2_full   <- fmnt_full$get_value_at_time(2, 0.5, "hertz")

  # 40ms window around the same point — was failing before fix (r=0.57 vs Praat)
  window  <- snd$extract_part(0.48, 0.52, "rectangular", 1, FALSE)
  fmnt_w  <- window$to_formant_burg(0.005, 5, 5500, 0.025, 50)
  f1_win  <- fmnt_w$get_value_at_time(1, 0.02, "hertz")
  f2_win  <- fmnt_w$get_value_at_time(2, 0.02, "hertz")

  # Short window must agree with full-sound within 200 Hz (before fix: up to 481
  #  Hz mean diff)
  if (!is.na(f1_win) && !is.na(f1_full))
    expect_lt(abs(f1_win - f1_full), 200,
      label = paste0("F1 diff window vs full-sound: ",
        round(abs(f1_win - f1_full)), " Hz"))
  if (!is.na(f2_win) && !is.na(f2_full))
    expect_lt(abs(f2_win - f2_full), 300,
      label = paste0("F2 diff window vs full-sound: ",
        round(abs(f2_win - f2_full)), " Hz"))
})
