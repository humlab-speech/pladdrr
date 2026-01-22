#!/usr/bin/env Rscript
# Phase 2 Task 2.2: Pre-emphasis Filter SIMD Accuracy Test
# Created: 2026-01-22
# Tests numerical accuracy of SIMD pre-emphasis vs scalar implementation

library(pladdrr)

cat("Pre-emphasis SIMD Accuracy Test\n")
cat("================================\n\n")

# Test parameters
test_sizes <- c(100, 1000, 10000, 48000)  # Various signal sizes
cutoff_freq <- 50  # Hz
sampling_rate <- 16000  # Hz

# Track results
all_passed <- TRUE
max_error_preemph <- 0
max_error_deemph <- 0

for (n in test_sizes) {
  cat(sprintf("Testing signal size: %d samples\n", n))

  # Generate test signal: sum of sinusoids
  t <- seq(0, (n-1) / sampling_rate, length.out = n)
  signal <- sin(2 * pi * 100 * t) +
            0.5 * sin(2 * pi * 300 * t) +
            0.3 * sin(2 * pi * 800 * t)

  # Create Sound object
  snd <- Sound$from_values(signal, sampling_rate)

  # Test 1: Pre-emphasis
  # SIMD version (default with HAVE_XSIMD)
  snd$pre_emphasize(cutoff_freq)
  simd_result <- as.vector(snd$as_matrix()[1, ])

  # Scalar version (manually computed)
  emphasis_factor <- exp(-2 * pi * cutoff_freq / sampling_rate)
  scalar_result <- signal
  for (i in length(scalar_result):2) {
    scalar_result[i] <- scalar_result[i] - emphasis_factor * scalar_result[i - 1]
  }

  # Compare
  diff_preemph <- abs(simd_result - scalar_result)
  max_diff <- max(diff_preemph)
  max_error_preemph <- max(max_error_preemph, max_diff)

  cat(sprintf("  Pre-emphasis max difference: %.2e\n", max_diff))

  if (max_diff > 1e-10) {
    cat(sprintf("  FAILED: Difference exceeds threshold (1e-10)\n"))
    all_passed <- FALSE
  } else {
    cat(sprintf("  PASSED\n"))
  }

  # Test 2: De-emphasis (inverse operation)
  snd$de_emphasize(cutoff_freq)
  deemph_result <- as.vector(snd$as_matrix()[1, ])

  # Should recover original signal
  diff_roundtrip <- abs(deemph_result - signal)
  max_diff_roundtrip <- max(diff_roundtrip)
  max_error_deemph <- max(max_error_deemph, max_diff_roundtrip)

  cat(sprintf("  Round-trip max difference: %.2e\n", max_diff_roundtrip))

  if (max_diff_roundtrip > 1e-9) {
    cat(sprintf("  FAILED: Round-trip error exceeds threshold (1e-9)\n"))
    all_passed <- FALSE
  } else {
    cat(sprintf("  PASSED\n"))
  }

  cat("\n")
}

cat("Summary\n")
cat("=======\n")
cat(sprintf("Maximum pre-emphasis error: %.2e\n", max_error_preemph))
cat(sprintf("Maximum de-emphasis error:  %.2e\n", max_error_deemph))

if (all_passed) {
  cat("\nAll tests PASSED ✓\n")
  quit(status = 0)
} else {
  cat("\nSome tests FAILED ✗\n")
  quit(status = 1)
}
