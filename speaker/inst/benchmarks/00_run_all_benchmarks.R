# Master Benchmark Runner
# Runs all SIMD baseline benchmarks and saves results
# Run this BEFORE implementing SIMD optimizations

library(speaker)

cat("\n")
cat(strrep("=", 80), "\n")
cat("SPEAKER PACKAGE - SIMD BASELINE BENCHMARKS\n")
cat(strrep("=", 80), "\n")
cat("Date:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat("Package version:", as.character(packageVersion("speaker")), "\n")
cat("R version:", R.version.string, "\n")
cat("Platform:", R.version$platform, "\n")
cat(strrep("=", 80), "\n\n")

# Create results directory
if (!dir.exists("inst/benchmarks/results")) {
  dir.create("inst/benchmarks/results", recursive = TRUE)
  cat("Created results directory: inst/benchmarks/results/\n\n")
}

# Store system info  
system_info <- list(
  timestamp = Sys.time(),
  package_version = as.character(packageVersion("speaker")),
  r_version = R.version.string,
  platform = R.version$platform,
  cpu_info = if (.Platform$OS.type == "unix") {
    system("sysctl -n machdep.cpu.brand_string 2>/dev/null || echo 'Unknown'", intern = TRUE)
  } else {
    "Windows"
  },
  has_simd = requireNamespace("RcppXsimd", quietly = TRUE)
)

saveRDS(system_info, "inst/benchmarks/results/00_system_info.rds")


# List of benchmark scripts
benchmarks <- c(
  # Phase 1: Foundation (Week 1) - Target: 4-8x speedup
  "01_matrix_operations.R",           # Matrix stats
  "02_data_conversion.R",             # Praat ↔ R conversion
  "03_tone_generation.R",             # Sine wave synthesis
  
  # Phase 2: Signal Processing (Week 2) - Target: 3-5x speedup
  "06_phase2_intensity.R",            # RMS/energy calculations
  "07_phase2_sound_mixing.R",         # Sound mixing/scaling
  
  # Phase 3: DSP Operations (Week 3) - Target: 2.5-6x speedup  ⭐ NEW!
  "12_phase3_window_functions.R",     # Hamming, Hanning, Gaussian windows
  "13_phase3_autocorrelation.R",      # Autocorrelation (HIGHEST IMPACT!)
  "08_phase3_fft_operations.R",       # Spectrogram, FFT
  "09_phase3_formant_lpc.R",          # LPC autocorrelation
  "10_phase3_pitch_detection.R",      # Pitch autocorrelation
  
  # Phase 4: End-to-End (Week 4) - Target: 2-4x overall
  "11_end_to_end_pipelines.R",        # Complete workflows
  
  # Optional: Comparisons
  "04_parselmouth_comparison.R",      # Compare with Python Parselmouth
  "05_converted_scripts_comparison.R" # Praat script conversions
)

# Detect SIMD support
forced_mode <- Sys.getenv("SPEAKER_BENCHMARK_MODE", "")
if (forced_mode != "") {
  has_simd <- (forced_mode == "simd")
  run_mode <- forced_mode
  cat("⚠️  Mode forced to:", run_mode, "(via SPEAKER_BENCHMARK_MODE env var)\n")
} else {
  has_simd <- requireNamespace("RcppXsimd", quietly = TRUE)
  run_mode <- if (has_simd) "simd" else "scalar"
}

cat("SIMD support:", ifelse(has_simd, "✓ Available (RcppXsimd loaded)", "✗ Not available"), "\n")
cat("Run mode:", run_mode, "\n")

if (run_mode == "simd") {
  cat("\n💡 TIP: To generate scalar baseline for comparison:\n")
  cat("   Sys.setenv(SPEAKER_BENCHMARK_MODE='scalar'); source('inst/benchmarks/00_run_all_benchmarks.R')\n")
} else {
  cat("\n💡 TIP: To generate SIMD comparison:\n")
  cat("   install.packages('RcppXsimd') then re-run benchmarks\n")
  cat("   OR: Sys.setenv(SPEAKER_BENCHMARK_MODE='simd'); source('inst/benchmarks/00_run_all_benchmarks.R')\n")
}
cat("\n")

# Set environment variable for benchmarks to know the mode
Sys.setenv(SPEAKER_BENCHMARK_MODE = run_mode)

# Run each benchmark
for (benchmark_file in benchmarks) {
  cat("\n")
  cat(strrep("=", 80), "\n")
  cat("Running:", benchmark_file, "\n")
  cat(strrep("=", 80), "\n")

  benchmark_path <- file.path("inst/benchmarks", benchmark_file)

  if (file.exists(benchmark_path)) {
    tryCatch({
      # Source in inst/benchmarks directory for correct relative paths
      old_wd <- getwd()
      setwd("inst/benchmarks")
      source(benchmark_file, local = new.env())
      setwd(old_wd)
      cat("✓ Completed:", benchmark_file, "\n")
    }, error = function(e) {
      cat("✗ Error in", benchmark_file, ":", conditionMessage(e), "\n")
      # Restore directory in case of error
      if (exists("old_wd")) setwd(old_wd)
    })
  } else {
    cat("✗ File not found:", benchmark_path, "\n")
  }
}

# Save completion info
completion_info <- list(
  timestamp = Sys.time(),
  mode = run_mode,
  has_simd = has_simd,
  completed_benchmarks = benchmarks
)
saveRDS(completion_info, paste0("inst/benchmarks/results/00_completion_", run_mode, ".rds"))

# Create summary report
cat("\n")
cat(strrep("=", 80), "\n")
cat(toupper(run_mode), "BENCHMARKS COMPLETE\n")
cat(strrep("=", 80), "\n\n")

cat("Results saved in: inst/benchmarks/results/\n")
cat("Files created:\n")
result_files <- list.files("inst/benchmarks/results", pattern = "\\.rds$", full.names = FALSE)
for (f in result_files) {
  cat("  -", f, "\n")
}

cat("\n")
if (run_mode == "scalar") {
  cat("Next steps:\n")
  cat("1. Install RcppXsimd: install.packages('RcppXsimd')\n")
  cat("2. Re-run this script to generate SIMD benchmarks\n")
  cat("3. Compare results: Rscript inst/benchmarks/compare_results.R\n")
} else {
  cat("Next steps:\n")
  cat("1. Compare SIMD vs scalar: Rscript inst/benchmarks/compare_results.R\n")
  cat("2. Review Parselmouth comparison (if available)\n")
  cat("3. Identify optimization opportunities\n")
}

cat("\n", run_mode, " benchmark run completed successfully!\n")
cat("\n")

# Save completion marker
completion_info <- list(
  completed_at = Sys.time(),
  benchmarks_run = benchmarks,
  system_info = system_info
)
saveRDS(completion_info, "inst/benchmarks/results/00_completion_info.rds")

cat("Baseline benchmark run completed successfully!\n\n")
