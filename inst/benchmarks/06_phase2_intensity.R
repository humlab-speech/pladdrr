# Phase 2: Intensity Calculations Benchmark
# Target: 3-5x speedup with SIMD
# Operations: RMS, Energy, Sliding window analysis

library(speaker)
library(bench)

cat("\n=== Phase 2: Intensity Calculations Benchmark ===\n")
cat("Target speedup: 3-5x\n")
cat("Operations: RMS over windows, energy calculations\n\n")

# Check if required methods exist by trying to call them
sound_test <- Sound$from_values(values = c(0, 0), sampling_rate = 16000)
has_get_rms <- tryCatch(
  {
    sound_test$get_rms(0, 0)
    TRUE
  },
  error = function(e) FALSE
)

has_get_energy <- tryCatch(
  {
    sound_test$get_energy(0, 0)
    TRUE
  },
  error = function(e) FALSE
)

has_get_power <- tryCatch(
  {
    sound_test$get_power(0, 0)
    TRUE
  },
  error = function(e) FALSE
)

if (!has_get_rms || !has_get_energy || !has_get_power) {
  cat("SKIPPING: Required Sound methods not yet implemented:\n")
  if (!has_get_rms) cat("  - get_rms()\n")
  if (!has_get_energy) cat("  - get_energy()\n")
  if (!has_get_power) cat("  - get_power()\n")
  cat("\nThis benchmark will be enabled after Phase 2 SIMD implementation.\n")
  quit(save = "no", status = 0)
}

rm(sound_test) # Clean up test object

# Test configurations
configs <- list(
  small = list(duration = 0.5, sample_rate = 16000, label = "Small (0.5s)"),
  medium = list(duration = 2.0, sample_rate = 16000, label = "Medium (2s)"),
  large = list(duration = 10.0, sample_rate = 16000, label = "Large (10s)"),
  xlarge = list(duration = 30.0, sample_rate = 16000, label = "XLarge (30s)")
)

results <- list()

for (config_name in names(configs)) {
  cfg <- configs[[config_name]]

  cat(sprintf("\nBenchmarking: %s\n", cfg$label))
  cat(sprintf("  Duration: %.1fs, Sample rate: %d Hz\n", cfg$duration, cfg$sample_rate))

  # Create test sound (noise signal for realistic computation)
  n_samples <- cfg$duration * cfg$sample_rate
  values <- rnorm(n_samples)
  sound <- Sound$from_values(
    values = values,
    sampling_rate = cfg$sample_rate
  )

  # Benchmark: RMS calculation
  bm_rms <- bench::mark(
    rms = {
      sound$get_rms(from_time = 0, to_time = cfg$duration)
    },
    iterations = 100,
    check = FALSE
  )

  # Benchmark: Energy calculation
  bm_energy <- bench::mark(
    energy = {
      sound$get_energy(from_time = 0, to_time = cfg$duration)
    },
    iterations = 100,
    check = FALSE
  )

  # Benchmark: Intensity extraction (windowed analysis)
  bm_intensity <- bench::mark(
    to_intensity = {
      intensity <- sound$to_intensity(
        minimum_pitch = 75,
        time_step = 0.01
      )
      # Clean up
      rm(intensity)
      gc(verbose = FALSE)
    },
    iterations = 50,
    check = FALSE
  )

  # Benchmark: Power calculation
  bm_power <- bench::mark(
    power = {
      sound$get_power(from_time = 0, to_time = cfg$duration)
    },
    iterations = 100,
    check = FALSE
  )

  results[[config_name]] <- list(
    config = cfg,
    rms = bm_rms,
    energy = bm_energy,
    to_intensity = bm_intensity,
    power = bm_power
  )

  cat(sprintf("  RMS: median = %s\n", format(bm_rms$median)))
  cat(sprintf("  Energy: median = %s\n", format(bm_energy$median)))
  cat(sprintf("  to_intensity: median = %s\n", format(bm_intensity$median)))
  cat(sprintf("  Power: median = %s\n", format(bm_power$median)))
}

# Summary
cat("\n=== Summary ===\n")
summary_df <- data.frame(
  size = character(),
  operation = character(),
  median_time = numeric(),
  mem_alloc = numeric(),
  stringsAsFactors = FALSE
)

for (config_name in names(results)) {
  r <- results[[config_name]]
  summary_df <- rbind(summary_df, data.frame(
    size = config_name,
    operation = "RMS",
    median_time = as.numeric(r$rms$median),
    mem_alloc = as.numeric(r$rms$mem_alloc),
    stringsAsFactors = FALSE
  ))
  summary_df <- rbind(summary_df, data.frame(
    size = config_name,
    operation = "Energy",
    median_time = as.numeric(r$energy$median),
    mem_alloc = as.numeric(r$energy$mem_alloc),
    stringsAsFactors = FALSE
  ))
  summary_df <- rbind(summary_df, data.frame(
    size = config_name,
    operation = "to_intensity",
    median_time = as.numeric(r$to_intensity$median),
    mem_alloc = as.numeric(r$to_intensity$mem_alloc),
    stringsAsFactors = FALSE
  ))
  summary_df <- rbind(summary_df, data.frame(
    size = config_name,
    operation = "Power",
    median_time = as.numeric(r$power$median),
    mem_alloc = as.numeric(r$power$mem_alloc),
    stringsAsFactors = FALSE
  ))
}

print(summary_df)

# Save results
timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
output_file <- sprintf("inst/benchmarks/results/baseline/06_phase2_intensity_%s.rds", timestamp)

results_package <- list(
  metadata = list(
    date = Sys.time(),
    package_version = as.character(packageVersion("speaker")),
    r_version = R.version.string,
    platform = R.version$platform,
    simd_enabled = FALSE
  ),
  benchmarks = results,
  summary = summary_df
)

dir.create("inst/benchmarks/results/baseline", showWarnings = FALSE, recursive = TRUE)
saveRDS(results_package, output_file)

cat(sprintf("\nResults saved to: %s\n", output_file))
cat("\nNote: After SIMD implementation, re-run with simd_enabled = TRUE\n")
cat("Expected speedup: 3-5x for all operations\n")
