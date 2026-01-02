# test_formantpath_module.R
# Test script for FormantPath module - Phase 2.2
# Run after package build to verify FormantPath functionality

library(pladdrr)

cat("FormantPath Module Test\n")
cat("=======================\n\n")

# 1. Create test sound
cat("1. Creating test sound...\n")
sound <- Sound$create_tone(440, 0.5, 44100)
cat("   Sound duration:", sound$get_duration(), "s\n\n")

# 2. Create FormantPath
cat("2. Creating FormantPath...\n")
fp <- sound$to_formant_path(
  max_num_formants = 5,
  formant_ceiling = 5500,
  ceiling_step_fraction = 0.05,
  num_steps_up_down = 4
)

cat("   FormantPath created\n")
cat("   Valid:", fp$is_valid(), "\n")
cat("   Duration:", fp$get_duration(), "s\n")
cat("   Number of frames:", fp$get_nx(), "\n")
cat("   Number of candidates:", fp$get_number_of_candidates(), "\n\n")

# 3. Query ceiling frequencies
cat("3. Ceiling frequencies:\n")
ceilings <- fp$get_all_ceiling_frequencies()
cat("   Min:", min(ceilings), "Hz\n")
cat("   Max:", max(ceilings), "Hz\n")
cat("   Count:", length(ceilings), "\n\n")

# 4. Get candidate in first frame
cat("4. Candidate path query:\n")
candidate <- fp$get_candidate_in_frame(1)
cat("   Candidate in frame 1:", candidate, "\n")
ceiling_freq <- fp$get_ceiling_frequency(candidate)
cat("   Ceiling frequency:", ceiling_freq, "Hz\n\n")

# 5. Set optimal path
cat("5. Finding optimal path...\n")
fp$set_optimal_path()
cat("   Optimal path set\n\n")

# 6. Extract optimal formant
cat("6. Extracting optimal Formant...\n")
formant <- fp$extract_formant()
cat("   Formant extracted\n")
cat("   Formant duration:", formant$get_duration(), "s\n")
cat("   Number of frames:", formant$get_number_of_frames(), "\n\n")

# 7. Export to data frame
cat("7. Exporting to data frame...\n")
df <- as.data.frame(fp, max_formants = 5)
cat("   Rows:", nrow(df), "\n")
cat("   Columns:", paste(names(df), collapse = ", "), "\n")
cat("   First 5 rows:\n")
print(head(df, 5))
cat("\n")

# 8. Test with real vowel (if available)
test_wav <- "inst/extdata/test.wav"
if (file.exists(test_wav)) {
  cat("8. Testing with real audio file...\n")
  sound2 <- Sound(test_wav)
  fp2 <- sound2$to_formant_path(
    max_num_formants = 5,
    formant_ceiling = 5500
  )
  
  cat("   Duration:", fp2$get_duration(), "s\n")
  cat("   Candidates:", fp2$get_number_of_candidates(), "\n")
  
  # Find optimal ceiling
  optimal_ceiling <- fp2$get_optimal_ceiling()
  cat("   Optimal ceiling:", optimal_ceiling, "Hz\n")
  
  # Get stress for each candidate
  cat("   Testing stress calculation...\n")
  for (i in 1:min(3, fp2$get_number_of_candidates())) {
    stress <- fp2$get_stress_of_candidate(candidate = i)
    cat("     Candidate", i, "stress:", stress, "\n")
  }
  cat("\n")
} else {
  cat("8. Skipping real audio test (file not found)\n\n")
}

# 9. Test print method
cat("9. Testing print method:\n")
fp$print()
cat("\n")

cat("=============================\n")
cat("All FormantPath tests passed!\n")
cat("=============================\n")
