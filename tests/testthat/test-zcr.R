# test-zcr.R - Tests for Zero Crossing Rate functionality

test_that("sound_get_zcr returns valid frame data", {
  # Generate test tone - sine wave has predictable ZCR
  sound <- Sound$create_tone(frequency = 440, duration = 0.5, sampling_rate = 16000)
  zcr_data <- sound_get_zcr(sound, window_duration = 0.03, hop_duration = 0.01)

  expect_true(is.list(zcr_data))
  expect_true("times" %in% names(zcr_data))
  expect_true("zcr" %in% names(zcr_data))
  expect_equal(length(zcr_data$times), length(zcr_data$zcr))

  # ZCR should be non-negative
  expect_true(all(zcr_data$zcr >= 0))
})

test_that("sound_get_zcr for sine wave matches expected frequency", {
  freq <- 440
  sound <- Sound$create_tone(frequency = freq, duration = 0.5, sampling_rate = 16000)
  zcr_data <- sound_get_zcr(sound, window_duration = 0.03, hop_duration = 0.01)

  # A pure sine wave at frequency F crosses zero 2*F times per second
  expected_zcr <- 2 * freq  # 880 for 440 Hz
  mean_zcr <- mean(zcr_data$zcr)

  # Allow 10% tolerance for windowing effects
  expect_true(abs(mean_zcr - expected_zcr) / expected_zcr < 0.1,
              label = sprintf("ZCR %.0f should be near %.0f", mean_zcr, expected_zcr))
})

test_that("sound_get_zcr handles short sounds", {
  # Very short sound
  sound <- Sound$create_tone(frequency = 440, duration = 0.01, sampling_rate = 16000)
  zcr_data <- sound_get_zcr(sound, window_duration = 0.03, hop_duration = 0.01)

  expect_true(is.list(zcr_data))
  expect_true(length(zcr_data$times) >= 1)
})

test_that("extract_voiced_segments with ZCR filtering works", {
  # Test that the function exists and has correct signature
  expect_true(is.function(extract_voiced_segments))
})

test_that("textgrid_get_intervals_where works", {
  test_wav <- system.file("extdata", "test.wav", package = "pladdrr")
  skip_if_not(file.exists(test_wav), "Test audio not available")

  sound <- Sound$new(test_wav)
  # Create a VAD textgrid from the sound
  vad_grid <- sound_to_textgrid_silences(sound)

  # Get intervals
  result <- textgrid_get_intervals_where(vad_grid, tier = 1, condition = "equals", text = "sounding")

  expect_true(is.list(result))
  expect_true("xmin" %in% names(result))
  expect_true("xmax" %in% names(result))
  expect_true("count" %in% names(result))
})
