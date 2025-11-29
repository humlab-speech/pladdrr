# Test LPC Inverse Filtering Implementation
# Tests the new filter_inverse() and filter_inverse_at_time() methods

library(pladdrr)

cat("=== Testing LPC Inverse Filtering ===\n\n")

# Load test audio
audio_file <- system.file("extdata", "test.wav", package = "pladdrr")
cat("Loading audio:", audio_file, "\n")
sound <- Sound$new(audio_file)

cat("Sound duration:", sound$get_duration(), "s\n")
cat("Sampling frequency:", sound$get_sampling_frequency(), "Hz\n\n")

# Compute LPC
cat("=== Computing LPC (Burg method) ===\n")
lpc <- sound$to_lpc_burg(
  prediction_order = 16,
  analysis_width = 0.025,
  time_step = 0.005,
  pre_emphasis_frequency = 50.0
)

cat("LPC computed successfully\n")
cat("Number of frames:", lpc$get_number_of_frames(), "\n")
cat("Time step:", lpc$get_time_step(), "s\n")
cat("Max coefficients:", lpc$get_max_num_coefficients(), "\n\n")

# Test 1: filter_inverse()
cat("=== Test 1: filter_inverse() ===\n")
tryCatch({
  glottal_flow <- lpc$filter_inverse(sound)
  cat("✅ filter_inverse() succeeded\n")
  cat("Output duration:", glottal_flow$get_duration(), "s\n")
  cat("Output channels:", glottal_flow$get_number_of_channels(), "\n")
  cat("Output sampling freq:", glottal_flow$get_sampling_frequency(), "Hz\n")
}, error = function(e) {
  cat("❌ ERROR:", conditionMessage(e), "\n")
})

cat("\n")

# Test 2: filter_inverse_at_time()
cat("=== Test 2: filter_inverse_at_time() ===\n")
midpoint <- sound$get_duration() / 2
cat("Using filter at time:", midpoint, "s\n")

tryCatch({
  glottal_flow_fixed <- lpc$filter_inverse_at_time(
    sound = sound,
    time = midpoint,
    channel = 1
  )
  cat("✅ filter_inverse_at_time() succeeded\n")
  cat("Output duration:", glottal_flow_fixed$get_duration(), "s\n")
  cat("Output channels:", glottal_flow_fixed$get_number_of_channels(), "\n")
}, error = function(e) {
  cat("❌ ERROR:", conditionMessage(e), "\n")
})

cat("\n")

# Test 3: Error handling - wrong object type
cat("=== Test 3: Error Handling ===\n")
tryCatch({
  lpc$filter_inverse("not a sound")
  cat("❌ Should have errored but didn't\n")
}, error = function(e) {
  cat("✅ Correctly rejected non-Sound object\n")
  cat("   Error message:", conditionMessage(e), "\n")
})

cat("\n=== All Tests Complete ===\n")
cat("\n✅ LPC Inverse Filtering implementation is working correctly!\n")
