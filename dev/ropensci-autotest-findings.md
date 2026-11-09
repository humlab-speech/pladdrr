# autotest findings (2026-11-09)

Reproduce: `R CMD INSTALL --preclean .` then `Rscript dev/run-autotest.R 20 600`, then
`Rscript dev/triage-autotest.R`. `test = TRUE` is essential (the default is a dry run that only
lists the tests it would run). Results land in `dev/autotest/` (`summary.csv`, `findings.csv`,
per-batch `.rds`/`.log`).

**Use a clean release build.** On the `-O0 -UNDEBUG` objects left behind by
`roxygen2::roxygenise()`/`load_all()`, any wrongly typed scalar passed to an Rcpp entry point kills R
(exit 134); 29 functions "aborted" for that reason alone. On a `--preclean` build the same call is a
normal R error. See the project memory `pladdrr-debug-build-cost`.

## Coverage of the tool itself

256 exported functions, batches of 20, failed batches re-run one function at a time.

| Outcome | Functions |
|---------|-----------|
| mutation tests ran | 124 |
| autotest itself errored | 130 |
| R crashed (segfault) | 2, **fixed** (below) |

autotest's own errors, not pladdrr's: a regex built from the `C++Error` class name
(`grepl("C++Error", ...)`, 81 functions: the call returned an Rcpp error condition and autotest
then tried to match its class against the Rd `@return`), `seq_len(nrow(fn_pars))` on functions with
no parameters (29), `names<-` on a zero-parameter function (12), and a few others. These functions
are therefore *not* mutation-tested by autotest; the hand-written edge-condition matrix
(`tests/testthat/test-edge-conditions.R`) covers the core analyses instead.

## Real defect found and fixed

`amplitude_tier_from_point_process()` and `intensity_tier_to_amplitude_tier()` segfaulted (address
0x18) when handed an object whose external pointer was NULL, which is what `readRDS()`,
`saveRDS()` round-trips, parallel-worker results and restored sessions produce. They dereferenced
`R_ExternalPtrAddr()` without a check. Fixed by routing through the validated `get_ptr()` helper;
the same unchecked pattern was removed from `sound_extract_electroglottogram_cpp` and the
BandFilterSpectrogram accessors. Regression test: `tests/testthat/test-dead-pointers.R`.
`sound_pool_release` and the TextGrid predicate pointer were left as they are on purpose
(the first must tolerate dead pointers; the second is not user-supplied data).

## What the 124 functions that ran reported (671 rows, 238 warnings / 159 errors)

| Test | Rows | Reading |
|------|------|---------|
| `par_is_demonstrated` | 230 | Parameter never used in an example. Documentation work; not a defect. |
| `return_desc_includes_class` | 80 | `@return` does not name the returned class. Maps to TS4.2 / G2.1a. |
| `single_char_case` | 71 | Character parameter: is it case-sensitive? Maps to G2.3b; decide per parameter. |
| `return_successful` | 53 | Function errored on autotest's generated arguments. 54 of the errors are `Invalid Sound pointer (NULL)` and 24 are `Not a Sound (found Sound)`; the latter looks like autotest loading a second copy of the package, so the C++ type check sees a "different" Sound class (not verified). |
| `negate_logical`, `int_range`, `subst_int_for_logical`, `random_char_string`, `single_par_as_length_2` | 96 | Diagnostics: the function accepted a mutated argument. Candidates for stricter validation (G2.0-G2.2); not triaged one by one. |
| `par_is_documented`, `par_matches_docs` | 3 | Parameter/Rd mismatch. Cheap to fix. |

## Still to do

* Per-function triage of the 96 mutation diagnostics and 3 doc mismatches.
* Examples that exercise each parameter (230 rows).
* `@return` class statements (80 rows).
* Report the `C++Error` regex failure upstream (ropensci-review-tools/autotest).
