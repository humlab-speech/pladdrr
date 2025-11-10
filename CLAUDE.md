- # Using Gemini CLI for Large Codebase Analysis

When analyzing large codebases or multiple files that might exceed context limits, use the Gemini CLI with its massive
context window. Use `gemini -p` to leverage Google Gemini's large context capacity.

## File and Directory Inclusion Syntax

Use the `@` syntax to include files and directories in your Gemini prompts. The paths should be relative to WHERE you run the
  gemini command:

### Examples:

**Single file analysis:**
gemini -p "@src/main.py Explain this file's purpose and structure"

Multiple files:
gemini -p "@package.json @src/index.js Analyze the dependencies used in the code"

Entire directory:
gemini -p "@src/ Summarize the architecture of this codebase"

Multiple directories:
gemini -p "@src/ @tests/ Analyze test coverage for the source code"

Current directory and subdirectories:
gemini -p "@./ Give me an overview of this entire project"

# Or use --all_files flag:
gemini --all_files -p "Analyze the project structure and dependencies"

Implementation Verification Examples

Check if a feature is implemented:
gemini -p "@src/ @lib/ Has dark mode been implemented in this codebase? Show me the relevant files and functions"

Verify authentication implementation:
gemini -p "@src/ @middleware/ Is JWT authentication implemented? List all auth-related endpoints and middleware"

Check for specific patterns:
gemini -p "@src/ Are there any React hooks that handle WebSocket connections? List them with file paths"

Verify error handling:
gemini -p "@src/ @api/ Is proper error handling implemented for all API endpoints? Show examples of try-catch blocks"

Check for rate limiting:
gemini -p "@backend/ @middleware/ Is rate limiting implemented for the API? Show the implementation details"

Verify caching strategy:
gemini -p "@src/ @lib/ @services/ Is Redis caching implemented? List all cache-related functions and their usage"

Check for specific security measures:
gemini -p "@src/ @api/ Are SQL injection protections implemented? Show how user inputs are sanitized"

Verify test coverage for features:
gemini -p "@src/payment/ @tests/ Is the payment processing module fully tested? List all test cases"

When to Use Gemini CLI

Use gemini -p when:
- Analyzing entire codebases or large directories
- Comparing multiple large files
- Need to understand project-wide patterns or architecture
- Current context window is insufficient for the task
- Working with files totaling more than 100KB
- Verifying if specific features, patterns, or security measures are implemented
- Checking for the presence of certain coding patterns across the entire codebase

Important Notes

- Paths in @ syntax are relative to your current working directory when invoking gemini
- The CLI will include file contents directly in the context
- No need for --yolo flag for read-only analysis
- Gemini's context window can handle entire codebases that would overflow Claude's context
- When checking implementations, be specific about what you're looking for to get accurate results

## Active Technologies
- R 4.0+ with C++17 (required for Praat source compatibility) (001-praat-r-access)
- Rcpp 1.0+ (R/C++ interface via XPtr for memory management)
- R6 2.5+ (Object-oriented framework mirroring Praat's class hierarchy)
- av package (humlab-speech/av fork for audio I/O)
- Praat source code (selective compilation from fon/ directory)

## Recent Changes

### 2025-11-10: OOP Architecture Assessment & Future Integration Plan
- **Confirmed OOP approach is correct** - aligns with Praat's C++ architecture and Parselmouth's design
- **Documented integration patterns** for adding new Praat objects to the package
- **Created comprehensive Phase 3 plan** (PHASE3_IMPLEMENTATION_PLAN.md)
- **Identified critical priorities**:
  - Phase 3A: Documentation & Examples (re-implement superassp Python examples)
  - Phase 3B: TextGrid implementation (CRITICAL - 90% of users need this)
  - Phase 3C: Manipulation & Tier objects (pitch/duration modification)
  - Phase 3D: Complete spectral suite (Spectrogram, LPC, MFCC)
- **Established naming conventions** for consistent Praat script → R translation

### Previous
- 001-praat-r-access: Upgraded to C++17 for Praat source compatibility
- 001-praat-r-access: Adopted R6-based object-oriented architecture
- Implemented 6 core objects: Sound, Pitch, Formant, Intensity, Harmonicity, PointProcess
- Established XPtr memory management pattern with automatic cleanup

---

## ARCHITECTURAL DECISIONS FOR PRAAT INTEGRATION

### Decision Date: 2025-11-08

### Context
The initial implementation used a functional approach (standalone functions for pitch, formant extraction, etc.), but this doesn't reflect Praat's inherently object-oriented nature. Praat is built on a C++ object hierarchy with the `Thing` base class and objects like Sound, Pitch, Formant, TextGrid, etc. The Python Parselmouth library successfully mirrors this OOP structure.

### Decision: Object-Oriented R6 Architecture

**Rationale:**
1. **Mirrors Praat's Native Design**: Praat is fundamentally OOP with persistent object state and method chaining
2. **Proven Pattern**: Parselmouth's success demonstrates this approach works well
3. **Efficient**: Avoids data copying between operations via external pointers to C++ objects
4. **Intuitive**: Users familiar with Praat scripts can easily translate to R code
5. **Extensible**: Easy to add new objects and methods as Praat functionality is needed

### Core Architecture Pattern

```
R Layer (R6 Classes)          C++ Layer (Praat Objects via XPtr)
─────────────────────────────────────────────────────────
PraatObject (base)     <───>  Thing* (base, managed by XPtr)
  └─ Sound             <───>  structSound*
  └─ Pitch             <───>  structPitch*
  └─ Formant           <───>  structFormant*
  └─ Intensity         <───>  structIntensity*
  └─ TextGrid          <───>  structTextGrid*
  └─ Spectrogram       <───>  structSpectrogram*
  └─ Spectrum          <───>  structSpectrum*
  └─ Manipulation      <───>  structManipulation*
  └─ PointProcess      <───>  structPointProcess*
  └─ Harmonicity       <───>  structHarmonicity*
  └─ LPC               <───>  structLPC*
  └─ [Future objects]
```

### Implementation Guidelines for New Objects

#### 1. Naming Conventions (Praat → R)

| Praat Command Pattern | R6 Method Pattern | Example |
|----------------------|-------------------|---------|
| `Get [property]` | `get_[property]()` | `get_duration()`, `get_sampling_frequency()` |
| `To [Object]...` | `to_[object]()` | `to_pitch()`, `to_formant_burg()` |
| `Extract [part]...` | `extract_[part]()` | `extract_part()`, `extract_channel()` |
| `[Action]...` | `[action]()` | `scale_intensity()`, `resample()` |
| `Down to [Type]` | `as_[type]()` or `to_[type]()` | `as_data_frame()`, `as_matrix()` |
| `Save as...` | `save()` | `save("output.wav")` |

**Consistency Rules:**
- **Query methods**: `get_*()` → returns value, doesn't modify object
- **Transformation methods**: `to_*()` → creates and returns new object of different type
- **Extraction methods**: `extract_*()` → creates new object of same type (subset)
- **Modification methods**: verb without prefix → modifies object in place (when possible)
- **Export methods**: `as_*()` → converts to native R type (data.frame, matrix, vector)
- **I/O methods**: `save(path)` for writing, `$new(path)` constructor for reading

#### 2. C++ Wrapper Pattern

Each Praat object requires C++ wrappers following this pattern:

```cpp
// File: src/[object]_wrappers.cpp

#include <Rcpp.h>
#include "praat.github.io/[relevant headers]"
#include "praat_xptr_utils.h"
#include "praat_error_handling.h"

using namespace Rcpp;

// Finalizer for proper memory management
void [object]_finalizer(struct[Object]* obj) {
    if (obj != nullptr) {
        forget(obj);  // Praat's memory management
    }
}

// Constructor - read from file
// [[Rcpp::export(.[object]_new)]]
XPtr<struct[Object]> [object]_new(std::string path) {
    try {
        auto[Object] obj = [Object]_readFromFile(Melder_peek8to32(path.c_str()));
        struct[Object]* ptr = obj.releaseToAmbiguousOwner();
        return XPtr<struct[Object]>(ptr, true, [object]_finalizer);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to read [Object] from: " + path);
    }
}

// Query method example
// [[Rcpp::export(.[object]_get_[property])]]
double [object]_get_[property](XPtr<struct[Object]> xptr) {
    if (!xptr) stop("Invalid [Object] pointer");
    struct[Object]* obj = xptr.get();
    // Access Praat object properties/methods
    return [Object]_get[Property](obj);
}

// Transformation method example (returns different object type)
// [[Rcpp::export(.[object]_to_[other_object])]]
XPtr<struct[OtherObject]> [object]_to_[other_object](
    XPtr<struct[Object]> xptr,
    double param1,
    double param2
) {
    if (!xptr) stop("Invalid [Object] pointer");
    
    try {
        auto[OtherObject] result = [Object]_to_[OtherObject](
            xptr.get(),
            param1,
            param2
        );
        struct[OtherObject]* ptr = result.releaseToAmbiguousOwner();
        return XPtr<struct[OtherObject]>(ptr, true, [other_object]_finalizer);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to convert [Object] to [OtherObject]");
    }
}
```

#### 3. R6 Class Pattern

Each object has an R6 class in `R/[object]-r6.R`:

```r
#' [Object] Class
#'
#' R6 class representing a Praat [Object] object.
#'
#' @export
[Object] <- R6::R6Class("[Object]",
    inherit = PraatObject,
    
    public = list(
        #' @description
        #' Create a new [Object]
        #' @param path Path to [Object] file (optional)
        #' @param .xptr Internal: external pointer (optional)
        initialize = function(path = NULL, .xptr = NULL) {
            if (!is.null(.xptr)) {
                private$ptr <- .xptr
            } else if (!is.null(path)) {
                private$ptr <- .[object]_new(path)
            } else {
                stop("Provide either path or .xptr")
            }
        },
        
        #' @description Get [property]
        #' @return Numeric value
        get_[property] = function() {
            .[object]_get_[property](private$ptr)
        },
        
        #' @description Convert to [OtherObject]
        #' @param param1 First parameter
        #' @param param2 Second parameter
        #' @return New [OtherObject] object
        to_[other_object] = function(param1 = default1, param2 = default2) {
            result_ptr <- .[object]_to_[other_object](
                private$ptr, 
                param1, 
                param2
            )
            [OtherObject]$new(.xptr = result_ptr)
        },
        
        #' @description Print method
        print = function() {
            cat("<Praat [Object]>\n")
            # Add relevant summary information
            invisible(self)
        }
    ),
    
    private = list(
        ptr = NULL,
        
        finalize = function() {
            # XPtr finalizer handles C++ object cleanup
            private$ptr <- NULL
        }
    )
)
```

#### 4. Memory Management Strategy

**Critical for preventing memory leaks:**

1. **C++ side**: Use XPtr with finalizers
   - Each Praat object type has a specific finalizer function
   - Finalizer calls `forget()` on the Praat object (Praat's autoThing mechanism)
   - XPtr automatically calls finalizer when R object is garbage collected

2. **R side**: Minimal cleanup needed
   - Private `finalize()` method just clears the pointer
   - XPtr's finalizer does the actual C++ cleanup
   - No manual `delete` or `free` calls needed

3. **Testing**: Always validate with valgrind
   ```bash
   R -d valgrind --vanilla < test_script.R
   ```

#### 5. Error Handling Strategy

**Bridging Praat's MelderError to R errors:**

```cpp
try {
    // Praat function call
    auto result = SomePraatFunction(...);
    // Process result
} catch (MelderError) {
    Melder_clearError();  // Clear Praat's error state
    Rcpp::stop("Meaningful error message for R users");
}
```

**Never let MelderError propagate to R** - always catch and convert to Rcpp exceptions.

### Object Implementation Priority

Based on the comprehensive OOP plan (`specs/001-praat-r-access/COMPREHENSIVE-OOP-PLAN.md`):

**Phase 1 (Completed):**
- ✅ Base PraatObject infrastructure
- ✅ Sound (mostly complete, needs more methods)
- ✅ Pitch (R6 implemented)
- ✅ PointProcess (R6 implemented)

**Phase 2 (In Progress):**
- 🔄 Formant (S3 exists, needs R6 conversion)
- 🔄 Intensity (S3 exists, needs R6 conversion)
- 🔄 Harmonicity (S3 exists, needs R6 conversion)

**Phase 3 (High Priority - Missing Critical Features):**
- ❌ TextGrid (CRITICAL for linguistic annotation)
- ❌ Manipulation (needed for pitch/duration modification)
- ❌ Spectrogram
- ❌ Spectrum

**Phase 4 (Extended Functionality):**
- ❌ LPC
- ❌ VoiceReport (composite object)
- ❌ Tier objects (PitchTier, FormantTier, IntensityTier, DurationTier)
- ❌ Additional objects as needed

### Testing Requirements for New Objects

Each new object implementation must include:

1. **Unit tests** (`tests/testthat/test-[object].R`):
   - Constructor from file
   - Constructor from XPtr (internal)
   - All query methods
   - All transformation methods
   - Print method
   - Memory cleanup (no leaks)

2. **Integration tests**:
   - Object creation from other objects (e.g., `sound$to_pitch()`)
   - Method chaining workflows
   - Export to R data structures

3. **Validation tests** (compare to Praat desktop output):
   - Use known test files
   - Compare numeric results to Praat's output
   - Tolerance for floating-point differences

### Documentation Requirements

Each object needs:

1. **R documentation** (`man/[Object].Rd` via roxygen2):
   - Class description
   - Constructor parameters
   - All public methods with examples
   - Link to related objects

2. **Vignettes** (when object is significant):
   - Basic usage examples
   - Common workflows
   - Integration with other objects

3. **Examples** (`inst/examples/`):
   - Standalone scripts demonstrating capabilities
   - Re-implementations of Python Parselmouth examples

### Current Status Summary

**Version:** 0.2.1  
**Last Updated:** 2025-11-08

**Completed:**
- R6 infrastructure with proper memory management
- Sound R6 class (partial - needs more methods)
- Pitch R6 class (complete basic functionality)
- PointProcess R6 class (complete basic functionality)
- C++ build system with Praat source integration
- XPtr-based memory management with finalizers

**In Progress:**
- Converting remaining S3 implementations to R6
- Expanding Sound class methods
- Build system optimization for Praat source compilation

### STRATEGIC SHIFT: Full OOP Implementation

**Date:** 2025-11-08  
**Priority Change:** Move from function-based to comprehensive object-oriented implementation

**Key Insight from Praat Source Analysis:**
The Praat codebase is fundamentally object-oriented with the following hierarchy:
- `Thing` (base class) → `Function` → `Sampled`, `Vector`, `Matrix`
- Core phonetic objects: Sound, Pitch, Formant, Intensity, Spectrogram, TextGrid, etc.
- Each object has ~10-40 methods for querying, transforming, and exporting data
- Objects transform into other objects (e.g., `Sound_to_Pitch()`, `Pitch_to_PitchTier()`)

**Amended Implementation Plan:**

**Phase 1: Complete Foundation Objects (Priority)**
1. ✅ Sound - Expand to include ALL Sound methods (~40 total)
   - Missing: filtering, pre-emphasis, resampling, concatenation, mixing
   - Missing transforms: to_Spectrogram, to_Spectrum, to_LPC, to_Manipulation
2. 🔄 Pitch - Add missing methods (~20 total)
   - Missing: smooth, interpolate, kill_octave_jumps
   - Missing transforms: to_PitchTier, to_PointProcess, to_Sound (resynth)
3. 🔄 Formant - Convert S3 to R6, add methods (~15 total)
   - Missing: tracker, formula, down_to_FormantGrid
4. 🔄 Intensity - Convert S3 to R6, add methods (~12 total)
5. 🔄 Harmonicity - Convert S3 to R6, add methods (~10 total)
6. ✅ PointProcess - Expand for voice quality metrics

**Phase 2: Critical Missing Objects**
7. ❌ **TextGrid** ⭐⭐⭐ HIGHEST PRIORITY
   - Tier management (IntervalTier, PointTier)
   - Interval/point operations
   - Integration with Sound for segmentation
   - Essential for 90%+ of phonetic research
8. ❌ **Manipulation** ⭐⭐ HIGH PRIORITY  
   - PSOLA-based pitch/duration modification
   - Extract/replace PitchTier, DurationTier
   - Resynthesize modified sound
   - Essential for prosody research

**Phase 3: Spectral Analysis Objects**
9. ❌ Spectrogram
10. ❌ Spectrum
11. ❌ LPC (Linear Predictive Coding)
12. ❌ Ltas (Long-term average spectrum)

**Phase 4: Modifiable Tier Objects**
13. ❌ PitchTier (modifiable F0 contour)
14. ❌ FormantGrid (modifiable formant tracks)
15. ❌ IntensityTier (modifiable intensity contour)
16. ❌ DurationTier (time warping)

**Phase 5: Advanced Analysis**
17. ❌ VoiceReport (comprehensive voice quality)
18. ❌ Cochleagram (auditory model)
19. ❌ Excitation (vocal tract excitation)
20. ❌ Additional objects as research needs emerge

**Implementation Approach Per Object:**

For each Praat object class, implement in this order:
1. **Analyze Praat source** (`src/praat.github.io/fon/[Object].h`)
   - Identify all `[Object]_*` functions in the header
   - Map inheritance (Thing → Function → Vector/Matrix → SpecificObject)
   - List creation, query, transform, modify, export methods
   
2. **Create C++ wrappers** (`src/[object]_wrappers.cpp`)
   - Finalizer function for memory management
   - Constructor wrappers (from file, from data, from other objects)
   - Query method wrappers (get_* functions)
   - Transform method wrappers (to_* functions, return new XPtr)
   - Modify method wrappers (in-place or return modified copy)
   - Export method wrappers (to R data structures)
   
3. **Create R6 class** (`R/[object]-r6.R`)
   - Inherit from PraatObject
   - Initialize method (from file or XPtr)
   - Public methods wrapping C++ functions
   - Print method showing object summary
   - Static factory methods if needed (e.g., `Sound$create_tone()`)
   
4. **Write tests** (`tests/testthat/test-[object].R`)
   - Constructor tests
   - Query method tests with known values
   - Transform method tests (verify output object type)
   - Memory leak tests (create/destroy many objects)
   - Integration tests (workflows combining objects)
   
5. **Document** (`man/[Object].Rd` via roxygen2)
   - Class description linking to Praat manual
   - Constructor parameters
   - All method signatures with parameter descriptions
   - Examples showing common workflows
   - Links to related objects

**Next Immediate Actions:**
1. ✅ Document this strategic shift in CLAUDE.md
2. Expand Sound class with remaining ~25 methods
3. Convert Formant to R6 with all methods
4. Convert Intensity to R6 with all methods
5. Convert Harmonicity to R6 with all methods
6. Implement TextGrid (most critical missing feature)
7. Implement Manipulation (pitch/duration modification)
8. Add spectral objects (Spectrogram, Spectrum, LPC)
9. Create comprehensive examples re-implementing Parselmouth workflows
10. Validate against Praat desktop output for numerical accuracy

### MEDIA LOADING DECISION: AV Package Integration

**Date:** 2025-11-09  
**Decision:** Use `av` package (humlab-speech fork) for media loading instead of direct file I/O

**Rationale:**
1. **Standardization**: Other humlab-speech packages use this approach
2. **Format Support**: av handles diverse audio/video formats via FFmpeg
3. **In-Memory Processing**: Seamless integration with R's data structures
4. **Maintained**: Active development by humlab-speech team
5. **Cross-Platform**: FFmpeg provides consistent behavior across OS

**Implementation Approach (Option D):**
- **Sound Object Creation**: Accept both file paths AND raw audio matrices
  ```r
  # From file (via av)
  sound <- Sound$new("audio.mp3")  # av loads → matrix → Praat Sound
  
  # From matrix (direct)
  sound <- Sound$from_matrix(audio_matrix, sample_rate = 44100)
  ```
- **av Package Source**: https://github.com/humlab-speech/av
- **DESCRIPTION Dependency**: Add `av` to Imports
- **Conversion Path**: av::read_audio_fft() → matrix → Sound_create() C++ wrapper

**Technical Details:**
- av returns audio as numeric matrix (samples × channels)
- Create C++ wrapper: `Sound_from_matrix(matrix, sample_rate, channels)`
- R6 Sound class gets two constructors:
  - `initialize(path)` → uses av internally
  - `from_matrix(matrix, sample_rate)` → static factory method
- Maintains compatibility with Praat's native Sound creation

**Benefits Over Direct File I/O:**
- No need to implement format-specific parsers in C++
- Automatic resampling and format conversion via av
- Consistent with other humlab-speech packages (e.g., superassp)
- Users can pre-process audio in R before creating Sound objects

**Next Steps:**
1. Add `av` to DESCRIPTION Imports
2. Implement `Sound_from_matrix()` C++ wrapper
3. Add `Sound$from_matrix()` static factory method
4. Update `Sound$new(path)` to use av internally
5. Test with various audio formats (wav, mp3, flac, etc.)
6. Document in vignette showing both usage patterns

### FUTURE EXTENSIONS: Deferred Features

**Date:** 2025-11-10  
**Status:** Documented for future implementation

#### 1. Praat Script Interpreter ⏳ DEFERRED

**Current Status:** NOT IMPLEMENTED

**What this means:**
- Cannot execute raw Praat scripts directly (`.praat` files)
- Users must translate Praat syntax to R6 method calls
- No `praat.call()` or `praatScript()` function (like Parselmouth has)

**Why deferred:**
- Implementing a full script interpreter requires significant effort
- Would need to parse Praat script syntax
- Would need to implement Praat's formula language
- Current focus is on object-oriented API which covers most use cases
- Translation from Praat scripts to R is straightforward with naming conventions

**Impact:**
- ✅ All Praat functionality available via R6 methods
- ✅ Can write R equivalents of Praat scripts
- ❌ Cannot run .praat files directly
- ❌ No on-the-fly script execution

**Example Workaround:**
```r
# Praat script:
# sound = Open long sound file: "audio.wav"
# pitch = To Pitch (ac): 0, 75, 15, "no", 0.03, 0.45, 0.01, 0.35, 0.14, 600
# mean_f0 = Get mean: 0, 0, "Hertz"

# R equivalent (current approach):
sound <- Sound$new("audio.wav")
pitch <- sound$to_pitch_ac(
  time_step = 0,
  pitch_floor = 75,
  max_candidates = 15,
  very_accurate = FALSE,
  silence_threshold = 0.03,
  voicing_threshold = 0.45,
  octave_cost = 0.01,
  octave_jump_cost = 0.35,
  voiced_unvoiced_cost = 0.14,
  pitch_ceiling = 600
)
mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")
```

**Future implementation path:**
1. Implement Praat formula parser (using `fon/Formula.h`)
2. Create script tokenizer/lexer
3. Map Praat commands to R6 method calls
4. Implement `praatScript()` function
5. Support Praat's form/script parameters

**Estimated effort:** 3-4 weeks of dedicated development

#### 2. Picture Plotting (Praat Graphics System) ⏳ DEFERRED

**Current Status:** NOT IMPLEMENTED

**What this means:**
- No direct equivalent to Praat's Picture window
- Cannot use Praat's `Draw...` commands directly
- No `Erase all`, `Select inner viewport`, `Draw inner box` etc.
- Graphics stubs are implemented but only prevent compilation errors

**Why deferred:**
- Praat's graphics system is complex (custom rendering engine)
- R has excellent native plotting (base, ggplot2, etc.)
- Converting Praat graphics commands to R graphics is non-trivial
- Better to leverage R's strengths in visualization
- Core analysis functionality is higher priority

**Impact:**
- ✅ All analysis and data extraction works
- ✅ Can export data to R and plot with R graphics
- ❌ Cannot use Praat's drawing commands
- ❌ No `Draw...` methods on objects

**Current approach - Use R for plotting:**
```r
# Instead of Praat's drawing commands:
# select Pitch pitch
# Draw: 0, 0, 75, 600, "no"

# Use R plotting with exported data:
pitch <- sound$to_pitch()
pitch_df <- pitch$as_data_frame()

library(ggplot2)
ggplot(pitch_df, aes(x = time, y = frequency)) +
  geom_line() +
  ylim(75, 600) +
  labs(title = "Pitch contour", x = "Time (s)", y = "Frequency (Hz)")

# Or use base R:
plot(pitch_df$time, pitch_df$frequency, type = "l",
     ylim = c(75, 600), xlab = "Time (s)", ylab = "Frequency (Hz)")
```

**Future implementation options:**

**Option A: Native R Graphics Wrapper**
- Create `draw_*()` methods that use R graphics internally
- Translate Praat graphics calls to R equivalents
- Estimated effort: 2-3 weeks

**Option B: Export Praat Graphics to R**
- Implement Praat's graphics engine minimally
- Capture drawing commands and convert to R graphics objects
- More complex, estimated effort: 4-6 weeks

**Option C: Hybrid Approach** ⭐ RECOMMENDED
- Provide convenience plotting functions for common visualizations
- Use R's native plotting capabilities
- Document how to create Praat-style plots in R
- Estimated effort: 1 week

**Recommendation:** Option C - leverage R's superior plotting ecosystem

**Future helper functions to add:**
```r
# Convenience plotting functions
plot.Sound(sound, channel = 1)  # Waveform
plot.Pitch(pitch, range = c(75, 600))  # F0 contour
plot.Formant(formant, formants = 1:3)  # Formant tracks
plot.Spectrogram(spectrogram, freq_range = c(0, 5000))  # Spectrogram
plot.TextGrid(textgrid, tiers = "all")  # Annotation tiers
```

**Estimated effort for Option C:** 1-2 weeks

---

### COMPREHENSIVE OOP ARCHITECTURE - 2025-11-10 AMENDMENT

**Master Planning Document:** `specs/001-praat-r-access/OOP-ARCHITECTURE-AMENDMENT.md`

**Critical Insight:**
The Praat application and source code is fundamentally object-oriented with ~30+ object types forming a rich class hierarchy. The initial specification focused on procedural functions (e.g., `extract_pitch()`, `extract_formant()`), which doesn't reflect how Praat actually works and loses the power of object persistence and method chaining.

**Corrected Approach:**
Focus on making **Praat OBJECTS** work in R via R6 classes, NOT on implementing specific procedures. This mirrors the successful design of Python's Parselmouth library and enables direct transcoding of Praat scripts to R.

**Praat Script vs R Translation Example:**
```praat
# Praat script
sound = Read from file: "audio.wav"
pitch = To Pitch: 0.0, 75, 600
meanF0 = Get mean: 0, 0, "Hertz"
```

```r
# R translation (speaker package)
sound <- Sound$new("audio.wav")
pitch <- sound$to_pitch(time_step = 0.0, pitch_floor = 75, pitch_ceiling = 600)
mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "Hertz")
```

**Complete Object Implementation Roadmap:**

**Phase 1: Foundation Objects** (Weeks 1-3)
- ✅ Sound (expand with ~15 missing methods)
- ✅ Pitch (add manipulation methods)
- ⚠️ **Formant** (CRITICAL: migrate from S3 to R6)
- ✅ Intensity (complete)
- ✅ Harmonicity (complete)
- ✅ PointProcess (complete)
- ✅ TextGrid (mostly complete)

**Phase 2: Manipulation System** (Weeks 3-5) - CRITICAL MISSING FEATURE
- ❌ **Manipulation** (PSOLA-based pitch/duration modification)
- ❌ **PitchTier** (editable pitch contour)
- ❌ **DurationTier** (duration modification)
- ❌ **IntensityTier** (editable intensity)
- ❌ **FormantGrid** (editable formant trajectories)

**Phase 3: Spectral Analysis** (Weeks 5-7)
- ❌ Spectrum (FFT output)
- ❌ Spectrogram (time-frequency representation)
- ❌ LPC (Linear Predictive Coding)
- ❌ LTAS (Long-term average spectrum)
- ❌ MFCC (Mel-frequency cepstral coefficients)

**Phase 4: Utilities** (Week 7-8)
- ❌ Table (Praat's tabular data)
- ❌ Matrix (2D data container)

**Object Implementation Pattern:**

For each Praat object (e.g., Manipulation):

1. **Analyze Praat source** (`inst/include/praat.github.io/fon/[Object].h`)
2. **Create C++ wrappers** (`src/[object]-class.cpp`)
   - Constructor: `cpp_[object]_new()`
   - Queries: `cpp_[object]_get_*()`
   - Transforms: `cpp_[object]_to_*()`
   - Modifications: `cpp_[object]_[action]()`
3. **Create R6 class** (`R/[object]-r6.R`)
   - Inherit from `PraatObject`
   - Wrap C++ functions as methods
   - Follow naming conventions (see below)
4. **Write tests** (`tests/testthat/test-[object].R`)
5. **Document** (roxygen2 + vignettes)

**Naming Convention for Praat Compatibility:**
- `Get [X]` → `get_[x]()`
- `To [Object]` → `to_[object]()`
- `Extract [Part]` → `extract_[part]()`
- `[Action]` → `[action]()` (modify in place)
- `Save as` → `save(path)`
- Export to R → `as_data_frame()`, `as_matrix()`

**Integration with Parselmouth Examples:**

Python code in `/Users/frkkan96/Documents/src/superassp/inst/python` that uses Parselmouth should be re-implemented in R using this package's R6 objects. These re-implementations should be placed in `inst/examples/` to demonstrate:
1. Migration path from Python to R
2. Complete workflows using object-oriented approach
3. Integration with other R packages (av, ggplot2, etc.)

**Next Implementation Steps:**

1. **IMMEDIATE:** Convert Formant from S3 to R6 (critical gap)
2. **HIGH PRIORITY:** Implement Manipulation + Tier objects (PitchTier, DurationTier)
   - Required for voice modification research
   - Missing from current implementation
   - Used extensively in prosody studies
3. **MEDIUM PRIORITY:** Implement spectral objects (Spectrum, Spectrogram, LPC, LTAS)
4. **LOW PRIORITY:** Implement utility objects (Table, Matrix, MFCC)
5. **ONGOING:** Expand Sound, Pitch methods to match Praat's full API

**Success Metrics:**
- ✅ All major Praat objects have R6 equivalents
- ✅ Praat scripts can be mechanically translated to R
- ✅ No Python/Parselmouth dependency needed
- ✅ Performance comparable to native Praat
- ✅ Comprehensive documentation with migration guides

**Key Insight for Future Objects:**
When adding any new capability, ask: "What Praat OBJECT does this relate to?" not "What procedure should I implement?" The object-oriented approach ensures consistency, extensibility, and alignment with how Praat actually works.

### Future Considerations

**When adding new Praat source files:**
1. Check dependencies on other Praat modules
2. Update `src/Makevars` to include new source files
3. Add necessary symbolic links if using modular approach
4. Test compilation on multiple platforms
5. Update SystemRequirements if needed

**When Praat updates:**
1. Praat source is included as git submodule or direct copy
2. Update to new Praat version carefully
3. Test all existing functionality
4. Check for API changes in Praat C++ code
5. Update wrappers if Praat function signatures change

**When considering script interpreter (future):**
1. Study Parselmouth's `praat.call()` implementation
2. Review Praat's Formula.h and Interpreter.h
3. Decide on scope (full scripts vs. formula evaluation only)
4. Consider security implications of code execution
5. Design R-friendly API for script execution

**When considering graphics support (future):**
1. Evaluate whether Praat graphics add value over R graphics
2. If yes, choose implementation option (A, B, or C above)
3. Create comprehensive examples showing R-based alternatives
4. Consider using existing R packages (phonR, phonTools, etc.)

### Reference Documentation

**Key Planning Documents:**
- **`OOP_IMPLEMENTATION_ROADMAP_REVISED.md`** ⭐ MASTER PLAN (2025-11-10)
- `specs/001-praat-r-access/COMPREHENSIVE-OOP-PLAN.md` - Detailed OOP design
- `specs/001-praat-r-access/NAMING-CONVENTIONS.md` - Naming standards
- `COMPREHENSIVE_OOP_ROADMAP.md` - High-level roadmap

**Implementation Status:**
- `OOP_IMPLEMENTATION_COMPLETE_STATUS.md` - Current progress tracking

---

## Architecture Decisions (2025-11-10)

### OOP-First Paradigm Shift

**Decision**: Refocus from procedure-based to object-oriented architecture.

**Rationale**: Praat source code is fundamentally OOP (C++ Thing hierarchy). Original spec missed this core design. Python's Parselmouth proves OOP approach works.

**Implementation**: R6 classes wrap Praat C++ objects via XPtr, exposing native methods.

### Critical Priorities

1. **TextGrid** (currently disabled) - Essential for linguistic annotation
2. **Manipulation** (not implemented) - Required for PSOLA pitch/duration modification  
3. **Complete foundation objects** - Sound, Pitch, Formant need missing methods

### Naming Convention

Praat → R6 mapping for easy translation:
- `Get X` → `get_x()`
- `To X` → `to_x()` (new object)
- `Extract X` → `extract_x()` (same type)
- `Scale/Filter X` → `verb_x()` (modify in-place)
- `Down to Matrix` → `as_x()` (export to R)

### Postponed Features

**Interpreter & Graphics** marked for future (v0.3.0+):
- Cannot run Praat scripts directly (use R6 API instead)
- No Picture layer (use R graphics)
- Mitigation: Comprehensive translation guides + 50+ examples

### Dependencies

- **av package**: Use humlab-speech fork (https://github.com/humlab-speech/av)
- **C++11**: Minimum for Rcpp + R 4.0+ compatibility
- **R6**: Object-oriented programming

### Timeline

13 weeks to CRAN-ready package:
- Weeks 1-2: Complete foundation objects
- Weeks 3-4: TextGrid implementation
- Weeks 5-6: Manipulation + tiers
- Weeks 7-8: Spectral + additional tiers
- Weeks 9-10: Re-implement superassp Python examples
- Week 11: Documentation (10 vignettes)
- Week 12: Testing & validation
- Week 13: CRAN preparation

---

*This architecture enables systematic, consistent integration of Praat objects into R, following proven patterns from Parselmouth while leveraging R's strengths and avoiding Python dependency.*

---

## FUTURE OBJECT INTEGRATION GUIDELINES

### Updated: 2025-11-10

This section provides a **step-by-step workflow** for integrating additional Praat objects into the speaker package.

### Step-by-Step Integration Process

#### Step 1: Source Analysis (1-2 hours)

1. **Locate Praat source files**:
   - Header: `src/praat.github.io/fon/[Object].h` or `src/praat.github.io/dwtools/[Object].h`
   - Implementation: `src/praat.github.io/fon/[Object].cpp`

2. **Map class hierarchy**:
   ```
   Thing → Function → [Sampled/Vector/Matrix] → SpecificObject
   ```

3. **Catalog methods** into categories:
   - **Creation**: `[Object]_create()`, `[Object]_readFromFile()`, `Sound_to_[Object]()`
   - **Query**: `[Object]_get*()`, `[Object]_count*()`
   - **Transformation**: `[Object]_to_*()` (returns new object)
   - **Modification**: `[Object]_modify*()` (changes object)
   - **Export**: `[Object]_down*()`, conversion methods

4. **Check dependencies**:
   - What Praat subsystems are needed? (file I/O, graphics, threading, collections)
   - Are stubs already available in `src/*_stubs.cpp`?
   - Will new stubs be needed?

#### Step 2: C++ Wrappers (2-4 days)

1. **Create `src/[object]_wrappers.cpp`**:

```cpp
#include <Rcpp.h>
#include "praat.github.io/fon/[Object].h"
#include "praat.github.io/fon/Sound.h"  // if needed
// ... other includes

using namespace Rcpp;

// Finalizer
void [object]_finalizer(struct[Object]* obj) {
    if (obj != nullptr) {
        forget(obj);
    }
}

// Constructor from file
// [[Rcpp::export(.[object]_read)]]
XPtr<struct[Object]> [object]_read(std::string path) {
    try {
        auto[Object] obj = [Object]_readFromFile(Melder_peek8to32(path.c_str()));
        struct[Object]* ptr = obj.releaseToAmbiguousOwner();
        return XPtr<struct[Object]>(ptr, true, [object]_finalizer);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to read [Object]: " + path);
    }
}

// Query methods
// [[Rcpp::export(.[object]_get_[property])]]
double [object]_get_[property](XPtr<struct[Object]> xptr) {
    if (!xptr) stop("Invalid [Object] pointer");
    try {
        return [Object]_get[Property](xptr.get());
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to get [property]");
    }
}

// Transform methods (return new object)
// [[Rcpp::export(.[object]_to_[other])]]
XPtr<struct[Other]> [object]_to_[other](XPtr<struct[Object]> xptr, /* params */) {
    if (!xptr) stop("Invalid [Object] pointer");
    try {
        auto[Other] result = [Object]_to_[Other](xptr.get(), /* params */);
        struct[Other]* ptr = result.releaseToAmbiguousOwner();
        return XPtr<struct[Other]>(ptr, true, [other]_finalizer);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to convert to [Other]");
    }
}

// Export to R data structure
// [[Rcpp::export(.[object]_as_data_frame)]]
DataFrame [object]_as_data_frame(XPtr<struct[Object]> xptr) {
    if (!xptr) stop("Invalid [Object] pointer");
    struct[Object]* obj = xptr.get();
    
    // Extract data from Praat object
    int n = [Object]_get_numberOfFrames(obj);
    NumericVector times(n);
    NumericVector values(n);
    
    for (int i = 1; i <= n; i++) {  // Praat uses 1-based indexing
        times[i-1] = [Object]_indexToX(obj, i);
        values[i-1] = [Object]_get_valueAtIndex(obj, i);
    }
    
    return DataFrame::create(
        _["time"] = times,
        _["value"] = values
    );
}
```

2. **Add to `src/Makevars` or CMakeLists if needed**

3. **Run `Rcpp::compileAttributes()`** to generate `RcppExports.R` and `RcppExports.cpp`

4. **Test compilation**: `R CMD INSTALL --preclean .`

#### Step 3: R6 Class (1-2 days)

1. **Create `R/[object]-r6.R`**:

```r
#' [Object] R6 Class
#'
#' R6 class wrapping Praat's [Object] object.
#'
#' @export
[Object] <- R6::R6Class("[Object]",
  inherit = PraatObject,
  
  public = list(
    #' @description
    #' Create new [Object] instance
    #' @param path Path to [Object] file (optional)
    #' @param .xptr External pointer to existing [Object] (internal use)
    initialize = function(path = NULL, .xptr = NULL) {
      if (!is.null(.xptr)) {
        private$ptr <- .xptr
      } else if (!is.null(path)) {
        private$ptr <- .[object]_read(path)
      } else {
        stop("Provide either path or .xptr")
      }
    },
    
    #' @description Get [property]
    #' @return Numeric value
    get_[property] = function() {
      .[object]_get_[property](private$ptr)
    },
    
    #' @description Convert to [Other] object
    #' @param param1 Description
    #' @param param2 Description
    #' @return [Other] R6 object
    to_[other] = function(param1, param2) {
      other_ptr <- .[object]_to_[other](private$ptr, param1, param2)
      [Other]$new(.xptr = other_ptr)
    },
    
    #' @description Export to data.frame
    #' @return data.frame with time and value columns
    as_data_frame = function() {
      .[object]_as_data_frame(private$ptr)
    },
    
    #' @description Print method
    print = function() {
      cat("<Praat [Object]>\n")
      cat(sprintf("  [Property]: %s\n", self$get_[property]()))
      invisible(self)
    }
  ),
  
  private = list(
    ptr = NULL
  )
)

# Static factory methods (if applicable)
#' @export
[Object]$create <- function(params...) {
  ptr <- .[object]_create(params...)
  [Object]$new(.xptr = ptr)
}
```

2. **Update `NAMESPACE`** with `@export` tags
3. **Run `devtools::document()`** to generate Rd files

#### Step 4: Testing (1-2 days)

1. **Create `tests/testthat/test-[object].R`**:

```r
test_that("[Object] constructor works", {
  obj <- [Object]$new("inst/extdata/test.[ext]")
  expect_s3_class(obj, "[Object]")
  expect_s3_class(obj, "PraatObject")
})

test_that("[Object] query methods work", {
  obj <- [Object]$new("inst/extdata/test.[ext]")
  
  prop <- obj$get_[property]()
  expect_type(prop, "double")
  expect_gt(prop, 0)
})

test_that("[Object] transformation works", {
  obj <- [Object]$new("inst/extdata/test.[ext]")
  other <- obj$to_[other](param1, param2)
  
  expect_s3_class(other, "[Other]")
})

test_that("[Object] export to data.frame works", {
  obj <- [Object]$new("inst/extdata/test.[ext]")
  df <- obj$as_data_frame()
  
  expect_s3_class(df, "data.frame")
  expect_true("time" %in% names(df))
  expect_true("value" %in% names(df))
  expect_gt(nrow(df), 0)
})

test_that("[Object] memory management works", {
  # Create and destroy many objects to test for leaks
  for (i in 1:100) {
    obj <- [Object]$new("inst/extdata/test.[ext]")
    rm(obj)
    gc()
  }
  # If no crash/hang, memory management is working
  expect_true(TRUE)
})

test_that("[Object] integrates with related objects", {
  # Example: Sound → [Object]
  sound <- Sound$new("inst/extdata/test.wav")
  obj <- sound$to_[object](params...)
  
  expect_s3_class(obj, "[Object]")
})
```

2. **Add test data** to `inst/extdata/` if needed
3. **Run tests**: `devtools::test()`
4. **Check coverage**: `covr::package_coverage()`

#### Step 5: Documentation (1 day)

1. **Complete Roxygen documentation** in R6 class
2. **Add examples** to every public method:

```r
#' @examples
#' \dontrun{
#' # Create from file
#' obj <- [Object]$new("my_file.[ext]")
#' 
#' # Query property
#' value <- obj$get_[property]()
#' 
#' # Transform to other object
#' other <- obj$to_[other](param1, param2)
#' 
#' # Export to data.frame
#' df <- obj$as_data_frame()
#' }
```

3. **Create vignette** (if complex object): `vignettes/[object]-guide.Rmd`
4. **Add example script**: `inst/examples/XX_[object]_example.R`

#### Step 6: Validation (1 day)

1. **Compare to Praat desktop**:
   - Process same file in Praat and speaker
   - Verify identical or near-identical output
   - Document any known differences

2. **Benchmark performance**:
   - Time operations in speaker vs. Praat
   - Target: within 10-20% of Praat desktop

3. **Platform testing**:
   - macOS (x86_64, arm64)
   - Linux (Ubuntu, Fedora)
   - Windows (if applicable)

### Object Priority Matrix (Updated 2025-11-10)

| Praat Object | Usage % | Complexity | Priority | Status | Next Step |
|--------------|---------|------------|----------|--------|-----------|
| Sound | 100% | Medium | Foundation | ✅ Complete | Maintain |
| Pitch | 95% | Medium | Core | ✅ Complete | Add missing methods |
| Formant | 90% | Medium | Core | ✅ Complete | Add tracking |
| TextGrid | 90% | High | **CRITICAL** | ⚠️ Disabled | Enable + test |
| Intensity | 80% | Low | Core | ✅ Complete | Maintain |
| Harmonicity | 75% | Low | Core | ✅ Complete | Maintain |
| PointProcess | 70% | Medium | Core | ✅ Complete | Maintain |
| Manipulation | 60% | High | High | ❌ Not started | Implement |
| PitchTier | 60% | Low | High | ❌ Not started | Implement |
| Spectrum | 50% | Medium | Medium | ⚠️ Partial | Complete |
| Spectrogram | 40% | Medium | Medium | ❌ Not started | Implement |
| FormantGrid | 30% | Medium | Medium | ❌ Not started | Defer |
| IntensityTier | 25% | Low | Low | ❌ Not started | Defer |
| DurationTier | 25% | Low | Low | ❌ Not started | Defer |
| LPC | 20% | Medium | Medium | ❌ Stubbed | Implement |
| MFCC | 15% | Medium | Medium | ❌ Not started | Implement |
| Ltas | 10% | Low | Low | ❌ Not started | Defer |

### Estimated Effort Per Object

| Complexity | C++ Wrappers | R6 Class | Tests | Docs | Total |
|------------|--------------|----------|-------|------|-------|
| **Low** (Tier, simple) | 0.5-1 day | 0.5 day | 0.5 day | 0.5 day | **2-2.5 days** |
| **Medium** (Analysis) | 1-2 days | 1 day | 1 day | 0.5 day | **3.5-4.5 days** |
| **High** (TextGrid, Manipulation) | 2-4 days | 1-2 days | 1-2 days | 1 day | **5-9 days** |

### Quick Reference: Common Stub Requirements

If you encounter build errors related to missing Praat functions:

| Missing Function | Required Stub | File | Status |
|------------------|---------------|------|--------|
| `MelderFile_*` | File I/O stubs | `src/file_stubs.cpp` | ❌ Needed |
| `Graphics_*` | Graphics stubs | `src/graphics_stubs*.cpp` | ✅ Exists |
| `praat_*` | Praat command stubs | `src/praat_stubs.cpp` | ✅ Exists |
| `Collection_*` | Data structures | `src/collection_stubs.cpp` | ❌ Needed |
| `Thread_*` | Threading | `src/thread_stubs.cpp` | ❌ Needed |
| `NUM_*` | Numerical routines | `src/num_stubs.cpp` | ✅ Partial |

---

**This integration workflow ensures consistent, high-quality implementation of new Praat objects while maintaining the package's architectural integrity.**

---

## UPDATED OOP DESIGN DECISIONS (2025-11-10)

### Amendment Based on Parselmouth Analysis

After analyzing Parselmouth examples in `/Users/frkkan96/Documents/src/superassp/inst/python`, the following updates clarify the implementation approach:

#### Key Findings from Parselmouth Usage

1. **FormantPath Object**: Parselmouth uses `FormantPath` for robust formant tracking (not yet in speaker)
2. **Method Chaining**: Extensive use of `pm.praat.call(obj, "Method", args)` pattern
3. **Conversion Methods**: Objects frequently convert to other types (e.g., Intensity → IntensityTier → TableOfReal)

#### Extended Naming Convention

| Praat Command | R Method | Parselmouth Equivalent | Priority |
|---------------|----------|------------------------|----------|
| `To FormantPath (burg)...` | `to_formant_path_burg()` | `call(snd, "To FormantPath (burg)", ...)` | HIGH |
| `Extract Formant` | `extract_formant()` | `call(fp, "Extract Formant")` | HIGH |
| `Down to IntensityTier` | `down_to_intensity_tier()` | `call(int, "Down to IntensityTier")` | MEDIUM |
| `Down to TableOfReal` | `down_to_table_of_real()` | `call(tier, "Down to TableOfReal")` | MEDIUM |
| `To Table` | `to_table()` | `call(tor, "To Table", "col")` | LOW |
| `To Spectrogram...` | `to_spectrogram()` | `call(snd, "To Spectrogram", ...)` | MEDIUM |

#### Missing Critical Objects (Priority Order)

1. **TextGrid** - Annotation/segmentation (HIGHEST - used in 90% of phonetic research)
2. **FormantPath** - Robust formant tracking (HIGH - demonstrated in Parselmouth examples)
3. **Spectrum** - Frequency domain analysis (MEDIUM)
4. **Ltas** - Long-term average spectrum (MEDIUM)
5. **FormantGrid** - Detailed formant manipulation (LOW)

#### Deferred Features - Documented

**Praat Script Interpreter**
- **Status**: Not implemented
- **Reason**: Requires full Praat parser and command interpreter
- **Impact**: Cannot execute raw `.praat` scripts directly in R
- **Workaround**: Manual translation using consistent naming conventions
- **Future**: May be added as extension if demand exists

**Picture/Graphics Commands**
- **Status**: Not implemented  
- **Reason**: Praat's Picture window is GUI-specific, tightly coupled to graphics library
- **Impact**: Cannot use `Paint...`, `Draw...`, `Speckle...` commands
- **Workaround**: Export data to R (`as_data_frame()`, `as_matrix()`), visualize with ggplot2/base R
- **Future**: May create ggplot2-based equivalents for common visualizations

#### Object Integration Workflow

To add a new Praat object (documented for future maintenance):

1. **Analysis Phase**
   - Identify Praat C++ class in `inst/include/praat/fon/`
   - List key methods from Praat manual
   - Check Parselmouth for usage patterns
   - Estimate stub requirements (Graphics, File I/O, etc.)

2. **Implementation Phase**
   - Create `R/<objecttype>-r6.R` with R6 class
   - Create `src/praat_<objecttype>.cpp` with C++ bindings
   - Export methods with `[[Rcpp::export(.<objecttype>_method)]]`
   - Add conversion methods to parent objects
   - Create stub functions for unsupported Praat dependencies

3. **Documentation Phase**
   - Document each method with Praat menu command equivalent
   - Create examples showing Praat script → R translation
   - Add tests comparing against known Praat output
   - Update package documentation

4. **Testing Phase**
   - Unit tests for each method
   - Integration tests for method chains
   - Comparison tests against Praat output
   - Parselmouth parity tests (if applicable)

#### Implementation Time Estimates

| Object Type | Implementation | C++ Bindings | Stubs | Testing | Total |
|-------------|----------------|--------------|-------|---------|-------|
| Simple (Tier) | 0.5-1 day | 0.5 day | 0.5 day | 0.5 day | **2-2.5 days** |
| Medium (Spectrum, Ltas) | 1-2 days | 1 day | 1 day | 0.5 day | **3.5-4.5 days** |
| Complex (TextGrid, FormantPath) | 2-4 days | 1-2 days | 1-2 days | 1 day | **5-9 days** |

### Parselmouth Translation Examples

These examples show how superassp Python code should translate to speaker R code:

**Example 1: Intensity Analysis**
```python
# Python (Parselmouth)
intensity = pm.praat.call(sound, "To Intensity", min_pitch, time_step, subtract_mean)
intensity_tier = pm.praat.call(intensity, "Down to IntensityTier")
table_of_real = pm.praat.call(intensity_tier, "Down to TableOfReal")
```

```r
# R (speaker)
intensity <- sound$to_intensity(min_pitch, time_step, subtract_mean)
intensity_tier <- intensity$down_to_intensity_tier()
table_of_real <- intensity_tier$down_to_table_of_real()
```

**Example 2: FormantPath Tracking**
```python
# Python (Parselmouth)
formant_path = pm.praat.call(sound, "To FormantPath (burg)", 
                             time_step, num_formants, max_formant, ...)
formant = pm.praat.call(formant_path, "Extract Formant")
```

```r
# R (speaker) - TO BE IMPLEMENTED
formant_path <- sound$to_formant_path_burg(
  time_step, num_formants, max_formant, ...)
formant <- formant_path$extract_formant()
```

### Package Evolution Strategy

**Current State (v0.3.0)**:
- ✅ Core objects: Sound, Pitch, Formant, Intensity, Harmonicity, PointProcess
- ✅ Manipulation objects: Manipulation, PitchTier, IntensityTier, DurationTier
- ✅ Basic spectral: Spectrogram (partial)
- ✅ R6 architecture with external pointers
- ✅ av package integration for audio I/O

**Next Release (v0.4.0)** - Missing Critical Objects:
- ⬜ TextGrid (intervals + points) - PRIORITY 1
- ⬜ FormantPath - PRIORITY 2
- ⬜ Spectrum - PRIORITY 3
- ⬜ Ltas - PRIORITY 3
- ⬜ Enhanced Spectrogram methods

**Future Release (v0.5.0)** - Advanced Features:
- ⬜ FormantGrid
- ⬜ Cochleagram
- ⬜ LPC
- ⬜ Excitation
- ⬜ MFCC (if demanded)

**Long-term (v1.0+)** - Potential Extensions:
- ⬜ Praat script interpreter (execute .praat files)
- ⬜ ggplot2-based visualization functions
- ⬜ Parallel processing for batch analysis
- ⬜ Streaming audio support

---

**Updated**: 2025-11-10  
**Next Review**: After TextGrid implementation

---

## UPDATED OOP DESIGN DECISIONS (2025-11-10)

### Amendment Based on Parselmouth Analysis

After analyzing Parselmouth examples in `/Users/frkkan96/Documents/src/superassp/inst/python`, the following updates clarify the implementation approach:

#### Key Findings from Parselmouth Usage

1. **FormantPath Object**: Parselmouth uses `FormantPath` for robust formant tracking (not yet in speaker)
2. **Method Chaining**: Extensive use of `pm.praat.call(obj, "Method", args)` pattern
3. **Conversion Methods**: Objects frequently convert to other types (e.g., Intensity → IntensityTier → TableOfReal)

#### Extended Naming Convention

| Praat Command | R Method | Parselmouth Equivalent | Priority |
|---------------|----------|------------------------|----------|
| `To FormantPath (burg)...` | `to_formant_path_burg()` | `call(snd, "To FormantPath (burg)", ...)` | HIGH |
| `Extract Formant` | `extract_formant()` | `call(fp, "Extract Formant")` | HIGH |
| `Down to IntensityTier` | `down_to_intensity_tier()` | `call(int, "Down to IntensityTier")` | MEDIUM |
| `Down to TableOfReal` | `down_to_table_of_real()` | `call(tier, "Down to TableOfReal")` | MEDIUM |
| `To Table` | `to_table()` | `call(tor, "To Table", "col")` | LOW |
| `To Spectrogram...` | `to_spectrogram()` | `call(snd, "To Spectrogram", ...)` | MEDIUM |

#### Missing Critical Objects (Priority Order)

1. **TextGrid** - Annotation/segmentation (HIGHEST - used in 90% of phonetic research)
2. **FormantPath** - Robust formant tracking (HIGH - demonstrated in Parselmouth examples)
3. **Spectrum** - Frequency domain analysis (MEDIUM)
4. **Ltas** - Long-term average spectrum (MEDIUM)
5. **FormantGrid** - Detailed formant manipulation (LOW)

#### Deferred Features - Documented

**Praat Script Interpreter**
- **Status**: Not implemented
- **Reason**: Requires full Praat parser and command interpreter
- **Impact**: Cannot execute raw `.praat` scripts directly in R
- **Workaround**: Manual translation using consistent naming conventions
- **Future**: May be added as extension if demand exists

**Picture/Graphics Commands**
- **Status**: Not implemented
- **Reason**: Praat's Picture window is GUI-specific, tightly coupled to graphics library
- **Impact**: Cannot use `Paint...`, `Draw...`, `Speckle...` commands
- **Workaround**: Export data to R (`as_data_frame()`, `as_matrix()`), visualize with ggplot2/base R
- **Future**: May create ggplot2-based equivalents for common visualizations

#### Object Integration Workflow

To add a new Praat object (documented for future maintenance):

1. **Analysis Phase**
   - Identify Praat C++ class in `inst/include/praat/fon/`
   - List key methods from Praat manual
   - Check Parselmouth for usage patterns
   - Estimate stub requirements (Graphics, File I/O, etc.)

2. **Implementation Phase**
   - Create `R/<objecttype>-r6.R` with R6 class
   - Create `src/praat_<objecttype>.cpp` with C++ bindings
   - Export methods with `[[Rcpp::export(.<objecttype>_method)]]`
   - Add conversion methods to parent objects
   - Create stub functions for unsupported Praat dependencies

3. **Documentation Phase**
   - Document each method with Praat menu command equivalent
   - Create examples showing Praat script → R translation
   - Add tests comparing against known Praat output
   - Update package documentation

4. **Testing Phase**
   - Unit tests for each method
   - Integration tests for method chains
   - Comparison tests against Praat output
   - Parselmouth parity tests (if applicable)

#### Implementation Time Estimates

| Object Type | Implementation | C++ Bindings | Stubs | Testing | Total |
|-------------|----------------|--------------|-------|---------|-------|
| Simple (Tier) | 0.5-1 day | 0.5 day | 0.5 day | 0.5 day | **2-2.5 days** |
| Medium (Spectrum, Ltas) | 1-2 days | 1 day | 1 day | 0.5 day | **3.5-4.5 days** |
| Complex (TextGrid, FormantPath) | 2-4 days | 1-2 days | 1-2 days | 1 day | **5-9 days** |

### Parselmouth Translation Examples

These examples show how superassp Python code should translate to speaker R code:

**Example 1: Intensity Analysis**
```python
# Python (Parselmouth)
intensity = pm.praat.call(sound, "To Intensity", min_pitch, time_step, subtract_mean)
intensity_tier = pm.praat.call(intensity, "Down to IntensityTier")
table_of_real = pm.praat.call(intensity_tier, "Down to TableOfReal")
```

```r
# R (speaker)
intensity <- sound$to_intensity(min_pitch, time_step, subtract_mean)
intensity_tier <- intensity$down_to_intensity_tier()
table_of_real <- intensity_tier$down_to_table_of_real()
```

**Example 2: FormantPath Tracking**
```python
# Python (Parselmouth)
formant_path = pm.praat.call(sound, "To FormantPath (burg)", 
                             time_step, num_formants, max_formant, ...)
formant = pm.praat.call(formant_path, "Extract Formant")
```

```r
# R (speaker) - TO BE IMPLEMENTED
formant_path <- sound$to_formant_path_burg(
  time_step, num_formants, max_formant, ...)
formant <- formant_path$extract_formant()
```

### Package Evolution Strategy

**Current State (v0.3.0)**:
- ✅ Core objects: Sound, Pitch, Formant, Intensity, Harmonicity, PointProcess
- ✅ Manipulation objects: Manipulation, PitchTier, IntensityTier, DurationTier
- ✅ Basic spectral: Spectrogram (partial)
- ✅ R6 architecture with external pointers
- ✅ av package integration for audio I/O

**Next Release (v0.4.0)** - Missing Critical Objects:
- ⬜ TextGrid (intervals + points) - PRIORITY 1
- ⬜ FormantPath - PRIORITY 2
- ⬜ Spectrum - PRIORITY 3
- ⬜ Ltas - PRIORITY 3
- ⬜ Enhanced Spectrogram methods

**Future Release (v0.5.0)** - Advanced Features:
- ⬜ FormantGrid
- ⬜ Cochleagram
- ⬜ LPC
- ⬜ Excitation
- ⬜ MFCC (if demanded)

**Long-term (v1.0+)** - Potential Extensions:
- ⬜ Praat script interpreter (execute .praat files)
- ⬜ ggplot2-based visualization functions
- ⬜ Parallel processing for batch analysis
- ⬜ Streaming audio support

---

**Updated**: 2025-11-10  
**Next Review**: After TextGrid implementation

