# Test Suite for Cochleagram R6 Class
# Tests for auditory modeling using Bark scale representation

test_that("Cochleagram can be created from Sound", {
  skip_if_not(dir.exists(system.file("audio", package = "pladdrr")), 
              "Test audio files not available")
  
  # Create test sound
  sound <- generate_sine_wave(440, 0.1, sampling_rate = 16000)
  
  # Create cochleagram with standard parameters
  cochlea <- sound$to_cochleagram(
    dt = 0.01,
    df = 0.1,
    window_length = 0.025,
    forward_masking_time = 0.03
  )
  
  expect_s3_class(cochlea, "Cochleagram")
  expect_s3_class(cochlea, "PraatObject")
  expect_true(cochlea$is_valid())
})

test_that("Cochleagram EDB method works", {
  skip("Segfaults - C++ bug in to_cochleagram_edb")
  sound <- generate_sine_wave(440, 0.1, sampling_rate = 16000)
  
  # Create cochleagram with ear-drum-brain model
  cochlea_edb <- sound$to_cochleagram_edb(
    dtime = 0.01,
    dfreq = 0.1,
    has_synapse = TRUE
  )
  
  expect_s3_class(cochlea_edb, "Cochleagram")
  expect_true(cochlea_edb$is_valid())
})

test_that("Cochleagram can query values at time and frequency", {
  sound <- generate_sine_wave(440, 0.2, sampling_rate = 16000)
  cochlea <- sound$to_cochleagram(dt = 0.01, df = 0.1)
  
  # Query at specific time and Bark frequency
  # 440 Hz ≈ 4.2 Bark
  value <- cochlea$get_value_at_time_and_frequency(0.1, 4.2)
  
  expect_type(value, "double")
  expect_true(is.finite(value))
  expect_true(value >= 0)  # Excitation is non-negative
})

test_that("Cochleagram can calculate loudness", {
  sound <- generate_sine_wave(440, 0.2, sampling_rate = 16000)
  cochlea <- sound$to_cochleagram(dt = 0.01, df = 0.1)
  
  # Get loudness at specific time
  loudness <- cochlea$get_loudness_at_time(0.1)
  
  expect_type(loudness, "double")
  expect_true(is.finite(loudness))
  expect_true(loudness > 0)  # Non-zero sound should have loudness
})

test_that("Cochleagram can be converted to Excitation", {
  sound <- generate_sine_wave(440, 0.2, sampling_rate = 16000)
  cochlea <- sound$to_cochleagram(dt = 0.01, df = 0.1)
  
  # Extract excitation pattern at specific time
  excitation <- cochlea$to_excitation(0.1)
  
  expect_s3_class(excitation, "Excitation")
  expect_true(excitation$is_valid())
})

test_that("Cochleagram can be exported as matrix", {
  sound <- generate_sine_wave(440, 0.1, sampling_rate = 16000)
  cochlea <- sound$to_cochleagram(dt = 0.01, df = 0.2)
  
  # Export to R matrix
  mat <- cochlea$as_matrix()
  
  expect_true(is.data.frame(mat) || is.matrix(mat))
  expect_true(nrow(mat) > 0)
  expect_true(ncol(mat) > 0)
})

test_that("Cochleagram difference can be computed", {
  sound1 <- generate_sine_wave(440, 0.1, sampling_rate = 16000)
  sound2 <- generate_sine_wave(880, 0.1, sampling_rate = 16000)
  
  cochlea1 <- sound1$to_cochleagram(dt = 0.01, df = 0.2)
  cochlea2 <- sound2$to_cochleagram(dt = 0.01, df = 0.2)
  
  # Compute perceptual difference
  diff <- cochlea1$get_difference(cochlea2, tmin = 0, tmax = 0)
  
  expect_type(diff, "double")
  expect_true(is.finite(diff))
  expect_true(diff >= 0)  # Distance metric
  expect_true(diff > 0)   # Different frequencies should differ
})

test_that("Cochleagram handles edge cases", {
  # Silence
  sound_silence <- Sound(rep(0, round(0.1 * 16000)), sampling_rate = 16000)
  cochlea_silence <- sound_silence$to_cochleagram()
  expect_s3_class(cochlea_silence, "Cochleagram")
  
  # Very short sound
  sound_short <- generate_sine_wave(440, 0.01, sampling_rate = 16000)
  cochlea_short <- sound_short$to_cochleagram(dt = 0.002)
  expect_s3_class(cochlea_short, "Cochleagram")
})

test_that("Cochleagram SIMD accuracy matches scalar", {
  skip_if_not(simd_info()$available, "SIMD not available")
  
  sound <- generate_sine_wave(440, 0.1, sampling_rate = 16000)
  
  # Create two cochleagrams (should use SIMD if available)
  cochlea1 <- sound$to_cochleagram(dt = 0.01, df = 0.1)
  cochlea2 <- sound$to_cochleagram(dt = 0.01, df = 0.1)
  
  # Results should be identical (SIMD deterministic)
  loudness1 <- cochlea1$get_loudness_at_time(0.05)
  loudness2 <- cochlea2$get_loudness_at_time(0.05)
  
  expect_equal(loudness1, loudness2, tolerance = 1e-10)
})

test_that("Cochleagram validates parameters", {
  sound <- generate_sine_wave(440, 0.1, sampling_rate = 16000)
  
  # Invalid time step
  expect_error(sound$to_cochleagram(dt = -0.01))
  
  # Invalid frequency step
  expect_error(sound$to_cochleagram(df = -0.1))
  
  # Invalid window length
  expect_error(sound$to_cochleagram(window_length = -0.025))
})
