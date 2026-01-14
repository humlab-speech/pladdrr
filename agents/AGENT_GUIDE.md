# pladdrr Agent Guide

**Version:** 4.0.4 (2026-01-13)
**Purpose:** Reference for LLM agents reimplementing Praat functionality via pladdrr

---

## Quick Start for Agents

This guide provides the **complete API reference** for pladdrr, an R package that provides direct access to Praat C++ functionality. When reimplementing Praat code in R:

1. **Object Creation**: Use function constructors (not R6 classes): `Sound()`, `Pitch()`, etc.
2. **Method Calls**: Use `$` syntax: `sound$to_pitch()`, `pitch$get_mean()`
3. **Units**: Specify as strings: `"hertz"`, `"bark"`, `"db"` (converted internally to codes)
4. **Class Names**: Use clean names for `inherits()` checks: `Formant`, `Pitch`, `Intensity` (not internal `*_constructor` names)
5. **Batch Operations**: Use batch query functions when extracting multiple values
6. **Properties**: Fast access via `.cpp$property` or backward-compatible `get_property()` methods

---

## Architecture Overview (v4.0.3 - 3-Tier Performance API + data.table)

```
┌─────────────────────────────────────────────────────────────┐
│ R User Code                                                  │
│   sound <- Sound("audio.wav")                               │
│   pitch <- sound$to_pitch_cc()                              │
└─────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌───────────────┐  ┌───────────────┐  ┌───────────────────────┐
│ TIER 3        │  │ TIER 2        │  │ TIER 1                │
│ (Fastest)     │  │ (Fast)        │  │ (Standard)            │
│               │  │               │  │                       │
│ *_batch()     │  │ *_direct()    │  │ object$method()       │
│ *_parallel()  │  │ to_*_direct() │  │                       │
│ 5-20x faster  │  │ 2-3x faster   │  │ Full features         │
└───────────────┘  └───────────────┘  └───────────────────────┘
        │                   │                   │
        └───────────────────┼───────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ Rcpp Module Layer (src/modules/*.cpp)                       │
│   - 33 C++ module classes: RSound, RPitch, etc.            │
│   - XPtr<structPitch> wrapping Praat objects               │
│   - Batch queries: batch_queries.cpp (vectorized)          │
│   - Parallel processing: R/parallel-batch.R (multi-core)   │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ Praat C++ Layer (src/praat.github.io/)                      │
│   - 1,254 headers from Praat codebase                      │
│   - Direct calls: Sound_to_Pitch(), Formant_getValueAtTime()│
│   - LTO optimization: -flto for cross-file inlining        │
└─────────────────────────────────────────────────────────────┘
```

**Performance Tiers (v4.0.3):**
| Tier | API | Speedup | Use Case |
|------|-----|---------|----------|
| **Tier 1 (Standard)** | `sound$to_pitch()` | 1x baseline | Interactive, <10 files |
| **Tier 2 (Direct)** | `to_pitch_direct()` | 2-3x | Loops, 10-100 files |
| **Tier 3 (Batch)** | `sound_to_pitch_batch()` | 5-10x | Production, >100 files |

**See comprehensive guides:**
- `vignettes/performance-optimization.Rmd` - Complete 3-tier API guide
- `vignettes/articles/batch-operations-guide.Rmd` - High-performance batch processing
- `vignettes/articles/migration-guide.Rmd` - v3.0 breaking changes guide
- `vignettes/articles/naming-conventions.Rmd` - API organization and patterns

### Data Flow Example: `sound$to_pitch_cc()`

**NEW: Module-Based Architecture (v2.0+)**

1. User calls: `pitch <- sound$to_pitch_cc(75, 600)`
2. R wrapper (function factory) extracts `.cpp` module object
3. **Direct C++ call:** `cpp_obj$to_pitch_cc_ptr(75, 600)` (NO R6 lookup)
4. C++ module calls `Sound_to_Pitch_cc()` (Praat function)
5. Result wrapped in `XPtr<structPitch>` with custom deleter
6. R wrapper creates new `Pitch()` from pointer via factory function
7. Returns: `structure(list(.xptr = ptr, .cpp = module, ...), class = "Pitch")`

**Key Performance Improvement:** Direct module calls eliminate R6 method dispatch overhead (2-3x faster).

### Object Structure (Function Factory Pattern)

**All 30 core objects (except PraatInterpreter) use this pattern:**

For detailed technical rationale on the module vs R6 architecture decision, see `.planning/REMAINING_R6_CLASSES.md` (completion status) or the comprehensive reference document `docs/MODULE_VS_R6_DESIGN.md` (if available locally - not in git).

```r
# MODERN: Function factory (v2.0+)
Pitch <- function(.xptr = NULL) {
  pitch_mod <- get_module("pitch_module")
  cpp_obj <- pitch_mod$RPitch$new(.xptr)
  
  structure(list(
    .xptr = .xptr,                              # External pointer
    .cpp = cpp_obj,                              # C++ module object
    get_mean = function(...) cpp_obj$get_mean(...),  # Direct C++ call
    # ... all methods
  ), class = c("Pitch", "PraatObject"))
}

# OLD: R6::R6Class (deprecated, only PraatInterpreter & legacy)
# DON'T USE - Much slower due to environment traversal
```

**Converted Objects (30/31):** Sound, Pitch, Formant, Intensity, Spectrum, Spectrogram, Harmonicity, PointProcess, TextGrid, Ltas, PowerCepstrum, PowerCepstrogram, LPC, Cochleagram, Excitation, Cepstrum, Electroglottogram, Matrix, Table, VocalTract, PitchTier, FormantTier, FormantGrid, IntensityTier, AmplitudeTier, DurationTier, Manipulation, LongSound, KlattGrid, FormantPath, ComplexSpectrogram, Polygon

**Intentionally R6 (1/31):** PraatInterpreter (requires persistent mutable state for script execution)

---

## Object Types (33 modules)

**Update v2.1.0:** Added `Interpreter` module for persistent Praat script execution.

### Audio Analysis

| Type | R Constructor | Creation Method |
|------|---------------|-----------------|
| `Sound` | `Sound("file.wav")` | Direct from file |
| `Pitch` | `sound$to_pitch()` | From Sound |
| `Formant` | `sound$to_formant_burg()` | From Sound |
| `Intensity` | `sound$to_intensity()` | From Sound |
| `Harmonicity` | `sound$to_harmonicity_cc()` | From Sound |
| `Spectrum` | `sound$to_spectrum()` | From Sound |
| `Spectrogram` | `sound$to_spectrogram()` | From Sound |
| `Ltas` | `sound$to_ltas()` | From Sound |
| `PointProcess` | `sound$to_point_process_periodic_cc()` | From Sound |

### Editable Tiers

| Type | Creation Method |
|------|-----------------|
| `PitchTier` | `pitch$down_to_pitch_tier()` |
| `DurationTier` | `DurationTier$create(tmin, tmax)` |
| `IntensityTier` | `IntensityTier$create(tmin, tmax)` |
| `AmplitudeTier` | `AmplitudeTier$create(tmin, tmax)` |
| `FormantTier` | `formant$down_to_formant_tier()` |
| `FormantGrid` | `formant$to_formantgrid()` |

### Advanced Analysis

| Type | Creation Method |
|------|-----------------|
| `Cepstrum` | `spectrum$to_cepstrum()` |
| `PowerCepstrum` | `spectrum$to_power_cepstrum()` |
| `Cochleagram` | `sound$to_cochleagram()` |
| `Excitation` | `cochleagram$to_excitation()` |
| `LPC` | `sound$to_lpc_burg()` |
| `FormantPath` | `sound$to_formant_path()` |

### Manipulation

| Type | Creation Method |
|------|-----------------|
| `Manipulation` | `sound$to_manipulation()` |
| `KlattGrid` | `KlattGrid$create()` |
| `VocalTract` | `VocalTract$create()` |

### Data Structures

| Type | Creation Method |
|------|-----------------|
| `TextGrid` | `TextGrid("file.TextGrid")` |
| `Table` | `formant$down_to_table()` |
| `Matrix` | `Matrix$create()` |
| `LongSound` | `LongSound("large_file.wav")` |

### Interpreter (NEW in v2.1.0)

| Type | Creation Method | Purpose |
|------|-----------------|---------|
| `PraatInterpreter` | `PraatInterpreter$new()` | Persistent Praat script interpreter with variable state |

**NOTE:** PraatInterpreter is the **only object that uses R6::R6Class** (1/31). All other 30 objects use the high-performance module pattern. This is intentional - the interpreter requires persistent mutable state, reference semantics, and method chaining (`self` reference). See `.planning/REMAINING_R6_CLASSES.md` for design rationale.

**Key Methods:**
- `run(script)` - Execute Praat script
- `eval_numeric(expr)` - Evaluate expression to number
- `eval_string(expr)` - Evaluate expression to string
- `eval_vector(expr)` - Evaluate to numeric vector
- `get_variable(name)` - Get interpreter variable
- `set_variable(name, value)` - Set interpreter variable

**Example:**
```r
interp <- PraatInterpreter$new()
interp$run('x = 42')
interp$run('y = x * 2')
result <- interp$eval_numeric('y')  # 84
```

---

## Unit Code Reference

### Frequency Units (Pitch, Formant)

| R String | Code | Praat Enum |
|----------|------|------------|
| `"hertz"` / `"hz"` | `0` | `kPitch_unit::HERTZ` |
| `"semitones"` | `1` | `kPitch_unit::SEMITONES` |
| `"mel"` | `2` | `kPitch_unit::MEL` |
| `"erb"` | `3` | `kPitch_unit::ERB` |
| `"loghertz"` | `4` | `kPitch_unit::LOG_HERTZ` |

### Formant Units

| R String | Code | Praat Enum |
|----------|------|------------|
| `"hertz"` | `0` | `kFormant_unit::HERTZ` |
| `"bark"` | `1` | `kFormant_unit::BARK` |

### Intensity Units

| R String | Code | Praat Enum |
|----------|------|------------|
| `"db"` | `0` | dB SPL |
| `"energy"` | `1` | Energy (Pa²·s) |
| `"sones"` | `2` | Sones |

### LTAS Units (FIXED in v4.0.4)

**BREAKING CHANGE:** Prior to v4.0.4, LTAS unit codes were incorrectly mapped. The fix aligns with Praat's `Ltas.cpp:44-60`.

| R String | Code | Praat Behavior |
|----------|------|----------------|
| `"db"` | `0` | Passthrough (no conversion) |
| `"energy"` | `1` | `10*log10(ratio)` → dB |
| `"sones"` | `2` | `10*log2(ratio)` → dB |

**Migration note:** If you used `unit="sones"` as a workaround for getting correct dB values, switch to `unit="energy"` or `unit="dB"`.

```r
# CORRECT (v4.0.4+):
slope <- ltas$get_slope(0, 1000, 1000, 10000, unit = "energy")  # Returns dB

# WRONG (pre-v4.0.4 workaround - no longer needed):
slope <- ltas$get_slope(0, 1000, 1000, 10000, unit = "sones")   # Was accidental fix
```

### Interpolation Methods

**Updated v2.1.1:** Fixed intensity interpolation codes.

| Code | Method | Use Case |
|------|--------|----------|
| `0` | Nearest | Fast, no smoothing |
| `1` | Linear | Moderate smoothing |
| `2` | Cubic | Smooth curves (DEFAULT for intensity) |
| `3` | Sinc70 | High-quality, 70-point window |
| `4` | Sinc700 | Highest quality, 700-point window |

**String API (recommended):**
```r
# Use string names - automatically converted to codes
intensity$get_value_at_time(time = 1.0, interpolate = "cubic")
get_intensity_at_times(intensity, times, interpolate = "sinc70")
```

---

## Common Patterns

### Pattern 1: Sound → Analysis Object

```r
# Load audio
sound <- Sound("audio.wav")

# Extract analysis objects (all return new objects)
pitch <- sound$to_pitch(
  time_step = 0.0,              # 0 = auto (0.75 / pitch_floor)
  pitch_floor = 75.0,           # Hz
  pitch_ceiling = 600.0         # Hz
)

formant <- sound$to_formant_burg(
  time_step = 0.0,              # 0 = auto
  max_number_of_formants = 5,   # Usually 5 for adults
  maximum_formant = 5500.0,     # Hz (5500 for female, 5000 for male)
  window_length = 0.025,        # seconds
  pre_emphasis_from = 50.0      # Hz
)

intensity <- sound$to_intensity(
  minimum_pitch = 100.0,        # Hz
  time_step = 0.0,              # 0 = auto
  subtract_mean = TRUE
)
```

### Pattern 2: Query Values at Time

```r
# Point queries (single time point)
f0 <- pitch$get_value_at_time(time = 1.0, unit = "hertz")
f1 <- formant$get_value_at_time(formant_number = 1, time = 1.0, unit = "hertz")
f2 <- formant$get_value_at_time(formant_number = 2, time = 1.0, unit = "hertz")
db <- intensity$get_value_at_time(time = 1.0)

# Range queries (time range, 0,0 = entire duration)
mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")
sd_f0 <- pitch$get_standard_deviation(from_time = 0, to_time = 0, unit = "hertz")
min_f0 <- pitch$get_minimum(from_time = 1.0, to_time = 2.0, unit = "hertz")
```

### Pattern 2b: Batch Queries (v2.0.9+)

**Performance:** 5-10x faster than loops by reducing R↔C++ boundary crossings.

```r
# Extract formants F1-F4 at multiple time points (1 call instead of 200)
times <- seq(0.5, 2.5, by = 0.01)  # 200 time points
formants <- get_formants_at_times(formant, times, formant_numbers = 1:4)
# Returns: list(F1 = ..., F2 = ..., F3 = ..., F4 = ...)

# Extract pitch contour (1 call instead of 200)
f0_values <- get_pitch_at_times(pitch, times, unit = "hertz", interpolate = TRUE)

# Extract intensity contour (1 call instead of 200)
db_values <- get_intensity_at_times(intensity, times, interpolate = "cubic")

# Get all PointProcess times at once (1 call instead of n)
all_times <- get_pointprocess_times(pointprocess)

# Get all inter-point intervals (for jitter analysis)
intervals <- get_pointprocess_intervals(pointprocess)
```

**Key batch query functions:**
- `get_formants_at_times(formant, times, formant_numbers = 1:4, unit = "hertz")` - 10-20x faster
- `get_formant_bandwidths_at_times(formant, times, formant_numbers, unit)` - 10-20x faster
- `get_pitch_at_times(pitch, times, unit = "hertz", interpolate = TRUE)` - 5-10x faster
- `get_pitch_strengths_at_times(pitch, times, unit, interpolate)` - 5-10x faster
- `get_intensity_at_times(intensity, times, interpolate = "cubic")` - 5-10x faster
- `get_pointprocess_times(pointprocess)` - All times in one call
- `get_pointprocess_intervals(pointprocess)` - All intervals in one call
- `get_pointprocess_nearest_indices(pointprocess, times)` - Vectorized nearest point lookup

**Deprecated functions (v2.4.0):**
The following functions are deprecated and will be removed in v3.0.0. Use the recommended alternatives:
- `pitch_get_values_at_times()` → use `get_pitch_at_times()` instead
- `formant_get_values_at_times()` → use `get_formants_at_times()` instead
- `intensity_get_values_at_times()` → use `get_intensity_at_times()` instead

See `MIGRATION_GUIDE.md` for details.

### Pattern 2c: Batch Statistics (NEW in v2.2.1)

**Performance:** 10-50x faster than loops for multi-interval statistics.

When you need statistics (min, max, mean, stdev, quartiles) over **multiple time intervals**, use batch statistics functions:

```r
# Define 100 time intervals
from_times <- seq(0, 9, length.out = 100)
to_times <- from_times + 0.1
metrics <- c("min", "max", "mean", "stdev", "q25", "q75")

# SLOW: Loop with repeated R↔C++ boundary crossings (600 calls)
for (i in 1:100) {
  min_val <- pitch$get_minimum(from_times[i], to_times[i], "hertz")
  max_val <- pitch$get_maximum(from_times[i], to_times[i], "hertz")
  # ... 4 more calls per interval
}

# FAST: Single C++ call returns 100x6 matrix (1 call)
stats <- pitch_get_statistics_batch(
  pitch$.xptr,
  from_times,
  to_times,
  metrics,
  unit = 0L  # 0=Hertz
)
# Returns: matrix[100 rows, 6 cols] with column names from metrics
```

**Batch statistics functions:**
- `pitch_get_statistics_batch(pitch_xptr, from_times, to_times, metrics, unit)`
  - Metrics: `"min"`, `"max"`, `"mean"`, `"stdev"`, `"q25"`, `"q50"`, `"q75"`, `"count_voiced"`

### Pattern 2d: Fast CPPS API (NEW in v2.2.1 - Module-Based)

**PowerCepstrogram converted to modules in v2.2.1** for 1.5-2x speedup in AVQI v3.01. By v2.2.3, all 30 analysis objects use modules.

For voice quality analysis, use the module-based API (now default) or fast helper functions:

```r
# STANDARD API (v2.2.1+): Now uses modules directly (1.5-2x faster than v2.2.0)
pcep <- sound$to_powercepstrogram(60, 0.002, 5000, 50)
cpps <- pcep$get_cpps(
  subtract_tilt = FALSE,
  time_averaging_window = 0.01,
  quefrency_averaging_window = 0.001,
  pitch_floor = 60,
  pitch_ceiling = 330
)

# FAST API (v2.2.0+): Bypass object creation for batch processing (1.5-2x faster)
cpps <- calculate_cpps_fast(
  sound,
  subtract_tilt = FALSE,
  time_averaging_window = 0.01,
  quefrency_averaging_window = 0.001,
  pitch_floor = 60,
  pitch_ceiling = 330
)

# ADVANCED: Two-step for multiple CPPS calculations from same cepstrogram
pcep_ptr <- to_powercepstrogram_fast(sound, 60, 0.002, 5000, 50)
cpps1 <- get_cpps_fast(pcep_ptr, subtract_tilt = FALSE, pitch_floor = 60)
cpps2 <- get_cpps_fast(pcep_ptr, subtract_tilt = TRUE, pitch_floor = 80)
```

**Performance comparison (verified v2.2.3):**
- v2.2.0 R6Class: 9.5s for AVQI v3.01
- v2.2.1+ Module: **4.0-4.5s** (2.1-2.4x faster)
- v2.2.1+ Fast API: **3.5-4.0s** (2.4-2.7x faster)

### Pattern 2e: XPtr Window Functions (NEW in v2.2.1)

**Performance:** 70x faster than R function callbacks for custom DSP.

When applying custom window or transform functions to large audio files, use compiled C++ functions via RcppXPtrUtils:

```r
# Requires: install.packages("RcppXPtrUtils")
library(RcppXPtrUtils)

# Create compiled C++ window function (runs once at setup)
gauss_window <- cppXPtr(
  "#include <cmath>
   double window(double t) {
     double x = t - 0.5;
     return exp(-18.0 * x * x);
   }",
  depends = character()
)

# Apply to sound (70x faster than R function callback)
windowed <- apply_window_xptr(sound, gauss_window)

# Or use pre-defined window types (no RcppXPtrUtils code needed)
hamming <- create_window_xptr("hamming")  # Also: hanning, gaussian, triangular, blackman
windowed <- apply_window_xptr(sound, hamming)
```

**XPtr performance functions:**
- `apply_window_xptr(sound, window_func)` - Apply window (t normalized 0-1)
- `apply_transform_xptr(sound, transform_func)` - Transform sample values
- `create_window_xptr(type, sigma)` - Create pre-defined window function

**Custom transform example (soft clipping):**
```r
soft_clip <- cppXPtr(
  "#include <cmath>
   double clip(double x) { return tanh(x * 2.0); }",
  depends = character()
)
clipped <- apply_transform_xptr(sound, soft_clip)
```

### Pattern 2f: Parallel Processing (NOT YET EXPORTED - v4.0.1)

**NOTE:** Parallel processing functions exist in `R/parallel-batch.R` but are **not currently exported** in NAMESPACE. These are planned for a future release.

**Performance (when available):** 3-8x speedup on multi-core systems for I/O-bound tasks.

```r
# FUTURE: Generic parallel file processing (NOT AVAILABLE YET)
# files <- list.files("audio/", pattern = "\\.wav$", full.names = TRUE)
# 
# results <- analyze_files_parallel(files, function(sound) {
#   pitch <- sound$to_pitch()
#   list(
#     mean_f0 = pitch$get_mean(0, 0, "hertz"),
#     sd_f0 = pitch$get_standard_deviation(0, 0, "hertz")
#   )
# }, n_cores = 4)

# WORKAROUND: Use parallel package directly
library(parallel)
cl <- makeCluster(4)
clusterEvalQ(cl, library(pladdrr))
results <- parLapply(cl, files, function(file) {
  sound <- Sound(file)
  pitch <- sound$to_pitch()
  list(mean_f0 = pitch$get_mean(0, 0, "hertz"))
})
stopCluster(cl)
```

**Parallel processing functions (NOT EXPORTED):**
- `analyze_files_parallel(files, analysis_func, n_cores)` - Generic parallel file processing
- `process_sounds_parallel(sounds, analysis_func, n_cores)` - Process pre-loaded sounds
- `extract_pitch_parallel(files, n_cores, ...)` - Parallel pitch extraction
- `extract_formant_parallel(files, n_cores, ...)` - Parallel formant extraction
- `extract_intensity_parallel(files, n_cores, ...)` - Parallel intensity extraction

**Status:** Implementation exists but awaiting export decision and comprehensive testing.
- `benchmark_parallel(files, analysis_func, cores)` - Find optimal core count

**Best practices:**
- Use `n_cores = parallel::detectCores() - 1` to leave one core for system
- On Windows, uses `parLapply`; on Unix/Mac, uses `mclapply`
- For very large files, consider batch processing + parallel combined

### Pattern 2g: Direct API Functions (v2.3.0)

**Performance:** 2-3x faster than module dispatch for hot paths.

**NEW in v4.0.2:** Full-parameter Direct API pitch functions now available! Use `to_pitch_ac_direct()` or `to_pitch_cc_direct()` for custom voicing parameters with Direct API performance.

```r
# TIER 1: Standard (baseline, full features, R6 object)
pitch <- sound$to_pitch_cc(voicing_threshold = 0.6)
mean_f0 <- pitch$get_mean(0, 0, "hertz")

# TIER 2: Direct API with FULL PARAMETERS (v4.0.2+) ⭐ NEW
pitch_ptr <- to_pitch_cc_direct(sound, voicing_threshold = 0.6)
f0_value <- get_pitch_value_direct(pitch_ptr, time = 1.0, unit = "hertz", interpolate = TRUE)
# 2x faster than Tier 1, returns external pointer

# TIER 2: Legacy Direct API (basic parameters only)
pitch_ptr <- to_pitch_direct(sound)  # Only: time_step, pitch_floor, pitch_ceiling
# Kept for backward compatibility

# TIER 3: Batch API (fastest for >10 files)
pitches <- sound_to_pitch_cc_batch(sounds, voicing_threshold = 0.6)
```

**Direct API functions for object creation:**
- `to_pitch_direct(sound, time_step, pitch_floor, pitch_ceiling)` → Pitch XPtr (legacy, basic params)
- `to_pitch_ac_direct(sound, ...)` → Pitch XPtr ✅ **Full params (v4.0.2+)**
- `to_pitch_cc_direct(sound, ...)` → Pitch XPtr ✅ **Full params (v4.0.2+)**
- `to_formant_direct(sound, time_step, max_formants, max_formant, window_length, pre_emphasis)` → Formant XPtr ✅ **Full params**
- `to_intensity_direct(sound, minimum_pitch, time_step, subtract_mean)` → Intensity XPtr ✅ **Full params**
- `to_harmonicity_direct(sound, time_step, minimum_pitch, silence_threshold, periods_per_window)` → Harmonicity XPtr ✅ **Full params**
- `to_spectrum_direct(sound, fast)` → Spectrum XPtr (v2.3.0)
- `to_spectrogram_direct(sound, ...)` → Spectrogram XPtr (v2.3.0)
- `to_ltas_direct(sound, bandwidth)` → LTAS XPtr (v2.3.0)
- `to_point_process_direct(sound, ...)` → PointProcess XPtr (v2.3.0)

**Direct API functions for queries (accepts string units):**
- `get_pitch_value_direct(pitch_xptr, time, unit, interpolate)` - Single F0 value (unit: "hertz", "semitones", etc.)
- `get_pitch_stats_direct(pitch_xptr, from_time, to_time, unit)` - All pitch statistics
- `get_formant_value_direct(formant_xptr, formant_number, time, unit)` - Single formant
- `get_formants_direct(formant_xptr, time, unit)` - All formants at time
- `get_intensity_value_direct(intensity_xptr, time, interpolation)` - Single intensity

**Compound operations (single C++ call for multiple stats):**
```r
# Get all common pitch statistics in one call
stats <- get_pitch_stats_direct(pitch_ptr, 0, 0, "hertz")
# Returns: list(min, max, mean, stdev, median, q25, q75, count_voiced)

# Get all formants at single time point
formants <- get_formants_direct(formant_ptr, time = 1.0, unit = "hertz")
# Returns: numeric vector of formant values
```

**Note:** All Direct API functions use the unified `extract_xptr()` utility for consistent pointer extraction.

### Pattern 2h: Tier 3 Batch Operations (v2.2.7+)

**Performance:** 5-10x faster for bulk object creation and processing.

When creating multiple analysis objects or processing many sounds, use batch operations:

```r
# TIER 1: Individual sound processing (baseline)
sounds <- lapply(files, Sound)
pitches <- lapply(sounds, function(s) s$to_pitch())

# TIER 3: Batch processing (5-10x faster)
sounds <- lapply(files, Sound)
pitches <- sound_to_pitch_batch(sounds, time_step = 0.01, 
                                 pitch_floor = 75, pitch_ceiling = 600)

# Other batch conversion functions
formants <- sound_to_formant_batch(sounds)
intensities <- sound_to_intensity_batch(sounds)

# Batch operations with pitch algorithms
pitches_ac <- sound_to_pitch_ac_batch(sounds, time_step = 0.01)
pitches_cc <- sound_to_pitch_cc_batch(sounds, time_step = 0.01)

# Combined extraction and analysis
results <- sound_extract_and_pitch(sound, start_times, end_times)
results <- sound_extract_and_formant(sound, start_times, end_times)
```

**Batch conversion functions:**
- `sound_to_pitch_batch(sounds, ...)` - Batch pitch extraction
- `sound_to_pitch_ac_batch(sounds, ...)` - Batch autocorrelation pitch
- `sound_to_pitch_cc_batch(sounds, ...)` - Batch cross-correlation pitch
- `sound_to_formant_batch(sounds, ...)` - Batch formant extraction
- `sound_to_intensity_batch(sounds, ...)` - Batch intensity extraction
- `sound_extract_and_pitch(sound, starts, ends)` - Extract parts + pitch
- `sound_extract_and_formant(sound, starts, ends)` - Extract parts + formant
- `sound_concatenate_all(sounds)` - Concatenate multiple sounds (19x faster than iterative)
- `sound_load_window(path, start, end, resample_to = NULL)` - Load audio window without full file read (27x faster)
- `textgrid_merge(textgrids, equalize_domains = FALSE)` - Merge multiple TextGrids (17x faster than manual tier copying)

**NEW in v4.0.3:** Added specialized functions for complex workflows:

```r
# Load only needed audio segment (avoids loading entire file)
window <- sound_load_window("long_audio.wav", start = 10.5, end = 10.55, resample_to = 10000)
# Use case: Extract 50ms window from 10-minute file + resample in one operation

# Merge TextGrids efficiently (native Praat function)
tg1 <- TextGrid(0, 1); tg1$add_interval_tier("words")
tg2 <- TextGrid(0, 1); tg2$add_point_tier("events")
merged <- textgrid_merge(list(tg1, tg2))
# Use case: Combine annotation layers from different sources

# Concatenate voiced segments efficiently
voiced_parts <- list(sound1, sound2, sound3)  # 10-50 segments
concatenated <- sound_concatenate_all(voiced_parts)
# Use case: AVQI analysis requiring voiced-only audio
```

See `vignettes/articles/batch-operations-guide.Rmd` for comprehensive batch operations documentation.

---

### Pattern 3: Export to Data Frame (v4.0+: Returns data.table)

**NEW in v4.0:** All `as.data.frame()` methods now return `data.table` (inherits from `data.frame`) for 5-15x faster batch operations.

```r
# All objects support as.data.frame() - returns data.table
pitch_df <- as.data.frame(pitch)           # time, f0 (data.table)
formant_df <- as.data.frame(formant)       # time, f1, f2, f3, ... (data.table)
intensity_df <- as.data.frame(intensity)   # time, intensity (data.table)

# Check return type
class(pitch_df)  # c("data.table", "data.frame")

# data.table provides fast operations
library(data.table)
pitch_df[f0 > 200]              # Fast filtering (keyed by time)
pitch_df[, mean(f0, na.rm=TRUE)] # Fast aggregation

# Backward compatible - works with data.frame code
pitch_df$f0                     # Column access works as before
pitch_df[pitch_df$f0 > 200, ]  # data.frame syntax still works

# With options
pitch_df <- pitch$as_data_frame(
  include_strength = TRUE,
  include_intensity = TRUE
)
```

**Performance benefits:**
- Fast keyed lookups by time/formant/frequency
- `rbindlist()` for efficient aggregation (replaces slow rbind loops)
- In-place modification for memory efficiency
- 5-15x faster for batch operations

### Pattern 4: Tier Manipulation

```r
# Extract editable tier from analysis
pitch_tier <- pitch$down_to_pitch_tier()

# Add/modify points
pitch_tier$add_point(time = 1.0, value = 150.0)
pitch_tier$remove_point_near(time = 1.0)

# Use in resynthesis
manipulation <- sound$to_manipulation(
  time_step = 0.01,
  pitch_floor = 75,
  pitch_ceiling = 600
)
manipulation$replace_pitch_tier(pitch_tier)
new_sound <- manipulation$to_sound()
```

### Pattern 5: TextGrid Operations

```r
# Load TextGrid
tg <- TextGrid("annotations.TextGrid")

# Query structure
n_tiers <- tg$get_number_of_tiers()
tier_name <- tg$get_tier_name(tier_number = 1)
is_interval <- tg$is_interval_tier(tier_number = 1)

# Query intervals
n_intervals <- tg$get_number_of_intervals(tier_number = 1)
label <- tg$get_label_of_interval(tier_number = 1, interval_number = 5)
start <- tg$get_start_time_of_interval(tier_number = 1, interval_number = 5)
end <- tg$get_end_time_of_interval(tier_number = 1, interval_number = 5)

# Extract Sound for interval
sound_segment <- sound$extract_part(start, end)
```

### Pattern 6: Voice Activity Detection with ZCR (NEW in v4.0.4)

**Critical for AVQI:** The AVQI algorithm uses both intensity AND Zero Crossing Rate (ZCR) filtering to identify voiced segments. pladdrr v4.0.4 adds proper ZCR support matching Praat's `checkZeros` procedure.

```r
# === COMPLETE AVQI-COMPATIBLE VOICED EXTRACTION ===
sound <- Sound("continuous_speech.wav")

# Single function: intensity + ZCR filtering (default: use_zcr = TRUE)
voiced <- extract_voiced_segments(
  sound,
  minimum_pitch = 50,           # Hz, for intensity detection
  silence_threshold = -25,      # dB below max
  zcr_threshold = 3000,         # Hz, reject segments above this
  use_zcr = TRUE                # Enable ZCR filtering (default)
)

# Result: Concatenated voiced audio matching Praat's AVQI extraction
cat("Voiced duration:", voiced$get_duration(), "s\n")

# === INTENSITY-ONLY EXTRACTION (legacy behavior) ===
voiced_no_zcr <- extract_voiced_segments(sound, use_zcr = FALSE)

# === WITH TEXTGRID OUTPUT (for inspection) ===
result <- extract_voiced_segments(sound, return_textgrid = TRUE)
voiced_sound <- result$sound
vad_grid <- result$textgrid
```

**Step-by-step manual control:**

```r
# 1. Create VAD TextGrid (intensity-based)
vad_grid <- sound_to_textgrid_silences(
  sound,
  minimum_pitch = 50,
  time_step = 0.003,
  silence_threshold = -25,
  min_silent_interval = 0.1,
  min_sounding_interval = 0.1
)

# 2. Get matching intervals
voiced_intervals <- textgrid_get_intervals_where(
  vad_grid,
  tier = 1,
  condition = "equals",        # Also: "contains", "starts with", "ends with"
  text = "sounding"
)
# Returns: list(xmin, xmax, text, count)

# 3. Calculate ZCR for filtering
zcr_data <- sound_get_zcr(
  sound,
  window_duration = 0.03,      # 30ms windows (AVQI standard)
  hop_duration = 0.01          # 10ms hop
)
# Returns: list(times, zcr, window_duration, hop_duration)

# 4. Filter intervals by ZCR (manual approach)
keep_intervals <- logical(voiced_intervals$count)
for (i in seq_along(voiced_intervals$xmin)) {
  in_interval <- zcr_data$times >= voiced_intervals$xmin[i] &
                 zcr_data$times <= voiced_intervals$xmax[i]
  mean_zcr <- mean(zcr_data$zcr[in_interval])
  keep_intervals[i] <- mean_zcr < 3000  # Voiced < 3000 Hz
}

# 5. Extract and concatenate passing intervals
voiced_sounds <- sound_extract_parts(
  sound,
  voiced_intervals$xmin[keep_intervals],
  voiced_intervals$xmax[keep_intervals]
)
concatenated <- sound_concatenate_all(voiced_sounds)
```

**ZCR interpretation:**
- **Voiced speech:** 500-2000 crossings/second (low ZCR)
- **Unvoiced fricatives:** 3000-6000 crossings/second (high ZCR)
- **Silence:** Variable (depends on noise floor)

**AVQI threshold:** `zcr_threshold = 3000` rejects unvoiced segments (fricatives, aspiration).

---

## Method Signatures

### Sound Methods

| Method | Parameters | Return | Praat Function |
|--------|------------|--------|----------------|
| `get_duration()` | - | `numeric` | `sound->xmax - sound->xmin` |
| `get_sampling_frequency()` | - | `numeric` | `1.0 / sound->dx` |
| `get_number_of_samples()` | - | `integer` | `sound->nx` |
| `get_number_of_channels()` | - | `integer` | `sound->ny` |
| `get_value_at_time(time, channel, interpolation)` | `double, int, int` | `numeric` | `Vector_getValueAtX()` |
| `get_rms(from_time, to_time, channel)` | `double, double, int` | `numeric` | `Sound_getRootMeanSquare()` |
| `get_energy(from_time, to_time)` | `double, double` | `numeric` | `Sound_getEnergy()` |
| `get_power(from_time, to_time)` | `double, double` | `numeric` | `Sound_getPower()` |
| `get_intensity_db(from_time, to_time)` | `double, double` | `numeric` | `Sound_getIntensity_dB()` |
| `to_pitch(time_step, pitch_floor, pitch_ceiling)` | `double, double, double` | `Pitch` | `Sound_to_Pitch()` |
| `to_formant_burg(...)` | multiple | `Formant` | `Sound_to_Formant_burg()` |
| `to_intensity(minimum_pitch, time_step, subtract_mean)` | `double, double, bool` | `Intensity` | `Sound_to_Intensity()` |
| `to_spectrum(fast)` | `bool` | `Spectrum` | `Sound_to_Spectrum()` |
| `to_spectrogram(window_length, max_freq, time_step, freq_step, window_shape)` | multiple | `Spectrogram` | `Sound_to_Spectrogram()` |
| `extract_part(start_time, end_time)` | `double, double` | `Sound` | `Sound_extractPart()` |
| `extract_channel(channel)` | `int` | `Sound` | `Sound_extractChannel()` |

### Pitch Methods

| Method | Parameters | Return | Notes |
|--------|------------|--------|-------|
| `get_value_at_time(time, unit, interpolate)` | `double, string, bool` | `numeric` | unit: "hertz", "semitones", "mel", "erb" |
| `get_mean(from_time, to_time, unit)` | `double, double, string` | `numeric` | 0,0 = entire duration |
| `get_standard_deviation(from_time, to_time, unit)` | `double, double, string` | `numeric` | |
| `get_minimum(from_time, to_time, unit, interpolate)` | `double, double, string, bool` | `numeric` | |
| `get_maximum(from_time, to_time, unit, interpolate)` | `double, double, string, bool` | `numeric` | |
| `get_quantile(quantile, from_time, to_time, unit)` | `double, double, double, string` | `numeric` | quantile: 0.5 = median |
| `count_voiced_frames()` | - | `integer` | |
| `down_to_pitch_tier()` | - | `PitchTier` | |

### Formant Methods

| Method | Parameters | Return | Notes |
|--------|------------|--------|-------|
| `get_value_at_time(formant_number, time, unit)` | `int, double, string` | `numeric` | unit: "hertz", "bark" |
| `get_bandwidth_at_time(formant_number, time, unit)` | `int, double, string` | `numeric` | |
| `get_mean(formant_number, from_time, to_time, unit)` | `int, double, double, string` | `numeric` | |
| `get_standard_deviation(formant_number, from_time, to_time, unit)` | `int, double, double, string` | `numeric` | |
| `get_quantile(formant_number, quantile, from_time, to_time, unit)` | `int, double, double, double, string` | `numeric` | |
| `track(number_of_tracks, ref_f1, ...)` | multiple | `Formant` | |
| `to_formantgrid()` | - | `FormantGrid` | |

### Intensity Methods

| Method | Parameters | Return | Notes |
|--------|------------|--------|-------|
| `get_value_at_time(time, interpolate)` | `double, string` | `numeric` | interpolate: "nearest", "linear", "cubic" |
| `get_mean(from_time, to_time, averaging_method)` | `double, double, string` | `numeric` | |
| `get_minimum(from_time, to_time, interpolation)` | `double, double, string` | `numeric` | |
| `get_maximum(from_time, to_time, interpolation)` | `double, double, string` | `numeric` | |
| `get_standard_deviation(from_time, to_time)` | `double, double` | `numeric` | |
| `get_quantile(from_time, to_time, quantile)` | `double, double, double` | `numeric` | |

---

## Validation Patterns

### Comparing pladdrr with Praat Script Output

```r
# Run equivalent Praat script
praat_script <- '
Read from file: "audio.wav"
To Pitch: 0, 75, 600
mean_f0 = Get mean: 0, 0, "Hertz"
writeInfoLine: mean_f0
'
praat_result <- as.numeric(system(
  paste("praat --run -", praat_script),
  intern = TRUE
))

# pladdrr equivalent
sound <- Sound("audio.wav")
pitch <- sound$to_pitch(time_step = 0, pitch_floor = 75, pitch_ceiling = 600)
pladdrr_result <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")

# Compare (should be identical within floating-point tolerance)
stopifnot(abs(praat_result - pladdrr_result) < 1e-6)
```

### Using Praat Interpreter from R

```r
# Run Praat scripts directly via interpreter wrapper
praat_run_script('
  Read from file: "audio.wav"
  selectObject: "Sound audio"
  duration = Get total duration
')

# Get variables back
duration <- praat_eval_numeric("duration")
```

---

## Common Pitfalls

### 1. Class Name Checks (UPDATED v2.1.1)

```r
# CORRECT: Use clean public class names
if (inherits(formant, "Formant")) {
  # Process formant object
}
if (inherits(pitch, "Pitch")) {
  # Process pitch object
}
if (inherits(intensity, "Intensity")) {
  # Process intensity object
}

# WRONG: Don't use internal constructor names (deprecated)
if (inherits(formant, "formant_constructor")) {  # Old, don't use
  # This still works but is deprecated
}
```

**Available class names:** `Sound`, `Pitch`, `Formant`, `Intensity`, `Spectrum`, `Spectrogram`, `TextGrid`, `PointProcess`, `Harmonicity`, `Ltas`, `Cepstrum`, `PowerCepstrum`, `LPC`, `Cochleagram`, `Excitation`, `Matrix`, `Table`, `PitchTier`, `FormantTier`, `IntensityTier`, `AmplitudeTier`, `DurationTier`, `FormantGrid`, `Manipulation`, `KlattGrid`, `FormantPath`, `ComplexSpectrogram`, `Polygon`, `VocalTract`, `LongSound`, `Electroglottogram`

### 2. Unit Code Mismatch

**NOTE:** Modern pladdrr API accepts strings directly - no need for manual conversion.

```r
# MODERN (v2.0+): Pass strings directly (RECOMMENDED)
f0 <- pitch$get_value_at_time(time = 1.0, unit = "hertz")
mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")

# LEGACY: Manual unit code conversion (still works, but unnecessary)
unit_code <- function(unit) {
  switch(tolower(unit), "hertz" = 0L, "semitones" = 1L, ...)
}
f0 <- pitch$get_value_at_time(time = 1.0, unit = unit_code("hertz"))
```

### 3. Frame Indexing (1-based)

```r
# Praat uses 1-based indexing
first_frame <- pitch$get_time_from_frame(1)    # Correct
first_frame <- pitch$get_time_from_frame(0)    # Error!

# Interval numbers are also 1-based
label <- tg$get_label_of_interval(tier_number = 1, interval_number = 1)
```

### 4. Time Range 0,0 Means "Entire Duration"

```r
# from_time=0, to_time=0 is special: uses full duration
mean_all <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")

# Explicit range
mean_part <- pitch$get_mean(from_time = 1.0, to_time = 2.0, unit = "hertz")
```

### 5. NA for Undefined Values

```r
# Pitch returns NA for unvoiced frames
f0 <- pitch$get_value_at_time(time = 1.0, unit = "hertz")
if (is.na(f0)) {
  # Frame is unvoiced
}

# Formant returns NA for missing formants
f5 <- formant$get_value_at_time(formant_number = 5, time = 1.0, unit = "hertz")
```

### 6. Invalid Pointer Access

```r
# Always check validity before heavy operations
if (pitch$is_valid()) {
  # Safe to use
  mean_f0 <- pitch$get_mean(0, 0, "hertz")
} else {
  stop("Invalid Pitch object")
}
```

### 7. Method Name Changes (v2.1.1)

```r
# CORRECT: Use specific method names
formant <- sound$to_formant_burg()      # Burg's method (standard)
pitch <- sound$to_pitch_cc()            # Cross-correlation method

# DEPRECATED: Generic methods (still work via dispatch, but use specific names)
formant <- sound$to_formant()           # Deprecated, use to_formant_burg()
pitch <- sound$to_pitch()               # Deprecated, use to_pitch_cc()
```

### 8. Property Access (Fast Path)

```r
# FAST: Direct property access via .cpp (v2.0.8+)
duration <- sound$.cpp$duration         # Direct C++ member access
nx <- sound$.cpp$nx                     # Fast, no function call overhead

# BACKWARD-COMPATIBLE: Method access (still works)
duration <- sound$get_duration()        # Slightly slower, but familiar
nx <- sound$get_number_of_samples()
```

### 9. Batch Operations vs Loops

```r
# SLOW: R loop with repeated C++ calls
times <- seq(0, 2, by = 0.01)
f1_values <- numeric(length(times))
for (i in seq_along(times)) {
  f1_values[i] <- formant$get_value_at_time(1, times[i], "hertz")
}

# FAST: Batch query (3-5x faster)
result <- get_formants_at_times(formant, times, formant_numbers = 1)
f1_values <- result$F1
```

---

## File Locations

```
src/
├── modules/               # Rcpp Module C++ code
│   ├── module_common.h    # Unit codes, validation macros
│   ├── sound_module.cpp   # RSound class
│   ├── pitch_module.cpp   # RPitch class
│   └── ...
├── praat.github.io/       # Praat C++ source
│   ├── fon/              # Core phonetic objects
│   │   ├── Sound.h
│   │   ├── Pitch.h
│   │   └── ...
│   └── melder/           # Error handling
├── datatable_utils.h      # C++ helpers for data.table creation (v4.0+)
R/
├── sound-r6-new.R         # Sound R wrapper
├── pitch-r6.R             # Pitch R wrapper
├── formant-r6.R           # Formant R wrapper
├── datatable-utils.R      # R data.table helpers (v4.0+)
├── parallel-batch.R       # Parallel processing (not exported)
├── zzz.R                  # Module loading
└── RcppExports.R          # Auto-generated (don't edit)
```

---

## Quick Reference Card

**Updated for v4.0.4 - 3-Tier Performance API + data.table + ZCR**

```r
# === LOAD AUDIO ===
sound <- Sound("audio.wav")

# === TIER 1: STANDARD API (baseline, full features) ===
pitch <- sound$to_pitch_cc(time_step = 0, pitch_floor = 75, pitch_ceiling = 600)
formant <- sound$to_formant_burg()
intensity <- sound$to_intensity()

# === QUERY AT TIME (single point) ===
f0 <- pitch$get_value_at_time(1.0, "hertz")
f1 <- formant$get_value_at_time(1, 1.0, "hertz")
f2 <- formant$get_value_at_time(2, 1.0, "hertz")
db <- intensity$get_value_at_time(1.0, "cubic")

# === DATA EXPORT (v4.0+: returns data.table) ===
pitch_df <- as.data.frame(pitch)      # Returns data.table (inherits data.frame)
formant_df <- as.data.frame(formant)  # data.table with keyed columns
library(data.table)
pitch_df[f0 > 200]                    # Fast filtering (5-15x faster)

# === TIER 2: DIRECT API (2-3x faster, bypasses R dispatch) ===
# NEW in v4.0.2: Full-parameter pitch functions available!
pitch_ptr <- to_pitch_cc_direct(sound, voicing_threshold = 0.6)  # All 10 params ✓
f0_value <- get_pitch_value_direct(pitch_ptr, 1.0, "hertz", TRUE)
all_stats <- get_pitch_stats_direct(pitch_ptr, 0, 0, "hertz")

# Legacy: Basic parameters only
pitch_ptr <- to_pitch_direct(sound)  # Basic: time_step, pitch_floor, pitch_ceiling

# === TIER 3: BATCH QUERIES (5-10x faster for multiple points) ===
times <- seq(0.5, 2.5, by = 0.01)
formants <- get_formants_at_times(formant, times, 1:4)  # Returns list(F1, F2, F3, F4)
f0_contour <- get_pitch_at_times(pitch, times, "hertz")
db_contour <- get_intensity_at_times(intensity, times, "cubic")

# === TIER 3: BATCH OPERATIONS (5-10x faster bulk processing) ===
sounds <- lapply(files, Sound)
pitches <- sound_to_pitch_batch(sounds, time_step = 0.01)
formants <- sound_to_formant_batch(sounds)

# Aggregate using data.table::rbindlist (v4.0+)
library(data.table)
all_results <- rbindlist(results, idcol = "file_id")

# === BATCH STATISTICS (10-50x faster for multi-interval) ===
from_times <- seq(0, 9, length.out = 100)
to_times <- from_times + 0.1
stats <- pitch_get_statistics_batch(pitch$.xptr, from_times, to_times,
                                     c("min", "max", "mean", "stdev"), 0L)

# === FAST CPPS (1.5-2x faster AVQI) ===
cpps <- calculate_cpps_fast(sound, subtract_tilt = FALSE,
                             pitch_floor = 60, pitch_ceiling = 330)

# === VOICED EXTRACTION WITH ZCR (v4.0.4 - AVQI-compatible) ===
voiced <- extract_voiced_segments(sound, zcr_threshold = 3000, use_zcr = TRUE)
zcr_data <- sound_get_zcr(sound, window_duration = 0.03)  # Per-frame ZCR

# === XPTR WINDOWS (70x faster custom DSP) ===
hamming <- create_window_xptr("hamming")
windowed <- apply_window_xptr(sound, hamming)

# === STATISTICS (0,0 = entire duration) ===
mean_f0 <- pitch$get_mean(0, 0, "hertz")
sd_f0 <- pitch$get_standard_deviation(0, 0, "hertz")

# === FAST PROPERTY ACCESS ===
duration <- sound$.cpp$duration        # Fast C++ property
sr <- sound$.cpp$sampling_frequency    # Direct member access

# === EXPORT ===
df <- as.data.frame(pitch)
pitch$save("output.Pitch")

# === CLASS CHECKING ===
if (inherits(pitch, "Pitch")) {
  # Process pitch object
}

# === INTERPRETER (persistent state) ===
interp <- PraatInterpreter$new()
interp$run('x = 42')
result <- interp$eval_numeric('x * 2')
```

**Performance Decision Tree:**
- **< 10 files, interactive:** Use Tier 1 (Standard API)
- **10-100 files, loops:** Use Tier 2 (Direct API)
- **> 100 files, production:** Use Tier 3 (Batch/Parallel)
- **Need statistics from many intervals:** Use Tier 3 (Batch Statistics)

**See comprehensive guides:**
- `vignettes/performance-optimization.Rmd` - Complete 3-tier API guide
- `BATCH_OPERATIONS_GUIDE.md` - All batch functions with benchmarks
- `MIGRATION_GUIDE.md` - How to optimize existing code
- `NAMING_CONVENTIONS.md` - Function naming patterns

---

## Known Limitations

### Direct API Pitch Parameters (v4.0.2)

**Status:** ✅ **RESOLVED** - Full-parameter Direct API functions now available!

**NEW in v4.0.2:** Use `to_pitch_ac_direct()` or `to_pitch_cc_direct()` for custom parameters:

```r
# ✅ RECOMMENDED: Direct API with full parameters (v4.0.2+)
pitch_ptr <- to_pitch_ac_direct(
  sound,
  voicing_threshold = 0.6,      # Custom parameter ✓
  silence_threshold = 0.01,     # Custom parameter ✓
  octave_cost = 0.02            # Custom parameter ✓
)
# Fast (2x faster than Tier 1), full control, returns external pointer

# Alternative: Cross-correlation method
pitch_ptr <- to_pitch_cc_direct(
  sound,
  voicing_threshold = 0.6,
  silence_threshold = 0.01
)
```

**Legacy Function:** `to_pitch_direct()` remains available but only supports 4 basic parameters (time_step, pitch_floor, pitch_ceiling, method). Use the new `_ac_direct()` or `_cc_direct()` variants for custom voicing parameters.

**API Tier Comparison for Custom Parameters:**

```r
# Tier 1: Standard API (R6 object returned)
pitch <- sound$to_pitch_cc(voicing_threshold = 0.6)
# Speed: Medium | Returns: R6 Pitch object

# Tier 2: Direct API (external pointer returned) ⭐ NEW
pitch_ptr <- to_pitch_cc_direct(sound, voicing_threshold = 0.6)
# Speed: Fast (2x faster) | Returns: External pointer

# Tier 3: Batch API (list returned)
pitches <- sound_to_pitch_cc_batch(sounds, voicing_threshold = 0.6)
# Speed: Fastest | Returns: List of Pitch objects | Best for >10 files
```

### to_point_process_periodic_cc Parameters

The R wrapper accepts `time_step`, `max_period_factor`, and `max_amplitude_factor` parameters for API compatibility with Praat's GUI, but **only `pitch_floor` and `pitch_ceiling` are currently used**. The underlying Praat C function `Sound_to_PointProcess_periodic_cc()` only accepts minimum and maximum pitch.

```r
# These parameters are used:
pp <- sound$to_point_process_periodic_cc(pitch_floor = 75, pitch_ceiling = 600)

# These parameters are accepted but ignored:
# time_step, max_period_factor, max_amplitude_factor
```

---

## Real-World Use Cases (v4.0.3 Optimizations)

This section demonstrates how v4.0.3 batch operations enable efficient implementation of complex voice analysis workflows that previously required manual iteration.

### Use Case 1: AVQI (Acoustic Voice Quality Index) - Voice Concatenation

**Challenge:** AVQI requires concatenating 10-50 voiced segments into a single audio file for analysis. Previous approach used iterative concatenation which is O(n²).

**v4.0.3 Solution:** `sound_concatenate_all()` performs batch concatenation in O(n) time (19x faster).

```r
# Extract voiced segments from recording
voiced_intervals <- textgrid$get_intervals_where(tier = "voicing", label = "voiced")

# Extract each voiced segment as a Sound object
voiced_sounds <- lapply(voiced_intervals, function(interval) {
  sound$extract_part(interval$start, interval$end)
})

# OLD (slow): Iterative concatenation - O(n²) due to repeated copying
# result <- voiced_sounds[[1]]
# for (i in 2:length(voiced_sounds)) {
#   result <- sounds_append(result, voiced_sounds[[i]])  # Each call copies entire result
# }

# NEW (fast): Single-pass batch concatenation - O(n)
concatenated <- sound_concatenate_all(voiced_sounds)

# Continue with AVQI analysis using concatenated voiced audio
pitch <- concatenated$to_pitch_cc()
cpps <- calculate_cpps_fast(concatenated, 
                             subtract_tilt = FALSE,
                             pitch_floor = 60, 
                             pitch_ceiling = 330)
shimmer <- concatenated$to_amplitude_tier()$get_shimmer_local()
# ... etc.
```

**Performance:** 19x faster for 30 segments (150ms → 8ms), scales linearly with segment count.

### Use Case 2: VUV (Voiced/Unvoiced/Voiced) Analysis - TextGrid Merging

**Challenge:** VUV analysis creates voicing annotations that must be merged with existing TextGrid tiers. Manual approach requires save/reload + O(n²) boundary insertion.

**v4.0.3 Solution:** `textgrid_merge()` uses Praat's native batch merge (17x faster).

```r
# Load original TextGrid with phoneme annotations
original_tg <- TextGrid("recording.TextGrid")

# Perform VUV detection on audio
sound <- Sound("recording.wav")
pitch <- sound$to_pitch_cc()

# Create new TextGrid with VUV tier
vuv_tg <- TextGrid(0, sound$get_duration())
vuv_tg$add_interval_tier("vuv")

# Populate VUV tier based on pitch detection
times <- seq(0, sound$get_duration(), by = 0.01)
pitch_values <- get_pitch_at_times(pitch, times, unit = "hertz")

# Add boundaries for voiced/unvoiced transitions
for (i in 2:length(pitch_values)) {
  if (is.na(pitch_values[i-1]) != is.na(pitch_values[i])) {
    vuv_tg$insert_boundary(tier = 1, time = times[i])
  }
}

# Set labels for each interval
for (j in 1:vuv_tg$get_number_of_intervals(1)) {
  start <- vuv_tg$get_start_time_of_interval(1, j)
  mid <- (start + vuv_tg$get_end_time_of_interval(1, j)) / 2
  f0 <- pitch$get_value_at_time(mid, "hertz")
  label <- if (!is.na(f0)) "voiced" else "unvoiced"
  vuv_tg$set_interval_text(1, j, label)
}

# OLD (slow): Manual merge via save/reload + tier copying
# original_tg$save("temp.TextGrid")
# reloaded <- TextGrid("temp.TextGrid")
# for each interval in vuv_tg:
#   reloaded$insert_boundary(...)  # O(n²) - each insert shifts all later intervals

# NEW (fast): Native Praat batch merge - O(n)
merged_tg <- textgrid_merge(list(original_tg, vuv_tg))

# Result has both original tiers AND vuv tier
merged_tg$save("recording_with_vuv.TextGrid")
```

**Performance:** 17x faster for 100 intervals (1.7s → 0.1s). Avoids disk I/O and O(n²) insertion.

**Key parameter:** `equalize_domains = FALSE` (default) preserves original tier domains. Use `TRUE` to extend all tiers to unified domain.

### Use Case 3: Pharyngeal Consonant Analysis - Windowed Resampling

**Challenge:** Pharyngeal consonant analysis requires high-frequency spectrum analysis (10 kHz) but only for 50ms windows, not entire recording. Loading and resampling full 10-minute file wastes memory.

**v4.0.3 Solution:** `sound_load_window()` loads only needed segment and resamples in one operation (27x faster).

```r
# Pharyngeal consonant typically occurs at specific time points
pharyngeal_times <- c(3.45, 7.82, 12.34)  # seconds into recording

# Analyze each pharyngeal token
results <- lapply(pharyngeal_times, function(time) {
  # OLD (slow): Load entire file, then extract window, then resample
  # sound <- Sound("long_recording.wav")           # Load 10 minutes (slow)
  # segment <- sound$extract_part(time, time+0.05) # Extract 50ms
  # resampled <- segment$resample(10000, 50)       # Resample for high-freq analysis
  
  # NEW (fast): Load+resample only the needed 50ms window
  window <- sound_load_window(
    "long_recording.wav",
    start = time,
    end = time + 0.05,        # 50ms window
    resample_to = 10000       # Resample to 10 kHz for spectral analysis
  )
  
  # Perform spectrum analysis at high frequency resolution
  spectrum <- window$to_spectrum(fast = TRUE)
  
  # Extract pharyngeal signature: energy in 2-4 kHz band
  band_energy <- spectrum$get_band_energy(2000, 4000)
  
  # Get formants at high ceiling for pharyngeal detection
  formant <- window$to_formant_burg(
    max_number_of_formants = 5,
    maximum_formant = 7000  # Higher ceiling for pharyngeal F3/F4
  )
  
  list(
    time = time,
    f1 = formant$get_value_at_time(1, 0.025, "hertz"),
    f2 = formant$get_value_at_time(2, 0.025, "hertz"),
    f3 = formant$get_value_at_time(3, 0.025, "hertz"),
    pharyngeal_energy = band_energy
  )
})

# Combine results
pharyngeal_df <- do.call(rbind, lapply(results, as.data.frame))
```

**Performance:** 27x faster (540ms → 20ms per window). Avoids loading 10-minute file for each 50ms analysis.

**Key benefits:**
- Loads only requested time window (no full file I/O)
- Resampling happens during load (single operation)
- `preserve_times = FALSE` (default) makes window start at t=0 for simpler analysis

### Use Case 4: Batch Pitch Extraction with Custom Voicing Parameters

**Challenge:** Analyzing 1000+ files with non-default pitch parameters (e.g., voicing_threshold for creaky voice).

**v4.0.3 Solution:** Combine Direct API (`to_pitch_cc_direct`) with batch operations.

```r
files <- list.files("creaky_voice_corpus/", pattern = "\\.wav$", full.names = TRUE)

# Load all sounds
sounds <- lapply(files, Sound)

# Tier 3: Batch pitch extraction with custom voicing threshold
pitches <- sound_to_pitch_cc_batch(
  sounds,
  time_step = 0.01,
  voicing_threshold = 0.3,    # Lower threshold for creaky voice (default 0.45)
  silence_threshold = 0.01,
  pitch_floor = 50,            # Lower floor for male creaky voice
  pitch_ceiling = 300
)

# Extract statistics using batch queries
mean_f0s <- sapply(pitches, function(p) p$get_mean(0, 0, "hertz"))
jitter_local <- sapply(pitches, function(p) p$get_jitter_local())

# Create results data.table (fast)
library(data.table)
results <- data.table(
  file = basename(files),
  mean_f0 = mean_f0s,
  jitter = jitter_local
)
```

**Performance:** 5-10x faster than Tier 1 loop for batch processing.

### Migration Checklist for Agents

When reimplementing Praat code that involves:

**✓ Multiple sound concatenation:**
- Replace `Reduce(sounds_append, sound_list)` or loops with `sound_concatenate_all(sound_list)`
- Speedup: 19x for 30 segments

**✓ TextGrid tier merging:**
- Replace save/reload + manual `insert_boundary()` loops with `textgrid_merge(list(tg1, tg2))`
- Speedup: 17x for 100 intervals

**✓ Analysis of small windows in large files:**
- Replace `Sound(file) |> extract_part() |> resample()` with `sound_load_window(file, start, end, resample_to)`
- Speedup: 27x for 50ms windows in 10-minute files

**✓ Batch processing with custom parameters:**
- Use Tier 3 `sound_to_pitch_cc_batch()` instead of loops
- Use Tier 2 `to_pitch_cc_direct()` if only need external pointers
- Both support full parameter set (v4.0.2+)

---

## Version History

**v4.0.4 (2026-01-13):**
- **BREAKING: Fixed LTAS `get_slope()` unit parameter**
  - Unit codes were incorrectly mapped: energy/sones/dB off by one
  - Now matches Praat's `Ltas.cpp:44-60`: dB=0, energy=1, sones=2
  - Migration: If you used `unit="sones"` as workaround, switch to `unit="energy"`
- **NEW: Zero Crossing Rate (ZCR) support for AVQI-compatible extraction**
  - `sound_get_zcr(sound, window_duration, hop_duration)` - Calculate ZCR per frame
  - Uses Praat's `to_point_process_zeros()` for accurate interpolated detection
  - Matches AVQI203.praat `checkZeros` procedure
- **ENHANCED: `extract_voiced_segments()` now includes ZCR filtering**
  - New parameters: `zcr_threshold = 3000`, `zcr_window = 0.03`, `use_zcr = TRUE`
  - Default `use_zcr = TRUE` for AVQI-compatible extraction
  - Set `use_zcr = FALSE` for intensity-only detection (legacy behavior)
- **NEW: `textgrid_get_intervals_where()` - Query intervals by condition**
  - Conditions: "equals", "contains", "does not contain", "starts with", "ends with"
  - Returns list with xmin, xmax, text, count
- **NEW: `sound_extract_parts()` - Batch extract multiple time intervals**
  - Vectorized extraction of multiple Sound segments
  - Supports `return_r6 = FALSE` for raw pointer performance
- **Pattern 6 added:** Voice Activity Detection with ZCR documentation

**v4.0.3 (2026-01-13):**
- **NEW: Tier 3 specialized batch operations for complex workflows** (3 new functions)
  - `sound_concatenate_all(sounds, overlap)` - O(n) batch concatenation (19x faster than iterative)
    - Use case: AVQI analysis requiring concatenation of 10-50 voiced segments
    - Replaces O(n²) `Reduce(sounds_append, ...)` pattern
  - `sound_load_window(path, start, end, resample_to, preserve_times)` - Window loading with optional resample (27x faster)
    - Use case: Pharyngeal consonant analysis - extract 50ms window from 10-minute file at 10 kHz
    - Avoids loading entire file into memory
    - Combines read + resample in single operation
  - `textgrid_merge(textgrids, equalize_domains)` - Native Praat batch merge (17x faster than manual)
    - Use case: VUV analysis - merge voicing tier with existing phoneme annotations
    - Replaces save/reload + O(n²) `insert_boundary()` pattern
    - Uses Praat's `TextGrids_merge()` for O(n) performance
- **Real-world use case documentation**
  - Added "Real-World Use Cases (v4.0.3 Optimizations)" section to AGENT_GUIDE
  - Complete examples: AVQI voice concatenation, VUV TextGrid merging, Pharyngeal windowed analysis
  - Migration checklist for agents reimplementing Praat code
- **Critical bug fix:**
  - Fixed linker error preventing package installation
  - Removed `[[Rcpp::interfaces(r, cpp)]]` from textgrid_merge.cpp (function only called from R)
- **Performance verified:**
  - All 36 AGENT_GUIDE functions properly exported and tested
  - Benchmarks confirm: AVQI 3-5x faster, VUV 17x faster, Pharyngeal 27x faster

**v4.0.1 (2026-01-11):**
- **MAJOR: Complete data.table migration** - All C++ modules and R code
  - 26 Rcpp modules migrated to return data.table (inherits from data.frame)
  - Added `src/datatable_utils.h` - C++ helpers for data.table creation
  - Added `R/datatable-utils.R` - R utilities and backward compatibility
  - **Performance gains:** 5-15x faster batch operations, 8x faster formant extraction
  - Fast keyed lookups by time/formant/frequency columns
  - `rbindlist()` eliminates slow rbind loops (400+ operations in formant.R)
- **Critical R bottleneck refactoring:**
  - `formant.R`: Replaced nested rbind() → list + rbindlist() (8x faster)
  - `batch-processing.R`: Vectorized data.table merge (8x faster file pairing)
  - TextGrid filtering: 10-50x faster with keyed data.table lookups
- **Infrastructure updates:**
  - Package now requires `data.table (>= 1.14.0)` in Imports
  - All `@return` tags updated to reflect data.table return types
  - Comprehensive benchmarks in `inst/benchmarks/16_datatable_migration_benchmark.R`
  - Migration guide: `vignettes/articles/migration-guide.Rmd`
- **Build fixes:**
  - Fixed KlattGrid vignette segfaults (disabled execution during build)
  - All vignettes now render successfully in R CMD build

**v3.0.2 (2026-01-10):**
- **CRITICAL:** Fixed TextGrid export bug (missing NAMESPACE entry)
- Fixed pkgdown site build errors

**v3.0.1 (2026-01-10):**
- **Documentation restructure for pkgdown**
  - Created `_pkgdown.yml` with 15 function groups (450+ functions)
  - Added developer articles: migration-guide, naming-conventions, batch-operations-guide
  - Archived 48 historical docs to `docs-archive/`
- **Package metadata:** Added URL and BugReports to DESCRIPTION

**v3.0.0 (2026-01-10):**
- **BREAKING:** Removed deprecated functions and disabled batch analysis stubs
- Clean v3.0 baseline for data.table migration

**v2.4.2 (2026-01-10):**
- **Phase 5 investigation:** Analyzed disabled batch analysis functions (voice_quality_batch, etc.)
  - Conclusion: Not worth re-enabling due to Praat API changes and excellent existing alternatives
  - Existing batch queries + parallel processing already provide superior performance
  - Created `PHASE5_INVESTIGATION_SUMMARY.md` documenting findings
- **Documentation:** Clarified that improvement plan goals are already met through existing functionality

**v2.4.1 (2026-01-10):**
- Version bump for package maintenance

**v2.4.0 (2026-01-10):**
- **Deprecation cycle started** for duplicate batch query functions
  - `pitch_get_values_at_times()` → use `get_pitch_at_times()`
  - `formant_get_values_at_times()` → use `get_formants_at_times()`
  - `intensity_get_values_at_times()` → use `get_intensity_at_times()`
  - All deprecated functions emit `.Deprecated()` warnings
  - Will be removed in v3.0.0 (12+ month notice)
- **New guides:**
  - `vignettes/articles/migration-guide.Rmd` - Complete migration reference (v3.0 breaking changes)
  - `vignettes/articles/naming-conventions.Rmd` - Function naming patterns explained
- **Developer experience:** Clear guidance on API usage and deprecation timeline

**v2.3.0 (2026-01-10):**
- **Parallel processing API** (NEW - 3-8x speedup)
  - `analyze_files_parallel()` - Generic parallel file processing framework
  - `process_sounds_parallel()` - Parallel processing of pre-loaded sounds
  - `extract_pitch_parallel()`, `extract_formant_parallel()`, `extract_intensity_parallel()`
  - `benchmark_parallel()` - Find optimal core count
  - Auto-detects platform (mclapply on Unix, parLapply on Windows)
- **Complete Direct API coverage** (4 new functions)
  - `to_spectrum_direct()` - Create Spectrum (returns XPtr)
  - `to_spectrogram_direct()` - Create Spectrogram (returns XPtr)
  - `to_ltas_direct()` - Create LTAS (returns XPtr)
  - `to_point_process_direct()` - Create PointProcess (returns XPtr)
- **Comprehensive documentation:**
  - New vignette: `performance-optimization.Rmd` - Complete 3-tier API guide (500+ lines)
  - New article: `vignettes/articles/batch-operations-guide.Rmd` - All batch functions explained
  - Decision trees, benchmarks, best practices

**v2.2.7 (2026-01-09):**
- **Critical bug fixes:**
  - Fixed pointer extraction in 10 batch functions (batch-ops.R)
  - All batch functions now work with function-wrapper objects
  - PowerCepstrogram converted to function wrapper (consistent with other objects)
- **API consistency improvements:**
  - Added `extract_xptr()` utility - Unified pointer extraction
  - Added `unit_to_code()` utility - Standardized unit mapping
  - Added `interpolation_to_code()` utility - Standardized interpolation codes
- **New tests:** `test-batch-ops.R` - Comprehensive batch operation tests (210 lines)

**v2.2.6 (2026-01-09):**
- **File rename:** `powercepstrum-r6.R` → `powercepstrum.R` (was never R6)
- Added missing `print.PowerCepstrogram` S3 method
- **AGENT_GUIDE accuracy fixes:**
  - Corrected Direct API function names to match NAMESPACE exports
  - `get_pitch_value_direct()`, `get_pitch_stats_direct()`, `get_formants_direct()`

**v2.2.5 (2026-01-09):**
- **Critical bug fix:** Corrected `kCepstrum_trendFit` enum mapping for CPPS/AVQI
  - Fixed slope calculation discrepancy (R was -23.85 vs Praat -19.20)
  - Affected: `calculate_cpps_fast()`, `get_cpps_fast()`, PowerCepstrum trend methods
  - Root cause: R mapped "least_squares"=0, but Praat expects LEAST_SQUARES=2

**v2.2.4 (2026-01-09):**
- **Direct API** for maximum performance (2-3x faster than module dispatch)
  - `to_pitch_direct()`, `to_formant_direct()`, `to_intensity_direct()`, `to_harmonicity_direct()`
  - Direct query functions: `get_pitch_value_direct()`, `get_pitch_stats_direct()`, etc.
- **LTO (Link-Time Optimization)** enabled by default for 5-15% overall speedup

**v2.2.3 (2026-01-09):**
- **Architecture documentation complete** - Comprehensive investigation confirmed 30/31 objects use module pattern
- Added comprehensive technical reference: `docs/MODULE_VS_R6_DESIGN.md` (400+ lines, local only)
- Updated `.planning/REMAINING_R6_CLASSES.md` - marked conversion work complete (97% coverage)
- Documented PraatInterpreter R6 rationale - intentionally kept as R6 for stateful design
- Verified performance achievements: AVQI 2.1-2.4x faster, CPPS 1.5-2.0x faster

**v2.2.1 (2026-01-08):**
- Added batch statistics API: `pitch_get_statistics_batch()` (10-50x faster for multi-interval)
- Added XPtr window/transform functions via RcppXPtrUtils (70x faster custom DSP)
  - `apply_window_xptr()`, `apply_transform_xptr()`, `create_window_xptr()`
- Added RcppXPtrUtils to Suggests for optional custom function compilation

**v2.2.0 (2026-01-08):**
- Added fast CPPS API: `calculate_cpps_fast()` (1.5-2x faster for AVQI v3.01)
- Added `to_powercepstrogram_fast()`, `get_cpps_fast()` for two-step workflows

**v2.1.2 (2026-01-08):**
- Fixed AGENT_GUIDE pitch `get_quantile()` parameter order documentation
- Clarified that R API uses string units (not integer codes)
- Added Intensity `get_quantile()` method
- Documented `to_point_process_periodic_cc` parameter limitations

**v2.1.1 (2026-01-07):**
- Fixed class name checks (use `Formant`, `Pitch`, `Intensity` not `*_constructor`)
- Fixed interpolation codes for intensity
- Added method aliases (`get_xmin`, `get_xmax`) for consistency

**v2.1.0 (2026-01-07):**
- Added Interpreter module for persistent Praat script execution
- 33 total modules (92% coverage)

**v2.0.9 (2026-01-07):**
- Added batch query operations (3-10x faster)
- `get_formants_at_times`, `get_pitch_at_times`, `get_intensity_at_times`
- PointProcess batch operations

**v2.0.8 (2026-01-07):**
- Zero-copy data access
- TextGrid batch operations
- Module properties for fast access (`.cpp$property`)

---

**Guide Version:** 4.0.4
**Last Updated:** 2026-01-13
**Package Version:** 4.0.4
**Modules:** 33 (30/31 objects use modules, PraatInterpreter uses R6)
**Major Features:** 3-tier performance API (Standard/Direct/Batch), data.table integration, LTO optimization, AVQI-compatible VAD with ZCR (v4.0.4), specialized workflow functions (sound_concatenate_all, sound_load_window, textgrid_merge)
