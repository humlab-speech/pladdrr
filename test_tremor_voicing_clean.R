#!/usr/bin/env Rscript
# Clean tremor voicing test - suppress C debug output
library(pladdrr)

cat("=== Tremor Voicing Test (Clean Output) ===\n")
cat("Testing: inst/signalfiles/AVQI/input/sv1.wav\n")
cat("Issue: Frames 4-9 should be unvoiced (match Praat)\n\n")

# Load audio
snd <- Sound$new("inst/signalfiles/AVQI/input/sv1.wav")
cat(sprintf("Duration: %.3f sec, Sample rate: %d Hz\n", 
            snd$get_duration(), snd$get_sampling_rate()))

# Extract pitch with tremor parameters (redirect stderr to suppress C debug)
cat("\nExtracting pitch (this may take a moment)...\n")
sink(stderr(), type = "output")  # Suppress stderr
pitch <- snd$to_pitch_cc(
  time_step = 0.015,
  pitch_floor = 60,
  pitch_ceiling = 350,
  max_candidates = 15,
  silence_threshold = 0.03,
  voicing_threshold = 0.3,
  octave_cost = 0.01,
  octave_jump_cost = 0.35,
  voiced_unvoiced_cost = 0.14
)
sink(type = "output")  # Restore stderr

# Get pitch contour
times <- sapply(1:pitch$get_number_of_frames(), function(i) {
  pitch$get_time_from_frame(i)
})
freqs <- sapply(1:pitch$get_number_of_frames(), function(i) {
  time <- pitch$get_time_from_frame(i)
  pitch$get_value_at_time(time, unit = "HERTZ", interpolate = FALSE)
})

# Focus on first 10 frames
cat("\n=== First 10 Frames (Critical Region) ===\n")
cat(sprintf("%-6s %-10s %-12s %s\n", "Frame", "Time (s)", "Freq (Hz)", "Status"))
cat(strrep("-", 50), "\n")

for (i in 1:min(10, length(freqs))) {
  voiced <- !is.na(freqs[i]) && freqs[i] > 0
  status <- if (voiced) {
    if (i >= 4 && i <= 9) "WRONG (should be unvoiced)" else "voiced"
  } else {
    if (i >= 4 && i <= 9) "CORRECT (unvoiced)" else "unvoiced"
  }
  
  freq_str <- if (voiced) sprintf("%.2f", freqs[i]) else "unvoiced"
  cat(sprintf("%-6d %-10.3f %-12s %s\n", i, times[i], freq_str, status))
}

# Summary
voiced_4_9 <- sum(!is.na(freqs[4:9]) & freqs[4:9] > 0)
cat("\n=== Test Result ===\n")
cat(sprintf("Frames 4-9 voiced: %d / 6\n", voiced_4_9))
if (voiced_4_9 == 0) {
  cat("✅ PASS: All frames 4-9 unvoiced (matches Praat)\n")
} else {
  cat(sprintf("❌ FAIL: %d frames incorrectly voiced\n", voiced_4_9))
  cat("This is the BLOCKING issue causing 188%% tremor error\n")
}

cat("\n=== Mean F0 Comparison ===\n")
mean_f0 <- mean(freqs[!is.na(freqs) & freqs > 0], na.rm = TRUE)
cat(sprintf("pladdrr mean F0: %.3f Hz\n", mean_f0))
cat("Expected (Praat): 138.450 Hz\n")
cat(sprintf("Difference: %.3f Hz (%.1f%%)\n", 
            mean_f0 - 138.450, 
            abs(mean_f0 - 138.450) / 138.450 * 100))
