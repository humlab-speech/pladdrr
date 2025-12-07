library(pladdrr)

# Pure 200 Hz tone
t <- seq(0, 0.1, by=1/16000)
samples <- 0.9 * sin(2*pi*200*t)
sound <- create_sound(samples, sampling_rate=16000)

# Extract pitch
pitch_result <- extract_pitch(sound, time_step=0.01, pitch_floor=75, pitch_ceiling=600)

cat("Pitch extraction results:\n")
cat("  Total frames:", nrow(pitch_result), "\n")
cat("  Voiced frames:", sum(!is.na(pitch_result$frequency)), "\n")
cat("  Voicing %:", round(100*mean(!is.na(pitch_result$frequency)), 1), "%\n")
if (sum(!is.na(pitch_result$frequency)) > 0) {
  cat("  Mean F0 (Hz):", round(mean(pitch_result$frequency, na.rm=TRUE), 1), "\n")
}
