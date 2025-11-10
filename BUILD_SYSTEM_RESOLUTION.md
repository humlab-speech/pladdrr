# Build System Resolution Summary

**Date:** 2025-11-09  
**Session:** Build system fix for Praat source integration

## Problem Identified

The speaker package was failing to build because R's build system was compiling **959 .cpp files** instead of the ~120 we actually need. This was caused by having **directory symlinks** to Praat source folders (fon/, melder/, etc.), which R automatically recurses into and compiles everything.

## Solution Implemented

### 1. Migrate from Directory to File Symlinks

**Before:**
```
src/fon -> praat.github.io/fon/       (directory symlink)
src/melder -> praat.github.io/melder/ (directory symlink)
...
```
R would compile ALL .cpp files in these directories (959 total).

**After:**
```
src/fon/Sound.cpp -> praat.github.io/fon/Sound.cpp          (file symlink)
src/fon/Pitch.cpp -> praat.github.io/fon/Pitch.cpp          (file symlink)
src/melder/melder.cpp -> praat.github.io/melder/melder.cpp  (file symlink)
...
```
Now only the **122 specific files** listed in Makevars are compiled.

**Implementation:**
- Created `src/migrate_to_file_symlinks.sh` script
- Removes directory symlinks
- Creates real directories (kar/, melder/, sys/, stat/, fon/)
- Symlinks only the specific .cpp files listed in Makevars

### 2. Add Stub Files for NO_GUI/NO_GRAPHICS Build

Since Praat is designed as a GUI application, some source files reference graphics and GUI functions even when built with `NO_GUI` and `NO_GRAPHICS` flags.

#### Graphics Stubs (`graphics_stubs_comprehensive.cpp`)
- Stubs for ~60 `Graphics_*` functions
- Required by: Matrix.cpp, Cochleagram.cpp
- Functions: Graphics_grey, Graphics_line, Graphics_mark, Graphics_text, etc.
- All functions are no-ops (do nothing)

#### UiForm Stubs (`uiform_stubs.cpp`)
- Stubs for ~20 `UiForm_*` functions
- Required by: Interpreter.cpp (interactive forms)
- Functions: UiForm_create, UiForm_addReal, UiForm_getString, etc.
- All functions return null/0/false

### 3. Current Build Status

**Compilation:** ✅ SUCCESS (122 files compile cleanly)
**Linking:** ✅ SUCCESS (speaker.so created)
**Loading:** ⚠️ PARTIAL - Still needs Demo_* GUI stubs

**Last error:**
```
symbol not found: __Z14Demo_clickedIndddd
```

This is `Demo_clickedIn(double, double, double, double)`, which is called by GUI demo code in Interpreter.cpp.

## Remaining Work

### Option A: Add More Stubs (Current Path)
Continue adding stubs for Demo_*, Gui_*, etc. functions.

**Pros:**
- Keeps Interpreter/Formula/Script functionality
- More complete Praat feature set

**Cons:**
- Potentially dozens more stub functions needed
- Increases maintenance burden
- These are GUI functions we'll never actually use

### Option B: Remove Interpreter/Formula/Script (RECOMMENDED)
Remove these files from the build since they're primarily for GUI scripting:
- `src/sys/Interpreter.cpp`
- `src/sys/Formula.cpp`
- `src/sys/Script.cpp`

**Pros:**
- Cleaner build with fewer stubs
- These are GUI-focused modules not needed for library use
- Reduces potential future build issues

**Cons:**
- Loses Praat formula/scripting capabilities
- May need to re-add later if we want scripting support

**Analysis Required:**
```bash
# Check if fon/*.cpp actually uses these functions
nm -u src/fon/*.o | grep -i "formula\|interpreter\|script" | wc -l
```

If fon/ objects don't depend on them, we can safely remove them.

## Files Changed

### New Files
- `src/migrate_to_file_symlinks.sh` - Migration script
- `src/graphics_stubs_comprehensive.cpp` - Graphics stubs
- `src/generate_graphics_stubs.sh` - Generator for graphics stubs
- `src/uiform_stubs.cpp` - UiForm stubs
- `IMPLEMENTATION_STATUS_CURRENT.md` - Current status doc
- `BUILD_SYSTEM_RESOLUTION.md` - This file

### Modified Files
- `src/Makevars` - Updated WRAPPER_SRC list
- 122 new symlinks in src/fon/, src/melder/, src/sys/, src/stat/, src/kar/

### Deleted
- Old directory symlinks: src/fon, src/melder, src/sys, src/stat, src/dwsys, src/kar

## Testing Commands

```bash
# Count .cpp files being compiled
find src -name "*.cpp" -type l | wc -l  # Should be ~122

# Check compilation
R CMD INSTALL --preclean .

# Check for undefined symbols
nm -u src/speaker.so | grep -v "^_R" | head -20

# Test if package loads
R -e "library(speaker)"
```

## Next Steps

1. **Decision:** Choose Option A or B above
2. **If Option A:** Add Demo_* and remaining GUI stubs
3. **If Option B:** Remove Interpreter/Formula/Script from Makevars, test build
4. **Once building:** Test basic functionality (Sound creation, pitch extraction)
5. **Proceed with:** Implementation of remaining objects (TextGrid, Manipulation, etc.)

## Lessons Learned

1. **R build system quirk:** Symlinked directories are fully recursed and all .cpp files compiled
2. **Solution:** Only symlink specific files, not directories
3. **NO_GUI doesn't mean no GUI code:** Many Praat files still reference GUI functions
4. **Stub strategy:** Create minimal stubs matching exact C++ signatures
5. **Type matters:** `long` vs `long long` (`integer`) creates different mangled names

## References

- Makevars source list: Lines 55-114
- Praat source: src/praat.github.io/
- Build log: Check `R CMD INSTALL` output
- Symbol checking: `nm -u file.o`, `c++filt` for demangling

---

**Status:** Build system 95% complete, ready for final decision on Interpreter/Formula/Script
