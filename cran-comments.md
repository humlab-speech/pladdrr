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

### Test environments

- local macOS (aarch64), R 4.4 — `R CMD check`
- (to be completed: win-builder devel/release, R-hub)

### R CMD check results

0 errors | 0 warnings | (notes: installed size, justified above).
