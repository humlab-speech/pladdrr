# rOpenSci Statistical Software Review — gap analysis (silver / gold)

Assessed 2026-11-09 against the standards source
(`ropensci/statistical-software-review-book`, `standards/*.Rmd`, `pkgdev.Rmd`,
`overview.Rmd`, fetched raw from `main` on the same day). Package state:
`main` @ 05442e6c, DESCRIPTION 5.1.0.

Evidence is from grep/inspection of the tree plus the **stale** `pkgcheck.log`
(it describes 5.0.5, not 5.1.0). Counts marked "heuristic" are grep-based and
need verification before being quoted to reviewers.

---

## 0. Blocking finding: scope

1. **"Wrapper Packages" are explicitly "Not yet in scope"** of the statistical
   standards (`overview.Rmd`, §Wrapper Packages: *"beyond the scope of current
   standards … contact us directly"*). pladdrr is by construction a wrapper
   around Praat. Scope is defined by the eight categories (Bayesian, Regression,
   Unsupervised, EDA, Time Series, ML, Spatial, Distributions); software that
   fits none is out of scope.
2. **Badges exist only inside this system.** Bronze/silver/gold are granted by
   the *statistical* review (`pkgdev.Rmd`, "Gold, Silver, and Bronze Badges").
   The general rOpenSci software review issues no grade. So there is no
   silver/gold path unless pladdrr is accepted into stats review.
3. **Only plausible route:** argue it as *Time Series* (Sound, Pitch, Formant,
   Intensity, Spectrogram, MFCC are temporally indexed `Sampled` objects), with
   partial *Unsupervised* (PCA, Discriminant) and *EDA* (autoplot, summaries)
   overlap. Editors decide. The pre-submission enquiry
   (`dev/ropensci-presubmission-enquiry.md`) is still a **draft, not posted**
   (per `dev/ropensci-readiness-plan.md`), and it asks the wrong question: it
   frames the package as "Statistical Software / general" and asks only
   "wrapper in scope?". It should ask: *"Can pladdrr be reviewed under Time
   Series (+ partial Unsupervised/EDA) with a negotiated N/A set for wrapped
   upstream algorithms, and is silver realistic given wrapper standards do not
   exist yet?"*

**Everything below is conditional on editors saying yes. Do not spend the
srr/standards effort before that answer.**

---

## 1. What the badges require

| Grade | Requirement (from `pkgdev.Rmd`) |
|-------|---------------------------------|
| Bronze | Sufficiently/minimally compliant with applicable standards. |
| Silver | Beyond bronze in **≥1 of 4 aspects** (below). |
| Gold | **All** standards reviewers deem potentially applicable, **and ≥3 of the 4 aspects**, and actively maintained as the standards are revised. Badge can be downgraded if not kept aligned. |

The four aspects:

| # | Aspect | Threshold | pladdrr outlook |
|---|--------|-----------|-----------------|
| A | Standards beyond the agreed minimum | ≥¼ of the *additional* applicable standards met (definitely if >½) | Needs reviewer-agreed min/full sets; unknowable until negotiated. |
| B | Excellence across ≥2 sub-categories (e.g. G1 docs + G5 tests), "notably beyond" ≥2 standards in each | | **Strong candidate**: G5 (oracle-based faithfulness, 188 test files, 89.6% coverage at 5.0.5, 3-OS + devel CI) and G1 (16 vignettes, 327 Rd, pkgdown). Needs G5.2/G5.5/G1.x gaps closed first or it undercuts "excellence". |
| C | Demonstrated generality beyond the author's use case | | **Weak/medium**: README says the package "was developed to serve our specific needs". Counter-evidence: 39 modules, interpreter bridge, migration vignettes. Must be argued and documented. |
| D | Internal design/structure of core algorithms | | **Strong, but with a caveat**: bit-exactness controls (`-ffp-contract=off`, thread-affinity-aware pool, typed error classes, golden/fingerprint tests). The *core algorithms are Praat's*, so reviewers may credit integration design, not algorithm design. |

**Verdict:** silver is realistic via B + D, if scope is accepted. Gold needs a
third aspect (C is the only one within reach) **and** "all potentially
applicable" standards, which includes the full General set plus Time Series;
it is a large, ongoing commitment. Recommend **targeting silver, stating gold
as aspirational** in the submission.

---

## 2. Process / tooling gates (prerequisites for submission)

| Gate | Status | Gap / action |
|------|--------|--------------|
| `pkgcheck::pkgcheck()` says "may be submitted" | **Stale.** `pkgcheck.log` is for 5.0.5 (HEAD at that run was 0fd6920d). Last result: all ✔, coverage 89.6%, 0 check warnings. R is now 4.6.1, so pkgcheck/pkgstats **run locally** (installed). | Re-run on 5.1.0. Multi-hour (covr rebuild). Note the pkgcheck list also reports **"srr: TODO standards"** as blocking once srr is wired in. |
| `srr` standards annotated | **Not started.** `srr` is installed; DESCRIPTION has no `Roxygen: list(..., roclets = c("namespace","rd","srr::srr_stats_roclet"))`, no `R/srr-stats-standards.R`, no `@srrstats*` tags anywhere. | The single largest work item. Run `srr::srr_stats_roxygen(category = "time-series")` (+ `"unsupervised"`, `"eda"` if the editors agree), distribute tags, resolve every `@srrstatsTODO` to `@srrstats` or `@srrstatsNA`. |
| `autotest` mutation test clean | **Not yet run on the full package.** (Correction: autotest 0.2.0 *is* installed; an earlier version of this table wrongly said otherwise.) Spike on `create_sound` returned 19 rows: 18 `dummy` (informational, to inspect) + 1 real `warning` (`start_time` not demonstrated in examples). See `dev/ropensci-stats-plan.md` Phase 6. | Run in batches, triage, document false positives (it is "recommended, not strictly required"). |
| CI, coverage ≥75% | ✔ R-CMD-check (ubuntu/macos/windows/devel), test-coverage, pkgcheck, lintr, semgrep, OSV, pkgdown. | None. |
| Package metadata | codemeta.json, CITATION.cff = 5.1.0 ✔. **`inst/CITATION` still says 5.0.5** (lines 15, 21). | Fix; add to the release checklist check. |
| Housekeeping | `tests/testthat/_problems/*.R` (3 files) **tracked in git**; stray `Rplots.pdf` in `tests/testthat/`. | `git rm`, gitignore. |
| goodpractice backlog (from the 5.0.5 log) | long functions ×4, dead internal fns (113+), 622 uncovered lines, 213 lines >80 chars, duplicated `@param` ×24, NEWS spelling ×3 | Triage; most are cosmetic, spelling and long functions are cheap. |
| Name collisions | 12 exported names clash with other packages (`PCA`, `Matrix`, `Polygon`, `Spectrum`, `DTW`, `LPC`, `Intensity`, `Table`, …). Memory notes the `Matrix`/`as.matrix` S3 collision as an unresolved CRAN risk. | Not a hard gate, but reviewers will raise it. Decide: namespace-qualified docs vs rename. |

---

## 3. General Standards (G1–G5)

Legend: ✅ met · 🟡 partial · ❌ gap · ⚪ likely N/A (give reason in `@srrstatsNA`)

### G1 Documentation

| ID | Status | Evidence / action |
|----|--------|-------------------|
| G1.0 primary reference | 🟡 | README + `inst/CITATION` cite Praat (Boersma & Weenink) and the package Zenodo DOI. Only **5 of 327 Rd** have `\references`. Algorithm-level citations (Boersma 1993 pitch, Burg, CPPS: Hillenbrand; AVQI: Maryn; Klatt) live in vignettes but not in function help. Add `@references` per algorithm family. |
| G1.1 novelty/prior-art statement | 🟡 | README "Other similar packages" covers parselmouth, speakr. Add explicit statement: *first in-process R implementation of Praat's C++ algorithms*, and list all known implementations (parselmouth, Praat scripting, speakr, rPraat, PraatR, wrassp, seewave/tuneR where overlapping). The enquiry draft names rPraat/PraatR; README doesn't. |
| G1.2 life-cycle statement | ❌ | Only a repostatus "Active" badge. Add one of the four stock statements to `CONTRIBUTING.md` (suggest: "stable, with active development primarily in response to user feedback" — **maintainer's call**). Cheap. |
| G1.3 terminology defined | 🟡 | Not audited. Acoustic terms (CPPS, jitter, HNR, F1…, "robust slow") need a glossary or per-function definitions. Candidate: one vignette "Terminology". |
| G1.4 roxygen2 for all functions | ✅ | roxygen 8.1.0, 327 Rd. |
| G1.4a internal fns documented (+`@noRd`/`@keywords internal`) | ❌ | pkgcheck: `doclines_per_fn_not_exp = 0.0` (0th percentile); 1672 non-exported R fns vs 175 `@noRd` + 192 `@keywords internal`. Largest chunk is generated `RcppExports.R` (exempt in spirit; say so in NA note), but hand-written internals need blocks. |
| G1.5 code to reproduce publication performance claims | 🟡 | `inst/benchmarks/` is comprehensive. There is no associated publication yet; if the paper in `paper/` makes claims, link scripts to it and make them one-command reproducible. |
| G1.6 code to compare against other R packages | 🟡 | `04_parselmouth_comparison.R` is Python via reticulate, not R-vs-R. Add comparison vs speakr/rPraat if any performance claim names them. Memory caveat applies (parselmouth CPPS gap is a Praat version difference); state oracle version. |

### G2 Input structures

pladdrr takes **Praat objects and numeric vectors**, not data frames; G2.7–G2.12
are mostly ⚪ and G2.0–G2.6 apply to scalar parameters.

| ID | Status | Evidence / action |
|----|--------|-------------------|
| G2.0 length assertions | ✅/🟡 | `R/validators.R` (`.is_numeric_scalar`, `.check_pitch_range`, typed `pladdrr_input_error`). Coverage by validators is **partial**: `grep` found 15 validator call sites across `R/`; many wrappers rely on C++-side Melder errors. Audit per exported function. |
| G2.0a/G2.1a documented expectations | 🟡 | `@param` exists but types/lengths are inconsistently stated. Make this a lint-able convention (`inst/agents/DOCUMENTATION.md` already has one). |
| G2.1 type assertions | 🟡 | As G2.0. |
| G2.2 reject multivariate for univariate | 🟡 | Verify via autotest. |
| G2.3a `match.arg` | ✅ | 87 uses. |
| G2.3b case handling | 🟡 | 28 `tolower()` uses; document "case-sensitive" where not lowercased. |
| G2.4 conversions | 🟡 | `as.data.frame` methods exist for ~43 classes (✅ output); explicit input converters (`create_sound`, `sound_from_values`). Fine. |
| G2.5 factor inputs | ⚪ | No factor parameters expected. Confirm and NA. |
| G2.6 1-D input class robustness (`units`, etc.) | ❌ | `create_sound(values, ...)` is the only 1-D data entry. Test `units` vectors, integer, integer64, `ts`, matrix-with-1-col. |
| G2.7–G2.10 tabular input | ⚪/🟡 | Praat objects are not tabular; but batch APIs take data frames of paths/params (`batch-*`). Test tibble/data.table/data.frame equivalence there (G2.10 `drop=` traps in `data.table` code paths). |
| G2.11–G2.12 odd/list columns | 🟡 | Same batch APIs. Add tests. |
| G2.13–G2.16 NA/NaN/Inf | 🟡 | `test-nan-guards.R` exists. Praat uses `--undefined--` (NaN) semantics natively; policy options for NA handling (error / ignore+warn / impute) are **not offered uniformly**. Document Praat's "undefined" model as a deliberate deviation (G2.14) or add an `na_action` convention. `na.rm` appears 20× in `R/`; G2.15 needs an audit of `mean()`/`sd()` on possibly-NA data. |

### G3 Algorithms

| ID | Status | Evidence / action |
|----|--------|-------------------|
| G3.0 no floating-point equality | 🟡 | R: 2 literal `== 0.0` sentinels (`R/formant-wrapper.R:296`, `R/formant.R:126`, "0 means default" semantics; benign but literal violations — use `isTRUE(all.equal())` or `identical(x, 0)` with a comment). Own C++ wrappers: ~26 `==`/`!=` against float literals (heuristic, `src/*.cpp` excluding vendored). The **vendored Praat tree (1.5 M LOC, 3798 tracked files) will have thousands**; you cannot change it (bit-exactness is the point). Write an NA note: *"vendored upstream; exact comparisons are inherited and deliberately preserved; deviations recorded in `PRAAT_MODIFICATIONS.md`"*. |
| G3.1 covariance algorithm choice | ⚪ | PCA/Discriminant delegate to Praat's covariance. Document; NA with reason, or expose Praat's pooled/group option. |

### G4 Output

| ID | Status | Evidence / action |
|----|--------|-------------------|
| G4.0 auto file suffix | ❌ | `grep file_ext` in `R/` = 0 hits. Writers (`save_as_*`, `write_*`, TextGrid/WAV) don't normalise extensions. Add a helper + tests, or document that suffixes are the caller's responsibility (weaker). |

### G5 Testing

| ID | Status | Evidence / action |
|----|--------|-------------------|
| G5.0 reference data sets | ✅ | Oracle = Praat itself on fixed signals (`tests/testthat/test-praat-faithfulness.R`, `FAITHFULNESS_REPORT.md`: 19 routines pass at documented tolerances). |
| G5.1 test data exported/available | 🟡 | `inst/extdata/test.wav`, `test.TextGrid` via `system.file`; no exported dataset or generator doc. Document `system.file` fixtures in a vignette and export the generator helpers. |
| G5.2 error/warning behaviour tested | 🟡 | 610 `expect_error|warning` vs 434 `stop|warning|message` call sites. |
| G5.2a **unique** messages | ❌ | **33 literal messages occur more than once**: `"Package 'ggplot2' is required. Please install it."` ×38, `"sound must be a Sound object"` ×21, `"…or external pointer"` ×16, `"Could not extract pointer from Sound object"` ×9, … (364 literal sites). Fix by routing through the existing `.stop_input(routine, param, msg)` helper so the routine/param make each message unique, or a shared `.require_ggplot2("fn")`. |
| G5.2b every message triggered & compared | ❌ | Crude grep: ~93% of `expect_error` calls have no message string (heuristic — some use `class=`; verify). A message-coverage check is cheap: collect all `stop()` literals, assert each appears in a test. |
| G5.3 no NA/NaN/Inf in returns | 🟡 | `test-nan-guards.R`; extend to every exported numeric return. Praat's undefined → NaN is intentional for pitch/formant: say so. |
| G5.4 correctness | ✅ | **Best-in-class**: oracle comparison, stored fingerprints, `faithfulness_report.csv`. |
| G5.4a/b vs previous implementation | ✅ | Praat is the previous implementation; versions pinned in report (6.4.47 / 6.4.27). Make the oracle-version policy a test-time assertion. |
| G5.4c published values | ⚪/🟡 | Optional. CPPS/AVQI published reference values (Maryn) could be added. |
| G5.5 fixed seeds | 🟡 | 17 test files use `rnorm|runif|sample`; 7 call `set.seed` (heuristic; some may seed in helpers). Audit and add `withr::local_seed`. |
| G5.6 parameter recovery | 🟡 | 440 Hz tone → F0 = 440.0102 in faithfulness test. Add systematic recovery: F0 across 80–500 Hz, vowel synthesis via KlattGrid → recovered formants, AM depth → shimmer, injected jitter → jitter local. KlattGrid makes this unusually easy; a strong "excellence" demonstrator. |
| G5.6a tolerance | ✅ | Tolerances documented per routine. |
| G5.6b multiple seeds | 🟡 | Same as G5.5. |
| G5.7 performance-with-data tests | 🟡 | Timing tests exist but are CRAN-skipped. Add scaling tests (error vs SNR, vs duration). |
| G5.8a zero-length | 🟡 | 42 test files mention empty/zero-length; no systematic matrix. |
| G5.8b unsupported types | 🟡 | `test-cochleagram-input-validation.R`, others. Systematise. |
| G5.8c all-NA / constant | 🟡 | Add silence, DC offset, all-NaN, clipped signals per analysis. |
| G5.8d outside algorithm scope | 🟡 | e.g. pitch ceiling > Nyquist, window longer than signal; `test-size-validation.R` is a start. |
| G5.9a trivial-noise susceptibility | ❌ | No test. Add: adding `.Machine$double.eps`-scale noise ⇒ pitch/formant/CPPS unchanged within tolerance. Deterministic algorithms still need this. |
| G5.9b seeds/initial conditions | 🟡 | Stochastic parts: Praat "robust slow" (documented non-deterministic, see FAITHFULNESS_REPORT). Document under G5.9b; test that deterministic paths ignore seed. |
| G5.10 extended-tests flag | ❌ | No `PLADDRR_EXTENDED_TESTS`. 26 `skip_on_cran` + ~82 other conditional skips form an ad hoc tier. Migrate timing/large-file/compile tests to `skip_if(!extended)` and wire into CI (`run-extended` commit phrase). |
| G5.11/11a large data fetched; download failures skip | 🟡 | Large fixtures are in-repo. Either move to a release asset with skip-on-fail, or NA. |
| G5.12 extended-test conditions documented | ❌ | Add to `CONTRIBUTING.md` / `tests/README.md` (platform, memory, runtime). |

---

## 4. Time Series standards (closest category)

| ID | Status | Notes |
|----|--------|-------|
| TS1.0 explicit class system, no generic input | ✅ | R6 `Sound`, `Pitch`, `Formant`, … carry time axes (`get_start_time`, `get_time_step`). Concern: `create_sound(values, sampling_rate, start_time)` accepts bare numeric vectors; justify (sampling rate + start supply the index) or require explicit. |
| TS1.1 document input types, show ≥1 common class (`ts`) | ❌ | No `ts`/`tsibble`/`units` interop shown. Add `as_sound(ts)` + vignette example. |
| TS1.2/1.3/1.4 validation, single pre-processor, preserve time attrs | 🟡 | Validators exist but no single entry. Consider `.as_sound_input()` (also fixes G2.6/G2.8). |
| TS1.5/1.6 strict time ordering | ✅/🟡 | Regular sampling is intrinsic; irregular tiers (`PointProcess`, `TextGrid`, `*Tier`) need explicit sorted-order validation and tests. |
| TS1.7 accept `units` input | ❌ | `units` installed; not supported. Optional: accept `units` seconds/Hz. |
| TS1.8 calendar systems | ⚪ | Relative seconds only. NA with that reason. |
| TS2.0/TS2.1 regular data, explicit missing | 🟡 | Praat has no NA in samples; undefined frames appear as NaN. Document + choose policy (see G2.14). |
| TS2.2–TS2.4 stationarity | 🟡 | Analyses assume quasi-stationarity within a frame (window length, pitch floor). Document per method; add a warning/advice where window < 3/f0_floor. |
| TS2.5–2.6 autocovariance matrices | ⚪ | Autocorrelation pitch is internal. NA unless exposed. |
| TS3.* forecasting | ⚪ | Not forecasting (LPC prediction is analysis, not forecast; say so). |
| TS4.0–4.3 return value class, units | 🟡 | Returns carry time axes; **units are not attached as attributes** (`units` pkg). Document units in `@return` per method (TS4.2). |
| TS4.4–4.7 | ⚪ | Forecasting only. |
| TS5.0 default `plot` methods | ✅ | `plot`/`autoplot` S3 for most classes. |
| TS5.1–5.3 time axis labelled, horizontal, with units | 🟡 | Audit autoplot defaults ("Time (s)"). |
| TS5.4 frequency axis convention | ✅ | Hz positive axis; confirm no `[-π, π]`. |
| TS5.5 NA → broken vs continuous lines | 🟡 | Pitch unvoiced gaps: add `connect_gaps` option (check `autoplot` args). |
| TS5.6–5.8 forecasts | ⚪ | NA. |

## 5. Secondary categories (only if editors agree)

* **Unsupervised (PCA, Discriminant).** UL1.x–UL4.x apply to these wrappers
  (row names handling UL1.2, scaling UL2.x, prediction on new data UL3.3,
  return structure UL4.x). Small surface; pladdrr delegates to Praat's
  PCA/Discriminant. Likely best handled as NA ("only 2 of 39 modules; wrapped
  verbatim") — raise with editors.
* **EDA.** EA1.x–EA4.x (audience, data kinds, `summary`/`print`/`plot`
  methods, reproducible outputs). `autoplot`, `summary`, `as.data.frame` give a
  strong fit for EA4.x; EA1.x need an explicit "Audience" statement (README
  currently describes internal needs).

---

## 6. Prioritised plan

**P0 — decide before any more work**
1. Post the pre-submission enquiry, rewritten as in §0.3, with the
   Time-Series-plus-negotiated-NA framing and an honest ask about silver.
   (Posting is external and public; requires your go-ahead.)
2. Re-run `pkgcheck::pkgcheck()` on 5.1.0 in the background (multi-hour) so
   the baseline is current while waiting for the editors.

**P1 — cheap, valuable regardless of the answer** (≈1–2 days)
3. `inst/CITATION` 5.0.5 → 5.1.0; `git rm` `_problems/*.R`, `Rplots.pdf`.
4. G1.2 life-cycle statement in `CONTRIBUTING.md`; G5.12 extended-test docs.
5. G1.1 prior-art paragraph; G1.0 `@references` for the ~15 algorithm families.
6. G5.2a: unify duplicated messages through `.stop_input` / `.require_ggplot2`
   (33 sites × many callers; mechanical, test-guarded).
7. G3.0: replace the 2 R `== 0.0` sentinels; list the ~26 C++ ones.
8. G4.0: output-suffix helper + tests.
9. G5.10: `PLADDRR_EXTENDED_TESTS` flag; move the 26 `skip_on_cran` timing/large
   tests under it; CI workflow wiring.

**P2 — the standards-specific work** (blocked by P0 answer; ≈1–2 weeks)
10. `srr` wiring, generate TODO list, annotate (G + TS, then maybe UL/EDA).
11. Parameter-recovery and noise-susceptibility tests via KlattGrid (G5.6,
    G5.9) — doubles as the evidence for silver aspect B.
12. Edge-condition matrix (G5.8) as a single parametrised test over exported
    analysis functions.
13. Message-coverage test (G5.2b): every `stop()` literal appears in a test.
14. `autotest` run; document unavoidable R6/XPtr false positives.
15. G1.4a: internal-function roxygen blocks (hand-written ones only), G1.3
    glossary vignette, G2.6/TS1.1 `ts`/`units` input path.

**P3 — gold only**
16. Evidence for aspect C (generality): documented use cases beyond author's
    workflows (corpus-scale batch, clinical voice quality, forensic, language
    documentation), two external users/case studies.
17. Standing commitment to track standards revisions (gold is re-assessed
    against *current* standards).

## 7. Risks to be honest about

* **Scope outcome is a hard binary** and out of your control. If "no", the
  package is still a candidate for the *general* rOpenSci software review,
  which has no badge grades — silver/gold would not apply.
* **Reviewer credit for algorithms.** Core algorithms are upstream Praat. Aspect
  D (design) and G1.1 must be framed around integration fidelity, not algorithm
  novelty. Praat is GPL-2+; the licensing chain check noted in the enquiry
  draft ("GPL-3 + file LICENSE" with `inst/COPYRIGHTS`) is still open.
* **Gold's "all applicable standards"** is judged by reviewers, not by you.
  Expect the TS5/G2 sets to expand once reviewers see 405 exports.
* **Package size.** 405 exports and 1.5 M LOC of vendored C++ is 100th-percentile
  on every pkgstats axis; reviewer load is real and may lengthen review.
* **Heuristic counts** (unique-message tally, `expect_error` message rate,
  seed usage, C++ float-equality count) should be re-derived with a script
  before they are cited in a submission.
