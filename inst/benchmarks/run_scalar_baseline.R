# Run Benchmarks in Scalar Mode (Without SIMD)
# This script runs benchmarks with SIMD disabled for baseline comparison

cat("\n")
cat(strrep("=", 80), "\n")
cat("RUNNING BENCHMARKS IN SCALAR MODE (NO SIMD)\n")
cat(strrep("=", 80), "\n\n")

# Force scalar mode by setting environment variable
Sys.setenv(SPEAKER_BENCHMARK_MODE = "scalar")
Sys.setenv(RETICULATE_PYTHON = "/opt/miniconda3/bin/python3")
cat("SIMD optimization: DISABLED\n")
cat("This run will establish the scalar baseline for comparison.\n\n")

# Source the main benchmark runner
source("inst/benchmarks/00_run_all_benchmarks.R", chdir = FALSE)

cat("\n")
cat(strrep("=", 80), "\n")
cat("SCALAR BASELINE COMPLETE\n")
cat(strrep("=", 80), "\n\n")
cat(
  "Next step: Run inst/benchmarks/run_simd_optimized.R",
  "to generate SIMD results\n"
)
cat("Then compare: Rscript inst/benchmarks/compare_results.R\n\n")
