# Benchmark 2: Data Conversion (Praat <-> R)
# Tests: Sound creation from matrix, Sound export to matrix
# Expected SIMD speedup: 4-8x

library(speaker)
library(bench)

cat("="*80, "\n")
cat("Benchmark 2: Data Conversion (Baseline - Pre-SIMD)\n")
cat("="*80, "\n\n")

# Test different audio durations and channel counts
configs <- list(
  mono_1s = list(duration = 1.0, channels = 1, rate = 44100),
  stereo_1s = list(duration = 1.0, channels = 2, rate = 44100),
  mono_10s = list(duration = 10.0, channels = 1, rate = 44100),
  stereo_10s = list(duration = 10.0, channels = 2, rate = 44100),
  mono_60s = list(duration = 60.0, channels = 1, rate = 44100)
)

results <- list()

for (config_name in names(configs)) {
  cfg <- configs[[config_name]]
  n_samples <- as.integer(cfg$duration * cfg$rate)

  cat(sprintf("\nTesting %s (%d channels, %.1f seconds, %d samples):\n",
              config_name, cfg$channels, cfg$duration, n_samples))

  # Create test data
  test_data <- matrix(rnorm(cfg$channels * n_samples),
                      nrow = cfg$channels,
                      ncol = n_samples)

  # Benchmark: R matrix -> Sound object
  bench_create <- bench::mark(
    create_sound = Sound$from_values(test_data, cfg$rate),
    iterations = 20,
    check = FALSE
  )

  # Create sound for export test
  sound_obj <- Sound$from_values(test_data, cfg$rate)

  # Benchmark: Sound object -> R matrix
  bench_export <- bench::mark(
    export_matrix = sound_obj$as_matrix(),
    export_df = sound_obj$as_data_frame(),
    iterations = 20,
    check = FALSE
  )

  results[[config_name]] <- list(
    create = bench_create,
    export = bench_export,
    config = cfg,
    n_samples = n_samples
  )

  cat("\nCreation:\n")
  print(bench_create[, c("expression", "min", "median", "max", "mem_alloc")])

  cat("\nExport:\n")
  print(bench_export[, c("expression", "min", "median", "max", "mem_alloc")])
  cat("\n")
}

# Save results
saveRDS(results, "inst/benchmarks/results/02_data_conversion_baseline.rds")

cat("\nBaseline results saved to: inst/benchmarks/results/02_data_conversion_baseline.rds\n")
