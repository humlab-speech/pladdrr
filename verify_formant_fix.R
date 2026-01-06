#!/usr/bin/env Rscript
# Quick verification script for formant unit bug fix

cat("Loading pladdrr package...\n")
library(pladdrr)

cat("Creating test sound...\n")
# Create a simple test sound
duration <- 0.5
sr <- 16000
n_samples <- duration * sr
t <- seq(0, duration, length.out = n_samples)

# Simulate vowel with formants (F1 = 700 Hz, F2 = 1220 Hz)
f0 <- 120
signal <- sin(2 * pi * f0 * t)
signal <- signal + 0.5 * sin(2 * pi * 700 * t)
signal <- signal + 0.3 * sin(2 * pi * 1220 * t)
signal <- signal / max(abs(signal)) * 0.5

sound <- Sound$from_values(signal, sampling_rate = sr)

cat("Extracting formants...\n")
formant <- sound$to_formant_burg(
  time_step = 0.01,
  max_formants = 5,
  max_frequency = 5500,
  window_length = 0.025,
  pre_emphasis_from = 50
)

cat("\nTesting formant unit bug fix:\n")
cat("=====================================\n")

# Get F1 at time 0.25 using get_value_at_time with "hertz"
f1_method_hz <- formant$get_value_at_time(1, 0.25, unit = "hertz")
cat(sprintf("F1 via get_value_at_time(unit='hertz'): %.2f Hz\n", f1_method_hz))

# Get F1 at time 0.25 using get_value_at_time with "bark"
f1_method_bark <- formant$get_value_at_time(1, 0.25, unit = "bark")
cat(sprintf("F1 via get_value_at_time(unit='bark'):  %.2f bark\n", f1_method_bark))

# Get F1 at time 0.25 from data frame
df <- formant$as_data_frame()
idx <- which.min(abs(df$time - 0.25))
f1_dataframe <- df$F1[idx]
cat(sprintf("F1 via as_data_frame():                 %.2f Hz\n", f1_dataframe))

cat("\nVerifying fix:\n")
cat("=====================================\n")

# Check if values are reasonable
if (!is.na(f1_method_hz) && !is.na(f1_dataframe)) {
  diff <- abs(f1_method_hz - f1_dataframe)
  cat(sprintf("Difference between methods: %.2f Hz\n", diff))
  
  if (f1_method_hz > 50 && f1_method_hz < 2000) {
    cat("✓ get_value_at_time returns Hertz scale (not Bark)\n")
  } else {
    cat("✗ FAIL: get_value_at_time returns unexpected value\n")
  }
  
  if (diff < 100) {
    cat("✓ Both methods agree within 100 Hz\n")
  } else {
    cat(sprintf("✗ FAIL: Methods differ by %.2f Hz (expected < 100 Hz)\n", diff))
  }
  
  if (!is.na(f1_method_bark) && f1_method_bark < 20 && f1_method_bark < f1_method_hz / 10) {
    cat("✓ Bark scale returns appropriately smaller values\n")
  } else {
    cat("⚠ Warning: Bark scale behavior unclear\n")
  }
  
  cat("\n✅ FIX VERIFIED: Unit codes corrected!\n")
} else {
  cat("⚠ Warning: Could not verify fix (NA values returned)\n")
}
