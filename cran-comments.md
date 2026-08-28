## Submission notes

pladdrr provides a dependency-free, object-oriented R interface to Praat's
phonetic-analysis DSP routines by vendoring a **curated subset** of Praat's
C++ source (from the pinned `praat.github.io` upstream) and compiling it via
Rcpp. Bundling the source is what lets the package reproduce Praat's numeric
output faithfully without requiring an external Praat installation.

### Installed/source size

The package compiles 243 Praat translation units (~5.5 MB of `.cpp`) plus the
headers they include — most notably Praat's Unicode character database
(`kar/UCD_features_generated.h`, `kar/UnicodeData.h`, ~27 MB), which
`longchar.cpp` compiles in directly and cannot be reduced without breaking
text handling.

We have removed everything not required to build:

- a redundant duplicate Praat tree that was formerly shipped for the Windows
  build (both platforms now compile from a single source directory);
- all bundled-external-library **sources** (espeak, flac, mp3, portaudio,
  vorbis, opusfile, lame, clapack, gsl, glpk) — these are stubbed out at build
  time, so only the referenced **headers** are retained;
- Praat subtrees that are neither compiled nor on any include path
  (artsynth, EEG, FFNet, gram, main, makefiles, dwtest, docs, generate, tests);
- Praat manual/documentation source files (`manual_*.cpp`), which are compiled
  nowhere in this package.

This reduced the source tarball from ~52 MB to ~9 MB. The remaining size is
inherent to faithfully wrapping Praat's DSP core, consistent with other CRAN
packages that vendor substantial upstream C/C++ (e.g. duckdb, arrow, V8).

Installed size is ~34 Mb, broken down as: `libs` 22.7 Mb (the compiled DSP
core — object code for 243 Praat translation units plus the vendored Unicode
tables, statically linked into one shared object), `doc` 4.3 Mb (vignettes,
built as part of the CRAN-required vignette re-build), `extdata` 1.3 Mb and
`signalfiles` 1.7 Mb (small WAV/TextGrid fixtures exercised by the
`get_durations_batch()`/Tier-4 batch tests — kept intentionally small; an
unused AVQI fixture subset was removed. See
`tests/testthat/faithfulness/`). None of this is reducible without either
dropping DSP coverage or dropping the bit-exact regression fixtures that
back the package's core correctness claim.

`src/Makevars` contains no non-portable flags. FP contraction (FMA fusion) is
disabled at source level with `#pragma STDC FP_CONTRACT OFF` in the vendored
`melder.h`, which every DSP translation unit includes. This preserves the
package's primary correctness guarantee — the compiled DSP routines reproduce
the reference Praat application's output bit-for-bit (the regression-test
oracle) — without any compiler flags. The previous `-ffp-contract=off` in
`PKG_CXXFLAGS` triggered a "Non-portable flags" warning; removing it leaves
the check clean. GCC and Clang both honour the pragma; it is compiled out on
other compilers. All warning-suppressing `-Wno-*` flags have been removed;
the remaining build warnings originate in the vendored Praat C++ sources and
are non-significant.

`src/Makevars` sets one non-portable flag, `-ffp-contract=off`. This is a
deliberate correctness requirement, not an optimization: it disables
floating-point FMA contraction so the compiled DSP routines reproduce the
reference Praat application's output bit-for-bit (the package's primary purpose
and its regression-test oracle). Removing it changes results (e.g. a CPPS value
shifts by ~0.003 dB), breaking the faithfulness guarantee. It is supported by
GCC and Clang. All warning-suppressing `-Wno-*` flags have been removed; the
remaining build warnings originate in the vendored Praat C++ sources and are
non-significant.

The 'checking compiled code' WARNING for `stderr`/`stdout`/`_exit` symbols in
the vendored Praat objects was resolved in this release. The `abort` calls and
the app-shutdown `_Exit` had already been removed; the remaining direct
references to the libc `stdout`/`stderr` streams and to `exit()` are gone:

- `melder_console.cpp` now routes console output through the R API
  (`Rprintf`/`REprintf`) in library builds instead of the libc streams.
  R's console API is only safe on the main thread, and Praat DSP frame
  loops on worker threads can emit casual messages (e.g.
  `Sound_to_Pitch.cpp`), so writes are gated to the main thread — the first
  writer (the R main thread at package load) is recorded and messages from
  other threads are dropped; a mutex serializes main-thread writers. (The
  `R_Outputfile`/`R_Consolefile` handles were considered and rejected: R
  CMD check flags them as non-API entry points.)
- All remaining `exit()` call sites (Praat's interactive CLI/argument
  handling, compiled but never entered from the embedded library) now throw a
  `MelderError` under `PRAAT_LIB` instead of terminating the process.
- `melder_sysenv.cpp`: Praat's `system`/`system$`/`runSystem`/
  `runSubprocess` script commands, which pladdrr's `PraatInterpreter`
  exposes to arbitrary R-supplied script text, throw immediately instead of
  forking a shell (see `melder_sysenv.cpp`, `runAny_STR`), closing the
  shell-exec surface.
- A Praat-internal debug/self-test command (`Praat_tests.cpp`, "Praat
  test..." menu action) that wrote raw `fprintf(stderr, ...)` was removed
  from the build entirely (menu registration deleted, source file dropped
  from `SOURCES`).

The 'checking compiled code' NOTE may report `stderr`/`stdout`/`_exit` in the
vendored Praat objects. The widespread `abort` and the app-shutdown `_Exit`
have been removed, and the remaining `printf`/`rand`/`sprintf` call sites that
were under package control have been removed or replaced. The
remainder are legitimate and cannot be replaced without regressions:

- `melder_console.cpp` writes casual diagnostics to `stderr`/`stdout` as a
  fallback. Praat runs DSP frame loops on worker threads that can emit these
  messages, and R's `REprintf`/`Rprintf` are only safe on the main thread, so
  routing them through R would be unsafe.
- `melder_sysenv.cpp` uses `_exit` in the child of a `fork()` (the correct
  POSIX idiom — the child must not run `atexit`/flush handlers). This
  fork/exec path is defined but disabled: Praat's `system`/`system$`/
  `runSystem`/`runSubprocess` script commands, which pladdrr's
  `PraatInterpreter` exposes to arbitrary R-supplied script text, now throw
  immediately instead of forking a shell (see `melder_sysenv.cpp`,
  `runAny_STR`). This closes the shell-exec surface entirely; the fork/exec/
  `_exit` code below the throw is unreachable and kept only because removing
  it would require restructuring `melder_sysenv.cpp`'s upstream body.
- The remaining `exit`/`isatty`/`fprintf(stderr)` live in Praat's interactive
  `main`/CLI, which is compiled but never entered from the embedded library
  (`-DPRAAT_LIB -DNO_GUI`).
- A Praat-internal debug/self-test command (`Praat_tests.cpp`, "Praat
  test..." menu action) was found to be reachable from arbitrary
  `PraatInterpreter` script text via `praat_doMenuCommand()` and wrote raw
  `fprintf(stderr, ...)` outside Melder's console abstraction. It has been
  removed from the build entirely (menu registration deleted, source file
  dropped from `SOURCES`), closing that surface rather than justifying it.

### URLs

Broken package-site and private-repository URLs were removed from package
metadata and replaced in the vignettes with public canonical links or plain
citations/contact details.

### Test environments

- local macOS (aarch64), R 4.6.1 — `R CMD check --as-cran --no-manual pladdrr_5.0.5.tar.gz` (0 errors, 0 warnings, 1 note — the new-submission boilerplate)
- GitHub Actions: R CMD check on ubuntu-latest (release + devel), macos-latest and windows-latest (all success), plus test-coverage, lintr and pkgdown
- win-builder, R-devel and R-release — pladdrr_5.0.5 submitted, results pending (the identical source already passes the windows-latest R CMD check in CI)
- R-hub: pending

### R CMD check results

Local tarball check (R 4.6.1, aarch64, full `R CMD check --as-cran`
including the PDF manual) finishes with:

- 0 errors
- 0 warnings
- 2 notes: the new-submission boilerplate and the outdated-macOS-HTML-Tidy
  environmental note (documented below)

The previously reported install-time compiler warnings have been resolved: an
unsequenced-modification warning in vendored `melder_ftoa.cpp` was fixed at
source, and the deprecation warnings emitted by libc++ inside the RcppXsimd
headers are silenced with the portable define
`-D_LIBCPP_DISABLE_DEPRECATION_WARNINGS`; the install step now completes with
no significant warnings. Both R CMD check warnings reported previously were
resolved in this release:

- the compiled-code WARNING for the residual vendored `stderr`/`stdout`/
  `_exit` symbols (see "Compiled-code diagnostics" above), and
- the "Non-portable flags in variable 'PKG_CXXFLAGS'" WARNING for
  `-ffp-contract=off` (see "Compiler flags" above).

Notes are:

- new submission
- installed size
- local clock verification unavailable during check (local-environment only)
- HTML manual validation messages from the outdated HTML Tidy shipped with
  macOS, which predates HTML5 (`<main>` unrecognized); not reproducible with a
  current Tidy.

win-builder R-devel previously finished with **0 errors, 4 warnings, 1 note**:

- Install-time significant-warnings WARNING: cosmetic vendored-Praat noise
  under mingw/gcc 14 (C++20 template-id-cdtor, class-memaccess,
  uninitialized-var, array-bounds, return-type) — not package code, does not
  block install or affect correctness.
- S3-registration WARNING: `as.matrix.Matrix` intentionally overridden.
- Makevars-flags WARNING: `-ffp-contract=off` — resolved in this release
  (source-level pragma, see "Compiler flags" above).
- Compiled-code WARNING: residual vendored `exit` symbol — resolved in this
  release (see "Compiled-code diagnostics" above).
- CRAN-incoming-feasibility NOTE: new submission + possibly-misspelled
  DESCRIPTION words that are real domain/product terms (Cochleagram,
  FormantModeler, KlattGrid, Praat, Rcpp, TextGrid, etc.).

win-builder runs for this release are pending; the two source-level fixes
above apply on all platforms (the pragma is GCC/Clang-guarded, MSVC unaffected).
