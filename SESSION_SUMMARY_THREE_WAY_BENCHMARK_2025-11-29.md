# Session Summary: Three-Way Benchmarking Implementation
**Date**: 2025-11-29  
**Package Version**: 1.0.7  
**Status**: ✅ COMPLETE

---

## Overview

Extended the pladdrr benchmarking system to include **native Praat** desktop application alongside existing pladdrr and Parselmouth comparisons, creating a comprehensive three-way performance analysis.

---

## Objectives Completed

✅ Analyze superassp's Praat integration approach  
✅ Create Praat script execution framework with timing isolation  
✅ Implement script generators for 5 core operations  
✅ Extend benchmark 04 to three-way comparison  
✅ Ensure execution-time-only measurement (exclude startup)  
✅ Document methodology and results  
✅ Commit changes as version 1.0.7

---

## Key Deliverables

### 1. Praat Runner Module
**File**: `inst/benchmarks/praat_runner.R` (195 lines)

**Core Functions**:
- `run_praat_script()` - Execute Praat script with timing
- `benchmark_praat()` - Run benchmarks with warmup
- `praat_pitch_script()` - Pitch extraction script generator
- `praat_formant_script()` - Formant tracking script generator
- `praat_intensity_script()` - Intensity calculation script generator
- `praat_spectrogram_script()` - Spectrogram script generator
- `praat_harmonicity_script()` - Harmonicity (HNR) script generator

**Key Innovation - Timing Isolation**:
```praat
stopwatch                          # Start AFTER Praat loads
# ... user script ...
execution_time = stopwatch        # Capture execution only
writeInfoLine: "EXEC_TIME:", fixed$(execution_time, 6)
```

This ensures fair comparison by measuring only script execution, not Praat startup overhead.

### 2. Enhanced Benchmark 04
**File**: `inst/benchmarks/04_parselmouth_comparison.R`

**Changes**:
- Added Praat executable detection
- Integrated Praat benchmarking for all 5 operations
- Separated benchmark execution (sequential, not parallel via `bench::mark()`)
- Enhanced reporting with speedups vs both competitors
- Graceful degradation if Praat not installed

**Operations Benchmarked**:
1. Pitch extraction (autocorrelation)
2. Formant tracking (Burg method)
3. Intensity calculation
4. Spectrogram generation
5. Harmonicity (HNR)

### 3. Documentation
**File**: `THREE_WAY_BENCHMARK_PRAAT_2025-11-29.md`

Complete analysis including:
- Methodology explanation
- Benchmark results
- Performance analysis
- Investigation plan
- Technical details

---

## Benchmark Results

### Three-Way Performance Comparison

| Operation   | pladdrr | Parselmouth | Praat | vs PM   | vs Praat |
|-------------|---------|-------------|-------|---------|----------|
| Pitch       | 13.3ms  | 1.7ms       | 2.0ms | 0.13x ❌ | 0.15x ❌  |
| Formant     | 18.5ms  | 8.6ms       | 5.4ms | 0.47x ❌ | 0.29x ❌  |
| Intensity   | 81.0ms  | 0.9ms       | 1.2ms | 0.01x ❌ | 0.01x ❌  |
| Spectrogram | 13.3ms  | 2.8ms       | 1.2ms | 0.21x ❌ | 0.09x ❌  |
| Harmonicity | 26.4ms  | 10.3ms      | 8.4ms | 0.39x ❌ | 0.32x ❌  |

**Summary**:
- Parselmouth is 2-90x faster than pladdrr
- Native Praat is 3-67x faster than pladdrr
- Intensity calculation shows extreme slowdown (67-90x)

---

## Performance Analysis

### Unexpected Finding
pladdrr is significantly **slower** than both competitors. This was not expected given the direct C++ binding architecture.

### Hypothesized Causes

#### 1. R6 Method Call Overhead (Most Likely)
```r
# pladdrr: R6 dispatch overhead
sound$to_pitch()  # R → R6 → C++ wrapper → Praat C++

# Parselmouth: Direct Python→C++
pm.praat.call(sound, "To Pitch")

# Praat: Direct C++
Sound_to_Pitch()
```

#### 2. Build Configuration
- pladdrr may be in debug mode
- Compiler optimizations may not be fully enabled
- SIMD may not be engaged for these operations

#### 3. Memory Management
- External pointer creation/destruction overhead
- R garbage collection during benchmarks
- Unnecessary defensive copies

#### 4. Parameter Processing
- R type checking and validation
- Conversion between R and C++ types
- Default parameter expansion

#### 5. Different Execution Paths
- Parselmouth may cache intermediate objects
- Praat may use optimized buffers
- pladdrr may recreate objects unnecessarily

---

## Investigation Plan

### High Priority (Next Session)

1. **Check Compiler Flags**
   ```bash
   grep "CXXFLAGS" src/Makevars
   # Should see -O3 or similar
   ```

2. **Profile R6 Dispatch**
   ```r
   Rprof("benchmark.prof")
   sound$to_pitch()
   Rprof(NULL)
   summaryRprof("benchmark.prof")
   ```

3. **Test Direct C++ Calls**
   Bypass R6 and call C++ wrappers directly to quantify overhead.

4. **Verify SIMD Engagement**
   Check if SIMD is actually being used for signal processing.

### Medium Priority

1. Compare exact parameter defaults across implementations
2. Check for unnecessary defensive copies in wrappers
3. Profile memory allocations
4. Verify equivalent operation configurations

### Long-term Optimizations

1. Add performance mode that bypasses R6 for batch operations
2. Optimize R6 method dispatch for hot paths
3. Implement caching for repeated operations
4. Consider C++ batch entry points

---

## Technical Notes

### Timing Methodology

**Parselmouth**: `bench::mark()` → measures R→Python→C++ round-trip  
**pladdrr**: `bench::mark()` → measures R→R6→C++ round-trip  
**Praat**: `stopwatch` → measures only C++ execution

The different measurement approaches may explain **some** of the gap, but not the 90x difference observed for intensity calculation.

### Praat Executable

**Location**: `/Applications/Praat.app/Contents/MacOS/Praat`  
**Can be overridden** in all `praat_runner.R` functions

### Benchmark Configuration

- **Iterations**: 50 per operation
- **Warmup**: 3 iterations (Praat only)
- **Metric**: Median execution time
- **Results**: `inst/benchmarks/results/04_parselmouth_comparison.rds`

---

## Files Modified

1. **Created**: `inst/benchmarks/praat_runner.R` (+195 lines)
2. **Modified**: `inst/benchmarks/04_parselmouth_comparison.R` (+120 lines, restructured)
3. **Created**: `THREE_WAY_BENCHMARK_PRAAT_2025-11-29.md` (documentation)
4. **Modified**: `DESCRIPTION` (version 1.0.7)
5. **Modified**: `NEWS.md` (changelog entry)

---

## Git Status

**Branch**: `001-praat-r-access`  
**Commit**: `dce9b37`  
**Message**: "v1.0.7: Add three-way benchmarking (pladdrr vs Parselmouth vs Praat)"

**Ahead of origin**: 15 commits (local development)

---

## Reproducibility

Run the three-way benchmark:
```bash
cd /Users/frkkan96/Documents/src/pladdrr
Rscript inst/benchmarks/04_parselmouth_comparison.R
```

**Requirements**:
- ✅ pladdrr installed (version 1.0.7)
- ✅ Python with parselmouth: `pip install praat-parselmouth`
- ✅ Praat.app installed: `/Applications/Praat.app/`
- ✅ Test audio: `inst/extdata/test.wav`

**Duration**: ~5 minutes (5 operations × 50 iterations × 3 implementations)

---

## Next Steps Recommended

### Immediate (Performance Investigation)
1. Profile pladdrr to identify bottlenecks
2. Check compiler optimization flags
3. Measure pure C++ function calls (bypass R6)
4. Verify SIMD is engaged

### Short-term (Optimization)
1. Add batch processing benchmarks
2. Implement performance mode
3. Optimize R6 dispatch for hot paths
4. Document acceptable performance tradeoffs

### Long-term (Architecture)
1. Consider performance-critical C++ entry points
2. Add result caching for repeated operations
3. Optimize memory management
4. Create performance tuning guide

---

## Lessons Learned

1. **Direct C++ ≠ Fast in R** - R6 overhead and R bridges add latency
2. **Measurement matters** - Different tools measure at different layers
3. **Intensity is problematic** - 90x slowdown needs immediate investigation
4. **Praat is highly optimized** - Desktop app is extremely efficient
5. **Parselmouth well-tuned** - Python→C++ bridge is optimized

---

## Success Criteria Met

✅ Three-way benchmarking infrastructure complete  
✅ Accurate timing methodology (excludes startup)  
✅ Comprehensive reporting  
✅ Graceful degradation  
✅ Documentation complete  
✅ Version 1.0.7 committed

⚠️ **Performance investigation required** - unexpected slowdown vs competitors

---

## Conclusion

The three-way benchmarking system is **fully functional** and provides comprehensive performance visibility. However, it revealed **significant performance gaps** that require investigation.

**Status**: Infrastructure ✅ COMPLETE | Performance ⚠️ NEEDS OPTIMIZATION  
**Duration**: ~3 hours (analysis + implementation + testing + documentation)  
**Impact**: Critical insight into pladdrr performance characteristics

**Recommendation**: Prioritize performance profiling in next session to identify and address bottlenecks, especially for intensity calculation (90x slower).

---

**Session End**: 2025-11-29  
**Package Version**: 1.0.7  
**Commits**: 15 ahead of origin
