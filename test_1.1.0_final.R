#!/usr/bin/env Rscript
library(pladdrr)

cat("\n" ,"═══════════════════════════════════════════════════", "\n")
cat(" pladdrr 1.1.0 Critical Fixes Validation", "\n")
cat("═══════════════════════════════════════════════════", "\n\n")

errors <- 0

# Test 1: PointProcess$voice_report() pointer fix
cat("1. PointProcess$voice_report() - Fixed pointer access\n")
tryCatch({
  snd <- Sound$new(system.file("extdata", "test.wav", package="pladdrr"))
  pitch <- snd$to_pitch()
  pp <- pitch$to_point_process()
  report <- pp$voice_report(sound=snd, pitch=pitch)
  cat("   ✓ PASS - Voice report generated\n")
  cat("     Jitter (local):", round(report$jitter_local, 4), "\n")
}, error = function(e) {
  cat("   ✗ FAIL:", e$message, "\n")
  errors <<- errors + 1
})

# Test 2: Pitch$to_textgrid_vuv()
cat("\n2. Pitch$to_textgrid_vuv() - C++ wrapper implemented\n")
tryCatch({
  snd <- Sound$new(system.file("extdata", "test.wav", package="pladdrr"))
  pitch <- snd$to_pitch()
  tg <- pitch$to_textgrid_vuv()
  cat("   ✓ PASS - VUV TextGrid created\n")
  cat("     Tiers:", tg$get_number_of_tiers(), "\n")
}, error = function(e) {
  cat("   ✗ FAIL:", e$message, "\n")
  errors <<- errors + 1
})

# Test 3: Pitch$to_textgrid_silences()
cat("\n3. Pitch$to_textgrid_silences() - C++ wrapper implemented\n")
tryCatch({
  snd <- Sound$new(system.file("extdata", "test.wav", package="pladdrr"))
  pitch <- snd$to_pitch()
  tg <- pitch$to_textgrid_silences()
  cat("   ✓ PASS - Silences TextGrid created\n")
  cat("     Tiers:", tg$get_number_of_tiers(), "\n")
}, error = function(e) {
  cat("   ✗ FAIL:", e$message, "\n")
  errors <<- errors + 1
})

# Test 4: TextGrid$extract_intervals_where() - THE CRITICAL FIX
cat("\n4. TextGrid$extract_intervals_where() - Enum mapping fixed\n")
tryCatch({
  # Create test signal
  values <- matrix(sin(2*pi*440*seq(0, 1, length.out=44100)), nrow=1)
  snd <- Sound$from_values(values, sampling_rate=44100)
  pitch <- snd$to_pitch()
  tg <- pitch$to_textgrid_vuv()
  
  # Extract intervals
  sounds <- tg$extract_intervals_where(
    sound = snd,
    tier_number = 1,
    criterion = "is equal to",
    text = "U"
  )
  
  cat("   ✓ PASS - Intervals extracted without segfault!\n")
  cat("     Extracted:", length(sounds), "sound(s)\n")
  if (length(sounds) > 0) {
    cat("     First sound duration:", round(sounds[[1]]$get_duration(), 3), "s\n")
  }
}, error = function(e) {
  cat("   ✗ FAIL:", e$message, "\n")
  errors <<- errors + 1
})

# Summary
cat("\n","───────────────────────────────────────────────────", "\n")
if (errors == 0) {
  cat(" ✓ ALL TESTS PASSED - Ready for DSI/AVQI/tremor!\n")
} else {
  cat(" ✗", errors, "TESTS FAILED\n")
}
cat("───────────────────────────────────────────────────", "\n\n")

quit(status = errors)
