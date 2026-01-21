# pladdrr SIMD Benchmarks

Performance benchmarking suite for SIMD-accelerated operations in pladdrr.

## Overview

This directory contains benchmark scripts for validating SIMD performance improvements across different phases of implementation.

## Benchmark Scripts

### Phase 1 Integration Benchmarks

**File:** `phase1_integration_benchmark.R`

Comprehensive benchmarks for SIMD Phase 1 (Tasks 1.1-1.4):
- Task 1.1: Pitch extraction (autocorrelation SIMD)
- Task 1.2: Intensity calculation (windowed RMS SIMD)
- Task 1.3: Formant extraction (Burg's algorithm SIMD)
- Task 1.4: Spectrogram generation (window functions SIMD)

**Usage:**
```r
source("benchmarks/phase1_integration_benchmark.R")
```

**Expected Speedups:**
- Pitch (AC/CC): 1.5-2.5x
- Intensity: 1.5-2.0x
- Formant: 2.0-4.0x
- Spectrogram: 1.5-2.0x

**Output:**
- Console report with speedup metrics
- Saved RDS file: `phase1_benchmark_results_YYYYMMDD_HHMMSS.rds`

### Original SIMD Benchmark

**File:** `simd_benchmark.R`

Earlier SIMD benchmarking script.

## Running Benchmarks

### Prerequisites

```r
install.packages("microbenchmark")
library(pladdrr)
```

### Basic Usage

```r
# Run Phase 1 benchmarks
source("benchmarks/phase1_integration_benchmark.R")

# Load saved results
results <- readRDS("benchmarks/phase1_benchmark_results_<timestamp>.rds")
print(results$results_summary)
```

### Configuration

Edit benchmark parameters in the script:

```r
BENCHMARK_TIMES <- 50    # Number of iterations (default: 50)
TEST_DURATION <- 5.0     # Test audio duration in seconds (default: 5.0)
TEST_SAMPLE_RATE <- 44100  # Sample rate (default: 44100)
```

## Interpreting Results

### Speedup Calculation

```
Speedup = Scalar_Time / SIMD_Time
```

- **< 1.0x**: SIMD slower (regression)
- **1.0-1.3x**: Minimal improvement
- **1.3-2.0x**: Good improvement
- **> 2.0x**: Excellent improvement

### Status Indicators

- **✓**: Target speedup achieved
- **✗**: Target speedup not met

### Example Output

```
=======================================================================
Phase 1 Integration Summary
=======================================================================

Speedup Results:

  Operation          Scalar_ms  SIMD_ms  Speedup  Target     Status
  Pitch (AC)         245.32     98.45    2.49x    1.5-2.5x   ✓
  Pitch (CC)         312.67     145.23   2.15x    1.5-2.5x   ✓
  Intensity          89.12      52.34    1.70x    1.5-2.0x   ✓
  Formant            523.45     187.92   2.78x    2.0-4.0x   ✓
  Spectrogram        678.23     423.11   1.60x    1.5-2.0x   ✓

Overall average speedup: 2.14x
Target achievement: 5/5 operations meeting target
```

## Saved Results Format

Benchmark results are saved as RDS files containing:

```r
list(
  timestamp = Sys.time(),
  system_info = simd_info(),
  r_version = R.version.string,
  package_version = "4.4.4",
  results_summary = data.frame(...),  # Summary table
  detailed_results = list(            # Full microbenchmark objects
    pitch_ac = list(scalar = ..., simd = ...),
    pitch_cc = list(scalar = ..., simd = ...),
    intensity = list(scalar = ..., simd = ...),
    formant = list(scalar = ..., simd = ...),
    spectrogram = list(scalar = ..., simd = ...)
  )
)
```

## System Information

Check SIMD support before running benchmarks:

```r
simd_info()
# $enabled
# [1] TRUE
#
# $architecture
# [1] "NEON"  # or "AVX2", "SSE4.2", etc.
#
# $batch_size_double
# [1] 2  # or 4 for AVX2
```

## Troubleshooting

### SIMD Not Available

If benchmarks show no speedup, check:

```r
# Check SIMD status
simd_info()$enabled  # Should be TRUE

# Check build flags
system("R CMD config CXXFLAGS")  # Should include -DHAVE_XSIMD
```

### Inconsistent Results

For stable benchmarks:
- Close other applications
- Run multiple times and average
- Use longer test audio (10+ seconds)
- Increase `BENCHMARK_TIMES` to 100+

### Memory Issues

If benchmarks crash:
- Reduce `TEST_DURATION` to 2-3 seconds
- Reduce `BENCHMARK_TIMES` to 20-30
- Run `gc()` between tests

## Platform-Specific Notes

### macOS (Apple Silicon)
- Uses ARM NEON SIMD
- Typical batch size: 2 doubles
- Expected speedups: 1.5-2.5x

### macOS/Linux (Intel x86_64)
- Uses AVX2 or SSE4.2
- Typical batch size: 4 doubles (AVX2), 2 doubles (SSE4.2)
- Expected speedups: 2.0-4.0x (AVX2), 1.5-2.5x (SSE4.2)

### Windows
- Uses AVX2 or SSE4.2
- Performance may vary by compiler (MSVC vs Rtools)

## Contributing

When adding new benchmarks:
1. Follow the naming pattern: `phase<N>_<description>_benchmark.R`
2. Include configuration section at top
3. Generate both console output and saved RDS
4. Update this README with new benchmarks

## References

- SIMD Implementation Plan: `../SIMD_IMPLEMENTATION_PLAN.md`
- Progress Tracker: `../SIMD_PROGRESS_TRACKER.md`
- Test Suite: `../tests/testthat/test-simd-integration.R`

---

**Last Updated:** 2026-01-21
**pladdrr Version:** 4.4.4
**Phase:** 1 (Integration)
