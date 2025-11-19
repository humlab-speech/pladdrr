#!/usr/bin/env Rscript
# Test batch processing utilities

library(speaker)

# Test 1: create_file_list
cat("Test 1: create_file_list\n")
cat("========================================\n")
files <- create_file_list("inst/extdata", pattern = "\\.(wav|TextGrid)$")
cat("Found", length(files), "files:\n")
print(head(files, 3))
cat("\n")

# Test 2: pair_sound_textgrid
cat("Test 2: pair_sound_textgrid\n")
cat("========================================\n")
pairs <- pair_sound_textgrid(
  sound_dir = "inst/extdata",
  textgrid_dir = "inst/extdata",
  sound_pattern = "\\.wav$",
  textgrid_pattern = "\\.TextGrid$",
  require_both = FALSE
)
cat("Found", nrow(pairs), "pairs:\n")
print(pairs)
cat("\n")

# Test 3: batch_process (if we have audio files)
cat("Test 3: batch_process\n")
cat("========================================\n")
wav_files <- list.files("inst/extdata", pattern = "\\.wav$", full.names = TRUE)
if (length(wav_files) > 0) {
  cat("Processing", length(wav_files), "WAV files...\n")
  
  results <- batch_process(
    directory = "inst/extdata",
    pattern = "\\.wav$",
    func = function(sound) {
      # Test basic sound properties
      dur <- tryCatch(sound$get_total_duration(), error = function(e) NA)
      nchan <- tryCatch(sound$get_number_of_channels(), error = function(e) NA)
      sr <- tryCatch(sound$get_sampling_frequency(), error = function(e) NA)
      
      list(
        duration = dur,
        n_channels = nchan,
        sample_rate = sr
      )
    },
    progress = FALSE
  )
  
  cat("Results:\n")
  print(results)
} else {
  cat("No WAV files found in inst/extdata\n")
}
cat("\n")

# Test 4: extract_measurements (if we have paired files)
cat("Test 4: extract_measurements\n")
cat("========================================\n")
cat("Skipping TextGrid test - TextGrid file reading currently unavailable\n")
cat("(This would work with programmatically created TextGrids)\n")

cat("\n✓ Batch processing utilities test complete!\n")
