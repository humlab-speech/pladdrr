# test-sound-generate.R - Tests for synthetic sound generation
#
# These tests verify that generated sounds (sine waves, noise) have
# correct mathematical properties

test_that("generate_sine_wave() creates mathematically correct waveform", {
  frequency <- 440  # A4 note
  duration <- 1.0
  sampling_rate <- 44100
  amplitude <- 0.5

  sound <- generate_sine_wave(frequency, duration,
                              sampling_rate = sampling_rate,
                              amplitude = amplitude)

  # Check object type
  expect_s3_class(sound, "Sound")

  # Check dimensions
  expected_samples <- round(duration * sampling_rate)
  expect_equal(sound$get_number_of_samples(), expected_samples,
    tolerance = sqrt(.Machine$double.eps))
  expect_equal(sound$get_sampling_frequency(), sampling_rate,
    tolerance = sqrt(.Machine$double.eps))
  expect_equal(sound$get_total_duration(), duration, tolerance = 1e-6)

  # Check amplitude range
  expect_true(all(sound$get_values() >= -amplitude))
  expect_true(all(sound$get_values() <= amplitude))
  expect_gte(max(abs(sound$get_values())), amplitude * 0.99)  # Should reach near amplitude

  # Check sine wave properties
  # At t=0, sin(2*pi*f*0) = 0, so first value should be near 0
  expect_equal(sound$get_values()[1], 0, tolerance = 0.01)

  # Check frequency by counting zero crossings
  # A sine wave should have 2 * frequency zero crossings per second
  zero_crossings <- sum(diff(sign(sound$get_values())) != 0)
  expected_crossings <- 2 * frequency * duration
  expect_equal(zero_crossings, expected_crossings, tolerance = 10)
})

test_that("generate_sine_wave() uses default parameters correctly", {
  # Test with minimal parameters (should use defaults)
  sound <- generate_sine_wave(440, 0.1)

  expect_s3_class(sound, "Sound")
  expect_equal(sound$get_sampling_frequency(), 44100, tolerance = sqrt(.Machine$double.eps))  # Default
  # Default amplitude should create values in [-1, 1] range
  expect_true(all(sound$get_values() >= -1.0))
  expect_true(all(sound$get_values() <= 1.0))
})

test_that("generate_sine_wave() validates parameters", {
  # Non-positive frequency should error
  expect_error(generate_sine_wave(0, 1.0), "frequency.*positive")
  expect_error(generate_sine_wave(-100, 1.0), "frequency.*positive")

  # Non-positive duration should error
  expect_error(generate_sine_wave(440, 0), "duration.*positive")
  expect_error(generate_sine_wave(440, -1), "duration.*positive")

  # Non-positive sampling rate should error
  expect_error(generate_sine_wave(440, 1.0, sampling_rate = 0),
               "sampling.*rate.*positive")

  # Non-positive amplitude should error
  expect_error(generate_sine_wave(440, 1.0, amplitude = 0),
               "amplitude.*positive")
  expect_error(generate_sine_wave(440, 1.0, amplitude = -0.5),
               "amplitude.*positive")
})

test_that("generate_sine_wave() creates phase-coherent waveform", {
  # Generate two sine waves with same parameters
  sound1 <- generate_sine_wave(440, 0.1, sampling_rate = 44100)
  sound2 <- generate_sine_wave(440, 0.1, sampling_rate = 44100)

  # They should be identical (deterministic, no phase offset)
  expect_equal(sound1$get_values(), sound2$get_values(),
    tolerance = sqrt(.Machine$double.eps))
})

test_that("generate_noise() creates random noise with correct properties", {
  duration <- 1.0
  sampling_rate <- 44100
  amplitude <- 0.5
  seed <- 12345

  sound <- generate_noise(duration, sampling_rate = sampling_rate,
                         amplitude = amplitude, seed = seed)

  # Check object type
  expect_s3_class(sound, "Sound")

  # Check dimensions
  expected_samples <- round(duration * sampling_rate)
  expect_equal(sound$get_number_of_samples(), expected_samples,
    tolerance = sqrt(.Machine$double.eps))
  expect_equal(sound$get_sampling_frequency(), sampling_rate,
    tolerance = sqrt(.Machine$double.eps))

  # Check values are numeric
  expect_type(sound$get_values(), "double")
  expect_length(sound$get_values(), expected_samples)

  # Check no NAs or infinite values
  expect_false(anyNA(sound$get_values()))
  expect_false(any(is.infinite(sound$get_values())))

  # Check amplitude scaling (noise should be roughly within amplitude range)
  # For Gaussian noise, ~99.7% should be within 3 standard deviations
  # If amplitude scales the standard deviation, most values should be within
  #  amplitude range
  expect_lt(mean(abs(sound$get_values())), amplitude)
})

test_that("generate_noise() with seed produces reproducible results", {
  seed <- 42
  duration <- 0.1

  sound1 <- generate_noise(duration, seed = seed)
  sound2 <- generate_noise(duration, seed = seed)

  # With same seed, should get identical noise
  expect_equal(sound1$get_values(), sound2$get_values(),
    tolerance = sqrt(.Machine$double.eps))
})

test_that("generate_noise() without seed produces different results", {
  duration <- 0.1

  sound1 <- generate_noise(duration)
  sound2 <- generate_noise(duration)

  # Without seed, should get different noise
  # (very unlikely to be equal, but check a subset to be safe)
  expect_false(all(sound1$get_values() == sound2$get_values()))
  expect_false(
    identical(sound1$get_values()[1:100], sound2$get_values()[1:100]))
})

test_that("generate_noise() uses default parameters correctly", {
  sound <- generate_noise(0.1)

  expect_s3_class(sound, "Sound")
  expect_equal(sound$get_sampling_frequency(), 44100, tolerance = sqrt(.Machine$double.eps))  # Default
  expect_equal(sound$get_total_duration(), 0.1, tolerance = 1e-6)
})

test_that("generate_noise() validates parameters", {
  # Non-positive duration should error
  expect_error(generate_noise(0), "duration.*positive")
  expect_error(generate_noise(-1), "duration.*positive")

  # Non-positive sampling rate should error
  expect_error(generate_noise(1.0, sampling_rate = 0),
               "sampling.*rate.*positive")

  # Non-positive amplitude should error
  expect_error(generate_noise(1.0, amplitude = 0),
               "amplitude.*positive")
  expect_error(generate_noise(1.0, amplitude = -0.5),
               "amplitude.*positive")
})

test_that("generate_noise() creates white noise (flat spectrum)", {
  # This is a more advanced test - white noise should have equal power
  # across all frequencies. We can check this by comparing power in
  # different frequency bands (though this is a statistical test)

  set.seed(123)
  sound <- generate_noise(2.0, sampling_rate = 44100, seed = 123)

  # Very basic check: variance should be roughly constant over time
  # Split into chunks and check variance doesn't vary too much
  chunk_size <- 1000
  n_chunks <- floor(length(sound$get_values()) / chunk_size)

  variances <- vapply(1:n_chunks, function(i) {
    start_idx <- (i-1) * chunk_size + 1
    end_idx <- i * chunk_size
    var(sound$get_values()[start_idx:end_idx])
  }, numeric(1))

  # Coefficient of variation should be relatively small for white noise
  cv <- sd(variances) / mean(variances)
  expect_lt(cv, 0.5)  # Arbitrary threshold for "roughly equal"
})
