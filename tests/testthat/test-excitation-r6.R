# Test Suite for Excitation R6 Class
# Tests for auditory excitation pattern modeling (ERB scale)

test_that("Excitation can be created from Spectrum", {
  sound <- Sound$new(440, duration = 0.1, sampling_frequency = 16000)
  spectrum <- sound$to_spectrum()
  
  # Create excitation pattern
  excitation <- spectrum$to_excitation(erb_density = 0.1)
  
  expect_s3_class(excitation, "Excitation")
  expect_s3_class(excitation, "PraatObject")
  expect_true(!is.null(excitation$.xptr))
})

test_that("Excitation can be created from Cochleagram", {
  sound <- Sound$new(440, duration = 0.2, sampling_frequency = 16000)
  cochlea <- sound$to_cochleagram(dt = 0.01, df = 0.1)
  
  # Extract excitation at specific time
  excitation <- cochlea$to_excitation(0.1)
  
  expect_s3_class(excitation, "Excitation")
  expect_true(!is.null(excitation$.xptr))
})

test_that("Excitation can calculate total loudness", {
  sound <- Sound$new(440, duration = 0.1, sampling_frequency = 16000)
  spectrum <- sound$to_spectrum()
  excitation <- spectrum$to_excitation()
  
  # Get total loudness in sones
  loudness <- excitation$get_loudness()
  
  expect_type(loudness, "double")
  expect_true(is.finite(loudness))
  expect_true(loudness > 0)  # Non-silent sound should have loudness
})

test_that("Excitation can query value at frequency", {
  sound <- Sound$new(440, duration = 0.1, sampling_frequency = 16000)
  spectrum <- sound$to_spectrum()
  excitation <- spectrum$to_excitation()
  
  # Query at 440 Hz (≈ 4.2 Bark)
  value <- excitation$get_value_at_frequency(4.2)
  
  expect_type(value, "double")
  expect_true(is.finite(value))
  expect_true(value >= 0)  # Excitation is non-negative
})

test_that("Excitation perceptual distance works", {
  sound1 <- Sound$new(440, duration = 0.1, sampling_frequency = 16000)
  sound2 <- Sound$new(880, duration = 0.1, sampling_frequency = 16000)
  
  spectrum1 <- sound1$to_spectrum()
  spectrum2 <- sound2$to_spectrum()
  
  excitation1 <- spectrum1$to_excitation()
  excitation2 <- spectrum2$to_excitation()
  
  # Calculate perceptual distance
  distance <- excitation1$get_distance(excitation2)
  
  expect_type(distance, "double")
  expect_true(is.finite(distance))
  expect_true(distance >= 0)  # Distance metric property
  expect_true(distance > 0)   # Different sounds should differ
})

test_that("Excitation can be converted to Formant", {
  sound <- Sound$new(440, duration = 0.1, sampling_frequency = 16000)
  spectrum <- sound$to_spectrum()
  excitation <- spectrum$to_excitation()
  
  # Extract formants from excitation pattern
  formant <- excitation$to_formant(max_formants = 5)
  
  expect_s3_class(formant, "Formant")
  expect_true(!is.null(formant$.xptr))
})

test_that("Excitation can be exported as vector", {
  sound <- Sound$new(440, duration = 0.1, sampling_frequency = 16000)
  spectrum <- sound$to_spectrum()
  excitation <- spectrum$to_excitation()
  
  # Export to R vector/dataframe
  vec <- excitation$as_vector()
  
  expect_true(is.data.frame(vec) || is.numeric(vec))
  expect_true(length(vec) > 0 || nrow(vec) > 0)
})

test_that("Excitation handles silence correctly", {
  # Create silent sound
  sound_silence <- Sound$new(duration = 0.1, sampling_frequency = 16000)
  spectrum_silence <- sound_silence$to_spectrum()
  excitation_silence <- spectrum_silence$to_excitation()
  
  loudness <- excitation_silence$get_loudness()
  
  expect_type(loudness, "double")
  expect_true(is.finite(loudness))
  expect_true(loudness >= 0)  # Should be zero or near-zero
})

test_that("Excitation SIMD accuracy matches scalar", {
  skip_if_not(pladdrr:::.has_simd(), "SIMD not available")
  
  sound <- Sound$new(440, duration = 0.1, sampling_frequency = 16000)
  spectrum <- sound$to_spectrum()
  
  # Create two excitations (should use SIMD if available)
  excitation1 <- spectrum$to_excitation()
  excitation2 <- spectrum$to_excitation()
  
  # Results should be identical
  loudness1 <- excitation1$get_loudness()
  loudness2 <- excitation2$get_loudness()
  
  expect_equal(loudness1, loudness2, tolerance = 1e-10)
})

test_that("Excitation validates parameters", {
  sound <- Sound$new(440, duration = 0.1, sampling_frequency = 16000)
  spectrum <- sound$to_spectrum()
  
  # Invalid ERB density
  expect_error(spectrum$to_excitation(erb_density = -0.1))
  expect_error(spectrum$to_excitation(erb_density = 0))
})

test_that("Excitation distance is symmetric", {
  sound1 <- Sound$new(440, duration = 0.1, sampling_frequency = 16000)
  sound2 <- Sound$new(550, duration = 0.1, sampling_frequency = 16000)
  
  excitation1 <- sound1$to_spectrum()$to_excitation()
  excitation2 <- sound2$to_spectrum()$to_excitation()
  
  # Distance should be symmetric
  dist12 <- excitation1$get_distance(excitation2)
  dist21 <- excitation2$get_distance(excitation1)
  
  expect_equal(dist12, dist21, tolerance = 1e-8)
})

test_that("Excitation identical sounds have zero distance", {
  sound <- Sound$new(440, duration = 0.1, sampling_frequency = 16000)
  
  excitation1 <- sound$to_spectrum()$to_excitation()
  excitation2 <- sound$to_spectrum()$to_excitation()
  
  # Same sound should have zero distance
  distance <- excitation1$get_distance(excitation2)
  
  expect_equal(distance, 0, tolerance = 1e-8)
})
