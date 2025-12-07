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

# Get raw audio data to verify
audio_data <- sound$as_matrix()
cat("  Audio range:", min(audio_data), "to", max(audio_data), "\n")
cat("  RMS:", sqrt(mean(audio_data^2)), "\n")

cat("\n=== Testing to_pitch (simple wrapper) ===\n")
pitch1 <- sound$to_pitch(
  time_step = 0.01,
  pitch_floor = 75,
  pitch_ceiling = 600
)
cat("Frames:", pitch1$get_number_of_frames(), "\n")
cat("Voiced:", pitch1$count_voiced_frames(), "\n")

cat("\n=== Testing to_pitch_ac (full parameters) ===\n")
pitch2 <- sound$to_pitch_ac(
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
cat("Frames:", pitch2$get_number_of_frames(), "\n")
cat("Voiced:", pitch2$count_voiced_frames(), "\n")

cat("\n=== Testing with relaxed parameters ===\n")
pitch3 <- sound$to_pitch_ac(
  time_step = 0.01,
  pitch_floor = 75,
  pitch_ceiling = 600,
  silence_threshold = 0.001,  # Very low
  voicing_threshold = 0.2     # Very low
)
cat("Frames:", pitch3$get_number_of_frames(), "\n")
cat("Voiced:", pitch3$count_voiced_frames(), "\n")

# Try with longer signal
cat("\n=== Testing with longer signal (1 second) ===\n")
t_long <- seq(0, 1.0, by = 1/fs)
signal_long <- 0.9 * sin(2 * pi * 200 * t_long)
sound_long <- Sound$from_values(matrix(signal_long, nrow = 1), sampling_rate = fs)

pitch4 <- sound_long$to_pitch(
  time_step = 0.01,
  pitch_floor = 75,
  pitch_ceiling = 600
)
cat("Frames:", pitch4$get_number_of_frames(), "\n")
cat("Voiced:", pitch4$count_voiced_frames(), "\n")
cat("Voicing %:", 100 * pitch4$count_voiced_frames() / pitch4$get_number_of_frames(), "%\n")
