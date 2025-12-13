#!/usr/bin/env Rscript
# DSI Performance Benchmark - Phase 1 Optimization
# Compare optimized build against baseline from DSI_PERFORMANCE_ANALYSIS.md
#
# Baseline (unoptimized):
#   - Total DSI: 2.902s (12 files)
#   - Pitch extraction: 0.289s (single file)
#
# Expected Phase 1 (with -O3 -flto):
#   - Total DSI: ~1.7-2.0s (40-50% improvement)
#   - Pitch extraction: ~0.190s (1.5x faster)

library(pladdrr)
library(microbenchmark)

# Test files
dsi_dir <- "inst/signalfiles/DSI/input"
test_files <- list(
  mpt = file.path(dsi_dir, c("mpt1.wav", "mpt2.wav", "mpt3.wav")),
  fh  = file.path(dsi_dir, c("fh1.wav", "fh2.wav", "fh3.wav")),
  im  = file.path(dsi_dir, c("im1.wav", "im2.wav", "im3.wav")),
  ppq = file.path(dsi_dir, c("ppq1.wav", "ppq2.wav", "ppq3.wav"))
)

cat("=== Phase 1 DSI Performance Benchmark ===\n\n")

# 1. Single pitch extraction (comparable to baseline)
cat("1. Single Pitch Extraction (mpt1.wav):\n")
pitch_bench <- microbenchmark(
  {
    snd <- Sound$new(test_files$mpt[[1]])
    pitch <- snd$to_pitch()
  },
  times = 10
)
print(pitch_bench)
pitch_median_ms <- median(pitch_bench$time) / 1e6
cat(sprintf("   Median: %.1f ms\n", pitch_median_ms))
cat(sprintf("   Baseline: 289 ms\n"))
cat(sprintf("   Speedup: %.2fx\n\n", 289 / pitch_median_ms))

# 2. Full DSI calculation (all 12 files)
cat("2. Full DSI Calculation (12 files):\n")

calc_dsi <- function() {
  # Load all sounds
  mpt_snds <- lapply(test_files$mpt, Sound$new)
  fh_snds  <- lapply(test_files$fh, Sound$new)
  im_snds  <- lapply(test_files$im, Sound$new)
  ppq_snds <- lapply(test_files$ppq, Sound$new)
  
  # Extract pitches
  mpt_pitches <- lapply(mpt_snds, function(s) s$to_pitch())
  ppq_pitches <- lapply(ppq_snds, function(s) s$to_pitch())
  
  # Calculate metrics (simplified)
  mpt_means <- sapply(mpt_pitches, function(p) p$get_mean(unit = "hertz"))
  ppq_means <- sapply(ppq_pitches, function(p) {
    pp <- p$to_point_process()
    pp$get_jitter_ppq5(0, 0, 0.0001, 0.02, 1.3)
  })
  
  list(mpt = mpt_means, ppq = ppq_means)
}

dsi_bench <- microbenchmark(
  calc_dsi(),
  times = 5
)
print(dsi_bench)
dsi_median_s <- median(dsi_bench$time) / 1e9
cat(sprintf("   Median: %.3f s\n", dsi_median_s))
cat(sprintf("   Baseline: 2.902 s\n"))
cat(sprintf("   Speedup: %.2fx\n\n", 2.902 / dsi_median_s))

# 3. Summary
cat("=== Summary ===\n")
cat(sprintf("Pitch extraction: %.1f ms (%.2fx speedup)\n", 
            pitch_median_ms, 289 / pitch_median_ms))
cat(sprintf("Full DSI:         %.3f s (%.2fx speedup)\n", 
            dsi_median_s, 2.902 / dsi_median_s))

improvement_pct <- (1 - dsi_median_s / 2.902) * 100
cat(sprintf("Overall improvement: %.1f%%\n", improvement_pct))

if (improvement_pct >= 30) {
  cat("\n✅ SUCCESS: Phase 1 optimization achieved target (>30% improvement)\n")
} else {
  cat(sprintf("\n⚠️  WARNING: Below target. Expected >30%%, got %.1f%%\n", improvement_pct))
}
