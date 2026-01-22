# Phase 3 Task 3.1: MFCC SIMD Benchmark
#
# Comprehensive benchmarking of SIMD-accelerated MFCC operations
#
# Usage:
#   source("benchmarks/phase3_task3.1_mfcc_benchmark.R")
#
# Expected Performance (Phase 3 Target):
#   - MFCC extraction: 2-4x speedup
#   - Mel filterbank: 2-3x speedup
#   - DCT: 2-3x speedup

library(pladdrr)

cat("\n")
cat(packageStartupMessage("pladdrr"))
cat("\n")
cat("Phase 3 Task 3.1: MFCC SIMD Comprehensive Benchmark\n")
cat("=====================================================\n")
cat("Tasks: Mel-scale conversion, Triangular filterbank, DCT\n")
cat("\n")

# Platform info
cat("Platform:", Sys.info()["machine"], "\n")
cat("R version:", R.version.string, "\n")
cat("pladdrr version:", as.character(packageVersion("pladdrr")), "\n")
cat("\n")

# ============================================================================
# Benchmark Configuration
# ============================================================================

n_iterations <- 50
n_warmup <- 5

# Test signals: different durations
test_signals <- list(
  list(duration = 1, sr = 16000, name = "1s"),
  list(duration = 5, sr = 16000, name = "5s"),
  list(duration = 10, sr = 16000, name = "10s")
)

# Generate speech-like test signals
generate_speech_signal <- function(duration, sr) {
  t <- seq(0, duration, length.out = as.integer(duration * sr))
  # Fundamental + harmonics (speech-like)
  f0 <- 120
  signal <- sin(2 * pi * f0 * t) +
            0.5 * sin(2 * pi * 2 * f0 * t) +
            0.3 * sin(2 * pi * 3 * f0 * t) +
            0.2 * sin(2 * pi * 4 * f0 * t)
  signal / max(abs(signal))
}

# Prepare test data
cat("Generating test signals...\n")
for (i in seq_along(test_signals)) {
  test_signals[[i]]$signal <- generate_speech_signal(
    test_signals[[i]]$duration,
    test_signals[[i]]$sr
  )
}

# ============================================================================
# Task 3.1: MFCC Extraction SIMD
# ============================================================================

cat("\nTask 3.1: MFCC Extraction (Full Pipeline)\n")
cat("==========================================\n\n")

results_mfcc <- list()

for (test_data in test_signals) {
  cat("Signal duration:", test_data$duration, "s (", length(test_data$signal), "samples)\n")

  # Warmup
  for (i in 1:n_warmup) {
    snd <- Sound$from_values(test_data$signal, test_data$sr)
    options(speaker.use_simd = FALSE)
    mfcc_scalar <- snd$to_mfcc(n_coefficients = 13, analysis_width = 0.015, dt = 0.005)
    rm(snd, mfcc_scalar)
    gc(verbose = FALSE)
  }

  # Scalar benchmark
  scalar_times <- numeric(n_iterations)
  for (i in 1:n_iterations) {
    snd <- Sound$from_values(test_data$signal, test_data$sr)
    options(speaker.use_simd = FALSE)
    start_time <- Sys.time()
    mfcc_scalar <- snd$to_mfcc(n_coefficients = 13, analysis_width = 0.015, dt = 0.005)
    end_time <- Sys.time()
    scalar_times[i] <- as.numeric(end_time - start_time) * 1000
    rm(snd, mfcc_scalar)
    gc(verbose = FALSE)
  }

  # SIMD benchmark
  simd_times <- numeric(n_iterations)
  for (i in 1:n_iterations) {
    snd <- Sound$from_values(test_data$signal, test_data$sr)
    options(speaker.use_simd = TRUE)
    start_time <- Sys.time()
    mfcc_simd <- snd$to_mfcc(n_coefficients = 13, analysis_width = 0.015, dt = 0.005)
    end_time <- Sys.time()
    simd_times[i] <- as.numeric(end_time - start_time) * 1000
    rm(snd, mfcc_simd)
    gc(verbose = FALSE)
  }

  scalar_median <- median(scalar_times)
  simd_median <- median(simd_times)
  speedup <- scalar_median / simd_median

  cat("  Scalar median: ", sprintf("%.2f", scalar_median), " ms\n", sep = "")
  cat("  SIMD median:   ", sprintf("%.2f", simd_median), " ms\n", sep = "")
  cat("  Speedup:       ", sprintf("%.2f", speedup), "x\n\n", sep = "")

  results_mfcc[[test_data$name]] <- list(
    duration = test_data$duration,
    scalar_time = scalar_median,
    simd_time = simd_median,
    speedup = speedup
  )
}

# ============================================================================
# Summary Statistics
# ============================================================================

cat("\nPhase 3 Task 3.1 Summary\n")
cat("========================\n\n")

# Create summary table
summary_df <- data.frame(
  task = "MFCC",
  duration_s = sapply(results_mfcc, function(x) x$duration),
  scalar_time_ms = sapply(results_mfcc, function(x) x$scalar_time),
  simd_time_ms = sapply(results_mfcc, function(x) x$simd_time),
  speedup = sapply(results_mfcc, function(x) x$speedup)
)

print(summary_df, row.names = FALSE)
cat("\n")

# Average speedups
mfcc_speedups <- sapply(results_mfcc, function(x) x$speedup)
avg_speedup_mfcc <- mean(mfcc_speedups)
geomean_speedup_mfcc <- exp(mean(log(mfcc_speedups)))

cat("MFCC Average Speedup:\n")
cat("  Arithmetic mean: ", sprintf("%.2f", avg_speedup_mfcc), "x\n", sep = "")
cat("  Geometric mean:  ", sprintf("%.2f", geomean_speedup_mfcc), "x\n", sep = "")
cat("\n")

# Overall performance
all_speedups <- c(mfcc_speedups)
overall_avg <- mean(all_speedups)
overall_geomean <- exp(mean(log(all_speedups)))
best_speedup <- max(all_speedups)
worst_speedup <- min(all_speedups)

cat("Overall Phase 3 Task 3.1 Performance:\n")
cat("  Average speedup:          ", sprintf("%.2f", overall_avg), "x\n", sep = "")
cat("  Geometric mean speedup:   ", sprintf("%.2f", overall_geomean), "x\n", sep = "")
cat("  Best speedup:             ", sprintf("%.2f", best_speedup), "x\n", sep = "")
cat("  Worst speedup:            ", sprintf("%.2f", worst_speedup), "x\n", sep = "")
cat("\n")

# Target achievement
cat("Target vs Achieved:\n")
cat("  Task 3.1 MFCC:  Target 2.0-4.0x, Achieved: ", sprintf("%.2f", geomean_speedup_mfcc), "x\n", sep = "")
cat("\n")

# Platform notes
cat("Platform Notes:\n")
platform <- Sys.info()["machine"]
if (grepl("arm", platform, ignore.case = TRUE)) {
  cat("  - ARM NEON architecture (batch size 2)\n")
  cat("  - Expected higher speedups on x86_64 AVX2 (batch size 4)\n")
} else if (grepl("x86", platform, ignore.case = TRUE)) {
  cat("  - x86_64 architecture with AVX2 (batch size 4)\n")
  cat("  - Optimal SIMD performance\n")
}

# Identify bottlenecks
cat("  - MFCC includes: Mel filterbank (triangular filter), power-to-dB, DCT\n")
cat("  - DCT is computationally intensive (inner products)\n")
cat("  - Triangular filtering benefits from SIMD accumulation\n")
cat("\n")

# Save results
timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
results_file <- sprintf("benchmarks/phase3_task3.1_results_%s.txt", timestamp)

cat("Saving results to:", results_file, "\n")

sink(results_file)
cat("Phase 3 Task 3.1: MFCC SIMD Benchmark Results\n")
cat("==============================================\n")
cat("Date:", format(Sys.time()), "\n")
cat("Platform:", platform, "\n")
cat("R version:", R.version.string, "\n")
cat("pladdrr version:", as.character(packageVersion("pladdrr")), "\n\n")
print(summary_df, row.names = FALSE)
cat("\nOverall geometric mean speedup: ", sprintf("%.2f", overall_geomean), "x\n", sep = "")
sink()

cat("\n=== Phase 3 Task 3.1 Benchmark Complete ===\n")

# Return results invisibly
invisible(list(
  mfcc = results_mfcc,
  summary = summary_df,
  avg_speedup = overall_avg,
  geomean_speedup = overall_geomean
))
