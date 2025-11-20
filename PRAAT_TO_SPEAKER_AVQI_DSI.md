# Praat Script to speaker Package Translation Guide
## AVQI and DSI Line-by-Line Mapping

---

## AVQI v3.01 Translation

### Section 1: File Loading & Concatenation

| Praat Script | speaker Package |
|-------------|-----------------|
| `svLst = Create Strings as file list: "svList", "'input_directory$'/sv*.wav"` | `sv_files <- list.files(input_dir, pattern = "^sv.*\\.wav$", full.names = TRUE)` |
| `noSv = Get number of strings` | `length(sv_files)` |
| `Read from file: "'input_directory$'/'currSv$'"` | `Sound$new(sv_files[i])` |
| `Concatenate` | `Sound$concatenate(sound_list)` |
| `svTotalDuration = Get total duration` | `sv_sound$get_total_duration()` |
| `Rename: "sv"` | `sv <- sv_concatenated` (R assignment) |

**speaker Implementation**:
```r
# Load and concatenate sustained vowels
sv_files <- list.files(input_dir, pattern = "^sv.*\\.wav$", full.names = TRUE)
sv_sounds <- lapply(sv_files, function(f) Sound$new(f))
sv <- Sound$concatenate(sv_sounds)
sv_total_duration <- sv$get_total_duration()

# Load and concatenate continuous speech
cs_files <- list.files(input_dir, pattern = "^cs.*\\.wav$", full.names = TRUE)
cs_sounds <- lapply(cs_files, function(f) Sound$new(f))
cs <- Sound$concatenate(cs_sounds)
cs_total_duration <- cs$get_total_duration()
```

---

### Section 2: High-Pass Filtering

| Praat Script | speaker Package |
|-------------|-----------------|
| `Filter (stop Hann band)... 0 34 0.1` | ❌ **MISSING** `sound$filter_stop_hann_band(0, 34, 0.1)` |
| `Rename... cs2` | `cs2 <- cs_filtered` |

**Required Implementation**:
```cpp
// src/sound_wrappers.cpp
// [[Rcpp::export]]
SEXP praat_sound_filter_stop_band(SEXP xptr, double from_freq, double to_freq, double smoothing) {
    autoSound sound = unwrapSound(xptr);
    autoSound filtered = Sound_filter_stopHann(sound.get(), from_freq, to_freq, smoothing);
    return wrapSound(filtered.move());
}
```

```r
# R/sound-r6.R
filter_stop_hann_band = function(from_frequency, to_frequency, smoothing = 0.1) {
  filtered_xptr <- praat_sound_filter_stop_band(self$.xptr, from_frequency, to_frequency, smoothing)
  Sound$new(.xptr = filtered_xptr)
}
```

---

### Section 3: Voice Activity Detection & Extraction

| Praat Script | speaker Package |
|-------------|-----------------|
| `To TextGrid (silences)... 50 0.003 -25 0.1 0.1 silence sounding` | ❌ **MISSING** `sound$to_textgrid_silences(...)` |
| `Extract intervals where... 1 no "does not contain" silence` | ❌ **MISSING** `textgrid$extract_intervals_where(...)` |
| `Concatenate` | `Sound$concatenate(voiced_intervals)` |
| `globalPower = Get power in air` | ❌ **MISSING** `sound$get_power_in_air()` |

**Required Implementation**:
```cpp
// src/vad_wrappers.cpp
// [[Rcpp::export]]
SEXP praat_sound_to_textgrid_silences(
    SEXP xptr,
    double min_pitch,
    double time_step,
    double silence_threshold,
    double min_silent_interval,
    double min_sounding_interval,
    const std::string& silent_label,
    const std::string& sounding_label
) {
    autoSound sound = unwrapSound(xptr);
    autoTextGrid grid = Sound_to_TextGrid_detectSilences(
        sound.get(), min_pitch, time_step, silence_threshold,
        min_silent_interval, min_sounding_interval,
        Melder_cat(silent_label.c_str()), Melder_cat(sounding_label.c_str())
    );
    return wrapTextGrid(grid.move());
}

// [[Rcpp::export]]
double praat_sound_get_power_in_air(SEXP xptr, double from_time, double to_time) {
    autoSound sound = unwrapSound(xptr);
    return Sound_getPowerInAir(sound.get(), from_time, to_time);
}
```

```r
# R/vad.R (new file)
sound_to_textgrid_silences <- function(sound, min_pitch = 100, time_step = 0.0, 
                                       silence_threshold = -25, min_silent_interval = 0.1,
                                       min_sounding_interval = 0.1, silent_label = "silence",
                                       sounding_label = "sounding") {
  grid_xptr <- praat_sound_to_textgrid_silences(
    sound$.xptr, min_pitch, time_step, silence_threshold,
    min_silent_interval, min_sounding_interval, silent_label, sounding_label
  )
  TextGrid$new(.xptr = grid_xptr)
}

# R/sound-r6.R
get_power_in_air = function(from_time = 0, to_time = 0) {
  if (to_time == 0) to_time <- self$get_total_duration()
  praat_sound_get_power_in_air(self$.xptr, from_time, to_time)
}
```

**speaker Implementation**:
```r
# Voice activity detection
vad_grid <- sound_to_textgrid_silences(
  cs2,
  min_pitch = 50,
  time_step = 0.003,
  silence_threshold = -25,
  min_silent_interval = 0.1,
  min_sounding_interval = 0.1
)

# Extract voiced intervals
voiced_intervals <- vad_grid$get_intervals_where(tier = 1, condition = "equals", text = "sounding")

# Extract sounds and concatenate
voiced_sounds <- lapply(voiced_intervals, function(interval) {
  cs2$extract_part(interval$xmin, interval$xmax, "rectangular", 1.0, FALSE)
})
only_voice <- Sound$concatenate(voiced_sounds)
```

---

### Section 4: Concatenate SV + Voiced CS

| Praat Script | speaker Package |
|-------------|-----------------|
| `plus Sound sv2` + `Concatenate` | `Sound$concatenate(list(only_voice, sv2))` |

```r
# Concatenate voiced CS and SV
concatenated_signal <- Sound$concatenate(list(only_voice, sv2))
```

---

### Section 5: Acoustic Measures

#### 5.1 Harmonics-to-Noise Ratio (HNR)

| Praat Script | speaker Package |
|-------------|-----------------|
| `To Harmonicity (cc)... 0.01 75 0.1 1.0` | ✅ `sound$to_harmonicity_cc(0.01, 75, 0.1, 1.0)` |
| `Get mean... 0 0` | ✅ `harmonicity$get_mean(0, 0)` |

```r
harmonicity <- concatenated_signal$to_harmonicity_cc(
  time_step = 0.01,
  minimum_pitch = 75,
  silence_threshold = 0.1,
  periods_per_window = 1.0
)
hnr <- harmonicity$get_mean(from_time = 0, to_time = 0)
```

#### 5.2 Shimmer Local & Shimmer Local dB

| Praat Script | speaker Package |
|-------------|-----------------|
| `To Pitch (cc)... 0.005 50 15 no 0.03 0.8 0.01 0.35 0.14 600` | ✅ `sound$to_pitch_cc(...)` |
| `To PointProcess (cc)` | ✅ Sound + Pitch → PointProcess |
| `voiceReport$ = Voice report... 0 0 75 600 1.3 1.6 0.03 0.45` | ❌ **MISSING** |
| `shimmerLocal = extractNumber(voiceReport$, "Shimmer (local): ")` | ❌ Needs voice_report implementation |
| `shimmerLocalDB = extractNumber(voiceReport$, "Shimmer (local, dB): ")` | ❌ Needs voice_report implementation |

**Required Implementation**:
```cpp
// src/pointprocess_wrappers.cpp
// [[Rcpp::export]]
Rcpp::List praat_voice_report(
    SEXP sound_xptr, SEXP pitch_xptr, SEXP pp_xptr,
    double t1, double t2, double floor, double ceiling,
    double max_period_factor, double max_amplitude_factor,
    double silence_threshold, double voicing_threshold
) {
    autoSound sound = unwrapSound(sound_xptr);
    autoPitch pitch = unwrapPitch(pitch_xptr);
    autoPointProcess pp = unwrapPointProcess(pp_xptr);
    
    // Get voice report string
    autostring32 report = Sound_Pitch_PointProcess_voiceReport(
        sound.get(), pitch.get(), pp.get(),
        t1, t2, floor, ceiling, max_period_factor, max_amplitude_factor,
        silence_threshold, voicing_threshold
    );
    
    // Parse all values from report string
    double jitter_local = /* parse "Jitter (local): X%" */;
    double jitter_ppq5 = /* parse "Jitter (ppq5): X%" */;
    double shimmer_local = /* parse "Shimmer (local): X%" */;
    double shimmer_local_db = /* parse "Shimmer (local, dB): X dB" */;
    // ... etc
    
    return Rcpp::List::create(
        Rcpp::Named("jitter_local") = jitter_local,
        Rcpp::Named("jitter_ppq5") = jitter_ppq5,
        Rcpp::Named("shimmer_local") = shimmer_local,
        Rcpp::Named("shimmer_local_db") = shimmer_local_db,
        // ... all other measures
    );
}
```

```r
# R/pointprocess-r6.R
voice_report = function(sound, pitch, from_time = 0, to_time = 0,
                       pitch_floor = 75, pitch_ceiling = 600,
                       max_period_factor = 1.3, max_amplitude_factor = 1.6,
                       silence_threshold = 0.03, voicing_threshold = 0.45) {
  praat_voice_report(sound$.xptr, pitch$.xptr, self$.xptr,
                    from_time, to_time, pitch_floor, pitch_ceiling,
                    max_period_factor, max_amplitude_factor,
                    silence_threshold, voicing_threshold)
}
```

**speaker Implementation**:
```r
# Compute pitch
pitch <- concatenated_signal$to_pitch_cc(
  time_step = 0.005,
  pitch_floor = 50,
  max_number_of_candidates = 15,
  very_accurate = FALSE,
  silence_threshold = 0.03,
  voicing_threshold = 0.8,
  octave_cost = 0.01,
  octave_jump_cost = 0.35,
  voiced_unvoiced_cost = 0.14,
  pitch_ceiling = 600
)

# Create point process
point_process <- concatenated_signal$to_point_process_cc(pitch)

# Get voice report
report <- point_process$voice_report(
  sound = concatenated_signal,
  pitch = pitch,
  pitch_floor = 75,
  pitch_ceiling = 600
)

shimmer_local <- report$shimmer_local
shimmer_local_db <- report$shimmer_local_db
```

#### 5.3 CPPS (Smoothed Cepstral Peak Prominence)

| Praat Script | speaker Package |
|-------------|-----------------|
| `To PowerCepstrogram... 60 0.002 5000 50` | ❌ **MISSING** `sound$to_power_cepstrogram(...)` |
| `cpps = Get CPPS... yes 0.001 0.05 60 330 0.05 Parabolic 0.001 0 0 Straight` | ❌ **MISSING** `cepstrogram$get_cpps(...)` |

**Required Implementation**:
```cpp
// src/powercepstrum_wrappers.cpp
// [[Rcpp::export]]
SEXP praat_sound_to_power_cepstrogram(
    SEXP xptr, double pitch_floor, double time_step,
    double max_frequency, double pre_emphasis_from
) {
    autoSound sound = unwrapSound(xptr);
    autoPowerCepstrogram cepstrogram = Sound_to_PowerCepstrogram(
        sound.get(), pitch_floor, time_step, max_frequency, pre_emphasis_from
    );
    return wrapPowerCepstrogram(cepstrogram.move());
}

// [[Rcpp::export]]
double praat_power_cepstrogram_get_cpps(
    SEXP xptr, bool subtract_tilt, double time_averaging,
    double quefrency_averaging, double floor, double ceiling,
    double tolerance, const std::string& interpolation,
    double qstep, double from_time, to_time
) {
    autoPowerCepstrogram cepstrogram = unwrapPowerCepstrogram(xptr);
    
    double cpps = PowerCepstrogram_getCPPS(
        cepstrogram.get(), subtract_tilt, time_averaging, quefrency_averaging,
        1.0/ceiling, 1.0/floor,  // Convert pitch to quefrency
        interpolation == "Parabolic" ? 1 : 0,
        qstep, tolerance, from_time, to_time, 0  // 0 = Straight
    );
    
    return cpps;
}
```

```r
# R/sound-r6.R
to_power_cepstrogram = function(pitch_floor = 60, time_step = 0.002,
                                max_frequency = 5000, pre_emphasis_from = 50) {
  cepstrogram_xptr <- praat_sound_to_power_cepstrogram(
    self$.xptr, pitch_floor, time_step, max_frequency, pre_emphasis_from
  )
  PowerCepstrogram$new(.xptr = cepstrogram_xptr)
}

# R/powercepstrogram-r6.R (NEW FILE)
PowerCepstrogram <- R6::R6Class(
  "PowerCepstrogram",
  public = list(
    .xptr = NULL,
    
    initialize = function(.xptr) {
      self$.xptr <- .xptr
    },
    
    get_cpps = function(subtract_tilt = TRUE, time_averaging = 0.001,
                       quefrency_averaging = 0.05, pitch_floor = 60,
                       pitch_ceiling = 330, tolerance = 0.05,
                       interpolation = "Parabolic", quefrency_step = 0.001,
                       from_time = 0, to_time = 0) {
      praat_power_cepstrogram_get_cpps(
        self$.xptr, subtract_tilt, time_averaging, quefrency_averaging,
        pitch_floor, pitch_ceiling, tolerance, interpolation,
        quefrency_step, from_time, to_time
      )
    }
  )
)
```

**speaker Implementation**:
```r
# Create power cepstrogram
cepstrogram <- concatenated_signal$to_power_cepstrogram(
  pitch_floor = 60,
  time_step = 0.002,
  max_frequency = 5000,
  pre_emphasis_from = 50
)

# Get CPPS
cpps <- cepstrogram$get_cpps(
  subtract_tilt = TRUE,
  time_averaging = 0.001,
  quefrency_averaging = 0.05,
  pitch_floor = 60,
  pitch_ceiling = 330,
  tolerance = 0.05,
  interpolation = "Parabolic",
  quefrency_step = 0.001
)
```

#### 5.4 LTAS Slope

| Praat Script | speaker Package |
|-------------|-----------------|
| `To Ltas... 1` | ✅ `sound$to_ltas(bandwidth = 1)` |
| `slope = Get slope... 0 1000 1000 5000 energy` | ✅ `ltas$get_slope(0, 1000, 1000, 5000, "energy")` |

```r
ltas <- concatenated_signal$to_ltas(bandwidth = 1)
slope <- ltas$get_slope(
  low_band_from = 0,
  low_band_to = 1000,
  high_band_from = 1000,
  high_band_to = 5000,
  method = "energy"
)
```

#### 5.5 LTAS Tilt (H1-A3 Approximation)

| Praat Script | speaker Package |
|-------------|-----------------|
| `tiltLow = Get value at frequency... 50 cubic` | ✅ `ltas$get_value_at_frequency(50, "cubic")` |
| `tiltHigh = Get value at frequency... 1500 cubic` | ✅ `ltas$get_value_at_frequency(1500, "cubic")` |
| `tilt = tiltLow - tiltHigh` | ✅ R calculation |

```r
tilt_low <- ltas$get_value_at_frequency(frequency = 50, interpolation = "cubic")
tilt_high <- ltas$get_value_at_frequency(frequency = 1500, interpolation = "cubic")
tilt <- tilt_low - tilt_high
```

---

### Section 6: AVQI Score Calculation

| Praat Script | speaker Package |
|-------------|-----------------|
| `avqi = 4.152 - 0.177*cpps - 0.006*hnr - 0.037*shimmerLocal + 0.941*shimmerLocalDB + 0.01*slope + 0.093*tilt` | ✅ R calculation |

```r
# AVQI formula (Barsties & Maryn, 2015)
avqi_score <- 4.152 - 
              (0.177 * cpps) - 
              (0.006 * hnr) - 
              (0.037 * shimmer_local) + 
              (0.941 * shimmer_local_db) + 
              (0.01 * slope) + 
              (0.093 * tilt)
```

---

## DSI v2.01 Translation

### Section 1: Maximum Phonation Time (MPT)

| Praat Script | speaker Package |
|-------------|-----------------|
| `Create Strings as file list: "mptList", "'input_directory$'/mpt*.wav"` | `list.files(input_dir, pattern = "^mpt.*\\.wav$")` |
| `Open long sound file: ...` | `Sound$new(file)` |
| `curr = Get total duration` | `sound$get_total_duration()` |

```r
# Find maximum phonation time
mpt_files <- list.files(input_dir, pattern = "^mpt.*\\.wav$", full.names = TRUE)
mpt <- 0
for (file in mpt_files) {
  sound <- Sound$new(file)
  duration <- sound$get_total_duration()
  if (duration > mpt) mpt <- duration
}
```

### Section 2: Minimum Intensity (I-low)

| Praat Script | speaker Package |
|-------------|-----------------|
| `To Pitch (cc)... 0 70 15 no 0.03 0.8 0.01 0.35 0.14 600` | ✅ `sound$to_pitch_cc(...)` |
| `To PointProcess (cc)` | ✅ Sound + Pitch → PointProcess |
| `To TextGrid (vuv)... 0.02 0.01` | ❌ **MISSING** `pp$to_textgrid_vuv(...)` |
| `Extract intervals where... 1 no "is equal to" V` | Use TextGrid interval extraction |
| `To Intensity... 60 0.0 yes` | ✅ `sound$to_intensity(60, 0.0, TRUE)` |
| `Formula... 1*self+'calibration'` | ❌ **MISSING** `intensity$formula(...)` |
| `minimumIntensity = Get minimum... 0 0 none` | ✅ `intensity$get_minimum(0, 0, "none")` |

```r
# Load and concatenate soft phonation files
im_files <- list.files(input_dir, pattern = "^im.*\\.wav$", full.names = TRUE)
im_sounds <- lapply(im_files, function(f) Sound$new(f))
im <- Sound$concatenate(im_sounds)

# Extract voiced segments
pitch_im <- im$to_pitch_cc(time_step = 0, pitch_floor = 70, max_number_of_candidates = 15,
                           very_accurate = FALSE, silence_threshold = 0.03,
                           voicing_threshold = 0.8, octave_cost = 0.01,
                           octave_jump_cost = 0.35, voiced_unvoiced_cost = 0.14,
                           pitch_ceiling = 600)
pp_im <- im$to_point_process_cc(pitch_im)

# Create V/U TextGrid and extract voiced
vuv_grid <- pp_im$to_textgrid_vuv(max_period = 0.02, mean_period = 0.01)  # MISSING
voiced_intervals <- vuv_grid$get_intervals_where(tier = 1, condition = "equals", text = "V")
voiced_im_sounds <- lapply(voiced_intervals, function(int) {
  im$extract_part(int$xmin, int$xmax, "rectangular", 1.0, FALSE)
})
voiced_im <- Sound$concatenate(voiced_im_sounds)

# Compute intensity
intensity_im <- voiced_im$to_intensity(minimum_pitch = 60, time_step = 0.0, subtract_mean = TRUE)

# Apply calibration if needed
if (apply_calibration) {
  intensity_im$formula(paste0("1*self+", calibration))  # MISSING
}

i_low <- intensity_im$get_minimum(from_time = 0, to_time = 0, interpolation = "none")
```

### Section 3: Maximum F0 (f0-high)

| Praat Script | speaker Package |
|-------------|-----------------|
| `To Pitch (cc)... 0 70 15 no 0.03 0.8 0.01 0.35 0.14 1300` | ✅ `sound$to_pitch_cc(..., pitch_ceiling = 1300)` |
| `maximumF0 = Get maximum... 0 0 Hertz none` | ✅ `pitch$get_maximum(0, 0, "hertz", "none")` |

```r
# Load and concatenate high pitch files
fh_files <- list.files(input_dir, pattern = "^fh.*\\.wav$", full.names = TRUE)
fh_sounds <- lapply(fh_files, function(f) Sound$new(f))
fh <- Sound$concatenate(fh_sounds)

# Compute pitch with higher ceiling
pitch_fh <- fh$to_pitch_cc(
  time_step = 0,
  pitch_floor = 70,
  max_number_of_candidates = 15,
  very_accurate = FALSE,
  silence_threshold = 0.03,
  voicing_threshold = 0.8,
  octave_cost = 0.01,
  octave_jump_cost = 0.35,
  voiced_unvoiced_cost = 0.14,
  pitch_ceiling = 1300  # Higher ceiling for high pitches
)

f0_high <- pitch_fh$get_maximum(from_time = 0, to_time = 0, unit = "hertz", interpolation = "none")
```

### Section 4: Jitter ppq5

| Praat Script | speaker Package |
|-------------|-----------------|
| `Extract part... durationStart durationVowel rectangular 1 no` | ✅ `sound$extract_part(...)` |
| `To Pitch... 0 70 600` | ✅ `sound$to_pitch(...)` |
| `To PointProcess (cc)` | ✅ Sound + Pitch → PointProcess |
| `voiceReport$ = Voice report... 0 0 70 600 1.3 1.6 0.03 0.45` | ❌ **MISSING** |
| `jitterPpq5Pre = extractNumber(voiceReport$, "Jitter (ppq5): ")` | ❌ Needs voice_report |
| `jitterPpq5 = jitterPpq5Pre*100` | Convert to percentage |

```r
# Load sustained vowel
ppq_files <- list.files(input_dir, pattern = "^ppq.*\\.wav$", full.names = TRUE)
ppq_sounds <- lapply(ppq_files, function(f) Sound$new(f))
ppq <- Sound$concatenate(ppq_sounds)

# Extract last 3 seconds
duration_vowel <- ppq$get_total_duration()
duration_start <- max(0, duration_vowel - 3)
ppq2 <- ppq$extract_part(
  from_time = duration_start,
  to_time = duration_vowel,
  window_shape = "rectangular",
  relative_width = 1.0,
  preserve_times = FALSE
)

# Compute pitch and point process
pitch_ppq <- ppq2$to_pitch(time_step = 0, pitch_floor = 70, pitch_ceiling = 600)
pp_ppq <- ppq2$to_point_process_cc(pitch_ppq)

# Get voice report
report_ppq <- pp_ppq$voice_report(
  sound = ppq2,
  pitch = pitch_ppq,
  pitch_floor = 70,
  pitch_ceiling = 600,
  max_period_factor = 1.3,
  max_amplitude_factor = 1.6,
  silence_threshold = 0.03,
  voicing_threshold = 0.45
)

jitter_ppq5 <- report_ppq$jitter_ppq5 * 100  # Convert to percentage
```

### Section 5: DSI Calculation

| Praat Script | speaker Package |
|-------------|-----------------|
| `dsi2 = 1.127 + 0.164*mpt - 0.038*minimumIntensity + 0.0053*maximumF0 - 5.30*jitterPpq5` | ✅ R calculation |

```r
# DSI formula (Wuyts et al., 2000)
dsi_score <- 1.127 + 
             (0.164 * mpt) - 
             (0.038 * i_low) + 
             (0.0053 * f0_high) - 
             (5.30 * jitter_ppq5)
```

---

## Summary of Required Implementations

### Critical (Must Implement)

1. **Voice Report** - `src/pointprocess_wrappers.cpp`
   - Returns all jitter/shimmer metrics
   - Needed for both AVQI and DSI

2. **PowerCepstrogram + CPPS** - `src/powercepstrum_wrappers.cpp`
   - `Sound$to_power_cepstrogram()`
   - `PowerCepstrogram$get_cpps()`
   - Critical for AVQI

3. **Voice Activity Detection** - `src/vad_wrappers.cpp`
   - `Sound$to_textgrid_silences()`
   - `TextGrid$extract_intervals_where()`
   - Needed for AVQI voiced segment extraction

### Important (Improves Accuracy)

4. **Bandstop Filter** - `src/sound_wrappers.cpp`
   - `Sound$filter_stop_hann_band()`

5. **Power Calculations** - `src/sound_wrappers.cpp`
   - `Sound$get_power_in_air()`

6. **PointProcess to TextGrid (V/U)** - `src/pointprocess_wrappers.cpp`
   - `PointProcess$to_textgrid_vuv()`

7. **Formula Interface** - `src/intensity_wrappers.cpp`, `src/matrix_wrappers.cpp`
   - `Intensity$formula()`
   - `Matrix$formula()`

---

**Next Step**: Begin implementation with Voice Report (highest priority)
