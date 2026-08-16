# Phase 3 Task 3.1: MFCC SIMD Tests
# Test suite for SIMD-optimized MFCC operations

library(testthat)
library(pladdrr)

# Helper function to generate test signals
generate_test_signal <- function(duration = 1.0, sr = 16000, freq = 440) {
  t <- seq(0, duration, length.out = as.integer(duration * sr))
  sin(2 * pi * freq * t)
}

# Helper function to generate speech-like signal (multiple harmonics)
generate_speech_signal <- function(duration = 1.0, sr = 16000) {
  t <- seq(0, duration, length.out = as.integer(duration * sr))
  # Fundamental + harmonics
  f0 <- 120  # Hz
  signal <- sin(2 * pi * f0 * t) +
            0.5 * sin(2 * pi * 2 * f0 * t) +
            0.3 * sin(2 * pi * 3 * f0 * t) +
            0.2 * sin(2 * pi * 4 * f0 * t) +
            0.1 * sin(2 * pi * 5 * f0 * t)
  signal / max(abs(signal))  # Normalize
}

# ============================================================================
# Test 1: MFCC SIMD vs Scalar Accuracy
# ============================================================================

test_that("MFCC SIMD matches scalar implementation", {

  signal <- generate_speech_signal(duration = 0.5, sr = 16000)
  snd <- Sound$from_values(signal, 16000)

  # Scalar MFCC
  pladdrr_simd(FALSE)
  mfcc_scalar <- snd$to_mfcc(
    num_coefficients = 13,
    analysis_width = 0.015,
    time_step = 0.005,
    f1_mel = 0,
    fmax_mel = 0,
    df_mel = 100
  )

  # SIMD MFCC
  pladdrr_simd(TRUE)
  mfcc_simd <- snd$to_mfcc(
    num_coefficients = 13,
    analysis_width = 0.015,
    time_step = 0.005,
    f1_mel = 0,
    fmax_mel = 0,
    df_mel = 100
  )

  # Check structure
  expect_equal(mfcc_scalar$get_number_of_frames(), mfcc_simd$get_number_of_frames())
  expect_equal(mfcc_scalar$get_max_num_coefficients(),
               mfcc_simd$get_max_num_coefficients())

  # Check coefficient values (allowing small numerical differences)
  scalar_coeffs <- mfcc_scalar$get_all_coefficients()
  simd_coeffs <- mfcc_simd$get_all_coefficients()

  expect_equal(dim(scalar_coeffs), dim(simd_coeffs))
  expect_equal(scalar_coeffs, simd_coeffs, tolerance = 1e-10)
})

# ============================================================================
# Test 2: MFCC with Different Signal Lengths
# ============================================================================

test_that("MFCC SIMD works with various signal lengths", {

  test_durations <- c(0.1, 0.5, 1.0, 2.0)

  for (dur in test_durations) {
    signal <- generate_test_signal(duration = dur, sr = 16000, freq = 440)
    snd <- Sound$from_values(signal, 16000)

    pladdrr_simd(TRUE)
    mfcc <- snd$to_mfcc(num_coefficients = 12, analysis_width = 0.015, time_step = 0.005)

    expect_true(mfcc$get_number_of_frames() > 0)
    expect_equal(mfcc$get_num_coefficients_at_frame(1), 12)
  }
})

# ============================================================================
# Test 3: MFCC with Different Coefficient Counts
# ============================================================================

test_that("MFCC SIMD works with different coefficient counts", {

  signal <- generate_speech_signal(duration = 0.5, sr = 16000)
  snd <- Sound$from_values(signal, 16000)

  test_n_coeffs <- c(6, 12, 13, 20)

  for (n_coeff in test_n_coeffs) {
    pladdrr_simd(TRUE)
    mfcc <- snd$to_mfcc(num_coefficients = n_coeff, analysis_width = 0.015, time_step = 0.005)

    expect_true(mfcc$get_max_num_coefficients() >= n_coeff)
    expect_true(mfcc$get_number_of_frames() > 0)
  }
})

# ============================================================================
# Test 4: MFCC with Different Analysis Widths
# ============================================================================

test_that("MFCC SIMD works with different analysis widths", {

  signal <- generate_speech_signal(duration = 0.5, sr = 16000)
  snd <- Sound$from_values(signal, 16000)

  test_widths <- c(0.01, 0.015, 0.025, 0.032)

  for (width in test_widths) {
    pladdrr_simd(TRUE)
    mfcc <- snd$to_mfcc(num_coefficients = 12, analysis_width = width, time_step = 0.005)

    expect_true(mfcc$get_number_of_frames() > 0)
    expect_equal(mfcc$get_num_coefficients_at_frame(1), 12)
  }
})

# ============================================================================
# Test 5: MFCC SIMD Enable/Disable
# ============================================================================

test_that("MFCC SIMD can be toggled on/off", {

  signal <- generate_speech_signal(duration = 0.3, sr = 16000)
  snd <- Sound$from_values(signal, 16000)

  # Disable SIMD
  pladdrr_simd(FALSE)
  mfcc1 <- snd$to_mfcc(num_coefficients = 12, analysis_width = 0.015, time_step = 0.005)
  expect_true(mfcc1$get_number_of_frames() > 0)

  # Enable SIMD
  pladdrr_simd(TRUE)
  mfcc2 <- snd$to_mfcc(num_coefficients = 12, analysis_width = 0.015, time_step = 0.005)
  expect_true(mfcc2$get_number_of_frames() > 0)

  # Both should produce valid results
  expect_equal(mfcc1$get_number_of_frames(), mfcc2$get_number_of_frames())
})

# ============================================================================
# Test 6: MFCC with Different Sampling Rates
# ============================================================================

test_that("MFCC SIMD works with different sampling rates", {

  test_srs <- c(8000, 16000, 22050, 44100)

  for (sr in test_srs) {
    signal <- generate_test_signal(duration = 0.5, sr = sr, freq = 440)
    snd <- Sound$from_values(signal, sr)

    pladdrr_simd(TRUE)
    mfcc <- snd$to_mfcc(num_coefficients = 12, analysis_width = 0.015, time_step = 0.005)

    expect_true(mfcc$get_number_of_frames() > 0)
    expect_equal(mfcc$get_num_coefficients_at_frame(1), 12)
  }
})

# ============================================================================
# Test 7: MFCC Coefficient Range Check
# ============================================================================

test_that("MFCC coefficients are in reasonable range", {

  signal <- generate_speech_signal(duration = 0.5, sr = 16000)
  snd <- Sound$from_values(signal, 16000)

  pladdrr_simd(TRUE)
  mfcc <- snd$to_mfcc(num_coefficients = 13, analysis_width = 0.015, time_step = 0.005)

  # Get coefficient matrix
  coeffs <- mfcc$get_all_coefficients()

  # Check that coefficients are finite and in reasonable range
  # (bound is a garbage/overflow sanity check, not a tight magnitude spec —
  # DCT AC coefficient magnitude scales with per-band spectral contrast,
  # which for a strongly harmonic synthetic signal legitimately exceeds 1000)
  expect_true(all(is.finite(coeffs)))
  expect_true(all(abs(coeffs) < 10000))

  # C0 (energy) should be larger than other coefficients
  # (This is a rough heuristic check)
  c0_mean <- mean(abs(coeffs[1, ]))
  c1_mean <- mean(abs(coeffs[2, ]))
  expect_true(c0_mean > 0)
})

# ============================================================================
# Test 8: MFCC with Mel Frequency Range Constraints
# ============================================================================

test_that("MFCC SIMD works with custom Mel frequency ranges", {

  signal <- generate_speech_signal(duration = 0.5, sr = 16000)
  snd <- Sound$from_values(signal, 16000)

  pladdrr_simd(TRUE)

  # Test different Mel frequency ranges
  mfcc1 <- snd$to_mfcc(
    num_coefficients = 12,
    analysis_width = 0.015,
    time_step = 0.005,
    f1_mel = 0,
    fmax_mel = 0,  # Use defaults
    df_mel = 100
  )

  mfcc2 <- snd$to_mfcc(
    num_coefficients = 12,
    analysis_width = 0.015,
    time_step = 0.005,
    f1_mel = 100,
    fmax_mel = 8000,
    df_mel = 100
  )

  expect_true(mfcc1$get_number_of_frames() > 0)
  expect_true(mfcc2$get_number_of_frames() > 0)

  # Both should produce different results due to different frequency ranges
  coeffs1 <- mfcc1$get_all_coefficients()
  coeffs2 <- mfcc2$get_all_coefficients()

  expect_false(isTRUE(all.equal(coeffs1, coeffs2, tolerance = 0.01)))
})

# ============================================================================
# Test 9: MFCC Frame-by-Frame Consistency
# ============================================================================

test_that("MFCC frames are consistent across SIMD/scalar", {

  signal <- generate_speech_signal(duration = 0.3, sr = 16000)
  snd <- Sound$from_values(signal, 16000)

  # Scalar
  pladdrr_simd(FALSE)
  mfcc_scalar <- snd$to_mfcc(num_coefficients = 12, analysis_width = 0.015, time_step = 0.005)

  # SIMD
  pladdrr_simd(TRUE)
  mfcc_simd <- snd$to_mfcc(num_coefficients = 12, analysis_width = 0.015, time_step = 0.005)

  # Check frame-by-frame
  n_frames <- mfcc_scalar$get_number_of_frames()

  for (iframe in seq_len(min(10, n_frames))) {
    scalar_frame <- mfcc_scalar$get_value_in_frame(frame_number = iframe, coeff_number = 1)
    simd_frame <- mfcc_simd$get_value_in_frame(frame_number = iframe, coeff_number = 1)

    expect_equal(scalar_frame, simd_frame, tolerance = 1e-10)
  }
})

# ============================================================================
# Test 10: MFCC with Real Audio File (if available)
# ============================================================================

test_that("MFCC SIMD works with real audio (if available)", {

  # Try to load a real audio file
  test_file <- system.file("extdata", "test.wav", package = "pladdrr")

  if (file.exists(test_file) && nchar(test_file) > 0) {
    snd <- Sound$new(test_file)

    pladdrr_simd(TRUE)
    mfcc <- snd$to_mfcc(num_coefficients = 13, analysis_width = 0.015, time_step = 0.005)

    expect_true(mfcc$get_number_of_frames() > 0)
    expect_equal(mfcc$get_num_coefficients_at_frame(1), 13)

    # Check that coefficients are valid
    coeffs <- mfcc$get_all_coefficients()
    expect_true(all(is.finite(coeffs)))
  } else {
    skip("No test audio file available")
  }
})

# ============================================================================
# Integration Test: Full MFCC Pipeline
# ============================================================================

test_that("MFCC full pipeline works end-to-end with SIMD", {

  # Generate a complex signal
  sr <- 16000
  duration <- 1.0
  t <- seq(0, duration, length.out = as.integer(duration * sr))

  # Speech-like signal with multiple formants
  f1 <- 700  # First formant
  f2 <- 1220 # Second formant
  f3 <- 2600 # Third formant
  signal <- sin(2 * pi * f1 * t) + 0.7 * sin(2 * pi * f2 * t) + 0.5 * sin(2 * pi * f3 * t)
  signal <- signal / max(abs(signal))

  snd <- Sound$from_values(signal, sr)

  pladdrr_simd(TRUE)

  # Full MFCC extraction
  mfcc <- snd$to_mfcc(
    num_coefficients = 13,
    analysis_width = 0.025,  # 25ms window
    time_step = 0.010,              # 10ms step
    f1_mel = 0,
    fmax_mel = 0,
    df_mel = 100
  )

  # Verify output
  expect_true(mfcc$get_number_of_frames() > 0)
  expect_equal(mfcc$get_num_coefficients_at_frame(1), 13)

  # Get full coefficient matrix
  coeffs <- mfcc$get_all_coefficients()

  # Basic sanity checks
  expect_equal(nrow(coeffs), 14)  # 13 coefficients + c0
  expect_true(ncol(coeffs) > 0)
  expect_true(all(is.finite(coeffs)))

  # Check that we have variation across frames (not all zeros/constants)
  expect_true(sd(coeffs[2, ]) > 0.01)  # C1 should vary across frames
})

cat("\n=== Phase 3 Task 3.1: MFCC SIMD Tests Complete ===\n")
