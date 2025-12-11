#!/usr/bin/env Rscript
# Test script for window shape enum fix (v1.2.2)
# Tests all 12 window types from kSound_windowShape

library(pladdrr)

cat("Testing Window Shape Enum Fix\n")
cat("==============================\n\n")

# Generate test sound
snd <- Sound$create(1, 0, 1, 1000, 0.001, 0)  # 1 sec, 1000 Hz

# All window shapes from Sound_enums.h
windows <- c(
  "rectangular",  # 0
  "triangular",   # 1
  "parabolic",    # 2
  "hanning",      # 3 (FIXED: was 4)
  "hamming",      # 4 (FIXED: was 1)
  "Gaussian1",    # 5
  "Gaussian2",    # 6
  "Gaussian3",    # 7
  "Gaussian4",    # 8
  "Gaussian5",    # 9
  "Kaiser1",      # 10
  "Kaiser2"       # 11
)

cat("Testing all", length(windows), "window shapes:\n\n")

for (win in windows) {
  cat("Testing:", win, "... ")
  
  tryCatch({
    # Extract 0.5 sec with this window
    part <- snd$extract_part(0, 0.5, window_shape = win, 
                             relative_width = 1.0, preserve_times = FALSE)
    
    # Basic validation
    if (!inherits(part, "Sound")) {
      stop("Did not return Sound object")
    }
    
    dur <- part$get_duration()
    if (abs(dur - 0.5) > 0.001) {
      stop(sprintf("Wrong duration: %.3f (expected 0.5)", dur))
    }
    
    cat("✓ PASS\n")
  }, error = function(e) {
    cat("✗ FAIL:", conditionMessage(e), "\n")
  })
}

cat("\n=== Window Shape Test Complete ===\n")
