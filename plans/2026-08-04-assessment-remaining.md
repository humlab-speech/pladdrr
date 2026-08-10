# Remaining Assessment Items — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Complete remaining high-impact improvements from the v4.9.16 comprehensive assessment: performance, code quality, documentation, and infrastructure.

**Architecture:** Work in `perf/assess-fixes` branch. Three phases: quick wins (dead code, doc fixes, cache patterns), structural improvements (class documentation overhaul, wrapper dispatch migration), and infrastructure (CI, coverage).

**Branch:** `perf/assess-fixes` (created, 1 commit ahead of main)
**Base:** `main`
**Current version:** 4.9.16

---

## Phase 1 — Quick Wins (~2 hours)

### Task 1.1: Update remaining num_stubs → melderthread_impl references

**Files:** `inst/agents/AGENT_GUIDE.md`, `inst/agents/PRAAT_MODIFICATIONS.md`
**What:** Replace all `num_stubs.cpp` references with `melderthread_impl.cpp` in documentation files. 5 occurrences remain.
**Test:** `grep -r "num_stubs" inst/` returns zero matches.
**Commit:** `docs: update num_stubs -> melderthread_impl references`

### Task 1.2: Delete remaining dead stub files

**Files to delete from src/:**
- `flac_stubs.cpp` (269 lines) — FLAC stubs, never linked (real FLAC in `FLAC_SRC`)
- `sound_audio_stubs.cpp` (135 lines) — playback/recording no-ops

**Files to keep despite "stub" name:**
- `praat_stubs.cpp` — guards with `#ifndef PLADDRR_FULL_PRAAT`
- `uiform_stubs.cpp` — needed for library mode
- `graphics_stubs_comprehensive.cpp` — needed by Praat linking
- All `_stubs.cpp` in the praat.github.io/ referenced source group

**After deletion:** Remove `flac_stubs.cpp` and `sound_audio_stubs.cpp` from `WRAPPER_SRC` in `Makevars.in`, `Makevars`, and `Makevars.win`. Remove `flac_stubs.cpp` from `SOURCES` line (it was already separate). Verify `sound_audio_stubs.cpp` is also only in `SOURCES` line, not in a named group.

**Test:** `R CMD INSTALL .` succeeds. `library(pladdrr)` loads without missing symbol errors.
**Commit:** `chore: delete dead stub files (flac_stubs, sound_audio_stubs)`

### Task 1.3: Cache jitter/shimmer batch results in PointProcess methods

**File:** `R/pointprocess-wrapper.R`

**Current state:** Five individual jitter methods (`get_jitter_local`, `get_jitter_local_absolute`, `get_jitter_rap`, `get_jitter_ppq5`, `get_jitter_ddp`) and six shimmer methods each call a separate `.Call()`. Each crosses R↔C boundary. `get_jitter_shimmer_batch()` exists in `batch-queries.R` and returns all 11 metrics in one call.

**What:** Add a `.jitter_shimmer_cache` field to PointProcess objects (the shared dispatch list). When any individual jitter/shimmer method is called:
1. Check if cache exists for given parameters (from_time, to_time, period_floor, period_ceiling, max_period_factor, max_amplitude_factor)
2. If miss: call `get_jitter_shimmer_batch_cpp()` once, store all 11 metrics in cache
3. Extract and return the requested metric

**Cache key:** `paste(from_time, to_time, period_floor, period_ceiling, max_period_factor, max_amplitude_factor)`

**Shimmer problem:** Shimmer methods take a `sound` argument. The batch function also takes a sound. The cache key must include the sound identity. Use `sound$.xptr` address for uniqueness.

```r
# Pseudocode for get_jitter_local:
.pp_methods$get_jitter_local <- function(.self, from_time = 0, to_time = 0, ...) {
  key <- paste(from_time, to_time, period_floor, period_ceiling, max_period_factor)
  if (is.null(.self$.jscache) || .self$.jscache$key != key) {
    .self$.jscache <- list(
      key = key,
      data = get_jitter_shimmer_batch_cpp(.self$.xptr, NULL, from_time, to_time, ...)
    )
  }
  .self$.jscache$data[["local"]]
}
```

**Test:** Write a test in `tests/testthat/test-pointprocess.R` that calls two jitter metrics and verifies they return expected values. Verify second call doesn't invoke another C++ call (hard to test directly, verify output consistency instead).
**Commit:** `perf: cache jitter/shimmer batch results in PointProcess`

### Task 1.4: Make additional class examples executable

**Files:** `R/spectrum-wrapper.R`, `R/harmonicity.R`, `R/powercepstrum.R`, `R/pitch-wrapper.R`

**What:** For each file, add a self-contained runnable `@examples` block (before the `\dontrun{}` block) using `Sound$create_tone()`:
- **Spectrum:** `s$to_spectrum()` → `get_real_value_in_bin()`, `get_centre_of_gravity()`
- **Harmonicity:** `s$to_harmonicity_cc()` → `get_value_at_time()`, `get_mean()`
- **PowerCepstrum:** `spectrum$to_power_cepstrum()` → `get_peak_prominence()`
- **Pitch:** Already has `@return`, but example is `\dontrun{}`. Add runnable `to_pitch()` example.

**Test:** `R CMD check --no-manual` runs all examples without errors.
**Commit:** `docs: add runnable examples to Spectrum, Harmonicity, PowerCepstrum, Pitch`

### Task 1.5: Fix formant get_all_values_at_time

**File:** `R/formant-wrapper.R` (line ~109)

**Current:** Uses `vapply` loop → N C++ calls for N formants at one time point.
**Fix:** Add a C++ function `formant_get_all_values_at_time` in `src/formant_wrappers.cpp` that queries all formant values at a single time in one C++ call, then update the R method to call it.

```cpp
// In formant_wrappers.cpp:
// [[Rcpp::export(.formant_get_all_values_at_time)]]
Rcpp::NumericVector formant_get_all_values_at_time(
    SEXP xptr, double time, int max_formants, int unit) {
    XPtr<structFormant> formant(xptr);
    Rcpp::NumericVector out(max_formants);
    for (int i = 0; i < max_formants; i++) {
        out[i] = Formant_getValueAtTime(formant.get(), i + 1, time, (kFormant_unit)unit);
    }
    return out;
}
```

Then update `R/formant-wrapper.R`:
```r
.formant_methods$get_all_values_at_time <- function(.self, time, max_formants = 5, unit = c("hertz", "bark")) {
  unit <- match.arg(unit)
  uc <- .formant_unit_code(unit)
  .formant_get_all_values_at_time(.self$.xptr, as.numeric(time), as.integer(max_formants), uc)
}
```

Also add the R wrapper in `R/RcppExports.R` (or run `Rcpp::compileAttributes()`).
**Test:** `R CMD INSTALL .` succeeds. Formant test passes. Run `Rscript -e 'library(pladdrr); s <- Sound$create_tone(); f <- s$to_formant_burg(); f$get_all_values_at_time(0.5)'` and verify result matches old vapply output.
**Commit:** `perf: single C++ call for get_all_values_at_time`

---

## Phase 2 — Class Documentation Overhaul (~3 hours)

### Task 2.1: Expand R6 class man pages to ultra-function quality

**Target files (15 files):**
`formant-wrapper.R`, `pitch-wrapper.R`, `intensity-wrapper.R`, `pointprocess-wrapper.R`, `spectrum-wrapper.R`, `spectrogram-wrapper.R`, `harmonicity.R`, `powercepstrum.R`, `textgrid-wrapper.R`, `lpc-wrapper.R`, `ltas-wrapper.R`, `mfcc-wrapper.R`, `pca-wrapper.R`, `discriminant-wrapper.R`, `dtw-wrapper.R`

**What each needs:**
1. Full method listing in `@section Methods:` (like `spectrum-wrapper.R` already has)
2. Parameter descriptions for commonly-used methods
3. A second self-contained runnable example showing a realistic workflow
4. Cross-references to related classes (`@seealso`)
5. A `@description` that says what the object IS (not just what it wraps)

**Template:**
```r
#' @title Formant Object
#'
#' @description
#' Formant objects represent vocal tract resonance frequencies over time.
#' Created from a Sound using formant tracking (Burg, Split-Levinson, or Willems).
#'
#' @return A \code{Formant} object.
#'
#' @section Methods:
#' \describe{
#'   \item{$get_value_at_time(formant_number, time, unit)}{Query formant frequency at a time point.}
#'   \item{$get_mean(formant_number, from_time, to_time, unit)}{Mean formant frequency over interval.}
#'   \item{$get_all_formant_tracks(max_formants, unit)}{Matrix of all formant tracks.}
#'   ...
#' }
#'
#' @seealso \code{\link{Sound}}, \code{\link{LPC}}, \code{\link{FormantPath}}
#'
#' @examples
#' # Create a tone and extract formants
#' sound <- Sound$create_tone(duration = 0.5, frequency = 200, sampling_rate = 44100)
#' formant <- sound$to_formant_burg()
#' formant$get_value_at_time(formant_number = 1, time = 0.25, unit = "hertz")
#' ...
#' @name Formant
```

**Split into 3 commits (5 files each) to keep diffs reviewable.**

**Test:** Run `R CMD check` to verify no Rd parsing errors.
**Commits:**
- `docs: expand Formant, Pitch, Intensity, PointProcess, Spectrum man pages`
- `docs: expand Spectrogram, Harmonicity, PowerCepstrum, TextGrid, LPC man pages`
- `docs: expand Ltas, MFCC/LFCC, PCA, Discriminant, DTW man pages`

---

## Phase 3 — Architecture: Wrapper Dispatch Migration (~4 hours)

### Task 3.1: Migrate dispatch tables from module methods to wrapper .Call()

**Background:** The codebase has dual C++ APIs:
- **Modules** (38 RCPP_MODULE in `modules/`) — used by shared dispatch tables via `.self$.cpp$method()`. Slower (~3 layers: R → Module dispatch → Module C++ → Praat C++).
- **Wrappers** (`_wrappers.cpp` files) — direct `.Call("_pladdrr_func", ...)`. Faster (R → Praat C++, one hop).

The Tier 4 ultra API already uses wrapper calls. The main user-facing API uses modules. Migrating the dispatch tables to call wrapper functions instead of module methods gives Tier 4 speed to every user-facing method (~30-40% less overhead per call).

**Plan per class (e.g., Sound):**

1. **Audit:** List all `.self$.cpp$method()` calls in `R/sound-wrapper.R` — note which have corresponding `_sound_*` wrapper functions in `R/RcppExports.R`
2. **Map:** For each module method, find or create the corresponding wrapper `_sound_*` function
3. **Replace:** Change `.self$.cpp$method(args)` → `.Call("_pladdrr_sound_method", .self$.xptr, args)`
4. **Test:** Verify output matches old module-based output bit-exactly
5. **Drop:** Remove the module from `modules/sound_module.cpp` and `module_init.cpp` boot list (only after all classes migrated)

**Priority order (most-used → least):**
1. Sound (highest usage, biggest win)
2. Pitch
3. Formant
4. Intensity
5. PointProcess
6. TextGrid
7. Spectrogram
8. Spectrum
9. Harmonicity
10. Ltas
11. PowerCepstrum/PowerCepstrogram
12-38: Remaining classes

**Migration pattern:**
```r
# Before (module):
.pp_methods$get_value_at_time <- function(.self, time) {
  .self$.cpp$get_value_at_time(as.numeric(time))
}

# After (wrapper):
.pp_methods$get_value_at_time <- function(.self, time) {
  .Call("_pladdrr_pitch_get_value_at_time", .self$.xptr, as.numeric(time), 0L)
}
```

**If wrapper doesn't exist:** Create it in the corresponding `*_wrappers.cpp` using the pattern:
```cpp
// [[Rcpp::export(.pitch_get_value_at_time)]]
double pitch_get_value_at_time(SEXP xptr, double time, int unit) {
    XPtr<structPitch> pitch(xptr);
    return Pitch_getValueAtTime(pitch.get(), time, (kPitch_unit)unit, true);
}
```
Then run `Rcpp::compileAttributes()` to update `RcppExports.R` and `RcppExports.cpp`.

**Test strategy per class:**
- Write a regression test comparing old (module) vs new (wrapper) output for every method
- Use a synthetic tone signal so results are deterministic
- Verify identical within 1e-12 tolerance

**Commits (one per class or logical group):**
- `perf: migrate Sound dispatch to wrapper functions`
- `perf: migrate Pitch dispatch to wrapper functions`
- `perf: migrate Formant dispatch to wrapper functions`
- ... etc.

**Completion condition:** When all 38 `module_init.cpp` boot entries can be removed.

---

## Phase 4 — Infrastructure (~2 hours)

### Task 4.1: Add GitHub Actions CI

**File:** `.github/workflows/R-CMD-check.yaml`

**What:**
- Ubuntu 22.04 with R release + devel
- macOS arm64
- Windows (if possible — GSL may be an issue)
- `R CMD check --as-cran`
- Skip tests tagged `skip_on_cran()` in the CRAN job only; run them in a separate "full" job
- Cache R packages and compiled objects

**Template:** Standard `usethis::use_github_action("check-standard")` + customizations.

**Test:** Push to GitHub, verify Actions run.
**Commit:** `ci: add GitHub Actions R CMD check`

### Task 4.2: Add code coverage tracking

**File:** `.github/workflows/test-coverage.yaml`

**What:**
- Use `covr::package_coverage()` with GitHub Actions
- Upload to Codecov or coveralls
- Add coverage badge to README

**Also:** Add `Config/testthat/parallel: true` to DESCRIPTION.
**Commit:** `ci: add code coverage workflow`

### Task 4.3: Fix hardcoded developer paths in tests

**Files:** `tests/testthat/test-cpps-consistency.R`, `tests/testthat/test-tier4-ultra.R`, `tests/testthat/test-*` (grep for `/Users/frkkan96/`)

**What:** Replace hardcoded paths with `system.file()` or skip logic that checks for environment variables. Tests should not silently skip — they should either run or clearly report why they can't.
**Commit:** `test: remove hardcoded developer paths`

---

## Phase 5 — Future/Parking Lot

These items are documented as technical debt; not planned for immediate implementation:

1. **Eliminate modules entirely** — After Phase 3 migration, delete all `modules/*.cpp` and `module_init.cpp`. Simplify `Makevars.in`.
2. **Extend Sound pool to parallel pipeline** — `sound_pool.cpp` exists but only used in `batch-ops.R`, not `analyze_files_parallel`.
3. **Pre-allocate R vectors in C++ wrappers** — Use `Rcpp::NumericVector(known_size)` instead of `Rcpp::wrap()` in hot batch paths.
4. **PRAAT_CATCH audit** — Ensure all 107 export functions wrap C++ calls consistently.
5. **Replace remaining `\dontrun{}` examples with `\donttest{}` where possible** — `\donttest{}` at least attempts execution in `R CMD check`.

---

## Implementation Order

```
Phase 1 (today):
  1.1 → 1.2 → 1.3 → 1.4 → 1.5

Phase 2 (next):
  2.1a → 2.1b → 2.1c

Phase 3 (after Phase 2):
  3.1-Sound → 3.1-Pitch → 3.1-Formant → 3.1-Intensity → ...

Phase 4 (anytime, parallelizable):
  4.1 → 4.2 → 4.3
```

**Total estimated effort:** ~11 hours
**Target version:** 4.10.0 (minor bump for architectural change in Phase 3)
