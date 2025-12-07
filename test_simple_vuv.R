# Simplest possible test - just check if ANYTHING is voiced
library(pladdrr)

cat("=== SIMPLE VOICING TEST ===\n\n")

# Test 1: Pure tone (should be 100% voiced)
cat("TEST 1: Pure 200 Hz sine wave\n")
sound1 <- Sound$create_tone(duration = 1, frequency = 200, sampling_rate = 16000, amplitude = 0.9)
pitch1 <- sound1$to_pitch()
df1 <- pitch1$as_data_frame()
cat("  Voiced:", sum(!is.na(df1$frequency)), "/", nrow(df1), "\n")
cat("  Expected: ~97/97 (100%)\n\n")

# Test 2: Different frequency
cat("TEST 2: Pure 440 Hz sine wave\n")
sound2 <- Sound$create_tone(duration = 1, frequency = 440, sampling_rate = 16000, amplitude = 0.9)
pitch2 <- sound2$to_pitch(pitch_floor = 100, pitch_ceiling = 600)
df2 <- pitch2$as_data_frame()
cat("  Voiced:", sum(!is.na(df2$frequency)), "/", nrow(df2), "\n")
cat("  Expected: ~97/97 (100%)\n\n")

# Test 3: Very low frequency
cat("TEST 3: Pure 100 Hz sine wave\n")
sound3 <- Sound$create_tone(duration = 1, frequency = 100, sampling_rate = 16000, amplitude = 0.9)
pitch3 <- sound3$to_pitch(pitch_floor = 50, pitch_ceiling = 300)
df3 <- pitch3$as_data_frame()
cat("  Voiced:", sum(!is.na(df3$frequency)), "/", nrow(df3), "\n")
cat("  Expected: ~97/97 (100%)\n\n")

# Test 4: Check internal pitch structure
cat("TEST 4: Inspecting internal Pitch structure\n")
cat("  This requires accessing C++ internals...\n")

cat("\n=== SUMMARY ===\n")
if (sum(!is.na(df1$frequency)) == 0 && sum(!is.na(df2$frequency)) == 0 && sum(!is.na(df3$frequency)) == 0) {
  cat("FAILURE: ALL pitch detection methods return 0 voiced frames\n")
  cat("This is a fundamental algorithm bug, not a parameter issue.\n")
  cat("\nLikely causes:\n")
  cat("1. Sound data not accessible to Praat algorithms\n")
  cat("2. Pitch detection algorithm broken in our build\n")
  cat("3. Missing/incorrect build flags or dependencies\n")
  cat("4. Memory layout mismatch between R and Praat\n")
} else {
  cat("SUCCESS: Some frames were detected as voiced\n")
}
