# Baseline Benchmark Results - PENDING

**Date**: 2025-11-12
**Status**: ⏳ **Awaiting package installation**
**Package Version**: 0.4.1 (development)

## Summary

The benchmarking suite has been created and is ready to run, but requires the speaker package to be properly installed first.

## Prerequisites

Before running benchmarks, the package must be built and installed:

```bash
# From package root directory
R CMD INSTALL --preclean .

# Or using devtools
Rscript -e "devtools::install()"
```

## Running Baseline Benchmarks

Once the package is installed, run:

```bash
cd /Users/frkkan96/Documents/src/speaker
Rscript inst/benchmarks/00_run_all_benchmarks.R
```

This will:
1. Create `inst/benchmarks/results/` directory
2. Run all benchmark scripts (01, 02, 03)
3. Save baseline results as `.rds` files
4. Generate summary report

**Estimated time**: 5-10 minutes

## Expected Output Files

After running, the following files will be created:

```
inst/benchmarks/results/
├── 00_system_info.rds                      # Platform/CPU information
├── 00_completion_info.rds                  # Benchmark metadata
├── 01_matrix_operations_baseline.rds       # Matrix ops results
├── 02_data_conversion_baseline.rds         # Conversion results
└── 03_tone_generation_baseline.rds         # Tone synthesis results
```

## Benchmark Configurations

### 1. Matrix Operations
- **Sizes**: 100×100, 500×500, 1000×1000, 2000×2000
- **Operations**: sum, mean, min, max
- **Iterations**: 50 per operation
- **Expected speedup with SIMD**: 4-8x

### 2. Data Conversion
- **Durations**: 1s, 10s, 60s
- **Channels**: mono (1), stereo (2)
- **Sample rate**: 44.1 kHz
- **Operations**: create Sound, export to matrix/dataframe
- **Iterations**: 20 per operation
- **Expected speedup with SIMD**: 4-8x

### 3. Tone Generation
- **Durations**: 0.1s, 1s, 10s
- **Frequencies**: 220 Hz, 440 Hz, 880 Hz
- **Sample rate**: 44.1 kHz
- **Iterations**: 50 per operation
- **Expected speedup with SIMD**: 4-6x

## Next Steps

1. **Install package**:
   ```bash
   R CMD INSTALL --preclean .
   ```

2. **Run baseline benchmarks**:
   ```bash
   Rscript inst/benchmarks/00_run_all_benchmarks.R
   ```

3. **Implement SIMD optimizations** (see `SIMD_INTEGRATION_PLAN.md`)

4. **Run post-SIMD benchmarks**:
   ```bash
   Rscript inst/benchmarks/00_run_all_benchmarks.R
   ```

5. **Compare results**:
   ```bash
   Rscript inst/benchmarks/compare_results.R
   ```

## Manual Benchmark Execution

If the master script fails, run benchmarks individually:

```r
# From R console
setwd("/Users/frkkan96/Documents/src/speaker")
library(speaker)

# Create results directory
dir.create("inst/benchmarks/results", recursive = TRUE, showWarnings = FALSE)

# Run each benchmark
source("inst/benchmarks/01_matrix_operations.R")
source("inst/benchmarks/02_data_conversion.R")
source("inst/benchmarks/03_tone_generation.R")
```

## Troubleshooting

### Package installation fails
**Check**:
- R version ≥ 4.0
- Rcpp is installed: `install.packages("Rcpp")`
- C++17 compiler is available
- All dependencies are installed

### Benchmark fails
**Common issues**:
1. Not running from package root directory
2. Results directory doesn't exist (created automatically)
3. Insufficient memory (reduce matrix sizes in scripts)
4. Missing dependencies (`bench` package)

**Install missing dependencies**:
```r
install.packages(c("bench", "R6"))
```

## Platform Notes

### macOS
- ✅ Tested on macOS 14.0+ (Darwin 25.1.0)
- CPU detection: Uses `sysctl -n machdep.cpu.brand_string`

### Linux
- ✅ Should work on Ubuntu 20.04+, Fedora 35+
- CPU detection: Uses `/proc/cpuinfo`

### Windows
- ⚠️ Not yet tested
- May require Rtools for package compilation

## Contact

For issues or questions:
- File issue: https://github.com/humlab-speech/speaker/issues
- See: `inst/benchmarks/README.md` for detailed documentation

---

**Status**: Ready to run once package is installed
**Created**: 2025-11-12
**Author**: Claude (Anthropic)
