# Object-Oriented Paradigm Shift Amendment

**Date**: 2025-11-11  
**Status**: ACTIVE AMENDMENT  
**Priority**: CRITICAL - Fundamental Architecture Change

## Executive Summary

This amendment transforms the speaker package from a **procedural, function-based approach** to a **comprehensive object-oriented system** that properly mirrors Praat's native C++ architecture, similar to how Python's Parselmouth implements it.

### The Core Problem

The original specifications and initial implementation focused on **isolated procedures**:

```r
# WRONG: Procedural approach (original spec)
pitch_data <- praat_extract_pitch(audio_file, min_pitch = 75)
formant_data <- praat_extract_formant(audio_file, max_formant = 5500)
```

**Why this is wrong**:
1. ❌ **Ignores Praat's OOP architecture** - Praat has ~30+ object types with inheritance
2. ❌ **Forces repeated data copying** - Each function call reloads/reprocesses audio
3. ❌ **No object persistence** - Can't chain operations or build workflows
4. ❌ **Missing critical functionality** - TextGrid, Manipulation, object interactions
5. ❌ **Doesn't match Praat's actual design** - Praat is fundamentally object-oriented

### The Correct Approach

**Object-oriented design matching Praat's architecture**:

```r
# CORRECT: Object-oriented approach (mirrors Praat)
sound <- Sound$new("audio.wav")
pitch <- sound$to_pitch(pitch_floor = 75, pitch_ceiling = 600)
formant <- sound$to_formant_burg(max_formant_hz = 5500)

# Method chaining and object interaction
mean_f0 <- pitch$get_mean(unit = "hertz")
f1_values <- formant$get_values_at_time(1, seq(0, sound$get_duration(), 0.01))

# Critical missing features now possible
tg <- TextGrid$new("annotation.TextGrid")
intervals <- tg$get_intervals("words")

manip <- sound$to_manipulation()
pitch_tier <- manip$extract_pitch_tier()
pitch_tier$multiply_frequencies(1.2)  # Raise pitch 20%
modified <- manip$get_resynthesis_overlap_add()
```

## Praat's Object-Oriented Architecture

### Object Hierarchy (from Praat C++ source)

```
Thing (base class for all Praat objects)
├── Data
│   ├── Function (time-based objects)
│   │   ├── Sampled
│   │   │   ├── Sound          ⭐ Audio waveform
│   │   │   ├── Pitch          ⭐ F0 contour
│   │   │   ├── Formant        ⭐ Formant trajectories
│   │   │   ├── Intensity      ⭐ Loudness contour
│   │   │   ├── Spectrogram    Spectral slice over time
│   │   │   ├── Harmonicity    HNR contour
│   │   │   ├── LPC            Linear predictive coefficients
│   │   │   └── Matrix         Generic 2D data
│   │   └── AnyTier (sparse time series)
│   │       ├── PitchTier      ⭐ Editable pitch contour
│   │       ├── IntensityTier  Editable intensity
│   │       ├── DurationTier   Editable duration
│   │       └── FormantGrid    Editable formant contours
│   ├── Collection (object lists)
│   │   ├── PointProcess       ⭐ Time point sequences
│   │   └── TextGrid           ⭐⭐⭐ Multi-tier annotation
│   │       ├── IntervalTier   Labeled time intervals
│   │       └── TextTier       Labeled time points
│   ├── Manipulation           ⭐⭐ PSOLA pitch/duration modification
│   └── Spectrum               Single frequency domain representation
└── ...
```

**Legend**:
- ⭐⭐⭐ = CRITICAL (essential for 90%+ of users)
- ⭐⭐ = HIGH PRIORITY (essential for synthesis/manipulation)
- ⭐ = CORE (essential for analysis)

## Current Implementation Status

### ✅ Implemented Objects (R6 Classes)

| Object | Status | Methods Count | Completeness |
|--------|--------|---------------|--------------|
| PraatObject | ✅ Complete | Base class | 100% |
| Sound | ✅ Partial | ~15/40 | 40% |
| Pitch | ✅ Partial | ~10/20 | 50% |
| Formant | ✅ Partial | ~8/15 | 55% |
| Intensity | ✅ Partial | ~6/12 | 50% |
| Harmonicity | ✅ Basic | ~4/10 | 40% |
| Spectrogram | ✅ Basic | ~5/12 | 40% |
| Spectrum | ✅ Basic | ~5/15 | 35% |
| LTAS | ✅ Basic | ~4/8 | 50% |
| TextGrid | ✅ Partial | ~15/35 | 45% |
| PointProcess | ✅ Partial | ~8/15 | 55% |
| Manipulation | ✅ Partial | ~5/10 | 50% |
| PitchTier | ✅ Basic | ~4/10 | 40% |
| IntensityTier | ✅ Basic | ~3/10 | 30% |
| DurationTier | ✅ Basic | ~3/8 | 40% |

### ❌ Missing Critical Functionality

1. **Sound Object** - Missing ~25 methods:
   - Advanced transforms: `to_harmonicity_ac()`, `to_lpc()`, `to_cochleagram()`
   - Filtering: `filter_stop_hann_band()`, `filter_pre_emphasis()`, `filter_de_emphasis()`
   - Modification: `lengthen()`, `deepen_band_modulation()`, `change_gender()`
   - Generation: `create_pure_tone()`, `create_sound_from_formula()`
   - Combination: `concatenate()`, `convolve()`, `cross_correlate()`

2. **TextGrid Object** - Missing ~20 methods:
   - Tier manipulation: `duplicate_tier()`, `remove_tier()`, `insert_interval_tier()`, `insert_point_tier()`
   - Boundary operations: `insert_boundary()`, `remove_boundary()`, `set_interval_text()`
   - Extraction: `extract_intervals_where()`, `extract_part()`
   - Export variations: `down_to_table()`, `list_all_labels()`

3. **Manipulation Object** - Missing ~5 methods:
   - Component extraction: `extract_original_sound()`, `extract_pulses()`
   - Synthesis controls: `play_resynthesis_lpc()`, `get_resynthesis()`

4. **Voice Quality** - Not yet integrated:
   - VoiceReport comprehensive analysis
   - Jitter variants (local, RAP, PPQ5)
   - Shimmer variants (local, APQ3, APQ5, APQ11)
   - HNR integration with Harmonicity

5. **Tier Objects** - Incomplete:
   - FormantGrid/FormantTier (not implemented)
   - DurationTier (minimal implementation)
   - Point manipulation methods

## Implementation Priority Matrix

### Phase 1: Complete Core Objects (Weeks 1-4)

**Goal**: 100% method coverage for critical objects

#### 1.1 Sound Object Completion
**Target**: 40/40 methods (currently 15/40)

**Missing High Priority**:
```r
# Transforms to other objects
sound$to_harmonicity_ac()           # Autocorrelation harmonicity
sound$to_harmonicity_cc()           # Cross-correlation harmonicity  
sound$to_lpc(prediction_order)      # Linear predictive coding
sound$to_point_process_peaks()      # Find amplitude peaks
sound$to_matrix()                   # Convert to Matrix object

# Filtering
sound$filter_pre_emphasis(from_frequency)
sound$filter_de_emphasis(from_frequency)
sound$filter_stop_hann_band(from_freq, to_freq, smoothing)

# Modification
sound$scale_peak(new_peak)
sound$multiply(factor)
sound$override_sampling_frequency(new_rate)
sound$lengthen(factor, method)
sound$deepen_band_modulation(enhancement_dB, from_freq, to_freq, slow_modulation, fast_modulation)

# Generation (static methods)
Sound$create_pure_tone(duration, frequency, amplitude, sampling_rate)
Sound$create_tone_complex(duration, first_frequency, num_components, sampling_rate)
Sound$create_from_formula(duration, formula, sampling_rate)

# Combination
sound$concatenate(other_sound)
sound$convolve(other_sound)
sound$cross_correlate(other_sound)
sound$auto_correlate()

# Advanced queries
sound$get_energy()
sound$get_power()
sound$get_energy_in_air()
sound$get_rms()
sound$get_intensity_db()
sound$get_nearest_zero_crossing(time, channel)
```

**Deliverable**: `R/sound-r6.R` with all 40 methods, complete C++ wrappers

---

#### 1.2 TextGrid Object Completion ⭐⭐⭐
**Target**: 35/35 methods (currently 15/35)

**Critical Missing**:
```r
# Tier management
tg$add_interval_tier(name)
tg$add_point_tier(name)
tg$duplicate_tier(tier_number, new_name)
tg$remove_tier(tier)
tg$set_tier_name(tier, new_name)

# Interval manipulation
tg$insert_boundary(tier, time)
tg$remove_boundary(tier, boundary_number)
tg$remove_left_boundary(tier, interval_number)
tg$remove_right_boundary(tier, interval_number)
tg$set_interval_text(tier, interval, text)

# Point manipulation
tg$insert_point(tier, time, mark)
tg$remove_point(tier, index)
tg$set_point_text(tier, index, text)

# Queries
tg$get_intervals_where(tier, label_matches)
tg$get_points_where(tier, label_matches)
tg$count_intervals_where(tier, condition)
tg$list_all_labels(tier)

# Extraction & combination
tg$extract_part(from_time, to_time, preserve_times)
tg$extract_tier(tier_number)
tg$merge(other_textgrid)

# Export
tg$down_to_table(include_tier_names, include_labels, include_times)
tg$save_as_chronological_text_file(path)
```

**Why Critical**: 90% of phonetic researchers use TextGrid for annotation, forced alignment, and segmentation

**Deliverable**: `R/textgrid-r6.R` with all 35 methods, complete tests, vignette

---

#### 1.3 Pitch/Formant/Intensity Completion
**Target**: Full method coverage

**Pitch** (20/20 methods):
```r
# Missing statistical queries
pitch$get_quantile(quantile, unit)
pitch$get_standard_deviation(unit)
pitch$count_voiced_frames()

# Missing transformations
pitch$interpolate()
pitch$smooth(bandwidth)
pitch$subtract_linear_fit(unit)
pitch$kill_octave_jumps()

# Missing modifications
pitch$shift_frequencies(time_range_start, time_range_end, frequency_shift, unit)
pitch$formula(formula)
```

**Formant** (15/15 methods):
```r
# Missing queries
formant$get_time_of_maximum(formant_number)
formant$get_time_of_minimum(formant_number)
formant$get_value_in_bark(formant_number, time)

# Missing transformations
formant$track(num_formants, ref_f1, ref_f2, ref_f3, ref_f4, ref_f5)
formant$to_formant_grid()
```

**Intensity** (12/12 methods):
```r
# Missing queries
intensity$get_quantile(quantile)
intensity$get_time_of_maximum()
intensity$get_time_of_minimum()
```

---

#### 1.4 Manipulation Object Completion ⭐⭐
**Target**: 10/10 methods (currently 5/10)

**Critical for**: Pitch shifting, duration modification, PSOLA resynthesis

```r
# Missing extractions
manip$extract_original_sound()      # Get original Sound
manip$extract_pulses()              # Get PointProcess
manip$extract_duration_tier()       # Get DurationTier

# Missing synthesis
manip$play()                        # Play resynthesis
manip$play_lpc()                    # LPC resynthesis
manip$get_resynthesis_lpc()         # Get LPC resynthesis as Sound
```

**Example workflow**:
```r
# Complete pitch manipulation pipeline
sound <- Sound$new("voice.wav")
manip <- sound$to_manipulation(
  time_step = 0.01,
  minimum_pitch = 75,
  maximum_pitch = 600
)

# Extract components
original <- manip$extract_original_sound()
pulses <- manip$extract_pulses()
pitch_tier <- manip$extract_pitch_tier()
duration_tier <- manip$extract_duration_tier()

# Modify pitch (raise by musical fifth = factor of 1.5)
pitch_tier$multiply_frequencies(1.5)
manip$replace_pitch_tier(pitch_tier)

# Modify duration (slow down by 20%)
duration_tier$add_point(0, 1.2)
duration_tier$add_point(original$get_duration(), 1.2)
manip$replace_duration_tier(duration_tier)

# Resynthesize
modified <- manip$get_resynthesis_overlap_add()
modified$save("voice_modified.wav")
```

---

### Phase 2: Voice Quality Integration (Week 5)

#### 2.1 VoiceReport Class
**New comprehensive object for voice quality**

```r
#' Voice Quality Analysis Report
#' Comprehensive voice quality metrics combining multiple analyses
VoiceReport <- R6Class("VoiceReport",
  public = list(
    # Create from Sound
    initialize = function(sound, 
                         time_range_start = 0,
                         time_range_end = 0,  # 0 = use sound duration
                         pitch_floor = 75,
                         pitch_ceiling = 600,
                         max_period_factor = 1.3,
                         max_amplitude_factor = 1.6) {
      # Internal: calls comprehensive C++ analysis
    },
    
    # Pitch statistics
    get_mean_pitch = function(unit = "Hertz"),
    get_median_pitch = function(unit = "Hertz"),
    get_minimum_pitch = function(unit = "Hertz"),
    get_maximum_pitch = function(unit = "Hertz"),
    get_standard_deviation_pitch = function(unit = "Hertz"),
    
    # Jitter (period-to-period variation)
    get_jitter_local = function(),           # Local jitter
    get_jitter_local_absolute = function(),  # Absolute jitter
    get_jitter_rap = function(),             # Relative Average Perturbation
    get_jitter_ppq5 = function(),            # 5-point Period Perturbation Quotient
    get_jitter_ddp = function(),             # Difference of Differences of Periods
    
    # Shimmer (amplitude variation)
    get_shimmer_local = function(),          # Local shimmer
    get_shimmer_local_db = function(),       # Shimmer in dB
    get_shimmer_apq3 = function(),           # 3-point Amplitude Perturbation Quotient
    get_shimmer_apq5 = function(),           # 5-point APQ
    get_shimmer_apq11 = function(),          # 11-point APQ
    get_shimmer_dda = function(),            # Difference of Differences of Amplitudes
    
    # Harmonicity
    get_mean_harmonicity_to_noise_ratio = function(),
    
    # Voice breaks
    get_fraction_of_locally_unvoiced_frames = function(),
    get_number_of_voice_breaks = function(),
    get_degree_of_voice_breaks = function(),
    
    # Export all
    as_data_frame = function(),              # Single row with all metrics
    print = function()
  )
)

# Usage
sound <- Sound$new("voice.wav")
report <- VoiceReport$new(sound, pitch_floor = 75, pitch_ceiling = 600)

# Get individual metrics
jitter <- report$get_jitter_local()
shimmer <- report$get_shimmer_local()
hnr <- report$get_mean_harmonicity_to_noise_ratio()

# Or export everything
metrics_df <- report$as_data_frame()
# Returns: mean_f0, sd_f0, jitter_local, jitter_rap, jitter_ppq5, 
#          shimmer_local, shimmer_apq3, shimmer_apq5, hnr_mean, ...
```

**Deliverable**: `R/voice-report-r6.R`, `src/voice_report_wrappers.cpp`, complete tests

---

#### 2.2 Enhanced PointProcess-Sound Interactions

```r
# All voice quality calculations require both Sound and PointProcess
pp <- sound$to_point_process_periodic_cc(pitch_floor = 75, pitch_ceiling = 600)

# Jitter calculations
pp$get_jitter_local(sound, period_floor, period_ceiling, max_period_factor)
pp$get_jitter_rap(sound, period_floor, period_ceiling, max_period_factor)
pp$get_jitter_ppq5(sound, period_floor, period_ceiling, max_period_factor)
pp$get_jitter_ddp(sound, period_floor, period_ceiling, max_period_factor)

# Shimmer calculations
pp$get_shimmer_local(sound, period_floor, period_ceiling, max_amplitude_factor)
pp$get_shimmer_apq3(sound, period_floor, period_ceiling, max_amplitude_factor)
pp$get_shimmer_apq5(sound, period_floor, period_ceiling, max_amplitude_factor)
pp$get_shimmer_apq11(sound, period_floor, period_ceiling, max_amplitude_factor)

# Mean period, frequency
pp$get_mean_period(sound, period_floor, period_ceiling, max_period_factor)
```

---

### Phase 3: Advanced Objects (Weeks 6-7)

#### 3.1 FormantGrid/FormantTier
**Currently missing - essential for formant manipulation**

```r
# Extract from Formant
formant <- sound$to_formant_burg(max_formant_hz = 5500)
formant_grid <- formant$to_formant_grid()

# Modify formant frequencies
formant_grid$add_formant_point(formant_number = 1, time = 0.5, frequency = 500)
formant_grid$add_bandwidth_point(formant_number = 1, time = 0.5, bandwidth = 50)

formant_grid$remove_formant_points_between(formant_number = 2, from_time = 0.3, to_time = 0.7)

# Create modified Sound with FormantGrid + source
# (Requires source/filter synthesis)
```

#### 3.2 LPC Object Completion

```r
lpc <- sound$to_lpc_auto(prediction_order = 16, window_length = 0.025, time_step = 0.005)

lpc$to_formant()
lpc$to_spectrum(time, sampling_rate)
lpc$to_spectrogram(bandwidth)
lpc$get_number_of_coefficients(time)
```

---

### Phase 4: Media Loading Integration (Week 8)

**Use humlab-speech/av fork for robust media loading**

```r
# Current: Only handles files that Praat can read directly
sound <- Sound$new("audio.wav")  # Works for WAV, AIFF

# Problem: Praat doesn't handle MP3, MP4, FLAC, OGG, etc.

# Solution: Use av package for media loading
Sound$new_from_av <- function(path, start_time = NULL, end_time = NULL) {
  # 1. Use av::read_audio_bin() to decode to raw PCM
  # 2. Convert to R numeric vector
  # 3. Use Sound$from_values() to create Sound object
  
  require(av)
  
  # Read audio (handles MP3, MP4, FLAC, OGG, WMA, AAC, etc.)
  audio_data <- av::read_audio_bin(path)
  
  # Get sample rate
  info <- av::av_media_info(path)
  sample_rate <- info$audio$sample_rate
  
  # Convert to numeric values (-1 to 1 range)
  # av returns int16, convert to float
  values <- as.numeric(audio_data) / 32768.0
  
  # Create Sound
  sound <- Sound$from_values(values, sample_rate)
  
  # Extract time range if specified
  if (!is.null(start_time) || !is.null(end_time)) {
    duration <- sound$get_duration()
    start_time <- start_time %||% 0
    end_time <- end_time %||% duration
    sound <- sound$extract_part(start_time, end_time)
  }
  
  sound
}

# Usage
sound <- Sound$new_from_av("podcast.mp3", start_time = 10, end_time = 20)
sound <- Sound$new_from_av("video.mp4")  # Extract audio from video
```

**Dependencies to add**:
```r
# DESCRIPTION
Suggests:
  av (>= 0.9.0)

# With recommendation to use humlab-speech fork
# remotes::install_github("humlab-speech/av")
```

---

### Phase 5: Praat Script Translation (Weeks 9-10)

**Goal**: Enable easy migration from Praat scripts to R

#### 5.1 Translation Patterns

**Document clear mapping** in `vignettes/praat-to-r.Rmd`:

| Praat Script | R (speaker package) | Notes |
|--------------|---------------------|-------|
| `Read from file: "audio.wav"` | `sound <- Sound$new("audio.wav")` | Object creation |
| `To Pitch: 0.01, 75, 600` | `pitch <- sound$to_pitch(0.01, 75, 600)` | Transform |
| `Get mean: 0, 0, Hertz` | `pitch$get_mean(unit = "hertz")` | Query method |
| `Scale intensity: 70` | `sound$scale_intensity(70)` | Modification |
| `Extract part: 0, 1, rectangular` | `part <- sound$extract_part(0, 1)` | Extraction |
| `plus`, `minus` | Method calls on objects | No object list needed |
| `select Sound audio` | Just use `sound` variable | No selection needed |
| `Remove` | Let R GC handle it | Automatic cleanup |

#### 5.2 Common Workflow Examples

**Example 1: Basic pitch analysis**

Praat script:
```praat
sound = Read from file: "audio.wav"
pitch = To Pitch: 0, 75, 600
mean_f0 = Get mean: 0, 0, Hertz
```

R equivalent:
```r
sound <- Sound$new("audio.wav")
pitch <- sound$to_pitch(pitch_floor = 75, pitch_ceiling = 600)
mean_f0 <- pitch$get_mean(unit = "hertz")
```

**Example 2: Formant analysis**

Praat script:
```praat
sound = Read from file: "vowel.wav"
formant = To Formant (burg): 0, 5, 5500, 0.025, 50
f1 = Get mean: 1, 0, 0, Hertz
f2 = Get mean: 2, 0, 0, Hertz
```

R equivalent:
```r
sound <- Sound$new("vowel.wav")
formant <- sound$to_formant_burg(
  time_step = 0,
  max_num_formants = 5,
  max_formant_hz = 5500,
  window_length = 0.025,
  pre_emphasis_from = 50
)
f1 <- formant$get_mean(1, unit = "hertz")
f2 <- formant$get_mean(2, unit = "hertz")
```

**Example 3: TextGrid annotation**

Praat script:
```praat
tg = Read from file: "annotation.TextGrid"
sound = Read from file: "audio.wav"
n_intervals = Get number of intervals: 1
for i from 1 to n_intervals
  label$ = Get label of interval: 1, i
  if label$ = "vowel"
    start = Get start time of interval: 1, i
    end = Get end time of interval: 1, i
    selectObject: sound
    part = Extract part: start, end, rectangular
    Save as WAV file: "vowel_" + string$(i) + ".wav"
  endif
endfor
```

R equivalent:
```r
tg <- TextGrid$new("annotation.TextGrid")
sound <- Sound$new("audio.wav")

# Get all intervals as data.frame
intervals <- tg$as_data_frame(tiers = 1)
vowel_intervals <- intervals[intervals$text == "vowel", ]

# Extract each vowel
for (i in 1:nrow(vowel_intervals)) {
  part <- sound$extract_part(
    vowel_intervals$tmin[i],
    vowel_intervals$tmax[i]
  )
  part$save(paste0("vowel_", i, ".wav"))
}
```

---

### Phase 6: Parselmouth Migration (Weeks 10-11)

**Goal**: Re-implement all superassp Python examples in R

#### 6.1 Python → R Translation Template

For each `inst/python/*.py` file in superassp:

1. **Analyze Parselmouth usage**
2. **Map to speaker methods**
3. **Create equivalent R script**
4. **Document in `inst/examples/`**

**Example: `praat_voice_report_memory.py`**

Python (Parselmouth):
```python
import parselmouth
from parselmouth.praat import call

sound = parselmouth.Sound("voice.wav")

# Manual voice report calculation
pitch = sound.to_pitch(time_step=0.0, pitch_floor=75, pitch_ceiling=600)
point_process = call(sound, "To PointProcess (periodic, cc)", 75, 600)

jitter_local = call([sound, point_process], "Get jitter (local)", 0, 0, 0.0001, 0.02, 1.3)
shimmer_local = call([sound, point_process], "Get shimmer (local)", 0, 0, 0.0001, 0.02, 1.3, 1.6)

harmonicity = call(sound, "To Harmonicity (cc)", 0.01, 75, 0.1, 1.0)
hnr = call(harmonicity, "Get mean", 0, 0)
```

R (speaker):
```r
library(speaker)

sound <- Sound$new("voice.wav")

# Method 1: Use comprehensive VoiceReport
report <- VoiceReport$new(sound, pitch_floor = 75, pitch_ceiling = 600)
jitter_local <- report$get_jitter_local()
shimmer_local <- report$get_shimmer_local()
hnr <- report$get_mean_harmonicity_to_noise_ratio()

# Method 2: Manual calculation (matches Python exactly)
pitch <- sound$to_pitch(time_step = 0.0, pitch_floor = 75, pitch_ceiling = 600)
point_process <- sound$to_point_process_periodic_cc(pitch_floor = 75, pitch_ceiling = 600)

jitter_local <- point_process$get_jitter_local(
  sound, 
  period_floor = 0.0001, 
  period_ceiling = 0.02, 
  max_period_factor = 1.3
)
shimmer_local <- point_process$get_shimmer_local(
  sound,
  period_floor = 0.0001,
  period_ceiling = 0.02,
  max_period_factor = 1.3,
  max_amplitude_factor = 1.6
)

harmonicity <- sound$to_harmonicity_cc(time_step = 0.01, minimum_pitch = 75, silence_threshold = 0.1, periods_per_window = 1.0)
hnr <- harmonicity$get_mean()
```

**Files to re-implement** (11 total):
1. `praat_voice_report_memory.py` → `inst/examples/voice_report.R`
2. `praat_pitch.py` → `inst/examples/pitch_analysis.R`
3. `praat_formant_burg.py` → `inst/examples/formant_analysis.R`
4. `praat_intensity.py` → `inst/examples/intensity_analysis.R`
5. `praat_spectral_moments.py` → `inst/examples/spectral_moments.R`
6. `praat_formantpath_burg.py` → `inst/examples/formant_path.R`
7. `praat_avqi_memory.py` → `inst/examples/avqi.R`
8. `praat_dsi_memory.py` → `inst/examples/dsi.R`
9. `praat_praatsauce_memory.py` → `inst/examples/praatsauce.R`
10. `praat_sauce_memory.py` → `inst/examples/sauce.R`
11. `praat_voice_tremor_memory.py` → `inst/examples/voice_tremor.R`

---

## Naming Convention Enforcement

**CRITICAL for Praat script transcodability**

### Method Naming Standard

| Praat Pattern | R Method Pattern | Example |
|---------------|------------------|---------|
| `Get [property]` | `get_[property]()` | `get_duration()` |
| `Get [property] at time: t` | `get_[property]_at_time(t)` | `get_value_at_time(0.5)` |
| `Get mean [property]` | `get_mean_[property]()` | `get_mean_pitch()` |
| `Get mean: f` | `get_mean(formant_number = f)` | `get_mean(1)` |
| `To [Object]` | `to_[object]()` | `to_pitch()` |
| `To [Object] ([algorithm])` | `to_[object]_[algorithm]()` | `to_formant_burg()` |
| `Extract [part]` | `extract_[part]()` | `extract_part()` |
| `Scale [property]: v` | `scale_[property](v)` | `scale_intensity(70)` |
| `Down to [type]` | `as_[type]()` | `as_data_frame()` |
| `Save as [format] file: path` | `save(path, format)` | `save("out.wav")` |

### Consistency Rules

1. **Query methods** (read-only): `get_*()` → returns value(s)
2. **Transform methods** (create new object): `to_*()` → returns new R6 object of different class
3. **Extract methods** (subset): `extract_*()` → returns new R6 object of same class
4. **Modify methods** (in-place or return modified): `scale_*()`, `filter_*()`, `multiply_*()` → may modify or return
5. **Export methods** (convert to R native): `as_*()` → returns R data structure
6. **I/O methods**: `new(path)` reads, `save(path)` writes

---

## Implementation Sequence (Revised)

### Week 1-2: Complete Core Objects (Sound, Pitch, Formant, Intensity)
- [ ] Sound: 15/40 → 40/40 methods
- [ ] Pitch: 10/20 → 20/20 methods
- [ ] Formant: 8/15 → 15/15 methods
- [ ] Intensity: 6/12 → 12/12 methods
- [ ] Harmonicity: 4/10 → 10/10 methods
- [ ] Comprehensive tests for all

### Week 3: Complete TextGrid ⭐⭐⭐
- [ ] TextGrid: 15/35 → 35/35 methods
- [ ] Full tier manipulation (interval + point)
- [ ] Export to data.frame (long format)
- [ ] Integration with Sound (segment extraction)
- [ ] Vignette: "Working with TextGrid Annotations"

### Week 4: Complete Manipulation & PointProcess
- [ ] Manipulation: 5/10 → 10/10 methods
- [ ] PointProcess: 8/15 → 15/15 methods (with Sound interactions)
- [ ] PitchTier: 4/10 → 10/10 methods
- [ ] DurationTier: 3/8 → 8/8 methods
- [ ] Vignette: "Pitch and Duration Manipulation"

### Week 5: Voice Quality Analysis
- [ ] Implement VoiceReport class
- [ ] Integrate all jitter/shimmer calculations
- [ ] PointProcess-Sound interaction methods
- [ ] Vignette: "Comprehensive Voice Quality Analysis"

### Week 6: Spectral Objects Completion
- [ ] Spectrogram: 5/12 → 12/12 methods
- [ ] Spectrum: 5/15 → 15/15 methods
- [ ] LTAS: 4/8 → 8/8 methods
- [ ] LPC: Implement full object

### Week 7: Advanced Objects
- [ ] FormantGrid/FormantTier (new)
- [ ] IntensityTier: 3/10 → 10/10 methods
- [ ] Advanced Sound methods (filtering, synthesis)

### Week 8: Media Loading Integration
- [ ] Integrate av package (humlab-speech fork)
- [ ] `Sound$new_from_av()` method
- [ ] Support MP3, MP4, FLAC, OGG, etc.
- [ ] Update documentation

### Week 9-10: Examples & Migration
- [ ] Re-implement 11 superassp Python examples
- [ ] Create `inst/examples/` directory
- [ ] Document Python → R mapping
- [ ] Create Praat script → R translation guide

### Week 11-12: Documentation & Polish
- [ ] 10 comprehensive vignettes
- [ ] Complete Rd documentation (all methods)
- [ ] Update README with full feature list
- [ ] CRAN preparation

---

## Success Metrics

### Technical Completeness
- ✅ **16+ Praat objects** as R6 classes
- ✅ **300+ methods** covering comprehensive Praat functionality
- ✅ **TextGrid full support** (read, write, manipulate, export)
- ✅ **Voice quality complete** (jitter, shimmer, HNR, VoiceReport)
- ✅ **Pitch manipulation** (Manipulation, PitchTier, DurationTier, PSOLA)
- ✅ **Media loading** (MP3, MP4, FLAC via av package)

### Usability
- ✅ **Consistent naming** (Praat → R mapping is obvious)
- ✅ **Method chaining** (object$method1()$method2())
- ✅ **10+ vignettes** (comprehensive workflows)
- ✅ **11+ examples** (Python Parselmouth equivalents)
- ✅ **Translation guides** (Praat scripts, Parselmouth code)

### Quality
- ✅ **95%+ test coverage** (R code)
- ✅ **85%+ test coverage** (C++ code)
- ✅ **Zero memory leaks** (valgrind clean)
- ✅ **Cross-platform** (macOS, Linux, Windows)
- ✅ **Performance** (within 10% of Praat desktop)

---

## Documentation Requirements

### Vignettes (10 required)

1. **Getting Started** - Installation, basic Sound/Pitch/Formant workflow
2. **Working with Sound** - Audio I/O, manipulation, generation, filtering
3. **Pitch Analysis** - F0 extraction, statistics, visualization, manipulation
4. **Formant Analysis** - Vowel analysis, formant tracking, statistics
5. **TextGrid Annotation** - Creating, editing, querying, integration with Sound
6. **Voice Quality Analysis** - Jitter, shimmer, HNR, comprehensive VoiceReport
7. **Pitch Manipulation** - PSOLA synthesis, pitch shifting, duration modification
8. **Spectral Analysis** - Spectrogram, Spectrum, LTAS, LPC
9. **From Praat Scripts to R** - Translation patterns, common workflows
10. **From Parselmouth to speaker** - Python → R migration guide

### Reference Documentation

- Complete `man/*.Rd` for all R6 classes (16+)
- Method-level documentation with examples
- Cross-references between related objects
- Package-level documentation (`?speaker`)

---

## Future Extensions (Post-CRAN)

### Phase 7: Praat Script Interpreter (Optional)
- Execute Praat scripts directly from R
- Convert Praat scripts to R code automatically
- `run_praat_script("my_script.praat")`

### Phase 8: Picture/Graphics (Optional)
- Praat's Picture window functionality
- Create spectrograms, pitch contours, TextGrid visualizations
- Export to PDF, PNG

### Phase 9: Additional Objects (Optional)
- Cochleagram (auditory filterbank)
- Excitation (basilar membrane excitation)
- Table (Praat's spreadsheet)
- Polygon, PointProcess advanced features
- Matrix operations

---

## Commit Strategy

After each major milestone:

```bash
# Week 1-2: Core objects complete
git add -A
git commit -m "feat: Complete Sound, Pitch, Formant, Intensity objects (300+ methods)

- Sound: 40/40 methods implemented
- Pitch: 20/20 methods implemented  
- Formant: 15/15 methods implemented
- Intensity: 12/12 methods implemented
- Harmonicity: 10/10 methods implemented
- Comprehensive tests and documentation
- Version bump to 0.5.0"

# Week 3: TextGrid complete
git add -A
git commit -m "feat: Complete TextGrid implementation with full tier manipulation

- TextGrid: 35/35 methods (tier management, interval/point operations)
- Integration with Sound for segment extraction
- Export to long-format data.frame
- Comprehensive tests and vignette
- Version bump to 0.6.0"

# Week 4: Manipulation complete
git add -A
git commit -m "feat: Complete Manipulation, PointProcess, and Tier objects

- Manipulation: 10/10 methods (PSOLA resynthesis)
- PointProcess: 15/15 methods (voice quality)
- PitchTier, DurationTier: full implementation
- Pitch manipulation vignette
- Version bump to 0.7.0"

# Week 5: Voice quality
git add -A
git commit -m "feat: Add comprehensive VoiceReport class

- VoiceReport: 20+ metrics (jitter, shimmer, HNR)
- PointProcess-Sound interactions complete
- Voice quality vignette
- Version bump to 0.8.0"

# Weeks 6-7: Spectral + advanced
git add -A
git commit -m "feat: Complete spectral objects and FormantGrid

- Spectrogram, Spectrum, LTAS, LPC: full implementation
- FormantGrid/FormantTier: new implementation
- IntensityTier: complete
- Version bump to 0.9.0"

# Week 8: Media loading
git add -A
git commit -m "feat: Add av package integration for media loading

- Sound$new_from_av() supports MP3, MP4, FLAC, OGG
- Integration with humlab-speech/av fork
- Documentation updates
- Version bump to 0.9.5"

# Weeks 9-10: Examples
git add -A
git commit -m "docs: Add 11 example scripts from superassp Python code

- Re-implement all Parselmouth examples in R
- inst/examples/ directory with complete workflows
- Python → R translation guide
- Praat script → R translation guide
- Version bump to 0.9.9"

# Weeks 11-12: CRAN prep
git add -A
git commit -m "docs: Complete documentation and CRAN preparation

- 10 comprehensive vignettes
- Complete Rd documentation (all methods)
- README update with full feature list
- R CMD check clean
- Version bump to 1.0.0"
```

---

## Conclusion

This amendment transforms speaker from a **procedural function library** into a **comprehensive object-oriented Praat interface** that:

1. ✅ **Mirrors Praat's architecture** - 16+ objects, 300+ methods matching Praat's OOP design
2. ✅ **Eliminates Python dependency** - Native R implementation, no Parselmouth needed
3. ✅ **Enables complete workflows** - TextGrid, Manipulation, VoiceReport, all critical features
4. ✅ **Provides clear migration** - Praat scripts and Parselmouth code easily translate to R
5. ✅ **Production-ready quality** - Comprehensive tests, documentation, cross-platform support

**This is the comprehensive phonetic analysis toolkit R deserves!** 🎉
