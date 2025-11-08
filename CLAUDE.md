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
- R 4.0+ with C++17 (upgraded for Praat source compatibility) (001-praat-r-access)
- R6 OOP framework (for object-oriented Praat interface) (001-praat-r-access)
- N/A (in-memory audio processing, no persistent storage) (001-praat-r-access)

## Recent Changes
- 001-praat-r-access: Upgraded to C++17 for Praat source compatibility
- 001-praat-r-access: Adopted R6-based object-oriented architecture

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

### Reference Documentation

**Key Planning Documents:**
- `specs/001-praat-r-access/COMPREHENSIVE-OOP-PLAN.md` - Master implementation plan
- `specs/001-praat-r-access/NAMING-CONVENTIONS.md` - Naming standards
- `COMPREHENSIVE_OOP_ROADMAP.md` - High-level roadmap

**Implementation Status:**
- `OOP_IMPLEMENTATION_COMPLETE_STATUS.md` - Current progress tracking

---

*This architecture enables systematic, consistent integration of Praat objects into R, following proven patterns from Parselmouth while leveraging R's strengths.*
