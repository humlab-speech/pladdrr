#!/usr/bin/env Rscript
# Performance Benchmark: Current vs POC Sound Implementation
# POC Day 5 - Performance Testing

library(microbenchmark)
library(pladdrr)

cat("=== Sound POC Performance Benchmark ===\n")
cat("Testing current implementation vs POC (Rcpp Modules)\n")
cat("Target: POC within 5% of current performance\n\n")

# Check if test file exists
test_file <- "inst/extdata/test.wav"
if (!file.exists(test_file)) {
  # Try alternate paths
  test_file <- "inst/extdata/hallo.wav"
  if (!file.exists(test_file)) {
    stop("No test audio file found. Need inst/extdata/test.wav or hallo.wav")
  }
}

cat("Using test file:", test_file, "\n\n")

# Load with both implementations
cat("Loading Sound objects...\n")
sound_current <- tryCatch({
  praat_read_Sound(test_file)
}, error = function(e) {
  cat("Current implementation not available, using Sound$new()\n")
  Sound$new(test_file)
})

sound_poc <- new(SoundModulePOC, test_file)
cat("Both loaded successfully\n\n")

# Test 1: Simple Queries
cat("=== Test 1: Simple Queries ===\n")
bm_queries <- microbenchmark(
  current_duration = sound_current$get_duration(),
  poc_duration = sound_poc$get_duration(),
  
  current_sampling = sound_current$get_sampling_frequency(),
  poc_sampling = sound_poc$get_sampling_frequency(),
  
  current_nsamples = sound_current$get_number_of_samples(),
  poc_nsamples = sound_poc$get_number_of_samples(),
  
  times = 500
)
print(bm_queries)

# Calculate overhead
query_results <- summary(bm_queries)
current_median <- median(query_results$median[seq(1, 6, 2)])
poc_median <- median(query_results$median[seq(2, 6, 2)])
query_overhead <- ((poc_median - current_median) / current_median) * 100
cat(sprintf("\nQuery overhead: %.2f%% %s\n\n", 
            query_overhead, 
            ifelse(query_overhead <= 5, "✅ PASS", "❌ FAIL")))

# Test 2: Complex Transforms
cat("=== Test 2: Complex Transforms (to_Pitch) ===\n")
bm_pitch <- microbenchmark(
  current_pitch = sound_current$to_Pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600),
  poc_pitch = sound_poc$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600),
  
  times = 50
)
print(bm_pitch)

pitch_results <- summary(bm_pitch)
pitch_overhead <- ((pitch_results$median[2] - pitch_results$median[1]) / pitch_results$median[1]) * 100
cat(sprintf("\nPitch overhead: %.2f%% %s\n\n", 
            pitch_overhead, 
            ifelse(pitch_overhead <= 5, "✅ PASS", "❌ FAIL")))

# Test 3: In-Place Modifications
cat("=== Test 3: In-Place Modifications ===\n")

# Need to reload for each test to avoid side effects
test_current_scale <- function() {
  s <- Sound$new(test_file)
  s$scale_intensity(70)
}

test_poc_scale <- function() {
  s <- new(SoundModulePOC, test_file)
  s$scale_intensity(70)
}

bm_modify <- microbenchmark(
  current_scale = test_current_scale(),
  poc_scale = test_poc_scale(),
  
  times = 100
)
print(bm_modify)

modify_results <- summary(bm_modify)
modify_overhead <- ((modify_results$median[2] - modify_results$median[1]) / modify_results$median[1]) * 100
cat(sprintf("\nModification overhead: %.2f%% %s\n\n", 
            modify_overhead, 
            ifelse(modify_overhead <= 5, "✅ PASS", "❌ FAIL")))

# Test 4: Export Operations
cat("=== Test 4: Export Operations ===\n")
bm_export <- microbenchmark(
  current_matrix = sound_current$as_matrix(),
  poc_matrix = sound_poc$as_matrix(),
  
  current_values = sound_current$get_values(channel = 1),
  poc_values = sound_poc$get_values(channel = 1),
  
  times = 200
)
print(bm_export)

export_results <- summary(bm_export)
export_overhead <- ((export_results$median[2] - export_results$median[1]) / export_results$median[1]) * 100
cat(sprintf("\nExport overhead: %.2f%% %s\n\n", 
            export_overhead, 
            ifelse(export_overhead <= 5, "✅ PASS", "❌ FAIL")))

# Summary
cat("\n=== PERFORMANCE SUMMARY ===\n")
cat(sprintf("Query operations:        %+.2f%%\n", query_overhead))
cat(sprintf("Complex transforms:      %+.2f%%\n", pitch_overhead))
cat(sprintf("In-place modifications:  %+.2f%%\n", modify_overhead))
cat(sprintf("Export operations:       %+.2f%%\n", export_overhead))

overall_overhead <- mean(c(query_overhead, pitch_overhead, modify_overhead, export_overhead))
cat(sprintf("\nOverall average:         %+.2f%% %s\n", 
            overall_overhead,
            ifelse(overall_overhead <= 5, "✅ PASS", "❌ FAIL")))

if (overall_overhead <= 5) {
  cat("\n✅ PERFORMANCE TEST PASSED\n")
  cat("POC implementation meets performance requirements (≤5% overhead)\n")
  quit(status = 0)
} else {
  cat("\n⚠️  PERFORMANCE TEST NEEDS REVIEW\n")
  cat("POC implementation has >5% overhead, investigate optimization\n")
  quit(status = 1)
}
