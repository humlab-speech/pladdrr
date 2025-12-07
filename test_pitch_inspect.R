library(pladdrr)

# Use absolute simplest case: create tone with Praat, extract pitch
tone <- Sound$create_tone(duration = 1.0, frequency = 200, amplitude = 0.9, sampling_rate = 16000)

cat("Testing with 1 second, 200 Hz tone\n")
cat("Sound properties:\n")
cat("  Duration:", tone$get_duration(), "s\n")
cat("  Samples:", tone$get_number_of_samples(), "\n")
cat("  SR:", tone$get_sampling_frequency(), "Hz\n")
cat("  RMS:", tone$get_rms(0, 0), "\n")

# Try different pitch extraction methods
cat("\n=== Method 1: Simple to_pitch ===\n")
p1 <- tone$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
cat("Frames:", p1$get_number_of_frames(), ", Voiced:", p1$count_voiced_frames(), "\n")

cat("\n=== Method 2: AC with defaults ===\n")
p2 <- tone$to_pitch_ac(
  time_step = 0.01,
  pitch_floor = 75,
  pitch_ceiling = 600
)
cat("Frames:", p2$get_number_of_frames(), ", Voiced:", p2$count_voiced_frames(), "\n")

cat("\n=== Method 3: CC (cross-correlation) ===\n")
p3 <- tone$to_pitch_cc(
  time_step = 0.01,
  pitch_floor = 75,
  pitch_ceiling = 600
)
cat("Frames:", p3$get_number_of_frames(), ", Voiced:", p3$count_voiced_frames(), "\n")

# Try reading existing file if available
test_file <- "inst/extdata/H.wav"
if (file.exists(test_file)) {
  cat("\n=== Testing with real audio file ===\n")
  real_sound <- Sound$new(test_file)
  cat("File duration:", real_sound$get_duration(), "s\n")
  
  real_pitch <- real_sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
  cat("Frames:", real_pitch$get_number_of_frames(), ", Voiced:", real_pitch$count_voiced_frames(), "\n")
  
  if (real_pitch$count_voiced_frames() > 0) {
    cat("Mean F0:", real_pitch$get_mean(unit = "hertz"), "Hz\n")
  }
} else {
  cat("\nNo test file found at", test_file, "\n")
}
