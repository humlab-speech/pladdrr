# R Function Signatures (API Contract)

**Date**: 2025-11-02
**Context**: Public R API for speaker package

This document defines the complete public R API - all exported functions that users can call. Each function maps to functional requirements from spec.md.

## Sound Object Functions

### create_sound

**Purpose**: Create sound object from numeric vector

**Signature**:
```r
create_sound(values, sampling_rate = 44100, start_time = 0.0)
```

**Parameters**:
- `values`: Numeric vector of sample values (amplitude)
- `sampling_rate`: Sampling frequency in Hz (default: 44100)
- `start_time`: Start time in seconds (default: 0.0)

**Returns**: S3 object of class `praat_sound`

**FR**: FR-001

---

### read_sound

**Purpose**: Load sound from audio file

**Signature**:
```r
read_sound(file_path, channel = 1)
```

**Parameters**:
- `file_path`: Character string, path to WAV file
- `channel`: Integer, channel to extract for multi-channel files (default: 1 = left)

**Returns**: S3 object of class `praat_sound`

**Errors**:
- File not found
- Unsupported format
- Corrupted file

**FR**: FR-001

---

### get_duration

**Purpose**: Get sound duration in seconds

**Signature**:
```r
get_duration(sound)
```

**Parameters**:
- `sound`: praat_sound object

**Returns**: Numeric, duration in seconds

**FR**: FR-002

---

### get_sampling_rate

**Purpose**: Get sampling frequency

**Signature**:
```r
get_sampling_rate(sound)
```

**Parameters**:
- `sound`: praat_sound object

**Returns**: Numeric, sampling rate in Hz

**FR**: FR-002

---

### get_n_channels

**Purpose**: Get number of channels

**Signature**:
```r
get_n_channels(sound)
```

**Parameters**:
- `sound`: praat_sound object

**Returns**: Integer, number of channels

**FR**: FR-002

---

### get_n_samples

**Purpose**: Get total number of samples

**Signature**:
```r
get_n_samples(sound)
```

**Parameters**:
- `sound`: praat_sound object

**Returns**: Integer, number of samples

**FR**: FR-002

---

## Test Signal Generation

### generate_sine_wave

**Purpose**: Generate sine wave test signal

**Signature**:
```r
generate_sine_wave(frequency, duration, sampling_rate = 44100, amplitude = 0.99)
```

**Parameters**:
- `frequency`: Numeric, frequency in Hz
- `duration`: Numeric, duration in seconds
- `sampling_rate`: Numeric, sampling rate in Hz (default: 44100)
- `amplitude`: Numeric, amplitude [0, 1] (default: 0.99)

**Returns**: S3 object of class `praat_sound`

**FR**: FR-003

---

### generate_noise

**Purpose**: Generate white noise test signal

**Signature**:
```r
generate_noise(duration, sampling_rate = 44100, amplitude = 0.5, seed = NULL)
```

**Parameters**:
- `duration`: Numeric, duration in seconds
- `sampling_rate`: Numeric, sampling rate in Hz (default: 44100)
- `amplitude`: Numeric, amplitude scaling [0, 1] (default: 0.5)
- `seed`: Integer or NULL, random seed for reproducibility

**Returns**: S3 object of class `praat_sound`

**FR**: FR-003

---

## Sound Statistics

### sound_mean

**Purpose**: Compute mean amplitude

**Signature**:
```r
sound_mean(sound)
```

**Parameters**:
- `sound`: praat_sound object

**Returns**: Numeric, mean amplitude

**FR**: FR-004

---

### sound_min

**Purpose**: Compute minimum amplitude

**Signature**:
```r
sound_min(sound)
```

**Parameters**:
- `sound`: praat_sound object

**Returns**: Numeric, minimum amplitude

**FR**: FR-004

---

### sound_max

**Purpose**: Compute maximum amplitude

**Signature**:
```r
sound_max(sound)
```

**Parameters**:
- `sound`: praat_sound object

**Returns**: Numeric, maximum amplitude

**FR**: FR-004

---

### sound_rms

**Purpose**: Compute root mean square amplitude

**Signature**:
```r
sound_rms(sound)
```

**Parameters**:
- `sound`: praat_sound object

**Returns**: Numeric, RMS amplitude

**FR**: FR-004

---

### sound_statistics

**Purpose**: Compute all basic statistics at once

**Signature**:
```r
sound_statistics(sound)
```

**Parameters**:
- `sound`: praat_sound object

**Returns**: Named list with elements: `mean`, `min`, `max`, `rms`, `length`

**FR**: FR-004

---

## Pitch Analysis

### extract_pitch

**Purpose**: Extract pitch (F0) contour from sound

**Signature**:
```r
extract_pitch(sound,
              pitch_floor = 75,
              pitch_ceiling = 600,
              time_step = 0.0,
              max_candidates = 15,
              very_accurate = FALSE)
```

**Parameters**:
- `sound`: praat_sound object
- `pitch_floor`: Numeric, minimum F0 to search (Hz, default: 75)
- `pitch_ceiling`: Numeric, maximum F0 to search (Hz, default: 600)
- `time_step`: Numeric, time between frames in seconds (0 = auto, default: 0.0)
- `max_candidates`: Integer, maximum pitch candidates (default: 15)
- `very_accurate`: Logical, use slow but accurate algorithm (default: FALSE)

**Returns**: S3 object of class `praat_pitch` (data frame)

**Warnings**:
- Few voiced frames detected
- Pitch tracking may be unreliable

**FR**: FR-005, FR-017

---

### get_pitch_at_time

**Purpose**: Get F0 value at specific time point

**Signature**:
```r
get_pitch_at_time(pitch, time, unit = "Hertz")
```

**Parameters**:
- `pitch`: praat_pitch object
- `time`: Numeric, time point in seconds
- `unit`: Character, "Hertz" or "semitones" (default: "Hertz")

**Returns**: Numeric or NA (if unvoiced)

**FR**: FR-006

---

### get_mean_pitch

**Purpose**: Get mean F0 across entire pitch contour

**Signature**:
```r
get_mean_pitch(pitch, unit = "Hertz")
```

**Parameters**:
- `pitch`: praat_pitch object
- `unit`: Character, "Hertz" or "semitones" (default: "Hertz")

**Returns**: Numeric, mean F0 (NA values excluded)

**FR**: FR-006

---

### get_min_pitch

**Purpose**: Get minimum F0

**Signature**:
```r
get_min_pitch(pitch, unit = "Hertz")
```

**Parameters**:
- `pitch`: praat_pitch object
- `unit`: Character, "Hertz" or "semitones" (default: "Hertz")

**Returns**: Numeric, minimum F0

**FR**: FR-006

---

### get_max_pitch

**Purpose**: Get maximum F0

**Signature**:
```r
get_max_pitch(pitch, unit = "Hertz")
```

**Parameters**:
- `pitch`: praat_pitch object
- `unit`: Character, "Hertz" or "semitones" (default: "Hertz")

**Returns**: Numeric, maximum F0

**FR**: FR-006

---

## Formant Analysis

### extract_formants

**Purpose**: Extract formant frequencies and bandwidths from sound

**Signature**:
```r
extract_formants(sound,
                 max_formant = 5500,
                 n_formants = 5,
                 window_length = 0.025,
                 pre_emphasis_from = 50.0,
                 time_step = 0.0)
```

**Parameters**:
- `sound`: praat_sound object
- `max_formant`: Numeric, maximum formant frequency in Hz (default: 5500 for female)
- `n_formants`: Integer, number of formants to track (default: 5)
- `window_length`: Numeric, analysis window length in seconds (default: 0.025)
- `pre_emphasis_from`: Numeric, pre-emphasis frequency in Hz (default: 50.0)
- `time_step`: Numeric, time between frames in seconds (0 = auto, default: 0.0)

**Returns**: S3 object of class `praat_formant` (data frame)

**Warnings**:
- Formant tracking unstable
- Implausible formant values detected

**FR**: FR-007, FR-017

---

### get_formant_at_time

**Purpose**: Get formant value at specific time point

**Signature**:
```r
get_formant_at_time(formant, formant_number, time, unit = "Hertz")
```

**Parameters**:
- `formant`: praat_formant object
- `formant_number`: Integer, which formant (1-5 for F1-F5)
- `time`: Numeric, time point in seconds
- `unit`: Character, "Hertz" or "Bark" (default: "Hertz")

**Returns**: Numeric or NA (if undefined)

**FR**: FR-008

---

### get_formant_statistics

**Purpose**: Get formant statistics over time range

**Signature**:
```r
get_formant_statistics(formant, formant_number, time_min = NULL, time_max = NULL)
```

**Parameters**:
- `formant`: praat_formant object
- `formant_number`: Integer, which formant (1-5)
- `time_min`: Numeric or NULL, start time (NULL = beginning)
- `time_max`: Numeric or NULL, end time (NULL = end)

**Returns**: Named list with `mean`, `min`, `max`, `sd` of formant values

**FR**: FR-008

---

## Intensity Analysis

### compute_intensity

**Purpose**: Compute intensity (loudness) contour

**Signature**:
```r
compute_intensity(sound,
                  min_pitch = 100,
                  time_step = 0.0,
                  subtract_mean = TRUE)
```

**Parameters**:
- `sound`: praat_sound object
- `min_pitch`: Numeric, minimum pitch for window size (Hz, default: 100)
- `time_step`: Numeric, time between frames in seconds (0 = auto, default: 0.0)
- `subtract_mean`: Logical, subtract mean intensity (default: TRUE)

**Returns**: S3 object of class `praat_intensity` (data frame)

**FR**: FR-009

---

### get_intensity_at_time

**Purpose**: Get intensity value at specific time point

**Signature**:
```r
get_intensity_at_time(intensity, time)
```

**Parameters**:
- `intensity`: praat_intensity object
- `time`: Numeric, time point in seconds

**Returns**: Numeric, intensity in dB

**FR**: FR-009

---

## Spectrogram Analysis

### create_spectrogram

**Purpose**: Create spectrogram from sound

**Signature**:
```r
create_spectrogram(sound,
                   window_length = 0.005,
                   max_frequency = 5000,
                   time_step = 0.002,
                   frequency_step = 20,
                   window_shape = "Gaussian")
```

**Parameters**:
- `sound`: praat_sound object
- `window_length`: Numeric, analysis window length in seconds (default: 0.005)
- `max_frequency`: Numeric, maximum frequency in Hz (default: 5000)
- `time_step`: Numeric, time resolution in seconds (default: 0.002)
- `frequency_step`: Numeric, frequency resolution in Hz (default: 20)
- `window_shape`: Character, "Gaussian" or "Hamming" (default: "Gaussian")

**Returns**: S3 object of class `praat_spectrogram`

**FR**: FR-010

---

### get_power_at

**Purpose**: Get spectral power at specific time and frequency

**Signature**:
```r
get_power_at(spectrogram, time, frequency)
```

**Parameters**:
- `spectrogram`: praat_spectrogram object
- `time`: Numeric, time point in seconds
- `frequency`: Numeric, frequency in Hz

**Returns**: Numeric, power spectral density

**FR**: FR-010

---

## Validation and Error Handling

All functions perform parameter validation and throw informative errors (FR-011, FR-015):

**Example error messages**:
```r
# Invalid sampling rate
create_sound(rnorm(100), sampling_rate = -1)
# Error: sampling_rate must be positive (got: -1)

# File not found
read_sound("nonexistent.wav")
# Error: File not found: nonexistent.wav

# Invalid pitch range
extract_pitch(sound, pitch_floor = 200, pitch_ceiling = 100)
# Error: pitch_floor (200 Hz) must be less than pitch_ceiling (100 Hz)

# Out of range time
get_pitch_at_time(pitch, time = 999)
# Error: time (999 s) is outside pitch object range [0.0, 5.0] s
```

## S3 Methods (Generic Functions)

Each object type implements standard S3 methods:

### print methods

```r
print.praat_sound(x, ...)
print.praat_pitch(x, ...)
print.praat_formant(x, ...)
print.praat_intensity(x, ...)
print.praat_spectrogram(x, ...)
```

**FR**: FR-013

### summary methods

```r
summary.praat_sound(object, ...)
summary.praat_pitch(object, ...)
summary.praat_formant(object, ...)
# etc.
```

### plot methods (optional, may be deferred)

```r
plot.praat_pitch(x, ...)      # Time vs F0 line plot
plot.praat_formant(x, ...)    # Formant tracks over time
plot.praat_spectrogram(x, ...) # Heat map visualization
```

## Function Organization by File

**R/sound.R**:
- `create_sound()`, `read_sound()`
- `get_duration()`, `get_sampling_rate()`, `get_n_channels()`, `get_n_samples()`

**R/sound-generate.R**:
- `generate_sine_wave()`, `generate_noise()`

**R/sound-stats.R**:
- `sound_mean()`, `sound_min()`, `sound_max()`, `sound_rms()`, `sound_statistics()`

**R/pitch.R**:
- `extract_pitch()`
- `get_pitch_at_time()`, `get_mean_pitch()`, `get_min_pitch()`, `get_max_pitch()`

**R/formant.R**:
- `extract_formants()`
- `get_formant_at_time()`, `get_formant_statistics()`

**R/intensity.R**:
- `compute_intensity()`, `get_intensity_at_time()`

**R/spectrogram.R**:
- `create_spectrogram()`, `get_power_at()`

**R/s3-methods.R**:
- `print.praat_*()`, `summary.praat_*()`, `plot.praat_*()`, `as.data.frame.praat_*()`

**R/utils.R**:
- Internal validation helpers (not exported)
- Parameter checking utilities

## Total API Surface

**Exported functions**: ~30
**S3 classes**: 5
**S3 methods**: ~15 (print, summary, etc.)

This API provides comprehensive phonetic analysis capabilities while maintaining simplicity and R idioms.
