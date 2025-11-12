# Benchmark 1: Matrix Operations
# Tests: sum, mean, min, max operations on matrices
# Expected SIMD speedup: 4-8x

library(speaker)
library(bench)

cat("="*80, "\n")
cat("Benchmark 1: Matrix Operations (Baseline - Pre-SIMD)\n")
cat("="*80, "\n\n")

# Test matrices of various sizes
sizes <- list(
  small = c(100, 100),
  medium = c(500, 500),
  large = c(1000, 1000),
  xlarge = c(2000, 2000)
)

results <- list()

for (size_name in names(sizes)) {
  dims <- sizes[[size_name]]
  cat(sprintf("\nTesting %s matrix (%dx%d):\n", size_name, dims[1], dims[2]))

  # Create test matrix
  test_matrix <- matrix(rnorm(dims[1] * dims[2]), dims[1], dims[2])

  # Create Matrix object
  mat_obj <- Matrix$from_r_matrix(test_matrix)

  # Benchmark all operations
  bench_result <- bench::mark(
    sum = mat_obj$get_sum(),
    mean = mat_obj$get_mean(),
    min = mat_obj$get_minimum(),
    max = mat_obj$get_maximum(),
    iterations = 50,
    check = FALSE
  )

  results[[size_name]] <- bench_result

  # Print results
  print(bench_result[, c("expression", "min", "median", "max", "mem_alloc")])
  cat("\n")
}

# Save results
saveRDS(results, "inst/benchmarks/results/01_matrix_operations_baseline.rds")

cat("\nBaseline results saved to: inst/benchmarks/results/01_matrix_operations_baseline.rds\n")
cat("Run this benchmark again after SIMD implementation to compare.\n")
