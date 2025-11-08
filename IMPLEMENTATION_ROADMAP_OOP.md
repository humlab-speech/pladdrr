# Object-Oriented Implementation Roadmap

**Created:** 2025-11-08  
**Current Version:** 0.2.1  
**Target:** Comprehensive Praat OOP implementation in R

## Current Implementation Status

### ✅ Completed Objects

**Sound** - ~60% complete (19/40 methods)
- ✅ Constructors: from file, from values, create tone
- ✅ Query: duration, sampling_frequency, number_of_samples, number_of_channels, value_at_time, rms, energy, power, intensity_db  
- ✅ Transforms: to_pitch, to_formant_burg, to_intensity, to_harmonicity_ac/cc, to_point_process (3 variants), to_spectrogram, to_spectrum
- ✅ Export: as_data_frame, as_matrix, save
- ❌ Missing: filtering, pre-emphasis, resampling, concatenation, modification, extraction methods

**Pitch** - ~40% complete (8/20 methods)
- ✅ Basic R6 structure
- ✅ Query: get_mean, get_standard_deviation, get_value_at_time, count_voiced_frames
- ✅ Export: as_data_frame
- ❌ Missing: smooth, interpolate, kill_octave_jumps, to_pitch_tier, to_sound, statistics (quantile, min/max, etc.)

**PointProcess** - ~50% complete (8/15 methods)
- ✅ Basic R6 structure  
- ✅ Query: get_number_of_points, get_time_from_index, get_jitter_local, get_jitter_rap, get_jitter_ppq5, get_shimmer_local
- ❌ Missing: get_shimmer_apq3, get_shimmer_apq5, add/remove points, voice reports

**Formant** - 10% complete (S3 only, needs R6)
- ✅ S3 functions exist
- ❌ Need R6 conversion
- ❌ Missing: most methods (~15 total)

**Intensity** - 10% complete (S3 only, needs R6)
- ✅ S3 functions exist
- ❌ Need R6 conversion
- ❌ Missing: most methods (~12 total)

**Harmonicity** - 10% complete (S3 only, needs R6)
- ✅ S3 functions exist
- ❌ Need R6 conversion
- ❌ Missing: most methods (~10 total)

### ❌ Missing Critical Objects

**Priority 1: TextGrid** ⭐⭐⭐ (0%)
- Essential for 90%+ of phonetic research
- Required for forced alignment workflows
- Needed: ~35 methods (tier management, intervals, points, I/O)

**Priority 2: Manipulation** ⭐⭐ (0%)
- Pitch and duration modification
- PSOLA resynthesis
- Needed: ~10 methods

**Priority 3: Spectral Objects** (0%)
- Spectrogram - partially handled (to_spectrogram exists)
- Spectrum - partially handled (to_spectrum exists)  
- LPC - not implemented
- Ltas - not implemented

**Priority 4: Tier Objects** (0%)
- PitchTier
- FormantGrid
- IntensityTier
- DurationTier

## Implementation Plan

### Phase 1: Complete Foundation (Weeks 1-2)

#### Week 1: Expand Sound Class

**Goal:** Implement missing 21 Sound methods

**New Methods to Add:**

1. **Filtering Methods** (6 methods)
   ```r
   # C++ wrapper + R6 method
   sound$filter_pass_hann_band(from_freq, to_freq, smooth_width)
   sound$filter_stop_hann_band(from_freq, to_freq, smooth_width)
   sound$filter_pass_formula(formula)  
   sound$filter_stop_formula(formula)
   sound$filter_one_formant(frequency, bandwidth)
   sound$pre_emphasize(from_freq)  # ✅ Already have
   sound$de_emphasize(from_freq)   # ✅ Already have
   ```

2. **Modification Methods** (7 methods)
   ```r
   sound$resample(new_frequency, precision)
   sound$lengthen(factor)
   sound$deepen_band_modulation(enhancement_dB, from_freq, to_freq, slow_mod_hz, fast_mod_hz)
   sound$override_sampling_frequency(new_freq)  # Dangerous but sometimes needed
   sound$scale_intensity(new_avg_intensity)
   sound$scale_peak(new_absolute_peak)
   sound$multiply_by_window(window_shape)
   ```

3. **Extraction Methods** (4 methods)
   ```r
   sound$extract_part(from, to, window_shape, relative_width, preserve_times)  # Enhanced version
   sound$extract_channel(channel_number)
   sound$extract_left_channel()  # Convenience
   sound$extract_right_channel()  # Convenience
   ```

4. **Combination Methods** (4 methods)
   ```r
   sound$concatenate(other_sound, overlap)
   sound$convolve(other_sound, scaling, signal_outside)
   sound$cross_correlate(other_sound, scaling, signal_outside)
   sound$mix(other_sound)  # Add two sounds
   ```

**Implementation Steps:**
1. Add C++ wrappers in `src/sound_wrappers.cpp`
2. Add R6 methods to `R/sound-r6-new.R`
3. Write tests in `tests/testthat/test-sound.R`
4. Update documentation

**Deliverable:** Complete Sound class (40/40 methods) ✅

---

#### Week 2: Complete Core Analysis Objects

**Goal:** Finish Pitch, convert Formant/Intensity/Harmonicity to R6

**1. Expand Pitch** (~12 new methods)

```r
# Modification
pitch$smooth(bandwidth)
pitch$interpolate()
pitch$kill_octave_jumps()
pitch$subtract_linear_fit()

# Statistics  
pitch$get_minimum(from_time, to_time, unit, interpolation)
pitch$get_maximum(from_time, to_time, unit, interpolation)
pitch$get_time_of_minimum(from_time, to_time, unit, interpolation)
pitch$get_time_of_maximum(from_time, to_time, unit, interpolation)
pitch$get_quantile(from_time, to_time, quantile, unit)

# Transforms
pitch$to_pitch_tier()
pitch$to_point_process()
pitch$to_sound(sampling_frequency)  # Pitch resynthesis
```

**2. Formant R6 Conversion** (~15 methods)

```r
# Constructor
Formant$new(path)
Formant$new(.xptr = ptr)

# Query
formant$get_value_at_time(formant_number, time, unit)
formant$get_bandwidth_at_time(formant_number, time)
formant$get_minimum(formant_number, from_time, to_time, unit, interpolation)
formant$get_maximum(formant_number, from_time, to_time, unit, interpolation)
formant$get_mean(formant_number, from_time, to_time, unit)
formant$get_standard_deviation(formant_number, from_time, to_time, unit)
formant$get_quantile(formant_number, from_time, to_time, quantile, unit)
formant$get_number_of_formants(time)

# Tracking
formant$track(num_tracks, ref_f1, ref_f2, ref_f3, ref_f4, ref_f5,
              freq_cost, bandwidth_cost, transition_cost)

# Transforms
formant$down_to_formant_grid()
formant$down_to_table(include_frame_number, include_time, time_decimals,
                      include_intensity, freq_decimals, bandwidth_decimals)

# Export
formant$as_data_frame()
formant$save(path)

# Print
formant$print()
```

**3. Intensity R6 Conversion** (~12 methods)

```r
# Constructor
Intensity$new(path)
Intensity$new(.xptr = ptr)

# Query
intensity$get_value_at_time(time, interpolation)
intensity$get_minimum(from_time, to_time, interpolation)
intensity$get_maximum(from_time, to_time, interpolation)
intensity$get_time_of_minimum(from_time, to_time, interpolation)
intensity$get_time_of_maximum(from_time, to_time, interpolation)
intensity$get_mean(from_time, to_time, averaging_method)
intensity$get_standard_deviation(from_time, to_time)
intensity$get_quantile(from_time, to_time, quantile)

# Transforms
intensity$down_to_intensity_tier()
intensity$down_to_matrix()

# Export
intensity$as_data_frame()
intensity$save(path)
```

**4. Harmonicity R6 Conversion** (~10 methods)

```r
# Constructor
Harmonicity$new(path)
Harmonicity$new(.xptr = ptr)

# Query
harmonicity$get_value_at_time(time, interpolation)
harmonicity$get_mean(from_time, to_time)
harmonicity$get_standard_deviation(from_time, to_time)
harmonicity$get_minimum(from_time, to_time, interpolation)
harmonicity$get_maximum(from_time, to_time, interpolation)
harmonicity$get_time_of_minimum(from_time, to_time, interpolation)
harmonicity$get_time_of_maximum(from_time, to_time, interpolation)
harmonicity$get_quantile(from_time, to_time, quantile)

# Export
harmonicity$as_data_frame()
harmonicity$save(path)
```

**Implementation Steps per Object:**
1. Create `R/[object]-r6.R` file
2. Create or expand `src/[object]_wrappers.cpp`
3. Add Rcpp exports
4. Run `devtools::document()` to update
5. Write comprehensive tests
6. Document with roxygen2

**Deliverables:**
- Complete Pitch (20/20 methods) ✅
- Complete Formant R6 (15/15 methods) ✅
- Complete Intensity R6 (12/12 methods) ✅
- Complete Harmonicity R6 (10/10 methods) ✅
- Comprehensive tests for all
- Full documentation

---

### Phase 2: TextGrid Implementation (Weeks 3-4) ⭐⭐⭐

**Goal:** Complete TextGrid support - THE MOST CRITICAL MISSING FEATURE

**Why Critical:**
- Used by 90%+ of phonetic researchers
- Essential for forced alignment (MFA, P2FA, WebMAUS)
- Required for segment-based analysis
- Enables annotation workflows

**TextGrid Object Structure:**

```r
TextGrid$new(path)                    # Read from file
TextGrid$new(.xptr = ptr)             # From C++ pointer
TextGrid$create(xmin, xmax, tier_names, point_tier_indices)  # Create new

# Tier query
textgrid$get_number_of_tiers()
textgrid$get_tier_name(tier_number)
textgrid$get_tier_names()  # Vector of all names
textgrid$is_interval_tier(tier)
textgrid$is_point_tier(tier)

# Interval tier methods (for IntervalTier type)
textgrid$get_number_of_intervals(tier)
textgrid$get_interval_at_time(tier, time)
textgrid$get_interval_start_time(tier, interval_number)
textgrid$get_interval_end_time(tier, interval_number)
textgrid$get_interval_text(tier, interval_number)
textgrid$set_interval_text(tier, interval_number, text)
textgrid$get_label_at_time(tier, time)
textgrid$insert_boundary(tier, time)
textgrid$remove_boundary(tier, time)
textgrid$remove_left_boundary(tier, interval_number)
textgrid$remove_right_boundary(tier, interval_number)

# Point tier methods (for TextTier/PointTier type)
textgrid$get_number_of_points(tier)
textgrid$get_point_time(tier, point_number)
textgrid$get_point_text(tier, point_number)
textgrid$insert_point(tier, time, text)
textgrid$remove_point(tier, point_number)
textgrid$get_nearest_point_index(tier, time)
textgrid$get_point_at_time(tier, time)

# Tier management
textgrid$add_interval_tier(name, position = NULL)
textgrid$add_point_tier(name, position = NULL)
textgrid$remove_tier(tier)
textgrid$duplicate_tier(tier, new_name, position = NULL)

# Extraction
textgrid$extract_part(from_time, to_time, preserve_times)

# Export
textgrid$as_data_frame(tiers = NULL, include_empty = FALSE)
  # Returns: data.frame with columns tier_number, tier_name, tier_type, 
  #          interval/point_number, start_time (intervals), end_time (intervals),
  #          time (points), text

textgrid$save(path, format = c("text", "short_text", "binary"))

# Print
textgrid$print()
  # Shows tier structure with counts
```

**C++ Implementation** (`src/textgrid_wrappers.cpp`):

Need to wrap Praat's TextGrid functions:
- `TextGrid_readFromFile()`
- `TextGrid_create()`
- Tier query functions
- Interval/point manipulation functions
- Export functions
- Save functions

**Integration with Sound:**

```r
# Example workflow: Extract segments based on TextGrid
sound <- Sound$new("recording.wav")
tg <- TextGrid$new("recording.TextGrid")

# Get all word intervals
words_df <- tg$as_data_frame(tiers = "words", include_empty = FALSE)

# Extract each word as separate sound file
for (i in 1:nrow(words_df)) {
  word_sound <- sound$extract_part(
    from = words_df$start_time[i],
    to = words_df$end_time[i],
    preserve_times = FALSE
  )
  word_sound$save(paste0("words/", words_df$text[i], "_", i, ".wav"))
}
```

**Testing Requirements:**
- Create test TextGrid files (text format)
- Test reading both text and binary formats
- Test tier management (add, remove, duplicate)
- Test interval operations (insert boundary, set text)
- Test point operations (insert, remove)
- Test export to data.frame
- Test integration with Sound
- Memory leak testing

**Documentation:**
- Complete roxygen2 documentation for TextGrid class
- Vignette: "Working with TextGrid Annotations"
- Examples of forced alignment workflows
- Migration guide from Praat TextGrid scripts

**Deliverable:** Fully functional TextGrid class (35/35 methods) ✅

---

### Phase 3: Manipulation & PSOLA (Weeks 5-6) ⭐⭐

**Goal:** Pitch and duration modification

**Manipulation Object:**

```r
Manipulation$new(sound, pitch_floor, pitch_ceiling)
Manipulation$new(.xptr = ptr)

# Extract components
manipulation$extract_original_sound()  → Sound
manipulation$extract_pulses()  → PointProcess  
manipulation$extract_pitch_tier()  → PitchTier
manipulation$extract_duration_tier()  → DurationTier

# Replace components
manipulation$replace_pitch_tier(pitch_tier)
manipulation$replace_duration_tier(duration_tier)
manipulation$replace_pulses(point_process)

# Synthesize
manipulation$get_resynthesis_overlap_add()  → Sound (PSOLA)
manipulation$get_resynthesis_lpc()  → Sound

# Play (if possible)
manipulation$play()
```

**PitchTier Object:**

```r
PitchTier$new(xmin, xmax)
PitchTier$new(.xptr = ptr)

# Point manipulation
pitch_tier$add_point(time, frequency)
pitch_tier$remove_point(index)
pitch_tier$remove_points_between(from_time, to_time)
pitch_tier$remove_points_below(frequency)
pitch_tier$remove_points_above(frequency)

# Query
pitch_tier$get_value_at_time(time)
pitch_tier$get_number_of_points()

# Modification
pitch_tier$multiply_frequencies(from_time, to_time, factor)
pitch_tier$shift_frequencies(from_time, to_time, shift_hz)
pitch_tier$stylize(num_semitones, from_time, to_time)

# Export
pitch_tier$as_data_frame()
pitch_tier$save(path)
```

**DurationTier Object:**

```r
DurationTier$new(xmin, xmax)
DurationTier$new(.xptr = ptr)

# Point manipulation
duration_tier$add_point(time, duration_factor)
duration_tier$remove_point(index)

# Query
duration_tier$get_value_at_time(time)
duration_tier$get_target_duration(from_time, to_time)

# Export
duration_tier$as_data_frame()
duration_tier$save(path)
```

**Example Workflow:**

```r
# Raise pitch by 20%
sound <- Sound$new("voice.wav")
manip <- Manipulation$new(sound, pitch_floor = 75, pitch_ceiling = 600)

pitch_tier <- manip$extract_pitch_tier()
pitch_tier$multiply_frequencies(0, 0, factor = 1.2)
manip$replace_pitch_tier(pitch_tier)

modified_sound <- manip$get_resynthesis_overlap_add()
modified_sound$save("voice_higher.wav")
```

**Deliverables:**
- Manipulation R6 class ✅
- PitchTier R6 class ✅
- DurationTier R6 class ✅
- Tests and documentation ✅
- Vignette: "Pitch and Duration Manipulation" ✅

---

### Phase 4: Spectral Objects (Weeks 7-8)

**Note:** Spectrogram and Spectrum already have basic `to_*` methods in Sound.
Need to add full query/manipulation methods.

**Goal:** Complete spectral analysis capabilities

**Spectrogram, Spectrum, LPC, Ltas classes** with full methods

---

### Phase 5: Remaining Tier Objects (Weeks 9-10)

**IntensityTier, FormantGrid** with full methods

---

### Phase 6: Polish & Examples (Weeks 11-12)

**Goal:** Production-ready package

1. Re-implement superassp Python examples
2. Comprehensive testing and validation
3. Documentation polish
4. CRAN preparation

---

## Next Immediate Actions

1. ✅ Document OOP strategy (DONE)
2. Expand Sound class (21 new methods)
3. Complete Pitch class (12 new methods)
4. Convert Formant to R6 (15 methods)
5. Convert Intensity to R6 (12 methods)
6. Convert Harmonicity to R6 (10 methods)
7. Implement TextGrid ⭐⭐⭐
8. Implement Manipulation ⭐⭐
9. Complete remaining objects
10. Examples and validation

## Success Metrics

- [ ] 15+ Praat object types as R6 classes
- [ ] 200+ methods total
- [ ] TextGrid fully functional ⭐
- [ ] Manipulation fully functional ⭐
- [ ] Test coverage >90%
- [ ] Zero memory leaks
- [ ] Documentation complete
- [ ] 10+ example workflows
- [ ] CRAN-ready

**Current Progress: ~25% (6 objects partially implemented, 0 complete)**  
**Target: 100% (15+ objects, all with full method coverage)**
