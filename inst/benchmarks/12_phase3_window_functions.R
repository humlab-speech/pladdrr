#!/usr/bin/env Rscript
# 12_phase3_window_functions.R
# Benchmark window functions (SIMD Phase 3)

library(pladdrr)
library(bench)

cat("\n=== Phase 3: Window Functions Benchmark ===\n")
cat("Target speedup: 4-6x (EPYC), 2.5-3x (M1)\n")
cat("Operations: Hamming, Hanning, Gaussian windows\n\n")

# Test sizes
test_sizes <- list(
  small = list(name = "Small (256 samples, typical FFT frame)", n = 256),
  medium = list(name = "Medium (1024 samples, spectrogram frame)", n = 1024),
  large = list(name = "Large (4096 samples, high-res FFT)", n = 4096),
  xlarge = list(name = "X-Large (16384 samples, very high-res)", n = 16384)
)

results <- list()

for (size_name in names(test_sizes)) {
  size_info <- test_sizes[[size_name]]
  cat("\nBenchmarking:", size_info$name, "\n")

  # Generate test signal (sine wave with noise)
  data <- sin(2 * pi * seq(0, 1, length.out = size_info$n) * 5) +
    rnorm(size_info$n, sd = 0.1)

  # Benchmark window functions
  result <- bench::mark(
    hamming_scalar = pladdrr:::.apply_hamming_window_scalar(data),
    hamming_simd = pladdrr:::.apply_hamming_window_simd(data),
    hanning_scalar = pladdrr:::.apply_hanning_window_scalar(data),
    hanning_simd = pladdrr:::.apply_hanning_window_simd(data),
    gaussian_scalar = pladdrr:::.apply_gaussian_window_scalar(data, 0.4),
    gaussian_simd = pladdrr:::.apply_gaussian_window_simd(data, 0.4),
    iterations = 100,
    check = FALSE
  )

  print(result[, c("expression", "median", "mem_alloc")])

  # Calculate speedups
  expr <- as.character(result$expression)
  hamming_speedup <- as.numeric(result$median[expr == "hamming_scalar"]) /
    as.numeric(result$median[expr == "hamming_simd"])
  cat(sprintf("  Hamming speedup: %.2fx\n", hamming_speedup))

  hanning_speedup <- as.numeric(result$median[expr == "hanning_scalar"]) /
    as.numeric(result$median[expr == "hanning_simd"])
  cat(sprintf("  Hanning speedup: %.2fx\n", hanning_speedup))

  gaussian_speedup <- as.numeric(result$median[expr == "gaussian_scalar"]) /
    as.numeric(result$median[expr == "gaussian_simd"])
  cat(sprintf("  Gaussian speedup: %.2fx\n", gaussian_speedup))

  results[[size_name]] <- result
}

# Save results
dir.create("inst/benchmarks/results", recursive = TRUE, showWarnings = FALSE)
saveRDS(
  results,
  "inst/benchmarks/results/12_phase3_window_functions_baseline.rds"
)
cat("\n✓ Window functions benchmark complete\n")
