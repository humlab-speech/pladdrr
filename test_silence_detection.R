#!/usr/bin/env Rscript
library(pladdrr)

cat("Loading test.wav...\n")
sound <- Sound$new("inst/extdata/test.wav")
cat("Duration:", sound$get_duration(), "seconds\n")
cat("Sampling rate:", sound$get_sampling_frequency(), "Hz\n")

cat("\nTesting Sound$to_textgrid_silences()...\n")
cat("Calling with minimal parameters...\n")

# Use safe defaults
result <- tryCatch({
  tg_silence <- sound$to_textgrid_silences(
    min_pitch = 100,
    time_step = 0.01,
    silence_threshold = -25,
    min_silent_duration = 0.1,
    min_sounding_duration = 0.1,
    silent_label = "silent",
    sounding_label = "sounding"
  )
  tg_silence
}, error = function(e) {
  cat("ERROR:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(result) && inherits(result, "TextGrid")) {
  cat("✓ TextGrid created successfully!\n")
  cat("  Tiers:", result$get_number_of_tiers(), "\n")
  cat("  Tier name:", result$get_tier_name(1), "\n")
  cat("  Intervals:", result$get_number_of_intervals(1), "\n")
} else {
  cat("✗ Failed to create TextGrid\n")
}

cat("\nDONE\n")
