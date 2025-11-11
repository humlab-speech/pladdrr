# Object-Oriented Paradigm Shift Amendment

**Date**: 2025-11-11  
**Status**: Master Amendment - Supersedes Previous Plans  
**Purpose**: Realign package architecture with Praat's native OOP design

## Executive Summary

This amendment fundamentally restructures the `speaker` package approach to **mirror Praat's object-oriented architecture** rather than providing isolated procedural functions. This aligns with how Praat actually works internally and how Python's Parselmouth successfully exposes Praat functionality.

### Core Principle

**Expose Praat OBJECTS with their full METHOD suites, not isolated analysis procedures.**

### Rationale

1. **Praat is Object-Oriented**: Praat's C++ codebase is fundamentally OOP with a deep class hierarchy (Thing → Data → Function → Sampled → Sound/Pitch/Formant/etc.)
2. **Parselmouth Proves the Pattern**: Python's Parselmouth successfully wraps Praat by exposing objects and methods
3. **Current Approach is Incomplete**: The procedural function approach misses:
   - Object persistence and method chaining
   - Inter-object transformations
   - Critical objects like TextGrid, Manipulation, PointProcess
   - The natural Praat workflow
4. **Enable Praat Script Translation**: R code should closely mirror Praat scripts for easy migration

## Problem with Original Specification

### Original Approach (Procedural)

```r
# Isolated functional calls - data copying on each call
pitch_data <- praat_extract_pitch(audio_file, min_pitch = 75, max_pitch = 600)
formant_data <- praat_extract_formant(audio_file, max_formant = 5500)
intensity_data <- praat_extract_intensity(audio_file, min_pitch = 100)
```

**Limitations:**
- Treats Praat like a collection of standalone algorithms
- Ignores object relationships and transformations
- Forces redundant file loading and memory copying
- No access to object methods (only extraction)
- Missing critical functionality (TextGrid annotation, Manipulation, etc.)
- Doesn't reflect how Praat or Parselmouth work

### New Approach (Object-Oriented)

```r
# Object-oriented - mirrors Praat's architecture
sound <- Sound$new("audio.wav")

# Objects persist - transformations create new objects
pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
formant <- sound$to_formant_burg(time_step = 0.01, max_formant_hz = 5500)
intensity <- sound$to_intensity(minimum_pitch = 100)

# Objects have methods
mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")
f0_at_0.5 <- pitch$get_value_at_time(0.5, unit = "hertz")
sd_f0 <- pitch$get_standard_deviation(from_time = 0, to_time = 0, unit = "hertz")

# Query formants
f1 <- formant$get_value_at_time(time = 0.5, formant_number = 1, unit = "hertz")
f2 <- formant$get_mean(formant_number = 2, from_time = 0, to_time = 0.5)

# Export to R when needed
pitch_df <- pitch$as_data_frame()
formant_df <- formant$as_data_frame()
```

## Comparison: Praat Script → Parselmouth → speaker (R)

### Example 1: Basic Pitch Analysis

**Praat Script:**
```praat
sound = Read from file: "audio.wav"
pitch = To Pitch: 0.01, 75, 600
mean_f0 = Get mean: 0, 0, "Hertz"
min_f0 = Get minimum: 0, 0, "Hertz", "Parabolic"
max_f0 = Get maximum: 0, 0, "Hertz", "Parabolic"
```

**Parselmouth (Python):**
```python
import parselmouth as pm

sound = pm.Sound("audio.wav")
pitch = sound.to_pitch(time_step=0.01, pitch_floor=75, pitch_ceiling=600)
mean_f0 = pitch.get_mean(from_time=0, to_time=0, unit="hertz")
min_f0 = pitch.get_minimum(from_time=0, to_time=0, unit="hertz")
max_f0 = pitch.get_maximum(from_time=0, to_time=0, unit="hertz")
```

**speaker (R) - NEW APPROACH:**
```r
sound <- Sound$new("audio.wav")
pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")
min_f0 <- pitch$get_minimum(from_time = 0, to_time = 0, unit = "hertz")
max_f0 <- pitch$get_maximum(from_time = 0, to_time = 0, unit = "hertz")
```

### Example 2: Formant Analysis

**Praat Script:**
```praat
sound = Read from file: "vowel.wav"
formant = To Formant (burg): 0.01, 5, 5500, 0.025, 50
f1 = Get value at time: 1, 0.5, "Hertz", "Linear"
f2 = Get value at time: 2, 0.5, "Hertz", "Linear"
```

**Parselmouth (Python):**
```python
sound = pm.Sound("vowel.wav")
formant = sound.to_formant_burg(time_step=0.01, max_number_of_formants=5, 
                                 maximum_formant=5500, window_length=0.025, 
                                 pre_emphasis_from=50)
f1 = formant.get_value_at_time(formant_number=1, time=0.5)
f2 = formant.get_value_at_time(formant_number=2, time=0.5)
```

**speaker (R) - NEW APPROACH:**
```r
sound <- Sound$new("vowel.wav")
formant <- sound$to_formant_burg(time_step = 0.01, max_number_of_formants = 5,
                                  maximum_formant = 5500, window_length = 0.025,
                                  pre_emphasis_from = 50)
f1 <- formant$get_value_at_time(formant_number = 1, time = 0.5)
f2 <- formant$get_value_at_time(formant_number = 2, time = 0.5)
```

### Example 3: TextGrid Annotation (CRITICAL MISSING FEATURE)

**Praat Script:**
```praat
textgrid = Read from file: "annotation.TextGrid"
num_tiers = Get number of tiers
tier_name = Get tier name: 1
label = Get label of interval: 1, 5
start_time = Get start time of interval: 1, 5
```

**Parselmouth (Python):**
```python
textgrid = pm.read("annotation.TextGrid")
num_tiers = textgrid.get_number_of_tiers()
tier_name = textgrid.get_tier_name(1)
interval = textgrid.get_interval_at_time(tier_number=1, time=0.5)
label = interval.text
```

**speaker (R) - TO BE IMPLEMENTED:**
```r
textgrid <- TextGrid$new("annotation.TextGrid")
num_tiers <- textgrid$get_number_of_tiers()
tier_name <- textgrid$get_tier_name(1)
interval <- textgrid$get_interval_at_time(tier_number = 1, time = 0.5)
label <- interval$text
```

### Example 4: Pitch Manipulation (CRITICAL MISSING FEATURE)

**Praat Script:**
```praat
sound = Read from file: "voice.wav"
manipulation = To Manipulation: 0.01, 75, 600
pitch_tier = Extract pitch tier
Add point: 0.5, 150
Replace pitch tier
resynthesis = Get resynthesis (overlap-add)
Save as WAV file: "modified.wav"
```

**Parselmouth (Python):**
```python
sound = pm.Sound("voice.wav")
manipulation = pm.praat.call(sound, "To Manipulation", 0.01, 75, 600)
pitch_tier = pm.praat.call(manipulation, "Extract pitch tier")
pm.praat.call(pitch_tier, "Add point", 0.5, 150)
pm.praat.call(manipulation, "Replace pitch tier", pitch_tier)
resynthesis = pm.praat.call(manipulation, "Get resynthesis (overlap-add)")
resynthesis.save("modified.wav")
```

**speaker (R) - TO BE IMPLEMENTED:**
```r
sound <- Sound$new("voice.wav")
manipulation <- sound$to_manipulation(time_step = 0.01, 
                                       pitch_floor = 75, pitch_ceiling = 600)
pitch_tier <- manipulation$extract_pitch_tier()
pitch_tier$add_point(time = 0.5, value = 150)
manipulation$replace_pitch_tier(pitch_tier)
resynthesis <- manipulation$get_resynthesis_overlap_add()
resynthesis$save("modified.wav")
```

## Complete Praat Object Hierarchy to Implement

Based on Praat source code analysis and Parselmouth design:

### Tier 1: FOUNDATION (Already Implemented)

1. **Sound** ✅ `R/sound-r6-new.R`
   - Represents sampled audio waveform
   - **Key Methods**: `to_pitch()`, `to_formant_burg()`, `to_intensity()`, `to_spectrum()`, `to_spectrogram()`, `to_manipulation()`
   - **Query Methods**: `get_duration()`, `get_sampling_frequency()`, `get_value_at_time()`, `get_rms()`
   - **Export**: `as_matrix()`, `as_data_frame()`, `save()`

2. **Pitch** ✅ `R/pitch-r6.R`
   - F0 contour representation
   - **Key Methods**: `get_value_at_time()`, `get_mean()`, `get_minimum()`, `get_maximum()`, `get_standard_deviation()`
   - **Transformations**: `to_pitch_tier()`, `to_point_process()`
   - **Export**: `as_data_frame()`

3. **Formant** ✅ `R/formant-r6.R`
   - Formant trajectory representation
   - **Key Methods**: `get_value_at_time()`, `get_bandwidth_at_time()`, `get_mean()`, `get_number_of_formants()`
   - **Export**: `as_data_frame()`

4. **Intensity** ✅ `R/intensity-r6.R`
   - Loudness contour
   - **Key Methods**: `get_value()`, `get_mean()`, `get_minimum()`, `get_maximum()`
   - **Transformations**: `to_intensity_tier()`
   - **Export**: `as_data_frame()`

5. **Spectrogram** ✅ `R/spectrogram-r6.R`
   - Time-frequency representation
   - **Key Methods**: `get_power_at()`, `get_time_from_column()`, `get_frequency_from_row()`

6. **Spectrum** ✅ `R/spectrum-r6.R`
   - Frequency domain representation
   - **Key Methods**: `get_bin_from_frequency()`, `get_real_value_in_bin()`, `get_imaginary_value_in_bin()`

### Tier 2: TIER OBJECTS (Partially Implemented)

7. **PitchTier** ✅ `R/pitchtier-r6.R`
   - Editable F0 points
   - **Methods**: `add_point()`, `remove_point()`, `get_value_at_time()`

8. **IntensityTier** ✅ `R/intensitytier-r6.R`
   - Editable intensity points
   - **Methods**: `add_point()`, `remove_point()`, `get_value_at_time()`

9. **DurationTier** ✅ `R/durationtier-r6.R`
   - Duration modification points
   - **Methods**: `add_point()`, `remove_point()`, `get_value_at_time()`

### Tier 3: CRITICAL MISSING OBJECTS

10. **TextGrid** ❌ NOT IMPLEMENTED
    - **PRIORITY: HIGHEST** - Essential for annotation
    - Multi-tier annotation system
    - **Methods needed**:
      - `get_number_of_tiers()`
      - `get_tier_name(tier_number)`
      - `get_tier(tier_number_or_name)`
      - `get_interval_at_time(tier, time)`
      - `get_number_of_intervals(tier)`
      - `get_label_at_time(tier, time)`
      - `insert_interval_tier(name, position)`
      - `insert_point_tier(name, position)`
    - **Sub-objects**: IntervalTier, PointTier, TextInterval, TextPoint

11. **Manipulation** ✅ `R/manipulation-r6.R` (PARTIAL)
    - **PRIORITY: HIGH** - Required for pitch/duration modification
    - Pitch and duration modification interface
    - **Methods needed** (check implementation completeness):
      - `extract_pitch_tier()`
      - `extract_duration_tier()`
      - `replace_pitch_tier(pitch_tier)`
      - `replace_duration_tier(duration_tier)`
      - `get_resynthesis_overlap_add()`
      - `get_resynthesis_lpc()`

12. **PointProcess** ✅ `R/pointprocess-r6.R` (CHECK COMPLETENESS)
    - Point events in time (glottal pulses, etc.)
    - **Methods to verify**:
      - `get_number_of_points()`
      - `get_time_from_index(index)`
      - `get_interval(from_time, to_time)`
      - `add_point(time)`
      - `remove_point(index)`
      - `to_pitch_tier()`

13. **Harmonicity** ✅ `R/harmonicity.R` (CHECK IF R6 CLASS EXISTS)
    - HNR (Harmonics-to-Noise Ratio) contour
    - **Methods needed**:
      - `get_value()` at time
      - `get_mean()`
      - `get_minimum()`
      - `get_maximum()`

14. **LTAS** ✅ `R/ltas-r6.R`
    - Long-Term Average Spectrum
    - **Methods to verify**:
      - `get_bin_number_from_frequency()`
      - `get_value_at_frequency()`
      - `get_slope()`

### Tier 4: ADVANCED OBJECTS (Future)

15. **FormantGrid** ❌ NOT IMPLEMENTED
    - Editable formant trajectories
    - Methods: `add_formant_point()`, `add_bandwidth_point()`

16. **Sound (MultiChannel)** ⚠️ PARTIAL
    - Multi-channel audio support
    - Methods: `extract_channel()`, `convert_to_mono()`

17. **Cochleagram** ❌ NOT IMPLEMENTED
    - Auditory model representation

18. **Excitation** ❌ NOT IMPLEMENTED
    - Source-filter model

19. **Artword** ❌ NOT IMPLEMENTED
    - Articulatory synthesis

20. **SpeechSynthesizer** ❌ NOT IMPLEMENTED
    - Text-to-speech using Klatt synthesizer

## Naming Convention Alignment

To enable easy Praat script → R translation, we use consistent naming:

### Object Names

- Praat class names translate directly to R6 class names
- `Sound`, `Pitch`, `Formant`, `TextGrid`, `Manipulation`, etc.

### Method Names

Convert Praat's command naming to R's snake_case convention:

| Praat Command | R6 Method |
|--------------|-----------|
| `To Pitch...` | `to_pitch()` |
| `Get mean...` | `get_mean()` |
| `Get value at time...` | `get_value_at_time()` |
| `To Formant (burg)...` | `to_formant_burg()` |
| `Extract pitch tier` | `extract_pitch_tier()` |
| `Get resynthesis (overlap-add)` | `get_resynthesis_overlap_add()` |
| `Add point...` | `add_point()` |
| `Remove point...` | `remove_point()` |
| `Get number of tiers` | `get_number_of_tiers()` |
| `Get tier name...` | `get_tier_name()` |

### Parameter Names

| Praat Parameter | R Parameter |
|----------------|-------------|
| `Time step` | `time_step` |
| `Pitch floor` | `pitch_floor` |
| `Pitch ceiling` | `pitch_ceiling` |
| `Maximum formant` | `maximum_formant` |
| `Number of formants` | `max_number_of_formants` |
| `Window length` | `window_length` |
| `Minimum pitch` | `minimum_pitch` |
| `From time` | `from_time` |
| `To time` | `to_time` |
| `Formant number` | `formant_number` |

## Implementation Roadmap

### Phase 1: Verify and Complete Existing Objects (Week 1)

**Objective**: Ensure all implemented R6 classes have complete method coverage

#### Task 1.1: Audit Existing R6 Classes
- [ ] Review `R/sound-r6-new.R` - verify all transformation methods
- [ ] Review `R/pitch-r6.R` - verify all query and transform methods
- [ ] Review `R/formant-r6.R` - verify completeness
- [ ] Review `R/intensity-r6.R` - verify completeness
- [ ] Review `R/spectrogram-r6.R` - verify completeness
- [ ] Review `R/spectrum-r6.R` - verify completeness
- [ ] Review `R/manipulation-r6.R` - **CRITICAL** - verify transformation methods
- [ ] Review `R/pointprocess-r6.R` - verify completeness
- [ ] Review `R/ltas-r6.R` - verify completeness

#### Task 1.2: Complete Missing Methods
For each object, compare against Praat source and Parselmouth to identify missing methods:
- Query methods (getters)
- Statistical methods (mean, min, max, stdev, etc.)
- Transformation methods (to_X)
- Modification methods (for tier objects)
- Export methods (as_data_frame, as_matrix)

#### Task 1.3: Add Corresponding C++ Bindings
- Update `src/pitch.cpp`, `src/formant.cpp`, etc. with missing method wrappers
- Update `R/RcppExports.R` via `Rcpp::compileAttributes()`

### Phase 2: Implement TextGrid (Week 2) ⭐ HIGHEST PRIORITY

**Objective**: Implement full TextGrid support for annotation

#### Task 2.1: Create TextGrid R6 Class
- [ ] Create `R/textgrid-r6.R`
- [ ] Implement initialization: `TextGrid$new(path)` to read from file
- [ ] Implement tier query methods:
  - `get_number_of_tiers()`
  - `get_tier_name(tier_number)`
  - `get_tier(tier_number_or_name)` returns IntervalTier or PointTier object
- [ ] Implement interval query methods:
  - `get_interval_at_time(tier, time)`
  - `get_number_of_intervals(tier)`
  - `get_start_time(tier, interval_number)`
  - `get_end_time(tier, interval_number)`
  - `get_label(tier, interval_number)`
- [ ] Implement tier creation methods:
  - `insert_interval_tier(name, position = NULL)`
  - `insert_point_tier(name, position = NULL)`
- [ ] Implement export: `as_data_frame()`, `save(path)`

#### Task 2.2: Create IntervalTier R6 Class
- [ ] Create `R/intervaltier-r6.R`
- [ ] Methods:
  - `get_number_of_intervals()`
  - `get_interval(index)` returns TextInterval
  - `get_interval_at_time(time)` returns TextInterval
  - `add_boundary(time)`
  - `remove_boundary(time)`

#### Task 2.3: Create TextInterval R6 Class
- [ ] Create `R/textinterval-r6.R`
- [ ] Fields: `xmin`, `xmax`, `text`
- [ ] Methods: `get_duration()`

#### Task 2.4: Create C++ Bindings
- [ ] Create `src/textgrid.cpp` with Praat TextGrid integration
- [ ] Wrap TextGrid reading from file
- [ ] Wrap tier access methods
- [ ] Wrap interval access methods
- [ ] Handle both IntervalTier and PointTier (polymorphism)

#### Task 2.5: Documentation and Tests
- [ ] Document TextGrid class with examples
- [ ] Create comprehensive tests in `tests/testthat/test-textgrid.R`
- [ ] Test reading standard Praat TextGrid files
- [ ] Test tier access, interval access, label extraction
- [ ] Compare results with Praat desktop application

### Phase 3: Complete Manipulation Object (Week 3)

**Objective**: Enable pitch and duration modification workflows

#### Task 3.1: Verify Manipulation Implementation
- [ ] Review `R/manipulation-r6.R`
- [ ] Ensure all methods are implemented:
  - `extract_pitch_tier()`
  - `extract_duration_tier()`
  - `replace_pitch_tier(pitch_tier)`
  - `replace_duration_tier(duration_tier)`
  - `get_resynthesis_overlap_add()`

#### Task 3.2: Add Missing Methods (if any)
- [ ] Implement any missing transformation methods
- [ ] Add corresponding C++ bindings in `src/manipulation.cpp`

#### Task 3.3: Test Manipulation Workflows
- [ ] Test pitch modification pipeline
- [ ] Test duration modification pipeline
- [ ] Compare resynthesis output with Praat
- [ ] Document pitch/duration modification workflows

### Phase 4: Enhance Documentation (Week 4)

**Objective**: Provide clear migration guides

#### Task 4.1: Create Migration Guides
- [ ] Create `vignettes/praat-script-to-r.Rmd`
  - Common Praat script patterns
  - Equivalent R code
  - Side-by-side comparisons
- [ ] Create `vignettes/parselmouth-to-speaker.Rmd`
  - Python Parselmouth code
  - Equivalent R speaker code
  - Migration examples

#### Task 4.2: Create Object Method Reference
- [ ] Document all R6 classes comprehensively
- [ ] Cross-reference with Praat command equivalents
- [ ] Provide method-level examples

#### Task 4.3: Create Workflow Examples
- [ ] Basic phonetic analysis workflows
- [ ] Vowel formant analysis
- [ ] Pitch analysis and visualization
- [ ] TextGrid-based annotation workflows
- [ ] Pitch manipulation for speech synthesis

### Phase 5: Implement Parselmouth Examples in R (Week 5)

**Objective**: Re-implement `/Users/frkkan96/Documents/src/superassp/inst/python` examples

#### Task 5.1: Create Examples Directory
- [ ] Create `inst/examples/` directory structure
- [ ] Organize by analysis type

#### Task 5.2: Port Python Examples
For each Python file using Parselmouth:
- [ ] `praat_intensity.py` → `inst/examples/intensity_analysis.R`
- [ ] `praat_formantpath_burg.py` → `inst/examples/formant_analysis.R`
- [ ] `praat_dsi_memory.py` → `inst/examples/dsi_calculation.R`
- [ ] `praat_voice_tremor_memory.py` → `inst/examples/voice_tremor.R`
- [ ] `praat_sauce_memory.py` → `inst/examples/sauce_features.R`
- [ ] `praat_avqi_memory.py` → `inst/examples/avqi_analysis.R`
- [ ] `tremor_analysis.py` → `inst/examples/tremor_analysis.R`

#### Task 5.3: Document Ported Examples
- [ ] Add header comments explaining the original Python version
- [ ] Document any differences in approach
- [ ] Provide usage examples

## Success Criteria

1. ✅ **Object Completeness**: All critical Praat objects have R6 implementations
2. ✅ **Method Coverage**: Each object has >80% of commonly used methods
3. ✅ **Naming Consistency**: Method names follow predictable Praat → R convention
4. ✅ **TextGrid Support**: Full annotation capabilities matching Praat
5. ✅ **Manipulation Support**: Complete pitch/duration modification workflows
6. ✅ **Migration Guides**: Clear documentation for Praat script → R translation
7. ✅ **Example Parity**: All Parselmouth examples have R equivalents
8. ✅ **No Python Dependency**: All workflows achievable in pure R

## Continuous Integration Note

Document in `CLAUDE.md`:

```markdown
## OOP Architecture Decision (2025-11-11)

The speaker package follows Praat's native object-oriented architecture:

1. **R6 Classes**: Each Praat object type (Sound, Pitch, Formant, TextGrid, etc.) 
   is an R6 class backed by an external pointer to a persistent C++ Praat object

2. **Method Naming**: Praat commands translate to snake_case methods
   - `To Pitch...` → `to_pitch()`
   - `Get mean...` → `get_mean()`
   - `Get value at time...` → `get_value_at_time()`

3. **Object Relationships**: Objects create other objects via transformation methods
   - `sound$to_pitch()` → returns Pitch object
   - `sound$to_formant_burg()` → returns Formant object
   - `manipulation$extract_pitch_tier()` → returns PitchTier object

4. **Priority Objects**:
   - Tier 1 (Foundation): Sound, Pitch, Formant, Intensity, Spectrum, Spectrogram
   - Tier 2 (Tiers): PitchTier, IntensityTier, DurationTier
   - Tier 3 (Critical): **TextGrid** (annotation), **Manipulation** (modification)

5. **Future Extensions**:
   - Additional objects: FormantGrid, Cochleagram, Excitation
   - Script interpreter for running unmodified Praat scripts
   - Picture/plotting functionality (Praat's graphics system)
```

## Next Steps

1. **Audit existing R6 classes** for method completeness (Phase 1)
2. **Implement TextGrid** (highest priority missing object) (Phase 2)
3. **Verify Manipulation** completeness (Phase 3)
4. **Create migration guides** (Phase 4)
5. **Port Parselmouth examples** to demonstrate parity (Phase 5)

---

**This amendment supersedes all previous implementation plans and establishes the OOP paradigm as the foundational architecture.**
