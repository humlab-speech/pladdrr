#!/usr/bin/env Rscript
# Test voicing decisions on tremor test file (sv1.wav)
# Validates if v1.2.1 int→integer fix resolved voicing issue
# Expected: Frames 4-9 should be UNVOICED (match Praat/Python)

library(pladdrr)

cat("=== Tremor Voicing Decision Test ===\n")
cat("Testing: inst/signalfiles/AVQI/input/sv1.wav\n")
cat("Issue: Frames 4-9 detected as voiced (should be unvoiced)\n")
cat("Reference: /tmp/PLADDRR_TREMOR_BLOCKING_ISSUES_REPORT.md\n\n")

# Load test file
file_path <- "inst/signalfiles/AVQI/input/sv1.wav"
if (!file.exists(file_path)) {
  stop("Test file not found: ", file_path)
}

sound <- Sound$new(file_path)
cat("Loaded:", file_path, "\n")
cat("Duration:", sound$get_duration(), "sec\n")
cat("Sample rate:", sound$get_sampling_frequency(), "Hz\n\n")

# Extract with Hanning window (Praat uses Gaussian1 but not available)
sound_windowed <- sound$extract_part(
  0, sound$get_duration(),
  window_shape = "hanning",
  relative_width = 1.0,
  preserve_times = FALSE
)

cat("Extracting pitch with console_tremor305.praat parameters:\n")
cat("  time_step = 0.015\n")
cat("  pitch_floor = 60\n")
cat("  pitch_ceiling = 350\n")
cat("  max_candidates = 15\n")
cat("  silence_threshold = 0.03\n")
cat("  voicing_threshold = 0.3\n\n")

# Exact parameters from tremor algorithm
pitch <- sound_windowed$to_pitch_cc(
  time_step = 0.015,
  pitch_floor = 60,
  pitch_ceiling = 350,
  max_candidates = 15,  # v1.2.1 fix: now cast to integer in C++
  very_accurate = FALSE,
  silence_threshold = 0.03,
  voicing_threshold = 0.3,
  octave_cost = 0.01,
  octave_jump_cost = 0.35,
  voiced_unvoiced_cost = 0.14
)

cat("Pitch object created\n")
cat("Total frames:", pitch$get_number_of_frames(), "\n\n")

# Check critical frames 1-20 (frames 4-9 are the problem)
cat("Frame-by-Frame Voicing Analysis:\n")
cat("Frame | Time (s) | F0 (Hz)   | Expected (Praat) | Status\n")
cat("------|----------|-----------|------------------|--------\n")

# Expected results from /tmp/pitch_extraction_comparison.csv
expected <- data.frame(
  frame = 1:20,
  time = seq(0.015, 0.300, by = 0.015),
  praat_voiced = c(rep(FALSE, 9), rep(TRUE, 11)),
  praat_f0 = c(rep(0, 9), 137.102, 136.458, 135.812, 135.167, 
               134.521, 133.876, 143.229, 146.583, 148.937, 
               150.291, 155.644)
)

errors <- 0
problem_frames <- integer(0)

for (i in 1:20) {
  f0 <- pitch$get_value_in_frame(i)
  is_voiced <- !is.na(f0) && f0 > 0
  expected_voiced <- expected$praat_voiced[i]
  
  # Status
  if (is_voiced == expected_voiced) {
    status <- "✓ OK"
  } else {
    status <- "✗ FAIL"
    errors <- errors + 1
    problem_frames <- c(problem_frames, i)
  }
  
  # Format output
  f0_str <- if (is_voiced) sprintf("%.3f", f0) else "unvoiced"
  expected_str <- if (expected_voiced) sprintf("%.3f", expected$praat_f0[i]) else "unvoiced"
  
  # Highlight problem frames
  marker <- if (i >= 4 && i <= 9) "→" else " "
  
  cat(sprintf("%s %3d | %6.3f | %9s | %9s | %s\n",
              marker, i, expected$time[i], f0_str, expected_str, status))
}

cat("\n")
cat("=" , rep("=", 60), "\n", sep = "")
cat("SUMMARY\n")
cat("=" , rep("=", 60), "\n", sep = "")

if (errors == 0) {
  cat("✓✓✓ ALL TESTS PASSED ✓✓✓\n")
  cat("pladdrr v1.2.1 matches Praat voicing decisions!\n")
  cat("The int→integer fix resolved the tremor issue.\n")
} else {
  cat("✗✗✗ ", errors, " VOICING ERRORS DETECTED ✗✗✗\n", sep = "")
  cat("Problem frames:", paste(problem_frames, collapse = ", "), "\n")
  cat("\n")
  
  if (all(problem_frames >= 4 & problem_frames <= 9)) {
    cat("Known Issue: Frames 4-9 voicing mismatch\n")
    cat("This is the exact problem described in:\n")
    cat("/tmp/PLADDRR_TREMOR_BLOCKING_ISSUES_REPORT.md\n")
    cat("\n")
    cat("The v1.2.1 int→integer fix did NOT resolve this issue.\n")
    cat("Voicing decision logic needs deeper investigation.\n")
  }
}

cat("\nTest file: test_tremor_voicing.R\n")
cat("Expected: Frames 1-9 unvoiced, frame 10+ voiced\n")
cat("Reference: /tmp/pitch_extraction_comparison.csv\n")
