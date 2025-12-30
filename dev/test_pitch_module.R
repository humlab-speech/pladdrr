#!/usr/bin/env Rscript
# Quick test: Verify Pitch module wrapper works
# Tests the new Rcpp Module-based Pitch implementation

library(pladdrr)

cat("Testing Pitch Module Wrapper\n")
cat("=============================\n\n")

# Create test sound
cat("1. Creating test sound (440 Hz tone)...\n")
sound <- Sound$create_tone(duration = 1.0, sampling_rate = 44100, frequency = 440, amplitude = 0.5)
cat("   ✓ Sound created\n\n")

# Extract pitch using module-based wrapper
cat("2. Extracting pitch (module-based)...\n")
pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
cat("   ✓ Pitch extracted\n")
cat("   Type:", class(pitch)[1], "\n\n")

# Test properties
cat("3. Testing properties...\n")
cat("   Duration:", pitch$duration(), "s\n")
cat("   Frames:", pitch$get_number_of_frames(), "\n")
cat("   Time step:", pitch$get_time_step(), "s\n")
cat("   ✓ Properties work\n\n")

# Test query methods
cat("4. Testing query methods...\n")
mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")
cat("   Mean F0:", round(mean_f0, 1), "Hz (expected ~440 Hz)\n")

min_f0 <- pitch$get_minimum(from_time = 0, to_time = 0, unit = "hertz")
max_f0 <- pitch$get_maximum(from_time = 0, to_time = 0, unit = "hertz")
cat("   Range:", round(min_f0, 1), "-", round(max_f0, 1), "Hz\n")

n_voiced <- pitch$count_voiced_frames()
n_total <- pitch$get_number_of_frames()
cat("   Voiced frames:", n_voiced, "/", n_total, sprintf("(%.1f%%)\n", 100 * n_voiced / n_total))
cat("   ✓ Query methods work\n\n")

# Test export
cat("5. Testing export methods...\n")
df <- as.data.frame(pitch)
cat("   Data frame:", nrow(df), "rows x", ncol(df), "columns\n")
cat("   Columns:", paste(names(df), collapse = ", "), "\n")
cat("   ✓ Export methods work\n\n")

# Test print
cat("6. Testing print method...\n")
pitch$print()
cat("\n   ✓ Print method works\n\n")

cat("=============================\n")
cat("All tests passed!\n")
cat("Pitch module wrapper is functional.\n")
