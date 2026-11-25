# Agent Guide: Common Patterns

Part of the [Agent
Guide](https://humlab-speech.github.io/pladdrr/articles/agents/agent-guide.md).

## Common Patterns

### Pattern 1: Sound → Analysis Object

``` r
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

``` r
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

**Performance:** 5-10x faster than loops by reducing R↔︎C++ boundary
crossings.

``` r
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

**Key batch query functions:** -
`get_formants_at_times(formant, times, formant_numbers = 1:4, unit = "hertz")` -
10-20x faster -
`get_formant_bandwidths_at_times(formant, times, formant_numbers, unit)` -
10-20x faster -
`get_pitch_at_times(pitch, times, unit = "hertz", interpolate = TRUE)` -
5-10x faster -
`get_pitch_strengths_at_times(pitch, times, unit, interpolate)` - 5-10x
faster -
`get_intensity_at_times(intensity, times, interpolate = "cubic")` -
5-10x faster - `get_pointprocess_times(pointprocess)` - All times in one
call - `get_pointprocess_intervals(pointprocess)` - All intervals in one
call - `get_pointprocess_nearest_indices(pointprocess, times)` -
Vectorized nearest point lookup

**Deprecated functions (v2.4.0):** The following functions are
deprecated and will be removed in v5.0.0. Use the recommended
alternatives: - `pitch_get_values_at_times()` → use
[`get_pitch_at_times()`](https://humlab-speech.github.io/pladdrr/reference/get_pitch_at_times.md)
instead - `formant_get_values_at_times()` → use
[`get_formants_at_times()`](https://humlab-speech.github.io/pladdrr/reference/get_formants_at_times.md)
instead - `intensity_get_values_at_times()` → use
`intensity$get_values_at_times()` instead (v4.8.22+)

See `vignettes/articles/migration-guide.Rmd` for details.

### Pattern 2c: Batch Statistics (NEW in v2.2.1)

**Performance:** 10-50x faster than loops for multi-interval statistics.

When you need statistics (min, max, mean, stdev, quartiles) over
**multiple time intervals**, use batch statistics functions:

``` r
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

**Batch statistics functions:** -
`pitch_get_statistics_batch(pitch_xptr, from_times, to_times, metrics, unit)` -
Metrics: `"min"`, `"max"`, `"mean"`, `"stdev"`, `"q25"`, `"q50"`,
`"q75"`, `"count_voiced"`

### Pattern 2d: Fast CPPS API (Updated v4.1.0 - Direct Sound→CPPS)

**v4.1.0 Major Performance Fix:** Removed debug output from Praat
threading code, achieving **3x speedup** for CPPS and all multi-threaded
operations. AVQI benchmark improved from 8x slower to **2.67x slower**
than Python/Parselmouth.

**PowerCepstrogram converted to modules in v2.2.1** for 1.5-2x speedup
in AVQI v3.01. By v4.8.33, all 35 wrappers use shared dispatch tables.

For voice quality analysis, use the module-based API (now default) or
fast helper functions:

``` r
# RECOMMENDED (v4.1.0+): Direct Sound→CPPS path (single C++ call, no intermediate objects)
# PowerCepstrogram created and destroyed internally - no R/C++ boundary crossing
cpps <- calculate_cpps_fast(sound)  # Uses optimized defaults matching get_cpps()

# With custom parameters:
cpps <- calculate_cpps_fast(
  sound,
   subtract_tilt = TRUE,              # Default: TRUE (matches get_cpps)
  time_averaging_window = 0.001,     # Default: 0.001
  quefrency_averaging_window = 0.0005, # Default: 0.0005
  pitch_floor = 60,
  pitch_ceiling = 333.3              # Default: 333.3
)

# STANDARD API: Two-step with wrapper object (same performance, returns reusable object)
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

# Single-interval CPP is a different, cheaper path
segment <- sound$extract_part(0, 0.5)
cpp <- segment$to_spectrum()$to_power_cepstrum()$get_peak_prominence(
  60, 333.3, "parabolic", 0.001, 0.05, "exponential decay", "robust slow"
)
```

Use the PowerCepstrum path above when you need a single interval’s
**CPP**. Use
[`calculate_cpps_fast()`](https://humlab-speech.github.io/pladdrr/reference/calculate_cpps_fast.md)
/
[`calculate_cpps_ultra()`](https://humlab-speech.github.io/pladdrr/reference/calculate_cpps_ultra.md)
when you need smoothed whole-sound **CPPS**. They are not
interchangeable, and CPPS is much more expensive because it builds a
full PowerCepstrogram first.

**Performance comparison (verified v4.1.0):** \| Version \| AVQI
Benchmark \| vs Python \| \|———\|—————\|———–\| \| v4.0.x (with debug
output) \| ~17s \| 8.0x slower \| \| **v4.1.0 (threading fix)** \|
**~5.7s** \| **2.67x slower** \| \| Python/Parselmouth \| ~2.1s \|
baseline \|

**Key v4.1.0 changes:** -
[`calculate_cpps_fast()`](https://humlab-speech.github.io/pladdrr/reference/calculate_cpps_fast.md)
now uses direct C++ path (Sound→CPPS in single call) - Defaults aligned
with `get_cpps()` method for identical output - Threading debug output
removed from Praat’s `MelderThread.cpp` - Benefits ALL multi-threaded
Praat operations (Pitch, Formant, CPPS, etc.)

### Pattern 2e: XPtr Window Functions (NEW in v2.2.1)

**Performance:** 70x faster than R function callbacks for custom DSP.

When applying custom window or transform functions to large audio files,
use compiled C++ functions via RcppXPtrUtils:

``` r
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

**XPtr performance functions:** -
`apply_window_xptr(sound, window_func)` - Apply window (t normalized
0-1) - `apply_transform_xptr(sound, transform_func)` - Transform sample
values - `create_window_xptr(type, sigma)` - Create pre-defined window
function

**Custom transform example (soft clipping):**

``` r
soft_clip <- cppXPtr(
  "#include <cmath>
   double clip(double x) { return tanh(x * 2.0); }",
  depends = character()
)
clipped <- apply_transform_xptr(sound, soft_clip)
```

### Pattern 2f: Parallel Processing (v4.0.1+)

**Performance:** 3-8x speedup on multi-core systems for I/O-bound tasks.

``` r
files <- list.files("audio/", pattern = "\\.wav$", full.names = TRUE)

# Generic parallel file processing
results <- analyze_files_parallel(files, function(sound) {
  pitch <- sound$to_pitch()
  list(
    mean_f0 = pitch$get_mean(0, 0, "hertz"),
    sd_f0 = pitch$get_standard_deviation(0, 0, "hertz")
  )
}, n_cores = 4)

# Specialized parallel extraction (convenience wrappers)
pitches <- extract_pitch_parallel(files, n_cores = 4)
formants <- extract_formant_parallel(files, n_cores = 4)
intensities <- extract_intensity_parallel(files, n_cores = 4)
```

**Exported parallel functions:** -
`analyze_files_parallel(files, analysis_func, n_cores)` - Generic
parallel file processing -
`process_sounds_parallel(sounds, analysis_func, n_cores)` - Process
pre-loaded sounds - `extract_pitch_parallel(files, n_cores, ...)` -
Parallel pitch extraction -
`extract_formant_parallel(files, n_cores, ...)` - Parallel formant
extraction - `extract_intensity_parallel(files, n_cores, ...)` -
Parallel intensity extraction -
`benchmark_parallel(files, analysis_func, cores)` - Find optimal core
count

**Best practices:** - The default (`n_cores = NULL`) is
`pladdrr_threads()$processors - 1`, or all of them when there are only
two — the CPUs this process may actually use (affinity mask ∩ cgroup
quota), which
[`parallel::detectCores()`](https://rdrr.io/r/parallel/detectCores.html)
ignores. Under `R CMD check` (`_R_CHECK_LIMIT_CORES_` set) it is at most
2, and so is the C++ thread pool -
[`analyze_files_parallel()`](https://humlab-speech.github.io/pladdrr/reference/analyze_files_parallel.md):
PSOCK (`parLapply`) on Windows and macOS, `mclapply` on Linux.
[`process_sounds_parallel()`](https://humlab-speech.github.io/pladdrr/reference/process_sounds_parallel.md)
on PSOCK sends one sound’s samples per task (2026-10; previously the
whole list went to every worker) - For very large files, consider batch
processing + parallel combined

### Pattern 2g: Direct API Functions (v2.3.0)

**Performance:** 2-3x faster than module dispatch for hot paths.

**NEW in v4.0.2:** Full-parameter Direct API pitch functions now
available! Use
[`to_pitch_ac_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_pitch_ac_direct.md)
or
[`to_pitch_cc_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_pitch_cc_direct.md)
for custom voicing parameters with Direct API performance.

``` r
# TIER 1: Standard (baseline, full features)
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

**Direct API functions for object creation:** -
`to_pitch_direct(sound, time_step, pitch_floor, pitch_ceiling)` → Pitch
XPtr (legacy, basic params) - `to_pitch_ac_direct(sound, ...)` → Pitch
XPtr ✅ **Full params (v4.0.2+)** - `to_pitch_cc_direct(sound, ...)` →
Pitch XPtr ✅ **Full params (v4.0.2+)** -
`to_pitch_shs_direct(sound, time_step, pitch_floor, max_frequency, pitch_ceiling, max_subharmonics, max_candidates, compression_factor, n_points_per_octave)`
→ Pitch XPtr ✅ **v4.8.34+** -
`to_pitch_spinet_direct(sound, time_step, window_duration, min_frequency, max_frequency, n_filters, pitch_ceiling, max_candidates)`
→ Pitch XPtr ✅ **v4.8.34+** -
`to_formant_direct(sound, time_step, max_formants, max_formant, window_length, pre_emphasis)`
→ Formant XPtr ✅ **Full params** -
`to_intensity_direct(sound, minimum_pitch, time_step, subtract_mean)` →
Intensity XPtr ✅ **Full params** -
`to_harmonicity_direct(sound, time_step, minimum_pitch, silence_threshold, periods_per_window)`
→ Harmonicity XPtr ✅ **Full params** -
`to_spectrum_direct(sound, fast)` → Spectrum XPtr (v2.3.0) -
`to_spectrogram_direct(sound, ...)` → Spectrogram XPtr (v2.3.0) -
`to_ltas_direct(sound, bandwidth)` → LTAS XPtr (v2.3.0) -
`to_point_process_direct(sound, ...)` → PointProcess XPtr (v2.3.0) -
`to_point_process_from_sound_and_pitch(sound, pitch)` → PointProcess
XPtr (multi-object)

**Pipeline functions (v4.3.0+):** -
`two_pass_adaptive_pitch(sound, ...)` → list(pitch, min_pitch,
max_pitch, q1, q3) -
`get_jitter_shimmer_batch(pointprocess, sound, ...)` → list(11 voice
quality metrics)

**Direct API functions for queries (accepts string units):** -
`get_pitch_value_direct(pitch_xptr, time, unit, interpolate)` - Single
F0 value (unit: “hertz”, “semitones”, etc.) -
`get_pitch_stats_direct(pitch_xptr, from_time, to_time, unit)` - All
pitch statistics -
`get_formant_value_direct(formant_xptr, formant_number, time, unit)` -
Single formant - `get_formants_direct(formant_xptr, time, unit)` - All
formants at time -
`get_intensity_value_direct(intensity_xptr, time, interpolation)` -
Single intensity

**Compound operations (single C++ call for multiple stats):**

``` r
# Get all common pitch statistics in one call
stats <- get_pitch_stats_direct(pitch_ptr, 0, 0, "hertz")
# Returns: list(min, max, mean, stdev, median, q25, q75, count_voiced)

# Get all formants at single time point
formants <- get_formants_direct(formant_ptr, time = 1.0, unit = "hertz")
# Returns: numeric vector of formant values
```

**Note:** All Direct API functions use the unified `extract_xptr()`
utility for consistent pointer extraction.

### Pattern 2h: Tier 3 Batch Operations (v2.2.7+)

**Performance:** 5-10x faster for bulk object creation and processing.

When creating multiple analysis objects or processing many sounds, use
batch operations:

``` r
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

**Batch conversion functions:** - `sound_to_pitch_batch(sounds, ...)` -
Batch pitch extraction - `sound_to_pitch_ac_batch(sounds, ...)` - Batch
autocorrelation pitch - `sound_to_pitch_cc_batch(sounds, ...)` - Batch
cross-correlation pitch - `sound_to_pitch_shs_batch(sounds, ...)` -
Batch subharmonic summation pitch ✅ **v4.8.34+** -
`sound_to_pitch_spinet_batch(sounds, ...)` - Batch SPINET pitch ✅
**v4.8.34+** - `sound_to_formant_batch(sounds, ...)` - Batch formant
extraction - `sound_to_intensity_batch(sounds, ...)` - Batch intensity
extraction - `sound_extract_and_pitch(sound, starts, ends)` - Extract
parts + pitch - `sound_extract_and_formant(sound, starts, ends)` -
Extract parts + formant - `sound_concatenate_all(sounds)` - Concatenate
multiple sounds (19x faster than iterative) -
`sound_load_window(path, start, end, resample_to = NULL)` - Load audio
window without full file read (27x faster) -
`textgrid_merge(textgrids, equalize_domains = FALSE)` - Merge multiple
TextGrids (17x faster than manual tier copying)

**NEW in v4.0.3:** Added specialized functions for complex workflows:

``` r
# Load only needed audio segment (avoids loading entire file)
window <- sound_load_window("long_audio.wav", start = 10.5, end = 10.55, resample_to = 10000)
# Use case: Extract 50ms window from 10-minute file + resample in one operation

# Merge TextGrids efficiently (native Praat function)
tg1 <- TextGrid$create(0, 1, "words", "")           # one interval tier
tg2 <- TextGrid$create(0, 1, "phones", "events")    # an interval tier and a point tier  (TextGrid(path) only reads a file)
merged <- textgrid_merge(list(tg1, tg2))
# Use case: Combine annotation layers from different sources

# Concatenate voiced segments efficiently
voiced_parts <- list(sound1, sound2, sound3)  # 10-50 segments
concatenated <- sound_concatenate_all(voiced_parts)
# Use case: AVQI analysis requiring voiced-only audio
```

See `vignettes/articles/batch-operations-guide.Rmd` for comprehensive
batch operations documentation.

### Pattern 2i: Vectorized Object Methods (NEW in v4.0.13)

**Performance:** 20-150x faster than R loops by keeping iteration inside
C++.

These methods avoid the 1-2ms R↔︎C++ boundary crossing overhead per call.
Instead of looping in R and calling individual methods, use vectorized
methods that loop in C++.

#### Sound Batch Window Operations

``` r
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

``` r
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

``` r
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

#### Intensity Batch Queries (NEW in v4.8.22)

``` r
intensity <- sound$to_intensity(minimum_pitch = 100)

# SLOW: R loop
times <- seq(0.1, 2.9, by = 0.01)
values <- vapply(times, function(t) intensity$get_value_at_time(t), numeric(1))

# FAST: Single C++ call (20x speedup)
values <- intensity$get_values_at_times(times, interpolation = "cubic")
```

#### Harmonicity Batch Statistics

``` r
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

``` r
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

``` r
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

``` r
spectrogram <- sound$to_spectrogram(window_length = 0.005, max_frequency = 5000)

# Get dimension vectors
times <- spectrogram$get_times_vector()
freqs <- spectrogram$get_frequencies_vector()

# Get frames and slices (50x speedup)
frame <- spectrogram$get_frame(time = 1.0)           # All freqs at one time
slice <- spectrogram$get_frequency_slice(frequency = 1000) # One freq across all times

# Get multiple frames at once
query_times <- c(0.5, 1.0, 1.5, 2.0)
frames <- spectrogram$get_frames(query_times)  # matrix[n_freqs, 4]

# Band power over time
band_power <- spectrogram$get_band_power(fmin = 500, fmax = 2000)
# Returns: power in band for each time frame
```

#### TextGrid Batch Labels

``` r
tg <- TextGrid("annotations.TextGrid")

# Get labels at multiple times (60x speedup for VUV analysis)
times <- seq(0.1, 9.9, by = 0.1)
labels <- tg$get_labels_at_times(tier = 1, times)

# Batch set interval texts
intervals <- c(1, 2, 3, 4)
texts <- c("hello", "world", "test", "end")
tg$set_interval_texts_batch(tier = 1, intervals, texts)
```

**Summary of vectorized methods:**

| Object | Method | Speedup | Use Case |
|----|----|----|----|
| Sound | `get_power_windows()`, `get_rms_windows()`, `get_energy_windows()` | 100-150x | AVQI windowed analysis |
| Sound | `get_values_at_times()`, `get_values_in_range()` | 20x | Tremor peak extraction |
| Intensity | `get_values_at_times()` | 20x | Batch intensity queries (v4.8.22) |
| Pitch | `get_voiced_mask()`, `get_strengths_vector()` | 5x | DSI voicing analysis |
| Harmonicity | `get_statistics_batch()` | 10x | Multi-band HNR (VQ) |
| Spectrum | `get_power_vector()`, `get_band_energies()` | 150x | Pharyngeal analysis |
| Formant | `get_formant_track()`, `get_all_formant_tracks()` | 20x | Vowel space analysis |
| Spectrogram | `get_frame()`, `get_band_power()` | 50x | Time-frequency analysis |
| Spectrogram | [`get_spectral_moments_batch()`](https://humlab-speech.github.io/pladdrr/reference/get_spectral_moments_batch.md) | 14x | CoG/SD/skewness/kurtosis all frames (v4.9.1) |
| TextGrid | `get_labels_at_times()` | 60x | VUV segmentation |

------------------------------------------------------------------------

### Pattern 2j: Batch API v4.0.14 (Advanced Optimizations)

**Performance:** 10-50x faster for specific analysis workflows
(Pharyngeal, Tremor, DSI, AVQI).

These methods target specific performance bottlenecks identified in
voice quality analysis pipelines.

#### LTAS Batch Peak Search (Pharyngeal: 36x → 3x)

``` r
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
# NOTE (v4.9.1): parabolic interpolation is now numerically safe for flat peaks.
# Before v4.9.1, near-zero d2y produced values up to 1231 dB (physically impossible).
# The guard is in NUMimproveExtremum() in praat.github.io/melder/NUMinterpol.cpp.

# Also available:
minima <- ltas$get_minima_batch(fmins, fmaxs, interpolation = "parabolic")
# Returns: data.frame(fmin, fmax, min_value, min_frequency)

# Get LTAS values at specific frequencies
freqs <- c(100, 440, 880, 1000)
values <- ltas$get_values_at_frequencies(freqs, interpolation = "cubic")

# Get mean values in multiple bands
means <- ltas$get_means_batch(fmins, fmaxs, unit = "energy")
```

#### Pitch Detrending (native Praat “Subtract linear fit”)

``` r
pitch <- sound$to_pitch(pitch_floor = 75, pitch_ceiling = 600)

# Native Praat detrending: slope removed, MEAN PRESERVED (centred on mean F0, not 0)
detrended <- pitch$get_values_detrended(unit = "hertz")  # Returns NumericVector, NA = unvoiced

# Or get a new detrended Pitch object
detrended_pitch <- pitch$subtract_linear_fit(unit = "hertz")  # Returns Pitch object

# NOT equivalent to residuals(lm(values ~ times)):
#  - lm residuals are zero-mean; native keeps the mean
#  - native fits the contour after linear interpolation of unvoiced gaps
#    (first..last voiced frame); lm with na.exclude fits voiced frames only
#  - originally unvoiced frames stay unvoiced (NA) in the native result
# With no gaps, native == residuals(lm(...)) + mean(values, na.rm = TRUE).
# Relative contour (e.g. tremor %): separate step
#   rel <- (detrended - mean(detrended, na.rm = TRUE)) / mean(detrended, na.rm = TRUE)

# Additional pitch processing methods (v4.0.14)
interpolated <- pitch$interpolate()      # Fill unvoiced gaps
smoothed <- pitch$smooth(bandwidth = 10) # Smooth pitch contour
cleaned <- pitch$kill_octave_jumps()     # Remove octave errors
```

#### Filtered Window Extraction (AVQI: 2.9x → 1.5x)

``` r
sound <- Sound("recording.wav")

# SLOW: Extract each window separately, filter, concatenate
starts <- seq(0.0, 9.9, by = 0.1)
ends <- starts + 0.1
voiced_sounds <- list()
for (i in seq_along(starts)) {
  part <- sound$extract_part(starts[i], ends[i])
  power <- part$get_power()
  zcr <- part$get_zcr_windows(0, part$get_total_duration())
  if (power > 0.03 && zcr < 3000) {
    voiced_sounds <- c(voiced_sounds, list(part))
  }
}
result <- Reduce(function(a, b) a$concatenate(b), voiced_sounds)

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
concatenated <- sound1$concatenate_sounds(sounds_list, overlap_time = 0.01)
```

#### PointProcess Batch Operations (DSI/Shimmer: 10-20x speedup)

``` r
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

``` r
spectrum <- sound$to_spectrum()

# Get power at specific frequencies (Pharyngeal harmonic analysis)
freqs <- c(100, 440, 880, 1000)
powers <- spectrum$get_power_at_frequencies(freqs)
# Returns: NumericVector of power values (nearest bin, no interpolation)
```

**Summary of v4.0.14 batch methods:**

| Object | Method | Speedup | Use Case |
|----|----|----|----|
| LTAS | `get_peaks_batch()` | 18x | Pharyngeal harmonic peaks |
| LTAS | `get_minima_batch()` | 18x | Spectral valley detection |
| LTAS | `get_values_at_frequencies()` | 10x | Targeted frequency sampling |
| LTAS | `get_means_batch()` | 10x | Multi-band energy analysis |
| Pitch | `subtract_linear_fit()` | native | Slope removed, mean kept (Praat) |
| Pitch | `get_values_detrended()` | native | Same, as vector; not `lm` residuals |
| Pitch | `interpolate()`, [`smooth()`](https://rdrr.io/r/stats/smooth.html) | 5x | Pitch post-processing |
| Sound | `extract_windows_filtered()` | 10x | AVQI voiced extraction |
| Sound | `get_windows_passing_filter()` | 5x | Filter mask inspection |
| PointProcess | `get_values_from_sound()` | 20x | Shimmer amplitude extraction |
| PointProcess | `get_periods_vector()` | 10x | Jitter period analysis |
| PointProcess | `get_jitter_batch()` | 5x | All jitter measures at once |
| Spectrum | `get_power_at_frequencies()` | 10x | Harmonic power extraction |

------------------------------------------------------------------------

### Pattern 2k: Pipeline Operations (v4.3.0+)

**Performance:** 5-10x faster for multi-step analysis workflows.

Pipeline functions combine common multi-step workflows into single
optimized calls.

#### Two-Pass Adaptive Pitch Extraction

**Problem:** Fixed pitch range often misses speaker’s actual range
(creaky voice = low, children = high).

**Solution:**
[`two_pass_adaptive_pitch()`](https://humlab-speech.github.io/pladdrr/reference/two_pass_adaptive_pitch.md) -
Speaker-adaptive pitch extraction in one call.

``` r
# OLD WAY: Manual two-pass implementation (5+ function calls)
pitch_rough <- to_pitch_cc_direct(sound, pitch_floor = 50, pitch_ceiling = 800)
range <- pitch_get_adaptive_range(pitch_rough, q1_factor = 0.75, q3_factor = 1.5, unit = 0L)
pitch_refined <- to_pitch_cc_direct(sound, pitch_floor = range$min_pitch, pitch_ceiling = range$max_pitch)

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

**Use cases:** - Speaker-adaptive pitch tracking (unknown speaker
demographics) - Creaky voice analysis (needs lower floor detection) -
Child speech analysis (needs higher ceiling detection) - Clinical voice
analysis (abnormal pitch ranges)

#### Batch Voice Quality Metrics

**Problem:** Getting all jitter/shimmer measures requires 11 separate
C++ calls.

**Solution:**
[`get_jitter_shimmer_batch()`](https://humlab-speech.github.io/pladdrr/reference/get_jitter_shimmer_batch.md) -
All 11 metrics in one C++ call.

``` r
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

``` r
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
|----|----|----|
| [`two_pass_adaptive_pitch()`](https://humlab-speech.github.io/pladdrr/reference/two_pass_adaptive_pitch.md) | 2x | Speaker-adaptive pitch extraction |
| [`get_jitter_shimmer_batch()`](https://humlab-speech.github.io/pladdrr/reference/get_jitter_shimmer_batch.md) | 5-10x | All 11 voice quality metrics |

#### API Reference: `two_pass_adaptive_pitch()`

**Signature:**

``` r
two_pass_adaptive_pitch(
  sound,                      # Sound XPtr or wrapper object
  time_step = 0,              # 0 = auto (0.75 / initial_floor)
  voicing_threshold = 0.45,   # Voicing detection threshold
  silence_threshold = 0.03,   # Silence detection threshold
  initial_floor = 50,         # Pass 1 pitch floor (Hz)
  initial_ceiling = 800,      # Pass 1 pitch ceiling (Hz)
  octave_cost = 0.01,         # Cost of octave jumps
  octave_jump_cost = 0.35,    # Cost of octave jump transitions
  voiced_unvoiced_cost = 0.14,# Cost of V→U transitions
  q1_factor = 0.75,           # min_pitch = Q1 * q1_factor
  q3_factor = 1.5,            # max_pitch = Q3 * q3_factor
  method = c("cc", "ac")      # "cc" (cross-correlation) or "ac" (autocorrelation)
)
```

**Returns:** Named list with: \| Element \| Type \| Description \|
\|———\|——\|————-\| \| `pitch` \| XPtr \| Refined Pitch object from Pass
2 \| \| `min_pitch` \| numeric \| Adaptive floor (Q1 × q1_factor), in Hz
\| \| `max_pitch` \| numeric \| Adaptive ceiling (Q3 × q3_factor), in Hz
\| \| `q1` \| numeric \| 25th percentile of Pass 1 F0, in Hz \| \| `q3`
\| numeric \| 75th percentile of Pass 1 F0, in Hz \|

**Note:** If no voiced frames detected, returns Pass 1 pitch with
initial range.

#### API Reference: `get_jitter_shimmer_batch()`

**Signature:**

``` r
get_jitter_shimmer_batch(
  pointprocess,               # PointProcess XPtr or wrapper object
  sound,                      # Sound XPtr or wrapper object
  from_time = 0,              # Start time (0 = beginning)
  to_time = 0,                # End time (0 = end)
  period_floor = 0.0001,      # Min period (seconds)
  period_ceiling = 0.02,      # Max period (seconds)
  max_period_factor = 1.3,    # Jitter threshold
  max_amplitude_factor = 1.6  # Shimmer threshold
)
```

**Returns:** Named list with 11 metrics (all as **fractions**, not
percentages): \| Element \| Unit \| Description \| \|———\|——\|————-\| \|
`jitter_local` \| fraction \| Local jitter (relative period variation)
\| \| `jitter_local_abs` \| seconds \| Absolute local jitter \| \|
`jitter_rap` \| fraction \| Relative average perturbation \| \|
`jitter_ppq5` \| fraction \| 5-point period perturbation quotient \| \|
`jitter_ddp` \| fraction \| Difference of differences of periods \| \|
`shimmer_local` \| fraction \| Local shimmer (amplitude variation) \| \|
`shimmer_local_db` \| dB \| Local shimmer in decibels \| \|
`shimmer_apq3` \| fraction \| 3-point amplitude perturbation quotient \|
\| `shimmer_apq5` \| fraction \| 5-point amplitude perturbation quotient
\| \| `shimmer_apq11` \| fraction \| 11-point amplitude perturbation
quotient \| \| `shimmer_dda` \| fraction \| Difference of differences of
amplitudes \|

**To convert fractions to percentages:** Multiply by 100 (e.g.,
`jitter_local * 100`).

#### API Reference: `to_point_process_from_sound_and_pitch()`

**When to use this vs alternatives:**

| Method | When to Use | Praat Equivalent |
|----|----|----|
| `to_point_process_from_sound_and_pitch(sound, pitch)` | **Recommended** for jitter/shimmer. Uses pitch-guided peak detection. | Select Sound + Pitch → “To PointProcess (cc)” |
| `sound$to_point_process_periodic_cc()` | Sound-only analysis. Less accurate for voice quality. | Select Sound → “To PointProcess (periodic, cc)” |
| `to_point_process_direct(sound)` | Direct API version of above. | Same as above |

**Why Sound+Pitch is better:** - Uses refined pitch information to guide
glottal pulse detection - More accurate period identification for
jitter/shimmer - Matches Praat’s recommended workflow for voice quality
analysis - Required for clinical voice assessment (DSI, AVQI, etc.)

**Example:**

``` r
# RECOMMENDED: Use Sound + Pitch (matches Praat best practice)
pitch_result <- two_pass_adaptive_pitch(sound)
pp <- to_point_process_from_sound_and_pitch(sound, pitch_result$pitch)
metrics <- get_jitter_shimmer_batch(pp, sound)

# NOT RECOMMENDED for voice quality (less accurate):
pp <- sound$to_point_process_periodic_cc()  # Sound-only, no pitch guidance
```

------------------------------------------------------------------------

### Pattern 2l: Tier 4 Ultra API (v4.6.3+) - Production Ready ✅

**Performance:** 5-77x faster for DSI and clinical voice workflows.

**Status:** All critical bugs fixed - production ready for AVQI and DSI
workflows!

Tier 4 “Ultra” functions keep entire analysis workflows in C++,
returning only final scalars. Eliminates intermediate object creation
and R-side coordination.

**Bug Fix Summary (v4.6.3):** - ✅
[`extract_voiced_segments_ultra()`](https://humlab-speech.github.io/pladdrr/reference/extract_voiced_segments_ultra.md):
Fixed v2.03/v3.01 algorithm inconsistency - ✅
[`calculate_cpps_ultra()`](https://humlab-speech.github.io/pladdrr/reference/calculate_cpps_ultra.md):
Fixed NA return issue (parameter mapping) - ✅
[`calculate_minimum_intensity_ultra()`](https://humlab-speech.github.io/pladdrr/reference/calculate_minimum_intensity_ultra.md):
Algorithm fix verified working

**Agent Recommendation:** Use Tier 4 Ultra API for all clinical voice
analysis workflows.

#### `get_durations_batch()` - Fast WAV Duration Reading

**Problem:** Getting audio durations via
[`LongSound()`](https://humlab-speech.github.io/pladdrr/reference/LongSound.md)
or
[`Sound()`](https://humlab-speech.github.io/pladdrr/reference/Sound.md)
loads entire file.

**Solution:** Read only 44-byte WAV header for instant duration
extraction.

``` r
# OLD WAY: Load entire file (slow for many files)
durations <- sapply(wav_files, function(f) {
  sound <- Sound(f)
  sound$get_xmax() - sound$get_xmin()
})

# NEW WAY: Header-only reading (77x faster)
durations <- get_durations_batch(wav_files)
```

**Signature:**

``` r
get_durations_batch(file_paths)
```

| Parameter    | Type      | Description               |
|--------------|-----------|---------------------------|
| `file_paths` | character | Vector of .wav file paths |

**Returns:** Numeric vector of durations (seconds). NA for
invalid/missing files.

#### `calculate_f0_stats_ultra()` - Single-Call F0 Statistics

**Problem:** Getting F0 statistics requires creating Pitch object, then
calling stat method.

**Solution:** Single C++ call returns statistic directly.

``` r
# OLD WAY: Create intermediate Pitch object
pitch <- sound$to_pitch_cc(pitch_floor = 75, pitch_ceiling = 600)
max_f0 <- pitch$get_maximum(0, 0, "hertz", TRUE)

# NEW WAY: Direct statistic (5x faster)
max_f0 <- calculate_f0_stats_ultra(sound, stat = "max", min_pitch = 75, max_pitch = 600)
```

**Signature:**

``` r
calculate_f0_stats_ultra(
  sound,                    # Sound object
  stat = "max",             # "max", "min", "mean", "median", "sd"
  time_step = 0,            # 0 = auto

  min_pitch = 75,           # Pitch floor (Hz)
  max_pitch = 600,          # Pitch ceiling (Hz)
  voicing_threshold = 0.45  # Voicing detection threshold
)
```

**Returns:** Single numeric value (Hz for pitch stats, NA if no voiced
frames).

#### `calculate_minimum_intensity_ultra()` - Voiced-Region Intensity

**Problem:** DSI requires minimum intensity in voiced regions only—needs
Pitch→PointProcess→TextGrid→Intensity pipeline.

**Solution:** Complete DSI-compliant pipeline in single C++ call.

**Algorithm (v4.4.1 - DSI compliant):** 1. Extract pitch with DSI
parameters (`voicing_threshold=0.8`, `very_accurate=FALSE`) 2. Create
PointProcess from Sound + Pitch 3. Create TextGrid with VUV segmentation
(`maxPeriod=0.02`, `meanPeriod=0.01`) 4. Extract and **concatenate** all
voiced intervals 5. Calculate intensity on concatenated sound
(`minimum_pitch=60`, DSI standard) 6. Return minimum intensity from
concatenated voiced regions

``` r
# OLD WAY: Multi-step pipeline
pitch <- sound$to_pitch_cc(pitch_floor = 70, voicing_threshold = 0.8)
pp <- to_point_process_from_sound_and_pitch(sound, pitch)
tg <- pp$to_textgrid_vuv(0.02, 0.01)
# ... extract voiced intervals, concatenate, calculate intensity ...

# NEW WAY: Single call (6x faster, DSI-compliant)
min_int <- calculate_minimum_intensity_ultra(sound, min_pitch = 70)  # explicit override; see default below
```

**Signature:**

``` r
calculate_minimum_intensity_ultra(
  sound,                 # Sound object
  min_pitch = 75,        # Pitch floor (Hz) for pitch extraction
  max_pitch = 600,       # Pitch ceiling (Hz) for pitch extraction
  time_step = 0,         # 0 = auto
  subtract_mean = TRUE   # Subtract mean for intensity calculation
)
```

**Returns:** Minimum intensity (dB) from concatenated voiced regions. NA
if no voiced frames.

**Note:** Intensity calculation uses `minimum_pitch=60` internally (DSI
standard), not the `min_pitch` parameter which is only for pitch
extraction.

#### `get_voice_quality_ultra()` - Complete Voice Quality Metrics

**Problem:** Getting jitter/shimmer/HNR requires creating Pitch,
PointProcess, then batch calls.

**Solution:** All metrics from single C++ call with selective
computation.

``` r
# OLD WAY: Multi-object pipeline
pitch <- sound$to_pitch_cc(pitch_floor = 75)
pp <- to_point_process_from_sound_and_pitch(sound, pitch)
metrics <- get_jitter_shimmer_batch(pp, sound)

# NEW WAY: Single call with selective metrics
vq <- get_voice_quality_ultra(sound, metrics = "all", min_pitch = 75)
# Or request specific metrics:
vq <- get_voice_quality_ultra(sound, metrics = "jitter", min_pitch = 75)
# Or match Praat's plain To Pitch... + PointProcess (cc) DSI path:
vq <- get_voice_quality_ultra(sound, metrics = "jitter",
                              pitch_method = "ac", very_accurate = FALSE)
```

**Signature:**

``` r
get_voice_quality_ultra(
  sound,                 # Sound object
  metrics = "all",       # "all", "jitter", "shimmer", "hnr", or vector
  min_pitch = 75,        # Pitch floor (Hz)
  max_pitch = 600,       # Pitch ceiling (Hz)
  time_step = 0,         # 0 = auto
  pitch_method = "cc",   # default keeps existing Tier 4 behaviour
  very_accurate = TRUE   # use FALSE with pitch_method="ac" for Praat parity
)
```

**Returns:** Named list with requested metrics:

| Metric Group | Elements |
|----|----|
| `jitter` | `jitter_local`, `jitter_rap`, `jitter_ppq5`, `jitter_ddp` |
| `shimmer` | `shimmer_local`, `shimmer_local_db`, `shimmer_apq3`, `shimmer_apq5`, `shimmer_apq11`, `shimmer_dda` |
| `hnr` | `hnr_mean`, `hnr_sd` |

#### Complete DSI Workflow Example (v4.4.1)

**Dysphonia Severity Index calculation with Tier 4 Ultra:**

``` r
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
|----|----|----|
| [`get_durations_batch()`](https://humlab-speech.github.io/pladdrr/reference/get_durations_batch.md) | 77x | MPT measurement |
| [`calculate_f0_stats_ultra()`](https://humlab-speech.github.io/pladdrr/reference/calculate_f0_stats_ultra.md) | 5x | FH (highest frequency) |
| [`calculate_minimum_intensity_ultra()`](https://humlab-speech.github.io/pladdrr/reference/calculate_minimum_intensity_ultra.md) | 6x | IM (lowest intensity) |
| [`get_voice_quality_ultra()`](https://humlab-speech.github.io/pladdrr/reference/get_voice_quality_ultra.md) | 3.6x | PPQ (jitter) |
| [`calculate_cpps_ultra()`](https://humlab-speech.github.io/pladdrr/reference/calculate_cpps_ultra.md) | 1.6x | AVQI CPPS extraction |
| [`extract_voiced_segments_ultra()`](https://humlab-speech.github.io/pladdrr/reference/extract_voiced_segments_ultra.md) | 2-4x | AVQI/VQ voiced extraction |
| [`calculate_multiband_hnr_ultra()`](https://humlab-speech.github.io/pladdrr/reference/calculate_multiband_hnr_ultra.md) | 2-2.5x | VQ multi-band HNR |

#### `calculate_cpps_ultra()` - Direct Sound→CPPS (v4.4.1+)

**Problem:** CPPS calculation requires creating PowerCepstrogram then
calling `get_cpps()`.

**Solution:** Single C++ call creates PowerCepstrogram internally and
returns CPPS directly.

``` r
# OLD WAY: Two-step with intermediate object
pcep <- sound$to_powercepstrogram(60, 0.002, 5000, 50)
cpps <- pcep$get_cpps(subtract_tilt = TRUE, time_averaging_window = 0.001,
                      quefrency_averaging_window = 0.0005, pitch_floor = 60, pitch_ceiling = 333.3)

# NEW WAY: Direct single call (1.6x faster)
cpps <- calculate_cpps_ultra(sound)

# With custom parameters
cpps <- calculate_cpps_ultra(
  sound,
  time_averaging_window = 0.001,
  quefrency_averaging_window = 0.0005,
  pitch_floor = 60,
  pitch_ceiling = 333.3,
  subtract_trend = TRUE,
  time_step = 0.002,
  max_quefrency = 0.04,
  tolerance = 0.05,
  interpolation = "parabolic",
  tilt_line_quefrency = 0.003,
  line_type = "straight",
  fit_method = "robust",
  pre_emphasis_from = 50,
  max_frequency = 5000
)
```

**Signature:**

``` r
calculate_cpps_ultra(
  sound,                                 # Sound object
  time_averaging_window = 0.001,         # CPPS smoothing window
  quefrency_averaging_window = 0.0005,   # Quefrency smoothing
  pitch_floor = 60,                      # Lowest pitch for cepstrogram
  pitch_ceiling = 333.3,                 # Highest pitch for cepstrogram
  subtract_trend = TRUE,                 # Remove spectral tilt/trend
  time_step = 0.002,                     # Frame shift
  max_quefrency = 0.04,                  # Max quefrency for trend fit
  tolerance = 0.05,                      # Peak-picking tolerance
  interpolation = "parabolic",           # "none", "parabolic"
  tilt_line_quefrency = 0.003,           # Trend-line start quefrency
  line_type = "straight",                # "straight", "exponential_decay"
  fit_method = "robust",                 # "least_squares", "robust"
  pre_emphasis_from = 50,                # Pre-emphasis frequency
  max_frequency = 5000                   # Max analysis frequency
)
```

**Note:** `line_type = "straight"` and `tilt_line_quefrency = 0.003` are
the correct current defaults (fixed in v4.6.4 and v4.9.10 respectively,
from earlier broken defaults `"exponential_decay"` / `0.001` — see
`R/performance-helpers.R:551` and CLAUDE.md’s CPPS parameter-default
warning). Do not revert to the old values.

**Returns:** Single numeric value (dB). NA if calculation fails.

**Use case:** AVQI v2.03 and v3.01 require CPPS calculation on
voiced-only audio. This function eliminates PowerCepstrogram object
overhead.

#### `extract_voiced_segments_ultra()` - AVQI-Compliant Voiced Extraction (v4.4.1+)

**Problem:** AVQI requires extracting and concatenating voiced segments
with optional power/ZCR filtering (v3.01). Multi-step pipeline in R is
slow.

**Solution:** Complete voiced extraction pipeline in single C++ call.
Supports both AVQI v2.03 (intensity-based) and v3.01 (windowed power +
ZCR filtering).

**Algorithm (v4.6.2+):** 1. Create Intensity object from Sound
(`Sound_to_Intensity` with `minPitch`, `timeStep=0.003s`) 2. Find
maximum intensity; calculate threshold as
`max_intensity + silence_threshold_db` 3. Detect sounding intervals by
scanning intensity values above threshold 4. Extract and concatenate
sounding intervals (min duration filtering applied) 5. **v3.01 only:**
Apply windowed power + ZCR filtering: - Calculate global power threshold
(default: 3% of global power) - Apply sliding windows (default: 0.03s,
nonoverlapping) - For each window: calculate power and ZCR using
`Sound_to_PointProcess_zeroes()` - ZCR formula (AVQI standard):
`zcr = n_crossings / (last_crossing - first_crossing)` - Keep window if:
`power > threshold AND zcr < max_zcr` - Concatenate passing windows 6.
Return concatenated voiced Sound

**Note:** v4.6.2 changed from TextGrid-based silence detection to direct
Intensity-based detection to avoid FFT crash in
`Sound_to_TextGrid_detectSilences()`.

``` r
# OLD WAY: Multi-step pipeline (6+ Praat calls)
tg <- sound$to_textgrid_silences(min_pitch = 100, silence_threshold = -25)
voiced_sounds <- list()
for (i in 1:tg$get_number_of_intervals(1)) {
  if (tg$get_interval_text(1, i) != "silent") {
    voiced_sounds <- c(voiced_sounds, list(sound$extract_part(...)))
  }
}
concatenated <- Reduce(function(a, b) a$concatenate(b), voiced_sounds)
# ... then v3.01 windowing + filtering ...

# NEW WAY: Single call (2-4x faster)
# AVQI v2.03 (intensity-based, simple)
voiced_203 <- extract_voiced_segments_ultra(sound, version = "v2.03")

# AVQI v3.01 (with windowed power + ZCR filtering)
voiced_301 <- extract_voiced_segments_ultra(
  sound,
  version = "v3.01",
  power_threshold_factor = 0.3,
  max_zcr = 3000,
  window_width = 0.03
)
```

**Signature:**

``` r
extract_voiced_segments_ultra(
  sound,                          # Sound object
  version = "v3.01",              # "v2.03" or "v3.01"
  min_pitch = 50,                 # Silence detection pitch floor
  silence_threshold_db = -25,     # Silence detection threshold (dB)
  min_silent_duration = 0.1,      # Min silent duration (s)
  min_sounding_duration = 0.1,    # Min sounding duration (s)
  power_threshold_factor = 0.3,   # v3.01: Power threshold (fraction of global)
  max_zcr = 3000,                 # v3.01: Max zero-crossing rate (Hz)
  window_width = 0.03             # v3.01: Window width for power/ZCR (s)
)
```

**Returns:** Sound object (shared dispatch wrapper around XPtr) with
concatenated voiced segments.

**Use case:** AVQI v2.03/v3.01 preprocessing. v3.01 is more robust
(filters out low-power/high-ZCR segments).

**Performance:** 2-4x faster than R pipeline. Biggest bottleneck fix for
AVQI (saves 4-6s on typical recordings).

#### `calculate_multiband_hnr_ultra()` / reusable multiband HNR path

**Problem:** VQ (Voice Quality) assessment needs HNR in 5 frequency
bands. The one-shot path is fine for one interval, but repeated
intervals on the same `Sound` should not rebuild the same 5 Harmonicity
objects every time.

**Solution:** - Use `calculate_multiband_hnr_ultra(sound, ...)` for
one-shot / whole-sound summaries - Use
`build_multiband_harmonicity(sound, ...)` once, then
`multiband_hnr_stats(...)` for repeated interval queries

**Algorithm:** 1. For each of 5 bands: `full`, `0-500`, `0-1500`,
`0-2500`, `0-3500` 2. Apply the Hann band filter for the non-full bands
3. Create CC Harmonicity (`time_step=0.005`, `min_pitch=75`,
`silence_threshold=0.1`, `periods_per_window=1`) 4. Either: - return
mean + SD immediately (one-shot), or - keep the 5 Harmonicity objects
for later interval queries

``` r
# One-shot path
hnr <- calculate_multiband_hnr_ultra(sound)
# Returns: list(
#   full_mean, full_sd,
#   band500_mean, band500_sd,
#   band1500_mean, band1500_sd,
#   band2500_mean, band2500_sd,
#   band3500_mean, band3500_sd
# )

# Reusable path for multiple intervals on the same sound
built <- build_multiband_harmonicity(sound)
hnr_i1 <- multiband_hnr_stats(built, 0, 0.5)
hnr_i2 <- multiband_hnr_stats(built, 0.5, 1.0)
```

**Signatures:**

``` r
calculate_multiband_hnr_ultra(
  sound,                      # Sound object
  bands = c(0, 500, 1500, 2500, 3500),
  time_step = 0.005,
  min_pitch = 75,
  from_time = 0,
  to_time = 0
)

build_multiband_harmonicity(
  sound,
  bands = c(0, 500, 1500, 2500, 3500),
  time_step = 0.005,
  min_pitch = 75
)

multiband_hnr_stats(
  multiband,
  from_time = 0,
  to_time = 0
)
```

**Returns:** -
[`calculate_multiband_hnr_ultra()`](https://humlab-speech.github.io/pladdrr/reference/calculate_multiband_hnr_ultra.md)
-\> named list with 10 elements: \| Element \| Description \|
\|———\|————-\| \| `full_mean` \| Mean HNR for full spectrum \| \|
`full_sd` \| SD of HNR for full spectrum \| \| `band500_mean` \| Mean
HNR for 0-500 Hz \| \| `band500_sd` \| SD of HNR for 0-500 Hz \| \|
`band1500_mean` \| Mean HNR for 0-1500 Hz \| \| `band1500_sd` \| SD of
HNR for 0-1500 Hz \| \| `band2500_mean` \| Mean HNR for 0-2500 Hz \| \|
`band2500_sd` \| SD of HNR for 0-2500 Hz \| \| `band3500_mean` \| Mean
HNR for 0-3500 Hz \| \| `band3500_sd` \| SD of HNR for 0-3500 Hz \|

- [`build_multiband_harmonicity()`](https://humlab-speech.github.io/pladdrr/reference/build_multiband_harmonicity.md)
  -\> named list of 5 `Harmonicity` objects: `full`, `band500`,
  `band1500`, `band2500`, `band3500`

**Use case:** simple one-shot VQ summaries vs repeated-interval VQ
workflows on the same sound. Matches `VQ_measurements_V2.praat` lines
102-122.

**Note:** `bands` must have exactly 5 elements. The first element uses
`0` as the full-spectrum sentinel in the current API.

#### AVQI v3.01 Complete Workflow (v4.4.1)

**Acoustic Voice Quality Index calculation with new Tier 4 Ultra
functions:**

``` r
sound <- Sound("sustained_vowel.wav")

# Step 1: Extract voiced segments (AVQI v3.01 with power + ZCR filtering)
voiced <- extract_voiced_segments_ultra(sound, version = "v3.01")

# Step 2: Calculate CPPS on voiced audio
cpps <- calculate_cpps_ultra(voiced)

# Step 3: Calculate multi-band HNR
hnr <- calculate_multiband_hnr_ultra(voiced)

# Step 4: Calculate other AVQI metrics (shimmer, slope, tilt)
# ... standard pladdrr functions ...

# AVQI formula components now available:
avqi_cpps <- cpps
avqi_hnr <- hnr$band3500_mean  # HNR 0-3500Hz
# ... combine with other metrics per AVQI formula ...
```

**Performance improvement:** - AVQI benchmark: 19.8s → 12.3s (1.6x
speedup) - VQ benchmark: 1.35s → 0.9s (1.5x speedup) - Code reduction in
plabench: 210 lines → 14 lines (93% reduction)

------------------------------------------------------------------------

### Pattern 2m: Prosodic Analysis Workflows (v4.8.24+)

**Use case:** Batch feature extraction at target times (INTSINT points,
syllable nuclei, etc.) — common in prosodic analysis packages like
dysprosody and superassp.

#### Pre-extract all formants at target times (batch)

``` r
sound <- Sound("utterance.wav")
formant <- sound$to_formant_burg()
targets <- c(0.15, 0.35, 0.52, 0.71)  # e.g., syllable nuclei

# FAST: batch query per formant number
f1 <- formant$get_values_at_times(1, targets)
f2 <- formant$get_values_at_times(2, targets)
f3 <- formant$get_values_at_times(3, targets)

# Or get all formants at a single time point
all_f <- formant$get_all_values_at_time(0.35, max_formants = 5)
# Returns: numeric(5) with NA for missing formants
```

#### Intensity at target times (batch)

``` r
intensity <- sound$to_intensity()
int_vals <- intensity$get_values_at_times(targets)
```

#### LTAS spectral analysis

``` r
ltas <- sound$to_ltas(100)

# Spectral slope (convenience — returns scalar)
slope <- ltas$get_spectral_slope(100, 5000)

# Full trend report (slope, intercept, R², fitted values)
trend <- ltas$report_spectral_trend(100, 5000)

# Harmonic peaks in frequency bands
peaks <- ltas$get_peaks_batch(
  fmins = c(0, 1000, 2000, 3000),
  fmaxs = c(1000, 2000, 3000, 4000)
)

# Values at specific frequencies
vals <- ltas$get_values_at_frequencies(c(500, 1000, 2000, 4000))
```

#### Performance: loop vs batch

``` r
# SLOW: loop per target per formant
for (t in targets) {
  for (fn in 1:5) formant$get_value_at_time(fn, t)  # N*5 C++ calls
}

# FAST: batch per formant (N calls total, vectorized in C++)
for (fn in 1:5) formant$get_values_at_times(fn, targets)
```

------------------------------------------------------------------------

### Pattern 2n: Advanced Audio Analysis (v4.8.25+)

**New Tier 1 and Tier 2 methods for specialized audio processing.**

#### Tier 1: High-Impact Audio Processing

##### Time-Stretching with Overlap-Add

**Use case:** Change playback speed without changing pitch (time
compression/expansion).

``` r
sound <- Sound("speech.wav")

# Slow down by 50% (factor > 1)
slower <- sound$lengthen(fmin = 75, fmax = 600, factor = 1.5)

# Speed up by 20% (factor < 1)
faster <- sound$lengthen(fmin = 75, fmax = 600, factor = 0.8)
```

**Parameters:** - `fmin`, `fmax`: Pitch range for analysis (Hz) -
`factor`: Time stretch factor (1.5 = 50% slower, 0.5 = 50% faster)

**Praat equivalent:** `Sound: Lengthen (overlap-add)...`

##### Pitch-Corrected LTAS for Voice Quality

**Use case:** LTAS that adapts to speaker’s fundamental frequency, used
in voice quality assessment.

``` r
sound <- Sound("vowel.wav")

# Standard LTAS (fixed frequency bins)
ltas_std <- sound$to_ltas(bandwidth = 100)

# Pitch-corrected LTAS (harmonic structure preserved)
ltas_pc <- sound$to_ltas_pitch_corrected(
  pitch_floor = 75,
  pitch_ceiling = 600,
  max_frequency = 5000,
  bandwidth = 100,
  shortest_period = 0.0001,
  longest_period = 0.02,
  max_period_factor = 1.3
)
```

**Praat equivalent:** `Sound: To Ltas (pitch-corrected)...`

##### Robust Formant Tracking (Outlier Removal)

**Use case:** Formant tracking with automatic outlier detection and
removal (iterative refinement).

``` r
sound <- Sound("vowel.wav")

# Standard formant tracking
formant_std <- sound$to_formant_burg(
  time_step = 0.005,
  max_formants = 5,
  max_frequency = 5500
)

# Robust formant tracking (removes outliers, iteratively refines)
formant_robust <- sound$to_formant_robust(
  time_step = 0.005,
  max_formants = 5.0,
  max_frequency = 5500,
  window_length = 0.025,
  pre_emphasis_from = 50,
  num_std_dev = 1.5,      # Outlier threshold (standard deviations)
  max_iterations = 5       # Refinement iterations
)
```

**Praat equivalent:** `Sound: To Formant (robust)...`

**Use cases:** - Pathological voice (creaky, breathy) with irregular
formants - Continuous speech with rapid formant transitions - Noisy
recordings where Burg tracking fails

##### Formant-Based Filtering

**Use case:** Filter sound using formant structure (e.g., remove
formants, inverse filter).

``` r
sound <- Sound("vowel.wav")
formant <- sound$to_formant_burg()

# Filter by formant structure (with intensity scaling)
filtered <- sound$filter_by_formant(formant)

# Filter without intensity scaling
filtered_noscale <- sound$filter_by_formant_noscale(formant)
```

**Praat equivalents:** - `Sound & Formant: Filter` -
`Sound & Formant: Filter (no scale)`

##### MelSpectrogram and BarkSpectrogram

**Use case:** Psychoacoustic spectrograms for perceptual analysis, MFCC
computation.

``` r
sound <- Sound("speech.wav")

# Create mel-scale spectrogram (common in speech recognition)
mel_spec <- sound$to_mel_spectrogram(
  window_length = 0.025,
  time_step = 0.01,
  first_filter_frequency = 100,  # mel
  frequency_step = 100,          # mel (distance between filters)
  max_frequency = 0              # 0 = Nyquist
)

# Inspect values via matrix export (no per-cell query methods on MelSpectrogram)
mel_mat <- mel_spec$as_matrix(to_db = TRUE)

# Convert to MFCC
mfcc <- mel_spec$to_mfcc(number_of_coefficients = 12)

# Convert to Matrix for further processing
matrix <- mel_spec$to_matrix()

# Convert to Intensity (band energy over time)
intensity <- mel_spec$to_intensity()

# Create bark-scale spectrogram (auditory filter bank)
bark_spec <- sound$to_bark_spectrogram(
  window_length = 0.025,
  time_step = 0.01,
  first_filter_frequency = 1,  # Bark
  frequency_step = 1,          # Bark (distance between filters)
  max_frequency = 0            # 0 = Nyquist
)

# Inspect values via matrix export (no per-cell query methods on BarkSpectrogram)
bark_mat <- bark_spec$as_matrix(to_db = TRUE)

# Convert to Matrix or Intensity
bark_matrix <- bark_spec$to_matrix()
bark_intensity <- bark_spec$to_intensity()
```

**Praat equivalents:** - `Sound: To MelSpectrogram...` -
`Sound: To BarkSpectrogram...`

#### Tier 2: Useful Signal Processing Additions

##### Autocorrelation

``` r
sound <- Sound("tone.wav")
autocorr <- sound$autocorrelate()  # Returns new Sound with autocorrelation
```

**Praat equivalent:** `Sound: Autocorrelate...`

##### Deep Band Modulation

**Use case:** Enhance modulation in specific frequency band.

``` r
sound <- Sound("speech.wav")
enhanced <- sound$deepen_band_modulation(
  enhancement_db = 10,
  flow = 300,
  fhigh = 4000,
  slow_modulation = 3,
  fast_modulation = 30,
  band_smoothing = 100
)
```

**Praat equivalent:** `Sound: Deepen band modulation...`

##### Convolution and Cross-Correlation

``` r
sound1 <- Sound("signal.wav")
sound2 <- Sound("impulse.wav")

# Convolve two sounds (impulse response, filtering)
convolved <- sound1$convolve(sound2, scaling = "normalize", signal_outside = "zero")

# Cross-correlate two sounds (similarity measure)
xcorr <- sound1$cross_correlate(sound2, scaling = "normalize", signal_outside = "zero")
```

**Praat equivalents:** - `Sound & Sound: Convolve...` -
`Sound & Sound: Cross-correlate...`

##### MFCC ↔︎ MelSpectrogram Conversion

``` r
sound <- Sound("speech.wav")
mfcc <- sound$to_mfcc()

# Reverse conversion: MFCC → MelSpectrogram
mel_spec <- mfcc$to_mel_spectrogram()
```

**Praat equivalent:** `MFCC: To MelSpectrogram...`

##### LPC to Spectrogram

``` r
sound <- Sound("vowel.wav")
lpc <- sound$to_lpc_burg(prediction_order = 16, analysis_width = 0.025, time_step = 0.005)

# Convert LPC to Spectrogram for visualization
spec <- lpc$to_spectrogram(
  df_min = 20.0,                 # minimum frequency resolution (Hz)
  bandwidth_reduction = 0.0,
  de_emphasis_frequency = 50.0
)
```

**Praat equivalent:** `LPC: To Spectrogram...`

##### PointProcess Sound Generation

``` r
pp <- PointProcess(xmin = 0, xmax = 1)
pp$add_point(0.1)
pp$add_point(0.2)
pp$add_point(0.3)

# Generate pulse train (Dirac deltas at pulse times)
pulse_train <- pp$to_sound_pulse_train(
  sampling_frequency = 44100,
  adapt_factor = 1.0,
  adapt_time = 0.05,
  interpolation_depth = 30L
)

# Generate harmonic hum (sum of sines at pulse frequencies) — takes no parameters
hum <- pp$to_sound_hum()
```

**Praat equivalents:** - `PointProcess: To Sound (pulse train)...` -
`PointProcess: To Sound (hum)...`

##### Intensity-Based Silence Detection

**Use case:** Create TextGrid with silence/sounding intervals.

``` r
sound <- Sound("speech.wav")
intensity <- sound$to_intensity(minimum_pitch = 100)

# Detect silences and create TextGrid
tg <- intensity$to_textgrid_silences(
  silence_threshold = -25,       # dB relative to max
  min_silence_duration = 0.3,    # seconds
  min_sounding_duration = 0.1,   # seconds
  silent_label = "silent",
  sounding_label = "sounding"
)
```

**Praat equivalent:** `Intensity: To TextGrid (silences)...`

##### Table Operations

``` r
formant <- sound$to_formant_burg()
table <- formant$down_to_table(include_frame_numbers = TRUE,
                                include_time = TRUE,
                                time_decimals = 6,
                                include_intensity = FALSE,
                                include_number_of_formants = TRUE,
                                include_bandwidths = TRUE)

# Sort by column
sorted <- table$sort_rows("F1(Hz)")

# Extract rows where numeric column matches condition
high_f1 <- table$extract_rows_where_number("F1(Hz)", 0, 500)  # 0 = "greater than"

# Extract rows where string column matches
voiced <- table$extract_rows_where_string("label", 2, "voiced")  # 2 = "contains"
```

**Praat equivalents:** - `Table: Sort rows...` -
`Table: Extract rows where column (number)...` -
`Table: Extract rows where column (text)...`

##### Average Multiple LTAS

**Use case:** Combine LTAS from multiple speakers or recordings.

``` r
ltas1 <- Sound("speaker1.wav")$to_ltas(100)
ltas2 <- Sound("speaker2.wav")$to_ltas(100)
ltas3 <- Sound("speaker3.wav")$to_ltas(100)

# Average LTAS objects
avg_ltas <- ltas_average(list(ltas1, ltas2, ltas3))
```

**Praat equivalent:** Select multiple Ltas → `Ltases: Average`

------------------------------------------------------------------------

### Pattern 2o: Tier 3 Audio Processing (v4.8.26+)

#### Speaker Transformation (Change Gender / Change Speaker)

**Use case:** Modify speaker characteristics by independently scaling
formant frequencies (vocal tract length), pitch level, pitch range, and
duration.

``` r
sound <- Sound("speech.wav")

# Change to higher-pitched speaker (e.g., female → child)
transformed <- sound$change_speaker(
  pitch_floor = 75,              # Min pitch for analysis
  pitch_ceiling = 600,           # Max pitch for analysis
  formant_multiplier = 1.2,      # Raise formants 20% (shorter vocal tract)
  pitch_multiplier = 1.3,        # Raise pitch 30%
  pitch_range_multiplier = 1.0,  # Keep pitch range
  duration_multiplier = 1.0      # Keep duration
)

# Change gender (typical male → female)
female <- sound$change_speaker(
  formant_multiplier = 1.1,
  pitch_multiplier = 1.8,
  pitch_range_multiplier = 1.2,
  duration_multiplier = 1.0
)

# Use existing Pitch object (more control)
pitch <- sound$to_pitch_ac()
modified <- sound$change_speaker_with_pitch(
  pitch = pitch,
  formant_multiplier = 1.1,
  pitch_multiplier = 1.5,
  pitch_range_multiplier = 1.0,
  duration_multiplier = 0.9      # Slightly faster
)
```

**Praat equivalents:** - `Sound & Pitch: Change speaker...` -
`Sound: Change speaker...` (internal pitch extraction)

**Parameters:** - `formant_multiplier`: Scales formant frequencies (\> 1
= shorter vocal tract / higher formants) - `pitch_multiplier`: Scales
median pitch up/down - `pitch_range_multiplier`: Scales excursion from
median (\> 1 = more melodic, \< 1 = more monotone) -
`duration_multiplier`: Combined with formant_multiplier for final
duration

#### Sound Creation from Scratch

``` r
# Pure tone with fade in/out (avoids clicks)
tone <- sound_create_pure_tone(
  channels = 1,
  starting_time = 0,
  end_time = 0.5,
  sample_rate = 44100,
  frequency = 440,       # Hz (A4)
  amplitude = 0.5,       # 0–1
  fade_in_duration = 0.01,
  fade_out_duration = 0.01
)

# Also available as static method
tone <- Sound$create_pure_tone(440, amplitude = 0.7, end_time = 1.0)

# Harmonic complex tone (sum of sines)
# phase: 0 = sine, 1 = cosine, 2 = alternating sine/cosine
complex <- sound_create_tone_complex(
  starting_time = 0,
  end_time = 0.5,
  sample_rate = 44100,
  phase = 0L,              # 0=sine, 1=cosine, 2=alternating
  frequency_step = 100,    # Spacing between harmonics (Hz)
  first_frequency = 100,   # Fundamental / first harmonic
  ceiling = 10000,         # Max frequency to include
  number_of_components = 0L  # 0 = determined by ceiling
)

# Also available as static method
complex <- Sound$create_tone_complex(frequency_step = 200, first_frequency = 200)
```

**Praat equivalents:** - `Create Sound as pure tone...` -
`Create Sound as tone complex...`

#### Spectrum Frequency Shifting

**Use case:** Shift all spectral energy by a fixed amount in Hz (useful
for formant synthesis, frequency warping).

``` r
sound <- Sound("vowel.wav")
spectrum <- sound$to_spectrum()

# Shift spectrum up by 200 Hz
shifted_up <- spectrum$shift_frequencies(
  shift_by = 200,                # Hz (positive = up, negative = down)
  new_maximum_frequency = 5000,  # Output bandwidth (0 = same as input)
  interpolation_depth = 50       # Sinc interpolation depth
)

# Shift down (frequency lowering)
shifted_down <- spectrum$shift_frequencies(shift_by = -500)

# Convert back to sound
shifted_sound <- shifted_up$to_sound()
```

**Praat equivalent:** `Spectrum: Shift frequencies...`

------------------------------------------------------------------------

### Pattern 2p: Spectral Moments Batch (v4.9.1+)

**Performance:** 14× faster than per-frame R loop. Before this API
existed, spectral moments required ~2000 R→C++ round-trips per file (400
frames × 5 calls); Praat ran identical logic 14× faster in compiled C++.
The batch API closes that gap by computing all frames in one C++ pass
with no R-level iteration.

**Praat equivalent:** Loop over `Spectrum: Get centre of gravity...`,
`...standard deviation...`, `...skewness...`, `...kurtosis...` for every
frame of a Spectrogram.

#### Spectral Moments (CoG, SD, Skewness, Kurtosis)

``` r
spectrogram <- sound$to_spectrogram(
  window_length  = 0.005,
  max_frequency  = 5000,
  time_step      = 0.002,
  frequency_step = 20,
  window_shape   = "Gaussian"
)

# SLOW: Per-frame R loop — was 14× slower than Praat (0.514s vs 0.037s per file)
# Anti-pattern: 400 autoSpectrum C++ allocations + 1600 R→C++ crossings per file
moments_slow <- do.call(rbind, lapply(seq_len(spectrogram$.cpp$get_number_of_frames()), function(ix) {
  t    <- spectrogram$.cpp$get_time_from_frame(ix)
  spec <- spectrogram$to_spectrum(t)          # C++ object allocation per frame
  data.frame(
    time     = t,
    cog      = spec$get_centre_of_gravity(2.0),
    sd       = spec$get_standard_deviation(2.0),
    skewness = spec$get_skewness(2.0),
    kurtosis = spec$get_kurtosis(2.0)
  )
}))

# FAST: Single C++ pass (v4.9.1+) — no R-level iteration, no per-frame allocation
moments <- get_spectral_moments_batch(spectrogram, power = 2.0)
# Returns: data.frame(time, cog, sd, skewness, kurtosis) — one row per frame
# NA where CoG is undefined (zero-power frames)

# Also accessible as a method on the Spectrogram object:
moments <- spectrogram$get_spectral_moments_batch(power = 2.0)
```

**`power` parameter:** Matches Praat’s “power” argument in spectral
moment functions. - `power = 2.0` (default): energy-weighted moments —
standard Praat default - `power = 1.0`: amplitude-weighted moments

**NA handling:** Frames with zero total power return `NA` for all four
moments, matching Praat’s behaviour when the spectrum is silent.

------------------------------------------------------------------------

### Pattern 3: Export to Data Frame (v4.0+: Returns data.table)

**NEW in v4.0:** All
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) methods
now return `data.table` (inherits from `data.frame`) for 5-15x faster
batch operations.

``` r
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

**Performance benefits:** - Fast keyed lookups by
time/formant/frequency -
[`rbindlist()`](https://rdrr.io/pkg/data.table/man/rbindlist.html) for
efficient aggregation (replaces slow rbind loops) - In-place
modification for memory efficiency - 5-15x faster for batch operations

**Matrix export:** `as.matrix(x)` works on any object that has
`$as_matrix()` (Sound, Pitch, Intensity, Spectrogram, Ltas, the tiers,
Matrix, Polygon, …) and returns exactly what that method returns; the
classes without one raise a catchable `pladdrr_input_error` naming the
class rather than returning a fake matrix, so use `as.data.frame(x)` for
those.

### Pattern 4: Tier Manipulation (PitchTier v4.6.6+)

``` r
# === CREATE AND POPULATE PITCHTIER ===
pt <- PitchTier(0, 2)  # Empty tier from 0 to 2 seconds
pt$add_point(0.5, 120)  # 120 Hz at 0.5s
pt$add_point(1.0, 150)  # 150 Hz at 1.0s
pt$add_point(1.5, 100)  # 100 Hz at 1.5s

# === EXTRACT FROM PITCH ANALYSIS ===
pitch <- sound$to_pitch()
pitch_tier <- pitch$down_to_pitch_tier()

# === QUERY TIER ===
n <- pitch_tier$get_number_of_points()
f0_min <- pitch_tier$get_minimum()
f0_max <- pitch_tier$get_maximum()
f0_mean <- pitch_tier$get_mean()
f0_at_1s <- pitch_tier$get_value_at_time(1.0)

# === MODIFY TIER ===
pitch_tier$add_point(time = 1.0, value = 150.0)
pitch_tier$remove_point(index = 1)
pitch_tier$multiply_frequencies(1.2)  # +20%
pitch_tier$shift_frequencies(10, "hertz")  # +10 Hz

# === SMOOTHING ===
pitch_tier$interpolate_quadratically(4, FALSE)  # 4 points per parabola

# === SYNTHESIZE SOUND FROM PITCHTIER ===
snd_sine <- pitch_tier$to_sound_sine(16000)
snd_pulse <- pitch_tier$to_sound_pulse_train(16000)
snd_phon <- pitch_tier$to_sound_phonation(16000)

# === CONVERT PITCHTIER TO PITCH ===
pitch_sampled <- pitch_tier$to_pitch(0.01, 75, 600)

# === EXPORT DATA ===
df <- pitch_tier$as_data_frame()  # data.table: time, frequency
mat <- pitch_tier$as_matrix()     # matrix (n x 2)

# === USE IN RESYNTHESIS (PSOLA) ===
manipulation <- sound$to_manipulation(
  time_step = 0.01,
  pitch_floor = 75,
  pitch_ceiling = 600
)
manipulation$replace_pitch_tier(pitch_tier)
new_sound <- manipulation$to_sound()

# === LOAD/SAVE ===
pitch_tier$save("modified.PitchTier")
pt2 <- PitchTier("modified.PitchTier")
```

### Pattern 5: TextGrid Operations

``` r
# Load TextGrid
tg <- TextGrid("annotations.TextGrid")

# Query structure
n_tiers <- tg$get_number_of_tiers()
tier_name <- tg$get_tier_name(tier_number = 1)
is_interval <- tg$tier_is_interval_tier(tier = 1)

# Query intervals
n_intervals <- tg$get_number_of_intervals(tier = 1)
label <- tg$get_interval_text(tier = 1, interval_number = 5)
start <- tg$get_interval_start_time(tier = 1, interval_number = 5)
end <- tg$get_interval_end_time(tier = 1, interval_number = 5)

# Extract Sound for interval
sound_segment <- sound$extract_part(start, end)
```

### Pattern 6: Voice Activity Detection with ZCR (NEW in v4.0.4)

**Critical for AVQI:** The AVQI algorithm uses both intensity AND Zero
Crossing Rate (ZCR) filtering to identify voiced segments. pladdrr
v4.0.4 adds proper ZCR support matching Praat’s `checkZeros` procedure.

``` r
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

``` r
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

**ZCR interpretation:** - **Voiced speech:** 500-2000 crossings/second
(low ZCR) - **Unvoiced fricatives:** 3000-6000 crossings/second (high
ZCR) - **Silence:** Variable (depends on noise floor)

**AVQI threshold:** `zcr_threshold = 3000` rejects unvoiced segments
(fricatives, aspiration).

------------------------------------------------------------------------
