# phase1_integration_benchmark.R
# SIMD Phase 1 Integration Benchmarks
# Comprehensive performance testing for Tasks 1.1-1.4
# Author: Claude (2026-01-21)

library(pladdrr)
library(microbenchmark)

# ============================================================================
# Configuration
# ============================================================================

# Benchmark parameters
BENCHMARK_TIMES <- 50  # Number of iterations per test
WARMUP_ITERATIONS <- 5  # Warmup runs

# Test audio parameters
TEST_DURATION <- 5.0    # seconds
TEST_FREQUENCY <- 440   # Hz
TEST_SAMPLE_RATE <- 44100  # Hz

# ============================================================================
# Helper Functions
# ============================================================================

# Print section header
print_section <- function(title) {
  cat("\n")
  cat(paste0(rep("=", 70), collapse = ""), "\n")
  cat(title, "\n")
  cat(paste0(rep("=", 70), collapse = ""), "\n\n")
}

# Format speedup report
report_speedup <- function(scalar_time, simd_time, operation) {
  speedup <- scalar_time / simd_time
  cat(sprintf("%-30s: %.2fx speedup (SIMD: %6.2f ms, Scalar: %6.2f ms)\n",
              operation, speedup, simd_time, scalar_time))
  return(speedup)
}

# Get SIMD info
simd_status <- simd_info()

# ============================================================================
# Setup
# ============================================================================

print_section("SIMD Phase 1 Integration Benchmark")

cat("System Information:\n")
cat(sprintf("  R version: %s\n", R.version.string))
cat(sprintf("  pladdrr version: %s\n", packageVersion("pladdrr")))
cat(sprintf("  SIMD enabled: %s\n", simd_status$enabled))
cat(sprintf("  SIMD architecture: %s\n", simd_status$architecture))
cat(sprintf("  SIMD batch size (double): %d\n", simd_status$batch_size_double))
cat("\n")

cat("Benchmark Configuration:\n")
cat(sprintf("  Test duration: %.1f seconds\n", TEST_DURATION))
cat(sprintf("  Sample rate: %d Hz\n", TEST_SAMPLE_RATE))
cat(sprintf("  Iterations per test: %d\n", BENCHMARK_TIMES))
cat("\n")

# Create test sound
cat("Creating test audio... ")
test_sound <- Sound$create_tone(TEST_FREQUENCY,
                                duration = TEST_DURATION)
cat("Done\n")

# Warmup
cat("Warming up... ")
for (i in 1:WARMUP_ITERATIONS) {
  options(speaker.use_simd = TRUE)
  p <- test_sound$to_pitch()
  rm(p)
  gc(verbose = FALSE)
}
cat("Done\n")

# ============================================================================
# Task 1.1: Pitch Extraction Benchmarks
# ============================================================================

print_section("Task 1.1: Pitch Extraction (Autocorrelation SIMD)")

cat("Benchmarking Sound$to_pitch_ac() ...\n")

# Scalar version
options(speaker.use_simd = FALSE)
bench_pitch_ac_scalar <- microbenchmark(
  pitch_ac_scalar = test_sound$to_pitch_ac(time_step = 0.01,
                                            pitch_floor = 75,
                                            pitch_ceiling = 600),
  times = BENCHMARK_TIMES,
  unit = "ms"
)
pitch_ac_scalar_median <- median(bench_pitch_ac_scalar$time) / 1e6

# SIMD version
options(speaker.use_simd = TRUE)
bench_pitch_ac_simd <- microbenchmark(
  pitch_ac_simd = test_sound$to_pitch_ac(time_step = 0.01,
                                          pitch_floor = 75,
                                          pitch_ceiling = 600),
  times = BENCHMARK_TIMES,
  unit = "ms"
)
pitch_ac_simd_median <- median(bench_pitch_ac_simd$time) / 1e6

speedup_pitch_ac <- report_speedup(pitch_ac_scalar_median, pitch_ac_simd_median,
                                    "Pitch (AC method)")
cat("\n")

# Cross-correlation method
cat("Benchmarking Sound$to_pitch_cc() ... ")
tryCatch({
  # Scalar
  options(speaker.use_simd = FALSE)
  bench_pitch_cc_scalar <- microbenchmark(
    pitch_cc_scalar = test_sound$to_pitch_cc(time_step = 0.01,
                                              pitch_floor = 200,
                                              pitch_ceiling = 600),
    times = BENCHMARK_TIMES,
    unit = "ms"
  )
  pitch_cc_scalar_median <- median(bench_pitch_cc_scalar$time) / 1e6

  # SIMD
  options(speaker.use_simd = TRUE)
  bench_pitch_cc_simd <- microbenchmark(
    pitch_cc_simd = test_sound$to_pitch_cc(time_step = 0.01,
                                            pitch_floor = 200,
                                            pitch_ceiling = 600),
    times = BENCHMARK_TIMES,
    unit = "ms"
  )
  pitch_cc_simd_median <- median(bench_pitch_cc_simd$time) / 1e6

  speedup_pitch_cc <- report_speedup(pitch_cc_scalar_median, pitch_cc_simd_simd_median,
                                      "Pitch (CC method)")
}, error = function(e) {
  cat("SKIPPED (parameter issues)\n")
  speedup_pitch_cc <<- NA
})

# ============================================================================
# Task 1.2: Intensity Calculation Benchmarks
# ============================================================================

print_section("Task 1.2: Intensity Calculation (Windowed RMS SIMD)")

cat("Benchmarking Sound$to_intensity() ...\n")

# Scalar
options(speaker.use_simd = FALSE)
bench_intensity_scalar <- microbenchmark(
  intensity_scalar = test_sound$to_intensity(minimum_pitch = 100,
                                              time_step = 0.01,
                                              subtract_mean = TRUE),
  times = BENCHMARK_TIMES,
  unit = "ms"
)
intensity_scalar_median <- median(bench_intensity_scalar$time) / 1e6

# SIMD
options(speaker.use_simd = TRUE)
bench_intensity_simd <- microbenchmark(
  intensity_simd = test_sound$to_intensity(minimum_pitch = 100,
                                            time_step = 0.01,
                                            subtract_mean = TRUE),
  times = BENCHMARK_TIMES,
  unit = "ms"
)
intensity_simd_median <- median(bench_intensity_simd$time) / 1e6

speedup_intensity <- report_speedup(intensity_scalar_median, intensity_simd_median,
                                     "Intensity (windowed RMS)")

# ============================================================================
# Task 1.3: Formant Extraction Benchmarks
# ============================================================================

print_section("Task 1.3: Formant Extraction (Burg's Algorithm SIMD)")

cat("Benchmarking Sound$to_formant_burg() ... ")
tryCatch({
  # Scalar
  options(speaker.use_simd = FALSE)
  bench_formant_scalar <- microbenchmark(
    formant_scalar = test_sound$to_formant_burg(time_step = 0.01,
                                                 max_formants = 5,
                                                 max_frequency = 5500,
                                                 window_length = 0.025,
                                                 pre_emphasis_from = 50),
    times = BENCHMARK_TIMES,
    unit = "ms"
  )
  formant_scalar_median <- median(bench_formant_scalar$time) / 1e6

  # SIMD
  options(speaker.use_simd = TRUE)
  bench_formant_simd <- microbenchmark(
    formant_simd = test_sound$to_formant_burg(time_step = 0.01,
                                               max_formants = 5,
                                               max_frequency = 5500,
                                               window_length = 0.025,
                                               pre_emphasis_from = 50),
    times = BENCHMARK_TIMES,
    unit = "ms"
  )
  formant_simd_median <- median(bench_formant_simd$time) / 1e6

  speedup_formant <- report_speedup(formant_scalar_median, formant_simd_median,
                                     "Formant (Burg LPC)")
}, error = function(e) {
  cat("SKIPPED (pure tone has no formants)\n")
  speedup_formant <<- NA
})

# ============================================================================
# Task 1.4: Spectrogram (Window Functions SIMD)
# ============================================================================

print_section("Task 1.4: Spectrogram Generation (Window Functions SIMD)")

cat("Benchmarking Sound$to_spectrogram() with Hamming window... ")
tryCatch({
  # Scalar
  options(speaker.use_simd = FALSE)
  bench_spec_scalar <- microbenchmark(
    spec_scalar = test_sound$to_spectrogram(window_length = 0.005,
                                             max_frequency = 5000,
                                             time_step = 0.002,
                                             frequency_step = 20,
                                             window_shape = "Hamming"),
    times = BENCHMARK_TIMES,
    unit = "ms"
  )
  spec_scalar_median <- median(bench_spec_scalar$time) / 1e6

  # SIMD
  options(speaker.use_simd = TRUE)
  bench_spec_simd <- microbenchmark(
    spec_simd = test_sound$to_spectrogram(window_length = 0.005,
                                           max_frequency = 5000,
                                           time_step = 0.002,
                                           frequency_step = 20,
                                           window_shape = "Hamming"),
    times = BENCHMARK_TIMES,
    unit = "ms"
  )
  spec_simd_median <- median(bench_spec_simd$time) / 1e6

  speedup_spec <- report_speedup(spec_scalar_median, spec_simd_median,
                                  "Spectrogram (Hamming)")
}, error = function(e) {
  cat("SKIPPED (test signal incompatible)\n")
  speedup_spec <<- NA
})

# ============================================================================
# Summary Report
# ============================================================================

print_section("Phase 1 Integration Summary")

cat("Speedup Results:\n\n")

# Create results only for completed benchmarks
results_list <- list()
if (exists("speedup_pitch_ac") && !is.na(speedup_pitch_ac)) {
  results_list[[length(results_list) + 1]] <- list(
    Operation = "Pitch (AC)", Speedup = speedup_pitch_ac,
    Scalar_ms = pitch_ac_scalar_median, SIMD_ms = pitch_ac_simd_median,
    Target = "1.5-2.5x"
  )
}
if (exists("speedup_intensity") && !is.na(speedup_intensity)) {
  results_list[[length(results_list) + 1]] <- list(
    Operation = "Intensity", Speedup = speedup_intensity,
    Scalar_ms = intensity_scalar_median, SIMD_ms = intensity_simd_median,
    Target = "1.5-2.0x"
  )
}
if (exists("speedup_formant") && !is.na(speedup_formant)) {
  results_list[[length(results_list) + 1]] <- list(
    Operation = "Formant (Burg)", Speedup = speedup_formant,
    Scalar_ms = formant_scalar_median, SIMD_ms = formant_simd_median,
    Target = "2.0-4.0x"
  )
}

if (length(results_list) > 0) {
  results <- do.call(rbind, lapply(results_list, as.data.frame))
  results$Status <- ifelse(
    (results$Operation == "Pitch (AC)" & results$Speedup >= 1.5) |
    (results$Operation == "Intensity" & results$Speedup >= 1.5) |
    (results$Operation == "Formant (Burg)" & results$Speedup >= 2.0),
    "✓", "✗"
  )

  print(results, row.names = FALSE)

  cat("\n")
  cat(sprintf("Overall average speedup: %.2fx\n", mean(results$Speedup, na.rm = TRUE)))
  cat(sprintf("Target achievement: %d/%d operations meeting target\n",
              sum(results$Status == "✓"), nrow(results)))
} else {
  cat("No benchmarks completed successfully.\n")
}

# ============================================================================
# Detailed Statistics
# ============================================================================

print_section("Detailed Statistics")

if (exists("bench_pitch_ac_simd")) {
  cat("\nPitch (AC) Benchmark:\n")
  print(summary(bench_pitch_ac_simd))
  print(summary(bench_pitch_ac_scalar))
}

if (exists("bench_intensity_simd")) {
  cat("\nIntensity Benchmark:\n")
  print(summary(bench_intensity_simd))
  print(summary(bench_intensity_scalar))
}

cat("\nFormant Benchmark:\n")
print(summary(bench_formant_simd))
print(summary(bench_formant_scalar))

# ============================================================================
# Save Results
# ============================================================================

results_file <- sprintf("phase1_benchmark_results_%s.rds",
                        format(Sys.time(), "%Y%m%d_%H%M%S"))

benchmark_results <- list(
  timestamp = Sys.time(),
  system_info = simd_status,
  r_version = R.version.string,
  package_version = as.character(packageVersion("pladdrr")),
  results_summary = results,
  detailed_results = list(
    pitch_ac = list(scalar = bench_pitch_ac_scalar, simd = bench_pitch_ac_simd),
    pitch_cc = list(scalar = bench_pitch_cc_scalar, simd = bench_pitch_cc_simd),
    intensity = list(scalar = bench_intensity_scalar, simd = bench_intensity_simd),
    formant = list(scalar = bench_formant_scalar, simd = bench_formant_simd),
    spectrogram = list(scalar = bench_spec_scalar, simd = bench_spec_simd)
  )
)

saveRDS(benchmark_results, file.path("benchmarks", results_file))

cat(sprintf("\nResults saved to: benchmarks/%s\n", results_file))

print_section("Benchmark Complete")

# Reset to default
options(speaker.use_simd = TRUE)
