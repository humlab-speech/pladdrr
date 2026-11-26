## Submission notes

This is a new submission (version 5.2.0).

pladdrr is an object-oriented R interface to Praat's phonetic-analysis DSP
routines. It vendors a curated subset of Praat's C++ source (`src/praat.github.io`)
and compiles it via Rcpp, so results match the Praat application without an
external Praat installation. Bundled third-party code (Praat, pocketfft,
libFLAC/Ogg/Vorbis/Opusfile) and its copyright holders are listed in
`inst/COPYRIGHTS` and as `cph` in `Authors@R`. Praat is GPL (>= 3), as is the
package.

### Package size

The source tarball is 4.7 MB. Installed size is ~27 MB, mostly `libs` (22 MB,
object code of the vendored Praat sources, which includes Praat's Unicode tables
compiled into `longchar.cpp`). Only the Praat sources that are compiled or
included were kept; unused upstream subtrees, GUI/manual sources and duplicate
trees were removed.

### Build and compiled code

- `src/Makevars` contains no non-portable flags. Floating-point contraction is
  disabled in the vendored `melder.h` with `#pragma STDC FP_CONTRACT OFF`, which
  keeps results bit-identical to Praat.
- The package is built with `-DPRAAT_LIB -DNO_GUI`. In this configuration
  Praat's console output goes through `Rprintf`/`REprintf` (main thread only),
  `exit()` call sites throw an error instead, and Praat's `system`/`runSystem`
  script commands are disabled (`melder_sysenv.cpp`), so no shell is started.
  `R CMD check` reports no problem under "checking compiled code".
- Computation is multi-threaded (C++ threads). The default thread count follows
  the process CPU affinity/cgroup quota; see `?pladdrr_threads` for how to limit
  it.

### Test environments

- local macOS 27.2 (aarch64), R 4.6.1: `R CMD check --as-cran` on
  `pladdrr_5.2.0.tar.gz`, including `--run-donttest`
- win-builder (R-release, R-devel): TODO paste results for the final tarball
- GitHub Actions R CMD check: TODO confirm ubuntu (release, devel), macOS, Windows
  green for the submitted commit

### R CMD check results

0 errors | 0 warnings | 2 notes

- CRAN incoming feasibility: "New submission". The `LICENSE` file only states the
  copyright holder and year (`GPL-3 + file LICENSE`).
- HTML manual validation was skipped because the HTML Tidy shipped with macOS is
  too old (local environment only).
