library(pladdrr)

# Create pure 200 Hz tone
cat("Creating test sound...\n")
fs <- 16000
duration <- 0.1
t <- seq(0, duration, by = 1/fs)
signal <- 0.9 * sin(2 * pi * 200 * t)

sound <- Sound$from_values(matrix(signal, nrow = 1), sampling_rate = fs)

cat("\nSound properties:\n")
cat("  Duration:", sound$get_duration(), "s\n")
cat("  Samples:", sound$get_number_of_samples(), "\n")
cat("  SR:", sound$get_sampling_frequency(), "Hz\n")

cat("\nExtracting pitch...\n")
pitch <- sound$to_pitch(
  time_step = 0.01,
  pitch_floor = 75,
  pitch_ceiling = 600
)

cat("\nPitch properties:\n")
n_frames <- pitch$get_number_of_frames()
n_voiced <- pitch$count_voiced_frames()
time_step <- pitch$get_time_step()

cat("  Total frames:", n_frames, "\n")
cat("  Voiced frames:", n_voiced, "\n")
cat("  Time step:", time_step, "\n")
cat("  Voicing %:", if(n_frames > 0) 100 * n_voiced / n_frames else NaN, "\n")

if (n_voiced > 0) {
  mean_f0 <- pitch$get_mean(unit = "hertz")
  cat("  Mean F0:", mean_f0, "Hz\n")
}

# Try accessing raw data
cat("\nTrying to export as data.frame...\n")
df <- tryCatch(
  pitch$as_data_frame(),
  error = function(e) {
    cat("  ERROR:", e$message, "\n")
    NULL
  }
)

if (!is.null(df)) {
  cat("  Rows:", nrow(df), "\n")
  cat("  Voiced rows:", sum(df$voiced, na.rm = TRUE), "\n")
  if (nrow(df) > 0) {
    print(head(df))
  }
}
