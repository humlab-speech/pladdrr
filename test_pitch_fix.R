#!/usr/bin/env Rscript
# Test script for pitch detection type mismatch fix (v1.2.1)

library(pladdrr)

cat("=== Testing Pitch Detection Fix ===\n\n")

# Load test file
snd <- Sound$new("inst/extdata/bell.wav")
cat("Loaded:", snd$get_total_duration(), "sec,", snd$get_sampling_frequency(), "Hz\n\n")

# Test pitch detection with standard parameters
cat("Testing to_pitch() with max_candidates=15...\n")
pitch <- snd$to_pitch(
  time_step = 0.01,
  pitch_floor = 75,
  pitch_ceiling = 600,
  max_candidates = 15,
  very_accurate = FALSE,
  silence_threshold = 0.03,
  voicing_threshold = 0.45,
  octave_cost = 0.01,
  octave_jump_cost = 0.35,
  voiced_unvoiced_cost = 0.14
)

# Check first 10 frames
pitch_df <- pitch$as_data_frame()
cat("\nFirst 10 pitch frames:\n")
print(pitch_df[1:10, ])

# Verify fix: Previously frames 4-9 had incorrect F0 values (120-137 Hz)
# After fix, they should be NA (unvoiced) like Praat
unvoiced_count <- sum(is.na(pitch_df$frequency[4:9]))
cat("\nFrames 4-9 unvoiced count:", unvoiced_count, "/ 6\n")

if (unvoiced_count >= 4) {
  cat("✓ PASS: Most frames 4-9 correctly marked unvoiced (like Praat)\n")
} else {
  cat("✗ FAIL: Too many frames 4-9 detected as voiced (bug still present?)\n")
}

# Test other pitch methods
cat("\nTesting to_pitch_ac()...\n")
pitch_ac <- snd$to_pitch_ac(max_candidates = 10)
cat("  Frames:", pitch_ac$get_number_of_frames(), "\n")

cat("Testing to_pitch_cc()...\n")
pitch_cc <- snd$to_pitch_cc(max_candidates = 8)
cat("  Frames:", pitch_cc$get_number_of_frames(), "\n")

cat("\n=== Test Complete ===\n")
