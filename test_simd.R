#!/usr/bin/env Rscript
# Test script to verify SIMD optimizations are working

library(speaker)

cat(strrep("=", 80), "\n")
cat("Testing SIMD Implementation\n")
cat(strrep("=", 80), "\n\n")

# Create a large matrix
cat("Creating 1000x1000 test matrix...\n")
test_data <- matrix(rnorm(1000 * 1000), 1000, 1000)
mat <- praat_matrix_from_matrix(test_data)

# Test sum
cat("\nTesting sum operation:\n")
system.time({
  result_sum <- mat$get_sum()
})
r_sum <- sum(test_data)
cat(sprintf("  Matrix sum: %.6f\n", result_sum))
cat(sprintf("  R sum:      %.6f\n", r_sum))
cat(sprintf("  Match: %s\n", ifelse(abs(result_sum - r_sum) < 1e-6, "YES ✓", "NO ✗")))

# Test mean
cat("\nTesting mean operation:\n")
system.time({
  result_mean <- mat$get_mean()
})
r_mean <- mean(test_data)
cat(sprintf("  Matrix mean: %.6f\n", result_mean))
cat(sprintf("  R mean:      %.6f\n", r_mean))
cat(sprintf("  Match: %s\n", ifelse(abs(result_mean - r_mean) < 1e-6, "YES ✓", "NO ✗")))

# Test min
cat("\nTesting min operation:\n")
system.time({
  result_min <- mat$get_minimum()
})
r_min <- min(test_data)
cat(sprintf("  Matrix min: %.6f\n", result_min))
cat(sprintf("  R min:      %.6f\n", r_min))
cat(sprintf("  Match: %s\n", ifelse(abs(result_min - r_min) < 1e-6, "YES ✓", "NO ✗")))

# Test max
cat("\nTesting max operation:\n")
system.time({
  result_max <- mat$get_maximum()
})
r_max <- max(test_data)
cat(sprintf("  Matrix max: %.6f\n", result_max))
cat(sprintf("  R max:      %.6f\n", r_max))
cat(sprintf("  Match: %s\n", ifelse(abs(result_max - r_max) < 1e-6, "YES ✓", "NO ✗")))

cat("\n")
cat(strrep("=", 80), "\n")
cat("SIMD Test Complete\n")
cat(strrep("=", 80), "\n")
