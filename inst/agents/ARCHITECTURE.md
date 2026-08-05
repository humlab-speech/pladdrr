# pladdrr Architecture Reference

**Version:** 4.9.17 | **Maintained by:** coding agents and maintainers
**Purpose:** Operational knowledge — build system, threading, dispatch patterns, stale-binary trap, compilation flags.

---

## Dispatch Patterns

pladdrr uses three object dispatch patterns (documented v4.9.17). Each exists for a specific reason.

### 1. Shared Dispatch Table (Sound, Formant, Pitch, etc. — 35/38 types)

All 35 wrappers use a shared `.{type}_methods` environment + `$.Type` S3 dispatch. PraatInterpreter is the only R6Class.

```r
.pitch_methods <- new.env(hash = TRUE, parent = emptyenv())
.pitch_methods$get_mean <- function(.self, ...) .self$.cpp$get_mean(...)
lockEnvironment(.pitch_methods, bindings = TRUE)

Pitch <- function(.xptr = NULL) {
  pitch_mod <- get_module("pitch_module")
  cpp_obj <- pitch_mod$RPitch$new(.xptr)
  structure(list(.xptr = .xptr, .cpp = cpp_obj), class = c("Pitch", "PraatObject"))
}

`$.Pitch` <- function(x, name) {
  val <- .subset2(x, name)       # Fast path: .xptr, .cpp
  if (!is.null(val)) return(val)
  method <- .pitch_methods[[name]]
  if (is.null(method)) return(NULL)
  function(...) method(x, ...)    # Bind self, return closure
}
```

**Characteristics:**
- `.self$.xptr` + `.self$.cpp` (both present, `.xptr` is the external pointer to C++ Praat object)
- Wrapper dispatch (v4.9.17) replaces Rcpp Module's 3-layer R→Module→C++ path with direct 2-layer R→C++ `.Call()` for frequent query methods, reducing per-call overhead ~30-40%.
- All wrappers inherit dispatch from this pattern via `$.PraatObject`.

**List of types using this pattern:** AmplitudeTier, BarkSpectrogram, Cepstrum, Cochleagram, ComplexSpectrogram, DTW, Discriminant, DurationTier, Excitation, Formant, FormantGrid, FormantModeler, FormantPath, FormantTier, Harmonicity, Intensity, IntensityTier, KlattGrid, LFCC, LPC, LongSound, Ltas, MFCC, Manipulation, Matrix, MelSpectrogram, PCA, Pitch, PitchModule, PitchTier, PointProcess, Polygon, Sound, Spectrogram, Spectrum, Table, TextGrid, VocalTract.

### 2. Pure XPtr (PowerCepstrogram, PowerCepstrum)

No `.cpp` module at all — only `.self$.xptr`. All methods are R wrapper functions that call C++ directly via `.Call()`.

**Why:** More performant than module dispatch for these types. The shared dispatch table pattern would add unnecessary indirection for objects that only need pointer access.

### 3. Triple-Class + Pointer Compat (Electroglottogram)

Triple class `c("Electroglottogram", "Sound", "PraatObject")` + `.pointer` compat alias. Inherits Sound's methods via class hierarchy.

**Why:** Electroglottogram is a Sound subclass in Praat's type system. The triple class allows it to inherit Sound's methods while maintaining its own identity.

### Special Cases

- **AmplitudeTier:** `.pointer` compat alias in `$` dispatch (used by factory functions)
- **PitchTier, FormantTier, LongSound, VocalTier:** static `$.{type}_constructor` for class methods
- **FormantPath, KlattGrid, ComplexSpectrogram:** no `.xptr` — only `.cpp` stored
- **PraatInterpreter (R6):** requires persistent mutable state for script execution

---

## Threading Model

### MelderThread (Praat's Internal Pool)

Praat's `MelderThread_PARALLELIZE` macro (defined in `melder/MelderThread.h`) is the canonical threading mechanism for all Praat vendored code. It:
- Spawns threads once per parallel region
- Respects `pladdrr_threads()` cap via `MelderThread_getMaximumNumberOfConcurrentThreads()`
- Uses `MelderThread_FOR(ielement)` / `MelderThread_ENDFOR` blocks for per-element work
- Propagates errors via `_errorFlag_` atomic

**IMPORTANT:** MelderThread worker threads CANNOT call R API functions (Rcpp::Environment, getOption, etc.). These are not thread-safe and cause segfaults. SIMD bridge functions called from MelderThread workers must avoid R API calls.

### Custom `parallel_for_range` (REMOVED v4.9.17)

The former custom thread pool in `batch_queries.cpp` (`parallel_for_range` template) has been replaced with `MelderThread_PARALLELIZE`. This eliminates:
- Redundant thread creation/destruction per call
- Competition between two independent thread pools
- Failure to respect `pladdrr_threads()` cap

---

## Build System

### Compilation Flags

```
-O2 (CRAN floor) — default
-O3 -march=native (embedder option) — 3-7× speedup
-ffp-contract=off — required for CPPS bit-exactness with Praat
-DHAVE_XSIMD — SIMD enabled by default since v4.9.9
```

### SIMD Configuration

32 SIMD files compile by default (`-DHAVE_XSIMD` in `PKG_CPPFLAGS`). Runtime detection via xsimd selects best instruction set per architecture (NEON on arm64, AVX2/SSE4.2 on x86_64).

**NEON (Apple Silicon) caveat:** Gains are "modest" — pitch gets little SIMD help, cepstrogram/CPPS gains 10-15%. The `src/simd_bridge.h` header now includes small-input scalar fallback (`n < 16`) to avoid dispatch overhead for tiny vectors.

### Stale-Binary Trap

`tools/check_callentries.sh` is wired into `configure` to self-heal the `static→extern` patch on `RcppExports.cpp`. `Rcpp::compileAttributes()` generates `static` by default, but `src/module_init.cpp` declares `extern const R_CallMethodDef CallEntries[]` to build a combined registration table. The patch converts `static` to `extern` in `RcppExports.cpp`.

**Do NOT remove this patch.** The combined registration table in `module_init.cpp` merges `CallEntries` + `ModuleEntries` into one `R_registerRoutines` call. `R_registerRoutines` REPLACES previous registrations, so both must be in a single call.
