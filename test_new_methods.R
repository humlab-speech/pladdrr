#!/usr/bin/env Rscript

# Quick test of new methods without full installation
library(pladdrr)

cat("Testing new methods...\n\n")

# Test 1: Pitch to TextGrid VUV
cat("1. Testing Pitch$to_textgrid_vuv()...\n")
tryCatch({
  snd <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
  pitch <- snd$to_pitch()
  tg_vuv <- pitch$to_textgrid_vuv()
  cat("   ✓ Success! Created TextGrid with", tg_vuv$get_number_of_tiers(), "tier(s)\n")
}, error = function(e) {
  cat("   ✗ Failed:", conditionMessage(e), "\n")
})

# Test 2: Pitch to TextGrid silences
cat("\n2. Testing Pitch$to_textgrid_silences()...\n")
tryCatch({
  snd <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
  pitch <- snd$to_pitch()
  tg_sil <- pitch$to_textgrid_silences(min_silent_interval_duration = 0.1, 
                                        min_sounding_interval_duration = 0.1)
  cat("   ✓ Success! Created TextGrid with", tg_sil$get_number_of_tiers(), "tier(s)\n")
}, error = function(e) {
  cat("   ✗ Failed:", conditionMessage(e), "\n")
})

# Test 3: TextGrid extract intervals where
cat("\n3. Testing TextGrid$extract_intervals_where()...\n")
tryCatch({
  snd <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
  pitch <- snd$to_pitch()
  tg_vuv <- pitch$to_textgrid_vuv()
  
  # Extract voiced intervals
  voiced_sounds <- tg_vuv$extract_intervals_where(snd, 1, "is equal to", "V")
  cat("   ✓ Success! Extracted", length(voiced_sounds), "voiced interval(s)\n")
}, error = function(e) {
  cat("   ✗ Failed:", conditionMessage(e), "\n")
})

# Test 4: Sound extract intervals where
cat("\n4. Testing Sound$extract_intervals_where()...\n")
tryCatch({
  snd <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
  pitch <- snd$to_pitch()
  tg_vuv <- pitch$to_textgrid_vuv()
  
  # Extract voiced intervals
  voiced_sounds <- snd$extract_intervals_where(tg_vuv, 1, "is equal to", "V")
  cat("   ✓ Success! Extracted", length(voiced_sounds), "voiced interval(s)\n")
}, error = function(e) {
  cat("   ✗ Failed:", conditionMessage(e), "\n")
})

# Test 5: PointProcess voice_report
cat("\n5. Testing PointProcess$voice_report()...\n")
tryCatch({
  snd <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
  pitch <- snd$to_pitch()
  pp <- snd$to_point_process_periodic_cc(pitch)
  
  report <- pp$voice_report(snd, pitch, 75, 600, 1.3, 1.6, 0.03)
  cat("   ✓ Success! Got voice report with jitter =", report$jitter_local, "\n")
}, error = function(e) {
  cat("   ✗ Failed:", conditionMessage(e), "\n")
})

cat("\n=== Test complete ===\n")
