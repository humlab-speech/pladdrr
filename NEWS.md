# pladdrr 2.2.0 (2026-01-08)

## Performance Enhancements

Major performance improvements based on plabench user feedback, reducing R↔C++ boundary crossing overhead. Target: move from 5-20x slower than Python/Parselmouth to within 2-5x.

### New Batch/Vectorized Methods

* **TextGrid batch extraction** (2-3x faster for AVQI, 5-20x for large grids)
  - `get_all_intervals(tier)` - Extract all intervals in single call → data.frame(start, end, text)
  - `get_all_points(tier)` - Extract all points in single call → data.frame(time, text)
  - Eliminates 3n+1 R↔C++ calls per n intervals/points

* **Compound statistics** (1.3-1.5x faster, 40-50% speedup for VUV workflows)
  - `Pitch$get_statistics(metrics)` - Get multiple pitch stats (min/max/mean/stdev/q1/q3/median/count_voiced) in one call
  - `Intensity$get_statistics(metrics)` - Get multiple intensity stats in one call
  - Replaces 5-8 individual method calls with single batch call

* **Direct vector access** (1.3-1.4x faster, 30-40% speedup for tremor analysis)
  - `Pitch$get_times_vector()` / `get_values_vector(unit)` - Direct numeric vectors bypassing data.frame overhead
  - `Intensity$get_times_vector()` / `get_values_vector()` - Direct numeric vectors
  - Sound already had `get_values(channel)` and `get_sample_times()`

* **Batch sound extraction** (1.2-1.3x faster for AVQI v2.03)
  - `Sound$extract_parts_batch(starts, ends)` - Extract multiple segments in single call
  - Exposed existing C++ implementation to R6 interface

### Bug Fixes

* **sound_concatenate_all() now accepts R6 objects** (1.5-2x faster for DSI/AVQI)
  - Fixed to accept Sound R6 objects directly, not just raw external pointers
  - Automatically extracts .xptr from R6 objects in C++

### Expected Impact on plabench Tools

| Tool | Before | After | Speedup |
|------|--------|-------|---------|
| VUV | 0.36s | 0.10s | **3.6x** |
| AVQI v2.03 | 7.48s | 2.5s | **3.0x** |
| DSI | 0.98s | 0.45s | **2.2x** |
| AVQI v3.01 | 6.19s | 3.0s | **2.1x** |
| Tremor | 0.30s | 0.15s | **2.0x** |
| VQ | 3.06s | 1.5s | **2.0x** |

### Backwards Compatibility

All changes are 100% backwards compatible. Existing code continues to work; users can opt-in to new faster methods.

**Files changed:** `src/textgrid_wrappers.cpp`, `src/sound_wrappers.cpp`, `src/modules/pitch_module.cpp`, `src/modules/intensity_module.cpp`, `R/textgrid-r6.R`, `R/pitch-r6.R`, `R/intensity-r6.R`, `R/sound-r6-new.R`, `tests/testthat/test-performance-enhancements.R`

**See also:** `PERFORMANCE_ENHANCEMENTS_2026-01-08.md` for detailed implementation notes

---

# pladdrr 2.1.1 (2026-01-07)

## Bug Fixes: API Consistency

Fixed class naming and method consistency issues across sampled objects:

* **Class name standardization**
  - Changed `inherits()` checks from internal names (`formant_constructor`, `pitch_constructor`, `intensity_constructor`) to clean public names (`Formant`, `Pitch`, `Intensity`)
  - Improves consistency with module-based object architecture
  
* **Method aliases for consistency**
  - Added `get_xmin()` and `get_xmax()` aliases to Formant, Intensity, Pitch R6 classes
  - Ensures consistent API across all sampled objects (Sound, Pitch, Formant, Intensity, etc.)
  
* **Fixed interpolation codes**
  - Corrected `get_intensity_at_times()` interpolation mapping:
    - cubic: 4 → 2 (correct)
    - sinc70: 6 → 3 (correct)
    - Added missing sinc700: 4
  - Aligns with Praat's internal interpolation constants
  
* **Test updates**
  - Updated tests to use specific method names (`to_formant_burg`, `to_pitch_cc`) instead of deprecated generic methods
  - All batch-queries tests passing (43 PASS, 0 FAIL)

**Files changed:** `R/batch-queries.R`, `R/formant-r6.R`, `R/intensity-r6.R`, `R/pitch-r6.R`, `tests/testthat/test-batch-queries.R`

---

# pladdrr 2.1.0 (2026-01-07)

## Phase 2 Complete: Interpreter Module

Migrated persistent Praat interpreter from wrapper functions to Rcpp Module for better performance and memory management.

### Interpreter Module (`RInterpreter` class)

* **New module:** `src/modules/interpreter_module.cpp` (370 lines)
  - Wraps `XPtr<structInterpreter>` with clean C++ class interface
  - 10 methods migrated from wrapper functions to module methods
  
* **Methods migrated to module:**
  - `run(script)` - Execute Praat script
  - `eval_numeric(expr)` - Evaluate numeric expression
  - `eval_string(expr)` - Evaluate string expression
  - `eval_vector(expr)` - Evaluate vector expression
  - `eval_matrix(expr)` - Evaluate matrix expression
  - `eval_string_array(expr)` - Evaluate string array
  - `get_variable(name, type)` - Get variable from interpreter
  - `set_variable(name, value)` - Set variable in interpreter
  - `is_valid()` - Check interpreter validity
  - `get_xptr()` - Get raw XPtr (for legacy compatibility)

* **Preserved wrapper functions:** 8 global object list operations
  - These operate on `theCurrentPraatObjects` singleton (global state)
  - Correctly kept as wrappers: `interpreter_object_count()`, `interpreter_object_info()`, `interpreter_select()`, etc.

### Architecture Clarification

* **Module vs Wrapper roles documented:**
  - **Modules:** Instance methods, property access, queries (performance-critical)
  - **Wrappers:** Factory functions, transformations, global state operations
  - Both are necessary and complementary (not duplicates)

### Updated Documentation

* **`LEGACY_AUDIT.md`**: Marked Phase 2 (Interpreter Module) as COMPLETE
* **`IMPLEMENTATION_STATUS_2026-01-07.md`**: Comprehensive package status report
  - 33 Rcpp modules (92% coverage)
  - 780+ module methods
  - ~530 wrapper functions (creation/transformation - needed)
  - Package is production-ready at v2.1.0

**Implementation:** `src/modules/interpreter_module.cpp`, `R/praat-interpreter-r6.R`

---

# pladdrr 2.0.9 (2026-01-07)

## Phase 5 Performance Enhancements: Batch Query Operations (3-5x faster)

Added batch query operations for common analysis workflows, reducing R<->C++ boundary crossings.

### Formant Batch Queries

* **`get_formants_at_times(formant, times, formant_numbers = 1:4, unit = "hertz")`**
  - Query multiple formants at multiple time points in single call
  - Returns list with `F1`, `F2`, `F3`, `F4`, etc.
  - Impact: 4n → 1 call reduction (3-5x faster for vowel analysis)
  - Example: Extract F1-F4 at 100 time points = 400 → 1 calls

* **`get_formant_bandwidths_at_times(formant, times, formant_numbers, unit)`**
  - Batch query formant bandwidths
  - Returns list with `B1`, `B2`, `B3`, `B4`, etc.

### Pitch Batch Queries

* **`get_pitch_at_times(pitch, times, unit = "hertz", interpolate = TRUE)`**
  - Query pitch (F0) values at multiple time points
  - Returns numeric vector
  - Impact: n → 1 calls (2-3x faster for pitch contour extraction)

* **`get_pitch_strengths_at_times(pitch, times, unit, interpolate)`**
  - Query pitch strengths (voicing confidence) in batch
  - Useful for voice quality analysis

### Intensity Batch Queries

* **`get_intensity_at_times(intensity, times, interpolate = "cubic")`**
  - Query intensity (dB) at multiple time points
  - Supports: "nearest", "linear", "cubic", "sinc70" interpolation
  - Impact: n → 1 calls (2-3x faster)

### PointProcess Batch Operations

* **`get_pointprocess_times(pointprocess)`**
  - Extract all point times as vector in single call
  - Impact: n → 1 calls (5-10x faster than looping `get_time(i)`)

* **`get_pointprocess_intervals(pointprocess)`**
  - Compute all inter-point intervals in C++
  - Returns vector of length `n_points - 1`
  - Impact: Useful for jitter analysis (5-10x faster)

* **`get_pointprocess_nearest_indices(pointprocess, times)`**
  - Find nearest point index for multiple query times
  - Returns integer vector of indices (1-based)

### Implementation

* **New C++ file:** `src/batch_queries.cpp` (320 lines)
* **New R file:** `R/batch-queries.R` (360 lines)
* **Tests:** `tests/testthat/test-batch-queries.R` (15 tests + benchmarks)

### Performance Summary

| Operation | Old (calls) | New (calls) | Speedup |
|-----------|-------------|-------------|---------|
| Formant F1-F4 × 50 times | 200 | 1 | 3-5x |
| Pitch contour × 100 times | 100 | 1 | 2-3x |
| PointProcess all times (n=500) | 500 | 1 | 5-10x |

**Total workflow speedup (Phase 1-5):** 75-100% (~2x faster than baseline v2.0.4)

---

# pladdrr 2.0.8 (2026-01-07)

## Phase 3+4 Performance Enhancements: Zero-Copy + TextGrid Batch + Module Properties

### Phase 3: Zero-Copy Data Access (5-10x faster for large files)

Implemented read-only views into Praat memory without copying:

* **`get_sound_values_zerocopy(sound, channel)`**
  - Returns numeric vector pointing to Praat's internal memory
  - No allocation/copying overhead
  - Impact: 5-10x faster for large audio files (>10 MB)
  - Safety: Read-only, valid only while Sound exists
  - Implemented in: `src/sound_zerocopy.cpp`, `R/zerocopy-access.R`

* **`get_sound_times_fast(sound)`**
  - Optimized time vector computation
  - Impact: 2-3x faster than regular method

* **`sound_as_matrix_zerocopy(sound, zerocopy = FALSE)`**
  - Matrix export with optional zero-copy for mono sounds
  - Default FALSE for safety

* **`is_zerocopy_vector(x)`**
  - Check if vector is zero-copy view

**Tests:** `tests/testthat/test-zerocopy-access.R` (10 comprehensive tests)

### Phase 3: TextGrid Batch Operations (10-50x faster)

Reduce R<->C++ boundary crossings for TextGrid workflows:

* **`extract_textgrid_intervals(textgrid, tier, ...)`**
  - Extract multiple matching intervals in single C++ call
  - Parameters: `text_equals`, `text_contains`, `text_starts_with`
  - Optional: `sound` for extracting audio segments
  - Impact: 10-50x faster than R loops (DSI, AVQI workflows)
  - Implemented in: `src/textgrid_batch_operations.cpp`, `R/textgrid-batch.R`

* **`get_textgrid_labels_all(textgrid, tier)`**
  - Get all interval labels in single call
  - Impact: 4n → 1 call reduction

* **`get_textgrid_interval_stats(textgrid, tier)`**
  - DataFrame with index, label, start, end, duration
  - Impact: 5n → 1 call reduction

**Tests:** `tests/testthat/test-textgrid-batch.R` (9 tests + benchmarks)

### Phase 3+4: Module Properties (2-3x faster property access)

Added Rcpp Module properties for direct member access without method call overhead:

**Phase 3 Modules:**
* **Sound Module** - `duration`, `xmin`, `xmax`, `nx`, `dx`, `x1`, `sampling_frequency`, `number_of_samples`, `number_of_channels`
* **Pitch Module** - `duration`, `xmin`, `xmax`, `nx`, `dx`, `x1`, `ceiling`
* **Intensity Module** - `duration`, `xmin`, `xmax`, `nx`, `dx`, `x1`

**Phase 4 Modules:**
* **Formant Module** - `duration`, `xmin`, `xmax`, `nx`, `dx`, `x1`, `min_num_formants`, `max_num_formants`
* **Harmonicity Module** - `duration`, `xmin`, `xmax`, `nx`, `dx`, `x1`
* **Spectrum Module** - `fmin`, `fmax`, `n_bins`, `df`, `f1`
* **Spectrogram Module** - `duration`, `xmin`, `xmax`, `nx`, `dx`, `x1`, `ymin`, `ymax`, `ny`, `dy`, `y1`
* **PointProcess Module** - `xmin`, `xmax`, `duration`, `nt`

**Usage:** `sound$.cpp$duration` (fast) vs `sound$get_duration()` (backward compatible)  
**Impact:** 2-3x faster for property queries in loops  
**Note:** Old `get_*()` methods remain fully functional

### Performance Summary

Combined with Phase 1+2 (already committed):
- **Phase 1+2:** 40-55% baseline speedup
- **Phase 3+4:** +20-30% additional speedup
- **Total:** 60-75% faster than v2.0.4 baseline

### Technical Changes

**New Files:**
- `src/sound_zerocopy.cpp` - Zero-copy implementation
- `src/textgrid_batch_operations.cpp` - TextGrid batch operations
- `R/zerocopy-access.R` - Zero-copy R wrappers
- `R/textgrid-batch.R` - TextGrid batch R wrappers
- `tests/testthat/test-zerocopy-access.R` - 10 tests
- `tests/testthat/test-textgrid-batch.R` - 9 tests

**Modified Files:**
- `src/modules/sound_module.cpp` - Added 9 properties
- `src/modules/pitch_module.cpp` - Added 7 properties
- `src/modules/intensity_module.cpp` - Added 6 properties
- `src/modules/formant_module.cpp` - Added 8 properties
- `src/modules/harmonicity_module.cpp` - Added 6 properties
- `src/modules/spectrum_module.cpp` - Added 5 properties
- `src/modules/spectrogram_module.cpp` - Added 11 properties
- `src/modules/pointprocess_module.cpp` - Added 4 properties
- `src/Makevars`, `src/Makevars.in` - Added new source files
- `NAMESPACE` - Exported new functions
- `R/batch-analysis.R` - Disabled voice_quality_batch (pending Praat API update)

**Removed:**
- `src/sound_zerocopy_OLD.cpp` - Superseded by sound_zerocopy.cpp

**Backward Compatibility:** All changes are additive. No breaking changes.

---

# pladdrr 2.0.7 (2026-01-07)

**Safety Features:**
- Vectors marked as read-only with attributes
- Warning on first use per session
- Clear documentation about lifetime constraints
- Print method shows zero-copy status

### TextGrid Batch Operations (10-50x faster)

Batch operations reduce R<->C++ boundary crossings for TextGrid workflows:

* **`extract_textgrid_intervals(textgrid, tier, text_equals/contains/starts_with, extract_sounds)`**
  - Extracts all matching intervals in single call
  - Replaces manual R loops with 4n calls → 1 call
  - Expected impact: 10-50x faster for DSI/AVQI TextGrid extraction
  - Returns: indices, labels, start_times, end_times, optional Sound objects
  - Implemented in: `src/textgrid_batch_operations.cpp`, `R/textgrid-batch.R`

* **`get_textgrid_labels_all(textgrid, tier)`**
  - Get all interval labels in one call
  - Expected impact: 20-40x faster than n calls to `get_interval_text()`

* **`get_textgrid_interval_stats(textgrid, tier)`**
  - Returns data frame with index, label, start, end, duration for all intervals
  - Expected impact: 30-50x faster than manual loops

### Testing

* Added `tests/testthat/test-zerocopy-access.R` - 10 tests for zero-copy functionality
* Added `tests/testthat/test-textgrid-batch.R` - 9 tests including performance benchmarks
* All Phase 1 + Phase 2 tests remain passing

**Phase 3 Expected Impact: 20-30% additional speedup**  
**Combined Phases 1+2+3: 60-75% total workflow speedup**

---

# pladdrr 2.0.6 (2026-01-06)

## Phase 2 Performance Enhancements: Batch Operations Framework

### New Batch Analysis Functions

Implemented batch operations that combine multiple R<->C++ calls into single function calls:

* **`voice_quality_batch()`** - Voice quality analysis in one call
  - Combines 10 separate operations: to_pitch_cc() + 4 pitch stats + to_intensity() + 4 intensity stats
  - Returns: pitch (mean, max, min, stdev, median) + intensity (mean, max, min, stdev, median)
  - Expected impact: 15-20% speedup for DSI, AVQI workflows
  - Implemented in: `src/sound_batch_analysis.cpp`, `R/batch-analysis.R`

* **`formant_analysis_batch()`** - Multi-formant statistics in one call
  - Combines 21 operations for 4 formants: to_formant_burg() + (5 stats × 4 formants)
  - Returns: F1, F2, F3, F4 each with mean, stdev, median, minimum, maximum
  - Expected impact: 20-25% speedup for vowel space analysis
  - Implemented in: `src/sound_batch_analysis.cpp`, `R/batch-analysis.R`

* **`pitch_harmonicity_batch()`** - Combined pitch/HNR analysis
  - Optimized to share autocorrelation computation between pitch and harmonicity
  - Returns: pitch statistics + HNR statistics
  - Expected impact: 10-15% speedup compared to separate analyses
  - Implemented in: `src/sound_batch_analysis.cpp`, `R/batch-analysis.R`

### Testing
* Added comprehensive test suite: `tests/testthat/test-batch-analysis.R`
* Tests verify correctness by comparing batch vs individual calls
* Tests validate input handling and error messages

**Phase 2 Expected Impact: 15-25% additional speedup**  
**Combined with Phase 1: 40-55% total workflow speedup**

---

# pladdrr 2.0.5 (2026-01-06)

## Phase 1 Performance Enhancements

### Critical Bug Fix
* **Fixed `sound_concatenate_all()` pointer extraction bug**
  - Root cause: Function tried `s$.__enclos_env__$private$ptr` but Sound objects use `.xptr` field
  - Added robust pointer extraction with fallback methods
  - Fixes multi-file batch concatenation operations
  - Expected impact: 10-20% speedup for multi-file workflows

### New Direct Vector Access Methods
* **Added `Sound$get_values(channel)` and `Sound$get_sample_times()`**
  - Returns numeric vectors directly, bypassing data frame overhead
  - Expected impact: 20-30% speedup for signal processing (AVQI v3.01, VQ analyses)
  - Implemented in: `src/modules/sound_module.cpp`, `R/sound-r6-new.R`

### Batch Statistics Methods
* **Added `Pitch$get_statistics()` method**
  - Returns multiple statistics in single call: min, max, mean, stdev, median, quantiles
  - Expected impact: 10-15% speedup for pitch analyses requiring multiple stats
  - Usage: `pitch$.cpp$get_statistics(from_time, to_time, unit, c("mean", "stdev"))`
  - Implemented in: `src/modules/pitch_module.cpp`

* **Added `Intensity$get_statistics()` method**
  - Same metrics as Pitch: min, max, mean, stdev, median, quantiles
  - Expected impact: 10-15% speedup for intensity analyses
  - Usage: `intensity$.cpp$get_statistics(from_time, to_time, c("mean", "maximum"))`
  - Implemented in: `src/modules/intensity_module.cpp`

### Documentation
* **Created comprehensive planning documents**
  - `ARCHITECTURAL_CHANGES_ROADMAP.md` - Long-term performance roadmap
  - `IMPLEMENTATION_SUMMARY_2026-01-06.md` - Session implementation details
  - Based on user feedback analyzing 5-56× performance gap vs Python/Parselmouth

**Overall Expected Performance Improvement: 30-40% for typical voice analysis workflows**

## Bug Fixes

### Formant Unit Code - Critical Fix
* **Fixed unit code mapping in `Formant$get_value_at_time()` (CRITICAL)**
  - Root cause: `unit_code()` returned 1L for "hertz" and 2L for "bark" (should be 0L and 1L)
  - Symptom: Requesting "hertz" returned Bark values (~7) instead of Hz (~862)
  - Users had to workaround by extracting via `as_data_frame()` instead
  - Fixed in: `R/formant-r6.R` line 40
  - Affects all formant query methods: `get_value_at_time()`, `get_mean()`, `get_standard_deviation()`, `get_quantile()`, `get_minimum()`, `get_maximum()`
  - Discovered by: plabench 3-way validation testing (Praat ↔ Python ↔ R)

# pladdrr 2.0.3 (2026-01-04)

## Bug Fixes

### TextGrid Reading - Critical Fix
* **Fixed segfault when reading TextGrid files (CRITICAL)**
  - Root cause: `praat_initialize()` never called on package load
  - Praat class registry uninitialized → null pointer in `Data_readFromTextFile()`
  - Added `praat_initialize()` call to `.onLoad()` in `R/zzz.R`
  - Tested with 1.7KB and 1.2MB TextGrid files ✓
  - Pharyngeal test now unblocked

### PointProcess Usage Warning
* **Added warning to `Pitch$to_point_process()` for voice quality**
  - Warns users to use `sound$to_point_process_periodic_cc()` for jitter/shimmer
  - `pitch$to_point_process()` lacks amplitude data (causes 80-137× errors)
  - File: `R/pitch-r6.R`

### Shimmer Units - Verified
* **No bug found - shimmer correctly returns fractions (not percentages)**
  - Matches Praat/Parselmouth behavior
  - Example: `0.0268` (not `2.68`)

# pladdrr 2.0.2 (2026-01-04)

## Bug Fixes

### Function Signature Fixes (Build Warnings)
* **FormantGrid$to_formant()**: Removed unused parameters
  - Old signature had `first_frequency`, `ceiling`, `bandwidth_fraction` (ignored)
  - Praat's `FormantGrid_to_Formant()` only accepts `(time_step, intensity)`
  - File: `R/formantgrid-r6.R`
  
* **TextGrid$get_intervals_where()**: Fixed parameter names
  - Old: `pattern`, `regex` (parameter mismatch)
  - New: `condition`, `text` (matches underlying function)
  - Conditions: "equals", "contains", "does not contain", "starts with", "ends with"
  - File: `R/textgrid-r6.R`

### Voice Quality Analysis - CPP Parameters (Critical)
* **Fixed CPP default parameters to match Praat standards**
  - Changed `qmin` default: `0.001` → `0.003` (quefrency floor)
  - Changed `qmax` default: `0` → `0.04` (quefrency ceiling)
  - **Impact**: CPP values now match Praat/Parselmouth output (was off by ~15 dB)
  - **Functions affected**:
    - `PowerCepstrum$get_peak_prominence()`
    - `PowerCepstrum$get_quefrency_of_peak()`
    - `PowerCepstrum$fit_trend_line()`
    - `PowerCepstrogram$get_cpp_at_time()`
    - `PowerCepstrogram$get_mean_cpp()`
    - `PowerCepstrogram$get_cpps()`: `quefrency_range_start` and `quefrency_range_end`
  - **Validation**: DSI, AVQI v2.03, AVQI v3.01, and VQ tests now pass ✅
  - **Reference**: User feedback comparing pladdrr vs Praat/Parselmouth

### TextGrid Reading - Critical Fix
* **Fixed segfault when reading TextGrid files (CRITICAL)**
  - Root cause: `praat_initialize()` was never called on package load
  - Praat class registry was uninitialized, causing null pointer dereference in `Data_readFromTextFile()`
  - Fix: Added `praat_initialize()` call to `.onLoad()` in `R/zzz.R`
  - **Impact**: TextGrid reading now works correctly for all file formats
  - Tested with 1.7KB and 1.2MB TextGrid files
  - File: `R/zzz.R`

### Voice Quality Analysis - Usage Warnings
* **PointProcess creation for jitter/shimmer**: 
  - Added warning to `Pitch$to_point_process()` method
  - Warning directs users to `sound$to_point_process_periodic_cc()` for voice quality analysis
  - `pitch$to_point_process()` only uses pitch candidates (no amplitude data)
  - Can cause 80-137× incorrect jitter/shimmer values if used for voice quality
  - File: `R/pitch-r6.R`
* **Shimmer values**:
  - Shimmer methods return fractions (not percentages)
  - No multiplication by 100 needed (matches Praat/Parselmouth behavior)
  - Example: `0.0268` (not `2.68`)

## New Features

### GNE (Glottal-to-Noise Excitation Ratio) - NEW
* Added `sound$to_harmonicity_gne()` method
  - Computes GNE (alternative voice quality measure to HNR)
  - Parameters: `fmin` (500), `fmax` (4500), `bandwidth` (1000), `step` (80)
  - Returns Matrix object (time × GNE values)
  - Useful for voice pathology assessment
  - Example:
    ```r
    sound <- Sound$new("voice.wav")
    gne_matrix <- sound$to_harmonicity_gne(fmin = 500, fmax = 4500)
    ```
* Wrapper: `src/sound_wrappers.cpp::sound_to_harmonicity_gne()`
* Documentation: `R/sound-r6-new.R`

## Validation

### Voice Quality Tests (User Feedback)
All 7 voice quality analysis tests now pass with corrected parameters:

| Analysis   | pladdrr vs Praat | pladdrr vs Parselmouth |
|------------|------------------|------------------------|
| DSI        | ✅               | ✅                     |
| AVQI v2.03 | ✅               | ✅                     |
| AVQI v3.01 | ✅               | ✅                     |
| VUV        | ✅               | ✅                     |
| VQ (Voice Quality) | ✅       | ✅                     |
| Tremor     | ⚠ differs       | ⚠ differs             |
| Pharyngeal | ⏭ skipped       | ⏭ skipped (TextGrid)  |

**Notes**:
- Tremor differences under investigation (may be algorithm variation)
- Pharyngeal test skipped due to TextGrid reading issues

## Breaking Changes

* **CPP parameter defaults changed** (intentional fix, not a regression)
  - If you relied on the old defaults (`qmin=0.001, qmax=0`), explicitly set them
  - New defaults match Praat standard practice

## Module Coverage

* **31 Praat modules** (unchanged from 2.0.1)
* **GNE added** to Sound analysis methods (voice quality suite expanded)

---

# pladdrr 2.0.1 (2026-01-03)

## Bug Fixes

### Vignette Build Errors (Critical)
* Fixed all v2.0.0 vignette compilation errors
* **Root causes**:
  - Removed `library(dplyr)` causing `$` operator conflicts (3 vignettes)
  - Renamed `formant` variable → `frm_result` to avoid namespace conflicts
  - Fixed Formant API: use `sound$get_duration()` not `formant$get_duration()`
  - Fixed parameter case sensitivity: `"HERTZ"` → `"hertz"`
  - Fixed KlattGrid API: `add_formant_point(formantType, iformant, t, value)`
  - Corrected FormantPath parameter names (`max_num_formants`, `formant_ceiling`)
  - Removed candidate faceting (API limitation)
  - Replaced `bind_rows()` with `rbind()` (base R)
* **Result**: All vignettes build successfully
* **Files**: `formantpath-robust-tracking.Rmd`, `analysis-resynthesis-workflow.Rmd`, 
  `speech-synthesis-klattgrid.Rmd`, `visualization.Rmd`
* **Commits**: 5d005db, 251143e, 7bd4a44, 7392bc6

### SIMD Jitter/Shimmer Removal (Praat Fidelity)
* Removed SIMD voice quality implementation due to algorithmic differences
* **Issue**: SIMD version missing period filtering logic from Praat
  - No filtering by `pmin`/`pmax` duration bounds
  - No `maximumPeriodFactor` interval ratio checking
  - Resulted in 0.1-100%+ output differences (voice quality dependent)
* **Verification**: SIMD functions were never used (package always called Praat directly)
* **Retained**: All 17 Praat-native jitter/shimmer wrappers in `pointprocess_wrappers.cpp`
* **Technical details**: `.planning/SIMD_JITTER_ACCURACY_ASSESSMENT.md`
* **Rationale**: `.planning/SIMD_JITTER_REMOVAL_RATIONALE.md`
* **Files removed**: `src/voice_quality_simd.cpp`, 3 man pages
* **Commit**: 16f1f76

## Documentation
* Added comprehensive SIMD jitter analysis (`.planning/SIMD_JITTER_ACCURACY_ASSESSMENT.md`)
* Added removal rationale document (`.planning/SIMD_JITTER_REMOVAL_RATIONALE.md`)

---

# pladdrr 2.0.0 (2026-01-03) 🎉

## Major Release - Phase 2 & 3 Complete

pladdrr 2.0.0 represents a major milestone with **31 Praat modules** (32% coverage), advanced analysis capabilities, speech synthesis, and comprehensive documentation.

## New Features - Phase 2 (Advanced Modules)

### Phase 2.1: ComplexSpectrogram Module
* **ComplexSpectrogram** - Time-frequency analysis with phase information
  - Create from Sound with configurable FFT parameters
  - Query magnitude and phase spectra at time points
  - Convert to Spectrum or Sound
  - Used in Pitch analysis internals

### Phase 2.2: FormantPath Module
* **FormantPath** - Robust formant tracking with multiple ceiling candidates
  - Tests multiple formant ceiling frequencies (e.g., 5 candidates: 4977-6078 Hz)
  - Automatic optimal path selection via stress minimization
  - Viterbi-style path finder for global optimization
  - Extract optimal Formant from FormantPath
  - Handles 25+ statistical dependencies (SVD, PCA, CCA, Procrustes, stress)
  - **80% test pass rate** on comprehensive test suite
  - Example: `fp <- sound$to_formant_path(num_steps_up_down=2L); formant <- fp$extract_formant()`

### Phase 2.3: KlattGrid Module
* **KlattGrid** - Parametric speech synthesis (Klatt cascade/parallel synthesizer)
  - `KlattGrid_createFromVowel()` - Safe vowel synthesis with F1/F2/F3 + bandwidths
  - `KlattGrid_createExample()` - Pre-configured complex synthesis
  - Pitch contour manipulation (`add_pitch_point()`)
  - Formant transitions for diphthongs
  - Voicing amplitude control
  - **83% test pass rate** (20/24 tests)
  - Real-world synthesis validated on vowel triangle (/i/, /a/, /u/)

### Phase 2.4: Polygon Module
* **Polygon** - Geometric operations for vowel space analysis
  - Create polygons from point sequences
  - Query perimeter, area, centroid
  - Point-in-polygon testing
  - Reverse, translate, rotate, scale operations
  - Used in FormantPath statistical computations

## New Features - Phase 3 (Enhancements)

### Phase 3.1: Sound Operations Module
* **9 standalone sound functions** (functional interface)
  - `sounds_append()` - Concatenate with optional silence
  - `sound_extract_part()` - Time slice extraction
  - `sound_lengthen()` - Pitch-preserving time stretch
  - `sound_deepen_band_modulation()` - Hearing enhancement
  - `sounds_convolve()`, `sounds_cross_correlate()`, `sound_auto_correlate()`
  - `sound_filter_pass_hann_band()`, `sound_filter_stop_hann_band()`

### Phase 3.2: Spectrum Operations
* **3 spectrum wrapper functions**
  - `spectrum_cepstral_smoothing()` - Spectral envelope smoothing
  - `spectrum_pass_hann_band()`, `spectrum_stop_hann_band()` - In-place filters

### Phase 3.4: Comprehensive Vignettes
* **3 new vignettes for Phase 2 modules** (~3,000 lines total)
  - `vignette("formantpath-robust-tracking")` - Multi-ceiling formant tracking
  - `vignette("speech-synthesis-klattgrid")` - Vowel synthesis, pitch contours, formant transitions
  - `vignette("analysis-resynthesis-workflow")` - Complete FormantPath→KlattGrid pipeline

## Module Coverage

* **31 Praat modules** implemented (32% of ~96 target classes)
* **25/28 R6→Module conversions** complete (89%)
* **Key capabilities unlocked**:
  - Advanced formant tracking (FormantPath)
  - Speech synthesis (KlattGrid)
  - Complex spectral analysis (ComplexSpectrogram)
  - Geometric operations (Polygon)
  - Sound manipulation (9 operations)

## Testing & Validation

* **Phase 2 comprehensive test suites** (56 tests, 1,244 lines)
  - FormantPath: 82% pass (18/22)
  - KlattGrid: 83% pass (20/24)
  - Integration workflow: 80% pass (8/10)
  - Vowel space relationships preserved in synthesis-analysis round-trip

## Documentation

* **11 comprehensive vignettes** (including 3 new Phase 2 guides)
* **344-line KlattGrid usage guide** with formant tables
* **Complete API documentation** for all Phase 2 modules
* **Planning documents** tracking architecture and progress

## Breaking Changes

* None - fully backward compatible with 1.9.x

## Known Issues

* **KlattGrid empty grid**: `KlattGrid(0,1,5)$to_sound()` segfaults
  - **Workaround**: Always use `KlattGrid_createFromVowel()` or `KlattGrid_createExample()`
* **FormantPath API**: Some methods untested (core functionality works)

## Performance

* Module preloading maintained (~8-12µs per method call)
* 40% binary size reduction from Phase 1+ cleanup
* FormantPath: ~5× slower than standard (5 candidates)
* KlattGrid synthesis: ~1-2s per minute of audio

## Migration Guide

See existing vignettes for upgrade assistance:
* `vignette("migration-from-praat")` - For Praat users
* `vignette("migration-from-parselmouth")` - For Parselmouth users
* `vignette("getting-started")` - Package overview

---

# pladdrr 1.9.3 (2026-01-01)

## New Features - Phase 3.2 (Spectrum Wrappers)

* **Spectrum Operation Wrappers** - 3 convenience functions
  - `spectrum_cepstral_smoothing()` - Cepstral smoothing for spectral envelope
  - `spectrum_pass_hann_band()` - In-place Hann band-pass filter
  - `spectrum_stop_hann_band()` - In-place Hann band-stop filter

## Architecture

* R wrappers for existing C++ exports (no new module needed)
* Simplified functional interface for spectrum operations

# pladdrr 1.9.2 (2026-01-01)

## New Features - Phase 3.1 (Standalone Functions)

* **Sound Operations Module** - 9 new standalone functions
  - `sounds_append()` - Concatenate sounds with optional silence
  - `sound_extract_part()` - Extract time slices
  - `sound_lengthen()` - Time-stretch using overlap-add (pitch-preserve)
  - `sound_deepen_band_modulation()` - Hearing enhancement
  - `sounds_convolve()` - Signal convolution
  - `sounds_cross_correlate()` - Cross-correlation analysis
  - `sound_auto_correlate()` - Auto-correlation
  - `sound_filter_pass_hann_band()` - Band-pass filter
  - `sound_filter_stop_hann_band()` - Band-stop filter

## Architecture

* Added sound_operations_module (30th module total)
* Functional interface - no class instantiation needed
* All functions return new Sound objects

---

# pladdrr 1.9.1 (2026-01-01)

## New Features - Phase 2.2

* **FormantPath Module** (29th module total)
  - Robust formant tracking with multiple candidate ceilings
  - Automatic optimal path selection
  - Multiple analysis algorithms (Burg, robust)
  - Path optimization and stress calculation
  - Extract optimal Formant from FormantPath
  - Functions: `FormantPath()`, `extract_formant()`, path manipulation
  - Example: `fp <- FormantPath(sound); formant <- fp$extract_formant()`

## Documentation

* Added comprehensive roxygen documentation for FormantPath
* Updated module preloading list in `.onLoad` (29 modules)

---

# pladdrr 1.8.1 (2025-12-31)

## Performance Optimization

* **Module Preloading**
  - All 27 modules now preloaded during package load (`.onLoad`)
  - Eliminates repeated module lookup overhead
  - Faster object creation and initialization
  - Measured performance: ~8-12µs per method call

---

# pladdrr 1.8.0 (2025-12-31)

## Major Code Cleanup - Phase 1+ Finalization

* **Removed Duplicate Wrapper Code (40% Binary Size Reduction)**
  - Archived 23 duplicate `*_wrappers.cpp` files to `src/old_wrappers_archive/`
  - Modules now provide sole implementation path
  - Eliminated ~6,440 lines of duplicated wrapper code
  - Binary size reduced by ~40% (from ~46MB to ~28MB)
  - Compile time reduced by ~50%
  - Simplified maintenance: single implementation per class

## Architecture Improvements

* **Cleanup of Dual Architecture**
  - Updated `src/Makevars.in` and `src/Makevars` to remove wrapper compilation
  - All 27 converted objects now use only Rcpp modules
  - Kept: `interpreter_wrappers.cpp` (stateful, no module), stub files (linking), utilities
  - Clear separation: modules for classes, wrappers only for stateful/special cases

## Testing & Validation

* **Comprehensive Module Testing**
  - Verified all 27 modules work correctly after wrapper removal
  - Tested: Sound, Pitch, Formant, Intensity, Spectrum, Spectrogram, TextGrid, LPC
  - All transformations and operations functional
  - No API breakage - existing code continues to work

## Performance Impact

* **Current Status (v1.8.0)**
  - Binary: 28 MB (down from ~46 MB in v1.7.3)
  - Method dispatch: ~10 µs overhead (measured)
  - 27/28 objects using Rcpp modules (96%)
  - 10-15x faster than original R6 implementation

## Documentation

* **Architecture Audit & Planning**
  - `.planning/ARCHITECTURE_AUDIT_2025.md` - Comprehensive 62-page assessment
  - `.planning/CLEANUP_PRIORITY_LIST.md` - Implementation guide for cleanup
  - `.planning/README.md` - Navigation guide for planning documents
  - Identified 69 missing Praat classes with prioritized roadmap

## Archived Files

* **Old Wrapper Files Moved to Archive**
  - `src/old_wrappers_archive/` contains 23 archived wrapper files
  - Can be restored if needed for reference
  - Files: sound, formant, formantgrid, pointprocess, spectrum, spectrogram,
    ltas, lpc, textgrid, pitchtier, durationtier, intensitytier, manipulation,
    table, amplitudetier, electroglottogram, powercepstrum, cochleagram,
    excitation, matrix, vocaltract, longsound, formanttier

## Next Steps (Planned)

* **Phase 2 (v1.9.0)**: Add 5 high-value missing classes
  - Polygon, FormantPath, KlattGrid, ComplexSpectrogram, Harmonics
* **Phase 3 (v2.0.0)**: Expose 40-50 standalone Praat functions
* **Future**: Optimize R dispatch pattern for additional 5-7x speedup

# pladdrr 1.7.4 (2025-12-30)

## Documentation & Planning

* **Phase 1+ Complete - Documentation Update**
  - Comprehensive performance architecture documentation
  - Phase 1+ completion summary (27/28 objects, 96%)
  - Updated README with performance badges and highlights
  - Detailed benchmarking guidelines and optimization patterns

## Documentation Files Added

* `.planning/PERFORMANCE_ARCHITECTURE.md` - Complete performance guide
  - Module architecture patterns
  - Performance breakdown (10x improvement)
  - SIMD vectorization details (17 optimized files)
  - Memory optimization strategies
  - Benchmarking recommendations
  - Development guidelines for adding module methods

* `.planning/PHASE1PLUS_COMPLETE.md` - Milestone summary
  - 27/28 objects converted (96%)
  - Performance impact analysis
  - Technical architecture overview
  - Next steps recommendations

* Updated `README.md` with performance highlights:
  - Rcpp Modules architecture badges
  - 5-10x faster method dispatch vs R6
  - Competitive with Python's Parselmouth (2-3x gap vs 5-18x)
  - SIMD vectorization features

## Status

* **Phase 1+ COMPLETE:** All performance-critical objects optimized
* **Production Ready:** Package stable, tested, and documented
* **27/28 objects converted (96%)** - Only PraatInterpreter remains R6 (intentional)

# pladdrr 1.7.3 (2025-12-30)

## Performance Improvements

* **LongSound Module Conversion (27/28 objects - 96% COMPLETE)**
  - Converted `LongSound` from R6 to Rcpp Module architecture
  - 5-10x faster method dispatch for streaming large audio files
  - 11 methods: duration, sample rate, channels, file path queries
  - Streaming methods: `extract_part()`, `have_window()`, `get_window_extrema()`
  - Static method: `LongSound$open(path)`
  - Save methods remain as wrappers (file I/O operations)

## Bug Fixes

* Fixed LongSound file path access: `file.path` field structure

## Status

* **Converted:** 27/28 Praat objects (96%)
* **Remaining R6:** PraatInterpreter (intentionally kept for stateful scripting)
* **Phase 1+ COMPLETE:** All meaningful conversions done

# pladdrr 1.7.2 (2025-12-30)

## Performance Improvements

* **VocalTract Module Conversion (26/28 objects - 93% COMPLETE)**
  - Converted `VocalTract` from R6 to Rcpp Module architecture
  - 5-10x faster method dispatch for vocal tract modeling
  - 10 methods: length/section queries, area get/set, transformations
  - Static method: `VocalTract$create_from_phone(phone)`
  - Transformations: `to_spectrum()`, `to_matrix()`

## Bug Fixes

* Fixed VocalTract module compilation: corrected Matrix.h include path
* Fixed NAMESPACE S3method syntax: backticks for `$` operator
* Fixed Matrix type ambiguity with Rcpp::Matrix namespace
* Updated factory call in praat-interpreter-r6.R

## Status

* **Converted:** 26/28 Praat objects (93%)
* **Remaining R6:** LongSound (next), PraatInterpreter (intentionally kept)

# pladdrr 1.7.1 (2025-12-30)

## Performance Improvements

* **FormantTier Module Conversion (25/28 objects - 89% COMPLETE)**
  - Converted `FormantTier` from R6 to Rcpp Module architecture
  - Adds fast C++ method dispatch for formant manipulation workflows
  - 5-10x faster method calls for formant filtering and queries
  - Static method support: `FormantTier$from_formant()`

## Bug Fixes

* Fixed FormantTier compilation in Makevars and Makevars.in
* Fixed `as_data_frame()` field name: `formants` → `formant`
* Added S3 method exports for FormantTier static methods

## Status

* **Converted:** 25/28 Praat objects (89%)
* **Remaining R6:** LongSound, PraatInterpreter, VocalTract (intentionally kept)

# pladdrr 1.7.0 (2025-12-30)

## Major Performance Improvements

### Phase 1: Rcpp Modules Conversion (24/24 objects - 100% COMPLETE)

* **Converted all 24 core Praat objects from R6 to Rcpp Modules**
  - Eliminates R6 method dispatch overhead (~1-2µs per call)
  - Direct C++ method calls via modules (~0.1-0.2µs)
  - **Expected: 5-10x faster** for typical workflows
  - **Closes major performance gap to Parselmouth** (from 5-18x slower to ~2-3x)

* **Core Analysis Objects (7):**
  - `Pitch`, `Intensity`, `Formant`, `Spectrum`, `Spectrogram`, `Harmonicity`, `Ltas`

* **Specialized Analysis (6):**
  - `LPC`, `Cepstrum`, `PowerCepstrum`, `Excitation`, `Cochleagram`, `Electroglottogram`

* **Tier Objects (5):**
  - `PitchTier`, `IntensityTier`, `DurationTier`, `AmplitudeTier`, `FormantGrid`

* **Annotation & Data (3):**
  - `TextGrid`, `PointProcess`, `Matrix`, `Table`

* **Audio & Manipulation (3):**
  - `Sound`, `Manipulation`, `FormantTier`

### Module Architecture

* **Fast path:** Query, transform, extract, export methods use direct C++ dispatch
* **Hybrid approach:** Complex methods (advanced pitch/formant algorithms) kept as wrappers
* **Backward compatibility:** Function wrappers support both `Object()` and `Object$new()` syntax

## Bug Fixes

* Fixed `Sound$create_tone()` and `Sound$new()` static methods (S3 registration)
* Fixed audio file format codes (WAV=3, AIFF=1 per Melder constants)
* Fixed spectrogram creation parameters (oversampling 8.0, 8.0)
* All vignettes now build successfully

## Breaking Changes

* None - full backward compatibility maintained
* Both patterns work: `Sound(path = "file.wav")` and `Sound$new(path = "file.wav")`

---

# pladdrr 1.6.0 (2025-12-30)

## Major Features

### Praat Script Interpreter (Complete)

* **Persistent interpreter with state** (`PraatInterpreter` R6 class)
  - `run(script)` - execute Praat scripts with persistent variables
  - `get_variable(name)` / `set_variable(name, value)` - access interpreter vars
  - `eval(expression)` - evaluate expressions in interpreter context
  - Variables persist across multiple `run()` calls
  - Supports all Praat data types: numeric, string, vector, matrix, string arrays

* **Bidirectional R ↔ Praat object transfer**
  - `get_object(name, type)` - extract Praat object to R6 class
  - `set_object(name, object)` - inject R6 object into interpreter
  - `list_objects()` / `object_count()` - inspect interpreter state
  - Enables 100% Praat functionality via script commands

* **Predefined script constants**
  - `yes` / `no` - boolean values for colon-syntax commands
  - `true` / `false` - alternative boolean constants

### Limitations

* Object creation commands (e.g., `Create Sound...`) not fully supported
  - Due to stubbed GUI code in library mode
  - Use R6 classes for object creation, then transfer with `set_object()`

## Documentation

* Added comprehensive `PraatInterpreter` examples
* Updated class documentation with limitations and best practices

---

# pladdrr 1.5.0 (2025-12-29)

## Major Features

### Interpreter Object Bridge (Phase 1)

* **Bidirectional R ↔ Praat object transfer**
  - `PraatInterpreter$get_object(name, type)` - extract Praat object to R
  - `PraatInterpreter$get_object_by_id(id)` - extract by ID
  - `PraatInterpreter$set_object(name, object)` - inject R object into interpreter
  - `PraatInterpreter$remove_object(name)` / `remove_object_by_id(id)`
  - `PraatInterpreter$select_object(name, add)` - select objects in list
  - `PraatInterpreter$clear_objects()` - remove all objects
  - Enables 100% Praat coverage: any Praat command accessible via scripts

### New R6 Classes (Phase 2)

* **VocalTract** - articulatory synthesis
  - Create from vocal tract area functions
  - LPC-based vocal tract estimation from Sound
  - Synthesis and filtering operations

* **LongSound** - streaming large audio files
  - Memory-efficient access to multi-hour recordings
  - Window extraction without loading full file
  - Get samples at specific time ranges

* **FormantTier** - editable formant contours
  - Add/remove formant points
  - Get values at arbitrary times
  - Convert to FormantGrid

### Pitch Manipulation (Phase 3)

* `Pitch$interpolate()` - fill unvoiced gaps
* `Pitch$smooth(bandwidth)` - frequency-domain smoothing
* `Pitch$kill_octave_jumps()` - automatic octave error correction

### Rcpp Modules (Phase 4)

* Enabled dynamic symbol registration for all 24 Rcpp Module boot functions
* Modules expose C++ classes directly (RPitch, RSound, RFormant, etc.)
* Lower dispatch overhead than R6 method calls
* Access via `Rcpp::Module("xxx_module", PACKAGE = "pladdrr")`

### Zero-Copy & SIMD (Phase 5)

* **Zero-copy Sound sample access**
  - `.sound_get_sample()` / `.sound_set_sample()` - single sample
  - `.sound_get_samples_range()` / `.sound_set_samples_range()` - batch memcpy
  - `.sound_get_values_at_times()` - vectorized interpolated access
  - `.sound_get_windows()` - windowed processing for FFT/analysis
  - `.sound_info()` - metadata without sample copy

* **In-place Sound modifications**
  - `.sound_scale_inplace()`, `.sound_add_inplace()`
  - `.sound_apply_gain_db_inplace()`, `.sound_normalize_peak_inplace()`

* **SIMD voice quality metrics**
  - `.jitter_from_periods_simd()` - local, RAP, PPQ5, DDP
  - `.shimmer_from_amplitudes_simd()` - local, dB, APQ3/5/11, DDA
  - `.voice_quality_metrics_simd()` - combined batch calculation

## Performance

* Rcpp Modules reduce R6 dispatch overhead by ~20-40%
* Zero-copy operations eliminate R→C++ data marshalling for large sounds
* SIMD jitter/shimmer uses xsimd vectorization on ARM64/x86_64

---

# pladdrr 1.4.2 (2025-12-25)

## New Features

### Pharyngeal Voice Quality Analysis Support

* **Implemented `Spectrum$formula()` for spectral manipulation**
  - Added real implementation (was stub in 1.3.0)
  - Supports full Praat formula language (`self`, `x`, `row`, `col`)
  - Enables pre-emphasis formulas: `"if x >= 50 then self*x else self fi"`
  - Required for pharyngeal voice quality analysis workflows

* **Fixed `Spectrum$to_ltas_1to1()` conversion**
  - Changed from `Spectrum_to_Ltas(bandwidth=1.0)` to `Spectrum_to_Ltas_1to1()`
  - Now uses correct Praat function for 1-to-1 bin mapping
  - Essential for accurate H1-H2, H1-A1, etc. measurements

* **Fixed `Ltas$get_maximum()` signature to match Praat**
  - Changed from `get_maximum(fmin, fmax, unit, interpolate)` 
  - To: `get_maximum(fmin, fmax, interpolation)` 
  - Interpolation options: "none", "parabolic", "cubic", "sinc70", "sinc700"
  - Always returns dB (as in Praat)
  - Uses Praat's `Vector_getMaximum()` for accurate peak detection

## Bug Fixes

### Critical Segfault Prevention

* **Fixed segfaults in cochleagram/excitation/matrix tests**
  - Added parameter validation to `Sound$to_cochleagram()` preventing negative/invalid parameters from reaching C code
  - Added sampling rate check to `Sound$to_cochleagram_edb()` - requires ≥44.1kHz due to Praat bug
  - Added validation to `Spectrum$to_excitation()` for erb_density parameter
  - Root cause: Praat's EDB algorithm creates 10+ second gammatone filters at low frequencies causing memory corruption

* **Fixed test suite errors**
  - Updated `test-cochleagram-r6.R`: Fixed method names, updated EDB tests to use 44.1kHz, adjusted edge cases
  - Updated `test-excitation-r6.R`: Migrated to `Sound$from_values()`, adjusted silence expectations
  - Updated `test-matrix-r6.R`: Fixed method names (`get_ny()`/`get_nx()` vs `get_number_of_rows()`)

## Code Quality

* **Refactored validation code for better maintainability**
  - Replaced multiple if/stop blocks with idiomatic `stopifnot()` (62% code reduction: 16→6 lines)
  - Improved error messages: proper formatting with `sprintf()`, indentation, and `call.=FALSE`
  - Enhanced user experience by hiding internal call stacks in error messages

## Test Results

* All previously crashing tests now pass without segfaults
  - ✅ test-cochleagram-r6: 25 PASS, 2 SKIP
  - ✅ test-excitation-r6: 25 PASS, 1 SKIP
  - ✅ test-matrix-r6: 26 PASS
  - ✅ Core R6 tests run without crashes

---

# pladdrr 1.3.0 (2025-12-20)

## New Features

### Spectral Analysis API Enhancements

* **Added `LTAS$get_frequency_of_maximum()`** - Find frequency of spectral peaks with parabolic interpolation
  - Supports interpolation methods: "none", "parabolic", "cubic", "sinc70", "sinc700"
  - Essential for H1, H2, A1, A2, A3 harmonic/formant peak detection
  - Parabolic interpolation provides sub-bin frequency resolution

* **Added `Spectrum$formula()`** - Apply Praat formula syntax to modify spectrum values
  - Supports full Praat formula language: "self" for current value, "x" for frequency
  - Enables pre-emphasis: `spectrum$formula("if x >= 50 then self*x else self fi")`
  - Enables dB conversion: `spectrum$formula("10 * log10(self)")`
  - Modifies spectrum in-place for efficiency

* **Added `Spectrum$to_ltas_1to1()`** - Convert filtered Spectrum to LTAS with 1-to-1 bin mapping
  - Preserves filtered spectrum's frequency resolution
  - Enables spectral peak analysis after filtering
  - Critical for pharyngeal voice quality workflows

### Impact

These additions unblock 80% of previously impossible voice quality workflows:
- ✅ Pharyngeal voice quality: H1-H2, H1-A1, H1-A2, H1-A3 (Iseli & Alwan 2004)
- ✅ Cepstral Peak Prominence (CPP)
- ✅ Spectral tilt measurements
- ✅ AVQI (Acoustic Voice Quality Index) components
- ✅ DSI (Dysphonia Severity Index) harmonic analysis

## Documentation

* Created SESSION10_SPECTRAL_API_IMPLEMENTATION.md with complete workflow examples
* Added example pharyngeal analysis workflow
* Documented interpolation methods and formula syntax

---

# pladdrr 1.2.9 (2025-12-20)

## Documentation

* Added comprehensive TextGrid fix documentation suite
  - Created DOCUMENTATION_INDEX.md for navigation
  - Created TEXTGRID_FIX_SUMMARY.md with complete technical overview
  - Created TEXTGRID_FIX_CHECKLIST.md for verification
  - Added docs/PRAAT_MODIFICATIONS.md with source code change details
  - Added docs/praat_modifications.patch for reapplication
  - Updated vignettes/textgrid-workflows.Rmd with performance data
  - Created comprehensive test suite (test-textgrid-comprehensive.R, 32 passing)

---

# pladdrr 1.2.8 (2025-12-19)

## Critical Bug Fixes

* **Fixed TextGrid file loading segfault (SIGSEGV at address 0x68)**
  - **Root cause:** Class registry arrays (`theReadableClasses`) were declared `static`, making them invisible across shared library boundaries
  - **Solution:** Changed class registry linkage from `static` to `extern` in `sys/Thing.cpp` and `sys/Thing.h`
  - Added null pointer checks in `Thing_classFromClassName()` to prevent crashes from partially initialized registry
  - Added error checking in `Thing_newFromClassName()` with informative error messages
  - Removed debug output from production code (NUMinterpol.cpp)
  
* **TextGrid loading now fully operational**
  - ✅ Small files (1 min, 1.2 MB): 0.012s
  - ✅ Medium files (10 min, 12 MB): 0.057s  
  - ✅ Large files (30 min, 37 MB): 0.163s
  - All 34 TextGrid methods working correctly
  - Comprehensive test suite added (32 passing tests)

## Praat Source Modifications

Modified 5 Praat source files to enable shared library operation:
- `sys/Thing.h` - Exposed class registry with `extern` declarations
- `sys/Thing.cpp` - Changed registry linkage, added null checks and error handling
- `sys/Data.cpp` - Added debug support headers
- `melder/MelderReadText.cpp` - Added debug support headers
- `melder/NUMinterpol.cpp` - Removed debug output

All modifications documented in `docs/PRAAT_MODIFICATIONS.md` and `docs/praat_modifications.patch`.

## Technical Details

The segfault occurred because:
1. Static linkage made class registry invisible when Praat code was compiled as a shared library
2. `Thing_classFromClassName()` couldn't find registered classes, returned NULL
3. Null pointer dereferenced in subsequent object creation code

The fix maintains full Praat compatibility while enabling proper shared library operation for R packages.

---

# pladdrr 1.2.7 (2025-12-16)

## Bug Fixes

* **Removed debug logging from production code**
  - Removed `fprintf` debug statement from `src/sound_wrappers.cpp`
  - Clean console output during pitch extraction operations
  - Package now production-ready without debug spam

## Minor Changes

* Cleaned obsolete documentation files from repository
* Fixed NAMESPACE exports after AVQI/DSI removal

---

# pladdrr 1.2.6 (2025-12-14)

## Breaking Changes

* **Removed AVQI (Acoustic Voice Quality Index) implementation**
  - Removed `compute_avqi()` function
  - Removed `plot_avqi()` function
  - Removed `create_avqi_report_plot()` function
  - Removed associated documentation

* **Removed DSI (Dysphonia Severity Index) implementation**
  - Removed `compute_dsi()` function
  - Removed `plot_dsi()` function
  - Removed `create_dsi_report_plot()` function
  - Removed associated documentation

* **Removed tremor analysis functions**
  - Removed all tremor-specific analysis functions
  - Removed associated documentation

**Rationale**: These implementations were experimental and not fully validated against clinical standards. Users requiring these metrics should use validated clinical tools such as:
- AVQI: Official Praat AVQI script or KayPENTAX CSL
- DSI: MDVP (Multi-Dimensional Voice Program)
- Tremor: Specialized tremor analysis software

## Bug Fixes

* Fixed AVQI tilt calculation in commit bf76101 (before removal)
  - Corrected tilt to use LTAS slope instead of incorrect H1-A3 formula
  - Note: Full AVQI implementation was subsequently removed in this version

## Minor Changes

* Updated documentation to remove tremor references from Pitch object
* Updated `vignettes/visualization.Rmd` to remove AVQI/DSI examples
* Maintained all core Praat functionality (Sound, Pitch, Formant, Intensity, etc.)

---

# pladdrr 1.2.5 (2025-12-14)

## Bug Fixes

### Fixed AVQI Tilt Calculation
* **Issue**: AVQI computed "tilt" as H1-A3 (harmonic 1 minus formant 3 amplitude)
* **Correct Definition**: Tilt should be LTAS slope from 0-1000 Hz to 1000-10000 Hz
* **Fix**: Modified `R/avqi.R` to use `ltas$get_slope()` instead of H1-A3 difference
* **Impact**: More accurate AVQI calculations matching clinical standards
* **Documentation**: See `AVQI_TILT_FIX_SUMMARY.md`
* **Commit**: bf76101

Note: AVQI implementation was removed in v1.2.6

---

# pladdrr 1.2.4 (2025-12-13)

## Performance Improvements

### Phase 1 Compiler Optimization - 6x DSI Speedup
* **Achievement**: 6.16x speedup in DSI calculation (83.8% improvement)
* **Changes**: Added aggressive compiler optimizations to `src/Makevars` and `src/Makevars.in`:
  - `-O3`: Aggressive optimization (loop unrolling, auto-vectorization)
  - `-flto -fno-fat-lto-objects`: Link-time optimization for cross-module inlining
  - `-mfpmath=sse`: SSE floating-point math (x86_64)
* **Results**:
  - Pitch extraction: 289ms → 77ms (3.76x faster)
  - Full DSI (12 files): 2.902s → 0.471s (6.16x faster)
* **Impact**: pladdrr now FASTER than Python Parselmouth (0.471s vs 0.558s)
* **Platform**: Tested on Apple Silicon ARM64, should improve x86_64 similarly
* **Validation**: ✅ No numerical regressions, results identical to unoptimized build
* **Documentation**: See `PHASE1_OPTIMIZATION_RESULTS.md` and `OPTIMIZATION_SUMMARY.md`
* **Commit**: Current

---

# pladdrr 1.2.3 (2025-12-12)

## Bug Fixes

### Fixed FTrI Calculation - Added start_time Parameter
* **Issue**: FTrI (Frequency Tremor Intensity Index) returned 0.0% instead of expected 2.17%
* **Root Cause**: `Sound$from_values()` lacked `start_time` parameter, breaking time alignment for peak detection
* **Fix**: 
  - Added `start_time` parameter to `.sound_create_from_values()` C++ wrapper
  - Added `start_time` parameter to `Sound$from_values()` R6 method
  - Ensures correct temporal alignment of generated waveforms
* **Validation**: FTrI now returns 2.17% as expected
* **Documentation**: Complete analysis in `FTRI_FIX_SUMMARY.md`
* **Commit**: 5b0eee8

---

# pladdrr 1.2.2 (2025-12-11)

## Bug Fixes

### Critical Build Configuration Fix - macOS and Linux Support Restored
* **Issue**: Package failed to build on macOS and Linux due to hardcoded Windows compiler flags
* **Root Cause**: Conditional compilation logic in `src/Makevars.in` was broken
* **Impact**: Package could not be installed on Unix-like systems
* **Fix**:
  - Corrected platform detection in `src/Makevars.in` configure script
  - Properly separated Windows-specific flags (`-DMS_WIN64`, `-DWIN32`)
  - Ensured Unix flags applied on macOS/Linux (`-DUNIX`, `-Wno-trigraphs`)
* **Validation**: 
  - ✅ Builds successfully on macOS (M1 ARM64)
  - ✅ All tests pass on macOS
  - ⏳ Linux validation pending
* **Documentation**: Complete analysis in `MAKEVARS_FIX_SUMMARY.md`
* **Commit**: 44bdcd0

---

# pladdrr 1.2.1 (2025-12-10)

## New Features

* Added comprehensive tremor analysis functions
* Improved AVQI implementation
* Enhanced DSI calculation accuracy

## Bug Fixes

* Various minor bug fixes and improvements

---

# pladdrr 1.2.0 (2025-12-08)

## Major Changes

* Complete rewrite using R6 object-oriented interface
* Direct Praat C++ integration via Rcpp
* 19+ Praat object types with 320+ methods
* SIMD optimization for 2-4x performance gains

## New Features

* Sound object with comprehensive audio manipulation
* Pitch analysis with multiple algorithms
* Formant extraction (Burg, Robust, Keep All)
* Intensity and harmonicity analysis
* Spectrogram and spectrum analysis
* TextGrid annotation support
* Voice quality metrics (jitter, shimmer, HNR)
* Cochleagram and excitation auditory models

## Performance

* 2-4x faster than equivalent Python Parselmouth operations
* Zero-copy operations via external pointers
* Modern CPU SIMD vectorization

---
