# Agent Guide: Pitfalls, Limitations and Use Cases

Part of the [Agent
Guide](https://humlab-speech.github.io/pladdrr/articles/agents/agent-guide.md).

## Validation Patterns

### Comparing pladdrr with Praat Script Output

``` r
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

``` r
# Run Praat scripts directly via interpreter wrapper
praat_run_script('
  Read from file: "audio.wav"
  selectObject: "Sound audio"
  duration = Get total duration
')

# Get variables back
duration <- praat_eval_numeric("duration")
```

------------------------------------------------------------------------

## Common Pitfalls

### 1. Class Name Checks (UPDATED v2.1.1)

``` r
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

**Available class names:** `Sound`, `Pitch`, `Formant`, `Intensity`,
`Spectrum`, `Spectrogram`, `TextGrid`, `PointProcess`, `Harmonicity`,
`Ltas`, `Cepstrum`, `PowerCepstrum`, `LPC`, `Cochleagram`, `Excitation`,
`PraatMatrix`, `Table`, `PitchTier`, `FormantTier`, `IntensityTier`,
`AmplitudeTier`, `DurationTier`, `FormantGrid`, `Manipulation`,
`KlattGrid`, `FormantPath`, `ComplexSpectrogram`, `Polygon`,
`VocalTract`, `LongSound`, `Electroglottogram`, `MFCC`, `LFCC`,
`FormantModeler`, `PCA`, `Discriminant`

### 2. Unit Code Mismatch

**NOTE:** Modern pladdrr API accepts strings directly - no need for
manual conversion.

``` r
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

``` r
# Praat uses 1-based indexing
first_frame <- pitch$get_time_from_frame(1)    # Correct
first_frame <- pitch$get_time_from_frame(0)    # Error!

# Interval numbers are also 1-based
label <- tg$get_interval_text(tier = 1, interval_number = 1)
```

### 4. Time Range 0,0 Means “Entire Duration”

``` r
# from_time=0, to_time=0 is special: uses full duration
mean_all <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")

# Explicit range
mean_part <- pitch$get_mean(from_time = 1.0, to_time = 2.0, unit = "hertz")
```

### 5. NA for Undefined Values

``` r
# Pitch returns NA for unvoiced frames
f0 <- pitch$get_value_at_time(time = 1.0, unit = "hertz")
if (is.na(f0)) {
  # Frame is unvoiced
}

# Formant returns NA for missing formants
f5 <- formant$get_value_at_time(formant_number = 5, time = 1.0, unit = "hertz")

# NaN/NA inputs safely return NA (v4.8.22+) — no need to pre-filter
ltas$get_value_at_frequency(NaN)                # returns NA
intensity$get_values_at_times(c(0.1, NaN, 0.3)) # returns c(val, NA, val)
```

### 6. Invalid Pointer Access

``` r
# Always check validity before heavy operations
if (pitch$is_valid()) {
  # Safe to use
  mean_f0 <- pitch$get_mean(0, 0, "hertz")
} else {
  stop("Invalid Pitch object")
}
```

### 7. Method Name Changes (v2.1.1)

``` r
# CORRECT: Use specific method names
formant <- sound$to_formant_burg()      # Burg's method (standard)
pitch <- sound$to_pitch_cc()            # Cross-correlation method

# WRONG: sound$to_formant() does NOT exist — dispatch returns NULL, next call errors
formant <- sound$to_formant()           # Error: use to_formant_burg() (or _robust/_willems)

# sound$to_pitch() IS a first-class, non-deprecated method — both are valid
pitch1 <- sound$to_pitch()              # Praat's default AC method
pitch2 <- sound$to_pitch_cc()           # Cross-correlation method
```

### 8. Property Access (Fast Path)

``` r
# FAST: Direct property access via .cpp (v2.0.8+)
duration <- sound$.cpp$duration         # Direct C++ member access
nx <- sound$.cpp$nx                     # Fast, no function call overhead

# BACKWARD-COMPATIBLE: Method access (still works)
duration <- sound$get_duration()        # Slightly slower, but familiar
nx <- sound$get_number_of_samples()
```

### 9. Batch Operations vs Loops

``` r
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

**Rule:** If you’re writing a loop that calls the same method
repeatedly, check for a vectorized `$get_*_windows()`,
`$get_*_vector()`, or `$get_*_track()` method first.

### 10. Build System: Never Edit `src/Makevars` Directly

`src/Makevars` is **generated** by the `configure` script from
`src/Makevars.in` via `sed` on every `R CMD INSTALL`. Any manual edit to
`src/Makevars` will be silently overwritten.

``` bash
# WRONG: editing Makevars directly (changes lost on next install)
vim src/Makevars

# CORRECT: edit the template, then rebuild
vim src/Makevars.in
R CMD INSTALL .
```

Also do NOT commit `src/Makevars` — verify with `git diff src/Makevars`
before committing.

#### Build System Architecture (v4.9.5+)

**configure** detects two things via `sed` substitution into
`Makevars.in`: - **RcppXsimd** → `@XSIMD_FLAG@` (may expand to
additional xsimd include paths or flags; `-DHAVE_XSIMD` is now also
hardcoded in `PKG_CPPFLAGS` so SIMD is always enabled) - **GSL** →
`@GSL_CFLAGS@` + `@GSL_LIBS@` (via gsl-config → pkg-config → fallback
`-lgsl -lgslcblas`)

**GSL is required.** ~19 GSL functions called from Praat’s
`NUMspecfunc.cpp`, `NUM2.cpp`, `melder.cpp`. Headers come from Praat’s
bundled GSL 1.10 at `praat.github.io/external/gsl/`, but implementations
link against system GSL.

**Windows:** `src/Makevars.win` is NOT generated — it’s a static file
(no `configure.win`) that compiles from the same `praat.github.io/`
prefix as Unix (the old `src/praat/` mirror is gone). It hardcodes
`-lgsl -lgslcblas` (GSL via Rtools MSYS2/ucrt64:
`pacman -S mingw-w64-ucrt-x86_64-gsl`) and must keep defining
`UNICODE`/`_UNICODE` (Praat calls generic Win32 macros with wide buffers
— without these they resolve to `...A` variants and fail on mingw) and
`_FILE_OFFSET_BITS=64`, mirroring Praat’s own mingw makefiles.

**libc++ note:** `PKG_CPPFLAGS` in `Makevars.in` carries
`-D_LIBCPP_DISABLE_DEPRECATION_WARNINGS` — silences C++17
allocator-member deprecations inside RcppXsimd’s
`xsimd_aligned_allocator.hpp` under `--as-cran`; portable define, inert
on libstdc++ (so not needed in `Makevars.win`).

**CRAN-forbidden flags:** Do NOT add `-O3`, `-flto`, `-march=native`, or
`-ffp-contract=off` to Makevars.in — R provides its own optimization via
`Makeconf`. Do NOT re-add `-Wno-*` suppressions (all were removed in
v4.9.6). FP contraction is disabled at source level:
`#pragma STDC FP_CONTRACT OFF` in the vendored `melder.h` (included by
every DSP translation unit; GCC and Clang both honour it) — see
praat-modifications.Rmd. Never restore a compiler-flag version: R CMD
check flags `-ffp-contract=off` in `PKG_CXXFLAGS` as non-portable.
`-DHAVE_XSIMD` is unconditional (no `@XSIMD_FLAG@` substitution any
more); xsimd picks the instruction set at compile time from the
compiler’s default target (SSE2/NEON on CRAN).

The former bundled GSL trees (`src/gsl-2.8/`, `src/praat/external/gsl/`,
`src/build_gsl.sh`) were removed in the v4.9.5 slimming — only Praat’s
GSL 1.10 *headers* under `praat.github.io/external/gsl/` remain in the
tarball.

### 11. Shared Dispatch Table: `$.Type` S3 Methods

Since v4.8.33, ALL 35 wrappers use shared dispatch tables instead of
per-instance closures. Key implications:

``` r
# Methods work identically from the user's perspective:
sound$to_pitch()     # Works — $.Sound dispatches to .sound_methods

# BUT: do.call still works because $.Type returns a bound closure:
do.call(sound$to_pitch, list())  # Works — returns function(...) method(x, ...)

# Field access (.xptr, .cpp) is a fast path via .subset2:
sound$.xptr          # Direct list access, no method lookup

# .pointer is a compat alias for .xptr (Sound, Electroglottogram, AmplitudeTier):
sound$.pointer       # Returns .xptr
```

When adding new methods to any wrapper, add them to the
`.{type}_methods` env in the corresponding `R/*-wrapper.R` file, not
inside the constructor.

### 12. Per-frame R loops over Spectrogram frames

Any R-level loop that calls `spectrogram$to_spectrum(t)` per frame is an
anti-pattern. Each iteration allocates a `structSpectrum` in C++, wraps
it in R, calls the moment function, and GC-collects it — ~5 R→C++
boundary crossings per frame.

``` r
# WRONG (anti-pattern): per-frame loop — 14× slower than Praat
for (ix in seq_len(n_frames)) {
  t    <- spectrogram$.cpp$get_time_from_frame(ix)
  spec <- spectrogram$to_spectrum(t)              # C++ alloc per frame
  cog  <- spec$get_centre_of_gravity(2.0)         # R→C++ per frame
}

# CORRECT (v4.9.1+): single C++ pass
moments <- get_spectral_moments_batch(spectrogram, power = 2.0)
```

The general rule: **if you are iterating over frames and calling the
same per-frame method each time, there should be a C++ batch function
for it.** If one doesn’t exist yet, add it to `src/batch_queries.cpp`
following the `get_jitter_shimmer_batch_cpp` pattern (lines 754–826 as
of v4.9.1).

### 13. Parabolic interpolation with flat LTAS peaks (fixed v4.9.1)

Before v4.9.1, `ltas$get_peaks_batch(interpolation="parabolic")` could
return values in the range 500–1231 dB — physically impossible for any
acoustic spectrum. The cause was a division by near-zero `d2y` in
`NUMimproveExtremum()` when adjacent LTAS bins had nearly equal power
(flat peak). The benchmark saw h1_onset r ≈ −0.08 vs Praat (random
noise).

**Fixed in v4.9.1:** `d2y ≤ 0` guard returns the bin peak unchanged;
`|offset| ≥ 1.0` clamp prevents extrapolation beyond one bin. Safe to
use `interpolation="parabolic"` in v4.9.1+.

**When implementing new Praat procedures that use parabolic
interpolation:** Always test with a flat-spectrum signal (white noise
LTAS) and a pure tone (sharp peak) to confirm the interpolated values
are within ±50 dB of the surrounding bins.

### 14. Short-window formant extraction (fixed v4.9.1)

Before v4.9.1, `to_formant_burg()` on windows ≤100ms returned severely
wrong F1/F2/F3 (r=0.57/0.38 vs Praat; Python/Parselmouth achieved
r\>0.9999 on the same algorithm).

**Root cause:** LAPACK `dhseqr_` silently returns only the eigenvalues
it converged on when the LPC companion matrix is ill-conditioned (short
windows → fewer samples → ill-conditioned autocorrelation). Missing
eigenvalues = missing formants.

**Fixed in v4.9.1:** `burg()` in `Sound_to_Formant.cpp` now detects
`roots->numberOfRoots < coefficients.size` and retries with Laguerre’s
method (`src/polynomial_roots_laguerre.h`), which is robust to
ill-conditioned matrices. Long-window audio is unaffected (fallback
never triggers when `dhseqr_` converges).

``` r
# This now works correctly on short windows (v4.9.1+)
window <- snd$extract_part(0.48, 0.52, "rectangular", 1, FALSE)  # 40ms
fmnt   <- window$to_formant_burg(0.005, 5, 5500, 0.025, 50)
f1     <- fmnt$get_value_at_time(1, 0.02, "hertz")               # now correct

# If you need to verify: compare against full-sound analysis at the same time
fmnt_full <- snd$to_formant_burg(0.005, 5, 5500, 0.025, 50)
f1_ref    <- fmnt_full$get_value_at_time(1, 0.50, "hertz")
stopifnot(abs(f1 - f1_ref) < 200)  # should pass
```

**When implementing any LPC-based procedure:** if the procedure operates
on user-supplied audio windows of unknown length, verify accuracy on
both 40ms and 500ms windows and add both to the faithfulness registry.

### 15. `to_ltas_direct()` returned raw externalptr (fixed v4.9.1)

Before v4.9.1,
[`to_ltas_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_ltas_direct.md)
returned a raw `externalptr` instead of a wrapped `Ltas` object, making
it unusable without manual construction:

``` r
# OLD workaround (pre-v4.9.1) — no longer needed
ltas <- Ltas(.xptr = to_ltas_direct(snd, 1))

# CORRECT (v4.9.1+) — returns wrapped Ltas directly
ltas <- to_ltas_direct(snd, bandwidth = 100)
ltas$get_slope(0, 1000, 1000, 10000, "energy")  # works immediately
```

The underlying C++ `.sound_to_ltas()` was always correct; only the R
wrapper was missing the `Ltas(.xptr = ...)` wrap. All other `*_direct()`
functions were already correct.

------------------------------------------------------------------------

## Deprecated API Migration

⚠️ **Legacy S3 API functions are deprecated and will be removed in
v6.0.0** (still present in v5.2.0)

The following S3-style functions have been replaced by the modern shared
dispatch API. While they still work, they emit deprecation warnings and
should not be used in new code.

### Deprecated Functions → Modern Replacements

| Deprecated Function             | Modern Replacement                   |
|---------------------------------|--------------------------------------|
| `create_sound(values, sr)`      | `Sound$from_values(values, sr)`      |
| `read_sound(file_path)`         | `Sound(file_path)`                   |
| `get_duration(sound)`           | `sound$get_duration()`               |
| `get_sampling_rate(sound)`      | `sound$get_sampling_frequency()`     |
| `get_n_channels(sound)`         | `sound$get_number_of_channels()`     |
| `get_n_samples(sound)`          | `sound$get_number_of_samples()`      |
| `extract_pitch(sound, ...)`     | `sound$to_pitch(...)`                |
| `get_pitch_at_time(pitch, t)`   | `pitch$get_value_at_time(t)`         |
| `get_mean_pitch(pitch)`         | `pitch$get_mean()`                   |
| `get_min_pitch(pitch)`          | `pitch$get_minimum()`                |
| `get_max_pitch(pitch)`          | `pitch$get_maximum()`                |
| `extract_intensity(sound, ...)` | `sound$to_intensity(...)`            |
| `get_intensity_at_time(int, t)` | `intensity$get_value_at_time(t)`     |
| `get_mean_intensity(int)`       | `intensity$get_mean()`               |
| `get_min_intensity(int)`        | `intensity$get_minimum()`            |
| `get_max_intensity(int)`        | `intensity$get_maximum()`            |
| `get_sd_intensity(int)`         | `intensity$get_standard_deviation()` |
| `extract_formants(sound, ...)`  | `sound$to_formant_burg(...)`         |
| `get_formant_at_time(f, n, t)`  | `formant$get_value_at_time(n, t)`    |
| `get_mean_formant(f, n)`        | `formant$get_mean(n)`                |

### Migration Example

**Before (deprecated):**

``` r
# Old S3-style workflow
sound <- read_sound("speech.wav")
duration <- get_duration(sound)
pitch <- extract_pitch(sound, pitch_floor = 75)
mean_f0 <- get_mean_pitch(pitch)
```

**After (modern):**

``` r
# Modern shared dispatch workflow
sound <- Sound("speech.wav")
duration <- sound$get_duration()
pitch <- sound$to_pitch(pitch_floor = 75)
mean_f0 <- pitch$get_mean()
```

### Benefits of Modern API

1.  **Method chaining** - Chain operations:
    `sound$to_pitch()$get_mean()`
2.  **Consistent interface** - All objects follow same pattern:
    `$to_*()`, `$get_*()`
3.  **Better performance** - Direct C++ module binding, no wrapper
    overhead
4.  **Full Praat parity** - More methods available than S3 functions
5.  **Type safety** - Built-in parameter validation

### Removal Timeline

- **v4.x**: Deprecated functions emit warnings
- **v5.x**: Deprecated functions still present and warn
- **v6.0.0**: Deprecated functions will be removed

------------------------------------------------------------------------

## File Locations

    src/
    ├── modules/               # Rcpp Module C++ code (39 modules)
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
    ├── parallel-batch.R       # Parallel processing (exported: analyze_files_parallel, process_sounds_parallel, extract_pitch_parallel, extract_formant_parallel, extract_intensity_parallel, benchmark_parallel)
    ├── zzz.R                  # Module loading
    └── RcppExports.R          # Auto-generated (don't edit)

**File Naming Convention (v4.0.7):** All R wrapper files use
`-wrapper.R` suffix (not `-r6.R`) to accurately reflect the shared
dispatch table pattern used instead of R6 classes.

------------------------------------------------------------------------

## Known Limitations

### Direct API Pitch Parameters (v4.0.2)

**Status:** ✅ **RESOLVED** - Full-parameter Direct API functions now
available!

**NEW in v4.0.2:** Use
[`to_pitch_ac_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_pitch_ac_direct.md)
or
[`to_pitch_cc_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_pitch_cc_direct.md)
for custom parameters:

``` r
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

**Legacy Function:**
[`to_pitch_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_pitch_direct.md)
remains available but only supports 4 basic parameters (time_step,
pitch_floor, pitch_ceiling, method). Use the new `_ac_direct()` or
`_cc_direct()` variants for custom voicing parameters.

**API Tier Comparison for Custom Parameters:**

``` r
# Tier 1: Standard API (wrapper object returned)
pitch <- sound$to_pitch_cc(voicing_threshold = 0.6)
# Speed: Medium | Returns: Pitch wrapper object

# Tier 2: Direct API (external pointer returned) ⭐ NEW
pitch_ptr <- to_pitch_cc_direct(sound, voicing_threshold = 0.6)
# Speed: Fast (2x faster) | Returns: External pointer

# Tier 3: Batch API (list returned)
pitches <- sound_to_pitch_cc_batch(sounds, voicing_threshold = 0.6)
# Speed: Fastest | Returns: List of Pitch objects | Best for >10 files
```

### to_point_process_periodic_cc Parameters

The R wrapper accepts `time_step`, `max_period_factor`, and
`max_amplitude_factor` parameters for API compatibility with Praat’s
GUI, but **only `pitch_floor` and `pitch_ceiling` are currently used**.
The underlying Praat C function `Sound_to_PointProcess_periodic_cc()`
only accepts minimum and maximum pitch.

``` r
# These parameters are used:
pp <- sound$to_point_process_periodic_cc(pitch_floor = 75, pitch_ceiling = 600)

# These parameters are accepted but ignored:
# time_step, max_period_factor, max_amplitude_factor
```

### pitch_to_pointprocess_peaks (NEW in v4.0.9)

**Purpose:** Extract amplitude peaks and/or troughs from a sound guided
by pitch contour. Essential for **tremor analysis** (vocal amplitude
modulation detection).

**Signature:**
`sound$pitch_to_pointprocess_peaks(pitch, include_maxima = TRUE, include_minima = FALSE)`

**Parameters:** - `pitch`: Pitch object (created with
`sound$to_pitch()`) - `include_maxima`: Include amplitude peaks
(default: TRUE) - `include_minima`: Include amplitude troughs (default:
FALSE)

**Returns:** PointProcess object with timestamps of detected
peaks/troughs

**Praat Equivalent:** `Sound & Pitch: To PointProcess (peaks)...`

**Use Case - Tremor Analysis:**

``` r
# Step 1: Extract pitch contour
pitch <- sound$to_pitch(time_step = 0.0, pitch_floor = 75, pitch_ceiling = 600)

# Step 2: Extract amplitude peaks guided by pitch
pp_peaks <- sound$pitch_to_pointprocess_peaks(pitch, 
                                               include_maxima = TRUE, 
                                               include_minima = FALSE)

# Step 3: Get timestamps and amplitudes at peaks
peak_times <- get_pointprocess_times(pp_peaks)
peak_amplitudes <- sapply(peak_times, function(t) {
  sound$get_value_at_time(time = t, channel = 1, interpolation = 2)
})

# Step 4: Calculate tremor intensity (mean absolute deviation)
tremor_intensity <- 100 * mean(abs(peak_amplitudes))
```

**Why Use Pitch-Guided Detection:** - **Accuracy:** Aligns peak
detection with fundamental frequency periods - **Robustness:** Filters
out noise peaks that don’t align with vocal fold cycles - **Clinical
Validity:** Matches Praat’s established tremor analysis methodology

**Alternative - Both Peaks and Troughs:**

``` r
# For comprehensive tremor analysis, analyze both peaks and troughs
pp_peaks <- sound$pitch_to_pointprocess_peaks(pitch, 
                                               include_maxima = TRUE, 
                                               include_minima = FALSE)
pp_troughs <- sound$pitch_to_pointprocess_peaks(pitch, 
                                                 include_maxima = FALSE, 
                                                 include_minima = TRUE)

# Calculate separate intensities (no batch helper exists — sample at each point time)
intensity <- sound$to_intensity()
peak_times <- vapply(seq_len(pp_peaks$get_number_of_points()), pp_peaks$get_time, numeric(1))
trough_times <- vapply(seq_len(pp_troughs$get_number_of_points()), pp_troughs$get_time, numeric(1))
peak_intensity <- vapply(peak_times, intensity$get_value_at_time, numeric(1))
trough_intensity <- vapply(trough_times, intensity$get_value_at_time, numeric(1))
tremor_intensity <- (mean(peak_intensity) + mean(trough_intensity)) / 2
```

**Note:** `calculate_intensity_at_points()` does not exist in this
package — there is no dedicated batch helper for this. Sample
`Intensity$get_value_at_time()` per `PointProcess` timestamp as shown
above.

------------------------------------------------------------------------

### API Naming Differences from Praat/Parselmouth (v4.8.5)

pladdrr uses slightly different parameter/method names than Praat. This
is by design (shorter, more R-idiomatic) but may cause errors when
porting scripts.

**Parameter Name Differences:**

| Function         | Praat/Parselmouth          | pladdrr          |
|------------------|----------------------------|------------------|
| Pitch creation   | `max_number_of_candidates` | `max_candidates` |
| Formant creation | `max_number_of_formants`   | `max_formants`   |
| Formant creation | `maximum_formant`          | `max_formant`    |
| Formant creation | `pre_emphasis_from`        | `pre_emphasis`   |

**Method Name Differences (with v4.8.5 aliases):**

| Operation | Praat | pladdrr (original) | pladdrr (v4.8.5 alias) |
|----|----|----|----|
| LTAS with bandwidth | `To Ltas...` | N/A | ✅ `to_ltas(bandwidth)` |
| LTAS 1-to-1 | `To Ltas (1-to-1)` | `to_ltas_1to1()` | same |
| Power Cepstrum (Spectrum) | `To PowerCepstrum` | `to_powercepstrum()` | ✅ `to_power_cepstrum()` |
| Power Cepstrum (Cepstrum) | `To PowerCepstrum` | `to_powercepstrum()` | ✅ `to_power_cepstrum()` |
| Start time | `Get start time` | `get_xmin()` | ✅ `get_start_time()` |
| End time | `Get end time` | `get_xmax()` | ✅ `get_end_time()` |

**Agent Guidance - Porting Praat Scripts:**

``` r
# Pitch creation
pitch <- to_pitch_cc_direct(sound,
  max_candidates = 15,     # NOT max_number_of_candidates
  pitch_ceiling = 600
)

# Formant creation
formant <- to_formant_direct(sound,
  max_formants = 5,        # NOT max_number_of_formants
  max_formant = 5500,      # NOT maximum_formant
  pre_emphasis = 50        # NOT pre_emphasis_from
)

# Time bounds - BOTH work in v4.8.5+
start <- sound$get_start_time()  # Praat-compatible (v4.8.5+)
end <- sound$get_end_time()      # Praat-compatible (v4.8.5+)
# OR legacy:
start <- sound$get_xmin()
end <- sound$get_xmax()

# Spectrum operations - BOTH work in v4.8.5+
ltas <- spectrum$to_ltas(100)         # Praat-compatible with bandwidth (v4.8.5+)
ltas <- spectrum$to_ltas_1to1()       # Legacy 1-to-1 mapping
cepstrum <- spectrum$to_power_cepstrum()  # Praat-compatible (v4.8.5+)
cepstrum <- spectrum$to_powercepstrum()   # Legacy
```

------------------------------------------------------------------------

### Jitter/Shimmer Value Scaling

**Note:**
[`get_jitter_shimmer_batch()`](https://humlab-speech.github.io/pladdrr/reference/get_jitter_shimmer_batch.md)
returns values as decimals (0.0-1.0), not percentages (0-100).

``` r
js <- get_jitter_shimmer_batch(pp, sound, 0, 0, 0.0001, 0.02, 1.3, 1.6)

# Values are decimals
js$jitter_local   # 0.00478 (not 0.478%)
js$shimmer_local  # 0.02551 (not 2.551%)

# Convert to percentage if needed
jitter_percent <- js$jitter_local * 100   # 0.478%
shimmer_percent <- js$shimmer_local * 100 # 2.551%
```

------------------------------------------------------------------------

### Known limitations after the 2026-11 audit round

- **Praat is not bit-identical across platforms.** On Apple Silicon the
  Praat application and pladdrr differ by ~2e-6 dB in the default-grid
  Intensity energy mean (fused multiply-add flips the centre sample of 5
  of 117 frames at exact rounding boundaries; pladdrr disables
  contraction on purpose). Tolerances in the faithfulness registry cover
  it. See `faithfulness-report.Rmd`.
- **C++ errors are mostly untagged.** Only `batch_queries.cpp`,
  `sound_wrappers.cpp` and the `.xptr` check emit tagged conditions;
  check before relying on a class from an arbitrary routine (see “Typed
  Errors”).
- **Worker conditions are flattened** in
  [`batch_process()`](https://humlab-speech.github.io/pladdrr/reference/batch_process.md)
  (rows with `error_class`) and the `parallel` helpers; they cannot be
  caught by class around the call.
- **[`praat_run_script()`](https://humlab-speech.github.io/pladdrr/reference/praat_run_script.md)
  leaves objects** in Praat’s list, also from a script that fails
  part-way (as Praat does); empty it with
  `PraatInterpreter$new()$clear_objects()`.
- **Automatic thread count** reads affinity and cgroup quota on Linux
  only; macOS and Windows use the machine’s core count.
  `.pladdrr_available_cpus()` reports `$processors`, not a cap set with
  `pladdrr_threads(n)`, so a batch nested inside a capped worker still
  defaults to many workers.
- **`av` fallback:** AAC/MP4 encoder delay is not trimmed (Praat has no
  reader for those containers).
- **Allocation bound:** 2^29 cells (4 GiB of doubles) for tones,
  matrices and cochleagrams; longer inputs raise rather than run.

## Real-World Use Cases (v4.0.3 Optimizations)

This section demonstrates how v4.0.3 batch operations enable efficient
implementation of complex voice analysis workflows that previously
required manual iteration.

### Use Case 1: AVQI (Acoustic Voice Quality Index) - Voice Concatenation

**Challenge:** AVQI requires concatenating 10-50 voiced segments into a
single audio file for analysis. Previous approach used iterative
concatenation which is O(n²).

**v4.0.3 Solution:**
[`sound_concatenate_all()`](https://humlab-speech.github.io/pladdrr/reference/sound_concatenate_all.md)
performs batch concatenation in O(n) time (19x faster).

``` r
# Extract voiced segments from recording
voiced_intervals <- textgrid$get_intervals_where(tier = "voicing", text = "voiced")

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
cpps <- calculate_cpps_fast(concatenated)
pp <- concatenated$to_point_process_periodic_cc()
shimmer <- pp$get_shimmer_local(concatenated)
# ... etc.
```

**Performance:** 19x faster for 30 segments (150ms → 8ms), scales
linearly with segment count.

### Use Case 2: VUV (Voiced/Unvoiced/Voiced) Analysis - TextGrid Merging

**Challenge:** VUV analysis creates voicing annotations that must be
merged with existing TextGrid tiers. Manual approach requires
save/reload + O(n²) boundary insertion.

**v4.0.3 Solution:**
[`textgrid_merge()`](https://humlab-speech.github.io/pladdrr/reference/textgrid_merge.md)
uses Praat’s native batch merge (17x faster).

``` r
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
  start <- vuv_tg$get_interval_start_time(1, j)
  mid <- (start + vuv_tg$get_interval_end_time(1, j)) / 2
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

**Performance:** 17x faster for 100 intervals (1.7s → 0.1s). Avoids disk
I/O and O(n²) insertion.

**Key parameter:** `equalize_domains = FALSE` (default) preserves
original tier domains. Use `TRUE` to extend all tiers to unified domain.

### Use Case 3: Pharyngeal Consonant Analysis - Windowed Resampling

**Challenge:** Pharyngeal consonant analysis requires high-frequency
spectrum analysis (10 kHz) but only for 50ms windows, not entire
recording. Loading and resampling full 10-minute file wastes memory.

**v4.0.3 Solution:**
[`sound_load_window()`](https://humlab-speech.github.io/pladdrr/reference/sound_load_window.md)
loads only needed segment and resamples in one operation (27x faster).

``` r
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

**Performance:** 27x faster (540ms → 20ms per window). Avoids loading
10-minute file for each 50ms analysis.

**Key benefits:** - Loads only requested time window (no full file
I/O) - Resampling happens during load (single operation) -
`preserve_times = FALSE` (default) makes window start at t=0 for simpler
analysis

### Use Case 4: Batch Pitch Extraction with Custom Voicing Parameters

**Challenge:** Analyzing 1000+ files with non-default pitch parameters
(e.g., voicing_threshold for creaky voice).

**v4.0.3 Solution:** Combine Direct API (`to_pitch_cc_direct`) with
batch operations.

``` r
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

### Use Case 5: Prosodic Feature Extraction at Target Times

**Challenge:** Extract F0, formants, intensity, and spectral features at
predetermined analysis points (e.g., INTSINT targets, syllable nuclei)
for prosodic research.

**Solution:** Extract analysis objects once, use batch queries at all
target times.

``` r
# 1. Extract analysis objects once
sound <- Sound("utterance.wav")
pitch <- sound$to_pitch()
formant <- sound$to_formant_burg()
intensity <- sound$to_intensity()
ltas <- sound$to_ltas(100)

# 2. Define target times (e.g., from TextGrid or INTSINT)
targets <- c(0.12, 0.34, 0.56, 0.78, 1.01)

# 3. Batch extraction at all targets
f0 <- pitch$get_values_at_times(targets)
f1 <- formant$get_values_at_times(1, targets)
f2 <- formant$get_values_at_times(2, targets)
f3 <- formant$get_values_at_times(3, targets)
int <- intensity$get_values_at_times(targets)

# 4. Spectral measures (whole-utterance)
spectral_slope <- ltas$get_spectral_slope(100, 5000)
band_peaks <- ltas$get_peaks_batch(
  fmins = c(0, 1000, 2000),
  fmaxs = c(1000, 2000, 4000)
)

# 5. Assemble results
library(data.table)
results <- data.table(
  time = targets,
  f0 = f0, f1 = f1, f2 = f2, f3 = f3,
  intensity = int,
  spectral_slope = spectral_slope
)
```

**Performance:** Batch queries avoid per-target C++ call overhead. For
100 targets: ~2ms batch vs ~50ms loop.

------------------------------------------------------------------------

### Migration Checklist for Agents

When reimplementing Praat code that involves:

**✓ Multiple sound concatenation:** - Replace
`Reduce(sounds_append, sound_list)` or loops with
`sound_concatenate_all(sound_list)` - Speedup: 19x for 30 segments

**✓ TextGrid tier merging:** - Replace save/reload + manual
`insert_boundary()` loops with `textgrid_merge(list(tg1, tg2))` -
Speedup: 17x for 100 intervals

**✓ Analysis of small windows in large files:** - Replace
`Sound(file) |> extract_part() |> resample()` with
`sound_load_window(file, start, end, resample_to)` - Speedup: 27x for
50ms windows in 10-minute files

**✓ Batch processing with custom parameters:** - Use Tier 3
[`sound_to_pitch_cc_batch()`](https://humlab-speech.github.io/pladdrr/reference/sound_to_pitch_cc_batch.md)
instead of loops - Use Tier 2
[`to_pitch_cc_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_pitch_cc_direct.md)
if only need external pointers - Both support full parameter set
(v4.0.2+)

------------------------------------------------------------------------
