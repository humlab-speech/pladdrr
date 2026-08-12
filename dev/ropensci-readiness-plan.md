# rOpenSci readiness — remaining work

Plan for bringing pladdrr in line with the
[rOpenSci packaging guide](https://devguide.ropensci.org/pkg_building.html).

**Status as of 2026-08-12.** Phases 1–3 are committed (`61eb370a`, `93b224fe`,
`0e72605a`) and unpushed. Phases 4 (verification, 4.1–4.4, 4.7), 6, and 7 are
complete — see results below, uncommitted pending review. 4.5 (push) and 4.6
(coverage) remain blocked on maintainer action / CI. Phase 5 decisions are
confirmed (see below). What's left: 4.5/4.6/4.7-via-CI, and Phase 8
submission once the pre-submission enquiry (drafted, not yet posted) gets an
answer.

## Ordering rationale

Nothing has been verified end to end. Three commits changed build metadata,
check gating, examples and vignettes, but **no `R CMD check` has run since**.
Vignettes that previously executed nothing now execute, which materially
changes build time and is the single biggest unknown. Verification comes
first; everything else is polish that could be invalidated by what
verification finds.

---

## Phase 4 — Verification and gates (do first)

| # | Step | Command / gate | Notes |
|---|------|----------------|-------|
| 4.1 | Clean rebuild | `R CMD INSTALL --preclean .` | The current library `.so` is a debug build (the package says so at load). Every timing before this is meaningless. ~20–40 min. |
| 4.2 | Build tarball, **measure vignette time** | `time R CMD build .` | **New risk:** 16 vignettes now actually run. CRAN enforces overall check-time limits. If this is slow, the fix is selectively re-disabling the heaviest chunks — decided by data, not guesswork. |
| 4.3 | Full check | `R CMD check --as-cran pladdrr_5.0.0.tar.gz` | Expect the 4 documented WARNINGs. Anything else is a regression from Phases 1–3. |
| 4.4 | Confirm tarball contents | `tar tzf` → assert no `src/pffft/`, no `dev/`, no `codemeta.json` / `CITATION.cff`, no loose `tests/*.R` | Verifies the Phase-2 `.Rbuildignore` work against a real build rather than regex simulation. |
| 4.5 | Push, observe CI | GitHub Actions | Verifies the **Windows job** (Rtools/pacman GSL path — expect ≥1 iteration) and the **warning-gate step**, neither of which can be tested locally. |
| 4.6 | Coverage number | Codecov after 4.5, or local `covr::package_coverage()` | The rOpenSci ≥75% target is still unmeasured. A local run needs a gcov-instrumented rebuild of 243 translation units — prefer reading it off CI. |
| 4.7 | `pkgcheck` + `goodpractice` | `pkgcheck::pkgcheck()`, `goodpractice::gp()` | The actual rOpenSci entry criteria. Requires installing both. Replaces the hand-audit with the authoritative list. |

**Gate:** 4.7 clean, or a written justification for each remaining item.

### Results (2026-08-12)

| # | Result |
|---|---|
| 4.1 | Clean `--preclean` install: 8:34. Confirmed `-O2 -DNDEBUG` (not debug), loads, v5.0.0. |
| 4.2 | `R CMD build .`: 4:16 total, no warnings/errors. 16 vignettes executing did **not** blow up build time — no chunk re-disabling needed. Tarball 11.3M. |
| 4.3 | `R CMD check --as-cran`: 13:45. **2 WARNINGs, 6 NOTEs** on first run — matches `cran-comments.md`'s own documented local baseline exactly (the plan text's "4 WARNINGs" was the win-builder count, not local macOS; no regression). One NOTE was new and real: `dplyr`/`purrr`/`tidyr` used in 3 vignettes but undeclared — caused by Phase 3 turning vignette execution on. Fixed by adding them to `Suggests` (uncommitted). Re-ran clean: **2 WARNINGs, 5 NOTEs**. Remaining 5 NOTEs are new-submission/size/HTML-tidy/clock-check, all already justified in `cran-comments.md`, plus a local-only `.DS_Store` from the check directory (confirmed absent from the tarball itself). |
| 4.4 | Tarball contents verified clean: no `pffft/`, no `dev/`, no `codemeta.json`/`CITATION.cff`, no stray files, no `.DS_Store`. Only `tests/testthat.R` (the standard boilerplate runner) + `tests/testthat/` — no loose test files directly under `tests/`. |
| 4.5 | **Not run.** Requires pushing 4 local commits + this fix to `origin/main` — maintainer call. |
| 4.6 | **Not measured.** `goodpractice`'s local `covr` prep step failed ("Package installation did not succeed") after ~7 min — consistent with the plan's prediction that a gcov-instrumented rebuild of 243 translation units is unreliable locally. Prefer reading coverage off Codecov after 4.5. |
| 4.7 | `pkgcheck::pkgcheck()` **cannot run in this environment**: `pkgstats` 0.2.4.1 calls base-R `grepv()`, added in R 4.5.0; local R is 4.4.2. Environment gap, not a package defect — needs a newer local R or CI. `goodpractice::gp()` ran successfully (51:36 total). 0 errors from its embedded `rcmdcheck`/`rd`/`roxygen2`/`revdep`/`urlchecker` checks. It flagged 60 checks, split three ways: (a) duplicate of the already-justified `cran-comments.md` items (non-portable Makevars, installed size); (b) a large volume of `lintr`/`tidyverse`-style violations across 314 R files — expected for a codebase not authored against tidyverse style from day one, not a correctness issue; (c) genuinely new counts worth triaging in Phase 6 — see below. |

**New Phase 6 candidates from goodpractice** (not in the original audit):

| Check | Count | What it means |
|---|---|---|
| `complexity_unused_internal` | 384 | See triage below — 44 are false positives, ~52 have indirect real usage, **272 are confirmed zero-reference candidates for real dead code**. |
| `roxygen2_has_export_or_nord` | 87 | Functions with neither `@export` nor `@noRd` — ambiguous doc-visibility intent. |
| `roxygen2_duplicate_params` | 298 (across ~73 functions) | Same `@param` name documented with different text in different functions. Expected at this scale (`sound`, `time_step` etc. recur constantly) — likely low-value to chase individually. |
| `complexity_function_length` | 35 | Functions goodpractice's default length threshold flags as long. |
| `print_return_invisible` | 40 | `print.*`/`format.*` methods not returning their argument invisibly (R convention). |
| `duplicate_function_bodies` | 20 | Structurally identical function bodies — refactor candidates. |
| `no_description_date` | — | DESCRIPTION has a `Date:` field; goodpractice's default policy discourages it (manually-maintained dates go stale). Stylistic, not a CRAN blocker. |

### `complexity_unused_internal` triage (2026-08-12)

Cross-referenced all 384 flagged names against `rg --fixed-strings` over
`R/`, `tests/`, `vignettes/`, `man/`, `inst/` (goodpractice's own static
scan only covers `R/`, and its `\b` word-boundary logic silently fails on
dot-prefixed names, so its raw list needed independent verification):

- **44 are S3 `` $.ClassName `` dispatch methods** (e.g. `` `$.Sound` ``).
  Always a false positive — invoked implicitly by the `$` operator, never
  by literal name. Not actionable.
- **324 of the remaining 340 live in `R/RcppExports.R`** — auto-generated
  `.Call()` wrappers for `// [[Rcpp::export]]` C++ functions, none of which
  appear in `NAMESPACE` (0 dot-prefixed exports), i.e. these are
  internal-only, not part of the public API.
  - 52 of those 324 do have real call sites once the search widens beyond
    `R/` to `tests/`/`vignettes/`/`man/`/`inst/` — false positives from a
    narrower scan.
  - **272 have zero references anywhere in the package tree.** Sample
    inspection shows a plausible root cause: e.g.
    `amplitude_tier_get_shimmer_local_cpp`,
    `amplitude_tier_get_shimmer_apq3_cpp`, etc. — individual per-metric
    exports that look superseded by the batched `get_jitter_shimmer_batch()`
    (see project memory) — i.e. genuine leftover dead code from a past
    refactor, not a scan artifact.
- **16 are hand-written R functions** (`R/datatable-utils.R`,
  `R/validation-utils.R`, etc.) — all had real call sites once checked with
  a correct (non-`\b`-broken) search; none are actually dead.

**Recommendation:** the 272 are a real, mechanically-verified dead-code
candidate list, but removing them means deleting the `// [[Rcpp::export]]`
tag (or the whole function) at the **C++ level** and regenerating
`RcppExports.R`/`RcppExports.cpp` via `Rcpp::compileAttributes()`, then a
full rebuild + `R CMD check` cycle to confirm nothing regresses — compiled-
code surgery, not a quick R-level cleanup. Worth doing for Phase 7 size
reduction, but scope and sequence it as its own pass rather than folding
into the rest of Phase 6's R-level fixes.

---

## Phase 5 — Decisions that are not the implementer's to make — confirmed (2026-08-12)

| Decision | Options | Confirmed |
|---|---|---|
| **roxygen2 pin** | Accept 8.1.0 (currently committed), or regenerate with 7.3.3 and revert the NAMESPACE / 4-Rd churn | **Accept 8.1.0.** |
| **rOpenSci scope** | File a pre-submission enquiry before further work | **Yes, file it.** Draft written to `dev/ropensci-presubmission-enquiry.md`; not yet posted to `ropensci/software-review` (external, public — needs explicit go-ahead to actually submit). |
| **Development status** | README currently claims repostatus "Active" | **Keep "Active".** |

---

## Phase 6 — Code quality — done (2026-08-12)

- **21 unsafe sequence patterns fixed** (plan estimated 17; a full `rg` sweep
  found 21 actual call sites, incl. `R/pca-wrapper.R:94`,
  `R/discriminant-wrapper.R:107`, `R/batch-processing.R:304,347`,
  `R/plotting-combined.R` ×9, `R/formant.R` ×3, and others). All converted to
  `seq_len()`/`seq_along()`. All edited files parse clean; full rebuild +
  `R CMD check` shows no regression.
- **2 camelCase exports renamed.** `KlattGrid_createExample` →
  `klattgrid_create_example`, `KlattGrid_createFromVowel` →
  `klattgrid_create_from_vowel`. Old names kept as `.Deprecated()`-wrapped
  aliases (matching the existing `get_sound_values_zerocopy`-style pattern in
  `R/fast-access.R`), both still exported, one shared Rd topic via `@rdname`.
  All ~50 call sites across 5 vignettes updated to the new name. Regenerating
  docs via `roxygen2::roxygenise()` incidentally caught `RcppExports.cpp`
  being stale against 5 already-changed TextGrid function signatures
  (`std::string`/`std::vector<std::string>` → `Rcpp::String`/
  `Rcpp::CharacterVector`, from the `1136e30a` encoding fix that never got a
  `compileAttributes()` re-run) — resynced as a side effect, verified benign.
- **`skip_on_cran()` audited: 91 → 21 calls.** Classified every call site by
  reading its test body: kept only genuine timing/benchmark assertions (7),
  large-fixture-file tests (5, `test-textgrid-benchmark.R`), and
  `RcppXPtrUtils`-based tests that compile C++ at test time (3), plus 2 more
  CPPS-intensive SIMD tests and a `data.table` speedup helper. Removed the
  remaining 70 from 11 files where `skip_on_cran()` was applied to ordinary
  fast correctness tests with no CRAN-unfriendly property (batch-API
  matching, NaN guards, deprecation-warning checks, MFCC SIMD-vs-scalar,
  etc.) — verified by running the full suite with `NOT_CRAN=true`: 0
  failures. (One test flaked under forced `NOT_CRAN=true` on a kept
  timing-ratio assertion — expected noise from a test that's supposed to be
  CRAN-skipped, not a regression.)
- **Own-test deprecation-warning noise: 66 → 0.** Root cause wasn't scattered
  test-file misuse — `generate_sine_wave()`/`generate_noise()` in
  `R/sound-generate.R` themselves called the deprecated `create_sound()`
  internally. Fixed at the source (2 call sites); every test that used these
  generators (7 files, `test-cochleagram-r6.R`, `test-excitation-r6.R`, etc.)
  stopped warning with zero test-file edits needed. `test-sound.R` and
  `test-s3-methods.R`, which deliberately exercise the deprecated legacy S3
  API, were correctly left untouched (the latter is already file-level
  `skip()`'d).

---

## Phase 7 — Slimming and polish — done (2026-08-12)

- **`inst/agents` kept as-is.** Has real, active dependents
  (`tools/check_doc_version.sh`, `tools/perf_inventory.sh`,
  `tools/check_callentries.sh`, plus doc cross-references in 3 R files) —
  moving it risks breaking maintainer tooling for only 468K against a 34Mb
  total dominated by `libs` (22.7Mb). Not worth the risk/reward.
- **`inst/signalfiles/AVQI/` removed** (1.5Mb, 10 WAV files). Verified zero
  references anywhere in `R/`, `tests/`, `vignettes/`, or `man/`; the
  similarly-named `dev/cross-validation/*.R` scripts that mention "AVQI"
  read from an external `PLABENCH_DIR`, not this package's `inst/`. The
  `DSI/` sibling (12 files, 1.7Mb) is fully exercised — confirmed via
  `list.files()` enumeration in `test-tier4-ultra.R`'s benchmark test — and
  was kept. Also deleted an untracked, stray `inst/signalfiles/.DS_Store`.
  `cran-comments.md`'s size breakdown updated to match (34.0Mb → 32.5Mb
  installed; tarball 11.85Mb → 10.49Mb).
- **`.Rbuildignore` consolidated: 173 lines → 98.** (Plan estimated ~140→~25;
  98 was the actual floor once every pattern was checked against files that
  still exist — the `src/praat.github.io/` and bundled-library exclusions
  are all load-bearing and don't compress further without risk.) Removed 38
  dead `SESSION_*.md`/`BUILD_*.md`/etc. patterns matching zero current
  files, deduplicated 4 exact-duplicate lines, and collapsed 16 lines of
  `src/*.o`/`.so`/`.backup`/etc. junk patterns into one alternation regex.
  One consolidation attempt broke `roxygen2::roxygenise()` (a comment
  split across two lines left an unbalanced `(` that roxygen2's own
  `.Rbuildignore` parser — unlike `R CMD build`'s — tries to regex-compile
  even for `#`-prefixed lines); fixed by keeping parentheticals on one line.
  Verified via full tarball diff: nothing new leaked in, nothing needed
  stayed excluded.
- **`get_module()`'s `pladdrr:::` example removed** rather than kept — it's
  `@keywords internal`, not exported, and the `:::`-qualified example added
  no value an internal helper's signature doesn't already convey.

**Full verification after Phase 6+7:** clean rebuild → `R CMD build` (4:20)
→ `R CMD check --as-cran` (13:44): **2 WARNINGs, 5 NOTEs, 0 ERRORs** — same
as the Phase 4 baseline. (One run produced a spurious example ERROR in
`to_pitch_spinet_direct`, traced to `Sound$create_tone()` producing an
all-zero sample; did not reproduce in isolation or on a same-day re-run with
no code changes — a pre-existing, order/memory-dependent flake in the
vendored SPINET path, unrelated to anything touched this session. Worth a
maintainer look but out of scope here.)

**Explicitly dropped: moving `ggplot2` to Suggests.** This appeared in the
original audit; the facts do not support it. There are 269 `ggplot2::` call
sites across 4 files, and `autoplot`/`autolayer` are a documented feature.
`grid` is used exactly once, but `grid` ships with R, so moving it buys nothing.

---

## Phase 8 — Submission

Pre-submission enquiry outcome → `pkgcheck` clean → open the rOpenSci
submission issue → add the review badge to the README.

---

## Effort

| Phase | Wall time | Attention required |
|---|---|---|
| 4 | 2–4 h (mostly compiles) | Low, except triage of 4.3 and 4.7 |
| 5 | minutes | Maintainer decision |
| 6 | 3–4 h | Medium |
| 7 | 1–2 h | Low |

**Critical path:** 4.1 → 4.2 → 4.3. A slow vignette build or an unexpected
check failure reshapes the scope of Phases 6 and 7.

---

## Appendix — what Phases 1–3 already covered

Committed and verified except where noted.

**`61eb370a` — community and metadata files.** `.github/CODE_OF_CONDUCT.md`,
`.github/CONTRIBUTING.md`, `CITATION.cff`, `codemeta.json`, README badges
(repostatus / R-CMD-check / Codecov / license) and a Citation section,
`windows-latest` added to CI, dead `r.yml` workflow removed.

**`93b224fe` — policy fixes.** Cross-validation scripts moved out of `tests/`
(where `R CMD check` was executing them despite their needing an external Praat
binary); a CI step that fails on any WARNING outside the four justified ones;
removal of global `options()` mutation; a dead duplicate `.onLoad`;
`cph` entries in `Authors@R` plus `LICENSE.note` → `inst/COPYRIGHTS`;
`src/pffft/` excluded (unused, uncompiled, unattributed); `Title` no longer
ends in "in R".

**`0e72605a` — executable documentation.** All 7 `\dontrun` blocks converted to
runnable examples against the shipped `test.wav`; seven vignettes that set
`eval = FALSE` globally now execute; disabled chunks reduced from roughly half
of all chunks to 21 of 314, each with a stated reason; testthat edition 3;
`cat()` audit (311 of 312 legitimately inside print methods).

Defects that running the documentation exposed, now fixed: two KlattGrid
chunks that deliberately illustrate an error needed `error=TRUE`;
`vowel-space-analysis` faceted by a `speaker` column it never created; and six
chunks wrote files into the reader's working directory.

**Known-unverified from Phases 1–3:** no `R CMD check` run; the Windows CI job
and the CI warning gate are untested outside a synthetic log; coverage
unmeasured.
