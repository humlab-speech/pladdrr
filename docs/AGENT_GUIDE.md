# pladdrr Agent Guide

**Version:** 2.2.6 (2026-01-09)
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

## Architecture Overview (v2.2.6 - Module-Based with Performance APIs)

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
│ DIRECT API    │  │ Module API    │  │ Standard R Wrapper    │
│ (Fastest)     │  │ (Fast)        │  │ (Convenient)          │
│               │  │               │  │                       │
│ to_*_direct() │  │ .cpp$method() │  │ object$method()       │
│ *_direct()    │  │               │  │                       │
│ 2-3x faster   │  │ 1.5-2x faster │  │ Full features         │
└───────────────┘  └───────────────┘  └───────────────────────┘
        │                   │                   │
        └───────────────────┼───────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ Rcpp Module Layer (src/modules/*.cpp)                       │
│   - 33 C++ module classes: RSound, RPitch, RPowerCepstrogram│
│   - XPtr<structPitch> wrapping Praat objects               │
│   - Direct API: praat_direct.cpp (bypasses all R overhead)  │
│   - Object Pool: sound_pool.cpp (memory reuse)             │
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

**Performance Tiers (v2.2.6):**
| Tier | API | Speedup | Use Case |
|------|-----|---------|----------|
| Direct | `to_pitch_direct()`, `*_direct()` | 2-3x | Hot loops, batch processing |
| Module | `object$.cpp$method()` | 1.5-2x | Performance-critical code |
| Standard | `object$method()` | Baseline | General use, full features |

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

### Pattern 2b: Batch Queries (NEW in v2.0.9)

**Performance:** 3-10x faster than loops by reducing R↔C++ boundary crossings.

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
- `get_formants_at_times(formant, times, formant_numbers = 1:4, unit = "hertz")`
- `get_formant_bandwidths_at_times(formant, times, formant_numbers, unit)`
- `get_pitch_at_times(pitch, times, unit = "hertz", interpolate = TRUE)`
- `get_pitch_strengths_at_times(pitch, times, unit, interpolate)`
- `get_intensity_at_times(intensity, times, interpolate = "cubic")`
- `get_pointprocess_times(pointprocess)`
- `get_pointprocess_intervals(pointprocess)`
- `get_pointprocess_nearest_indices(pointprocess, times)`

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

### Pattern 2f: Direct API Functions (NEW in v2.2.4)

**Performance:** 2-3x faster than R6/module dispatch for hot paths.

When maximum performance is critical (tight loops, batch processing), use Direct API functions that bypass all R wrapper overhead:

```r
# STANDARD: Module-based (good performance, full features)
pitch <- sound$to_pitch()
mean_f0 <- pitch$get_mean(0, 0, "hertz")

# DIRECT API: Bypass all R dispatch (maximum performance)
pitch_ptr <- to_pitch_direct(sound$.xptr)
f0_value <- get_pitch_value_direct(pitch_ptr, time = 1.0, unit = 0L, interpolate = TRUE)

# Create analysis objects directly
formant_ptr <- to_formant_direct(sound$.xptr)
intensity_ptr <- to_intensity_direct(sound$.xptr)
harmonicity_ptr <- to_harmonicity_direct(sound$.xptr)
```

**Direct API functions for object creation:**
- `to_pitch_direct(sound_xptr, time_step, pitch_floor, pitch_ceiling)` → Pitch XPtr
- `to_formant_direct(sound_xptr, time_step, max_formants, max_formant, window_length, pre_emphasis)` → Formant XPtr
- `to_intensity_direct(sound_xptr, minimum_pitch, time_step, subtract_mean)` → Intensity XPtr
- `to_harmonicity_direct(sound_xptr, time_step, minimum_pitch, silence_threshold, periods_per_window)` → Harmonicity XPtr

**Direct API functions for queries (use integer unit codes):**
- `get_pitch_value_direct(pitch_xptr, time, unit, interpolate)` - Single F0 value
- `get_pitch_stats_direct(pitch_xptr, from_time, to_time, unit)` - All pitch statistics
- `get_formant_value_direct(formant_xptr, formant_number, time, unit)` - Single formant
- `get_formants_direct(formant_xptr, time, unit)` - All formants at time
- `get_intensity_value_direct(intensity_xptr, time, interpolation)` - Single intensity

**Compound operations (single C++ call for multiple stats):**
```r
# Get all common pitch statistics in one call
stats <- get_pitch_stats_direct(pitch_ptr, 0, 0, 0L)
# Returns: list(min, max, mean, stdev, median, q25, q75, count_voiced)

# Get all formants at single time point
formants <- get_formants_direct(formant_ptr, time = 1.0, unit = 0L)
# Returns: numeric vector of formant values
```

### Pattern 2g: Object Pool for Batch Processing (NEW in v2.2.4)

**Performance:** 20-30% faster for batch segment extraction.

When extracting many sound segments (e.g., for interval-based analysis), use the object pool to reuse memory allocations:

```r
# Define extraction intervals
starts <- c(0.1, 0.5, 1.0, 1.5, 2.0)
ends <- c(0.3, 0.7, 1.2, 1.7, 2.2)

# STANDARD: Each extraction allocates new memory
for (i in seq_along(starts)) {
  segment <- sound$extract_part(starts[i], ends[i])
  # ... process segment
}

# POOLED: Reuse memory allocations (20-30% faster)
segments <- sound_extract_parts_pooled(sound$.xptr, starts, ends, use_pool = TRUE)
for (seg_ptr in segments) {
  # ... process segment
  sound_pool_release(seg_ptr)  # Return to pool for reuse
}

# Check pool efficiency
stats <- sound_pool_stats()
cat("Hit rate:", stats$hit_rate, "%\n")

# Clear pool when done (optional - frees memory)
sound_pool_clear()
```

**Object pool functions:**
- `sound_extract_parts_pooled(sound_xptr, start_times, end_times, use_pool)` - Batch extract with pooling
- `sound_pool_stats()` - Get pool hit/miss statistics
- `sound_pool_clear()` - Clear pool and free memory
- `sound_pool_resize(max_size)` - Set maximum pool size
- `sound_pool_acquire(xmin, xmax, nx, dx, x1, ny)` - Low-level acquire (internal)
- `sound_pool_release(sound_xptr)` - Return Sound to pool

### Pattern 2h: TextGrid XPtr Predicates (NEW in v2.2.4)

**Performance:** 50-70x faster than R predicate callbacks for interval filtering.

When filtering TextGrid intervals by label patterns, use compiled C++ predicates:

```r
# SLOW: R function callback (50-70x slower)
intervals <- textgrid_get_intervals_where(
  tg, tier = 1,
  predicate = function(label) grepl("^[aeiou]", label)
)

# FAST: Compiled C++ predicate
vowel_pred <- get_interval_predicate("starts_with_vowel")
intervals <- textgrid_filter_xptr(tg$.xptr, tier = 1L, vowel_pred)

# Available predicates:
# - "non_empty" - Label is not empty
# - "starts_with_vowel" - Starts with a/e/i/o/u (case-insensitive)
# - "is_silence" - Common silence markers (#, sil, sp, pause, <sil>)
```

**TextGrid XPtr functions:**
- `get_interval_predicate(type)` - Get compiled predicate by name
- `textgrid_filter_xptr(tg_xptr, tier, predicate_xptr)` - Filter intervals with XPtr predicate

---

### Pattern 3: Export to Data Frame

```r
# All objects support as.data.frame()
pitch_df <- as.data.frame(pitch)           # time, f0
formant_df <- as.data.frame(formant)       # time, f1, f2, f3, ...
intensity_df <- as.data.frame(intensity)   # time, intensity

# With options
pitch_df <- pitch$as_data_frame(
  include_strength = TRUE,
  include_intensity = TRUE
)
```

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
duration <- praat_evaluate_numeric("duration")
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
R/
├── sound-r6-new.R         # Sound R wrapper
├── pitch-r6.R             # Pitch R wrapper
├── formant-r6.R           # Formant R wrapper
├── zzz.R                  # Module loading
└── RcppExports.R          # Auto-generated (don't edit)
```

---

## Quick Reference Card

**Updated for v2.2.6**

```r
# === LOAD AUDIO ===
sound <- Sound("audio.wav")

# === CORE ANALYSES ===
pitch <- sound$to_pitch_cc(time_step = 0, pitch_floor = 75, pitch_ceiling = 600)
formant <- sound$to_formant_burg()
intensity <- sound$to_intensity()

# === QUERY AT TIME (single point) ===
f0 <- pitch$get_value_at_time(1.0, "hertz")
f1 <- formant$get_value_at_time(1, 1.0, "hertz")
f2 <- formant$get_value_at_time(2, 1.0, "hertz")
db <- intensity$get_value_at_time(1.0, "cubic")

# === BATCH QUERIES (3-10x faster for multiple points) ===
times <- seq(0.5, 2.5, by = 0.01)
formants <- get_formants_at_times(formant, times, 1:4)  # Returns list(F1, F2, F3, F4)
f0_contour <- get_pitch_at_times(pitch, times, "hertz")
db_contour <- get_intensity_at_times(intensity, times, "cubic")

# === BATCH STATISTICS (10-50x faster for multi-interval) ===
from_times <- seq(0, 9, length.out = 100)
to_times <- from_times + 0.1
stats <- pitch_get_statistics_batch(pitch$.xptr, from_times, to_times,
                                     c("min", "max", "mean", "stdev"), 0L)

# === DIRECT API (2-3x faster, bypasses R dispatch) [v2.2.4] ===
pitch_ptr <- to_pitch_direct(sound$.xptr)
f0_value <- get_pitch_value_direct(pitch_ptr, 1.0, 0L, TRUE)
all_stats <- get_pitch_stats_direct(pitch_ptr, 0, 0, 0L)

# === OBJECT POOL (20-30% faster batch extraction) [v2.2.4] ===
segments <- sound_extract_parts_pooled(sound$.xptr, starts, ends, use_pool = TRUE)
sound_pool_stats()  # Check hit rate
sound_pool_clear()  # Free memory

# === TEXTGRID XPTR PREDICATES (50-70x faster filtering) [v2.2.4] ===
pred <- get_interval_predicate("non_empty")
intervals <- textgrid_filter_xptr(tg$.xptr, 1L, pred)

# === FAST CPPS (1.5-2x faster AVQI) ===
cpps <- calculate_cpps_fast(sound, subtract_tilt = FALSE,
                             pitch_floor = 60, pitch_ceiling = 330)

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

---

## Known Limitations

### to_point_process_periodic_cc Parameters

The R wrapper accepts `time_step`, `max_period_factor`, and `max_amplitude_factor` parameters for API compatibility with Praat's GUI, but **only `pitch_floor` and `pitch_ceiling` are currently used**. The underlying Praat C function `Sound_to_PointProcess_periodic_cc()` only accepts minimum and maximum pitch.

```r
# These parameters are used:
pp <- sound$to_point_process_periodic_cc(pitch_floor = 75, pitch_ceiling = 600)

# These parameters are accepted but ignored:
# time_step, max_period_factor, max_amplitude_factor
```

---

## Version History

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
- **Object Pool** for batch segment extraction (20-30% faster)
  - `sound_extract_parts_pooled()`, `sound_pool_stats()`, `sound_pool_clear()`
- **TextGrid XPtr Predicates** for interval filtering (50-70x faster)
  - `get_interval_predicate()`, `textgrid_filter_xptr()`
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

**Guide Version:** 2.2.6
**Last Updated:** 2026-01-09
**Package Version:** 2.2.6
**Modules:** 33 (30/31 objects use modules, PraatInterpreter uses R6)
