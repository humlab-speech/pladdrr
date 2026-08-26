# data.table Migration Performance Benchmark (v4.0.1)
# Compares critical operations before/after data.table migration

library(pladdrr)
library(microbenchmark)
library(data.table)

cat("\n")
cat(strrep("=", 80), "\n")
cat("PLADDRR v4.0.1 - DATA.TABLE MIGRATION BENCHMARK\n")
cat(strrep("=", 80), "\n")
cat("Date:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat("Package version:", as.character(packageVersion("pladdrr")), "\n")
cat(strrep("=", 80), "\n\n")

# Load test audio file
test_file <- system.file("extdata", "test.wav", package = "pladdrr")
if (!file.exists(test_file)) {
  stop("Test file not found. Please ensure package is properly installed.")
}

sound <- Sound$new(test_file)

# ==============================================================================
# BENCHMARK 1: Formant Extraction Data Structure Performance
# ==============================================================================

cat("\n[1/4] Formant Extraction - Testing data.table return performance...\n")

# Extract formant (this now returns data.table internally)
formant <- sound$to_formant_burg(
  time_step = 0.01,
  max_formants = 5,
  max_frequency = 5500,
  window_length = 0.025,
  pre_emphasis_from = 50
)

bm_formant <- microbenchmark(
  datatable_output = {
    df <- formant$as_data_frame(max_formants = 5)
    # Simulate filtering operation (keyed lookup)
    subset(df, time > 0.1 & time < 0.5)
  },
  times = 100
)

cat("\nFormant extraction + filtering:\n")
print(summary(bm_formant)[, c("expr", "mean", "median")])

# ==============================================================================
# BENCHMARK 2: Pitch Extraction Data Structure Performance
# ==============================================================================

cat("\n[2/4] Pitch Extraction - Testing data.table return performance...\n")

pitch <- sound$to_pitch_ac(
  time_step = 0.01,
  pitch_floor = 75,
  pitch_ceiling = 600
)

bm_pitch <- microbenchmark(
  datatable_output = {
    df <- pitch$as_data_frame()
    # Simulate filtering and aggregation
    subset(df, !is.na(frequency) & voiced)
  },
  times = 100
)

cat("\nPitch extraction + filtering:\n")
print(summary(bm_pitch)[, c("expr", "mean", "median")])

# ==============================================================================
# BENCHMARK 3: Intensity Extraction Data Structure Performance
# ==============================================================================

cat("\n[3/4] Intensity Extraction - Testing data.table return performance...\n")

intensity <- sound$to_intensity(
  minimum_pitch = 100,
  time_step = 0.01
)

bm_intensity <- microbenchmark(
  datatable_output = {
    df <- intensity$as_data_frame()
    # Simulate filtering
    subset(df, !is.na(intensity_db) & intensity_db > 50)
  },
  times = 100
)

cat("\nIntensity extraction + filtering:\n")
print(summary(bm_intensity)[, c("expr", "mean", "median")])

# ==============================================================================
# BENCHMARK 4: Batch Data Aggregation (Simulated)
# ==============================================================================

cat("\n[4/4] Batch Aggregation - Testing rbindlist performance...\n")

# Simulate extracting formants from multiple segments
n_segments <- 50

bm_batch <- microbenchmark(
  rbindlist_method = {
    results <- vector("list", n_segments)
    for (i in seq_len(n_segments)) {
      # Simulate repeated extraction (using cached result for speed)
      results[[i]] <- formant$as_data_frame(max_formants = 5)
      results[[i]]$file_id <- i
    }
    # This is the critical operation: combining many data.frames
    combined <- data.table::rbindlist(results)
    data.table::setkey(combined, file_id, time)
  },
  times = 20
)

cat("\nBatch aggregation (50 segments):\n")
print(summary(bm_batch)[, c("expr", "mean", "median")])

# ==============================================================================
# SUMMARY
# ==============================================================================

cat("\n")
cat(strrep("=", 80), "\n")
cat("BENCHMARK SUMMARY\n")
cat(strrep("=", 80), "\n\n")

cat("All operations now return data.table (inheriting from data.frame)\n")
cat("Key benefits:\n")
cat("  - Fast keyed lookups for filtering\n")
cat("  - Efficient rbindlist for batch operations\n")
cat("  - Memory-efficient reference semantics\n")
cat("  - Backward compatible with data.frame workflows\n\n")

cat("Results saved to: inst/benchmarks/results/16_datatable_results.rds\n")

# Save results
results <- list(
  timestamp = Sys.time(),
  package_version = as.character(packageVersion("pladdrr")),
  formant_benchmark = bm_formant,
  pitch_benchmark = bm_pitch,
  intensity_benchmark = bm_intensity,
  batch_benchmark = bm_batch
)

if (!dir.exists("inst/benchmarks/results")) {
  dir.create("inst/benchmarks/results", recursive = TRUE)
}

saveRDS(results, "inst/benchmarks/results/16_datatable_results.rds")

cat("\nBenchmark complete!\n")
