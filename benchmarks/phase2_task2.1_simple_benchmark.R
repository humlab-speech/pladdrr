# phase2_task2.1_simple_benchmark.R
# Simplified SIMD Phase 2, Task 2.1 Benchmark
# Author: Claude (2026-01-22)

library(pladdrr)
library(microbenchmark)

print_section <- function(title) {
  cat("\n", paste0(rep("=", 70), collapse = ""), "\n", title, "\n",
      paste0(rep("=", 70), collapse = ""), "\n\n", sep = "")
}

print_section("Phase 2 Task 2.1: Spectrogram SIMD Benchmark")

simd_status <- simd_info()
cat("System:\n")
cat(sprintf("  pladdrr: %s\n", packageVersion("pladdrr")))
cat(sprintf("  SIMD: %s (%s)\n", simd_status$enabled, simd_status$architecture))
cat(sprintf("  Batch size: %d doubles\n\n", simd_status$batch_size_double))

if (!simd_status$enabled) stop("SIMD not available")

# Create test sound
cat("Creating 5 second test signal...\n")
test_sound <- Sound$create_tone(440, duration = 5.0)

TIMES <- 50

# Test with Gaussian window (most commonly used)
print_section("Gaussian Window Spectrogram")

cat("Scalar version...\n")
options(speaker.use_simd = FALSE)
bench_scalar <- microbenchmark(
  test_sound$to_spectrogram(window_length = 0.005, max_frequency = 5000,
                             time_step = 0.002, frequency_step = 20,
                             window_shape = "Gaussian"),
  times = TIMES, unit = "ms"
)
scalar_median <- median(bench_scalar$time) / 1e6

cat("SIMD version...\n")
options(speaker.use_simd = TRUE)
bench_simd <- microbenchmark(
  test_sound$to_spectrogram(window_length = 0.005, max_frequency = 5000,
                             time_step = 0.002, frequency_step = 20,
                             window_shape = "Gaussian"),
  times = TIMES, unit = "ms"
)
simd_median <- median(bench_simd$time) / 1e6

speedup <- scalar_median / simd_median

print_section("Results")
cat(sprintf("Scalar:  %.2f ms (median)\n", scalar_median))
cat(sprintf("SIMD:    %.2f ms (median)\n", simd_median))
cat(sprintf("Speedup: %.2fx\n\n", speedup))

cat("SIMD optimizations in Task 2.1:\n")
cat("  1. extract_and_window_frame_simd() - frame extraction + windowing\n")
cat("  2. accumulate_power_spectrum_simd() - complex FFT to power\n")
cat("  3. zero_fft_tail_simd() - zero-fill FFT tail\n\n")

cat(sprintf("Platform: %s\n", simd_status$architecture))
cat(sprintf("Date: %s\n", Sys.time()))

options(speaker.use_simd = TRUE)
