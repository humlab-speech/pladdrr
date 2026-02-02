# Praat Source Modifications for pladdrr

**Last Updated:** 2026-02-02
**Package Version:** 4.8.4
**Praat Base Version:** 6.4.x (submodule at src/praat.github.io)

## Overview

This document details all modifications made to the Praat source code to enable proper operation within the pladdrr R package. Changes fall into these categories:

1. **Critical Bug Fixes** - Crashes and linkage issues
2. **CRAN Compliance** - Removal of non-portable files
3. **Performance Optimizations** - SIMD acceleration
4. **API Compatibility** - Function declarations for FormantPath

---

## 1. Critical Bug Fixes

### 1.1 TextGrid Loading Segfault

**Problem:** TextGrid files caused SIGSEGV at address 0x68 when loaded through R.

**Root Cause:** Two issues:
1. Class registry arrays declared `static` - invisible across shared library boundaries
2. `Melder_casual()` debug logging attempted to lock uninitialized mutex

**Files Modified:**

#### `sys/Thing.h`
```cpp
/* Expose class registry for shared library access (pladdrr fix) */
extern integer theNumberOfReadableClasses;
extern ClassInfo theReadableClasses [1 + 1000];
```

#### `sys/Thing.cpp`
- Changed `static` to `extern` for class registry arrays
- Added null pointer checks in class lookup loop
- Added error checking in `Thing_newFromClassName()`
- Added `#include <cstdio>`

#### `sys/Data.cpp`
- Added `#include <cstdio>` for debugging

#### `melder/MelderReadText.cpp`
- Added `#include <cstdio>` for debugging

#### `melder/NUMinterpol.cpp`
- Removed 13 debug `fprintf()` statements from `improve_evaluate()` and `NUMimproveExtremum()`

---

### 1.2 NUMfpp Linkage Fix (Pitch Detection Crash)

**Problem:** Pitch detection crashed with NULL pointer dereference on `NUMfpp->eps`.

**Root Cause:** `NUMfpp` was declared `inline` in header, causing each compilation unit to get its own copy. Only one was initialized, others remained NULL.

**Files Modified:**

#### `dwsys/NUMmachar.h`
```cpp
/* OLD */
inline machar_Table NUMfpp;

/* NEW */
extern machar_Table NUMfpp;
```

#### `dwsys/NUMmachar.cpp`
```cpp
/* Added global definition */
machar_Table NUMfpp = nullptr;
```

---

### 1.3 NUMfpp NULL Check (Defensive Fix)

**Problem:** `NUMminimize_brent()` crashed if called before `NUMmachar()` initialization.

**File Modified:** `dwsys/NUM2.cpp`

```cpp
double NUMminimize_brent (...) {
    // Ensure NUMfpp is initialized (needed for sqrt_epsilon calculation)
    if (!NUMfpp) {
        extern void NUMmachar();
        NUMmachar();
    }
    // ... rest of function
}
```

---

### 1.4 Threading Debug Performance Fix

**Problem:** Multi-threaded operations (CPPS, etc.) were 6-60x slower than expected.

**Root Cause:** Debug `fprintf(stderr)` + `fflush()` calls in `MelderThread_run()`.

**File Modified:** `melder/MelderThread.cpp`
- Removed 3 debug fprintf statements from threading code

---

## 2. CRAN Compliance

### 2.1 Non-Portable File Removal

**Commit:** 977ba12ad

Removed files that CRAN rejects:
- Executable binaries (`sendpraat-*`, `silipa93.exe`, `spit*`)
- Test audio files (`.wav`)
- ExperimentMFC test files
- Files with special characters in paths
- `.clang-format` configuration

**Total:** 43 files removed (all test/docs artifacts, no functional code)

---

## 3. API Compatibility

### 3.1 Formant_extractPart Declaration

**Problem:** `FormantPath.cpp` called `Formant_extractPart()` but declaration used `const Formant`, causing linker failure due to C++ name mangling mismatch.

**File Modified:** `fon/Formant.h`

```cpp
// Stub for FormantPath support (pladdrr)
autoFormant Formant_extractPart (Formant me, double tmin, double tmax);
```

---

## 4. SIMD Performance Optimizations

All SIMD changes use conditional compilation (`#ifdef HAVE_XSIMD`) with scalar fallbacks.

### 4.1 Phase 1: Core Analysis Functions

**Commit:** a257dc628

#### `dwsys/NUM2.cpp` - Burg Algorithm (LPC/Formant)
- SIMD-accelerated reflection coefficient computation in `VECburg()`
- SIMD-accelerated prediction error update
- **v4.8.4 Bug Fix:** Fixed data dependency bug in error update loop using temp buffer
  - Original SIMD code corrupted `b1[j+1..j+simd_size]` values needed for subsequent reads
  - Solution: Store new b2 values in `autoVEC b2_new_temp`, copy back after all computations
- Expected speedup: ~2x

#### `melder/NUM.cpp` - Inner Product (Autocorrelation)
- **v4.8.4:** Added `NUMinner_simd()` for SIMD-accelerated inner product
- Uses FMA accumulation for stride-1 vectors >= 16 elements
- Used by autocorrelation in pitch/formant analysis
- Expected speedup: 3-4x

#### `fon/Sound_to_Intensity.cpp` - RMS Calculation
- SIMD-accelerated RMS computation loop
- Expected speedup: 1.5-2x

#### `fon/Sound_to_Pitch.cpp` - Pitch Analysis
- Forward declarations for SIMD bridge functions
- SIMD power spectrum accumulation
- SIMD cross-correlation computation
- Expected speedup: 1.5-3x

---

### 4.2 Phase 2: Additional Integrations

#### `fon/Sound_to_Formant.cpp` - VECburg Integration
**Commit:** 7309d66d8 (original), v4.8.4 (simplified)
- **v4.8.4:** Removed separate `burg_simd` path due to algorithmic differences
- Now uses `VECburg()` directly, which has SIMD-accelerated inner loops
- The separate `burg_simd` in `formant_simd_bridge.cpp` caused 35-60% formant errors

#### `fon/Sound_and_Spectrogram.cpp` - Spectrogram Generation
**Commits:** 6e89fe9dd, 8a79ccd3e
- SIMD forward declarations for frame extraction, windowing, power spectrum
- Integration in channel processing loop
- Expected speedup: 2-3x

#### `fon/Sound.cpp` - Pre-emphasis Filter
**Commit:** 0d262ccaa
- SIMD-accelerated pre-emphasis filtering
- Used in spectrogram and MFCC pipelines

#### `fon/Sound_to_Pitch.cpp` - Pitch Filter
**Commit:** d89b65dff
- SIMD declarations for Gaussian low-pass spectrum filtering
- Applied to both `filteredAc` and `filteredCc` variants
- Runtime control via `should_use_simd_for_pitch_filter()`
- Expected speedup: 2-3x

---

### 4.3 Phase 3: Advanced Features

#### `dwtools/Sound_and_Spectrogram_extensions.cpp` - MFCC
**Commit:** 308b614cf
- SIMD triangular filter bank application
- SIMD DCT computation
- Expected speedup: 2-4x for MFCC extraction

#### `dwtools/Spectrogram_extensions.cpp` - MFCC Support
**Commit:** 308b614cf
- Additional SIMD integration for mel-frequency analysis

#### `LPC/FormantPath.cpp` - Frequency Change Cost
**Commit:** 0389ce7f6
- SIMD optimization for frequency change cost computation in `FormantPath_getOptimumPath()`
- Conditional SIMD with scalar fallback
- Expected speedup: 1.5-2x

---

## Summary of Modified Files

| File | Category | Changes |
|------|----------|---------|
| `sys/Thing.h` | Bug fix | Extern class registry |
| `sys/Thing.cpp` | Bug fix | Extern linkage, null checks |
| `sys/Data.cpp` | Bug fix | cstdio header |
| `melder/MelderReadText.cpp` | Bug fix | cstdio header |
| `melder/NUMinterpol.cpp` | Bug fix | Remove debug output |
| `melder/MelderThread.cpp` | Performance | Remove debug fprintf |
| `dwsys/NUMmachar.h` | Bug fix | Extern NUMfpp |
| `dwsys/NUMmachar.cpp` | Bug fix | NUMfpp definition |
| `dwsys/NUM2.cpp` | Bug fix + SIMD | NULL check + Burg SIMD (v4.8.4 fix) |
| `melder/NUM.cpp` | SIMD | NUMinner SIMD (v4.8.4) |
| `fon/Formant.h` | API | extractPart declaration |
| `fon/Sound_to_Intensity.cpp` | SIMD | RMS optimization |
| `fon/Sound_to_Pitch.cpp` | SIMD | Pitch analysis optimization |
| `fon/Sound_to_Formant.cpp` | SIMD | Uses VECburg directly (v4.8.4) |
| `fon/Sound_and_Spectrogram.cpp` | SIMD | Spectrogram optimization |
| `fon/Sound.cpp` | SIMD | Pre-emphasis optimization |
| `dwtools/Sound_and_Spectrogram_extensions.cpp` | SIMD | MFCC optimization |
| `dwtools/Spectrogram_extensions.cpp` | SIMD | Mel-frequency SIMD |
| `LPC/FormantPath.cpp` | SIMD | Path optimization |

---

## Risk Assessment

| Category | Risk | Rationale |
|----------|------|-----------|
| Bug fixes | LOW | Minimal, targeted changes |
| CRAN cleanup | NONE | Only removes non-functional files |
| API compatibility | LOW | Adds declaration only |
| SIMD optimizations | LOW | All have scalar fallbacks via `#ifdef` |

---

## Maintenance: Updating Praat Source

### Step 1: Save Current Patch
```bash
cd src/praat.github.io
git diff > ../../docs/praat_modifications_$(date +%Y-%m-%d).patch
```

### Step 2: Update Submodule
```bash
git fetch origin
git merge origin/master  # or specific tag
```

### Step 3: Reapply Modifications
```bash
# Try automatic patch
git apply ../../docs/praat_modifications.patch

# If fails, manually reapply using this document as reference
```

### Step 4: Verify
```bash
cd ../..
R CMD INSTALL --preclean .
Rscript -e "testthat::test_dir('tests/testthat')"
```

---

## Key Commits in Submodule

| Commit | Description |
|--------|-------------|
| `f64063348` | TextGrid loading fix |
| `e929a431f` | NUMfpp linkage fix |
| `06b94b648` | NUMfpp NULL check |
| `977ba12ad` | CRAN file cleanup |
| `93be586f4` | Formant_extractPart declaration |
| `a38ceec17` | Threading debug removal |
| `a257dc628` | SIMD Phase 1 (pitch/intensity/formant) |
| `7309d66d8` | SIMD formant bridge |
| `8a79ccd3e` | SIMD spectrogram |
| `0d262ccaa` | SIMD pre-emphasis |
| `d89b65dff` | SIMD pitch filter |
| `308b614cf` | SIMD MFCC |
| `0389ce7f6` | SIMD FormantPath |

---

## Backup Files

Legacy backup files exist in the submodule:
- `sys/Thing.cpp.backup`
- `sys/Data.cpp.backup`
- `melder/MelderReadText.cpp.backup`
- `melder/melder_files.cpp.backup`

These can be removed once modifications are stable.
