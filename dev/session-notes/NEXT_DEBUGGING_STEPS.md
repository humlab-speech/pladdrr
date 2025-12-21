# Next Debugging Steps for TextGrid File Reading Crash

## Current Situation

**Status**: Debug output added, package needs rebuild  
**Goal**: Identify exact crash location in file reading code  
**Method**: fprintf() debugging at critical checkpoints

## Immediate Next Step: Rebuild Package

### Why Rebuild is Required
The debug statements we added are in source files that must be recompiled. Until the package is rebuilt, the debug output won't appear.

### Build Command
```bash
cd /Users/frkkan96/Documents/src/pladdrr

# Option 1: Full clean build (recommended, ~10-15 minutes)
R CMD INSTALL --preclean --no-multiarch --with-keep.source .

# Option 2: devtools (may be faster)
R --vanilla -e "devtools::load_all(compile=TRUE, recompile=TRUE)"
```

**Note**: The build takes time because it compiles the entire Praat C++ codebase (~500+ source files).

## After Rebuild: Run Test

```r
# Load package
library(pladdrr)
# OR
devtools::load_all()

# Test with debug output
cat("Testing TextGrid file reading with debug output...\n")
tg <- TextGrid$new('inst/extdata/benchmarkdata1min.TextGrid')
```

## Expected Debug Output

If the crash happens in `MelderFile_readText()` (our hypothesis), you'll see:

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
DEBUG MelderReadText_createFromFile: ENTRY
DEBUG: unique_ptr created, about to call MelderFile_readText
DEBUG: file pointer = 0x...
DEBUG MelderFile_readText: ENTRY
DEBUG: file pointer = 0x...
DEBUG: Inside try block, about to initialize type
DEBUG: About to call Melder_fopen
*** caught segfault ***          ← CRASH WILL BE HERE OR EARLIER
```

The **last line of debug output** before the crash tells us exactly where the problem is.

## Interpreting Results

### Case 1: No Debug Output from MelderReadText_createFromFile
**Diagnosis**: Crash happens before we enter the function  
**Action**: Add debug to `Data_readFromTextFile()` caller

### Case 2: "ENTRY" but no "unique_ptr created"
**Diagnosis**: Crash in function preamble or parameter setup  
**Action**: Check function signature, parameter types

### Case 3: "unique_ptr created" but no "MelderFile_readText: ENTRY"
**Diagnosis**: Crash in function call setup or parameter passing  
**Action**: Check `MelderFile_readText()` signature

### Case 4: "MelderFile_readText: ENTRY" but no "Inside try block"
**Diagnosis**: Crash before try block (unlikely)  
**Action**: Check function prolog code

### Case 5: "Inside try block" but no "About to call Melder_fopen"
**Diagnosis**: Crash in variable initialization (`autostring32 text`)  
**Action**: Check `autostring32` default constructor

### Case 6: "About to call Melder_fopen" but no "returned successfully"
**Diagnosis**: Crash inside `Melder_fopen()`  ✅ **MOST LIKELY**
**Action**: Add fprintf() to `Melder_fopen()` implementation

## If Crash is in Melder_fopen()

### Find Melder_fopen Implementation
```bash
cd /Users/frkkan96/Documents/src/pladdrr
grep -rn "^autofile.*Melder_fopen\|^FILE.*Melder_fopen" src/praat.github.io/melder/*.cpp
```

### Add Debug Output
Once you find it (likely in `melder_files.cpp`), add fprintf at the start:
```cpp
autofile Melder_fopen (MelderFile file, const char *mode) {
    fprintf(stderr, "DEBUG Melder_fopen: ENTRY, mode=%s\n", mode); fflush(stderr);
    fprintf(stderr, "DEBUG: file pointer = %p\n", (void*)file); fflush(stderr);
    fprintf(stderr, "DEBUG: file->path = %p\n", (void*)(file->path)); fflush(stderr);
    // ... rest of function
}
```

## Likely Root Causes (Based on Address 0x68)

### 1. Null Pointer + Struct Offset
Address 0x68 = 104 bytes suggests:
```cpp
struct SomeStruct {
    // ... 104 bytes of members
    void* problematic_field;  // At offset 0x68
};

SomeStruct* ptr = nullptr;  // Or invalid
ptr->problematic_field;  // ← CRASH at 0x68
```

### 2. File Handle Not Initialized
```cpp
FILE* f = nullptr;  // Not initialized
fseeko(f, 0, SEEK_END);  // ← CRASH accessing f->some_field
```

### 3. Missing Platform-Specific Initialization
```cpp
// Missing call to:
// - File system initialization
// - Locale setup
// - Path encoding tables
// - File handle pool
```

## Quick Diagnostic Checklist

Before next session, verify:

- [ ] Package rebuilt successfully (no compile errors)
- [ ] Debug output appears when testing
- [ ] Exact crash location identified
- [ ] File pointer values logged before crash
- [ ] Last successful debug line recorded

## Success Criteria

We'll know we've succeeded when:
1. **Debug output appears** - Confirms our changes compiled
2. **Crash location narrowed** - To specific function/line
3. **Root cause identified** - Based on what code didn't execute
4. **Fix is obvious** - Once we know where it crashes

## Time Estimate

- **Rebuild package**: 10-15 minutes
- **Run test**: < 1 minute
- **Analyze output**: 5 minutes
- **Identify fix**: 10-30 minutes (depends on root cause)
- **Implement & verify fix**: 30-60 minutes

**Total**: ~1-2 hours to complete diagnosis and fix

## Files Ready for Testing

```
✅ src/praat.github.io/melder/MelderReadText.cpp  (debug added)
✅ src/praat.github.io/melder/melder_files.cpp    (debug added)
⏸ src/textgrid_wrappers.cpp                      (already has debug)
⏸ src/praat_wrapper.cpp                          (encoding init done in Session 6)
```

## Summary

The groundwork is complete. We've added comprehensive debug output at every critical checkpoint. Once the package rebuilds, we'll see EXACTLY where the crash occurs, making the fix straightforward.

**Next action**: Run the build command and test!
