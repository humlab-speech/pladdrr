# phase2_task2.1_benchmark.R
# SIMD Phase 2, Task 2.1: Spectrogram Generation Benchmarks
# Tests SIMD optimizations for frame extraction, windowing, and power spectrum
# Author: Claude (2026-01-21)

library(pladdrr)
library(microbenchmark)

# ============================================================================
# Configuration
# ============================================================================

BENCHMARK_TIMES <- 100  # Number of iterations
WARMUP_ITERATIONS <- 10

# Test parameters - various audio lengths
TEST_DURATIONS <- c(1.0, 5.0, 10.0)  # seconds
TEST_FREQUENCY <- 440  # Hz

# ============================================================================
# Helper Functions
# ============================================================================

print_section <- function(title) {
  cat("\n")
  cat(paste0(rep("=", 75), collapse = ""), "\n")
  cat(title, "\n")
  cat(paste0(rep("=", 75), collapse = ""), "\n\n")
}

report_speedup <- function(scalar_time, simd_time, operation) {
  speedup <- scalar_time / simd_time
  cat(sprintf("%-40s: %.2fx speedup (SIMD: %7.2f ms, Scalar: %7.2f ms)\n",
              operation, speedup, simd_time, scalar_time))
  return(speedup)
}

# ============================================================================
# Setup
# ============================================================================

print_section("SIMD Phase 2, Task 2.1: Spectrogram Generation Benchmark")

simd_status <- simd_info()
cat("System Information:\n")
cat(sprintf("  R version: %s\n", R.version.string))
cat(sprintf("  pladdrr version: %s\n", packageVersion("pladdrr")))
cat(sprintf("  SIMD enabled: %s\n", simd_status$enabled))
cat(sprintf("  SIMD architecture: %s\n", simd_status$architecture))
cat(sprintf("  SIMD batch size: %d doubles\n", simd_status$batch_size_double))
cat("\n")

if (!simd_status$enabled) {
  stop("SIMD not available - cannot run benchmark")
}

# ============================================================================
# Phase 2 Task 2.1: Spectrogram SIMD Benchmarks
# ============================================================================

# Three SIMD optimizations:
# 1. extract_and_window_frame_simd - combines frame extraction and windowing
# 2. accumulate_power_spectrum_simd - converts complex FFT to power spectrum
# 3. zero_fft_tail_simd - zero-fills FFT buffer

results <- list()

for (duration in TEST_DURATIONS) {
  print_section(sprintf("Testing with %.1f second audio", duration))

  # Create test sound
  cat(sprintf("Creating %.1f second test signal... ", duration))
  test_sound <- Sound$create_tone(TEST_FREQUENCY, duration = duration)
  cat("done\n\n")

  # Test 1: Different window shapes (affects extract_and_window_frame_simd)
  cat("Benchmark 1: Window shape performance\n")
  cat(paste0(rep("-", 75), collapse = ""), "\n")

  window_shapes <- c("Gaussian", "Hamming", "Hanning", "Square")
  window_results <- list()

  for (shape in window_shapes) {
    # Scalar
    options(speaker.use_simd = FALSE)
    bench_scalar <- microbenchmark(
      test_sound$to_spectrogram(window_length = 0.005,
                                 max_frequency = 5000,
                                 time_step = 0.002,
                                 frequency_step = 20,
                                 window_shape = shape),
      times = BENCHMARK_TIMES,
      unit = "ms"
    )
    scalar_median <- median(bench_scalar$time) / 1e6

    # SIMD
    options(speaker.use_simd = TRUE)
    bench_simd <- microbenchmark(
      test_sound$to_spectrogram(window_length = 0.005,
                                 max_frequency = 5000,
                                 time_step = 0.002,
                                 frequency_step = 20,
                                 window_shape = shape),
      times = BENCHMARK_TIMES,
      unit = "ms"
    )
    simd_median <- median(bench_simd$time) / 1e6

    speedup <- report_speedup(scalar_median, simd_median,
                               sprintf("  %s window", shape))
    window_results[[shape]] <- list(
      scalar = scalar_median,
      simd = simd_median,
      speedup = speedup
    )
  }

  cat("\n")

  # Test 2: Different frequency ranges (affects FFT size and power spectrum)
  cat("Benchmark 2: Frequency range performance\n")
  cat(paste0(rep("-", 75), collapse = ""), "\n")

  freq_ranges <- c(2500, 5000, 8000)
  freq_results <- list()

  for (max_freq in freq_ranges) {
    # Scalar
    options(speaker.use_simd = FALSE)
    bench_scalar <- microbenchmark(
      test_sound$to_spectrogram(window_length = 0.005,
                                 max_frequency = max_freq,
                                 time_step = 0.002,
                                 frequency_step = 20,
                                 window_shape = "Gaussian"),
      times = BENCHMARK_TIMES,
      unit = "ms"
    )
    scalar_median <- median(bench_scalar$time) / 1e6

    # SIMD
    options(speaker.use_simd = TRUE)
    bench_simd <- microbenchmark(
      test_sound$to_spectrogram(window_length = 0.005,
                                 max_frequency = max_freq,
                                 time_step = 0.002,
                                 frequency_step = 20,
                                 window_shape = "Gaussian"),
      times = BENCHMARK_TIMES,
      unit = "ms"
    )
    simd_median <- median(bench_simd$time) / 1e6

    speedup <- report_speedup(scalar_median, simd_median,
                               sprintf("  Max freq %d Hz", max_freq))
    freq_results[[as.character(max_freq)]] <- list(
      scalar = scalar_median,
      simd = simd_median,
      speedup = speedup
    )
  }

  cat("\n")

  # Test 3: Different window lengths (affects frame size)
  cat("Benchmark 3: Window length performance\n")
  cat(paste0(rep("-", 75), collapse = ""), "\n")

  window_lengths <- c(0.003, 0.005, 0.010)
  length_results <- list()

  for (win_len in window_lengths) {
    # Scalar
    options(speaker.use_simd = FALSE)
    bench_scalar <- microbenchmark(
      test_sound$to_spectrogram(window_length = win_len,
                                 max_frequency = 5000,
                                 time_step = 0.002,
                                 frequency_step = 20,
                                 window_shape = "Gaussian"),
      times = BENCHMARK_TIMES,
      unit = "ms"
    )
    scalar_median <- median(bench_scalar$time) / 1e6

    # SIMD
    options(speaker.use_simd = TRUE)
    bench_simd <- microbenchmark(
      test_sound$to_spectrogram(window_length = win_len,
                                 max_frequency = 5000,
                                 time_step = 0.002,
                                 frequency_step = 20,
                                 window_shape = "Gaussian"),
      times = BENCHMARK_TIMES,
      unit = "ms"
    )
    simd_median <- median(bench_simd$time) / 1e6

    speedup <- report_speedup(scalar_median, simd_median,
                               sprintf("  Window length %.3f s", win_len))
    length_results[[as.character(win_len)]] <- list(
      scalar = scalar_median,
      simd = simd_median,
      speedup = speedup
    )
  }

  # Store results for this duration
  results[[sprintf("duration_%.1f", duration)]] <- list(
    window_shapes = window_results,
    freq_ranges = freq_results,
    window_lengths = length_results
  )
}

# ============================================================================
# Summary Report
# ============================================================================

print_section("Summary Report")

cat("Average Speedups by Test Category:\n\n")

for (dur_name in names(results)) {
  duration <- as.numeric(gsub("duration_", "", dur_name))
  cat(sprintf("%.1f second audio:\n", duration))

  # Window shapes average
  window_speedups <- sapply(results[[dur_name]]$window_shapes, function(x) x$speedup)
  cat(sprintf("  Window shapes:  %.2fx (%.2f - %.2fx)\n",
              mean(window_speedups), min(window_speedups), max(window_speedups)))

  # Frequency ranges average
  freq_speedups <- sapply(results[[dur_name]]$freq_ranges, function(x) x$speedup)
  cat(sprintf("  Freq ranges:    %.2fx (%.2f - %.2fx)\n",
              mean(freq_speedups), min(freq_speedups), max(freq_speedups)))

  # Window lengths average
  length_speedups <- sapply(results[[dur_name]]$window_lengths, function(x) x$speedup)
  cat(sprintf("  Window lengths: %.2fx (%.2f - %.2fx)\n",
              mean(length_speedups), min(length_speedups), max(length_speedups)))

  cat("\n")
}

# Overall statistics
all_speedups <- unlist(lapply(results, function(dur) {
  c(sapply(dur$window_shapes, function(x) x$speedup),
    sapply(dur$freq_ranges, function(x) x$speedup),
    sapply(dur$window_lengths, function(x) x$speedup))
}))

cat(sprintf("Overall Performance:\n"))
cat(sprintf("  Mean speedup:   %.2fx\n", mean(all_speedups)))
cat(sprintf("  Median speedup: %.2fx\n", median(all_speedups)))
cat(sprintf("  Min speedup:    %.2fx\n", min(all_speedups)))
cat(sprintf("  Max speedup:    %.2fx\n", max(all_speedups)))
cat("\n")

cat("Phase 2 Task 2.1 Spectrogram SIMD optimizations:\n")
cat("  1. extract_and_window_frame_simd - combines frame extraction + windowing\n")
cat("  2. accumulate_power_spectrum_simd - complex FFT to power spectrum\n")
cat("  3. zero_fft_tail_simd - zero-fill FFT buffer tail\n")
cat("\n")

cat("Benchmark completed!\n")
cat(sprintf("Date: %s\n", Sys.time()))
cat(sprintf("Architecture: %s\n", simd_status$architecture))

# Reset to default
options(speaker.use_simd = TRUE)
