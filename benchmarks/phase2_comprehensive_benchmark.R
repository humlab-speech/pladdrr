#!/usr/bin/env Rscript
# Phase 2 Comprehensive Benchmark
# Tasks 2.1-2.3: Spectrogram, Pre-emphasis, Pitch Filter
# Created: 2026-01-22

library(pladdrr)

cat("Phase 2 SIMD Comprehensive Benchmark\n")
cat("=====================================\n")
cat("Tasks 2.1-2.3: Spectrogram, Pre-emphasis, Pitch Filter\n\n")

cat(sprintf("Platform: %s\n", Sys.info()["machine"]))
cat(sprintf("R version: %s\n", R.version$version.string))
cat(sprintf("pladdrr version: %s\n\n", packageVersion("pladdrr")))

# Benchmark parameters
n_iterations <- 50
signal_durations <- c(1, 5, 10)  # seconds
sampling_rate <- 16000

# Generate test signals
test_signals <- lapply(signal_durations, function(duration) {
  n_samples <- duration * sampling_rate
  t <- seq(0, duration, length.out = n_samples)
  signal <- sin(2 * pi * 200 * t) +
            0.5 * sin(2 * pi * 400 * t) +
            0.3 * sin(2 * pi * 800 * t)
  list(duration = duration, signal = signal, sr = sampling_rate)
})

# Results storage
results <- data.frame(
  task = character(),
  duration_s = numeric(),
  scalar_time_ms = numeric(),
  simd_time_ms = numeric(),
  speedup = numeric(),
  stringsAsFactors = FALSE
)

# ============================================================================
# Task 2.1: Spectrogram Benchmark
# ============================================================================

cat("Task 2.1: Spectrogram SIMD\n")
cat("==========================\n\n")

for (test_data in test_signals) {
  cat(sprintf("Signal duration: %.0f s (%d samples)\n",
              test_data$duration, length(test_data$signal)))

  # Scalar benchmark
  scalar_times <- numeric(n_iterations)
  for (i in 1:n_iterations) {
    snd <- Sound$from_values(test_data$signal, test_data$sr)
    options(speaker.use_simd = FALSE)
    start_time <- Sys.time()
    spec <- snd$to_spectrogram(window_length = 0.005, time_step = 0.002)
    end_time <- Sys.time()
    scalar_times[i] <- as.numeric(end_time - start_time, units = "secs") * 1000
    rm(snd, spec)
    gc(verbose = FALSE)
  }

  # SIMD benchmark
  simd_times <- numeric(n_iterations)
  for (i in 1:n_iterations) {
    snd <- Sound$from_values(test_data$signal, test_data$sr)
    options(speaker.use_simd = TRUE)
    start_time <- Sys.time()
    spec <- snd$to_spectrogram(window_length = 0.005, time_step = 0.002)
    end_time <- Sys.time()
    simd_times[i] <- as.numeric(end_time - start_time, units = "secs") * 1000
    rm(snd, spec)
    gc(verbose = FALSE)
  }

  scalar_median <- median(scalar_times)
  simd_median <- median(simd_times)
  speedup <- scalar_median / simd_median

  cat(sprintf("  Scalar median:  %.2f ms\n", scalar_median))
  cat(sprintf("  SIMD median:    %.2f ms\n", simd_median))
  cat(sprintf("  Speedup:        %.2fx\n\n", speedup))

  results <- rbind(results, data.frame(
    task = "Spectrogram",
    duration_s = test_data$duration,
    scalar_time_ms = scalar_median,
    simd_time_ms = simd_median,
    speedup = speedup
  ))
}

# ============================================================================
# Task 2.2: Pre-emphasis Benchmark
# ============================================================================

cat("Task 2.2: Pre-emphasis Filter SIMD\n")
cat("===================================\n\n")

for (test_data in test_signals) {
  cat(sprintf("Signal duration: %.0f s (%d samples)\n",
              test_data$duration, length(test_data$signal)))

  # Scalar benchmark
  scalar_times <- numeric(n_iterations)
  for (i in 1:n_iterations) {
    snd <- Sound$from_values(test_data$signal, test_data$sr)
    options(speaker.use_simd = FALSE)
    start_time <- Sys.time()
    snd$pre_emphasize(50)
    end_time <- Sys.time()
    scalar_times[i] <- as.numeric(end_time - start_time, units = "secs") * 1000
    rm(snd)
    gc(verbose = FALSE)
  }

  # SIMD benchmark
  simd_times <- numeric(n_iterations)
  for (i in 1:n_iterations) {
    snd <- Sound$from_values(test_data$signal, test_data$sr)
    options(speaker.use_simd = TRUE)
    start_time <- Sys.time()
    snd$pre_emphasize(50)
    end_time <- Sys.time()
    simd_times[i] <- as.numeric(end_time - start_time, units = "secs") * 1000
    rm(snd)
    gc(verbose = FALSE)
  }

  scalar_median <- median(scalar_times)
  simd_median <- median(simd_times)
  speedup <- scalar_median / simd_median

  cat(sprintf("  Scalar median:  %.3f ms\n", scalar_median))
  cat(sprintf("  SIMD median:    %.3f ms\n", simd_median))
  cat(sprintf("  Speedup:        %.2fx\n\n", speedup))

  results <- rbind(results, data.frame(
    task = "Pre-emphasis",
    duration_s = test_data$duration,
    scalar_time_ms = scalar_median,
    simd_time_ms = simd_median,
    speedup = speedup
  ))
}

# ============================================================================
# Task 2.3: Pitch Extraction (with internal pitch filter SIMD)
# ============================================================================

cat("Task 2.3: Pitch Extraction (with filter SIMD)\n")
cat("==============================================\n\n")

for (test_data in test_signals) {
  cat(sprintf("Signal duration: %.0f s (%d samples)\n",
              test_data$duration, length(test_data$signal)))

  # Scalar benchmark
  scalar_times <- numeric(n_iterations)
  for (i in 1:n_iterations) {
    snd <- Sound$from_values(test_data$signal, test_data$sr)
    options(speaker.use_simd = FALSE)
    start_time <- Sys.time()
    pitch <- snd$to_pitch(pitch_floor = 75, pitch_ceiling = 600)
    end_time <- Sys.time()
    scalar_times[i] <- as.numeric(end_time - start_time, units = "secs") * 1000
    rm(snd, pitch)
    gc(verbose = FALSE)
  }

  # SIMD benchmark
  simd_times <- numeric(n_iterations)
  for (i in 1:n_iterations) {
    snd <- Sound$from_values(test_data$signal, test_data$sr)
    options(speaker.use_simd = TRUE)
    start_time <- Sys.time()
    pitch <- snd$to_pitch(pitch_floor = 75, pitch_ceiling = 600)
    end_time <- Sys.time()
    simd_times[i] <- as.numeric(end_time - start_time, units = "secs") * 1000
    rm(snd, pitch)
    gc(verbose = FALSE)
  }

  scalar_median <- median(scalar_times)
  simd_median <- median(simd_times)
  speedup <- scalar_median / simd_median

  cat(sprintf("  Scalar median:  %.2f ms\n", scalar_median))
  cat(sprintf("  SIMD median:    %.2f ms\n", simd_median))
  cat(sprintf("  Speedup:        %.2fx\n\n", speedup))

  results <- rbind(results, data.frame(
    task = "Pitch (w/ filter)",
    duration_s = test_data$duration,
    scalar_time_ms = scalar_median,
    simd_time_ms = simd_median,
    speedup = speedup
  ))
}

# ============================================================================
# Phase 2 Summary
# ============================================================================

cat("\n")
cat("Phase 2 Summary\n")
cat("===============\n\n")

print(results, row.names = FALSE)

cat("\n")
cat("Average Speedups by Task:\n")
for (task_name in unique(results$task)) {
  task_results <- results[results$task == task_name, ]
  avg_speedup <- mean(task_results$speedup)
  geom_mean_speedup <- exp(mean(log(task_results$speedup)))
  cat(sprintf("  %s: %.2fx (geometric: %.2fx)\n",
              task_name, avg_speedup, geom_mean_speedup))
}

cat("\n")
cat("Overall Phase 2 Performance:\n")
cat(sprintf("  Average speedup:           %.2fx\n", mean(results$speedup)))
cat(sprintf("  Geometric mean speedup:    %.2fx\n", exp(mean(log(results$speedup)))))
cat(sprintf("  Best speedup:              %.2fx (%s, %.0fs)\n",
            max(results$speedup),
            results$task[which.max(results$speedup)],
            results$duration_s[which.max(results$speedup)]))
cat(sprintf("  Worst speedup:             %.2fx (%s, %.0fs)\n",
            min(results$speedup),
            results$task[which.min(results$speedup)],
            results$duration_s[which.min(results$speedup)]))

cat("\n")
cat("Target vs Achieved:\n")
cat("  Task 2.1 Spectrogram:    Target 2.0-3.0x, Achieved: ")
spec_speedup <- mean(results$speedup[results$task == "Spectrogram"])
cat(sprintf("%.2fx", spec_speedup))
if (spec_speedup >= 2.0) {
  cat(" ✓\n")
} else {
  cat(sprintf(" (%.0f%% of target)\n", spec_speedup / 2.0 * 100))
}

cat("  Task 2.2 Pre-emphasis:   Target 1.5-2.0x, Achieved: ")
preemph_speedup <- mean(results$speedup[results$task == "Pre-emphasis"])
cat(sprintf("%.2fx", preemph_speedup))
if (preemph_speedup >= 1.5) {
  cat(" ✓\n")
} else {
  cat(sprintf(" (%.0f%% of target)\n", preemph_speedup / 1.5 * 100))
}

cat("  Task 2.3 Pitch Filter:   Target 2.0-3.0x, Achieved: ")
pitch_speedup <- mean(results$speedup[results$task == "Pitch (w/ filter)"])
cat(sprintf("%.2fx", pitch_speedup))
if (pitch_speedup >= 2.0) {
  cat(" ✓\n")
} else {
  cat(sprintf(" (included in overall pitch, %.0f%% of target)\n", pitch_speedup / 2.0 * 100))
}

cat("\n")
cat("Platform Notes:\n")
if (Sys.info()["machine"] == "arm64") {
  cat("  - ARM NEON architecture (batch size 2)\n")
  cat("  - Expected higher speedups on x86_64 AVX2 (batch size 4)\n")
  cat("  - Spectrogram dominated by non-SIMD FFT operations\n")
} else {
  cat(sprintf("  - Architecture: %s\n", Sys.info()["machine"]))
}

cat("\n")

# Save results
timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
output_file <- sprintf("benchmarks/phase2_results_%s.txt", timestamp)
sink(output_file)
cat("Phase 2 SIMD Benchmark Results\n")
cat("==============================\n")
cat(sprintf("Date: %s\n", Sys.time()))
cat(sprintf("Platform: %s\n", Sys.info()["machine"]))
cat(sprintf("R version: %s\n", R.version$version.string))
cat(sprintf("pladdrr version: %s\n\n", packageVersion("pladdrr")))
print(results, row.names = FALSE)
cat(sprintf("\nOverall geometric mean speedup: %.2fx\n", exp(mean(log(results$speedup)))))
sink()

cat(sprintf("Results saved to: %s\n", output_file))

# Reset to SIMD enabled
options(speaker.use_simd = TRUE)
