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

### Compiler flags

`src/Makevars` sets one non-portable flag, `-ffp-contract=off`. This is a
deliberate correctness requirement, not an optimization: it disables
floating-point FMA contraction so the compiled DSP routines reproduce the
reference Praat application's output bit-for-bit (the package's primary purpose
and its regression-test oracle). Removing it changes results (e.g. a CPPS value
shifts by ~0.003 dB), breaking the faithfulness guarantee. It is supported by
GCC and Clang. All warning-suppressing `-Wno-*` flags have been removed; the
remaining build warnings originate in the vendored Praat C++ sources and are
non-significant.

### Compiled-code diagnostics

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
  POSIX idiom — the child must not run `atexit`/flush handlers).
- The remaining `exit`/`isatty`/`fprintf(stderr)` live in Praat's interactive
  `main`/CLI and self-test code, which is compiled but never entered from the
  embedded library (`-DPRAAT_LIB -DNO_GUI`).

### URLs

Broken package-site and private-repository URLs were removed from package
metadata and replaced in the vignettes with public canonical links or plain
citations/contact details.

### Test environments

- local macOS (aarch64), R 4.4 — `R CMD check --as-cran pladdrr_4.9.6.tar.gz`
- win-builder, R-devel (x86_64-w64-mingw32, Windows Server 2022) — clean
- win-builder, R-release — pending
- (to be completed: R-hub)

### R CMD check results

Local tarball check currently finishes with:

- 0 errors
- 2 warnings
- notes as listed below

The previously reported install-time compiler warnings have been resolved: an
unsequenced-modification warning in vendored `melder_ftoa.cpp` was fixed at
source, and the deprecation warnings emitted by libc++ inside the RcppXsimd
headers are silenced with the portable define
`-D_LIBCPP_DISABLE_DEPRECATION_WARNINGS`; the install step now completes with
no significant warnings.

Warnings are:

- `PKG_CXXFLAGS` contains `-ffp-contract=off` for bit-for-bit Praat
  faithfulness (justified above).
- The compiled-code check reports the residual vendored Praat
  `stderr`/`stdout`/`_exit` symbols described above.

Notes are:

- new submission
- installed size
- local clock verification unavailable during check (local-environment only)
- HTML manual validation messages from the outdated HTML Tidy shipped with
  macOS, which predates HTML5 (`<main>` unrecognized); not reproducible with a
  current Tidy.

win-builder R-devel finishes with **0 errors, 4 warnings, 1 note**:

- Install-time significant-warnings WARNING: cosmetic vendored-Praat noise
  under mingw/gcc 14 (C++20 template-id-cdtor, class-memaccess,
  uninitialized-var, array-bounds, return-type) — not package code, does not
  block install or affect correctness.
- S3-registration WARNING: `as.matrix.Matrix` intentionally overridden.
- Makevars-flags WARNING: `-ffp-contract=off`, justified above.
- Compiled-code WARNING: residual vendored `exit` symbol, justified above.
- CRAN-incoming-feasibility NOTE: new submission + possibly-misspelled
  DESCRIPTION words that are real domain/product terms (Cochleagram,
  FormantModeler, KlattGrid, Praat, Rcpp, TextGrid, etc.).
