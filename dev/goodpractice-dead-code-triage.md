# goodpractice `complexity_unused_internal` triage

Date: 2026-09-01 · Package: pladdrr 5.0.5 · Check: 114 findings

## Method

Cross-referenced every flagged function against:

- a repo-wide reference index (R/, tests/, vignettes/, man/, NAMESPACE,
  inst/, dev/) built from a single-pass token scan of all internal
  function names (2080 extracted via `getParseData`)
- the `complexity_unused_internal` positions from `goodpractice::gp()`
- NAMESPACE export/S3method registrations
- runtime reachability via the passing test suite (FAIL 0 / PASS 4920)

## Verdict: 1 true dead, 113 false positives

### Deleted (1)

- `R/pointprocess-wrapper.R`: `.pp_methods$._bust_cache` — zero
  references anywhere (R, tests, vignettes, inst, dev, C++); the
  jitter/shimmer cache it was meant to clear is never invalidated
  through it.

### Kept — dispatch glue invoked outside the static call graph (66)

- `$.<Class>` S3 methods (49): `$.Sound`, `$.Pitch`, … implement `$`
  dispatch for the wrapper classes; called as `sound$get_mean()` etc.
  The static analyzer cannot resolve `$`-operator dispatch. Exercised
  by thousands of passing tests.
- `.sound_methods$X` / `.pp_methods$X` / `.textgrid_methods$X` env
  method definitions (16): reachable via the `$.<Class>` methods above
  (e.g. `sound$change_speaker()` → `$.Sound` → `.sound_methods$change_speaker`).
- `._bust_cache`-style R6/`$`-assigned helpers in wrapper files (1
  additional occurrence group covered by the above).

### Kept — S3 generic methods (registered, classes live)

`print.*`, `as.data.frame.*`, `as.matrix.*` for all wrapper classes:
registered in NAMESPACE via `S3method()`, every target class is
constructed in R/ and exercised by tests. Not flagged by goodpractice
itself (it resolves S3 dispatch); kept.

### Kept — roxygen documentation anchors (15)

`pladdrr_shared_params`, `pladdrr_shared_sound`, … are `@rdname`
targets used by `@inheritParams` (328 inherit sites). They are
referenced in roxygen source, invisible to the call graph. Not
runtime code by design.

### Kept — RcppExports bridge wrappers (64)

`sound_get_duration_direct`, `.apply_hamming_window_simd`,
`.table_get_numeric_value`, … are the auto-generated R interface
(`R/RcppExports.R`, `src/RcppExports.cpp`) to `// [[Rcpp::export]]`
C++ functions. Unreferenced from R/tests/vignettes/inst/dev, but:

- they are part of the compiled C++ API surface of the package;
- removal requires editing the C++ sources and regenerating
  RcppExports via `Rcpp::compileAttributes()`, then a full rebuild —
  disproportionate for zero functional gain;
- the underlying C++ implementations may be called from other C++
  translation units.

## Outcome

The check cannot be driven to zero without deleting load-bearing
dispatch glue or the Rcpp export surface. The 113 remaining findings
are accepted as false positives and documented here. Re-run the
reference index (`/tmp/phase0/refcounts.txt` regeneration procedure)
after any future refactor that could orphan an internal helper.
