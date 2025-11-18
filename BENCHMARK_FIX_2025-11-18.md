# Benchmark File I/O Fix - 2025-11-18

**Date**: 2025-11-18  
**Issue**: Benchmark scripts failing with file I/O errors  
**Root Cause**: Missing directory creation before saveRDS()  
**Status**: ✅ RESOLVED

---

## Problem Description

Benchmark scripts were failing with errors like:
```
Error in gzfile(file, mode) :
  cannot open compressed file 'inst/benchmarks/results/01_matrix_operations_simd.rds',
  probable reason 'No such file or directory'
```

The main benchmark runner (`00_run_all_benchmarks.R`) creates the results directory, but individual benchmarks could fail if run standalone.

---

## Solution

Added `dir.create("inst/benchmarks/results", recursive = TRUE, showWarnings = FALSE)` before all `saveRDS()` calls in benchmark scripts.

---

## Files Modified

### Core Benchmarks
1. ✅ `inst/benchmarks/01_matrix_operations.R`
   - Added: `dir.create("inst/benchmarks/results", ...)` before saveRDS

2. ✅ `inst/benchmarks/02_data_conversion.R`
   - Added: `dir.create("inst/benchmarks/results", ...)` before saveRDS

3. ✅ `inst/benchmarks/03_tone_generation.R`
   - Added: `dir.create("inst/benchmarks/results", ...)` before saveRDS

### Phase 2 Benchmarks
4. ✅ `inst/benchmarks/06_phase2_intensity.R`
   - Changed: `"results/baseline/"` → `"inst/benchmarks/results/baseline/"`
   - Added: Full path to dir.create

5. ✅ `inst/benchmarks/07_phase2_sound_mixing.R`
   - Changed: Path standardization to `"inst/benchmarks/results/baseline/"`

### Phase 3 Benchmarks
6. ✅ `inst/benchmarks/08_phase3_fft_operations.R`
   - Changed: Path standardization

7. ✅ `inst/benchmarks/09_phase3_formant_lpc.R`
   - Changed: Path standardization

8. ✅ `inst/benchmarks/10_phase3_pitch_detection.R`
   - Changed: Path standardization

9. ✅ `inst/benchmarks/11_end_to_end_pipelines.R`
   - Changed: Path standardization

10. ✅ `inst/benchmarks/12_phase3_window_functions.R`
    - Added: `dir.create("inst/benchmarks/results", ...)` before saveRDS

11. ✅ `inst/benchmarks/13_phase3_autocorrelation.R`
    - Added: `dir.create("inst/benchmarks/results", ...)` before saveRDS

---

## Path Standardization

**Before** (Inconsistent):
```r
# Some benchmarks
saveRDS(results, "inst/benchmarks/results/01_matrix_operations_scalar.rds")

# Other benchmarks
saveRDS(results, "results/baseline/06_phase2_intensity_baseline.rds")
```

**After** (Consistent):
```r
# All benchmarks now use full path from package root
dir.create("inst/benchmarks/results", recursive = TRUE, showWarnings = FALSE)
saveRDS(results, "inst/benchmarks/results/01_matrix_operations_scalar.rds")

# Or for baseline subdirectory
dir.create("inst/benchmarks/results/baseline", recursive = TRUE, showWarnings = FALSE)
saveRDS(results, "inst/benchmarks/results/baseline/06_phase2_intensity_baseline.rds")
```

---

## Benefits

1. ✅ **Standalone Execution**: Each benchmark can run independently
2. ✅ **Consistent Paths**: All use `inst/benchmarks/results/` prefix
3. ✅ **Automatic Creation**: Directories created as needed
4. ✅ **No Warnings**: `showWarnings = FALSE` prevents noise
5. ✅ **Recursive**: Creates parent directories if needed

---

## Testing

### Test 1: Standalone Benchmark Execution
```bash
cd /Users/frkkan96/Documents/src/speaker
Rscript inst/benchmarks/01_matrix_operations.R
# Expected: Creates directory and saves results
```

### Test 2: Full Benchmark Suite
```bash
Rscript inst/benchmarks/00_run_all_benchmarks.R
# Expected: All benchmarks save results successfully
```

### Test 3: Results Directory Structure
```
inst/benchmarks/results/
├── 01_matrix_operations_scalar.rds
├── 01_matrix_operations_simd.rds
├── 02_data_conversion_scalar.rds
├── 02_data_conversion_simd.rds
├── 03_tone_generation_baseline.rds
├── baseline/
│   ├── 06_phase2_intensity_*.rds
│   ├── 07_phase2_sound_mixing_*.rds
│   └── ...
└── ...
```

---

## Related Issues Fixed

### Issue 1: Parselmouth Benchmarks
**Status**: Separate issue - requires test audio file

Benchmarks 04 and 05 need `inst/extdata/test.wav`:
```r
# Current error:
# ✗ Test audio file not found at inst/extdata/test.wav
```

**Solution** (separate task):
```r
# Create test audio in inst/extdata/
dir.create("inst/extdata", recursive = TRUE, showWarnings = FALSE)
# Generate synthetic test file or add to package
```

### Issue 2: SIMD vs Scalar Result Loading
**Status**: Fixed by standardization

The compare_results.R script was looking for:
- `01_matrix_operations_simd.rds`
- `01_matrix_operations_scalar.rds`

But some benchmarks weren't saving with correct names.

**Solution**: Consistent naming pattern throughout

---

## Verification Commands

```bash
# Clean results directory
rm -rf inst/benchmarks/results/

# Run individual benchmark
Rscript inst/benchmarks/01_matrix_operations.R

# Verify file created
ls -lh inst/benchmarks/results/

# Run all benchmarks
Rscript inst/benchmarks/run_scalar_baseline.R
Rscript inst/benchmarks/run_simd_optimized.R

# Compare results
Rscript inst/benchmarks/compare_results.R
```

---

## Status

✅ **RESOLVED**: All benchmark file I/O issues fixed  
✅ **Path Consistency**: All benchmarks use standard paths  
✅ **Directory Creation**: Automatic for all benchmarks  
⏳ **Testing**: Ready for full benchmark suite run  

---

**Fix Applied**: 2025-11-18  
**Files Modified**: 11 benchmark scripts  
**Ready for**: Full benchmark validation
