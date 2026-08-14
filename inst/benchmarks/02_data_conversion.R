# Benchmark 2: Data Conversion (Praat <-> R)
# Tests: Sound creation from matrix, Sound export to matrix
# Expected SIMD speedup: 4-8x

library(speaker)
library(bench)

cat(strrep("=", 80), "\n")
run_mode <- Sys.getenv("SPEAKER_BENCHMARK_MODE", "baseline")
cat(sprintf("Benchmark 2: Data Conversion [%s mode]\n", toupper(run_mode)))
cat(strrep("=", 80), "\n\n")

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

  cat(sprintf(
    "\nTesting %s (%d channels, %.1f seconds, %d samples):\n",
    config_name, cfg$channels, cfg$duration, n_samples
  ))

  # Create test data
  test_data <- matrix(rnorm(cfg$channels * n_samples),
    nrow = cfg$channels,
    ncol = n_samples
  )

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
  cols <- c("expression", "min", "median", "itr/sec", "mem_alloc")
  print(bench_create[, cols])

  cat("\nExport:\n")
  print(bench_export[, cols])
  cat("\n")
}

# Save results
dir.create("inst/benchmarks/results", recursive = TRUE, showWarnings = FALSE)
output_file <- sprintf(
  "inst/benchmarks/results/02_data_conversion_%s.rds",
  run_mode
)
saveRDS(results, output_file)

cat(sprintf("\nResults saved to: %s\n", output_file))
