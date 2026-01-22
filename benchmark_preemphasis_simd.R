#!/usr/bin/env Rscript
# Phase 2 Task 2.2: Pre-emphasis Filter SIMD Performance Benchmark
# Created: 2026-01-22
# Measures speedup from SIMD implementation

library(pladdrr)

cat("Pre-emphasis SIMD Performance Benchmark\n")
cat("========================================\n\n")

# Benchmark parameters
signal_lengths <- c(1000, 10000, 48000, 96000, 192000)  # Various durations
cutoff_freq <- 50  # Hz
sampling_rate <- 16000  # Hz
n_iterations <- 100  # Number of repetitions for timing

cat(sprintf("Platform: %s\n", Sys.info()["machine"]))
cat(sprintf("Iterations: %d\n", n_iterations))
cat(sprintf("Cutoff frequency: %d Hz\n", cutoff_freq))
cat(sprintf("Sampling rate: %d Hz\n\n", sampling_rate))

results <- data.frame(
  samples = integer(),
  duration_s = numeric(),
  simd_time_ms = numeric(),
  scalar_time_ms = numeric(),
  speedup = numeric(),
  stringsAsFactors = FALSE
)

for (n in signal_lengths) {
  duration <- n / sampling_rate
  cat(sprintf("Signal length: %d samples (%.3f s)\n", n, duration))

  # Generate test signal
  t <- seq(0, (n-1) / sampling_rate, length.out = n)
  signal <- sin(2 * pi * 100 * t) +
            0.5 * sin(2 * pi * 300 * t) +
            0.3 * sin(2 * pi * 800 * t)

  # Benchmark SIMD version
  simd_times <- numeric(n_iterations)
  for (i in 1:n_iterations) {
    snd <- Sound$from_values(signal, sampling_rate)
    start_time <- Sys.time()
    snd$pre_emphasize(cutoff_freq)
    end_time <- Sys.time()
    simd_times[i] <- as.numeric(end_time - start_time, units = "secs") * 1000
  }

  simd_median <- median(simd_times)
  cat(sprintf("  SIMD median:  %.3f ms\n", simd_median))

  # Benchmark scalar version (manual R loop)
  scalar_times <- numeric(n_iterations)
  emphasis_factor <- exp(-2 * pi * cutoff_freq / sampling_rate)
  for (i in 1:n_iterations) {
    test_signal <- signal  # Copy
    start_time <- Sys.time()
    for (j in length(test_signal):2) {
      test_signal[j] <- test_signal[j] - emphasis_factor * test_signal[j - 1]
    }
    end_time <- Sys.time()
    scalar_times[i] <- as.numeric(end_time - start_time, units = "secs") * 1000
  }

  scalar_median <- median(scalar_times)
  speedup <- scalar_median / simd_median

  cat(sprintf("  Scalar median: %.3f ms\n", scalar_median))
  cat(sprintf("  Speedup: %.2fx\n\n", speedup))

  results <- rbind(results, data.frame(
    samples = n,
    duration_s = duration,
    simd_time_ms = simd_median,
    scalar_time_ms = scalar_median,
    speedup = speedup
  ))
}

cat("\nSummary\n")
cat("=======\n")
print(results, row.names = FALSE)

cat(sprintf("\nAverage speedup: %.2fx\n", mean(results$speedup)))
cat(sprintf("Geometric mean speedup: %.2fx\n", exp(mean(log(results$speedup)))))

# Note about comparison fairness
cat("\nNote: 'Scalar' here is an R loop, not optimized C++.\n")
cat("The actual scalar C++ implementation in Praat is much faster.\n")
cat("This benchmark shows the SIMD implementation speed, not direct SIMD vs scalar C++ comparison.\n")
