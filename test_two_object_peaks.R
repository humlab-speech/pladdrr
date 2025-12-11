#!/usr/bin/env Rscript
# Test script for Pitch$to_pointprocess_peaks() (v1.2.2)
# Tests two-object command: [Sound, Pitch] -> To PointProcess (peaks)

library(pladdrr)

cat("Testing Two-Object Peaks Method\n")
cat("================================\n\n")

# Load test sound
sound_file <- "inst/extdata/1.wav"
if (!file.exists(sound_file)) {
  sound_file <- "inst/signalfiles/tremor_1.736Hz_500ms.wav"
}

if (!file.exists(sound_file)) {
  cat("✗ Test sound not found, generating synthetic\n")
  sound <- Sound$create(0.5, 0, 0.5, 16000, 1/16000, 0)
} else {
  cat("Loading:", sound_file, "\n")
  sound <- Sound$new(sound_file)
}

cat("Duration:", sound$get_duration(), "sec\n")
cat("Sample rate:", sound$get_sampling_frequency(), "Hz\n\n")

# Create pitch object
cat("Creating Pitch object...\n")
pitch <- sound$to_pitch(
  time_step = 0.01,
  pitch_floor = 75,
  pitch_ceiling = 600,
  max_candidates = 15,
  very_accurate = FALSE,
  silence_threshold = 0.03,
  voicing_threshold = 0.45,
  octave_cost = 0.01,
  octave_jump_cost = 0.35,
  voiced_unvoiced_cost = 0.14
)

cat("Pitch frames:", pitch$get_number_of_frames(), "\n\n")

# Test new method: Pitch$to_pointprocess_peaks(sound, ...)
cat("Testing Pitch$to_pointprocess_peaks()...\n")

tryCatch({
  # Include maxima (peaks)
  pp_maxima <- pitch$to_pointprocess_peaks(
    sound = sound,
    include_maxima = TRUE,
    include_minima = FALSE
  )
  
  cat("✓ Maxima PointProcess created\n")
  cat("  Points:", pp_maxima$get_number_of_points(), "\n")
  
  # Include minima (valleys)
  pp_minima <- pitch$to_pointprocess_peaks(
    sound = sound,
    include_maxima = FALSE,
    include_minima = TRUE
  )
  
  cat("✓ Minima PointProcess created\n")
  cat("  Points:", pp_minima$get_number_of_points(), "\n")
  
  # Include both
  pp_both <- pitch$to_pointprocess_peaks(
    sound = sound,
    include_maxima = TRUE,
    include_minima = TRUE
  )
  
  cat("✓ Both PointProcess created\n")
  cat("  Points:", pp_both$get_number_of_points(), "\n\n")
  
  # Validate
  if (pp_both$get_number_of_points() < pp_maxima$get_number_of_points()) {
    stop("Both should have >= maxima points")
  }
  
  if (pp_both$get_number_of_points() < pp_minima$get_number_of_points()) {
    stop("Both should have >= minima points")
  }
  
  cat("✓ All validations passed\n")
  
}, error = function(e) {
  cat("✗ FAILED:", conditionMessage(e), "\n")
  traceback()
})

cat("\n=== Two-Object Peaks Test Complete ===\n")
