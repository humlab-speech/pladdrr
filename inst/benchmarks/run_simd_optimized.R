# Run Benchmarks with SIMD Optimizations
# Requires: RcppXsimd package installed

if (!requireNamespace("RcppXsimd", quietly = TRUE)) {
  stop("RcppXsimd package not installed. Install with: install.packages('RcppXsimd')")
}

cat("\n")
cat(strrep("=", 80), "\n")
cat("RUNNING BENCHMARKS WITH SIMD OPTIMIZATIONS\n")
cat(strrep("=", 80), "\n\n")

cat("SIMD optimization: ENABLED (RcppXsimd loaded)\n")
cat("This run will test performance with SIMD vectorization.\n\n")

# Source the main benchmark runner (will auto-detect SIMD)
source("inst/benchmarks/00_run_all_benchmarks.R", chdir = FALSE)

cat("\n")
cat(strrep("=", 80), "\n")
cat("SIMD BENCHMARKS COMPLETE\n")
cat(strrep("=", 80), "\n\n")
cat("Compare results: Rscript inst/benchmarks/compare_results.R\n\n")
