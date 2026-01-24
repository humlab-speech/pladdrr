# phase4_task4.2_harmonicity_benchmark.R
# Benchmarks for Task 4.2: Harmonicity SIMD optimization
# Tests performance of SIMD-optimized FCC cross-correlation in harmonicity/pitch

library(pladdrr)
library(microbenchmark)

cat("============================================================\n")
cat("Phase 4 Task 4.2: Harmonicity SIMD Benchmark\n")
cat("============================================================\n\n")

# Print system info
cat("Platform:", R.version$platform, "\n")
cat("R version:", R.version.string, "\n")
cat("pladdrr version:", as.character(packageVersion("pladdrr")), "\n")
cat("SIMD enabled:", getOption("speaker.use_simd", TRUE), "\n\n")

# Create test sounds of various durations
create_test_sound <- function(duration, sr = 44100, freq = 150) {
    Sound$create_tone(duration = duration, sampling_rate = sr, frequency = freq)
}

# Benchmark parameters
durations <- c(1, 2, 5)  # seconds
n_iter <- 20  # iterations per benchmark

cat("Benchmark Configuration:\n")
cat("- Durations:", paste(durations, "s", sep = "", collapse = ", "), "\n")
cat("- Iterations:", n_iter, "\n")
cat("- Sampling rate: 44100 Hz\n")
cat("- Test frequency: 150 Hz\n\n")

# Results storage
results <- list()

# =============================================================================
# Benchmark: Harmonicity CC Method (uses SIMD FCC cross-correlation)
# =============================================================================
cat("=== Harmonicity CC Method (FCC Cross-Correlation) ===\n")
cat("Target speedup: 1.5-2x on ARM NEON, 2-3x on x86 AVX2\n\n")

for (dur in durations) {
    cat(sprintf("Duration: %.1f seconds...\n", dur))

    sound <- create_test_sound(dur)

    # Benchmark scalar
    options(speaker.use_simd = FALSE)
    bench_scalar <- microbenchmark(
        scalar = sound$to_harmonicity_cc(),
        times = n_iter,
        unit = "ms"
    )

    # Benchmark SIMD
    options(speaker.use_simd = TRUE)
    bench_simd <- microbenchmark(
        simd = sound$to_harmonicity_cc(),
        times = n_iter,
        unit = "ms"
    )

    # Calculate statistics
    scalar_median <- median(bench_scalar$time) / 1e6  # Convert to ms
    simd_median <- median(bench_simd$time) / 1e6

    speedup <- scalar_median / simd_median

    results[[paste0("cc_", dur, "s")]] <- list(
        method = "CC",
        duration = dur,
        scalar_median_ms = scalar_median,
        simd_median_ms = simd_median,
        speedup = speedup
    )

    cat(sprintf("  Scalar: %.2f ms, SIMD: %.2f ms, Speedup: %.2fx\n",
                scalar_median, simd_median, speedup))
}

cat("\n")

# =============================================================================
# Benchmark: Harmonicity AC Method (uses FFT-based autocorrelation)
# =============================================================================
cat("=== Harmonicity AC Method (FFT-based Autocorrelation) ===\n")
cat("Note: AC method uses different code path, mainly for comparison\n\n")

for (dur in durations) {
    cat(sprintf("Duration: %.1f seconds...\n", dur))

    sound <- create_test_sound(dur)

    # Benchmark scalar
    options(speaker.use_simd = FALSE)
    bench_scalar <- microbenchmark(
        scalar = sound$to_harmonicity_ac(),
        times = n_iter,
        unit = "ms"
    )

    # Benchmark SIMD
    options(speaker.use_simd = TRUE)
    bench_simd <- microbenchmark(
        simd = sound$to_harmonicity_ac(),
        times = n_iter,
        unit = "ms"
    )

    scalar_median <- median(bench_scalar$time) / 1e6
    simd_median <- median(bench_simd$time) / 1e6

    speedup <- scalar_median / simd_median

    results[[paste0("ac_", dur, "s")]] <- list(
        method = "AC",
        duration = dur,
        scalar_median_ms = scalar_median,
        simd_median_ms = simd_median,
        speedup = speedup
    )

    cat(sprintf("  Scalar: %.2f ms, SIMD: %.2f ms, Speedup: %.2fx\n",
                scalar_median, simd_median, speedup))
}

cat("\n")

# =============================================================================
# Summary
# =============================================================================
cat("=== Summary ===\n\n")

# Calculate averages
cc_speedups <- sapply(results[grepl("^cc_", names(results))], function(x) x$speedup)
ac_speedups <- sapply(results[grepl("^ac_", names(results))], function(x) x$speedup)

cat(sprintf("CC Method (FCC) average speedup: %.2fx\n", mean(cc_speedups)))
cat(sprintf("AC Method (FFT) average speedup: %.2fx\n", mean(ac_speedups)))
cat(sprintf("Overall geometric mean speedup: %.2fx\n",
            exp(mean(log(c(cc_speedups, ac_speedups))))))

# Target comparison
target_cc <- 1.5  # 1.5-2x expected on ARM NEON
cat(sprintf("\nCC method vs target (%.1fx): %s\n", target_cc,
            ifelse(mean(cc_speedups) >= target_cc, "MET", "BELOW TARGET")))

# Save results
results_file <- paste0("harmonicity_benchmark_results_",
                       format(Sys.time(), "%Y%m%d_%H%M%S"), ".rds")
saveRDS(results, results_file)
cat(sprintf("\nResults saved to: %s\n", results_file))

# Reset SIMD setting
options(speaker.use_simd = TRUE)
