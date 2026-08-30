# Pitch API Tier Comparison Benchmark
# Compare Tier 1 (Standard) vs Tier 3 (Batch) for custom pitch parameters
# Related to v4.0.1 Direct API documentation (agents/AGENT_GUIDE.md)

cat("\n=== Pitch API Tier Comparison Benchmark ===\n")
cat("Purpose: Compare performance when custom voicing parameters ",
    "are required\n\n", sep = "")

library(pladdrr)
library(microbenchmark)

# Create test audio
sr <- 16000
duration <- 1.0 # 1 second
n_samples <- as.integer(sr * duration)
time <- seq(0, duration - 1 / sr, length.out = n_samples)
test_audio <- sin(2 * pi * 200 * time) + sin(2 * pi * 300 * time)
test_audio <- test_audio / max(abs(test_audio)) * 0.5

sound <- Sound(
  values = test_audio,
  sampling_frequency = sr,
  start_time = 0
)

cat("Test audio: 1 second, 16kHz, dual-tone signal\n\n")

# Custom parameters (these require Tier 1 or Tier 3, not available in
# Direct API)
custom_params <- list(
  time_step = 0,
  pitch_floor = 75,
  pitch_ceiling = 600,
  max_candidates = 15,
  very_accurate = FALSE,
  silence_threshold = 0.01, # Custom (default: 0.03)
  voicing_threshold = 0.6, # Custom (default: 0.45)
  octave_cost = 0.02, # Custom (default: 0.01)
  octave_jump_cost = 0.35,
  voiced_unvoiced_cost = 0.14
)

cat("Custom parameters:\n")
cat(sprintf(
  "  silence_threshold: %.2f (vs default 0.03)\n",
  custom_params$silence_threshold
))
cat(sprintf(
  "  voicing_threshold: %.2f (vs default 0.45)\n",
  custom_params$voicing_threshold
))
cat(sprintf(
  "  octave_cost: %.2f (vs default 0.01)\n\n",
  custom_params$octave_cost
))

# Benchmark 1: Single file - Tier 1 vs Direct API (if it existed with
# full params)
cat("Benchmark 1: Single File Processing\n")
cat("Comparing Tier 1 (Standard API) with custom parameters\n\n")

tier1_result <- microbenchmark(
  Tier1_Standard = {
    pitch <- sound$to_pitch_cc(
      time_step = custom_params$time_step,
      pitch_floor = custom_params$pitch_floor,
      pitch_ceiling = custom_params$pitch_ceiling,
      max_candidates = custom_params$max_candidates,
      very_accurate = custom_params$very_accurate,
      silence_threshold = custom_params$silence_threshold,
      voicing_threshold = custom_params$voicing_threshold,
      octave_cost = custom_params$octave_cost,
      octave_jump_cost = custom_params$octave_jump_cost,
      voiced_unvoiced_cost = custom_params$voiced_unvoiced_cost
    )
  },
  times = 50
)

print(tier1_result)
cat("\n")

# Benchmark 2: Multiple files - Tier 1 vs Tier 3
n_files <- c(5, 10, 20, 50)
batch_results <- list()

for (n in n_files) {
  cat(sprintf("Benchmark 2: %d Files Processing\n", n))
  cat(
    "Comparing Tier 1 (Standard) vs Tier 3 (Batch) with custom parameters\n\n"
  )

  # Create multiple sound objects
  sounds <- replicate(n, sound, simplify = FALSE)

  result <- microbenchmark(
    Tier1_Loop = {
      pitches <- lapply(sounds, function(s) {
        s$to_pitch_cc(
          time_step = custom_params$time_step,
          pitch_floor = custom_params$pitch_floor,
          pitch_ceiling = custom_params$pitch_ceiling,
          max_candidates = custom_params$max_candidates,
          very_accurate = custom_params$very_accurate,
          silence_threshold = custom_params$silence_threshold,
          voicing_threshold = custom_params$voicing_threshold,
          octave_cost = custom_params$octave_cost,
          octave_jump_cost = custom_params$octave_jump_cost,
          voiced_unvoiced_cost = custom_params$voiced_unvoiced_cost
        )
      })
    },
    Tier3_Batch = {
      pitches <- sound_to_pitch_cc_batch(
        sounds,
        time_step = custom_params$time_step,
        pitch_floor = custom_params$pitch_floor,
        pitch_ceiling = custom_params$pitch_ceiling,
        max_candidates = custom_params$max_candidates,
        very_accurate = custom_params$very_accurate,
        silence_threshold = custom_params$silence_threshold,
        voicing_threshold = custom_params$voicing_threshold,
        octave_cost = custom_params$octave_cost,
        octave_jump_cost = custom_params$octave_jump_cost,
        voiced_unvoiced_cost = custom_params$voiced_unvoiced_cost
      )
    },
    times = 20
  )

  print(result)

  # Calculate speedup
  medians <- summary(result)$median
  # speedup: Tier1_Loop median / Tier3_Batch median
  speedup <- medians[1] / medians[2]

  cat(sprintf("\nSpeedup (Tier 3 vs Tier 1): %.2fx\n", speedup))
  cat(sprintf(
    "Recommendation: Use Tier 3 for >%d files with custom parameters\n\n",
    ifelse(speedup > 1.5, 5, 10)
  ))

  batch_results[[as.character(n)]] <- list(
    n_files = n,
    tier1_median_ms = medians[1],
    tier3_median_ms = medians[2],
    speedup = speedup
  )
}

# Summary
cat("\n=== Summary ===\n\n")
cat("For pitch extraction with custom parameters:\n\n")

cat("Single file:\n")
cat("  - Use Tier 1 (Standard API): sound$to_pitch_cc(...)\n")
cat(
  "  - Performance: ~", round(summary(tier1_result)$median, 2), " ms\n\n"
)

cat("Multiple files:\n")
for (n in names(batch_results)) {
  res <- batch_results[[n]]
  cat(sprintf(
    "  - %s files: Tier 3 is %.2fx faster (%.1f ms vs %.1f ms)\n",
    n, res$speedup, res$tier3_median_ms, res$tier1_median_ms
  ))
}

cat("\nRecommendation:\n")
cat("  - 1 file: Use Tier 1 (Standard API)\n")
best_batch_n <- min(as.numeric(names(batch_results)[
  vapply(batch_results, function(x) x$speedup > 1.5, logical(1))
]))
cat(sprintf(
  "  - >%d files: Use Tier 3 (Batch API) for best performance\n",
  best_batch_n
))

cat("\nNote: Direct API (Tier 2) does NOT support custom voicing parameters.\n")
cat("See agents/AGENT_GUIDE.md for workarounds and full documentation.\n\n")

# Save results
timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
output_file <- sprintf(
  "inst/benchmarks/results/17_pitch_api_tier_comparison_%s.rds",
  timestamp
)

results <- list(
  metadata = list(
    date = Sys.time(),
    benchmark = "Pitch API Tier Comparison",
    purpose = "Compare Tier 1 vs Tier 3 for custom pitch parameters",
    test_duration = duration,
    sampling_rate = sr
  ),
  single_file = tier1_result,
  batch_results = batch_results,
  custom_params = custom_params
)

dir.create("inst/benchmarks/results", showWarnings = FALSE, recursive = TRUE)
saveRDS(results, output_file)

cat(sprintf("Results saved to: %s\n", output_file))
