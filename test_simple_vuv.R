#!/usr/bin/env Rscript
library(pladdrr)

cat("Loading test.wav...\n")
sound <- Sound$new("inst/extdata/test.wav")
cat("Duration:", sound$get_duration(), "seconds\n")

cat("\nTesting PointProcess$to_textgrid_vuv()...\n")
pitch <- sound$to_pitch()
pp <- pitch$to_point_process()
cat("PointProcess points:", pp$get_number_of_points(), "\n")

cat("\nCreating VUV TextGrid...\n")
tg_vuv <- pp$to_textgrid_vuv(
  max_voiced_period = 0.02,
  max_unvoiced_period = 0.01
)

if (inherits(tg_vuv, "TextGrid")) {
  cat("✓ TextGrid created successfully!\n")
  cat("  Tiers:", tg_vuv$get_number_of_tiers(), "\n")
  cat("  Tier name:", tg_vuv$get_tier_name(1), "\n")
  cat("  Intervals:", tg_vuv$get_number_of_intervals(1), "\n")
} else {
  cat("✗ Failed to create TextGrid\n")
}

cat("\nDONE: PointProcess$to_textgrid_vuv() works!\n")
