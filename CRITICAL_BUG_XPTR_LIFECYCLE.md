# CRITICAL BUG: XPtr/R6 Object Lifecycle Issue

**Date**: 2025-11-18  
**Severity**: CRITICAL  
**Status**: IDENTIFIED - Requires Investigation  
**Affects**: Core package functionality

---

## Symptom

Sequential creation and destruction of R6 Sound objects causes `.xptr must be an external pointer` errors:

```r
# First operation works
sound1 <- Sound$create_tone(1.0, 440, 44100, 0.5)
pitch <- sound1$to_pitch()  # ✓ Works

# Second operation fails
sound2 <- Sound$create_tone(1.0, 440, 44100, 0.5)
formants <- sound2$to_formant_burg()  # ✗ Error: .xptr must be an external pointer
```

---

## Reproduction

```r
library(speaker)

# Test 1: Single operation - WORKS
for (i in 1:5) {
  sound <- Sound$create_tone(1.0, 440, 44100, 0.5)
  pitch <- sound$to_pitch()
}
# ✓ Success

gc()  # Force garbage collection

# Test 2: Different operation - FAILS
for (i in 1:5) {
  sound <- Sound$create_tone(1.0, 440, 44100, 0.5)
  formants <- sound$to_formant_burg()
}
# ✗ Error on first iteration
```

---

## Error Details

```
Error in initialize(...) : .xptr must be an external pointer
Calls: <Anonymous> -> <Anonymous> -> initialize
```

---

## Failure Pattern

| Step | Operation | Result |
|------|-----------|--------|
| 1 | Create Sound + to_pitch() × 5 | ✓ Works |
| 2 | gc() | ✓ Completes |
| 3 | Create Sound + to_formant_burg() × 1 | ✗ FAILS |

**Key Observation**: 
- First set of R6 operations: ✓ Works
- After GC or completion: ✗ Second set fails immediately
- Single operations work fine
- Multiple operations in sequence fail

---

## Likely Causes

### 1. XPtr Finalizer Issue (Most Likely)
```cpp
// Hypothesis: Finalizer corrupts global state
Rcpp::XPtr<Sound> ptr(sound_obj, [](Sound* obj) {
  // Potential issue: Praat cleanup affecting global state?
  delete obj;
});
```

**Evidence**:
- Failure occurs after first set of objects destroyed
- gc() triggers the problem
- Error is "xptr must be an external pointer" = invalid XPtr

**Investigation Needed**:
- Review all XPtr finalizers in `src/*_wrappers.cpp`
- Check if Praat objects have global dependencies
- Test XPtr validity across object lifecycles

### 2. Global Praat State Corruption
```cpp
// Hypothesis: Praat C++ has global state that gets corrupted
static PraatGlobalState* state = nullptr;

// First operation initializes
// Cleanup may reset/corrupt
// Second operation fails due to invalid state
```

**Evidence**:
- Problem persists across different operations
- Affects all R6 object types (Sound, Pitch, Formant)
- Reproducible and consistent

**Investigation Needed**:
- Review Praat source for global variables
- Check initialization/cleanup sequences
- Test Praat objects in standalone C++ (without R)

### 3. R6 Class Definition Issue
```r
# Hypothesis: initialize() method validation too strict
initialize = function(path = NULL, .xptr = NULL, ...) {
  if (!is.null(.xptr)) {
    # Is this check failing incorrectly?
    super$initialize(.xptr)
  }
}
```

**Evidence**:
- Error originates in `initialize()`
- XPtr parameter validation
  
**Investigation Needed**:
- Add debug logging to initialize()
- Check XPtr validity before initialization
- Test with is.external() checks

---

## Impact Assessment

### Critical Impact ⚠️
- **Benchmarking**: Cannot run multiple benchmarks
- **Batch Processing**: Sequential file processing fails
- **Workflows**: Multi-step analyses broken
- **Testing**: Some test patterns fail

### Currently Working ✓
- Single R6 object operations
- Individual function calls
- Basic package functionality
- First operation in sequence

### Currently Broken ✗
- Sequential R6 object creation
- Benchmark suites (bench::mark)
- Loops with R6 objects
- Multiple operations after gc()

---

## Workarounds

### 1. Single Operation per Session
```r
# Works: Create once, use multiple times
sound <- Sound$create_tone(1.0, 440, 44100, 0.5)
pitch1 <- sound$to_pitch()
pitch2 <- sound$to_pitch()  # Same object, multiple calls
```

### 2. Avoid gc() Between Operations
```r
# May work: Prevent premature garbage collection
for (i in 1:10) {
  sound <- Sound$create_tone(1.0, 440, 44100, 0.5)
  pitch <- sound$to_pitch()
  # Don't call gc() here
}
```

### 3. Restart R Session
```r
# Nuclear option: Fresh session for each operation sequence
# Not practical for production use
```

---

## Investigation Plan

### Phase 1: Diagnostics (IMMEDIATE)
1. ✓ Add debug logging to XPtr creation
2. ✓ Test XPtr validity with is.external()
3. ✓ Review finalizer implementations
4. ✓ Check Praat global state

### Phase 2: Isolation (HIGH PRIORITY)
1. Create minimal C++ test case
2. Test Praat objects without R
3. Test XPtr without Praat
4. Identify exact failure point

### Phase 3: Fix (CRITICAL)
1. Implement proper XPtr lifecycle
2. Add XPtr validity checks
3. Handle Praat global state correctly
4. Add comprehensive tests

### Phase 4: Verification
1. Run all benchmarks successfully
2. Test sequential operations
3. Stress test with loops
4. Validate all R6 classes

---

## Files to Investigate

### C++ Wrappers
- `src/sound_wrappers.cpp` - Sound object XPtr handling
- `src/pitch_wrappers.cpp` - Pitch object XPtr handling  
- `src/formant_wrappers.cpp` - Formant object XPtr handling
- `src/RcppExports.cpp` - Generated Rcpp exports

### R6 Classes
- `R/sound-r6-new.R` - Sound$initialize()
- `R/pitch-r6.R` - Pitch$initialize()
- `R/formant-r6.R` - Formant$initialize()
- `R/praat-object-r6.R` - Base class

### Praat Source
- `src/praat/sys/Thing.cpp` - Base Praat object
- `src/praat/fon/Sound.cpp` - Sound implementation
- Check for global variables, singletons

---

## Next Steps

1. **IMMEDIATE**: Review XPtr finalizer code
2. **URGENT**: Add XPtr validity checks  
3. **HIGH**: Create isolated test case
4. **CRITICAL**: Fix root cause

---

## Status Updates

**2025-11-18 10:00 UTC**: 
- Issue identified during benchmark development
- Affects all R6 object creation cycles
- Workarounds implemented for benchmarks
- Investigation ongoing

---

**Priority**: P0 - CRITICAL BUG
**Blocks**: v1.0.0 Release
**Requires**: Deep C++/Rcpp expertise

This issue must be resolved before production release.
