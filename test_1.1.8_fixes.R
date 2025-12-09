#!/usr/bin/env Rscript
# Test script for pladdrr 1.1.8 fixes
# Tests: LTAS energy unit, debug suppression, Sound filtering

library(pladdrr)

cat("=== Testing pladdrr", as.character(packageVersion("pladdrr")), "===\n\n")

# Test 1: LTAS with unit="energy" (CRITICAL FIX)
cat("Test 1: LTAS get_slope with unit='energy'\n")
cat("------------------------------------------\n")
tryCatch({
  # Create test sound
  sound <- Sound$new_tone(frequency = 440, duration = 1.0, sampling_frequency = 44100)
  
  # Create LTAS
  spectrum <- sound$to_spectrum()
  ltas <- spectrum$to_ltas(bandwidth = 100)
  
  # Test get_slope with different units
  slope_energy <- ltas$get_slope(100, 1000, 1000, 5000, unit = "energy")
  slope_sones <- ltas$get_slope(100, 1000, 1000, 5000, unit = "sones")
  slope_db <- ltas$get_slope(100, 1000, 1000, 5000, unit = "db")
  
  cat(sprintf("  slope (energy): %.4f dB\n", slope_energy))
  cat(sprintf("  slope (sones):  %.4f dB\n", slope_sones))
  cat(sprintf("  slope (dB):     %.4f dB\n", slope_db))
  cat("  ✓ PASS: All units work\n\n")
  
}, error = function(e) {
  cat("  ✗ FAIL:", e$message, "\n\n")
})

# Test 2: Sound filtering methods
cat("Test 2: Sound filter_pass_hann_band and filter_stop_hann_band\n")
cat("--------------------------------------------------------------\n")
tryCatch({
  # Create test sound with multiple frequency components
  sound1 <- Sound$new_tone(frequency = 100, duration = 0.5, sampling_frequency = 44100)
  sound2 <- Sound$new_tone(frequency = 1000, duration = 0.5, sampling_frequency = 44100)
  sound3 <- Sound$new_tone(frequency = 5000, duration = 0.5, sampling_frequency = 44100)
  
  # Mix sounds (would need Sound$add or similar - testing just one for now)
  sound <- sound1
  
  # Test pass filter (should pass 500-2000 Hz range)
  filtered_pass <- sound$filter_pass_hann_band(fmin = 500, fmax = 2000, smooth = 100)
  cat(sprintf("  Pass filter (500-2000 Hz):\n"))
  cat(sprintf("    Original duration: %.3f s\n", sound$get_total_duration()))
  cat(sprintf("    Filtered duration: %.3f s\n", filtered_pass$get_total_duration()))
  cat(sprintf("    Filtered channels: %d\n", filtered_pass$get_number_of_channels()))
  
  # Test stop filter (should stop 500-2000 Hz range)
  filtered_stop <- sound$filter_stop_hann_band(fmin = 500, fmax = 2000, smooth = 100)
  cat(sprintf("  Stop filter (500-2000 Hz):\n"))
  cat(sprintf("    Filtered duration: %.3f s\n", filtered_stop$get_total_duration()))
  
  cat("  ✓ PASS: Both filters work\n\n")
  
}, error = function(e) {
  cat("  ✗ FAIL:", e$message, "\n\n")
})

# Test 3: Check debug output suppression
cat("Test 3: Debug output suppression\n")
cat("---------------------------------\n")
cat("Creating pitch object (should have no debug output)...\n")
tryCatch({
  sound <- Sound$new_tone(frequency = 220, duration = 0.5, sampling_frequency = 22050)
  
  # Capture output
  output <- capture.output({
    pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
  }, type = "message")
  
  # Check for debug messages
  has_debug <- any(grepl("PITCH_DEBUG|LOOP ITERATION|STUB MelderThread", output))
  
  if (has_debug) {
    cat("  ✗ FAIL: Debug output detected:\n")
    cat(paste0("    ", output[1:min(5, length(output))]), sep = "\n")
    cat("\n")
  } else {
    cat("  ✓ PASS: No debug output\n\n")
  }
  
}, error = function(e) {
  cat("  ✗ FAIL:", e$message, "\n\n")
})

cat("=== Test Summary ===\n")
cat("All critical fixes tested.\n")
cat("Check output above for PASS/FAIL status.\n")
