#!/usr/bin/env Rscript
# Benchmark: Old R6 vs New Module-based Pitch
# Measures actual performance improvement from Rcpp Modules

library(pladdrr)
library(bench)

cat("========================================\n")
cat("Pitch Module Performance Benchmark\n")
cat("========================================\n\n")

# Create test sound (1 second, 440 Hz)
cat("Preparing test sound...\n")
sound <- Sound$create_tone(duration = 1.0, sampling_rate = 44100, frequency = 440, amplitude = 0.5)
cat("✓ Sound ready\n\n")

# Test 1: Pitch extraction
cat("1. Benchmarking pitch extraction...\n")
bench_extract <- mark(
  extract = sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600),
  iterations = 100,
  check = FALSE
)
cat(sprintf("   Median: %s\n", format(bench_extract$median[[1]])))
cat(sprintf("   Mean:   %s\n", format(bench_extract$mean[[1]])))
cat("\n")

# Test 2: Property access (low overhead operations)
cat("2. Benchmarking property access...\n")
pitch <- sound$to_pitch()
bench_props <- mark(
  duration = pitch$duration(),
  frames = pitch$get_number_of_frames(),
  time_step = pitch$get_time_step(),
  iterations = 10000,
  check = FALSE
)
print(bench_props[, c("expression", "median", "mem_alloc")])
cat("\n")

# Test 3: Query methods (medium overhead)
cat("3. Benchmarking query methods...\n")
bench_queries <- mark(
  get_mean = pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz"),
  get_min = pitch$get_minimum(from_time = 0, to_time = 0, unit = "hertz"),
  get_max = pitch$get_maximum(from_time = 0, to_time = 0, unit = "hertz"),
  get_sd = pitch$get_standard_deviation(from_time = 0, to_time = 0, unit = "hertz"),
  count_voiced = pitch$count_voiced_frames(),
  iterations = 1000,
  check = FALSE
)
print(bench_queries[, c("expression", "median", "mem_alloc")])
cat("\n")

# Test 4: Value queries (high frequency operation)
cat("4. Benchmarking high-frequency operations (1000 calls)...\n")
times <- seq(0, 1, length.out = 1000)
bench_highfreq <- mark(
  value_queries = {
    for (t in times) {
      pitch$get_value_at_time(t, unit = "hertz", interpolate = TRUE)
    }
  },
  iterations = 10,
  check = FALSE
)
cat(sprintf("   1000 calls: %s\n", format(bench_highfreq$median[[1]])))
cat(sprintf("   Per call:   %s\n", format(bench_highfreq$median[[1]] / 1000)))
cat("\n")

# Test 5: Export operations
cat("5. Benchmarking export operations...\n")
bench_export <- mark(
  to_dataframe = as.data.frame(pitch),
  to_matrix = pitch$as_matrix(),
  iterations = 100,
  check = FALSE
)
print(bench_export[, c("expression", "median", "mem_alloc")])
cat("\n")

# Summary
cat("========================================\n")
cat("Summary\n")
cat("========================================\n\n")

cat("Module-based Pitch implementation is functional.\n\n")

cat("Key metrics:\n")
cat(sprintf("  Pitch extraction:   %s\n", format(bench_extract$median[[1]])))
cat(sprintf("  Property access:    %s - %s\n", 
            format(min(bench_props$median)), 
            format(max(bench_props$median))))
cat(sprintf("  Query methods:      %s - %s\n", 
            format(min(bench_queries$median)), 
            format(max(bench_queries$median))))
cat(sprintf("  Per-call overhead:  %s\n", format(bench_highfreq$median[[1]] / 1000)))
cat("\n")

cat("Note: To compare with R6 version, run with R6 implementation and compare results.\n")
cat("Expected improvement: 2-3x faster for query-heavy operations.\n")
