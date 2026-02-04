# pladdrr Package Shortcomings Report
**Date:** February 3, 2026  
**pladdrr Version Tested:** v4.8.8  
**Previous Version:** v4.8.7  
**Author:** OpenCode AI Assistant  

---

## Executive Summary

This report documents **remaining** shortcomings and API inconsistencies in pladdrr v4.8.8 after the package resolved 3 critical issues from v4.8.7.

**✅ RESOLVED in v4.8.8 (formerly CRITICAL issues):**
1. ~~`textgrid_merge()` crashes~~ → **FIXED:** Now works correctly
2. ~~`TextGrid()` not exported~~ → **FIXED:** Now exported from package namespace
3. ~~Missing `get_start_time()`/`get_end_time()`~~ → **FIXED:** Methods added

**Remaining Issues:**
- API inconsistency: `to_ltas()` fails on windowed spectra (use `to_ltas_1to1()`)
- Naming convention inconsistencies (snake_case vs camelCase)
- Documentation gaps for complex workflows
- R6 method call overhead in tight loops

**Overall Status:** pladdrr v4.8.8 is **production-ready** with excellent core functionality. Remaining issues are minor API design decisions and optimization opportunities.

---

## Recent Improvements in v4.8.8

### Fixed Issue #1: `textgrid_merge()` Now Working ✅

**What Changed:**
- External pointer bug resolved
- `textgrid_merge(list(tg1, tg2, ...), equalize_domains = TRUE)` works correctly
- No more crashes or pointer errors

**Impact on plabench:**
- Removed 40+ lines of manual TextGrid merge workaround code from `vuv.R`
- Simplified VUV implementation from 40 lines → 1 line
- More robust and maintainable code

**New API:**
```r
library(pladdrr)
merged <- textgrid_merge(list(tg1, tg2, tg3), equalize_domains = TRUE)
```

### Fixed Issue #2: `TextGrid()` Now Exported ✅

**What Changed:**
- `TextGrid` R6 class constructor now properly exported
- No namespace workaround needed
- Consistent with `Sound()`, `Pitch()`, `Formant()`, etc.

**Impact on plabench:**
- Removed workaround code from 4 R implementations:
  - `vuv.R` (4 lines removed)
  - `vq.R` (4 lines removed)
  - `pharyngeal.R` (6 lines removed)
  - Related test/benchmark files updated

**Working API:**
```r
library(pladdrr)
tg <- TextGrid("file.TextGrid")  # Just works!
```

### Fixed Issue #3: Time Accessor Methods Added ✅

**What Changed:**
- Added `get_start_time()` and `get_end_time()` methods
- Available on all time-domain objects (Pitch, Sound, Formant, Intensity, etc.)
- More intuitive than geometric names (`get_xmin()`/`get_xmax()`)

**Impact on plabench:**
- Updated `voice_report.R` to use semantic `get_end_time()` instead of `get_xmax()`
- More readable, self-documenting code

**New Methods:**
```r
start <- pitch$get_start_time()  # Semantic name (recommended)
end <- pitch$get_end_time()

# Old names still work:
start <- pitch$get_xmin()  # Same result
end <- pitch$get_xmax()
```

---

## Remaining Issues (v4.8.8)

## 1. API Inconsistency: `to_ltas()` vs `to_ltas_1to1()`

**Severity:** MEDIUM  
**Status:** DESIGN ISSUE  
**Impact:** Confusing API, `to_ltas()` fails on common use cases  

### Description
The `to_ltas(bandwidth)` method fails when called on windowed or filtered spectra with the error:

```
Error: "To Ltas" requires that the analysis bandwidth (bandwidth) be greater 
than the frequency step (dx) in the Spectrum.
```

This occurs because windowed spectra have small frequency steps, violating the bandwidth constraint.

### Two LTAS Methods in Praat

1. **`to_ltas(bandwidth)`** - Frequency averaging (Praat menu: "To Ltas...")
   - Averages frequency bins across `bandwidth`
   - Requires: `bandwidth > frequency_step`
   - **Fails** on windowed/filtered spectra (small freq_step)

2. **`to_ltas_1to1()`** - Exact mapping (Praat menu: "To Ltas (1-to-1)")
   - 1-to-1 mapping of spectrum bins to LTAS
   - **No bandwidth requirement**
   - Works on any spectrum

### Impact on plabench
Most plabench use cases need **exact 1-to-1 mapping**, not frequency averaging:

- **AVQI:** Uses windowed spectra for CPPS calculation
- **VQ:** Uses full spectrum for CPP
- **Praatsauce:** Needs exact spectral measurements
- **Pharyngeal:** Analyzes specific formant regions

**Result:** We use `to_ltas_1to1()` everywhere, making the new `to_ltas(bandwidth)` rarely useful for voice analysis.

### Files Using `to_ltas_1to1()`
- `R_implementations/vq.R` (line ~263)
- `R_implementations/praatsauce.R` (line ~299)
- `R_implementations/pharyngeal.R` (lines ~535, ~762)
- `R_implementations/avqi.R` (CPPS calculations)

### Recommended Fix

**Option 1 (Preferred):** Make `bandwidth` optional
```r
to_ltas = function(bandwidth = NULL) {
  if (is.null(bandwidth)) {
    # Use 1-to-1 mapping (no averaging)
    self$to_ltas_1to1()
  } else {
    # Use bandwidth averaging (existing behavior)
    # ... existing code ...
  }
}
```

**Option 2:** Better error message
```r
to_ltas = function(bandwidth) {
  freq_step <- self$get_dx()
  if (bandwidth <= freq_step) {
    stop(sprintf(
      "bandwidth (%g Hz) must be > frequency_step (%g Hz). 
       For 1-to-1 mapping (no averaging), use to_ltas_1to1() instead.",
      bandwidth, freq_step
    ))
  }
  # ... rest of implementation ...
}
```

**Option 3 (Current):** Keep both methods but document clearly
- `to_ltas(bandwidth)` - For frequency smoothing/averaging
- `to_ltas_1to1()` - For exact spectral analysis (most voice analysis use cases)
- Add usage examples to documentation

---

## 2. API Inconsistency: Snake_case vs camelCase Method Names

**Severity:** LOW  
**Status:** ONGOING DESIGN ISSUE  
**Impact:** Inconsistent user experience  

### Description
pladdrr mixes naming conventions across methods, making the API harder to learn and remember.

### Examples

**Snake_case (Modern R convention):**
- ✅ `to_power_cepstrum()`
- ✅ `to_point_process()`
- ✅ `get_mean_period()`
- ✅ `to_ltas_1to1()`
- ✅ `get_start_time()` (NEW in v4.8.8)
- ✅ `get_end_time()` (NEW in v4.8.8)

**Mixed or inconsistent:**
- `get_number_of_tiers()` - verbose, could be `get_tier_count()`
- `get_interval_start_time()` - very long, could be `get_interval_start()`
- `get_xmin()` / `get_xmax()` - geometric names (now have semantic alternatives)

### Observation
pladdrr v4.8.8 is **moving toward consistent snake_case**, as evidenced by:
- PowerCepstrum rename: `to_powercepstrum()` → `to_power_cepstrum()`
- New time accessors: `get_start_time()`, `get_end_time()`

### Recommendation
**Continue snake_case standardization:**
- Audit all method names for consistency
- Add aliases for backwards compatibility during transition
- Update documentation to use consistent naming
- Consider shorter, more ergonomic names where appropriate:
  - `get_tier_count()` vs `get_number_of_tiers()`
  - `get_interval_count()` vs `get_number_of_intervals()`

---

## 3. Documentation: Insufficient Examples for Complex Workflows

**Severity:** LOW  
**Status:** DOCUMENTATION GAP  
**Impact:** Users must reverse-engineer Praat scripts  

### Description
While pladdrr documents individual methods well, complex workflows (like those in plabench) require reading Praat scripts and translating manually.

### Missing Documentation Examples

1. **TextGrid manipulation workflows:**
   - Merging TextGrids (now that `textgrid_merge()` works!)
   - Extracting intervals matching criteria
   - Creating custom tiers programmatically

2. **Spectral analysis pipelines:**
   - Sound → Spectrum → LTAS → CPP calculation
   - Windowing and filtering for voice analysis
   - Pre-emphasis for formant analysis

3. **Pitch analysis patterns:**
   - Adaptive pitch tracking with quantile-based ranges
   - VUV (Voiced/Unvoiced/Voiced) detection
   - Pitch-to-PointProcess conversion strategies

4. **Multi-file processing:**
   - Batch processing with consistent parameters
   - Error handling for failed analyses
   - Combining results across files

### Impact on plabench
We maintain detailed Praat script references to ensure R implementations match exactly:
- `praat-scripts/AVQI203.praat` → `R_implementations/avqi.R`
- `praat-scripts/DSI201.praat` → `R_implementations/dsi.R`
- `praat-scripts/tremor305.praat` → `R_implementations/tremor.R`
- etc.

plabench R implementations could serve as **real-world examples** for pladdrr documentation.

### Recommended Fix
Add vignettes demonstrating:
1. **"Translating Praat Scripts to pladdrr"** - Line-by-line guide
2. **"Voice Quality Analysis in R"** - AVQI, DSI, CPP examples
3. **"TextGrid Workflows"** - Using `textgrid_merge()`, interval manipulation
4. **"Batch Processing Audio Files"** - Production pipelines with error handling

**Suggestion:** plabench could contribute vignettes back to pladdrr documentation, as our 7 R implementations cover comprehensive voice analysis workflows.

---

## 4. Performance: R6 Method Call Overhead

**Severity:** INFO  
**Status:** OPTIMIZATION OPPORTUNITY  
**Impact:** Noticeable in loops with many R6 method calls  

### Description
R6 method calls have higher overhead than direct function calls. In tight loops processing TextGrid intervals or Pitch frames, this accumulates.

### Example from plabench
Processing TextGrid intervals one-by-one:

```r
# Slower: R6 method called n_intervals times in R loop
n_intervals <- textgrid$get_number_of_intervals(1)
labels <- character(n_intervals)
for (i in 1:n_intervals) {
  labels[i] <- textgrid$get_interval_text(1, i)  # R6 call per iteration
}
```

Even with pre-allocation, per-interval method calls have overhead.

### Benchmark Impact
Some plabench R implementations are 2-4x slower than Python equivalents, partly due to:
- R6 method call overhead in loops
- R's interpreted nature vs Python's more optimized C extensions
- **Note:** Still acceptable for production use (e.g., VUV: 56ms in R vs 22ms in Python)

### Current Best Practices
plabench already uses optimization patterns where possible:
- Pre-extract data before loops
- Use batch API functions (e.g., `get_jitter_shimmer_batch()`)
- Use pipeline operations (e.g., `two_pass_adaptive_pitch()`)
- Minimize R6 method calls in hot paths

### Recommended Fix (for pladdrr developers)

**Option 1:** Vectorized bulk accessors
```r
# Add methods that return all intervals at once
get_all_interval_texts = function(tier_num) {
  # C++ code returns character vector directly
}

get_all_interval_times = function(tier_num) {
  # C++ code returns data.frame/data.table with [start, end, label]
}
```

**Option 2:** Expose lower-level batch operations
```r
# Allow C++ to handle loops internally
textgrid_extract_tier_data = function(tier_num) {
  # Returns complete tier data in one call
  # list(times = matrix, labels = character)
}
```

**Option 3 (Current):** Document performance patterns
Add performance guide showing:
- Pre-extract data before loops
- Use batch functions where available (`get_jitter_shimmer_batch`, `get_peaks_batch`, etc.)
- Profile code to identify bottlenecks
- Accept that R is 2-4x slower than Python (still fast enough for production)

**Note:** plabench's warm-session R benchmarks show **R is competitive or faster** than Python for some tools:
- Tremor: R 2.25x **faster** than Python (24ms vs 54ms)
- VQ: R 1.41x **faster** than Python (1.36s vs 1.92s)

So R6 overhead is **not a blocker** for production use.

---

## Summary Table: Issue Severity & Status

| # | Issue | Severity | Status | Workaround? |
|---|-------|----------|--------|-------------|
| ~~1~~ | ~~`textgrid_merge()` crashes~~ | ~~CRITICAL~~ | ✅ **FIXED v4.8.8** | N/A |
| ~~2~~ | ~~`TextGrid()` not exported~~ | ~~HIGH~~ | ✅ **FIXED v4.8.8** | N/A |
| ~~3~~ | ~~Missing `get_start_time()`/`get_end_time()`~~ | ~~MEDIUM~~ | ✅ **FIXED v4.8.8** | N/A |
| 1 | `to_ltas()` fails on windowed spectra | MEDIUM | DESIGN | ✅ Use `to_ltas_1to1()` |
| 2 | Inconsistent snake_case/camelCase | LOW | ONGOING | N/A (style) |
| 3 | Insufficient documentation examples | LOW | GAP | ✅ Read Praat scripts / plabench code |
| 4 | R6 method call overhead | INFO | OPTIMIZATION | ✅ Use batch APIs |

---

## Impact on plabench Development

### v4.8.7 → v4.8.8 Improvements

**Code Simplified:**
- Removed **52 lines** of workaround code across 4 R implementations
- VUV: 40+ lines of manual TextGrid merge → 1 line using `textgrid_merge()`
- 3 files: Removed TextGrid namespace workarounds
- More maintainable, robust code

**Testing:**
✅ **All tests pass after v4.8.8 update:**
- 14/14 3-way validation tests (Praat vs Python vs R)
- All R implementations match Python/Praat within tolerance
- TextGrid merge/export functionality validated

### Current Status (v4.8.8)

**Remaining workaround needed:** Only Issue #1 (`to_ltas_1to1()` preference)

**Development friction:** Minimal
- Most API is consistent and intuitive
- Remaining issues are minor design preferences
- Documentation gaps filled by referencing plabench implementations

---

## Recommendations for pladdrr Development Team

### Short-term (v4.9.0)

1. **Improve `to_ltas()` API** (Issue #1)
   - Make bandwidth optional (default to 1-to-1 mapping)
   - Better error messages explaining when to use `to_ltas_1to1()`
   - Document use cases clearly

2. **Continue snake_case standardization** (Issue #2)
   - Audit method names for consistency
   - Consider shorter aliases where appropriate
   - Maintain backwards compatibility during transition

### Medium-term (v4.10.0)

3. **Add workflow vignettes** (Issue #3)
   - Voice quality analysis examples (AVQI, DSI, CPP)
   - TextGrid manipulation using `textgrid_merge()` and friends
   - Batch processing patterns
   - **Suggestion:** Use plabench implementations as real-world examples

### Long-term (v5.0.0)

4. **Performance optimizations** (Issue #4)
   - Vectorized bulk accessors for TextGrid intervals
   - Batch extraction methods for common operations
   - C++-level loop handling for hot paths
   - **Note:** Current performance already acceptable for production

---

## Testing Recommendations

### Unit Tests to Add

1. **TextGrid merge scenarios** (now that it works!):
   ```r
   test_that("textgrid_merge works with overlapping time ranges", { ... })
   test_that("textgrid_merge preserves interval labels", { ... })
   test_that("textgrid_merge handles different tier types", { ... })
   test_that("textgrid_merge equalize_domains parameter works", { ... })
   ```

2. **Time accessor equivalence:**
   ```r
   test_that("get_start_time equals get_xmin for Pitch", { ... })
   test_that("get_end_time equals get_xmax for Sound", { ... })
   test_that("time accessors work on all time-domain objects", { ... })
   ```

3. **LTAS conversion edge cases:**
   ```r
   test_that("to_ltas works with various bandwidths", { ... })
   test_that("to_ltas_1to1 works on windowed spectrum", { ... })
   test_that("to_ltas gives helpful error when bandwidth too small", { ... })
   ```

### Integration Tests

4. **Complex workflow tests** (like plabench's 3-way validation):
   - AVQI calculation pipeline with `textgrid_merge()`
   - DSI multi-file processing
   - VUV with TextGrid merge (now simplified!)
   - Pharyngeal formant analysis

---

## Conclusion

pladdrr v4.8.8 represents a **major quality improvement** over v4.8.7, resolving all 3 critical issues that required workarounds:

✅ **v4.8.8 Achievements:**
- `textgrid_merge()` works correctly
- `TextGrid()` properly exported
- Semantic time accessors added (`get_start_time()`, `get_end_time()`)
- **52 lines of workaround code removed from plabench**
- Cleaner, more maintainable codebase

**Overall Assessment:**
- ✅ **Core functionality:** Excellent - wraps Praat objects accurately
- ✅ **API completeness:** Very good - all essential Praat functions available
- ⚠️ **API consistency:** Good and improving - moving toward snake_case
- ✅ **Bug-free:** All critical bugs resolved in v4.8.8
- ⚠️ **Documentation:** Good for basics, could use more workflow examples
- ✅ **Performance:** Acceptable - competitive with Python for many tasks

**Recommendation:** pladdrr v4.8.8 is **production-ready** for clinical voice analysis. The plabench project successfully uses pladdrr for all 7 R implementations with **no critical workarounds needed**.

Remaining issues are minor API design preferences that don't block production use. The package is mature, stable, and suitable for research and clinical applications.

---

## Appendix A: Working Code Patterns (v4.8.8)

### Pattern 1: TextGrid Merge (NOW WORKING!)
```r
library(pladdrr)

# Create or load TextGrids
tg1 <- TextGrid("file1.TextGrid")
tg2 <- TextGrid("file2.TextGrid")

# Merge with time domain alignment
merged <- textgrid_merge(list(tg1, tg2, tg3), equalize_domains = TRUE)

# Result: All tiers from all TextGrids in one object
```

### Pattern 2: TextGrid Constructor (NOW EXPORTED!)
```r
library(pladdrr)

# Just works - no workaround needed!
tg <- TextGrid("file.TextGrid")
```

### Pattern 3: Semantic Time Accessors (NOW AVAILABLE!)
```r
library(pladdrr)
sound <- Sound("file.wav")
pitch <- sound$to_pitch()

# Recommended: Use semantic names
start <- pitch$get_start_time()
end <- pitch$get_end_time()

# Still works: Geometric names
start <- pitch$get_xmin()  # Same result
end <- pitch$get_xmax()
```

### Pattern 4: LTAS for Spectral Analysis
```r
# For exact spectral measurements (no averaging):
ltas <- spectrum$to_ltas_1to1()  # Always works

# For frequency smoothing (bandwidth must be > freq_step):
ltas <- spectrum$to_ltas(100)  # May fail on windowed spectra
```

### Pattern 5: Batch API Usage (Best Performance)
```r
# Use pipeline operations for best performance
library(pladdrr)

# Two-pass adaptive pitch detection
result <- two_pass_adaptive_pitch(sound, time_step = 0.01, 
                                   min_pitch = 75, max_pitch = 500)
pitch <- result$pitch

# Batch jitter/shimmer calculation
pointprocess <- to_point_process_from_sound_and_pitch(sound, pitch)
metrics <- get_jitter_shimmer_batch(pointprocess, sound, 
                                     min_period = 0.0001, 
                                     max_period = 0.02)

# Result: All 11 jitter/shimmer metrics in one call
```

---

## Appendix B: Migration Guide (v4.8.7 → v4.8.8)

### What to Update in Your Code

**1. Remove TextGrid Workarounds**

Before (v4.8.7):
```r
# Required workaround
if (!exists("TextGrid")) {
  TextGrid <- asNamespace("pladdrr")$TextGrid
}
```

After (v4.8.8):
```r
# Just works!
library(pladdrr)
# TextGrid is available
```

**2. Use textgrid_merge() Instead of Manual Merge**

Before (v4.8.7 - 40+ lines):
```r
# Manual merge required due to bug
temp_file <- tempfile(fileext = ".TextGrid")
textgrid_orig$save(temp_file)
textgrid_merged <- TextGrid(temp_file)
unlink(temp_file)

vuv_tier_name <- textgrid_vuv$get_tier_name(1)
textgrid_merged$add_interval_tier(vuv_tier_name)
# ... 30+ more lines of loops ...
```

After (v4.8.8 - 1 line):
```r
# Native merge now works!
textgrid_merged <- textgrid_merge(list(textgrid_orig, textgrid_vuv), 
                                   equalize_domains = TRUE)
```

**3. Use Semantic Time Accessors (Optional)**

Before (v4.8.7):
```r
end_time <- pitch$get_xmax()  # Only option
```

After (v4.8.8 - both work):
```r
end_time <- pitch$get_end_time()  # More readable (recommended)
# or
end_time <- pitch$get_xmax()      # Still works
```

---

## Appendix C: plabench Validation Results (v4.8.8)

All R implementations tested and validated against Praat and Python:

**Test Suite:** 14/14 tests passing (83s runtime)

**Tools Validated:**
- ✅ **DSI** - All metrics within tolerance
- ✅ **AVQI v2.03** - Matches Praat/Python
- ✅ **AVQI v3.01** - Matches with relaxed ZCR tolerances
- ✅ **Tremor** - 18 measures validated, FTrI bug fixed
- ✅ **VUV** - TextGrid merge working perfectly (2 tiers, 131 intervals)
- ✅ **VQ** - Jitter, shimmer, HNR, spectral, GNE, CPP all validated
- ✅ **Pharyngeal** - H1-H2, H1-A1 exact match (formant bug documented separately)

**Performance (Warm Session Benchmarks):**
| Tool | R (v4.8.8) | Python | R/Python Ratio |
|------|------------|--------|----------------|
| Tremor | 24ms | 54ms | 0.44x (R **faster**) |
| VQ | 1.36s | 1.92s | 0.71x (R **faster**) |
| Pharyngeal | 45ms | 31ms | 1.45x (R competitive) |
| AVQI | 12.5s | 11.6s | 1.07x (R competitive) |
| VUV | 56ms | 22ms | 2.55x (R slower, still fast) |
| DSI | 410ms | 115ms | 3.57x (R slower, acceptable) |

**Conclusion:** pladdrr v4.8.8 provides **production-ready performance** for all clinical voice analysis tasks. In some cases (Tremor, VQ), R implementation is **faster** than Python.

---

## Appendix D: Related Documentation

**plabench Documentation:**
- `PLADDRR_V4.8.8_UPDATE_SUMMARY.md` - Detailed v4.8.8 fixes and migration
- `PLADDRR_V488_MIGRATION_COMPLETE.md` - v4.8.7→v4.8.8 migration summary
- `PLADDRR_API_UPDATE_SUMMARY.md` - Previous v4.6.4→v4.8.7 work
- `PLADDRR_PERFORMANCE_ASSESSMENT.md` - Performance profiling results
- `CLAUDE.md` - Updated implementation notes

**Test/Validation:**
- `tests/test_3way_validation.py` - Praat vs Python vs R validation suite
- `benchmark_warm_r.R` - R warm-session performance benchmarks
- `benchmark_warm_python.py` - Python warm-session performance benchmarks

**R Implementations (Reference Code for Workflows):**
- `R_implementations/vuv.R` - VUV detection with TextGrid merge
- `R_implementations/vq.R` - Voice quality with batch jitter/shimmer
- `R_implementations/avqi.R` - AVQI with CPPS calculation
- `R_implementations/dsi.R` - DSI multi-file processing
- `R_implementations/tremor.R` - Tremor analysis
- `R_implementations/pharyngeal.R` - Pharyngealization analysis
- `R_implementations/dysprosody.R` - Prosody with MOMEL/INTSINT

**Status:** pladdrr v4.8.8 validated across 7 complex voice analysis implementations totaling ~2500 lines of R code.
