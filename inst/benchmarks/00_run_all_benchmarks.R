# Master Benchmark Runner
# Runs all SIMD baseline benchmarks and saves results
# Run this BEFORE implementing SIMD optimizations

library(speaker)

cat("\n")
cat("="*80, "\n")
cat("SPEAKER PACKAGE - SIMD BASELINE BENCHMARKS\n")
cat("="*80, "\n")
cat("Date:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat("Package version:", as.character(packageVersion("speaker")), "\n")
cat("R version:", R.version.string, "\n")
cat("Platform:", R.version$platform, "\n")
cat("="*80, "\n\n")

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
    system("sysctl -n machdep.cpu.brand_string", intern = TRUE)
  } else {
    "Windows"
  }
)

saveRDS(system_info, "inst/benchmarks/results/00_system_info.rds")

# List of benchmark scripts
benchmarks <- c(
  "01_matrix_operations.R",
  "02_data_conversion.R",
  "03_tone_generation.R",
  "04_parselmouth_comparison.R",
  "05_converted_scripts_comparison.R"
)

# Run each benchmark
for (benchmark_file in benchmarks) {
  cat("\n")
  cat("="*80, "\n")
  cat("Running:", benchmark_file, "\n")
  cat("="*80, "\n")

  benchmark_path <- file.path("inst/benchmarks", benchmark_file)

  if (file.exists(benchmark_path)) {
    tryCatch({
      source(benchmark_path, local = new.env())
      cat("✓ Completed:", benchmark_file, "\n")
    }, error = function(e) {
      cat("✗ Error in", benchmark_file, ":", conditionMessage(e), "\n")
    })
  } else {
    cat("✗ File not found:", benchmark_path, "\n")
  }
}

# Create summary report
cat("\n")
cat("="*80, "\n")
cat("BASELINE BENCHMARKS COMPLETE\n")
cat("="*80, "\n\n")

cat("Results saved in: inst/benchmarks/results/\n")
cat("Files created:\n")
result_files <- list.files("inst/benchmarks/results", pattern = "\\.rds$", full.names = FALSE)
for (f in result_files) {
  cat("  -", f, "\n")
}

cat("\n")
cat("Next steps:\n")
cat("1. Review Parselmouth comparison: source('inst/benchmarks/compare_results.R')\n")
cat("2. Consider SIMD optimizations using RcppXsimd (see SIMD_INTEGRATION_PLAN.md)\n")
cat("3. Implement any performance improvements identified\n")
cat("\n")

# Save completion marker
completion_info <- list(
  completed_at = Sys.time(),
  benchmarks_run = benchmarks,
  system_info = system_info
)
saveRDS(completion_info, "inst/benchmarks/results/00_completion_info.rds")

cat("Baseline benchmark run completed successfully!\n\n")
