#!/usr/bin/env Rscript
# 13_phase3_autocorrelation.R
# Benchmark autocorrelation functions (SIMD Phase 3 - Highest Impact)

library(speaker)
library(bench)

cat("\n=== Phase 3: Autocorrelation Benchmark ===\n")
cat("Target speedup: 4.5-6x (EPYC), 2.5-3.5x (M1) - HIGHEST IMPACT\n")
cat("Operations: Autocorrelation for pitch detection and LPC\n\n")

# Test configurations
test_configs <- list(
  small = list(
    name = "Small (0.025s @ 16kHz, typical pitch frame)",
    n = 400, # 25ms at 16kHz
    max_lag = 200 # ~12.5ms (80 Hz minimum pitch)
  ),
  medium = list(
    name = "Medium (0.05s @ 16kHz, formant frame)",
    n = 800, # 50ms at 16kHz
    max_lag = 400
  ),
  large = list(
    name = "Large (1s @ 16kHz, full speech segment)",
    n = 16000,
    max_lag = 800
  ),
  xlarge = list(
    name = "X-Large (1s @ 44.1kHz, high-res audio)",
    n = 44100,
    max_lag = 2000
  )
)

results <- list()

for (config_name in names(test_configs)) {
  config <- test_configs[[config_name]]
  cat("\nBenchmarking:", config$name, "\n")

  # Generate test signal (speech-like: sine + harmonics + noise)
  t <- seq(0, config$n - 1) / 16000
  fundamental <- 120 # Hz (typical male voice)
  data <- sin(2 * pi * fundamental * t) +
    0.5 * sin(2 * pi * fundamental * 2 * t) +
    0.3 * sin(2 * pi * fundamental * 3 * t) +
    rnorm(config$n, sd = 0.1)

  # Benchmark autocorrelation
  result <- bench::mark(
    autocorr_scalar = speaker:::.autocorrelation_scalar(
      data, config$max_lag
    ),
    autocorr_simd = speaker:::.autocorrelation_simd(data, config$max_lag),
    autocorr_norm_scalar = speaker:::.autocorrelation_normalized_scalar(
      data, config$max_lag
    ),
    autocorr_norm_simd = speaker:::.autocorrelation_normalized_simd(
      data, config$max_lag
    ),
    iterations = if (config$n < 1000) 100 else 50,
    check = FALSE
  )

  print(result[, c("expression", "median", "mem_alloc")])

  # Calculate speedups
  expr <- as.character(result$expression)
  speedup <- as.numeric(result$median[expr == "autocorr_scalar"]) /
    as.numeric(result$median[expr == "autocorr_simd"])
  cat(sprintf("  Autocorrelation speedup: %.2fx\n", speedup))

  norm_speedup <- as.numeric(result$median[expr == "autocorr_norm_scalar"]) /
    as.numeric(result$median[expr == "autocorr_norm_simd"])
  cat(sprintf("  Normalized autocorr speedup: %.2fx\n", norm_speedup))

  results[[config_name]] <- result
}

# Benchmark LPC autocorrelation (used in formant extraction)
cat("\n--- LPC Autocorrelation (Formant Extraction) ---\n")
lpc_data <- sin(2 * pi * seq(0, 1, length.out = 8000) * 120) +
  rnorm(8000, sd = 0.1)
num_coeffs <- 12 # Typical for formant extraction

lpc_result <- bench::mark(
  lpc_scalar = speaker:::.lpc_autocorrelation_scalar(lpc_data, num_coeffs),
  lpc_simd = speaker:::.lpc_autocorrelation_simd(lpc_data, num_coeffs),
  iterations = 100,
  check = FALSE
)

print(lpc_result[, c("expression", "median", "mem_alloc")])

lpc_expr <- as.character(lpc_result$expression)
lpc_speedup <- as.numeric(lpc_result$median[lpc_expr == "lpc_scalar"]) /
  as.numeric(lpc_result$median[lpc_expr == "lpc_simd"])
cat(sprintf("  LPC autocorrelation speedup: %.2fx\n", lpc_speedup))

results$lpc <- lpc_result

# Save results
dir.create("inst/benchmarks/results", recursive = TRUE, showWarnings = FALSE)
saveRDS(
  results,
  "inst/benchmarks/results/13_phase3_autocorrelation_baseline.rds"
)
cat("\n✓ Autocorrelation benchmark complete\n")
cat(
  "  This is the HIGHEST IMPACT optimization for pitch and formant ",
  "analysis!\n",
  sep = ""
)
