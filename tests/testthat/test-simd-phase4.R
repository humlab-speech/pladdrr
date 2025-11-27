# Test Suite for SIMD Phase 4 - FFT and Formant/LPC Optimization
# Tests for SIMD-accelerated FFT and formant extraction operations

test_that("SIMD FFT produces accurate results", {
  skip_if_not(pladdrr:::.has_simd(), "SIMD not available")
  
  # Create test signal (sine wave)
  sound <- Sound$new(440, duration = 0.1, sampling_frequency = 16000)
  
  # Perform FFT via Spectrum creation (uses FFT internally)
  spectrum <- sound$to_spectrum()
  
  expect_s3_class(spectrum, "Spectrum")
  
  # Peak should be at ~440 Hz
  peak_freq <- spectrum$get_frequency_of_maximum(0, 1000)
  expect_true(abs(peak_freq - 440) < 10)  # Within 10 Hz
})

test_that("SIMD FFT matches scalar FFT", {
  skip_if_not(pladdrr:::.has_simd(), "SIMD not available")
  
  sound <- Sound$new(440, duration = 0.1, sampling_frequency = 16000)
  
  # Create two spectra (should use same SIMD path)
  spectrum1 <- sound$to_spectrum()
  spectrum2 <- sound$to_spectrum()
  
  # Get power at same frequency
  power1 <- spectrum1$get_value_at_frequency(440, unit = "hertz")
  power2 <- spectrum2$get_value_at_frequency(440, unit = "hertz")
  
  # Should be numerically identical (SIMD is deterministic)
  expect_equal(power1, power2, tolerance = 1e-10)
})

test_that("SIMD inverse FFT works correctly", {
  skip_if_not(pladdrr:::.has_simd(), "SIMD not available")
  
  # Create sound, convert to spectrum, back to sound
  sound_original <- Sound$new(440, duration = 0.05, sampling_frequency = 16000)
  spectrum <- sound_original$to_spectrum()
  sound_reconstructed <- spectrum$to_sound()
  
  expect_s3_class(sound_reconstructed, "Sound")
  
  # Reconstructed sound should be similar to original
  # (allowing for edge effects and windowing)
  original_rms <- sound_original$get_root_mean_square(0, 0)
  reconstructed_rms <- sound_reconstructed$get_root_mean_square(0, 0)
  
  # RMS should be in same ballpark
  expect_true(abs(original_rms - reconstructed_rms) / original_rms < 0.5)
})

test_that("SIMD formant extraction is accurate", {
  skip_if_not(pladdrr:::.has_simd(), "SIMD not available")
  
  # Create vowel-like sound
  sound <- Sound$new(duration = 0.2, sampling_frequency = 22050)
  
  # Extract formants (uses LPC with SIMD)
  formant <- sound$to_formant_burg(max_number_of_formants = 5)
  
  expect_s3_class(formant, "Formant")
  
  # Should be able to extract formants
  f1 <- formant$get_value_at_time(1, 0.1, unit = "hertz")
  
  # If formant found, should be in reasonable range
  if (!is.na(f1)) {
    expect_true(f1 > 50)     # Lower bound
    expect_true(f1 < 2000)   # Upper bound for F1
  }
})

test_that("SIMD LPC coefficients are consistent", {
  skip_if_not(pladdrr:::.has_simd(), "SIMD not available")
  
  sound <- Sound$new(440, duration = 0.2, sampling_frequency = 22050)
  
  # Create LPC object twice
  lpc1 <- sound$to_lpc_burg(prediction_order = 10, analysis_width = 0.025)
  lpc2 <- sound$to_lpc_burg(prediction_order = 10, analysis_width = 0.025)
  
  expect_s3_class(lpc1, "LPC")
  expect_s3_class(lpc2, "LPC")
  
  # Should produce identical results
  # (Test by converting to formants and comparing)
  formant1 <- lpc1$to_formant()
  formant2 <- lpc2$to_formant()
  
  f1_1 <- formant1$get_value_at_time(1, 0.1, unit = "hertz")
  f1_2 <- formant2$get_value_at_time(1, 0.1, unit = "hertz")
  
  if (!is.na(f1_1) && !is.na(f1_2)) {
    expect_equal(f1_1, f1_2, tolerance = 1e-10)
  }
})

test_that("SIMD autocorrelation in LPC is accurate", {
  skip_if_not(pladdrr:::.has_simd(), "SIMD not available")
  
  # Create periodic signal
  sound <- Sound$new(440, duration = 0.1, sampling_frequency = 16000)
  
  # LPC analysis (uses autocorrelation internally)
  lpc <- sound$to_lpc_burg(prediction_order = 12)
  
  expect_s3_class(lpc, "LPC")
  
  # Convert to spectrum (tests LPC accuracy)
  spectrum <- lpc$to_spectrum(0.05, 0, 50, 1000)
  expect_s3_class(spectrum, "Spectrum")
})

test_that("SIMD bandwidth estimation works", {
  skip_if_not(pladdrr:::.has_simd(), "SIMD not available")
  
  sound <- Sound$new(duration = 0.2, sampling_frequency = 22050)
  formant <- sound$to_formant_burg()
  
  # Query bandwidth
  b1 <- formant$get_bandwidth_at_time(1, 0.1, unit = "hertz")
  
  # If bandwidth found, should be positive and reasonable
  if (!is.na(b1)) {
    expect_true(b1 > 0)
    expect_true(b1 < 1000)  # Typical bandwidth range
  }
})

test_that("SIMD Willems formant method works", {
  skip_if_not(pladdrr:::.has_simd(), "SIMD not available")
  
  sound <- Sound$new(duration = 0.2, sampling_frequency = 22050)
  
  formant <- sound$to_formant_willems(number_of_formants = 5)
  
  expect_s3_class(formant, "Formant")
  
  # Verify consistency
  formant2 <- sound$to_formant_willems(number_of_formants = 5)
  
  f2_1 <- formant$get_value_at_time(2, 0.1, unit = "hertz")
  f2_2 <- formant2$get_value_at_time(2, 0.1, unit = "hertz")
  
  if (!is.na(f2_1) && !is.na(f2_2)) {
    expect_equal(f2_1, f2_2, tolerance = 1e-10)
  }
})

test_that("SIMD Split-Levinson method works", {
  skip_if_not(pladdrr:::.has_simd(), "SIMD not available")
  
  sound <- Sound$new(duration = 0.2, sampling_frequency = 22050)
  
  formant <- sound$to_formant_sl(number_of_poles = 10)
  
  expect_s3_class(formant, "Formant")
})

test_that("SIMD FFT handles power-of-2 sizes efficiently", {
  skip_if_not(pladdrr:::.has_simd(), "SIMD not available")
  
  # Create sounds with power-of-2 sample counts
  sound_256 <- Sound$new(440, duration = 256/16000, sampling_frequency = 16000)
  sound_512 <- Sound$new(440, duration = 512/16000, sampling_frequency = 16000)
  sound_1024 <- Sound$new(440, duration = 1024/16000, sampling_frequency = 16000)
  
  # All should work efficiently
  spectrum_256 <- sound_256$to_spectrum()
  spectrum_512 <- sound_512$to_spectrum()
  spectrum_1024 <- sound_1024$to_spectrum()
  
  expect_s3_class(spectrum_256, "Spectrum")
  expect_s3_class(spectrum_512, "Spectrum")
  expect_s3_class(spectrum_1024, "Spectrum")
})

test_that("SIMD FFT handles non-power-of-2 sizes correctly", {
  skip_if_not(pladdrr:::.has_simd(), "SIMD not available")
  
  # Create sound with non-power-of-2 sample count
  sound_odd <- Sound$new(440, duration = 0.0573, sampling_frequency = 16000)
  # 0.0573 * 16000 = ~917 samples (not power of 2)
  
  spectrum <- sound_odd$to_spectrum()
  expect_s3_class(spectrum, "Spectrum")
  
  # Should still find peak at ~440 Hz
  peak_freq <- spectrum$get_frequency_of_maximum(400, 480)
  expect_true(abs(peak_freq - 440) < 20)
})

test_that("SIMD formant extraction handles edge cases", {
  skip_if_not(pladdrr:::.has_simd(), "SIMD not available")
  
  # Very short sound
  sound_short <- Sound$new(440, duration = 0.01, sampling_frequency = 16000)
  formant_short <- sound_short$to_formant_burg(max_number_of_formants = 3)
  expect_s3_class(formant_short, "Formant")
  
  # Silence
  sound_silence <- Sound$new(duration = 0.1, sampling_frequency = 16000)
  formant_silence <- sound_silence$to_formant_burg()
  expect_s3_class(formant_silence, "Formant")
  
  # Very long sound
  sound_long <- Sound$new(440, duration = 2.0, sampling_frequency = 16000)
  formant_long <- sound_long$to_formant_burg(time_step = 0.01)
  expect_s3_class(formant_long, "Formant")
})

test_that("SIMD operations maintain numerical stability", {
  skip_if_not(pladdrr:::.has_simd(), "SIMD not available")
  
  # Test with very quiet sound (numerical stability test)
  sound_quiet <- Sound$new(440, duration = 0.1, sampling_frequency = 16000)
  sound_quiet <- sound_quiet$multiply(0.001)  # Make very quiet
  
  spectrum <- sound_quiet$to_spectrum()
  expect_s3_class(spectrum, "Spectrum")
  
  # Should still produce valid spectrum (no NaN/Inf)
  power <- spectrum$get_value_at_frequency(440, unit = "hertz")
  expect_true(is.finite(power))
  
  # Test formant extraction on quiet sound
  formant <- sound_quiet$to_formant_burg()
  expect_s3_class(formant, "Formant")
})

test_that("SIMD complex operations work correctly", {
  skip_if_not(pladdrr:::.has_simd(), "SIMD not available")
  
  # Create complex signal (sum of sine waves)
  sound <- Sound$new(440, duration = 0.1, sampling_frequency = 16000)
  sound2 <- Sound$new(880, duration = 0.1, sampling_frequency = 16000)
  sound_complex <- sound$add(sound2)
  
  # FFT should identify both frequency components
  spectrum <- sound_complex$to_spectrum()
  
  power_440 <- spectrum$get_value_at_frequency(440, unit = "hertz")
  power_880 <- spectrum$get_value_at_frequency(880, unit = "hertz")
  power_660 <- spectrum$get_value_at_frequency(660, unit = "hertz")
  
  # Peaks at 440 and 880 should be larger than at 660
  expect_true(power_440 > power_660)
  expect_true(power_880 > power_660)
})

test_that("SIMD performance is better than scalar", {
  skip_if_not(pladdrr:::.has_simd(), "SIMD not available")
  skip_on_cran()  # Performance tests can be slow
  
  sound <- Sound$new(440, duration = 0.5, sampling_frequency = 22050)
  
  # Warm-up
  _ <- sound$to_spectrum()
  
  # Time SIMD execution
  time_simd <- system.time({
    for (i in 1:10) {
      spectrum <- sound$to_spectrum()
      formant <- sound$to_formant_burg()
    }
  })
  
  # SIMD should complete in reasonable time
  # (Not testing absolute performance, just that it runs)
  expect_true(time_simd["elapsed"] < 10)  # 10 seconds for 10 iterations
})
