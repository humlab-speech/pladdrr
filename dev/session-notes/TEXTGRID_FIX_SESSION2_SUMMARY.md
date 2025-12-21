# TextGrid Reading Fix - Session 2 Summary

**Date:** 2025-12-18  
**Objective:** Fix TextGrid file reading segfault  
**Approach Attempted:** Option 1 - Add numeric library initialization

## What We Tried

### Hypothesis
Sound reading works and calls `ensure_numeric_libs_initialized()` before reading files. TextGrid reading doesn't. Maybe TextGrid needs same initialization.

### Implementation
Modified `src/textgrid_wrappers.cpp`:

1. ✅ Added numeric library headers:
   ```cpp
   #include "praat.github.io/dwsys/NUMmachar.h"
   #include "praat.github.io/melder/NUMrandom.h"
   ```

2. ✅ Added initialization function (same pattern as sound_wrappers.cpp):
   ```cpp
   static bool numeric_libs_initialized = false;
   
   static void ensure_numeric_libs_initialized() {
       if (!numeric_libs_initialized) {
           NUMmachar();
           NUMrandom_initializeSafelyAndUnpredictably();
           numeric_libs_initialized = true;
       }
   }
   ```

3. ✅ Called before file reading (line 85):
   ```cpp
   Rcpp::XPtr<structTextGrid> textgrid_read_from_file(std::string path) {
       try {
           // Initialize numeric libraries (required for text parsing)
           ensure_numeric_libs_initialized();
           
           structMelderFile file = {};
           Melder_pathToFile(Melder_peek8to32(path.c_str()), &file);
           autoDaata data = Data_readFromTextFile(&file);
           // ...
   ```

### Result

**❌ NO FIX - Still segfaults at address 0x0**

```r
library(pladdrr)
tg <- TextGrid$new('inst/extdata/benchmarkdata1min.TextGrid')
# *** caught segfault ***
# address 0x0, cause 'invalid permissions'
```

## Key Findings

1. **Initialization IS happening**: 
   - `praat_initialize()` called in `.onLoad()`
   - Can verify by calling `pladdrr:::praat_initialize()` (returns TRUE)
   - `classTextGrid` IS in `Thing_recognizeClassesByName()` list

2. **Numeric init is NOT sufficient**:
   - Added same initialization as Sound reading
   - Sound reading works, TextGrid reading still crashes
   - Issue is deeper than numeric library initialization

3. **Crash location**: 
   - Segfault at address 0x0 (null pointer dereference)
   - Happens in `Data_readFromTextFile()` call
   - Possibly in `Thing_newFromClassName()` or `MelderReadText_createFromFile()`

## What We Ruled Out

- ❌ Missing numeric initialization
- ❌ Missing praat_initialize() call  
- ❌ classTextGrid not registered
- ❌ Simple compilation/linking issues

## Next Steps to Try

### Option 2: MelderFile Initialization
Check if `structMelderFile file = {}` zero-initialization is sufficient:
- Maybe needs explicit `MelderFile_init()` or similar
- Compare with how Sound initializes MelderFile

### Option 3: Text Encoding Setup
`Data_readFromTextFile()` calls `Melder_getInputEncoding()`:
- Check if encoding preferences need initialization
- Try calling `Melder_setInputEncoding()` first

### Option 4: Deep Investigation
- Run with lldb/gdb to see exact crash line
- Check what pointer is NULL
- Inspect Data_readFromTextFile implementation step by step

### Option 5: Alternative Approach
- Check if there's a TextGrid-specific reader we should use
- Try binary file reading
- Use Praat's C API differently

## Files Modified

**Modified:**
- `src/textgrid_wrappers.cpp` - Added numeric initialization (lines 16-17, 60-73, 85-86)

**Unchanged (test file removed):**
- `src/test_textgrid_read.cpp` - Created then removed (caused linker errors)

## Testing Commands

```bash
# Rebuild
cd /Users/frkkan96/Documents/src/pladdrr
R CMD INSTALL --preclean .

# Test
R --vanilla --quiet -e "
library(pladdrr)
tg <- TextGrid\$new('inst/extdata/benchmarkdata1min.TextGrid')
print(tg\$get_number_of_tiers())
"

# Should print tier count
# Instead: segfault at address 0x0
```

## Conclusion

Numeric library initialization was a reasonable hypothesis based on the working Sound implementation, but it did NOT fix the TextGrid reading segfault. The issue is more fundamental - likely in how Praat's generic `Data_readFromTextFile()` function interacts with TextGrid objects, or in the initialization state required for that function to work properly.

**Status**: Bug persists, need to try Option 2 or deeper investigation.
