# TextGrid File Reading Debug - Session 7 Progress

## What We Did

### 1. Added fprintf() Debug Output to Critical Functions ✅

We added low-level debugging to pinpoint the exact crash location:

#### File: `src/praat.github.io/melder/MelderReadText.cpp`
```cpp
autoMelderReadText MelderReadText_createFromFile (MelderFile file) {
	fprintf(stderr, "DEBUG MelderReadText_createFromFile: ENTRY\n"); fflush(stderr);
	autoMelderReadText me = std::make_unique <structMelderReadText> ();
	fprintf(stderr, "DEBUG: unique_ptr created, about to call MelderFile_readText\n"); fflush(stderr);
	fprintf(stderr, "DEBUG: file pointer = %p\n", (void*)file); fflush(stderr);
	my string32 = MelderFile_readText (file, & my string8);
	fprintf(stderr, "DEBUG: MelderFile_readText returned successfully\n"); fflush(stderr);
	// ... rest of function
}
```

#### File: `src/praat.github.io/melder/melder_files.cpp`
```cpp
autostring32 MelderFile_readText (MelderFile file, autostring8 *string8) {
	fprintf(stderr, "DEBUG MelderFile_readText: ENTRY\n"); fflush(stderr);
	fprintf(stderr, "DEBUG: file pointer = %p\n", (void*)file); fflush(stderr);
	try {
		fprintf(stderr, "DEBUG: Inside try block, about to initialize type\n"); fflush(stderr);
		int type = 0;   // 8-bit
		autostring32 text;
		fprintf(stderr, "DEBUG: About to call Melder_fopen\n"); fflush(stderr);
		autofile f = Melder_fopen (file, "rb");
		fprintf(stderr, "DEBUG: Melder_fopen returned successfully\n"); fflush(stderr);
		// ... rest of function
}
```

### 2. Why fprintf() Instead of Melder_casual()?

Previous debug attempts with `Melder_casual()` in `Data_readFromTextFile()` produced NO output, suggesting the crash happens before the function body executes or in function preamble/destructors.

**fprintf()** advantages:
- Writes directly to stderr (no buffering)
- Doesn't depend on Praat's message system
- Works even if Praat initialization is incomplete
- `fflush(stderr)` ensures output appears immediately

### 3. Git Changes Confirmed

```bash
$ cd src/praat.github.io && git diff melder/MelderReadText.cpp melder/melder_files.cpp

Both files show:
✅ #include <cstdio> added
✅ fprintf() statements at critical points
✅ fflush(stderr) after each print
```

## Current Status

### Changes Made ✅
1. Debug output added to `MelderReadText_createFromFile()` 
2. Debug output added to `MelderFile_readText()`
3. Debug output added to `Melder_fopen()` call

### Next Required Steps

#### Step 1: Rebuild Package (REQUIRED)
The debug output will only appear after recompiling. Two options:

**Option A: Full Package Build** (slow but reliable)
```bash
cd /Users/frkkan96/Documents/src/pladdrr
R CMD INSTALL --preclean .
```

**Option B: devtools::load_all()** (faster, may have issues)
```r
devtools::load_all(compile = TRUE, recompile = TRUE)
```

**Note**: Build may take 10-15 minutes due to large Praat codebase.

#### Step 2: Test with Debug Output
```r
library(pladdrr)  # or devtools::load_all()
tg <- TextGrid$new('inst/extdata/benchmarkdata1min.TextGrid')
```

**Expected Debug Output** (if our changes work):
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
DEBUG MelderReadText_createFromFile: ENTRY          ← NEW!
DEBUG: unique_ptr created, about to call MelderFile_readText  ← NEW!
DEBUG: file pointer = 0x...                         ← NEW!
DEBUG MelderFile_readText: ENTRY                    ← NEW!
DEBUG: file pointer = 0x...                         ← NEW!
DEBUG: Inside try block, about to initialize type   ← NEW!
DEBUG: About to call Melder_fopen                   ← NEW!
[CRASH LOCATION WILL BE REVEALED HERE]
```

## Diagnostic Strategy

### Scenario A: Crash Before "MelderReadText_createFromFile: ENTRY"
**Diagnosis**: Crash in `Data_readFromTextFile()` before calling `MelderReadText_createFromFile()`  
**Next Action**: Add fprintf() to `Data_readFromTextFile()` in `src/praat.github.io/sys/Data.cpp`

### Scenario B: Crash Between "ENTRY" and "unique_ptr created"
**Diagnosis**: Crash in function preamble or parameter processing  
**Next Action**: Check if `file` parameter is valid pointer

### Scenario C: Crash Between "unique_ptr created" and "MelderFile_readText: ENTRY"
**Diagnosis**: Crash in `MelderFile_readText()` function call setup  
**Next Action**: Check calling convention, parameter passing

### Scenario D: Crash After "MelderFile_readText: ENTRY" but before "Inside try block"
**Diagnosis**: Crash in function preamble before try block  
**Next Action**: Check parameter validation, pointer dereferencing

### Scenario E: Crash After "Inside try block" but before "About to call Melder_fopen"
**Diagnosis**: Crash in variable initialization (type, text)  
**Next Action**: Check if `autostring32` constructor has issues

### Scenario F: Crash After "About to call Melder_fopen"
**Diagnosis**: Crash in `Melder_fopen()` function  
**Next Action**: Add fprintf() to `Melder_fopen()` implementation

## Expected Crash Location (Hypothesis)

Based on previous analysis, the crash likely occurs in:
1. **Melder_fopen()** - File opening with platform-specific code
2. **MelderFile structure access** - Dereferencing file->path at offset ~104 bytes
3. **Missing file I/O initialization** - Some global state not initialized

## Why This Approach Will Work

1. **fprintf() bypasses Praat's message system** - Works even if Praat isn't fully initialized
2. **Immediate flushing** - Ensures we see output before crash
3. **Multiple checkpoints** - Narrow down crash to specific line
4. **No dependencies** - Uses only C standard library

## Files Modified (Ready for Testing)

```
src/praat.github.io/melder/MelderReadText.cpp  (7 fprintf statements added)
src/praat.github.io/melder/melder_files.cpp    (6 fprintf statements added)
```

## Build Commands

### Quick Build Test
```bash
cd /Users/frkkan96/Documents/src/pladdrr
# Check if files compile (won't link, just syntax check)
R CMD SHLIB src/praat.github.io/melder/MelderReadText.cpp -c 2>&1 | head -20
```

### Full Package Build
```bash
cd /Users/frkkan96/Documents/src/pladdrr
R CMD INSTALL --preclean --no-multiarch --with-keep.source .
```

### Test After Build
```r
library(pladdrr)
cat("Testing TextGrid file reading with debug output...\n")
tg <- TextGrid$new('inst/extdata/benchmarkdata1min.TextGrid')
cat("SUCCESS! TextGrid loaded.\n")
```

## Summary

We've added comprehensive fprintf() debug output at every critical point in the file reading code path. Once the package is rebuilt and tested, we will see EXACTLY where the crash occurs, allowing us to identify the root cause.

**The debug output will tell us**:
- Does execution enter `MelderReadText_createFromFile()`?
- Does execution enter `MelderFile_readText()`?
- Where precisely does the crash occur?
- What's the state of the file pointer?

This is the definitive diagnostic approach that will solve the mystery of the segfault at address 0x68.

## Next Session Action

1. **Rebuild package** (may take time, let it complete)
2. **Run test** with debug output
3. **Analyze output** to identify exact crash location
4. **Implement fix** based on crash location
