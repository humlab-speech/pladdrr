# Test SIMD tone generation
# Validates numerical accuracy and performance of tone synthesis

test_that("SIMD tone generation creates valid sine wave", {
  skip_if_not_installed("speaker")
  library(speaker)
  
  # Generate 440 Hz sine wave
  sound <- Sound$new_generate_tone(
    start_time = 0,
    end_time = 1.0,
    sample_rate = 44100,
    frequency = 440,
    amplitude = 0.5
  )
  
  # Check basic properties
  expect_true(!is.null(sound))
  expect_equal(sound$get_total_duration(), 1.0, tolerance = 0.01)
  
  # Convert to matrix
  mat <- sound$as_matrix()
  
  # Check amplitude
  max_amp <- max(abs(mat))
  expect_equal(max_amp, 0.5, tolerance = 0.01)
  
  # Check it's roughly sinusoidal (zero crossings)
  zero_crossings <- sum(diff(sign(mat[,1])) != 0)
  expected_crossings <- 440 * 2  # Two crossings per cycle
  expect_equal(zero_crossings, expected_crossings, tolerance = 10)
})

test_that("SIMD tone generation handles different frequencies", {
  skip_if_not_installed("speaker")
  library(speaker)
  
  # Low frequency
  sound_low <- Sound$new_generate_tone(
    start_time = 0,
    end_time = 1.0,
    sample_rate = 44100,
    frequency = 110,
    amplitude = 0.5
  )
  
  mat_low <- sound_low$as_matrix()
  zero_crossings_low <- sum(diff(sign(mat_low[,1])) != 0)
  expect_equal(zero_crossings_low, 110 * 2, tolerance = 10)
  
  # High frequency
  sound_high <- Sound$new_generate_tone(
    start_time = 0,
    end_time = 1.0,
    sample_rate = 44100,
    frequency = 1000,
    amplitude = 0.5
  )
  
  mat_high <- sound_high$as_matrix()
  zero_crossings_high <- sum(diff(sign(mat_high[,1])) != 0)
  expect_equal(zero_crossings_high, 1000 * 2, tolerance = 10)
})

test_that("SIMD tone generation handles different amplitudes", {
  skip_if_not_installed("speaker")
  library(speaker)
  
  # Low amplitude
  sound_quiet <- Sound$new_generate_tone(
    start_time = 0,
    end_time = 1.0,
    sample_rate = 44100,
    frequency = 440,
    amplitude = 0.1
  )
  
  mat_quiet <- sound_quiet$as_matrix()
  expect_equal(max(abs(mat_quiet)), 0.1, tolerance = 0.01)
  
  # High amplitude
  sound_loud <- Sound$new_generate_tone(
    start_time = 0,
    end_time = 1.0,
    sample_rate = 44100,
    frequency = 440,
    amplitude = 0.9
  )
  
  mat_loud <- sound_loud$as_matrix()
  expect_equal(max(abs(mat_loud)), 0.9, tolerance = 0.01)
  
  # Amplitude ratio should be preserved
  ratio <- max(abs(mat_loud)) / max(abs(mat_quiet))
  expect_equal(ratio, 9.0, tolerance = 0.1)
})

test_that("SIMD tone generation handles different sample rates", {
  skip_if_not_installed("speaker")
  library(speaker)
  
  # Low sample rate
  sound_16k <- Sound$new_generate_tone(
    start_time = 0,
    end_time = 1.0,
    sample_rate = 16000,
    frequency = 440,
    amplitude = 0.5
  )
  
  mat_16k <- sound_16k$as_matrix()
  expect_equal(nrow(mat_16k), 16000, tolerance = 5)
  
  # Standard sample rate
  sound_44k <- Sound$new_generate_tone(
    start_time = 0,
    end_time = 1.0,
    sample_rate = 44100,
    frequency = 440,
    amplitude = 0.5
  )
  
  mat_44k <- sound_44k$as_matrix()
  expect_equal(nrow(mat_44k), 44100, tolerance = 5)
  
  # High sample rate
  sound_48k <- Sound$new_generate_tone(
    start_time = 0,
    end_time = 1.0,
    sample_rate = 48000,
    frequency = 440,
    amplitude = 0.5
  )
  
  mat_48k <- sound_48k$as_matrix()
  expect_equal(nrow(mat_48k), 48000, tolerance = 5)
})

test_that("SIMD tone generation handles different durations", {
  skip_if_not_installed("speaker")
  library(speaker)
  
  # Short
  sound_short <- Sound$new_generate_tone(
    start_time = 0,
    end_time = 0.1,
    sample_rate = 44100,
    frequency = 440,
    amplitude = 0.5
  )
  
  expect_equal(sound_short$get_total_duration(), 0.1, tolerance = 0.01)
  
  # Medium
  sound_medium <- Sound$new_generate_tone(
    start_time = 0,
    end_time = 5.0,
    sample_rate = 44100,
    frequency = 440,
    amplitude = 0.5
  )
  
  expect_equal(sound_medium$get_total_duration(), 5.0, tolerance = 0.01)
  
  # Long
  sound_long <- Sound$new_generate_tone(
    start_time = 0,
    end_time = 30.0,
    sample_rate = 44100,
    frequency = 440,
    amplitude = 0.5
  )
  
  expect_equal(sound_long$get_total_duration(), 30.0, tolerance = 0.01)
})

test_that("SIMD tone generation is deterministic", {
  skip_if_not_installed("speaker")
  library(speaker)
  
  # Generate same tone twice
  sound1 <- Sound$new_generate_tone(
    start_time = 0,
    end_time = 1.0,
    sample_rate = 44100,
    frequency = 440,
    amplitude = 0.5
  )
  
  sound2 <- Sound$new_generate_tone(
    start_time = 0,
    end_time = 1.0,
    sample_rate = 44100,
    frequency = 440,
    amplitude = 0.5
  )
  
  mat1 <- sound1$as_matrix()
  mat2 <- sound2$as_matrix()
  
  # Should be identical
  expect_equal(mat1, mat2, tolerance = 1e-12)
})

test_that("SIMD tone generation performance is reasonable", {
  skip_if_not_installed("speaker")
  library(speaker)
  
  # Generate long tone and measure time
  time_taken <- system.time({
    sound <- Sound$new_generate_tone(
      start_time = 0,
      end_time = 10.0,
      sample_rate = 44100,
      frequency = 440,
      amplitude = 0.5
    )
  })["elapsed"]
  
  # Should be fast (< 0.5 seconds for 10 seconds of audio)
  expect_true(time_taken < 0.5)
})
