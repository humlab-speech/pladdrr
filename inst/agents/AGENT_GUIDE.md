# pladdrr Agent Guide

**Version:** 5.0.3 guide refresh (2026-08-14)
**Purpose:** Reference for LLM agents reimplementing Praat functionality via pladdrr
**Status:** Current through package 5.0.3. Shared-dispatch wrappers + threaded Praat backend + xsimd acceleration (enabled at build time, runtime toggle via `pladdrr_simd()`) + clinical Tier 4 helpers + wrapper dispatch migration (Sound/Formant/Spectrum/Spectrogram queries now use direct `.Call()` instead of Rcpp module dispatch) + current `praat.github.io/` build prefix guidance + current CPPS/CPP usage notes + macOS PSOCK parallelism + unified SIMD bridge header (`simd_bridge.h`) + GitHub Actions CI + code coverage + spectral-moments/data-frame allocation cleanup (v4.9.24) + CRAN pre-submission hygiene and full man/ coverage (v5.0.0) + Ltas full Praat-parity query coverage and new SpectrumTier peak-picking class (v5.0.3).
- **v4.9.18 — Performance + docs + CI (2026-08-05 assessment, Phases 1-4):**
  - **PointProcess jitter/shimmer batch cache:** First shimmer call fetches all 11 jitter+shimmer metrics via `get_jitter_shimmer_batch_cpp()`. Subsequent jitter or shimmer calls with matching parameters return from cache — no additional C++ crossing. Backward compatible: jitter methods unchanged (no Sound required); cache activates automatically after first shimmer call.
  - **Formant `get_all_values_at_time` — single C++ call:** Added `formant_get_all_values_at_time()` export; replaces `vapply` loop over N module calls with one direct wrapper call.
  - **Runnable examples:** Spectrum, Harmonicity, PowerCepstrum, Pitch, PointProcess now have self-contained examples using `Sound$create_tone()` — executable during `R CMD check`.
  - **Phase 2 — class documentation overhaul:** All 15 R6 class wrapper files expanded with full method listings grouped by category, `@seealso` cross-references, and improved `@description` text (Formant, Pitch, Intensity, PointProcess, Spectrum, Spectrogram, Harmonicity, PowerCepstrum, LPC, TextGrid, Ltas, MFCC/LFCC, PCA, Discriminant, DTW).
  - **Phase 3 — dispatch migration from module to wrapper calls:** Sound (7 query methods), Formant (14), Spectrum (16), Spectrogram (12) migrated from `.self$.cpp$method()` (Rcpp Module dispatch, 3 layers: R→Module→C++) to `.Call("_pladdrr_*", .self$.xptr, args)` (direct wrapper, 2 layers: R→C++). ~30-40% less per-call overhead. Remaining module calls: simple getters without wrapper equivalents (xmin/xmax), print methods, and object-creation transforms.
  - **Phase 4 — CI infrastructure:** `.github/workflows/R-CMD-check.yaml` (ubuntu release/devel, macOS) with system deps. `.github/workflows/test-coverage.yaml` (covr + Codecov). Hardcoded developer paths in tests replaced with `PLADDRR_PRAAT_EXEC` / `PLADDRR_PLABENCH_DIR` env vars.
- **v4.9.18 — Assessment-driven fixes (2026-08-05):**
  - **CPPS trend-fit fusion:** `calculate_cpps_ultra(fused=TRUE)` reuses per-frame trends, eliminating duplicate trend fit (~2x speedup for CPPS-heavy pipelines). Default `fused=FALSE` preserves bit-exact Praat output.
  - **SIMD small-input gating:** `simd_bridge.h` scalar fallback for `n < 16` avoids dispatch overhead on tiny vectors. `simd_bridge_stat_direct()` zero-copy overload for 0-based SIMD functions.
  - **Thread pool consolidation:** Removed custom `parallel_for_range` pool in `batch_queries.cpp`; `PowerCepstrogram_smooth_fast` now uses `MelderThread_PARALLELIZE`, respecting `pladdrr_threads()` cap.
  - **Frequency unit code fix:** `get_pitch_at_times()`, `get_pitch_quantiles_batch()`, and pitchtier wrapper now route through centralized `unit_to_code()` instead of inline `switch()` blocks with wrong `semitones=3` (Praat enum: `semitones=1`). String API users unaffected.
  - **Bridge function visibility:** 13 `*_simd_bridge` functions re-marked `@keywords internal` (were erroneously `@export` in v4.9.14). Not part of the public API.
  - **Faithfulness test expansion:** 5 → 11 Praat oracle routines (added CPPS, Pitch AC, Pitch SHS, Intensity, Formant KeepAll, Pitch quantile).
  - **Documentation:** `inst/agents/ARCHITECTURE.md` (dispatch patterns, threading, build system) and `inst/agents/HISTORY.md` extracted from AGENT_GUIDE.

- **v4.9.16 — SIMD enabled at build time; macOS parallelism fix; code cleanup (2026-08-04 assessment):**
  - **SIMD now compiled by default:** `-DHAVE_XSIMD` added to `PKG_CPPFLAGS` in `Makevars.in`/`Makevars`. All 32 SIMD files (previously dead code gated behind `#ifdef HAVE_XSIMD`) are now active. Runtime detection via xsimd selects best instruction set per architecture (NEON on arm64, AVX2/SSE4.2 on x86_64). SIMD regression tests pass bit-identically (0 failures, 23 passes). `simd_info()` shows actual architecture at runtime.
  - **macOS parallel-batch fix:** `analyze_files_parallel()` now uses PSOCK clusters on macOS (`Sys.info()[["sysname"]] == "Darwin"`) instead of `mclapply()`, avoiding fork event-loop issues. Linux and Windows paths unchanged.
  - **Rename `num_stubs.cpp` → `melderthread_impl.cpp`:** The file contained the real `MelderThread` implementation (not stubs). Renamed for clarity. All 3 Makevars files + `praat_app_stubs.cpp` references updated.
  - **Deleted `sound_module_poc.cpp`:** 1,197-line proof-of-concept duplicating `modules/sound_module.cpp`. Removed from build.
  - **Unified SIMD bridge header:** New `src/simd_bridge.h` provides `simd_bridge_stat<T>()` and `simd_bridge_binary<T>()` templates for the repeated pattern across 6 bridge files (R vector → 1-indexed C array → SIMD fn → return). Reduces ~2,500 lines of future boilerplate.
  - **Documentation:** 17 R6 class wrapper files now have `@return` tags. Self-contained runnable examples added to Formant, Intensity, PointProcess, Spectrogram (using `Sound$create_tone()` — executable during `R CMD check`). README spelling errors fixed (14 typos).
- **v4.9.14 — SIMD batch-query bridge functions restored to public API; stale CPPS test fixed:** 8 `*_simd_bridge` functions in `batch_queries_simd_bridge.cpp` (`calculate_mean_simd_bridge` etc.) were implemented and compiled correctly but missing from `NAMESPACE` — `// [[Rcpp::export]]` tags had no `//' @export` roxygen comment, so `roxygen2::document()` silently dropped them. Added the missing tags and regenerated `NAMESPACE`/`RcppExports.R`. Also fixed `tests/testthat/test-cpps-defaults.R`, which still asserted the pre-v4.9.10 `max_quefrency`/`tilt_line_quefrency` defaults.
- **v4.9.13 — `voice_report()` arg-order bug fixed; Tier 4 Ultra algorithm choices documented:** `PointProcess$voice_report()` passed xptrs in the wrong order and exposed `period_floor`/`period_ceiling` params with no C++ counterpart, silently corrupting jitter/shimmer/voice-break output; signature corrected to `silence_threshold`/`voicing_threshold`. `get_voice_quality_ultra()` gains `pitch_method = "periodic_cc"` as an alias for `pitch_method = "ac", very_accurate = FALSE`. See "Tier 4 Ultra: Hardcoded Algorithm Choices" below for the full per-function algorithm audit.
- **v4.9.11 — `get_voice_quality_ultra()` gains `pitch_method`/`very_accurate`:** opt-in args let callers request Praat's `Sound_to_Pitch_rawAc` path instead of the hardcoded `Sound_to_Pitch_rawCc(veryAccurate=TRUE)`. Also fixes a `CallEntries[]` regression where `Rcpp::compileAttributes()` reverts `extern`→`static`, breaking dynamic symbol lookup; `tools/check_callentries.sh` now self-heals this in `configure`.
- **v4.9.10 — `calculate_cpps_ultra()` trend-fit quefrency window fix:** `tilt_line_quefrency`/`max_quefrency` were declared but silently ignored by the C++ core (hardcoded `[0.003, 0.04]`); now threaded through correctly. R-level defaults changed `0.001`/`0.05` → `0.003`/`0.04` to match prior actual behavior (no change for default callers).

---


## Typed Errors (design principle 6)

**Status as of v4.9.19: argument validation is wired up; the C++ layer mostly is not.**

Two independent mechanisms produce classed conditions.

**R-level validators (live, always on).** `R/validators.R` raises
`pladdrr_input_error` conditions directly — you do **not** need
`with_pladdrr_errors()` to catch them:

```r
tryCatch(
  sound$to_pitch(0, 600, 75),                    # ceiling < floor
  pladdrr_input_error = function(e) e$param      # -> "pitch_ceiling"
)
```

Conditions carry `$routine` and `$param` so callers can branch programmatically.
Validators currently covering: pitch range, positive counts/numbers, `time_step`
(0 = auto, matching Praat), quefrency ranges, trend-fit method.

**Data loss (live).** When a routine returns something Praat fabricated, pladdrr
returns Praat's value and says so:

```r
w <- tryCatch(sound$extract_part(5, 10), warning = function(w) w)
class(w)   # "pladdrr_data_loss" "pladdrr_warning" "warning" "condition"
```

Praat zero-pads a window that runs past the signal; goal 1 says reproduce the
value, goal 6 says report the fabrication. Controlled by
`options(pladdrr.data_loss = "warn" | "error" | "silent")`; default `"warn"`.

**C++ tags (partially wired).** Wrappers can emit tagged messages that
`with_pladdrr_errors(expr)` reclassifies:

```cpp
PLADDRR_REQUIRE_PTR("routine_name", xptr, "xptr_param_name");
PLADDRR_REQUIRE_FINITE("routine_name", "param_name", value);
PLADDRR_STOP_INPUT("routine_name", "param", "human-readable reason");
PLADDRR_STOP_PRAAT("routine_name", "Praat raised an error doing X");
PLADDRR_WARN_DATA_LOSS("routine_name", "n of m values undefined");
```

Only `src/batch_queries.cpp` uses them today. **Every other C++ wrapper still
raises a plain `simpleError`**, so do not assume a `pladdrr_praat_error` will
arrive from an arbitrary routine — check before you rely on it.

| Class                 | Meaning                              | Where it comes from       |
|-----------------------|--------------------------------------|---------------------------|
| `pladdrr_input_error` | invalid argument / precondition fail | R validators (live)       |
| `pladdrr_praat_error` | Praat internal failure               | C++ macros (2 sites only) |
| `pladdrr_data_loss`   | output incomplete vs request         | R + C++ (live)            |

All inherit from `pladdrr_error` → `error` → `condition`, so one
`tryCatch(pladdrr_error = ...)` catches them all.

When porting a new wrapper: call the shared validators at R level, replace bare
`stop("...")` in C++ with the macros above, and emit `WARN_DATA_LOSS` whenever
the result contains NA from out-of-range or undefined input. Lock the behaviour
in `tests/testthat/test-error-reporting.R`.

## Performance Audit

**Before you time anything, check `simd_info()$debug_build`.** If it is `TRUE`
the shared object was compiled without `NDEBUG` at `-O0` — almost always because
`devtools::load_all()` / `pkgbuild::compile_dll()` wrote the `.o` files and a
later `R CMD INSTALL` only relinked them. Every measurement from such a build is
2–7x too slow and worthless. Fix with `R CMD INSTALL --preclean .`. See the
v4.9.22 entry under "What's New" for the full diagnosis.

Static SIMD + threading inventory: `tools/perf_inventory.sh` walks `src/` and
the Praat submodule and emits `inst/agents/PERFORMANCE_INVENTORY.md`. Use it
to find wrappers that lack an accompanying `*_simd.cpp` (Phase F SIMD
candidates) and to enumerate every `MelderThread_PARALLELIZE` call site.

Runtime benchmark: `inst/benchmarks/run_audit_benchmarks.R` times each
faithfulness-registry routine against Praat-native execution and writes
`inst/benchmarks/RESULTS.md` with a `speedup_vs_praat` column. Praat startup
is intentionally part of the timing — that cost is real for the
"shell out to Praat" alternative the package replaces. Requires
`R CMD INSTALL .` first.

## Faithfulness Audit

Design principle 1 — faithfulness to Praat's own DSP output — is enforced by
`tests/testthat/test-praat-faithfulness.R`, which invokes
`/Applications/Praat.app/Contents/MacOS/Praat --run` against an extensible
registry of routines in `tests/testthat/faithfulness/routines.R`, compares the
output to the matching pladdrr call at a per-routine tolerance, and emits
`inst/agents/FAITHFULNESS_REPORT.md`.

When porting a new Praat routine into pladdrr, add a registry row. Default
tolerance is `0` for exact-arithmetic routines; looser tolerances require a
written rationale in the row. Failing rows are first-class regressions.

## What's New in v5.0.4

- **v5.0.4 — 8 Spectrogram/PowerCepstrogram/PowerCepstrum plotting bugs fixed; all 5 affected functions had zero prior test coverage (2026-08-19).**
  - **Root cause, shared by all 5 functions:** each independently hand-rolled matrix-to-dataframe conversion instead of delegating to the object's own already-correct `as_data_frame()`/`as.data.frame()` accessor. `expand.grid(time =, frequency =)` (or `quefrency =`) varies its first-listed argument fastest; `as.vector(matrix)` varies the matrix's **row** fastest (column-major storage) — the two orderings only agree when the matrix happens to be square. Fix pattern throughout: delegate to the correct accessor, then apply `10 * log10(pmax(power, 1e-20))` explicitly where the source is raw linear power.
  - **`autoplot.Spectrogram()` / `autolayer.Spectrogram()` / `plot.Spectrogram()`** (`R/autoplot-methods.R`, `R/plotting-methods.R`): frequency axis scrambled (measured: a 220 Hz tone peaked at 2201.3 Hz before the fix, 218.75 Hz after) — `nrow(mat)` is frequency, but `time` was listed first in `expand.grid()`. Also plotted raw linear power (measured range for a typical fixture: `4.8e-17` to `15.0`) directly as `"Power (dB)"`, so `dynamic_range` clipping (`power_db < max - dynamic_range`) never triggered — linear power is always numerically greater than a negative threshold. Fixed by delegating to `.spectrogram_methods$as_data_frame` (`R/spectrogram-wrapper.R`), which was already correct and already used elsewhere, plus explicit dB conversion. `plot.Matrix` (`R/plotting-methods.R`) was checked and confirmed **not** to share this bug — it builds its data frame with `rep(each=)/rep(times=)`, not `expand.grid()`, and the two orderings do agree there.
  - **`plot_powercepstrogram()`** (`R/cepstrum_plots.R`): same transposition bug (time/quefrency), plus `max_time <- 5.0  # Placeholder` instead of the cepstrogram's real duration (measured: 0.249s for a 0.3s fixture — a 20x error), plus the same missing-dB-conversion bug (measured raw range `6.9e-6` to `2.8e11`; `-51.6` to `114.5` dB after fixing). Fixed by delegating to `as.data.frame.PowerCepstrogram` (`R/as-data-frame-missing.R`), already correct.
  - **`plot_cpp_timeseries()`** (`R/cepstrum_plots.R`): same `max_time <- 5.0` placeholder, plus an unrelated `tryCatch()` scoping bug — the error handler did `cpp_values[i] <- NA`, which assigns to a copy of `cpp_values` local to the handler closure (R closures over `for` loops don't get automatic `<<-` promotion), so a failed `get_cpp_at_time()` call silently left that sample at its `numeric(n_samples)` default of `0` instead of becoming `NA` and being dropped by the downstream `!is.na()` filter. One-character fix: `<-` → `<<-`.
  - **`plot_powercepstrum()`** (`R/cepstrum_plots.R`): `max_quefrency <- 0.05  # Reasonable default max quefrency` instead of the cepstrum's real range (measured: 0.256 for the planning fixture — a >5x error), plus the same missing-dB-conversion bug with a twist: `cepstrum$as_data_frame()`'s second column is named `power_dB` (capital B) but is raw linear power (see `POWERCEPSTRUM_DB_MISLABEL.md` — this is the same defect that doc already tracked at other call sites, just not this one). Confirmed by comparing against `cepstrum$get_value_at_quefrency(q, unit = "dB")`, a *different* accessor on the same object that does return real dB — before the fix, the line trace and its own peak-prominence marker were plotted on incompatible scales (one linear, one log). Fixed by reading from the misleadingly-named `power_dB` source column and writing the converted value to a new, honestly-named `power_db` (lowercase) column — the capitalization difference is intentional, not a typo.
   - **Deliberately not fixed in this release** (documented, not silently dropped) — *all of these were subsequently fixed later in the same 5.0.4 dev cycle* (see `POWERCEPSTRUM_DB_MISLABEL.md` "Resolution" and the NEWS.md follow-up entries):
     - The C++-level column mislabel (`RPowerCepstrum::as_data_frame()`) is now renamed `power_dB` → `power`, and `autoplot.PowerCepstrum()`/`autolayer.PowerCepstrum()`/`plot.PowerCepstrum()` now read `power` and convert to dB.
     - `plot_powercepstrogram(show_cpp_contour = TRUE)` now overlays the real per-frame cepstral-peak quefrency (argmax of each frame's raster row), not a flat `quefrency = 0.01`.
     - `plot.Spectrogram()`'s dead `preemphasis` parameter was removed.
     - `plot_cpp_timeseries()`'s NaN subtitle now reads "No samples" when every sample fails.
  - **New test files**, both added with zero prior coverage on the functions they exercise: `tests/testthat/test-spectrogram-plot-regression.R` (5 tests), `tests/testthat/test-cepstrum-plots-regression.R` (7 tests).
  - Found while writing regression tests for `autoplot.Spectrogram()`/`autolayer.Spectrogram()` (part of a separate pass bringing `R/autoplot-methods.R`'s Sound/Pitch/Formant/Intensity/Spectrogram autoplot methods from 0% to 40% test coverage) — the frequency-axis-transposition bug surfaced there, and checking its siblings (`plot.Spectrogram()`, then the structurally similar `R/cepstrum_plots.R` functions) found the rest.
  - **Coverage denominator pinned (2026-08-19):** `covr::package_coverage()` instruments compiled code by default (`covr.gcov = Sys.which("gcov")`, set on covr load), so measured coverage is dominated by ~2.31M lines of vendored Praat DSP (`src/praat.github.io/`) plus bundled third-party FFTs (`src/pffft/`, `src/pocketfft/`) — 96% of the codebase, vs ~28k lines of R and ~60k lines of pladdrr-authored C++ wrappers. A 75% bar over the full denominator is unreachable and meaningless. Added `.covrignore` excluding those vendored trees so both pkgcheck and Codecov measure pladdrr-authored code only; the 27%→75% roadmap applies to that reduced, meaningful denominator.

## What's New in v5.0.3

- **v5.0.3 — Ltas full Praat-parity query coverage, new SpectrumTier peak-picking class (2026-08-14).**
  - **6 Ltas methods that already existed in the `RLtas` Rcpp module but were never reachable from R:** `get_value_in_bin(bin)`, `get_local_peak_height(environment_min, environment_max, peak_min, peak_max, unit)`, `get_standard_deviation(fmin, fmax, unit)`, `get_frequency_range()`, `to_matrix()` (returns a real `Matrix` object via the module's `to_matrix_ptr`, distinct from the existing `as_matrix()` which returns a plain R matrix), and `save(path)`. All were mechanical R-side wiring, matching Praat's Ltas "Query" and "Hack" menus — no new C++ needed.
  - **New `SpectrumTier` class** (`R/spectrumtier-wrapper.R`, `src/modules/spectrumtier_module.cpp`), wrapping Praat's `Ltas_to_SpectrumTier_peaks` (`fon/Ltas_to_SpectrumTier.cpp`), previously unwrapped anywhere in pladdrr. Read-only: it's peak-picking analysis output, not something a user constructs by hand. `ltas$to_spectrum_tier_peaks()` returns one; query methods (`get_number_of_points()`, `get_frequency_from_index()`, `get_value_at_index()`) and export (`as_data_frame()`, `as_matrix()`, `save()`) mirror the existing tier-wrapper pattern (e.g. `IntensityTier`). Corresponds to Praat's Ltas "Analyse > To SpectrumTier (peaks)".
  - **Build fix surfaced along the way:** `RcppExports.cpp` needs every Praat struct type used in an exported function signature forward-declared in `inst/include/pladdrr_types.h` (that's how the other ~30 wrapper types already do it) — `structSpectrumTier` was missing, which failed the compile with a real (not just the usual `-Wdelete-incomplete` warning noise) error until added.
  - **Deliberately not wrapped:** Praat's Ltas `Formula...` (R already gives full vector access via `as_data_frame()`/`as_matrix()`, which is strictly more capable than Praat's scripting mini-language) and `Combine > Merge` (`Ltases_merge`, not requested; `ltas_average()` already covers the "Combine" case that exists today). `Draw...` was already covered by `plot.Ltas()`/`autoplot.Ltas()`/`autolayer.Ltas()`.
  - **Documentation rewrite** for `?Ltas` and new `?SpectrumTier` following the `Sound`-reference doc convention (`inst/agents/DOCUMENTATION.md`): full `\itemize` method-list sections (Frequency domain, Query values, Batch queries, Trend and peaks, Export for Ltas; Query methods, Export for SpectrumTier), a shared "Units and interpolation" section explaining the `unit`/`interpolation` string codes once instead of repeating them per method, 90% usage-focused, humanized prose.
  - Praat module count reconciled 38→39 in `DESCRIPTION`'s `Description:` field and here, matching the new `spectrumtier_module.cpp`.

## What's New in v5.0.2

- **v5.0.2 — LongSound API expansion, save_part/save_channel crash fix, doc rewrite (2026-08-14).**
  - **New LongSound methods:** `get_dx()` (sampling period), `get_x1()` (time of first sample), `get_time_from_sample(sample)`/`get_sample_from_time(time)` (Sampled index/time conversion, matching Sound's existing convention), and package-level `longsound_get_buffer_size_pref_seconds()`/`longsound_set_buffer_size_pref_seconds()` (the global streaming-buffer-size preference, default 600 s).
  - **Fixed a real, pre-existing crash in `save_part()`/`save_channel()`.** Root cause: pladdrr's headless build stubs out Praat's `Preferences_add*` functions (no GUI, no prefs file), but the stubs were pure no-ops — they never set `*value = defaultValue`. `LongSound_open()` relies on `Preferences_addInteger` to seed its streaming buffer-length preference at 600 s; with the no-op stub it silently stayed at 0. That made `LongSound`'s internal read buffer exactly 1 sample wide, and the write-path arithmetic (`(n-1)/nmax`) computed nonsense instead of trapping — ARM64 doesn't fault on integer division by zero — so every `save_part()`/`save_channel()` call overflowed a 1-element buffer by up to the full sample count. The corruption didn't crash immediately; it surfaced later, nondeterministically, usually at an unrelated garbage-collection pass, which is why it went unnoticed (LongSound had zero test coverage before this release). Fixed in two places: `src/praat_stubs.cpp`'s four `Preferences_add{Integer,Real,Bool}`/`_Preferences_addEnum` stubs now set the default value (matching the real function's essential contract) while still skipping the inapplicable persistent-registry bookkeeping; `praat_initialize()` (`src/praat_wrapper.cpp`) now calls `LongSound_preferences()` explicitly at package load, matching what Praat's own startup sequence does for every object type. Verified with 15 consecutive repro runs (0 crashes) after the fix, versus a consistent ~50-70% crash rate before it — see `tests/testthat/test-longsound.R`.
  - **Architectural cleanup:** `save_part`/`save_channel` moved from standalone `Rcpp::export` functions into the `RLongSound` Rcpp module, matching every other query/streaming method. Removed 9 dead, unreachable `Rcpp::export` duplicates in `src/longsound_wrappers.cpp` (get_duration, get_start_time, get_end_time, get_sample_rate, get_number_of_channels, get_number_of_samples, get_file_path, extract_part, have_window, get_window_extrema) that duplicated the module's own methods but were never called from R.
  - **Documentation rewrite** for `?LongSound` following the `Sound`-reference doc convention (`inst/agents/DOCUMENTATION.md`): proper `\itemize` method-list sections (Query methods, Time/sample conversion, Streaming, Save, Utility), 90% usage-focused, humanized prose.

## What's New in v5.0.1

- **v5.0.1 — ggplot2 autoplot/autolayer coverage for all drawable Praat types (2026-08-12).**
  - Added `autoplot()` + `autolayer()` S3 methods for 27 previously unsupported classes: AmplitudeTier, DurationTier, IntensityTier, PitchTier, FormantTier (sampled), FormantGrid, FormantPath (candidate paths), Excitation, ComplexSpectrogram, Cepstrum (via PowerCepstrum), Cochleagram, PowerCepstrogram, MFCC, LFCC (wide-to-long reshape), BarkSpectrogram, MelSpectrogram, Matrix, PCA, Discriminant (scree/scores/both), FormantModeler, Electroglottogram, LongSound (streaming extract), DTW (warping path), Polygon, VocalTract, LPC (spectrum envelope), KlattGrid. All methods return ggplot2 objects compatible with `+ autolayer()` composition.
  - Added `as.data.frame()` S3 methods for 15 classes lacking data export: BarkSpectrogram, Cepstrum, Cochleagram, Discriminant, DTW, Electroglottogram, FormantModeler, KlattGrid, LPC, LongSound (errors with guidance), Matrix, MelSpectrogram, PCA, PowerCepstrogram, VocalTract.
  - Fixed `FormantGrid$as_data_frame()` pre-existing bug: C++ method `as_data_frame(time_step)` was called without the required argument, producing "could not find valid method". Now passes `time_step = 0.005`.
  - New files: `R/autoplot-missing.R`, `R/as-data-frame-missing.R`. NAMESPACE now registers 42 `as.data.frame`, 38 `autoplot`, 38 `autolayer` S3 methods.

## What's New in v5.0.0

- **v5.0.0 — Spectral-moments/data-frame memory rework; CRAN perf-claim sweep; full `man/` `\value`/`\examples` coverage (2026-08-07).**
  - **`get_spectral_moments_batch_cpp` no longer allocates a `Spectrum` per frame.** Centre of gravity, standard deviation, skewness, and kurtosis are now computed directly from the spectrogram's z-matrix in two fused passes — bit-exact, because `Spectrogram_to_Spectrum` sets `re=sqrt(z)`, `im=0`, so `sqr(re)+sqr(im) = z`; the intermediate Spectrum was pure overhead. Removes N per-frame allocations for an N-frame spectrogram (was the primary driver of `spectral_moments`' 897 MB peak per algobench). Numerically identical to prior versions — a memory/allocation change, not an algorithm change; no new timing number is claimed here. See `PRAAT_MODIFICATIONS.md`.
  - **`formant_as_data_frame`/`pitch_as_data_frame` pre-allocate output vectors.** `formant_as_data_frame` counts rows up front and allocates Rcpp vectors directly instead of `std::vector` push_back + copy; `pitch_as_data_frame` conditionally allocates the strength/intensity columns only when `include_strength`/`include_intensity` are requested, instead of always. Output unchanged.
  - **BREAKING for embedders reading `DESCRIPTION`/`README.md` for numbers: all absolute and relative performance claims removed** (including Parselmouth comparisons), per CRAN submission review. Historical changelog entries carrying benchmark data moved to `NEWS-archive.md`, which is excluded from the package tarball. `NEWS.md` is now claim-free by policy — this file and `PERFORMANCE_INVENTORY.md` remain the place for agent-facing perf detail, since neither ships as CRAN-facing prose.
  - **Praat module count reconciled 37→38** in `DESCRIPTION`'s `Description:` field, matching the actual number of exposed Rcpp modules under `src/modules/*.cpp`.
  - **Full `man/` `\value`/`\examples` coverage.** Added missing `@return`/`@examples` roxygen blocks across Tier 1 (R6 object classes), Tier 2 (conversion functions), and Tier 3 (batch-query functions) — four Tier 3 batches plus two follow-up bugfixes surfaced by writing runnable examples: `.pitchtier_unit_code`/`.table_to_data_frame` were referenced but never defined, and 0-row `Table` columns were misdetected as numeric. All fixed alongside the doc sweep.
  - **CRAN metadata hygiene:** added `URL`/`BugReports` fields; declared `methods`/`tools`/`utils`/`parallel`/`grid` as explicit `Imports`; un-excluded `NEWS.md` from the tarball (it was in `.Rbuildignore`, which would have hidden the changelog from CRAN's own listing).
  - Also fixed: a malformed comment in `batch_queries.cpp` that broke `Rcpp::compileAttributes()` — introduced while stripping perf claims from roxygen source, caught before it reached a release.

## What's New in v4.9.x

- **v4.9.24 — CRAN pre-submission fixes: two example errors, doc/link gaps, tarball hygiene, build-flags re-confirmed clean (2026-08-06).**
  - **Two stale-arg-name example errors that would have failed CRAN's automated check.** `Harmonicity.Rd` called `to_harmonicity_cc(minimum_pitch = 75)`; the real parameter is `min_pitch`. `Spectrogram.Rd` called `to_spectrogram(maximum_frequency = 5000)`; the real parameter is `max_frequency` (unlike `to_complex_spectrogram()`/`to_powercepstrogram()`, which do use `maximum_frequency` — don't assume consistency across sibling functions). `R CMD check` only reports the *first* example failure per run; found the second only after fixing the first and re-running against a clean tarball, then swept all 370 `man/*.Rd` pages against the installed package with `tools::Rd_db()` + `tools::Rd2ex()` to confirm no others remain.
  - **8 `*_simd_bridge` functions were exported but undocumented again** (`src/batch_queries_simd_bridge.cpp`) — same failure mode as v4.9.14, this time from Doxygen-style `/** */` blocks that roxygen2 doesn't parse (only the `//' @export` line was roxygen syntax, so `@title`/`@description` never made it into the Rd). Converted to `//'`-prefixed roxygen comments with `@keywords internal`, kept `@export` (covered by `tests/testthat/test-phase3-batch-queries-simd.R`, which calls them by bare name).
  - **Dangling `\link{TableOfReal}` removed** from `PCA.Rd`/`Discriminant.Rd` `@seealso` — no such doc topic exists in pladdrr's public API (Rd cross-reference WARNING).
  - **`textgrid_filter_xptr.Rd` "Lost braces" NOTE fixed** — an embedded C++ predicate signature in the `@details` markdown fence had unescaped `{`/`}`; escaped to `\{`/`\}`. (Package doesn't set `Roxygen: list(markdown = TRUE)`, so fenced code blocks pass through as literal Rd text rather than `\preformatted{}` — that's a separate, lower-priority cosmetic gap: `**bold**`/backtick markdown shows up literally in several other Rd pages too.)
  - **`.pi/` (unrelated local tool state, untracked) was leaking into the source tarball** — added to `.Rbuildignore`.
  - **`LICENSE.note`'s GSL entry was stale since the v4.9.5 slimming**: it still described GSL as vendored at `src/gsl-2.8/` with license text there; that directory has been empty (dynamic linking via `configure`/`gsl-config` only) since v4.9.5. Corrected the note and removed the empty `src/gsl-2.8/`, `src/gsl_build/` placeholder dirs. `AGENT_GUIDE.md`'s own GSL section (below) was already accurate — only the license note had drifted.
  - **`DESCRIPTION` cleanup:** dropped a changelog-style sentence from `Description:` (CRAN reviewers push back on version-history text there) and the redundant, stale manual `Author:`/`Maintainer:` fields (`Authors@R` already supplies both; R regenerates them at build time regardless).
  - **Re-confirmed the v4.9.22 build-flags finding from the CRAN-check side, not just codegen.** A clean-tarball `R CMD check --as-cran` with only this machine's local toolchain path-fixes applied (no `-O3`/`-march=native`, no optimisation override at all) installed and checked with **0 install/check errors** — pladdrr's own `Makevars`/`Makevars.in` are genuinely portable; the `-march=native` NOTE seen in earlier ad hoc local checks was 100% `~/.R/Makevars` (a personal, non-CRAN file), never the package's own build config.
  - Full before/after: 1 ERROR, 6 WARNINGs, 7 NOTEs → 0 ERRORs, 4 WARNINGs, 4 NOTEs (all four remaining are the ones already justified in `cran-comments.md`: `-ffp-contract=off`, residual vendored `stderr`/`stdout`/`_exit` symbols, installed size, outdated macOS HTML Tidy).

- **v4.9.22 — the CPPS-vs-Praat gap was a debug build, not code. This closes the "Still open" item in the v4.9.21 entry below and invalidates the build-flag advice in the v4.9.15 entry. Read it before benchmarking anything.**
  - **A `.so` compiled without `NDEBUG` costs 2.1–7.0x across the whole package.** `pkgbuild::compile_dll()` — i.e. `devtools::load_all()` — forces `-UNDEBUG -Wall -pedantic -g -O0`. A later `R CMD INSTALL` **does not** fix it: `make` sees the `.o` files as current and only relinks, so the installed package stays unoptimised with no outward sign. This is what every pladdrr-vs-Praat/parselmouth timing before 2026-08-05 was measured against.
  - **How to recognise it in a profile.** `sample` the R process and look for `constvector<double>::operator[]`, `DYLD-STUB$$constvector<double>::operator[]`, `ninther`, `medianIndex` or `std::swap<double>` as top-of-stack entries. All of them are inlined in the Praat 6.4.47 binary; if they appear, the build is bad. In the disassembly, `getSlope_Siegel` is 186 instructions calling `operator[]` through PLT stubs 4x per inner iteration, and calls `Melder_assert_` — a live `Melder_assert_` call *proves* `NDEBUG` was absent. A good build is 82–87 instructions with 3–4 calls.
  - **Detection is now built in.** `simd_info()$debug_build` is `TRUE` on such a build and `library(pladdrr)` prints a NOTE. **Never benchmark after `load_all()`; rebuild with `R CMD INSTALL --preclean .`.**
  - **Effect of the rebuild alone (no source change), downstream plabench, 15/15 three-way Praat-parity tests byte-identical:** CPPS 3.72s→0.91s, AVQI v2.03 2.65→0.84, AVQI v3.01 2.61→0.83, VQ 1.97→0.46, DSI 0.28→0.06, VUV 0.110→0.020, pharyngeal 0.126→0.023, intensity 0.014→0.002, spectral moments 0.043→0.011, CPP 2.06→0.96, pitch 0.075→0.025, formant 0.099→0.030, voice report 0.088→0.019, PraatSauce 0.296→0.095, dysprosody 7.81→3.46. R goes from losing 9 of 14 to winning 11 of 15, and now matches the Praat 6.4.47 binary on the identical `Get CPPS` call (0.95–1.08s vs 0.95–1.04s).
  - **⚠️ Supersedes v4.9.15's "`-O3 -march=native` yields 3–7x".** That 3–7x was the debug-build penalty, misattributed. Measured properly — two interleaved clean rebuilds, 6 timed reps each, machine settled after each build — CPPS min is **0.922/0.853s at CRAN `-O2`** vs **0.868/0.870s at `-O3 -march=native`**: indistinguishable. Codegen agrees: `SlopeSelector.cpp` produces a **byte-identical object** at `-O2`, `-O3` and `-O3 -march=native` (87144 / 89232 bytes; `getSlope_Siegel` 82 vs 87 instructions, quickselect chain already fully inlined at `-O2`). `-fvisibility-inlines-hidden` is likewise a no-op. **CRAN's stock `-O2` is full speed. Do not tell embedders to use custom flags.**
  - **Where CPPS time actually goes, on an optimised build.** ~**84%** is Praat's median-of-ninthers quickselect (`expandPartition` 19729, `medianOfNinthers` 10404, `adaptiveQuickselect` 9280, `NUMquantile_e` 3987 samples); the Siegel pairwise-division loop is **~16%** (8351). FFT, cepstrogram creation and smoothing are each <1%. The v4.9.21 note that "~94% of `getSlope_Siegel` is median selection" was directionally right but measured on the debug build — use these numbers. Any future SIMD work must target `NUMquantile_e`; re-measuring `PLADDRR_ENABLE_SLOPESELECTOR_SIMD=1` interleaved (3 pairs x 6 reps) put it within noise, so it stays off.
  - **Threading has no headroom either.** CPPS 1→10 threads: 8.42s → 1.55s (**5.4x**); 8 threads already gives 5.39x, so the M1 Pro's two efficiency cores contribute ~1% and a dynamic scheduler is not worth adding. Amdahl serial fraction ≈7%. The Praat binary's own parallel efficiency on the same workload is 4.85 effective cores (32.32s user / 6.67s wall over 5 runs) — *below* pladdrr's. The v4.9.x suspicion that thread QoS on Apple Silicon was costing us is dead.

- **v4.9.20 — `Formant$as_data_frame()` shape fixed (build.log triage). Read this before writing any code that consumes `as.data.frame(formant_object)`.**
  - **BREAKING: `Formant$as_data_frame()` / `as.data.frame.Formant()` now return long format** — one row per (frame, formant number), columns `time`, `formant`, `frequency`, `bandwidth` — instead of a wide `time, F1, B1, F2, B2, ...` layout. This matches `FormantPath$as_data_frame()`, which was already long format; `Formant`'s wide layout was the one thing in the package out of sync with its own tests. If you have code reading `$F1`/`$F2`/`$B1` off a `Formant` data frame, it will now get `NULL`. Filter instead: `df$frequency[df$formant == 1]`.
  - **`df[cond, "colname"]` does not drop to a vector on a `data.table`** the way it does on a base `data.frame` — it returns a one-column `data.table`, and `mean()` on that silently returns `NA` with a warning rather than erroring. Every pladdrr `as_data_frame()` returns a `data.table`. Always write `df$colname[cond]`, never `df[cond, "colname"]`, when extracting a single column by name — this bit three vignettes (`analysis-resynthesis-workflow.Rmd`, `formantpath-robust-tracking.Rmd`, `speech-synthesis-klattgrid.Rmd`) and would not have shown up as an R CMD check ERROR, only a silently wrong NA.
  - `plot.Formant()` and `plot_spectrogram_formants()` (`R/plotting-methods.R`, `R/plotting-combined.R`) were independently broken before this release, filtering on `formant_number`/`frequency_hz` — columns that existed in neither the old wide format nor the new long one. Fixed alongside.
  - `autoplot.Formant()`/`autolayer.Formant()` no longer reshape internally; the data is long already.

- **v4.9.19 — assessment follow-up (see `dev/ASSESSMENT_2026-08-05.md`). Read this before writing CPPS, spectrogram or formant code.**
  - **BREAKING: `calculate_cpps_ultra(fused = )` removed.** It was added in v4.9.18 and was wrong: it reused the trend fitted on the *raw* cepstrum as the baseline for the peak measured on the *smoothed, trend-subtracted* cepstrum. Praat fits twice deliberately (`PowerCepstrogram_subtractTrend`, then again inside `PowerCepstrogram_to_Matrix_CPP`). Result was **-47.169 dB where the correct value is 9.9205 dB**, and 3.1x slower. Do not reintroduce this "optimisation".
  - **`Spectrogram$get_power_at()` semantics changed to match Praat.** It performed a nearest-cell lookup; Praat's "Get power at (time, frequency)" is `Matrix_getValueAtXY`, i.e. **bilinear interpolation**. Old results differed from Praat by up to ~24% at a point, and disagreed with the same class's `get_power_at_points()`, which was always correct. Out-of-domain queries now return `NA` instead of a clamped edge cell. **Any stored spectrogram point values computed before v4.9.19 are wrong.**
  - **`Formant$get_value_at_time()` returns `NA` for non-finite `time`** instead of raising "Failed to get formant value at time". A `NaN` in an upstream time vector no longer aborts the whole query.
  - **`to_formant_keepall/willems/sl()` accept `time_step = 0` again.** Praat means "auto" (= `window_length / 4`) by 0 everywhere; rejecting it made a documented Praat idiom unusable. Use `.check_time_step()`, not `.check_positive_number()`, for any new time-step argument.
  - **`get_pitch_strengths_at_times()` fixed** — it errored with `object 'unit_code' not found` (regression from the v4.9.18 unit-code refactor).
  - **Reversed quefrency ranges now error.** `calculate_cpps_fast(qstart_fit = 0.04, qend_fit = 0.003)` used to return a silently different measurement. `qend = 0` still means "autowindow the full range" (Praat convention).
  - **`fit_method = "robust slow"` warns once per session.** Praat's Theil-Sen trend fit samples randomly and **is not reproducible**: ~0.8 dB spread across identical runs, and Praat itself occasionally returns values around 1e290. This is an upstream Praat defect that pladdrr reproduces faithfully. Never use it for anything that must be reproducible; prefer `"robust"` (Siegel, deterministic) or `"least_squares"`.
  - **CPPS defaults are documented as deviating from Praat's.** pladdrr follows the AVQI/clinical convention in 5 of 11 parameters (`time_averaging_window`, `pitch_ceiling`, `qstart_fit`, `qend_fit`, `trend_line_type`, `fit_method`). On a 1 s signal the two parameter sets give 9.92 dB and 4.82 dB — a different measurement, not rounding. See the table in `?calculate_cpps_fast`. **To reproduce a Praat run, pass Praat's values explicitly.**
  - **Faithfulness registry: 10 -> 14 routines, all passing.** Four v4.9.18 additions could not run (malformed oracle scripts, a nonexistent method name, an unachievable tolerance); repaired. New coverage: harmonicity, spectrogram, jitter, MFCC. Tests no longer write into the source tree — reports go to `tempdir()` unless `PLADDRR_FAITHFULNESS_OUTDIR` is set.
  - **SIMD batch bridges no longer copy their input** (`src/batch_queries_simd_bridge.cpp`): they pass `values.begin() - 1` to the 1-based kernels. vs base R on 1e6 doubles: mean 0.87x -> **4.1x**, sd 1.10x -> **2.8x**, range 2.33x -> **15.4x**, quantile 0.47x -> **1.8x**. `src/simd_bridge.h` is **dead** — included by no translation unit; do not "fix" bridges there.
  - **Do not try `std::nth_element` in `getSlope_Siegel`.** Measured: bit-exact but **25% slower** than Praat's median-of-ninthers, because Siegel slopes are clustered. See `PRAAT_MODIFICATIONS.md` v4.9.19.
  - Deleted 6 unreferenced `*_simd.cpp` files (1,174 lines); fixed the platform thread-count formula for Windows/Linux; corrected the FLAC/MP3 documentation (they go through the suggested `av` package, **not** natively).

- **v4.9.21 — SlopeSelector SIMD default flipped OFF. This supersedes the v4.9.15 entry below; read it before touching CPPS performance.**
  - **`should_use_simd_for_slopeselector()` now returns `false` by default** (`src/slopeselector_simd.cpp`). The v4.9.15 "~25% faster" claim did not survive re-measurement against the real CPPS workload. M1 Pro, `ppq1.wav`, Praat-script parameter profile, `-O3 -march=native`, clean rebuild: `calculate_cpps_ultra` **4.06s wall / 31.2s CPU with SIMD vs 2.35s / 17.6s scalar**; AVQI v2.03 (R) **6.87s vs 2.84s**. Output bit-identical both ways (CPPS 19.36722538 dB, AVQI 3.471873) — it bought nothing and cost 1.7–2.4x.
  - **Why it lost, so nobody re-tries it:** `sample` profiling puts ~94% of `getSlope_Siegel` in the median selection (`num::NUMquantile_e` → `adaptiveQuickselect`), not in the divides. The kernels vectorize the other ~6%, and as out-of-line `extern "C"` calls they lose cross-TU inlining while NEON f64 divide has no throughput edge over scalar `fdiv` on Apple silicon. **Any future SIMD work on this fit must target `NUMquantile_e`.** `PLADDRR_ENABLE_SLOPESELECTOR_SIMD=1` still forces the old path, for A/B only.
  - Downstream: plabench R CPP benchmark **3.56s → 2.20s**, R AVQI v2.03 ~**4.26s → 2.8s**, values unchanged.
  - ~~**Still open:** with SIMD off, pladdrr's serial CPPS work is ~16.8s CPU vs the Praat 6.4.47 binary's ~6.6s for the identical upstream algorithm, same n (491 fit points) and frame count (1410). Ruled out: n, frame count, fit method, optimisation level, thread count, bounds checks. Build/binary level, not yet root-caused.~~ **CLOSED in v4.9.22 — it was a `-O0`/`-UNDEBUG` build, see the v4.9.22 entry above.** The "optimisation level ruled out" step was the wrong one: `~/.R/Makevars` did request `-O3`, but the `.o` files predating it were never recompiled, because changing `~/.R/Makevars` does not make anything stale.

- **v4.9.15 — CPPS slopeselector SIMD gate + stale-binary caveat + build-flag guidance (downstream perf assessment 2026-07-31):**
  - **`should_use_simd_for_slopeselector()` now honors two env knobs** (`src/slopeselector_simd.cpp`): `PLADDRR_DISABLE_SLOPESELECTOR_SIMD=1` forces scalar, `PLADDRR_ENABLE_SLOPESELECTOR_SIMD=1` forces SIMD. ~~Default stays **ON**~~ — **superseded by v4.9.21: the default is now OFF and the "~25% faster on a clean build" claim below is wrong.** It was measured on the short `ppq1` case only; on the full CPPS workload the SIMD path is 1.7–2.4x *slower* with identical output.
  - **⚠️ Stale-binary trap (root-caused downstream).** A released `.so` can carry a **mis-optimized `slopeselector_simd.o`** that is ~2× *slower* than a clean recompile of identical source (observed SIMD 2.14s vs 0.92s; CPP tool 3.63s vs 1.55s; AVQI 4.53s vs 0.69s). ~~Do NOT reflexively gate SIMD off on arm64.~~ **Superseded by v4.9.21:** the "clean rebuild fixes it" reading was wrong — a clean rebuild still leaves the SIMD path slower than scalar, so the 2.14s-vs-0.92s spread was the SIMD/scalar difference, not a stale object. The remaining useful part of this note is that the scalar path is stable across builds; if CPPS/AVQI timing regresses, still rebuild clean (`R CMD INSTALL --preclean .`) before suspecting the algorithm.
  - **Long-signal CPPS regression guard** added to `inst/benchmarks/18_cpps_ultra_performance.R`: the per-frame Siegel trend fit only dominates on many-frame (long) signals, so the short `ppq1` case alone hid the stale-object slowdown. New case concatenates `ppq1` ~8× and times it; compare across versions/arches (a >20% jump = trend-fit regression).
  - ~~**Build-flag guidance for non-CRAN consumers.** ... `-O3 -march=native` ... yields **3–7× on nearly every routine**~~ — **WRONG, superseded by v4.9.22.** The 3–7× was the debug-build penalty (`-UNDEBUG -O0` objects left behind by `devtools::load_all()`), not the optimisation level. `-O2` and `-O3 -march=native` are indistinguishable on this code and produce byte-identical objects for the hot translation unit. The one accurate part of this note survives: `CXX17FLAGS` is the variable R applies to `CXX_STD=CXX17` TUs (not `CXXFLAGS`), so a `~/.R/Makevars` that sets only `CXXFLAGS` silently does nothing here. **CRAN's `-O2` is full speed; recommend no custom flags.**

- **v4.9.9 — optimization follow-ups from the 2026-07 assessment:** added public `pladdrr_simd(enabled = NULL)` for runtime SIMD A/B checks; `PowerCepstrum$get_peak_prominence()` now accepts the Praat-style trend-fit argument without coercion warnings; documented the measured arm64 reality that pitch gets little SIMD help while cepstrogram/CPPS gets a modest gain, so threading remains the main speed lever. Also clarified when to use single-interval CPP (`Spectrum -> PowerCepstrum`) versus smoothed CPPS (`PowerCepstrogram` helpers), and added the reusable `build_multiband_harmonicity()` + `multiband_hnr_stats()` path for repeated-interval VQ workflows.

- **Unreleased (branch `cran-warnings-fix`) — CRAN build fixes + wrapper alignment:** `Makevars.win` now defines `UNICODE`/`_UNICODE` (Praat calls generic Win32 macros with wide buffers; without it they resolve to `...A` variants and fail on mingw) and `_FILE_OFFSET_BITS=64`, and drops the stale `-Iclapack/INCLUDE`; `r_lapack_wrapper.cpp` opts in to `USE_FC_LEN_T` (R-devel FCLEN compatibility); `-D_LIBCPP_DISABLE_DEPRECATION_WARNINGS` added to `PKG_CPPFLAGS` (silences C++17 allocator deprecations from RcppXsimd under `--as-cran`; inert on libstdc++). New methods: `formantgrid$to_sound()` (KlattGrid-style synthesis from formant tracks) and `cochleagram$get_loudness_at_time()`. Fixes: `to_formant_keepall/willems/sl()` now validate `time_step`/`max_frequency`/`window_length` at R level; `PraatInterpreter$set_object()` extracts `.xptr` from current S3 wrappers (was calling the removed R6 `get_ptr()`); `matrix$as_matrix()` calls the correct `.matrix_to_r_matrix()` export.

- **v4.9.6 — CRAN compliance:** (1) **XPtr finalizer bug fixed** — module wrappers built pointers as `XPtr<T>(ptr, lambda)`, where the lambda silently bound Rcpp's `bool set_delete_finalizer` overload, so Praat objects were freed with `delete` instead of `forget()`. All construction now goes through `make_praat_xptr()` / `make_praat_xptr_from_auto()` (`src/praat_xptr_utils.h`), which register the finalizer explicitly via `R_RegisterCFinalizerEx`. **Never construct `XPtr<T>(ptr, deleter)` in new code.** (2) All `-Wno-*` warning suppressions removed from `Makevars`; `-ffp-contract=off` kept (required for bit-exact fidelity with Praat). (3) Vendored Praat patched so compiled code no longer calls `abort()`/`_Exit()` — assertions/fatals now throw and propagate to R as errors; `-Wunsequenced`/`-Wswitch` warnings fixed. (4) R-level cleanups: 147 internal `.Call` wrappers `@noRd`, `globalVariables` declared, non-ASCII removed.

- **v4.9.5 — Source tarball slimmed 52 MB → 9 MB (no behaviour change):** the duplicate `src/praat/` tree (~107 MB, formerly the Windows build prefix) was **removed** — Windows now compiles from the same `praat.github.io/` prefix as Unix. Bundled external-library sources (espeak, flac, mp3, portaudio, vorbis, opusfile, lame, clapack, gsl, glpk) excluded from the tarball (stubbed at build time; only referenced headers kept). Any doc or script that references `src/praat/...` paths is stale.

- **v4.9.4 — Nested-parallelism fix + lazy module load:** batch helpers (`analyze_files_parallel()`, `process_sounds_parallel()`, `batch_process()`) cap each parallel worker's C++ thread count so N R workers no longer spawn ~N² threads; new `threads_per_worker` argument (`NULL` = auto-divide, `1` = single-threaded workers). `PowerCepstrogram_smooth_fast` honours the `pladdrr_threads()` cap instead of always using all cores. Modules load lazily on first use instead of all ~38 eagerly in `.onLoad`. Numeric output unchanged.

- **v4.9.3 — Willems/split-Levinson crash fixed:** `Sound$to_formant_willems()` and `to_formant_sl()` no longer segfault on pure tones or silence. Root cause was a null console stream in the embedded build (`MelderConsole::write` → `fputc(NULL)`); guarded to fall back to libc `stderr`/`stdout` (see `PRAAT_MODIFICATIONS.md` v4.9.3). Formant values are unchanged. Both methods now reject `number_of_formants`/`number_of_poles < 1` with a clear R-level error. Also fixed `sound_extract_parts()` (was passing a dead R6 private pointer → NULL; now uses `$.xptr`).
- **v4.9.2 — Thread control:** `pladdrr_threads(n)` caps or disables Praat's multi-threaded analyses at runtime. `pladdrr_threads(1)` forces single-threaded (use inside `parallel::mclapply()` workers so cores aren't oversubscribed); `pladdrr_threads(0)` restores automatic (all cores); `pladdrr_threads()` with no argument returns the current state (`processors`, `enabled`, `max_threads`, `min_elements_per_thread`). Threading never changes results — threads only partition analysis frames.

- **v4.9.2 — Data-loss policy:** `options(pladdrr.data_loss=)` controls how routines that return NA for undefined values react: `"warn"` (default, classed warning per incident), `"error"` (stop at first incident), `"silent"` (only attach `attr(., "pladdrr_data_loss")`). Set `"error"` in batch pipelines where silent NA truncation would corrupt aggregates.

- **v4.9.2 — Input validation:** `Sound$to_pitch*/to_manipulation/to_ltas_pitch_corrected/change_speaker/to_point_process_periodic_*` now reject `pitch_floor <= 0` or `pitch_ceiling <= pitch_floor` with a clear R-level error instead of a generic "Failed to create ..." from C++.

- **v4.9.2 — CPPS profiles:** the three CPPS parameter sets are now centralized in `R/constants.R` (`.cpps_profiles$r6`, `$avqi`, `$praat_gui`). `PowerCepstrogram$get_cpps()`/`calculate_cpps_fast()`/`calculate_cpps_ultra()` use the **r6** profile (0.001 s smoothing, ceiling 333.3 Hz); `get_cpps_fast()` uses the **avqi** profile (Maryn & Weenink: `subtract_tilt=FALSE`, 0.01/0.001 smoothing, ceiling 330 Hz). Neither equals the Praat GUI form defaults (**praat_gui**), which pladdrr reproduces exactly only when those values are passed explicitly. `test-cpps-defaults.R` fails if any signature drifts from its profile.

- **v4.9.2 — Perf (no fidelity change):** eliminated redundant per-interval `Data_copy(sound)` in TextGrid interval extraction and concatenation paths (`sound_wrappers.cpp`, `textgrid_wrappers.cpp`, `batch_queries.cpp`) — inputs are now referenced or moved rather than deep-copied. `extract_measurements()` now pulls all formant numbers in a single `formant_get_multiple_formants_at_times()` call.

- **v4.9.1 — PERF-1:** `get_spectral_moments_batch(spectrogram, power=2.0)` — new API returns a `data.frame(time, cog, sd, skewness, kurtosis)` for every frame in a single C++ pass. Eliminates the 14× R-loop penalty (400 per-frame `autoSpectrum` allocations + 1600 R→C++ boundary crossings per file). Available as standalone function and as `spectrogram$get_spectral_moments_batch()`. See [Pattern 2p](#pattern-2p-spectral-moments-batch-v491).

- **v4.9.1 — BUG-2:** Parabolic peak interpolation in `NUMimproveExtremum()` (`praat.github.io/melder/NUMinterpol.cpp`) now guards against division by near-zero `d2y` (flat or concave-up peak) and clamps `|offset| ≥ 1.0` (parabola cannot extrapolate beyond one bin). Fixes 500–1200 dB physically impossible values from `ltas$get_peaks_batch(interpolation="parabolic")`. Both `praat.github.io/` (macOS/Linux) and `praat/` (Windows) copies patched. See [Pitfall 13](#13-parabolic-interpolation-with-flat-ltas-peaks-fixed-v491).

- **v4.9.1 — BUG-1:** Burg LPC formant extraction on short windows (≤100ms) now has a Laguerre-method fallback (`src/polynomial_roots_laguerre.h`) that activates when LAPACK `dhseqr_` fails to converge on all eigenvalues of the ill-conditioned companion matrix. Before this fix: F1 r=0.57, F2 r=0.38 vs Praat on 40ms windows; Python/Parselmouth achieved r>0.9999 on the same algorithm, confirming the bug was in pladdrr alone. Normal long-window audio is unaffected. See [Pitfall 14](#14-short-window-formant-extraction-fixed-v491).

- **v4.9.1 — API-1:** `to_ltas_direct()` now returns a wrapped `Ltas` object, consistent with every other `*_direct()` constructor. Previously returned a raw `externalptr`, making it unusable without `Ltas(.xptr = to_ltas_direct(snd, bw))`. See [Pitfall 15](#15-to_ltas_direct-returned-raw-externalptr-fixed-v491).

---

## What's New in v4.8.x

- **v4.8.35:** SPINET gammatone arg-swap fix in `src/praat.github.io/fon/Sound_to_SPINET.cpp`. `Sound_createGammaTone(...)` was called with `b=1.02` (ERB bandwidth constant) as frequency and `f[i]` as bandwidth — every filter was built at 1.02 Hz, so SPINET output was all zero on real speech and `SPINET_to_Pitch` aborted with *"The sound should not have all amplitudes equal to zero."* Corrected to `frequency=f[i]`, `bandwidth=bw[i]/NUM2pi` (bw already encodes `2π·b·ERB(f)`). Logged in `inst/agents/PRAAT_MODIFICATIONS.md` v4.8.35.

- **v4.8.34:** SHS and SPINET pitch methods across all 3 API tiers. Tier 1: `sound$to_pitch_shs()`, `sound$to_pitch_spinet()`. Tier 2: `to_pitch_shs_direct()`, `to_pitch_spinet_direct()`. Tier 3: `sound_to_pitch_shs_batch()`, `sound_to_pitch_spinet_batch()`. Compiles 4 new Praat sources (`Sound_to_Pitch2.cpp`, `SPINET.cpp`, `Sound_to_SPINET.cpp`, `SPINET_to_Pitch.cpp`) plus extracted helper functions (`Sound_createGammaTone`, `Sound_power`, `Sound_correlateParts`, `Sound_localPeak`) in `sound_create_gaussian.cpp`. Build system updated (`Makevars.in`, `Makevars`, `Makevars.win`).

- **v4.8.33:** All 35 wrappers ported to shared dispatch table pattern. Every wrapper (34 new + Sound from v4.8.32) now uses a shared `.{type}_methods` environment + `$.Type` S3 dispatch instead of per-instance closures. Zero new test regressions. Eliminates ~832 closure definitions across the codebase. Also: added `is_valid` method to 22 wrappers that lost it during porting, fixed `cochleagram$as_matrix()` return type (was trying `mat_list$values` on plain matrix), fixed `cepstrum$to_sound()` R6 call `Sound$new(xptr)` → `Sound(.xptr = xptr)`, added `@method $ Type` roxygen tags to 13 files, bumped NAMESPACE to 44 `S3method("$", ...)` entries.

- **v4.8.32:** Sound shared dispatch table + critical bugfixes. (1) `sound-wrapper.R`: replaced per-instance closure list (~107 closures/object, ~120KB) with shared `.sound_methods` environment + `$.Sound` S3 dispatch. Creation 9x faster (23μs→2.6μs), memory 160x less (120KB→0.7KB). Method call ~2.5x slower per-call (0.4μs→1.0μs), negligible vs Praat computation. (2) `module_init.cpp`/`RcppExports.cpp`: fixed `R_registerRoutines` overwrite bug — the `[[Rcpp::init]]` hook was calling `R_registerRoutines` a second time with only 38 module entries, replacing the 777 Rcpp-exported entries. Now builds a combined table (777 + 38 = 815 entries) in a single registration call. This was breaking package load since v4.8.30 (Phase 1 commit `d99be82`). (3) `Makevars.in`: added missing `simd_utils.cpp` — the `configure` script generates `src/Makevars` from `src/Makevars.in` on every install, so fixing `Makevars` directly never persisted. (4) `NAMESPACE`: registered `S3method("$", Sound)` for shared dispatch.

- **v4.8.31:** Phase 2 performance fixes — (1) `vad.R` `textgrid_get_intervals_where()`: replaced O(n²) vector growth (`c(x, val)` in loop) with pre-allocated vectors + counter + trim, (2) `textgrid-wrapper.R` `get_all_points()`: removed duplicate slow R-loop definition (line 409) that shadowed fast C++ version (line 300) due to R list duplicate-name semantics; fast version now uses `tier = 1L` default, (3) `batch-processing.R` `extract_measurements()`: replaced per-interval `lapply` with O(n) R→C++ calls with vectorized batch C++ calls — `textgrid_interval_statistics_batch()` for all intervals, `.pitch_get_values_at_times()` / `.formant_get_values_at_times()` / `.intensity_get_values_at_times()` for measurements; reduces ~10n R→C++ boundary crossings to ~(3 + max_formants) total calls.
- **v4.8.30:** `Sound_to_Pitch.cpp`: SIMD optimizations re-enabled for FCC path — Fixes 1-5 (local mean, sum of squares, DC removal, local peak, batched `xsimd::sqrt` normalization over lags). Fixes earlier comment contradiction on `compute_local_mean_simd_bridge` (bridge returns mean, not sum). `Sound_to_Harmonicity_GNE.cpp`: Loop B (50-band Hilbert envelopes) and Loop C (1225-pair cross-correlation matrix) both parallelized via `MelderThread_PARALLELIZE`; upper-triangle pairs flattened into a linear index for even thread distribution.
- **v4.8.29:** Critical performance regression fixes and HNR accuracy fix. Pitch CC and HNR: removed broken `#ifdef HAVE_XSIMD` blocks in `Sound_to_Pitch.cpp` — the FCC SIMD block allocated 2 heap vectors per pitch frame causing ~29× slowdown; the AC SIMD block had a brace bug that closed the channel loop prematurely (breaking stereo) and added non-inlined call overhead. Both revert to scalar loops that auto-vectorize under `-O3`. GNE: raised `MelderThread_PARALLELIZE` threshold 1→4 to cut allocator contention. `get_voice_quality_ultra(..., metrics="hnr")`: HNR now uses Praat's standard minimum pitch 75 Hz / time step 0.01 s instead of the caller's `min_pitch`; fixes ~1.31 dB underestimation in AVQI pipeline.
- **v4.8.27/4.8.28:** Internal C++ performance optimizations (later found to regress — see v4.8.29). `Sound$to_harmonicity_gne()`: Loop B/C parallelized via `MelderThread_PARALLELIZE`. `sound$to_pitch_cc()`: batched `xsimd::sqrt` normalization (Fix 5). Both superseded/reverted by v4.8.29.
- **v4.8.26:** Tier 3 audio additions: `Sound$change_speaker()`, `Sound$change_speaker_with_pitch()` (PSOLA-based speaker transformation — formant + pitch + duration multipliers), `sound_create_pure_tone()` / `Sound$create_pure_tone()` (pure tone with fades), `sound_create_tone_complex()` / `Sound$create_tone_complex()` (harmonic complex tone), `Spectrum$shift_frequencies()` (frequency shift with interpolation). See Pattern 2o for usage.
- **v4.8.25:** Advanced audio analysis methods (Tier 1): `Sound$lengthen()` (overlap-add time-stretch), `Sound$to_ltas_pitch_corrected()` (voice quality LTAS), `Sound$to_formant_robust()` (outlier-resistant formants), `Sound$filter_by_formant[_noscale]()` (formant filtering), `Sound$to_mel_spectrogram()`, `Sound$to_bark_spectrogram()` (psychoacoustic spectrograms). New wrappers: `MelSpectrogram`, `BarkSpectrogram` with `to_mfcc()`, `to_matrix()`, `to_intensity()`. Extended Tier 2 methods: `Sound$autocorrelate()`, `Sound$deepen_band_modulation()`, `Sound$convolve()`, `Sound$cross_correlate()`, `MFCC$to_mel_spectrogram()`, `LPC$to_spectrogram()`, `PointProcess$to_sound_pulse_train()`, `PointProcess$to_sound_hum()`, `Intensity$to_textgrid_silences()`, `Table$sort_rows()`, `Table$extract_rows_where_[number|string]()`, `ltas_average()`. See Pattern 2n for usage.
- **v4.8.24:** Convenience methods: `ltas$get_spectral_slope()`, `formant$get_all_values_at_time()`. New AGENT_GUIDE Pattern 2m (Prosodic Analysis Workflows) and Use Case 5 (Prosodic Feature Extraction)
- **v4.8.23:** Doc/code default fixes (CPPS), AGENT_GUIDE reorganization (TOC, changelog moved to end), `plot.TextGrid`, `as.data.frame` for PointProcess/TextGrid/MFCC/LFCC, `interpolation` alias on `get_intensity_at_times()`, removed leaked `sound_as_matrix_fast_impl` export (was `sound_as_matrix_zerocopy_impl`)
- **v4.8.22:** NaN/NA input guards on all query methods, Intensity batch queries, Formant/Spectrogram API additions
- **v4.8.20:** Spectrogram segfault fix (thread-unsafe R API in SIMD check)
- **v4.8.19:** xsimd v8+ compatibility for all SIMD files
- **v4.8.15:** XPtr memory corruption fix across 123 methods
- **v4.8.14:** Multi-threaded PowerCepstrogram (MelderThread_PARALLELIZE)

See [Full Changelog](#full-changelog-recent-changes) at end of file.

---

## Table of Contents

- [Quick Start for Agents](#quick-start-for-agents)
- [Architecture Overview](#architecture-overview-current-shared-dispatch--4-tier-performance-api)
- [Object Types](#object-types)
- [Unit Code Reference](#unit-code-reference)
- [Common Patterns](#common-patterns)
- [**Re-implementing a Praat Procedure**](#re-implementing-a-praat-procedure) ← start here for new ports
- [Utility Functions](#utility-functions)
- [Method Signatures](#method-signatures)
- [Validation Patterns](#validation-patterns)
- [Common Pitfalls](#common-pitfalls)
- [Deprecated API Migration](#deprecated-api-migration)
- [File Locations](#file-locations)
- [Quick Reference Card](#quick-reference-card)
- [Known Limitations](#known-limitations)
- [Real-World Use Cases](#real-world-use-cases-v403-optimizations)
- [Parameter Naming Conventions](#parameter-naming-conventions)
- [Version History](#version-history)
- [Full Changelog (Recent Changes)](#full-changelog-recent-changes)

---

## Quick Start for Agents

This guide provides the **complete API reference** for pladdrr, an R package that provides direct access to Praat C++ functionality. When reimplementing Praat code in R:

1. **Object Creation**: Use function constructors (not R6 classes): `Sound()`, `Pitch()`, etc.
2. **Method Calls**: Use `$` syntax: `sound$to_pitch()`, `pitch$get_mean()`
3. **Units**: Specify as strings: `"hertz"`, `"bark"`, `"db"` (converted internally to codes)
4. **Class Names**: Use clean names for `inherits()` checks: `Formant`, `Pitch`, `Intensity` (not internal `*_constructor` names)
5. **Batch Operations**: Use batch query functions when extracting multiple values
6. **Vectorized Methods**: Use `$get_*_windows()`, `$get_*_vector()`, `$get_spectral_moments_batch()` for 14-150x speedups (Patterns 2i, 2p)
7. **Properties**: Fast access via `.cpp$property` or backward-compatible `get_property()` methods
8. **Pipeline Operations**: Use `two_pass_adaptive_pitch()` and `get_jitter_shimmer_batch()` for voice quality (Pattern 2k)
9. **Tier 4 Ultra API**: Use `get_durations_batch()`, `calculate_f0_stats_ultra()`, `calculate_minimum_intensity_ultra()`, `get_voice_quality_ultra()` for DSI workflows, plus `calculate_cpps_ultra()`, `extract_voiced_segments_ultra()`, `calculate_multiband_hnr_ultra()` for simple AVQI/VQ workflows. For repeated intervals on the same sound, build once with `build_multiband_harmonicity()` and query with `multiband_hnr_stats()` (Pattern 2l)
10. **Fidelity target**: Every re-implemented Praat procedure must achieve r > 0.95 vs Praat on ≥50 real files before shipping. Use the in-repo Praat faithfulness registry and audit benchmark runner (see [Re-implementing a Praat Procedure](#re-implementing-a-praat-procedure)).

---

## Architecture Overview (current shared-dispatch + 4-tier performance API)

```
┌─────────────────────────────────────────────────────────────┐
│ R User Code                                                  │
│   sound <- Sound("audio.wav")                               │
│   pitch <- sound$to_pitch_cc()                              │
└─────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌───────────────┐  ┌───────────────┐  ┌───────────────────────┐
│ TIER 3        │  │ TIER 2        │  │ TIER 1                │
│ (Fastest)     │  │ (Fast)        │  │ (Standard)            │
│               │  │               │  │                       │
│ *_batch()     │  │ *_direct()    │  │ object$method()       │
│ *_parallel()  │  │ to_*_direct() │  │                       │
│ 5-20x faster  │  │ 2-3x faster   │  │ Full features         │
└───────────────┘  └───────────────┘  └───────────────────────┘
        │                   │                   │
        └───────────────────┼───────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ Rcpp Module Layer (src/modules/*.cpp)                       │
│   - 39 C++ module classes: RSound, RPitch, RMFCC, RPCA, etc. │
│   - XPtr<structPitch> wrapping Praat objects               │
│   - Batch queries: batch_queries.cpp (vectorized)          │
│   - Parallel processing: R/parallel-batch.R (multi-core)   │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ Praat C++ Layer (src/praat.github.io/)                      │
│   - 1,254 headers from Praat codebase                      │
│   - Direct calls: Sound_to_Pitch(), Formant_getValueAtTime()│
│   - Build flags come from R Makeconf; pladdrr keeps        │
│     `-ffp-contract=off` and optional xsimd detection       │
└─────────────────────────────────────────────────────────────┘
```

Tier 4 Ultra is a specialized one-call layer that sits alongside the tiered
APIs above; the diagram shows the shared object/direct/batch structure, while
the table below lists the current public tiers.

**Performance Tiers (current):**
| Tier | API | Speedup | Use Case |
|------|-----|---------|----------|
| **Tier 1 (Standard)** | `sound$to_pitch()` | 1x baseline | Interactive, <10 files |
| **Tier 2 (Direct)** | `to_pitch_direct()` | 2-3x | Loops, 10-100 files |
| **Tier 3 (Batch)** | `sound_to_pitch_batch()` | 5-10x | Production, >100 files |
| **Tier 4 (Ultra)** | `get_durations_batch()`, `calculate_f0_stats_ultra()`, `calculate_cpps_ultra()` | 5-77x | DSI/AVQI/VQ clinical workflows |

**See comprehensive guides:**
- `vignettes/performance-optimization.Rmd` - Complete performance API guide
- `vignettes/articles/batch-operations-guide.Rmd` - High-performance batch processing
- `vignettes/articles/migration-guide.Rmd` - v3.0 breaking changes guide
- `vignettes/articles/naming-conventions.Rmd` - API organization and patterns

### Tier 4 Ultra: Hardcoded Algorithm Choices

Every Tier 4 "Ultra" function that touches pitch/harmonicity picks one Praat
algorithm internally (raw AC vs. raw CC, `veryAccurate` true/false, fixed
threshold constants) so the whole pipeline can run in one C++ call. Some of
that choice is exposed as an R parameter, some is hardcoded to match a
specific reference Praat script. Check this table before assuming an Ultra
function is configurable, or before porting a Praat script that expects a
different algorithm — the alternative is discovering the mismatch via a
Praat-vs-R diff test (see `get_voice_quality_ultra()`'s AC-vs-CC history) or
reading the C++ source directly.

| Function | Pitch/harmonicity algorithm | Configurable | Matches |
|---|---|---|---|
| `calculate_f0_stats_ultra()` | `Sound_to_Pitch_rawCc`, `veryAccurate = TRUE`, `silenceThreshold = 0.03` | `voicing_threshold` only | DSI201.praat `To Pitch (cc)...` |
| `calculate_minimum_intensity_ultra()` | `Sound_to_Pitch_rawCc`, `veryAccurate = FALSE`, `silenceThreshold = 0.03`, `voicingThreshold = 0.8` (hardcoded, not exposed) | none | DSI201.praat IM component (stricter voicing threshold than the jitter block) |
| `get_voice_quality_ultra()` | `Sound_to_Pitch_rawCc` or `rawAc` via `pitch_method` (`"cc"`/`"ac"`), `very_accurate` | `pitch_method`, `very_accurate` | DSI201.praat (default `"cc"`); `pitch_method = "periodic_cc"` is an alias for `"ac"` + `very_accurate = FALSE`, which is byte-for-byte Praat's `Sound: To PointProcess (periodic, cc)...` (see `Sound_to_PointProcess.cpp`: that command is defined as `Sound_to_Pitch()` + `Sound_Pitch_to_PointProcess_cc`, and `Sound_to_Pitch()` is `Sound_to_Pitch_rawAc(..., veryAccurate=false, 0.03,0.45,0.01,0.35,0.14)`) |
| `calculate_multiband_hnr_ultra()` | `Sound_to_Harmonicity_cc` (no AC option) | none | VQ_measurements_V2.praat lines 102-122 |
| `calculate_cpps_ultra()` | n/a — pitch-independent, built on `Sound_to_PowerCepstrogram` | see CPPS parameter table in `/CLAUDE.md` | — |
| `extract_voiced_segments_ultra()` | n/a — voiced/silence split is Intensity-threshold based, not pitch-based | `silence_threshold_db`, `min_pitch` (controls the Intensity window, not a pitch algorithm choice) | — |

Each function's own `?function_name` help has a matching `@section Algorithm
choice:` block with the same fact, so this table and the roxygen never need
to be read in isolation.

### Data Flow Example: `sound$to_pitch_cc()`

**Shared Dispatch Table Architecture (v4.8.33, optimized v4.9.18)**

1. User calls: `pitch <- sound$to_pitch_cc(75, 600)`
2. `$.Sound` S3 dispatch looks up `to_pitch_cc` in `.sound_methods` env
3. Method calls **either** `.self$.cpp$method()` (module, for transforms/complex ops) **or** `.Call("_pladdrr_*", .self$.xptr, args)` (wrapper, for frequent queries). As of v4.9.18: Sound (7 methods), Formant (14), Spectrum (16), Spectrogram (12) use the faster wrapper path (~30-40% less overhead).
4. C++ calls Praat function (`Sound_to_Pitch_cc()`, `Formant_getValueAtTime()`, etc.)
5. Result wrapped in `XPtr<structPitch>` with custom deleter
6. R wrapper creates new `Pitch()` from pointer via factory function
7. Returns: `structure(list(.xptr = ptr, .cpp = module), class = c("Pitch", "PraatObject"))`

**Key Performance Improvements:**
- Shared dispatch tables eliminate per-instance closure allocation (9x faster creation, 160x less memory, v4.8.32).
- Wrapper dispatch (v4.9.18) replaces Rcpp Module's 3-layer R→Module→C++ path with direct 2-layer R→C++ `.Call()` for frequent query methods, reducing per-call overhead ~30-40%.

### Object Structure (Shared Dispatch Table Pattern)

**All 36 wrappers use the Shared Dispatch Table pattern (v4.8.33, extended since):**

All wrappers use a shared `.{type}_methods` environment + `$.Type` S3 dispatch. PraatInterpreter is the only R6Class — it requires persistent mutable state and reference semantics.

```r
# Shared method table (one per type, not per instance)
.pitch_methods <- new.env(hash = TRUE, parent = emptyenv())
.pitch_methods$get_mean <- function(.self, ...) .self$.cpp$get_mean(...)
.pitch_methods$to_point_process <- function(.self, ...) { ... }
# ... all methods take .self as first arg
lockEnvironment(.pitch_methods, bindings = TRUE)

# Constructor: minimal list, no closures
Pitch <- function(.xptr = NULL) {
  pitch_mod <- get_module("pitch_module")
  cpp_obj <- pitch_mod$RPitch$new(.xptr)
  structure(list(.xptr = .xptr, .cpp = cpp_obj), class = c("Pitch", "PraatObject"))
}

# S3 dispatch: $.Pitch intercepts field/method access
`$.Pitch` <- function(x, name) {
  val <- .subset2(x, name)       # Fast path: .xptr, .cpp
  if (!is.null(val)) return(val)
  method <- .pitch_methods[[name]]
  if (is.null(method)) return(NULL)
  function(...) method(x, ...)    # Bind self, return closure
}
```

**Special cases:** Some wrappers have additional fields or no `.xptr`:
- **FormantPath, KlattGrid, ComplexSpectrogram**: no `.xptr` — only `.cpp` stored
- **PowerCepstrogram**: opposite of the above — pure `.xptr`, no `.cpp` module at all
- **Electroglottogram**: triple class `c("Electroglottogram", "Sound", "PraatObject")` + `.pointer` compat alias
- **AmplitudeTier**: `.pointer` compat alias in `$` dispatch (used by factory functions)
- **PitchTier, FormantTier, LongSound, VocalTract**: static `$.{type}_constructor` for class methods

**Intentionally R6 (1/37):** PraatInterpreter (requires persistent mutable state for script execution)

---

## Object Types

**Note:** ~41 distinct object types are wrapped in R, backed by 39 `src/modules/*.cpp` files (not a 1:1 mapping —
some types like MelSpectrogram/BarkSpectrogram/LFCC/PowerCepstrogram share or lack a dedicated module file, while
some modules like Electroglottogram/DTW/Polygon aren't broken out as separate rows below).

**Update v4.8.25:** Added MelSpectrogram and BarkSpectrogram modules for psychoacoustic analysis.
**Update v4.0.7:** Added MFCC, LFCC, FormantModeler, PCA, Discriminant modules for speaker recognition, robust formant tracking, and statistical analysis.

### Audio Analysis

| Type | R Constructor | Creation Method |
|------|---------------|-----------------|
| `Sound` | `Sound("file.wav")` | Direct from file |
| `Pitch` | `sound$to_pitch()` | From Sound |
| `Formant` | `sound$to_formant_burg()` | From Sound |
| `Intensity` | `sound$to_intensity()` | From Sound |
| `Harmonicity` | `sound$to_harmonicity_cc()` | From Sound |
| `Spectrum` | `sound$to_spectrum()` | From Sound |
| `Spectrogram` | `sound$to_spectrogram()` | From Sound |
| `ComplexSpectrogram` | `ComplexSpectrogram(sound)` | From Sound (phase-preserving) |
| `MelSpectrogram` | `sound$to_mel_spectrogram()` | From Sound (v4.8.25) |
| `BarkSpectrogram` | `sound$to_bark_spectrogram()` | From Sound (v4.8.25) |
| `Ltas` | `sound$to_ltas()` | From Sound |
| `SpectrumTier` | `ltas$to_spectrum_tier_peaks()` | From Ltas (read-only peak-picking output, v5.0.3) |
| `PointProcess` | `sound$to_point_process_periodic_cc()` | From Sound |

### Editable Tiers

| Type | Creation Method |
|------|-----------------|
| `PitchTier` | `pitch$down_to_pitch_tier()` |
| `DurationTier` | `DurationTier(tmin, tmax)` |
| `IntensityTier` | `IntensityTier(tmin, tmax)` |
| `AmplitudeTier` | `amplitude_tier_from_point_process(point_process, sound)` |
| `FormantTier` | `FormantTier$from_formant(formant)` |
| `FormantGrid` | `formant$to_formantgrid()` |

### Advanced Analysis

| Type | Creation Method |
|------|-----------------|
| `Cepstrum` | `spectrum$to_cepstrum()` |
| `PowerCepstrum` | `spectrum$to_power_cepstrum()` |
| `PowerCepstrogram` | `sound$to_powercepstrogram()` |
| `Cochleagram` | `sound$to_cochleagram()` |
| `Excitation` | `cochleagram$to_excitation()` |
| `LPC` | `sound$to_lpc_burg()` |
| `FormantPath` | `sound$to_formant_path()` |
| `FormantModeler` | `formant$to_formant_modeler()` |
| `MFCC` | `sound$to_mfcc()` |
| `LFCC` | `lpc$to_lfcc()` |

### Statistical Analysis (NEW in v4.0.7)

| Type | Creation Method | Use Case |
|------|-----------------|----------|
| `PCA` | `pca_from_matrix(data)` | Dimensionality reduction, vowel space analysis |
| `Discriminant` | `discriminant_from_matrix(data, labels)` | Classification, speaker ID, vowel classification |

### Manipulation

| Type | Creation Method |
|------|-----------------|
| `Manipulation` | `sound$to_manipulation()` |
| `KlattGrid` | `KlattGrid(tmin, tmax, ...)` |
| `VocalTract` | `VocalTract(nx, dx)` |

### Data Structures

| Type | Creation Method |
|------|-----------------|
| `TextGrid` | `TextGrid("file.TextGrid")` |
| `Table` | `formant$down_to_table()` |
| `Matrix` | `Matrix(xmin, xmax, nx, dx, ...)` |
| `LongSound` | `LongSound$open("large_file.wav")` |

### Interpreter (NEW in v2.1.0)

| Type | Creation Method | Purpose |
|------|-----------------|---------|
| `PraatInterpreter` | `PraatInterpreter$new()` | Persistent Praat script interpreter with variable state |

**NOTE:** PraatInterpreter is the **only object that uses R6::R6Class**. All other ~40 object types use the shared dispatch table pattern (v4.8.33). This is intentional — the interpreter requires persistent mutable state, reference semantics, and method chaining (`self` reference).

**Key Methods:**
- `run(script)` - Execute Praat script
- `eval_numeric(expr)` - Evaluate expression to number
- `eval_string(expr)` - Evaluate expression to string
- `eval_vector(expr)` - Evaluate to numeric vector
- `get_variable(name)` - Get interpreter variable
- `set_variable(name, value)` - Set interpreter variable

**Example:**
```r
interp <- PraatInterpreter$new()
interp$run('x = 42')
interp$run('y = x * 2')
result <- interp$eval('y')  # 84 (numeric tried first, then string)
```

---

## Unit Code Reference

### Frequency Units (Pitch, Formant)

**WARNING:** Frequency/pitch unit codes are NOT consistent across the codebase — there are 4 different,
mutually-incompatible int-code schemes depending on which R file the call goes through. Always use the
string API (`"hertz"`, `"semitones"`, etc.) rather than passing raw integer codes, and if you must know the
integer value, check the specific call site below.

| Call site | `hertz` | `semitones` | `mel` | `erb` | `loghertz` |
|-----------|---------|--------------|-------|-------|------------|
| `R/pitch-wrapper.R` (`Pitch$` methods) | `0` | `1` | `2` | `3` | not supported |
| `R/batch-queries.R`, `R/pitchtier-wrapper.R` | `0` | `3` | `1` | `4` | `2` |
| `R/praat-direct.R` | `0` | `1` | `2` | `3` | `4` |
| `R/utils-internal.R` (`unit_to_code`, matches Praat's `kPitch_unit` enum) | `0` | `1` | `2` | `3` | `4` |

### Formant Units

| R String | Code | Praat Enum |
|----------|------|------------|
| `"hertz"` | `0` | `kFormant_unit::HERTZ` |
| `"bark"` | `1` | `kFormant_unit::BARK` |

### Intensity Units

There is no general-purpose "intensity unit" code. The only related parameter is `averaging_method`
on `Intensity$get_mean(from_time, to_time, averaging_method)`, internally mapped by `.intensity_avg_code`
(`R/intensity-wrapper.R:38`):

| R String | Code |
|----------|------|
| `"energy"` | `0` |
| `"sones"` | `1` |
| `"db"` | `2` |

### LTAS Units (FIXED in v4.0.4)

**BREAKING CHANGE:** Prior to v4.0.4, LTAS unit codes were incorrectly mapped. The fix aligns with Praat's `Ltas.cpp:44-60`.

| R String | Code | Praat Behavior |
|----------|------|----------------|
| `"db"` | `0` | Passthrough (no conversion) |
| `"energy"` | `1` | `10*log10(ratio)` → dB |
| `"sones"` | `2` | `10*log2(ratio)` → dB |

**Migration note:** If you used `unit="sones"` as a workaround for getting correct dB values, switch to `unit="energy"` or `unit="dB"`.

```r
# CORRECT (v4.0.4+):
slope <- ltas$get_slope(0, 1000, 1000, 10000, unit = "energy")  # Returns dB

# WRONG (pre-v4.0.4 workaround - no longer needed):
slope <- ltas$get_slope(0, 1000, 1000, 10000, unit = "sones")   # Was accidental fix
```

### Interpolation Methods

**Updated v2.1.1:** Fixed intensity interpolation codes.

| Code | Method | Use Case |
|------|--------|----------|
| `0` | Nearest | Fast, no smoothing |
| `1` | Linear | Moderate smoothing |
| `2` | Cubic | Smooth curves (DEFAULT for intensity) |
| `3` | Sinc70 | High-quality, 70-point window |
| `4` | Sinc700 | Highest quality, 700-point window |

**String API (recommended):**
```r
# Use string names - automatically converted to codes
intensity$get_value_at_time(time = 1.0, interpolate = "cubic")
get_intensity_at_times(intensity, times, interpolate = "sinc70")
```

---

## Common Patterns

### Pattern 1: Sound → Analysis Object

```r
# Load audio
sound <- Sound("audio.wav")

# Extract analysis objects (all return new objects)
pitch <- sound$to_pitch(
  time_step = 0.0,              # 0 = auto (0.75 / pitch_floor)
  pitch_floor = 75.0,           # Hz
  pitch_ceiling = 600.0         # Hz
)

formant <- sound$to_formant_burg(
  time_step = 0.0,              # 0 = auto
  max_number_of_formants = 5,   # Usually 5 for adults
  maximum_formant = 5500.0,     # Hz (5500 for female, 5000 for male)
  window_length = 0.025,        # seconds
  pre_emphasis_from = 50.0      # Hz
)

intensity <- sound$to_intensity(
  minimum_pitch = 100.0,        # Hz
  time_step = 0.0,              # 0 = auto
  subtract_mean = TRUE
)
```

### Pattern 2: Query Values at Time

```r
# Point queries (single time point)
f0 <- pitch$get_value_at_time(time = 1.0, unit = "hertz")
f1 <- formant$get_value_at_time(formant_number = 1, time = 1.0, unit = "hertz")
f2 <- formant$get_value_at_time(formant_number = 2, time = 1.0, unit = "hertz")
db <- intensity$get_value_at_time(time = 1.0)

# Range queries (time range, 0,0 = entire duration)
mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")
sd_f0 <- pitch$get_standard_deviation(from_time = 0, to_time = 0, unit = "hertz")
min_f0 <- pitch$get_minimum(from_time = 1.0, to_time = 2.0, unit = "hertz")
```

### Pattern 2b: Batch Queries (v2.0.9+)

**Performance:** 5-10x faster than loops by reducing R↔C++ boundary crossings.

```r
# Extract formants F1-F4 at multiple time points (1 call instead of 200)
times <- seq(0.5, 2.5, by = 0.01)  # 200 time points
formants <- get_formants_at_times(formant, times, formant_numbers = 1:4)
# Returns: list(F1 = ..., F2 = ..., F3 = ..., F4 = ...)

# Extract pitch contour (1 call instead of 200)
f0_values <- get_pitch_at_times(pitch, times, unit = "hertz", interpolate = TRUE)

# Extract intensity contour (1 call instead of 200)
db_values <- get_intensity_at_times(intensity, times, interpolate = "cubic")

# Get all PointProcess times at once (1 call instead of n)
all_times <- get_pointprocess_times(pointprocess)

# Get all inter-point intervals (for jitter analysis)
intervals <- get_pointprocess_intervals(pointprocess)
```

**Key batch query functions:**
- `get_formants_at_times(formant, times, formant_numbers = 1:4, unit = "hertz")` - 10-20x faster
- `get_formant_bandwidths_at_times(formant, times, formant_numbers, unit)` - 10-20x faster
- `get_pitch_at_times(pitch, times, unit = "hertz", interpolate = TRUE)` - 5-10x faster
- `get_pitch_strengths_at_times(pitch, times, unit, interpolate)` - 5-10x faster
- `get_intensity_at_times(intensity, times, interpolate = "cubic")` - 5-10x faster
- `get_pointprocess_times(pointprocess)` - All times in one call
- `get_pointprocess_intervals(pointprocess)` - All intervals in one call
- `get_pointprocess_nearest_indices(pointprocess, times)` - Vectorized nearest point lookup

**Deprecated functions (v2.4.0):**
The following functions are deprecated and will be removed in v5.0.0. Use the recommended alternatives:
- `pitch_get_values_at_times()` → use `get_pitch_at_times()` instead
- `formant_get_values_at_times()` → use `get_formants_at_times()` instead
- `intensity_get_values_at_times()` → use `intensity$get_values_at_times()` instead (v4.8.22+)

See `vignettes/articles/migration-guide.Rmd` for details.

### Pattern 2c: Batch Statistics (NEW in v2.2.1)

**Performance:** 10-50x faster than loops for multi-interval statistics.

When you need statistics (min, max, mean, stdev, quartiles) over **multiple time intervals**, use batch statistics functions:

```r
# Define 100 time intervals
from_times <- seq(0, 9, length.out = 100)
to_times <- from_times + 0.1
metrics <- c("min", "max", "mean", "stdev", "q25", "q75")

# SLOW: Loop with repeated R↔C++ boundary crossings (600 calls)
for (i in 1:100) {
  min_val <- pitch$get_minimum(from_times[i], to_times[i], "hertz")
  max_val <- pitch$get_maximum(from_times[i], to_times[i], "hertz")
  # ... 4 more calls per interval
}

# FAST: Single C++ call returns 100x6 matrix (1 call)
stats <- pitch_get_statistics_batch(
  pitch$.xptr,
  from_times,
  to_times,
  metrics,
  unit = 0L  # 0=Hertz
)
# Returns: matrix[100 rows, 6 cols] with column names from metrics
```

**Batch statistics functions:**
- `pitch_get_statistics_batch(pitch_xptr, from_times, to_times, metrics, unit)`
  - Metrics: `"min"`, `"max"`, `"mean"`, `"stdev"`, `"q25"`, `"q50"`, `"q75"`, `"count_voiced"`

### Pattern 2d: Fast CPPS API (Updated v4.1.0 - Direct Sound→CPPS)

**v4.1.0 Major Performance Fix:** Removed debug output from Praat threading code, achieving **3x speedup** for CPPS and all multi-threaded operations. AVQI benchmark improved from 8x slower to **2.67x slower** than Python/Parselmouth.

**PowerCepstrogram converted to modules in v2.2.1** for 1.5-2x speedup in AVQI v3.01. By v4.8.33, all 35 wrappers use shared dispatch tables.

For voice quality analysis, use the module-based API (now default) or fast helper functions:

```r
# RECOMMENDED (v4.1.0+): Direct Sound→CPPS path (single C++ call, no intermediate objects)
# PowerCepstrogram created and destroyed internally - no R/C++ boundary crossing
cpps <- calculate_cpps_fast(sound)  # Uses optimized defaults matching get_cpps()

# With custom parameters:
cpps <- calculate_cpps_fast(
  sound,
   subtract_tilt = TRUE,              # Default: TRUE (matches get_cpps)
  time_averaging_window = 0.001,     # Default: 0.001
  quefrency_averaging_window = 0.0005, # Default: 0.0005
  pitch_floor = 60,
  pitch_ceiling = 333.3              # Default: 333.3
)

# STANDARD API: Two-step with wrapper object (same performance, returns reusable object)
pcep <- sound$to_powercepstrogram(60, 0.002, 5000, 50)
cpps <- pcep$get_cpps(
  subtract_tilt = TRUE,
  time_averaging_window = 0.001,
  quefrency_averaging_window = 0.0005,
  pitch_floor = 60,
  pitch_ceiling = 333.3
)

# ADVANCED: Two-step for multiple CPPS calculations from same cepstrogram
pcep_ptr <- to_powercepstrogram_fast(sound, 60, 0.002, 5000, 50)
cpps1 <- get_cpps_fast(pcep_ptr, subtract_tilt = FALSE, pitch_floor = 60)
cpps2 <- get_cpps_fast(pcep_ptr, subtract_tilt = TRUE, pitch_floor = 80)

# Single-interval CPP is a different, cheaper path
segment <- sound$extract_part(0, 0.5)
cpp <- segment$to_spectrum()$to_power_cepstrum()$get_peak_prominence(
  60, 333.3, "parabolic", 0.001, 0.05, "exponential decay", "robust slow"
)
```

Use the PowerCepstrum path above when you need a single interval's **CPP**.
Use `calculate_cpps_fast()` / `calculate_cpps_ultra()` when you need smoothed
whole-sound **CPPS**. They are not interchangeable, and CPPS is much more
expensive because it builds a full PowerCepstrogram first.

**Performance comparison (verified v4.1.0):**
| Version | AVQI Benchmark | vs Python |
|---------|---------------|-----------|
| v4.0.x (with debug output) | ~17s | 8.0x slower |
| **v4.1.0 (threading fix)** | **~5.7s** | **2.67x slower** |
| Python/Parselmouth | ~2.1s | baseline |

**Key v4.1.0 changes:**
- `calculate_cpps_fast()` now uses direct C++ path (Sound→CPPS in single call)
- Defaults aligned with `get_cpps()` method for identical output
- Threading debug output removed from Praat's `MelderThread.cpp`
- Benefits ALL multi-threaded Praat operations (Pitch, Formant, CPPS, etc.)

### Pattern 2e: XPtr Window Functions (NEW in v2.2.1)

**Performance:** 70x faster than R function callbacks for custom DSP.

When applying custom window or transform functions to large audio files, use compiled C++ functions via RcppXPtrUtils:

```r
# Requires: install.packages("RcppXPtrUtils")
library(RcppXPtrUtils)

# Create compiled C++ window function (runs once at setup)
gauss_window <- cppXPtr(
  "#include <cmath>
   double window(double t) {
     double x = t - 0.5;
     return exp(-18.0 * x * x);
   }",
  depends = character()
)

# Apply to sound (70x faster than R function callback)
windowed <- apply_window_xptr(sound, gauss_window)

# Or use pre-defined window types (no RcppXPtrUtils code needed)
hamming <- create_window_xptr("hamming")  # Also: hanning, gaussian, triangular, blackman
windowed <- apply_window_xptr(sound, hamming)
```

**XPtr performance functions:**
- `apply_window_xptr(sound, window_func)` - Apply window (t normalized 0-1)
- `apply_transform_xptr(sound, transform_func)` - Transform sample values
- `create_window_xptr(type, sigma)` - Create pre-defined window function

**Custom transform example (soft clipping):**
```r
soft_clip <- cppXPtr(
  "#include <cmath>
   double clip(double x) { return tanh(x * 2.0); }",
  depends = character()
)
clipped <- apply_transform_xptr(sound, soft_clip)
```

### Pattern 2f: Parallel Processing (v4.0.1+)

**Performance:** 3-8x speedup on multi-core systems for I/O-bound tasks.

```r
files <- list.files("audio/", pattern = "\\.wav$", full.names = TRUE)

# Generic parallel file processing
results <- analyze_files_parallel(files, function(sound) {
  pitch <- sound$to_pitch()
  list(
    mean_f0 = pitch$get_mean(0, 0, "hertz"),
    sd_f0 = pitch$get_standard_deviation(0, 0, "hertz")
  )
}, n_cores = 4)

# Specialized parallel extraction (convenience wrappers)
pitches <- extract_pitch_parallel(files, n_cores = 4)
formants <- extract_formant_parallel(files, n_cores = 4)
intensities <- extract_intensity_parallel(files, n_cores = 4)
```

**Exported parallel functions:**
- `analyze_files_parallel(files, analysis_func, n_cores)` - Generic parallel file processing
- `process_sounds_parallel(sounds, analysis_func, n_cores)` - Process pre-loaded sounds
- `extract_pitch_parallel(files, n_cores, ...)` - Parallel pitch extraction
- `extract_formant_parallel(files, n_cores, ...)` - Parallel formant extraction
- `extract_intensity_parallel(files, n_cores, ...)` - Parallel intensity extraction
- `benchmark_parallel(files, analysis_func, cores)` - Find optimal core count

**Best practices:**
- Use `n_cores = parallel::detectCores() - 1` to leave one core for system
- On Windows, uses `parLapply`; on Unix/Mac, uses `mclapply`
- For very large files, consider batch processing + parallel combined

### Pattern 2g: Direct API Functions (v2.3.0)

**Performance:** 2-3x faster than module dispatch for hot paths.

**NEW in v4.0.2:** Full-parameter Direct API pitch functions now available! Use `to_pitch_ac_direct()` or `to_pitch_cc_direct()` for custom voicing parameters with Direct API performance.

```r
# TIER 1: Standard (baseline, full features)
pitch <- sound$to_pitch_cc(voicing_threshold = 0.6)
mean_f0 <- pitch$get_mean(0, 0, "hertz")

# TIER 2: Direct API with FULL PARAMETERS (v4.0.2+) ⭐ NEW
pitch_ptr <- to_pitch_cc_direct(sound, voicing_threshold = 0.6)
f0_value <- get_pitch_value_direct(pitch_ptr, time = 1.0, unit = "hertz", interpolate = TRUE)
# 2x faster than Tier 1, returns external pointer

# TIER 2: Legacy Direct API (basic parameters only)
pitch_ptr <- to_pitch_direct(sound)  # Only: time_step, pitch_floor, pitch_ceiling
# Kept for backward compatibility

# TIER 3: Batch API (fastest for >10 files)
pitches <- sound_to_pitch_cc_batch(sounds, voicing_threshold = 0.6)
```

**Direct API functions for object creation:**
- `to_pitch_direct(sound, time_step, pitch_floor, pitch_ceiling)` → Pitch XPtr (legacy, basic params)
- `to_pitch_ac_direct(sound, ...)` → Pitch XPtr ✅ **Full params (v4.0.2+)**
- `to_pitch_cc_direct(sound, ...)` → Pitch XPtr ✅ **Full params (v4.0.2+)**
- `to_pitch_shs_direct(sound, time_step, pitch_floor, max_frequency, pitch_ceiling, max_subharmonics, max_candidates, compression_factor, n_points_per_octave)` → Pitch XPtr ✅ **v4.8.34+**
- `to_pitch_spinet_direct(sound, time_step, window_duration, min_frequency, max_frequency, n_filters, pitch_ceiling, max_candidates)` → Pitch XPtr ✅ **v4.8.34+**
- `to_formant_direct(sound, time_step, max_formants, max_formant, window_length, pre_emphasis)` → Formant XPtr ✅ **Full params**
- `to_intensity_direct(sound, minimum_pitch, time_step, subtract_mean)` → Intensity XPtr ✅ **Full params**
- `to_harmonicity_direct(sound, time_step, minimum_pitch, silence_threshold, periods_per_window)` → Harmonicity XPtr ✅ **Full params**
- `to_spectrum_direct(sound, fast)` → Spectrum XPtr (v2.3.0)
- `to_spectrogram_direct(sound, ...)` → Spectrogram XPtr (v2.3.0)
- `to_ltas_direct(sound, bandwidth)` → LTAS XPtr (v2.3.0)
- `to_point_process_direct(sound, ...)` → PointProcess XPtr (v2.3.0)
- `to_point_process_from_sound_and_pitch(sound, pitch)` → PointProcess XPtr (multi-object)

**Pipeline functions (v4.3.0+):**
- `two_pass_adaptive_pitch(sound, ...)` → list(pitch, min_pitch, max_pitch, q1, q3)
- `get_jitter_shimmer_batch(pointprocess, sound, ...)` → list(11 voice quality metrics)

**Direct API functions for queries (accepts string units):**
- `get_pitch_value_direct(pitch_xptr, time, unit, interpolate)` - Single F0 value (unit: "hertz", "semitones", etc.)
- `get_pitch_stats_direct(pitch_xptr, from_time, to_time, unit)` - All pitch statistics
- `get_formant_value_direct(formant_xptr, formant_number, time, unit)` - Single formant
- `get_formants_direct(formant_xptr, time, unit)` - All formants at time
- `get_intensity_value_direct(intensity_xptr, time, interpolation)` - Single intensity

**Compound operations (single C++ call for multiple stats):**
```r
# Get all common pitch statistics in one call
stats <- get_pitch_stats_direct(pitch_ptr, 0, 0, "hertz")
# Returns: list(min, max, mean, stdev, median, q25, q75, count_voiced)

# Get all formants at single time point
formants <- get_formants_direct(formant_ptr, time = 1.0, unit = "hertz")
# Returns: numeric vector of formant values
```

**Note:** All Direct API functions use the unified `extract_xptr()` utility for consistent pointer extraction.

### Pattern 2h: Tier 3 Batch Operations (v2.2.7+)

**Performance:** 5-10x faster for bulk object creation and processing.

When creating multiple analysis objects or processing many sounds, use batch operations:

```r
# TIER 1: Individual sound processing (baseline)
sounds <- lapply(files, Sound)
pitches <- lapply(sounds, function(s) s$to_pitch())

# TIER 3: Batch processing (5-10x faster)
sounds <- lapply(files, Sound)
pitches <- sound_to_pitch_batch(sounds, time_step = 0.01, 
                                 pitch_floor = 75, pitch_ceiling = 600)

# Other batch conversion functions
formants <- sound_to_formant_batch(sounds)
intensities <- sound_to_intensity_batch(sounds)

# Batch operations with pitch algorithms
pitches_ac <- sound_to_pitch_ac_batch(sounds, time_step = 0.01)
pitches_cc <- sound_to_pitch_cc_batch(sounds, time_step = 0.01)

# Combined extraction and analysis
results <- sound_extract_and_pitch(sound, start_times, end_times)
results <- sound_extract_and_formant(sound, start_times, end_times)
```

**Batch conversion functions:**
- `sound_to_pitch_batch(sounds, ...)` - Batch pitch extraction
- `sound_to_pitch_ac_batch(sounds, ...)` - Batch autocorrelation pitch
- `sound_to_pitch_cc_batch(sounds, ...)` - Batch cross-correlation pitch
- `sound_to_pitch_shs_batch(sounds, ...)` - Batch subharmonic summation pitch ✅ **v4.8.34+**
- `sound_to_pitch_spinet_batch(sounds, ...)` - Batch SPINET pitch ✅ **v4.8.34+**
- `sound_to_formant_batch(sounds, ...)` - Batch formant extraction
- `sound_to_intensity_batch(sounds, ...)` - Batch intensity extraction
- `sound_extract_and_pitch(sound, starts, ends)` - Extract parts + pitch
- `sound_extract_and_formant(sound, starts, ends)` - Extract parts + formant
- `sound_concatenate_all(sounds)` - Concatenate multiple sounds (19x faster than iterative)
- `sound_load_window(path, start, end, resample_to = NULL)` - Load audio window without full file read (27x faster)
- `textgrid_merge(textgrids, equalize_domains = FALSE)` - Merge multiple TextGrids (17x faster than manual tier copying)

**NEW in v4.0.3:** Added specialized functions for complex workflows:

```r
# Load only needed audio segment (avoids loading entire file)
window <- sound_load_window("long_audio.wav", start = 10.5, end = 10.55, resample_to = 10000)
# Use case: Extract 50ms window from 10-minute file + resample in one operation

# Merge TextGrids efficiently (native Praat function)
tg1 <- TextGrid(0, 1); tg1$add_interval_tier("words")
tg2 <- TextGrid(0, 1); tg2$add_point_tier("events")
merged <- textgrid_merge(list(tg1, tg2))
# Use case: Combine annotation layers from different sources

# Concatenate voiced segments efficiently
voiced_parts <- list(sound1, sound2, sound3)  # 10-50 segments
concatenated <- sound_concatenate_all(voiced_parts)
# Use case: AVQI analysis requiring voiced-only audio
```

See `vignettes/articles/batch-operations-guide.Rmd` for comprehensive batch operations documentation.

### Pattern 2i: Vectorized Object Methods (NEW in v4.0.13)

**Performance:** 20-150x faster than R loops by keeping iteration inside C++.

These methods avoid the 1-2ms R↔C++ boundary crossing overhead per call. Instead of looping in R and calling individual methods, use vectorized methods that loop in C++.

#### Sound Batch Window Operations

```r
# SLOW: R loop (1-2ms per call × 500 windows = 500-1000ms)
starts <- seq(0, 14.97, by = 0.03)  # 500 windows
ends <- starts + 0.03
powers <- vapply(seq_along(starts), function(i) {
  sound$get_power(starts[i], ends[i])
}, numeric(1))

# FAST: Single C++ call (all 500 windows in ~5ms = 100-150x speedup)
powers <- sound$get_power_windows(starts, ends)
rms_vals <- sound$get_rms_windows(starts, ends)
energies <- sound$get_energy_windows(starts, ends)
zcr_vals <- sound$get_zcr_windows(starts, ends, channel = 1)
```

#### Sound Vectorized Value Extraction

```r
# SLOW: R loop for amplitude extraction
times <- seq(0.01, 2.99, by = 0.001)  # 2980 time points
values <- vapply(times, function(t) sound$get_value_at_time(t), numeric(1))

# FAST: Single C++ call (20x speedup)
values <- sound$get_values_at_times(times, channel = 1, interpolation = "linear")

# Get all samples in a time range
values <- sound$get_values_in_range(from_time = 0.5, to_time = 1.5, channel = 1)
times <- sound$get_times_in_range(from_time = 0.5, to_time = 1.5)
```

#### Pitch Vectorized Operations

```r
pitch <- sound$to_pitch(0.01, 75, 500)

# Get all frame times and values at once
times <- pitch$get_times_vector()
values <- pitch$get_values_vector()

# Voiced/unvoiced mask (logical vector, TRUE = voiced)
voiced <- pitch$get_voiced_mask()
voiced_times <- times[voiced]
voiced_f0 <- values[voiced]

# Strengths and intensities
strengths <- pitch$get_strengths_vector(unit = "hertz")
intensities <- pitch$get_intensities_vector()

# Values at specific times (interpolated)
query_times <- seq(0.5, 2.5, by = 0.1)
f0_values <- pitch$get_values_at_times(query_times, unit = "hertz", interpolate = TRUE)
```

#### Intensity Batch Queries (NEW in v4.8.22)

```r
intensity <- sound$to_intensity(minimum_pitch = 100)

# SLOW: R loop
times <- seq(0.1, 2.9, by = 0.01)
values <- vapply(times, function(t) intensity$get_value_at_time(t), numeric(1))

# FAST: Single C++ call (20x speedup)
values <- intensity$get_values_at_times(times, interpolation = "cubic")
```

#### Harmonicity Batch Statistics

```r
hnr <- sound$to_harmonicity_ac(0.01, 75)

# Direct vector access
values <- hnr$get_values_vector()
times <- hnr$get_times_vector()

# Batch statistics for multiple windows (10x speedup for multi-band analysis)
starts <- c(0.5, 1.0, 1.5, 2.0)
ends <- c(1.0, 1.5, 2.0, 2.5)
metrics <- c("mean", "min", "max", "stdev")
stats <- hnr$get_statistics_batch(starts, ends, metrics)
# Returns: matrix[4 windows, 4 metrics]
```

#### Spectrum Vector Extraction

```r
spectrum <- sound$to_spectrum()

# Get all vectors at once (150x speedup for spectral analysis)
freqs <- spectrum$get_frequencies_vector()
powers <- spectrum$get_power_vector()
reals <- spectrum$get_real_vector()
imags <- spectrum$get_imaginary_vector()

# Band energies for multiple bands
fmins <- c(0, 500, 1000, 2000)
fmaxs <- c(500, 1000, 2000, 4000)
energies <- spectrum$get_band_energies(fmins, fmaxs)
densities <- spectrum$get_band_densities(fmins, fmaxs)
```

#### Formant Track Extraction

```r
formant <- sound$to_formant_burg(0.01, 5, 5500)

# Get complete formant tracks (20x speedup)
times <- formant$get_times_vector()
f1_track <- formant$get_formant_track(1, unit = "hertz")
f2_track <- formant$get_formant_track(2, unit = "hertz")
b1_track <- formant$get_bandwidth_track(1, unit = "hertz")

# Get all formant tracks as matrix
all_tracks <- formant$get_all_formant_tracks(max_formants = 4, unit = "hertz")
# Returns: matrix[n_frames, 4]

# Values at specific times
query_times <- seq(0.5, 2.5, by = 0.1)
f1_at_times <- formant$get_values_at_times(1, query_times, unit = "hertz")
```

#### Spectrogram Batch Queries

```r
spectrogram <- sound$to_spectrogram(window_length = 0.005, max_frequency = 5000)

# Get dimension vectors
times <- spectrogram$get_times_vector()
freqs <- spectrogram$get_frequencies_vector()

# Get frames and slices (50x speedup)
frame <- spectrogram$get_frame(time = 1.0)           # All freqs at one time
slice <- spectrogram$get_frequency_slice(frequency = 1000) # One freq across all times

# Get multiple frames at once
query_times <- c(0.5, 1.0, 1.5, 2.0)
frames <- spectrogram$get_frames(query_times)  # matrix[n_freqs, 4]

# Band power over time
band_power <- spectrogram$get_band_power(fmin = 500, fmax = 2000)
# Returns: power in band for each time frame
```

#### TextGrid Batch Labels

```r
tg <- TextGrid("annotations.TextGrid")

# Get labels at multiple times (60x speedup for VUV analysis)
times <- seq(0.1, 9.9, by = 0.1)
labels <- tg$get_labels_at_times(tier = 1, times)

# Batch set interval texts
intervals <- c(1, 2, 3, 4)
texts <- c("hello", "world", "test", "end")
tg$set_interval_texts_batch(tier = 1, intervals, texts)
```

**Summary of vectorized methods:**

| Object | Method | Speedup | Use Case |
|--------|--------|---------|----------|
| Sound | `get_power_windows()`, `get_rms_windows()`, `get_energy_windows()` | 100-150x | AVQI windowed analysis |
| Sound | `get_values_at_times()`, `get_values_in_range()` | 20x | Tremor peak extraction |
| Intensity | `get_values_at_times()` | 20x | Batch intensity queries (v4.8.22) |
| Pitch | `get_voiced_mask()`, `get_strengths_vector()` | 5x | DSI voicing analysis |
| Harmonicity | `get_statistics_batch()` | 10x | Multi-band HNR (VQ) |
| Spectrum | `get_power_vector()`, `get_band_energies()` | 150x | Pharyngeal analysis |
| Formant | `get_formant_track()`, `get_all_formant_tracks()` | 20x | Vowel space analysis |
| Spectrogram | `get_frame()`, `get_band_power()` | 50x | Time-frequency analysis |
| Spectrogram | `get_spectral_moments_batch()` | 14x | CoG/SD/skewness/kurtosis all frames (v4.9.1) |
| TextGrid | `get_labels_at_times()` | 60x | VUV segmentation |

---

### Pattern 2j: Batch API v4.0.14 (Advanced Optimizations)

**Performance:** 10-50x faster for specific analysis workflows (Pharyngeal, Tremor, DSI, AVQI).

These methods target specific performance bottlenecks identified in voice quality analysis pipelines.

#### LTAS Batch Peak Search (Pharyngeal: 36x → 3x)

```r
ltas <- sound$to_ltas(bandwidth = 100)

# SLOW: Individual peak searches (18 calls for Pharyngeal analysis)
fmins <- c(180, 380, 580)  # Search ranges for H1, H2, H3
fmaxs <- c(220, 420, 620)
for (i in seq_along(fmins)) {
  peak_val <- ltas$get_maximum(fmins[i], fmaxs[i])
  peak_freq <- ltas$get_frequency_of_maximum(fmins[i], fmaxs[i])
}

# FAST: Single batch call (18x speedup)
peaks <- ltas$get_peaks_batch(fmins, fmaxs, interpolation = "parabolic")
# Returns: data.frame(fmin, fmax, peak_value, peak_frequency)
# NOTE (v4.9.1): parabolic interpolation is now numerically safe for flat peaks.
# Before v4.9.1, near-zero d2y produced values up to 1231 dB (physically impossible).
# The guard is in NUMimproveExtremum() in praat.github.io/melder/NUMinterpol.cpp.

# Also available:
minima <- ltas$get_minima_batch(fmins, fmaxs, interpolation = "parabolic")
# Returns: data.frame(fmin, fmax, min_value, min_frequency)

# Get LTAS values at specific frequencies
freqs <- c(100, 440, 880, 1000)
values <- ltas$get_values_at_frequencies(freqs, interpolation = "cubic")

# Get mean values in multiple bands
means <- ltas$get_means_batch(fmins, fmaxs, unit = "energy")
```

#### Pitch Detrending (Tremor: 10x → 4x)

```r
pitch <- sound$to_pitch(pitch_floor = 75, pitch_ceiling = 600)

# SLOW: R-side detrending with lm() + predict() (~40ms)
values <- pitch$get_values_vector()
times <- pitch$get_times_vector()
model <- lm(values ~ times, na.action = na.exclude)
detrended <- residuals(model)

# FAST: Native Praat detrending (~4ms = 10x speedup)
detrended <- pitch$get_values_detrended(unit = "hertz")  # Returns NumericVector

# Or get a new detrended Pitch object
detrended_pitch <- pitch$subtract_linear_fit(unit = "hertz")  # Returns Pitch object

# Additional pitch processing methods (v4.0.14)
interpolated <- pitch$interpolate()      # Fill unvoiced gaps
smoothed <- pitch$smooth(bandwidth = 10) # Smooth pitch contour
cleaned <- pitch$kill_octave_jumps()     # Remove octave errors
```

#### Filtered Window Extraction (AVQI: 2.9x → 1.5x)

```r
sound <- Sound("recording.wav")

# SLOW: Extract each window separately, filter, concatenate
starts <- seq(0.0, 9.9, by = 0.1)
ends <- starts + 0.1
voiced_sounds <- list()
for (i in seq_along(starts)) {
  part <- sound$extract_part(starts[i], ends[i])
  power <- part$get_power()
  zcr <- part$get_zcr_windows(0, part$get_total_duration())
  if (power > 0.03 && zcr < 3000) {
    voiced_sounds <- c(voiced_sounds, list(part))
  }
}
result <- Reduce(function(a, b) a$concatenate(b), voiced_sounds)

# FAST: Single C++ call filters and concatenates (10x speedup)
result <- sound$extract_windows_filtered(
  window_starts = starts,
  window_ends = ends,
  min_power = 0.03,      # Minimum power threshold
  max_zcr = 3000,        # Maximum zero-crossing rate
  overlap_time = 0.0,    # Overlap for crossfade
  window_shape = "rectangular"  # or "hanning", "hamming", etc.
)

# Get filter mask only (for inspection)
passes <- sound$get_windows_passing_filter(starts, ends, min_power = 0.03, max_zcr = 3000)
# Returns: logical vector (TRUE = window passes filter)

# Concatenate multiple sounds efficiently
sounds_list <- list(sound1, sound2, sound3)
concatenated <- sound1$concatenate_sounds(sounds_list, overlap_time = 0.01)
```

#### PointProcess Batch Operations (DSI/Shimmer: 10-20x speedup)

```r
sound <- Sound$create_tone(frequency = 200, duration = 0.5)
pp <- sound$to_point_process_periodic_cc(pitch_floor = 75, pitch_ceiling = 600)

# SLOW: Get amplitude at each pulse point individually
for (i in 1:pp$get_number_of_points()) {
  t <- pp$get_time(i)
  val <- sound$get_value_at_time(t, channel = 1, interpolation = "cubic")
}

# FAST: Get all values in one call (20x speedup)
values <- pp$get_values_from_sound(sound, channel = 1, interpolation = "cubic")
# Returns: NumericVector of amplitude values at all pulse times

# Get all inter-point intervals (periods) efficiently
periods <- pp$get_periods_vector()  # All intervals
# Returns: NumericVector of length (n_points - 1)

# Get only periods within physiological range
filtered_periods <- pp$get_periods_filtered(min_period = 0.0001, max_period = 0.02)

# Get ALL jitter measures in one call (5x speedup vs individual calls)
jitter <- pp$get_jitter_batch(
  from_time = 0, to_time = 0,  # 0,0 = entire duration
  period_floor = 0.0001,
  period_ceiling = 0.02,
  max_period_factor = 1.3
)
# Returns: list(local, local_absolute, rap, ppq5, ddp)
```

#### Spectrum Power at Frequencies

```r
spectrum <- sound$to_spectrum()

# Get power at specific frequencies (Pharyngeal harmonic analysis)
freqs <- c(100, 440, 880, 1000)
powers <- spectrum$get_power_at_frequencies(freqs)
# Returns: NumericVector of power values (nearest bin, no interpolation)
```

**Summary of v4.0.14 batch methods:**

| Object | Method | Speedup | Use Case |
|--------|--------|---------|----------|
| LTAS | `get_peaks_batch()` | 18x | Pharyngeal harmonic peaks |
| LTAS | `get_minima_batch()` | 18x | Spectral valley detection |
| LTAS | `get_values_at_frequencies()` | 10x | Targeted frequency sampling |
| LTAS | `get_means_batch()` | 10x | Multi-band energy analysis |
| Pitch | `subtract_linear_fit()` | 10x | Tremor F0 detrending |
| Pitch | `get_values_detrended()` | 10x | Direct detrended values |
| Pitch | `interpolate()`, `smooth()` | 5x | Pitch post-processing |
| Sound | `extract_windows_filtered()` | 10x | AVQI voiced extraction |
| Sound | `get_windows_passing_filter()` | 5x | Filter mask inspection |
| PointProcess | `get_values_from_sound()` | 20x | Shimmer amplitude extraction |
| PointProcess | `get_periods_vector()` | 10x | Jitter period analysis |
| PointProcess | `get_jitter_batch()` | 5x | All jitter measures at once |
| Spectrum | `get_power_at_frequencies()` | 10x | Harmonic power extraction |

---

### Pattern 2k: Pipeline Operations (v4.3.0+)

**Performance:** 5-10x faster for multi-step analysis workflows.

Pipeline functions combine common multi-step workflows into single optimized calls.

#### Two-Pass Adaptive Pitch Extraction

**Problem:** Fixed pitch range often misses speaker's actual range (creaky voice = low, children = high).

**Solution:** `two_pass_adaptive_pitch()` - Speaker-adaptive pitch extraction in one call.

```r
# OLD WAY: Manual two-pass implementation (5+ function calls)
pitch_rough <- to_pitch_cc_direct(sound, pitch_floor = 50, pitch_ceiling = 800)
range <- pitch_get_adaptive_range(pitch_rough, q1_factor = 0.75, q3_factor = 1.5, unit = 0L)
pitch_refined <- to_pitch_cc_direct(sound, pitch_floor = range$min_pitch, pitch_ceiling = range$max_pitch)

# NEW WAY: Single pipeline function (v4.3.0+)
result <- two_pass_adaptive_pitch(sound)
# Returns: list(pitch, min_pitch, max_pitch, q1, q3)

pitch_ptr <- result$pitch          # Refined pitch XPtr
speaker_range <- c(result$min_pitch, result$max_pitch)  # Speaker's pitch range

# Customization options:
result <- two_pass_adaptive_pitch(
  sound,
  initial_floor = 75,       # Start higher for known adult
  initial_ceiling = 500,    # Start lower for known adult
  voicing_threshold = 0.5,  # Stricter voicing detection
  q1_factor = 0.80,         # Less aggressive low bound (default: 0.75)
  q3_factor = 1.25,         # Less aggressive high bound (default: 1.5)
  method = "ac"             # Use autocorrelation method (default: "cc")
)
```

**Use cases:**
- Speaker-adaptive pitch tracking (unknown speaker demographics)
- Creaky voice analysis (needs lower floor detection)
- Child speech analysis (needs higher ceiling detection)
- Clinical voice analysis (abnormal pitch ranges)

#### Batch Voice Quality Metrics

**Problem:** Getting all jitter/shimmer measures requires 11 separate C++ calls.

**Solution:** `get_jitter_shimmer_batch()` - All 11 metrics in one C++ call.

```r
# Create PointProcess from Sound + Pitch
result <- two_pass_adaptive_pitch(sound)
pp <- to_point_process_from_sound_and_pitch(sound, result$pitch)

# OLD WAY: 11 separate calls
jitter_local <- pp$get_jitter_local(0, 0, 0.0001, 0.02, 1.3)
jitter_rap <- pp$get_jitter_rap(0, 0, 0.0001, 0.02, 1.3)
shimmer_local <- pp$get_shimmer_local(sound, 0, 0, 0.0001, 0.02, 1.3, 1.6)
# ... 8 more calls ...

# NEW WAY: Single batch call (v4.3.0+)
metrics <- get_jitter_shimmer_batch(pp, sound)
# Returns named list with all 11 metrics:
# $jitter_local, $jitter_local_abs, $jitter_rap, $jitter_ppq5, $jitter_ddp
# $shimmer_local, $shimmer_local_db, $shimmer_apq3, $shimmer_apq5, $shimmer_apq11, $shimmer_dda

# Extract what you need
jitter_local <- metrics$jitter_local
shimmer_apq3 <- metrics$shimmer_apq3

# Custom parameters
metrics <- get_jitter_shimmer_batch(
  pp, sound,
  from_time = 0.5, to_time = 1.5,   # Time range
  period_floor = 0.0001,             # Min period (default)
  period_ceiling = 0.02,             # Max period (default)
  max_period_factor = 1.3,           # Jitter threshold (default)
  max_amplitude_factor = 1.6         # Shimmer threshold (default)
)
```

#### Complete Voice Quality Workflow (v4.3.0)

**Combine both functions for optimal voice quality analysis:**

```r
# Load sound
sound <- Sound("patient_vowel.wav")

# Step 1: Adaptive pitch extraction (handles unknown speaker range)
pitch_result <- two_pass_adaptive_pitch(sound)

# Step 2: Create glottal pulses
pp <- to_point_process_from_sound_and_pitch(sound, pitch_result$pitch)

# Step 3: Get all voice quality metrics
metrics <- get_jitter_shimmer_batch(pp, sound)

# Step 4: Calculate additional measures
mean_f0 <- get_pitch_mean_direct(pitch_result$pitch)
stdev_f0 <- get_pitch_stdev_direct(pitch_result$pitch)
hnr <- mean(to_harmonicity_direct(sound)$values, na.rm = TRUE)

# Combine into report
voice_quality <- c(
  mean_f0 = mean_f0,
  stdev_f0 = stdev_f0,
  pitch_range = paste0(round(pitch_result$min_pitch), "-", round(pitch_result$max_pitch), " Hz"),
  hnr = hnr,
  metrics
)
```

| Function | Speedup | Use Case |
|----------|---------|----------|
| `two_pass_adaptive_pitch()` | 2x | Speaker-adaptive pitch extraction |
| `get_jitter_shimmer_batch()` | 5-10x | All 11 voice quality metrics |

#### API Reference: `two_pass_adaptive_pitch()`

**Signature:**
```r
two_pass_adaptive_pitch(
  sound,                      # Sound XPtr or wrapper object
  time_step = 0,              # 0 = auto (0.75 / initial_floor)
  initial_floor = 50,         # Pass 1 pitch floor (Hz)
  initial_ceiling = 800,      # Pass 1 pitch ceiling (Hz)
  voicing_threshold = 0.45,   # Voicing detection threshold
  silence_threshold = 0.03,   # Silence detection threshold
  octave_cost = 0.01,         # Cost of octave jumps
  octave_jump_cost = 0.35,    # Cost of octave jump transitions
  voiced_unvoiced_cost = 0.14,# Cost of V→U transitions
  q1_factor = 0.75,           # min_pitch = Q1 * q1_factor
  q3_factor = 1.5,            # max_pitch = Q3 * q3_factor
  method = c("cc", "ac")      # "cc" (cross-correlation) or "ac" (autocorrelation)
)
```

**Returns:** Named list with:
| Element | Type | Description |
|---------|------|-------------|
| `pitch` | XPtr | Refined Pitch object from Pass 2 |
| `min_pitch` | numeric | Adaptive floor (Q1 × q1_factor), in Hz |
| `max_pitch` | numeric | Adaptive ceiling (Q3 × q3_factor), in Hz |
| `q1` | numeric | 25th percentile of Pass 1 F0, in Hz |
| `q3` | numeric | 75th percentile of Pass 1 F0, in Hz |

**Note:** If no voiced frames detected, returns Pass 1 pitch with initial range.

#### API Reference: `get_jitter_shimmer_batch()`

**Signature:**
```r
get_jitter_shimmer_batch(
  pointprocess,               # PointProcess XPtr or wrapper object
  sound,                      # Sound XPtr or wrapper object
  from_time = 0,              # Start time (0 = beginning)
  to_time = 0,                # End time (0 = end)
  period_floor = 0.0001,      # Min period (seconds)
  period_ceiling = 0.02,      # Max period (seconds)
  max_period_factor = 1.3,    # Jitter threshold
  max_amplitude_factor = 1.6  # Shimmer threshold
)
```

**Returns:** Named list with 11 metrics (all as **fractions**, not percentages):
| Element | Unit | Description |
|---------|------|-------------|
| `jitter_local` | fraction | Local jitter (relative period variation) |
| `jitter_local_abs` | seconds | Absolute local jitter |
| `jitter_rap` | fraction | Relative average perturbation |
| `jitter_ppq5` | fraction | 5-point period perturbation quotient |
| `jitter_ddp` | fraction | Difference of differences of periods |
| `shimmer_local` | fraction | Local shimmer (amplitude variation) |
| `shimmer_local_db` | dB | Local shimmer in decibels |
| `shimmer_apq3` | fraction | 3-point amplitude perturbation quotient |
| `shimmer_apq5` | fraction | 5-point amplitude perturbation quotient |
| `shimmer_apq11` | fraction | 11-point amplitude perturbation quotient |
| `shimmer_dda` | fraction | Difference of differences of amplitudes |

**To convert fractions to percentages:** Multiply by 100 (e.g., `jitter_local * 100`).

#### API Reference: `to_point_process_from_sound_and_pitch()`

**When to use this vs alternatives:**

| Method | When to Use | Praat Equivalent |
|--------|-------------|------------------|
| `to_point_process_from_sound_and_pitch(sound, pitch)` | **Recommended** for jitter/shimmer. Uses pitch-guided peak detection. | Select Sound + Pitch → "To PointProcess (cc)" |
| `sound$to_point_process_periodic_cc()` | Sound-only analysis. Less accurate for voice quality. | Select Sound → "To PointProcess (periodic, cc)" |
| `to_point_process_direct(sound)` | Direct API version of above. | Same as above |

**Why Sound+Pitch is better:**
- Uses refined pitch information to guide glottal pulse detection
- More accurate period identification for jitter/shimmer
- Matches Praat's recommended workflow for voice quality analysis
- Required for clinical voice assessment (DSI, AVQI, etc.)

**Example:**
```r
# RECOMMENDED: Use Sound + Pitch (matches Praat best practice)
pitch_result <- two_pass_adaptive_pitch(sound)
pp <- to_point_process_from_sound_and_pitch(sound, pitch_result$pitch)
metrics <- get_jitter_shimmer_batch(pp, sound)

# NOT RECOMMENDED for voice quality (less accurate):
pp <- sound$to_point_process_periodic_cc()  # Sound-only, no pitch guidance
```

---

### Pattern 2l: Tier 4 Ultra API (v4.6.3+) - Production Ready ✅

**Performance:** 5-77x faster for DSI and clinical voice workflows.

**Status:** All critical bugs fixed - production ready for AVQI and DSI workflows!

Tier 4 "Ultra" functions keep entire analysis workflows in C++, returning only final scalars. Eliminates intermediate object creation and R-side coordination.

**Bug Fix Summary (v4.6.3):**
- ✅ `extract_voiced_segments_ultra()`: Fixed v2.03/v3.01 algorithm inconsistency
- ✅ `calculate_cpps_ultra()`: Fixed NA return issue (parameter mapping)
- ✅ `calculate_minimum_intensity_ultra()`: Algorithm fix verified working

**Agent Recommendation:** Use Tier 4 Ultra API for all clinical voice analysis workflows.

#### `get_durations_batch()` - Fast WAV Duration Reading

**Problem:** Getting audio durations via `LongSound()` or `Sound()` loads entire file.

**Solution:** Read only 44-byte WAV header for instant duration extraction.

```r
# OLD WAY: Load entire file (slow for many files)
durations <- sapply(wav_files, function(f) {
  sound <- Sound(f)
  sound$get_xmax() - sound$get_xmin()
})

# NEW WAY: Header-only reading (77x faster)
durations <- get_durations_batch(wav_files)
```

**Signature:**
```r
get_durations_batch(file_paths)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `file_paths` | character | Vector of .wav file paths |

**Returns:** Numeric vector of durations (seconds). NA for invalid/missing files.

#### `calculate_f0_stats_ultra()` - Single-Call F0 Statistics

**Problem:** Getting F0 statistics requires creating Pitch object, then calling stat method.

**Solution:** Single C++ call returns statistic directly.

```r
# OLD WAY: Create intermediate Pitch object
pitch <- sound$to_pitch_cc(pitch_floor = 75, pitch_ceiling = 600)
max_f0 <- pitch$get_maximum(0, 0, "hertz", TRUE)

# NEW WAY: Direct statistic (5x faster)
max_f0 <- calculate_f0_stats_ultra(sound, stat = "max", min_pitch = 75, max_pitch = 600)
```

**Signature:**
```r
calculate_f0_stats_ultra(
  sound,                    # Sound object
  stat = "max",             # "max", "min", "mean", "median", "sd"
  time_step = 0,            # 0 = auto

  min_pitch = 75,           # Pitch floor (Hz)
  max_pitch = 600,          # Pitch ceiling (Hz)
  voicing_threshold = 0.45  # Voicing detection threshold
)
```

**Returns:** Single numeric value (Hz for pitch stats, NA if no voiced frames).

#### `calculate_minimum_intensity_ultra()` - Voiced-Region Intensity

**Problem:** DSI requires minimum intensity in voiced regions only—needs Pitch→PointProcess→TextGrid→Intensity pipeline.

**Solution:** Complete DSI-compliant pipeline in single C++ call.

**Algorithm (v4.4.1 - DSI compliant):**
1. Extract pitch with DSI parameters (`voicing_threshold=0.8`, `very_accurate=FALSE`)
2. Create PointProcess from Sound + Pitch
3. Create TextGrid with VUV segmentation (`maxPeriod=0.02`, `meanPeriod=0.01`)
4. Extract and **concatenate** all voiced intervals
5. Calculate intensity on concatenated sound (`minimum_pitch=60`, DSI standard)
6. Return minimum intensity from concatenated voiced regions

```r
# OLD WAY: Multi-step pipeline
pitch <- sound$to_pitch_cc(pitch_floor = 70, voicing_threshold = 0.8)
pp <- to_point_process_from_sound_and_pitch(sound, pitch)
tg <- pp$to_textgrid_vuv(0.02, 0.01)
# ... extract voiced intervals, concatenate, calculate intensity ...

# NEW WAY: Single call (6x faster, DSI-compliant)
min_int <- calculate_minimum_intensity_ultra(sound, min_pitch = 70)  # explicit override; see default below
```

**Signature:**
```r
calculate_minimum_intensity_ultra(
  sound,                 # Sound object
  min_pitch = 75,        # Pitch floor (Hz) for pitch extraction
  max_pitch = 600,       # Pitch ceiling (Hz) for pitch extraction
  time_step = 0,         # 0 = auto
  subtract_mean = TRUE   # Subtract mean for intensity calculation
)
```

**Returns:** Minimum intensity (dB) from concatenated voiced regions. NA if no voiced frames.

**Note:** Intensity calculation uses `minimum_pitch=60` internally (DSI standard), not the `min_pitch` parameter which is only for pitch extraction.

#### `get_voice_quality_ultra()` - Complete Voice Quality Metrics

**Problem:** Getting jitter/shimmer/HNR requires creating Pitch, PointProcess, then batch calls.

**Solution:** All metrics from single C++ call with selective computation.

```r
# OLD WAY: Multi-object pipeline
pitch <- sound$to_pitch_cc(pitch_floor = 75)
pp <- to_point_process_from_sound_and_pitch(sound, pitch)
metrics <- get_jitter_shimmer_batch(pp, sound)

# NEW WAY: Single call with selective metrics
vq <- get_voice_quality_ultra(sound, metrics = "all", min_pitch = 75)
# Or request specific metrics:
vq <- get_voice_quality_ultra(sound, metrics = "jitter", min_pitch = 75)
# Or match Praat's plain To Pitch... + PointProcess (cc) DSI path:
vq <- get_voice_quality_ultra(sound, metrics = "jitter",
                              pitch_method = "ac", very_accurate = FALSE)
```

**Signature:**
```r
get_voice_quality_ultra(
  sound,                 # Sound object
  metrics = "all",       # "all", "jitter", "shimmer", "hnr", or vector
  min_pitch = 75,        # Pitch floor (Hz)
  max_pitch = 600,       # Pitch ceiling (Hz)
  time_step = 0,         # 0 = auto
  pitch_method = "cc",   # default keeps existing Tier 4 behaviour
  very_accurate = TRUE   # use FALSE with pitch_method="ac" for Praat parity
)
```

**Returns:** Named list with requested metrics:

| Metric Group | Elements |
|--------------|----------|
| `jitter` | `jitter_local`, `jitter_rap`, `jitter_ppq5`, `jitter_ddp` |
| `shimmer` | `shimmer_local`, `shimmer_local_db`, `shimmer_apq3`, `shimmer_apq5`, `shimmer_apq11`, `shimmer_dda` |
| `hnr` | `hnr_mean`, `hnr_sd` |

#### Complete DSI Workflow Example (v4.4.1)

**Dysphonia Severity Index calculation with Tier 4 Ultra:**

```r
# Load test files
mpt_file <- "maximum_phonation_time.wav"
fh_file <- "highest_frequency.wav"
im_file <- "lowest_intensity.wav"
ppq_file <- "sustained_vowel.wav"

# Tier 4 Ultra workflow (~195ms vs ~520ms with Tier 2/3)
max_mpt <- max(get_durations_batch(mpt_file))
max_f0 <- calculate_f0_stats_ultra(Sound(fh_file), "max", min_pitch = 70, max_pitch = 600)
min_int <- calculate_minimum_intensity_ultra(Sound(im_file), min_pitch = 70)  # Uses DSI-compliant algorithm
vq <- get_voice_quality_ultra(Sound(ppq_file), "jitter", min_pitch = 70)
jitter_ppq5 <- vq$jitter_ppq5

# DSI formula (add +10 dB calibration to min_int if needed)
dsi <- 0.13 * max_mpt + 0.0053 * max_f0 - 0.26 * min_int - 1.18 * (jitter_ppq5 * 100) + 12.4
```

| Function | Target Speedup | Use Case |
|----------|----------------|----------|
| `get_durations_batch()` | 77x | MPT measurement |
| `calculate_f0_stats_ultra()` | 5x | FH (highest frequency) |
| `calculate_minimum_intensity_ultra()` | 6x | IM (lowest intensity) |
| `get_voice_quality_ultra()` | 3.6x | PPQ (jitter) |
| `calculate_cpps_ultra()` | 1.6x | AVQI CPPS extraction |
| `extract_voiced_segments_ultra()` | 2-4x | AVQI/VQ voiced extraction |
| `calculate_multiband_hnr_ultra()` | 2-2.5x | VQ multi-band HNR |

#### `calculate_cpps_ultra()` - Direct Sound→CPPS (v4.4.1+)

**Problem:** CPPS calculation requires creating PowerCepstrogram then calling `get_cpps()`.

**Solution:** Single C++ call creates PowerCepstrogram internally and returns CPPS directly.

```r
# OLD WAY: Two-step with intermediate object
pcep <- sound$to_powercepstrogram(60, 0.002, 5000, 50)
cpps <- pcep$get_cpps(subtract_tilt = TRUE, time_averaging_window = 0.001,
                      quefrency_averaging_window = 0.0005, pitch_floor = 60, pitch_ceiling = 333.3)

# NEW WAY: Direct single call (1.6x faster)
cpps <- calculate_cpps_ultra(sound)

# With custom parameters
cpps <- calculate_cpps_ultra(
  sound,
  time_averaging_window = 0.001,
  quefrency_averaging_window = 0.0005,
  pitch_floor = 60,
  pitch_ceiling = 333.3,
  subtract_trend = TRUE,
  time_step = 0.002,
  max_quefrency = 0.04,
  tolerance = 0.05,
  interpolation = "parabolic",
  tilt_line_quefrency = 0.003,
  line_type = "straight",
  fit_method = "robust",
  pre_emphasis_from = 50,
  max_frequency = 5000
)
```

**Signature:**
```r
calculate_cpps_ultra(
  sound,                                 # Sound object
  time_averaging_window = 0.001,         # CPPS smoothing window
  quefrency_averaging_window = 0.0005,   # Quefrency smoothing
  pitch_floor = 60,                      # Lowest pitch for cepstrogram
  pitch_ceiling = 333.3,                 # Highest pitch for cepstrogram
  subtract_trend = TRUE,                 # Remove spectral tilt/trend
  time_step = 0.002,                     # Frame shift
  max_quefrency = 0.04,                  # Max quefrency for trend fit
  tolerance = 0.05,                      # Peak-picking tolerance
  interpolation = "parabolic",           # "none", "parabolic"
  tilt_line_quefrency = 0.003,           # Trend-line start quefrency
  line_type = "straight",                # "straight", "exponential_decay"
  fit_method = "robust",                 # "least_squares", "robust"
  pre_emphasis_from = 50,                # Pre-emphasis frequency
  max_frequency = 5000                   # Max analysis frequency
)
```

**Note:** `line_type = "straight"` and `tilt_line_quefrency = 0.003` are the correct current defaults
(fixed in v4.6.4 and v4.9.10 respectively, from earlier broken defaults `"exponential_decay"` / `0.001` —
see `R/performance-helpers.R:551` and CLAUDE.md's CPPS parameter-default warning). Do not revert to the old values.

**Returns:** Single numeric value (dB). NA if calculation fails.

**Use case:** AVQI v2.03 and v3.01 require CPPS calculation on voiced-only audio. This function eliminates PowerCepstrogram object overhead.

#### `extract_voiced_segments_ultra()` - AVQI-Compliant Voiced Extraction (v4.4.1+)

**Problem:** AVQI requires extracting and concatenating voiced segments with optional power/ZCR filtering (v3.01). Multi-step pipeline in R is slow.

**Solution:** Complete voiced extraction pipeline in single C++ call. Supports both AVQI v2.03 (intensity-based) and v3.01 (windowed power + ZCR filtering).

**Algorithm (v4.6.2+):**
1. Create Intensity object from Sound (`Sound_to_Intensity` with `minPitch`, `timeStep=0.003s`)
2. Find maximum intensity; calculate threshold as `max_intensity + silence_threshold_db`
3. Detect sounding intervals by scanning intensity values above threshold
4. Extract and concatenate sounding intervals (min duration filtering applied)
5. **v3.01 only:** Apply windowed power + ZCR filtering:
   - Calculate global power threshold (default: 3% of global power)
   - Apply sliding windows (default: 0.03s, nonoverlapping)
   - For each window: calculate power and ZCR using `Sound_to_PointProcess_zeroes()`
   - ZCR formula (AVQI standard): `zcr = n_crossings / (last_crossing - first_crossing)`
   - Keep window if: `power > threshold AND zcr < max_zcr`
   - Concatenate passing windows
6. Return concatenated voiced Sound

**Note:** v4.6.2 changed from TextGrid-based silence detection to direct Intensity-based detection to avoid FFT crash in `Sound_to_TextGrid_detectSilences()`.

```r
# OLD WAY: Multi-step pipeline (6+ Praat calls)
tg <- sound_to_textgrid_detect_silences(sound, min_pitch = 100, silence_threshold = -25)
voiced_sounds <- list()
for (i in 1:tg$get_number_of_intervals(1)) {
  if (tg$get_interval_text(1, i) != "silent") {
    voiced_sounds <- c(voiced_sounds, list(sound$extract_part(...)))
  }
}
concatenated <- Reduce(function(a, b) a$concatenate(b), voiced_sounds)
# ... then v3.01 windowing + filtering ...

# NEW WAY: Single call (2-4x faster)
# AVQI v2.03 (intensity-based, simple)
voiced_203 <- extract_voiced_segments_ultra(sound, version = "v2.03")

# AVQI v3.01 (with windowed power + ZCR filtering)
voiced_301 <- extract_voiced_segments_ultra(
  sound,
  version = "v3.01",
  power_threshold_factor = 0.3,
  max_zcr = 3000,
  window_width = 0.03
)
```

**Signature:**
```r
extract_voiced_segments_ultra(
  sound,                          # Sound object
  version = "v3.01",              # "v2.03" or "v3.01"
  min_pitch = 50,                 # Silence detection pitch floor
  silence_threshold_db = -25,     # Silence detection threshold (dB)
  min_silent_duration = 0.1,      # Min silent duration (s)
  min_sounding_duration = 0.1,    # Min sounding duration (s)
  power_threshold_factor = 0.3,   # v3.01: Power threshold (fraction of global)
  max_zcr = 3000,                 # v3.01: Max zero-crossing rate (Hz)
  window_width = 0.03             # v3.01: Window width for power/ZCR (s)
)
```

**Returns:** Sound object (shared dispatch wrapper around XPtr) with concatenated voiced segments.

**Use case:** AVQI v2.03/v3.01 preprocessing. v3.01 is more robust (filters out low-power/high-ZCR segments).

**Performance:** 2-4x faster than R pipeline. Biggest bottleneck fix for AVQI (saves 4-6s on typical recordings).

#### `calculate_multiband_hnr_ultra()` / reusable multiband HNR path

**Problem:** VQ (Voice Quality) assessment needs HNR in 5 frequency bands. The
one-shot path is fine for one interval, but repeated intervals on the same
`Sound` should not rebuild the same 5 Harmonicity objects every time.

**Solution:**
- Use `calculate_multiband_hnr_ultra(sound, ...)` for one-shot / whole-sound summaries
- Use `build_multiband_harmonicity(sound, ...)` once, then
  `multiband_hnr_stats(...)` for repeated interval queries

**Algorithm:**
1. For each of 5 bands: `full`, `0-500`, `0-1500`, `0-2500`, `0-3500`
2. Apply the Hann band filter for the non-full bands
3. Create CC Harmonicity (`time_step=0.005`, `min_pitch=75`, `silence_threshold=0.1`, `periods_per_window=1`)
4. Either:
   - return mean + SD immediately (one-shot), or
   - keep the 5 Harmonicity objects for later interval queries

```r
# One-shot path
hnr <- calculate_multiband_hnr_ultra(sound)
# Returns: list(
#   full_mean, full_sd,
#   band500_mean, band500_sd,
#   band1500_mean, band1500_sd,
#   band2500_mean, band2500_sd,
#   band3500_mean, band3500_sd
# )

# Reusable path for multiple intervals on the same sound
built <- build_multiband_harmonicity(sound)
hnr_i1 <- multiband_hnr_stats(built, 0, 0.5)
hnr_i2 <- multiband_hnr_stats(built, 0.5, 1.0)
```

**Signatures:**
```r
calculate_multiband_hnr_ultra(
  sound,                      # Sound object
  bands = c(0, 500, 1500, 2500, 3500),
  time_step = 0.005,
  min_pitch = 75,
  from_time = 0,
  to_time = 0
)

build_multiband_harmonicity(
  sound,
  bands = c(0, 500, 1500, 2500, 3500),
  time_step = 0.005,
  min_pitch = 75
)

multiband_hnr_stats(
  multiband,
  from_time = 0,
  to_time = 0
)
```

**Returns:**
- `calculate_multiband_hnr_ultra()` -> named list with 10 elements:
| Element | Description |
|---------|-------------|
| `full_mean` | Mean HNR for full spectrum |
| `full_sd` | SD of HNR for full spectrum |
| `band500_mean` | Mean HNR for 0-500 Hz |
| `band500_sd` | SD of HNR for 0-500 Hz |
| `band1500_mean` | Mean HNR for 0-1500 Hz |
| `band1500_sd` | SD of HNR for 0-1500 Hz |
| `band2500_mean` | Mean HNR for 0-2500 Hz |
| `band2500_sd` | SD of HNR for 0-2500 Hz |
| `band3500_mean` | Mean HNR for 0-3500 Hz |
| `band3500_sd` | SD of HNR for 0-3500 Hz |

- `build_multiband_harmonicity()` -> named list of 5 `Harmonicity` objects:
  `full`, `band500`, `band1500`, `band2500`, `band3500`

**Use case:** simple one-shot VQ summaries vs repeated-interval VQ workflows on
the same sound. Matches `VQ_measurements_V2.praat` lines 102-122.

**Note:** `bands` must have exactly 5 elements. The first element uses `0` as
the full-spectrum sentinel in the current API.

#### AVQI v3.01 Complete Workflow (v4.4.1)

**Acoustic Voice Quality Index calculation with new Tier 4 Ultra functions:**

```r
sound <- Sound("sustained_vowel.wav")

# Step 1: Extract voiced segments (AVQI v3.01 with power + ZCR filtering)
voiced <- extract_voiced_segments_ultra(sound, version = "v3.01")

# Step 2: Calculate CPPS on voiced audio
cpps <- calculate_cpps_ultra(voiced)

# Step 3: Calculate multi-band HNR
hnr <- calculate_multiband_hnr_ultra(voiced)

# Step 4: Calculate other AVQI metrics (shimmer, slope, tilt)
# ... standard pladdrr functions ...

# AVQI formula components now available:
avqi_cpps <- cpps
avqi_hnr <- hnr$band3500_mean  # HNR 0-3500Hz
# ... combine with other metrics per AVQI formula ...
```

**Performance improvement:**
- AVQI benchmark: 19.8s → 12.3s (1.6x speedup)
- VQ benchmark: 1.35s → 0.9s (1.5x speedup)
- Code reduction in plabench: 210 lines → 14 lines (93% reduction)

---

### Pattern 2m: Prosodic Analysis Workflows (v4.8.24+)

**Use case:** Batch feature extraction at target times (INTSINT points, syllable nuclei, etc.) — common in prosodic analysis packages like dysprosody and superassp.

#### Pre-extract all formants at target times (batch)

```r
sound <- Sound("utterance.wav")
formant <- sound$to_formant_burg()
targets <- c(0.15, 0.35, 0.52, 0.71)  # e.g., syllable nuclei

# FAST: batch query per formant number
f1 <- formant$get_values_at_times(1, targets)
f2 <- formant$get_values_at_times(2, targets)
f3 <- formant$get_values_at_times(3, targets)

# Or get all formants at a single time point
all_f <- formant$get_all_values_at_time(0.35, max_formants = 5)
# Returns: numeric(5) with NA for missing formants
```

#### Intensity at target times (batch)

```r
intensity <- sound$to_intensity()
int_vals <- intensity$get_values_at_times(targets)
```

#### LTAS spectral analysis

```r
ltas <- sound$to_ltas(100)

# Spectral slope (convenience — returns scalar)
slope <- ltas$get_spectral_slope(100, 5000)

# Full trend report (slope, intercept, R², fitted values)
trend <- ltas$report_spectral_trend(100, 5000)

# Harmonic peaks in frequency bands
peaks <- ltas$get_peaks_batch(
  fmins = c(0, 1000, 2000, 3000),
  fmaxs = c(1000, 2000, 3000, 4000)
)

# Values at specific frequencies
vals <- ltas$get_values_at_frequencies(c(500, 1000, 2000, 4000))
```

#### Performance: loop vs batch

```r
# SLOW: loop per target per formant
for (t in targets) {
  for (fn in 1:5) formant$get_value_at_time(fn, t)  # N*5 C++ calls
}

# FAST: batch per formant (N calls total, vectorized in C++)
for (fn in 1:5) formant$get_values_at_times(fn, targets)
```

---

### Pattern 2n: Advanced Audio Analysis (v4.8.25+)

**New Tier 1 and Tier 2 methods for specialized audio processing.**

#### Tier 1: High-Impact Audio Processing

##### Time-Stretching with Overlap-Add

**Use case:** Change playback speed without changing pitch (time compression/expansion).

```r
sound <- Sound("speech.wav")

# Slow down by 50% (factor > 1)
slower <- sound$lengthen(fmin = 75, fmax = 600, factor = 1.5)

# Speed up by 20% (factor < 1)
faster <- sound$lengthen(fmin = 75, fmax = 600, factor = 0.8)
```

**Parameters:**
- `fmin`, `fmax`: Pitch range for analysis (Hz)
- `factor`: Time stretch factor (1.5 = 50% slower, 0.5 = 50% faster)

**Praat equivalent:** `Sound: Lengthen (overlap-add)...`

##### Pitch-Corrected LTAS for Voice Quality

**Use case:** LTAS that adapts to speaker's fundamental frequency, used in voice quality assessment.

```r
sound <- Sound("vowel.wav")

# Standard LTAS (fixed frequency bins)
ltas_std <- sound$to_ltas(bandwidth = 100)

# Pitch-corrected LTAS (harmonic structure preserved)
ltas_pc <- sound$to_ltas_pitch_corrected(
  pitch_floor = 75,
  pitch_ceiling = 600,
  max_frequency = 5000,
  bandwidth = 100,
  shortest_period = 0.0001,
  longest_period = 0.02,
  max_period_factor = 1.3
)
```

**Praat equivalent:** `Sound: To Ltas (pitch-corrected)...`

##### Robust Formant Tracking (Outlier Removal)

**Use case:** Formant tracking with automatic outlier detection and removal (iterative refinement).

```r
sound <- Sound("vowel.wav")

# Standard formant tracking
formant_std <- sound$to_formant_burg(
  time_step = 0.005,
  max_formants = 5,
  max_frequency = 5500
)

# Robust formant tracking (removes outliers, iteratively refines)
formant_robust <- sound$to_formant_robust(
  time_step = 0.005,
  max_formants = 5.0,
  max_frequency = 5500,
  window_length = 0.025,
  pre_emphasis_from = 50,
  num_std_dev = 1.5,      # Outlier threshold (standard deviations)
  max_iterations = 5       # Refinement iterations
)
```

**Praat equivalent:** `Sound: To Formant (robust)...`

**Use cases:**
- Pathological voice (creaky, breathy) with irregular formants
- Continuous speech with rapid formant transitions
- Noisy recordings where Burg tracking fails

##### Formant-Based Filtering

**Use case:** Filter sound using formant structure (e.g., remove formants, inverse filter).

```r
sound <- Sound("vowel.wav")
formant <- sound$to_formant_burg()

# Filter by formant structure (with intensity scaling)
filtered <- sound$filter_by_formant(formant)

# Filter without intensity scaling
filtered_noscale <- sound$filter_by_formant_noscale(formant)
```

**Praat equivalents:**
- `Sound & Formant: Filter`
- `Sound & Formant: Filter (no scale)`

##### MelSpectrogram and BarkSpectrogram

**Use case:** Psychoacoustic spectrograms for perceptual analysis, MFCC computation.

```r
sound <- Sound("speech.wav")

# Create mel-scale spectrogram (common in speech recognition)
mel_spec <- sound$to_mel_spectrogram(
  window_length = 0.025,
  time_step = 0.01,
  first_filter_frequency = 100,  # mel
  frequency_step = 100,          # mel (distance between filters)
  max_frequency = 0              # 0 = Nyquist
)

# Inspect values via matrix export (no per-cell query methods on MelSpectrogram)
mel_mat <- mel_spec$as_matrix(to_db = TRUE)

# Convert to MFCC
mfcc <- mel_spec$to_mfcc(number_of_coefficients = 12)

# Convert to Matrix for further processing
matrix <- mel_spec$to_matrix()

# Convert to Intensity (band energy over time)
intensity <- mel_spec$to_intensity()

# Create bark-scale spectrogram (auditory filter bank)
bark_spec <- sound$to_bark_spectrogram(
  window_length = 0.025,
  time_step = 0.01,
  first_filter_frequency = 1,  # Bark
  frequency_step = 1,          # Bark (distance between filters)
  max_frequency = 0            # 0 = Nyquist
)

# Inspect values via matrix export (no per-cell query methods on BarkSpectrogram)
bark_mat <- bark_spec$as_matrix(to_db = TRUE)

# Convert to Matrix or Intensity
bark_matrix <- bark_spec$to_matrix()
bark_intensity <- bark_spec$to_intensity()
```

**Praat equivalents:**
- `Sound: To MelSpectrogram...`
- `Sound: To BarkSpectrogram...`

#### Tier 2: Useful Signal Processing Additions

##### Autocorrelation

```r
sound <- Sound("tone.wav")
autocorr <- sound$autocorrelate()  # Returns new Sound with autocorrelation
```

**Praat equivalent:** `Sound: Autocorrelate...`

##### Deep Band Modulation

**Use case:** Enhance modulation in specific frequency band.

```r
sound <- Sound("speech.wav")
enhanced <- sound$deepen_band_modulation(
  enhancement_db = 10,
  flow = 300,
  fhigh = 4000,
  slow_modulation = 3,
  fast_modulation = 30,
  band_smoothing = 100
)
```

**Praat equivalent:** `Sound: Deepen band modulation...`

##### Convolution and Cross-Correlation

```r
sound1 <- Sound("signal.wav")
sound2 <- Sound("impulse.wav")

# Convolve two sounds (impulse response, filtering)
convolved <- sound1$convolve(sound2, scaling = "normalize", signal_outside = "zero")

# Cross-correlate two sounds (similarity measure)
xcorr <- sound1$cross_correlate(sound2, scaling = "normalize", signal_outside = "zero")
```

**Praat equivalents:**
- `Sound & Sound: Convolve...`
- `Sound & Sound: Cross-correlate...`

##### MFCC ↔ MelSpectrogram Conversion

```r
sound <- Sound("speech.wav")
mfcc <- sound$to_mfcc()

# Reverse conversion: MFCC → MelSpectrogram
mel_spec <- mfcc$to_mel_spectrogram()
```

**Praat equivalent:** `MFCC: To MelSpectrogram...`

##### LPC to Spectrogram

```r
sound <- Sound("vowel.wav")
lpc <- sound$to_lpc_burg(prediction_order = 16, analysis_width = 0.025, time_step = 0.005)

# Convert LPC to Spectrogram for visualization
spec <- lpc$to_spectrogram(
  df_min = 20.0,                 # minimum frequency resolution (Hz)
  bandwidth_reduction = 0.0,
  de_emphasis_frequency = 50.0
)
```

**Praat equivalent:** `LPC: To Spectrogram...`

##### PointProcess Sound Generation

```r
pp <- PointProcess(xmin = 0, xmax = 1)
pp$add_point(0.1)
pp$add_point(0.2)
pp$add_point(0.3)

# Generate pulse train (Dirac deltas at pulse times)
pulse_train <- pp$to_sound_pulse_train(
  sampling_frequency = 44100,
  adapt_factor = 1.0,
  adapt_time = 0.05,
  interpolation_depth = 30L
)

# Generate harmonic hum (sum of sines at pulse frequencies) — takes no parameters
hum <- pp$to_sound_hum()
```

**Praat equivalents:**
- `PointProcess: To Sound (pulse train)...`
- `PointProcess: To Sound (hum)...`

##### Intensity-Based Silence Detection

**Use case:** Create TextGrid with silence/sounding intervals.

```r
sound <- Sound("speech.wav")
intensity <- sound$to_intensity(minimum_pitch = 100)

# Detect silences and create TextGrid
tg <- intensity$to_textgrid_silences(
  silence_threshold = -25,       # dB relative to max
  min_silence_duration = 0.3,    # seconds
  min_sounding_duration = 0.1,   # seconds
  silent_label = "silent",
  sounding_label = "sounding"
)
```

**Praat equivalent:** `Intensity: To TextGrid (silences)...`

##### Table Operations

```r
formant <- sound$to_formant_burg()
table <- formant$down_to_table(include_frame_numbers = TRUE,
                                include_time = TRUE,
                                time_decimals = 6,
                                include_intensity = FALSE,
                                include_number_of_formants = TRUE,
                                include_bandwidths = TRUE)

# Sort by column
sorted <- table$sort_rows("F1(Hz)")

# Extract rows where numeric column matches condition
high_f1 <- table$extract_rows_where_number("F1(Hz)", 0, 500)  # 0 = "greater than"

# Extract rows where string column matches
voiced <- table$extract_rows_where_string("label", 2, "voiced")  # 2 = "contains"
```

**Praat equivalents:**
- `Table: Sort rows...`
- `Table: Extract rows where column (number)...`
- `Table: Extract rows where column (text)...`

##### Average Multiple LTAS

**Use case:** Combine LTAS from multiple speakers or recordings.

```r
ltas1 <- Sound("speaker1.wav")$to_ltas(100)
ltas2 <- Sound("speaker2.wav")$to_ltas(100)
ltas3 <- Sound("speaker3.wav")$to_ltas(100)

# Average LTAS objects
avg_ltas <- ltas_average(list(ltas1, ltas2, ltas3))
```

**Praat equivalent:** Select multiple Ltas → `Ltases: Average`

---

### Pattern 2o: Tier 3 Audio Processing (v4.8.26+)

#### Speaker Transformation (Change Gender / Change Speaker)

**Use case:** Modify speaker characteristics by independently scaling formant frequencies (vocal tract length), pitch level, pitch range, and duration.

```r
sound <- Sound("speech.wav")

# Change to higher-pitched speaker (e.g., female → child)
transformed <- sound$change_speaker(
  pitch_floor = 75,              # Min pitch for analysis
  pitch_ceiling = 600,           # Max pitch for analysis
  formant_multiplier = 1.2,      # Raise formants 20% (shorter vocal tract)
  pitch_multiplier = 1.3,        # Raise pitch 30%
  pitch_range_multiplier = 1.0,  # Keep pitch range
  duration_multiplier = 1.0      # Keep duration
)

# Change gender (typical male → female)
female <- sound$change_speaker(
  formant_multiplier = 1.1,
  pitch_multiplier = 1.8,
  pitch_range_multiplier = 1.2,
  duration_multiplier = 1.0
)

# Use existing Pitch object (more control)
pitch <- sound$to_pitch_ac()
modified <- sound$change_speaker_with_pitch(
  pitch = pitch,
  formant_multiplier = 1.1,
  pitch_multiplier = 1.5,
  pitch_range_multiplier = 1.0,
  duration_multiplier = 0.9      # Slightly faster
)
```

**Praat equivalents:**
- `Sound & Pitch: Change speaker...`
- `Sound: Change speaker...` (internal pitch extraction)

**Parameters:**
- `formant_multiplier`: Scales formant frequencies (> 1 = shorter vocal tract / higher formants)
- `pitch_multiplier`: Scales median pitch up/down
- `pitch_range_multiplier`: Scales excursion from median (> 1 = more melodic, < 1 = more monotone)
- `duration_multiplier`: Combined with formant_multiplier for final duration

#### Sound Creation from Scratch

```r
# Pure tone with fade in/out (avoids clicks)
tone <- sound_create_pure_tone(
  channels = 1,
  starting_time = 0,
  end_time = 0.5,
  sample_rate = 44100,
  frequency = 440,       # Hz (A4)
  amplitude = 0.5,       # 0–1
  fade_in_duration = 0.01,
  fade_out_duration = 0.01
)

# Also available as static method
tone <- Sound$create_pure_tone(440, amplitude = 0.7, end_time = 1.0)

# Harmonic complex tone (sum of sines)
# phase: 0 = sine, 1 = cosine, 2 = alternating sine/cosine
complex <- sound_create_tone_complex(
  starting_time = 0,
  end_time = 0.5,
  sample_rate = 44100,
  phase = 0L,              # 0=sine, 1=cosine, 2=alternating
  frequency_step = 100,    # Spacing between harmonics (Hz)
  first_frequency = 100,   # Fundamental / first harmonic
  ceiling = 10000,         # Max frequency to include
  number_of_components = 0L  # 0 = determined by ceiling
)

# Also available as static method
complex <- Sound$create_tone_complex(frequency_step = 200, first_frequency = 200)
```

**Praat equivalents:**
- `Create Sound as pure tone...`
- `Create Sound as tone complex...`

#### Spectrum Frequency Shifting

**Use case:** Shift all spectral energy by a fixed amount in Hz (useful for formant synthesis, frequency warping).

```r
sound <- Sound("vowel.wav")
spectrum <- sound$to_spectrum()

# Shift spectrum up by 200 Hz
shifted_up <- spectrum$shift_frequencies(
  shift_by = 200,                # Hz (positive = up, negative = down)
  new_maximum_frequency = 5000,  # Output bandwidth (0 = same as input)
  interpolation_depth = 50       # Sinc interpolation depth
)

# Shift down (frequency lowering)
shifted_down <- spectrum$shift_frequencies(shift_by = -500)

# Convert back to sound
shifted_sound <- shifted_up$to_sound()
```

**Praat equivalent:** `Spectrum: Shift frequencies...`

---

### Pattern 2p: Spectral Moments Batch (v4.9.1+)

**Performance:** 14× faster than per-frame R loop. Before this API existed, spectral moments
required ~2000 R→C++ round-trips per file (400 frames × 5 calls); Praat ran identical logic
14× faster in compiled C++. The batch API closes that gap by computing all frames in one C++
pass with no R-level iteration.

**Praat equivalent:** Loop over `Spectrum: Get centre of gravity...`, `...standard deviation...`,
`...skewness...`, `...kurtosis...` for every frame of a Spectrogram.

#### Spectral Moments (CoG, SD, Skewness, Kurtosis)

```r
spectrogram <- sound$to_spectrogram(
  window_length  = 0.005,
  max_frequency  = 5000,
  time_step      = 0.002,
  frequency_step = 20,
  window_shape   = "Gaussian"
)

# SLOW: Per-frame R loop — was 14× slower than Praat (0.514s vs 0.037s per file)
# Anti-pattern: 400 autoSpectrum C++ allocations + 1600 R→C++ crossings per file
moments_slow <- do.call(rbind, lapply(seq_len(spectrogram$.cpp$get_number_of_frames()), function(ix) {
  t    <- spectrogram$.cpp$get_time_from_frame(ix)
  spec <- spectrogram$to_spectrum(t)          # C++ object allocation per frame
  data.frame(
    time     = t,
    cog      = spec$get_centre_of_gravity(2.0),
    sd       = spec$get_standard_deviation(2.0),
    skewness = spec$get_skewness(2.0),
    kurtosis = spec$get_kurtosis(2.0)
  )
}))

# FAST: Single C++ pass (v4.9.1+) — no R-level iteration, no per-frame allocation
moments <- get_spectral_moments_batch(spectrogram, power = 2.0)
# Returns: data.frame(time, cog, sd, skewness, kurtosis) — one row per frame
# NA where CoG is undefined (zero-power frames)

# Also accessible as a method on the Spectrogram object:
moments <- spectrogram$get_spectral_moments_batch(power = 2.0)
```

**`power` parameter:** Matches Praat's "power" argument in spectral moment functions.
- `power = 2.0` (default): energy-weighted moments — standard Praat default
- `power = 1.0`: amplitude-weighted moments

**NA handling:** Frames with zero total power return `NA` for all four moments, matching
Praat's behaviour when the spectrum is silent.

---

### Pattern 3: Export to Data Frame (v4.0+: Returns data.table)

**NEW in v4.0:** All `as.data.frame()` methods now return `data.table` (inherits from `data.frame`) for 5-15x faster batch operations.

```r
# All objects support as.data.frame() - returns data.table
pitch_df <- as.data.frame(pitch)           # time, f0 (data.table)
formant_df <- as.data.frame(formant)       # time, f1, f2, f3, ... (data.table)
intensity_df <- as.data.frame(intensity)   # time, intensity (data.table)

# Check return type
class(pitch_df)  # c("data.table", "data.frame")

# data.table provides fast operations
library(data.table)
pitch_df[f0 > 200]              # Fast filtering (keyed by time)
pitch_df[, mean(f0, na.rm=TRUE)] # Fast aggregation

# Backward compatible - works with data.frame code
pitch_df$f0                     # Column access works as before
pitch_df[pitch_df$f0 > 200, ]  # data.frame syntax still works

# With options
pitch_df <- pitch$as_data_frame(
  include_strength = TRUE,
  include_intensity = TRUE
)
```

**Performance benefits:**
- Fast keyed lookups by time/formant/frequency
- `rbindlist()` for efficient aggregation (replaces slow rbind loops)
- In-place modification for memory efficiency
- 5-15x faster for batch operations

### Pattern 4: Tier Manipulation (PitchTier v4.6.6+)

```r
# === CREATE AND POPULATE PITCHTIER ===
pt <- PitchTier(0, 2)  # Empty tier from 0 to 2 seconds
pt$add_point(0.5, 120)  # 120 Hz at 0.5s
pt$add_point(1.0, 150)  # 150 Hz at 1.0s
pt$add_point(1.5, 100)  # 100 Hz at 1.5s

# === EXTRACT FROM PITCH ANALYSIS ===
pitch <- sound$to_pitch()
pitch_tier <- pitch$down_to_pitch_tier()

# === QUERY TIER ===
n <- pitch_tier$get_number_of_points()
f0_min <- pitch_tier$get_minimum()
f0_max <- pitch_tier$get_maximum()
f0_mean <- pitch_tier$get_mean()
f0_at_1s <- pitch_tier$get_value_at_time(1.0)

# === MODIFY TIER ===
pitch_tier$add_point(time = 1.0, value = 150.0)
pitch_tier$remove_point(index = 1)
pitch_tier$multiply_frequencies(1.2)  # +20%
pitch_tier$shift_frequencies(10, "hertz")  # +10 Hz

# === SMOOTHING ===
pitch_tier$interpolate_quadratically(4, FALSE)  # 4 points per parabola

# === SYNTHESIZE SOUND FROM PITCHTIER ===
snd_sine <- pitch_tier$to_sound_sine(16000)
snd_pulse <- pitch_tier$to_sound_pulse_train(16000)
snd_phon <- pitch_tier$to_sound_phonation(16000)

# === CONVERT PITCHTIER TO PITCH ===
pitch_sampled <- pitch_tier$to_pitch(0.01, 75, 600)

# === EXPORT DATA ===
df <- pitch_tier$as_data_frame()  # data.table: time, frequency
mat <- pitch_tier$as_matrix()     # matrix (n x 2)

# === USE IN RESYNTHESIS (PSOLA) ===
manipulation <- sound$to_manipulation(
  time_step = 0.01,
  pitch_floor = 75,
  pitch_ceiling = 600
)
manipulation$replace_pitch_tier(pitch_tier)
new_sound <- manipulation$to_sound()

# === LOAD/SAVE ===
pitch_tier$save("modified.PitchTier")
pt2 <- PitchTier("modified.PitchTier")
```

### Pattern 5: TextGrid Operations

```r
# Load TextGrid
tg <- TextGrid("annotations.TextGrid")

# Query structure
n_tiers <- tg$get_number_of_tiers()
tier_name <- tg$get_tier_name(tier_number = 1)
is_interval <- tg$tier_is_interval_tier(tier = 1)

# Query intervals
n_intervals <- tg$get_number_of_intervals(tier = 1)
label <- tg$get_interval_text(tier = 1, interval_number = 5)
start <- tg$get_interval_start_time(tier = 1, interval_number = 5)
end <- tg$get_interval_end_time(tier = 1, interval_number = 5)

# Extract Sound for interval
sound_segment <- sound$extract_part(start, end)
```

### Pattern 6: Voice Activity Detection with ZCR (NEW in v4.0.4)

**Critical for AVQI:** The AVQI algorithm uses both intensity AND Zero Crossing Rate (ZCR) filtering to identify voiced segments. pladdrr v4.0.4 adds proper ZCR support matching Praat's `checkZeros` procedure.

```r
# === COMPLETE AVQI-COMPATIBLE VOICED EXTRACTION ===
sound <- Sound("continuous_speech.wav")

# Single function: intensity + ZCR filtering (default: use_zcr = TRUE)
voiced <- extract_voiced_segments(
  sound,
  minimum_pitch = 50,           # Hz, for intensity detection
  silence_threshold = -25,      # dB below max
  zcr_threshold = 3000,         # Hz, reject segments above this
  use_zcr = TRUE                # Enable ZCR filtering (default)
)

# Result: Concatenated voiced audio matching Praat's AVQI extraction
cat("Voiced duration:", voiced$get_duration(), "s\n")

# === INTENSITY-ONLY EXTRACTION (legacy behavior) ===
voiced_no_zcr <- extract_voiced_segments(sound, use_zcr = FALSE)

# === WITH TEXTGRID OUTPUT (for inspection) ===
result <- extract_voiced_segments(sound, return_textgrid = TRUE)
voiced_sound <- result$sound
vad_grid <- result$textgrid
```

**Step-by-step manual control:**

```r
# 1. Create VAD TextGrid (intensity-based)
vad_grid <- sound_to_textgrid_silences(
  sound,
  minimum_pitch = 50,
  time_step = 0.003,
  silence_threshold = -25,
  min_silent_interval = 0.1,
  min_sounding_interval = 0.1
)

# 2. Get matching intervals
voiced_intervals <- textgrid_get_intervals_where(
  vad_grid,
  tier = 1,
  condition = "equals",        # Also: "contains", "starts with", "ends with"
  text = "sounding"
)
# Returns: list(xmin, xmax, text, count)

# 3. Calculate ZCR for filtering
zcr_data <- sound_get_zcr(
  sound,
  window_duration = 0.03,      # 30ms windows (AVQI standard)
  hop_duration = 0.01          # 10ms hop
)
# Returns: list(times, zcr, window_duration, hop_duration)

# 4. Filter intervals by ZCR (manual approach)
keep_intervals <- logical(voiced_intervals$count)
for (i in seq_along(voiced_intervals$xmin)) {
  in_interval <- zcr_data$times >= voiced_intervals$xmin[i] &
                 zcr_data$times <= voiced_intervals$xmax[i]
  mean_zcr <- mean(zcr_data$zcr[in_interval])
  keep_intervals[i] <- mean_zcr < 3000  # Voiced < 3000 Hz
}

# 5. Extract and concatenate passing intervals
voiced_sounds <- sound_extract_parts(
  sound,
  voiced_intervals$xmin[keep_intervals],
  voiced_intervals$xmax[keep_intervals]
)
concatenated <- sound_concatenate_all(voiced_sounds)
```

**ZCR interpretation:**
- **Voiced speech:** 500-2000 crossings/second (low ZCR)
- **Unvoiced fricatives:** 3000-6000 crossings/second (high ZCR)
- **Silence:** Variable (depends on noise floor)

**AVQI threshold:** `zcr_threshold = 3000` rejects unvoiced segments (fricatives, aspiration).

---

## Re-implementing a Praat Procedure

This section is a step-by-step guide for agents porting a new Praat analysis procedure into
pladdrr. It distils lessons from the 2026 developer report and prior SIMD/threading work.

### Step 1 — Find the Praat source

Every Praat menu action maps to a C++ function in the submodule:

```
src/praat.github.io/fon/          ← core audio analysis (Pitch, Formant, Intensity, etc.)
src/praat.github.io/LPC/          ← LPC, Cepstrum, PowerCepstrogram
src/praat.github.io/dwtools/      ← advanced (KlattGrid, DTW, MFCC, CC, SSCP, PCA)
src/praat.github.io/dwsys/        ← numerical utilities (Polynomial, Roots, SVD, etc.)
src/praat.github.io/melder/       ← signal math (NUMinterpol, NUMfilter, FFT, etc.)
```

All platforms (including Windows via `Makevars.win`) compile from the `praat.github.io/`
prefix. The former `src/praat/` Windows mirror was removed in v4.9.5 — never reference it.

Map from Praat menu name to file:

| Praat menu action | Source file |
|------------------|------------|
| `Sound: To Formant (burg)...` | `fon/Sound_to_Formant.cpp` |
| `Sound: To Pitch (cc)...` | `fon/Sound_to_Pitch.cpp` |
| `Sound: To Spectrogram...` | `fon/Sound_and_Spectrogram.cpp` |
| `Spectrum: Get centre of gravity...` | `fon/Spectrum.cpp` |
| `Sound: To PowerCepstrogram...` | `LPC/Sound_to_PowerCepstrogram.cpp` |
| `LTAS: Get maximum...` | `fon/Vector.cpp` → `melder/NUMinterpol.cpp` |

To locate any function: `grep -r "FunctionName" src/praat.github.io/fon/ --include="*.h"`.

### Step 2 — Choose the right API tier

| Tier | When to use | What it returns | Relative speed |
|------|------------|----------------|----------------|
| **Tier 1** (object method `sound$to_X()`) | Interactive / exploratory; full API surface | Wrapped R object | 1× |
| **Tier 2** (`to_X_direct()`) | Chaining: result goes straight into another Praat call | `externalptr` | ~2× |
| **Tier 3** (batch `sound_to_X_batch()`) | ≥10 files; loops over a corpus | List of results | 5–10× |
| **Tier 4** (ultra `calculate_X_ultra()`) | Complete pipeline that never needs to surface R objects | Named list of scalars | 10–30× |

**Critical rule for Tier 2:** Always wrap the returned pointer before returning it to user
code. Every `*_direct()` function **must** return a wrapped object (e.g. `Ltas(.xptr = ...)`),
not a raw `externalptr`. `to_ltas_direct()` returned a raw pointer until v4.9.1 — that was a
bug, not a feature. See [Pitfall 15](#15-to_ltas_direct-returned-raw-externalptr-fixed-v491).

### Step 3 — Avoid per-frame R loops (the #1 performance anti-pattern)

Any R loop that calls a Praat object method once per audio frame is an anti-pattern.
The canonical example from the 2026 developer report:

```r
# ANTI-PATTERN: 1600 R→C++ crossings for a 400-frame spectrogram
for (frame in seq_len(n_frames)) {
  t    <- spectrogram$get_time_from_frame(frame)   # C++ round-trip
  spec <- spectrogram$to_spectrum(t)               # C++ object allocation
  cog  <- spec$get_centre_of_gravity(power)        # C++ round-trip
  sd   <- spec$get_standard_deviation(power)       # C++ round-trip
  ...
}
# Result: 14× slower than Praat on the same algorithm.

# CORRECT: implement as a C++ batch function (see src/batch_queries.cpp)
moments <- get_spectral_moments_batch(spectrogram, power = 2.0)
```

**Recipe for a new batch function:**

1. Add `// [[Rcpp::export(.my_batch_fn)]]` to `src/batch_queries.cpp`
2. Accept the object as `SEXP xptr`, cast to `XPtr<structType>`
3. Loop in C++, call Praat functions directly
4. Return `List::create(Named("col1") = vec1, ...)`. If returning a **new Praat object**, wrap it with `make_praat_xptr()` / `make_praat_xptr_from_auto()` from `src/praat_xptr_utils.h` — NEVER construct `XPtr<T>(ptr, deleter)` with a lambda: the lambda silently binds Rcpp's `bool set_delete_finalizer` overload, so the object is freed with `delete` instead of Praat's `forget()` (the v4.9.6 finalizer bug)
5. Run `Rcpp::compileAttributes(".")` to regenerate `src/RcppExports.cpp`
6. **After `compileAttributes`:** verify `src/RcppExports.cpp` has `extern const R_CallMethodDef CallEntries[]` (NOT `static`) — `compileAttributes` resets it to `static`, which breaks the `module_init.cpp` link. Fix if needed before building.
7. Add R wrapper in `R/batch-queries.R` + entry in `NAMESPACE`
8. Add delegating method to the object's `R/*-wrapper.R`

### Step 4 — Numerical traps in Praat DSP

Three classes of traps discovered during the 2026 benchmarking cycle:

#### Trap A: Division by near-zero in interpolation

`NUMimproveExtremum()` in `melder/NUMinterpol.cpp` (and all callers using parabolic
interpolation) is vulnerable to near-zero denominators when adjacent bins have nearly equal
power. **Fixed in v4.9.1** for the `NUM_PEAK_INTERPOLATE_PARABOLIC` path.

**Rule for new interpolation code:** Always guard `|denominator| > epsilon` before dividing,
and clamp the result to a physically plausible range (e.g., `|offset| < 1.0` for one-bin
parabolic interpolation).

#### Trap B: Silent partial convergence in eigenvalue solvers

LAPACK `NUMlapack_dhseqr_()` (called by `Polynomial_to_Roots()` in `dwsys/Roots.cpp`) may
return `info > 0`, indicating it only found `n - info` of the `n` eigenvalues. The code
silently uses the partial set — producing fewer formants than expected from short-window LPC.

**Fixed in v4.9.1** with a Laguerre-method fallback in `Sound_to_Formant.cpp`.

**Rule for new LPC-based procedures:** After calling `Polynomial_to_Roots`, assert
`roots->numberOfRoots == expected_order`. If the assertion can fail, add a robust fallback.
`src/polynomial_roots_laguerre.h` provides a self-contained Laguerre + deflation
implementation that does not depend on LAPACK conditioning.

#### Trap C: dB-domain vs energy-domain averaging

Praat's `Intensity: Get mean` averages in the **energy domain** (Pa²), then converts to dB:
```
mean_dB = 10 * log10( mean(energy_i) )
```
Averaging in the dB domain directly gives a systematically lower result (Jensen's inequality).
This is a known 1–3 dB bias if the wrong domain is used. Always verify the domain in the
Praat source before implementing a mean-intensity wrapper.

### Step 5 — Faithfulness testing

Every new procedure must have a faithfulness registry entry in
`tests/testthat/faithfulness/routines.R` and must pass at r > 0.95 vs Praat on ≥50 real files.

```r
# In faithfulness/routines.R, add a row like:
list(
  name       = "spectral_moments_cog",
  pladdrr_fn = function(snd) {
    spg <- snd$to_spectrogram(window_length = 0.005, max_frequency = 5000)
    get_spectral_moments_batch(spg)$cog
  },
  praat_script = "spectral_moments_cog.praat",
  tolerance    = 1.0,   # Hz; requires written rationale if > 0
  n_min        = 50
)
```

Run the package-local validation commands with:
```bash
Rscript tests/testthat/test-praat-faithfulness.R
Rscript inst/benchmarks/run_audit_benchmarks.R
```

Target metrics per fix category:
- Bug fix: r > 0.95 (was typically < 0.60 before fix)
- New API: r > 0.99 vs the R-loop reference implementation
- Performance: speedup ≥ 0.80× Praat (within 20% of Praat's native speed)

### Step 6 — Log Praat source modifications

Whenever `src/praat.github.io/` is modified, add an entry to
`inst/agents/PRAAT_MODIFICATIONS.md` in this format:

```markdown
## v4.9.1 — NUMinterpol.cpp parabolic guard (2026-06-10)

**File:** `src/praat.github.io/melder/NUMinterpol.cpp`
**Function:** `NUMimproveExtremum()`
**Change:** Added `d2y <= 0` guard and `|offset| >= 1.0` clamp to prevent division by
near-zero denominator in parabolic peak interpolation.
**Reason:** 500–1231 dB physically impossible values from LTAS get_peaks_batch.
**Upstream:** Not reported upstream (Praat's own parabolic path may not be called with
flat LTAS peaks in normal Praat GUI use).
```

This log is the authoritative record of divergences between pladdrr's Praat source and
upstream Praat. It must be updated before committing any change to `src/praat.github.io/`.

---

## Utility Functions

### Memory Pooling API

For batch segment extraction, reuses Sound allocations for 20-30% speedup:

```r
# Check pool efficiency
stats <- sound_pool_stats()
cat("Hit rate:", stats$hits / (stats$hits + stats$misses) * 100, "%\n")

# Clear pool to free memory
sound_pool_clear()

# Resize pool capacity (default: 32)
sound_pool_resize(64)
```

| Function | Description |
|----------|-------------|
| `sound_pool_stats()` | Get hit/miss statistics |
| `sound_pool_clear()` | Clear pool, free memory |
| `sound_pool_resize(max_size)` | Change pool capacity |
| `sound_pool_acquire(...)` | Internal: get Sound from pool |
| `sound_pool_release(xptr)` | Internal: return Sound to pool |

### Spectrum Filtering

Filter spectrum frequencies with Hann window smoothing:

```r
spectrum <- sound$to_spectrum()

# Pass band (keep 100-4000 Hz, smooth 100 Hz)
spectrum_pass_hann_band(spectrum, fmin = 100, fmax = 4000, smooth = 100)

# Stop band (remove 50-60 Hz hum)
spectrum_stop_hann_band(spectrum, fmin = 50, fmax = 60, smooth = 10)
```

### Sound Filtering

Apply frequency filters directly to Sound objects:

```r
# Bandpass filter (100-4000 Hz)
filtered <- sound_filter_pass_hann_band(sound, fmin = 100, fmax = 4000, smooth = 100)

# Bandstop filter (remove hum)
cleaned <- sound_filter_stop_hann_band(sound, fmin = 50, fmax = 60, smooth = 10)
```

### Sound Operations

Correlation and convolution functions:

```r
# Auto-correlation
autocorr <- sound_auto_correlate(sound, scaling = 4L, signal_outside = 1L)

# Cross-correlation between two sounds
xcorr <- sounds_cross_correlate(sound1, sound2, scaling = 4L)

# Convolve two sounds
convolved <- sounds_convolve(sound1, sound2, scaling = 4L)
```

### Fast Data Access

2-5x faster access to Sound samples via direct pointer copy:

```r
# Fast sample access (independent copy — safe to modify)
samples <- get_sound_values_fast(sound, channel = 1)
rms <- sqrt(mean(samples^2))
peak <- max(abs(samples))

# Check if vector came from fast access
is_fast_vector(samples)  # TRUE

# Matrix access (all channels)
mat <- sound_as_matrix_fast(sound)

# Fast time vector computation
times <- get_sound_times_fast(sound)
```

**Note:** Despite the legacy "zerocopy" name, these functions always return independent R copies.
The old names (`get_sound_values_zerocopy`, `sound_as_matrix_zerocopy`, `is_zerocopy_vector`) still
work but are deprecated — use the `_fast` variants instead.

### Batch Processing

High-level functions for corpus-scale measurement extraction:

```r
# Pair .wav and .TextGrid files by basename
pairs <- pair_files("~/audio/", "~/annotations/")

# Extract pitch/formant/intensity at interval midpoints (uses batch C++ calls internally)
results <- extract_measurements(
  sound = "audio.wav", textgrid = "audio.TextGrid",
  tier = 1, measurements = c("pitch", "formants", "intensity"),
  time_point = "midpoint"
)

# Generic batch processing over a directory
batch_process("~/audio/", pattern = "\\.wav$", func = my_analysis, parallel = TRUE)
```

| Function | Description |
|----------|-------------|
| `pair_files(sound_dir, textgrid_dir)` | Match .wav/.TextGrid by basename |
| `extract_measurements(sound, textgrid, ...)` | Per-interval pitch/formant/intensity via batch C++ |
| `extract_measurements_custom(sound, textgrid, tier, measures)` | Custom measure functions per interval |
| `batch_process(directory, pattern, func, parallel)` | Map function over files with optional parallelism |

### SIMD Information

SIMD acceleration is **enabled at build time** (`-DHAVE_XSIMD` in `Makevars.in`). Runtime
detection selects the best instruction set per architecture (NEON on arm64, AVX2/SSE4.2
on x86_64). All 32 SIMD files in `src/` are active; output is bit-identical to scalar paths.
A new bridge header `src/simd_bridge.h` provides `simd_bridge_stat<T>()` and
`simd_bridge_binary<T>()` templates for the common R→C SIMD adapter pattern.

Check capabilities:

```r
info <- simd_info()
# Returns: enabled, available, architecture, batch_size_double, batch_size_float, version

# Common architectures:
# - AVX2: 4 doubles/operation (Intel/AMD x86_64)
# - SSE4.2: 2 doubles/operation (older x86_64)
# - NEON: 2 doubles/operation (ARM/Apple Silicon)

# Disable SIMD at runtime for testing
pladdrr_simd(FALSE)
```

New SIMD functions should follow the bridge template in `simd_bridge.h` rather than
copying the R→C array conversion pattern manually.

---

## Method Signatures

### Sound Methods

| Method | Parameters | Return | Praat Function |
|--------|------------|--------|----------------|
| `get_duration()` | - | `numeric` | `sound->xmax - sound->xmin` |
| `get_sampling_frequency()` | - | `numeric` | `1.0 / sound->dx` |
| `get_number_of_samples()` | - | `integer` | `sound->nx` |
| `get_number_of_channels()` | - | `integer` | `sound->ny` |
| `get_value_at_time(time, channel, interpolation)` | `double, int, string` | `numeric` | `Vector_getValueAtX()`; `interpolation` is a string (e.g. `"linear"`), not an int |
| `get_rms(from_time, to_time)` | `double, double` | `numeric` | `Sound_getRootMeanSquare()`; no `channel` param |
| `get_energy(from_time, to_time)` | `double, double` | `numeric` | `Sound_getEnergy()` |
| `get_power(from_time, to_time)` | `double, double` | `numeric` | `Sound_getPower()` |
| `get_intensity_db()` | - | `numeric` | `Sound_getIntensity_dB()`; takes NO arguments |
| `to_pitch(time_step, pitch_floor, pitch_ceiling)` | `double, double, double` | `Pitch` | `Sound_to_Pitch()` |
| `to_formant_burg(...)` | multiple | `Formant` | `Sound_to_Formant_burg()` |
| `to_intensity(minimum_pitch, time_step, subtract_mean)` | `double, double, bool` | `Intensity` | `Sound_to_Intensity()` |
| `to_spectrum(fast)` | `bool` | `Spectrum` | `Sound_to_Spectrum()` |
| `to_spectrogram(window_length, max_freq, time_step, freq_step, window_shape)` | multiple | `Spectrogram` | `Sound_to_Spectrogram()` |
| `pitch_to_pointprocess_peaks(pitch, include_maxima, include_minima)` | `Pitch, bool, bool` | `PointProcess` | `Sound_Pitch_to_PointProcess_peaks()` (NEW v4.0.9) |
| `extract_part(from_time, to_time, window_shape, relative_width, preserve_times)` | `double, double, string, double, bool` | `Sound` | `Sound_extractPart()`; `window_shape = "rectangular"`, `relative_width = 1.0`, `preserve_times = FALSE` |
| `extract_channel(channel)` | `int` | `Sound` | `Sound_extractChannel()` |

### Pitch Methods

| Method | Parameters | Return | Notes |
|--------|------------|--------|-------|
| `get_value_at_time(time, unit, interpolate)` | `double, string, bool` | `numeric` | unit: "hertz", "semitones", "mel", "erb" |
| `get_mean(from_time, to_time, unit)` | `double, double, string` | `numeric` | 0,0 = entire duration |
| `get_standard_deviation(from_time, to_time, unit)` | `double, double, string` | `numeric` | |
| `get_minimum(from_time, to_time, unit, interpolate)` | `double, double, string, bool` | `numeric` | |
| `get_maximum(from_time, to_time, unit, interpolate)` | `double, double, string, bool` | `numeric` | |
| `get_quantile(quantile, from_time, to_time, unit)` | `double, double, double, string` | `numeric` | quantile: 0.5 = median |
| `count_voiced_frames()` | - | `integer` | |
| `down_to_pitch_tier()` | - | `PitchTier` | |

### Formant Methods

| Method | Parameters | Return | Notes |
|--------|------------|--------|-------|
| `get_value_at_time(formant_number, time, unit, interpolation)` | `int, double, string, string` | `numeric` | unit: "hertz", "bark" |
| `get_bandwidth_at_time(formant_number, time, unit)` | `int, double, string` | `numeric` | |
| `get_values_at_times(formant_number, times, unit, interpolation)` | `int, numeric vector, string, string` | `numeric vector` | interpolation param v4.8.22 |
| `get_mean(formant_number, from_time, to_time, unit)` | `int, double, double, string` | `numeric` | |
| `get_standard_deviation(formant_number, from_time, to_time, unit)` | `int, double, double, string` | `numeric` | |
| `get_quantile(formant_number, quantile, from_time, to_time, unit)` | `int, double, double, double, string` | `numeric` | |
| `track(number_of_tracks, ref_f1, ...)` | multiple | `Formant` | |
| `to_formantgrid()` | - | `FormantGrid` | |

### Intensity Methods

| Method | Parameters | Return | Notes |
|--------|------------|--------|-------|
| `get_value_at_time(time, interpolation)` | `double, string` | `numeric` | interpolation: "nearest", "linear", "cubic" |
| `get_values_at_times(times, interpolation)` | `numeric vector, string` | `numeric vector` | Batch query (v4.8.22) |
| `get_mean(from_time, to_time, averaging_method)` | `double, double, string` | `numeric` | |
| `get_minimum(from_time, to_time, interpolation)` | `double, double, string` | `numeric` | |
| `get_maximum(from_time, to_time, interpolation)` | `double, double, string` | `numeric` | |
| `get_standard_deviation(from_time, to_time)` | `double, double` | `numeric` | |
| `get_quantile(from_time, to_time, quantile, unit)` | `double, double, double, string` | `numeric` | |

### MFCC Methods (NEW in v4.0.7)

MFCC (Mel-Frequency Cepstral Coefficients) for speaker recognition and speech analysis.

| Method | Parameters | Return | Notes |
|--------|------------|--------|-------|
| `get_number_of_frames()` | - | `integer` | Total analysis frames |
| `get_number_of_coefficients()` | - | `integer` | Coefficients per frame (usually 12-13) |
| `get_xmin()`, `get_xmax()` | - | `numeric` | Time domain |
| `get_frame_time(frame)` | `int` | `numeric` | Time of frame center |
| `get_coefficients_at_frame(frame)` | `int` | `numeric vector` | All coefficients at frame |
| `get_all_coefficients()` | - | `matrix` | Frames × coefficients matrix |
| `lifter(from, to)` | `int, int` | `MFCC` | Apply liftering to coefficient range |
| `as_data_frame()` | - | `data.table` | Export to data.table |

**Creation:** `sound$to_mfcc(num_coefficients = 13, analysis_width = 0.025, time_step = 0.01, f1_mel = 100.0, fmax_mel = 7800.0, df_mel = 100.0)`

### LFCC Methods (NEW in v4.0.7)

LFCC (Linear-Frequency Cepstral Coefficients) - alternative to MFCC with linear frequency scale.

| Method | Parameters | Return | Notes |
|--------|------------|--------|-------|
| `get_number_of_frames()` | - | `integer` | Total analysis frames |
| `get_number_of_coefficients()` | - | `integer` | Coefficients per frame |
| `get_coefficients_at_frame(frame)` | `int` | `numeric vector` | All coefficients at frame |
| `get_all_coefficients()` | - | `matrix` | Frames × coefficients matrix |
| `as_data_frame()` | - | `data.table` | Export to data.table |

**Creation:** `lpc$to_lfcc(num_coefficients = 12)` (from LPC object)

### FormantModeler Methods (NEW in v4.0.7)

Robust polynomial formant tracking with outlier detection.

| Method | Parameters | Return | Notes |
|--------|------------|--------|-------|
| `get_number_of_tracks()` | - | `integer` | Number of formant tracks |
| `get_number_of_parameters()` | - | `integer` | Polynomial order per track |
| `get_xmin()`, `get_xmax()` | - | `numeric` | Time domain |
| `get_coefficient_of_determination(track)` | `int` | `numeric` | R² for track |
| `get_model_value_at_time(track, time)` | `int, double` | `numeric` | Smoothed formant value |
| `get_residual_at_time(track, time)` | `int, double` | `numeric` | Deviation from model |
| `get_data_point_status(track, frame)` | `int, int` | `integer` | 1=valid, 0=outlier |
| `to_formant()` | - | `Formant` | Convert back to Formant |
| `process_outliers(sigma)` | `double` | `FormantModeler` | Mark outliers beyond sigma |
| `as_data_frame()` | - | `data.table` | Export modeled values |

**Creation:** `formant$to_formant_modeler(tmin, tmax, num_tracks = 4, num_params = 5)`

### PCA Methods (NEW in v4.0.7)

Principal Component Analysis for vowel space analysis and dimensionality reduction.

| Method | Parameters | Return | Notes |
|--------|------------|--------|-------|
| `get_number_of_components()` | - | `integer` | Number of principal components |
| `get_dimension()` | - | `integer` | Original data dimension |
| `get_number_of_observations()` | - | `integer` | Training data count |
| `get_eigenvalues()` | - | `numeric vector` | All eigenvalues |
| `get_eigenvalue(component)` | `int` | `numeric` | Single eigenvalue |
| `get_fraction_variance(from, to)` | `int, int` | `numeric` | Cumulative variance explained |
| `get_dimension_of_fraction(frac)` | `double` | `integer` | Components for variance fraction |
| `get_eigenvector(component)` | `int` | `numeric vector` | PC loadings |
| `get_eigenvectors()` | - | `matrix` | All PC loadings |
| `get_centroid()` | - | `numeric vector` | Data centroid |
| `project(data, num_dimensions)` | `matrix, int` | `matrix` | Project new data |
| `as_data_frame()` | - | `data.table` | Component summary |

**Creation:** `pca_from_matrix(data)` where rows are observations, columns are variables.

**Example - Vowel Space Analysis:**
```r
# F1, F2, F3 measurements for vowels
vowels <- matrix(c(
  700, 1200, 2500,  # /a/
  350, 2100, 2800,  # /i/
  450, 700, 2400    # /u/
), ncol = 3, byrow = TRUE)

pca <- pca_from_matrix(vowels)
pca$get_fraction_variance(1, 2)  # Variance in first 2 PCs
projected <- pca$project(new_vowels, num_dimensions = 2)  # Project to 2D
```

### Discriminant Methods (NEW in v4.0.7)

Linear Discriminant Analysis for classification (vowel ID, speaker ID, dialect classification).

| Method | Parameters | Return | Notes |
|--------|------------|--------|-------|
| `get_number_of_groups()` | - | `integer` | Number of classes |
| `get_number_of_functions()` | - | `integer` | Discriminant functions |
| `get_dimension()` | - | `integer` | Feature dimension |
| `get_number_of_observations(group)` | `int` | `integer` | Training samples in group |
| `get_total_observations()` | - | `integer` | Total training samples |
| `get_eigenvalues()` | - | `numeric vector` | Discriminant eigenvalues |
| `get_fraction_variance(from, to)` | `int, int` | `numeric` | Variance explained |
| `get_wilks_lambda(from)` | `int` | `numeric` | Wilks' Lambda statistic |
| `get_partial_discrimination_probability(n)` | `int` | `list` | Chi-squared test |
| `get_eigenvector(func)` | `int` | `numeric vector` | Discriminant function coefficients |
| `get_eigenvectors()` | - | `matrix` | All discriminant coefficients |
| `get_group_centroids()` | - | `matrix` | Group means in original space |
| `get_group_labels()` | - | `character vector` | Class names |
| `get_apriori_probabilities()` | - | `numeric vector` | Prior probabilities |
| `set_apriori_probability(group, p)` | `int, double` | - | Set prior for group |
| `as_data_frame()` | - | `data.table` | Function summary |

**Creation:** `discriminant_from_matrix(data, labels)` where labels is a character vector of group memberships.

**Example - Vowel Classification:**
```r
# Training data: F1, F2, F3 for labeled vowels
vowels <- matrix(c(
  700, 1200, 2500,  # /a/
  720, 1180, 2520,  # /a/
  350, 2100, 2800,  # /i/
  340, 2150, 2780   # /i/
), ncol = 3, byrow = TRUE)
labels <- c("a", "a", "i", "i")

lda <- discriminant_from_matrix(vowels, labels)
lda$get_wilks_lambda(1)  # Classification power (lower = better)
lda$get_group_centroids()  # Mean formants per vowel
```

---

## Validation Patterns

### Comparing pladdrr with Praat Script Output

```r
# Run equivalent Praat script
praat_script <- '
Read from file: "audio.wav"
To Pitch: 0, 75, 600
mean_f0 = Get mean: 0, 0, "Hertz"
writeInfoLine: mean_f0
'
praat_result <- as.numeric(system(
  paste("praat --run -", praat_script),
  intern = TRUE
))

# pladdrr equivalent
sound <- Sound("audio.wav")
pitch <- sound$to_pitch(time_step = 0, pitch_floor = 75, pitch_ceiling = 600)
pladdrr_result <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")

# Compare (should be identical within floating-point tolerance)
stopifnot(abs(praat_result - pladdrr_result) < 1e-6)
```

### Using Praat Interpreter from R

```r
# Run Praat scripts directly via interpreter wrapper
praat_run_script('
  Read from file: "audio.wav"
  selectObject: "Sound audio"
  duration = Get total duration
')

# Get variables back
duration <- praat_eval_numeric("duration")
```

---

## Common Pitfalls

### 1. Class Name Checks (UPDATED v2.1.1)

```r
# CORRECT: Use clean public class names
if (inherits(formant, "Formant")) {
  # Process formant object
}
if (inherits(pitch, "Pitch")) {
  # Process pitch object
}
if (inherits(intensity, "Intensity")) {
  # Process intensity object
}

# WRONG: Don't use internal constructor names (deprecated)
if (inherits(formant, "formant_constructor")) {  # Old, don't use
  # This still works but is deprecated
}
```

**Available class names:** `Sound`, `Pitch`, `Formant`, `Intensity`, `Spectrum`, `Spectrogram`, `TextGrid`, `PointProcess`, `Harmonicity`, `Ltas`, `Cepstrum`, `PowerCepstrum`, `LPC`, `Cochleagram`, `Excitation`, `Matrix`, `Table`, `PitchTier`, `FormantTier`, `IntensityTier`, `AmplitudeTier`, `DurationTier`, `FormantGrid`, `Manipulation`, `KlattGrid`, `FormantPath`, `ComplexSpectrogram`, `Polygon`, `VocalTract`, `LongSound`, `Electroglottogram`, `MFCC`, `LFCC`, `FormantModeler`, `PCA`, `Discriminant`

### 2. Unit Code Mismatch

**NOTE:** Modern pladdrr API accepts strings directly - no need for manual conversion.

```r
# MODERN (v2.0+): Pass strings directly (RECOMMENDED)
f0 <- pitch$get_value_at_time(time = 1.0, unit = "hertz")
mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")

# LEGACY: Manual unit code conversion (still works, but unnecessary)
unit_code <- function(unit) {
  switch(tolower(unit), "hertz" = 0L, "semitones" = 1L, ...)
}
f0 <- pitch$get_value_at_time(time = 1.0, unit = unit_code("hertz"))
```

### 3. Frame Indexing (1-based)

```r
# Praat uses 1-based indexing
first_frame <- pitch$get_time_from_frame(1)    # Correct
first_frame <- pitch$get_time_from_frame(0)    # Error!

# Interval numbers are also 1-based
label <- tg$get_interval_text(tier = 1, interval_number = 1)
```

### 4. Time Range 0,0 Means "Entire Duration"

```r
# from_time=0, to_time=0 is special: uses full duration
mean_all <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")

# Explicit range
mean_part <- pitch$get_mean(from_time = 1.0, to_time = 2.0, unit = "hertz")
```

### 5. NA for Undefined Values

```r
# Pitch returns NA for unvoiced frames
f0 <- pitch$get_value_at_time(time = 1.0, unit = "hertz")
if (is.na(f0)) {
  # Frame is unvoiced
}

# Formant returns NA for missing formants
f5 <- formant$get_value_at_time(formant_number = 5, time = 1.0, unit = "hertz")

# NaN/NA inputs safely return NA (v4.8.22+) — no need to pre-filter
ltas$get_value_at_frequency(NaN)                # returns NA
intensity$get_values_at_times(c(0.1, NaN, 0.3)) # returns c(val, NA, val)
```

### 6. Invalid Pointer Access

```r
# Always check validity before heavy operations
if (pitch$is_valid()) {
  # Safe to use
  mean_f0 <- pitch$get_mean(0, 0, "hertz")
} else {
  stop("Invalid Pitch object")
}
```

### 7. Method Name Changes (v2.1.1)

```r
# CORRECT: Use specific method names
formant <- sound$to_formant_burg()      # Burg's method (standard)
pitch <- sound$to_pitch_cc()            # Cross-correlation method

# WRONG: sound$to_formant() does NOT exist — dispatch returns NULL, next call errors
formant <- sound$to_formant()           # Error: use to_formant_burg() (or _robust/_willems)

# sound$to_pitch() IS a first-class, non-deprecated method — both are valid
pitch1 <- sound$to_pitch()              # Praat's default AC method
pitch2 <- sound$to_pitch_cc()           # Cross-correlation method
```

### 8. Property Access (Fast Path)

```r
# FAST: Direct property access via .cpp (v2.0.8+)
duration <- sound$.cpp$duration         # Direct C++ member access
nx <- sound$.cpp$nx                     # Fast, no function call overhead

# BACKWARD-COMPATIBLE: Method access (still works)
duration <- sound$get_duration()        # Slightly slower, but familiar
nx <- sound$get_number_of_samples()
```

### 9. Batch Operations vs Loops

```r
# SLOW: R loop with repeated C++ calls (1-2ms per call overhead)
times <- seq(0, 2, by = 0.01)
f1_values <- numeric(length(times))
for (i in seq_along(times)) {
  f1_values[i] <- formant$get_value_at_time(1, times[i], "hertz")
}

# FAST: Batch query function (5-10x faster)
result <- get_formants_at_times(formant, times, formant_numbers = 1)
f1_values <- result$F1

# FASTEST: Vectorized object method (20x faster, loops in C++)
f1_track <- formant$get_formant_track(1, unit = "hertz")  # All frames at once

# Sound window operations (100-150x speedup)
starts <- seq(0, 14.97, by = 0.03)  # 500 windows
ends <- starts + 0.03
# SLOW: ~500-1000ms (1-2ms × 500)
powers <- vapply(seq_along(starts), function(i) sound$get_power(starts[i], ends[i]), numeric(1))
# FAST: ~5ms
powers <- sound$get_power_windows(starts, ends)

# Pitch voiced mask (5x speedup)
voiced_mask <- pitch$get_voiced_mask()  # Logical vector, TRUE = voiced
voiced_f0 <- pitch$get_values_vector()[voiced_mask]
```

**Rule:** If you're writing a loop that calls the same method repeatedly, check for a vectorized `$get_*_windows()`, `$get_*_vector()`, or `$get_*_track()` method first.

### 10. Build System: Never Edit `src/Makevars` Directly

`src/Makevars` is **generated** by the `configure` script from `src/Makevars.in` via `sed` on every `R CMD INSTALL`. Any manual edit to `src/Makevars` will be silently overwritten.

```bash
# WRONG: editing Makevars directly (changes lost on next install)
vim src/Makevars

# CORRECT: edit the template, then rebuild
vim src/Makevars.in
R CMD INSTALL .
```

Also do NOT commit `src/Makevars` — verify with `git diff src/Makevars` before committing.

#### Build System Architecture (v4.9.5+)

**configure** detects two things via `sed` substitution into `Makevars.in`:
- **RcppXsimd** → `@XSIMD_FLAG@` (may expand to additional xsimd include paths or flags;
  `-DHAVE_XSIMD` is now also hardcoded in `PKG_CPPFLAGS` so SIMD is always enabled)
- **GSL** → `@GSL_CFLAGS@` + `@GSL_LIBS@` (via gsl-config → pkg-config → fallback `-lgsl -lgslcblas`)

**GSL is required.** ~19 GSL functions called from Praat's `NUMspecfunc.cpp`, `NUM2.cpp`, `melder.cpp`. Headers come from Praat's bundled GSL 1.10 at `praat.github.io/external/gsl/`, but implementations link against system GSL.

**Windows:** `src/Makevars.win` is NOT generated — it's a static file (no `configure.win`) that compiles from the same `praat.github.io/` prefix as Unix (the old `src/praat/` mirror is gone). It hardcodes `-lgsl -lgslcblas` (GSL via Rtools MSYS2/ucrt64: `pacman -S mingw-w64-ucrt-x86_64-gsl`) and must keep defining `UNICODE`/`_UNICODE` (Praat calls generic Win32 macros with wide buffers — without these they resolve to `...A` variants and fail on mingw) and `_FILE_OFFSET_BITS=64`, mirroring Praat's own mingw makefiles.

**libc++ note:** `PKG_CPPFLAGS` in `Makevars.in` carries `-D_LIBCPP_DISABLE_DEPRECATION_WARNINGS` — silences C++17 allocator-member deprecations inside RcppXsimd's `xsimd_aligned_allocator.hpp` under `--as-cran`; portable define, inert on libstdc++ (so not needed in `Makevars.win`).

**CRAN-forbidden flags:** Do NOT add `-O3`, `-flto`, or `-march=native` to Makevars.in — R provides its own optimization via `Makeconf`. Do NOT re-add `-Wno-*` suppressions (all were removed in v4.9.6; the only justified non-standard flag is `-ffp-contract=off`, required for bit-exact fidelity with Praat). The `@XSIMD_FLAG@` mechanism handles SIMD detection without architecture-specific flags; xsimd auto-detects the best instruction set at compile time.

The former bundled GSL trees (`src/gsl-2.8/`, `src/praat/external/gsl/`, `src/build_gsl.sh`) were removed in the v4.9.5 slimming — only Praat's GSL 1.10 *headers* under `praat.github.io/external/gsl/` remain in the tarball.

### 11. Shared Dispatch Table: `$.Type` S3 Methods

Since v4.8.33, ALL 35 wrappers use shared dispatch tables instead of per-instance closures. Key implications:

```r
# Methods work identically from the user's perspective:
sound$to_pitch()     # Works — $.Sound dispatches to .sound_methods

# BUT: do.call still works because $.Type returns a bound closure:
do.call(sound$to_pitch, list())  # Works — returns function(...) method(x, ...)

# Field access (.xptr, .cpp) is a fast path via .subset2:
sound$.xptr          # Direct list access, no method lookup

# .pointer is a compat alias for .xptr (Sound, Electroglottogram, AmplitudeTier):
sound$.pointer       # Returns .xptr
```

When adding new methods to any wrapper, add them to the `.{type}_methods` env in the corresponding `R/*-wrapper.R` file, not inside the constructor.

### 12. Per-frame R loops over Spectrogram frames

Any R-level loop that calls `spectrogram$to_spectrum(t)` per frame is an anti-pattern.
Each iteration allocates a `structSpectrum` in C++, wraps it in R, calls the moment
function, and GC-collects it — ~5 R→C++ boundary crossings per frame.

```r
# WRONG (anti-pattern): per-frame loop — 14× slower than Praat
for (ix in seq_len(n_frames)) {
  t    <- spectrogram$.cpp$get_time_from_frame(ix)
  spec <- spectrogram$to_spectrum(t)              # C++ alloc per frame
  cog  <- spec$get_centre_of_gravity(2.0)         # R→C++ per frame
}

# CORRECT (v4.9.1+): single C++ pass
moments <- get_spectral_moments_batch(spectrogram, power = 2.0)
```

The general rule: **if you are iterating over frames and calling the same per-frame
method each time, there should be a C++ batch function for it.** If one doesn't exist
yet, add it to `src/batch_queries.cpp` following the `get_jitter_shimmer_batch_cpp`
pattern (lines 754–826 as of v4.9.1).

### 13. Parabolic interpolation with flat LTAS peaks (fixed v4.9.1) {#13-parabolic-interpolation-with-flat-ltas-peaks-fixed-v491}

Before v4.9.1, `ltas$get_peaks_batch(interpolation="parabolic")` could return values in
the range 500–1231 dB — physically impossible for any acoustic spectrum. The cause was a
division by near-zero `d2y` in `NUMimproveExtremum()` when adjacent LTAS bins had nearly
equal power (flat peak). The benchmark saw h1_onset r ≈ −0.08 vs Praat (random noise).

**Fixed in v4.9.1:** `d2y ≤ 0` guard returns the bin peak unchanged; `|offset| ≥ 1.0`
clamp prevents extrapolation beyond one bin. Safe to use `interpolation="parabolic"` in
v4.9.1+.

**When implementing new Praat procedures that use parabolic interpolation:**
Always test with a flat-spectrum signal (white noise LTAS) and a pure tone (sharp peak)
to confirm the interpolated values are within ±50 dB of the surrounding bins.

### 14. Short-window formant extraction (fixed v4.9.1) {#14-short-window-formant-extraction-fixed-v491}

Before v4.9.1, `to_formant_burg()` on windows ≤100ms returned severely wrong F1/F2/F3
(r=0.57/0.38 vs Praat; Python/Parselmouth achieved r>0.9999 on the same algorithm).

**Root cause:** LAPACK `dhseqr_` silently returns only the eigenvalues it converged on
when the LPC companion matrix is ill-conditioned (short windows → fewer samples →
ill-conditioned autocorrelation). Missing eigenvalues = missing formants.

**Fixed in v4.9.1:** `burg()` in `Sound_to_Formant.cpp` now detects
`roots->numberOfRoots < coefficients.size` and retries with Laguerre's method
(`src/polynomial_roots_laguerre.h`), which is robust to ill-conditioned matrices.
Long-window audio is unaffected (fallback never triggers when `dhseqr_` converges).

```r
# This now works correctly on short windows (v4.9.1+)
window <- snd$extract_part(0.48, 0.52, "rectangular", 1, FALSE)  # 40ms
fmnt   <- window$to_formant_burg(0.005, 5, 5500, 0.025, 50)
f1     <- fmnt$get_value_at_time(1, 0.02, "hertz")               # now correct

# If you need to verify: compare against full-sound analysis at the same time
fmnt_full <- snd$to_formant_burg(0.005, 5, 5500, 0.025, 50)
f1_ref    <- fmnt_full$get_value_at_time(1, 0.50, "hertz")
stopifnot(abs(f1 - f1_ref) < 200)  # should pass
```

**When implementing any LPC-based procedure:** if the procedure operates on
user-supplied audio windows of unknown length, verify accuracy on both 40ms and 500ms
windows and add both to the faithfulness registry.

### 15. `to_ltas_direct()` returned raw externalptr (fixed v4.9.1) {#15-to_ltas_direct-returned-raw-externalptr-fixed-v491}

Before v4.9.1, `to_ltas_direct()` returned a raw `externalptr` instead of a wrapped `Ltas`
object, making it unusable without manual construction:

```r
# OLD workaround (pre-v4.9.1) — no longer needed
ltas <- Ltas(.xptr = to_ltas_direct(snd, 1))

# CORRECT (v4.9.1+) — returns wrapped Ltas directly
ltas <- to_ltas_direct(snd, bandwidth = 100)
ltas$get_slope(0, 1000, 1000, 10000, "energy")  # works immediately
```

The underlying C++ `.sound_to_ltas()` was always correct; only the R wrapper was missing
the `Ltas(.xptr = ...)` wrap. All other `*_direct()` functions were already correct.

---

## Deprecated API Migration

⚠️ **Legacy S3 API functions are deprecated and will be removed in v5.0.0**

The following S3-style functions have been replaced by the modern shared dispatch API. While they still work, they emit deprecation warnings and should not be used in new code.

### Deprecated Functions → Modern Replacements

| Deprecated Function | Modern Replacement |
|---------------------|-------------------|
| `create_sound(values, sr)` | `sound_n(values, sr)` |
| `read_sound(file_path)` | `Sound(file_path)` |
| `get_duration(sound)` | `sound$get_duration()` |
| `get_sampling_rate(sound)` | `sound$get_sampling_frequency()` |
| `get_n_channels(sound)` | `sound$get_number_of_channels()` |
| `get_n_samples(sound)` | `sound$get_number_of_samples()` |
| `extract_pitch(sound, ...)` | `sound$to_pitch(...)` |
| `get_pitch_at_time(pitch, t)` | `pitch$get_value_at_time(t)` |
| `get_mean_pitch(pitch)` | `pitch$get_mean()` |
| `get_min_pitch(pitch)` | `pitch$get_minimum()` |
| `get_max_pitch(pitch)` | `pitch$get_maximum()` |
| `extract_intensity(sound, ...)` | `sound$to_intensity(...)` |
| `get_intensity_at_time(int, t)` | `intensity$get_value_at_time(t)` |
| `get_mean_intensity(int)` | `intensity$get_mean()` |
| `get_min_intensity(int)` | `intensity$get_minimum()` |
| `get_max_intensity(int)` | `intensity$get_maximum()` |
| `get_sd_intensity(int)` | `intensity$get_standard_deviation()` |
| `extract_formants(sound, ...)` | `sound$to_formant_burg(...)` |
| `get_formant_at_time(f, n, t)` | `formant$get_value_at_time(n, t)` |
| `get_mean_formant(f, n)` | `formant$get_mean(n)` |

### Migration Example

**Before (deprecated):**
```r
# Old S3-style workflow
sound <- read_sound("speech.wav")
duration <- get_duration(sound)
pitch <- extract_pitch(sound, pitch_floor = 75)
mean_f0 <- get_mean_pitch(pitch)
```

**After (modern):**
```r
# Modern shared dispatch workflow
sound <- Sound("speech.wav")
duration <- sound$get_duration()
pitch <- sound$to_pitch(pitch_floor = 75)
mean_f0 <- pitch$get_mean()
```

### Benefits of Modern API

1. **Method chaining** - Chain operations: `sound$to_pitch()$get_mean()`
2. **Consistent interface** - All objects follow same pattern: `$to_*()`, `$get_*()`
3. **Better performance** - Direct C++ module binding, no wrapper overhead
4. **Full Praat parity** - More methods available than S3 functions
5. **Type safety** - Built-in parameter validation

### Removal Timeline

- **v4.x**: Deprecated functions emit warnings
- **v5.0.0**: Deprecated functions will be removed

---

## File Locations

```
src/
├── modules/               # Rcpp Module C++ code (39 modules)
│   ├── module_common.h    # Unit codes, validation macros
│   ├── sound_module.cpp   # RSound class
│   ├── pitch_module.cpp   # RPitch class
│   ├── mfcc_module.cpp    # RMFCC, RLFCC classes (v4.0.7)
│   ├── pca_module.cpp     # RPCA class (v4.0.7)
│   ├── discriminant_module.cpp  # RDiscriminant class (v4.0.7)
│   ├── formantmodeler_module.cpp # RFormantModeler class (v4.0.7)
│   └── ...
├── praat.github.io/       # Praat C++ source
│   ├── fon/              # Core phonetic objects
│   │   ├── Sound.h
│   │   ├── Pitch.h
│   │   └── ...
│   ├── dwtools/          # Statistical analysis (PCA, Discriminant, MFCC)
│   └── melder/           # Error handling
├── datatable_utils.h      # C++ helpers for data.table creation (v4.0+)
R/
├── sound-wrapper.R        # Sound R wrapper (renamed from sound-r6-new.R in v4.0.7)
├── pitch-wrapper.R        # Pitch R wrapper (renamed from pitch-r6.R in v4.0.7)
├── formant-wrapper.R      # Formant R wrapper
├── mfcc-wrapper.R         # MFCC/LFCC R wrappers (v4.0.7)
├── pca-wrapper.R          # PCA R wrapper (v4.0.7)
├── discriminant-wrapper.R # Discriminant R wrapper (v4.0.7)
├── formantmodeler-wrapper.R # FormantModeler R wrapper (v4.0.7)
├── datatable-utils.R      # R data.table helpers (v4.0+)
├── parallel-batch.R       # Parallel processing (exported: analyze_files_parallel, process_sounds_parallel, extract_pitch_parallel, extract_formant_parallel, extract_intensity_parallel, benchmark_parallel)
├── zzz.R                  # Module loading
└── RcppExports.R          # Auto-generated (don't edit)
```

**File Naming Convention (v4.0.7):** All R wrapper files use `-wrapper.R` suffix (not `-r6.R`) to accurately reflect the shared dispatch table pattern used instead of R6 classes.

---

## Quick Reference Card

**Updated for the current shared-dispatch + 4-tier performance API**

```r
# === LOAD AUDIO ===
sound <- Sound("audio.wav")

# === TIER 1: STANDARD API (baseline, full features) ===
pitch <- sound$to_pitch_cc(time_step = 0, pitch_floor = 75, pitch_ceiling = 600)
formant <- sound$to_formant_burg()
intensity <- sound$to_intensity()

# === QUERY AT TIME (single point) ===
f0 <- pitch$get_value_at_time(1.0, "hertz")
f1 <- formant$get_value_at_time(1, 1.0, "hertz")
f2 <- formant$get_value_at_time(2, 1.0, "hertz")
db <- intensity$get_value_at_time(1.0, "cubic")

# === DATA EXPORT (v4.0+: returns data.table) ===
pitch_df <- as.data.frame(pitch)      # Returns data.table (inherits data.frame)
formant_df <- as.data.frame(formant)  # data.table with keyed columns
library(data.table)
pitch_df[f0 > 200]                    # Fast filtering (5-15x faster)

# === TIER 2: DIRECT API (2-3x faster, bypasses R dispatch) ===
# NEW in v4.0.2: Full-parameter pitch functions available!
pitch_ptr <- to_pitch_cc_direct(sound, voicing_threshold = 0.6)  # All 10 params ✓
f0_value <- get_pitch_value_direct(pitch_ptr, 1.0, "hertz", TRUE)
all_stats <- get_pitch_stats_direct(pitch_ptr, 0, 0, "hertz")

# Legacy: Basic parameters only
pitch_ptr <- to_pitch_direct(sound)  # Basic: time_step, pitch_floor, pitch_ceiling

# === TIER 3: BATCH QUERIES (5-10x faster for multiple points) ===
times <- seq(0.5, 2.5, by = 0.01)
formants <- get_formants_at_times(formant, times, 1:4)  # Returns list(F1, F2, F3, F4)
f0_contour <- get_pitch_at_times(pitch, times, "hertz")
db_contour <- get_intensity_at_times(intensity, times, "cubic")

# === TIER 3: BATCH OPERATIONS (5-10x faster bulk processing) ===
sounds <- lapply(files, Sound)
pitches <- sound_to_pitch_batch(sounds, time_step = 0.01)
formants <- sound_to_formant_batch(sounds)

# Aggregate using data.table::rbindlist (v4.0+)
library(data.table)
all_results <- rbindlist(results, idcol = "file_id")

# === BATCH STATISTICS (10-50x faster for multi-interval) ===
from_times <- seq(0, 9, length.out = 100)
to_times <- from_times + 0.1
stats <- pitch_get_statistics_batch(pitch$.xptr, from_times, to_times,
                                     c("min", "max", "mean", "stdev"), 0L)

# === VECTORIZED OBJECT METHODS (20-150x faster, v4.0.13) ===
# Sound window operations (AVQI: 100-150x speedup)
powers <- sound$get_power_windows(starts, ends)
rms_vals <- sound$get_rms_windows(starts, ends)
values <- sound$get_values_at_times(times, channel = 1)

# Pitch vectors (DSI: 5x speedup)
voiced_mask <- pitch$get_voiced_mask()           # Logical: TRUE = voiced
f0_values <- pitch$get_values_vector()           # All frame values
strengths <- pitch$get_strengths_vector()

# Formant tracks (Vowel analysis: 20x speedup)
f1_track <- formant$get_formant_track(1)
all_tracks <- formant$get_all_formant_tracks(4)  # matrix[frames, 4]

# Spectrum vectors (Pharyngeal: 150x speedup)
powers <- spectrum$get_power_vector()
energies <- spectrum$get_band_energies(fmins, fmaxs)

# Spectrogram slices (50x speedup)
frame <- spectrogram$get_frame(time = 1.0)
band_power <- spectrogram$get_band_power(500, 2000)

# HNR batch stats (VQ: 10x speedup)
stats <- hnr$get_statistics_batch(starts, ends, c("mean", "min", "max"))

# TextGrid batch labels (VUV: 60x speedup)
labels <- tg$get_labels_at_times(tier = 1, times)

# === BATCH API v4.0.14 (10-50x faster for specific workflows) ===
# LTAS batch peak search (Pharyngeal: 18x speedup)
peaks <- ltas$get_peaks_batch(fmins, fmaxs)     # data.frame(fmin, fmax, peak_value, peak_frequency)
minima <- ltas$get_minima_batch(fmins, fmaxs)   # data.frame(fmin, fmax, min_value, min_frequency)

# Pitch detrending (Tremor: 10x speedup)
detrended <- pitch$get_values_detrended(unit = "hertz")  # NumericVector
detrended_pitch <- pitch$subtract_linear_fit(unit = "hertz")  # Pitch object

# Filtered window extraction (AVQI: 10x speedup)
voiced <- sound$extract_windows_filtered(starts, ends, min_power = 0.03, max_zcr = 3000)
passes <- sound$get_windows_passing_filter(starts, ends, min_power = 0.03, max_zcr = 3000)

# PointProcess batch (DSI/Shimmer: 20x speedup)
amplitudes <- pp$get_values_from_sound(sound, channel = 1, interpolation = "cubic")
periods <- pp$get_periods_vector()
jitter <- pp$get_jitter_batch(0, 0, 0.0001, 0.02, 1.3)  # list(local, local_abs, rap, ppq5, ddp)

# Spectrum at frequencies (Pharyngeal harmonics)
powers <- spectrum$get_power_at_frequencies(freqs)

# === FAST CPPS (1.5-2x faster AVQI) ===
cpps <- calculate_cpps_fast(sound, subtract_tilt = FALSE,
                             pitch_floor = 60, pitch_ceiling = 330)

# === VOICED EXTRACTION WITH ZCR (v4.0.4 - AVQI-compatible) ===
voiced <- extract_voiced_segments(sound, zcr_threshold = 3000, use_zcr = TRUE)
zcr_data <- sound_get_zcr(sound, window_duration = 0.03)  # Per-frame ZCR

# === XPTR WINDOWS (70x faster custom DSP) ===
hamming <- create_window_xptr("hamming")
windowed <- apply_window_xptr(sound, hamming)

# === MFCC/LFCC (v4.0.7 - Speaker Recognition) ===
mfcc <- sound$to_mfcc(num_coefficients = 12)
coeffs <- mfcc$get_all_coefficients()  # Frames × coefficients matrix

lpc <- sound$to_lpc_burg()
lfcc <- lpc$to_lfcc(num_coefficients = 12)

# === PCA (v4.0.7 - Dimensionality Reduction) ===
vowels <- matrix(c(700, 1200, 350, 2100, 450, 700), ncol = 2, byrow = TRUE)
pca <- pca_from_matrix(vowels)
projected <- pca$project(new_data, num_dimensions = 2)

# === DISCRIMINANT (v4.0.7 - Classification) ===
lda <- discriminant_from_matrix(vowels, labels = c("a", "i", "u"))
lda$get_wilks_lambda(1)  # Lower = better separation
lda$get_group_centroids()  # Class means

# === FORMANTMODELER (v4.0.7 - Robust Formant Tracking) ===
fm <- formant$to_formant_modeler(tmin = 0, tmax = 0, num_tracks = 4)
smoothed_f1 <- fm$get_model_value_at_time(track = 1, time = 0.5)

# === STATISTICS (0,0 = entire duration) ===
mean_f0 <- pitch$get_mean(0, 0, "hertz")
sd_f0 <- pitch$get_standard_deviation(0, 0, "hertz")

# === FAST PROPERTY ACCESS ===
duration <- sound$.cpp$duration        # Fast C++ property
sr <- sound$.cpp$sampling_frequency    # Direct member access

# === EXPORT ===
df <- as.data.frame(pitch)
pitch$save("output.Pitch")

# === CLASS CHECKING ===
if (inherits(pitch, "Pitch")) {
  # Process pitch object
}

# === INTERPRETER (persistent state) ===
interp <- PraatInterpreter$new()
interp$run('x = 42')
result <- interp$eval('x * 2')
```

**Performance Decision Tree:**
- **< 10 files, interactive:** Use Tier 1 (Standard API)
- **10-100 files, loops:** Use Tier 2 (Direct API)
- **> 100 files, production:** Use Tier 3 (Batch/Parallel)
- **DSI/AVQI/VQ one-call helpers:** Use Tier 4 (Ultra)
- **Many values from one object:** Use Vectorized Methods (`$get_*_vector()`, `$get_*_windows()`)
- **Need statistics from many intervals:** Use Tier 3 (Batch Statistics)

**See comprehensive guides:**
- `vignettes/performance-optimization.Rmd` - Complete performance API guide
- `vignettes/articles/batch-operations-guide.Rmd` - All batch functions with benchmarks
- `vignettes/articles/migration-guide.Rmd` - How to optimize existing code
- `vignettes/articles/naming-conventions.Rmd` - Function naming patterns

---

## Known Limitations

### Direct API Pitch Parameters (v4.0.2)

**Status:** ✅ **RESOLVED** - Full-parameter Direct API functions now available!

**NEW in v4.0.2:** Use `to_pitch_ac_direct()` or `to_pitch_cc_direct()` for custom parameters:

```r
# ✅ RECOMMENDED: Direct API with full parameters (v4.0.2+)
pitch_ptr <- to_pitch_ac_direct(
  sound,
  voicing_threshold = 0.6,      # Custom parameter ✓
  silence_threshold = 0.01,     # Custom parameter ✓
  octave_cost = 0.02            # Custom parameter ✓
)
# Fast (2x faster than Tier 1), full control, returns external pointer

# Alternative: Cross-correlation method
pitch_ptr <- to_pitch_cc_direct(
  sound,
  voicing_threshold = 0.6,
  silence_threshold = 0.01
)
```

**Legacy Function:** `to_pitch_direct()` remains available but only supports 4 basic parameters (time_step, pitch_floor, pitch_ceiling, method). Use the new `_ac_direct()` or `_cc_direct()` variants for custom voicing parameters.

**API Tier Comparison for Custom Parameters:**

```r
# Tier 1: Standard API (wrapper object returned)
pitch <- sound$to_pitch_cc(voicing_threshold = 0.6)
# Speed: Medium | Returns: Pitch wrapper object

# Tier 2: Direct API (external pointer returned) ⭐ NEW
pitch_ptr <- to_pitch_cc_direct(sound, voicing_threshold = 0.6)
# Speed: Fast (2x faster) | Returns: External pointer

# Tier 3: Batch API (list returned)
pitches <- sound_to_pitch_cc_batch(sounds, voicing_threshold = 0.6)
# Speed: Fastest | Returns: List of Pitch objects | Best for >10 files
```

### to_point_process_periodic_cc Parameters

The R wrapper accepts `time_step`, `max_period_factor`, and `max_amplitude_factor` parameters for API compatibility with Praat's GUI, but **only `pitch_floor` and `pitch_ceiling` are currently used**. The underlying Praat C function `Sound_to_PointProcess_periodic_cc()` only accepts minimum and maximum pitch.

```r
# These parameters are used:
pp <- sound$to_point_process_periodic_cc(pitch_floor = 75, pitch_ceiling = 600)

# These parameters are accepted but ignored:
# time_step, max_period_factor, max_amplitude_factor
```

### pitch_to_pointprocess_peaks (NEW in v4.0.9)

**Purpose:** Extract amplitude peaks and/or troughs from a sound guided by pitch contour. Essential for **tremor analysis** (vocal amplitude modulation detection).

**Signature:** `sound$pitch_to_pointprocess_peaks(pitch, include_maxima = TRUE, include_minima = FALSE)`

**Parameters:**
- `pitch`: Pitch object (created with `sound$to_pitch()`)
- `include_maxima`: Include amplitude peaks (default: TRUE)
- `include_minima`: Include amplitude troughs (default: FALSE)

**Returns:** PointProcess object with timestamps of detected peaks/troughs

**Praat Equivalent:** `Sound & Pitch: To PointProcess (peaks)...`

**Use Case - Tremor Analysis:**

```r
# Step 1: Extract pitch contour
pitch <- sound$to_pitch(time_step = 0.0, pitch_floor = 75, pitch_ceiling = 600)

# Step 2: Extract amplitude peaks guided by pitch
pp_peaks <- sound$pitch_to_pointprocess_peaks(pitch, 
                                               include_maxima = TRUE, 
                                               include_minima = FALSE)

# Step 3: Get timestamps and amplitudes at peaks
peak_times <- get_pointprocess_times(pp_peaks)
peak_amplitudes <- sapply(peak_times, function(t) {
  sound$get_value_at_time(time = t, channel = 1, interpolation = 2)
})

# Step 4: Calculate tremor intensity (mean absolute deviation)
tremor_intensity <- 100 * mean(abs(peak_amplitudes))
```

**Why Use Pitch-Guided Detection:**
- **Accuracy:** Aligns peak detection with fundamental frequency periods
- **Robustness:** Filters out noise peaks that don't align with vocal fold cycles
- **Clinical Validity:** Matches Praat's established tremor analysis methodology

**Alternative - Both Peaks and Troughs:**

```r
# For comprehensive tremor analysis, analyze both peaks and troughs
pp_peaks <- sound$pitch_to_pointprocess_peaks(pitch, 
                                               include_maxima = TRUE, 
                                               include_minima = FALSE)
pp_troughs <- sound$pitch_to_pointprocess_peaks(pitch, 
                                                 include_maxima = FALSE, 
                                                 include_minima = TRUE)

# Calculate separate intensities (no batch helper exists — sample at each point time)
intensity <- sound$to_intensity()
peak_times <- vapply(seq_len(pp_peaks$get_number_of_points()), pp_peaks$get_time, numeric(1))
trough_times <- vapply(seq_len(pp_troughs$get_number_of_points()), pp_troughs$get_time, numeric(1))
peak_intensity <- vapply(peak_times, intensity$get_value_at_time, numeric(1))
trough_intensity <- vapply(trough_times, intensity$get_value_at_time, numeric(1))
tremor_intensity <- (mean(peak_intensity) + mean(trough_intensity)) / 2
```

**Note:** `calculate_intensity_at_points()` does not exist in this package — there is no dedicated batch
helper for this. Sample `Intensity$get_value_at_time()` per `PointProcess` timestamp as shown above.

---

### API Naming Differences from Praat/Parselmouth (v4.8.5)

pladdrr uses slightly different parameter/method names than Praat. This is by design (shorter, more R-idiomatic) but may cause errors when porting scripts.

**Parameter Name Differences:**

| Function | Praat/Parselmouth | pladdrr |
|----------|-------------------|---------|
| Pitch creation | `max_number_of_candidates` | `max_candidates` |
| Formant creation | `max_number_of_formants` | `max_formants` |
| Formant creation | `maximum_formant` | `max_formant` |
| Formant creation | `pre_emphasis_from` | `pre_emphasis` |

**Method Name Differences (with v4.8.5 aliases):**

| Operation | Praat | pladdrr (original) | pladdrr (v4.8.5 alias) |
|-----------|-------|-------------------|------------------------|
| LTAS with bandwidth | `To Ltas...` | N/A | ✅ `to_ltas(bandwidth)` |
| LTAS 1-to-1 | `To Ltas (1-to-1)` | `to_ltas_1to1()` | same |
| Power Cepstrum (Spectrum) | `To PowerCepstrum` | `to_powercepstrum()` | ✅ `to_power_cepstrum()` |
| Power Cepstrum (Cepstrum) | `To PowerCepstrum` | `to_powercepstrum()` | ✅ `to_power_cepstrum()` |
| Start time | `Get start time` | `get_xmin()` | ✅ `get_start_time()` |
| End time | `Get end time` | `get_xmax()` | ✅ `get_end_time()` |

**Agent Guidance - Porting Praat Scripts:**
```r
# Pitch creation
pitch <- to_pitch_cc_direct(sound,
  max_candidates = 15,     # NOT max_number_of_candidates
  pitch_ceiling = 600
)

# Formant creation
formant <- to_formant_direct(sound,
  max_formants = 5,        # NOT max_number_of_formants
  max_formant = 5500,      # NOT maximum_formant
  pre_emphasis = 50        # NOT pre_emphasis_from
)

# Time bounds - BOTH work in v4.8.5+
start <- sound$get_start_time()  # Praat-compatible (v4.8.5+)
end <- sound$get_end_time()      # Praat-compatible (v4.8.5+)
# OR legacy:
start <- sound$get_xmin()
end <- sound$get_xmax()

# Spectrum operations - BOTH work in v4.8.5+
ltas <- spectrum$to_ltas(100)         # Praat-compatible with bandwidth (v4.8.5+)
ltas <- spectrum$to_ltas_1to1()       # Legacy 1-to-1 mapping
cepstrum <- spectrum$to_power_cepstrum()  # Praat-compatible (v4.8.5+)
cepstrum <- spectrum$to_powercepstrum()   # Legacy
```

---

### Jitter/Shimmer Value Scaling

**Note:** `get_jitter_shimmer_batch()` returns values as decimals (0.0-1.0), not percentages (0-100).

```r
js <- get_jitter_shimmer_batch(pp, sound, 0, 0, 0.0001, 0.02, 1.3, 1.6)

# Values are decimals
js$jitter_local   # 0.00478 (not 0.478%)
js$shimmer_local  # 0.02551 (not 2.551%)

# Convert to percentage if needed
jitter_percent <- js$jitter_local * 100   # 0.478%
shimmer_percent <- js$shimmer_local * 100 # 2.551%
```

---

## Real-World Use Cases (v4.0.3 Optimizations)

This section demonstrates how v4.0.3 batch operations enable efficient implementation of complex voice analysis workflows that previously required manual iteration.

### Use Case 1: AVQI (Acoustic Voice Quality Index) - Voice Concatenation

**Challenge:** AVQI requires concatenating 10-50 voiced segments into a single audio file for analysis. Previous approach used iterative concatenation which is O(n²).

**v4.0.3 Solution:** `sound_concatenate_all()` performs batch concatenation in O(n) time (19x faster).

```r
# Extract voiced segments from recording
voiced_intervals <- textgrid$get_intervals_where(tier = "voicing", text = "voiced")

# Extract each voiced segment as a Sound object
voiced_sounds <- lapply(voiced_intervals, function(interval) {
  sound$extract_part(interval$start, interval$end)
})

# OLD (slow): Iterative concatenation - O(n²) due to repeated copying
# result <- voiced_sounds[[1]]
# for (i in 2:length(voiced_sounds)) {
#   result <- sounds_append(result, voiced_sounds[[i]])  # Each call copies entire result
# }

# NEW (fast): Single-pass batch concatenation - O(n)
concatenated <- sound_concatenate_all(voiced_sounds)

# Continue with AVQI analysis using concatenated voiced audio
pitch <- concatenated$to_pitch_cc()
cpps <- calculate_cpps_fast(concatenated)
pp <- concatenated$to_point_process_periodic_cc()
shimmer <- pp$get_shimmer_local(concatenated)
# ... etc.
```

**Performance:** 19x faster for 30 segments (150ms → 8ms), scales linearly with segment count.

### Use Case 2: VUV (Voiced/Unvoiced/Voiced) Analysis - TextGrid Merging

**Challenge:** VUV analysis creates voicing annotations that must be merged with existing TextGrid tiers. Manual approach requires save/reload + O(n²) boundary insertion.

**v4.0.3 Solution:** `textgrid_merge()` uses Praat's native batch merge (17x faster).

```r
# Load original TextGrid with phoneme annotations
original_tg <- TextGrid("recording.TextGrid")

# Perform VUV detection on audio
sound <- Sound("recording.wav")
pitch <- sound$to_pitch_cc()

# Create new TextGrid with VUV tier
vuv_tg <- TextGrid(0, sound$get_duration())
vuv_tg$add_interval_tier("vuv")

# Populate VUV tier based on pitch detection
times <- seq(0, sound$get_duration(), by = 0.01)
pitch_values <- get_pitch_at_times(pitch, times, unit = "hertz")

# Add boundaries for voiced/unvoiced transitions
for (i in 2:length(pitch_values)) {
  if (is.na(pitch_values[i-1]) != is.na(pitch_values[i])) {
    vuv_tg$insert_boundary(tier = 1, time = times[i])
  }
}

# Set labels for each interval
for (j in 1:vuv_tg$get_number_of_intervals(1)) {
  start <- vuv_tg$get_interval_start_time(1, j)
  mid <- (start + vuv_tg$get_interval_end_time(1, j)) / 2
  f0 <- pitch$get_value_at_time(mid, "hertz")
  label <- if (!is.na(f0)) "voiced" else "unvoiced"
  vuv_tg$set_interval_text(1, j, label)
}

# OLD (slow): Manual merge via save/reload + tier copying
# original_tg$save("temp.TextGrid")
# reloaded <- TextGrid("temp.TextGrid")
# for each interval in vuv_tg:
#   reloaded$insert_boundary(...)  # O(n²) - each insert shifts all later intervals

# NEW (fast): Native Praat batch merge - O(n)
merged_tg <- textgrid_merge(list(original_tg, vuv_tg))

# Result has both original tiers AND vuv tier
merged_tg$save("recording_with_vuv.TextGrid")
```

**Performance:** 17x faster for 100 intervals (1.7s → 0.1s). Avoids disk I/O and O(n²) insertion.

**Key parameter:** `equalize_domains = FALSE` (default) preserves original tier domains. Use `TRUE` to extend all tiers to unified domain.

### Use Case 3: Pharyngeal Consonant Analysis - Windowed Resampling

**Challenge:** Pharyngeal consonant analysis requires high-frequency spectrum analysis (10 kHz) but only for 50ms windows, not entire recording. Loading and resampling full 10-minute file wastes memory.

**v4.0.3 Solution:** `sound_load_window()` loads only needed segment and resamples in one operation (27x faster).

```r
# Pharyngeal consonant typically occurs at specific time points
pharyngeal_times <- c(3.45, 7.82, 12.34)  # seconds into recording

# Analyze each pharyngeal token
results <- lapply(pharyngeal_times, function(time) {
  # OLD (slow): Load entire file, then extract window, then resample
  # sound <- Sound("long_recording.wav")           # Load 10 minutes (slow)
  # segment <- sound$extract_part(time, time+0.05) # Extract 50ms
  # resampled <- segment$resample(10000, 50)       # Resample for high-freq analysis
  
  # NEW (fast): Load+resample only the needed 50ms window
  window <- sound_load_window(
    "long_recording.wav",
    start = time,
    end = time + 0.05,        # 50ms window
    resample_to = 10000       # Resample to 10 kHz for spectral analysis
  )
  
  # Perform spectrum analysis at high frequency resolution
  spectrum <- window$to_spectrum(fast = TRUE)
  
  # Extract pharyngeal signature: energy in 2-4 kHz band
  band_energy <- spectrum$get_band_energy(2000, 4000)
  
  # Get formants at high ceiling for pharyngeal detection
  formant <- window$to_formant_burg(
    max_number_of_formants = 5,
    maximum_formant = 7000  # Higher ceiling for pharyngeal F3/F4
  )
  
  list(
    time = time,
    f1 = formant$get_value_at_time(1, 0.025, "hertz"),
    f2 = formant$get_value_at_time(2, 0.025, "hertz"),
    f3 = formant$get_value_at_time(3, 0.025, "hertz"),
    pharyngeal_energy = band_energy
  )
})

# Combine results
pharyngeal_df <- do.call(rbind, lapply(results, as.data.frame))
```

**Performance:** 27x faster (540ms → 20ms per window). Avoids loading 10-minute file for each 50ms analysis.

**Key benefits:**
- Loads only requested time window (no full file I/O)
- Resampling happens during load (single operation)
- `preserve_times = FALSE` (default) makes window start at t=0 for simpler analysis

### Use Case 4: Batch Pitch Extraction with Custom Voicing Parameters

**Challenge:** Analyzing 1000+ files with non-default pitch parameters (e.g., voicing_threshold for creaky voice).

**v4.0.3 Solution:** Combine Direct API (`to_pitch_cc_direct`) with batch operations.

```r
files <- list.files("creaky_voice_corpus/", pattern = "\\.wav$", full.names = TRUE)

# Load all sounds
sounds <- lapply(files, Sound)

# Tier 3: Batch pitch extraction with custom voicing threshold
pitches <- sound_to_pitch_cc_batch(
  sounds,
  time_step = 0.01,
  voicing_threshold = 0.3,    # Lower threshold for creaky voice (default 0.45)
  silence_threshold = 0.01,
  pitch_floor = 50,            # Lower floor for male creaky voice
  pitch_ceiling = 300
)

# Extract statistics using batch queries
mean_f0s <- sapply(pitches, function(p) p$get_mean(0, 0, "hertz"))
jitter_local <- sapply(pitches, function(p) p$get_jitter_local())

# Create results data.table (fast)
library(data.table)
results <- data.table(
  file = basename(files),
  mean_f0 = mean_f0s,
  jitter = jitter_local
)
```

**Performance:** 5-10x faster than Tier 1 loop for batch processing.

### Use Case 5: Prosodic Feature Extraction at Target Times

**Challenge:** Extract F0, formants, intensity, and spectral features at predetermined analysis points (e.g., INTSINT targets, syllable nuclei) for prosodic research.

**Solution:** Extract analysis objects once, use batch queries at all target times.

```r
# 1. Extract analysis objects once
sound <- Sound("utterance.wav")
pitch <- sound$to_pitch()
formant <- sound$to_formant_burg()
intensity <- sound$to_intensity()
ltas <- sound$to_ltas(100)

# 2. Define target times (e.g., from TextGrid or INTSINT)
targets <- c(0.12, 0.34, 0.56, 0.78, 1.01)

# 3. Batch extraction at all targets
f0 <- pitch$get_values_at_times(targets)
f1 <- formant$get_values_at_times(1, targets)
f2 <- formant$get_values_at_times(2, targets)
f3 <- formant$get_values_at_times(3, targets)
int <- intensity$get_values_at_times(targets)

# 4. Spectral measures (whole-utterance)
spectral_slope <- ltas$get_spectral_slope(100, 5000)
band_peaks <- ltas$get_peaks_batch(
  fmins = c(0, 1000, 2000),
  fmaxs = c(1000, 2000, 4000)
)

# 5. Assemble results
library(data.table)
results <- data.table(
  time = targets,
  f0 = f0, f1 = f1, f2 = f2, f3 = f3,
  intensity = int,
  spectral_slope = spectral_slope
)
```

**Performance:** Batch queries avoid per-target C++ call overhead. For 100 targets: ~2ms batch vs ~50ms loop.

---

### Migration Checklist for Agents

When reimplementing Praat code that involves:

**✓ Multiple sound concatenation:**
- Replace `Reduce(sounds_append, sound_list)` or loops with `sound_concatenate_all(sound_list)`
- Speedup: 19x for 30 segments

**✓ TextGrid tier merging:**
- Replace save/reload + manual `insert_boundary()` loops with `textgrid_merge(list(tg1, tg2))`
- Speedup: 17x for 100 intervals

**✓ Analysis of small windows in large files:**
- Replace `Sound(file) |> extract_part() |> resample()` with `sound_load_window(file, start, end, resample_to)`
- Speedup: 27x for 50ms windows in 10-minute files

**✓ Batch processing with custom parameters:**
- Use Tier 3 `sound_to_pitch_cc_batch()` instead of loops
- Use Tier 2 `to_pitch_cc_direct()` if only need external pointers
- Both support full parameter set (v4.0.2+)

---

## Parameter Naming Conventions

pladdrr parameter names intentionally follow Praat's own naming conventions, which differ across analysis domains. These are **not inconsistencies** — they reflect distinct physical concepts:

| Parameter | Used In | Rationale |
|-----------|---------|-----------|
| `minimum_pitch` | Intensity analysis | Praat UI: "Minimum pitch (Hz)" for effective analysis length |
| `pitch_floor` | Pitch, CPPS, voice quality | Praat UI: "Pitch floor" for F0 candidate range |
| `max_frequency` | Spectrogram, Cepstrogram | Maximum frequency of spectral representation |
| `maximum_formant` | Formant extraction (deprecated S3) | Nyquist-like ceiling for formant search |
| `max_formant` | `to_formant_burg()` | Same concept, shorter name in wrapper API |

**Known intentional inconsistencies:**
- `interpolate` (boolean/string in batch queries) vs `interpolation` (string in wrapper methods) — batch queries accept both `TRUE`/`FALSE` shorthand and string values; wrapper methods always use string names
- `get_intensity_at_times(..., interpolate = "cubic")` uses string type while `get_pitch_at_times(..., interpolate = TRUE)` uses boolean — these cannot be unified without breaking changes

---

## Version history and superseded material

Moved out of this guide in v4.9.19. Version history, the superseded SIMD and
performance archive, and the full changelog now live in `HISTORY.md`
(same directory). Nothing was deleted — only relocated, so this guide stays
usable as a reference rather than a changelog.

- Architecture, build system, threading, dispatch patterns: `ARCHITECTURE.md`
- Changes to the vendored Praat tree: `PRAAT_MODIFICATIONS.md`
- Faithfulness status per routine: `FAITHFULNESS_REPORT.md`
- Version history and superseded notes: `HISTORY.md`
