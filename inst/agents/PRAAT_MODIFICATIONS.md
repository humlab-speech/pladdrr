# Praat Source Modifications for pladdrr

**Last Updated:** 2026-02-05
**Package Version:** 4.8.14
**Praat Base Version:** 6.4.x (submodule at src/praat.github.io)

## Overview

This document details all modifications made to the Praat source code to enable proper operation within the pladdrr R package. Changes fall into these categories:

1. **Critical Bug Fixes** - Crashes and linkage issues
2. **CRAN Compliance** - Removal of non-portable files
3. **Performance Optimizations** - SIMD acceleration, multi-threading
4. **API Compatibility** - Function declarations for FormantPath

---

## Recent Changes

### v4.8.14 Enable real multi-threading for Praat parallel operations (2026-02-05)

**Summary:** Replaced single-threaded `MelderThread` stubs with a real multi-threaded implementation. All Praat operations that use `MelderThread_PARALLELIZE` (PowerCepstrogram, Pitch, FormantPath) now utilize all CPU cores.

**Root Cause:** `num_stubs.cpp` contained stubs that forced `MelderThread_run()` to execute single-threaded (`threadFunction(0, 1, N)`) and `MelderThread_getNumberOfProcessors()` to return 1. These were originally needed when `MelderThread.cpp` couldn't compile without the `macintosh` platform macro, but they silently disabled all parallelism.

**Files Modified:**
- `src/num_stubs.cpp` — Replaced threading stubs (lines 165-200) with real `std::thread`-based `MelderThread_run()`, `MelderThread_computeNumberOfThreads()`, and all supporting functions. Implementation based on `praat.github.io/melder/MelderThread.cpp`.

**Impact:** On 10-core Apple Silicon:
- `Sound_to_PowerCepstrogram`: ~6-7x parallelism (4.7ms wall for 1s audio)
- `PowerCepstrogram_to_Matrix_CPP`: multi-threaded via `SampledIntoSampled_mt`
- `Sound_to_Pitch`: multi-threaded frame analysis
- CPPS total: ~70-80ms for 1s audio (was ~800ms+ single-threaded)

**Also fixed:** `to_point_process_direct()` in `R/praat-direct.R` — missing `time_step` parameter caused positional argument shift in fallback path.

---

### v4.8.12 Replace Praat FFTPACK with pocketfft (2026-02-04)

**Summary:** Replaced Praat's 1996-era FFTPACK FFT implementation with pocketfft (header-only, BSD, double-precision, C++11).

**Motivation:** Code modernization — pocketfft supports more factors (2,3,4,5,7,8,11 + Bluestein fallback), has built-in plan caching, and is the same FFT backend used by NumPy/SciPy.

**Files Modified:**
- `dwsys/NUMFourier.cpp` — replaced `#include "NUMfft_core.h"` with `#include "pocketfft_hdronly.h"`, swapped `drftf1`/`drftb1` calls in `NUMfft_forward`/`NUMfft_backward` with `pocketfft::r2r_fftpack`, removed `NUMrffti` trig/split cache init from `NUMFourierTable_create`

**Build System:**
- `src/Makevars.in` + `src/Makevars` — added `-Ipocketfft` include path

**Format Compatibility:** Both use FFTPACK halfcomplex format `[DC, Re(1), Im(1), ...]` — drop-in replacement, no data layout changes. All 13+ call sites through `NUMfft_forward`/`NUMfft_backward` benefit automatically.

**New Dependencies:**
- `src/pocketfft/pocketfft_hdronly.h` (header-only, no .cpp to compile)

**Defines:** `POCKETFFT_NO_MULTITHREADING` (avoids std::thread on R toolchains), `POCKETFFT_CACHE_SIZE=16`

**Dead Code:** `dwsys/NUMfft_core.h` is no longer included (1350 lines of FFTPACK C code).

---

### v4.8.10 CPPS/PowerCepstrogram SIMD Optimization (2026-02-04)

**Summary:** SIMD acceleration for PowerCepstrogram computation to optimize CPPS calculation (93% of AVQI runtime).

#### PowerCepstrogram SIMD (Sound_to_PowerCepstrogram.cpp)

**Problem:** CPPS calculation (primary AVQI bottleneck) 1.57x slower than Python/Parselmouth.

**Solution:** Comprehensive SIMD optimization of PowerCepstrogram frame processing with 4 integration points:

**File Modified:**
- `LPC/Sound_to_PowerCepstrogram.cpp` - SIMD forward declarations + 4 conditional integration points

**SIMD Integration Points:**
1. **Frame extraction** (lines 102-114): Boundary-aware frame extraction with zero-padding
2. **Window multiplication** (lines 119-127): In-place windowing
3. **Log power spectrum** (lines 152-167): PRIMARY TARGET - `log(re² + im² + ε)` for Re/Im pairs
4. **Final power** (lines 174-188): Power cepstrum values `(val * df)²`

**New Files Created:**
- `src/powercepstrogram_simd.cpp` (430 lines) - 4 core SIMD functions with scalar fallbacks
- `tests/testthat/test-powercepstrogram-simd.R` (60 lines) - Accuracy and edge case tests
- `benchmarks/powercepstrogram_simd_benchmark.R` (70 lines) - Performance measurement

**Expected Performance:**
- ARM NEON: 1.15-1.20x speedup
- x86 AVX2: 1.25-1.35x speedup
- AVQI improvement: R/Python ratio 1.58x → ~1.38x (13% improvement)
- CPPS speedup: 11.8s → ~10.0s (15% faster)

**Note:** All Praat modifications are conditional (`#ifdef HAVE_XSIMD`) with scalar fallbacks. No changes to threading or FFT operations.

---

### v4.8.9 Performance Optimizations (2026-02-04)

**Summary:** Fixed 4 critical performance/accuracy issues from plabench benchmarking (`PLADDRR_PERFORMANCE_REQUESTS.md`).

#### Pitch Parallelization Threshold (Sound_to_Pitch.cpp)

**Problem:** Core pitch extraction ~5x slower than Python/Parselmouth for short audio segments.

**Root Cause:** Low parallelization threshold (5 frames) caused threading overhead to dominate.

**Fix:** Increased `MelderThread_PARALLELIZE` threshold from 5 to 20 frames (line 507).

**File Modified:**
- `fon/Sound_to_Pitch.cpp:507` - Changed threshold with performance comment

**Impact:** Expected 5-20x speedup for short audio segments (<1s) in DSI, VUV, Pharyngeal, and Tremor workflows.

**Note:** This is the ONLY modification to Praat source code in v4.8.9. All other changes are in pladdrr-specific files (formant_lpc_simd.cpp, formant_simd_bridge.cpp, batch_queries.cpp).

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
| `fon/Sound_to_Pitch.cpp` | SIMD + Performance | Pitch analysis optimization + parallelization threshold (v4.8.9) |
| `fon/Sound_to_Formant.cpp` | SIMD | Uses VECburg directly (v4.8.4) |
| `fon/Sound_and_Spectrogram.cpp` | SIMD | Spectrogram optimization |
| `fon/Sound.cpp` | SIMD | Pre-emphasis optimization |
| `dwtools/Sound_and_Spectrogram_extensions.cpp` | SIMD | MFCC optimization |
| `dwtools/Spectrogram_extensions.cpp` | SIMD | Mel-frequency SIMD |
| `LPC/FormantPath.cpp` | SIMD | Path optimization |
| `LPC/Sound_to_PowerCepstrogram.cpp` | SIMD | PowerCepstrogram frame processing (v4.8.10) |
| `dwsys/NUMFourier.cpp` | FFT backend | Replaced FFTPACK with pocketfft (v4.8.12) |

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
