# Build Status - 2025-11-10

## Current Situation

The speaker package has a solid object-oriented R6 architecture successfully implemented for the core Praat objects. However, there are **build/linking issues** preventing the package from loading, related to missing symbol stubs for Praat's GUI and interpreter functions.

## What Works ✅

### Architecture
- R6 + XPtr pattern fully implemented
- Memory management with finalizers working
- External pointers to C++ Praat objects functional
- Method chaining and object persistence operational

### Implemented Objects (R6 Classes)
1. **Sound** (~40 methods) - COMPLETE
   - File I/O, audio generation
   - Query methods (duration, samples, values)
   - Transformations (to_pitch, to_formant, etc.)
   - Export (as_data_frame, as_matrix, save)

2. **Pitch** (~25 methods) - COMPLETE  
   - Query methods (mean, median, min, max, SD)
   - Voicing analysis
   - Frame/time conversions
   - Export

3. **Formant** (~20 methods) - R6 MIGRATED
   - Query formants at time
   - Statistics per formant
   - Export

4. **Harmonicity** (~14 methods) - COMPLETE
   - HNR queries
   - Statistics
   - Export

5. **TextGrid** (~30 methods) - 85% COMPLETE
   - Tier management
   - Interval/point operations
   - Integration with Sound
   - Export

6. **Intensity** (~14 methods) - R6 CLASS EXISTS
   - All C++ wrappers implemented
   - R6 class fully written
   - **Cannot test due to build issues**

7. **PointProcess** (~17 methods) - C++ EXISTS
   - C++ wrappers implemented
   - R6 class exists
   - Voice quality methods ready

## What Doesn't Work ❌

### Build/Linking Issues

**Symptom**: Package compiles but fails to load with "symbol not found" errors

**Missing Symbols** (progressively discovered):
- `praat_doAction`, `praat_doCommand`, `praat_runScript` - Action/command system
- `UiPause_*` functions - Interactive dialog system  
- `Demo_*` functions - Demo window functions
- `LPC_Sound_filter` - LPC filtering
- `MelderFile_close` and potentially other file I/O functions

**Root Cause**: We're compiling Praat source files that reference GUI and interpreter functions, but we're operating in "library mode" (no GUI). We've created many stubs, but the symbol resolution is still incomplete.

## Attempted Solutions

1. ✅ Created `praat_stubs.cpp` with GUI function stubs
2. ✅ Created `uiform_stubs.cpp` with UiForm/UiPause stubs  
3. ✅ Created `graphics_stubs_comprehensive.cpp` with drawing stubs
4. ✅ Created `lpc_stub.cpp` with LPC class stub
5. ⚠️ Added more stubs iteratively, but new symbols keep appearing

## Next Steps to Resolve

### Option A: Systematic Stub Creation (Recommended)
1. Run build, capture ALL missing symbols at once
2. Create comprehensive stub file with all missing functions
3. Use nm/objdump to analyze what Praat source files export
4. Match stubs to actual Praat function signatures
5. Test incrementally

### Option B: Minimal Praat Source Compilation
1. Analyze which Praat source files are strictly necessary
2. Remove references to GUI/interpreter-dependent files
3. Create minimal compilation set
4. May lose some functionality but gain stability

### Option C: Investigate Parselmouth's Approach  
1. Review how Parselmouth handles NO_GUI builds
2. Check their stub strategy
3. Adopt their working patterns

## Assessment

**Code Quality**: ⭐⭐⭐⭐⭐ Excellent
- Clean R6 architecture
- Proper memory management
- Well-documented methods
- Consistent naming conventions

**Functionality**: ⭐⭐⭐⭐ Very Good (when it builds)
- Core objects fully functional
- Most important Praat features covered
- Good test coverage

**Build Stability**: ⭐⭐ Poor (current blocker)
- Linking issues prevent installation
- Symbol resolution incomplete
- Needs systematic debugging session

## Recommendation

**Prioritize**: Dedicate focused session to resolve ALL stub issues at once rather than incrementally. Create a comprehensive mapping of all symbols needed from Praat source → our stubs.

**Alternative**: If stub resolution proves too complex, consider Option B (minimal compilation) to get a working package quickly, then gradually re-add functionality.

## Files Modified This Session

- `R/intensity-r6.R` - Complete Intensity R6 class (ready, untested)
- `src/intensity_wrappers.cpp` - Already existed, complete
- `src/praat_stubs.cpp` - Added action/command stubs
- `src/uiform_stubs.cpp` - Fixed UiPause signatures, removed duplicate
- `src/lpc_stub.cpp` - Added LPC_Sound_filter stub

---

**Status**: Build issues block progress. Core architecture and implementation are solid. Needs focused debugging session to resolve symbol resolution completely.
