#!/usr/bin/env Rscript
# Phase 2 Task 2.3: Pitch Filter SIMD Accuracy Test
# Created: 2026-01-22
# Tests numerical accuracy of SIMD filtered pitch extraction vs scalar

library(pladdrr)

cat("Pitch Filter SIMD Accuracy Test\n")
cat("================================\n\n")

# Test parameters
sampling_rate <- 16000  # Hz
duration <- 0.5  # seconds
pitch_floor <- 75  # Hz
pitch_ceiling <- 600  # Hz

# Track results
all_passed <- TRUE

# Create test signal: combination of harmonics
t <- seq(0, duration, length.out = sampling_rate * duration)
# Fundamental at 200 Hz with harmonics
signal <- sin(2 * pi * 200 * t) +
          0.5 * sin(2 * pi * 400 * t) +
          0.3 * sin(2 * pi * 600 * t) +
          0.2 * sin(2 * pi * 800 * t)

cat(sprintf("Test signal: %.1f s duration, %d Hz sampling rate\n", duration, sampling_rate))
cat(sprintf("Pitch range: %d-%d Hz\n\n", pitch_floor, pitch_ceiling))

# Create Sound object
snd <- Sound$from_values(signal, sampling_rate)

# Test filtered AC method
cat("Testing Sound_to_Pitch_filteredAc:\n")

# Force scalar (disable SIMD)
options(speaker.use_simd = FALSE)
pitch_scalar <- snd$to_pitch_filtered_ac(
  time_step = 0.01,
  pitch_floor = pitch_floor,
  pitch_ceiling = pitch_ceiling
)
pitch_scalar_values <- pitch_scalar$get_value_in_frames()

# Force SIMD
options(speaker.use_simd = TRUE)
pitch_simd <- snd$to_pitch_filtered_ac(
  time_step = 0.01,
  pitch_floor = pitch_floor,
  pitch_ceiling = pitch_ceiling
)
pitch_simd_values <- pitch_simd$get_value_in_frames()

# Compare
diff_ac <- abs(pitch_simd_values - pitch_scalar_values)
# Ignore NaN differences (both should be NaN for unvoiced frames)
diff_ac <- diff_ac[!is.nan(diff_ac)]

if (length(diff_ac) == 0) {
  cat("  Warning: All frames unvoiced\n")
} else {
  max_diff_ac <- max(diff_ac, na.rm = TRUE)
  mean_diff_ac <- mean(diff_ac, na.rm = TRUE)

  cat(sprintf("  Max difference: %.2e Hz\n", max_diff_ac))
  cat(sprintf("  Mean difference: %.2e Hz\n", mean_diff_ac))

  if (max_diff_ac > 1e-6) {
    cat(sprintf("  FAILED: Difference exceeds threshold (1e-6 Hz)\n"))
    all_passed <- FALSE
  } else {
    cat(sprintf("  PASSED\n"))
  }
}

cat("\n")

# Test filtered CC method
cat("Testing Sound_to_Pitch_filteredCc:\n")

# Force scalar
options(speaker.use_simd = FALSE)
pitch_scalar_cc <- snd$to_pitch_filtered_cc(
  time_step = 0.01,
  pitch_floor = pitch_floor,
  pitch_ceiling = pitch_ceiling
)
pitch_scalar_cc_values <- pitch_scalar_cc$get_value_in_frames()

# Force SIMD
options(speaker.use_simd = TRUE)
pitch_simd_cc <- snd$to_pitch_filtered_cc(
  time_step = 0.01,
  pitch_floor = pitch_floor,
  pitch_ceiling = pitch_ceiling
)
pitch_simd_cc_values <- pitch_simd_cc$get_value_in_frames()

# Compare
diff_cc <- abs(pitch_simd_cc_values - pitch_scalar_cc_values)
diff_cc <- diff_cc[!is.nan(diff_cc)]

if (length(diff_cc) == 0) {
  cat("  Warning: All frames unvoiced\n")
} else {
  max_diff_cc <- max(diff_cc, na.rm = TRUE)
  mean_diff_cc <- mean(diff_cc, na.rm = TRUE)

  cat(sprintf("  Max difference: %.2e Hz\n", max_diff_cc))
  cat(sprintf("  Mean difference: %.2e Hz\n", mean_diff_cc))

  if (max_diff_cc > 1e-6) {
    cat(sprintf("  FAILED: Difference exceeds threshold (1e-6 Hz)\n"))
    all_passed <- FALSE
  } else {
    cat(sprintf("  PASSED\n"))
  }
}

cat("\nSummary\n")
cat("=======\n")

if (all_passed) {
  cat("\nAll tests PASSED ✓\n")
  cat("SIMD filtered pitch extraction matches scalar implementation.\n")
  quit(status = 0)
} else {
  cat("\nSome tests FAILED ✗\n")
  quit(status = 1)
}
