# SIMD Benchmarking Suite for speaker Package

This directory contains a comprehensive benchmarking suite for measuring the performance impact of SIMD optimizations using RcppXsimd.

## Overview

The benchmarking suite is designed to:
1. Establish **baseline performance** metrics before SIMD implementation
2. Measure **SIMD-optimized performance** after implementation
3. Calculate **speedup ratios** and validate optimization impact
4. Track performance across **different platforms** and CPU architectures

## Directory Structure

```
inst/benchmarks/
├── README.md                           # This file
├── 00_run_all_benchmarks.R            # Master script (run this!)
├── 01_matrix_operations.R             # Matrix sum, mean, min, max
├── 02_data_conversion.R               # Praat <-> R conversions
├── 03_tone_generation.R               # Sine wave synthesis
├── results/                           # Benchmark results (created automatically)
│   ├── 00_system_info.rds            # System/platform information
│   ├── 01_matrix_operations_baseline.rds
│   ├── 02_data_conversion_baseline.rds
│   ├── 03_tone_generation_baseline.rds
│   └── ...                           # Additional results after SIMD
└── compare_results.R                  # Compare baseline vs SIMD (TODO)
```

## Quick Start

### Step 1: Run Baseline Benchmarks (Pre-SIMD)

**Run this BEFORE implementing SIMD optimizations:**

```r
# From package root directory
source("inst/benchmarks/00_run_all_benchmarks.R")
```

This will:
- Run all benchmark scripts
- Save results to `inst/benchmarks/results/*.rds`
- Record system information
- Print summary statistics

**Time required**: ~5-10 minutes depending on system

---

### Step 2: Implement SIMD Optimizations

Follow the implementation plan in:
- `SIMD_OPTIMIZATION_REPORT.md`
- `SIMD_INTEGRATION_PLAN.md`

---

### Step 3: Run Post-SIMD Benchmarks

After implementing SIMD optimizations:

```r
# Run benchmarks again (results saved with _simd suffix)
source("inst/benchmarks/00_run_all_benchmarks.R")
```

---

### Step 4: Compare Results

```r
# Generate comparison report
source("inst/benchmarks/compare_results.R")
```

This will calculate speedup ratios and generate visualizations.

---

## Individual Benchmarks

### 1. Matrix Operations (`01_matrix_operations.R`)

**Tests**: `get_sum()`, `get_mean()`, `get_minimum()`, `get_maximum()`

**Configurations**:
- Small: 100×100 matrix
- Medium: 500×500 matrix
- Large: 1000×1000 matrix
- X-Large: 2000×2000 matrix

**Expected SIMD speedup**: 4-8x

**Run individually**:
```r
source("inst/benchmarks/01_matrix_operations.R")
```

---

### 2. Data Conversion (`02_data_conversion.R`)

**Tests**: Sound creation from matrix, Sound export to matrix/data.frame

**Configurations**:
- Mono 1s, Stereo 1s (short audio)
- Mono 10s, Stereo 10s (medium audio)
- Mono 60s (long audio)

**Expected SIMD speedup**: 4-8x

**Run individually**:
```r
source("inst/benchmarks/02_data_conversion.R")
```

---

### 3. Tone Generation (`03_tone_generation.R`)

**Tests**: Sine wave synthesis (vectorized sin function)

**Configurations**:
- Short (0.1s), Medium (1s), Long (10s)
- Different frequencies (220 Hz, 440 Hz, 880 Hz)

**Expected SIMD speedup**: 4-6x

**Run individually**:
```r
source("inst/benchmarks/03_tone_generation.R")
```

---

## Benchmark Results Format

Results are saved as RDS files containing:

```r
# Matrix operations
list(
  small = <bench::mark object>,
  medium = <bench::mark object>,
  large = <bench::mark object>,
  xlarge = <bench::mark object>
)

# Data conversion
list(
  mono_1s = list(
    create = <bench::mark object>,
    export = <bench::mark object>,
    config = list(duration, channels, rate),
    n_samples = <integer>
  ),
  ...
)
```

Each `bench::mark` object contains:
- `expression`: Function/operation being benchmarked
- `min`: Minimum execution time
- `median`: Median execution time (most reliable metric)
- `max`: Maximum execution time
- `mem_alloc`: Memory allocated
- `n_itr`: Number of iterations
- `n_gc`: Number of garbage collections

---

## System Requirements

### R Packages
```r
install.packages("bench")  # Accurate microbenchmarking
install.packages("speaker") # Must be installed
```

### Platform Support
- ✅ macOS (Intel x86-64)
- ✅ macOS (Apple Silicon ARM64)
- ✅ Linux (x86-64, AMD64)
- ✅ Windows (x86-64)

---

## Interpreting Results

### Median Time
Use **median** time as the primary metric (more stable than mean):
```r
results$small$median
```

### Speedup Calculation
```r
speedup <- baseline_median / simd_median
```

**Example**:
- Baseline: 2.5 ms
- SIMD: 0.4 ms
- Speedup: 2.5 / 0.4 = **6.25x**

### Expected Speedups

| Operation | Conservative | Realistic | Optimistic |
|-----------|-------------|-----------|------------|
| Matrix ops | 3x | 4-6x | 8x |
| Data conversion | 3x | 4-6x | 8x |
| Tone generation | 3x | 4-5x | 6x |
| Intensity (RMS) | 2x | 3-4x | 5x |

---

## Troubleshooting

### Benchmark fails with "function not found"
**Solution**: Make sure the speaker package is installed and loaded:
```r
install.packages("speaker", repos = NULL, type = "source")
library(speaker)
```

### Results directory not created
**Solution**: Run from package root directory or create manually:
```r
dir.create("inst/benchmarks/results", recursive = TRUE)
```

### Benchmarks are very slow
**Normal**: Large matrices (2000×2000) can take time.
**If excessively slow**: Reduce iterations in individual scripts.

### Memory errors on large benchmarks
**Solution**: Skip the x-large configurations or increase R memory limit:
```r
# Linux/macOS
ulimit -v unlimited

# Windows
memory.limit(size = 16000)  # 16 GB
```

---

## Platform-Specific Notes

### macOS (Intel)
- SIMD: SSE2, AVX, AVX2 (depends on CPU generation)
- Expected speedup: 4-8x with AVX2

### macOS (Apple Silicon)
- SIMD: NEON (ARM instruction set)
- Expected speedup: 3-6x with NEON

### Linux (Intel/AMD)
- SIMD: SSE2, AVX, AVX2, AVX512 (depends on CPU)
- Expected speedup: 4-8x with AVX2, up to 16x with AVX512

### Windows (Intel)
- SIMD: SSE2, AVX, AVX2 (depends on CPU)
- Expected speedup: 4-8x with AVX2

---

## Benchmark Design Principles

1. **Use bench::mark()**: More accurate than `system.time()` or `microbenchmark`
2. **Sufficient iterations**: 20-50 iterations to get stable median
3. **Warm-up**: bench::mark() handles this automatically
4. **Disable checking**: Use `check = FALSE` for pure performance measurement
5. **Realistic workloads**: Test sizes mirror real phonetic analysis tasks

---

## Contributing

To add a new benchmark:

1. Create `0X_benchmark_name.R` following the existing template
2. Save results to `inst/benchmarks/results/0X_benchmark_name_baseline.rds`
3. Add to `00_run_all_benchmarks.R`
4. Update this README

**Template**:
```r
# Benchmark X: Description
# Tests: What operations are tested
# Expected SIMD speedup: Nx

library(speaker)
library(bench)

cat("Benchmark X: ...\n\n")

# Your benchmark code here

results <- list(...)

saveRDS(results, "inst/benchmarks/results/0X_name_baseline.rds")
```

---

## References

- **SIMD Analysis**: See `SIMD_OPTIMIZATION_REPORT.md`
- **Integration Plan**: See `SIMD_INTEGRATION_PLAN.md`
- **RcppXsimd**: https://github.com/OHDSI/RcppXsimd
- **bench package**: https://bench.r-lib.org/

---

## Contact

For questions or issues:
- File issue: https://github.com/humlab-speech/speaker/issues
- See package documentation: `?speaker`

---

**Last Updated**: 2025-11-12
**Package Version**: 0.4.1 (baseline)
**Status**: Ready to run baseline benchmarks
