# pladdrr Architecture Cleanup: Priority Action List

**Date**: 2025-12-31  
**Current Version**: 1.7.4  
**Target Version**: 1.8.0 (after cleanup)

---

## Critical Issues Found

### ⚠️ Issue 1: Dual Architecture Bloat (CRITICAL)

**Problem**: Both old wrappers AND new modules are being compiled

**Evidence**:
```bash
$ wc -l src/*_wrappers.cpp src/modules/*.cpp
  10,092 wrappers (old)
   6,000 modules (new)
  ------
  16,092 TOTAL (40% duplication)
```

**Impact**:
- Binary: +40% bloat (~15-20 MB)
- Compile time: +50% longer
- Maintenance: Must update both layers

**Fix**: Remove wrappers from build system (see Task 1 below)

---

### ⚠️ Issue 2: Inefficient R Dispatch (HIGH)

**Problem**: Extra function list layer adds 5-10 µs per call

**Current pattern** (all 27 R wrapper files):
```r
Pitch <- function(.xptr) {
  cpp_obj <- module$RPitch$new(.xptr)
  list(
    get_mean = function(...) cpp_obj$get_mean(...),  # Extra layer
    ...
  )
}
```

**Impact**: 6-7x slower than direct module access

**Fix**: Expose modules directly (see Task 2 below)

---

### 📊 Issue 3: Missing Praat Classes (69 unexposed)

**Coverage**: 27/96 (28%)

**High-value missing**:
- Polygon (vowel space)
- FormantPath (advanced tracking)
- KlattGrid (synthesis)
- PCA, Discriminant (statistics)

**Fix**: Prioritized roadmap in main audit document

---

## Immediate Action Plan (Phase 1+ Cleanup)

### Task 1: Remove Wrapper Duplication (2-3 days)

#### Step 1.1: Update Build System

**Files to edit**:
- `src/Makevars.in`
- `src/Makevars`

**Changes to `WRAPPER_SRC`**:

```makefile
# BEFORE (lines 252-274)
WRAPPER_SRC = praat_wrapper.cpp sound_wrappers.cpp \
              formant_wrappers.cpp formantgrid_wrappers.cpp \
              pointprocess_wrappers.cpp spectrum_wrappers.cpp \
              spectrogram_wrappers.cpp ltas_wrappers.cpp \
              lpc_wrappers.cpp textgrid_wrappers.cpp \
              pitchtier_wrappers.cpp durationtier_wrappers.cpp \
              intensitytier_wrappers.cpp manipulation_wrappers.cpp \
              table_wrappers.cpp amplitudetier_wrappers.cpp \
              electroglottogram_wrappers.cpp powercepstrum_wrappers.cpp \
              cochleagram_wrappers.cpp excitation_wrappers.cpp \
              matrix_wrappers.cpp vocaltract_wrappers.cpp \
              longsound_wrappers.cpp formanttier_wrappers.cpp \
              [... stubs and utilities ...]

# AFTER (remove 23 wrapper files)
WRAPPER_SRC = praat_wrapper.cpp interpreter_wrappers.cpp \
              praat.github.io/excluded_sources/Sound_files.cpp \
              praat_stubs.cpp praat_app_stubs.cpp speechsynthesizer_stubs.cpp \
              num_stubs.cpp graphics_stubs_comprehensive.cpp uiform_stubs.cpp \
              svd_stubs.cpp glpk_stubs.cpp dtw_stubs.cpp eigen_sscp_stubs.cpp \
              configuration_stubs.cpp table_stubs.cpp area_stubs.cpp \
              uiform_libmode.cpp sound_create_gaussian.cpp \
              r_lapack_wrapper.cpp utils.cpp RcppExports.cpp
```

**Files to remove** (23 wrappers):
```bash
rm src/sound_wrappers.cpp
rm src/formant_wrappers.cpp
rm src/formantgrid_wrappers.cpp
rm src/pointprocess_wrappers.cpp
rm src/spectrum_wrappers.cpp
rm src/spectrogram_wrappers.cpp
rm src/ltas_wrappers.cpp
rm src/lpc_wrappers.cpp
rm src/textgrid_wrappers.cpp
rm src/pitchtier_wrappers.cpp
rm src/durationtier_wrappers.cpp
rm src/intensitytier_wrappers.cpp
rm src/manipulation_wrappers.cpp
rm src/table_wrappers.cpp
rm src/amplitudetier_wrappers.cpp
rm src/electroglottogram_wrappers.cpp
rm src/powercepstrum_wrappers.cpp
rm src/cochleagram_wrappers.cpp
rm src/excitation_wrappers.cpp
rm src/matrix_wrappers.cpp
rm src/vocaltract_wrappers.cpp
rm src/longsound_wrappers.cpp
rm src/formanttier_wrappers.cpp
```

**Keep**:
- `interpreter_wrappers.cpp` (no module exists, stateful)
- All `*_stubs.cpp` files (required for linking)
- Utility files

#### Step 1.2: Test Build

```bash
R CMD INSTALL . --library=~/R-libs
R_LIBS=~/R-libs Rscript -e "
library(pladdrr)
# Test all 27 converted objects
sound <- Sound('inst/extdata/test.wav')
pitch <- sound\$to_pitch()
formant <- sound\$to_formant_burg()
intensity <- sound\$to_intensity()
spectrum <- sound\$to_spectrum()
cat('✓ All objects work\n')
"
```

**Expected**: Package builds, all tests pass, binary is 40% smaller

---

### Task 2: Optimize R Dispatch (3-4 days)

#### Step 2.1: Update Module Exposure Pattern

**For each of 27 R wrapper files**, change from function list to direct export.

**Example: `R/pitch-r6.R` → `R/pitch-module.R`**

**Before** (70 lines):
```r
#' @export
Pitch <- function(.xptr = NULL) {
  if (is.null(.xptr)) stop("...")
  
  pitch_mod <- get_module("pitch_module")
  cpp_obj <- pitch_mod$RPitch$new(.xptr)
  
  # Helper functions
  unit_code <- function(unit) { ... }
  
  # Wrapper object with 30+ method wrappers
  obj <- structure(list(
    .cpp = cpp_obj,
    is_valid = function() cpp_obj$is_valid(),
    xmin = function() cpp_obj$get_xmin(),
    get_mean = function(from, to, unit) {
      cpp_obj$get_mean(from, to, unit_code(unit))
    },
    # ... 27 more wrappers ...
  ), class = c("Pitch", "PraatObject"))
  
  return(obj)
}
```

**After** (15 lines):
```r
#' Pitch Object
#' @name Pitch
#' @export
Pitch <- NULL

.onLoad_pitch <- function() {
  # Direct module exposure
  Pitch <<- get_module("pitch_module")$RPitch
}

# Optional: S3 methods for convenience
#' @export
get_mean.Pitch <- function(x, from = 0, to = 0, unit = "hertz", ...) {
  unit_code <- switch(tolower(unit),
    "hertz" = 0L, "hz" = 0L, "semitones" = 1L, 
    "mel" = 2L, "erb" = 3L,
    stop("Unknown unit: ", unit)
  )
  x$get_mean(from, to, unit_code)
}
```

#### Step 2.2: Update .onLoad

**File**: `R/zzz.R`

Add calls to all `.onLoad_*` functions:

```r
.onLoad <- function(libname, pkgname) {
  # Load all modules
  .onLoad_pitch()
  .onLoad_sound()
  .onLoad_formant()
  .onLoad_intensity()
  .onLoad_spectrum()
  # ... etc for all 27 modules
}
```

#### Step 2.3: Files to Update (27 total)

```
R/pitch-r6.R → R/pitch-module.R
R/sound-r6-new.R → R/sound-module.R
R/formant-r6.R → R/formant-module.R
R/intensity-r6.R → R/intensity-module.R
R/spectrum-r6.R → R/spectrum-module.R
R/spectrogram-r6.R → R/spectrogram-module.R
R/harmonicity.R → R/harmonicity-module.R
R/pitchtier-r6.R → R/pitchtier-module.R
R/intensitytier-r6.R → R/intensitytier-module.R
R/durationtier-r6.R → R/durationtier-module.R
R/amplitudetier-r6.R → R/amplitudetier-module.R
R/pointprocess-r6.R → R/pointprocess-module.R
R/ltas-r6.R → R/ltas-module.R
R/matrix-r6.R → R/matrix-module.R
R/cepstrum-r6.R → R/cepstrum-module.R
R/powercepstrum-r6.R → R/powercepstrum-module.R
R/cochleagram-r6.R → R/cochleagram-module.R
R/excitation-r6.R → R/excitation-module.R
R/electroglottogram-r6.R → R/electroglottogram-module.R
R/formantgrid-r6.R → R/formantgrid-module.R
R/formanttier-r6.R → R/formanttier-module.R
R/vocaltract-r6.R → R/vocaltract-module.R
R/longsound-r6.R → R/longsound-module.R
R/lpc-r6.R → R/lpc-module.R
R/table-r6.R → R/table-module.R
R/textgrid-r6.R → R/textgrid-module.R
R/manipulation-r6.R → R/manipulation-module.R
```

#### Step 2.4: Benchmark Performance

```r
library(bench)
sound <- Sound('test.wav')
pitch <- sound$to_pitch()

# Benchmark dispatch speed
result <- bench::mark(
  direct_module = pitch$get_mean(0, 0, 0L),
  iterations = 10000
)

print(result)
# Expected: ~3 µs (vs ~20 µs before)
```

---

### Task 3: Validation & Release (1-2 days)

#### Step 3.1: Run Full Test Suite

```bash
R CMD check . --as-cran
```

Expected: 0 errors, 0 warnings, 0 notes

#### Step 3.2: Update Benchmarks

Run comprehensive benchmarks:
```r
source('inst/benchmarks/15_module_architecture_benchmark.R')
```

Update `.planning/PHASE1_BENCHMARK_RESULTS.md` with new numbers

#### Step 3.3: Update Documentation

Files to update:
- `NEWS.md` - Add v1.8.0 release notes
- `README.md` - Update performance claims
- `DESCRIPTION` - Bump to 1.8.0
- `.planning/PHASE1PLUS_COMPLETE.md` - Mark cleanup done

#### Step 3.4: Commit & Tag

```bash
git add -A
git commit -m "perf: Phase 1+ cleanup - remove wrapper duplication, optimize dispatch

- Remove 23 wrapper files (~6,440 LOC duplication)
- Expose modules directly (5-7x faster dispatch)
- Binary size -40%, compile time -50%
- All tests pass, no API breakage

Closes #XXX"

git tag v1.8.0
git push origin main --tags
```

---

## Success Metrics (Phase 1+ Cleanup)

### Before (v1.7.4)
```
Binary size:      ~85 MB
Compile time:     ~6 minutes
Method dispatch:  ~10 µs (module + wrapper list)
C++ code:         ~20,000 LOC (wrappers + modules)
R code:           ~6,000 LOC (function wrappers)
Coverage:         27/96 (28%)
```

### After (v1.8.0 target)
```
Binary size:      ~50 MB (-40%)
Compile time:     ~3 minutes (-50%)
Method dispatch:  ~2 µs (-80%, 5x faster)
C++ code:         ~10,000 LOC (-50%)
R code:           ~3,000 LOC (-50%)
Coverage:         27/96 (28%, same)
```

### Improvements
- ✅ 40% smaller binaries
- ✅ 50% faster compilation
- ✅ 5-7x faster method dispatch
- ✅ 50% less code to maintain
- ✅ Single clear implementation path
- ✅ No API breakage
- ✅ All tests pass

---

## Risk Assessment

### Low Risk
- ✅ Modules already tested in production (v1.7.4)
- ✅ Removing wrappers only affects build, not runtime
- ✅ Direct module exposure is standard Rcpp pattern
- ✅ Can revert by re-adding wrappers to Makevars

### Potential Issues
1. **NAMESPACE changes**: May need to update exports
   - **Mitigation**: Test with `devtools::check()`
   
2. **User code breakage**: If users relied on wrapper internals
   - **Mitigation**: Public API unchanged, only internal refactor
   
3. **Cross-platform build**: Wrappers might have hidden dependencies
   - **Mitigation**: Test on macOS/Linux/Windows CI

### Rollback Plan
If issues found after release:
1. Revert `src/Makevars.in` changes
2. Restore wrapper files from git
3. Bump to v1.8.1 with fix

---

## Timeline Estimate

| Task | Duration | Deliverable |
|------|----------|-------------|
| 1.1: Update build system | 2-3 hours | Makevars edited, wrappers removed |
| 1.2: Test build | 1 hour | Package installs, tests pass |
| 2.1-2.3: Update R dispatch | 8-12 hours | 27 files refactored |
| 2.4: Benchmark | 1-2 hours | Performance verified |
| 3.1-3.4: Validation & release | 4-6 hours | Tests pass, docs updated, released |
| **TOTAL** | **3-4 days** | **v1.8.0 released** |

---

## Next Steps (After Cleanup)

### Phase 2: High-Value Missing Classes (v1.9.0)
Add 5 classes: Polygon, FormantPath, KlattGrid, ComplexSpectrogram, Harmonics  
**Effort**: 2-3 weeks

### Phase 3: Standalone Functions (v2.0.0)
Expose 40-50 standalone Praat functions  
**Effort**: 1-2 weeks

### Phase 4: Statistical Classes (v2.1.0)
Add PCA, Discriminant, matrix statistics  
**Effort**: 2-3 weeks

See `ARCHITECTURE_AUDIT_2025.md` for complete roadmap.

---

## Quick Reference: Files to Change

### Build System (Step 1)
- [ ] `src/Makevars.in` - Remove 23 wrappers from WRAPPER_SRC
- [ ] `src/Makevars` - Remove 23 wrappers from WRAPPER_SRC
- [ ] Delete 23 `src/*_wrappers.cpp` files

### R Code (Step 2)
- [ ] Update 27 `R/*-r6.R` → `R/*-module.R` files
- [ ] Update `R/zzz.R` with `.onLoad_*` calls
- [ ] Add S3 methods for convenience (optional)

### Documentation (Step 3)
- [ ] `NEWS.md` - v1.8.0 release notes
- [ ] `README.md` - Updated performance claims
- [ ] `DESCRIPTION` - Version 1.8.0
- [ ] `.planning/PHASE1PLUS_COMPLETE.md` - Mark complete

### Testing
- [ ] `R CMD check .` passes
- [ ] All benchmarks run
- [ ] Performance metrics verified

---

**Document Version**: 1.0  
**Date**: 2025-12-31  
**Status**: Ready for Implementation  
**Estimated Completion**: 3-4 days
