# pladdrr Architecture Reference

**Version:** 4.9.20 | **Maintained by:** coding agents and maintainers
**Purpose:** Operational knowledge — build system, threading, dispatch patterns, stale-binary trap, compilation flags.

---

## Dispatch Patterns

pladdrr uses three object dispatch patterns (documented v4.9.18). Each exists for a specific reason.

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
- Wrapper dispatch (v4.9.18) replaces Rcpp Module's 3-layer R→Module→C++ path with direct 2-layer R→C++ `.Call()` for frequent query methods, reducing per-call overhead ~30-40%.
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

**Macro syntax — get this wrong and the file will not compile.** `PARALLELIZE`
opens its own scope and `ENDFOR` closes it; `FOR` opens the loop brace itself.
Do **not** wrap the block in extra braces (that broke the v4.9.18 build):

```cpp
MelderThread_PARALLELIZE (numberOfElements, threshold)   // no brace here
    autoVEC scratch = raw_VEC (n);                       // per-thread locals
MelderThread_FOR (ielement) {
    ...body...
} MelderThread_ENDFOR                                    // closing brace first
```

**Thread count is platform-dependent.** `MelderThread_computeNumberOfThreads`
in `src/melderthread_impl.cpp` mirrors upstream's divisors — `floor(n/min)` on
macOS, `floor(n/2/min)` on Windows, `round(n/1.5/min)` elsewhere. Because
pladdrr cannot define Praat's `macintosh` macro globally (it pulls in
Objective-C headers), the switch is on `__APPLE__` / `_WIN32` / else. Before
v4.9.19 the macOS branch was hardcoded, oversubscribing Windows ~2x and Linux
~1.5x.

**Partitioning is static and equal-sized.** On asymmetric hardware (Apple
Silicon P+E cores) that can leave the performance cores waiting on an
efficiency-core straggler. Measured on an M1 Pro (8P+2E) with v4.9.19 this no
longer costs anything — 10 threads is the fastest point and CPU time is flat
above 8 — but the risk is latent if you change chunk sizes or thresholds.

### Custom `parallel_for_range` (REMOVED v4.9.18)

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
-DHAVE_XSIMD — unconditional; RcppXsimd is a LinkingTo dependency
```

`configure` no longer computes a `@XSIMD_FLAG@` substitution: `Makevars.in` set
`-DHAVE_XSIMD` unconditionally anyway, so the detection was dead code that would
have produced a confusing missing-header failure rather than a clear message.
It now checks for RcppXsimd and exits with one clear error if absent.

The `FLAC_SRC` / `MP3_SRC` variables were removed in v4.9.19: they named a
`praat/` prefix deleted in the v4.9.5 slimming and were never referenced by
`SOURCES`. **FLAC and MP3 are not decoded natively** — only headers survive under
`praat.github.io/external/{flac,mp3}`, `flac_stubs.cpp` is linked instead, and
`Sound()` falls back to the suggested `av` package for those formats.

### SIMD Configuration

26 SIMD files compile by default (`-DHAVE_XSIMD`, unconditional in `PKG_CPPFLAGS` —
RcppXsimd is a `LinkingTo` dependency, so the build cannot run without it). Six
files with no externally referenced symbols were deleted in v4.9.19
(`num_distance`, `num_filtering`, `num_matrix`, `pitch_processing`,
`sound_convolution`, `sound_statistics` — 1,174 lines).

**Instruction set is chosen at compile time, and there is no runtime dispatch.**
This is the most commonly misunderstood part of the build:

| Target | What a stock CRAN build reaches | Doubles/vector |
|---|---|---|
| arm64 | NEON | 2 |
| x86_64 | **SSE2 only** | 2 |
| x86_64 + `-march=native` in `~/.R/Makevars` | AVX2 / AVX-512 | 4 / 8 |

CRAN forbids `-march=`, and the tree contains no `__attribute__((target(...)))`
or `xsimd::dispatch`. **AVX2 and AVX-512 code paths are never executed by a
CRAN-installed binary**, whatever the CPU supports.

**Measured benefit (M1 Pro, 1 s signal, single-threaded).** Toggling
`pladdrr_simd()` moves whole-routine wall time by -1% to +6%: pitch 0.99x,
formant 0.98x, intensity 1.06x, spectrogram 1.03x, mfcc 1.00x, CPPS 1.00x.
End-to-end analysis time is dominated by work SIMD does not touch — for CPPS,
~94% is the branchy per-frame robust trend fit. Where SIMD *does* pay is the
batch-statistics bridges on long plain vectors (v4.9.19, after removing their
input copies): mean 4.1x, sd 2.8x, range 15.4x, quantile 1.8x vs base R on 1e6
doubles.

**`src/simd_bridge.h` is dead code** — included by no translation unit. The real
bridges are hand-written in `src/*_simd_bridge.cpp`. Edits to that header have no
effect; a v4.9.18 zero-copy fix landed there and did nothing. Bridges pass R's
storage straight through as `values.begin() - 1` (the same `ptr - 1` idiom as
Praat's `asArgumentToFunctionThatExpectsOneBasedArray()`); every kernel takes
`const double*` and none writes through it.

### Stale-Binary Trap

`tools/check_callentries.sh` is wired into `configure` to self-heal the `static→extern` patch on `RcppExports.cpp`. `Rcpp::compileAttributes()` generates `static` by default, but `src/module_init.cpp` declares `extern const R_CallMethodDef CallEntries[]` to build a combined registration table. The patch converts `static` to `extern` in `RcppExports.cpp`.

**Do NOT remove this patch.** The combined registration table in `module_init.cpp` merges `CallEntries` + `ModuleEntries` into one `R_registerRoutines` call. `R_registerRoutines` REPLACES previous registrations, so both must be in a single call.
