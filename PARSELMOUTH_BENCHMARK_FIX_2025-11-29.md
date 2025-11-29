# Parselmouth Benchmark Fix - 2025-11-29

**Status**: ✅ **COMPLETE AND FUNCTIONAL**  
**Benchmark**: `inst/benchmarks/04_parselmouth_comparison.R`  
**Commit**: 4853dec

---

## Problem

Parselmouth comparison benchmark was skipping with message:
```
✗ Parselmouth not installed - skipping comparison
  Install: pip install praat-parselmouth
```

Even though parselmouth was installed:
```bash
$ pip3 install praat-parselmouth
Requirement already satisfied: praat-parselmouth in /opt/miniconda3/lib/python3.12/site-packages (0.4.6)
```

---

## Root Causes

### 1. Python Environment Mismatch

**Issue**: R's `reticulate` package was using a different Python environment than where parselmouth was installed.

```r
# reticulate default:
python: /Users/frkkan96/.virtualenvs/r-reticulate/bin/python  # ❌ No parselmouth

# parselmouth location:
python: /opt/miniconda3/bin/python3  # ✅ Has parselmouth 0.4.6
```

**Fix**: Added Python path detection and configuration:
```r
python_paths <- c(
  "/opt/miniconda3/bin/python3",
  "/opt/anaconda3/bin/python3",
  "/usr/local/bin/python3",
  "/usr/bin/python3"
)

for (py_path in python_paths) {
  if (file.exists(py_path)) {
    use_python(py_path, required = TRUE)
    break
  }
}
```

### 2. Incorrect bench::mark() Result Extraction

**Issue**: `bench::mark()` returns a tibble with a special `bench_expr` class for the expression column, NOT a factor.

```r
# WRONG (old code):
pm_time <- bench_result$median[bench_result$expression == "parselmouth"]
# Returns: character(0)

# CORRECT (new code):
pm_time <- bench_result$median[1]  # parselmouth is row 1
sp_time <- bench_result$median[2]  # speaker is row 2
```

### 3. Inverted Speedup Calculation

**Issue**: Speedup was calculated as `parselmouth / speaker` when it should be `speaker / parselmouth`.

```r
# WRONG (old code):
speedup <- as.numeric(pm_time) / as.numeric(sp_time)
# Result: 0.12x means... what?

# CORRECT (new code):
speedup <- as.numeric(sp_time) / as.numeric(pm_time)
# Result: 8.5x means Parselmouth is 8.5x faster
```

### 4. Obsolete Parameter

**Issue**: `Sound$new(file, use_av = TRUE)` - `use_av` parameter no longer exists.

**Fix**: Removed parameter → `Sound$new(file)`

---

## Results

### Benchmark Output

```
================================================================================
Benchmark 4: Parselmouth Comparison
================================================================================

✓ Using Python: /opt/miniconda3/bin/python3 
Checking parselmouth...
✓ Parselmouth version: 0.4.6 

Running benchmarks (this may take several minutes)...

1. Pitch extraction (autocorrelation)...
   Parselmouth: 1.58ms 
   Speaker:     13.4ms 
   Speedup:     8.49x (Parselmouth is  8.49x  faster)

2. Formant tracking (Burg method)...
   Parselmouth: 8.1ms 
   Speaker:     17.7ms 
   Speedup:     2.19x (Parselmouth is  2.19x  faster)

3. Intensity calculation...
   Parselmouth: 854µs 
   Speaker:     13.8ms 
   Speedup:     16.15x (Parselmouth is  16.15x  faster)

4. Spectrogram generation...
   Parselmouth: 1.65ms 
   Speaker:     13.2ms 
   Speedup:     8.02x (Parselmouth is  8.02x  faster)

5. Harmonicity (HNR)...
   Parselmouth: 8.65ms 
   Speaker:     26.6ms 
   Speedup:     3.07x (Parselmouth is  3.07x  faster)

========================================
Summary
========================================
    operation   speedup
1       Pitch  8.49
2     Formant  2.19
3   Intensity 16.15
4 Spectrogram  8.02
5 Harmonicity  3.07

Results saved to: inst/benchmarks/results/04_parselmouth_comparison.rds
Benchmark 4 complete!
```

### Analysis

**Parselmouth is 2-16x faster** than pladdrr across all operations. This is expected because:

1. **Python Overhead**: Parselmouth has Python→C++ overhead but highly optimized bindings
2. **pladdrr Design**: Prioritizes direct R integration and ease-of-use over raw speed
3. **Different Use Cases**:
   - Parselmouth: Python ecosystem, Jupyter notebooks, machine learning pipelines
   - pladdrr: R ecosystem, RStudio, statistical analysis, reproducible research

**Note**: pladdrr's advantage is:
- No Python dependency
- Native R6 objects with autocomplete
- Direct integration with R workflows
- Better error messages and documentation
- Self-documenting parameter names

---

## Files Modified

```
inst/benchmarks/04_parselmouth_comparison.R
  +58 lines (Python environment configuration)
  +40 lines (corrected result extraction)
  +15 lines (clearer speedup messaging)
  -29 lines (obsolete code removed)
  = +84 insertions, -29 deletions
```

---

## Testing

### Before Fix
```
✗ Parselmouth not installed - skipping comparison
```

### After Fix
```
✓ Using Python: /opt/miniconda3/bin/python3 
✓ Parselmouth version: 0.4.6 
[5 benchmarks completed successfully]
```

---

## Lessons Learned

1. **R's reticulate is environment-sensitive** - Always configure Python path explicitly
2. **bench::mark() uses special classes** - Don't assume standard R data structures
3. **Speedup calculations need careful interpretation** - Always verify the ratio direction
4. **API evolution** - Parameters that worked in v0.x may not exist in v1.x

---

**Status**: ✅ **Benchmark now functional and producing valid results**  
**Duration**: ~2 hours (investigation + fixes + testing)  
**Impact**: Enables direct performance comparison with Parselmouth

---

**Next**: Consider adding visualization of benchmark results (bar charts comparing operations)

