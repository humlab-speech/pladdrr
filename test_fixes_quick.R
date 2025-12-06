#!/usr/bin/env Rscript
# Quick test of 1.1.0 fixes without full rebuild

library(pladdrr)

cat("\n=== Testing 1.1.0 Fixes ===\n\n")

# Test 1: Sound$from_values()
cat("1. Testing Sound$from_values()...\n")
tryCatch({
  values <- matrix(sin(2*pi*440*seq(0, 1, length.out=44100)), nrow=1)
  snd <- Sound$new_from_values(values, sampling_rate=44100)
  cat("   ✓ Sound created from values\n")
  cat("   Duration:", snd$get_total_duration(), "s\n")
}, error = function(e) cat("   ✗ ERROR:", e$message, "\n"))

# Test 2: PointProcess$voice_report()
cat("\n2. Testing PointProcess$voice_report()...\n")
tryCatch({
  snd <- Sound$new(system.file("extdata", "test.wav", package="pladdrr"))
  pitch <- snd$to_Pitch()
  pp <- pitch$to_PointProcess()
  
  report <- pp$voice_report(
    sound = snd,
    pitch = pitch,
    time_range_start = 0,
    time_range_end = 0,
    floor_pitch = 75,
    ceiling_pitch = 600,
    max_period_factor = 1.3,
    max_amplitude_factor = 1.6,
    silence_threshold = 0.03,
    voicing_threshold = 0.45
  )
  cat("   ✓ Voice report generated\n")
  cat("   Jitter:", report$jitter_local, "\n")
}, error = function(e) cat("   ✗ ERROR:", e$message, "\n"))

# Test 3: Pitch$to_textgrid_vuv()
cat("\n3. Testing Pitch$to_textgrid_vuv()...\n")
tryCatch({
  snd <- Sound$new(system.file("extdata", "test.wav", package="pladdrr"))
  pitch <- snd$to_Pitch()
  tg <- pitch$to_textgrid_vuv(min_voiced_duration=0.1, min_unvoiced_duration=0.1)
  cat("   ✓ VUV TextGrid created\n")
  cat("   Tiers:", tg$get_number_of_tiers(), "\n")
}, error = function(e) cat("   ✗ ERROR:", e$message, "\n"))

# Test 4: Pitch$to_textgrid_silences()
cat("\n4. Testing Pitch$to_textgrid_silences()...\n")
tryCatch({
  snd <- Sound$new(system.file("extdata", "test.wav", package="pladdrr"))
  pitch <- snd$to_Pitch()
  tg <- pitch$to_textgrid_silences(
    silence_threshold = -25,
    min_silence_duration = 0.1,
    min_sounding_duration = 0.1
  )
  cat("   ✓ Silence TextGrid created\n")
  cat("   Tiers:", tg$get_number_of_tiers(), "\n")
}, error = function(e) cat("   ✗ ERROR:", e$message, "\n"))

# Test 5: TextGrid$extract_intervals_where()
cat("\n5. Testing TextGrid$extract_intervals_where()...\n")
tryCatch({
  snd <- Sound$new(system.file("extdata", "test.wav", package="pladdrr"))
  pitch <- snd$to_Pitch()
  tg <- pitch$to_textgrid_vuv(min_voiced_duration=0.1, min_unvoiced_duration=0.1)
  
  collection <- tg$extract_intervals_where(
    sound = snd,
    tier_number = 1,
    criterion = "label_matches",
    text = "V"
  )
  cat("   ✓ Intervals extracted\n")
  cat("   Objects:", collection$get_size(), "\n")
}, error = function(e) cat("   ✗ ERROR:", e$message, "\n"))

cat("\n=== All Tests Complete ===\n")
