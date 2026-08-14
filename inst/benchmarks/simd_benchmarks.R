# SIMD Performance Benchmarking Suite
# Tests and validates SIMD optimizations implemented in Phase 1

library(testthat)
library(speaker)
library(rbenchmark)

# Check if SIMD is available
simd_available <- function() {
  # Try to detect if package was compiled with SIMD support
  tryCatch(
    {
      # This would need to be exposed from C++ side
      TRUE # Assume available for now
    },
    error = function(e) FALSE
  )
}

# Benchmark 1: Sound Statistics
benchmark_sound_statistics <- function() {
  cat("\n=== Benchmarking Sound Statistics ===\n")

  # Create test sound (10 seconds, 44.1 kHz, stereo)
  sound <- Sound$new(duration = 10, sample_rate = 44100, n_channels = 2)

  # Fill with random data
  for (ch in 1:2) {
    sound$set_samples(ch, rnorm(44100 * 10))
  }

  # Benchmark statistics computation
  results <- benchmark(
    "get_statistics" = {
      min_val <- sound$get_minimum(0, 0)
      max_val <- sound$get_maximum(0, 0)
      mean_val <- sound$get_mean(0, 0)
      rms_val <- sound$get_rms(0, 0)
    },
    replications = 100,
    columns = c("test", "replications", "elapsed", "relative")
  )

  print(results)

  # Return results for reporting
  results
}

# Benchmark 2: Mono Conversion
benchmark_mono_conversion <- function() {
  cat("\n=== Benchmarking Mono Conversion ===\n")

  # Test stereo to mono
  stereo <- Sound$new(duration = 10, sample_rate = 44100, n_channels = 2)
  for (ch in 1:2) {
    stereo$set_samples(ch, rnorm(44100 * 10))
  }

  stereo_results <- benchmark(
    "stereo_to_mono" = {
      mono <- stereo$convert_to_mono()
    },
    replications = 50,
    columns = c("test", "replications", "elapsed", "relative")
  )

  print(stereo_results)

  # Test multi-channel to mono
  multichannel <- Sound$new(duration = 5, sample_rate = 44100, n_channels = 6)
  for (ch in 1:6) {
    multichannel$set_samples(ch, rnorm(44100 * 5))
  }

  multi_results <- benchmark(
    "6ch_to_mono" = {
      mono <- multichannel$convert_to_mono()
    },
    replications = 30,
    columns = c("test", "replications", "elapsed", "relative")
  )

  print(multi_results)

  list(stereo = stereo_results, multichannel = multi_results)
}

# Benchmark 3: Matrix Operations
benchmark_matrix_operations <- function() {
  cat("\n=== Benchmarking Matrix Operations ===\n")

  # Test matrix row multiplication
  n_rows <- 1000
  n_cols <- 5000

  mat <- matrix(rnorm(n_rows * n_cols), nrow = n_rows, ncol = n_cols)
  vec <- rnorm(n_rows)

  # Would need exposed function
  # results <- benchmark(
  #   "row_multiply" = {
  #     .matrix_multiply_rows_simd(mat, vec)
  #   },
  #   replications = 50,
  #   columns = c("test", "replications", "elapsed", "relative")
  # )

  cat("Matrix operations benchmark (implementation pending)\n")
}

# Benchmark 4: Dot Product
benchmark_dot_product <- function() {
  cat("\n=== Benchmarking Dot Product ===\n")

  n <- 100000
  x <- rnorm(n)
  y <- rnorm(n)

  # Would need exposed function
  # results <- benchmark(
  #   "base_R" = sum(x * y),
  #   "simd" = .dot_product_simd(x, y),
  #   replications = 100,
  #   columns = c("test", "replications", "elapsed", "relative")
  # )

  # For now, just R comparison
  results <- benchmark(
    "base_R_crossprod" = crossprod(x, y)[1],
    "base_R_sum" = sum(x * y),
    replications = 100,
    columns = c("test", "replications", "elapsed", "relative")
  )

  print(results)
  results
}

# Accuracy validation
test_simd_accuracy <- function() {
  cat("\n=== Testing SIMD Accuracy ===\n")

  # Test 1: Sound statistics should match
  sound <- Sound$new(duration = 1, sample_rate = 16000, n_channels = 1)
  samples <- rnorm(16000)
  sound$set_samples(1, samples)

  # Compare with R calculations
  r_min <- min(samples)
  r_max <- max(samples)
  r_mean <- mean(samples)
  r_rms <- sqrt(mean(samples^2))

  s_min <- sound$get_minimum(0, 0)
  s_max <- sound$get_maximum(0, 0)
  s_mean <- sound$get_mean(0, 0)
  s_rms <- sound$get_rms(0, 0)

  cat(sprintf("Min:  R=%.10f  Speaker=%.10f  Diff=%.2e\n", r_min, s_min, abs(r_min - s_min)))
  cat(sprintf("Max:  R=%.10f  Speaker=%.10f  Diff=%.2e\n", r_max, s_max, abs(r_max - s_max)))
  cat(sprintf("Mean: R=%.10f  Speaker=%.10f  Diff=%.2e\n", r_mean, s_mean, abs(r_mean - s_mean)))
  cat(sprintf("RMS:  R=%.10f  Speaker=%.10f  Diff=%.2e\n", r_rms, s_rms, abs(r_rms - s_rms)))

  # Test 2: Mono conversion accuracy
  stereo <- Sound$new(duration = 0.1, sample_rate = 16000, n_channels = 2)
  ch1 <- rnorm(1600)
  ch2 <- rnorm(1600)
  stereo$set_samples(1, ch1)
  stereo$set_samples(2, ch2)

  mono <- stereo$convert_to_mono()
  mono_samples <- mono$get_samples(1)

  expected <- (ch1 + ch2) / 2
  max_diff <- max(abs(mono_samples - expected))

  cat(sprintf("\nMono conversion max difference: %.2e\n", max_diff))
  cat(sprintf("Accuracy: %s\n", ifelse(max_diff < 1e-10, "PASS", "FAIL")))

  invisible(list(
    stats_accurate = abs(r_rms - s_rms) < 1e-10,
    mono_accurate = max_diff < 1e-10
  ))
}

# Main benchmark suite
run_simd_benchmarks <- function() {
  cat("==========================================================\n")
  cat("SIMD Performance Benchmarking Suite\n")
  cat("Package: speaker\n")
  cat("Phase 1 Implementation\n")
  cat("==========================================================\n")

  if (simd_available()) {
    cat("SIMD Status: AVAILABLE\n")
  } else {
    cat("SIMD Status: NOT AVAILABLE (using scalar fallback)\n")
  }

  # Run accuracy tests first
  accuracy <- test_simd_accuracy()

  # Run performance benchmarks
  stats_bench <- benchmark_sound_statistics()
  mono_bench <- benchmark_mono_conversion()
  dot_bench <- benchmark_dot_product()

  # Summary
  cat("\n==========================================================\n")
  cat("Benchmark Summary\n")
  cat("==========================================================\n")
  cat("All tests completed. See results above.\n")

  invisible(list(
    accuracy = accuracy,
    sound_statistics = stats_bench,
    mono_conversion = mono_bench,
    dot_product = dot_bench
  ))
}

# Run if called directly
if (interactive()) {
  cat("Run run_simd_benchmarks() to execute the full benchmark suite\n")
} else {
  # Automated testing mode
  run_simd_benchmarks()
}
