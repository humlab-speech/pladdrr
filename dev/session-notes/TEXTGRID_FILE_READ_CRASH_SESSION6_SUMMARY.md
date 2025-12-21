# TextGrid File Reading Crash - Session 6 Summary

## Date: 2025-12-19

## Status: PARTIAL SUCCESS - Main segfault fixed, file reading crash isolated

## What We Fixed

### 1. Main Initialization Crash ✅ FIXED
**Root Cause**: Static class registry variables had file-local scope
**Fix**: Changed `theNumberOfReadableClasses` and `theReadableClasses` from `static` to `extern` linkage

**Files Modified**:
- `src/praat.github.io/sys/Thing.h` (lines 212-214): Added extern declarations
- `src/praat.github.io/sys/Thing.cpp` (lines 61-62): Changed from `static` to `extern`

**Result**: Package now loads successfully! Class registry is accessible with 17 classes registered.

### 2. Text Encoding Initialization ✅ ADDED
**Root Cause**: `Melder_getInputEncoding()` returns undefined value (0) on first file read
**Fix**: Initialize text encoding explicitly in `praat_initialize()`

**Files Modified**:
- `src/praat_wrapper.cpp`: 
  - Added `#include "praat.github.io/melder/melder_textencoding.h"`
  - Added platform-specific encoding initialization:
    - macOS: `UTF8_THEN_MACROMAN`
    - Windows: `UTF8_THEN_WINDOWS_LATIN1` 
    - Linux: `UTF8_THEN_ISO_LATIN1`
  - Set output encoding to UTF8

**Code Added** (after line 76):
```cpp
// Initialize text encoding (required for file reading)
Rcpp::Rcout << "DEBUG: Setting default text encoding...\n";
#if defined (macintosh) || defined (__APPLE__)
    Melder_setInputEncoding(kMelder_textInputEncoding::UTF8_THEN_MACROMAN);
#elif defined (_WIN32)
    Melder_setInputEncoding(kMelder_textInputEncoding::UTF8_THEN_WINDOWS_LATIN1);
#else
    Melder_setInputEncoding(kMelder_textInputEncoding::UTF8_THEN_ISO_LATIN1);
#endif
Melder_setOutputEncoding(kMelder_textOutputEncoding::UTF8);
```

## Current Problem: File Reading Still Crashes

### Crash Details
- **Location**: Inside `Data_readFromTextFile()`, very first line
- **Address**: `0x68` (104 bytes offset) - null pointer + offset access
- **Symptom**: Segfault before any debug output from `Data_readFromTextFile()` appears

### Call Stack
```
TextGrid$new() 
→ .textgrid_read_from_file() 
→ textgrid_read_from_file() (C++)
→ Data_readFromTextFile() 
→ CRASHES at line 166: MelderReadText_createFromFile()
```

### Debug Output Observed
```
DEBUG: Creating MelderFile structure...
DEBUG: File path = inst/extdata/benchmarkdata1min.TextGrid
DEBUG: Converting path string to UTF-32...
DEBUG: UTF-32 conversion complete
DEBUG: Calling Melder_pathToFile...
DEBUG: Melder_pathToFile complete
DEBUG: About to call Data_readFromTextFile...
DEBUG: file.path address = 0x16d828d98
DEBUG: Entering Data_readFromTextFile NOW...
*** caught segfault ***
address 0x68, cause 'invalid permissions'
```

### Debug Output NOT Appearing
These lines from `Data.cpp:165-186` never print:
```cpp
Melder_casual (U"DEBUG Data_readFromTextFile: Creating MelderReadText...");
Melder_casual (U"DEBUG: Reading first line...");
// etc.
```

### Analysis
1. **Text encoding now initialized** ✅ - Should fix `Melder_getInputEncoding()` issue
2. **Crash happens BEFORE first `Melder_casual()` call** - Suggests crash in function preamble or `autoMelderReadText` constructor
3. **Offset 0x68 = 104 bytes** - Accessing a struct member of a null/uninitialized pointer

### Likely Cause
The crash is in `MelderReadText_createFromFile()` line 186-187:
```cpp
autoMelderReadText me = std::make_unique<structMelderReadText>();
my string32 = MelderFile_readText (file, & my string8);  // ← LIKELY CRASH HERE
```

Possibly:
1. `MelderFile_readText()` accesses uninitialized global state
2. `file` pointer is valid but some field it accesses isn't initialized
3. File I/O subsystem needs additional initialization

## Next Steps

### Step 1: Verify Text Encoding Fix
Since we just added text encoding initialization, rebuild and test:
```bash
cd /Users/frkkan96/Documents/src/pladdrr
R --vanilla --slave -e "devtools::load_all(compile=TRUE, recompile=TRUE, quiet=FALSE)"
```

### Step 2: Add Debug to MelderFile_readText
If still crashes, add debug output at start of `MelderFile_readText()`:
- Location: `src/praat.github.io/melder/MelderFile.cpp` or `melder_files.cpp`
- Add fprintf to stderr (can't use Melder_casual if that's what's crashing)

### Step 3: Check File I/O Initialization
Look for any global file I/O state that needs initialization:
```bash
grep -rn "FILE.*=.*NULL\|fopen\|file.*init" src/praat.github.io/melder/
```

### Step 4: Alternative - Use fprintf for Debug
Replace `Melder_casual()` with direct `fprintf(stderr, ...)` in Data.cpp temporarily:
```cpp
fprintf(stderr, "DEBUG: Creating MelderReadText...\n"); fflush(stderr);
```

### Step 5: Check structMelderFile Initialization
Verify `Melder_pathToFile()` properly initialized all fields:
```bash
grep -A20 "void Melder_pathToFile" src/praat.github.io/melder/*.cpp
```

## Files with Debug Output Added

### textgrid_wrappers.cpp (lines 93-108)
```cpp
Rcpp::Rcout << "DEBUG: Creating MelderFile structure...\n";
structMelderFile file = {};
Rcpp::Rcout << "DEBUG: File path = " << path << "\n";

Rcpp::Rcout << "DEBUG: Converting path string to UTF-32...\n";
const char32 *path32 = Melder_peek8to32(path.c_str());
Rcpp::Rcout << "DEBUG: UTF-32 conversion complete\n";

Rcpp::Rcout << "DEBUG: Calling Melder_pathToFile...\n";
Melder_pathToFile(path32, &file);
Rcpp::Rcout << "DEBUG: Melder_pathToFile complete\n";

Rcpp::Rcout << "DEBUG: About to call Data_readFromTextFile...\n";
Rcpp::Rcout << "DEBUG: file.path address = " << (void*)file.path << "\n";
Rcpp::Rcout << "DEBUG: Entering Data_readFromTextFile NOW...\n";
autoDaata data = Data_readFromTextFile(&file);
```

### Data.cpp (lines 165-187)
```cpp
Melder_casual (U"DEBUG Data_readFromTextFile: Creating MelderReadText...");
autoMelderReadText text = MelderReadText_createFromFile (file);
Melder_casual (U"DEBUG: Reading first line...");
// ... more debug lines
```

### Thing.cpp (lines 103-159)
- Added debug output in `Thing_classFromClassName()`
- Added debug output in `Thing_newFromClassName()`

## Test Files
- `inst/extdata/benchmarkdata1min.TextGrid` - 60 seconds, 10 tiers
- `inst/extdata/benchmarkdata60min.TextGrid` - 60 minutes  
- `inst/extdata/benchmarkdata90min.TextGrid` - 90 minutes

## Test Command
```r
library(pladdrr)  # or devtools::load_all()
tg <- TextGrid$new('inst/extdata/benchmarkdata1min.TextGrid')
print(tg)
cat("Number of tiers:", tg$get_number_of_tiers(), "\n")
```

## Build Environment
- Platform: macOS ARM64 (Apple Silicon)
- Compiler: Apple clang 17.0.0
- R version: 4.4-arm64
- Package: pladdrr v0.9.11
- Branch: 001-praat-r-access

## Success Criteria
When fully fixed:
1. ✅ Package loads without crash
2. ✅ Class registry accessible
3. ⬜ TextGrid files read successfully
4. ⬜ No segfaults or memory errors
5. ⬜ All tiers and intervals accessible

## Key Learnings
1. **Static variables in shared libraries**: Must use `extern` for cross-compilation-unit visibility
2. **Praat initialization order**: NUMmachar → NUMrandom → Melder_alloc_init → Text encoding → Class registry
3. **Text encoding is critical**: Must initialize before any file I/O operations
4. **Debug output location matters**: `Melder_casual()` not appearing suggests crash before/during its execution
5. **Offset 0x68 pattern**: Accessing struct member at offset 104 - check for null pointer + dereference
