# Phase 3: FFT Operations Benchmark
# Target: 2-4x speedup with SIMD
# Operations: Spectrogram generation, window functions, overlap-add

library(speaker)
library(bench)

cat("\n=== Phase 3: FFT Operations Benchmark ===\n")
cat("Target speedup: 2-4x\n")
cat("Operations: Spectrogram, Spectrum, FFT-based analysis\n\n")

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
  
  # Create test sound with harmonics (more realistic for FFT)
  n_samples <- cfg$duration * cfg$sample_rate
  t <- seq(0, cfg$duration, length.out = n_samples)
  # Fundamental + harmonics
  signal <- sin(2 * pi * 200 * t) + 
            0.5 * sin(2 * pi * 400 * t) +
            0.3 * sin(2 * pi * 600 * t)
  
  sound <- Sound$new_from_values(
    values = matrix(signal, nrow = 1),
    sampling_rate = cfg$sample_rate
  )
  
  # Benchmark: Spectrogram creation
  bm_spectrogram <- bench::mark(
    to_spectrogram = {
      spec <- sound$to_spectrogram(
        window_length = 0.005,
        max_frequency = 5000,
        time_step = 0.002,
        frequency_step = 20,
        window_shape = "Gaussian"
      )
      rm(spec)
      gc(verbose = FALSE)
    },
    iterations = 20,
    check = FALSE
  )
  
  # Benchmark: Spectrum creation
  bm_spectrum <- bench::mark(
    to_spectrum = {
      spec <- sound$to_spectrum(fast = TRUE)
      rm(spec)
      gc(verbose = FALSE)
    },
    iterations = 50,
    check = FALSE
  )
  
  # Benchmark: LTAS (Long-Term Average Spectrum)
  bm_ltas <- bench::mark(
    to_ltas = {
      ltas <- sound$to_ltas(bandwidth = 100)
      rm(ltas)
      gc(verbose = FALSE)
    },
    iterations = 30,
    check = FALSE
  )
  
  # Benchmark: Harmonicity (autocorrelation-based, uses FFT internally)
  bm_harmonicity <- bench::mark(
    to_harmonicity = {
      harm <- sound$to_harmonicity_cc(
        time_step = 0.01,
        minimum_pitch = 75,
        silence_threshold = 0.1,
        periods_per_window = 1.0
      )
      rm(harm)
      gc(verbose = FALSE)
    },
    iterations = 20,
    check = FALSE
  )
  
  results[[config_name]] <- list(
    config = cfg,
    spectrogram = bm_spectrogram,
    spectrum = bm_spectrum,
    ltas = bm_ltas,
    harmonicity = bm_harmonicity
  )
  
  cat(sprintf("  Spectrogram: %s\n", format(bm_spectrogram$median)))
  cat(sprintf("  Spectrum: %s\n", format(bm_spectrum$median)))
  cat(sprintf("  LTAS: %s\n", format(bm_ltas$median)))
  cat(sprintf("  Harmonicity: %s\n", format(bm_harmonicity$median)))
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
  for (op in c("spectrogram", "spectrum", "ltas", "harmonicity")) {
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
output_file <- sprintf("results/baseline/08_phase3_fft_operations_%s.rds", timestamp)

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
cat("\nNote: FFT operations are complex\n")
cat("Expected speedup: 2-4x (conservative due to algorithm complexity)\n")
cat("Window functions and pre/post-processing will benefit most from SIMD\n")
