#!/usr/bin/env Rscript
# Quick POC Module Test via sourceCpp
# POC Day 5 - Load and verify POC module

cat("=== Loading POC Module via sourceCpp ===\n\n")

library(Rcpp)
library(pladdrr)

# Find test file
test_file <- "inst/extdata/test.wav"
if (!file.exists(test_file)) {
  test_file <- "inst/extdata/hallo.wav"
  if (!file.exists(test_file)) {
    stop("No test audio file found")
  }
}

cat("Test file:", test_file, "\n")

# Load POC module
cat("\nLoading sound_module_poc.cpp...\n")
sourceCpp("src/sound_module_poc.cpp", verbose = FALSE)

cat("✓ Module loaded successfully\n\n")

# Test basic functionality
cat("=== Testing Basic Functionality ===\n")

# Create Sound object
cat("Creating SoundModulePOC object...\n")
sound_poc <- new(SoundModulePOC, test_file)
cat("✓ Object created\n\n")

# Test queries
cat("Testing query methods:\n")
duration <- sound_poc$get_duration()
cat(sprintf("  Duration: %.3f seconds\n", duration))

sampling_freq <- sound_poc$get_sampling_frequency()
cat(sprintf("  Sampling frequency: %.0f Hz\n", sampling_freq))

n_samples <- sound_poc$get_number_of_samples()
cat(sprintf("  Number of samples: %d\n", n_samples))

n_channels <- sound_poc$get_number_of_channels()
cat(sprintf("  Number of channels: %d\n", n_channels))

cat("✓ All queries working\n\n")

# Test transform
cat("Testing transform method (to_pitch):\n")
pitch <- sound_poc$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
cat("  Pitch object created\n")

# Query pitch
pitch_obj <- Pitch$new(.xptr = pitch)
n_frames <- pitch_obj$get_number_of_frames()
cat(sprintf("  Pitch frames: %d\n", n_frames))

if (n_frames > 0) {
  mean_f0 <- pitch_obj$get_mean(from_time = 0, to_time = 0, unit = "hertz")
  cat(sprintf("  Mean F0: %.2f Hz\n", mean_f0))
}

cat("✓ Transform working\n\n")

# Test export
cat("Testing export method (as_matrix):\n")
mat <- sound_poc$as_matrix()
cat(sprintf("  Matrix dimensions: %d x %d\n", nrow(mat), ncol(mat)))
cat("✓ Export working\n\n")

# Test modification
cat("Testing modification method (scale_intensity):\n")
sound_poc$scale_intensity(70)
cat("  Intensity scaled to 70 dB\n")
cat("✓ Modification working\n\n")

cat("=== ALL TESTS PASSED ===\n")
cat("\nPOC module is fully functional!\n")
cat("Ready to run performance and memory benchmarks.\n\n")

cat("Next steps:\n")
cat("1. Run: Rscript benchmark_sound_poc.R\n")
cat("2. Run: Rscript test_sound_memory.R\n")
cat("3. Run: R -d valgrind --vanilla < test_sound_memory.R\n")
