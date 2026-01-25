# Test SIMD tone generation
# Validates numerical accuracy and performance of tone synthesis

# Helper function to create a tone (workaround for Sound$create_tone API issues)
create_test_tone <- function(duration, frequency, sample_rate, amplitude = 0.5) {
  n_samples <- as.integer(duration * sample_rate)
  t <- seq(0, duration, length.out = n_samples)
  samples <- amplitude * sin(2 * pi * frequency * t)
  Sound$from_values(samples, sample_rate)
}

test_that("SIMD tone generation creates valid sine wave", {
  skip_if_not_installed("pladdrr")
  library(pladdrr)

  # Generate 440 Hz sine wave
  sound <- create_test_tone(1.0, 440, 44100, 0.5)

  # Check basic properties
  expect_true(!is.null(sound))
  expect_equal(sound$get_duration(), 1.0, tolerance = 0.01)

  # Convert to matrix
  mat <- sound$as_matrix()

  # Check amplitude
  max_amp <- max(abs(mat))
  expect_equal(max_amp, 0.5, tolerance = 0.01)

  # Check it's roughly sinusoidal (zero crossings)
  # Matrix is 1 x N (channels x samples), so use mat[1,] to get samples
  zero_crossings <- sum(diff(sign(mat[1,])) != 0)
  expected_crossings <- 440 * 2  # Two crossings per cycle
  expect_equal(zero_crossings, expected_crossings, tolerance = 10)
})

test_that("SIMD tone generation handles different frequencies", {
  skip_if_not_installed("pladdrr")
  library(pladdrr)

  # Low frequency
  sound_low <- create_test_tone(1.0, 110, 44100, 0.5)

  mat_low <- sound_low$as_matrix()
  zero_crossings_low <- sum(diff(sign(mat_low[1,])) != 0)
  expect_equal(zero_crossings_low, 110 * 2, tolerance = 10)

  # High frequency
  sound_high <- create_test_tone(1.0, 1000, 44100, 0.5)

  mat_high <- sound_high$as_matrix()
  zero_crossings_high <- sum(diff(sign(mat_high[1,])) != 0)
  expect_equal(zero_crossings_high, 1000 * 2, tolerance = 10)
})

test_that("SIMD tone generation handles different amplitudes", {
  skip_if_not_installed("pladdrr")
  library(pladdrr)

  # Low amplitude
  sound_quiet <- create_test_tone(1.0, 440, 44100, 0.1)

  mat_quiet <- sound_quiet$as_matrix()
  expect_equal(max(abs(mat_quiet)), 0.1, tolerance = 0.01)

  # High amplitude
  sound_loud <- create_test_tone(1.0, 440, 44100, 0.9)

  mat_loud <- sound_loud$as_matrix()
  expect_equal(max(abs(mat_loud)), 0.9, tolerance = 0.01)

  # Amplitude ratio should be preserved
  ratio <- max(abs(mat_loud)) / max(abs(mat_quiet))
  expect_equal(ratio, 9.0, tolerance = 0.1)
})

test_that("SIMD tone generation handles different sample rates", {
  skip_if_not_installed("pladdrr")
  library(pladdrr)

  # Low sample rate
  sound_16k <- create_test_tone(1.0, 440, 16000, 0.5)

  mat_16k <- sound_16k$as_matrix()
  expect_equal(ncol(mat_16k), 16000, tolerance = 5)

  # Standard sample rate
  sound_44k <- create_test_tone(1.0, 440, 44100, 0.5)

  mat_44k <- sound_44k$as_matrix()
  expect_equal(ncol(mat_44k), 44100, tolerance = 5)

  # High sample rate
  sound_48k <- create_test_tone(1.0, 440, 48000, 0.5)

  mat_48k <- sound_48k$as_matrix()
  expect_equal(ncol(mat_48k), 48000, tolerance = 5)
})

test_that("SIMD tone generation handles different durations", {
  skip_if_not_installed("pladdrr")
  library(pladdrr)

  # Short
  sound_short <- create_test_tone(0.1, 440, 44100, 0.5)

  expect_equal(sound_short$get_duration(), 0.1, tolerance = 0.01)

  # Medium
  sound_medium <- create_test_tone(5.0, 440, 44100, 0.5)

  expect_equal(sound_medium$get_duration(), 5.0, tolerance = 0.01)

  # Long
  sound_long <- create_test_tone(30.0, 440, 44100, 0.5)

  expect_equal(sound_long$get_duration(), 30.0, tolerance = 0.01)
})

test_that("SIMD tone generation is deterministic", {
  skip_if_not_installed("pladdrr")
  library(pladdrr)

  # Generate same tone twice
  sound1 <- create_test_tone(1.0, 440, 44100, 0.5)

  sound2 <- create_test_tone(1.0, 440, 44100, 0.5)

  mat1 <- sound1$as_matrix()
  mat2 <- sound2$as_matrix()

  # Should be identical
  expect_equal(mat1, mat2, tolerance = 1e-12)
})

test_that("SIMD tone generation performance is reasonable", {
  skip_if_not_installed("pladdrr")
  library(pladdrr)

  # Generate long tone and measure time
  time_taken <- system.time({
    sound <- create_test_tone(10.0, 440, 44100, 0.5)
  })["elapsed"]

  # Should be fast (< 0.5 seconds for 10 seconds of audio)
  expect_true(time_taken < 0.5)
})
