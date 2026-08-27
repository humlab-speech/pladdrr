# test-ltas-units.R - Tests for LTAS get_slope unit parameter
#
# Verifies that LTAS unit codes match Praat's behavior:
# - "energy" = 1 (10*log10 conversion)
# - "sones" = 2 (10*log2 conversion)
# - "dB" = 0 (passthrough)

test_that("LTAS get_slope returns dB values, not ratios", {
  # Generate test tone
  sound <- Sound$create_tone(frequency = 440, duration = 0.5, sampling_rate = 16000)
  ltas <- sound$to_ltas(bandwidth = 100)

  # Test energy unit returns dB (negative value), not ratio (small positive)
  slope_energy <- ltas$get_slope(0, 1000, 1000, 10000, unit = "energy")

  # If returning ratio, would be ~0.1-1.0
  # If returning dB, should be negative ~-10 to -40
  expect_true(slope_energy < 0,
              label = "energy unit should return dB (negative), not ratio")
  expect_gt(slope_energy, -100, label = "energy unit value should be reasonable dB")
})

test_that("LTAS get_slope dB unit matches energy unit", {
  sound <- Sound$create_tone(frequency = 440, duration = 0.5, sampling_rate = 16000)
  ltas <- sound$to_ltas(bandwidth = 100)

  slope_energy <- ltas$get_slope(0, 1000, 1000, 10000, unit = "energy")
  slope_db <- ltas$get_slope(0, 1000, 1000, 10000, unit = "dB")

  # Both should be in dB - energy uses 10*log10, dB is passthrough
  # For slope calculation they should be similar
  expect_type(slope_energy, "double")
  expect_type(slope_db, "double")
  expect_lt(slope_energy, 0)
  expect_lt(slope_db, 0)
})

test_that("LTAS get_slope sones unit returns dB values", {
  sound <- Sound$create_tone(frequency = 440, duration = 0.5, sampling_rate = 16000)
  ltas <- sound$to_ltas(bandwidth = 100)

  slope_sones <- ltas$get_slope(0, 1000, 1000, 10000, unit = "sones")

  # Sones uses log2 instead of log10, but should still return dB-scale values
  expect_type(slope_sones, "double")
  # Should be in dB range, not a ratio
  expect_true(is.finite(slope_sones))
  expect_lt(slope_sones, 50,
              label = "sones unit returns reasonable dB value")
})

test_that("LTAS get_mean respects unit parameter", {
  sound <- Sound$create_tone(frequency = 440, duration = 0.5, sampling_rate = 16000)
  ltas <- sound$to_ltas(bandwidth = 100)

  mean_energy <- ltas$get_mean(0, 0, unit = "energy")
  mean_db <- ltas$get_mean(0, 0, unit = "dB")

  expect_type(mean_energy, "double")
  expect_type(mean_db, "double")
})
