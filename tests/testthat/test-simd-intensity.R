# Test SIMD intensity calculations
# Validates numerical accuracy of RMS, energy, and power calculations

test_that("SIMD RMS calculation is numerically accurate", {
  skip_if_not_installed("speaker")
  library(speaker)
  
  # Generate sine wave
  sound <- Sound$new_generate_tone(
    start_time = 0,
    end_time = 1.0,
    sample_rate = 44100,
    frequency = 440,
    amplitude = 0.5
  )
  
  # Get RMS using SIMD
  rms <- sound$get_rms(from_time = 0, to_time = 1.0)
  
  # Expected RMS for sine wave is amplitude / sqrt(2)
  expected_rms <- 0.5 / sqrt(2)
  
  # Allow some tolerance due to discretization
  expect_equal(rms, expected_rms, tolerance = 0.01)
})

test_that("SIMD energy calculation is consistent", {
  skip_if_not_installed("speaker")
  library(speaker)
  
  # Generate sine wave
  sound <- Sound$new_generate_tone(
    start_time = 0,
    end_time = 1.0,
    sample_rate = 44100,
    frequency = 440,
    amplitude = 0.5
  )
  
  energy <- sound$get_energy(from_time = 0, to_time = 1.0)
  
  # Energy should be positive
  expect_true(energy > 0)
  
  # Energy should scale with square of amplitude
  sound2 <- Sound$new_generate_tone(
    start_time = 0,
    end_time = 1.0,
    sample_rate = 44100,
    frequency = 440,
    amplitude = 1.0  # Double amplitude
  )
  
  energy2 <- sound2$get_energy(from_time = 0, to_time = 1.0)
  
  # Energy should be ~4x (square of amplitude ratio)
  expect_equal(energy2 / energy, 4.0, tolerance = 0.05)
})

test_that("SIMD power calculation is consistent with energy", {
  skip_if_not_installed("speaker")
  library(speaker)
  
  sound <- Sound$new_generate_tone(
    start_time = 0,
    end_time = 2.0,
    sample_rate = 44100,
    frequency = 440,
    amplitude = 0.5
  )
  
  energy <- sound$get_energy(from_time = 0, to_time = 2.0)
  power <- sound$get_power(from_time = 0, to_time = 2.0)
  
  # Power = Energy / Duration
  expected_power <- energy / 2.0
  
  expect_equal(power, expected_power, tolerance = 1e-10)
})

test_that("SIMD intensity calculations handle time windows", {
  skip_if_not_installed("speaker")
  library(speaker)
  
  # Generate sound with two different sections
  # First half: amplitude 0.3, second half: amplitude 0.9
  sound1 <- Sound$new_generate_tone(
    start_time = 0,
    end_time = 1.0,
    sample_rate = 44100,
    frequency = 440,
    amplitude = 0.3
  )
  
  sound2 <- Sound$new_generate_tone(
    start_time = 1.0,
    end_time = 2.0,
    sample_rate = 44100,
    frequency = 440,
    amplitude = 0.9
  )
  
  # Concatenate sounds (if method available)
  # For now, test individual windows
  
  rms1 <- sound1$get_rms(from_time = 0, to_time = 1.0)
  rms2 <- sound2$get_rms(from_time = 1.0, to_time = 2.0)
  
  # RMS should scale with amplitude
  expect_equal(rms2 / rms1, 3.0, tolerance = 0.01)
})

test_that("SIMD intensity handles edge cases", {
  skip_if_not_installed("speaker")
  library(speaker)
  
  # Silence
  sound <- Sound$new_generate_tone(
    start_time = 0,
    end_time = 1.0,
    sample_rate = 44100,
    frequency = 440,
    amplitude = 0.0
  )
  
  rms <- sound$get_rms(from_time = 0, to_time = 1.0)
  energy <- sound$get_energy(from_time = 0, to_time = 1.0)
  power <- sound$get_power(from_time = 0, to_time = 1.0)
  
  expect_equal(rms, 0.0, tolerance = 1e-12)
  expect_equal(energy, 0.0, tolerance = 1e-12)
  expect_equal(power, 0.0, tolerance = 1e-12)
})

test_that("SIMD intensity calculations are consistent across durations", {
  skip_if_not_installed("speaker")
  library(speaker)
  
  # Short sound
  sound_short <- Sound$new_generate_tone(
    start_time = 0,
    end_time = 0.5,
    sample_rate = 44100,
    frequency = 440,
    amplitude = 0.5
  )
  
  # Long sound
  sound_long <- Sound$new_generate_tone(
    start_time = 0,
    end_time = 10.0,
    sample_rate = 44100,
    frequency = 440,
    amplitude = 0.5
  )
  
  rms_short <- sound_short$get_rms(from_time = 0, to_time = 0.5)
  rms_long <- sound_long$get_rms(from_time = 0, to_time = 10.0)
  
  # RMS should be same regardless of duration (for constant amplitude)
  expect_equal(rms_short, rms_long, tolerance = 0.01)
  
  power_short <- sound_short$get_power(from_time = 0, to_time = 0.5)
  power_long <- sound_long$get_power(from_time = 0, to_time = 10.0)
  
  # Power should also be same
  expect_equal(power_short, power_long, tolerance = 0.01)
})
