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
- The vendored libFLAC statement-expression macros (`flac_min()`, `flac_max()`)
  carry `__extension__`, so R's default Windows CFLAGS (`-pedantic`) no longer
  report "ISO C forbids braced-groups within expressions" from
  `flac_private_macros.h`.

### Changes since the 2026-11-26 win-builder and pretest runs

- `License: GPL-3` replaces `GPL-3 + file LICENSE`, and the `LICENSE` stub is
  gone. GPL-3 needs no stub, and the stub made the incoming check echo the whole
  file under "License components with restrictions and base license permitting
  such". `COPYING` carries the full GPL-3 text, `inst/COPYRIGHTS` the
  third-party attributions.
- `DESCRIPTION` wording no longer triggers "Possibly misspelled words in
  DESCRIPTION" (that aspell pass ignores `inst/WORDLIST`): "formant tracking",
  "cepstral coefficients" and the bare `R-Praat` were reworded.
- `README.md` links the license badge to `COPYING` in the repository; the
  `www.gnu.org` URL timed out in win-builder's URL check.
- Documentation: the ten exports listed by R-devel's "Exported functions without
  usage information" diagnostic (`Cepstrum`, `IntensityTier`, `Spectrogram`,
  `PowerCepstrum`, `PraatMatrix`, `get_sound_values_zerocopy`,
  `sound_as_matrix_zerocopy`, `is_zerocopy_vector`, `KlattGrid_createExample`,
  `KlattGrid_createFromVowel`) now have `\usage` entries and, for the five
  constructors, `\arguments` entries. `tools::codoc()` reports no mismatches.

### Test environments

- local macOS 27.2 (aarch64), R 4.6.1: `R CMD check --as-cran` on
  `pladdrr_5.2.0.tar.gz`, including `--run-donttest`
- win-builder, R-release and R-devel (r90926), 2026-11-26
- CRAN incoming pretest, Debian (R-devel r90991) and Windows (r90926), 2026-11-26

### R CMD check results

On the tarball of this submission, `R CMD check --as-cran` (local R 4.6.1)
reports 0 errors, 0 warnings and 2 notes:

- CRAN incoming feasibility: "New submission".
- HTML manual validation skipped because the local HTML Tidy is too old (local
  environment only).

The 2026-11-26 win-builder and pretest runs predate the fixes above. Their
findings, all now addressed:

- WARNING, install (Windows): "ISO C forbids braced-groups within expressions
  [-Wpedantic]" from `src/praat.github.io/external/flac/flac_private_macros.h`.
  R's Windows CFLAGS include `-pedantic`; the Debian run compiles with clang,
  which does not take that header branch, hence no warning there.
- NOTE, incoming feasibility: license-component pointer for
  `GPL-3 + file LICENSE` with the whole file echoed, "Possibly misspelled words
  in DESCRIPTION" (Praat/cepstral/formant), and a `www.gnu.org` URL timeout.
- INFO, Debian pretest (R-devel r90991): "Exported functions without usage
  information" for the ten names listed above.
