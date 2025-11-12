# Benchmark 3: Tone Generation (Sine Wave Synthesis)
# Tests: Creating pure tones of various durations
# Expected SIMD speedup: 4-6x

library(speaker)
library(bench)

cat("="*80, "\n")
cat("Benchmark 3: Tone Generation (Baseline - Pre-SIMD)\n")
cat("="*80, "\n\n")

# Test different durations and frequencies
configs <- list(
  short_440Hz = list(duration = 0.1, freq = 440, amp = 1.0, rate = 44100),
  medium_440Hz = list(duration = 1.0, freq = 440, amp = 1.0, rate = 44100),
  long_440Hz = list(duration = 10.0, freq = 440, amp = 1.0, rate = 44100),
  medium_880Hz = list(duration = 1.0, freq = 880, amp = 1.0, rate = 44100),
  medium_220Hz = list(duration = 1.0, freq = 220, amp = 1.0, rate = 44100)
)

results <- list()

for (config_name in names(configs)) {
  cfg <- configs[[config_name]]
  n_samples <- as.integer(cfg$duration * cfg$rate)

  cat(sprintf("\nTesting %s (%.1f s, %.0f Hz, %d samples):\n",
              config_name, cfg$duration, cfg$freq, n_samples))

  # Benchmark tone generation
  bench_result <- bench::mark(
    create_tone = Sound$create_tone(cfg$duration, cfg$rate, cfg$freq, cfg$amp),
    iterations = 50,
    check = FALSE
  )

  results[[config_name]] <- list(
    benchmark = bench_result,
    config = cfg,
    n_samples = n_samples
  )

  print(bench_result[, c("expression", "min", "median", "max", "mem_alloc")])
  cat("\n")
}

# Save results
saveRDS(results, "inst/benchmarks/results/03_tone_generation_baseline.rds")

cat("\nBaseline results saved to: inst/benchmarks/results/03_tone_generation_baseline.rds\n")
