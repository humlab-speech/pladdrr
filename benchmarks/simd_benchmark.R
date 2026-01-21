# SIMD Benchmark Suite for pladdrr
# Run this to measure performance improvements from SIMD optimizations

library(pladdrr)
library(microbenchmark)
library(ggplot2)

# Configuration
BENCHMARK_ITERATIONS <- 100
AUDIO_DURATION <- 10.0  # seconds
SAMPLING_RATE <- 44100

cat("=== pladdrr SIMD Benchmark Suite ===\n")
cat(sprintf("Iterations: %d\n", BENCHMARK_ITERATIONS))
cat(sprintf("Audio duration: %.1f seconds\n", AUDIO_DURATION))
cat(sprintf("Sampling rate: %d Hz\n\n", SAMPLING_RATE))

# Check SIMD availability
simd_info <- .simd_info()
cat("SIMD Status:\n")
cat(sprintf("  Available: %s\n", simd_info$available))
cat(sprintf("  Architecture: %s\n", simd_info$architecture))
cat(sprintf("  Batch size (double): %d\n\n", simd_info$batch_size_double))

if (!simd_info$available) {
  stop("SIMD not available - cannot run benchmarks")
}

# Create test sound
cat("Creating test sound...\n")
test_sound <- Sound$create_tone(440, duration = AUDIO_DURATION, 
                                sampling_frequency = SAMPLING_RATE)

# Benchmark wrapper function
benchmark_operation <- function(name, op_func, sound = test_sound, 
                               times = BENCHMARK_ITERATIONS) {
  cat(sprintf("\nBenchmarking: %s\n", name))
  
  # Scalar version
  cat("  Running scalar version... ")
  options(speaker.use_simd = FALSE)
  time_scalar <- microbenchmark(
    op_func(sound),
    times = times,
    unit = "ms"
  )
  cat("done\n")
  
  # SIMD version
  cat("  Running SIMD version... ")
  options(speaker.use_simd = TRUE)
  time_simd <- microbenchmark(
    op_func(sound),
    times = times,
    unit = "ms"
  )
  cat("done\n")
  
  # Calculate statistics
  scalar_median <- median(time_scalar$time) / 1e6  # Convert to ms
  simd_median <- median(time_simd$time) / 1e6
  speedup <- scalar_median / simd_median
  
  # Print results
  cat(sprintf("  Scalar:  %.2f ms (±%.2f)\n", 
              scalar_median, sd(time_scalar$time) / 1e6))
  cat(sprintf("  SIMD:    %.2f ms (±%.2f)\n", 
              simd_median, sd(time_simd$time) / 1e6))
  cat(sprintf("  Speedup: %.2fx\n", speedup))
  
  # Return results
  list(
    operation = name,
    scalar_median = scalar_median,
    scalar_sd = sd(time_scalar$time) / 1e6,
    simd_median = simd_median,
    simd_sd = sd(time_simd$time) / 1e6,
    speedup = speedup,
    time_scalar = time_scalar,
    time_simd = time_simd
  )
}

# ============================================================================
# Phase 1 Benchmarks: Integration
# ============================================================================

cat("\n" , rep("=", 70), "\n", sep = "")
cat("PHASE 1: Core DSP Operations (Integration)\n")
cat(rep("=", 70), "\n")

results_phase1 <- list()

# 1. Pitch extraction (autocorrelation)
results_phase1$pitch_ac <- benchmark_operation(
  "Pitch extraction (autocorrelation)",
  function(s) s$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
)

# 2. Pitch extraction (cross-correlation)
results_phase1$pitch_cc <- benchmark_operation(
  "Pitch extraction (cross-correlation)",
  function(s) s$to_pitch_ac(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
)

# 3. Formant extraction (Burg)
results_phase1$formant <- benchmark_operation(
  "Formant extraction (Burg)",
  function(s) s$to_formant_burg(
    time_step = 0.01,
    max_number_of_formants = 5,
    maximum_formant = 5500,
    window_length = 0.025,
    pre_emphasis_from = 50
  )
)

# 4. Intensity calculation
results_phase1$intensity <- benchmark_operation(
  "Intensity calculation",
  function(s) s$to_intensity(minimum_pitch = 100, time_step = 0.0)
)

# 5. Harmonicity (HNR)
results_phase1$harmonicity <- benchmark_operation(
  "Harmonicity (HNR)",
  function(s) s$to_harmonicity_cc(time_step = 0.01, minimum_pitch = 75)
)

# ============================================================================
# Phase 2 Benchmarks: Spectrogram & Filtering
# ============================================================================

cat("\n", rep("=", 70), "\n", sep = "")
cat("PHASE 2: Spectrogram & Filtering\n")
cat(rep("=", 70), "\n")

results_phase2 <- list()

# 6. Spectrogram generation
results_phase2$spectrogram <- benchmark_operation(
  "Spectrogram generation",
  function(s) s$to_spectrogram(
    window_length = 0.005,
    maximum_frequency = 5000,
    time_step = 0.002,
    frequency_step = 20,
    window_shape = "Gaussian"
  ),
  times = 50  # Fewer iterations (slower operation)
)

# 7. Spectrum (FFT)
results_phase2$spectrum <- benchmark_operation(
  "Spectrum (FFT)",
  function(s) s$to_spectrum(fast = TRUE)
)

# 8. LTAS
results_phase2$ltas <- benchmark_operation(
  "Long-term average spectrum (LTAS)",
  function(s) s$to_ltas(bandwidth = 100)
)

# ============================================================================
# Phase 3 Benchmarks: Batch Operations
# ============================================================================

cat("\n", rep("=", 70), "\n", sep = "")
cat("PHASE 3: Batch Operations\n")
cat(rep("=", 70), "\n")

results_phase3 <- list()

# 9. Multiple pitch measurements
results_phase3$batch_pitch <- benchmark_operation(
  "Batch pitch measurements (10 time points)",
  function(s) {
    times <- seq(0, s$get_total_duration(), length.out = 10)
    pitch <- s$to_pitch()
    sapply(times, function(t) pitch$get_value_at_time(t, "hertz"))
  }
)

# 10. Multiple formant measurements
results_phase3$batch_formant <- benchmark_operation(
  "Batch formant measurements (10 time points)",
  function(s) {
    times <- seq(0, s$get_total_duration(), length.out = 10)
    formant <- s$to_formant_burg()
    lapply(times, function(t) {
      c(
        f1 = formant$get_value_at_time(1, t, "hertz"),
        f2 = formant$get_value_at_time(2, t, "hertz"),
        f3 = formant$get_value_at_time(3, t, "hertz")
      )
    })
  }
)

# ============================================================================
# Summary
# ============================================================================

cat("\n", rep("=", 70), "\n", sep = "")
cat("BENCHMARK SUMMARY\n")
cat(rep("=", 70), "\n\n")

all_results <- c(results_phase1, results_phase2, results_phase3)

summary_df <- data.frame(
  Operation = sapply(all_results, function(x) x$operation),
  Scalar_ms = sapply(all_results, function(x) x$scalar_median),
  SIMD_ms = sapply(all_results, function(x) x$simd_median),
  Speedup = sapply(all_results, function(x) x$speedup),
  stringsAsFactors = FALSE
)

# Sort by speedup
summary_df <- summary_df[order(-summary_df$Speedup), ]

print(summary_df, row.names = FALSE)

cat("\n")
cat(sprintf("Average speedup: %.2fx\n", mean(summary_df$Speedup)))
cat(sprintf("Best speedup: %.2fx (%s)\n", 
            max(summary_df$Speedup),
            summary_df$Operation[which.max(summary_df$Speedup)]))
cat(sprintf("Worst speedup: %.2fx (%s)\n", 
            min(summary_df$Speedup),
            summary_df$Operation[which.min(summary_df$Speedup)]))

# ============================================================================
# Visualizations
# ============================================================================

cat("\nGenerating plots...\n")

# Plot 1: Speedup comparison
p1 <- ggplot(summary_df, aes(x = reorder(Operation, Speedup), y = Speedup)) +
  geom_col(fill = "steelblue") +
  geom_hline(yintercept = 1, linetype = "dashed", color = "red") +
  geom_text(aes(label = sprintf("%.2fx", Speedup)), 
            hjust = -0.2, size = 3) +
  coord_flip() +
  ylim(0, max(summary_df$Speedup) * 1.1) +
  labs(
    title = "SIMD Speedup by Operation",
    subtitle = sprintf("pladdrr v%s - %s architecture", 
                       packageVersion("pladdrr"),
                       simd_info$architecture),
    x = "Operation",
    y = "Speedup (higher is better)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    axis.text.y = element_text(size = 9)
  )

ggsave("benchmark_speedup.png", p1, width = 10, height = 8, dpi = 300)

# Plot 2: Execution time comparison
summary_long <- reshape2::melt(
  summary_df[, c("Operation", "Scalar_ms", "SIMD_ms")],
  id.vars = "Operation",
  variable.name = "Implementation",
  value.name = "Time_ms"
)

summary_long$Implementation <- factor(
  summary_long$Implementation,
  levels = c("Scalar_ms", "SIMD_ms"),
  labels = c("Scalar", "SIMD")
)

p2 <- ggplot(summary_long, aes(x = reorder(Operation, Time_ms), 
                                y = Time_ms, 
                                fill = Implementation)) +
  geom_col(position = "dodge") +
  coord_flip() +
  scale_fill_manual(values = c("Scalar" = "coral", "SIMD" = "steelblue")) +
  labs(
    title = "Execution Time: Scalar vs SIMD",
    subtitle = sprintf("%d iterations, %.1fs audio @ %d Hz",
                       BENCHMARK_ITERATIONS, AUDIO_DURATION, SAMPLING_RATE),
    x = "Operation",
    y = "Median time (ms)",
    fill = "Implementation"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    axis.text.y = element_text(size = 9),
    legend.position = "bottom"
  )

ggsave("benchmark_time.png", p2, width = 10, height = 8, dpi = 300)

cat("\nPlots saved:\n")
cat("  - benchmark_speedup.png\n")
cat("  - benchmark_time.png\n")

# ============================================================================
# Save results
# ============================================================================

cat("\nSaving results...\n")

benchmark_data <- list(
  timestamp = Sys.time(),
  system_info = Sys.info(),
  simd_info = simd_info,
  config = list(
    iterations = BENCHMARK_ITERATIONS,
    audio_duration = AUDIO_DURATION,
    sampling_rate = SAMPLING_RATE
  ),
  results = all_results,
  summary = summary_df
)

saveRDS(benchmark_data, "benchmark_results.rds")
cat("Results saved to: benchmark_results.rds\n")

# ============================================================================
# Regression check
# ============================================================================

cat("\n", rep("=", 70), "\n", sep = "")
cat("REGRESSION CHECK\n")
cat(rep("=", 70), "\n\n")

cat("Checking SIMD vs Scalar accuracy...\n")

options(speaker.use_simd = FALSE)
pitch_scalar <- test_sound$to_pitch()
f0_scalar <- pitch_scalar$get_mean(unit = "hertz")

options(speaker.use_simd = TRUE)
pitch_simd <- test_sound$to_pitch()
f0_simd <- pitch_simd$get_mean(unit = "hertz")

diff <- abs(f0_scalar - f0_simd)
rel_diff <- diff / f0_scalar

cat(sprintf("Pitch (scalar):  %.6f Hz\n", f0_scalar))
cat(sprintf("Pitch (SIMD):    %.6f Hz\n", f0_simd))
cat(sprintf("Absolute diff:   %.10e Hz\n", diff))
cat(sprintf("Relative diff:   %.10e (%.6f%%)\n", rel_diff, rel_diff * 100))

if (rel_diff > 1e-6) {
  warning("SIMD results differ significantly from scalar!")
} else {
  cat("\n✓ Accuracy check passed (difference < 1e-6)\n")
}

cat("\n=== Benchmark complete ===\n")
