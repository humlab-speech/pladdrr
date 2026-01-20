# pladdrr Agent Guide

**Version:** 4.4.1 (2026-01-20)
**Purpose:** Reference for LLM agents reimplementing Praat functionality via pladdrr

---

## Quick Start for Agents

This guide provides the **complete API reference** for pladdrr, an R package that provides direct access to Praat C++ functionality. When reimplementing Praat code in R:

1. **Object Creation**: Use function constructors (not R6 classes): `Sound()`, `Pitch()`, etc.
2. **Method Calls**: Use `$` syntax: `sound$to_pitch()`, `pitch$get_mean()`
3. **Units**: Specify as strings: `"hertz"`, `"bark"`, `"db"` (converted internally to codes)
4. **Class Names**: Use clean names for `inherits()` checks: `Formant`, `Pitch`, `Intensity` (not internal `*_constructor` names)
5. **Batch Operations**: Use batch query functions when extracting multiple values
6. **Vectorized Methods**: Use `$get_*_windows()`, `$get_*_vector()` for 20-150x speedups (Pattern 2i)
7. **Properties**: Fast access via `.cpp$property` or backward-compatible `get_property()` methods
8. **Pipeline Operations**: Use `two_pass_adaptive_pitch()` and `get_jitter_shimmer_batch()` for voice quality (Pattern 2k)
9. **Tier 4 Ultra API**: Use `get_durations_batch()`, `calculate_f0_stats_ultra()`, `calculate_minimum_intensity_ultra()`, `get_voice_quality_ultra()` for DSI workflows (Pattern 2l)

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
│   - 37 C++ module classes: RSound, RPitch, RMFCC, RPCA, etc.            │
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

**Performance Tiers (v4.4.0):**
| Tier | API | Speedup | Use Case |
|------|-----|---------|----------|
| **Tier 1 (Standard)** | `sound$to_pitch()` | 1x baseline | Interactive, <10 files |
| **Tier 2 (Direct)** | `to_pitch_direct()` | 2-3x | Loops, 10-100 files |
| **Tier 3 (Batch)** | `sound_to_pitch_batch()` | 5-10x | Production, >100 files |
| **Tier 4 (Ultra)** | `get_durations_batch()`, `calculate_f0_stats_ultra()` | 5-77x | DSI/clinical workflows |

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

**Converted Objects (34/35):** Sound, Pitch, Formant, Intensity, Spectrum, Spectrogram, Harmonicity, PointProcess, TextGrid, Ltas, PowerCepstrum, PowerCepstrogram, LPC, Cochleagram, Excitation, Cepstrum, Electroglottogram, Matrix, Table, VocalTract, PitchTier, FormantTier, FormantGrid, IntensityTier, AmplitudeTier, DurationTier, Manipulation, LongSound, KlattGrid, FormantPath, ComplexSpectrogram, Polygon, MFCC, LFCC, FormantModeler, PCA, Discriminant

**Intentionally R6 (1/31):** PraatInterpreter (requires persistent mutable state for script execution)

---

## Object Types (37 modules)

**Update v4.0.7:** Added MFCC, LFCC, FormantModeler, PCA, Discriminant modules for speaker recognition, robust formant tracking, and statistical analysis.

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
| `FormantModeler` | `formant$to_formant_modeler()` |
| `MFCC` | `sound$to_mfcc()` |
| `LFCC` | `lpc$to_lfcc()` |

### Statistical Analysis (NEW in v4.0.7)

| Type | Creation Method | Use Case |
|------|-----------------|----------|
| `PCA` | `pca_from_matrix(data)` | Dimensionality reduction, vowel space analysis |
| `Discriminant` | `discriminant_from_matrix(data, labels)` | Classification, speaker ID, vowel classification |

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

### Pattern 2d: Fast CPPS API (Updated v4.1.0 - Direct Sound→CPPS)

**v4.1.0 Major Performance Fix:** Removed debug output from Praat threading code, achieving **3x speedup** for CPPS and all multi-threaded operations. AVQI benchmark improved from 8x slower to **2.67x slower** than Python/Parselmouth.

**PowerCepstrogram converted to modules in v2.2.1** for 1.5-2x speedup in AVQI v3.01. By v2.2.3, all 30 analysis objects use modules.

For voice quality analysis, use the module-based API (now default) or fast helper functions:

```r
# RECOMMENDED (v4.1.0+): Direct Sound→CPPS path (single C++ call, no intermediate objects)
# PowerCepstrogram created and destroyed internally - no R/C++ boundary crossing
cpps <- calculate_cpps_fast(sound)  # Uses optimized defaults matching get_cpps()

# With custom parameters:
cpps <- calculate_cpps_fast(
  sound,
  subtract_tilt = TRUE,              # Default: TRUE (matches R6 get_cpps)
  time_averaging_window = 0.001,     # Default: 0.001
  quefrency_averaging_window = 0.0005, # Default: 0.0005
  pitch_floor = 60,
  pitch_ceiling = 333.3              # Default: 333.3
)

# STANDARD API: Two-step with R6 object (same performance, returns reusable object)
pcep <- sound$to_powercepstrogram(60, 0.002, 5000, 50)
cpps <- pcep$get_cpps(
  subtract_tilt = TRUE,
  time_averaging_window = 0.001,
  quefrency_averaging_window = 0.0005,
  pitch_floor = 60,
  pitch_ceiling = 333.3
)

# ADVANCED: Two-step for multiple CPPS calculations from same cepstrogram
pcep_ptr <- to_powercepstrogram_fast(sound, 60, 0.002, 5000, 50)
cpps1 <- get_cpps_fast(pcep_ptr, subtract_tilt = FALSE, pitch_floor = 60)
cpps2 <- get_cpps_fast(pcep_ptr, subtract_tilt = TRUE, pitch_floor = 80)
```

**Performance comparison (verified v4.1.0):**
| Version | AVQI Benchmark | vs Python |
|---------|---------------|-----------|
| v4.0.x (with debug output) | ~17s | 8.0x slower |
| **v4.1.0 (threading fix)** | **~5.7s** | **2.67x slower** |
| Python/Parselmouth | ~2.1s | baseline |

**Key v4.1.0 changes:**
- `calculate_cpps_fast()` now uses direct C++ path (Sound→CPPS in single call)
- Defaults aligned with R6 `get_cpps()` method for identical output
- Threading debug output removed from Praat's `MelderThread.cpp`
- Benefits ALL multi-threaded Praat operations (Pitch, Formant, CPPS, etc.)

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
- `to_point_process_from_sound_and_pitch(sound, pitch)` → PointProcess XPtr (multi-object)

**Pipeline functions (v4.3.0+):**
- `two_pass_adaptive_pitch(sound, ...)` → list(pitch, min_pitch, max_pitch, q1, q3)
- `get_jitter_shimmer_batch(pointprocess, sound, ...)` → list(11 voice quality metrics)

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

### Pattern 2i: Vectorized Object Methods (NEW in v4.0.13)

**Performance:** 20-150x faster than R loops by keeping iteration inside C++.

These methods avoid the 1-2ms R↔C++ boundary crossing overhead per call. Instead of looping in R and calling individual methods, use vectorized methods that loop in C++.

#### Sound Batch Window Operations

```r
# SLOW: R loop (1-2ms per call × 500 windows = 500-1000ms)
starts <- seq(0, 14.97, by = 0.03)  # 500 windows
ends <- starts + 0.03
powers <- vapply(seq_along(starts), function(i) {
  sound$get_power(starts[i], ends[i])
}, numeric(1))

# FAST: Single C++ call (all 500 windows in ~5ms = 100-150x speedup)
powers <- sound$get_power_windows(starts, ends)
rms_vals <- sound$get_rms_windows(starts, ends)
energies <- sound$get_energy_windows(starts, ends)
zcr_vals <- sound$get_zcr_windows(starts, ends, channel = 1)
```

#### Sound Vectorized Value Extraction

```r
# SLOW: R loop for amplitude extraction
times <- seq(0.01, 2.99, by = 0.001)  # 2980 time points
values <- vapply(times, function(t) sound$get_value_at_time(t), numeric(1))

# FAST: Single C++ call (20x speedup)
values <- sound$get_values_at_times(times, channel = 1, interpolation = "linear")

# Get all samples in a time range
values <- sound$get_values_in_range(from_time = 0.5, to_time = 1.5, channel = 1)
times <- sound$get_times_in_range(from_time = 0.5, to_time = 1.5)
```

#### Pitch Vectorized Operations

```r
pitch <- sound$to_pitch(0.01, 75, 500)

# Get all frame times and values at once
times <- pitch$get_times_vector()
values <- pitch$get_values_vector()

# Voiced/unvoiced mask (logical vector, TRUE = voiced)
voiced <- pitch$get_voiced_mask()
voiced_times <- times[voiced]
voiced_f0 <- values[voiced]

# Strengths and intensities
strengths <- pitch$get_strengths_vector(unit = "hertz")
intensities <- pitch$get_intensities_vector()

# Values at specific times (interpolated)
query_times <- seq(0.5, 2.5, by = 0.1)
f0_values <- pitch$get_values_at_times(query_times, unit = "hertz", interpolate = TRUE)
```

#### Harmonicity Batch Statistics

```r
hnr <- sound$to_harmonicity_ac(0.01, 75)

# Direct vector access
values <- hnr$get_values_vector()
times <- hnr$get_times_vector()

# Batch statistics for multiple windows (10x speedup for multi-band analysis)
starts <- c(0.5, 1.0, 1.5, 2.0)
ends <- c(1.0, 1.5, 2.0, 2.5)
metrics <- c("mean", "min", "max", "stdev")
stats <- hnr$get_statistics_batch(starts, ends, metrics)
# Returns: matrix[4 windows, 4 metrics]
```

#### Spectrum Vector Extraction

```r
spectrum <- sound$to_spectrum()

# Get all vectors at once (150x speedup for spectral analysis)
freqs <- spectrum$get_frequencies_vector()
powers <- spectrum$get_power_vector()
reals <- spectrum$get_real_vector()
imags <- spectrum$get_imaginary_vector()

# Band energies for multiple bands
fmins <- c(0, 500, 1000, 2000)
fmaxs <- c(500, 1000, 2000, 4000)
energies <- spectrum$get_band_energies(fmins, fmaxs)
densities <- spectrum$get_band_densities(fmins, fmaxs)
```

#### Formant Track Extraction

```r
formant <- sound$to_formant_burg(0.01, 5, 5500)

# Get complete formant tracks (20x speedup)
times <- formant$get_times_vector()
f1_track <- formant$get_formant_track(1, unit = "hertz")
f2_track <- formant$get_formant_track(2, unit = "hertz")
b1_track <- formant$get_bandwidth_track(1, unit = "hertz")

# Get all formant tracks as matrix
all_tracks <- formant$get_all_formant_tracks(max_formants = 4, unit = "hertz")
# Returns: matrix[n_frames, 4]

# Values at specific times
query_times <- seq(0.5, 2.5, by = 0.1)
f1_at_times <- formant$get_values_at_times(1, query_times, unit = "hertz")
```

#### Spectrogram Batch Queries

```r
spectrogram <- sound$to_spectrogram(window_length = 0.005, maximum_frequency = 5000)

# Get dimension vectors
times <- spectrogram$get_times_vector()
freqs <- spectrogram$get_frequencies_vector()

# Get frames and slices (50x speedup)
frame <- spectrogram$get_frame(time = 1.0)           # All freqs at one time
slice <- spectrogram$get_frequency_slice(freq = 1000) # One freq across all times

# Get multiple frames at once
query_times <- c(0.5, 1.0, 1.5, 2.0)
frames <- spectrogram$get_frames(query_times)  # matrix[n_freqs, 4]

# Band power over time
band_power <- spectrogram$get_band_power(fmin = 500, fmax = 2000)
# Returns: power in band for each time frame
```

#### TextGrid Batch Labels

```r
tg <- TextGrid("annotations.TextGrid")

# Get labels at multiple times (60x speedup for VUV analysis)
times <- seq(0.1, 9.9, by = 0.1)
labels <- tg$get_labels_at_times(tier_number = 1, times)

# Batch set interval texts
intervals <- c(1, 2, 3, 4)
texts <- c("hello", "world", "test", "end")
tg$set_interval_texts_batch(tier_number = 1, intervals, texts)
```

**Summary of vectorized methods:**

| Object | Method | Speedup | Use Case |
|--------|--------|---------|----------|
| Sound | `get_power_windows()`, `get_rms_windows()`, `get_energy_windows()` | 100-150x | AVQI windowed analysis |
| Sound | `get_values_at_times()`, `get_values_in_range()` | 20x | Tremor peak extraction |
| Pitch | `get_voiced_mask()`, `get_strengths_vector()` | 5x | DSI voicing analysis |
| Harmonicity | `get_statistics_batch()` | 10x | Multi-band HNR (VQ) |
| Spectrum | `get_power_vector()`, `get_band_energies()` | 150x | Pharyngeal analysis |
| Formant | `get_formant_track()`, `get_all_formant_tracks()` | 20x | Vowel space analysis |
| Spectrogram | `get_frame()`, `get_band_power()` | 50x | Time-frequency analysis |
| TextGrid | `get_labels_at_times()` | 60x | VUV segmentation |

---

### Pattern 2j: Batch API v4.0.14 (Advanced Optimizations)

**Performance:** 10-50x faster for specific analysis workflows (Pharyngeal, Tremor, DSI, AVQI).

These methods target specific performance bottlenecks identified in voice quality analysis pipelines.

#### LTAS Batch Peak Search (Pharyngeal: 36x → 3x)

```r
ltas <- sound$to_ltas(bandwidth = 100)

# SLOW: Individual peak searches (18 calls for Pharyngeal analysis)
fmins <- c(180, 380, 580)  # Search ranges for H1, H2, H3
fmaxs <- c(220, 420, 620)
for (i in seq_along(fmins)) {
  peak_val <- ltas$get_maximum(fmins[i], fmaxs[i])
  peak_freq <- ltas$get_frequency_of_maximum(fmins[i], fmaxs[i])
}

# FAST: Single batch call (18x speedup)
peaks <- ltas$get_peaks_batch(fmins, fmaxs, interpolation = "parabolic")
# Returns: data.frame(fmin, fmax, peak_value, peak_frequency)

# Also available:
minima <- ltas$get_minima_batch(fmins, fmaxs, interpolation = "parabolic")
# Returns: data.frame(fmin, fmax, min_value, min_frequency)

# Get LTAS values at specific frequencies
freqs <- c(100, 440, 880, 1000)
values <- ltas$get_values_at_frequencies(freqs, interpolation = "cubic")

# Get mean values in multiple bands
means <- ltas$get_means_batch(fmins, fmaxs, averaging_units = "energy")
```

#### Pitch Detrending (Tremor: 10x → 4x)

```r
pitch <- sound$to_pitch(pitch_floor = 75, pitch_ceiling = 600)

# SLOW: R-side detrending with lm() + predict() (~40ms)
values <- pitch$get_values_vector()
times <- pitch$get_times_vector()
model <- lm(values ~ times, na.action = na.exclude)
detrended <- residuals(model)

# FAST: Native Praat detrending (~4ms = 10x speedup)
detrended <- pitch$get_values_detrended(unit = "hertz")  # Returns NumericVector

# Or get a new detrended Pitch object
detrended_pitch <- pitch$subtract_linear_fit(unit = "hertz")  # Returns Pitch object

# Additional pitch processing methods (v4.0.14)
interpolated <- pitch$interpolate()      # Fill unvoiced gaps
smoothed <- pitch$smooth(bandwidth = 10) # Smooth pitch contour
cleaned <- pitch$kill_octave_jumps()     # Remove octave errors
```

#### Filtered Window Extraction (AVQI: 2.9x → 1.5x)

```r
sound <- Sound("recording.wav")

# SLOW: Extract each window separately, filter, concatenate
starts <- seq(0.0, 9.9, by = 0.1)
ends <- starts + 0.1
voiced_sounds <- list()
for (i in seq_along(starts)) {
  part <- sound$extract_part(starts[i], ends[i])
  power <- part$get_power()
  zcr <- part$get_zcr()
  if (power > 0.03 && zcr < 3000) {
    voiced_sounds <- c(voiced_sounds, list(part))
  }
}
result <- Reduce(function(a, b) a$combine(b), voiced_sounds)

# FAST: Single C++ call filters and concatenates (10x speedup)
result <- sound$extract_windows_filtered(
  window_starts = starts,
  window_ends = ends,
  min_power = 0.03,      # Minimum power threshold
  max_zcr = 3000,        # Maximum zero-crossing rate
  overlap_time = 0.0,    # Overlap for crossfade
  window_shape = "rectangular"  # or "hanning", "hamming", etc.
)

# Get filter mask only (for inspection)
passes <- sound$get_windows_passing_filter(starts, ends, min_power = 0.03, max_zcr = 3000)
# Returns: logical vector (TRUE = window passes filter)

# Concatenate multiple sounds efficiently
sounds_list <- list(sound1, sound2, sound3)
concatenated <- Sound$concatenate_sounds(sounds_list, overlap_time = 0.01)
```

#### PointProcess Batch Operations (DSI/Shimmer: 10-20x speedup)

```r
sound <- Sound$create_tone(frequency = 200, duration = 0.5)
pp <- sound$to_point_process_periodic_cc(pitch_floor = 75, pitch_ceiling = 600)

# SLOW: Get amplitude at each pulse point individually
for (i in 1:pp$get_number_of_points()) {
  t <- pp$get_time(i)
  val <- sound$get_value_at_time(t, channel = 1, interpolation = "cubic")
}

# FAST: Get all values in one call (20x speedup)
values <- pp$get_values_from_sound(sound, channel = 1, interpolation = "cubic")
# Returns: NumericVector of amplitude values at all pulse times

# Get all inter-point intervals (periods) efficiently
periods <- pp$get_periods_vector()  # All intervals
# Returns: NumericVector of length (n_points - 1)

# Get only periods within physiological range
filtered_periods <- pp$get_periods_filtered(min_period = 0.0001, max_period = 0.02)

# Get ALL jitter measures in one call (5x speedup vs individual calls)
jitter <- pp$get_jitter_batch(
  from_time = 0, to_time = 0,  # 0,0 = entire duration
  period_floor = 0.0001,
  period_ceiling = 0.02,
  max_period_factor = 1.3
)
# Returns: list(local, local_absolute, rap, ppq5, ddp)
```

#### Spectrum Power at Frequencies

```r
spectrum <- sound$to_spectrum()

# Get power at specific frequencies (Pharyngeal harmonic analysis)
freqs <- c(100, 440, 880, 1000)
powers <- spectrum$get_power_at_frequencies(freqs)
# Returns: NumericVector of power values (nearest bin, no interpolation)
```

**Summary of v4.0.14 batch methods:**

| Object | Method | Speedup | Use Case |
|--------|--------|---------|----------|
| LTAS | `get_peaks_batch()` | 18x | Pharyngeal harmonic peaks |
| LTAS | `get_minima_batch()` | 18x | Spectral valley detection |
| LTAS | `get_values_at_frequencies()` | 10x | Targeted frequency sampling |
| LTAS | `get_means_batch()` | 10x | Multi-band energy analysis |
| Pitch | `subtract_linear_fit()` | 10x | Tremor F0 detrending |
| Pitch | `get_values_detrended()` | 10x | Direct detrended values |
| Pitch | `interpolate()`, `smooth()` | 5x | Pitch post-processing |
| Sound | `extract_windows_filtered()` | 10x | AVQI voiced extraction |
| Sound | `get_windows_passing_filter()` | 5x | Filter mask inspection |
| PointProcess | `get_values_from_sound()` | 20x | Shimmer amplitude extraction |
| PointProcess | `get_periods_vector()` | 10x | Jitter period analysis |
| PointProcess | `get_jitter_batch()` | 5x | All jitter measures at once |
| Spectrum | `get_power_at_frequencies()` | 10x | Harmonic power extraction |

---

### Pattern 2k: Pipeline Operations (v4.3.0+)

**Performance:** 5-10x faster for multi-step analysis workflows.

Pipeline functions combine common multi-step workflows into single optimized calls.

#### Two-Pass Adaptive Pitch Extraction

**Problem:** Fixed pitch range often misses speaker's actual range (creaky voice = low, children = high).

**Solution:** `two_pass_adaptive_pitch()` - Speaker-adaptive pitch extraction in one call.

```r
# OLD WAY: Manual two-pass implementation (5+ function calls)
pitch_rough <- to_pitch_cc_direct(sound, pitch_floor = 50, pitch_ceiling = 800)
q1 <- get_pitch_quantile_direct(pitch_rough, 0.25, unit = "hertz")
q3 <- get_pitch_quantile_direct(pitch_rough, 0.75, unit = "hertz")
min_pitch <- q1 * 0.75
max_pitch <- q3 * 1.5
pitch_refined <- to_pitch_cc_direct(sound, pitch_floor = min_pitch, pitch_ceiling = max_pitch)

# NEW WAY: Single pipeline function (v4.3.0+)
result <- two_pass_adaptive_pitch(sound)
# Returns: list(pitch, min_pitch, max_pitch, q1, q3)

pitch_ptr <- result$pitch          # Refined pitch XPtr
speaker_range <- c(result$min_pitch, result$max_pitch)  # Speaker's pitch range

# Customization options:
result <- two_pass_adaptive_pitch(
  sound,
  initial_floor = 75,       # Start higher for known adult
  initial_ceiling = 500,    # Start lower for known adult
  voicing_threshold = 0.5,  # Stricter voicing detection
  q1_factor = 0.80,         # Less aggressive low bound (default: 0.75)
  q3_factor = 1.25,         # Less aggressive high bound (default: 1.5)
  method = "ac"             # Use autocorrelation method (default: "cc")
)
```

**Use cases:**
- Speaker-adaptive pitch tracking (unknown speaker demographics)
- Creaky voice analysis (needs lower floor detection)
- Child speech analysis (needs higher ceiling detection)
- Clinical voice analysis (abnormal pitch ranges)

#### Batch Voice Quality Metrics

**Problem:** Getting all jitter/shimmer measures requires 11 separate C++ calls.

**Solution:** `get_jitter_shimmer_batch()` - All 11 metrics in one C++ call.

```r
# Create PointProcess from Sound + Pitch
result <- two_pass_adaptive_pitch(sound)
pp <- to_point_process_from_sound_and_pitch(sound, result$pitch)

# OLD WAY: 11 separate calls
jitter_local <- pp$get_jitter_local(0, 0, 0.0001, 0.02, 1.3)
jitter_rap <- pp$get_jitter_rap(0, 0, 0.0001, 0.02, 1.3)
shimmer_local <- pp$get_shimmer_local(sound, 0, 0, 0.0001, 0.02, 1.3, 1.6)
# ... 8 more calls ...

# NEW WAY: Single batch call (v4.3.0+)
metrics <- get_jitter_shimmer_batch(pp, sound)
# Returns named list with all 11 metrics:
# $jitter_local, $jitter_local_abs, $jitter_rap, $jitter_ppq5, $jitter_ddp
# $shimmer_local, $shimmer_local_db, $shimmer_apq3, $shimmer_apq5, $shimmer_apq11, $shimmer_dda

# Extract what you need
jitter_local <- metrics$jitter_local
shimmer_apq3 <- metrics$shimmer_apq3

# Custom parameters
metrics <- get_jitter_shimmer_batch(
  pp, sound,
  from_time = 0.5, to_time = 1.5,   # Time range
  period_floor = 0.0001,             # Min period (default)
  period_ceiling = 0.02,             # Max period (default)
  max_period_factor = 1.3,           # Jitter threshold (default)
  max_amplitude_factor = 1.6         # Shimmer threshold (default)
)
```

#### Complete Voice Quality Workflow (v4.3.0)

**Combine both functions for optimal voice quality analysis:**

```r
# Load sound
sound <- Sound("patient_vowel.wav")

# Step 1: Adaptive pitch extraction (handles unknown speaker range)
pitch_result <- two_pass_adaptive_pitch(sound)

# Step 2: Create glottal pulses
pp <- to_point_process_from_sound_and_pitch(sound, pitch_result$pitch)

# Step 3: Get all voice quality metrics
metrics <- get_jitter_shimmer_batch(pp, sound)

# Step 4: Calculate additional measures
mean_f0 <- get_pitch_mean_direct(pitch_result$pitch)
stdev_f0 <- get_pitch_stdev_direct(pitch_result$pitch)
hnr <- mean(to_harmonicity_direct(sound)$values, na.rm = TRUE)

# Combine into report
voice_quality <- c(
  mean_f0 = mean_f0,
  stdev_f0 = stdev_f0,
  pitch_range = paste0(round(pitch_result$min_pitch), "-", round(pitch_result$max_pitch), " Hz"),
  hnr = hnr,
  metrics
)
```

| Function | Speedup | Use Case |
|----------|---------|----------|
| `two_pass_adaptive_pitch()` | 2x | Speaker-adaptive pitch extraction |
| `get_jitter_shimmer_batch()` | 5-10x | All 11 voice quality metrics |

#### API Reference: `two_pass_adaptive_pitch()`

**Signature:**
```r
two_pass_adaptive_pitch(
  sound,                      # Sound XPtr or R6 object
  time_step = 0,              # 0 = auto (0.75 / initial_floor)
  initial_floor = 50,         # Pass 1 pitch floor (Hz)
  initial_ceiling = 800,      # Pass 1 pitch ceiling (Hz)
  voicing_threshold = 0.45,   # Voicing detection threshold
  silence_threshold = 0.03,   # Silence detection threshold
  octave_cost = 0.01,         # Cost of octave jumps
  octave_jump_cost = 0.35,    # Cost of octave jump transitions
  voiced_unvoiced_cost = 0.14,# Cost of V→U transitions
  q1_factor = 0.75,           # min_pitch = Q1 * q1_factor
  q3_factor = 1.5,            # max_pitch = Q3 * q3_factor
  method = c("cc", "ac")      # "cc" (cross-correlation) or "ac" (autocorrelation)
)
```

**Returns:** Named list with:
| Element | Type | Description |
|---------|------|-------------|
| `pitch` | XPtr | Refined Pitch object from Pass 2 |
| `min_pitch` | numeric | Adaptive floor (Q1 × q1_factor), in Hz |
| `max_pitch` | numeric | Adaptive ceiling (Q3 × q3_factor), in Hz |
| `q1` | numeric | 25th percentile of Pass 1 F0, in Hz |
| `q3` | numeric | 75th percentile of Pass 1 F0, in Hz |

**Note:** If no voiced frames detected, returns Pass 1 pitch with initial range.

#### API Reference: `get_jitter_shimmer_batch()`

**Signature:**
```r
get_jitter_shimmer_batch(
  pointprocess,               # PointProcess XPtr or R6 object
  sound,                      # Sound XPtr or R6 object
  from_time = 0,              # Start time (0 = beginning)
  to_time = 0,                # End time (0 = end)
  period_floor = 0.0001,      # Min period (seconds)
  period_ceiling = 0.02,      # Max period (seconds)
  max_period_factor = 1.3,    # Jitter threshold
  max_amplitude_factor = 1.6  # Shimmer threshold
)
```

**Returns:** Named list with 11 metrics (all as **fractions**, not percentages):
| Element | Unit | Description |
|---------|------|-------------|
| `jitter_local` | fraction | Local jitter (relative period variation) |
| `jitter_local_abs` | seconds | Absolute local jitter |
| `jitter_rap` | fraction | Relative average perturbation |
| `jitter_ppq5` | fraction | 5-point period perturbation quotient |
| `jitter_ddp` | fraction | Difference of differences of periods |
| `shimmer_local` | fraction | Local shimmer (amplitude variation) |
| `shimmer_local_db` | dB | Local shimmer in decibels |
| `shimmer_apq3` | fraction | 3-point amplitude perturbation quotient |
| `shimmer_apq5` | fraction | 5-point amplitude perturbation quotient |
| `shimmer_apq11` | fraction | 11-point amplitude perturbation quotient |
| `shimmer_dda` | fraction | Difference of differences of amplitudes |

**To convert fractions to percentages:** Multiply by 100 (e.g., `jitter_local * 100`).

#### API Reference: `to_point_process_from_sound_and_pitch()`

**When to use this vs alternatives:**

| Method | When to Use | Praat Equivalent |
|--------|-------------|------------------|
| `to_point_process_from_sound_and_pitch(sound, pitch)` | **Recommended** for jitter/shimmer. Uses pitch-guided peak detection. | Select Sound + Pitch → "To PointProcess (cc)" |
| `sound$to_point_process_periodic_cc()` | Sound-only analysis. Less accurate for voice quality. | Select Sound → "To PointProcess (periodic, cc)" |
| `to_point_process_direct(sound)` | Direct API version of above. | Same as above |

**Why Sound+Pitch is better:**
- Uses refined pitch information to guide glottal pulse detection
- More accurate period identification for jitter/shimmer
- Matches Praat's recommended workflow for voice quality analysis
- Required for clinical voice assessment (DSI, AVQI, etc.)

**Example:**
```r
# RECOMMENDED: Use Sound + Pitch (matches Praat best practice)
pitch_result <- two_pass_adaptive_pitch(sound)
pp <- to_point_process_from_sound_and_pitch(sound, pitch_result$pitch)
metrics <- get_jitter_shimmer_batch(pp, sound)

# NOT RECOMMENDED for voice quality (less accurate):
pp <- sound$to_point_process_periodic_cc()  # Sound-only, no pitch guidance
```

---

### Pattern 2l: Tier 4 Ultra API (v4.4.0+)

**Performance:** 5-77x faster for DSI and clinical voice workflows.

Tier 4 "Ultra" functions keep entire analysis workflows in C++, returning only final scalars. Eliminates intermediate R6 object creation and R-side coordination.

#### `get_durations_batch()` - Fast WAV Duration Reading

**Problem:** Getting audio durations via `LongSound()` or `Sound()` loads entire file.

**Solution:** Read only 44-byte WAV header for instant duration extraction.

```r
# OLD WAY: Load entire file (slow for many files)
durations <- sapply(wav_files, function(f) {
  sound <- Sound(f)
  sound$get_xmax() - sound$get_xmin()
})

# NEW WAY: Header-only reading (77x faster)
durations <- get_durations_batch(wav_files)
```

**Signature:**
```r
get_durations_batch(file_paths)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `file_paths` | character | Vector of .wav file paths |

**Returns:** Numeric vector of durations (seconds). NA for invalid/missing files.

#### `calculate_f0_stats_ultra()` - Single-Call F0 Statistics

**Problem:** Getting F0 statistics requires creating Pitch object, then calling stat method.

**Solution:** Single C++ call returns statistic directly.

```r
# OLD WAY: Create intermediate Pitch object
pitch <- sound$to_pitch_cc(pitch_floor = 75, pitch_ceiling = 600)
max_f0 <- pitch$get_maximum(0, 0, "hertz", TRUE)

# NEW WAY: Direct statistic (5x faster)
max_f0 <- calculate_f0_stats_ultra(sound, stat = "max", min_pitch = 75, max_pitch = 600)
```

**Signature:**
```r
calculate_f0_stats_ultra(
  sound,                    # Sound object
  stat = "max",             # "max", "min", "mean", "median", "sd"
  time_step = 0,            # 0 = auto

  min_pitch = 75,           # Pitch floor (Hz)
  max_pitch = 600,          # Pitch ceiling (Hz)
  voicing_threshold = 0.45  # Voicing detection threshold
)
```

**Returns:** Single numeric value (Hz for pitch stats, NA if no voiced frames).

#### `calculate_minimum_intensity_ultra()` - Voiced-Region Intensity

**Problem:** DSI requires minimum intensity in voiced regions only—needs Pitch→PointProcess→TextGrid→Intensity pipeline.

**Solution:** Complete DSI-compliant pipeline in single C++ call.

**Algorithm (v4.4.1 - DSI compliant):**
1. Extract pitch with DSI parameters (`voicing_threshold=0.8`, `very_accurate=FALSE`)
2. Create PointProcess from Sound + Pitch
3. Create TextGrid with VUV segmentation (`maxPeriod=0.02`, `meanPeriod=0.01`)
4. Extract and **concatenate** all voiced intervals
5. Calculate intensity on concatenated sound (`minimum_pitch=60`, DSI standard)
6. Return minimum intensity from concatenated voiced regions

```r
# OLD WAY: Multi-step pipeline
pitch <- sound$to_pitch_cc(pitch_floor = 70, voicing_threshold = 0.8)
pp <- to_point_process_from_sound_and_pitch(sound, pitch)
tg <- pp$to_textgrid_vuv(0.02, 0.01)
# ... extract voiced intervals, concatenate, calculate intensity ...

# NEW WAY: Single call (6x faster, DSI-compliant)
min_int <- calculate_minimum_intensity_ultra(sound, min_pitch = 70)
```

**Signature:**
```r
calculate_minimum_intensity_ultra(
  sound,                 # Sound object
  min_pitch = 70,        # Pitch floor (Hz) for pitch extraction
  max_pitch = 600,       # Pitch ceiling (Hz) for pitch extraction
  time_step = 0,         # 0 = auto
  subtract_mean = TRUE   # Subtract mean for intensity calculation
)
```

**Returns:** Minimum intensity (dB) from concatenated voiced regions. NA if no voiced frames.

**Note:** Intensity calculation uses `minimum_pitch=60` internally (DSI standard), not the `min_pitch` parameter which is only for pitch extraction.

#### `get_voice_quality_ultra()` - Complete Voice Quality Metrics

**Problem:** Getting jitter/shimmer/HNR requires creating Pitch, PointProcess, then batch calls.

**Solution:** All metrics from single C++ call with selective computation.

```r
# OLD WAY: Multi-object pipeline
pitch <- sound$to_pitch_cc(pitch_floor = 75)
pp <- to_point_process_from_sound_and_pitch(sound, pitch)
metrics <- get_jitter_shimmer_batch(pp, sound)

# NEW WAY: Single call with selective metrics
vq <- get_voice_quality_ultra(sound, metrics = "all", min_pitch = 75)
# Or request specific metrics:
vq <- get_voice_quality_ultra(sound, metrics = "jitter", min_pitch = 75)
```

**Signature:**
```r
get_voice_quality_ultra(
  sound,                 # Sound object
  metrics = "all",       # "all", "jitter", "shimmer", "hnr", or vector
  min_pitch = 75,        # Pitch floor (Hz)
  max_pitch = 600,       # Pitch ceiling (Hz)
  time_step = 0          # 0 = auto
)
```

**Returns:** Named list with requested metrics:

| Metric Group | Elements |
|--------------|----------|
| `jitter` | `jitter_local`, `jitter_rap`, `jitter_ppq5`, `jitter_ddp` |
| `shimmer` | `shimmer_local`, `shimmer_local_db`, `shimmer_apq3`, `shimmer_apq5`, `shimmer_apq11`, `shimmer_dda` |
| `hnr` | `hnr_mean`, `hnr_sd` |

#### Complete DSI Workflow Example (v4.4.1)

**Dysphonia Severity Index calculation with Tier 4 Ultra:**

```r
# Load test files
mpt_file <- "maximum_phonation_time.wav"
fh_file <- "highest_frequency.wav"
im_file <- "lowest_intensity.wav"
ppq_file <- "sustained_vowel.wav"

# Tier 4 Ultra workflow (~195ms vs ~520ms with Tier 2/3)
max_mpt <- max(get_durations_batch(mpt_file))
max_f0 <- calculate_f0_stats_ultra(Sound(fh_file), "max", min_pitch = 70, max_pitch = 600)
min_int <- calculate_minimum_intensity_ultra(Sound(im_file), min_pitch = 70)  # Uses DSI-compliant algorithm
vq <- get_voice_quality_ultra(Sound(ppq_file), "jitter", min_pitch = 70)
jitter_ppq5 <- vq$jitter_ppq5

# DSI formula (add +10 dB calibration to min_int if needed)
dsi <- 0.13 * max_mpt + 0.0053 * max_f0 - 0.26 * min_int - 1.18 * (jitter_ppq5 * 100) + 12.4
```

| Function | Target Speedup | Use Case |
|----------|----------------|----------|
| `get_durations_batch()` | 77x | MPT measurement |
| `calculate_f0_stats_ultra()` | 5x | FH (highest frequency) |
| `calculate_minimum_intensity_ultra()` | 6x | IM (lowest intensity) |
| `get_voice_quality_ultra()` | 3.6x | PPQ (jitter) |

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

## Utility Functions

### Memory Pooling API

For batch segment extraction, reuses Sound allocations for 20-30% speedup:

```r
# Check pool efficiency
stats <- sound_pool_stats()
cat("Hit rate:", stats$hits / (stats$hits + stats$misses) * 100, "%\n")

# Clear pool to free memory
sound_pool_clear()

# Resize pool capacity (default: 32)
sound_pool_resize(64)
```

| Function | Description |
|----------|-------------|
| `sound_pool_stats()` | Get hit/miss statistics |
| `sound_pool_clear()` | Clear pool, free memory |
| `sound_pool_resize(max_size)` | Change pool capacity |
| `sound_pool_acquire(...)` | Internal: get Sound from pool |
| `sound_pool_release(xptr)` | Internal: return Sound to pool |

### Spectrum Filtering

Filter spectrum frequencies with Hann window smoothing:

```r
spectrum <- sound$to_spectrum()

# Pass band (keep 100-4000 Hz, smooth 100 Hz)
spectrum_pass_hann_band(spectrum, fmin = 100, fmax = 4000, smooth = 100)

# Stop band (remove 50-60 Hz hum)
spectrum_stop_hann_band(spectrum, fmin = 50, fmax = 60, smooth = 10)
```

### Sound Filtering

Apply frequency filters directly to Sound objects:

```r
# Bandpass filter (100-4000 Hz)
filtered <- sound_filter_pass_hann_band(sound, fmin = 100, fmax = 4000, smooth = 100)

# Bandstop filter (remove hum)
cleaned <- sound_filter_stop_hann_band(sound, fmin = 50, fmax = 60, smooth = 10)
```

### Sound Operations

Correlation and convolution functions:

```r
# Auto-correlation
autocorr <- sound_auto_correlate(sound, scaling = 4L, signal_outside = 1L)

# Cross-correlation between two sounds
xcorr <- sounds_cross_correlate(sound1, sound2, scaling = 4L)

# Convolve two sounds
convolved <- sounds_convolve(sound1, sound2, scaling = 4L)
```

### Zero-Copy Data Access

5-10x faster read-only access to Sound samples:

```r
# Fast zero-copy access (READ-ONLY - do not modify!)
samples <- get_sound_values_zerocopy(sound, channel = 1)
rms <- sqrt(mean(samples^2))  # Safe
peak <- max(abs(samples))      # Safe

# Check if vector is zero-copy
is_zerocopy_vector(samples)  # TRUE

# Matrix access (mono sounds only for zerocopy)
mat <- sound_as_matrix_zerocopy(sound, zerocopy = TRUE)

# Fast time vector computation
times <- get_sound_times_fast(sound)
```

**Warning:** Zero-copy vectors are READ-ONLY views into Praat memory. Modifying them corrupts data!

### SIMD Information

Check SIMD acceleration capabilities:

```r
info <- simd_info()
# Returns: enabled, available, architecture, batch_size_double, batch_size_float, version

# Common architectures:
# - AVX2: 4 doubles/operation (Intel/AMD x86_64)
# - SSE4.2: 2 doubles/operation (older x86_64)
# - NEON: 2 doubles/operation (ARM/Apple Silicon)

# Disable SIMD for testing
options(speaker.use_simd = FALSE)
```

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
| `pitch_to_pointprocess_peaks(pitch, include_maxima, include_minima)` | `Pitch, bool, bool` | `PointProcess` | `Sound_Pitch_to_PointProcess_peaks()` (NEW v4.0.9) |
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

### MFCC Methods (NEW in v4.0.7)

MFCC (Mel-Frequency Cepstral Coefficients) for speaker recognition and speech analysis.

| Method | Parameters | Return | Notes |
|--------|------------|--------|-------|
| `get_number_of_frames()` | - | `integer` | Total analysis frames |
| `get_number_of_coefficients()` | - | `integer` | Coefficients per frame (usually 12-13) |
| `get_xmin()`, `get_xmax()` | - | `numeric` | Time domain |
| `get_frame_time(frame)` | `int` | `numeric` | Time of frame center |
| `get_coefficients_at_frame(frame)` | `int` | `numeric vector` | All coefficients at frame |
| `get_all_coefficients()` | - | `matrix` | Frames × coefficients matrix |
| `lifter(from, to)` | `int, int` | `MFCC` | Apply liftering to coefficient range |
| `as_data_frame()` | - | `data.table` | Export to data.table |

**Creation:** `sound$to_mfcc(num_coefficients = 12, window_length = 0.015, time_step = 0.005, first_filter_freq = 100, filter_freq_delta = 100, max_freq = 0)`

### LFCC Methods (NEW in v4.0.7)

LFCC (Linear-Frequency Cepstral Coefficients) - alternative to MFCC with linear frequency scale.

| Method | Parameters | Return | Notes |
|--------|------------|--------|-------|
| `get_number_of_frames()` | - | `integer` | Total analysis frames |
| `get_number_of_coefficients()` | - | `integer` | Coefficients per frame |
| `get_coefficients_at_frame(frame)` | `int` | `numeric vector` | All coefficients at frame |
| `get_all_coefficients()` | - | `matrix` | Frames × coefficients matrix |
| `as_data_frame()` | - | `data.table` | Export to data.table |

**Creation:** `lpc$to_lfcc(num_coefficients = 12)` (from LPC object)

### FormantModeler Methods (NEW in v4.0.7)

Robust polynomial formant tracking with outlier detection.

| Method | Parameters | Return | Notes |
|--------|------------|--------|-------|
| `get_number_of_tracks()` | - | `integer` | Number of formant tracks |
| `get_number_of_parameters()` | - | `integer` | Polynomial order per track |
| `get_xmin()`, `get_xmax()` | - | `numeric` | Time domain |
| `get_coefficient_of_determination(track)` | `int` | `numeric` | R² for track |
| `get_model_value_at_time(track, time)` | `int, double` | `numeric` | Smoothed formant value |
| `get_residual_at_time(track, time)` | `int, double` | `numeric` | Deviation from model |
| `get_data_point_status(track, frame)` | `int, int` | `integer` | 1=valid, 0=outlier |
| `to_formant()` | - | `Formant` | Convert back to Formant |
| `process_outliers(sigma)` | `double` | `FormantModeler` | Mark outliers beyond sigma |
| `as_data_frame()` | - | `data.table` | Export modeled values |

**Creation:** `formant$to_formant_modeler(tmin, tmax, num_tracks = 4, num_params = 5)`

### PCA Methods (NEW in v4.0.7)

Principal Component Analysis for vowel space analysis and dimensionality reduction.

| Method | Parameters | Return | Notes |
|--------|------------|--------|-------|
| `get_number_of_components()` | - | `integer` | Number of principal components |
| `get_dimension()` | - | `integer` | Original data dimension |
| `get_number_of_observations()` | - | `integer` | Training data count |
| `get_eigenvalues()` | - | `numeric vector` | All eigenvalues |
| `get_eigenvalue(component)` | `int` | `numeric` | Single eigenvalue |
| `get_fraction_variance(from, to)` | `int, int` | `numeric` | Cumulative variance explained |
| `get_dimension_of_fraction(frac)` | `double` | `integer` | Components for variance fraction |
| `get_eigenvector(component)` | `int` | `numeric vector` | PC loadings |
| `get_eigenvectors()` | - | `matrix` | All PC loadings |
| `get_centroid()` | - | `numeric vector` | Data centroid |
| `project(data, num_dim)` | `matrix, int` | `matrix` | Project new data |
| `as_data_frame()` | - | `data.table` | Component summary |

**Creation:** `pca_from_matrix(data)` where rows are observations, columns are variables.

**Example - Vowel Space Analysis:**
```r
# F1, F2, F3 measurements for vowels
vowels <- matrix(c(
  700, 1200, 2500,  # /a/
  350, 2100, 2800,  # /i/
  450, 700, 2400    # /u/
), ncol = 3, byrow = TRUE)

pca <- pca_from_matrix(vowels)
pca$get_fraction_variance(1, 2)  # Variance in first 2 PCs
projected <- pca$project(new_vowels, num_dim = 2)  # Project to 2D
```

### Discriminant Methods (NEW in v4.0.7)

Linear Discriminant Analysis for classification (vowel ID, speaker ID, dialect classification).

| Method | Parameters | Return | Notes |
|--------|------------|--------|-------|
| `get_number_of_groups()` | - | `integer` | Number of classes |
| `get_number_of_functions()` | - | `integer` | Discriminant functions |
| `get_dimension()` | - | `integer` | Feature dimension |
| `get_number_of_observations(group)` | `int` | `integer` | Training samples in group |
| `get_total_observations()` | - | `integer` | Total training samples |
| `get_eigenvalues()` | - | `numeric vector` | Discriminant eigenvalues |
| `get_fraction_variance(from, to)` | `int, int` | `numeric` | Variance explained |
| `get_wilks_lambda(from)` | `int` | `numeric` | Wilks' Lambda statistic |
| `get_partial_discrimination_probability(n)` | `int` | `list` | Chi-squared test |
| `get_eigenvector(func)` | `int` | `numeric vector` | Discriminant function coefficients |
| `get_eigenvectors()` | - | `matrix` | All discriminant coefficients |
| `get_group_centroids()` | - | `matrix` | Group means in original space |
| `get_group_labels()` | - | `character vector` | Class names |
| `get_apriori_probabilities()` | - | `numeric vector` | Prior probabilities |
| `set_apriori_probability(group, p)` | `int, double` | - | Set prior for group |
| `as_data_frame()` | - | `data.table` | Function summary |

**Creation:** `discriminant_from_matrix(data, labels)` where labels is a character vector of group memberships.

**Example - Vowel Classification:**
```r
# Training data: F1, F2, F3 for labeled vowels
vowels <- matrix(c(
  700, 1200, 2500,  # /a/
  720, 1180, 2520,  # /a/
  350, 2100, 2800,  # /i/
  340, 2150, 2780   # /i/
), ncol = 3, byrow = TRUE)
labels <- c("a", "a", "i", "i")

lda <- discriminant_from_matrix(vowels, labels)
lda$get_wilks_lambda(1)  # Classification power (lower = better)
lda$get_group_centroids()  # Mean formants per vowel
```

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

**Available class names:** `Sound`, `Pitch`, `Formant`, `Intensity`, `Spectrum`, `Spectrogram`, `TextGrid`, `PointProcess`, `Harmonicity`, `Ltas`, `Cepstrum`, `PowerCepstrum`, `LPC`, `Cochleagram`, `Excitation`, `Matrix`, `Table`, `PitchTier`, `FormantTier`, `IntensityTier`, `AmplitudeTier`, `DurationTier`, `FormantGrid`, `Manipulation`, `KlattGrid`, `FormantPath`, `ComplexSpectrogram`, `Polygon`, `VocalTract`, `LongSound`, `Electroglottogram`, `MFCC`, `LFCC`, `FormantModeler`, `PCA`, `Discriminant`

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
# SLOW: R loop with repeated C++ calls (1-2ms per call overhead)
times <- seq(0, 2, by = 0.01)
f1_values <- numeric(length(times))
for (i in seq_along(times)) {
  f1_values[i] <- formant$get_value_at_time(1, times[i], "hertz")
}

# FAST: Batch query function (5-10x faster)
result <- get_formants_at_times(formant, times, formant_numbers = 1)
f1_values <- result$F1

# FASTEST: Vectorized object method (20x faster, loops in C++)
f1_track <- formant$get_formant_track(1, unit = "hertz")  # All frames at once

# Sound window operations (100-150x speedup)
starts <- seq(0, 14.97, by = 0.03)  # 500 windows
ends <- starts + 0.03
# SLOW: ~500-1000ms (1-2ms × 500)
powers <- vapply(seq_along(starts), function(i) sound$get_power(starts[i], ends[i]), numeric(1))
# FAST: ~5ms
powers <- sound$get_power_windows(starts, ends)

# Pitch voiced mask (5x speedup)
voiced_mask <- pitch$get_voiced_mask()  # Logical vector, TRUE = voiced
voiced_f0 <- pitch$get_values_vector()[voiced_mask]
```

**Rule:** If you're writing a loop that calls the same method repeatedly, check for a vectorized `$get_*_windows()`, `$get_*_vector()`, or `$get_*_track()` method first.

---

## File Locations

```
src/
├── modules/               # Rcpp Module C++ code (37 modules)
│   ├── module_common.h    # Unit codes, validation macros
│   ├── sound_module.cpp   # RSound class
│   ├── pitch_module.cpp   # RPitch class
│   ├── mfcc_module.cpp    # RMFCC, RLFCC classes (v4.0.7)
│   ├── pca_module.cpp     # RPCA class (v4.0.7)
│   ├── discriminant_module.cpp  # RDiscriminant class (v4.0.7)
│   ├── formantmodeler_module.cpp # RFormantModeler class (v4.0.7)
│   └── ...
├── praat.github.io/       # Praat C++ source
│   ├── fon/              # Core phonetic objects
│   │   ├── Sound.h
│   │   ├── Pitch.h
│   │   └── ...
│   ├── dwtools/          # Statistical analysis (PCA, Discriminant, MFCC)
│   └── melder/           # Error handling
├── datatable_utils.h      # C++ helpers for data.table creation (v4.0+)
R/
├── sound-wrapper.R        # Sound R wrapper (renamed from sound-r6-new.R in v4.0.7)
├── pitch-wrapper.R        # Pitch R wrapper (renamed from pitch-r6.R in v4.0.7)
├── formant-wrapper.R      # Formant R wrapper
├── mfcc-wrapper.R         # MFCC/LFCC R wrappers (v4.0.7)
├── pca-wrapper.R          # PCA R wrapper (v4.0.7)
├── discriminant-wrapper.R # Discriminant R wrapper (v4.0.7)
├── formantmodeler-wrapper.R # FormantModeler R wrapper (v4.0.7)
├── datatable-utils.R      # R data.table helpers (v4.0+)
├── parallel-batch.R       # Parallel processing (not exported)
├── zzz.R                  # Module loading
└── RcppExports.R          # Auto-generated (don't edit)
```

**File Naming Convention (v4.0.7):** All R wrapper files use `-wrapper.R` suffix (not `-r6.R`) to accurately reflect the function-wrapper pattern used instead of R6 classes.

---

## Quick Reference Card

**Updated for v4.0.14 - 3-Tier Performance API + data.table + ZCR + Batch API v4.0.14**

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

# === VECTORIZED OBJECT METHODS (20-150x faster, v4.0.13) ===
# Sound window operations (AVQI: 100-150x speedup)
powers <- sound$get_power_windows(starts, ends)
rms_vals <- sound$get_rms_windows(starts, ends)
values <- sound$get_values_at_times(times, channel = 1)

# Pitch vectors (DSI: 5x speedup)
voiced_mask <- pitch$get_voiced_mask()           # Logical: TRUE = voiced
f0_values <- pitch$get_values_vector()           # All frame values
strengths <- pitch$get_strengths_vector()

# Formant tracks (Vowel analysis: 20x speedup)
f1_track <- formant$get_formant_track(1)
all_tracks <- formant$get_all_formant_tracks(4)  # matrix[frames, 4]

# Spectrum vectors (Pharyngeal: 150x speedup)
powers <- spectrum$get_power_vector()
energies <- spectrum$get_band_energies(fmins, fmaxs)

# Spectrogram slices (50x speedup)
frame <- spectrogram$get_frame(time = 1.0)
band_power <- spectrogram$get_band_power(500, 2000)

# HNR batch stats (VQ: 10x speedup)
stats <- hnr$get_statistics_batch(starts, ends, c("mean", "min", "max"))

# TextGrid batch labels (VUV: 60x speedup)
labels <- tg$get_labels_at_times(tier = 1, times)

# === BATCH API v4.0.14 (10-50x faster for specific workflows) ===
# LTAS batch peak search (Pharyngeal: 18x speedup)
peaks <- ltas$get_peaks_batch(fmins, fmaxs)     # data.frame(fmin, fmax, peak_value, peak_frequency)
minima <- ltas$get_minima_batch(fmins, fmaxs)   # data.frame(fmin, fmax, min_value, min_frequency)

# Pitch detrending (Tremor: 10x speedup)
detrended <- pitch$get_values_detrended(unit = "hertz")  # NumericVector
detrended_pitch <- pitch$subtract_linear_fit(unit = "hertz")  # Pitch object

# Filtered window extraction (AVQI: 10x speedup)
voiced <- sound$extract_windows_filtered(starts, ends, min_power = 0.03, max_zcr = 3000)
passes <- sound$get_windows_passing_filter(starts, ends, min_power = 0.03, max_zcr = 3000)

# PointProcess batch (DSI/Shimmer: 20x speedup)
amplitudes <- pp$get_values_from_sound(sound, channel = 1, interpolation = "cubic")
periods <- pp$get_periods_vector()
jitter <- pp$get_jitter_batch(0, 0, 0.0001, 0.02, 1.3)  # list(local, local_abs, rap, ppq5, ddp)

# Spectrum at frequencies (Pharyngeal harmonics)
powers <- spectrum$get_power_at_frequencies(freqs)

# === FAST CPPS (1.5-2x faster AVQI) ===
cpps <- calculate_cpps_fast(sound, subtract_tilt = FALSE,
                             pitch_floor = 60, pitch_ceiling = 330)

# === VOICED EXTRACTION WITH ZCR (v4.0.4 - AVQI-compatible) ===
voiced <- extract_voiced_segments(sound, zcr_threshold = 3000, use_zcr = TRUE)
zcr_data <- sound_get_zcr(sound, window_duration = 0.03)  # Per-frame ZCR

# === XPTR WINDOWS (70x faster custom DSP) ===
hamming <- create_window_xptr("hamming")
windowed <- apply_window_xptr(sound, hamming)

# === MFCC/LFCC (v4.0.7 - Speaker Recognition) ===
mfcc <- sound$to_mfcc(num_coefficients = 12)
coeffs <- mfcc$get_all_coefficients()  # Frames × coefficients matrix

lpc <- sound$to_lpc_burg()
lfcc <- lpc$to_lfcc(num_coefficients = 12)

# === PCA (v4.0.7 - Dimensionality Reduction) ===
vowels <- matrix(c(700, 1200, 350, 2100, 450, 700), ncol = 2, byrow = TRUE)
pca <- pca_from_matrix(vowels)
projected <- pca$project(new_data, num_dim = 2)

# === DISCRIMINANT (v4.0.7 - Classification) ===
lda <- discriminant_from_matrix(vowels, labels = c("a", "i", "u"))
lda$get_wilks_lambda(1)  # Lower = better separation
lda$get_group_centroids()  # Class means

# === FORMANTMODELER (v4.0.7 - Robust Formant Tracking) ===
fm <- formant$to_formant_modeler(tmin = 0, tmax = 0, num_tracks = 4)
smoothed_f1 <- fm$get_model_value_at_time(track = 1, time = 0.5)

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
- **Many values from one object:** Use Vectorized Methods (`$get_*_vector()`, `$get_*_windows()`)
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

### pitch_to_pointprocess_peaks (NEW in v4.0.9)

**Purpose:** Extract amplitude peaks and/or troughs from a sound guided by pitch contour. Essential for **tremor analysis** (vocal amplitude modulation detection).

**Signature:** `sound$pitch_to_pointprocess_peaks(pitch, include_maxima = TRUE, include_minima = FALSE)`

**Parameters:**
- `pitch`: Pitch object (created with `sound$to_pitch()`)
- `include_maxima`: Include amplitude peaks (default: TRUE)
- `include_minima`: Include amplitude troughs (default: FALSE)

**Returns:** PointProcess object with timestamps of detected peaks/troughs

**Praat Equivalent:** `Sound & Pitch: To PointProcess (peaks)...`

**Use Case - Tremor Analysis:**

```r
# Step 1: Extract pitch contour
pitch <- sound$to_pitch(time_step = 0.0, pitch_floor = 75, pitch_ceiling = 600)

# Step 2: Extract amplitude peaks guided by pitch
pp_peaks <- sound$pitch_to_pointprocess_peaks(pitch, 
                                               include_maxima = TRUE, 
                                               include_minima = FALSE)

# Step 3: Get timestamps and amplitudes at peaks
peak_times <- pp_peaks$get_times()
peak_amplitudes <- sapply(peak_times, function(t) {
  sound$get_value_at_time(time = t, channel = 1, interpolation = 2)
})

# Step 4: Calculate tremor intensity (mean absolute deviation)
tremor_intensity <- 100 * mean(abs(peak_amplitudes))
```

**Why Use Pitch-Guided Detection:**
- **Accuracy:** Aligns peak detection with fundamental frequency periods
- **Robustness:** Filters out noise peaks that don't align with vocal fold cycles
- **Clinical Validity:** Matches Praat's established tremor analysis methodology

**Alternative - Both Peaks and Troughs:**

```r
# For comprehensive tremor analysis, analyze both peaks and troughs
pp_peaks <- sound$pitch_to_pointprocess_peaks(pitch, 
                                               include_maxima = TRUE, 
                                               include_minima = FALSE)
pp_troughs <- sound$pitch_to_pointprocess_peaks(pitch, 
                                                 include_maxima = FALSE, 
                                                 include_minima = TRUE)

# Calculate separate intensities
peak_intensity <- calculate_intensity_at_points(sound, pp_peaks)
trough_intensity <- calculate_intensity_at_points(sound, pp_troughs)
tremor_intensity <- (peak_intensity + trough_intensity) / 2
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

**v4.3.0 (2026-01-19):**
- **NEW: Pipeline Operations** - Composite functions for common analysis workflows
  - `two_pass_adaptive_pitch(sound, ...)` - Two-pass adaptive pitch extraction
    - Pass 1: Wide range (50-800 Hz) to find speaker's actual range
    - Pass 2: Refined range based on Q1/Q3 (default: Q1×0.75 to Q3×1.5)
    - Returns: list(pitch, min_pitch, max_pitch, q1, q3)
    - Handles unvoiced sounds gracefully (returns initial range)
    - Supports both AC and CC methods via `method` parameter
  - `get_jitter_shimmer_batch(pointprocess, sound, ...)` - All 11 voice quality metrics in single C++ call
    - Jitter: local, local_abs, rap, ppq5, ddp
    - Shimmer: local, local_db, apq3, apq5, apq11, dda
    - 5-10x faster than calling individual methods
- **Performance improvement:** Complete voice quality workflow in 3 function calls vs 15+

**v4.0.14 (2026-01-18):**
- **NEW: Batch API v4.0.14** - Targeted optimizations for voice quality analysis pipelines
  - **LTAS:** `get_peaks_batch()`, `get_minima_batch()`, `get_values_at_frequencies()`, `get_means_batch()` (18x for Pharyngeal)
  - **Pitch:** `subtract_linear_fit()`, `get_values_detrended()`, `interpolate()`, `smooth()`, `kill_octave_jumps()` (10x for Tremor)
  - **Sound:** `extract_windows_filtered()`, `get_windows_passing_filter()`, `concatenate_sounds()` (10x for AVQI)
  - **PointProcess:** `get_values_from_sound()`, `get_periods_vector()`, `get_periods_filtered()`, `get_jitter_batch()` (20x for DSI/Shimmer)
  - **Spectrum:** `get_power_at_frequencies()` (10x for harmonic analysis)
- **Performance targets achieved:**
  - Pharyngeal analysis: 36x slower → ~3x slower than Python/Parselmouth
  - Tremor analysis: 10x slower → ~4x slower
  - AVQI analysis: 2.9x slower → ~1.5x slower
- **AGENT_GUIDE updated:** Added Pattern 2j with comprehensive batch API documentation

**v4.0.13 (2026-01-17):**
- **NEW: Vectorized Object Methods (20-150x speedup)** - Loop inside C++ instead of R
  - Eliminates 1-2ms R↔C++ boundary crossing overhead per call
  - **Sound:** `get_power_windows()`, `get_rms_windows()`, `get_energy_windows()`, `get_zcr_windows()` (100-150x for AVQI)
  - **Sound:** `get_values_at_times()`, `get_values_in_range()`, `get_times_in_range()` (20x for Tremor)
  - **Pitch:** `get_voiced_mask()`, `get_strengths_vector()`, `get_values_at_times()`, `get_intensities_vector()` (5x for DSI)
  - **Harmonicity:** `get_statistics_batch()`, `get_values_vector()`, `get_times_vector()` (10x for VQ)
  - **Spectrum:** `get_frequencies_vector()`, `get_power_vector()`, `get_real_vector()`, `get_imaginary_vector()`, `get_band_energies()`, `get_band_densities()` (150x for Pharyngeal)
  - **Formant:** `get_formant_track()`, `get_bandwidth_track()`, `get_all_formant_tracks()`, `get_values_at_times()` (20x for vowel analysis)
  - **Spectrogram:** `get_frame()`, `get_frequency_slice()`, `get_frames()`, `get_band_power()` (50x for time-frequency)
  - **TextGrid:** `get_labels_at_times()`, `set_interval_texts_batch()` (60x for VUV)
- **AGENT_GUIDE updated:** Added Pattern 2i with comprehensive vectorized method documentation

**v4.0.12 (2026-01-16):**
- **CRITICAL:** Fixed `TextGrid()` constructor export
  - `TextGrid()` had `@export` roxygen tag but was missing from NAMESPACE
  - Now properly exported: `TextGrid("file.TextGrid")` works without `pladdrr::` prefix
- **Build fix:** Removed 9 spurious NAMESPACE exports (`C++`, `in`, `Get`, `a`, `all`, `call`, `from`, `intervals`, `single`, `tier`)
  - These were incorrectly parsed from Praat command documentation and caused install failures

**v4.0.7 (2026-01-15):**
- **NEW: 4 statistical/cepstral modules** (37 total modules)
  - `MFCC` - Mel-Frequency Cepstral Coefficients for speaker recognition
    - `sound$to_mfcc(num_coefficients, window_length, time_step, ...)`
    - Methods: `get_coefficients_at_frame()`, `get_all_coefficients()`, `lifter()`
  - `LFCC` - Linear-Frequency Cepstral Coefficients (alternative to MFCC)
    - `lpc$to_lfcc(num_coefficients)` - Create from LPC object
    - Same query methods as MFCC
  - `FormantModeler` - Robust polynomial formant tracking
    - `formant$to_formant_modeler(tmin, tmax, num_tracks, num_params)`
    - Methods: `get_model_value_at_time()`, `process_outliers()`, `to_formant()`
    - Use case: Improved formant estimation with outlier detection
  - `PCA` - Principal Component Analysis
    - `pca_from_matrix(data)` - Create from numeric matrix
    - Methods: `get_eigenvalues()`, `get_eigenvectors()`, `project()`, `get_fraction_variance()`
    - Use case: Vowel space dimensionality reduction
  - `Discriminant` - Linear Discriminant Analysis
    - `discriminant_from_matrix(data, labels)` - Create from labeled data
    - Methods: `get_wilks_lambda()`, `get_group_centroids()`, `get_eigenvectors()`
    - Use case: Vowel classification, speaker identification
- **File naming standardization:**
  - Renamed 30 R wrapper files: `*-r6.R` → `*-wrapper.R`
  - Reflects actual function-wrapper pattern (not R6 classes)
  - No breaking changes to API - only internal file names changed
- **Sound methods added:**
  - `sound$to_mfcc()` - Extract MFCC from audio
  - `sound$to_formant_optimal()` - Find optimal formant ceiling
  - `sound$get_optimal_formant_ceiling()` - Ceiling search for speaker
- **LPC method added:**
  - `lpc$to_lfcc()` - Convert LPC to LFCC
- **Formant method added:**
  - `formant$to_formant_modeler()` - Create robust formant model

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

**v4.1.0 (2026-01-19):**
- **MAJOR PERFORMANCE FIX:** Removed debug `fprintf(stderr)` from Praat threading code
  - Root cause: `MelderThread.cpp` had debug output executing for every threaded frame
  - Impact: **3x speedup** for CPPS; AVQI benchmark improved from 8x to **2.67x** vs Python
  - Affects ALL multi-threaded Praat operations: CPPS, Pitch, Formant, etc.
- **New direct CPPS API:** `sound_to_cpps_direct()` C++ function
  - Single C++ call: Sound → CPPS (PowerCepstrogram kept internal, no R/C++ boundary)
  - `calculate_cpps_fast()` now uses this optimized path
- **Default alignment:** `calculate_cpps_fast()` defaults now match R6 `get_cpps()` method
  - `subtract_tilt = TRUE`, `time_averaging_window = 0.001`, `quefrency_averaging_window = 0.0005`
  - `pitch_ceiling = 333.3`, `qstart_fit = 0.003`, `qend_fit = 0.04`
  - Output verified identical (difference = 0.0 dB)

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

**Guide Version:** 4.1.1
**Last Updated:** 2026-01-19
**Package Version:** 4.1.1
**Modules:** 37 (34/35 objects use modules, PraatInterpreter uses R6)
**Major Features:** 3-tier performance API (Standard/Direct/Batch), data.table integration, LTO optimization, AVQI-compatible VAD with ZCR, specialized workflow functions, statistical analysis (PCA, Discriminant), cepstral coefficients (MFCC, LFCC), robust formant tracking (FormantModeler), **v4.1.0 threading performance fix (3x speedup for multi-threaded ops)**
