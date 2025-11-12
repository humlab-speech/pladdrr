# OOP Architecture Reassessment and Amendment
## Date: 2025-11-12
## Package: speaker v0.4.0

---

## Executive Summary

After reviewing the **speckit plan**, **current implementation**, and **Parselmouth Python code**, I've identified a critical architectural mismatch:

### The Problem

**Original Spec Approach**: Procedure-focused
- Spec-kit focused on implementing specific procedures (e.g., "implement pitch tracking", "implement formant extraction")
- Treated Praat as a collection of functions rather than objects
- Did not fully embrace the object-oriented nature of Praat's C++ codebase

**What Was Actually Built**: Object-oriented (✅ CORRECT)
- The implementation correctly shifted to R6 classes wrapping Praat C++ objects
- Sound, Pitch, Formant, etc. are proper objects with methods
- Mirrors Parselmouth's approach but WITHOUT Python interpreter overhead

**The Gap**: Incomplete object coverage
- Only 13/19 core Praat objects implemented
- Many objects missing methods available in Praat
- No systematic mapping from Praat's object hierarchy to R6 classes

---

## Comparison: Parselmouth vs. Current speaker Implementation

### Parselmouth (Python) Approach

```python
import parselmouth as pm

# Load sound
sound = pm.Sound("file.wav")

# Extract pitch - uses praat.call() wrapper
pitch = pm.praat.call(sound, "To Pitch", 0.01, 75, 600)
mean_f0 = pm.praat.call(pitch, "Get mean", 0, 0, "Hertz")

# Extract formants
formant = pm.praat.call(sound, "To Formant (burg)", 0.0, 5, 5500, 0.025, 50)
f1 = pm.praat.call(formant, "Get value at time", 1, 0.5, "hertz", "Linear")
```

**Parselmouth characteristics**:
- `praat.call()` is a generic dispatcher to Praat commands
- Every Praat command accessed through string name
- Returns Python objects wrapping Praat C++ objects
- Must know exact Praat command names
- No IDE autocomplete for Praat methods
- Requires Praat scripting knowledge

### speaker (R) Approach (BETTER)

```r
library(speaker)

# Load sound
sound <- Sound$new("file.wav")

# Extract pitch - direct R6 method
pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")

# Extract formants
formant <- sound$to_formant_burg(
  time_step = 0.0,
  max_number_of_formants = 5,
  maximum_formant = 5500,
  window_length = 0.025,
  pre_emphasis_from = 50
)
f1 <- formant$get_value_at_time(formant_number = 1, time = 0.5, unit = "hertz")
```

**speaker characteristics**:
- ✅ Direct R6 method calls (no string command dispatcher)
- ✅ Type-safe method signatures
- ✅ RStudio autocomplete works
- ✅ Self-documenting code (method names are descriptive)
- ✅ R-style parameter naming (snake_case)
- ✅ Direct C++ binding (no Python interpreter)
- ✅ Can transcribe Praat scripts to R with systematic mapping

---

## Why This Matters: Praat Code Transcoding

### The User's Goal

> "We want to allow R versions of code in the praat language, but without going through python, if possible."

### Current State: Partially Achievable

**Praat Script**:
```praat
# Load sound
sound = Read from file: "audio.wav"

# Extract pitch
pitch = To Pitch: 0.01, 75, 600
meanF0 = Get mean: 0, 0, "Hertz"

# Extract formants
selectObject: sound
formant = To Formant (burg): 0.0, 5, 5500, 0.025, 50
f1 = Get value at time: 1, 0.5, "Hertz", "Linear"
```

**R Transcoding** (with complete implementation):
```r
# Load sound
sound <- Sound$new("audio.wav")

# Extract pitch
pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")

# Extract formants
formant <- sound$to_formant_burg(
  time_step = 0.0,
  max_number_of_formants = 5,
  maximum_formant = 5500,
  window_length = 0.025,
  pre_emphasis_from = 50
)
f1 <- formant$get_value_at_time(formant_number = 1, time = 0.5, unit = "hertz")
```

**Systematic Mapping Rules**:

| Praat Pattern | R Pattern | Example |
|---------------|-----------|---------|
| `Read from file: "path"` | `Object$new("path")` | `Sound$new("audio.wav")` |
| `To X: params` | `$to_x(params)` | `$to_pitch()` |
| `Get X: params` | `$get_x(params)` | `$get_mean()` |
| `Set X: params` | `$set_x(params)` | `$set_label()` |
| `Extract X` | `$extract_x()` | `$extract_part()` |
| `Modify X: params` | `$modify_x(params)` | `$scale_intensity()` |

This **systematic 1:1 mapping** is only possible with a complete object-oriented implementation.

---

## Praat's Object-Oriented Architecture

### Core Object Hierarchy in Praat C++

```
Thing (base class)
├── Data
│   └── Function
│       ├── Sampled (time-sampled data)
│       │   ├── Sound             ✅ Implemented
│       │   ├── Pitch             ✅ Implemented
│       │   ├── Formant           ✅ Implemented
│       │   ├── Intensity         ✅ Implemented
│       │   ├── Harmonicity       ✅ Implemented
│       │   ├── PointProcess      ✅ Implemented
│       │   ├── Spectrogram       ✅ Implemented
│       │   ├── Spectrum          ✅ Implemented
│       │   ├── Ltas              ✅ Implemented
│       │   ├── LPC               ⚠️ Stubbed (incomplete)
│       │   ├── FormantPath       ❌ Not implemented
│       │   └── Cochleagram       ❌ Not implemented
│       ├── RealTier (modifiable time-value pairs)
│       │   ├── PitchTier         ✅ Implemented
│       │   ├── IntensityTier     ✅ Implemented
│       │   ├── DurationTier      ✅ Implemented
│       │   └── AmplitudeTier     ❌ Not implemented
│       ├── FormantGrid           ❌ Not implemented (complex tier)
│       └── TextGrid              🚧 80% complete
├── Manipulation                  ✅ Implemented (PSOLA pitch/duration mod)
├── Matrix                        ❌ Not implemented
├── Table                         ❌ Not implemented
└── Collection                    ❌ Not implemented
```

**Implementation Status**:
- ✅ Fully working: 13 objects
- 🚧 Partially working: 1 object (TextGrid)
- ⚠️ Stubbed: 1 object (LPC)
- ❌ Not started: 9 objects

---

## What the Parselmouth Code Reveals

### Analysis of `/Users/frkkan96/Documents/src/superassp/inst/python/praat_*.py`

I analyzed the Parselmouth-based Python implementations in superassp. Key findings:

#### 1. Heavy Use of `pm.praat.call()` for Object Methods

**Example from `praat_formant_burg.py`**:
```python
# Create Sound object
snd = pm.Sound(soundFile)

# Extract Formant object
form = snd.to_formant_burg(...)

# Track formants (Praat method call)
form = pm.praat.call(form, "Track", 
                     number_of_tracks, 
                     reference_F1, reference_F2, ...)

# Convert to Table (another Praat object)
formantTable = pm.praat.call(form, "Down to Table", True, True, 10, True, 3, True, 3, True)

# Get number of rows
nFormantRows = pm.praat.call(formantTable, "Get number of rows")
```

**What this shows**:
- Parselmouth wraps basic conversions (e.g., `to_formant_burg()`)
- BUT uses string-based `praat.call()` for many object methods
- Proof that many Praat object methods are NOT wrapped in Parselmouth
- Users must know exact Praat command names

#### 2. Object Chaining Patterns

**Example from `praat_voice_report_memory.py`**:
```python
# Sound → PointProcess (pulses) → VoiceReport
snd = pm.Sound(sound_array, sampling_frequency=sr)
pulses = pm.praat.call(snd, "To PointProcess (periodic, cc)", 
                       pitch_floor, pitch_ceiling)
voice_report = pm.praat.call([snd, pulses], "Voice report", 
                             time_range_start, time_range_end, ...)
```

**What this shows**:
- Praat operations often require multiple objects as input
- Objects must be properly chained
- speaker needs to support these multi-object operations

#### 3. Praat Objects Used in superassp

From analyzing all `praat_*.py` files:

| Object | Methods Used | R Implementation Status |
|--------|--------------|-------------------------|
| **Sound** | Load, extract, resample, filter, pre-emphasize | ✅ Complete |
| **Pitch** | Get mean, min, max, std dev, quantiles | ✅ Complete |
| **Formant** | Get values, Track (path tracking), Down to Table | ⚠️ Missing: Track, Down to Table |
| **FormantPath** | Extract candidates, optimize | ❌ Not implemented |
| **Intensity** | Get values, statistics | ✅ Complete |
| **PointProcess** | Jitter, shimmer, all voice quality metrics | ✅ Complete |
| **Harmonicity** | HNR values | ✅ Complete |
| **Spectrogram** | Get power, slices | ✅ Complete |
| **Spectrum** | Get power, COG, spectral moments | ✅ Complete |
| **Table** | Create, query rows, get/set values | ❌ Not implemented |

---

## Amended Architecture Plan

### Goal: Complete Object-Oriented Praat Access in R

**Principles**:
1. **Object-first, not function-first**: Implement Praat objects with their full method sets
2. **1:1 Praat command mapping**: Every Praat command should have a corresponding R6 method
3. **Systematic naming**: Consistent translation from Praat command names to R method names
4. **Self-documenting**: Method names and parameters should be self-explanatory
5. **No Python dependency**: Direct R ↔ C++ binding only

### Implementation Phases

#### **Phase 1: Complete Existing Objects** (Priority: HIGH)

**1.1 TextGrid (80% → 100%)**
- Add missing tier management methods:
  - `insert_tier()`, `remove_tier()`, `duplicate_tier()`
  - `rename_tier()`, `set_tier_name()`
- Add `extract_part()` method
- Complete test coverage for complex TextGrids

**1.2 Formant - Add Missing Methods**
- `track()` - formant tracking/path optimization
- `down_to_table()` - export to Praat Table object
- `to_formant_tier()` - convert to FormantTier

**1.3 LPC - Complete Implementation**
Currently stubbed. Needs:
- `to_formant()` - LPC → Formant conversion
- `to_spectrum()` - LPC → Spectrum conversion
- `get_coefficients()` - access LPC coefficients
- `to_matrix()` - export coefficients as Matrix

#### **Phase 2: Critical Missing Objects** (Priority: HIGH)

**2.1 FormantPath** (Modern formant tracking)
Priority: ⭐⭐⭐

Why critical:
- Modern alternative to classic Burg method
- Better tracking of formant trajectories
- Used in latest Praat versions

Methods needed (~15):
```r
FormantPath <- R6Class("FormantPath",
  public = list(
    # Query
    get_number_of_candidates = function(time) {},
    get_candidate_frequency = function(candidate, formant, time) {},
    
    # Path optimization
    extract_smooth_formant = function(...) {},  # Returns Formant
    
    # Export
    to_data_frame = function() {}
  )
)
```

**2.2 Table** (Praat's data structure)
Priority: ⭐⭐

Why needed:
- Many Praat methods return Tables
- Used for complex data export
- Bridge between Praat and R data.frames

Methods needed (~30):
```r
Table <- R6Class("Table",
  public = list(
    # Creation
    initialize = function(column_names = NULL, n_rows = 0) {},
    
    # Query
    get_number_of_rows = function() {},
    get_number_of_columns = function() {},
    get_column_label = function(column) {},
    get_value = function(row, column) {},
    
    # Modification
    set_value = function(row, column, value) {},
    insert_row = function(row) {},
    remove_row = function(row) {},
    append_column = function(label) {},
    
    # Export
    as_data_frame = function() {},  # Convert to R data.frame
    write_to_file = function(path) {}
  )
)
```

**2.3 Matrix** (2D numerical data)
Priority: ⭐

Why needed:
- Base class for many Praat objects
- Used for spectral data, coefficients
- Useful for custom analyses

Methods needed (~20):
```r
Matrix <- R6Class("Matrix",
  public = list(
    # Query dimensions
    get_nx = function() {},  # Number of columns
    get_ny = function() {},  # Number of rows
    get_value = function(row, col) {},
    
    # Modifications
    set_value = function(row, col, value) {},
    
    # Export
    as_matrix = function() {}  # Convert to R matrix
  )
)
```

#### **Phase 3: Advanced Objects** (Priority: MEDIUM)

**3.1 FormantGrid** (Modifiable formant contours)
- For voice transformation/modification
- Similar to PitchTier but for formants

**3.2 AmplitudeTier** (Modifiable amplitude)
- Complete the RealTier family
- Used in Manipulation

**3.3 Cochleagram** (Auditory spectrogram)
- Perceptual frequency representation
- Used in some voice analysis workflows

#### **Phase 4: Extended Functionality** (Priority: LOW)

**4.1 Collection** (Praat object lists)
- Manage multiple Praat objects
- Useful for batch processing

**4.2 LongSound** (Disk-based audio)
- For very large audio files
- Streaming access without full load

---

## Systematic Naming Convention

### Complete Mapping from Praat to R

#### **Creation Commands**

| Praat Command | R Method | Example |
|---------------|----------|---------|
| `Read from file` | `new(path)` | `Sound$new("file.wav")` |
| `Create Sound from formula` | `create_from_formula()` | `Sound$create_from_formula(...)` |
| `Create Strings as file list` | `create_file_list()` | `Strings$create_file_list()` |

#### **Conversion Commands (To X)**

| Praat Pattern | R Pattern | Example |
|---------------|-----------|---------|
| `To Pitch` | `to_pitch()` | `sound$to_pitch()` |
| `To Formant (burg)` | `to_formant_burg()` | `sound$to_formant_burg()` |
| `To Formant (keep all)` | `to_formant_keepall()` | `sound$to_formant_keepall()` |
| `To Intensity` | `to_intensity()` | `sound$to_intensity()` |
| `To Spectrum` | `to_spectrum()` | `sound$to_spectrum()` |
| `To Matrix` | `to_matrix()` | `object$to_matrix()` |
| `Down to Table` | `down_to_table()` | `formant$down_to_table()` |

#### **Query Commands (Get X)**

| Praat Pattern | R Pattern | Example |
|---------------|-----------|---------|
| `Get duration` | `get_duration()` | `sound$get_duration()` |
| `Get mean` | `get_mean()` | `pitch$get_mean()` |
| `Get minimum` | `get_minimum()` | `pitch$get_minimum()` |
| `Get value at time` | `get_value_at_time()` | `formant$get_value_at_time()` |
| `Get number of frames` | `get_number_of_frames()` | `pitch$get_number_of_frames()` |
| `Get time from frame` | `get_time_from_frame()` | `pitch$get_time_from_frame()` |

#### **Modification Commands (Set/Modify)**

| Praat Pattern | R Pattern | Example |
|---------------|-----------|---------|
| `Set value` | `set_value()` | `table$set_value()` |
| `Scale intensity` | `scale_intensity()` | `sound$scale_intensity()` |
| `Filter` | `filter()` | `sound$filter()` |
| `Set label` | `set_label()` | `textgrid$set_label()` |

#### **Extraction Commands**

| Praat Pattern | R Pattern | Example |
|---------------|-----------|---------|
| `Extract part` | `extract_part()` | `sound$extract_part()` |
| `Extract tier` | `extract_tier()` | `textgrid$extract_tier()` |

---

## Advantages Over Parselmouth

### speaker R Package

✅ **Direct method calls** - No `praat.call()` string dispatcher
✅ **Type safety** - R6 methods with clear parameter types
✅ **IDE support** - RStudio autocomplete for all methods
✅ **Self-documenting** - Method names are descriptive
✅ **No Python** - Direct R ↔ C++ binding
✅ **R conventions** - snake_case, named parameters
✅ **Documentation** - Roxygen2 docs for every method
✅ **Systematic mapping** - Predictable Praat → R transcoding

### Parselmouth (Python)

⚠️ **String-based dispatch** - `praat.call(obj, "Command Name", params)`
⚠️ **No autocomplete** - Must know exact Praat command names
⚠️ **Python dependency** - Requires Python interpreter
⚠️ **Less discoverable** - Methods hidden behind `praat.call()`

---

## Implementation Strategy

### 1. Prioritization

**Must Have (Phase 1-2)**:
- Complete TextGrid ✅
- Complete LPC ✅
- Add FormantPath ✅
- Add Table ✅

**Should Have (Phase 3)**:
- Add FormantGrid
- Add Matrix
- Add AmplitudeTier

**Nice to Have (Phase 4)**:
- Collection
- LongSound
- Cochleagram

### 2. Development Approach

For each new object:

1. **Define R6 class structure**
   - Inherit from `PraatObject`
   - External pointer to C++ object

2. **Create C++ wrappers** (Rcpp)
   - Wrap Praat C++ class methods
   - Handle memory management
   - Error handling

3. **Implement R6 methods**
   - Follow naming conventions
   - Document with roxygen2
   - Add parameter validation

4. **Create tests**
   - Unit tests for each method
   - Integration tests with real audio
   - Edge case handling

5. **Document usage**
   - Examples in roxygen2
   - Vignette demonstrating workflows

### 3. Code Generation

Many methods follow patterns. Consider code generation:

```r
# Generate wrapper code from Praat method signatures
generate_r6_methods <- function(praat_class, method_list) {
  # Parse Praat .h files
  # Generate Rcpp wrappers
  # Generate R6 methods
  # Generate roxygen2 docs
}
```

---

## Migration Path for superassp Python Code

### Example: `praat_formant_burg.py` → R

**Python (Parselmouth)**:
```python
def praat_formant_burg(sound, ...):
    snd = sound  # Accept Sound object
    form = snd.to_formant_burg(...)
    
    if track_formants:
        form = pm.praat.call(form, "Track", ...)
    
    formantTable = pm.praat.call(form, "Down to Table", ...)
    return pd.read_table(io.StringIO(pm.praat.call(formantTable, "List", True)))
```

**R (speaker)** - After completing Formant + Table:
```r
praat_formant_burg <- function(sound, ..., track_formants = FALSE) {
  # sound is already a Sound R6 object
  formant <- sound$to_formant_burg(...)
  
  if (track_formants) {
    formant <- formant$track(
      number_of_tracks = number_of_tracks,
      reference_f1 = reference_F1,
      reference_f2 = reference_F2,
      ...
    )
  }
  
  # Convert to Table, then to R data.frame
  formant_table <- formant$down_to_table(
    include_formants = TRUE,
    include_bandwidths = TRUE,
    ...
  )
  
  formant_table$as_data_frame()
}
```

**Benefits of R version**:
- No string-based method calls
- Type-safe R6 methods
- Native R data.frame output
- No Python dependency

---

## Deliverables

### Documentation

1. **CLAUDE.md update** - Document OOP decisions
2. **Naming conventions guide** - Praat → R mapping rules
3. **Object hierarchy diagram** - Visual reference
4. **Migration guide** - Praat script → R transcoding examples

### Code

1. **Complete objects** - TextGrid, LPC, FormantPath, Table
2. **C++ wrappers** - For all new objects
3. **R6 classes** - With full method sets
4. **Tests** - Comprehensive coverage
5. **Examples** - Real-world usage patterns

### Examples

Recreate superassp Python workflows in pure R:
- `inst/examples/formant_tracking.R`
- `inst/examples/voice_quality.R`
- `inst/examples/pitch_analysis.R`
- `inst/examples/praat_script_transcoding.R`

---

## Success Criteria

✅ **100% of core Praat objects** have R6 equivalents
✅ **All commonly-used Praat methods** are accessible
✅ **Systematic Praat → R mapping** documented and consistent
✅ **No Python dependency** for any Praat functionality
✅ **All superassp workflows** can be replicated in pure R
✅ **Praat scripts** can be systematically transcoded to R

---

## Conclusion

The current speaker implementation has **already made the correct architectural choice** by adopting an object-oriented approach with R6 classes wrapping Praat C++ objects. This is superior to Parselmouth's string-based `praat.call()` dispatcher.

**The path forward is clear**:
1. Complete the existing objects (TextGrid, LPC)
2. Add critical missing objects (FormantPath, Table)
3. Fill in remaining object hierarchy
4. Document systematic Praat → R mapping
5. Provide migration examples from Python/Praat

This will enable users to:
- ✅ Write Praat-like code directly in R
- ✅ Transcode Praat scripts systematically
- ✅ Avoid Python dependency
- ✅ Get IDE autocomplete and type safety
- ✅ Access full Praat functionality natively in R

The foundation is solid. We just need to **complete the object coverage**.
