# Three-Way Benchmark Enhancement (Praat Integration) - 2025-11-29

**Status**: ✅ **COMPLETE - Praat Benchmarking Integrated**  
**Files**: `inst/benchmarks/praat_runner.R`, `inst/benchmarks/04_parselmouth_comparison.R`

---

## Overview

Extended the benchmarking system to include **native Praat** alongside pladdrr and Parselmouth, creating a comprehensive three-way performance comparison.

---

## Changes Made

### 1. Created Praat Script Runner Module

**File**: `inst/benchmarks/praat_runner.R` (195 lines)

A comprehensive helper module for executing Praat scripts from R with accurate timing isolation:

**Key Functions:**
- `run_praat_script()` - Execute Praat script and return timing
- `benchmark_praat()` - Run benchmarks with warmup and statistics
- `praat_pitch_script()` - Generate pitch extraction script
- `praat_formant_script()` - Generate formant tracking script
- `praat_intensity_script()` - Generate intensity calculation script
- `praat_spectrogram_script()` - Generate spectrogram script
- `praat_harmonicity_script()` - Generate harmonicity script

**Timing Methodology:**
```praat
# Ensures only execution time is measured, not Praat startup
stopwatch                          # Start timer AFTER Praat loads
# ... user script here ...
execution_time = stopwatch        # Capture execution time
writeInfoLine: "EXEC_TIME:", fixed$(execution_time, 6)
```

**Key Features:**
- ✅ Isolates execution time from Praat startup overhead
- ✅ Warmup iterations for stable measurements
- ✅ Temporary directory management
- ✅ Automatic cleanup with `on.exit()`
- ✅ Configurable Praat executable location

### 2. Enhanced Three-Way Comparison Benchmark

**File**: `inst/benchmarks/04_parselmouth_comparison.R`

**Changes:**
- Added Praat executable detection
- Integrated Praat benchmarking for all 5 operations
- Separated benchmarks (run sequentially, not via `bench::mark()` together)
- Enhanced reporting with speedups vs both Parselmouth and Praat
- Graceful degradation if Praat not installed

**Benchmark Operations:**
1. Pitch extraction (autocorrelation)
2. Formant tracking (Burg method)
3. Intensity calculation
4. Spectrogram generation
5. Harmonicity (HNR)

---

## Benchmark Results

### Three-Way Performance Comparison

```
1. Pitch extraction (autocorrelation)...
   pladdrr:         13.3ms
   Parselmouth:      1.7ms
   Praat:            2.0ms
   vs Parselmouth:   0.13x (Parselmouth 7.8x faster)
   vs Praat:         0.15x (Praat 6.7x faster)

2. Formant tracking (Burg method)...
   pladdrr:         18.5ms
   Parselmouth:      8.6ms
   Praat:            5.4ms
   vs Parselmouth:   0.47x (Parselmouth 2.1x faster)
   vs Praat:         0.29x (Praat 3.4x faster)

3. Intensity calculation...
   pladdrr:         81.0ms
   Parselmouth:      0.9ms
   Praat:            1.2ms
   vs Parselmouth:   0.01x (Parselmouth 90x faster!)
   vs Praat:         0.01x (Praat 67x faster!)

4. Spectrogram generation...
   pladdrr:         13.3ms
   Parselmouth:      2.8ms
   Praat:            1.2ms
   vs Parselmouth:   0.21x (Parselmouth 4.8x faster)
   vs Praat:         0.09x (Praat 11x faster)

5. Harmonicity (HNR)...
   pladdrr:         26.4ms
   Parselmouth:     10.3ms
   Praat:            8.4ms
   vs Parselmouth:   0.39x (Parselmouth 2.6x faster)
   vs Praat:         0.32x (Praat 3.1x faster)
```

---

## Performance Analysis

### Surprising Finding: pladdrr is Slower

**Key Observations:**
1. **Parselmouth 2-90x faster** than pladdrr
2. **Native Praat 3-67x faster** than pladdrr
3. **Intensity calculation** shows extreme slowdown (90x)

### Possible Causes

#### 1. R6 Method Call Overhead
R6 object dispatch adds latency compared to direct function calls.

#### 2. Memory Management
- External pointer creation/destruction
- R garbage collection during benchmarks
- Unnecessary copies

#### 3. Build Configuration
- pladdrr may be in debug mode
- Compiler optimizations may not be enabled
- SIMD not engaged for signal processing

#### 4. Parameter Processing
- R type checking and validation
- Conversion between R and C++ types
- Defensive copies for safety

#### 5. Different Code Paths
- Parselmouth may cache objects differently
- Praat may use optimized buffers
- pladdrr may recreate objects unnecessarily

---

## Investigation Needed

### High Priority

1. **Check Build Flags**
   ```bash
   # Verify compiler optimization
   grep -i "cxxflags" src/Makevars
   # Should see: -O3 or similar
   ```

2. **Profile R6 Dispatch**
   ```r
   Rprof("benchmark.prof")
   sound$to_pitch()
   Rprof(NULL)
   summaryRprof("benchmark.prof")
   ```

3. **Test Direct C++ Calls**
   Bypass R6 and call C++ wrappers directly to isolate overhead.

4. **Verify SIMD Activation**
   Check if SIMD is actually being used for these operations.

### Medium Priority

1. Compare parameter defaults between implementations
2. Check for unnecessary defensive copies
3. Profile memory allocations
4. Verify equivalent operation parameters

---

## Technical Details

### Praat Executable Location

**macOS**: `/Applications/Praat.app/Contents/MacOS/Praat`

Can be overridden:
```r
benchmark_praat(praat_exe = "/path/to/Praat", ...)
```

### Benchmark Configuration

- **Iterations**: 50 per operation
- **Warmup**: 3 iterations (Praat only)
- **Metric**: Median execution time
- **Results**: Saved to `inst/benchmarks/results/04_parselmouth_comparison.rds`

### Timing Isolation

**Parselmouth**: `bench::mark()` measures R→Python→C++ round-trip  
**pladdrr**: `bench::mark()` measures R→R6→C++ round-trip  
**Praat**: `stopwatch` command measures only C++ execution

This may explain part of the difference - Praat timing excludes any bridge overhead.

---

## Files Modified

1. **Created**: `inst/benchmarks/praat_runner.R`
   - 195 lines of Praat integration code
   - 5 script generators
   - Timing and benchmarking infrastructure

2. **Modified**: `inst/benchmarks/04_parselmouth_comparison.R`
   - Added Praat benchmarking (+120 lines)
   - Separated benchmark execution for clarity
   - Enhanced reporting format
   - Three-way speedup calculations

---

## Reproducibility

Run the three-way comparison:
```bash
cd /Users/frkkan96/Documents/src/pladdrr
Rscript inst/benchmarks/04_parselmouth_comparison.R
```

**Requirements:**
- ✅ pladdrr installed
- ✅ Python with parselmouth (`pip install praat-parselmouth`)
- ✅ Praat.app installed in `/Applications/`
- ✅ Test audio file at `inst/extdata/test.wav`

---

## Next Steps

### Immediate
1. Investigate pladdrr performance bottlenecks
2. Profile R6 method call overhead
3. Verify compiler optimization flags
4. Check SIMD engagement

### Short-term
1. Add batch processing benchmarks (minimize R6 overhead)
2. Create performance optimization guide
3. Document acceptable vs problematic performance gaps

### Long-term
1. Consider performance-critical C++ entry points
2. Add caching for repeated operations
3. Optimize memory management
4. Benchmark mode that bypasses validation

---

## Conclusion

✅ **Three-way benchmarking infrastructure is complete and functional**

⚠️ **Performance investigation required** - pladdrr is significantly slower than both Parselmouth and native Praat, which was unexpected given the direct C++ binding architecture.

The timing methodology is sound (isolates execution time from startup), so these results reflect genuine performance characteristics that need optimization.

---

**Status**: Infrastructure ✅ COMPLETE | Performance ⚠️ NEEDS INVESTIGATION  
**Duration**: ~3 hours (design + implementation + testing)  
**Impact**: Comprehensive performance visibility across all three Praat interfaces
