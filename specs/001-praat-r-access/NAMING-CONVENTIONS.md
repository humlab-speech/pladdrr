# Naming Conventions: Praat to R6 Method Mapping

**Date**: 2025-01-08  
**Purpose**: Define consistent naming scheme for R6 methods that mirrors Praat's API  
**Inspiration**: Parselmouth (Python) and Praat scripting conventions

## Design Principles

1. **Follow Praat's Intent**: Maintain semantic meaning of Praat commands
2. **Use R Conventions**: Apply `snake_case` (R standard) instead of Praat's "Sentence case"
3. **Be Predictable**: Consistent verb patterns for similar operations
4. **Easy Transcoding**: Praat scripts should translate directly to R code
5. **Mirror Parselmouth**: Where possible, align with Parselmouth's proven naming

## Core Naming Patterns

### Pattern 1: Query Methods - `get_[property]`

**Praat Pattern**: `Get [property]`  
**R6 Pattern**: `get_[property]()`

| Praat Command | R6 Method | Parselmouth | Notes |
|---------------|-----------|-------------|-------|
| `Get sampling frequency` | `get_sampling_frequency()` | `sound.sampling_frequency` (attr) | Property-like query |
| `Get duration` | `get_duration()` | `sound.duration` (attr) | Property-like query |
| `Get number of channels` | `get_number_of_channels()` | `sound.n_channels` (attr) | Property-like query |
| `Get number of samples` | `get_number_of_samples()` | - | Property-like query |
| `Get minimum` | `get_minimum(...)` | `pitch.get_minimum()` | Computed query |
| `Get maximum` | `get_maximum(...)` | `pitch.get_maximum()` | Computed query |
| `Get mean` | `get_mean(...)` | `pitch.get_mean()` | Computed query |
| `Get median` | `get_median(...)` | - | Computed query |
| `Get quantile` | `get_quantile(q, ...)` | - | Computed query |
| `Get value at time` | `get_value_at_time(time, ...)` | `pitch.get_value_at_time(time)` | Time-based query |
| `Get time from frame` | `get_time_from_frame(frame)` | - | Frame-based query |
| `Get frame from time` | `get_frame_from_time(time)` | - | Frame-based query |

**R6 Implementation Note**: While Parselmouth uses attributes for simple properties (e.g., `sound.duration`), R6 doesn't support dynamic computed properties as cleanly. We use methods consistently: `sound$get_duration()`.

### Pattern 2: Transformation Methods - `to_[type]`

**Praat Pattern**: `To [New Type]...`  
**R6 Pattern**: `to_[type](...)`

| Praat Command | R6 Method | Parselmouth | Returns |
|---------------|-----------|-------------|---------|
| `To Pitch...` | `to_pitch(...)` | `sound.to_pitch()` | Pitch object |
| `To Pitch (ac)...` | `to_pitch_ac(...)` | `sound.to_pitch_ac()` | Pitch object (autocorrelation) |
| `To Pitch (cc)...` | `to_pitch_cc(...)` | `sound.to_pitch_cc()` | Pitch object (cross-correlation) |
| `To Formant (burg)...` | `to_formant_burg(...)` | `sound.to_formant_burg()` | Formant object |
| `To Formant (sl)...` | `to_formant_sl(...)` | - | Formant object (split Levinson) |
| `To Intensity...` | `to_intensity(...)` | `sound.to_intensity()` | Intensity object |
| `To Spectrogram...` | `to_spectrogram(...)` | `sound.to_spectrogram()` | Spectrogram object |
| `To Spectrum...` | `to_spectrum(...)` | `sound.to_spectrum()` | Spectrum object |
| `To TextGrid...` | `to_textgrid(...)` | `sound.to_textgrid()` | TextGrid object |

**Design Decision**: Use `to_` prefix (matches Parselmouth and Praat's "To" commands) rather than `extract_` or `compute_`.

### Pattern 3: Extraction Methods - `extract_[subset]`

**Praat Pattern**: `Extract [subset]`  
**R6 Pattern**: `extract_[subset](...)`

| Praat Command | R6 Method | Parselmouth | Returns |
|---------------|-----------|-------------|---------|
| `Extract part...` | `extract_part(from_time, to_time, ...)` | - | Sound object (subset) |
| `Extract channel...` | `extract_channel(channel)` | - | Sound object (mono) |

**Note**: "Extract" is reserved for creating subsets of the same object type, not transformations to different types.

### Pattern 4: Modification Methods - `[action]` or `set_[property]`

**Praat Pattern**: Various action verbs  
**R6 Pattern**: `[action](...)`

| Praat Command | R6 Method | Parselmouth | Effect |
|---------------|-----------|-------------|--------|
| `Scale intensity...` | `scale_intensity(new_level)` | - | Modifies Sound in-place |
| `Multiply...` | `multiply(factor)` | - | Modifies Sound in-place |
| `Add...` | `add(value)` | - | Modifies Sound in-place |
| `Resample...` | `resample(new_frequency, precision)` | - | Modifies Sound in-place |
| `Filter (pass Hann band)...` | `filter_pass_hann_band(...)` | - | Modifies Sound in-place |

**Design Decision**: In-place modifications use simple verb names. For immutable operations, use `to_[type]` that returns a new object.

### Pattern 5: I/O Methods - Standard R Convention

| Praat Command | R6 Method | Parselmouth | Effect |
|---------------|-----------|-------------|--------|
| `Read from file...` | `Sound$new(path)` (constructor) | `parselmouth.Sound(path)` | Creates object from file |
| `Write to WAV file...` | `save(path, format = "WAV")` | `sound.save(path, format)` | Writes to file |
| - | `as_data_frame()` | - | Export to R data.frame |
| - | `as_matrix()` | - | Export to R matrix |

### Pattern 6: Static/Factory Methods - `[Type]$[method]`

**R6 Pattern**: Class methods accessed via `$` on the class itself

| Praat Command | R6 Method | Parselmouth | Returns |
|---------------|-----------|-------------|---------|
| `Create Sound from formula...` | `Sound$from_formula(...)` | - | Sound object |
| `Generate Tone...` | `Sound$create_tone(...)` | - | Sound object |
| - | `Sound$from_values(values, sr)` | - | Sound object |

## Complete Examples by Object Type

### Sound Object

```r
# Constructor / I/O
sound <- Sound$new("audio.wav")                      # Read from file
sound <- Sound$from_values(values, sampling_rate)    # Create from data

# Query methods (get_*)
duration <- sound$get_duration()                     # seconds
sr <- sound$get_sampling_frequency()                 # Hz
n_ch <- sound$get_number_of_channels()               # integer
n_samp <- sound$get_number_of_samples()              # integer
value <- sound$get_value_at_time(time = 0.5, channel = 1)
time <- sound$get_time_from_sample(sample = 1000)

# Transformation methods (to_*)
pitch <- sound$to_pitch(time_step = 0, pitch_floor = 75, pitch_ceiling = 600)
formants <- sound$to_formant_burg(time_step = 0, max_formant = 5500)
intensity <- sound$to_intensity(min_pitch = 100, time_step = 0)
spectrogram <- sound$to_spectrogram(window_length = 0.005)

# Extraction methods (extract_*)
part <- sound$extract_part(from_time = 1.0, to_time = 2.0)
channel <- sound$extract_channel(channel = 1)

# Modification methods
sound$scale_intensity(new_average_intensity = 70)
sound$resample(new_frequency = 16000, precision = 50)

# Export methods
df <- sound$as_data_frame()
sound$save("output.wav", format = "WAV")
```

### Pitch Object

```r
# Usually created from Sound
pitch <- sound$to_pitch()

# Query methods - simple properties
n_frames <- pitch$get_number_of_frames()
time_step <- pitch$get_time_step()

# Query methods - computed values
f0 <- pitch$get_value_at_time(time = 0.5, unit = "Hertz")
mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "Hertz")
min_f0 <- pitch$get_minimum(from_time = 0, to_time = 0, unit = "Hertz")
max_f0 <- pitch$get_maximum(from_time = 0, to_time = 0, unit = "Hertz")
median_f0 <- pitch$get_median(from_time = 0, to_time = 0, unit = "Hertz")
q75_f0 <- pitch$get_quantile(quantile = 0.75, unit = "Hertz")

# Export methods
df <- pitch$as_data_frame()  # data.frame with time, frequency, strength
pitch$save("pitch.Pitch")
```

### Formant Object

```r
# Usually created from Sound
formants <- sound$to_formant_burg(max_formant = 5500, n_formants = 5)

# Query methods
n_formants <- formants$get_number_of_formants()
n_frames <- formants$get_number_of_frames()

# Get specific formant value
f1 <- formants$get_value_at_time(time = 0.5, formant_number = 1)
f2 <- formants$get_value_at_time(time = 0.5, formant_number = 2)

# Get formant statistics
mean_f1 <- formants$get_mean(formant_number = 1, from_time = 0, to_time = 0)
min_f1 <- formants$get_minimum(formant_number = 1, from_time = 0, to_time = 0)

# Get bandwidth
b1 <- formants$get_bandwidth_at_time(time = 0.5, formant_number = 1)

# Export methods
df <- formants$as_data_frame()  # data.frame with time, f1-f5, b1-b5
```

### Intensity Object

```r
# Usually created from Sound
intensity <- sound$to_intensity(min_pitch = 100)

# Query methods
value <- intensity$get_value_at_time(time = 0.5)
mean <- intensity$get_mean(from_time = 0, to_time = 0)
min <- intensity$get_minimum(from_time = 0, to_time = 0)
max <- intensity$get_maximum(from_time = 0, to_time = 0)

# Export methods
df <- intensity$as_data_frame()  # data.frame with time, intensity
```

## Praat Script to R6 Translation Guide

### Example 1: Basic Pitch Analysis

**Praat Script:**
```praat
sound = Read from file: "audio.wav"
pitch = To Pitch: 0, 75, 600
mean_pitch = Get mean: 0, 0, "Hertz"
writeInfoLine: "Mean pitch: ", mean_pitch
```

**R6 Translation:**
```r
sound <- Sound$new("audio.wav")
pitch <- sound$to_pitch(time_step = 0, pitch_floor = 75, pitch_ceiling = 600)
mean_pitch <- pitch$get_mean(from_time = 0, to_time = 0, unit = "Hertz")
cat("Mean pitch:", mean_pitch, "\n")
```

### Example 2: Formant Analysis

**Praat Script:**
```praat
sound = Read from file: "vowel.wav"
formant = To Formant (burg): 0, 5, 5500, 0.025, 50
f1 = Get value at time: 1, 0.5, "Hertz", "Linear"
f2 = Get value at time: 2, 0.5, "Hertz", "Linear"
```

**R6 Translation:**
```r
sound <- Sound$new("vowel.wav")
formant <- sound$to_formant_burg(time_step = 0, n_formants = 5, 
                                  max_formant = 5500, window_length = 0.025)
f1 <- formant$get_value_at_time(time = 0.5, formant_number = 1)
f2 <- formant$get_value_at_time(time = 0.5, formant_number = 2)
```

### Example 3: Sound Manipulation

**Praat Script:**
```praat
sound = Read from file: "audio.wav"
Scale intensity: 70
Resample: 16000, 50
Write to WAV file: "output.wav"
```

**R6 Translation:**
```r
sound <- Sound$new("audio.wav")
sound$scale_intensity(new_average_intensity = 70)
sound$resample(new_frequency = 16000, precision = 50)
sound$save("output.wav", format = "WAV")
```

## Parameter Naming Conventions

### Consistency Across Methods

Use consistent parameter names across all methods:

| Parameter Type | R6 Name | Praat Equivalent | Type |
|----------------|---------|------------------|------|
| Time point | `time` | time (seconds) | numeric |
| Time range start | `from_time` | "from" in GUI | numeric |
| Time range end | `to_time` | "to" in GUI | numeric |
| Time step/resolution | `time_step` | "Time step (s)" | numeric (0 = auto) |
| Pitch floor | `pitch_floor` | "Pitch floor (Hz)" | numeric |
| Pitch ceiling | `pitch_ceiling` | "Pitch ceiling (Hz)" | numeric |
| Formant number | `formant_number` | formant index | integer (1-5) |
| Maximum formant | `max_formant` | "Maximum formant (Hz)" | numeric |
| Number of formants | `n_formants` | "Number of formants" | integer |
| Channel number | `channel` | channel index | integer (1-based) |
| Sampling frequency | `sampling_rate` or `sr` | "Sampling frequency (Hz)" | numeric |
| Window length | `window_length` | "Window length (s)" | numeric |

### Default Values

Match Praat's defaults where possible:

```r
# Pitch analysis defaults (from Praat)
to_pitch = function(time_step = 0.0,           # 0 = auto (0.75 / pitch_floor)
                    pitch_floor = 75.0,        # Hz
                    pitch_ceiling = 600.0)     # Hz

# Formant analysis defaults (from Praat) 
to_formant_burg = function(time_step = 0.0,    # 0 = auto
                           max_formant = 5500.0, # Hz (for female voice)
                           n_formants = 5,      # number to track
                           window_length = 0.025, # seconds
                           pre_emphasis = 50.0)  # Hz
```

## Case Study: Full Transcoding Example

### Praat Script (Complex Analysis)

```praat
# Read sound
sound = Read from file: "speech.wav"

# Get basic info
duration = Get duration
sampling_rate = Get sampling frequency

# Extract middle portion
selectObject: sound
part = Extract part: 1.0, 2.0, "rectangular", 1, "no"

# Pitch analysis
selectObject: part
pitch = To Pitch: 0, 75, 600
mean_f0 = Get mean: 0, 0, "Hertz"

# Formant analysis
selectObject: part
formant = To Formant (burg): 0, 5, 5500, 0.025, 50
f1_mid = Get value at time: 1, 1.5, "Hertz", "Linear"
f2_mid = Get value at time: 2, 1.5, "Hertz", "Linear"

# Output results
writeInfoLine: "Duration: ", duration
appendInfoLine: "Mean F0: ", mean_f0
appendInfoLine: "F1 at midpoint: ", f1_mid
appendInfoLine: "F2 at midpoint: ", f2_mid
```

### R6 Translation

```r
# Read sound
sound <- Sound$new("speech.wav")

# Get basic info (no object selection needed!)
duration <- sound$get_duration()
sampling_rate <- sound$get_sampling_frequency()

# Extract middle portion (returns new object)
part <- sound$extract_part(from_time = 1.0, to_time = 2.0)

# Pitch analysis (no selection needed - method on object)
pitch <- part$to_pitch(time_step = 0, pitch_floor = 75, pitch_ceiling = 600)
mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "Hertz")

# Formant analysis
formant <- part$to_formant_burg(time_step = 0, n_formants = 5, 
                                 max_formant = 5500, window_length = 0.025,
                                 pre_emphasis = 50)
f1_mid <- formant$get_value_at_time(time = 1.5, formant_number = 1)
f2_mid <- formant$get_value_at_time(time = 1.5, formant_number = 2)

# Output results
cat("Duration:", duration, "\n")
cat("Mean F0:", mean_f0, "\n")
cat("F1 at midpoint:", f1_mid, "\n")
cat("F2 at midpoint:", f2_mid, "\n")
```

**Key Differences from Praat:**
1. **No object selection**: Methods called directly on objects
2. **Object-oriented**: `object$method()` instead of `selectObject: obj; Method`
3. **Return values**: Methods return new objects or values directly
4. **Consistent parameters**: All use `snake_case` with consistent names

## Implementation Checklist

When implementing a new Praat method:

- [ ] Identify Praat command pattern (Get, To, Extract, etc.)
- [ ] Apply appropriate R6 naming pattern (get_*, to_*, extract_*)
- [ ] Use `snake_case` for method and parameter names
- [ ] Match Praat's default parameter values
- [ ] Use consistent parameter names (time, from_time, to_time, etc.)
- [ ] Document with `@param` tags using Praat terminology
- [ ] Add examples showing Praat → R6 translation
- [ ] Test that transcoded Praat scripts produce identical results

## Summary

This naming convention ensures:
1. ✅ **Predictable**: Consistent verb patterns (get_, to_, extract_)
2. ✅ **Familiar**: Mirrors Praat's semantic structure
3. ✅ **Easy Transcoding**: Direct translation from Praat scripts
4. ✅ **R Idiomatic**: Uses snake_case and R6 conventions
5. ✅ **Parselmouth-aligned**: Similar to proven Python implementation

Users familiar with Praat can easily translate their scripts to R with minimal cognitive overhead.
