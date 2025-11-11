#!/usr/bin/env Rscript

# Test current implementation status
suppressPackageStartupMessages({
  devtools::load_all(quiet = TRUE)
})

cat("\n=== Testing Speaker Package v0.4.0 ===\n\n")

# Test data
test_wav <- system.file("extdata", "test.wav", package = "speaker")
test_tg <- system.file("extdata", "test.TextGrid", package = "speaker")

cat("Test files:\n")
cat("- Sound:", ifelse(file.exists(test_wav), "✅", "❌"), test_wav, "\n")
cat("- TextGrid:", ifelse(file.exists(test_tg), "✅", "❌"), test_tg, "\n\n")

# Test Sound object
cat("1. Testing Sound object...\n")
tryCatch({
  snd <- Sound$new_from_file(test_wav)
  cat("   ✅ Sound loaded\n")
  cat("   - Duration:", snd$get_total_duration(), "s\n")
  cat("   - Sample rate:", snd$get_sampling_frequency(), "Hz\n")
}, error = function(e) cat("   ❌ Error:", e$message, "\n"))

# Test Pitch
cat("\n2. Testing Pitch object...\n")
tryCatch({
  pitch <- snd$to_pitch()
  cat("   ✅ Pitch extracted\n")
  cat("   - Mean F0:", round(pitch$get_mean(unit = "hertz"), 1), "Hz\n")
}, error = function(e) cat("   ❌ Error:", e$message, "\n"))

# Test Formant
cat("\n3. Testing Formant object...\n")
tryCatch({
  formant <- snd$to_formant_burg()
  cat("   ✅ Formant extracted\n")
  cat("   - F1 mean:", round(formant$get_mean(1, unit = "hertz"), 1), "Hz\n")
}, error = function(e) cat("   ❌ Error:", e$message, "\n"))

# Test Intensity
cat("\n4. Testing Intensity object...\n")
tryCatch({
  intensity <- snd$to_intensity()
  cat("   ✅ Intensity extracted\n")
  cat("   - Mean:", round(intensity$get_mean(), 1), "dB\n")
}, error = function(e) cat("   ❌ Error:", e$message, "\n"))

# Test TextGrid
cat("\n5. Testing TextGrid object...\n")
tryCatch({
  tg <- TextGrid$new(test_tg)
  cat("   ✅ TextGrid loaded\n")
  cat("   - Tiers:", tg$get_number_of_tiers(), "\n")
  cat("   - Duration:", tg$get_total_duration(), "s\n")
}, error = function(e) cat("   ❌ Error:", e$message, "\n"))

# Test Manipulation
cat("\n6. Testing Manipulation object...\n")
tryCatch({
  manip <- snd$to_manipulation()
  cat("   ✅ Manipulation created\n")
  pt <- manip$extract_pitch_tier()
  cat("   - PitchTier extracted\n")
}, error = function(e) cat("   ❌ Error:", e$message, "\n"))

# Test Spectrum
cat("\n7. Testing Spectrum object...\n")
tryCatch({
  spec <- snd$to_spectrum()
  cat("   ✅ Spectrum created\n")
}, error = function(e) cat("   ❌ Error:", e$message, "\n"))

# Test LTAS
cat("\n8. Testing LTAS object...\n")
tryCatch({
  ltas <- snd$to_ltas()
  cat("   ✅ LTAS created\n")
}, error = function(e) cat("   ❌ Error:", e$message, "\n"))

cat("\n=== Test Complete ===\n")
