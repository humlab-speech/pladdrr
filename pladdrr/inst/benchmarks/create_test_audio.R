# Create test audio file for benchmarks
library(speaker)

cat("Creating test audio file...\n")

# Create a 1-second test tone (440 Hz A4 note)
sound <- Sound$create_tone(
  duration = 1.0,
  frequency = 440,
  sampling_frequency = 44100,
  amplitude = 0.5
)

# Try to save
output_file <- "inst/extdata/test.wav"

tryCatch({
  sound$save(output_file)
  cat("✓ Created:", output_file, "\n")
  cat("  Duration:", sound$get_duration(), "seconds\n")
  cat("  Sample rate:", sound$get_sampling_frequency(), "Hz\n")
}, error = function(e) {
  cat("✗ Could not save audio file\n")
  cat("Error:", e$message, "\n")
  cat("\nNote: This is expected if Sound$save() is not yet implemented.\n")
  cat("Benchmarks will use alternative test data.\n")
})
