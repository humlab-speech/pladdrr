# benchmarks/phase4_task4.1_formantpath_benchmark.R
#
# Benchmark suite for Phase 4 Task 4.1: FormantPath SIMD
#
# Tests performance of SIMD-accelerated FormantPath dynamic programming
# Target speedup: 2-3x on multi-ceiling formant extraction

library(pladdrr)
library(microbenchmark)

cat("========================================\n")
cat("Phase 4 Task 4.1: FormantPath SIMD Benchmark\n")
cat("========================================\n\n")

# Display SIMD info
simd_info <- pladdrr::simd_info()
cat("SIMD Available:", simd_info$available, "\n")
if (simd_info$available) {
  cat("Instruction Set:", simd_info$instruction_set, "\n")
  cat("Batch Size:", simd_info$batch_size, "\n")
}
cat("\n")

# Helper: Create synthetic vowel
create_test_vowel <- function(duration = 1.0, sr = 16000) {
  t <- seq(0, duration, length.out = duration * sr)
  f0 <- 150
  
  # Synthesize vowel with formants
  signal <- sin(2 * pi * f0 * t) * 0.3
  signal <- signal + sin(2 * pi * 700 * t) * 0.4   # F1
  signal <- signal + sin(2 * pi * 1200 * t) * 0.3  # F2
  signal <- signal + sin(2 * pi * 2500 * t) * 0.2  # F3
  signal <- signal + rnorm(length(signal), 0, 0.05)
  signal <- signal / max(abs(signal)) * 0.9
  
  Sound$create(signal, sampling_rate = sr)
}

# ==============================================================================
# Benchmark 1: FormantPath extraction (3 candidates)
# ==============================================================================
cat("Benchmark 1: FormantPath extraction (3 candidates)\n")
cat("---------------------------------------------------\n")

durations <- c(1, 5)
results_fp3 <- list()

for (dur in durations) {
  cat(sprintf("\nDuration: %ds\n", dur))
  sound <- create_test_vowel(duration = dur, sr = 16000)
  
  # Warmup
  for (i in 1:3) {
    options(speaker.use_simd = FALSE)
    fp <- sound$to_formant_path(
      time_step = 0.01,
      max_formants = 5.0,
      middle_ceiling = 5500,
      ceiling_step_size = 0.05,
      number_of_steps = 1  # 3 candidates
    )
  }
  
  # Scalar benchmark
  options(speaker.use_simd = FALSE)
  time_scalar <- microbenchmark(
    {
      fp <- sound$to_formant_path(
        time_step = 0.01,
        max_formants = 5.0,
        middle_ceiling = 5500,
        ceiling_step_size = 0.05,
        number_of_steps = 1
      )
    },
    times = 20,
    unit = "ms"
  )
  
  # SIMD benchmark
  options(speaker.use_simd = TRUE)
  time_simd <- microbenchmark(
    {
      fp <- sound$to_formant_path(
        time_step = 0.01,
        max_formants = 5.0,
        middle_ceiling = 5500,
        ceiling_step_size = 0.05,
        number_of_steps = 1
      )
    },
    times = 20,
    unit = "ms"
  )
  
  median_scalar <- median(time_scalar$time) / 1e6
  median_simd <- median(time_simd$time) / 1e6
  speedup <- median_scalar / median_simd
  
  cat(sprintf("  Scalar: %.2f ms\n", median_scalar))
  cat(sprintf("  SIMD:   %.2f ms\n", median_simd))
  cat(sprintf("  Speedup: %.2fx\n", speedup))
  
  results_fp3[[as.character(dur)]] <- list(
    duration = dur,
    scalar = median_scalar,
    simd = median_simd,
    speedup = speedup
  )
}

# ==============================================================================
# Benchmark 2: FormantPath extraction (5 candidates)
# ==============================================================================
cat("\n\nBenchmark 2: FormantPath extraction (5 candidates)\n")
cat("---------------------------------------------------\n")

results_fp5 <- list()

for (dur in durations) {
  cat(sprintf("\nDuration: %ds\n", dur))
  sound <- create_test_vowel(duration = dur, sr = 16000)
  
  # Warmup
  for (i in 1:3) {
    options(speaker.use_simd = FALSE)
    fp <- sound$to_formant_path(
      time_step = 0.01,
      max_formants = 5.0,
      middle_ceiling = 5500,
      ceiling_step_size = 0.05,
      number_of_steps = 2  # 5 candidates
    )
  }
  
  # Scalar benchmark
  options(speaker.use_simd = FALSE)
  time_scalar <- microbenchmark(
    {
      fp <- sound$to_formant_path(
        time_step = 0.01,
        max_formants = 5.0,
        middle_ceiling = 5500,
        ceiling_step_size = 0.05,
        number_of_steps = 2
      )
    },
    times = 20,
    unit = "ms"
  )
  
  # SIMD benchmark
  options(speaker.use_simd = TRUE)
  time_simd <- microbenchmark(
    {
      fp <- sound$to_formant_path(
        time_step = 0.01,
        max_formants = 5.0,
        middle_ceiling = 5500,
        ceiling_step_size = 0.05,
        number_of_steps = 2
      )
    },
    times = 20,
    unit = "ms"
  )
  
  median_scalar <- median(time_scalar$time) / 1e6
  median_simd <- median(time_simd$time) / 1e6
  speedup <- median_scalar / median_simd
  
  cat(sprintf("  Scalar: %.2f ms\n", median_scalar))
  cat(sprintf("  SIMD:   %.2f ms\n", median_simd))
  cat(sprintf("  Speedup: %.2fx\n", speedup))
  
  results_fp5[[as.character(dur)]] <- list(
    duration = dur,
    scalar = median_scalar,
    simd = median_simd,
    speedup = speedup
  )
}

# ==============================================================================
# Benchmark 3: FormantPath extraction (7 candidates)
# ==============================================================================
cat("\n\nBenchmark 3: FormantPath extraction (7 candidates)\n")
cat("---------------------------------------------------\n")

results_fp7 <- list()

for (dur in c(1, 3)) {  # Shorter durations for 7 candidates
  cat(sprintf("\nDuration: %ds\n", dur))
  sound <- create_test_vowel(duration = dur, sr = 16000)
  
  # Warmup
  for (i in 1:2) {
    options(speaker.use_simd = FALSE)
    fp <- sound$to_formant_path(
      time_step = 0.01,
      max_formants = 5.0,
      middle_ceiling = 5500,
      ceiling_step_size = 0.05,
      number_of_steps = 3  # 7 candidates
    )
  }
  
  # Scalar benchmark
  options(speaker.use_simd = FALSE)
  time_scalar <- microbenchmark(
    {
      fp <- sound$to_formant_path(
        time_step = 0.01,
        max_formants = 5.0,
        middle_ceiling = 5500,
        ceiling_step_size = 0.05,
        number_of_steps = 3
      )
    },
    times = 10,
    unit = "ms"
  )
  
  # SIMD benchmark
  options(speaker.use_simd = TRUE)
  time_simd <- microbenchmark(
    {
      fp <- sound$to_formant_path(
        time_step = 0.01,
        max_formants = 5.0,
        middle_ceiling = 5500,
        ceiling_step_size = 0.05,
        number_of_steps = 3
      )
    },
    times = 10,
    unit = "ms"
  )
  
  median_scalar <- median(time_scalar$time) / 1e6
  median_simd <- median(time_simd$time) / 1e6
  speedup <- median_scalar / median_simd
  
  cat(sprintf("  Scalar: %.2f ms\n", median_scalar))
  cat(sprintf("  SIMD:   %.2f ms\n", median_simd))
  cat(sprintf("  Speedup: %.2fx\n", speedup))
  
  results_fp7[[as.character(dur)]] <- list(
    duration = dur,
    scalar = median_scalar,
    simd = median_simd,
    speedup = speedup
  )
}

# ==============================================================================
# Summary
# ==============================================================================
cat("\n\n========================================\n")
cat("SUMMARY: Phase 4 Task 4.1 Benchmark Results\n")
cat("========================================\n\n")

cat("3 Candidates:\n")
for (r in results_fp3) {
  cat(sprintf("  %ds: %.2fx speedup (target: 2.0-3.0x)\n", 
              r$duration, r$speedup))
}

cat("\n5 Candidates:\n")
for (r in results_fp5) {
  cat(sprintf("  %ds: %.2fx speedup (target: 2.0-3.0x)\n", 
              r$duration, r$speedup))
}

cat("\n7 Candidates:\n")
for (r in results_fp7) {
  cat(sprintf("  %ds: %.2fx speedup (target: 2.0-3.0x)\n", 
              r$duration, r$speedup))
}

# Calculate average speedup
all_speedups <- c(
  sapply(results_fp3, function(x) x$speedup),
  sapply(results_fp5, function(x) x$speedup),
  sapply(results_fp7, function(x) x$speedup)
)
avg_speedup <- mean(all_speedups)
geom_mean_speedup <- exp(mean(log(all_speedups)))

cat("\n")
cat(sprintf("Average speedup: %.2fx\n", avg_speedup))
cat(sprintf("Geometric mean speedup: %.2fx\n", geom_mean_speedup))

if (geom_mean_speedup >= 2.0) {
  cat("\n✓ Target achieved (≥ 2.0x)\n")
} else {
  cat(sprintf("\n⚠ Target not achieved (%.2fx < 2.0x)\n", geom_mean_speedup))
  cat("Note: ARM NEON has smaller batch size (2) vs x86 AVX2 (4)\n")
}

# Save results
results <- list(
  timestamp = Sys.time(),
  platform = sessionInfo()$platform,
  r_version = R.version.string,
  pladdrr_version = packageVersion("pladdrr"),
  simd_info = simd_info,
  fp3_candidates = results_fp3,
  fp5_candidates = results_fp5,
  fp7_candidates = results_fp7,
  average_speedup = avg_speedup,
  geometric_mean_speedup = geom_mean_speedup,
  target_achieved = geom_mean_speedup >= 2.0
)

output_file <- sprintf("benchmarks/phase4_task4.1_results_%s.rds", 
                      format(Sys.time(), "%Y%m%d_%H%M%S"))
saveRDS(results, output_file)
cat(sprintf("\nResults saved to: %s\n", output_file))

# Reset option
options(speaker.use_simd = TRUE)

cat("\nBenchmark complete.\n")
