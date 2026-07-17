# Phase 2 SIMD Integration Tests
# Tasks 2.1-2.3: Spectrogram, Pre-emphasis, Pitch Filter
# Created: 2026-01-22

library(testthat)
library(pladdrr)

# Test helper: Generate test signal
generate_test_signal <- function(duration = 1.0, sr = 16000, freqs = c(200, 400, 800)) {
  t <- seq(0, duration, length.out = sr * duration)
  signal <- numeric(length(t))
  for (f in freqs) {
    signal <- signal + sin(2 * pi * f * t)
  }
  signal / length(freqs)  # Normalize
}

# ============================================================================
# Task 2.1: Spectrogram SIMD Tests
# ============================================================================

test_that("Spectrogram SIMD matches scalar (Gaussian window)", {
  signal <- generate_test_signal(duration = 0.5, sr = 16000)
  snd <- Sound$from_values(signal, 16000)

  # Scalar
  options(speaker.use_simd = FALSE)
  spec_scalar <- snd$to_spectrogram(
    window_length = 0.005,
    time_step = 0.002,
    window_shape = "Gaussian"
  )

  # SIMD
  options(speaker.use_simd = TRUE)
  spec_simd <- snd$to_spectrogram(
    window_length = 0.005,
    time_step = 0.002,
    window_shape = "Gaussian"
  )

  # Compare
  scalar_mat <- spec_scalar$as_matrix()
  simd_mat <- spec_simd$as_matrix()

  expect_equal(dim(scalar_mat), dim(simd_mat))
  expect_equal(simd_mat, scalar_mat, tolerance = 1e-10)
})

test_that("Spectrogram SIMD matches scalar (Hamming window)", {
  signal <- generate_test_signal(duration = 0.5, sr = 16000)
  snd <- Sound$from_values(signal, 16000)

  # Scalar
  options(speaker.use_simd = FALSE)
  spec_scalar <- snd$to_spectrogram(window_shape = "Hamming")

  # SIMD
  options(speaker.use_simd = TRUE)
  spec_simd <- snd$to_spectrogram(window_shape = "Hamming")

  scalar_mat <- spec_scalar$as_matrix()
  simd_mat <- spec_simd$as_matrix()

  expect_equal(simd_mat, scalar_mat, tolerance = 1e-10)
})

test_that("Spectrogram SIMD matches scalar (Hanning window)", {
  signal <- generate_test_signal(duration = 0.5, sr = 16000)
  snd <- Sound$from_values(signal, 16000)

  # Scalar
  options(speaker.use_simd = FALSE)
  spec_scalar <- snd$to_spectrogram(window_shape = "Hanning")

  # SIMD
  options(speaker.use_simd = TRUE)
  spec_simd <- snd$to_spectrogram(window_shape = "Hanning")

  scalar_mat <- spec_scalar$as_matrix()
  simd_mat <- spec_simd$as_matrix()

  expect_equal(simd_mat, scalar_mat, tolerance = 1e-10)
})

test_that("Spectrogram SIMD handles different signal lengths", {
  for (n_samples in c(1000, 5000, 10000, 48000)) {
    signal <- rnorm(n_samples)
    snd <- Sound$from_values(signal, 16000)

    options(speaker.use_simd = FALSE)
    spec_scalar <- snd$to_spectrogram()

    options(speaker.use_simd = TRUE)
    spec_simd <- snd$to_spectrogram()

    expect_equal(
      spec_simd$as_matrix(),
      spec_scalar$as_matrix(),
      tolerance = 1e-10,
      info = sprintf("Failed for %d samples", n_samples)
    )
  }
})

test_that("Spectrogram SIMD handles stereo signals", {
  skip("multichannel Sound construction is not supported by the current API")

  signal <- generate_test_signal(duration = 0.5, sr = 16000)
  # Create stereo by duplicating with slight variation
  stereo <- cbind(signal, signal * 0.9)
  snd <- Sound$from_values(stereo, 16000)

  options(speaker.use_simd = FALSE)
  spec_scalar <- snd$to_spectrogram()

  options(speaker.use_simd = TRUE)
  spec_simd <- snd$to_spectrogram()

  expect_equal(spec_simd$as_matrix(), spec_scalar$as_matrix(), tolerance = 1e-10)
})

# ============================================================================
# Task 2.2: Pre-emphasis Filter SIMD Tests
# ============================================================================

test_that("Pre-emphasis SIMD matches scalar", {
  signal <- generate_test_signal(duration = 0.5, sr = 16000)

  # Create two independent Sound objects
  snd_scalar <- Sound$from_values(signal, 16000)
  snd_simd <- Sound$from_values(signal, 16000)

  # Apply pre-emphasis
  options(speaker.use_simd = FALSE)
  snd_scalar$pre_emphasize(50)

  options(speaker.use_simd = TRUE)
  snd_simd$pre_emphasize(50)

  # Compare
  result_scalar <- as.vector(snd_scalar$as_matrix()[1, ])
  result_simd <- as.vector(snd_simd$as_matrix()[1, ])

  expect_equal(result_simd, result_scalar, tolerance = 1e-12)
})

test_that("Pre-emphasis SIMD is exact (zero error)", {
  signal <- generate_test_signal(duration = 0.5, sr = 16000)
  snd <- Sound$from_values(signal, 16000)

  # Manual calculation
  emphasis_factor <- exp(-2 * pi * 50 / 16000)
  expected <- signal
  for (i in length(expected):2) {
    expected[i] <- expected[i] - emphasis_factor * expected[i - 1]
  }

  # SIMD version
  options(speaker.use_simd = TRUE)
  snd$pre_emphasize(50)
  result <- as.vector(snd$as_matrix()[1, ])

  # Should be exact
  expect_equal(result, expected, tolerance = 1e-15)
})

test_that("Pre-emphasis + de-emphasis round-trip", {
  signal <- generate_test_signal(duration = 0.5, sr = 16000)
  snd <- Sound$from_values(signal, 16000)

  options(speaker.use_simd = TRUE)
  snd$pre_emphasize(50)
  snd$de_emphasize(50)

  result <- as.vector(snd$as_matrix()[1, ])

  # Should recover original (within floating-point precision)
  expect_equal(result, signal, tolerance = 1e-9)
})

test_that("Pre-emphasis SIMD handles different cutoff frequencies", {
  signal <- generate_test_signal(duration = 0.5, sr = 16000)

  for (cutoff in c(30, 50, 100, 200)) {
    snd_scalar <- Sound$from_values(signal, 16000)
    snd_simd <- Sound$from_values(signal, 16000)

    options(speaker.use_simd = FALSE)
    snd_scalar$pre_emphasize(cutoff)

    options(speaker.use_simd = TRUE)
    snd_simd$pre_emphasize(cutoff)

    expect_equal(
      as.vector(snd_simd$as_matrix()[1, ]),
      as.vector(snd_scalar$as_matrix()[1, ]),
      tolerance = 1e-12,
      info = sprintf("Failed for cutoff %d Hz", cutoff)
    )
  }
})

test_that("Pre-emphasis SIMD handles various signal lengths", {
  for (n in c(100, 1000, 10000, 48000)) {
    signal <- rnorm(n)
    snd <- Sound$from_values(signal, 16000)

    # Manual calculation
    emphasis_factor <- exp(-2 * pi * 50 / 16000)
    expected <- signal
    for (i in length(expected):2) {
      expected[i] <- expected[i] - emphasis_factor * expected[i - 1]
    }

    options(speaker.use_simd = TRUE)
    snd$pre_emphasize(50)
    result <- as.vector(snd$as_matrix()[1, ])

    expect_equal(
      result,
      expected,
      tolerance = 1e-15,
      info = sprintf("Failed for %d samples", n)
    )
  }
})

# ============================================================================
# Task 2.3: Pitch Filter SIMD (Internal C++ optimization)
# ============================================================================

# Note: Filtered pitch methods not exposed to R module
# These are internal C++ optimizations in Sound_to_Pitch_filteredAc/Cc
# Testing via standard pitch extraction to ensure no regressions

test_that("Pitch extraction works with SIMD enabled", {
  signal <- generate_test_signal(duration = 1.0, sr = 16000, freqs = c(200))
  snd <- Sound$from_values(signal, 16000)

  options(speaker.use_simd = TRUE)
  pitch <- snd$to_pitch(pitch_floor = 75, pitch_ceiling = 600)

  # Should detect ~200 Hz
  mean_pitch <- pitch$get_mean(from = 0, to = 1, unit = "Hertz")
  expect_true(!is.na(mean_pitch))
  expect_true(abs(mean_pitch - 200) < 10)  # Within 10 Hz
})

test_that("SIMD does not break pitch extraction", {
  signal <- generate_test_signal(duration = 1.0, sr = 16000)
  snd <- Sound$from_values(signal, 16000)

  options(speaker.use_simd = FALSE)
  pitch_scalar <- snd$to_pitch()

  options(speaker.use_simd = TRUE)
  pitch_simd <- snd$to_pitch()

  # Should produce similar results
  scalar_frames <- pitch_scalar$get_values_vector()
  simd_frames <- pitch_simd$get_values_vector()

  # Compare non-NaN values
  valid_idx <- !is.nan(scalar_frames) & !is.nan(simd_frames)
  if (sum(valid_idx) > 0) {
    expect_equal(
      simd_frames[valid_idx],
      scalar_frames[valid_idx],
      tolerance = 0.5  # Within 0.5 Hz
    )
  }
})

# ============================================================================
# Phase 2 Integration Tests
# ============================================================================

test_that("Phase 2 SIMD can be toggled on/off", {
  signal <- generate_test_signal(duration = 0.5, sr = 16000)
  snd <- Sound$from_values(signal, 16000)

  # Disable
  options(speaker.use_simd = FALSE)
  spec1 <- snd$to_spectrogram()

  # Enable
  options(speaker.use_simd = TRUE)
  spec2 <- snd$to_spectrogram()

  # Disable again
  options(speaker.use_simd = FALSE)
  spec3 <- snd$to_spectrogram()

  # All should match
  expect_equal(spec2$as_matrix(), spec1$as_matrix(), tolerance = 1e-10)
  expect_equal(spec3$as_matrix(), spec1$as_matrix(), tolerance = 1e-10)
})

test_that("Phase 2 operations work in sequence", {
  signal <- generate_test_signal(duration = 1.0, sr = 16000)
  snd <- Sound$from_values(signal, 16000)

  options(speaker.use_simd = TRUE)

  # Apply Phase 2 operations in sequence
  snd$pre_emphasize(50)
  spec <- snd$to_spectrogram()
  pitch <- snd$to_pitch()

  # All should complete without error
  expect_true(spec$get_number_of_time_bins() > 0)
  expect_true(pitch$get_number_of_frames() > 0)
})

# Cleanup
options(speaker.use_simd = TRUE)
