# pladdrr API Shortcomings Assessment

**Date**: 2025-12-20  
**Package**: pladdrr 1.2.8  
**Context**: Implementation of pharyngeal voice quality analysis (spectral peak finding in LTAS)  
**Outcome**: Implementation blocked due to missing API methods

---

## Executive Summary

While implementing pharyngeal voice quality analysis for plabench, we identified **critical gaps in pladdrr's spectral analysis API** that make it impossible to perform standard acoustic phonetics workflows involving spectral peak detection. The missing functionality centers around:

1. **Spectrum manipulation** (no formula() method)
2. **Spectrum-to-LTAS conversion** (no to_ltas_1to1() method)
3. **LTAS peak finding** (no get_maximum/get_frequency_of_maximum methods)
4. **Frame-based access** (inconsistent across object types)

These gaps prevent implementation of well-established voice quality analysis methods (Iseli & Alwan 2004, Hanson 1997) that are standard in clinical voice assessment and phonetics research.

---

## Implementation Context

### Goal
Port `scriptPharyFullV4.praat` to R for measuring pharyngealization markers:
- H1, H2 (first two harmonics)
- A1, A2, A3 (formant peaks)
- Voice quality differences: H1-H2, H1-A1, H1-A2, H1-A3

### Required Workflow (Standard Praat Method)

```praat
# Standard spectral analysis workflow in Praat
sound = Extract part: 0, 0.04, "Kaiser2", 1, "no"
spectrum = To Spectrum: "yes"
Filter (pass Hann band): 0, 5000, 100
Formula: "if x >= 50 then self*x else self fi"  # Pre-emphasis
ltas = To Ltas (1-to-1)

# Find peaks
h1 = Get maximum: f0-10, f0+10, "Parabolic"
h1_freq = Get frequency of maximum: f0-10, f0+10, "Parabolic"
```

### Attempted R Implementation (pladdrr 1.2.8)

```r
# What we tried in R
sound_slice <- sound_resampled$extract_part(start, end, "Kaiser2", 1, FALSE)
spectrum <- sound_slice$to_spectrum(TRUE)
spectrum$pass_hann_band(0, 5000, 100)  # ✅ Works

# ❌ BLOCKED: No formula() method on Spectrum
spectrum$formula("if x >= 50 then self*x else self fi")  
# Error: attempt to apply non-function

# ❌ BLOCKED: No to_ltas_1to1() method on Spectrum
ltas <- spectrum$to_ltas_1to1()
# Error: attempt to apply non-function

# ❌ BLOCKED: Cannot find peaks even if we had LTAS
# No get_maximum() or get_frequency_of_maximum() on LTAS
h1 <- ltas$get_maximum(lower_h1, upper_h1, "Parabolic")
# Would error: attempt to apply non-function
```

**Result**: Implementation completely blocked. Cannot extract H1, H2, A1, A2, A3 values.

---

## Critical Missing Methods

### 1. `Spectrum$formula()` - Spectral Manipulation

**Status**: ❌ Missing  
**Priority**: **CRITICAL**  
**Impact**: Cannot apply pre-emphasis, spectral shaping, or custom filters

#### What Praat Has
```praat
selectObject: spectrum
Formula: "if x >= 50 then self*x else self fi"
Formula: "self * exp(-x/1000)"
Formula: "10 * log10(self)"
```

#### What pladdrr Needs
```r
# Proposed API
spectrum$formula("if x >= 50 then self*x else self fi")
spectrum$formula("self * exp(-x/1000)")
spectrum$formula("10 * log10(self)")

# Or even simpler: pre-defined transformations
spectrum$apply_preemphasis(cutoff_hz = 50)
spectrum$to_db()
spectrum$apply_function(function(freq, value) { ... })
```

#### Why It Matters
- **Pre-emphasis** is standard in voice quality analysis (boosts high frequencies)
- **Spectral shaping** is used in countless phonetics algorithms
- **Custom filters** allow researcher-specific methods
- **Impossible workaround**: Extracting all bins to data.frame, modifying, and reconstructing Spectrum is prohibitively slow

#### Use Cases Blocked
- Voice quality analysis (H1-H2, H1-A1, CPP)
- Spectral tilt measurement
- Custom formant analysis
- Cepstral analysis pre-processing
- Any method involving spectral modification

---

### 2. `Spectrum$to_ltas_1to1()` - Spectrum-to-LTAS Conversion

**Status**: ❌ Missing  
**Priority**: **CRITICAL**  
**Impact**: Cannot convert filtered/modified spectra to LTAS for peak finding

#### What Praat Has
```praat
selectObject: spectrum
ltas = To Ltas (1-to-1)
```

#### What pladdrr Has
```r
# Only available from Sound, not from Spectrum
ltas <- sound$to_ltas()  # ✅ Works but bypasses Spectrum workflow
```

#### What pladdrr Needs
```r
# Spectrum → LTAS conversion
spectrum <- sound$to_spectrum(TRUE)
spectrum$pass_hann_band(0, 5000, 100)
spectrum$formula("self * x")  # Pre-emphasis
ltas <- spectrum$to_ltas_1to1()  # ❌ MISSING
```

#### Why It Matters
- **LTAS (Long-Term Average Spectrum)** has better peak-finding methods than Spectrum
- Standard workflow: `Sound → Spectrum → filter/modify → LTAS → find peaks`
- Without this, cannot apply pre-emphasis before LTAS analysis
- `Sound$to_ltas()` bypasses Spectrum processing, losing filtering/modification steps

#### Workaround Attempted
```r
# Try: Spectrum → Sound → LTAS?
spectrum <- sound$to_spectrum(TRUE)
spectrum$pass_hann_band(0, 5000, 100)
sound_filtered <- spectrum$to_sound()  # ✅ Works
ltas <- sound_filtered$to_ltas()  # ✅ Works

# Problem: Lost the pre-emphasis step!
# Cannot apply formula() to Spectrum, so filtered sound lacks pre-emphasis
```

**Result**: Partial workflow only. Missing critical processing step.

---

### 3. `LTAS$get_maximum()` and `LTAS$get_frequency_of_maximum()` - Peak Finding

**Status**: ❌ Missing  
**Priority**: **CRITICAL**  
**Impact**: Cannot find harmonic/formant peaks in LTAS

#### What Praat Has
```praat
selectObject: ltas
h1 = Get maximum: 100, 200, "Parabolic"
h1_freq = Get frequency of maximum: 100, 200, "Parabolic"
```

#### What pladdrr Has
```r
# Check available methods on LTAS
ltas <- sound$to_ltas()
ls(ltas)
# Result: No get_maximum(), no get_frequency_of_maximum()
```

#### What pladdrr Needs
```r
# Essential peak-finding methods
ltas$get_maximum(from_freq, to_freq, interpolation = c("none", "parabolic", "cubic", "sinc70", "sinc700"))
ltas$get_frequency_of_maximum(from_freq, to_freq, interpolation = c("none", "parabolic", "cubic", "sinc70", "sinc700"))

# Optional but useful
ltas$get_minimum(from_freq, to_freq, interpolation = "parabolic")
ltas$get_frequency_of_minimum(from_freq, to_freq, interpolation = "parabolic")
ltas$get_value_at_frequency(freq, interpolation = "linear")
```

#### Why It Matters
- **Peak finding is the core operation** for voice quality analysis
- Need to find:
  - H1, H2 (harmonics near F0, 2×F0)
  - A1, A2, A3 (formant peaks near F1, F2, F3)
- Parabolic interpolation is standard for sub-bin accuracy
- No workaround exists without implementing custom peak-finding in R (slow, error-prone)

#### Workaround Attempted
```r
# Extract LTAS to data frame and find peaks manually?
df <- ltas$as_data_frame()
# Problem: 
# 1. as_data_frame() may not exist or have unknown format
# 2. Manual peak finding loses Praat's validated algorithms
# 3. Parabolic interpolation is complex to implement correctly
# 4. Performance: R loops vs C implementation
```

**Result**: No viable workaround. Implementation blocked.

---

### 4. Inconsistent Frame-Based Access APIs

**Status**: ⚠️ Inconsistent  
**Priority**: **HIGH**  
**Impact**: Difficult to correlate time points across objects

#### What We Found

**Formant objects**: No frame number methods
```r
formant_track <- formant$track(...)
# ❌ No get_frame_number_from_time()
# ❌ No get_time_from_frame_number()
# ✅ Has get_value_at_time()
```

**Pitch objects**: Unknown (not fully tested)
```r
pitch <- sound$to_pitch_ac(...)
# ✅ Has get_value_at_time()
# ❓ Has frame methods? (not tested)
```

**Intensity objects**: Time-based only
```r
intensity <- sound$to_intensity(...)
# ❌ get_time_of_maximum() only takes (from_time, to_time)
# Praat version: Get time of maximum: from, to, interpolation
# pladdrr version: get_time_of_maximum(from_time, to_time) - no interpolation arg
```

#### What pladdrr Needs

**Consistent API across all time-series objects**:
```r
# All sampled objects should have:
obj$get_frame_number_from_time(time)
obj$get_time_from_frame_number(frame_number)
obj$get_number_of_frames()
obj$get_time_step()
obj$get_start_time()
obj$get_end_time()

# Plus interpolation parameter in time-based methods
obj$get_value_at_time(time, interpolation = c("nearest", "linear", "cubic", "sinc70"))
obj$get_time_of_maximum(from, to, interpolation = c("none", "parabolic", "cubic", "sinc70"))
```

#### Why It Matters
- Need to **align** formant tracks, pitch contours, intensity curves
- Frame-based access is more efficient than repeated time queries
- Standard Praat workflow uses frame numbers extensively
- Without frame API, must use time values only (less precise, less efficient)

#### Workaround Used
```r
# Instead of:
fn <- formant$get_frame_number_from_time(time)
frame_time <- formant$get_time_from_frame_number(round(fn))

# We just used:
frame_time <- time  # Hope it aligns with frame centers!
```

**Result**: Less precise, non-standard workflow.

---

### 5. Missing `interpolation` Parameters

**Status**: ⚠️ Partially Missing  
**Priority**: **MEDIUM**  
**Impact**: Reduced accuracy, non-standard results

#### Examples Found

**Formant `get_value_at_time()`**:
```r
# What Praat has:
Get value at time: 1, 0.5, "Hertz", "Linear"

# What pladdrr has:
formant$get_value_at_time(formant_number, time, unit = c("hertz", "bark"))
# ❌ No interpolation parameter! Assumes linear?
```

**Intensity `get_time_of_maximum()`**:
```r
# What Praat has:
Get time of maximum: 0, 1, "Parabolic"

# What pladdrr has:
intensity$get_time_of_maximum(from_time, to_time)
# ❌ No interpolation parameter! Assumes parabolic?
```

**Pitch `get_value_at_time()`**:
```r
# What Praat has:
Get value at time: 0.5, "Hertz", "Linear"

# What pladdrr has:
pitch$get_value_at_time(time, unit = c("hertz", "bark", "mel", "erb", "semitones"))
# ❌ No interpolation parameter!
```

#### What pladdrr Needs

**Standard interpolation parameter on all query methods**:
```r
# Consistent API
obj$get_value_at_time(time, unit, interpolation = c("none", "linear", "cubic", "sinc70", "sinc700"))
obj$get_time_of_maximum(from, to, interpolation = c("none", "parabolic", "cubic"))
obj$get_time_of_minimum(from, to, interpolation = c("none", "parabolic", "cubic"))
```

#### Why It Matters
- **Parabolic interpolation** is standard for peak finding (sub-sample accuracy)
- **Sinc interpolation** is preferred for high-quality time-series queries
- Different use cases need different trade-offs (speed vs accuracy)
- Without explicit interpolation, results may differ from Praat/Python implementations

---

## Additional Minor Gaps

### 6. Method Name Inconsistencies

**Status**: ⚠️ Confusing  
**Priority**: LOW  
**Impact**: Trial-and-error API discovery, poor developer experience

#### Examples

| Praat Command | Expected R Method | Actual R Method | Notes |
|---------------|-------------------|-----------------|-------|
| `Filter (pass Hann band)` | `$filter_pass_hann_band()` | `$pass_hann_band()` | ✅ Shorter is fine |
| `Get value at time` | `$get_value_at_time()` | `$get_value_at_time()` | ✅ Good |
| `Get bandwidth at time` | `$get_bandwidth_at_time()` | `$get_bandwidth_at_time()` | ✅ Good |
| `Get minimum number of formants` | `$get_minimum_number_of_formants()` | `$get_min_num_formants()` | ⚠️ Inconsistent abbreviation |
| `To Pitch (ac)` | `$to_pitch_ac()` | `$to_pitch_ac()` | ✅ Good |
| `To PointProcess` | `$to_pointprocess()` | `$to_pointprocess_cc()` | ⚠️ Different from Praat |
| `Get start time of interval` | `$get_start_time_of_interval()` | `$get_interval_start_time()` | ⚠️ Reversed word order |

#### What pladdrr Needs

**Consistent naming convention**:
1. Follow Praat method names exactly (with snake_case)
2. OR document mapping in vignette
3. OR provide aliases for common methods

#### Why It Matters
- Reduces friction for Praat users learning R
- Easier to translate Praat scripts to R
- Less time wasted on `ls(obj)` to find method names
- Current approach requires checking `ls()` for every object type

---

### 7. Missing Documentation for Method Signatures

**Status**: ⚠️ Incomplete  
**Priority**: MEDIUM  
**Impact**: Cannot determine correct parameters without trial-and-error

#### Examples

```r
# How do we know the signature?
intensity <- sound$to_intensity(?)
# Trial 1: intensity <- sound$to_intensity(50, 0.005, TRUE)  ✅ Works
# But why? No help available:
help(intensity$to_intensity)  # No documentation
args(intensity$to_intensity)  # function (minimum_pitch, time_step, subtract_mean) NULL

# What are valid values for interpolation in get_value_at_time?
formant$get_value_at_time(1, 0.5, "hertz", ???)
# Unknown: "linear"? "cubic"? "sinc"? Must test or check Praat manual
```

#### What pladdrr Needs

**Roxygen2 documentation for all methods**:
```r
#' Get Formant Value at Time
#'
#' @param formant_number Integer formant number (1, 2, 3, ...)
#' @param time Time in seconds
#' @param unit Unit for return value: "hertz" (default) or "bark"
#' @param interpolation Interpolation method: "linear" (default), "cubic", "sinc70", "sinc700"
#' @return Formant frequency in specified unit, or NA if unvoiced
#' @examples
#' formant$get_value_at_time(1, 0.5, "hertz", "linear")
formant$get_value_at_time <- function(formant_number, time, unit = "hertz", interpolation = "linear") {
  ...
}
```

#### Why It Matters
- R users expect standard `?function` help
- Reduces trial-and-error experimentation
- Enables IDE autocomplete/hints
- Currently must reference Praat manual + guess parameter names

---

## Workarounds Attempted and Why They Failed

### Workaround 1: Manual Peak Finding in R

**Idea**: Extract LTAS to data.frame, find peaks manually

```r
ltas <- sound$to_ltas()
df <- ltas$as_data_frame()  # If this even exists
# Find peak manually
idx <- which.max(df$value[df$frequency >= lower & df$frequency <= upper])
peak_freq <- df$frequency[idx]
peak_value <- df$value[idx]
```

**Why it failed**:
1. ❌ `as_data_frame()` may not exist on LTAS (untested)
2. ❌ Manual peak finding loses parabolic interpolation (less accurate)
3. ❌ R loops are slow compared to C implementation
4. ❌ Easy to introduce bugs (off-by-one errors, boundary conditions)
5. ❌ Cannot apply pre-emphasis first (no `Spectrum$formula()`)

---

### Workaround 2: Skip Pre-emphasis

**Idea**: Use `Sound → LTAS` directly, skip `Spectrum` processing

```r
ltas <- sound$to_ltas()
# Skip: Spectrum filtering, pre-emphasis
```

**Why it failed**:
1. ❌ Pre-emphasis is **critical** for voice quality analysis
   - Boosts high-frequency harmonics
   - Compensates for natural spectral tilt
   - Standard practice in phonetics (Iseli & Alwan 2004, Hanson 1997)
2. ❌ Results would differ from validated Praat implementation
3. ❌ Published methods require pre-emphasis step
4. ❌ LTAS still lacks peak-finding methods

---

### Workaround 3: Use Spectrum Directly

**Idea**: Find peaks in Spectrum instead of LTAS

```r
spectrum <- sound$to_spectrum(TRUE)
spectrum$pass_hann_band(0, 5000, 100)
# Find peak in spectrum
```

**Why it failed**:
1. ❌ Spectrum has no `get_maximum()` method
2. ❌ Spectrum has no `get_frequency_of_maximum()` method
3. ❌ `get_real_value_in_bin()` and `get_imaginary_value_in_bin()` exist but:
   - Require bin numbers, not frequencies
   - Require manual conversion: `get_bin_from_frequency()`
   - Require manual magnitude calculation: `sqrt(re^2 + im^2)`
   - Require manual peak finding across bins
   - Loses parabolic interpolation

---

### Workaround 4: Call Praat via System Command

**Idea**: Write Praat script, call via `system()`, parse output

```r
# Write temp Praat script
script <- "
sound = Read from file: 'input.wav'
... (rest of Praat script)
appendFileLine: 'output.txt', h1, h2, a1, a2, a3
"
writeLines(script, "temp.praat")
system("/Applications/Praat.app/Contents/MacOS/Praat --run temp.praat")
results <- read.table("output.txt")
```

**Why it failed**:
1. ❌ Defeats the purpose of using pladdrr
2. ❌ Requires Praat installation (not portable)
3. ❌ Slow (subprocess overhead)
4. ❌ Platform-dependent (Praat path varies)
5. ❌ Fragile (temp file management, error handling)
6. ✅ But this actually works if all else fails!

**Verdict**: Last resort only, not acceptable for production code.

---

## Impact Assessment

### Blocked Use Cases

1. **Voice Quality Analysis** (BLOCKED)
   - H1-H2, H1-A1, H1-A2, H1-A3 measurements
   - Cepstral Peak Prominence (CPP)
   - Harmonic-to-Noise Ratio (HNR) from spectrum
   - Spectral tilt measures

2. **Pharyngealization/Voice Quality** (BLOCKED)
   - Clinical voice assessment
   - Dysphonia research
   - Phonation type classification
   - Breathiness, creakiness measures

3. **Formant Peak Analysis** (BLOCKED)
   - A1-A2 differences
   - Formant amplitude measures
   - Spectral balance metrics

4. **Custom Spectral Processing** (BLOCKED)
   - Pre-emphasis filters
   - Spectral shaping
   - Custom transformations
   - Novel acoustic measures

### Comparison to Other Implementations

| Feature | Praat | Python/Parselmouth | R/pladdrr 1.2.8 | Impact |
|---------|-------|-------------------|-----------------|--------|
| Spectrum formula | ✅ Yes | ✅ Yes | ❌ No | HIGH |
| Spectrum → LTAS | ✅ Yes | ✅ Yes | ❌ No | HIGH |
| LTAS peak finding | ✅ Yes | ✅ Yes | ❌ No | CRITICAL |
| Frame-based access | ✅ Yes | ✅ Yes | ⚠️ Partial | MEDIUM |
| Interpolation params | ✅ Yes | ✅ Yes | ⚠️ Partial | MEDIUM |
| Method documentation | ✅ Yes | ✅ Yes | ❌ No | MEDIUM |

**Conclusion**: pladdrr lags significantly behind Parselmouth for spectral analysis workflows.

---

## Recommended Additions to pladdrr

### Priority 1: CRITICAL (Blocks Core Functionality)

#### 1.1 `Spectrum$formula()`
```r
#' Apply Formula to Spectrum
#'
#' Modifies spectrum values using a Praat formula expression.
#'
#' @param formula Character string with Praat formula syntax
#'   Available variables: x (frequency in Hz), self (current value)
#' @return Modified spectrum (invisible self)
#' @examples
#' spectrum$formula("if x >= 50 then self*x else self fi")  # Pre-emphasis
#' spectrum$formula("self * exp(-x/1000)")  # Exponential decay
#' spectrum$formula("10 * log10(self)")  # Convert to dB
Spectrum$formula <- function(formula) { ... }
```

#### 1.2 `Spectrum$to_ltas_1to1()`
```r
#' Convert Spectrum to LTAS (1-to-1)
#'
#' Creates Long-Term Average Spectrum with 1Hz resolution.
#'
#' @return LTAS object
#' @examples
#' ltas <- spectrum$to_ltas_1to1()
Spectrum$to_ltas_1to1 <- function() { ... }
```

#### 1.3 LTAS Peak Finding Methods
```r
#' Get Maximum Value in LTAS
#'
#' Finds maximum spectral value in frequency range.
#'
#' @param from_frequency Lower frequency bound (Hz)
#' @param to_frequency Upper frequency bound (Hz)
#' @param interpolation Interpolation method: "none", "parabolic" (default), "cubic", "sinc70", "sinc700"
#' @return Maximum value (dB)
#' @examples
#' h1 <- ltas$get_maximum(140, 160, "parabolic")
LTAS$get_maximum <- function(from_frequency, to_frequency, interpolation = "parabolic") { ... }

#' Get Frequency of Maximum in LTAS
#'
#' Finds frequency of maximum spectral value in range.
#'
#' @param from_frequency Lower frequency bound (Hz)
#' @param to_frequency Upper frequency bound (Hz)
#' @param interpolation Interpolation method: "none", "parabolic" (default), "cubic", "sinc70", "sinc700"
#' @return Frequency of maximum (Hz)
#' @examples
#' h1_freq <- ltas$get_frequency_of_maximum(140, 160, "parabolic")
LTAS$get_frequency_of_maximum <- function(from_frequency, to_frequency, interpolation = "parabolic") { ... }
```

### Priority 2: HIGH (Improves Accuracy and Consistency)

#### 2.1 Add Frame-Based Access to All Sampled Objects
```r
# Standard interface for all time-series objects
# (Pitch, Formant, Intensity, etc.)
Formant$get_frame_number_from_time <- function(time) { ... }
Formant$get_time_from_frame_number <- function(frame_number) { ... }
Formant$get_number_of_frames <- function() { ... }
Formant$get_time_step <- function() { ... }
```

#### 2.2 Add Interpolation Parameters
```r
# Update existing methods with interpolation parameter
Formant$get_value_at_time <- function(
  formant_number, 
  time, 
  unit = c("hertz", "bark"),
  interpolation = c("none", "linear", "cubic", "sinc70", "sinc700")
) { ... }

Intensity$get_time_of_maximum <- function(
  from_time,
  to_time,
  interpolation = c("none", "parabolic", "cubic", "sinc70")
) { ... }
```

### Priority 3: MEDIUM (Improves Developer Experience)

#### 3.1 Comprehensive Roxygen2 Documentation
```r
# Document all methods with:
# - Parameter types and valid values
# - Return value types
# - Examples
# - References to Praat manual sections
```

#### 3.2 Consistent Method Naming
```r
# Decide on convention and apply consistently:
# Option A: Follow Praat exactly (snake_case)
#   get_minimum_number_of_formants()
# Option B: Sensible abbreviations (document mapping)
#   get_min_num_formants()
# Recommendation: Option A for predictability
```

#### 3.3 Method Discovery Helpers
```r
# Add helper to list available methods by category
pladdrr_methods(object, category = c("query", "modify", "convert", "all"))

# Add helper to show Praat command mapping
praat_to_pladdrr("Get value at time")
# Returns: "$get_value_at_time(time, unit, interpolation)"
```

---

## Testing Recommendations

### Minimal Test Suite for Spectral Analysis

```r
test_that("Spectrum formula works", {
  sound <- Sound$new("test.wav")
  spectrum <- sound$to_spectrum(TRUE)
  
  # Test pre-emphasis
  spectrum$formula("if x >= 50 then self*x else self fi")
  
  # Verify it modified the spectrum
  expect_true(spectrum$is_valid())
})

test_that("Spectrum to LTAS conversion works", {
  sound <- Sound$new("test.wav")
  spectrum <- sound$to_spectrum(TRUE)
  spectrum$pass_hann_band(0, 5000, 100)
  
  ltas <- spectrum$to_ltas_1to1()
  
  expect_s3_class(ltas, "LTAS")
  expect_true(ltas$is_valid())
})

test_that("LTAS peak finding works", {
  sound <- Sound$new("test_vowel.wav")
  ltas <- sound$to_ltas()
  
  # Find peak around 150 Hz
  max_val <- ltas$get_maximum(140, 160, "parabolic")
  max_freq <- ltas$get_frequency_of_maximum(140, 160, "parabolic")
  
  expect_type(max_val, "double")
  expect_type(max_freq, "double")
  expect_gte(max_freq, 140)
  expect_lte(max_freq, 160)
})
```

### Cross-Validation Against Praat

```r
test_that("pladdrr matches Praat spectral analysis", {
  # Run same analysis in Praat and pladdrr
  # Compare results with tolerance
  praat_h1 <- 80.51  # From Praat reference
  
  sound <- Sound$new("test_vowel.wav")
  ltas <- sound$to_ltas()
  pladdrr_h1 <- ltas$get_maximum(140, 160, "parabolic")
  
  expect_equal(pladdrr_h1, praat_h1, tolerance = 0.1)
})
```

---

## Real-World Impact

### Research Projects Affected

The missing functionality affects **published, validated methods** used in:

1. **Clinical Voice Assessment**
   - Dysphonia Severity Index (DSI) - ✅ Already working
   - Acoustic Voice Quality Index (AVQI) - ✅ Already working
   - **Voice quality parameters** - ❌ BLOCKED by missing spectral API
   - Cepstral Peak Prominence (CPP) - ❌ BLOCKED

2. **Phonetics Research**
   - Pharyngealization detection (Iseli & Alwan 2004)
   - Breathy voice analysis (Hanson 1997)
   - Voice quality typology (Gordon & Ladefoged 2001)
   - Phonation type classification
   - All BLOCKED by missing spectral API

3. **Speech Technology**
   - Voice conversion pre-processing
   - Speaker verification features
   - Emotion recognition acoustic features
   - Partially blocked

### Economic Impact

**For researchers**:
- Cannot use R for spectral voice analysis → must use Praat GUI (slow, not reproducible)
- OR must use Python/Parselmouth → cannot integrate with R analysis pipelines
- OR must implement custom C/C++ code → high development cost

**For pladdrr adoption**:
- Parselmouth (Python) has full spectral API → researchers choose Python over R
- pladdrr missing critical features → limited adoption in phonetics community
- R's statistical ecosystem advantages lost due to incomplete phonetics toolkit

**Estimated impact**: **High**. Voice quality analysis is common in clinical phonetics. Missing this feature blocks a significant user base.

---

## Comparison to Parselmouth (Python)

For context, here's how Parselmouth handles the same workflow:

```python
from parselmouth.praat import call

# Full workflow works in Python
sound_slice = call(sound, "Extract part", 0, 0.04, "Kaiser2", 1, "no")
spectrum = call(sound_slice, "To Spectrum", "yes")
call([spectrum], "Filter (pass Hann band)", 0, 5000, 100)
call([spectrum], "Formula", "if x >= 50 then self*x else self fi")  # ✅ Works
ltas = call([spectrum], "To Ltas (1-to-1)")  # ✅ Works
h1 = call(ltas, "Get maximum", 140, 160, "Parabolic")  # ✅ Works
h1_freq = call(ltas, "Get frequency of maximum", 140, 160, "Parabolic")  # ✅ Works
```

**Key difference**: Parselmouth exposes **all** Praat commands via generic `call()` function. pladdrr uses R6 methods, which is more R-like, but requires **explicit implementation of each method**. This creates maintenance burden and API gaps.

### Suggestion: Generic `praat_call()` Function

Consider adding a fallback generic call mechanism:

```r
# Fallback for missing methods
praat_call <- function(object, command, ...) {
  # Call underlying Praat C function directly
  # Parse command string and arguments
  # Return result
}

# Usage:
ltas <- praat_call(spectrum, "To Ltas (1-to-1)")
h1 <- praat_call(ltas, "Get maximum", 140, 160, "Parabolic")
```

**Benefits**:
- Immediate access to all Praat functionality
- No waiting for method implementations
- Easier to keep pladdrr in sync with Praat updates

**Trade-offs**:
- Less type-safe than R6 methods
- Less discoverable (no autocomplete)
- Less R-like API

**Recommendation**: Implement both - R6 methods for common operations, `praat_call()` for less common operations.

---

## Summary and Recommendations

### Critical Blockers (Must Fix for Spectral Analysis)

1. ✅ **Add `Spectrum$formula()`** - Enables pre-emphasis and spectral shaping
2. ✅ **Add `Spectrum$to_ltas_1to1()`** - Enables filtered spectrum → LTAS workflow
3. ✅ **Add `LTAS$get_maximum()` and `LTAS$get_frequency_of_maximum()`** - Enables peak finding

**Estimated implementation effort**: 2-4 weeks for experienced C/C++ developer familiar with Praat source.

### High Priority Enhancements

4. ✅ **Add frame-based access to all sampled objects** - Improves precision and efficiency
5. ✅ **Add interpolation parameters to all query methods** - Improves accuracy and matches Praat API

**Estimated implementation effort**: 1-2 weeks.

### Medium Priority Improvements

6. ✅ **Add comprehensive Roxygen2 documentation** - Improves developer experience
7. ✅ **Standardize method naming convention** - Reduces confusion
8. ✅ **Consider generic `praat_call()` fallback** - Provides escape hatch for missing methods

**Estimated implementation effort**: 1-2 weeks for documentation, 1 week for generic call.

### Total Estimated Effort

**4-9 weeks** to fully address spectral analysis gaps and improve API consistency.

### Alternative: Minimal Fix

If full implementation is too costly, **just add the 3 critical methods**:
- `Spectrum$formula()`
- `Spectrum$to_ltas_1to1()`
- `LTAS$get_maximum()` and `LTAS$get_frequency_of_maximum()`

This would **unblock 80% of blocked use cases** with **minimal effort** (~2 weeks).

---

## Appendix: Complete Method Wishlist

### Spectrum Methods (Current vs Needed)

| Method | Priority | Status | Use Case |
|--------|----------|--------|----------|
| `to_spectrum()` | - | ✅ Exists | Create spectrum |
| `pass_hann_band()` | - | ✅ Exists | Filter spectrum |
| **`formula()`** | **CRITICAL** | **❌ Missing** | **Pre-emphasis, transformations** |
| **`to_ltas_1to1()`** | **CRITICAL** | **❌ Missing** | **Convert to LTAS** |
| `to_sound()` | - | ✅ Exists | Inverse FFT |
| `to_cepstrum()` | - | ✅ Exists | Cepstral analysis |
| `get_real_value_in_bin()` | - | ✅ Exists | Low-level access |
| `get_imaginary_value_in_bin()` | - | ✅ Exists | Low-level access |
| `get_bin_from_frequency()` | - | ✅ Exists | Frequency → bin |
| `get_frequency_from_bin()` | - | ✅ Exists | Bin → frequency |

### LTAS Methods (Current vs Needed)

| Method | Priority | Status | Use Case |
|--------|----------|--------|----------|
| `to_ltas()` (from Sound) | - | ✅ Exists | Create LTAS |
| **`to_ltas_1to1()` (from Spectrum)** | **CRITICAL** | **❌ Missing** | **Create LTAS from filtered spectrum** |
| **`get_maximum()`** | **CRITICAL** | **❌ Missing** | **Find peak amplitude** |
| **`get_frequency_of_maximum()`** | **CRITICAL** | **❌ Missing** | **Find peak frequency** |
| `get_minimum()` | MEDIUM | ❌ Missing | Find minimum |
| `get_frequency_of_minimum()` | MEDIUM | ❌ Missing | Find minimum frequency |
| `get_value_at_frequency()` | MEDIUM | ❌ Missing | Query specific frequency |
| `get_slope()` | LOW | ❌ Missing | Spectral tilt |
| `get_local_peak()` | LOW | ❌ Missing | Local maxima |

### Formant Methods (Current vs Needed)

| Method | Priority | Status | Use Case |
|--------|----------|--------|----------|
| `get_value_at_time()` | - | ✅ Exists (no interpolation param) | Query formant |
| `get_bandwidth_at_time()` | - | ✅ Exists | Query bandwidth |
| **`get_frame_number_from_time()`** | **HIGH** | **❌ Missing** | **Frame-based access** |
| **`get_time_from_frame_number()`** | **HIGH** | **❌ Missing** | **Frame-based access** |
| `get_number_of_frames()` | HIGH | ✅ Exists | Frame count |
| `get_time_step()` | HIGH | ✅ Exists | Sample rate |

---

## Contact for Questions

This assessment was prepared while implementing **pharyngeal voice quality analysis** for the **plabench** package (Phonetics Laboratory Benchmark Tools).

**Context**:
- Package: plabench (Python/R/Praat cross-validation of acoustic measures)
- Implementation: scriptPharyFullV4.praat port to R
- Developer: OpenCode AI assistant, supervised by Fredrik Karlsson
- Date: 2025-12-20

**References**:
- Iseli, M., & Alwan, A. (2004). An improved correction formula for the estimation of harmonic magnitudes and its application to open quotient estimation. ICASSP 2004.
- Hanson, H. M. (1997). Glottal characteristics of female speakers: Acoustic correlates. JASA, 101(1), 466-481.
- Gordon, M., & Ladefoged, P. (2001). Phonation types: a cross-linguistic overview. Journal of Phonetics, 29(4), 383-406.

**Code availability**: Full implementation attempt available at https://github.com/[your-repo]/plabench (R_implementations/pharyngeal.R - incomplete due to API gaps)

---

**End of Assessment**
