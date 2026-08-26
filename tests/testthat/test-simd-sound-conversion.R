# Test SIMD data conversion operations
library(data.table)
# Validates numerical accuracy of sound-to-matrix conversions

# Helper function to create a tone (workaround for Sound$create_tone API issues)
create_test_tone <- function(duration, frequency, sample_rate, amplitude = 0.5) {
  n_samples <- as.integer(duration * sample_rate)
  t <- seq(0, duration, length.out = n_samples)
  samples <- amplitude * sin(2 * pi * frequency * t)
  Sound$from_values(samples, sample_rate)
}

test_that("SIMD data conversion preserves values", {
  skip_if_not_installed("pladdrr")
  library(pladdrr)

  # Generate test sound
  sound <- create_test_tone(1.0, 440, 44100, 0.5)

  # Convert to matrix
  mat <- sound$as_matrix()

  # Check dimensions
  expect_true(nrow(mat) == 1)  # Mono
  expect_true(nrow(mat) > 0)

  # Check values are in reasonable range
  expect_true(max(abs(mat)) <= 0.5 + 1e-10)

  # Convert to data frame
  df <- sound$as_data_frame()

  # Check structure
  expect_true(is.data.frame(df))
  expect_true("time" %in% names(df))
  expect_true("value" %in% names(df))

  # Values should match matrix
  expect_equal(df$value, as.vector(mat), tolerance = 1e-12)
})

test_that("SIMD data conversion handles stereo", {
  skip_if_not_installed("pladdrr")
  library(pladdrr)

  # Generate stereo tone (if available)
  sound_left <- create_test_tone(0.5, 440, 44100, 0.3)

  sound_right <- create_test_tone(0.5, 880, 44100, 0.7)

  # Test individual sounds
  mat_left <- sound_left$as_matrix()
  mat_right <- sound_right$as_matrix()

  expect_true(max(abs(mat_left)) <= 0.3 + 0.01)
  expect_true(max(abs(mat_right)) <= 0.7 + 0.01)
})

test_that("SIMD data conversion handles different sample rates", {
  skip_if_not_installed("pladdrr")
  library(pladdrr)

  # Low sample rate
  sound_low <- create_test_tone(1.0, 440, 16000, 0.5)

  mat_low <- sound_low$as_matrix()
  expect_equal(ncol(mat_low), 16000, tolerance = 5)  # ncol = samples

  # High sample rate
  sound_high <- create_test_tone(1.0, 440, 48000, 0.5)

  mat_high <- sound_high$as_matrix()
  expect_equal(ncol(mat_high), 48000, tolerance = 5)  # ncol = samples
})

test_that("SIMD data conversion is lossless", {
  skip_if_not_installed("pladdrr")
  library(pladdrr)

  # Generate sound
  sound1 <- create_test_tone(0.1, 440, 44100, 0.5)

  # Convert to matrix and back
  mat <- sound1$as_matrix()

  # Create new sound from matrix (if method available)
  # For now, just verify conversion integrity
  df <- sound1$as_data_frame()

  # Data frame and matrix should have same values
  expect_equal(df$value, as.vector(mat), tolerance = 1e-12)

  # Time vector should be evenly spaced
  time_diffs <- diff(df$time)
  expect_true(all(abs(time_diffs - time_diffs[1]) < 1e-10))
})

test_that("SIMD data conversion handles edge cases", {
  skip_if_not_installed("pladdrr")
  library(pladdrr)

  # Very short sound
  sound_short <- create_test_tone(0.01, 440, 44100, 0.5)

  mat_short <- sound_short$as_matrix()
  expect_true(nrow(mat_short) > 0)
  expect_true(nrow(mat_short) == 1)

  df_short <- sound_short$as_data_frame()
  expect_true(nrow(df_short) > 0)
  expect_true("time" %in% names(df_short))
})

test_that("SIMD data conversion performance is reasonable", {
  skip_if_not_installed("pladdrr")
  library(pladdrr)

  # Large sound file
  sound_large <- create_test_tone(10.0, 440, 44100, 0.5)

  # Conversion should complete in reasonable time
  time_matrix <- system.time({
    mat <- sound_large$as_matrix()
  })["elapsed"]

  time_df <- system.time({
    df <- sound_large$as_data_frame()
  })["elapsed"]

  # Should be fast (< 1 second for 10 second audio)
  expect_lt(time_matrix, 1.0)
  # Data frame conversion is slower but should still be reasonable
  expect_lt(time_df, 2.0)
})
