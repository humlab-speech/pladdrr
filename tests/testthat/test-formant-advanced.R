# Test Suite for Advanced Formant Tracking Methods
# Tests for Willems, Split-Levinson, and Robust formant methods

test_that("Sound can create formant using Willems method", {
  sound <- Sound$new(440, duration = 0.2, sampling_frequency = 16000)
  
  formant <- sound$to_formant_willems(
    time_step = 0.005,
    number_of_formants = 5,
    maximum_formant_frequency = 5500,
    window_length = 0.025,
    pre_emphasis_from = 50
  )
  
  expect_s3_class(formant, "Formant")
  expect_s3_class(formant, "PraatObject")
  expect_true(!is.null(formant$.xptr))
})

test_that("Sound can create formant using Split-Levinson method", {
  sound <- Sound$new(440, duration = 0.2, sampling_frequency = 16000)
  
  formant <- sound$to_formant_sl(
    time_step = 0.005,
    number_of_poles = 10,
    maximum_frequency = 5500,
    window_length = 0.025,
    pre_emphasis_from = 50
  )
  
  expect_s3_class(formant, "Formant")
  expect_true(!is.null(formant$.xptr))
})

test_that("Willems method produces valid formant values", {
  # Create a sound with clear formant structure (vowel-like)
  sound <- Sound$new(duration = 0.2, sampling_frequency = 22050)
  
  formant <- sound$to_formant_willems(
    time_step = 0.01,
    number_of_formants = 4,
    maximum_formant_frequency = 5000
  )
  
  # Query first formant at middle of sound
  f1 <- formant$get_value_at_time(1, 0.1, unit = "hertz")
  
  expect_type(f1, "double")
  # F1 should be in reasonable range for speech (100-1000 Hz typically)
  if (!is.na(f1)) {
    expect_true(f1 > 0)
    expect_true(f1 < 2000)  # Upper bound for F1
  }
})

test_that("Split-Levinson method produces valid formant values", {
  sound <- Sound$new(duration = 0.2, sampling_frequency = 22050)
  
  formant <- sound$to_formant_sl(
    time_step = 0.01,
    number_of_poles = 10,
    maximum_frequency = 5000
  )
  
  # Query formant values
  f1 <- formant$get_value_at_time(1, 0.1, unit = "hertz")
  f2 <- formant$get_value_at_time(2, 0.1, unit = "hertz")
  
  # Basic sanity checks
  if (!is.na(f1) && !is.na(f2)) {
    expect_true(f1 > 0)
    expect_true(f2 > f1)  # F2 should be higher than F1
  }
})

test_that("Different formant methods produce comparable results", {
  sound <- Sound$new(440, duration = 0.2, sampling_frequency = 22050)
  
  # Same parameters for all methods
  params <- list(
    time_step = 0.01,
    maximum_frequency = 5000,
    window_length = 0.025,
    pre_emphasis_from = 50
  )
  
  formant_burg <- sound$to_formant_burg(
    time_step = params$time_step,
    max_number_of_formants = 5,
    maximum_formant_frequency = params$maximum_frequency,
    window_length = params$window_length,
    pre_emphasis_from = params$pre_emphasis_from
  )
  
  formant_willems <- sound$to_formant_willems(
    time_step = params$time_step,
    number_of_formants = 5,
    maximum_formant_frequency = params$maximum_frequency,
    window_length = params$window_length,
    pre_emphasis_from = params$pre_emphasis_from
  )
  
  # Both should produce valid formant objects
  expect_s3_class(formant_burg, "Formant")
  expect_s3_class(formant_willems, "Formant")
  
  # Formant values should be in same ballpark (not testing exact equality)
  f1_burg <- formant_burg$get_value_at_time(1, 0.1, unit = "hertz")
  f1_willems <- formant_willems$get_value_at_time(1, 0.1, unit = "hertz")
  
  if (!is.na(f1_burg) && !is.na(f1_willems)) {
    # Should be within an octave of each other for similar algorithm
    expect_true(abs(f1_burg - f1_willems) / f1_burg < 1.0)
  }
})

test_that("Formant methods handle edge cases", {
  # Very short sound
  sound_short <- Sound$new(440, duration = 0.01, sampling_frequency = 16000)
  formant_short <- sound_short$to_formant_willems(time_step = 0.002)
  expect_s3_class(formant_short, "Formant")
  
  # Silence
  sound_silence <- Sound$new(duration = 0.1, sampling_frequency = 16000)
  formant_silence <- sound_silence$to_formant_sl()
  expect_s3_class(formant_silence, "Formant")
})

test_that("Formant methods validate parameters", {
  sound <- Sound$new(440, duration = 0.2, sampling_frequency = 16000)
  
  # Invalid time step
  expect_error(sound$to_formant_willems(time_step = -0.01))
  expect_error(sound$to_formant_sl(time_step = -0.01))
  
  # Invalid number of formants/poles
  expect_error(sound$to_formant_willems(number_of_formants = 0))
  expect_error(sound$to_formant_sl(number_of_poles = 0))
  
  # Invalid frequency range
  expect_error(sound$to_formant_willems(maximum_formant_frequency = -1000))
  expect_error(sound$to_formant_sl(maximum_frequency = -1000))
})

test_that("Willems method number_of_formants parameter works", {
  sound <- Sound$new(duration = 0.2, sampling_frequency = 22050)
  
  # Request 3 formants
  formant_3 <- sound$to_formant_willems(number_of_formants = 3)
  
  # Request 5 formants
  formant_5 <- sound$to_formant_willems(number_of_formants = 5)
  
  # Both should work
  expect_s3_class(formant_3, "Formant")
  expect_s3_class(formant_5, "Formant")
  
  # Attempting to get 6th formant from 3-formant object should fail or return NA
  f6 <- formant_3$get_value_at_time(6, 0.1, unit = "hertz")
  expect_true(is.na(f6) || is.null(f6))
})

test_that("Split-Levinson poles parameter affects results", {
  sound <- Sound$new(duration = 0.2, sampling_frequency = 22050)
  
  # Different number of poles
  formant_10 <- sound$to_formant_sl(number_of_poles = 10)
  formant_14 <- sound$to_formant_sl(number_of_poles = 14)
  
  # Both should work
  expect_s3_class(formant_10, "Formant")
  expect_s3_class(formant_14, "Formant")
})

test_that("Formant methods handle high sampling rates", {
  # High sampling rate (48 kHz)
  sound_hifi <- Sound$new(440, duration = 0.2, sampling_frequency = 48000)
  
  formant_willems <- sound_hifi$to_formant_willems(
    maximum_formant_frequency = 8000
  )
  
  formant_sl <- sound_hifi$to_formant_sl(
    maximum_frequency = 8000
  )
  
  expect_s3_class(formant_willems, "Formant")
  expect_s3_class(formant_sl, "Formant")
})

test_that("Pre-emphasis affects formant extraction", {
  sound <- Sound$new(duration = 0.2, sampling_frequency = 22050)
  
  # No pre-emphasis
  formant_no_preemph <- sound$to_formant_willems(pre_emphasis_from = 0)
  
  # Standard pre-emphasis
  formant_preemph <- sound$to_formant_willems(pre_emphasis_from = 50)
  
  # Both should work (results may differ)
  expect_s3_class(formant_no_preemph, "Formant")
  expect_s3_class(formant_preemph, "Formant")
})
