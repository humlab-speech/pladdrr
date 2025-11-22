# Benchmarking Suite for speaker Package

This directory contains a comprehensive benchmarking suite for measuring the performance of the speaker package compared to Parselmouth and for evaluating potential SIMD optimizations.

## Overview

The benchmarking suite is designed to:
1. **Compare speaker vs Parselmouth** for common phonetic analysis operations
2. **Compare full workflow performance** for converted Praat scripts
3. Establish **baseline performance** metrics for potential SIMD optimization
4. Track performance across **different platforms** and CPU architectures

## Directory Structure

```
inst/benchmarks/
├── README.md                           # This file
├── 00_run_all_benchmarks.R            # Master script (run this!)
├── 01_matrix_operations.R             # Matrix sum, mean, min, max (SIMD baseline)
├── 02_data_conversion.R               # Praat <-> R conversions (SIMD baseline)
├── 03_tone_generation.R               # Sine wave synthesis (SIMD baseline)
├── 04_parselmouth_comparison.R        # speaker vs parselmouth operations
├── 05_converted_scripts_comparison.R  # speaker vs parselmouth workflows
├── compare_results.R                  # Generate comparison report
├── results/                           # Benchmark results (created automatically)
│   ├── 00_system_info.rds            # System/platform information
│   ├── 00_completion_info.rds        # Benchmark metadata
│   ├── 01_matrix_operations_baseline.rds
│   ├── 02_data_conversion_baseline.rds
│   ├── 03_tone_generation_baseline.rds
│   ├── 04_parselmouth_comparison.rds
│   ├── 05_converted_scripts_comparison.rds
│   ├── parselmouth_comparison.png
│   ├── converted_scripts_comparison.png
│   └── combined_comparison.png
└── BASELINE_RESULTS_PENDING.md        # Instructions
```

## Quick Start

### Step 1: Install Package

**Ensure the speaker package is built and installed:**

```bash
# From package root directory
R CMD INSTALL --preclean .
```

### Step 2: Run Benchmarks

**Run all benchmarks including Parselmouth comparison:**

```r
# From package root directory
source("inst/benchmarks/00_run_all_benchmarks.R")
```

This will:
- Run all benchmark scripts (01-05)
- Save results to `inst/benchmarks/results/*.rds`
- Record system information
- Print summary statistics

**Time required**: ~15-20 minutes (longer with Python/Parselmouth)

**Note**: Benchmarks 04 and 05 require Python with parselmouth installed. If not available, they will be skipped.

---

### Step 3: Generate Comparison Report

After running benchmarks:

```r
# Generate visualizations and comparison report
source("inst/benchmarks/compare_results.R")
```

This will create:
- `parselmouth_comparison.png` - Individual operations comparison
- `converted_scripts_comparison.png` - Full workflow comparison
- `combined_comparison.png` - Combined overview

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

### 4. Parselmouth Comparison (`04_parselmouth_comparison.R`)

**Tests**: Direct comparison of speaker vs parselmouth for common operations

**Operations**:
- Pitch extraction (autocorrelation)
- Formant tracking (Burg method)
- Intensity calculation
- Spectrogram generation
- Harmonicity (HNR)

**Expected speaker advantage**: 1.5-3x (direct C++ binding vs Python overhead)

**Requirements**: Python 3.x with parselmouth installed

**Run individually**:
```r
source("inst/benchmarks/04_parselmouth_comparison.R")
```

---

### 5. Converted Scripts Comparison (`05_converted_scripts_comparison.R`)

**Tests**: Full workflow comparisons for converted superassp scripts

**Workflows**:
- Voice quality analysis (jitter, shimmer, HNR)
- Formant tracking with statistics
- Spectral analysis (CoG, spectral moments)
- PSOLA pitch manipulation

**Expected speaker advantage**: 1.5-3x for complete workflows

**Requirements**: Python 3.x with parselmouth installed

**Run individually**:
```r
source("inst/benchmarks/05_converted_scripts_comparison.R")
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
install.packages("bench")      # Accurate microbenchmarking
install.packages("ggplot2")    # For visualization
install.packages("reticulate") # For Python integration (optional)
install.packages("speaker")    # Must be installed
```

### Python (Optional, for Parselmouth Comparison)
```bash
pip install praat-parselmouth
```

**Note**: Benchmarks 04 and 05 require Python with parselmouth. If not available, they will be automatically skipped.

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
