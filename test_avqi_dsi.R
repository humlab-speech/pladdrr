#!/usr/bin/env Rscript
# Test AVQI and DSI implementations

library(speaker)

cat("=== Testing AVQI and DSI Implementations ===\n\n")

# Use real speech sample for testing
test_wav <- system.file("extdata", "test.wav", package = "speaker")
if (!file.exists(test_wav) || nchar(test_wav) == 0) {
  # Try testthat fixtures
  test_wav <- "tests/testthat/fixtures/speech_sample.wav"
}

if (file.exists(test_wav)) {
  cat(sprintf("Loading test audio from: %s\n", test_wav))
  test_sound <- Sound$new(test_wav)
  cat("✓ Sound loaded successfully\n\n")
} else {
  cat("Creating synthetic test sound (440 Hz, 3 seconds)...\n")
  test_sound <- Sound$create_tone(
    duration = 3.0,
    frequency = 440,
    sampling_rate = 44100,
    amplitude = 0.5
  )
  cat("✓ Sound created successfully\n\n")
}


# Test basic Sound methods used by AVQI/DSI
cat("Testing Sound methods:\n")
cat(sprintf("  Duration: %.2f s\n", test_sound$get_duration()))
cat(sprintf("  Sampling frequency: %.0f Hz\n", test_sound$get_sampling_frequency()))
cat("✓ Basic methods work\n\n")

# Test DSI computation
cat("=== Testing DSI Computation ===\n")
tryCatch({
  dsi_result <- compute_dsi(
    test_sound,
    type = "sustained",
    gender = "male",
    verbose = TRUE
  )
  
  cat("\n✓ DSI computation completed!\n")
  cat("\nDSI Results:\n")
  cat(sprintf("  DSI Score: %.2f\n", dsi_result$dsi))
  cat(sprintf("  MPT: %.2f s\n", dsi_result$mpt))
  cat(sprintf("  I-low: %.2f dB\n", dsi_result$i_low))
  cat(sprintf("  F0-high: %.1f Hz\n", dsi_result$f0_high))
  cat(sprintf("  Jitter ppq5: %.3f %%\n", dsi_result$jitter_ppq5))
  cat("\nComponents table:\n")
  print(dsi_result$components)
  
}, error = function(e) {
  cat("✗ DSI computation failed:\n")
  cat("  Error:", conditionMessage(e), "\n")
  traceback()
})

cat("\n")

# Test AVQI computation (vowel only)
cat("=== Testing AVQI Computation (Vowel) ===\n")
tryCatch({
  avqi_result <- compute_avqi(
    test_sound,
    type = "vowel",
    gender = "male",
    verbose = TRUE
  )
  
  cat("\n✓ AVQI computation completed!\n")
  cat("\nAVQI Results:\n")
  cat(sprintf("  AVQI Score: %.2f\n", avqi_result$avqi))
  cat(sprintf("  CPPS: %.2f dB\n", avqi_result$cpps))
  cat(sprintf("  HNR: %.2f dB\n", avqi_result$hnr))
  cat(sprintf("  Shimmer Local: %.3f %%\n", avqi_result$shimmer_local))
  cat(sprintf("  Shimmer Local dB: %.3f dB\n", avqi_result$shimmer_local_db))
  cat(sprintf("  Slope: %.2f dB\n", avqi_result$slope))
  cat(sprintf("  Tilt: %.2f dB\n", avqi_result$tilt))
  cat("\nComponents table:\n")
  print(avqi_result$components)
  
}, error = function(e) {
  cat("✗ AVQI computation failed:\n")
  cat("  Error:", conditionMessage(e), "\n")
  traceback()
})

cat("\n=== Test Summary ===\n")
cat("If both DSI and AVQI completed without errors, the implementations are working!\n")
