# Praat Source Integration Progress - November 8, 2025

## Current Status

**Objective**: Integrate Praat C++ source code compilation into the speaker R package build process

**Progress**: Structural changes complete, compilation blocked by R build system limitations

## What Was Done Today

### 1. Complete OOP Amendment (✅ COMPLETE)
- Created `OOP_AMENDMENT_FINAL.md` - definitive master plan
- Documented all 30 Praat objects with 400+ methods
- Established 10-week implementation roadmap
- Defined naming conventions and migration paths
- Version bumped to 0.2.1

### 2. Implementation Status Documentation (✅ COMPLETE)
- Created `IMPLEMENTATION_STATUS_20251108.md`
- Analyzed current state: 7 objects, 165+ methods coded
- Identified critical blocker: Praat C++ source compilation
- Evaluated three forward paths (Option A recommended)

### 3. Build System Integration (🚧 IN PROGRESS)
- ✅ Created symbolic links: src/melder, src/sys, src/dwsys, src/stat, src/fon → praat.github.io/*
- ✅ Updated Makevars with Praat-specific compiler flags
- ✅ Listed all required Praat source files (based on Parselmouth CMakeLists.txt)
- ❌ **BLOCKED**: R's build system doesn't support subdirectory compilation out-of-the-box

## The Technical Challenge

### Problem
R CMD INSTALL expects all C++ source files to be directly in `src/` directory or needs explicit Make rules for subdirectories. Current error:

```
make: *** No rule to make target `melder/melder_strings.o', needed by `speaker.so'.  Stop.
```

### Root Cause
- Praat has ~270 C++ files across multiple subdirectories (melder/, sys/, dwsys/, stat/, fon/)
- R's default build process uses a flat source structure
- Makevars SOURCES variable with subdirectory paths doesn't automatically create build rules

### What Doesn't Work
1. ❌ Listing subdirectory sources in SOURCES (tried)
2. ❌ Using vpath (incompatible with R's Makefile)
3. ❌ Wild cards for subdirectories (tried)

### What Might Work (Not Yet Tried)

#### Option 1: Custom Build Rules (Recommended)
Create explicit Make rules for each subdirectory:

```makefile
# In src/Makevars
melder/%.o: melder/%.cpp
	$(CXX) $(ALL_CPPFLAGS) $(ALL_CXXFLAGS) -c $< -o $@

fon/%.o: fon/%.cpp
	$(CXX) $(ALL_CPPFLAGS) $(ALL_CXXFLAGS) -c $< -o $@

# etc for each subdirectory
```

#### Option 2: Configure Script with File Copying
Create `configure` script that:
1. Copies necessary Praat .cpp files from praat.github.io/* to src/ (flat structure)
2. Generates appropriate .gitignore entries
3. Cleans up on `make clean`

#### Option 3: Minimal Subset Approach
Start with absolute minimum Praat files needed for Sound object only:
- ~10 melder files
- ~5 sys files  
- ~5 fon files
- Copy these manually to src/ as a proof of concept
- Expand incrementally

#### Option 4: Static Praat Library
Pre-compile Praat as a static library (.a) separately:
1. Use CMake to build libpraat.a  
2. Link against it in PKG_LIBS
3. Distribute pre-built libraries for each platform

## Recommended Next Steps

### Immediate (Next Session) - Option 3: Minimal Proof of Concept

1. **Identify absolute minimum files for Sound object**:
   ```bash
   # Copy just enough to get Sound$new() working
   cp praat.github.io/melder/melder.cpp src/
   cp praat.github.io/melder/melder_alloc.cpp src/
   # ... (10-15 core files)
   cp praat.github.io/fon/Sound.cpp src/
   cp praat.github.io/fon/Sound_files.cpp src/
   ```

2. **Update Makevars for flat structure**:
   ```makefile
   SOURCES = melder.cpp melder_alloc.cpp ... Sound.cpp sound_wrappers.cpp RcppExports.cpp
   ```

3. **Test build**:
   ```bash
   R CMD INSTALL . --preclean
   ```

4. **If successful, test Sound object**:
   ```r
   library(speaker)
   sound <- Sound$new("test.wav")
   sound$get_duration()
   ```

5. **Document minimal working set**, then expand incrementally

### Short-term (This Week) - Scale to All Objects

Once minimal build works:
1. Add files for Pitch object
2. Add files for Formant, Intensity, Harmonicity
3. Add files for PointProcess
4. Test jitter/shimmer calculations
5. Document the final working file list

### Medium-term (Next Week) - Production Build System

Choose between:
- **Option 1**: Custom Makevars rules (most R-native)
- **Option 4**: Pre-compiled static library (most maintainable)

Implement chosen approach for all 270 Praat files.

## Key Files

### Created/Modified Today
- `OOP_AMENDMENT_FINAL.md` - Master implementation plan
- `IMPLEMENTATION_STATUS_20251108.md` - Status analysis
- `src/Makevars` - Updated with Praat flags and source lists (needs fixing)
- `src/melder`, `src/sys`, etc. - Symbolic links to praat.github.io/* (created)
- `PRAAT_SOURCE_INTEGRATION.md` (this file)

### Critical Next Edits
- `src/Makevars` - Simplify to flat structure or add custom rules
- Possibly: `configure` or `configure.ac` - For automated setup

## Dependencies Analysis

Based on Parselmouth CMakeLists.txt, minimum Praat dependencies are:

### Melder (core - ~30 files needed)
Essential:
- melder.cpp, melder_alloc.cpp, melder_str32.cpp
- melder_error.cpp, melder_info.cpp, melder_files.cpp
- NUM.cpp, VEC.cpp, MAT.cpp, STR.cpp, STRVEC.cpp
- NUMmath.cpp, NUMrandom.cpp

### Sys (core - ~5-10 files needed)
Essential:
- Thing.cpp, Data.cpp, Simple.cpp, Collection.cpp

### Fon (phonetics - ~60 files needed for current objects)
For Sound, Pitch, Formant, Intensity, Harmonicity, PointProcess, TextGrid:
- Function.cpp, Sampled.cpp, SampledXY.cpp, Matrix.cpp, Vector.cpp
- Sound.cpp, Sound_files.cpp, Sound_audio.cpp
- Pitch.cpp, Sound_to_Pitch.cpp
- Formant.cpp, Sound_to_Formant.cpp
- Intensity.cpp, Sound_to_Intensity.cpp
- Harmonicity.cpp, Sound_to_Harmonicity.cpp
- PointProcess.cpp, PointProcess_and_Sound.cpp, VoiceAnalysis.cpp
- TextGrid.cpp, TextGrid_Sound.cpp, Label.cpp
- Plus all *Tier objects for manipulation

**Total minimum**: ~100 files (not 270)

## Conclusion

The speaker package has achieved major milestones:
- ✅ Complete OOP architecture defined
- ✅ R6 classes for 7 objects with 165+ methods
- ✅ C++ wrappers fully coded
- ✅ Praat source code available and analyzed

**One remaining challenge**: Integrate Praat C++ compilation into R's build system.

**Estimated time to resolution**: 
- Minimal proof of concept: 2-4 hours
- Full integration: 1-2 days
- Production-ready multi-platform build: 1 week

**Next commit should**:
- Implement Option 3 (minimal subset)
- Get Sound object working end-to-end
- Validate the entire architecture with real Praat functionality
- Then expand to remaining objects

The finish line is close - we have all the pieces, just need to wire them together correctly.
