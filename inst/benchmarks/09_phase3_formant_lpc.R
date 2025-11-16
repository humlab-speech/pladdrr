# Phase 3: Formant Extraction (LPC) Benchmark
# Target: 2-4x speedup with SIMD
# Operations: LPC autocorrelation, Burg algorithm, covariance

library(speaker)
library(bench)

cat("\n=== Phase 3: Formant/LPC Benchmark ===\n")
cat("Target speedup: 2-4x\n")
cat("Operations: LPC autocorrelation, Burg algorithm\n\n")

# Test configurations (formant extraction is expensive)
configs <- list(
  small = list(duration = 0.5, sample_rate = 16000, label = "Small (0.5s)"),
  medium = list(duration = 2.0, sample_rate = 16000, label = "Medium (2s)"),
  large = list(duration = 5.0, sample_rate = 16000, label = "Large (5s)")
)

results <- list()

for (config_name in names(configs)) {
  cfg <- configs[[config_name]]
  
  cat(sprintf("\nBenchmarking: %s\n", cfg$label))
  
  # Create test sound with vowel-like spectrum
  n_samples <- cfg$duration * cfg$sample_rate
  t <- seq(0, cfg$duration, length.out = n_samples)
  
  # Simulate vowel with formants at F1=700Hz, F2=1200Hz, F3=2500Hz
  signal <- sin(2 * pi * 150 * t)  # F0
  # Add formant resonances (simplified)
  for (f in c(700, 1200, 2500)) {
    signal <- signal + 0.3 * sin(2 * pi * f * t) * exp(-abs(t - cfg$duration/2) * 5)
  }
  
  sound <- Sound$new_from_values(
    values = matrix(signal, nrow = 1),
    sampling_rate = cfg$sample_rate
  )
  
  # Benchmark: Formant extraction (Burg method - most common)
  bm_formant_burg <- bench::mark(
    to_formant_burg = {
      formant <- sound$to_formant_burg(
        time_step = 0.01,
        max_number_of_formants = 5,
        maximum_formant = 5500,
        window_length = 0.025,
        pre_emphasis_from = 50
      )
      rm(formant)
      gc(verbose = FALSE)
    },
    iterations = 20,
    check = FALSE
  )
  
  # Benchmark: LPC analysis (Burg)
  bm_lpc_burg <- bench::mark(
    to_lpc_burg = {
      lpc <- sound$to_lpc_burg(
        prediction_order = 16,
        window_length = 0.025,
        time_step = 0.005,
        pre_emphasis_frequency = 50
      )
      rm(lpc)
      gc(verbose = FALSE)
    },
    iterations = 20,
    check = FALSE
  )
  
  # Benchmark: LPC autocorrelation method
  bm_lpc_auto <- bench::mark(
    to_lpc_autocorrelation = {
      lpc <- sound$to_lpc_autocorrelation(
        prediction_order = 16,
        window_length = 0.025,
        time_step = 0.005,
        pre_emphasis_frequency = 50
      )
      rm(lpc)
      gc(verbose = FALSE)
    },
    iterations = 20,
    check = FALSE
  )
  
  # Benchmark: LPC covariance method
  bm_lpc_cov <- bench::mark(
    to_lpc_covariance = {
      lpc <- sound$to_lpc_covariance(
        prediction_order = 16,
        window_length = 0.025,
        time_step = 0.005,
        pre_emphasis_frequency = 50
      )
      rm(lpc)
      gc(verbose = FALSE)
    },
    iterations = 20,
    check = FALSE
  )
  
  results[[config_name]] <- list(
    config = cfg,
    formant_burg = bm_formant_burg,
    lpc_burg = bm_lpc_burg,
    lpc_autocorrelation = bm_lpc_auto,
    lpc_covariance = bm_lpc_cov
  )
  
  cat(sprintf("  Formant (Burg): %s\n", format(bm_formant_burg$median)))
  cat(sprintf("  LPC (Burg): %s\n", format(bm_lpc_burg$median)))
  cat(sprintf("  LPC (Autocorrelation): %s\n", format(bm_lpc_auto$median)))
  cat(sprintf("  LPC (Covariance): %s\n", format(bm_lpc_cov$median)))
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
  for (op in c("formant_burg", "lpc_burg", "lpc_autocorrelation", "lpc_covariance")) {
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
output_file <- sprintf("results/baseline/09_phase3_formant_lpc_%s.rds", timestamp)

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
cat("\nNote: LPC/Formant extraction involves:\n")
cat("  - Autocorrelation computation (SIMD target)\n")
cat("  - Levinson-Durbin recursion (harder to vectorize)\n")
cat("  - Root finding (sequential)\n")
cat("Expected speedup: 2-4x (autocorrelation phase will benefit most)\n")
