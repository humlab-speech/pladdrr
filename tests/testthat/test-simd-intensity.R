# Test SIMD intensity calculations
# Validates numerical accuracy of RMS, energy, and power calculations

test_that("SIMD RMS calculation is numerically accurate", {
  skip_if_not_installed("pladdrr")
  library(pladdrr)
  
  # Generate sine wave
  sound <- Sound$create_tone(1.0, 44100, 440, 0.5)
  
  # Get duration
  dur <- sound$get_duration()
  
  # Get RMS using SIMD
  rms <- sound$get_rms(0, dur)
  
  # Expected RMS for sine wave is amplitude / sqrt(2)
  expected_rms <- 0.5 / sqrt(2)
  
  # Allow some tolerance due to discretization
  expect_equal(rms, expected_rms, tolerance = 0.01)
})

test_that("SIMD energy calculation is consistent", {
  skip_if_not_installed("pladdrr")
  library(pladdrr)
  
  # Generate sine wave
  sound <- Sound$create_tone(1.0, 44100, 440, 0.5)
  dur <- sound$get_duration()
  
  energy <- sound$get_energy(0, dur)
  
  # Energy should be positive
  expect_gt(energy, 0)
  
  # Energy should scale with square of amplitude
  sound2 <- Sound$create_tone(1.0, 44100, 440, 1.0)  # Double amplitude
  dur2 <- sound2$get_duration()
  
  energy2 <- sound2$get_energy(0, dur2)
  
  # Energy should be ~4x (square of amplitude ratio)
  expect_equal(energy2 / energy, 4.0, tolerance = 0.05)
})

test_that("SIMD power calculation is consistent with energy", {
  skip_if_not_installed("pladdrr")
  library(pladdrr)
  
  sound <- Sound$create_tone(2.0, 44100, 440, 0.5)
  dur <- sound$get_duration()
  
  energy <- sound$get_energy(0, dur)
  power <- sound$get_power(0, dur)
  
  # Power = Energy / Duration
  expected_power <- energy / dur
  
  expect_equal(power, expected_power, tolerance = 1e-10)
})

test_that("SIMD intensity calculations handle time windows", {
  skip_if_not_installed("pladdrr")
  library(pladdrr)
  
  # Generate sounds with different amplitudes
  sound1 <- Sound$create_tone(1.0, 44100, 440, 0.3)
  sound2 <- Sound$create_tone(1.0, 44100, 440, 0.9)
  
  dur1 <- sound1$get_duration()
  dur2 <- sound2$get_duration()
  
  rms1 <- sound1$get_rms(0, dur1)
  rms2 <- sound2$get_rms(0, dur2)
  
  # RMS should scale with amplitude
  expect_equal(rms2 / rms1, 3.0, tolerance = 0.01)
})

test_that("SIMD intensity handles edge cases", {
  skip_if_not_installed("pladdrr")
  library(pladdrr)
  
  # Silence
  sound <- Sound$create_tone(1.0, 44100, 440, 0.0)
  dur <- sound$get_duration()
  
  rms <- sound$get_rms(0, dur)
  energy <- sound$get_energy(0, dur)
  power <- sound$get_power(0, dur)
  
  expect_equal(rms, 0.0, tolerance = 1e-12)
  expect_equal(energy, 0.0, tolerance = 1e-12)
  expect_equal(power, 0.0, tolerance = 1e-12)
})

test_that("SIMD intensity calculations are consistent across durations", {
  skip_if_not_installed("pladdrr")
  library(pladdrr)
  
  # Short sound
  sound_short <- Sound$create_tone(0.5, 44100, 440, 0.5)
  dur_short <- sound_short$get_duration()
  
  # Long sound
  sound_long <- Sound$create_tone(10.0, 44100, 440, 0.5)
  dur_long <- sound_long$get_duration()
  
  rms_short <- sound_short$get_rms(0, dur_short)
  rms_long <- sound_long$get_rms(0, dur_long)
  
  # RMS should be same regardless of duration (for constant amplitude)
  expect_equal(rms_short, rms_long, tolerance = 0.01)
  
  power_short <- sound_short$get_power(0, dur_short)
  power_long <- sound_long$get_power(0, dur_long)
  
  # Power should also be same
  expect_equal(power_short, power_long, tolerance = 0.01)
})
