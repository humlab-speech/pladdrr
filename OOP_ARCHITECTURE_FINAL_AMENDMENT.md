# Object-Oriented Architecture Amendment - Final Plan
**Date**: 2025-11-11  
**Status**: Master Amendment for OOP-First Approach  
**Purpose**: Align R package architecture with Praat's native OOP structure

## Executive Summary

This amendment fundamentally reorients the `speaker` package from a **procedural/functional approach** to an **object-oriented approach** that mirrors Praat's native C++ class hierarchy. The goal is to enable R users to write code that closely resembles Praat script syntax, similar to how Python's Parselmouth library achieved this.

### Key Insight from Parselmouth

The Python Parselmouth library successfully wraps Praat functionality by:
1. **Exposing Praat objects as Python objects** (Sound, Pitch, Formant, etc.)
2. **Mapping Praat methods to object methods** (sound.to_pitch(), pitch.get_mean(), etc.)
3. **Allowing method chaining** that mirrors Praat workflows
4. **Using the `call()` function** for Praat commands not yet wrapped

Example Parselmouth code:
```python
import parselmouth

# Load sound - creates Sound object
sound = parselmouth.Sound("audio.wav")

# Object methods mirror Praat commands
pitch = sound.to_pitch()
mean_f0 = pitch.get_mean()

# Advanced: use call() for unwrapped functionality
filtered = parselmouth.praat.call(sound, "Filter (stop Hann band)", 0, 34, 0.1)
```

### Current State vs. Desired State

**Current Approach** (Procedural - ❌ Not aligned with Praat):
```r
# Functions operate on file paths or raw data
pitch <- extract_pitch("audio.wav", time_step = 0.01)
mean_f0 <- get_pitch_mean(pitch)
```

**Desired Approach** (OOP - ✅ Aligned with Praat):
```r
# R6 objects mirror Praat objects
sound <- Sound$new("audio.wav")
pitch <- sound$to_pitch(time_step = 0.01)
mean_f0 <- pitch$get_mean()

# Method chaining
intensity <- sound$to_intensity()$smooth(50)

# Integration
formants <- sound$to_formant_burg(time_step = 0.01, max_formant = 5000)
```

## Current Implementation Status

### ✅ Already Implemented (OOP-First)

The package has **already transitioned to R6 OOP** for core objects:

1. **Sound** (`R/sound-r6-new.R`) - ~60 methods
   - File I/O: `Sound$new(path)`, `$save(path)`
   - Queries: `$get_duration()`, `$get_sampling_frequency()`, `$get_value_at_time()`
   - Transformations: `$to_pitch()`, `$to_formant_burg()`, `$to_intensity()`, `$to_harmonicity_cc()`
   - Export: `$as_data_frame()`, `$as_matrix()`

2. **Pitch** (`R/pitch-r6.R`) - ~35 methods
   - Queries: `$get_value_at_time()`, `$get_mean()`, `$get_minimum()`, `$get_maximum()`
   - Statistics: `$get_standard_deviation()`, `$get_quantile()`
   - Export: `$as_data_frame()`, `$to_pitch_tier()`

3. **Formant** (`R/formant-r6.R`) - ~25 methods
   - Queries: `$get_value_at_time()`, `$get_bandwidth_at_time()`
   - Statistics: `$get_mean()`, `$get_standard_deviation()`
   - Multi-formant queries: `$get_values_at_time()` returns all formants

4. **Intensity** (`R/intensity-r6.R`) - ~20 methods
   - Queries: `$get_value_at_time()`, `$get_mean()`, `$get_minimum()`, `$get_maximum()`
   - Statistics: `$get_standard_deviation()`, `$get_quantile()`

5. **Harmonicity** (`R/harmonicity.R`) - ~15 methods
   - HNR queries: `$get_value_at_time()`, `$get_mean()`

6. **TextGrid** (`R/textgrid-r6.R`) - ~50 methods
   - Tier queries: `$get_number_of_tiers()`, `$get_tier_names()`
   - IntervalTier: `$get_number_of_intervals()`, `$get_interval_text()`, `$insert_boundary()`
   - PointTier: `$get_number_of_points()`, `$insert_point()`
   - Export: `$as_data_frame()`

7. **Spectrogram** (`R/spectrogram-r6.R`) - ~20 methods
   - Queries: `$get_power_at()`, `$get_time_from_column()`, `$get_frequency_from_row()`

8. **Spectrum** (`R/spectrum-r6.R`) - ~18 methods
   - Queries: `$get_power_at()`, `$get_band_energy()`

9. **Ltas** (`R/ltas-r6.R`) - ~15 methods
   - Queries: `$get_value_at_frequency()`, `$get_slope()`
   - Statistics: `$get_mean()`, `$get_minimum()`, `$get_maximum()`

10. **Manipulation** (`R/manipulation-r6.R`) - ~15 methods
    - Extract/replace: `$extract_duration_tier()`, `$extract_pitch_tier()`, `$replace_pitch_tier()`
    - Synthesis: `$get_resynthesis_lpc()`, `$get_resynthesis_overlap_add()`

11. **PitchTier** (`R/pitchtier-r6.R`) - ~15 methods
    - Point manipulation: `$add_point()`, `$remove_point()`
    - Transformations: `$multiply_frequencies()`, `$shift_frequencies()`

12. **DurationTier** (`R/durationtier-r6.R`) - ~12 methods
    - Point manipulation: `$add_point()`, `$remove_point()`

13. **IntensityTier** (`R/intensitytier-r6.R`) - ~12 methods
    - Point manipulation: `$add_point()`, `$remove_point()`

14. **PointProcess** (`R/pointprocess-r6.R`) - ~20 methods
    - Voice analysis: `$get_jitter_local()`, `$get_shimmer_local()`

### ❌ Not Yet Implemented

Objects that exist in Praat but are not yet wrapped:

**Priority 1 - Core Analysis:**
- **FormantGrid** - Manipulable formant contours (for resynthesis)
- **FormantTier** - Single formant trajectory
- **Excitation** - Source spectrum for speech
- **LPC** - Linear predictive coding analysis
- **PowerCepstrogram** - Cepstral analysis (for CPPS)
- **MelFilter** - Mel-scale filtering

**Priority 2 - Advanced Features:**
- **Cochleagram** - Auditory model representation
- **VocalTract** - Articulatory synthesis
- **SpeechSynthesizer** - Text-to-speech
- **WordList**, **SpellingChecker** - Linguistic tools

**Priority 3 - Specialized:**
- **Photo** - Image processing
- **Polygon** - Shape representation
- **OTGrammar** - Optimality theory
- **Network** - Neural network models

## Naming Convention Strategy

### Principle: Mirror Praat Script Syntax

Praat scripts use commands like:
```praat
selectObject: "Sound mysound"
To Pitch... 0 75 600
mean = Get mean... 0 0 Hertz
```

Our R package should allow:
```r
sound <- Sound$new("mysound.wav")
pitch <- sound$to_pitch(pitch_floor = 75, pitch_ceiling = 600)
mean <- pitch$get_mean(unit = "Hertz")
```

### Method Naming Rules

1. **Transformation methods** - Create new objects
   - Format: `to_<object_type>()`
   - Examples: `to_pitch()`, `to_formant_burg()`, `to_intensity()`, `to_spectrogram()`
   - Praat equivalent: "To Pitch...", "To Formant (burg)..."

2. **Query methods** - Return scalar/vector values
   - Format: `get_<property>()`
   - Examples: `get_mean()`, `get_value_at_time()`, `get_number_of_intervals()`
   - Praat equivalent: "Get mean...", "Get value at time..."

3. **Modification methods** - Change object in place (rare, prefer immutability)
   - Format: `set_<property>()` or `<verb>_<object>()`
   - Examples: `set_interval_text()`, `insert_boundary()`, `add_point()`
   - Praat equivalent: "Set interval text...", "Insert boundary..."

4. **Creation methods** - Static constructors
   - Format: `create_<type>()` or `from_<source>()`
   - Examples: `Sound$create_tone()`, `Sound$from_matrix()`
   - Praat equivalent: "Create Sound from formula..."

5. **Export methods** - Convert to R structures
   - Format: `as_<format>()` or `to_<r_type>()`
   - Examples: `as_data_frame()`, `as_matrix()`
   - These are R-specific, no Praat equivalent

### Consistency with Praat Method Names

| Praat Command | R Method | Object |
|---------------|----------|--------|
| To Pitch... | `to_pitch()` | Sound |
| To Formant (burg)... | `to_formant_burg()` | Sound |
| To Intensity... | `to_intensity()` | Sound |
| To TextGrid (silences)... | `to_textgrid_silences()` | Sound |
| Get mean... | `get_mean()` | Pitch, Formant, Intensity |
| Get value at time... | `get_value_at_time()` | Pitch, Formant, Intensity |
| Get number of intervals... | `get_number_of_intervals()` | TextGrid |
| Set interval text... | `set_interval_text()` | TextGrid |
| Insert boundary... | `insert_boundary()` | TextGrid |
| Extract part... | `extract_part()` | Sound, TextGrid |
| Concatenate | `concatenate()` | Sound (static) |
| Filter (stop Hann band)... | `filter_stop_hann_band()` | Sound |

### Parameter Naming

Use snake_case for parameters, matching common R conventions:
- `time_step` (not `timeStep` or `dt`)
- `pitch_floor`, `pitch_ceiling` (not `minimumPitch`, `maximumPitch`)
- `max_formant` (not `maximumFormant`)
- `window_length` (not `windowLength`)

## Implementation Roadmap

### Phase 1: Complete Core Objects ✅ (DONE)

Already implemented:
- Sound, Pitch, Formant, Intensity, Harmonicity
- TextGrid with full tier manipulation
- Spectrogram, Spectrum, Ltas
- Manipulation, PitchTier, DurationTier, IntensityTier
- PointProcess

### Phase 2: Add Missing Essential Objects (IN PROGRESS)

**2.1 FormantGrid & FormantTier** (Week 1)
- Wrapper: `src/formantgrid_wrappers.cpp`
- R6 class: `R/formantgrid-r6.R`
- Methods: ~20 (tier management, formant manipulation)
- **Enables**: Formant manipulation and resynthesis

**2.2 PowerCepstrogram** (Week 1)
- Wrapper: `src/powercepstrogram_wrappers.cpp`
- R6 class: `R/powercepstrogram-r6.R`
- Methods: ~15 (CPPS calculation, cepstral queries)
- **Enables**: Voice quality assessment (AVQI, etc.)

**2.3 LPC** (Week 2)
- Wrapper: `src/lpc_wrappers.cpp` (expand stub)
- R6 class: `R/lpc-r6.R`
- Methods: ~12 (to_formant, to_spectrum, coefficients)
- **Enables**: Alternative formant extraction

### Phase 3: Enable Parselmouth-Style Examples (Week 2-3)

Port Python examples from `/Users/frkkan96/Documents/src/superassp/inst/python/` to R:

**3.1 AVQI (avqi_3.01.py)**
- Requires: Sound, PowerCepstrogram, Ltas, PointProcess
- Creates: `inst/examples/avqi_calculation.R`
- Demonstrates: Complex analysis pipeline

**3.2 Voice Quality Metrics**
- Jitter/shimmer calculations (using PointProcess)
- HNR analysis (using Harmonicity)
- Creates: `inst/examples/voice_quality.R`

**3.3 Prosody Modification**
- Pitch manipulation (using Manipulation, PitchTier)
- Duration modification (using DurationTier)
- Creates: `inst/examples/prosody_modification.R`

### Phase 4: TextGrid Validation & Benchmarking (Week 3)

Using new benchmark files:
- `inst/extdata/benchmarkdata60min.TextGrid` (60 min, 77 MB)
- `inst/extdata/benchmarkdata90min.TextGrid` (90 min, 115 MB)

**4.1 Performance Testing**
- Load time benchmarks
- Memory usage profiling
- Interval query speed tests
- Creates: `tests/testthat/test-textgrid-benchmark.R`

**4.2 Validation Testing**
- Compare with Praat output
- Test complex tier structures
- Verify boundary precision
- Creates: `tests/testthat/test-textgrid-validation.R`

### Phase 5: Documentation & Vignettes (Week 4)

**5.1 Object-Oriented Workflow Vignette**
- Shows OOP approach vs. procedural
- Demonstrates method chaining
- Explains object lifecycle
- Creates: `vignettes/oop-workflow.Rmd`

**5.2 Praat Script Translation Guide**
- Side-by-side Praat vs. R code
- Common patterns and idioms
- Creates: `vignettes/praat-to-r.Rmd`

**5.3 Complete Method Reference**
- Auto-generated from R6 classes
- Organized by object type
- Cross-references to Praat docs
- Updates: All `man/*.Rd` files

## Integration with External Code

### Python Parselmouth Examples

Re-implement examples from `/Users/frkkan96/Documents/src/superassp/inst/python/`:

**Example: avqi_3.01.py** (Acoustic Voice Quality Index)

Python (Parselmouth):
```python
import parselmouth
from parselmouth.praat import call

# Load and concatenate
sv = parselmouth.Sound("vowel.wav")
cs = parselmouth.Sound("speech.wav")

# Filter
cs2 = call(cs, "Filter (stop Hann band)", 0, 34, 0.1)

# Extract voiced segments
textgrid = call(cs2, "To TextGrid (silences)", 50, 0.003, -25, 0.1, 0.1, "silence", "sounding")
intervals = call([cs2, textgrid], "Extract intervals where", 1, False, "does not contain", "silence")

# Compute CPPS
cpps = call(intervals.to_power_cepstrogram(), "Get CPPS", False, 0.01, 0.001, 60, 330, 0.05)
```

R (speaker package):
```r
library(speaker)

# Load and concatenate
sv <- Sound$new("vowel.wav")
cs <- Sound$new("speech.wav")

# Filter
cs2 <- cs$filter_stop_hann_band(from_freq = 0, to_freq = 34, smoothing = 0.1)

# Extract voiced segments
textgrid <- cs2$to_textgrid_silences(
  min_pitch = 50,
  time_step = 0.003,
  silence_threshold = -25,
  min_silent_interval = 0.1,
  min_sounding_interval = 0.1,
  silent_label = "silence",
  sounding_label = "sounding"
)

intervals <- cs2$extract_intervals_where(
  textgrid = textgrid,
  tier = 1,
  condition = "does not contain",
  text = "silence"
)

# Compute CPPS
cepstrogram <- intervals$to_power_cepstrogram()
cpps <- cepstrogram$get_cpps(
  subtract_trend_before = FALSE,
  time_step = 0.01,
  quefrency_step = 0.001,
  pitch_floor = 60,
  pitch_ceiling = 330,
  peak_search_range = 0.05
)
```

## Future Extensions (Not in Current Scope)

### Praat Script Interpreter

To enable running **unmodified Praat scripts** directly from R:

```r
# Future capability (not yet implemented)
praat_eval('
  selectObject: "Sound mysound"
  To Pitch... 0 75 600
  mean = Get mean... 0 0 Hertz
')
```

**Requirements**:
- Parse Praat script syntax
- Map to R6 object methods
- Handle Praat object selection model
- **Status**: Deferred to future version

### Praat Picture System

To enable plotting capabilities:

```r
# Future capability (not yet implemented)
pitch$draw(from_time = 0, to_time = 1)
spectrogram$paint(dynamic_range = 50)
```

**Requirements**:
- Wrap Praat's Picture/Graphics system
- Convert to R grid/ggplot2 graphics
- **Status**: Deferred to future version

## Documentation Strategy

### CLAUDE.md Updates

Document key architectural decisions in `CLAUDE.md`:

```markdown
## Object-Oriented Architecture (2025-11-11)

The speaker package follows Praat's native OOP structure:
- Each Praat object type → R6 class
- Praat methods → R6 public methods
- Naming convention: snake_case, mirrors Praat commands
- Method prefixes: to_*(), get_*(), set_*(), create_*()

### Adding New Objects

1. Create wrapper in src/<object>_wrappers.cpp
2. Create R6 class in R/<object>-r6.R
3. Follow naming conventions (see OOP_ARCHITECTURE_FINAL_AMENDMENT.md)
4. Add examples to inst/examples/
5. Update method reference in man/

### Method Naming

- to_*(): Create new object (Sound$to_pitch())
- get_*(): Query value (pitch$get_mean())
- set_*(): Modify in-place (textgrid$set_interval_text())
- create_*(): Static constructor (Sound$create_tone())
- as_*(): Export to R (sound$as_data_frame())
```

## Success Criteria

1. **✅ Code Resemblance**: R code closely mirrors Praat script syntax
2. **✅ Object Completeness**: All major Praat objects have R6 wrappers
3. **✅ Method Consistency**: Naming follows clear conventions
4. **✅ Example Coverage**: Python Parselmouth examples successfully ported
5. **✅ Documentation Quality**: Clear vignettes explaining OOP approach
6. **✅ Performance**: Large TextGrids load and query efficiently

## Next Steps (Immediate)

1. **Test benchmark TextGrids** - Validate complex file handling
2. **Implement FormantGrid** - Complete manipulation support
3. **Implement PowerCepstrogram** - Enable AVQI calculations
4. **Port AVQI example** - Demonstrate complete workflow
5. **Update CLAUDE.md** - Document OOP decisions
6. **Create examples directory** - `inst/examples/` with ported Python code

## Conclusion

This amendment transforms the speaker package from a collection of utility functions to a **true object-oriented interface to Praat**, enabling R users to write code that is nearly identical to Praat scripts while leveraging R's data manipulation and visualization capabilities.

The key innovation is recognizing that **Praat is inherently object-oriented**, and our R interface should reflect this rather than flatten it into procedural functions.
