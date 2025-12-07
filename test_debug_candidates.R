library(pladdrr)

# Create using built-in tone generator
tone <- Sound$create_tone(duration = 0.5, frequency = 200, amplitude = 0.8, sampling_rate = 16000)

cat("Sound created:\n")
cat("  Duration:", tone$get_duration(), "s\n")
cat("  Samples:", tone$get_number_of_samples(), "\n")
cat("  SR:", tone$get_sampling_frequency(), "Hz\n")

# Try pitch detection with extreme relaxed parameters
cat("\nTrying with VERY relaxed parameters:\n")
pitch <- tone$to_pitch_ac(
  time_step = 0.01,
  pitch_floor = 50,          # Very low
  pitch_ceiling = 1000,      # Very high
  max_candidates = 15,
  very_accurate = TRUE,      # Use accurate method
  silence_threshold = 0.001, # Almost no silence detection
  voicing_threshold = 0.1,   # Very low voicing threshold
  octave_cost = 0.01,
  octave_jump_cost = 0.35,
  voiced_unvoiced_cost = 0.14
)

cat("Result:\n")
cat("  Frames:", pitch$get_number_of_frames(), "\n")
cat("  Voiced:", pitch$count_voiced_frames(), "\n")

# Export and examine
df <- pitch$as_data_frame()
cat("\nFirst 10 frames:\n")
print(head(df, 10))

# Check if pitch candidates exist but just not selected
cat("\nChecking if ANY non-NA frequencies exist:\n")
cat("  Non-NA count:", sum(!is.na(df$frequency)), "\n")
cat("  Unique frequencies:", unique(df$frequency), "\n")
