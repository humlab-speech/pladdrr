# pladdrr 0.9.10 (2025-11-25)

## Major Changes

### S3 to R6 Migration Complete

All S3 functional interfaces have been **deprecated** in favor of the R6 object-oriented interface. S3 functions still work but emit deprecation warnings.

**Deprecated functions** (will be removed in v1.0.0):

#### Sound
- `create_sound()` → `Sound$from_values()`
- `read_sound()` → `Sound$new()`
- `get_duration()` → `sound$get_duration()`
- `get_sampling_rate()` → `sound$get_sampling_frequency()`
- `get_n_channels()` → `sound$get_number_of_channels()`
- `get_n_samples()` → `sound$get_number_of_samples()`

#### Pitch
- `extract_pitch()` → `sound$to_pitch()`
- `get_pitch_at_time()` → `pitch$get_value_at_time()`
- `get_mean_pitch()` → `pitch$get_mean()`
- `get_min_pitch()` → `pitch$get_minimum()`
- `get_max_pitch()` → `pitch$get_maximum()`

#### Intensity
- `extract_intensity()` → `sound$to_intensity()`
- `get_intensity_at_time()` → `intensity$get_value_at_time()`
- `get_mean_intensity()` → `intensity$get_mean()`
- `get_min_intensity()` → `intensity$get_minimum()`
- `get_max_intensity()` → `intensity$get_maximum()`
- `get_sd_intensity()` → `intensity$get_standard_deviation()`

**Migration example**:
```r
# Old (deprecated)
sound <- read_sound("audio.wav")
pitch <- extract_pitch(sound)
mean_f0 <- get_mean_pitch(pitch)

# New (recommended)
sound <- Sound$new("audio.wav")
pitch <- sound$to_pitch()
mean_f0 <- pitch$get_mean()
```

**Benefits of R6 interface**:
- 4.7x faster method calls
- 1,668x smaller memory footprint (0.4 KB vs 707 KB per object)
- 84 additional methods (104 vs 20)
- Method chaining support: `sound$to_pitch()$get_mean()`
- Better IDE autocomplete

### Audio I/O Unified to av Package

All audio file loading now exclusively uses the `av` package (humlab-speech fork):
- Removed `tuneR` dependency
- Support for 30+ audio formats via FFmpeg (MP3, FLAC, OGG, M4A, AAC, etc.)
- `read_sound()` now supports all av-compatible formats (not just WAV)
- Consistent with R6 `Sound$new()` implementation

## Bug Fixes

- Fixed audio loading to use av package exclusively (#issue)
- Removed Praat C file I/O code from build

## Documentation

- Added S3 to R6 migration guide
- Added performance comparison analysis
- Updated all examples to use R6 interface

---

# pladdrr 0.9.9 (2025-11-22)

## Major Features

* **SIMD Acceleration**: 2-4x performance improvements on modern CPUs
  - Automatic CPU detection (ARM NEON, AVX2, SSE2)
  - Optimized matrix operations, audio processing, and DSP functions
  
* **Complete Praat Object Coverage**: 17+ object types with 300+ methods
  - Sound, Pitch, Formant, Intensity, Harmonicity
  - Spectrogram, Spectrum, LTAS
  - TextGrid with full tier management
  - Manipulation objects (PitchTier, DurationTier, IntensityTier)

* **Voice Quality Analysis**: AVQI and DSI implementations
  - Acoustic Voice Quality Index (AVQI)
  - Dysphonia Severity Index (DSI)
  - PowerCepstrum and PowerCepstrogram support

## Performance

* Matrix operations: 2-3x faster (sum, mean, min, max)
* Audio processing: 2-3x faster (RMS, energy, power)
* DSP operations: 3-6x faster (autocorrelation, windowing)

## Documentation

* 5 comprehensive vignettes
* 9 complete example workflows
* Full API documentation with Praat equivalents

## Dependencies

* Requires C++17 compiler
* Uses humlab-speech/av fork for audio I/O
* Added SIMD support via RcppXsimd

## Bug Fixes

* Fixed TextGrid tier management
* Improved memory management with external pointers
* Enhanced error handling across all objects

---

# pladdrr 0.5.0 (Initial Development)

* Initial implementation of core Praat objects
* R6-based object-oriented architecture
* Basic audio I/O and analysis functions
