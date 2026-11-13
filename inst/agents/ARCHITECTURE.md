# pladdrr Architecture Reference

**Version:** 5.1.1 | **Maintained by:** coding agents and maintainers
**Purpose:** Operational knowledge — build system, threading, dispatch patterns, stale-binary trap, compilation flags.

---

## Dispatch Patterns

pladdrr uses three object dispatch patterns (documented v4.9.18). Each exists for a specific reason.

### 1. Shared Dispatch Table (Sound, Formant, Pitch, etc. — 36/39 types)

All 36 wrappers use a shared `.{type}_methods` environment + `$.Type` S3 dispatch. PraatInterpreter is the only R6Class.

```r
.pitch_methods <- new.env(hash = TRUE, parent = emptyenv())
.pitch_methods$get_mean <- function(.self, ...) .self$.cpp$get_mean(...)
lockEnvironment(.pitch_methods, bindings = TRUE)

Pitch <- function(.xptr = NULL) {
  pitch_mod <- get_module("pitch_module")
  # The module constructor is where the pointer is reinterpreted as a Pitch; it
  # runs a Thing_isa class check, and with_pladdrr_errors() classes its refusal.
  cpp_obj <- with_pladdrr_errors(pitch_mod$RPitch$new(.xptr))
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

**List of types using this pattern:** AmplitudeTier, BarkSpectrogram, Cepstrum, Cochleagram, ComplexSpectrogram, DTW, Discriminant, DurationTier, Excitation, Formant, FormantGrid, FormantModeler, FormantPath, FormantTier, Harmonicity, Intensity, IntensityTier, KlattGrid, LFCC, LPC, LongSound, Ltas, MFCC, Manipulation, PraatMatrix, MelSpectrogram, PCA, Pitch, PitchModule, PitchTier, PointProcess, Polygon, Sound, Spectrogram, Spectrum, SpectrumTier, Table, TextGrid, VocalTract.

### 2. Pure XPtr (PowerCepstrogram)

No `.cpp` object is stored — only `.self$.xptr`. All methods are R wrapper functions that call C++ directly via `.Call()`. (`PowerCepstrum` is *not* in this group: it keeps a module object like the shared-table types.) The constructor still builds an `RPowerCepstrogram` module object once and discards it, purely to run the class check described under "The `.xptr` door" below.

**Why:** More performant than module dispatch for these types. The shared dispatch table pattern would add unnecessary indirection for objects that only need pointer access.

### 3. Triple-Class + Pointer Compat (Electroglottogram)

Triple class `c("Electroglottogram", "Sound", "PraatObject")` + `.pointer` compat alias. Inherits Sound's methods via class hierarchy.

**Why:** Electroglottogram is a Sound subclass in Praat's type system. The triple class allows it to inherit Sound's methods while maintaining its own identity.

### Special Cases

- **PraatMatrix:** the Praat `Matrix` wrapper is exported as `PraatMatrix()` with class `c("PraatMatrix", "PraatObject")`; the old name `Matrix` collided with the CRAN 'Matrix' package (duplicate function name in `pkgcheck`, S3 `as.matrix.Matrix` overwrite in `R CMD check`) and was removed without an alias. pladdrr registers no S3 method on a class named like another package's class. See `AGENT_GUIDE.md` "PraatMatrix and the 'Matrix' package".
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

**pladdrr-added parallel regions** (not upstream; Praat-tree ones logged in `PRAAT_MODIFICATIONS.md`):
`Sound_resample` sinc branch (`fon/Sound.cpp`, threshold 2000 samples, per channel,
2026-10) and `PowerCepstrogram_smooth_fast` (`batch_queries.cpp`). Only add one where
each element writes a disjoint output slot and reads shared input only — that keeps
results bit-identical at any thread count.

**How many threads "automatic" means (5.1.0).** `MelderThread_getNumberOfProcessors()`
(`src/melderthread_impl.cpp`) is the CPU affinity mask intersected with the cgroup
CPU quota on Linux, `hardware_concurrency()` on macOS and Windows (job objects and
macOS limits are not read), computed once per process. When `_R_CHECK_LIMIT_CORES_`
is set to anything but `false` — `R CMD check --as-cran` does — the automatic count
is capped at 2, because CRAN's timing check notes any example whose CPU time exceeds
2.5x its elapsed time. `pladdrr_threads(n)`, n > 0, beats both. Because the count is
read once, a test that depends on it needs a child process
(`tests/testthat/test-check-core-limit.R`). The R-level default worker count
(`.default_n_cores()`) follows the same CPU number, keeping one CPU spare only when
there are more than two.

**How much work a thread must get (5.1.0).** The minimum frames per thread at the
cepstrogram and Burg-formant sites are pladdrr constants in
`src/pladdrr_thread_thresholds.h` (250 and 40). The earlier values (40 and 3) were
below the cost of starting a thread. Remember that the divisor in
`MelderThread_computeNumberOfThreads` differs per platform, so a threshold that keeps
a short clip serial on Linux may still give it two threads on macOS.

### Custom `parallel_for_range` (REMOVED v4.9.18)

The former custom thread pool in `batch_queries.cpp` (`parallel_for_range` template) has been replaced with `MelderThread_PARALLELIZE`. This eliminates:
- Redundant thread creation/destruction per call
- Competition between two independent thread pools
- Failure to respect `pladdrr_threads()` cap

---

## The `.xptr` door and input limits (5.1.0)

**`.xptr` is a checked door.** Every wrapper constructor that accepts `.xptr` ends up
in an Rcpp module constructor (`src/modules/*_module.cpp`) that reinterprets the
external pointer as its C++ struct. Each of those constructors calls
`require_praat_class()` (`src/praat_xptr_utils.h`: Praat's `Thing_isa` *subclass*
test, so a `Sound` pointer is still accepted where Praat's `Matrix` is expected, e.g. by `PraatMatrix(.xptr = )`), and the R side wraps the
construction in `with_pladdrr_errors()` so the refusal arrives as a classed
`pladdrr_input_error` ("Not a Sound (found TextGrid)"). Without the check the first
field read is out of bounds and the R session dies uncatchably. A new wrapper type
needs both halves; `tests/testthat/test-xptr-all-constructors.R` lists the types.

**Sizes that become allocations are bounded.** `src/pladdrr_limits.h` caps a
Cochleagram at 2^29 cells and an Excitation at 10 000 bands; the guards sit in the
vendored `Sound_to_Cochleagram.cpp` / `Spectrum_to_Excitation.cpp` (all three call
doors reach them; logged in `PRAAT_MODIFICATIONS.md`). R-level factories
(`sound_create_tone()` and siblings, `PraatMatrix()`, the cochleagram methods) check
positive, finite and at most 2^29 cells with `.check_positive_finite()` /
`.check_cell_count()` in `R/validators.R`. The reason is platform behaviour: asking
for a 2.5 TB tensor makes Linux's allocator fail with a Praat error, but macOS
commits the pages and the kernel kills the R process (exit 137), which no
`tryCatch()` can see.

**Vendored `Melder_assert` is compiled out.** R adds `-DNDEBUG`, so Praat's ~1900
asserts, including every `part()`/`row()` bounds check, are dead code in an installed
build. A missing guard therefore means silent memory corruption, not an error:
validate at the pladdrr boundary. `-UNDEBUG` was considered and rejected (a
non-`NDEBUG` build is 2.1-7x slower package-wide).

---

## Test Gates

- `tests/testthat/test-fidelity-fingerprint.R` runs `tests/testthat/fingerprint/golden.R`
  (81 numbers from one synthetic signal) against `expected.tsv`; it refuses any
  ERR/NA/non-finite row. Re-record only after an intended numeric change, and explain
  every moved key in `NEWS.md`.
- `tests/testthat/test-praat-faithfulness.R` compares 19 routines with the Praat
  application (`PLADDRR_PRAAT_EXEC`, default `/Applications/Praat.app/...`) and, with
  `PLADDRR_FAITHFULNESS_OUTDIR` set, regenerates `FAITHFULNESS_REPORT.md`. Name the
  Praat version with any reference number: the CPPS pipeline differs between 6.4.27 and
  6.4.47 by about 0.13 dB.
- Some tests are platform-specific by nature (affinity and `/proc` checks are
  Linux-only; thread-count expectations differ per platform). A skip is not a pass:
  say which tests did not run.

---

## Build System

### Compilation Flags

```
-O2 (CRAN floor) — default, full speed
-O3 -march=native (embedder option) — byte-identical objects, no measurable gain (see v4.9.22 in AGENT_GUIDE.md)
#pragma STDC FP_CONTRACT OFF in melder.h — required for bit-exactness (replaced -ffp-contract=off, 2026-08)
-DHAVE_XSIMD — unconditional; RcppXsimd is a LinkingTo dependency
```

**`-O3 -march=native` does not speed this package up.** A 3–7x gap was measured
pre-2026-08-05, but it was the `-UNDEBUG -O0` debug-build penalty from
`devtools::load_all()`/`pkgbuild::compile_dll()` (see "Stale-Binary Trap"
below), not the optimisation level. On a clean build, `-O2` and
`-O3 -march=native` produce byte-identical objects for the hot translation
unit and are indistinguishable in wall time. Confirmed again 2026-08-06 via a
clean-tarball `R CMD check --as-cran` with only local toolchain path-fixes (no
`-O3`/`-march=native`): 0 install/check errors. **Do not recommend custom
flags to embedders; CRAN's stock `-O2` is full speed.**

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

`SIMD_SRC` compiles 10 `*_simd*.cpp` kernels/bridges plus `simd_utils`/`simd_info` (`-DHAVE_XSIMD`, unconditional in `PKG_CPPFLAGS` —
RcppXsimd is a `LinkingTo` dependency, so the build cannot run without it). Six
files with no externally referenced symbols were deleted in v4.9.19
(`num_distance`, `num_filtering`, `num_matrix`, `pitch_processing`,
`sound_convolution`, `sound_statistics` — 1,174 lines). The 2026-10 audit deleted 8 more
(pitch, pitch filter, autocorrelation, window functions, FormantPath, SlopeSelector,
cochleagram, excitation): dead, default-off, or not bit-exact; the FormantPath kernel
was a real `path_finder()` bug. **`pladdrr_simd(FALSE)` gates only `sound_mix`/`scale_peak`**;
other SIMD paths ignore it.

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

### Static Initialisation (load-time memory)

Praat globals are linked into `pladdrr.so`. A big global with a non-`constexpr`
constructor is initialised at `dyn.load`, dirtying every page. `theForegroundPraatObjects`
(42 MB) did this until 2026-10 (+48 MB RSS per R process/PSOCK worker → now +7 MB).
Constant-init needs **both** `constexpr _autostring()` (`melder/melder_string32.h`) and
value-init `structPraatObjects theForegroundPraatObjects {};` (`sys/praat.cpp`). Check
with RSS before/after `dyn.load` when touching `structPraatObjects` or `_autostring`.

### Stale-Binary Trap

`tools/check_callentries.sh` is wired into `configure` to self-heal the `static→extern` patch on `RcppExports.cpp`. `Rcpp::compileAttributes()` generates `static` by default, but `src/module_init.cpp` declares `extern const R_CallMethodDef CallEntries[]` to build a combined registration table. The patch converts `static` to `extern` in `RcppExports.cpp`.

**Do NOT remove this patch.** The combined registration table in `module_init.cpp` merges `CallEntries` + `ModuleEntries` into one `R_registerRoutines` call. `R_registerRoutines` REPLACES previous registrations, so both must be in a single call.

---

## Manuscript alignment (`paper/paper.md`)

The JOSS manuscript carries figures that drift. Last reconciled 2026-11-11 against version 5.1.1: the manuscript now carries
the package-side figures below, except the concordance statistic, which this repository cannot recompute. Re-check
before each submission.

| Manuscript says | Package says | Source of truth |
|-----------------|--------------|-----------------|
| 38 Praat modules | 39 (`DESCRIPTION` Description; 39 files in `src/modules/`) | `ls src/modules/*.cpp \| wc -l` |
| "version 5.0.5" (twice) | 5.1.1 | `DESCRIPTION` |
| 1401 tests | 1556 `test_that()` blocks | count lines matching `^\s*test_that\(` in `tests/testthat/*.R` (the manuscript's counting unit is not stated; use one unit) |
| 82% coverage | 93.8% (pkgcheck's covr run, macOS aarch64, 2026-11-12; `pkgcheck.log` is from 5.0.5 and stale) | rerun `covr` (see the covr FLIBS note in project memory) |
| CCC 0.9959 and 1.00 | `FAITHFULNESS_REPORT.md` is the live registry: 19 routines, all pass, tolerances per row | regenerate with the registry runner |

Statements in the manuscript that hold and that these documents depend on: wrapper objects are plain lists with
an external pointer and a shared per-class method environment; the interpreter is the only R6 class; SIMD and
threading are gated on output identical to the scalar reference; parity with Praat outranks speed.
