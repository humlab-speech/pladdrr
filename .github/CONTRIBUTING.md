# Contributing to pladdrr

Thanks for taking the time to contribute. This document covers what you need to
know to get a working build, because pladdrr is not a pure-R package: it
compiles a curated subset of the [Praat](https://praat.org) C++ sources and
exposes them through Rcpp modules.

Everyone participating is expected to follow the
[Code of Conduct](CODE_OF_CONDUCT.md).

## Ways to contribute

* **Bug reports** — open an issue at
  <https://github.com/humlab-speech/pladdrr/issues>. Please include a
  [reprex](https://reprex.tidyverse.org/), the output of
  `sessionInfo()`, and — if the bug is a numeric discrepancy — the equivalent
  Praat script and the value Praat produces. Faithfulness to Praat is the
  package's core contract, so a Praat reference value turns a vague report into
  a fixable one.
* **Feature requests** — open an issue describing the Praat functionality you
  need. Praat object types that are not yet wrapped generally require new C++
  wrapper code; say which Praat menu commands or functions you are after.
* **Pull requests** — see below.

Please open an issue before starting a large pull request, so we can agree on
the approach before you invest the effort.

## Setting up a development environment

### 1. Clone

Both `src/praat.github.io/` (the vendored Praat sources) and `src/pocketfft/`
(the FFT backend) are ordinary tracked directories, not git submodules. A
plain clone or `remotes::install_github()` pulls in everything needed to
build.

```bash
git clone https://github.com/humlab-speech/pladdrr.git
```

### 2. System requirements

* A C++17 compiler (GCC >= 7, Clang >= 5, MSVC >= 2017)
* The GNU Scientific Library (GSL >= 1.10)

```bash
# macOS
brew install gsl
# Debian/Ubuntu
sudo apt-get install libgsl-dev
# Windows (Rtools 4.x, UCRT toolchain)
pacman -S mingw-w64-ucrt-x86_64-gsl
```

### 3. Build and install

```bash
R CMD INSTALL .
# faster while iterating:
R CMD INSTALL --no-docs .
```

The first build compiles ~243 Praat translation units and takes a while.
Subsequent builds only recompile what changed.

## Things that will bite you

* **`src/Makevars` is generated.** The `configure` script regenerates it from
  `src/Makevars.in` on every install. Always edit **both** files, or your change
  will silently disappear on the next install. Windows uses a separate,
  hand-maintained `src/Makevars.win`; keep it in sync too.
* **`-ffp-contract=off` is deliberate.** It disables floating-point FMA
  contraction so compiled DSP routines reproduce Praat's output bit-for-bit.
  Do not remove it as an "optimisation".
* **Do not define `__APPLE__`-style macros globally.** Praat uses the
  `macintosh` macro; defining it globally pulls in Objective-C headers.
* **Benchmarks must be run against a release build.** `devtools::load_all()`
  compiles at `-O0`, which makes every timing 2–7x slower than reality.

## Making changes

1. Create a branch off `main`.
2. Write or update tests in `tests/testthat/`. Anything touching a numeric
   result also needs a faithfulness assertion — see
   `tests/testthat/test-praat-faithfulness.R` and
   `tests/testthat/faithfulness/`.
3. Document exported functions with roxygen2 comments, then regenerate:
   ```r
   devtools::document()
   ```
   Never hand-edit `NAMESPACE` or files in `man/`.
4. Add a bullet to `NEWS.md` under a new or existing top heading, describing the
   change from the user's point of view.
5. Run the checks:
   ```r
   devtools::test()
   ```
   ```bash
   R CMD build . && R CMD check --as-cran pladdrr_*.tar.gz
   ```
   Note that `R CMD check` must be run on the **built tarball**, not on the
   source directory — checking the directory reports a spurious
   "Required fields missing: Author, Maintainer", because those fields are
   generated from `Authors@R` at build time.
6. Open the pull request against `main`. CI runs `R CMD check` on Linux, macOS,
   and Windows, plus test coverage.

## Code style

* Follow the [tidyverse style guide](https://style.tidyverse.org/): snake_case
  for functions and arguments, `<-` for assignment, two-space indentation.
  Praat *object classes* keep their upstream CamelCase names (`Sound`,
  `TextGrid`, `KlattGrid`) so that Praat scripts translate readably.
* Keep user-facing output in `message()` / `warning()` so it can be suppressed.
  `cat()` belongs in `print.*` and `format.*` methods only.
* Do not modify global state from package code — no `options()`, no
  `Sys.setenv()`, no writing outside `tempdir()`.

## Third-party code

Changes under `src/praat.github.io/` and `src/pocketfft/` are
vendored upstream sources. Patches there must be recorded in
`inst/PRAAT_MODIFICATIONS.md` so the delta against upstream stays auditable, and
any new bundled component must be added to `inst/COPYRIGHTS` **and** to the
`cph` entries in `Authors@R`.

## Release checklist

* Bump `Version` and `Date` in `DESCRIPTION`, and the version in `inst/CITATION`
  and `CITATION.cff`.
* Regenerate `codemeta.json` (`codemetar::write_codemeta()`).
* Move the released section of `NEWS.md` and archive older entries in
  `NEWS-archive.md`.
* Update `cran-comments.md` with the current check results.
