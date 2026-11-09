# Plan: close the biggest gaps toward rOpenSci stats silver

Companion to `dev/ropensci-stats-gap-analysis.md` (read it for evidence and
standard IDs). Written 2026-11-09 against `main` @ 05442e6c, v5.1.0.

Target: **silver** (aspects B tests+docs, D design). Gold stays aspirational.

Ordering rule: do what is useful whatever the editors answer first (Phases
1–5), and defer the `srr` annotation (Phase 7) until scope is confirmed
(Phase 0). Every phase ends in a command that proves it.

---

## Phase 0 — scope gate (blocks only Phase 7)

| # | Task | Notes |
|---|------|-------|
| 0.1 | Rewrite `dev/ropensci-presubmission-enquiry.md` | Ask: *Time Series (+ partial Unsupervised/EDA) with negotiated N/A for wrapped upstream algorithms; is silver realistic while wrapper standards do not exist?* Fix "38 modules" → 39. |
| 0.2 | **Post it** to `ropensci/software-review` | External + public: **needs the maintainer's explicit go-ahead.** |
| 0.3 | Start `pkgcheck` baseline in background | See command below; multi-hour, run once Phase 1 is committed so it reflects the cleaned tree. |

```bash
Rscript -e 'res <- pkgcheck::pkgcheck("."); saveRDS(res, "pkgcheck.rds"); sink("pkgcheck.log"); print(summary(res)); sink()'
```

**Decisions needed from the maintainer** (answer once, then the phases run):

1. G1.2 life-cycle wording — which of the four stock statements.
2. G4.0 policy — auto-append suffix, or error on wrong suffix (see 5.1).
3. Extended tests — include in the covr run (slow, more honest coverage)?
4. Target stated in submission: silver, gold aspirational?

**Done when:** enquiry posted, answer recorded in memory.

---

## Phase 1 — hygiene (≈1 h, one commit)

| # | Task | Files |
|---|------|-------|
| 1.1 | `inst/CITATION` 5.0.5 → 5.1.0 (two places) | `inst/CITATION:15,21` |
| 1.2 | Guard against recurrence | add a test that `packageVersion("pladdrr")` matches `inst/CITATION` and `CITATION.cff`/`codemeta.json` (skip when source files absent, i.e. in the installed package) |
| 1.3 | `git rm -r tests/testthat/_problems`; add to `.gitignore` and `.Rbuildignore`; remove stray `tests/testthat/Rplots.pdf` | |
| 1.4 | Spelling items from pkgcheck (`NEWS.md:26,30`) | `inst/WORDLIST` |

**Verify:** `git status` clean after a test run; new test passes.

---

## Phase 2 — unique, tested messages (G5.2a/b) — biggest mechanical item

Measured: 364 literal `stop/warning/message` sites, **33 literals duplicated**
(`Package 'ggplot2' is required…` ×38 in 5 files, `sound must be a Sound
object` ×21, `…or external pointer` ×16, `Could not extract pointer…` ×9,
`Invalid input type: expected Sound or externalptr` ×9, `textgrid must be a
TextGrid object` ×8, `pitch must be a Pitch object` ×8, …). Heavy files:
`pointprocess-wrapper.R`, `sound-wrapper.R`, `vad.R`, `batch-queries.R`,
`plotting-combined.R`.

| # | Task | Detail |
|---|------|--------|
| 2.1 | **Audit script** `dev/audit-messages.R` | Use `getParseData()` on `R/*.R`, not grep: extract every `stop/warning/message/.stop_input/.warn_data_loss` call, resolve literal vs `paste0()` templates, emit CSV (file, line, fn, text). This replaces the heuristic counts used so far. |
| 2.2 | Central helpers in `R/validators.R` | `.require_pkg(pkg, fn)` (ggplot2/RcppSimdJson/av…), `.assert_class(x, "Sound", arg, fn)` (accepts XPtr where the wrapper does). Both build on the existing `.stop_input(routine, param, msg)` so **routine + param make each message unique** and the `pladdrr_input_error` class contract is preserved. |
| 2.3 | Migrate top offenders | Order by duplicate count; one file per commit; keep the user-facing wording otherwise. |
| 2.4 | Update tests that match old text | Search `tests/testthat` for the old literals; prefer `expect_error(…, class = "pladdrr_input_error")` plus a regexp on the unique part. |
| 2.5 | **Uniqueness guard test** `test-message-uniqueness.R` | Runs the 2.1 parser over `R/` (skip if `R/` absent); fails on any duplicate literal. Permanent regression gate. |
| 2.6 | **Message-coverage ratchet** (G5.2b) | `tests/message-baseline.txt` lists literals currently untested; test asserts the list never grows and prints the shrinking count. Burn it down per file as you touch code. Do **not** try to finish all 364 in one go. |

**Verify:** `Rscript dev/audit-messages.R` reports 0 duplicates; full test suite green; baseline file committed.
**Effort:** 2 (audit+helpers+guard) + ~3 days (migration) + ongoing burn-down.
**Risk:** user-visible message changes → note in NEWS.

---

## Phase 3 — extended-test tier (G5.10–G5.12)

Today: 26 `skip_on_cran()` in 12 files + ~80 `skip_if_not_installed`/CI skips = an
ad hoc tier. Files with `skip_on_cran`: `test-textgrid-benchmark.R` (5),
`test-performance-enhancements.R` (5), `test-check-core-limit.R` (3),
`test-fidelity-fingerprint.R` (2), `test-powercepstrogram-simd.R` (2),
`test-tier4-ultra.R` (2), `test-batch-queries.R` (2), plus singletons and two
helpers.

| # | Task |
|---|------|
| 3.1 | `tests/testthat/helper-extended.R`: `skip_if_not_extended()` reading `PLADDRR_EXTENDED_TESTS` (`"true"`). |
| 3.2 | Classify each `skip_on_cran` (read each body, as in the Phase 6 audit of 2026-08-12): **timing/benchmark / large-fixture / compile-at-test-time → extended**; ordinary correctness → remove the skip. |
| 3.3 | CI: add to `R-CMD-check.yaml` env `PLADDRR_EXTENDED_TESTS: ${{contains(github.event.head_commit.message, 'run-extended')}}` (rOpenSci's own recipe); optional weekly scheduled job with it forced on. |
| 3.4 | G5.12 docs: new section in `.github/CONTRIBUTING.md` (platform, memory, runtime, artefacts) + `tests/README.md`. |
| 3.5 | Decision 3: set the flag in `test-coverage.yaml` or not. |
| 3.6 | G5.11a: large fixtures stay in repo → write NA text, unless fixtures ever move to a release asset (then skip-on-download-fail). |

**Verify:** `PLADDRR_EXTENDED_TESTS=true Rscript -e 'devtools::test()'` and unset run both green; commit with `run-extended` triggers the job.
**Effort:** ≈1 day.

---

## Phase 4 — algorithm-level tests (G5.5, G5.6, G5.8, G5.9) — also the silver-B evidence

Create three focused files; derive tolerances **empirically first**, then pin:

| File | Content |
|------|---------|
| `test-parameter-recovery.R` (G5.6/6a) | Pure tones 80–500 Hz → F0 within 0.5 Hz (pitch AC/CC/SHS); KlattGrid-synthesised vowels (several F1/F2) → Burg formant recovery within tolerance; AM depth → shimmer; injected cycle-period jitter → jitter local; noise-added tones → HNR monotone in SNR. Use `withr::local_seed()` wherever noise is drawn (G5.6b: loop over ≥3 seeds in the extended tier). |
| `test-noise-susceptibility.R` (G5.9a) | Add `.Machine$double.eps`-scale noise to a vowel; pitch, intensity, formant, CPPS, jitter unchanged within the faithfulness tolerances. G5.9b: document that deterministic paths ignore seed; mark Praat "robust slow" non-determinism as the documented exception (already in `FAITHFULNESS_REPORT.md`). |
| `test-edge-conditions.R` (G5.8a–d) | One parametrised matrix over a registry of core analysis fns × {zero-length, NA/NaN-only, silence, constant/DC, clipped, non-numeric, complex, window > duration, ceiling > Nyquist}. Expect an informative error or documented NaN result — never a crash. Run each case in `callr` for the cases that could touch C++ UB. |

G5.5 seeds: add `withr::local_seed()` to the 11 files that draw random numbers
without seeding (listed by grep: `test-simd-matrix.R`, `test-phase3-textgrid-simd.R`,
`test-electroglottogram-r6.R`, `test-phase2-simd.R`, `test-simd-modules-vs-praat-golden.R`,
`test-phase4-formantpath-simd.R`, `test-simd-accuracy.R`,
`test-phase3-batch-queries-simd.R`, `test-longsound.R`, `test-cochleagram-r6.R`,
`test-deprecation-warnings.R`) — verify each actually needs it first.

**Verify:** suite green on all CI OSes (tolerance on Windows/macOS arm64 may differ; see the Intensity FMA caveat).
**Effort:** ≈3–4 days; most of it is choosing and validating tolerances.

---

## Phase 5 — documentation and API gaps (G1.*, G3.0, G4.0)

| # | Standard | Task |
|---|----------|------|
| 5.1 | G4.0 | **27 `save`/`write` methods** (Sound, TextGrid, Pitch, Formant, tiers, Matrix, Table, …). Add `.ensure_suffix(path, format)` (central, in `R/validators.R`) and call it in each; extend the tests per class; document. If decision 2 = "error on mismatch", say so in `@param path`. |
| 5.2 | G1.2 | Add the life-cycle statement to `.github/CONTRIBUTING.md` (it is not present; only the repostatus badge exists). |
| 5.3 | G1.1 | README: "Prior art / what is new" — first in-process R binding to Praat's C++ algorithms; list every known implementation (Praat scripting, parselmouth, speakr, rPraat, PraatR, wrassp, tuneR/seewave where overlapping). Verify each link before listing. |
| 5.4 | G1.0 | `@references` for each algorithm family (pitch AC/CC/SHS, Burg/FormantPath, intensity, HNR, jitter/shimmer, CPPS, AVQI, LPC/MFCC, KlattGrid, ComplexSpectrogram…). **Citations must be looked up and verified, not written from memory** (only 5 of 327 Rd have `\references` now). A single `@rdname`-shared reference block per family keeps it cheap. |
| 5.5 | G1.3 | `vignettes/terminology.Rmd`: define every acoustic/statistical term used in outputs (CPPS, HNR, jitter local/rap/ppq5, shimmer variants, "robust slow", undefined/NaN semantics). |
| 5.6 | G1.4a | Roxygen blocks (+ `@noRd`) for the **417 hand-written internal functions** (`.name <- function`), prioritised by complexity; generated `RcppExports.R` stays exempt with an NA note. Re-measure via `pkgstats` (`doclines_per_fn_not_exp`, currently 0). Time-box: highest-fan-in 100 first. |
| 5.7 | G3.0 | Replace `tmax == 0.0` (`R/formant-wrapper.R:296`) and `time_step == 0.0` (`R/formant.R:126`) with `identical(x, 0)`/`isTRUE(all.equal())` plus a comment ("0 = Praat default"). List the ≈26 own-C++ float comparisons in `inst/agents/PRAAT_MODIFICATIONS.md` or the NA note; vendored Praat remains untouchable by design. |
| 5.8 | G2.13–16 | Write the NA/undefined policy (Praat "undefined" → NaN, no imputation) once, in a vignette section, and cite from each `@srrstatsNA`; audit `mean()/sd()` calls on potentially-NaN data in `R/`. |
| 5.9 | G2.6 / TS1.1 | `create_sound()` accepts `units`, integer, `ts`, 1-col matrix; test each. Add a vignette snippet showing `ts` input (TS1.1). |

**Verify:** `roxygen2::roxygenise()` clean, `R CMD check` no new notes, relevant new tests green.
**Effort:** ≈1 week total; 5.4 and 5.6 dominate.

---

## Phase 6 — autotest (installed: 0.2.0; spike done)

Spike on `create_sound` took well under a minute and gave 19 rows: **18
`dummy`** (informational probes: noise-added numeric, vector→list-column,
double-is-int, length-2 for length-1 param, return documented/classed) and
**1 real `warning`** (`start_time` is not demonstrated in the examples).
So the actionable output is mostly documentation/validation hygiene, not crashes.

| # | Task |
|---|------|
| 6.1 | Script `dev/run-autotest.R`: iterate exported functions in batches of ~25, **one fresh R process per batch** (C++ crash isolation), `timeout`, results to `dev/autotest/<batch>.rds`. Note autotest installs a copy of the package; run it from a release (-O2) install. |
| 6.2 | Triage into: (a) `warning`/`diagnostic`/`error` rows → fix (examples exercising each parameter, missing `@return` class); (b) `single_par_as_length_2` → either validator or documented behaviour (covers G2.0/G2.2); (c) R6 method/XPtr false positives → record. |
| 6.3 | Before/after count in the submission text; remaining rows listed with reasons. |

**Verify:** `autotest_package()` yields only documented-false-positive rows.
**Effort:** ≈1 day to run, 2–3 days to triage.

---

## Phase 7 — `srr` annotation (after Phase 0 answer)

1. DESCRIPTION: `Roxygen: list(markdown = FALSE, roclets = c("namespace", "rd", "srr::srr_stats_roclet"))` (this package does **not** enable roxygen markdown — see `inst/agents/DOCUMENTATION.md`; keep `markdown = FALSE` and write `@srrstats` text accordingly). Config/roxygen2/version stays.
2. `srr::srr_stats_roxygen(category = "time-series")` → `R/srr-stats-standards.R`. Add `"unsupervised"`/`"eda"` only if editors agree.
3. Distribute tags next to the evidence from Phases 1–6 (tests → `tests/testthat/*`, docs → README/vignettes, validation → `R/validators.R`).
4. Draft the N/A set once, in one block with reasons: vendored-upstream float equality (G3.0), covariance (G3.1), factor input (G2.5), tabular standards where inapplicable (G2.7–12), calendar systems (TS1.8), forecasting (TS3, TS4.4–4.7, TS5.6–8), autocovariance (TS2.5–6), G5.11 large downloads. Agree it with editors during the enquiry.
5. `roxygen2::roxygenise()` prints the TODO count; goal 0. Then `srr::srr_report()`.

**Effort:** ≈1 week for G + TS, mostly writing precise "where/how" sentences.

---

## Schedule and dependencies

```
Phase 0.1–0.2 ──▶ (editor answer) ─────────────────────────▶ Phase 7
Phase 1 ─▶ 0.3 pkgcheck baseline (bg)
Phase 1 ─▶ Phase 2 ─▶ Phase 3 ─▶ Phase 4        Phase 5 (parallel after 2.2)
                                   └───────▶ Phase 6 (after 2 and 5.9, so fewer findings)
```

Rough total ≈ 4–5 working weeks for silver-ready, excluding editor latency.
Suggested first sprint (3–4 days): Phase 1, 5.2, 5.7, 2.1–2.2, 3.1–3.4. Those
alone turn four ❌ into ✅ and give a measured message audit.

## Definition of done (silver-ready)

* `pkgcheck` summary says "may be submitted"; `srr` TODO count = 0.
* Zero duplicate messages (guard test); message-coverage baseline shrinking.
* Extended tier documented and wired in CI.
* Parameter-recovery, noise-susceptibility and edge-condition tests present.
* `autotest` triaged; remaining rows documented.
* G1.0–G1.4a items addressed or justified; version metadata consistent.

## Memory to save when work lands

Scope answer from editors; tolerances chosen in Phase 4 and why; the
`autotest` batch/runner recipe; any message-text changes shipped.
