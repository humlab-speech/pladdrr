# Data Model: Praat Objects in R

**Date**: 2025-01-08
**Context**: R6 class definitions with external pointers to Praat C++ objects
**Status**: AMENDED - Replaces S3 data-transfer model with R6 object-oriented model

## Overview

This document defines the R data structures (R6 classes) that represent Praat phonetic objects. Each R6 class acts as a lightweight wrapper around a persistent Praat C++ object, using `Rcpp::XPtr` to maintain the connection. This design mirrors Praat's native object-oriented structure and the proven approach of the Python Parselmouth library.

## Design Principles

1. **R6 Classes**: Use R's R6 object system for encapsulation and stateful objects
2. **External Pointers (XPtr)**: Hold pointers to persistent C++ Praat objects, not data copies
3. **Zero-Copy Operations**: Data remains in C++ memory; only results returned to R
4. **Automatic Memory Management**: XPtr finalizers ensure C++ objects are freed when R objects are garbage collected
5. **Object-Oriented API**: Methods on objects (`sound$extract_pitch()`) match Praat's OOP design
6. **Explicit Data Export**: Use `$as_data_frame()` methods when users need data in R
7. **NA Handling**: Use R's NA for undefined/unmeasurable values in exported data
8. **Validation**: C++ layer validates inputs; R layer provides user-friendly error messages

## Core Object Classes

### 1. Sound Object

Represents digitized audio data. The R6 object holds a pointer to a Praat `Sound` C++ object.

**R6 Class**: `Sound`

**R Structure**:
```r
Sound <- R6Class("Sound",
  inherit = PraatObject,
  
  public = list(
    # Constructor
    initialize = function(path = NULL, from_pointer = NULL) {
      # Creates or wraps XPtr to Praat Sound object
    },
    
    # Query methods
    get_duration = function() { ... },              # Returns numeric (seconds)
    get_sampling_frequency = function() { ... },    # Returns numeric (Hz)
    get_number_of_channels = function() { ... },    # Returns integer
    get_number_of_samples = function() { ... },     # Returns integer
    get_time_from_sample = function(sample) { ... },
    get_value_at_time = function(time, channel = 1) { ... },
    
    # Analysis methods (return new R6 objects)
    to_pitch = function(time_step = 0.0, 
                        pitch_floor = 75, 
                        pitch_ceiling = 600,
                        ...) { ... },                  # Returns Pitch object
    to_formant_burg = function(time_step = 0.0,
                               max_formant = 5500,
                               n_formants = 5,
                               ...) { ... },           # Returns Formant object
    to_intensity = function(min_pitch = 100,
                            time_step = 0.0,
                            ...) { ... },              # Returns Intensity object
    to_spectrogram = function(window_length = 0.005,
                             max_frequency = 5000,
                             ...) { ... },             # Returns Spectrogram object
    
    # Modification methods (in-place operations on C++ object)
    scale_intensity = function(target_intensity) { ... },
    resample = function(new_frequency) { ... },
    
    # Export methods
    as_data_frame = function() { ... },            # Returns data.frame
    save = function(path, format = "WAV") { ... },
    
    # Print method
    print = function() { ... }
  ),
  
  private = list(
    ptr = NULL,  # Rcpp::XPtr<Sound>
    
    finalize = function() {
      # XPtr finalizer handles cleanup automatically
    }
  )
)
```

**C++ Backing**:
```cpp
// XPtr to Praat Sound object
Rcpp::XPtr<Sound> sound_ptr;

// Finalizer automatically called when R object is GC'd
void sound_finalizer(Sound* sound) {
  if (sound != nullptr) {
    forget(sound);  // Praat's memory management
  }
}
```

**Usage Example**:
```r
# Create from file
sound <- Sound$new("recording.wav")

# Query properties (no data copying)
duration <- sound$get_duration()              # 5.2 seconds
sr <- sound$get_sampling_frequency()          # 44100 Hz

# Chain operations (all in C++ memory)
pitch <- sound$to_pitch(pitch_floor = 75)
formants <- sound$to_formant_burg(max_formant = 5500)

# Export data only when needed
df <- sound$as_data_frame()  # Explicit copy to R
```

**Invariants** (enforced in C++ layer):
- `sampling_frequency > 0`
- `duration >= 0`
- `n_samples == ceiling(duration * sampling_frequency)`
- Pointer validity checked before every operation

### 2. Pitch Object

Represents fundamental frequency (F0) measurements over time. The R6 object holds a pointer to a Praat `Pitch` C++ object.

**R6 Class**: `Pitch`

**R Structure**:
```r
Pitch <- R6Class("Pitch",
  inherit = PraatObject,
  
  public = list(
    # Constructor (usually called internally from Sound$extract_pitch())
    initialize = function(path = NULL, from_pointer = NULL) { ... },
    
    # Query methods
    get_time_from_frame = function(frame_number) { ... },
    get_value_at_time = function(time, unit = "Hertz") { ... },  # Returns numeric or NA
    get_mean = function(from_time = 0, to_time = 0, unit = "Hertz") { ... },
    get_median = function(from_time = 0, to_time = 0, unit = "Hertz") { ... },
    get_minimum = function(from_time = 0, to_time = 0, unit = "Hertz") { ... },
    get_maximum = function(from_time = 0, to_time = 0, unit = "Hertz") { ... },
    get_quantile = function(quantile, from_time = 0, to_time = 0, unit = "Hertz") { ... },
    
    # Export methods
    as_data_frame = function() { ... },  # Returns data.frame(time, frequency, strength)
    save = function(path) { ... },
    
    # Print method
    print = function() { ... }
  ),
  
  private = list(
    ptr = NULL,  # Rcpp::XPtr<Pitch>
    finalize = function() { ... }
  )
)
```

**Usage Example**:
```r
# Extract from sound
sound <- Sound$new("vowel.wav")
pitch <- sound$to_pitch(pitch_floor = 75, pitch_ceiling = 300)

# Query values (direct C++ access, no data copying)
mean_f0 <- pitch$get_mean()           # 180.5 Hz
f0_at_midpoint <- pitch$get_value_at_time(0.5)  # 185.2 Hz or NA

# Export only when needed for R analysis
pitch_df <- pitch$as_data_frame()
# data.frame with columns: time, frequency, strength
```

**Exported Data Structure** (from `as_data_frame()`):
```r
data.frame(
  time = numeric,       # Time points (seconds)
  frequency = numeric,  # F0 values (Hz), NA for unvoiced
  strength = numeric    # Pitch strength/confidence [0, 1], NA if no pitch
)
```

**NA Semantics**:
- `frequency = NA`: Unvoiced segment or pitch tracking failed
- `strength = NA`: No pitch detected
- C++ layer determines voicing; R layer handles NA naturally

### 3. Formant Object (`praat_formant`)

Represents formant frequencies and bandwidths over time.

**S3 Class**: `praat_formant`

**Structure**:
```r
formant <- data.frame(
  time = numeric,                # Time points (seconds)
  f1 = numeric,                  # First formant frequency (Hz), NA if undefined
  b1 = numeric,                  # First formant bandwidth (Hz)
  f2 = numeric,                  # Second formant frequency (Hz)
  b2 = numeric,                  # Second formant bandwidth (Hz)
  f3 = numeric,                  # Third formant frequency (Hz)
  b3 = numeric,                  # Third formant bandwidth (Hz)
  f4 = numeric,                  # Fourth formant (Hz)
  b4 = numeric,
  f5 = numeric,                  # Fifth formant (Hz)
  b5 = numeric
)

# Attributes
attr(formant, "xmin") <- numeric          # Start time
attr(formant, "xmax") <- numeric          # End time
attr(formant, "time_step") <- numeric     # Time between frames
attr(formant, "max_formant") <- numeric   # Maximum formant frequency setting (Hz)
attr(formant, "n_formants") <- integer    # Number of formants tracked (typically 5)
attr(formant, "class") <- c("praat_formant", "data.frame")
```

**Invariants**:
- Formant frequencies typically ordered: `f1 < f2 < f3 < f4 < f5` (when all defined)
- Bandwidth `>= 0` or `NA`
- Formants may be `NA` when tracking fails or during silence
- `n_formants` typically 5, but may vary

**NA Semantics**:
- Formant = `NA`: Tracking failed, silence, or implausible result
- Users typically focus on F1, F2, F3; F4 and F5 often less reliable

**Example**:
```r
formants <- extract_formants(sound, max_formant = 5500, n_formants = 5)
vowel_midpoint <- 0.5
f1_at_midpoint <- formants$f1[which.min(abs(formants$time - vowel_midpoint))]
```

### 4. Intensity Object (`praat_intensity`)

Represents sound intensity (loudness) over time in dB.

**S3 Class**: `praat_intensity`

**Structure**:
```r
intensity <- data.frame(
  time = numeric,                # Time points (seconds)
  intensity = numeric            # Intensity in dB (relative to auditory threshold)
)

# Attributes
attr(intensity, "xmin") <- numeric         # Start time
attr(intensity, "xmax") <- numeric         # End time
attr(intensity, "time_step") <- numeric    # Time between frames
attr(intensity, "min_pitch") <- numeric    # Minimum pitch used for computation (Hz)
attr(intensity, "class") <- c("praat_intensity", "data.frame")
```

**Invariants**:
- `intensity` typically in range 40-100 dB for speech
- `intensity = NA` during silence or when computation fails
- `time` monotonically increasing
- `min_pitch` used to set analysis window duration

**Example**:
```r
intensity <- compute_intensity(sound, min_pitch = 100)
mean_intensity <- mean(intensity$intensity, na.rm = TRUE)
```

### 5. Spectrogram Object (`praat_spectrogram`)

Represents time-frequency-amplitude analysis of sound.

**S3 Class**: `praat_spectrogram`

**Structure**:
```r
spectrogram <- list(
  time = numeric vector,         # Time points (seconds)
  frequency = numeric vector,    # Frequency bins (Hz)
  power = matrix                 # Power values [time x frequency]
                                 # power[i, j] = power at time[i], frequency[j]
)

# Attributes
attr(spectrogram, "xmin") <- numeric           # Start time
attr(spectrogram, "xmax") <- numeric           # End time
attr(spectrogram, "time_step") <- numeric      # Time resolution
attr(spectrogram, "frequency_step") <- numeric # Frequency resolution (Hz)
attr(spectrogram, "window_length") <- numeric  # Analysis window length (seconds)
attr(spectrogram, "max_frequency") <- numeric  # Maximum frequency (Hz)
attr(spectrogram, "class") <- c("praat_spectrogram", "list")
```

**Invariants**:
- `dim(power) == c(length(time), length(frequency))`
- `power >= 0` (power spectral density)
- `frequency[1] == 0`, `frequency[end] <= max_frequency`
- `time` and `frequency` both monotonically increasing

**Example**:
```r
spectrogram <- create_spectrogram(sound, window_length = 0.005, max_frequency = 5000)
# Access power at time index i, frequency index j
power_val <- spectrogram$power[i, j]
```

## Relationships Between Objects

```
Sound (input)
  ├─> Pitch (via extract_pitch)
  ├─> Formant (via extract_formants)
  ├─> Intensity (via compute_intensity)
  └─> Spectrogram (via create_spectrogram)
```

All analysis objects (Pitch, Formant, Intensity, Spectrogram) are derived from Sound objects. Sound is the primary input type.

## Validation Rules

Each object constructor performs validation:

1. **Sound**:
   - `sampling_rate > 0`
   - `n_samples > 0`
   - `length(values) == n_samples`

2. **Pitch**:
   - `0 < pitch_floor < pitch_ceiling`
   - `time_step > 0`
   - Frequency values non-negative or NA

3. **Formant**:
   - `max_formant > 0` (typically 5000-5500 for female, 5000 for male)
   - `n_formants >= 1` (typically 5)
   - `time_step > 0`

4. **Intensity**:
   - `min_pitch > 0`
   - `time_step > 0`

5. **Spectrogram**:
   - `window_length > 0`
   - `max_frequency > 0`
   - Matrix dimensions consistent with time/frequency vectors

## S3 Methods Required

For each object class, implement:

### Generic Methods

1. **print.praat_XXX**: User-friendly console output
   ```r
   print.praat_sound <- function(x, ...) {
     cat("Praat Sound object\n")
     cat(sprintf("  Duration: %.3f seconds\n", attr(x, "duration")))
     cat(sprintf("  Sampling rate: %.0f Hz\n", attr(x, "sampling_rate")))
     cat(sprintf("  Channels: %d\n", x$n_channels))
     invisible(x)
   }
   ```

2. **summary.praat_XXX**: Statistical summary
   ```r
   summary.praat_pitch <- function(object, ...) {
     list(
       mean_f0 = mean(object$frequency, na.rm = TRUE),
       min_f0 = min(object$frequency, na.rm = TRUE),
       max_f0 = max(object$frequency, na.rm = TRUE),
       n_voiced = sum(!is.na(object$frequency)),
       n_unvoiced = sum(is.na(object$frequency))
     )
   }
   ```

3. **plot.praat_XXX**: Visualization (optional but recommended)
   ```r
   plot.praat_pitch <- function(x, ...) {
     plot(x$time, x$frequency,
          type = "l",
          xlab = "Time (s)",
          ylab = "F0 (Hz)",
          main = "Pitch Contour",
          ...)
   }
   ```

4. **as.data.frame.praat_XXX**: Convert to data frame (for objects not already data frames)
   ```r
   as.data.frame.praat_sound <- function(x, ...) {
     data.frame(
       time = x$time,
       amplitude = x$values
     )
   }
   ```

## Internal Representation (C++ Side)

Each R object is backed by a Praat C object held in an Rcpp `XPtr`:

```cpp
// Internal structure (not exposed to R users directly)
class SoundWrapper {
  Rcpp::XPtr<autoSound> praat_sound_;
  // ... methods to extract data for R
};
```

**Data flow**:
1. User calls R function: `sound <- read_sound("file.wav")`
2. C++ wrapper creates Praat Sound object
3. C++ extracts data into R-friendly structures (vectors, data frames)
4. R S3 object created with data + attributes
5. XPtr stored as hidden attribute for further C++ operations (optional optimization)

**Alternative**: Pure R representation (no XPtr persistence)
- Simpler: Extract all data to R immediately
- Good for typical use cases
- May recreate Praat objects for dependent analyses (pitch from sound)

**Recommendation**: Start with pure R representation for simplicity. Add XPtr persistence only if performance profiling shows it's needed.

## Migration Notes

If object structure changes in future versions:

1. Update `data-model.md` documentation
2. Increment package version (MINOR for additions, MAJOR for breaking changes)
3. Provide conversion utilities if needed
4. Document migration in NEWS.md

## Summary Table

| Class | Base Type | Key Fields | Typical Size |
|-------|-----------|------------|--------------|
| `praat_sound` | list | values, time | 1-10 MB (1 min audio) |
| `praat_pitch` | data.frame | time, frequency, strength | 10-100 KB |
| `praat_formant` | data.frame | time, f1-f5, b1-b5 | 50-500 KB |
| `praat_intensity` | data.frame | time, intensity | 10-100 KB |
| `praat_spectrogram` | list | time, frequency, power (matrix) | 1-10 MB |

All objects use standard R types, ensuring compatibility with R ecosystem tools (dplyr, ggplot2, etc.).
