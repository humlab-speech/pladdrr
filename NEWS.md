# pladdrr 1.2.6 (2025-12-14)

## Breaking Changes

* **Removed AVQI (Acoustic Voice Quality Index) implementation**
  - Removed `compute_avqi()` function
  - Removed `plot_avqi()` function
  - Removed `create_avqi_report_plot()` function
  - Removed associated documentation

* **Removed DSI (Dysphonia Severity Index) implementation**
  - Removed `compute_dsi()` function
  - Removed `plot_dsi()` function
  - Removed `create_dsi_report_plot()` function
  - Removed associated documentation

* **Removed tremor analysis functions**
  - Removed all tremor-specific analysis functions
  - Removed associated documentation

**Rationale**: These implementations were experimental and not fully validated against clinical standards. Users requiring these metrics should use validated clinical tools such as:
- AVQI: Official Praat AVQI script or KayPENTAX CSL
- DSI: MDVP (Multi-Dimensional Voice Program)
- Tremor: Specialized tremor analysis software

## Bug Fixes

* Fixed AVQI tilt calculation in commit bf76101 (before removal)
  - Corrected tilt to use LTAS slope instead of incorrect H1-A3 formula
  - Note: Full AVQI implementation was subsequently removed in this version

## Minor Changes

* Updated documentation to remove tremor references from Pitch object
* Updated `vignettes/visualization.Rmd` to remove AVQI/DSI examples
* Maintained all core Praat functionality (Sound, Pitch, Formant, Intensity, etc.)

---

# pladdrr 1.2.5 (2025-12-14)

## Bug Fixes

### Fixed AVQI Tilt Calculation
* **Issue**: AVQI computed "tilt" as H1-A3 (harmonic 1 minus formant 3 amplitude)
* **Correct Definition**: Tilt should be LTAS slope from 0-1000 Hz to 1000-10000 Hz
* **Fix**: Modified `R/avqi.R` to use `ltas$get_slope()` instead of H1-A3 difference
* **Impact**: More accurate AVQI calculations matching clinical standards
* **Documentation**: See `AVQI_TILT_FIX_SUMMARY.md`
* **Commit**: bf76101

Note: AVQI implementation was removed in v1.2.6

---

# pladdrr 1.2.4 (2025-12-13)

## Performance Improvements

### Phase 1 Compiler Optimization - 6x DSI Speedup
* **Achievement**: 6.16x speedup in DSI calculation (83.8% improvement)
* **Changes**: Added aggressive compiler optimizations to `src/Makevars` and `src/Makevars.in`:
  - `-O3`: Aggressive optimization (loop unrolling, auto-vectorization)
  - `-flto -fno-fat-lto-objects`: Link-time optimization for cross-module inlining
  - `-mfpmath=sse`: SSE floating-point math (x86_64)
* **Results**:
  - Pitch extraction: 289ms → 77ms (3.76x faster)
  - Full DSI (12 files): 2.902s → 0.471s (6.16x faster)
* **Impact**: pladdrr now FASTER than Python Parselmouth (0.471s vs 0.558s)
* **Platform**: Tested on Apple Silicon ARM64, should improve x86_64 similarly
* **Validation**: ✅ No numerical regressions, results identical to unoptimized build
* **Documentation**: See `PHASE1_OPTIMIZATION_RESULTS.md` and `OPTIMIZATION_SUMMARY.md`
* **Commit**: Current

---

# pladdrr 1.2.3 (2025-12-12)

## Bug Fixes

### Fixed FTrI Calculation - Added start_time Parameter
* **Issue**: FTrI (Frequency Tremor Intensity Index) returned 0.0% instead of expected 2.17%
* **Root Cause**: `Sound$from_values()` lacked `start_time` parameter, breaking time alignment for peak detection
* **Fix**: 
  - Added `start_time` parameter to `.sound_create_from_values()` C++ wrapper
  - Added `start_time` parameter to `Sound$from_values()` R6 method
  - Ensures correct temporal alignment of generated waveforms
* **Validation**: FTrI now returns 2.17% as expected
* **Documentation**: Complete analysis in `FTRI_FIX_SUMMARY.md`
* **Commit**: 5b0eee8

---

# pladdrr 1.2.2 (2025-12-11)

## Bug Fixes

### Critical Build Configuration Fix - macOS and Linux Support Restored
* **Issue**: Package failed to build on macOS and Linux due to hardcoded Windows compiler flags
* **Root Cause**: Conditional compilation logic in `src/Makevars.in` was broken
* **Impact**: Package could not be installed on Unix-like systems
* **Fix**:
  - Corrected platform detection in `src/Makevars.in` configure script
  - Properly separated Windows-specific flags (`-DMS_WIN64`, `-DWIN32`)
  - Ensured Unix flags applied on macOS/Linux (`-DUNIX`, `-Wno-trigraphs`)
* **Validation**: 
  - ✅ Builds successfully on macOS (M1 ARM64)
  - ✅ All tests pass on macOS
  - ⏳ Linux validation pending
* **Documentation**: Complete analysis in `MAKEVARS_FIX_SUMMARY.md`
* **Commit**: 44bdcd0

---

# pladdrr 1.2.1 (2025-12-10)

## New Features

* Added comprehensive tremor analysis functions
* Improved AVQI implementation
* Enhanced DSI calculation accuracy

## Bug Fixes

* Various minor bug fixes and improvements

---

# pladdrr 1.2.0 (2025-12-08)

## Major Changes

* Complete rewrite using R6 object-oriented interface
* Direct Praat C++ integration via Rcpp
* 19+ Praat object types with 320+ methods
* SIMD optimization for 2-4x performance gains

## New Features

* Sound object with comprehensive audio manipulation
* Pitch analysis with multiple algorithms
* Formant extraction (Burg, Robust, Keep All)
* Intensity and harmonicity analysis
* Spectrogram and spectrum analysis
* TextGrid annotation support
* Voice quality metrics (jitter, shimmer, HNR)
* Cochleagram and excitation auditory models

## Performance

* 2-4x faster than equivalent Python Parselmouth operations
* Zero-copy operations via external pointers
* Modern CPU SIMD vectorization

---
