library(pladdrr)

# Create pure 200 Hz tone
fs <- 16000
duration <- 0.1
t <- seq(0, duration, by = 1/fs)
signal <- 0.9 * sin(2 * pi * 200 * t)

cat("Signal stats:\n")
cat("  Length:", length(signal), "\n")
cat("  Range:", min(signal), "to", max(signal), "\n")
cat("  RMS:", sqrt(mean(signal^2)), "\n")

# Create sound object
sound <- Sound$from_values(matrix(signal, nrow = 1), sampling_rate = fs)

# Get data back
audio_matrix <- sound$as_matrix()

cat("\nRetrieved audio stats:\n")
cat("  Dims:", paste(dim(audio_matrix), collapse="x"), "\n")
cat("  Range:", min(audio_matrix), "to", max(audio_matrix), "\n")
cat("  RMS:", sqrt(mean(audio_matrix^2)), "\n")

# Check if data matches
cat("\nData comparison:\n")
cat("  Max difference:", max(abs(as.vector(audio_matrix) - signal)), "\n")
cat("  Correlation:", cor(as.vector(audio_matrix), signal), "\n")

# Try create_tone (built-in generator)
cat("\n=== Testing create_tone (Praat's built-in) ===\n")
tone <- Sound$create_tone(duration = 0.1, frequency = 200, amplitude = 0.9, sampling_rate = 16000)

cat("Tone stats:\n")
cat("  Duration:", tone$get_duration(), "s\n")
cat("  Samples:", tone$get_number_of_samples(), "\n")

tone_pitch <- tone$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
cat("Pitch from create_tone:\n")
cat("  Frames:", tone_pitch$get_number_of_frames(), "\n")
cat("  Voiced:", tone_pitch$count_voiced_frames(), "\n")
