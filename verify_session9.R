#!/usr/bin/env Rscript
# Comprehensive verification after Session 9 fix

cat("=== Session 9 Verification ===\n\n")

library(pladdrr)

# Test 1: Basic formant extraction
cat("Test 1: Basic formant extraction... ")
sound <- Sound$create_tone(duration = 0.5, sampling_rate = 22050)
formant <- sound$to_formant_burg(
  time_step = 0.005,
  max_formants = 5,
  max_frequency = 5500
)
if (!is.null(formant)) {
  cat("✅ PASS\n")
} else {
  cat("❌ FAIL\n")
  quit(status = 1)
}

# Test 2: Formant queries
cat("Test 2: Formant value queries... ")
f1 <- formant$get_value_at_time(1, 0.25, unit = "hertz")
if (!is.na(f1) && f1 > 0) {
  cat("✅ PASS (F1 = ", round(f1, 1), " Hz)\n", sep="")
} else {
  cat("❌ FAIL\n")
  quit(status = 1)
}

# Test 3: Different formant methods
cat("Test 3: Formant keep-all method... ")
formant2 <- sound$to_formant_keepall(
  time_step = 0.005,
  max_formants = 5,
  max_frequency = 5500
)
if (!is.null(formant2)) {
  cat("✅ PASS\n")
} else {
  cat("❌ FAIL\n")
  quit(status = 1)
}

# Test 4: Other analysis functions still work
cat("Test 4: Pitch extraction... ")
pitch <- sound$to_pitch(pitch_floor = 75, pitch_ceiling = 600)
if (!is.null(pitch)) {
  cat("✅ PASS\n")
} else {
  cat("❌ FAIL\n")
  quit(status = 1)
}

cat("Test 5: Intensity extraction... ")
intensity <- sound$to_intensity(minimum_pitch = 100)
if (!is.null(intensity)) {
  cat("✅ PASS\n")
} else {
  cat("❌ FAIL\n")
  quit(status = 1)
}

cat("\n=== All Tests Passed ✅ ===\n")
cat("Session 9 fix verified successfully!\n")
quit(status = 0)
