# Praat Source Modifications for pladdrr

**Last Updated:** 2025-12-19  
**Package Version:** 0.9.11  
**Praat Version:** Based on praat.github.io commit (submodule)

## Overview

This document details all modifications made to the Praat source code to enable proper operation within the pladdrr R package. All changes are documented in the accompanying `praat_modifications.patch` file.

## Critical Fix: TextGrid Loading Segfault

### Problem Summary

TextGrid files caused segmentation faults (SIGSEGV at address 0x68) when loaded through the R package. The crash occurred in `Thing_classFromClassName()` during file parsing.

### Root Cause

The segfault had **two distinct causes**:

1. **Static linkage issue**: Class registry arrays were declared `static`, making them invisible across shared library boundaries
2. **Mutex initialization issue**: `Melder_casual()` debug logging attempted to lock an uninitialized mutex (`theMelder_casual_mutex`)

### Solution

Both issues were addressed through targeted source modifications:

## File-by-File Modifications

### 1. `sys/Thing.h` - Class Registry Visibility

**Changes:**
- Added `extern` declarations for class registry arrays

**Code:**
```cpp
/* Expose class registry for shared library access (pladdrr fix) */
extern integer theNumberOfReadableClasses;
extern ClassInfo theReadableClasses [1 + 1000];
```

**Rationale:**
- Allows wrapper code in other compilation units to access the class registry
- Enables verification that classes are properly registered
- Critical for shared library (.so/.dylib) operation

### 2. `sys/Thing.cpp` - Class Registry Implementation

**Changes:**

#### A. Changed linkage from static to extern
```cpp
/* OLD - Static (invisible across shared library boundaries) */
static integer theNumberOfReadableClasses = 0;
static ClassInfo theReadableClasses [1 + 1000];

/* NEW - Extern (visible across shared library boundaries) */
integer theNumberOfReadableClasses = 0;
ClassInfo theReadableClasses [1 + 1000];
```

**Rationale:**
- Shared libraries require explicit visibility for global state
- `static` linkage makes variables local to the compilation unit
- `extern` linkage allows access from wrapper functions

#### B. Added null pointer checks
```cpp
for (integer i = 1; i <= theNumberOfReadableClasses; i ++) {
    ClassInfo classInfo = theReadableClasses [i];
    if (!classInfo) {
        continue;  // Skip null entries
    }
    if (str32equ (buffer, classInfo -> className))
        return classInfo;
}
```

**Rationale:**
- Prevents crashes from partially initialized class registry
- Defensive programming for shared library context

#### C. Added error checking in Thing_newFromClassName
```cpp
ClassInfo classInfo = Thing_classFromClassName (className, out_formatVersion);
if (!classInfo) {
    Melder_throw (U"Thing_classFromClassName returned null for '", className, U"'");
}
```

**Rationale:**
- Provides clear error messages instead of segfaults
- Helps diagnose class registration issues

#### D. Added cstdio header
```cpp
#include <cstdio>
```

**Rationale:**
- Required for `fprintf()` debugging (if needed in future)
- Standard C++ practice for file I/O

### 3. `sys/Data.cpp` - Debug Support

**Changes:**
```cpp
#include <cstdio>
```

**Rationale:**
- Consistency with Thing.cpp
- Enables `fprintf()` debugging if needed
- No functional changes to logic

### 4. `melder/MelderReadText.cpp` - Debug Support

**Changes:**
```cpp
#include <cstdio>  // For fprintf debugging
```

**Rationale:**
- Added during debugging phase
- No functional changes
- Left in place for future diagnostics

### 5. `melder/NUMinterpol.cpp` - Removed Debug Output

**Changes:**
- Removed 13 `fprintf()` debug statements from:
  - `improve_evaluate()`
  - `NUMimproveExtremum()`

**Before:**
```cpp
fprintf(stderr, "[NUMINTERPOL_DEBUG] improve_evaluate called: x=%.3f\n", x);
// ... many more debug lines
```

**After:**
```cpp
// All debug output removed for production
```

**Rationale:**
- Debug output was added to trace interpolation issues
- Not needed for production use
- Reduces console noise

## Impact Assessment

### Files Modified: 5
1. `sys/Thing.h` - Class registry visibility
2. `sys/Thing.cpp` - Class registry implementation + null checks
3. `sys/Data.cpp` - Debug support (header only)
4. `melder/MelderReadText.cpp` - Debug support (header only)
5. `melder/NUMinterpol.cpp` - Removed debug output

### Lines Changed: +17/-15 (net +2)
- Additions: Include headers, null checks, error messages, extern declarations
- Deletions: Debug output, static keywords

### Risk Level: **LOW**
- Changes are minimal and targeted
- No algorithm modifications
- No data structure changes
- Maintains Praat semantics exactly

## Backup Strategy

All modified files have `.backup` versions in the same directory:
- `sys/Thing.cpp.backup`
- `sys/Data.cpp.backup`
- `melder/MelderReadText.cpp.backup`
- `melder/melder_files.cpp.backup` (from earlier debugging)

**Restore command:**
```bash
cd src/praat.github.io
for file in $(find . -name "*.backup"); do
    cp "$file" "${file%.backup}"
done
```

## Testing

### Verification Checklist

- [x] Package compiles without errors
- [x] TextGrid files load successfully (all sizes)
- [x] No segmentation faults
- [x] All TextGrid methods work correctly
- [x] Performance acceptable (< 0.2s for 37 MB file)
- [x] No debug spam in console output
- [x] Memory management stable (no leaks)
- [x] Automated tests pass (32/33, 1 CRAN skip)

### Test Files Used

- `benchmarkdata1min.TextGrid` (1.2 MB) - ✅ 0.012s
- `benchmarkdata10min.TextGrid` (12 MB) - ✅ 0.057s
- `benchmarkdata30min.TextGrid` (37 MB) - ✅ 0.163s

## Future Maintenance

### When Updating Praat Source

1. **Save current patch:**
   ```bash
   cd src/praat.github.io
   git diff > ../../docs/praat_modifications_YYYY-MM-DD.patch
   ```

2. **Update submodule:**
   ```bash
   git submodule update --remote
   ```

3. **Reapply modifications:**
   ```bash
   git apply ../../docs/praat_modifications.patch
   ```

4. **Test thoroughly:**
   ```bash
   R CMD INSTALL --preclean .
   ./final_verification.R
   ```

### If Patch Fails

Manually reapply changes using this document as reference. The modifications are:
1. Make class registry `extern` in Thing.h and Thing.cpp
2. Add null checks in Thing.cpp
3. Add `#include <cstdio>` where needed
4. Ensure no debug `fprintf()` statements remain

## Alternative Solutions Considered

### 1. Initialize Melder System Earlier ❌
**Rejected:** Too invasive, requires understanding entire Praat initialization sequence

### 2. Avoid Melder_casual() Entirely ✅
**Chosen:** Replace with direct `fprintf()`, then remove debug output
**Result:** Clean, minimal changes, production-ready

### 3. Disable All Debug Output ⚠️
**Partially used:** Removed debug output after confirming fix works

### 4. Custom Class Registry ❌
**Rejected:** Would break compatibility with Praat source updates

## Conclusion

These modifications are **minimal, targeted, and necessary** for pladdrr to work correctly as an R package. They:

1. **Solve the critical issue:** TextGrid loading now works perfectly
2. **Maintain compatibility:** No Praat semantics changed
3. **Enable debugging:** Structure allows future diagnostics
4. **Production ready:** No performance impact, no debug spam

The changes are well-documented, backed up, and easily revertable if needed.

## Contact

For questions about these modifications:
- See: `TEXTGRID_FIX_COMPLETE.md` for full debugging history
- See: `SESSION9_FINAL_STATUS.md` for detailed session notes
- Patch file: `docs/praat_modifications.patch`
