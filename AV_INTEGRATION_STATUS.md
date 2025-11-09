# AV Package Integration Status

## Date: 2025-11-09

## Objective
Integrate the `av` package (humlab-speech fork: https://github.com/humlab-speech/av) for media loading into the speaker package, allowing flexible audio format support via FFmpeg.

## Decisions Made

### 1. Media Loading Strategy (Option D)
- **Chosen Approach**: Dual loading path
  - Primary: Use `av` package for loading diverse formats (MP3, OGG, FLAC, etc.)
  - Fallback: Direct Praat file I/O for WAV/AIFF
- **Rationale**: 
  - Consistency with other humlab-speech packages
  - Wide format support without implementing codecs in C++
  - Maintains compatibility with Praat's native loaders

### 2. Implementation Changes

####Changed Files:
1. **DESCRIPTION**: Added `av` to Imports
2. **CLAUDE.md**: Documented media loading decision and architecture
3. **R/sound-r6-new.R**: Updated `Sound$initialize()` to:
   - Auto-detect file format
   - Use `av` for non-WAV formats
   - Fall back to Praat loader for WAV/AIFF
   - Added `Sound$from_matrix()` alias for av workflow

#### Updated API:
```r
# Load any format via av
sound <- Sound$new("audio.mp3")

# From av-loaded matrix
audio_mat <- av::read_audio_fft("file.mp3", window = NULL, overlap = 0)
sound <- Sound$from_matrix(t(audio_mat), sample_rate = 44100)

# Direct Praat loader (WAV)
sound <- Sound$new("file.wav", use_av = FALSE)
```

## Build Issues Encountered

### Problem: Complex Praat Source Dependencies
When integrating av support, we discovered that R's build system compiles ALL .cpp files in symlinked directories, leading to:

1. **Unexpected compilations**: ~78 fon/*.cpp files compiled vs ~40 specified in Makevars
2. **Missing symbols**: Compiled files reference classes not in build:
   - `classLongSound` - very long audio files (not needed)
   - `classLPC` - linear predictive coding (internal use)
   - `theCurrentPraatApplication` - GUI application context
   - `theCurrentPraatObjects` - GUI object list  
   - `theMelder_error_threadId` - threading internals

### Attempted Solutions

1. **Created stub files**:
   - `src/longsound_stub.cpp` - LongSound class stub
   - `src/lpc_stub.cpp` - LPC class stub
   - `src/num_stubs.cpp` - PraatApplication, PraatObjects, statistical functions
   
2. **Excluded unnecessary sources**:
   - Moved GUI-related cpp files to `src/excluded_sources/`
   - Removed: LongSound.cpp, manual_*.cpp, praat_*.cpp, etc.

3. **Current blocker**: Deep Melder threading symbols
   - `_theMelder_error_threadId` and related threading infrastructure
   - These are internal to Melder's error handling system
   - Require either:
     a) Compiling more Melder source files with threading
     b) Providing complete threading stubs
     c) Refactoring build approach

## Recommended Next Steps

### Short-term (Complete av Integration)

**Option A: Stub Remaining Melder Symbols**
- Identify all missing Melder internal symbols
- Create comprehensive stub file for Melder threading/error internals
- Risk: May hit more dependencies

**Option B: Modular Build Approach** (RECOMMENDED)
- Move Praat sources to `src/praat_src/` subdirectory
- Explicitly symlink ONLY needed .cpp files to `src/`
- Gives precise control over compilation
- Cleaner separation of Praat vs wrapper code

**Option C: Static Praat Library**
- Compile Praat sources separately as static library
- Link against library in R package
- Most robust but requires more build infrastructure

### Medium-term (Improve Architecture)

1. **Document minimum Praat source set**
   - Create definitive list of required .cpp files
   - Document dependencies between Praat modules
   - Automate extraction from Praat source

2. **Enhance build system**
   - Add configure script to detect/setup Praat sources
   - Platform-specific Makevars (Makevars.win, etc.)
   - Validation tests for Praat integration

3. **Testing with av**
   - Once build succeeds, test av loading with various formats
   - Benchmark av vs native Praat loaders
   - Document format support matrix

## Files Modified (This Session)

- `DESCRIPTION` - Added av dependency
- `CLAUDE.md` - Documented av integration decision
- `R/sound-r6-new.R` - Dual-path loading with av support
- `src/Makevars` - Added stub files to build
- `src/longsound_stub.cpp` - NEW
- `src/lpc_stub.cpp` - NEW  
- `src/num_stubs.cpp` - Enhanced with Praat GUI stubs
- `src/excluded_sources/` - NEW directory with excluded cpp files

## Status: IN PROGRESS

Build currently fails at link stage due to missing Melder threading symbols.
Recommend Option B (Modular Build) for clean resolution.

## Related Documentation

- Media loading decision: `CLAUDE.md` lines 532-609
- Praat OOP architecture: `CLAUDE.md` lines 87-531
- Build configuration: `src/Makevars`

