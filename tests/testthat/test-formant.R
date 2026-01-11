# Tests for Formant extraction and analysis
#
# NOTE: These tests are for the DEPRECATED S3 API.
# The S3 API (extract_formants, etc.) is deprecated in favor of R6.
# Tests are skipped. Use R6 API: sound$to_formant_burg(), formant$get_value_at_time(), etc.

skip("S3 API deprecated - use R6 API instead (sound$to_formant_*(), formant$get_*())")

test_that("extract_formants works with basic input", {
  # Create a simple sound
  sound <- generate_sine_wave(440, duration = 0.1, sampling_rate = 16000)
  
  # Extract formants
  formants <- extract_formants(sound, max_formant = 5000, n_formants = 3)
  
  # Check structure
  expect_s3_class(formants, "Formant")
  expect_type(formants, "list")
  expect_true("values" %in% names(formants))
  expect_true("n_frames" %in% names(formants))
  expect_true("n_formants" %in% names(formants))
  
  # Check values data.frame
  expect_s3_class(formants$values, "data.frame")
  expect_s3_class(df, "data.table")
  expect_true("time" %in% names(formants$values))
  expect_true("formant_number" %in% names(formants$values))
  expect_true("frequency" %in% names(formants$values))
  expect_true("bandwidth" %in% names(formants$values))
  
  # Check n_formants matches
  expect_equal(formants$n_formants, 3)
  
  # Check that we got some measurements
  expect_gt(nrow(formants$values), 0)
})

test_that("extract_formants parameter validation works", {
  sound <- generate_sine_wave(440, duration = 0.1, sampling_rate = 16000)
  
  # Invalid max_formant
  expect_error(
    extract_formants(sound, max_formant = -100),
    "max_formant.*positive"
  )
  
  # Invalid n_formants
  expect_error(
    extract_formants(sound, n_formants = 0),
    "n_formants.*positive"
  )
  
  expect_error(
    extract_formants(sound, n_formants = 2.5),
    "n_formants.*integer"
  )
  
  # Invalid time_step
  expect_error(
    extract_formants(sound, time_step = -0.01),
    "time_step.*non-negative"
  )
  
  # Invalid window_length
  expect_error(
    extract_formants(sound, window_length = 0),
    "window_length.*positive"
  )
  
  # Invalid pre_emphasis_from
  expect_error(
    extract_formants(sound, pre_emphasis_from = -10),
    "pre_emphasis_from.*positive"
  )
  
  # Invalid sound object
  expect_error(
    extract_formants(list(foo = "bar")),
    "must be a praat_sound"
  )
})

test_that("get_formant_at_time works", {
  sound <- generate_sine_wave(440, duration = 0.2, sampling_rate = 16000)
  formants <- extract_formants(sound, max_formant = 5000, n_formants = 3)
  
  # Get F1 at middle of signal
  f1 <- get_formant_at_time(formants, formant_number = 1, time = 0.1)
  
  # Should return a single numeric value (or NA)
  expect_type(f1, "double")
  expect_length(f1, 1)
  
  # Get F2 with interpolation
  f2 <- get_formant_at_time(formants, formant_number = 2, time = 0.1, 
                           interpolate = TRUE)
  expect_type(f2, "double")
  expect_length(f2, 1)
})

test_that("get_formant_at_time validation works", {
  sound <- generate_sine_wave(440, duration = 0.1, sampling_rate = 16000)
  formants <- extract_formants(sound, max_formant = 5000, n_formants = 3)
  
  # Invalid formant object
  expect_error(
    get_formant_at_time(list(foo = "bar"), formant_number = 1, time = 0.05),
    "must be a praat_formant"
  )
  
  # Invalid formant_number
  expect_error(
    get_formant_at_time(formants, formant_number = 0, time = 0.05),
    "formant_number.*positive"
  )
  
  expect_error(
    get_formant_at_time(formants, formant_number = 1.5, time = 0.05),
    "formant_number.*integer"
  )
})

test_that("get_mean_formant works", {
  sound <- generate_sine_wave(440, duration = 0.2, sampling_rate = 16000)
  formants <- extract_formants(sound, max_formant = 5000, n_formants = 3)
  
  # Get mean F1
  mean_f1 <- get_mean_formant(formants, formant_number = 1)
  
  expect_type(mean_f1, "double")
  expect_length(mean_f1, 1)
  
  # With time range
  mean_f1_range <- get_mean_formant(formants, formant_number = 1, 
                                    time_range = c(0.05, 0.15))
  expect_type(mean_f1_range, "double")
  expect_length(mean_f1_range, 1)
})

test_that("get_mean_formant validation works", {
  sound <- generate_sine_wave(440, duration = 0.1, sampling_rate = 16000)
  formants <- extract_formants(sound, max_formant = 5000, n_formants = 3)
  
  # Invalid formant object
  expect_error(
    get_mean_formant(list(foo = "bar"), formant_number = 1),
    "must be a praat_formant"
  )
  
  # Invalid formant_number
  expect_error(
    get_mean_formant(formants, formant_number = -1),
    "formant_number.*positive"
  )
})

test_that("formant S3 methods work", {
  sound <- generate_sine_wave(440, duration = 0.1, sampling_rate = 16000)
  formants <- extract_formants(sound, max_formant = 5000, n_formants = 3)
  
  # print method
  expect_output(print(formants), "Praat Formant")
  expect_output(print(formants), "Number of frames")
  
  # summary method
  expect_output(summary(formants), "Formant F1")
  
  # as.data.frame method
  df <- as.data.frame(formants)
  expect_s3_class(df, "data.frame")
  expect_s3_class(df, "data.table")
  expect_true("time" %in% names(df))
  expect_true("frequency" %in% names(df))
})

test_that("is_praat_formant works", {
  sound <- generate_sine_wave(440, duration = 0.1, sampling_rate = 16000)
  formants <- extract_formants(sound, max_formant = 5000, n_formants = 3)
  
  expect_true(is_praat_formant(formants))
  expect_false(is_praat_formant(sound))
  expect_false(is_praat_formant(list(foo = "bar")))
  expect_false(is_praat_formant(NULL))
})

test_that("formant extraction handles edge cases", {
  # Very short sound
  sound_short <- generate_sine_wave(440, duration = 0.01, sampling_rate = 16000)
  formants_short <- extract_formants(sound_short, max_formant = 5000, n_formants = 2)
  
  expect_s3_class(formants_short, "Formant")
  expect_gt(nrow(formants_short$values), 0)
  
  # Silent sound (all zeros)
  sound_silent <- create_sound(rep(0, 1600), sampling_rate = 16000)
  formants_silent <- extract_formants(sound_silent, max_formant = 5000, n_formants = 2)
  
  expect_s3_class(formants_silent, "Formant")
  # Should handle gracefully (may have all NA values)
})

test_that("formant extraction with different parameters", {
  sound <- generate_sine_wave(440, duration = 0.2, sampling_rate = 16000)
  
  # Different max_formant
  formants_male <- extract_formants(sound, max_formant = 5000, n_formants = 5)
  formants_female <- extract_formants(sound, max_formant = 5500, n_formants = 5)
  formants_child <- extract_formants(sound, max_formant = 8000, n_formants = 5)
  
  expect_s3_class(formants_male, "Formant")
  expect_s3_class(formants_female, "Formant")
  expect_s3_class(formants_child, "Formant")
  
  expect_equal(formants_male$max_formant, 5000)
  expect_equal(formants_female$max_formant, 5500)
  expect_equal(formants_child$max_formant, 8000)
  
  # Different n_formants
  formants_3 <- extract_formants(sound, max_formant = 5000, n_formants = 3)
  formants_5 <- extract_formants(sound, max_formant = 5000, n_formants = 5)
  
  expect_equal(formants_3$n_formants, 3)
  expect_equal(formants_5$n_formants, 5)
  
  # Should have different number of measurements per frame
  unique_formant_numbers_3 <- unique(formants_3$values$formant_number)
  unique_formant_numbers_5 <- unique(formants_5$values$formant_number)
  
  expect_lte(max(unique_formant_numbers_3), 3)
  expect_lte(max(unique_formant_numbers_5), 5)
})
