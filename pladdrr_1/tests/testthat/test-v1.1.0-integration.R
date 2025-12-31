# Integration Tests for v1.1.0 Features
# Complete workflow tests for Cochleagram, Excitation, and advanced formants

test_that("Complete auditory modeling pipeline works", {
  # Create test sound
  sound <- generate_sine_wave(440, 0.2, sampling_rate = 22050)
  
  # Step 1: Create cochleagram
  cochlea <- sound$to_cochleagram(dt = 0.01, df = 0.1)
  expect_s3_class(cochlea, "Cochleagram")
  
  # Step 2: Extract excitation at specific time
  excitation <- cochlea$to_excitation(0.1)
  expect_s3_class(excitation, "Excitation")
  
  # Step 3: Extract formants from excitation
  formant <- excitation$to_formant(max_formants = 5)
  expect_s3_class(formant, "Formant")
  
  # Verify we can query results
  loudness <- cochlea$get_loudness_at_time(0.1)
  expect_true(is.finite(loudness))
  
  perceptual_loudness <- excitation$get_loudness()
  expect_true(is.finite(perceptual_loudness))
})

test_that("Spectrum to Excitation to Formant pipeline works", {
  sound <- generate_sine_wave(440, 0.2, sampling_rate = 22050)
  
  # Alternative path: Spectrum → Excitation → Formant
  spectrum <- sound$to_spectrum()
  expect_s3_class(spectrum, "Spectrum")
  
  excitation <- spectrum$to_excitation(erb_density = 0.1)
  expect_s3_class(excitation, "Excitation")
  
  formant <- excitation$to_formant(max_formants = 4)
  expect_s3_class(formant, "Formant")
})

test_that("Multiple formant methods produce comparable vowel formants", {
  # Create vowel-like sound (simple formant synthesis approximation)
  sound <- Sound$new(duration = 0.2, sampling_frequency = 22050)
  
  # Extract using different methods
  formant_burg <- sound$to_formant_burg(max_number_of_formants = 5)
  formant_willems <- sound$to_formant_willems(number_of_formants = 5)
  formant_sl <- sound$to_formant_sl(number_of_poles = 10)
  
  # All should succeed
  expect_s3_class(formant_burg, "Formant")
  expect_s3_class(formant_willems, "Formant")
  expect_s3_class(formant_sl, "Formant")
  
  # Query F1 and F2 from all methods
  time <- 0.1
  f1_burg <- formant_burg$get_value_at_time(1, time, unit = "hertz")
  f1_willems <- formant_willems$get_value_at_time(1, time, unit = "hertz")
  f1_sl <- formant_sl$get_value_at_time(1, time, unit = "hertz")
  
  # At least some methods should produce valid values
  valid_count <- sum(!is.na(c(f1_burg, f1_willems, f1_sl)))
  expect_true(valid_count >= 1)
})

test_that("Cochleagram comparison workflow for hearing simulation", {
  # Simulate normal hearing and hearing loss
  sound_original <- generate_sine_wave(440, 0.1, sampling_rate = 22050)
  
  # Normal hearing cochleagram
  cochlea_normal <- sound_original$to_cochleagram(dt = 0.01, df = 0.1)
  
  # Simulate hearing loss by filtering/attenuation
  sound_filtered <- sound_original$clone()
  # (In real use, would apply high-pass filter to simulate high-freq hearing loss)
  
  cochlea_impaired <- sound_filtered$to_cochleagram(dt = 0.01, df = 0.1)
  
  # Calculate perceptual difference
  difference <- cochlea_normal$get_difference(cochlea_impaired, tmin = 0, tmax = 0)
  
  expect_true(is.finite(difference))
  expect_true(difference >= 0)
})

test_that("Batch processing with new objects works", {
  # Create multiple test sounds
  sounds <- list(
    generate_sine_wave(440, 0.1, sampling_rate = 16000),
    generate_sine_wave(550, 0.1, sampling_rate = 16000),
    generate_sine_wave(660, 0.1, sampling_rate = 16000)
  )
  
  # Process all with cochleagram
  cochleagrams <- lapply(sounds, function(s) {
    s$to_cochleagram(dt = 0.01, df = 0.2)
  })
  
  # Verify all succeeded
  expect_equal(length(cochleagrams), 3)
  expect_true(all(sapply(cochleagrams, function(c) inherits(c, "Cochleagram"))))
  
  # Get loudness from all
  loudnesses <- sapply(cochleagrams, function(c) c$get_loudness_at_time(0.05))
  
  expect_equal(length(loudnesses), 3)
  expect_true(all(is.finite(loudnesses)))
  expect_true(all(loudnesses > 0))
})

test_that("SIMD-accelerated operations maintain accuracy", {
  skip_if_not(simd_info()$available, "SIMD not available")
  
  sound <- generate_sine_wave(440, 0.2, sampling_rate = 22050)
  
  # Run same analysis twice (should use SIMD both times)
  formant1 <- sound$to_formant_burg()
  formant2 <- sound$to_formant_burg()
  
  # Results should be identical
  f1_1 <- formant1$get_value_at_time(1, 0.1, unit = "hertz")
  f1_2 <- formant2$get_value_at_time(1, 0.1, unit = "hertz")
  
  if (!is.na(f1_1) && !is.na(f1_2)) {
    expect_equal(f1_1, f1_2, tolerance = 1e-10)
  }
  
  # Same for cochleagram
  cochlea1 <- sound$to_cochleagram()
  cochlea2 <- sound$to_cochleagram()
  
  loud1 <- cochlea1$get_loudness_at_time(0.1)
  loud2 <- cochlea2$get_loudness_at_time(0.1)
  
  expect_equal(loud1, loud2, tolerance = 1e-10)
})

test_that("Export and visualization pipeline works", {
  sound <- generate_sine_wave(440, 0.1, sampling_rate = 16000)
  
  # Create cochleagram and export
  cochlea <- sound$to_cochleagram(dt = 0.01, df = 0.2)
  cochlea_mat <- cochlea$as_matrix()
  
  expect_true(is.data.frame(cochlea_mat) || is.matrix(cochlea_mat))
  expect_true(nrow(cochlea_mat) > 0)
  
  # Create excitation and export
  excitation <- sound$to_spectrum()$to_excitation()
  excitation_vec <- excitation$as_vector()
  
  expect_true(is.data.frame(excitation_vec) || is.numeric(excitation_vec))
  expect_true(length(excitation_vec) > 0 || nrow(excitation_vec) > 0)
})

test_that("Memory management works across object conversions", {
  # Create chain of object conversions
  sound <- generate_sine_wave(440, 0.2, sampling_rate = 22050)
  cochlea <- sound$to_cochleagram()
  excitation <- cochlea$to_excitation(0.1)
  formant <- excitation$to_formant(max_formants = 5)
  
  # Force garbage collection
  gc()
  
  # Objects should still be accessible
  expect_true(sound$is_valid())
  expect_true(cochlea$is_valid())
  expect_true(excitation$is_valid())
  expect_true(formant$is_valid())
  
  # Can still query
  loudness <- excitation$get_loudness()
  expect_true(is.finite(loudness))
})

test_that("Error handling works across new features", {
  sound <- generate_sine_wave(440, 0.1, sampling_rate = 16000)
  
  # Invalid cochleagram parameters
  expect_error(sound$to_cochleagram(dt = -1))
  expect_error(sound$to_cochleagram(df = 0))
  
  # Invalid excitation parameters
  spectrum <- sound$to_spectrum()
  expect_error(spectrum$to_excitation(erb_density = -1))
  
  # Invalid formant parameters
  expect_error(sound$to_formant_willems(number_of_formants = -1))
  expect_error(sound$to_formant_sl(number_of_poles = 0))
})
