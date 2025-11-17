#!/usr/bin/env Rscript
# 12_phase3_window_functions.R
# Benchmark window functions (SIMD Phase 3)

library(speaker)
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
    hamming_scalar = .apply_hamming_window_scalar(data),
    hamming_simd = if (exists(".apply_hamming_window_simd")) 
      .apply_hamming_window_simd(data) else NA,
    hanning_scalar = .apply_hanning_window_scalar(data),
    hanning_simd = if (exists(".apply_hanning_window_simd")) 
      .apply_hanning_window_simd(data) else NA,
    gaussian_scalar = .apply_gaussian_window_scalar(data, 0.4),
    gaussian_simd = if (exists(".apply_gaussian_window_simd")) 
      .apply_gaussian_window_simd(data, 0.4) else NA,
    iterations = 100,
    check = FALSE
  )
  
  print(result[, c("expression", "median", "mem_alloc")])
  
  # Calculate speedups
  if (exists(".apply_hamming_window_simd")) {
    hamming_speedup <- median(result$time[result$expression == "hamming_scalar"]) /
                      median(result$time[result$expression == "hamming_simd"])
    cat(sprintf("  Hamming speedup: %.2fx\n", hamming_speedup))
    
    hanning_speedup <- median(result$time[result$expression == "hanning_scalar"]) /
                      median(result$time[result$expression == "hanning_simd"])
    cat(sprintf("  Hanning speedup: %.2fx\n", hanning_speedup))
    
    gaussian_speedup <- median(result$time[result$expression == "gaussian_scalar"]) /
                       median(result$time[result$expression == "gaussian_simd"])
    cat(sprintf("  Gaussian speedup: %.2fx\n", gaussian_speedup))
  }
  
  results[[size_name]] <- result
}

# Save results
saveRDS(results, "inst/benchmarks/results/12_phase3_window_functions_baseline.rds")
cat("\n✓ Window functions benchmark complete\n")
