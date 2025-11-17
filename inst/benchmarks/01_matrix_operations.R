# Benchmark 1: Matrix Operations
# Tests: sum, mean, min, max operations on matrices
# Expected SIMD speedup: 4-8x

library(speaker)
library(bench)

# Detect run mode
run_mode <- Sys.getenv("SPEAKER_BENCHMARK_MODE", "baseline")

cat(strrep("=", 80), "\n")
cat(sprintf("Benchmark 1: Matrix Operations [%s mode]\n", toupper(run_mode)))
cat(strrep("=", 80), "\n\n")

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
  mat_obj <- praat_matrix_from_matrix(test_matrix)

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
  print(bench_result[, c("expression", "min", "median", "itr/sec", "mem_alloc")])
  cat("\n")
}

# Save results
output_file <- sprintf("inst/benchmarks/results/01_matrix_operations_%s.rds", run_mode)
saveRDS(results, output_file)

cat(sprintf("\nResults saved to: %s\n", output_file))
if (run_mode == "scalar") {
  cat("Run with RcppXsimd installed to generate SIMD comparison.\n")
} else {
  cat("Compare with scalar results using compare_results.R\n")
}
