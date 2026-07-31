# Praat Source Modifications for pladdrr

**Last Updated:** 2026-07-31
**Package Version:** 4.9.15 (branch `cran-warnings-fix`)
**Praat Base Version:** 6.4.x (submodule at src/praat.github.io, fork `humlab-speech/praat.github.io`)
**Upstream merge-base:** `b1b3199a3` (praat/praat.github.io master, 2025-11-22) — `git diff b1b3199a3..HEAD` in the submodule is the authoritative full divergence (39 modified source files + CRAN deletions/additions)

## Overview

This document details all modifications made to the Praat source code to enable proper operation within the pladdrr R package. Changes fall into these categories:

1. **Critical Bug Fixes** - Crashes and linkage issues
2. **CRAN Compliance** - Removal of non-portable files
3. **Performance Optimizations** - SIMD acceleration, multi-threading
4. **API Compatibility** - Function declarations for FormantPath

---

## Recent Changes

### v4.9.10 — Fix dead quefrency-window params in `calculate_cpps_ultra_cpp` (2026-07-29)

`src/batch_queries.cpp`'s `calculate_cpps_ultra_cpp` declared `tilt_line_quefrency`
(default `0.001`) and `max_quefrency` (default `0.05`) but never passed them into its
`PowerCepstrogram_getCPPS_fast(...)` call — the trend-fit quefrency window was
hardcoded to `[0.003, 0.04]` regardless of caller input. Callers needing a different
window (e.g. AVQI's Praat-matching `[0.001, 0]`, `0` = autowindow to full range) got a
silently wrong CPPS with no error — plabench's AVQI R measured 0.31 dB off Praat
(11.91 vs 12.22 dB) as a result. Fixed: params now threaded through; R-level defaults in
`calculate_cpps_ultra()` changed `0.001`/`0.05` → `0.003`/`0.04` to match the value that
was actually being applied before, so default-argument callers see no behavior change.
See NEWS.md 4.9.10 entry.

### v4.9.9 — Refresh stale pitch-performance note (2026-07-27)

Submodule commit `9cd0e87c0`. Comment-only edit to `fon/Sound_to_Pitch.cpp`'s
header doc-comment — no DSP/behavioral change. Replaces the old "~5x slower
than Parselmouth / 95ms" claim with the 2026-07 assessment numbers:
`to_pitch_cc_direct()` is ~52ms single-threaded and ~9ms with the default
threaded path, i.e. roughly at parity with Parselmouth once threading is
on; NEON SIMD moves pitch little on this kernel. See
`dev/OPTIMIZATION_ASSESSMENT_2026-07.md` and the NEWS 4.9.9 entry
("Documented current NEON reality... refreshed stale pitch-performance note").

### v4.9.7 — Fix Windows COMDAT collision for FormantGridEditor_create (2026-07-20)

Submodule commit `42414e1d4`, file `fon/praat_Tiers.cpp` (+8 lines). The
header-inline `FormantGridEditor_create` emits a COMDAT in `praat_Tiers.o`
that collides with the library-mode stub's strong definition at link time on
COFF (mingw); ELF/Mach-O linkers let the strong symbol win silently, which
masked the issue on macOS/Linux. Editors cannot be opened in library mode, so
the NO_GUI branch now throws instead of linking a dead editor path. Matches
the NEWS 4.9.7 bullet "Fixed a Windows COMDAT collision for
`FormantGridEditor_create`".

### v4.9.7 — NO_GUI Win32 gate + NUMlapack.h R-header removal (2026-07-19)

Submodule commit `a17add655`. Two build repairs for CRAN's Windows and R-devel checks:

- **`sys/praat.cpp`:** `GuiWin_initialize1()` and `motif_win_setUserMessageCallback()`
  are not compiled in the NO_GUI edition, but the two `#if defined (_WIN32)` call
  sites in `praat_init`/`praat_run` referenced them unconditionally → undefined
  symbols at link on mingw. Both call sites are now additionally gated on
  `#if ! defined (NO_GRAPHICS)` (pure GUI initialization; never needed by the
  embedded library).
- **`dwsys/NUMlapack.h`:** stopped including `R_ext/BLAS.h` + `R_ext/Lapack.h`.
  Since R-devel these headers declare Fortran hidden-length (`FCLEN`) arguments
  unconditionally, conflicting with this header's CLAPACK-style inline shims that
  reuse the `dgeev_`/`dlamch_`/… names. R's LAPACK is reached only via the
  package's `src/r_lapack_wrapper.cpp` (which defines `USE_FC_LEN_T`); Praat
  code sees only the shim declarations.

### v4.9.6+ CRAN forbidden-function cleanup: rand()/sprintf()/printf() (2026-07-18)

Submodule commit `600ee49ec` (branch `cran-warnings-fix`). `R CMD check` flags
`rand`, `sprintf`, and `printf` in compiled code. All call sites patched:

- **`dwtools/KlattTable.cpp`** (`KlattFrame_flutter`): `rand() % …` noise source
  replaced with Praat's own `NUMrandomInteger (-8191, 8191)`. Praat's RNG is
  seeded deterministically per Melder init, so this also removes hidden global
  state; numeric character of the flutter noise is equivalent (uniform ±8191).
- **`melder/melder_ftoa.cpp`**: all 24 `sprintf` calls in the `Melder8_*`
  formatters (`bigInteger`, `dcomplex`, `scomplex`, `naturalLogarithm`,
  `colour`) replaced with bounds-checked `snprintf` against
  `MAXIMUM_NUMERIC_STRING_LENGTH + 1 - <offset>`. Output strings identical for
  all in-range values.
- **`sys/praat_script.cpp`** (`praat_executeCommandFromStandardInput`): the one
  `printf` prompt replaced with `Melder_casual` (routes through MelderConsole,
  which has the v4.9.3 null-stream guard). This is interactive-CLI code, never
  reached from the library, but the symbol had to go.

### v4.9.6 CRAN compiled-code cleanup: remove abort()/_Exit() (2026-07-18)

`R CMD check` flags direct `abort`/`exit`/`_exit`/`stderr`/`stdout` in compiled
code. Eliminated the two that appeared in many objects, both via central
definitions so no per-call-site edits were needed:

- `melder/melder_assert.h`, `melder/melder_error.h`: the `Melder_assert` and
  `Melder_fatal` macros ended in `abort()`. But `Melder_assert_` and
  `Melder_fatal_` (melder_error.cpp) already unconditionally `throw MelderError`
  — the `abort()` was unreachable. Marked both functions `[[noreturn]]` and
  dropped `abort()` from the macros, so the `abort` symbol disappears from every
  object. Assertion/fatal failures now propagate to the R boundary as errors
  instead of crashing R.
- `melder/melder_error.cpp` (`Melder_flushError` crash branch): replaced the one
  direct `abort()` with `throw MelderError()`.
- `sys/praat.cpp` (`praat_exit`): wrapped the `_Exit()/exit()` app-shutdown in
  `#ifndef PRAAT_LIB`; in the embedded library it throws instead of terminating
  the host R process.

**Residual (justified, not patched — see cran-comments.md):** `stderr`/`stdout`
remain in `melder_console.cpp` as a libc fallback because Praat's DSP worker
threads emit casual diagnostics and R's `REprintf`/`Rprintf` are main-thread
only; `_exit` remains in `melder_sysenv.cpp` as the correct POSIX fork-child
idiom; and unreachable Praat `main`/CLI/self-test code (`exit`, `isatty`,
`fprintf(stderr)`) is compiled but never entered from the library.

### v4.9.6 CRAN significant-warning fixes (2026-07-17)

Two edits so `R CMD check` reports no significant compiler warnings (needed
after removing the `-Wno-*` suppressions from `Makevars`):

- `sys/praat.cpp` (`praat_run`): the startup self-test that records how
  different compilers order function arguments uses `++i`/`i++` unsequenced in a
  single `snprintf`/`trace` call (undefined behaviour, `-Wunsequenced`). Wrapped
  the whole `{ ... }` self-test block in `#ifndef PRAAT_LIB ... #endif` — it is
  Praat-application diagnostic code, not needed in the embedded library, so it
  now compiles out. No behavioural change to any DSP routine.
- `fon/PitchTier.cpp` (`PitchTier_shiftFrequencies`): the `switch (unit)` over
  `kPitch_unit` did not handle every enum value (`-Wswitch`). Added a
  `default: {}` case that leaves the frequency unchanged, matching the prior
  fall-through behaviour.

### v4.9.5 CRAN tarball slimming — single Praat source tree (2026-07-17)

No Praat C++ source changes. Packaging only:

- Deleted `src/praat/`, a git-tracked ~107 MB partial duplicate of the Praat
  tree that existed solely to provide `-Ipraat/external/{gsl,glpk,num}` header
  paths for the Windows build. Those directories are byte-identical to
  `praat.github.io/external/{gsl,glpk,num}`, which are already on the include
  path, so the duplicate and the 3 `-Ipraat/external/*` lines in `Makevars.in`
  and `Makevars.win` were pure redundancy. **Both platforms now compile from a
  single `praat.github.io/` prefix.** When updating the Praat submodule, no
  second tree needs to be kept in sync.
- The built tarball now excludes (via `.Rbuildignore`) all non-compiled Praat
  source: external-library `.c/.cpp` (espeak/flac/mp3/portaudio/vorbis/opusfile/
  lame/clapack/gsl/glpk — stubbed at build time; only their headers are kept),
  the non-compiled subtrees (artsynth/EEG/FFNet/gram/main/makefiles/dwtest/
  docs/generate/test), and `manual_*.cpp`. These are dev-tree-only exclusions;
  the compiled source set (243 `.cpp`) and all reachable headers still ship.

### v4.9.3 Melder_casual null-stream guard (Willems/split-Levinson segfault) (2026-07-12)

#### `src/praat.github.io/melder/melder_console.cpp` — `MelderConsole::write`

**Problem:** `Sound_to_Formant_willems()` / `to_formant_sl()` crashed with SIGSEGV
at address 0x68 (same signature as §1.1) whenever the split-Levinson root-finder
emitted a casual diagnostic ("There is no zero between ...", "Degree N not
completed"). Pure tones and silence trigger this on every frame.

**Root Cause:** In the embedded (no-GUI) build, the lazy init that assigns
`Melder_stdout`/`Melder_stderr` never runs, so both globals are `nullptr`.
`MelderConsole::write()` did `fputc(kar, f)` with `f == nullptr` →
`flockfile(NULL)` derefs the FILE `_lock` field at offset 0x68. The formant
frame loop is `MelderThread_PARALLELIZE`d, so the casual write also fired from
worker threads, but the null stream — not threading — is the crash cause; it
would crash single-threaded too.

**Fix:** Fall back to the real libc `stderr`/`stdout` when the Melder globals are
null, and no-op if even those are null:
```cpp
FILE *f = useStderr ? Melder_stderr : Melder_stdout;
if (! f) f = useStderr ? stderr : stdout;   // pladdrr: embedded null-stream guard
if (! f) return;
```
Bit-exact: formant values are unchanged; only the previously-crashing diagnostic
text now reaches stderr (matching Praat's own behaviour). R-level wrappers
`to_formant_willems()`/`to_formant_sl()` additionally reject `number_of_formants`/
`number_of_poles < 1` before the C++ call (`.check_positive_count`).

### v4.9.1 BUG-1/BUG-2: Laguerre LPC fallback + parabolic interpolation guard (2026-06-10)

Submodule commit `dc9a63eab`, from the 2026 developer report (pladdrr commit `c600e287`).

#### `fon/Sound_to_Formant.cpp` — Laguerre fallback when dhseqr_ drops eigenvalues (BUG-1)

**Problem:** formant extraction on short analysis windows (≤100 ms) could return
fewer roots than the LPC order: LAPACK's `dhseqr_` fails to converge on all
eigenvalues of the ill-conditioned companion/Hessenberg matrix, and Praat
silently proceeded with the truncated root set → missing formants.

**Fix:** after `Polynomial_to_Roots`, if `roots->numberOfRoots < coefficients.size`,
re-solve the polynomial with Laguerre's method (`polynomial_roots_laguerre`,
implemented in pladdrr's `src/polynomial_roots_laguerre.h`, included via relative
path) and polish with `Roots_Polynomial_polish`. Primary path unchanged; the
fallback only runs when LAPACK under-delivers, so results are bit-exact for all
well-conditioned frames.

#### `melder/NUMinterpol.cpp` — `NUMimproveExtremum()` near-zero-denominator guard (BUG-2)

**Problem:** the `NUM_PEAK_INTERPOLATE_PARABOLIC` path computed
`y[ixmid] + 0.5 * dy * dy / d2y` without checking `d2y`. Flat LTAS peaks give
near-zero `d2y` → division blow-up; `get_peaks_batch` returned physically
impossible 500–1231 dB values.

**Fix:**
```cpp
if (d2y <= 0.0)               { *ixmid_real = ixmid; return y [ixmid]; }  // flat or concave-up
const double offset = dy / d2y;
if (fabs (offset) >= 1.0)     { *ixmid_real = ixmid; return y [ixmid]; }  // extrapolation out of range
```
Degenerate peaks now return the bin value unchanged; genuine parabolic peaks are
unaffected. **Upstream:** not reported (Praat's GUI may never hit this path with
flat LTAS peaks).

### v4.8.35 SPINET gammatone arg-swap fix (2026-05-06)

#### `src/praat.github.io/fon/Sound_to_SPINET.cpp` — gammatone filter args

Upstream Praat call `Sound_createGammaTone(..., b, f[i], ...)` passed `b=1.02`
(the ERB bandwidth constant) as the frequency argument and the center
frequency `f[i]` as the bandwidth — every cochlear filter was actually built
at 1.02 Hz. Speech has no energy near DC, so the filter outputs were ≈0, the
on-center / off-surround interaction yielded an all-zero SPINET matrix, and
`SPINET_to_Pitch` aborted with "The sound should not have all amplitudes
equal to zero."

```cpp
// BEFORE (upstream):
Sound_createGammaTone(..., /*frequency*/ b, /*bandwidth*/ f[i], ...);
// AFTER:
Sound_createGammaTone(..., /*frequency*/ f[i], /*bandwidth*/ bw[i] / NUM2pi, ...);
```

`bw[i]` is already computed by Praat as `2π · b · ERB(f[i])` in rad/s, so
dividing by `NUM2pi` recovers the ERB bandwidth in Hz that
`Sound_createGammaTone` expects.

This is a pure correctness fix; no perf impact. Required for `sound$to_pitch_spinet()`
to return non-empty results on real speech.

---

### v4.8.34 SHS & SPINET pitch methods (2026-04-08)

**Summary:** Add SHS (Subharmonic Summation) and SPINET (Seneff Periodic Network)
pitch extractors across all three API tiers. Compiles four new Praat sources and
adds four extracted helper functions.

#### `src/Makevars.in` / `src/Makevars` / `src/Makevars.win` — new sources

Added to `PRAAT_FON_SRC`:
- `Sound_to_Pitch2.cpp` (SHS pitch)
- `SPINET.cpp` (SPINET data class)
- `Sound_to_SPINET.cpp` (SPINET extraction)
- `SPINET_to_Pitch.cpp` (SPINET → Pitch)

#### `src/sound_create_gaussian.cpp` — extracted helpers

Hosted four helper functions previously embedded in Praat private TUs so the
SPINET path can link without dragging in the full upstream object:

- `Sound_createGammaTone`
- `Sound_power`
- `Sound_correlateParts`
- `Sound_localPeak`

**No Praat C++ source changes** — the SPINET correctness fix follows in v4.8.35.

---

### v4.8.33 All 35 wrappers on shared dispatch tables (2026-03-09)

**Summary:** No Praat C++ source changes. All 34 remaining wrappers (everything except Sound, which was done in v4.8.32) ported from per-instance closure pattern to shared dispatch table pattern. Also: 22 missing `is_valid` methods added, cochleagram `as_matrix()` return type fixed, cepstrum `Sound$new(xptr)` → `Sound(.xptr = xptr)` bug fixed, NAMESPACE updated (8→44 `S3method` entries), version bumped to 4.8.33.

---

### v4.8.32 Sound shared dispatch + symbol registration fix + Makevars.in fix (2026-03-09)

**Summary:** Three critical fixes plus the Sound wrapper rewrite. Two changes touch C++ source files.

#### `src/RcppExports.cpp` — `CallEntries` visibility change

Changed `CallEntries` from `static const R_CallMethodDef[]` to `extern const R_CallMethodDef[]` so `module_init.cpp` can reference it. This is the only change to the Rcpp-generated file.

**Update (v4.9.11, 2026-07-29):** `Rcpp::compileAttributes()` regenerates this file with `static` every time, silently reverting the patch and reintroducing a `dlopen`/`symbol not found: _CallEntries` load failure — this happened again in v4.9.11 when `compileAttributes()` ran to add `get_voice_quality_ultra()`'s new args. `tools/check_callentries.sh` is now wired into `configure` and self-heals: it `sed`-patches `static` back to `extern` automatically before every build, so this no longer requires manual re-application. Manual re-application is only needed if `CallEntries[]`'s declaration shape changes entirely (the script fails loudly in that case).

```cpp
// BEFORE:
static const R_CallMethodDef CallEntries[] = { ... };
// AFTER:
extern const R_CallMethodDef CallEntries[] = { ... };
```

#### `src/module_init.cpp` — Combined `R_registerRoutines` table

The `[[Rcpp::init]]` hook `register_module_entries()` was calling `R_registerRoutines(dll, NULL, ModuleEntries, NULL, NULL)` which **replaced** the 777 Rcpp-exported `CallEntries` with only 38 module boot entries. Now builds a combined table:

```cpp
extern const R_CallMethodDef CallEntries[];  // from RcppExports.cpp

void register_module_entries(DllInfo *dll) {
    // Count CallEntries
    int n_call = 0;
    while (CallEntries[n_call].name != NULL) n_call++;
    int n_mod = sizeof(ModuleEntries)/sizeof(ModuleEntries[0]) - 1;
    
    // Build combined table
    std::vector<R_CallMethodDef> combined;
    combined.reserve(n_call + n_mod + 1);
    for (int i = 0; i < n_call; i++) combined.push_back(CallEntries[i]);
    for (int i = 0; i < n_mod; i++) combined.push_back(ModuleEntries[i]);
    combined.push_back({NULL, NULL, 0});
    
    R_registerRoutines(dll, NULL, combined.data(), NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
}
```

#### `src/Makevars.in` — Added `simd_utils.cpp` to SIMD_SRC

The `configure` script generates `src/Makevars` from `src/Makevars.in` via `sed`. The file was missing `simd_utils.cpp` from the `SIMD_SRC` variable, causing the `_g_simd_enabled` symbol to be missing at load time. This was the root cause of persistent build failures after Phase 1 — fixing `Makevars` directly never persisted because `configure` overwrites it.

**No Praat submodule changes** — all modifications are in pladdrr wrapper code.

---

### v4.8.31 Phase 2 R-level performance fixes (2026-03-09)

**Summary:** No Praat C++ source changes. Three R-level performance fixes:
- `vad.R`: O(n²) → O(n) vector growth in `textgrid_get_intervals_where()`
- `textgrid-wrapper.R`: removed duplicate slow `get_all_points()` that shadowed fast C++ version
- `batch-processing.R`: `extract_measurements()` now uses batch C++ calls instead of per-interval R loops

---

### v4.8.29 Revert broken SIMD blocks in Sound_to_Pitch.cpp; fix GNE threshold (2026-02-19)

**Summary:** The v4.8.27 SIMD additions to `Sound_to_Pitch.cpp` caused ~16–29× performance regressions. Both `#ifdef HAVE_XSIMD` blocks are removed and the plain scalar code restored. GNE parallelization threshold raised from 1 to 4.

**No submodule commit** — changes are in pladdrr's copy of `src/praat.github.io/fon/`.

---

#### `fon/Sound_to_Pitch.cpp` — Remove FCC SIMD block (Fix 5 reverted)

The "Fix 5 (batched sqrt)" block inside `Sound_into_PitchFrame()` allocated two heap vectors per call:
```cpp
// REMOVED — caused ~29× regression:
autoVEC sumy2_arr  = raw_VEC (localMaximumLag);
autoVEC product_arr = raw_VEC (localMaximumLag);
// ... two-pass loop with simd_bridge_direct::compute_fcc_product_simd() ...
// ... xsimd normalization pass ...
```
`Sound_into_PitchFrame` is called for every pitch frame (hundreds per second). Two `raw_VEC` heap allocations × hundreds of calls = catastrophic malloc pressure.

**Current state:** Only the scalar `#else` branch remains (no `#ifdef`/`#endif` wrapper):
```cpp
for (integer i = 1; i <= localMaximumLag; i ++) {
    longdouble product = 0.0;
    for (integer channel = 1; channel <= my ny; channel ++) {
        const double *const amp = & my z [channel] [0] + offset;
        const double y0 = amp [i] - localMean [channel];
        const double yZ = amp [i + nsamp_window] - localMean [channel];
        sumy2 += yZ * yZ - y0 * y0;
        for (integer j = 1; j <= nsamp_window; j ++) {
            const double x = amp [j] - localMean [channel];
            const double y = amp [i + j] - localMean [channel];
            product += x * y;
        }
    }
    r [- i] = r [i] = (double) product / sqrt ((double) sumx2 * (double) sumy2);
}
```
This auto-vectorizes under `-O3 -march=armv8-a+simd` without any heap allocation.

---

#### `fon/Sound_to_Pitch.cpp` — Remove AC power spectrum SIMD block (brace bug)

The AC path had a structural brace bug in the `#ifdef HAVE_XSIMD` block:
```cpp
// REMOVED — brace closed channel for-loop inside #ifdef:
for (integer channel = 1; channel <= my ny; channel ++) {
    NUMfft_forward (...);
#ifdef HAVE_XSIMD
    simd_bridge_direct::accumulate_power_spectrum_simd(frame, ac, nsampFFT, my ny);
}   // ← closes for-loop inside #ifdef! wrong for ny>1
#else
    // scalar accumulation ...
}
#endif
```
For stereo (`ny>1`): the loop was only entered for channel=1 but accumulated all channels (the SIMD function received `my ny`), producing wrong results. For mono: a non-inlined function call per frame was added with no benefit.

**Current state:** Only the scalar accumulation remains:
```cpp
for (integer channel = 1; channel <= my ny; channel ++) {
    NUMfft_forward (fftTable, VEC (& frame [channel] [1], fftTable->n));
    ac [1] += frame [channel] [1] * frame [channel] [1];
    for (integer i = 2; i < nsampFFT; i += 2)
        ac [i] += frame [channel] [i] * frame [channel] [i] + frame [channel] [i+1] * frame [channel] [i+1];
    ac [nsampFFT] += frame [channel] [nsampFFT] * frame [channel] [nsampFFT];
}
```

---

#### `fon/Sound_to_Harmonicity_GNE.cpp` — Raise PARALLELIZE threshold 1→4

```cpp
// Before:
MelderThread_PARALLELIZE (nenvelopes, 1)

// After:
MelderThread_PARALLELIZE (nenvelopes, 4)
```

With threshold=1 and nenvelopes=50 (fmax=4500, step=80), all 50 bands were scheduled concurrently. Each band allocates `Data_copy` + `Spectrum_to_Sound` + `Sound_extractPart`. Concurrent malloc pressure across ~10 threads caused ~4.6× overhead vs sequential. Threshold=4 limits concurrency to ~12 batches, substantially reducing allocator contention while retaining parallelism.

The cross-correlation loop (Loop C, npairs=1225) retains threshold=5.

---

### v4.8.27 GNE parallelization + Pitch CC batched sqrt (2026-02-19)

**⚠ Partially reverted in v4.8.29:** GNE Loop B/C parallelization remains (threshold adjusted). Pitch CC "Fix 5" batched sqrt was reverted — see v4.8.29.

**Summary:** Two embarrassingly parallel loops in `Sound_to_Harmonicity_GNE.cpp` are now dispatched via `MelderThread_PARALLELIZE`. Pitch CC normalization used a two-pass batched `xsimd::sqrt` (since reverted due to heap-alloc regression).

**Submodule commit:** `4f52f5f07`

---

#### `fon/Sound_to_Harmonicity_GNE.cpp`

**Added headers:**
```cpp
#include <vector>
#include <utility>
```

**Loop B — Hilbert envelope computation (was sequential `while` loop):**

Before:
```cpp
double fmid = fmin;
integer ienvelope = 1;
while (fmid <= fmax) {
    // ... per-band work ...
    fmid += step;
    ienvelope += 1;
}
nenvelopes = ienvelope - 1;
```

After:
```cpp
// nenvelopes precomputed (loop no longer increments ienvelope)
nenvelopes = (integer) Melder_ifloor ((fmax - fmin) / step);  // moved up before Loop B
// ...
MelderThread_PARALLELIZE (nenvelopes, 4)   // threshold raised to 4 in v4.8.29
MelderThread_FOR (ienvelope) {
    const double fmid_local = fmin + (ienvelope - 1) * step;
    // identical per-band work, reads only shared read-only data,
    // writes only to envelope[ienvelope] (distinct per thread)
} MelderThread_ENDFOR
```

**Key:** `nenvelopes` must be computed **before** Loop B (from `Melder_ifloor((fmax-fmin)/step)`) since `ienvelope` is no longer incremented by the loop.

**Loop C — cross-correlation matrix (was nested `for row / for col`):**

Before:
```cpp
nenvelopes = ienvelope - 1;
autoMatrix cc = Matrix_createSimple (nenvelopes, nenvelopes);
for (integer row = 2; row <= nenvelopes; row ++) {
    for (integer col = 1; col <= row - 1; col ++) {
        autoSound crossCorrelation = Sounds_crossCorrelate_short (...);
        double ccmax = Vector_getMaximum (...);
        cc -> z [row] [col] = ccmax;
    }
}
```

After:
```cpp
// nenvelopes already set above (from Melder_ifloor)
autoMatrix cc = Matrix_createSimple (nenvelopes, nenvelopes);

std::vector<std::pair<integer,integer>> pairs;
pairs.reserve ((integer)(nenvelopes * (nenvelopes - 1) / 2));
for (integer row = 2; row <= nenvelopes; row ++)
    for (integer col = 1; col <= row - 1; col ++)
        pairs.push_back ({row, col});

const integer npairs = (integer) pairs.size ();
MelderThread_PARALLELIZE (npairs, 5)
MelderThread_FOR (ipair) {
    const integer row = pairs [(size_t) (ipair - 1)].first;
    const integer col = pairs [(size_t) (ipair - 1)].second;
    autoSound crossCorrelation = Sounds_crossCorrelate_short (
        envelope [row].get(), envelope [col].get(), -3.1e-4, 3.1e-4, true);
    cc -> z [row] [col] = Vector_getMaximum (
        crossCorrelation.get(), 0.0, 0.0, kVector_peakInterpolation :: NONE);
} MelderThread_ENDFOR
```

**Safety:** each pair `(row, col)` is unique — each thread writes to a distinct `cc->z[row][col]` cell with no contention. `envelope[i]` objects are read-only after Loop B.

---

#### `fon/Sound_to_Pitch.cpp` — Fix 5: batched sqrt

**Added header (at top of existing `#ifdef HAVE_XSIMD` block):**
```cpp
#include "../../xsimd_compat.h"
```
(`../../` resolves to `src/` from `src/praat.github.io/fon/`)

**Restructured CC normalization inside `Sound_into_PitchFrame()`:**

The original code (under `#ifdef HAVE_XSIMD`) called `compute_fcc_product_simd` for the inner product but still called `sqrt()` once per lag in the outer loop. Fix 5 splits into two passes:

**Pass 1 — accumulate per-lag arrays (replaces the single combined loop):**
```cpp
autoVEC sumy2_arr  = raw_VEC (localMaximumLag);
autoVEC product_arr = raw_VEC (localMaximumLag);

for (integer i = 1; i <= localMaximumLag; i ++) {
    longdouble product = 0.0;
    for (integer channel = 1; channel <= my ny; channel ++) {
        const double *const amp = & my z [channel] [0] + offset;
        const double y0 = amp [i] - localMean [channel];
        const double yZ = amp [i + nsamp_window] - localMean [channel];
        sumy2 += yZ * yZ - y0 * y0;
        simd_bridge_direct::compute_fcc_product_simd (
            amp, localMean [channel], i, nsamp_window, product);
    }
    sumy2_arr  [i] = (double) sumy2;
    product_arr [i] = (double) product;
}
```

**Pass 2 — vectorized normalization:**
```cpp
const double sumx2_d = (double) sumx2;
using batch_t = XSIMD_BATCH(double);
constexpr std::size_t simd_w = batch_t::size;
integer i = 1;
for (; i + (integer)simd_w - 1 <= localMaximumLag; i += (integer)simd_w) {
    auto sy2    = xsimd::load_unaligned (& sumy2_arr  [i]);
    auto pr     = xsimd::load_unaligned (& product_arr [i]);
    auto result = pr / xsimd::sqrt (sumx2_d * sy2);
    xsimd::store_unaligned (& r [i], result);
    for (std::size_t k = 0; k < simd_w; k ++)
        r [- (i + (integer)k)] = r [i + (integer)k];
}
// scalar tail
for (; i <= localMaximumLag; i ++) {
    r [- i] = r [i] = product_arr [i] / sqrt (sumx2_d * sumy2_arr [i]);
}
```

**`#else` branch** (no `HAVE_XSIMD`): retains original scalar loop (no SIMD dependency).

**Key API notes for transplantation:**
- Use `XSIMD_BATCH(double)` macro (from `xsimd_compat.h`) — NOT `xsimd::batch<double>`
- Use `xsimd::load_unaligned()` / `xsimd::store_unaligned()` free functions — NOT `.load_unaligned()` static methods
- `raw_VEC(n)` allocates an uninitialized heap `VEC` of length `n`

**Impact:** Eliminates ~210 individual `sqrt()` calls per pitch frame (one per lag in localMaximumLag ≈ 210 for typical settings). SIMD width replaces them with ≈ 210/4 = 53 batched `xsimd::sqrt` operations.

---

### v4.8.19 xsimd v8+ API Compatibility (2026-02-06)

**Summary:** Updated all SIMD code for compatibility with RcppXsimd's xsimd v8+ API. Fixes compilation errors from API changes between xsimd v7 and v8.

**Root Cause:** xsimd v8+ changed core APIs:
- `batch<T>` now requires two template params: `batch<T, Arch>`
- Load functions moved from members to namespace: `batch::load_*()` → `xsimd::load_*()`
- Reduce functions removed from namespace: `xsimd::reduce_add/min/max()` no longer exist
- Alignment queries changed: `batch::arch_type::alignment()` removed

**Changes to Praat Source (submodule commit 69a6ae069):**

**Files Modified:**
- `dwsys/NUM2.cpp` — Added `#include "../../../xsimd_compat.h"`, replaced `xsimd::batch<double>` with `XSIMD_BATCH(double)`, replaced `xsimd::reduce_add()` with `xsimd_compat::reduce_add_compat()` in Burg algorithm
- `melder/NUM.cpp` — Added xsimd_compat.h, updated batch typedef and reduce_add in `NUMinner_simd()`
- `fon/Sound_to_Intensity.cpp` — Added xsimd_compat.h, updated batch typedef and reduce_add in RMS computation

**Changes to pladdrr SIMD Wrappers (NOT in Praat submodule):**
- 12+ files updated with API compatibility fixes:
  - `xsimd_compat.h` — Added `reduce_min_compat()` and `reduce_max_compat()` wrappers
  - All `*_simd.cpp` files — Fixed batch initialization, load functions, reduce functions, alignment constants, namespace scoping
  - See main commit for full list of wrapper changes

**Build System:**
- No Makevars changes required (already had xsimd support)

**Impact:** Package now compiles successfully with RcppXsimd on all platforms. All SIMD optimizations remain functional.

**Compatibility:** All changes use `#ifdef HAVE_XSIMD` with scalar fallbacks. No functional changes when SIMD disabled.

---

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

Authoritative list: `git diff --name-status b1b3199a3..HEAD` in the submodule
(40 modified source files as of 2026-07-27). Grouped by purpose:

| File | Category | Changes |
|------|----------|---------|
| `sys/Thing.h` | Bug fix | Extern class registry |
| `sys/Thing.cpp` | Bug fix | Extern linkage, null checks |
| `sys/Data.cpp` | Bug fix | cstdio header |
| `sys/praat.cpp` | CRAN + build | `_Exit()/exit()` gated behind `#ifndef PRAAT_LIB` (v4.9.6); unsequenced self-test compiled out (v4.9.6); NO_GUI gate on Win32 GUI init (v4.9.7) |
| `sys/praat_script.cpp` | CRAN | `printf` prompt → `Melder_casual` (v4.9.6+) |
| `melder/MelderReadText.cpp` | Bug fix | cstdio header |
| `melder/melder_assert.h`, `melder/melder_error.h`, `melder/melder_error.cpp` | CRAN | `abort()` removed from `Melder_assert`/`Melder_fatal`; `[[noreturn]]` + throw (v4.9.6) |
| `melder/melder_console.cpp` | Bug fix | Null-stream guard in `MelderConsole::write` (v4.9.3) |
| `melder/melder_ftoa.cpp` | CRAN | 24× `sprintf` → bounds-checked `snprintf` (v4.9.6+) |
| `melder/NUMinterpol.cpp` | Bug fix | Debug-output removal (early); `NUMimproveExtremum` parabolic guard (v4.9.1) |
| `melder/NUM.cpp` | SIMD | NUMinner SIMD (v4.8.4) + xsimd v8+ compat (v4.8.19) |
| `melder/melder.cpp`, `melder/NUMspecfunc.cpp`, `melder/MAT.cpp` | Build plumbing | GSL includes stubbed/re-pathed (system GSL linked instead of vendored sources) |
| `dwsys/NUMmachar.h` | Bug fix | Extern NUMfpp |
| `dwsys/NUMmachar.cpp` | Bug fix | NUMfpp definition |
| `dwsys/NUM2.cpp` | Bug fix + SIMD | NULL check + Burg SIMD (v4.8.4 fix) + xsimd v8+ compat (v4.8.19) |
| `dwsys/NUMFourier.cpp` | FFT backend | Replaced FFTPACK with pocketfft (v4.8.12) |
| `dwsys/NUMlapack.h` | Build | R BLAS/LAPACK headers dropped (FCLEN conflict with CLAPACK shims; v4.9.7) |
| `dwsys/NUMselect.h` | Build plumbing | Include path flattened |
| `fon/Formant.h` | API | extractPart declaration |
| `fon/PitchTier.cpp` | CRAN | `-Wswitch` default case in `PitchTier_shiftFrequencies` (v4.9.6) |
| `fon/Sound_to_Intensity.cpp` | SIMD | RMS optimization + xsimd v8+ compat (v4.8.19) |
| `fon/Sound_to_Pitch.cpp` | SIMD + Performance | Pitch analysis SIMD + parallelization threshold (v4.8.9) + batched sqrt Fix 5 (v4.8.27); broken SIMD blocks reverted (v4.8.29); pitch-performance doc-comment refreshed, no behavior change (v4.9.9) |
| `fon/praat_Tiers.cpp` | Bug fix | NO_GUI-gate `FormantGridEditor_create` instantiation — Windows COMDAT collision (v4.9.7) |
| `fon/Sound_to_Harmonicity_GNE.cpp` | Performance | Loop B + Loop C parallelized via MelderThread (v4.8.27) |
| `fon/Sound_to_Formant.cpp` | SIMD + Bug fix | Uses VECburg directly (v4.8.4); Laguerre root-finding fallback (v4.9.1) |
| `fon/Sound_and_Spectrogram.cpp` | SIMD | Spectrogram optimization |
| `fon/Sound.cpp` | SIMD | Pre-emphasis optimization |
| `dwtools/Sound_and_Spectrogram_extensions.cpp` | SIMD | MFCC optimization |
| `dwtools/Spectrogram_extensions.cpp` | SIMD | Mel-frequency SIMD |
| `dwtools/Sound_to_SPINET.cpp` | Bug fix | Gammatone frequency/bandwidth arg swap (v4.8.35) |
| `dwtools/KlattTable.cpp` | CRAN | `rand()` → `NUMrandomInteger` (v4.9.6+) |
| `dwtools/Intensity_extensions.h`, `dwtools/Sound_and_TextGrid_extensions.{h,cpp}` | Build plumbing | Include paths made explicit (`../fon/...`) |
| `LPC/FormantPath.cpp` | SIMD | Path optimization |
| `LPC/Sound_to_PowerCepstrogram.cpp` | SIMD | PowerCepstrogram frame processing (v4.8.10) |

Note: `melder/MelderThread.cpp` has **zero net diff** vs upstream (the old
debug-fprintf edit was superseded); pladdrr's real multi-threaded MelderThread
implementation lives on the package side in `src/num_stubs.cpp`, not in the
submodule. Also diverged vs upstream: deleted external-library sources
(flac/mp3/…, CRAN slimming), `fon/Sound_files.cpp` moved to
`excluded_sources/Sound_files.cpp` (still compiled — see `SOURCES` in
`Makevars.in`), added flattened header copies (`fon/Table.h` etc.) and
`.disabled`/`.backup` files (never compiled).

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
| `9cd0e87c0` | Refresh stale pitch-performance note, comment-only (v4.9.9) |
| `42414e1d4` | NO_GUI-gate FormantGridEditor_create — fix Windows COMDAT collision (v4.9.7) |
| `a17add655` | NO_GUI-gate Win32 GUI init; drop R headers from NUMlapack.h (v4.9.7) |
| `600ee49ec` | rand()/sprintf()/printf() removal (v4.9.6+) |
| `fc0ee4d97` | abort()/_Exit() removal (v4.9.6) |
| `45cf303fd` | -Wunsequenced + -Wswitch fixes (v4.9.6) |
| `43a731ed6` | MelderConsole null-stream guard (v4.9.3 — commit titled "Init code for use in pladdrr") |
| `dc9a63eab` | Laguerre LPC fallback + NUMimproveExtremum guard (v4.9.1) |
| `9d7817260` | SPINET gammatone arg-swap fix (v4.8.35) |
| `51912e676` | Remove broken SIMD blocks from Pitch CC + GNE threshold (v4.8.29) |
| `4f52f5f07` | GNE Loop B+C parallelized, Pitch CC batched sqrt Fix 5 (v4.8.27) |
| `69a6ae069` | xsimd v8+ API compatibility (v4.8.19) |
| `e0ac128c9` | FFTPACK → pocketfft in NUMFourier (v4.8.12) |
| `38f99c1d1` | PowerCepstrogram SIMD (v4.8.10) |
| `fadf66fbc` | Pitch parallelization threshold 5→20 frames (v4.8.9) |
| `9bfd77e19` | SIMD formant fix — VECburg with SIMD inner loops (v4.8.4) |
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
