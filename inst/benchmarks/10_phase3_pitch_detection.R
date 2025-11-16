# Phase 3: Pitch Detection Benchmark
# Target: 2-4x speedup with SIMD
# Operations: Autocorrelation pitch detection, cross-correlation

library(speaker)
library(bench)

cat("\n=== Phase 3: Pitch Detection Benchmark ===\n")
cat("Target speedup: 2-4x\n")
cat("Operations: Autocorrelation method, peak detection\n\n")

# Test configurations
configs <- list(
  small = list(duration = 0.5, sample_rate = 16000, label = "Small (0.5s)"),
  medium = list(duration = 2.0, sample_rate = 16000, label = "Medium (2s)"),
  large = list(duration = 10.0, sample_rate = 16000, label = "Large (10s)")
)

results <- list()

for (config_name in names(configs)) {
  cfg <- configs[[config_name]]
  
  cat(sprintf("\nBenchmarking: %s\n", cfg$label))
  
  # Create test sound with varying F0 (120-180 Hz)
  n_samples <- cfg$duration * cfg$sample_rate
  t <- seq(0, cfg$duration, length.out = n_samples)
  f0 <- 120 + 60 * sin(2 * pi * t / cfg$duration)  # Varying F0
  
  signal <- sin(2 * pi * cumsum(f0 / cfg$sample_rate))
  
  sound <- Sound$new_from_values(
    values = matrix(signal, nrow = 1),
    sampling_rate = cfg$sample_rate
  )
  
  # Benchmark: Pitch extraction (autocorrelation - default)
  bm_pitch_ac <- bench::mark(
    to_pitch_ac = {
      pitch <- sound$to_pitch(
        time_step = 0.01,
        pitch_floor = 75,
        pitch_ceiling = 600
      )
      rm(pitch)
      gc(verbose = FALSE)
    },
    iterations = 20,
    check = FALSE
  )
  
  # Benchmark: Pitch cross-correlation method
  bm_pitch_cc <- bench::mark(
    to_pitch_cc = {
      pitch <- sound$to_pitch_cc(
        time_step = 0.01,
        pitch_floor = 75,
        max_number_of_candidates = 15,
        very_accurate = FALSE,
        silence_threshold = 0.03,
        voicing_threshold = 0.45,
        octave_cost = 0.01,
        octave_jump_cost = 0.35,
        voiced_unvoiced_cost = 0.14,
        pitch_ceiling = 600
      )
      rm(pitch)
      gc(verbose = FALSE)
    },
    iterations = 20,
    check = FALSE
  )
  
  # Benchmark: PointProcess from pitch (pulse detection)
  # First create pitch object
  pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
  
  bm_point_process <- bench::mark(
    to_point_process = {
      pp <- sound$to_point_process_periodic_cc(
        minimum_pitch = 75,
        maximum_pitch = 600
      )
      rm(pp)
      gc(verbose = FALSE)
    },
    iterations = 20,
    check = FALSE
  )
  
  rm(pitch)
  
  # Benchmark: Multiple pitch candidates (more intensive)
  bm_pitch_candidates <- bench::mark(
    to_pitch_many_candidates = {
      pitch <- sound$to_pitch_cc(
        time_step = 0.01,
        pitch_floor = 75,
        max_number_of_candidates = 30,  # More candidates = more computation
        very_accurate = TRUE,            # More accuracy = more computation
        silence_threshold = 0.03,
        voicing_threshold = 0.45,
        octave_cost = 0.01,
        octave_jump_cost = 0.35,
        voiced_unvoiced_cost = 0.14,
        pitch_ceiling = 600
      )
      rm(pitch)
      gc(verbose = FALSE)
    },
    iterations = 10,
    check = FALSE
  )
  
  results[[config_name]] <- list(
    config = cfg,
    pitch_ac = bm_pitch_ac,
    pitch_cc = bm_pitch_cc,
    point_process = bm_point_process,
    pitch_candidates = bm_pitch_candidates
  )
  
  cat(sprintf("  Pitch (AC): %s\n", format(bm_pitch_ac$median)))
  cat(sprintf("  Pitch (CC): %s\n", format(bm_pitch_cc$median)))
  cat(sprintf("  PointProcess: %s\n", format(bm_point_process$median)))
  cat(sprintf("  Pitch (many candidates): %s\n", format(bm_pitch_candidates$median)))
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
  for (op in c("pitch_ac", "pitch_cc", "point_process", "pitch_candidates")) {
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
output_file <- sprintf("results/baseline/10_phase3_pitch_detection_%s.rds", timestamp)

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
cat("\nNote: Pitch detection involves:\n")
cat("  - Lag correlation loops (SIMD target)\n")
cat("  - Peak detection (SIMD-friendly comparisons)\n")
cat("  - Path finding (harder to vectorize)\n")
cat("Expected speedup: 2-4x (correlation phase will benefit most)\n")
