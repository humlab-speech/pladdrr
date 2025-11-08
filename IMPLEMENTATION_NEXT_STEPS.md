# Speaker Package - Next Implementation Steps

**Date**: 2025-11-08  
**Current Status**: Plan Complete, Build System Partial  
**Blocker**: Praat Source Compilation

## Summary

The comprehensive OOP implementation plan is complete and committed (see `specs/001-praat-r-access/FINAL-OOP-IMPLEMENTATION-PLAN.md`). The architecture has been designed:

✅ R6 classes defined  
✅ C++ wrapper patterns established  
✅ XPtr memory management implemented  
✅ Naming conventions finalized  
✅ 12-week roadmap created  

❌ Praat source compilation incomplete  
❌ Build system needs Praat objects  

## Current Build Issue

**Problem**: Package compiles C++ wrappers successfully but linking fails with undefined symbols from Praat:

```
symbol not found in flat namespace '_Melder_peek8to32'
```

**Root Cause**: We're calling Praat functions but not compiling/linking the Praat source code itself.

## Two Paths Forward

### Option 1: Full Praat Compilation (Recommended for Complete Functionality)

**Approach**: Compile all necessary Praat source files into the package

**Steps**:
1. Identify minimal set of Praat .cpp files needed for Sound, Pitch, Formant, etc.
2. Add these to `src/Makevars` compilation list
3. Ensure all dependencies are included (melder, sys, NUM, etc.)
4. Handle platform-specific compilation (macOS, Linux, Windows)
5. Deal with Praat's build dependencies (might be extensive)

**Pros**:
- Full access to all Praat functionality
- No external dependencies
- True standalone R package

**Cons**:
- Complex build system
- Large package size
- Maintenance burden when Praat updates
- Windows compilation challenges

**Estimated Effort**: 2-4 weeks for initial setup, ongoing maintenance

### Option 2: Link to System Praat Library (Faster, Limited)

**Approach**: If a Praat shared library exists, link against it

**Steps**:
1. Check if Praat can be compiled as a shared library (.dylib, .so, .dll)
2. Add to SystemRequirements in DESCRIPTION
3. Update Makevars to link against system library
4. Provide installation instructions for users

**Pros**:
- Smaller package
- Easier to maintain
- Delegates Praat compilation to system

**Cons**:
- Users must install Praat library separately
- Platform-specific installation complexity
- May not exist as a shared library
- CRAN might reject external dependency

**Estimated Effort**: 1-2 weeks if library exists, otherwise not viable

### Option 3: Minimal Praat Subset (Pragmatic)

**Approach**: Only compile the absolutely necessary Praat files for core functionality

**Steps**:
1. Start with just Sound object
2. Compile minimal set: melder, sys, NUM, Sound.cpp, Sound_audio.cpp
3. Get Sound working end-to-end
4. Gradually add more objects (Pitch, Formant, etc.)
5. Each addition brings in more Praat dependencies

**Pros**:
- Incremental approach
- Can release partial functionality early
- Learn build system gradually
- Smaller initial scope

**Cons**:
- Still complex
- May hit dependency cascade
- Might end up needing most of Praat anyway

**Estimated Effort**: 1-2 weeks for Sound, 1 week per additional object type

## Recommended Approach: Option 3 (Minimal Subset)

Start small and iterate:

### Phase 1: Sound Object Only (Week 1-2)

**Goal**: Get one complete object working end-to-end

**Tasks**:
1. Identify minimal Praat files for Sound:
   - `melder/melder.cpp` (core utilities)
   - `sys/Thing.cpp` (base object)
   - `sys/Collection.cpp`
   - `sys/Data.cpp`
   - `sys/Simple.cpp`
   - `fon/Function.cpp`
   - `fon/Sampled.cpp`
   - `fon/Sound.cpp`
   - `fon/Sound_audio.cpp`
   - `NUM/NUM*.cpp` (numerical routines)

2. Add to `src/Makevars`:
   ```make
   PRAAT_SOURCES = \
     praat.github.io/melder/melder.cpp \
     praat.github.io/sys/Thing.cpp \
     praat.github.io/sys/Collection.cpp \
     ...

   OBJECTS = RcppExports.o sound_wrappers.o $(PRAAT_SOURCES:.cpp=.o)
   ```

3. Handle compilation flags for Praat code
4. Test Sound creation, query methods, export
5. Write unit tests for Sound

**Success Criteria**:
```r
library(speaker)
sound <- Sound$new("test.wav")
duration <- sound$get_duration()
df <- sound$as_data_frame()
```

### Phase 2: Add Pitch (Week 2-3)

**Incremental Dependencies**:
- `fon/Pitch.cpp`
- `fon/Pitch_def.h`
- `fon/Sound_to_Pitch.cpp`
- Additional NUM functions for autocorrelation

**Success Criteria**:
```r
pitch <- sound$to_pitch()
mean_f0 <- pitch$get_mean()
```

### Phase 3: Add Formant (Week 3-4)

**Incremental Dependencies**:
- `fon/Formant.cpp`
- `fon/Sound_to_Formant.cpp`
- `LPC/LPC.cpp` (for Burg's algorithm)

### Phase 4: TextGrid (Week 5-6)

**Critical Feature**:
- `fon/TextGrid.cpp`
- `fon/IntervalTier.cpp`
- `fon/TextTier.cpp`

## Immediate Next Actions

1. **Survey Praat Source Structure**
   ```bash
   cd src/praat.github.io
   find . -name "*.cpp" | grep -E "(melder|sys|fon)" | wc -l
   ```
   Understand scope of what needs to be compiled

2. **Create Minimal Makevars**
   Start with absolute minimal set for Sound

3. **Test Compilation**
   ```bash
   R CMD INSTALL --preclean .
   ```
   Debug linker errors one by one

4. **Document Dependencies**
   Keep list of which Praat files are needed for each object type

5. **Consider Helper Script**
   Create `tools/find_praat_dependencies.R` to automatically detect needed files

## Alternative: Hybrid Approach

If full Praat compilation proves too difficult:

**Use Existing S3 Implementation** + **Add R6 Wrapper Layer**

1. Keep current working S3 functions (extract_pitch, etc.)
2. Create thin R6 wrapper that calls S3 functions
3. Provides OOP interface without needing full Praat compilation

```r
# Hybrid approach
Sound <- R6Class("Sound",
  public = list(
    initialize = function(path) {
      private$s3_sound <- read_sound(path)  # Use existing S3
    },
    
    get_duration = function() {
      get_duration(private$s3_sound)  # Delegate to S3
    },
    
    to_pitch = function(...) {
      s3_pitch <- extract_pitch(private$s3_sound, ...)
      Pitch$new(.from_s3 = s3_pitch)
    }
  ),
  private = list(
    s3_sound = NULL
  )
)
```

**Pros**:
- Get OOP interface quickly
- Use existing working code
- No build system complexity

**Cons**:
- Still limited to current S3 functionality
- Missing TextGrid, Manipulation, etc.
- Not leveraging full Praat codebase

## Decision Point

**Recommendation**: Attempt Option 3 (Minimal Subset) for 1-2 weeks

If successful → Continue adding objects incrementally  
If too difficult → Fall back to Hybrid Approach  
If Hybrid insufficient → Re-evaluate full Praat compilation or external library

The key is to get SOMETHING working end-to-end before committing to the full build complexity.

## Resources Needed

1. **Praat Build Documentation**
   - Check Praat's own Makefile for compilation order
   - Look for Praat library/shared object build instructions
   - Study Parselmouth's build system (uses pybind11 + CMake)

2. **Rcpp + Large C++ Library Examples**
   - Find R packages that wrap large C++ codebases
   - Study their Makevars/Makevars.win
   - Learn from packages like Rstan, arrow, sf

3. **Platform Testing**
   - Set up CI/CD for macOS, Linux, Windows
   - GitHub Actions can test builds automatically

## Timeline Estimate

| Approach | Initial Working | Complete (16 objects) | CRAN Ready |
|----------|-----------------|----------------------|------------|
| Full Praat | 4 weeks | 12 weeks | 16 weeks |
| Minimal Subset | 2 weeks | 10 weeks | 14 weeks |
| Hybrid | 1 week | 6 weeks | 8 weeks |
| External Lib | 2 weeks (if exists) | 10 weeks | 12 weeks |

## Conclusion

The OOP plan is excellent and well-thought-out. The challenge is **purely in the build system**. This is a solvable engineering problem, but requires dedicated effort on the C++ compilation side.

**Next Session Should Focus On**:
1. Getting minimal Sound object compiling and linking
2. Creating working example: read audio → query duration → export
3. Once that works, everything else follows the same pattern

**Success Metric**: 
```r
# This should work
library(speaker)
s <- Sound$new("test.wav")
print(s)
# <Praat Sound>
#   Duration: 1.234 s
#   Sampling frequency: 44100 Hz
```

When that works, we'll know the architecture is sound and can proceed with full implementation.
