# Phase 2: Sound Mixing and Scaling Benchmark
# Target: 4-6x speedup with SIMD
# Operations: Addition, scaling, multi-channel mixing, cross-fading

library(speaker)
library(bench)

cat("\n=== Phase 2: Sound Mixing Benchmark ===\n")
cat("Target speedup: 4-6x\n")
cat("Operations: Sound addition, scaling, mixing\n\n")

# Test configurations
configs <- list(
  small = list(duration = 0.5, sample_rate = 16000),
  medium = list(duration = 2.0, sample_rate = 16000),
  large = list(duration = 10.0, sample_rate = 16000)
)

results <- list()

for (config_name in names(configs)) {
  cfg <- configs[[config_name]]
  
  cat(sprintf("\nBenchmarking: %s (%.1fs @ %d Hz)\n", config_name, cfg$duration, cfg$sample_rate))
  
  # Create test sounds
  n_samples <- cfg$duration * cfg$sample_rate
  sound1 <- Sound$new_from_values(
    values = matrix(rnorm(n_samples), nrow = 1),
    sampling_rate = cfg$sample_rate
  )
  sound2 <- Sound$new_from_values(
    values = matrix(rnorm(n_samples), nrow = 1),
    sampling_rate = cfg$sample_rate
  )
  
  # Benchmark: Sound multiplication (scaling)
  bm_multiply <- bench::mark(
    multiply_by_scalar = {
      scaled <- sound1$multiply(factor = 0.5)
      rm(scaled)
      gc(verbose = FALSE)
    },
    iterations = 50,
    check = FALSE
  )
  
  # Benchmark: Sound addition
  bm_add <- bench::mark(
    add_sounds = {
      mixed <- sound1$add(sound2)
      rm(mixed)
      gc(verbose = FALSE)
    },
    iterations = 50,
    check = FALSE
  )
  
  # Benchmark: Scale peak (normalization)
  bm_scale_peak <- bench::mark(
    scale_peak = {
      scaled <- sound1$scale_peak(new_absolute_peak = 0.99)
      rm(scaled)
      gc(verbose = FALSE)
    },
    iterations = 50,
    check = FALSE
  )
  
  # Benchmark: Override sampling frequency
  bm_override <- bench::mark(
    override_sampling_frequency = {
      new_sound <- sound1$override_sampling_frequency(new_frequency = 22050)
      rm(new_sound)
      gc(verbose = FALSE)
    },
    iterations = 50,
    check = FALSE
  )
  
  results[[config_name]] <- list(
    config = cfg,
    multiply = bm_multiply,
    add = bm_add,
    scale_peak = bm_scale_peak,
    override = bm_override
  )
  
  cat(sprintf("  Multiply: %s\n", format(bm_multiply$median)))
  cat(sprintf("  Add: %s\n", format(bm_add$median)))
  cat(sprintf("  Scale peak: %s\n", format(bm_scale_peak$median)))
  cat(sprintf("  Override freq: %s\n", format(bm_override$median)))
}

# Summary
summary_df <- data.frame(
  size = character(),
  operation = character(),
  median_time = numeric(),
  mem_alloc = numeric(),
  stringsAsFactors = FALSE
)

for (config_name in names(results)) {
  r <- results[[config_name]]
  for (op in c("multiply", "add", "scale_peak", "override")) {
    summary_df <- rbind(summary_df, data.frame(
      size = config_name,
      operation = op,
      median_time = as.numeric(r[[op]]$median),
      mem_alloc = as.numeric(r[[op]]$mem_alloc),
      stringsAsFactors = FALSE
    ))
  }
}

print(summary_df)

# Save results
timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
output_file <- sprintf("results/baseline/07_phase2_sound_mixing_%s.rds", timestamp)

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

dir.create("results/baseline", showWarnings = FALSE, recursive = TRUE)
saveRDS(results_package, output_file)

cat(sprintf("\nResults saved to: %s\n", output_file))
cat("Expected speedup with SIMD: 4-6x\n")
