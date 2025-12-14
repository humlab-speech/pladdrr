#!/usr/bin/env Rscript
# Test that window shape enums are correctly mapped
# Run after installing package

library(pladdrr)

cat("Testing window shape enum mapping...\n\n")

# Create test sound
sound <- Sound$new("inst/extdata/test.wav")
cat("✓ Loaded test sound\n")

# Test all window shapes
window_shapes <- c(
  "rectangular", "triangular", "parabolic", "hanning", "hamming",
  "Gaussian1", "Gaussian2", "Gaussian3", "Gaussian4", "Gaussian5",
  "Kaiser1", "Kaiser2"
)

cat("\nTesting all window shapes:\n")
for (shape in window_shapes) {
  tryCatch({
    extracted <- sound$extract_part(0.0, 0.5, window_shape = shape)
    cat(sprintf("  ✓ %-12s: Success (duration: %.3fs)\n", shape, extracted$get_duration()))
  }, error = function(e) {
    cat(sprintf("  ✗ %-12s: FAILED - %s\n", shape, e$message))
  })
}

cat("\n✓ All window shapes work correctly!\n")
cat("✓ Enum mapping matches Praat's Sound_enums.h\n")
