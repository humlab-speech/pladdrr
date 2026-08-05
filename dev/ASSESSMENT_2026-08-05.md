# pladdrr — comprehensive assessment

Date: 2026-08-05 · Reviewed version: 4.9.16 (installed) / 4.9.17 (tree) ·
Branch `perf/assess-fixes`

> **Implemented in v4.9.19 on 2026-08-05** — see
> [§8 v4.9.19 implementation log](#8-v4919-implementation-log) for what was fixed,
> what was measured and rejected, and what remains open.
>
> **Re-assessed against v4.9.18 on 2026-08-05** — see the new
> [§7 v4.9.18 re-assessment](#7-v4918-re-assessment) and the status-tracked plan in
> [§5](#5-prioritised-actions-status-tracked-against-v4918). Sections 1–4 record the
> original v4.9.16 findings and are left unedited except for two corrections marked
> **[corrected]**. All measurements below the re-assessment heading were re-taken on a
> locally built 4.9.18.

Priority order follows the stated design goals: (1) runtime power, (2) performance,
(3) standards / code quality / maintainability, (4) documentation.

---

## 0. Measurement setup

| Item | Value |
|---|---|
| Host | Apple M1 Pro — 8 performance cores + 2 efficiency cores (`hw.ncpu` = 10) |
| OS / R | macOS 26.5.2 · R 4.4.2 (aarch64) |
| Reference | Praat 6.x at `/Applications/Praat.app/Contents/MacOS/Praat`, driven with `--run` |
| Fixture | `inst/extdata/test.wav` — 1.000 s, 44 100 Hz, mono (and 5 s / 10 s self-concatenations) |
| SIMD | RcppXsimd 7.1.6.1, reported architecture NEON, `batch_size_double` = 2 |
| Timing | wall = min over 5 blocks of *n* reps (`Sys.time`); energy proxy = process CPU time (`user.self + sys.self`, sums all threads) |
| Profiling | macOS `sample` on a live single-threaded R process, 20 s |

Praat's `stopwatch` was verified to be wall-clock (`Melder_clock` →
`std::chrono::high_resolution_clock`), so cross-tool timings are comparable.

**Caveat.** All measurements are macOS/arm64. The x86 conclusions in §2.3 and the
Windows/Linux thread-count conclusion in §1.4 are derived from source inspection,
not measured.

---

## 1. Runtime power consumption

Total CPU time is used as the energy proxy: for a fixed core type, energy ≈ CPU-seconds ×
average power, and the package's threading changes wall time and CPU time independently.

### 1.1 Headline: the dominant energy sink is one O(n²) routine, not the parts that were optimised

Profiling `calculate_cpps_fast()` on 10 s of audio, single-threaded (20 s of samples,
leaf attribution):

| Leaf | Samples | Share of non-idle |
|---|---:|---:|
| `expandPartition<double>` | 6 562 | 39 % |
| `medianOfNinthers<double>` | 3 753 | 22 % |
| `adaptiveQuickselect<double>` | 3 620 | 21 % |
| `num::NUMquantile_e<double>` | 1 132 | 7 % |
| `siegel_row_slopes_simd` | 814 | 5 % |
| `pocketfft` (radf4 + radb4) | 43 | 0.3 % |
| `Sampled_getMean` + `getSumAndDefinitionRange` | 57 | 0.3 % |

All of the top five are inside `structSlopeSelector::getSlope_Siegel()`, reached from
two call sites per frame — `PowerCepstrogram_subtractTrend` (7 425 samples) and the
per-frame trend fit inside `PowerCepstrogram_to_Matrix_CPP` (8 560 samples).

**≈94 % of CPPS energy is the Siegel repeated-median slope estimator.** For a fit range
of *n* quefrency bins it computes *n* medians of *n*−1 slopes, i.e. Θ(n²) selection work
per frame, ~451 frames for a 1 s file, ~5 000 for a 10 s file.

By contrast, the FFT — replaced wholesale with pocketfft in v4.8.12 at a measurable
fidelity cost (§2.5) — is 0.3 % of the budget, and the smoothing pass that
`PowerCepstrogram_smooth_fast` was written and parallelised for is another 0.3 %.

Concretely on 10 s of audio: 10.5 CPU-seconds single-threaded, 11.4 CPU-seconds with
threads. Roughly 10 of those seconds are median selection.

**Actions, highest value first**

1. **Switch the default `fit_method` to Theil–Sen and measure the trade.** Praat maps
   `"Robust"` → Siegel (Θ(n²)) and `"Robust slow"` → Theil–Sen via Matoušek's
   O(n log n) slope selection. The names are backwards for realistic *n*: measured on
   the 1 s fixture, `fit_method = "robust slow"` runs in **67 ms vs 132 ms** for
   `"robust"` — a straight 2× energy saving. This is also Praat's *own* default for
   `Get CPPS…` (see §2.4). **But do not flip it before reading §2.6** — the Theil–Sen
   path is numerically unstable upstream.
2. **Devirtualise and hoist inside `getSlope_Siegel`.** `xp` (the quefrency grid) is
   identical for every frame and every call; only `yp` changes. Precomputing the
   reciprocal differences once per cepstrogram, and reusing one scratch buffer instead
   of `buffer.resize()` per call, removes n² divisions and the repeated allocation.
   Bit-exactness needs checking (a reciprocal-multiply is not identical to a divide);
   gate it behind the faithfulness harness.
3. **Replace `NUMselect`'s median-of-ninthers with `std::nth_element` for small n and
   benchmark.** For n ≈ 370 the guaranteed-linear machinery has a large constant;
   `expandPartition` alone is 39 % of total runtime. This is a contained experiment with
   a clear pass/fail (identical output, lower time).
4. **Pursue an O(n log n) repeated-median** (Matoušek/Mount/Netanyahu 1998) only if 1–3
   are insufficient. High effort, high payoff, and a genuine contribution back to Praat.

Rough ceiling: if the median cost drops 5×, whole-package CPPS energy drops ~4×. That
dwarfs everything else in this report.

### 1.2 Thread count: the default (`hardware_concurrency()`) is both slower and hungrier than the optimum

`calculate_cpps_fast()` on 5 s of audio, sweeping `pladdrr_threads(n)`:

| threads | wall (ms) | CPU (ms) | energy vs 1-thread | speed-up |
|---:|---:|---:|---:|---:|
| 1 | 5 167 | 5 163 | 1.00 | 1.00 |
| 2 | 2 640 | 5 224 | 1.01 | 1.96 |
| 4 | 1 366 | 5 316 | 1.03 | 3.78 |
| 6 | 940 | 5 354 | 1.04 | 5.50 |
| 8 | 770 | 5 551 | 1.08 | 6.71 |
| **9** | **718** | 5 694 | 1.10 | **7.20** |
| 10 (= default) | 755 | 5 735 | **1.11** | 6.84 |

The default is `std::thread::hardware_concurrency()` = 10, and 10 threads is **worse than
9 on both axes** — 5 % more wall time *and* 0.7 % more CPU. The cause is visible in the
hardware: 8 P-cores + 2 E-cores, and `MelderThread_run` hands every thread an
**equal-sized static range**. The two chunks that land on E-cores take ~2× longer, so
eight P-cores sit at `join()` waiting for two stragglers.

**Action.** Replace the static equal partition in
`src/melderthread_impl.cpp:MelderThread_run` and
`src/batch_queries.cpp:parallel_for_range` with **dynamic chunked dispatch** — an
`std::atomic<integer>` cursor handing out chunks of ~(elements / (4·threads)). Same
results (each frame is still computed identically and written to its own slot), no
straggler tail, and it degrades gracefully on any asymmetric or loaded machine. This is
the single cheapest power win in the package.

Interim mitigation if the scheduler change is deferred: cap the automatic thread count at
the performance-core count (`hw.perflevel0.logicalcpu` on Darwin, `sched_getaffinity`
mask on Linux) rather than `hardware_concurrency()`.

### 1.3 Threading thresholds are far too aggressive for short analyses

10 s of audio, threads = 1 vs auto:

| routine | wall 1→auto | CPU 1→auto | CPU overhead | speed-up |
|---|---|---|---:|---:|
| `to_spectrogram` | 18 → 5 ms | 18 → 39 ms | **+117 %** | 3.6× |
| `to_formant_burg` | 75 → 46 ms | 76 → 109 ms | **+43 %** | 1.6× |
| `to_pitch` | 54 → 10 ms | 54 → 72 ms | **+33 %** | 5.4× |
| `to_harmonicity_cc` | 387 → 56 ms | 387 → 422 ms | +9 % | 6.9× |
| `calculate_cpps_fast` | 10 508 → 1 521 ms | 10 512 → 11 389 ms | +8 % | 6.9× |

`to_formant_burg` is the worst deal in the package: **43 % more energy for a 1.6× wall
improvement**. On a laptop on battery, or in any throughput-bound corpus job where wall
time per file is irrelevant, that is a pure loss.

**Actions**

1. Raise per-routine `thresholdNumberOfElementsPerThread` so short analyses stay serial.
   The current thresholds were tuned for wall time only.
2. Add a documented power policy — e.g.
   `options(pladdrr.thread_policy = c("latency", "throughput", "efficiency"))`, where
   `"throughput"` (the right default for `analyze_files_parallel()` and any corpus loop)
   pins kernels to 1 thread and parallelises across *files* instead, and `"efficiency"`
   caps at the knee of the curve. Parallelising across files is strictly better than
   parallelising within a file: no join barrier, no straggler tail, near-linear scaling.
3. Publish the sweep in §1.2 in the performance vignette so users can pick a point on the
   energy/latency curve deliberately.

### 1.4 Portability defect in the thread-count formula (costs energy on Linux and Windows)

`src/melderthread_impl.cpp:250` hardcodes the macOS branch of Praat's platform switch:

```cpp
// macOS-style: round down, first spawned thread is costliest
integer numberOfThreads = Melder_iroundDown ((double) numberOfElements / minimumNumberOfElementsPerThread);
```

Upstream `praat.github.io/melder/MelderThread.cpp:99-109` is platform-dependent:

| platform | upstream formula |
|---|---|
| macOS | `floor(n / min)` |
| Windows | `floor(n / 2 / min)` |
| Linux | `round(n / 1.5 / min)` |

pladdrr therefore spawns roughly **2× more threads than intended on Windows** and **1.5×
more on Linux**. Given §1.3, extra threads on those platforms means more energy for less
(or negative) wall gain. This happened because `macintosh` cannot be defined globally
(it pulls in Objective-C headers); the fix is to switch on `__APPLE__` / `_WIN32` /
`__linux__` in pladdrr's own copy. Roughly a five-line change.

Not measurable on this host — flagged from source. Verify on CI before and after.

### 1.5 The SIMD layer costs energy roughly as often as it saves it

Toggling the global switch, single-threaded, 1 s fixture:

| routine | SIMD off | SIMD on | gain |
|---|---:|---:|---:|
| `to_pitch` | 5.627 ms | 6.485 ms | **0.87×** |
| `to_formant_burg` | 7.787 ms | 7.702 ms | 1.01× |
| `to_intensity` | 0.609 ms | 0.529 ms | 1.15× |
| `to_spectrogram` | 2.272 ms | 2.046 ms | 1.11× |
| `to_mfcc` | 3.544 ms | 2.970 ms | 1.19× |
| `calculate_cpps_fast` | 973.9 ms | 970.2 ms | 1.00× |

Aggregate over these six routines: **no net gain**, and pitch extraction is 13 % *slower*
with SIMD enabled. See §2.3 and §3.2 for the structural reasons and the recommended
response.

Two mechanical problems make the toggle less meaningful than it looks:

- None of the 26 `src/*_simd.cpp` kernel files consult `use_simd()`; gating lives at the
  call sites, and there are only three such sites in the whole vendored Praat tree
  (`dwsys/SlopeSelector.cpp:39,98,123`).
- That gate is `static const bool pladdrr_slopeSelector_useSimd = should_use_simd_for_slopeselector();`
  — evaluated once at static-initialisation time. **`pladdrr_simd(FALSE)` cannot turn it
  off at runtime**, contrary to the documented behaviour.

### 1.6 The SIMD↔R bridges are net-negative because of a mandatory copy

**[corrected 2026-08-05]** The copy is **not** in `src/simd_bridge.h` — that header is
included by no translation unit and is entirely dead code. The real copies are written
out by hand in each bridge, 8 sites in `src/batch_queries_simd_bridge.cpp` alone, e.g.
`calculate_mean_simd_bridge`:

```cpp
std::vector<double> arr(n + 1);
for (int i = 0; i < n; i++) arr[i + 1] = values[i];
return calculate_mean_simd(arr.data(), n);
```

Each allocates an `std::vector<double>` of size *n*+1 and copies the whole R vector into
it, purely to obtain 1-based indexing. On 10⁶ doubles:

| operation | base R | pladdrr bridge | ratio |
|---|---:|---:|---:|
| mean | 1 ms | 2 ms | **0.50×** |
| sd | 3 ms | 2 ms | 1.50× |
| range | 4 ms | 1 ms | 4.00× |
| quantile (p = 0.5) | 13 ms | 25 ms | **0.52×** |

Half of the exported bridges are slower than base R while doing an extra full-array
allocation, memory write and cache flush — pure wasted energy.

**Action.** Pass `REAL(rv) - 1` as the 1-based pointer and delete the copy. That is
exactly the idiom Praat itself uses
(`asArgumentToFunctionThatExpectsOneBasedArray()` is `cells - 1`), so it matches house
style. The edit must go in the `*_simd_bridge.cpp` files, not in `simd_bridge.h`.

### 1.7 Batch/corpus paths

`analyze_files_parallel()` gets the important thing right: `.pladdrr_worker_thread_budget()`
divides cores among workers so N workers × C kernel threads does not oversubscribe. Good.

Two remaining costs:

- On macOS and Windows it uses PSOCK. Each worker is a fresh R process that `library(pladdrr)`s
  a 22.9 MB shared object and re-initialises Praat. For short per-file work this startup
  can dominate. Consider `parallel::mclapply` on macOS behind an opt-in (the "fork is
  unsafe" concern applies to the GUI event loop, which is absent under `Rscript`), or at
  minimum document the crossover file count.
- `inst/signalfiles/` ships 22 WAV files (3.2 MB) to every installation. They are test
  fixtures; moving them under `tests/` or a companion data package removes 3.2 MB from
  every install (§3.4).

---

## 2. Performance

### 2.1 Headline: pladdrr is at or below Praat's own speed on 6 of 7 common routines

1 s fixture, both sides multithreaded with default settings, min of 5 × 200 reps
(60 for HNR); object construction and destruction inside the timed loop on both sides:

| routine | Praat (ms) | pladdrr auto (ms) | pladdrr 1 thread (ms) | Praat / pladdrr |
|---|---:|---:|---:|---:|
| `to_pitch` | 1.477 | 1.848 | 5.766 | 0.80× |
| `to_formant_burg` | 4.628 | 5.148 | 7.817 | 0.90× |
| `to_intensity` | 0.615 | 0.646 | 0.582 | 0.95× |
| `to_harmonicity_cc` | 7.780 | 10.453 | 38.544 | 0.74× |
| `to_spectrogram` | 0.536 | 1.010 | 2.195 | 0.53× |
| `to_mfcc` | 4.361 | 3.006 | 3.017 | **1.45×** |
| `to_point_process_periodic_cc` | 4.090 | 5.380 | 8.352 | 0.76× |

Calibrating against Praat with multithreading disabled (`Debug multi-threading: "no", 1, 0, "no"`):

| routine | Praat 1 thread | pladdrr 1 thread | Praat MT | pladdrr MT |
|---|---:|---:|---:|---:|
| `to_harmonicity_cc` | 38.42 ms | 38.54 ms | 7.80 ms | 10.45 ms |
| `to_pitch` | 5.10 ms | 5.77 ms | 1.30 ms | 1.85 ms |
| CPPS (1 s) | 1 034.7 ms | 957 ms | 173.9 ms | 147 ms |

Two clean conclusions:

1. **Single-threaded, pladdrr ≈ Praat** (within 1–13 %). Despite ~8 300 lines across 26
   SIMD kernel files, a pocketfft substitution and a "4-tier performance API", the
   scalar-equivalent throughput is upstream's. The one real algorithmic win is CPPS
   (957 vs 1 035 ms, 1.08×), and MFCC (1.45×).
2. **Multithreaded, pladdrr is 25–42 % *behind* Praat** on `to_harmonicity_cc` and
   `to_pitch`, while ahead on CPPS. Since `MelderThread_run` and
   `MelderThread_computeNumberOfThreads` in `melderthread_impl.cpp` are verbatim copies
   of upstream (verified line by line), the runner is not the difference. Candidate causes,
   in order of plausibility and all worth one experiment each:
   - **Thread QoS on Apple Silicon.** A process launched from `Rscript` may run at a lower
     QoS class than a foreground `.app`, which on M-series decides P-core vs E-core
     placement. Test with `pthread_set_qos_class_self_np(QOS_CLASS_USER_INITIATED, 0)` in
     the spawned thread body.
   - **Optimisation level.** Praat's own build uses `-O3`; CRAN policy pins R packages to
     R's `-O2`. This should show up single-threaded too, and largely doesn't — so probably
     secondary.
   - **Allocator contention** between Praat's `melder_alloc` and R's heap under
     concurrency.

   Fixing the MT gap is worth ~30 % on the most-used routines and is a bounded
   investigation.

### 2.2 The "4-tier performance API" delivers no measurable speed-up

1 s fixture, all cores:

| entry point | time | value |
|---|---:|---|
| `sound$to_powercepstrogram(...)$get_cpps()` | 149 ms | 9.9205293140 |
| `calculate_cpps_fast(sound)` | 150 ms | 9.9205293140 |
| `calculate_cpps_ultra(sound)` | 146 ms | 9.9205293140 |

All three are within 3 % — i.e. within noise — because 94 % of the work is the shared
Siegel fit (§1.1) and the R↔C++ boundary costs 3–10 µs per call (measured:
`Sound$get_total_duration()` 3.0 µs, `Pitch$get_mean()` 9.5 µs, empty R closure 1.5 µs).

The documentation claims otherwise. `R/performance-helpers.R:520-524` states
"Standard API: ~4000 ms · Tier 3: ~2000 ms · Tier 4: ~1500 ms (2.7× speedup)";
`calculate_cpps_fast`'s own `@description` claims "roughly 1.5–2×";
`vignettes/performance-optimization.Rmd` claims 2–3×, 5–20× and 20× in various places.
None of these reproduce.

**Action.** Collapse the tiers to one documented entry point per metric, keeping the
others as thin deprecated aliases. The tier split is currently pure cost: 4 code paths,
4 sets of defaults that have already diverged once into a 7 dB mismatch (recorded in
`CLAUDE.md`) and once into a silently-ignored quefrency window (`PRAAT_MODIFICATIONS.md`
v4.9.10, ~0.3 dB), 3× the documentation, and zero measured benefit. Replace every
hard-coded speed-up number with figures regenerated by
`inst/benchmarks/`, or delete the numbers.

### 2.3 On x86 the SIMD layer compiles to SSE2 only

`src/Makevars.in` deliberately, and correctly, omits `-march=`/`-O3`/`-flto` for CRAN
compliance. There is no runtime dispatch either — a grep for
`__attribute__((target(...)))`, `xsimd::dispatch` and `arch_list` across `src/` returns
nothing. So on x86-64 CRAN builds, `xsimd::simd_traits<double>::type` resolves to the
guaranteed baseline: **SSE2, 2 doubles per vector**. AVX2 (4-wide) and AVX-512 (8-wide)
are never reached on any user machine.

`vignettes/performance-simd.Rmd:72-74` advertises "AVX2 2–4×" and "AVX-512 4–8×" and
`:126-127` gives per-FFT AVX2/AVX-512 timings. Those code paths cannot execute as built.

Also note `RcppXsimd 7.1.6.1` pins xsimd to the 2019 v7 API; `src/xsimd_compat.h` exists
solely to bridge v7 and v8+. Current xsimd is 13.x.

**Actions.** Pick one:

- **Add runtime dispatch** where it demonstrably pays: compile the two or three genuinely
  hot kernels two or three times with `__attribute__((target("avx2")))` etc., select via
  `__builtin_cpu_supports` at load. This is CRAN-legal (no global `-march`). Only worth it
  after §1.1 and §2.1, and only for kernels with a measured win.
- **Or retire most of the SIMD layer** (§3.2). Given §1.5 measures no net gain on NEON,
  and x86 gets SSE2, the honest cost/benefit currently favours deletion.

Either way, correct the vignette so it describes what the shipped binary does.

### 2.4 pladdrr's CPPS defaults differ from Praat's in 5 of 11 parameters

From `praat.github.io/LPC/praat_LPC_init.cpp:759-773` and `LPC/Cepstrum_enums.h`:

| parameter | Praat `Get CPPS…` default | pladdrr default | same? |
|---|---|---|:--:|
| subtract trend before smoothing | `true` | `TRUE` | ✓ |
| time averaging window | **0.02 s** | 0.001 s | ✗ |
| quefrency averaging window | 0.0005 s | 0.0005 s | ✓ |
| peak search pitch floor | 60 Hz | 60 Hz | ✓ |
| peak search pitch ceiling | **330.0 Hz** | 333.3 Hz | ✗ |
| tolerance | 0.05 | 0.05 | ✓ |
| interpolation | parabolic | parabolic | ✓ |
| trend line quefrency range | **0.001 – 0.05 s** | 0.003 – 0.04 s | ✗ |
| trend type | **Exponential decay** | straight | ✗ |
| fit method | **Robust slow** (Theil–Sen) | robust (Siegel) | ✗ |

On the fixture this is the difference between 9.92 dB and 4.82 dB — not a rounding
difference, a different measurement. The pladdrr values are the AVQI/Maryn convention and
are a defensible *choice*, but they are undocumented as a deviation, and design goal 1
says a user who calls `pc$get_cpps()` should get what Praat's `Get CPPS…` gives.

**Action.** Either match Praat's defaults and provide `cpps_profile("avqi")` for the
clinical convention, or keep the current defaults and state the deviation prominently in
`get_cpps()`, `calculate_cpps_fast()` and `calculate_cpps_ultra()` with a side-by-side
table. Do not leave it implicit.

Note the performance interaction: Praat's default fit method is the O(n log n) one, so
matching Praat's defaults would *also* halve the runtime (§1.1).

### 2.5 Verified fidelity, and where it drifts

Same parameters on both sides, 1 s fixture:

| routine | pladdrr | Praat | relative Δ |
|---|---|---|---:|
| Pitch (ac) → mean F0 | 440.0102272576 | 440.0102272576 | 4.1e-14 |
| Formant (burg) → F1 mean | 420.9256276637 | 420.9256276637 | 4.2e-15 |
| Intensity → mean dB | 84.9480337385 | 84.9480334306 | 3.6e-09 |
| MFCC → n frames | 195 | 195 | exact |
| Harmonicity (cc) → mean | 91.8635027629 | 91.8634211224 | 8.9e-07 |
| PointProcess → jitter (local) | 8.024e-07 | 8.024e-07 | 4.1e-05 |
| **Spectrogram → power at (0.5 s, 1000 Hz)** | **3.87072e-05** | **3.13169e-05** | **2.4e-01** |

The first five are excellent. The spectrogram figure is a **24 % discrepancy** and needs
triage: either `get_power_at()` has different interpolation semantics from Praat's
`Get power at:` (an API-mapping bug), or the spectrogram itself drifts. Either way, no
test catches it today — which is the more important finding.

CPPS drifts consistently at the milli-dB level. Across six parameter variants, pladdrr −
Praat = −0.0049, −0.0027, −0.0027, −0.0023, +0.0004, +0.0014 dB. Traced to source: the
`PowerCepstrogram` matrix itself already differs — cell [10,10] is
30337052.27585732 vs 30337052.27644339 (rel 1.9e-11), cell [100,250] is
456863.33595815 vs 456863.33600452 (rel 1.0e-10). Disabling SIMD (`pladdrr_simd(FALSE)`)
and varying thread count both leave the CPPS value bit-identical, so neither is the cause.
The remaining candidate is the **pocketfft-for-FFTPACK substitution**
(`praat.github.io/dwsys/NUMFourier.cpp:42,95-112`, PRAAT_MODIFICATIONS v4.8.12), whose
different butterfly ordering gives ~1e-11 relative differences that the log + peak-pick +
robust-fit chain amplifies to ~3e-3 dB.

Milli-dB is far below any phonetic or clinical threshold, so this is not a usability
problem. It *is* a documentation problem: v4.8.12's rationale is recorded as "code
modernization" with "drop-in replacement, no data layout changes", and the numerical
consequence is not recorded anywhere. Given the FFT is 0.3 % of the CPPS budget (§1.1),
the substitution is currently paying a fidelity cost for no measured gain on the flagship
path — worth benchmarking pocketfft vs FFTPACK on the spectrum/spectrogram paths where it
might actually earn its keep, and reverting if it does not.

Threading is deterministic — CPPS is bit-identical at 1, 2, 4 and 10 threads. Good.

### 2.6 `fit_method = "robust slow"` is non-deterministic (upstream Praat defect)

Six runs of the same call on the same file, `pladdrr_threads(1)`:

```
6.9994374622  7.0983884471  6.8768187202  7.0050152433  6.6395636663  6.3004755654
```

A spread of ~0.8 dB on a metric whose clinical decision thresholds are around 0.5 dB.

This is **not** a pladdrr bug. Four runs of the identical Praat script:

```
1.3865e+290   6.8801067417   6.6758676480   -3.0559e+161
```

Praat's own Theil–Sen path is non-deterministic and occasionally returns values ~1e290.
Root cause is upstream: `structSlopeSelector::slopeQuantile_TheilSen` →
`getKth_TheilSen`, which uses `NUMrandomInteger` for Matoušek-style sampling
(`dwsys/SlopeSelector.cpp:66-68,243-249`). pladdrr faithfully reproduces the instability
while — in the samples taken — avoiding the astronomic blow-ups.

This matters more than it looks, because **`Robust slow` is Praat's documented default**
for `Get CPPS…` (`kCepstrum_trendFit` `enums_end` DEFAULT = `ROBUST_SLOW`). Anyone
reproducing a Praat CPPS analysis with default settings is using a broken estimator.

**Actions**

1. Document it. A user choosing `"robust slow"` must be told the result is not
   reproducible.
2. Warn at runtime when `fit_method = "robust slow"` is selected.
3. Consider seeding `NUMrandom` deterministically per call so pladdrr's Theil–Sen is at
   least *reproducible*. That is a deliberate, documentable deviation that makes pladdrr
   better than the oracle — exactly the case where deviating from Praat is right.
4. Report upstream. This is a genuine Praat bug with a clean reproducer.
5. Resolve this **before** acting on the §1.1 recommendation to switch the default
   `fit_method` for speed.

---

## 3. Standards, code quality, maintainability

### 3.1 `R CMD check --as-cran` status

From `pladdrr.Rcheck/00check.log` (tarball build, v4.9.6): **1 ERROR, 3 WARNINGs, 5 NOTEs**.

| finding | severity | assessment |
|---|---|---|
| `checking PDF version of manual without index … ERROR` | ERROR | Local only — missing `inconsolata.sty`. Install `tinytex::tlmgr_install("inconsolata")`; not a package defect. |
| Non-portable flag `-ffp-contract=off` | WARNING | **Real CRAN blocker.** Also a deliberate and well-argued choice — it is what keeps FMA contraction from breaking bit-exactness. Pre-clear it with CRAN in `cran-comments.md` with the fidelity justification; do not silently drop it. |
| Compiled code uses `stdout`/`stderr`/`exit`/`_exit` | WARNING | **Real CRAN blocker.** All four are in vendored Praat objects: `melder/melder_console.o`, `sys/praat.o`, `fon/Praat_tests.o`, `melder/melder_sysenv.o`. Needs the same patch-and-document treatment already applied for `rand()`/`sprintf()` in v4.9.6. `fon/Praat_tests.cpp` in particular looks droppable from `FON_SRC` entirely. |
| PDF manual LaTeX errors | WARNING | Same root cause as the ERROR. |
| Installed size 31.3 MB (libs 22.9, signalfiles 3.2, extdata 1.3, doc 1.6) | NOTE | Needs a written justification for CRAN, plus §3.2/§3.4 slimming. |
| HTML validation (`<main>` unrecognised, `<table>` lacks summary) | NOTE | Toolchain artefact of the local `tidy`; ignorable. |
| New submission / timestamps / check-dir detritus | NOTE | Housekeeping. |

Tarball is 9.87 MB against CRAN's 5 MB guideline — needs an explicit exemption request or
further slimming.

Not yet exercised: `R CMD check` on Windows and Linux, and under
`_R_CHECK_FORCE_SUGGESTS_`/`--use-valgrind`. Given §1.4 and §2.3 are platform-specific,
the existing `.github/workflows` matrix is the right place to close that gap.

### 3.2 Dead and near-dead code

Reachability scan over `src/*_simd.cpp` (a symbol counts as live if it is named in any
other `.cpp`/`.h` in the repo, so these are lower bounds on deadness):

**Fully unreferenced — 1 174 lines, compiled on every build:**

| file | lines |
|---|---:|
| `pitch_processing_simd.cpp` | 308 |
| `num_matrix_simd.cpp` | 231 |
| `num_distance_simd.cpp` | 214 |
| `sound_statistics_simd.cpp` | 191 |
| `sound_convolution_simd.cpp` | 124 |
| `num_filtering_simd.cpp` | 106 |

**Mostly unreferenced:**

| file | lines | symbols referenced |
|---|---:|---|
| `harmonicity_simd.cpp` | 811 | 1 of 13 |
| `klattgrid_simd.cpp` | 589 | 1 of 10 (spot-checked: `apply_exponential_decay_simd`, `find_extremum_simd`, `glottal_flow_polynomial_simd`, `normalize_sound_simd`, `sound_diff_simd` have **zero** references anywhere) |
| `excitation_simd.cpp` | 258 | 1 of 8 |
| `cochleagram_simd.cpp` | 231 | 1 of 6 |
| `complexspectrogram_simd.cpp` | 518 | 2 of 7 |
| `formant_lpc_simd.cpp` | 469 | 3 of 8 |

Roughly **half of the ~8 300 lines of SIMD code is unreachable**. Add `sound_pool.cpp`
(433 lines, "Phase 4 Memory Optimization") — referenced only from `RcppExports`, never
from any internal pipeline, so the object API never pools anything.

Combined with §1.5 (no net NEON gain) and §2.3 (SSE2-only on x86), the recommendation is
blunt: **delete the unreachable kernels and keep only those with a measured win**
(`mfcc_simd`, `textgrid_simd`, `intensity_simd`, `powercepstrogram_simd`, `slopeselector_simd`
are the plausible survivors). That removes thousands of lines, shortens the 347-second
install, shrinks the 22.9 MB `libs/`, and makes the remaining SIMD claims true.

### 3.3 Build system defects

1. **`configure`'s RcppXsimd detection is dead code.** It computes `XSIMD_FLAG` as
   `-DHAVE_XSIMD` or empty, but `src/Makevars.in:13` reads
   `PKG_CPPFLAGS = @XSIMD_FLAG@ -DHAVE_XSIMD …` — the macro is defined unconditionally.
   If RcppXsimd were genuinely absent, the build would define `HAVE_XSIMD` and then fail
   on the missing headers. Since `LinkingTo: RcppXsimd` makes it a hard build dependency
   anyway, delete the detection and the duplicate `-DHAVE_XSIMD`, or make the flag
   actually conditional.
2. **`FLAC_SRC` and `MP3_SRC` (lines 236-268) reference a `praat/` tree that no longer
   exists** (removed in the v4.9.5 CRAN slimming) and are not part of `SOURCES`. They are
   dead variables — *and* they hide a live bug, see §4.3.
3. `praat.github.io/fon/Praat_tests.cpp`, `Movie.cpp`, `Photo.cpp`, `WordList.cpp`,
   `SpellingChecker.cpp` and `Corpus.cpp` are compiled. `Praat_tests.o` is one of the
   objects triggering the `stderr` CRAN warning. Some of the others may be reachable from
   `praat_uvafon_init.cpp` class registration and needed by the script interpreter —
   verify per file before removing, but this is the right place to look for install-time
   and binary-size savings.

### 3.4 Package hygiene

- `inst/signalfiles/` (3.2 MB, 22 WAV files under `AVQI/input/` and `DSI/input/`) is
  shipped to every user. These are test fixtures. Move to `tests/` (Rbuildignored) or a
  companion data package.
- `inst/.DS_Store`, `inst/signalfiles/.DS_Store`, `inst/benchmarks/.DS_Store` are present
  in `inst/`. Add `\.DS_Store$` to `.Rbuildignore` and clean.
- `src/RcppExports.cpp` is 12 483 lines and `R/RcppExports.R` is 4 343 — 34 % of all C++
  and 17 % of all R in the package is generated glue. That is a symptom of the flat
  export surface (258 R exports, 500+ methods, many near-duplicates across the tiers).
  Collapsing the tiers (§2.2) shrinks this directly.

### 3.5 Design principle 6 (robust error reporting) is documented but not implemented

`inst/agents/AGENT_GUIDE.md:28-56` describes a typed condition system:
`pladdrr_input_error`, `pladdrr_praat_error`, `pladdrr_data_loss`, all inheriting
`pladdrr_error`, produced by macros in `src/pladdrr_errors.h` and reclassified by
`with_pladdrr_errors()`.

Measured reality:

```r
with_pladdrr_errors(sound$to_pitch(0, 600, 75))   # -> simpleError/error/condition
with_pladdrr_errors(Sound("/no/such.wav"))        # -> simpleError/error/condition
```

- `pladdrr_error_cond()` / `pladdrr_warning_cond()` (`R/error-classes.R:39,48`) are called
  from **no other file in the package**.
- `PLADDRR_STOP_PRAAT` appears in exactly one source file (`src/batch_queries.cpp`, twice).
- No error observed in testing carries a `pladdrr_*` class.

The messages themselves are good — `"pitch_floor must be a single positive number (Hz),
got: -10"`, `"Sound file not found: …"` — so the input-validation layer is real. It is the
*condition classing* that is unwired, which is what programmatic callers (and agents) need.

Related gaps found while probing:

- `sound$extract_part(5, 10)` on a 1.0 s Sound returns a 5-second, 220 500-sample object
  of silence with no warning. Praat does the same (verified), so this is faithful — but
  design principle 6 explicitly names "loss of data" as something to report. This is the
  textbook case for `PLADDRR_WARN_DATA_LOSS` while keeping Praat's return value.
- `calculate_cpps_fast(sound, qstart_fit = 0.04, qend_fit = 0.003)` — a reversed range —
  returns 10.43 silently instead of erroring.
- `sound$get_value_at_time(99, "sinc70")` produces `Warning: NAs introduced by coercion`
  followed by `Error: Invalid channel number`. The second positional argument is `channel`,
  not interpolation; a character argument is `as.integer()`-coerced rather than
  type-checked, so the diagnostic points at the wrong thing.
- `Sound()` on a non-audio file reports
  `FFMPEG error in 'avformat_open_input': Invalid data found…` — leaking a fallback
  implementation detail instead of "not a supported audio file".

### 3.6 Test suite

| metric | value |
|---|---|
| test files | 69 |
| `expect_*` calls | 2 050 |
| exported functions referenced in tests | 144 of 258 (56 %) |
| testthat wall time in `R CMD check` | 18 s |
| faithfulness oracle routines | **5** |

The faithfulness harness (`tests/testthat/faithfulness/routines.R` +
`test-praat-faithfulness.R`) is well designed — per-routine Praat oracle, explicit
tolerance, mandatory rationale, auto-generated `FAITHFULNESS_REPORT.md`. It is the right
mechanism for design goal 1. It covers **5 routines**: duration, sample count, pitch mean,
intensity mean, formant F1.

It does not cover CPPS, spectrogram, MFCC, HNR, jitter/shimmer, LPC, PointProcess, TextGrid
or any batch path — which is exactly why the milli-dB CPPS drift (§2.5), the 24 %
spectrogram discrepancy (§2.5) and the `"robust slow"` non-determinism (§2.6) were all
undetected.

**Action, and this is the highest-leverage quality item in the report:** grow
`FAITHFULNESS_ROUTINES` to cover every routine with a Praat equivalent. The registry
format makes each addition ~15 lines. Run it in CI on every PR. Target the ~40 most-used
routines first; 500 methods is the eventual goal but the first 40 catch nearly everything.

Also add: property tests for boundary/invalid inputs (the §3.5 cases), and a
determinism test that runs each routine twice and asserts bit-equality (which would have
caught §2.6 immediately).

---

## 4. Documentation

The stated target is 90 % "how to use it and what comes out", 10 % implementation
detail. Current state is closer to the inverse in several places.

### 4.1 Examples are essentially never executed

| metric | count |
|---|---:|
| `.Rd` files | 370 |
| with `\examples` | 175 |
| of those, using `\dontrun` | 166 |
| **with runnable examples** | **9** |
| with `\value` | 328 |
| with `\seealso` | 23 |
| with `\details` | 65 |

`R CMD check` reports `checking examples … OK` and `pladdrr-Ex.timings` shows 172 entries
at 0.000 s — nothing runs. So 195 documented objects have no example at all, and of the
175 that do, 166 are unverifiable and free to rot. One already has:
`calculate_cpps_ultra`'s example references
`system.file("signalfiles", "sound.wav", package = "pladdrr")`, which does not exist
(the directory contains `AVQI/input/cs1.wav` … `DSI/input/ppq3.wav`).

**Action.** `inst/extdata/test.wav` is 86 KB and ships already; almost every example can
run against it in milliseconds. Convert `\dontrun` → runnable for everything that does not
need Praat, network or a long computation; use `\donttest` for the slow ones so they still
run under `--run-donttest` in CI. This turns 370 man pages from prose into tested prose.

### 4.2 `AGENT_GUIDE.md` is 54 % changelog

9 231 lines / 365 KB. Section map:

| lines | section | category |
|---:|---|---|
| 1–4 213 | Quick start, architecture, object types, unit codes, common patterns, re-implementing a Praat procedure, method signatures, validation, pitfalls, quick reference | **usage — this is the valuable part** |
| 4 214–4 555 | Version History (historical archive) | changelog |
| 4 556–7 599 | Historical SIMD and performance archive (superseded) — **3 043 lines explicitly labelled superseded** | changelog |
| 7 600–9 231 | Full Changelog / Previous Changes v4.4.6–v4.4.8 | changelog |

Design principle 5 asks for a guide that lets a coding agent learn the package
*efficiently*. Over half the file is superseded history, and `NEWS.md` (115 KB) already
carries the changelog. Loading this guide costs an agent roughly 90 000 tokens, more than
half of it archive.

**Action.** Move everything from line 4 214 down into `NEWS.md` or
`dev/AGENT_GUIDE_ARCHIVE.md`. Target ~4 000 lines of pure usage. Also promote the
"Typed Errors" section from aspirational to accurate (§3.5) or move it to a design doc —
right now it documents behaviour that does not occur.

### 4.3 Documented behaviour that does not hold

- **Native FLAC/MP3 reading does not exist.** `man/Sound.Rd` and
  `R/sound-wrapper.R:15,87` state "Native Praat reader (primary): WAV, AIFF, AIFC, FLAC,
  MP3, NIST, NeXT/Sun" with "av package fallback: Only used for formats Praat doesn't
  support (OGG Vorbis, etc.)". Direct test:

  ```
  .sound_read_from_file_native("t.flac")  ->  Native sound file reading failed
  .sound_read_from_file_native("t.mp3")   ->  Native sound file reading failed
  ```

  Both succeed via `Sound()` only because they fall through to `av`. `av` is in
  **Suggests**, so on an installation without it, FLAC and MP3 fail outright. Root cause
  is §3.3 item 2 — `flac_stubs.cpp` and `sound_audio_stubs.cpp` are compiled instead of
  the FLAC/MP3 libraries, whose `FLAC_SRC`/`MP3_SRC` variables point at a deleted tree.
  Fix the build to include the libraries, or correct the documentation and move `av` to
  Imports.
- **`pladdrr_simd(FALSE)` does not fully disable SIMD** — §1.5.
- **All tier speed-up claims** — §2.2.
- **AVX2/AVX-512 vignette claims** — §2.3.
- **Typed error classes** — §3.5.

### 4.4 Reference pages read like release notes

`R/performance-helpers.R` is representative:

- `@param max_quefrency` (line 502) contains: *"BUG FIX v4.9.10: previously declared but
  silently ignored by the C++ core, which hardcoded the fit window to [0.003, 0.04]…"* —
  four lines of changelog inside a parameter description.
- `@details` leads with **"TIER 4 ULTRA API - Maximum Performance"** and a stale timing
  table, before saying what the function returns.
- Cross-references point at `/CLAUDE.md` and `inst/agents/AGENT_GUIDE.md` — the first is
  not shipped to users at all.
- `man/Sound.Rd` marks methods "**NEW**" and embeds Markdown fenced code blocks inside
  `\section{}`, which render as literal backticks in the PDF/HTML manual. Use
  `\preformatted{}` or roxygen `@examples`.

Method listings such as `man/Sound.Rd`'s "Query Methods" give names only — no signature,
no argument order, no return type, no units. For a package explicitly aimed at coding
agents re-implementing Praat scripts, argument order is the single most valuable fact
(and the one `CLAUDE.md` records as a past bug source: "`to_point_process_direct()` arg
order"). Generate per-method signature + `@return` blocks from the dispatch tables.

**Rewrite pattern for each page:** what it computes → arguments with units and valid
ranges → what is returned, with type and units → a runnable example → *then*, if truly
needed, one short "Praat correspondence" note naming the exact Praat command and its
default differences.

---

## 5. Prioritised actions (status-tracked against v4.9.18)

Status legend: **OPEN** — unchanged, still applies · **REDUCED** — partly addressed,
smaller now · **PARTIAL** — work landed but does not yet achieve the goal ·
**PRUNED** — no longer justified by measurement, dropped from the plan.

### Tier 0 — blockers introduced in v4.9.18 (new, must clear first)

| # | Action | Status |
|---|---|---|
| **B1** | **Fix the `MelderThread_PARALLELIZE` brace misuse in `src/batch_queries.cpp`.** HEAD does not compile. The macro already opens its own scope; the two new blocks in `PowerCepstrogram_smooth_fast` add a stray `{`…`}` pair each. Correct form is `MelderThread_PARALLELIZE(n, thr)` (no brace) … `MelderThread_FOR(i) {` … `} MelderThread_ENDFOR`. | **NEW — blocker** |
| **B2** | **Regenerate `src/RcppExports.cpp`.** `calculate_cpps_ultra_cpp` gained a 16th parameter (`fused`); `R/RcppExports.R` was regenerated but the C++ glue was not, so the package fails to load with `symbol not found in flat namespace '__Z24calculate_cpps_ultra_cppP7SEXPREC…'`. Add a `Rcpp::compileAttributes()` freshness check to CI. | **NEW — blocker** |
| **B3** | **Fix or remove `calculate_cpps_ultra(fused = TRUE)`.** It returns **−47.169 dB** where the correct value is **9.9205 dB**, and is **3.1× slower** (532 ms vs 173 ms). Deterministic, so it is a logic error: the fused path reuses the trend fitted on the *raw* cepstrum as the baseline for the peak computed on the *smoothed, trend-subtracted* cepstrum — Praat fits the second trend on the smoothed data. It also replaces a threaded path with a serial per-frame loop. | **NEW — blocker** |
| **B4** | **Repair the 4 broken faithfulness routines** added in v4.9.18 (see §7.2). Two have malformed Praat oracle scripts, one duplicates an existing routine at an unachievable tolerance, one returns `Δ=Inf`. Net working coverage added by v4.9.18 is 1 routine, not 5. | **NEW — blocker** |
| **B5** | **Triage the 43 failing/erroring tests** (28 failures + 15 errors of 612, across 12 files). Several are harness bugs — `test-simd-window-functions.R` and `test-simd-autocorrelation.R` call unexported internals such as `.apply_hamming_window_simd()` without a `pladdrr:::` prefix. Verified pre-existing, not introduced by the build fixes above. | **NEW** |
| **B6** | **Stop the test suite writing into the source tree.** Running the faithfulness tests overwrites the tracked files `inst/agents/FAITHFULNESS_REPORT.md` and `tests/faithfulness_report.csv`. Write to `tempdir()` and copy only on explicit request. | **NEW** |

### Tier 1 — largest effect on the stated goals

| # | Action | Status |
|---|---|---|
| 1 | **Cut the Siegel repeated-median cost in the CPPS path (§1.1).** Re-profiled on 4.9.18: `expandPartition` 6 628 + `medianOfNinthers` 3 829 + `adaptiveQuickselect` 3 544 + `NUMquantile_e` 1 167 + `siegel_row_slopes_simd` 826 ≈ **94 % of non-idle samples**, unchanged. pocketfft is still 0.3 %. Start with `std::nth_element` vs median-of-ninthers, and hoisting the constant `xp` grid. | **OPEN** — premise intact; the v4.9.18 `fused` attempt is B3 |
| 2 | **Extend the faithfulness oracle and run it in CI (§3.6).** Registry grew 5 → 10 routines, but only 6 execute correctly (see B4). Still uncovered: spectrogram, HNR, jitter/shimmer, MFCC, LPC, PointProcess, TextGrid, batch paths. Add a determinism test (run twice, assert bit-equality). | **PARTIAL** |
| 3 | ~~Replace static equal thread partitioning with dynamic chunk dispatch.~~ The symptom that justified this — 10 threads slower *and* hungrier than 9 — no longer reproduces. Three independent sweeps on 4.9.18 put 10 threads fastest (839–898 ms vs 860–933 at 9) with CPU flat at +4 % (was +11 %). `MelderThread_run` still partitions statically, so the E-core straggler risk remains latent, but there is no measured cost to fix. | **PRUNED** |
| 4 | **Triage the spectrogram `get_power_at` discrepancy (§2.5).** Re-measured on 4.9.18: pladdrr 3.8707177309e-05 vs Praat 3.13169e-05, relative Δ **2.36e-01**. Unchanged, and still not covered by the oracle. | **OPEN** |
| 5 | **Document, warn about, and consider deterministically seeding `fit_method = "robust slow"` (§2.6); report upstream.** No warning or documentation added. | **OPEN** |

### Tier 2 — clear wins, bounded work

| # | Action | Status |
|---|---|---|
| 6 | **Delete the 1-based copy in the `*_simd_bridge.cpp` files (§1.6).** v4.9.18 added `simd_bridge_stat_direct()` and small-*n* fallbacks to `src/simd_bridge.h` — but **that header is included by no translation unit**, so the change has no effect. Measured on 4.9.18 vs base R: mean **0.87×**, quantile **0.47×**, sd 1.10×, range 2.33×. Also note the new `simd_bridge_binary` small-*n* fallback hard-codes a dot product, which will be wrong for any non-dot-product binary kernel if the header is ever wired up. | **OPEN** (fix landed in dead code) |
| 7 | **Fix the platform thread-count formula for Windows and Linux (§1.4).** `src/melderthread_impl.cpp` still hardcodes the macOS `floor(n/min)` branch. | **OPEN** |
| 8 | **Raise threading thresholds for short analyses; add a throughput/efficiency thread policy (§1.3).** Overheads improved but the pattern holds — 10 s audio, 1 thread → auto: spectrogram **+65 %** CPU (was +117 %) for 3.4×, formant **+27 %** (was +43 %) for 1.6×, pitch **+16 %** (was +33 %) for 4.5×. | **REDUCED** |
| 9 | **Collapse the CPPS tiers to one entry point (§2.2).** Re-measured on 4.9.18, 1 s fixture, all cores: R6 170.1 ms, `calculate_cpps_fast` 172.6 ms, `calculate_cpps_ultra` 173.4 ms — all identical in value (9.9205293140) and within 2 % in time. Praat is 148.2 ms. `fused` adds a fifth variant. | **OPEN** — now worse |
| 10 | **Resolve the CPPS defaults question (§2.4)** — match Praat, or document the deviation loudly. | **OPEN** |
| 11 | **Investigate the multithreaded gap vs Praat, starting with thread QoS (§2.1).** Re-measured on 4.9.18: pitch 0.70×, formant 0.88×, intensity 0.90×, hnr 0.75×, spectrogram 0.57×, pointprocess 0.76×, mfcc 1.43×. | **OPEN** |

### Tier 3 — quality and compliance

| # | Action | Status |
|---|---|---|
| 12 | **Delete unreachable SIMD kernels and `sound_pool.cpp` (§3.2).** Byte-identical: the same 6 files (1 174 lines) have zero externally referenced symbols; `harmonicity_simd.cpp` 1/13, `klattgrid_simd.cpp` 1/10. The case strengthened — the SIMD toggle now measures **0.98×–1.06×** across five routines (was 0.87×–1.19×), i.e. indistinguishable from no SIMD at all. | **OPEN** |
| 13 | **Fix `configure`'s dead xsimd detection and the stale `FLAC_SRC`/`MP3_SRC` (§3.3); then fix native FLAC/MP3 or correct the docs and move `av` to Imports (§4.3).** `PKG_CPPFLAGS = @XSIMD_FLAG@ -DHAVE_XSIMD` still doubles the define; `FLAC_SRC`/`MP3_SRC` still point at the removed `praat/` tree; `.sound_read_from_file_native()` still fails on both `.flac` and `.mp3`. | **OPEN** |
| 14 | **Address the two real CRAN warnings (§3.1)** — `-ffp-contract=off` (pre-clear with the fidelity justification) and the vendored `stderr`/`exit` objects (`Praat_tests.o` is still in the link line). | **OPEN** |
| 15 | **Wire up the typed error conditions the guide promises; add data-loss warnings and reversed-range validation (§3.5).** Zero raise sites outside `R/error-classes.R`; `with_pladdrr_errors()` still yields `simpleError`; `extract_part(5, 10)` on a 1 s Sound still returns 5 s of silence with **no warning**; `calculate_cpps_fast(qstart_fit = 0.04, qend_fit = 0.003)` still returns 10.4325 silently. | **OPEN** |
| 16 | **Move `inst/signalfiles/` (3.2 MB) out of the shipped package (§3.4).** Still shipped, still absent from `.Rbuildignore`. | **OPEN** |

### Tier 4 — documentation

| # | Action | Status |
|---|---|---|
| 17 | **Make examples runnable against `inst/extdata/test.wav` (§4.1).** Unchanged: 370 Rd, 175 with `\examples`, 166 `\dontrun`, **9 runnable**, 23 `\seealso`. | **OPEN** |
| 18 | **Trim `AGENT_GUIDE.md` by archiving the changelog (§4.2).** v4.9.18 added `ARCHITECTURE.md` (106 lines) and `HISTORY.md` (30 lines), but **no archive content was moved**: `HISTORY.md` merely points back at AGENT_GUIDE sections, and the guide **grew from 9 231 to 9 240 lines** (366 KB). Lines 4 223–9 240 are still version history and the "superseded" SIMD archive. | **OPEN** — unchanged in substance |
| 19 | **Strip changelog text out of `@param`/`@details`; add signatures and return types/units to method listings (§4.4).** The `BUG FIX v4.9.10` prose was removed from two `@param` entries. Still present: `R/performance-helpers.R:520-522` "~4000ms / ~2000ms / ~1500ms (2.7x speedup)", `:484` "2-3x faster", `:8` "roughly 1.5-2x", `:657` "2-4x speedup". | **REDUCED** |
| 20 | **Correct the SIMD vignette to describe the shipped binary (§2.3).** `vignettes/performance-simd.Rmd:72-73,126-127` still advertise AVX2 2–4× and AVX-512 4–8×; `performance-optimization.Rmd` still claims 2–3×, 5–20× and 20×. | **OPEN** |

---

## 6. What is working well

Worth stating plainly, because the list above is a defect list:

- **Numerical fidelity where it has been checked is excellent** — pitch at 4e-14, formants
  at 4e-15, intensity at 4e-9 relative error against Praat.
- **Threading is deterministic.** CPPS is bit-identical from 1 to 10 threads. That is not
  free, and it is the property that matters most for a scientific package.
- **The faithfulness harness design is right** — oracle scripts, per-routine tolerances,
  mandatory rationale, generated report. It needs breadth, not redesign.
- **`PRAAT_MODIFICATIONS.md` is a genuinely good artefact** — 1 051 lines of dated,
  file-level, rationale-carrying records of every change to the vendored tree. It is
  exactly what design principle 2 asks for. The one gap is that it records *what* changed,
  not the *numerical consequence* (§2.5).
- **Input validation messages are clear and specific**, naming the parameter and the
  offending value.
- **Nested-parallelism oversubscription is handled** in `analyze_files_parallel()` —
  a subtle problem that most packages get wrong.
- **The vendored-Praat build works at all**, across a 239-file Praat tree with stubs for
  GUI, audio, graphics and networking. That is substantial engineering.

---

## 7. v4.9.18 re-assessment

Re-run 2026-08-05 against `277e53d6` (v4.9.18), three commits after the v4.9.17 baseline:
`87453c6a` (CPPS fusion, SIMD gating, unit code fix, docs split), `121d54b4` (agent docs),
`277e53d6` (version bump). Same host, same fixture, same method as §0.

### 7.1 The committed tree does not build or load

Two independent defects, both in `87453c6a`:

1. `src/batch_queries.cpp` — the new `MelderThread_PARALLELIZE` blocks in
   `PowerCepstrogram_smooth_fast` each add a brace pair the macro already supplies:

   ```
   batch_queries.cpp:1271:13: error: expected expression
     1271 |             MelderThread_ENDFOR
   praat.github.io/melder/MelderThread.h:190:6: note: expanded from macro 'MelderThread_ENDFOR'
   ```

   Upstream call sites (`fon/Sound_to_Pitch.cpp:499`, `fon/Sound_to_Formant.cpp:358`,
   `dwtools/SampledIntoSampled.cpp:30`) show the required shape: no brace after
   `PARALLELIZE`, and `} MelderThread_ENDFOR` to close the `FOR`.

2. After fixing (1), the shared object links but fails to load:

   ```
   symbol not found in flat namespace '__Z24calculate_cpps_ultra_cppP7SEXPRECddddbdddidiidd'
   ```

   `calculate_cpps_ultra_cpp` gained a 16th parameter (`bool fused`), and
   `R/RcppExports.R` was regenerated — but `src/RcppExports.cpp:609` still declares the
   15-parameter form and registers it with arity 15. Regenerating also revealed that the
   committed `R/RcppExports.R` carried a **duplicated** `calculate_durations_simd_bridge`
   stub and was **missing** `should_use_simd_for_batch_queries_bridge`.

To obtain any measurement at all I applied both fixes locally: the four stray braces in
`src/batch_queries.cpp`, and `Rcpp::compileAttributes()`. These are in the working tree,
uncommitted — keep or revert as you prefer. Everything in §7.2–7.5 is measured on that
build. A `compileAttributes()` freshness check and a compile step in CI would have caught
both.

### 7.2 The CPPS fusion is numerically wrong and slower

`calculate_cpps_ultra(sound, fused = TRUE)`, 1 s fixture:

| entry point | time | value |
|---|---:|---|
| R6 `to_powercepstrogram()$get_cpps()` | 170.1 ms | 9.9205293140 |
| `calculate_cpps_fast()` | 172.6 ms | 9.9205293140 |
| `calculate_cpps_ultra()` | 173.4 ms | 9.9205293140 |
| **`calculate_cpps_ultra(fused = TRUE)`** | **532.1 ms** | **−47.1690843451** |
| Praat, same parameters | 148.2 ms | 9.9231836233 |

Off by 57 dB and 3.1× slower. The result is bit-identical at 1, 4 and 10 threads, so it is
a logic error rather than a race. Two causes are visible in the code:

- **Wrong baseline.** Praat's `PowerCepstrogram_getCPPS` fits the trend twice on purpose:
  once on the raw cepstrum (for `subtractTrend`) and once on the *smoothed,
  trend-subtracted* cepstrum (inside `PowerCepstrogram_to_Matrix_CPP`). The fused path
  stores the first fit and reuses it for the second, so every frame's CPP is measured
  against the wrong trend line. The two fits are not interchangeable — that is precisely
  why there are two.
- **Serial regression.** The fused loop is a plain `for (iframe …)` over
  `PowerCepstrumWorkspace`, replacing a `SampledIntoSampled_mt` path, which is why it is
  slower than the code it replaces despite doing half the fits.

The parameter defaults to `FALSE` and is documented as trading bit-exactness for speed, so
no default user is affected — but it currently trades correctness for slowness, and should
be fixed or withdrawn.

### 7.3 The faithfulness registry grew 5 → 10, but only 6 routines execute

Regenerated `inst/agents/FAITHFULNESS_REPORT.md`:

| Routine | Status |
|---|---|
| `Sound$get_total_duration` | pass (Δ = 0) |
| `Sound$get_number_of_samples` | pass (Δ = 0) |
| Sound → Pitch (cc) → mean F0 | pass (8.6e-12) |
| Sound → Intensity → mean dB | pass (3.1e-7) |
| Sound → Formant (burg) → F1@0.5 s | pass (5.4e-11) |
| Pitch (AC) → mean F0 | pass (9.5e-12) |
| **CPPS (`calculate_cpps_ultra`)** | **praat-error** — the oracle script omits the leading `"yes"` boolean, so Praat rejects it: `Argument "Tolerance" should be a number, not a string` |
| **Pitch (SHS) → mean F0** | **praat-error** — `To Pitch (shs): 0.0, …`; Praat requires `Time step > 0` |
| **Intensity → mean dB** (second, duplicate entry) | **fail** — Δ = 7.72e-06 against a 1e-06 tolerance |
| **Formant (keepAll) → F1@0.5 s** | **fail** — Praat returns 0, pladdrr returns `NA`, Δ = Inf |

So the one routine the registry most needed — CPPS, where §2.5 measured a real
milli-dB drift — never runs, and the suite reports a failure rather than a gap. Net new
*working* coverage is one routine (Pitch AC). The 24 % spectrogram discrepancy of §2.5 is
still not represented at all.

Wider suite: **612 tests, 28 failures + 15 errors across 12 files.** A sample of these are
harness bugs rather than package defects — `test-simd-window-functions.R` and
`test-simd-autocorrelation.R` call unexported internals (`.apply_hamming_window_simd()`)
without a `pladdrr:::` prefix. Verified pre-existing: the same stubs are present in the
committed `R/RcppExports.R`, so the build fixes in §7.1 did not cause them.

Running the suite also rewrites two tracked files, `inst/agents/FAITHFULNESS_REPORT.md`
and `tests/faithfulness_report.csv`.

### 7.4 What genuinely improved

- **The 10-thread regression is gone.** Replacing the bespoke `parallel_for_range` with
  `MelderThread_PARALLELIZE` flattened the curve. `calculate_cpps_fast` on 5 s, three
  independent sweeps:

  | threads | wall (ms) | CPU (ms) |
  |---:|---|---|
  | 6 | 967 / 1089 / 955 | 5 438 / 5 596 / 5 404 |
  | 8 | 918 / 909 / 860 | 5 694 / 5 714 / 5 693 |
  | 9 | 933 / 920 / 886 | 5 729 / 5 714 / 5 712 |
  | 10 | **898 / 839 / 851** | 5 730 / 5 678 / 5 708 |

  10 threads is now fastest and CPU is flat above 8 (+4 % vs 1 thread, previously +11 %).
  Action 3 is **pruned**. The static equal partitioning in `MelderThread_run` is unchanged,
  so the straggler risk remains latent on other asymmetric hardware — worth a note in the
  threading docs, not a work item.

- **Threading energy overhead on short analyses roughly halved** (10 s audio, 1 thread →
  auto): spectrogram +117 % → **+65 %**, formant +43 % → **+27 %**, pitch +33 % → **+16 %**.
  Action 8 is **reduced**, not closed.

- **One threading mechanism instead of two.** Deleting `parallel_for_range` in favour of
  `MelderThread_PARALLELIZE` means `pladdrr_threads()` now governs the cepstrogram smooth
  by construction rather than by a duplicated core-count lookup.

- **Unit-code duplication removed.** Four hand-rolled `c("hertz" = 0L, …)` maps in
  `R/batch-queries.R` and `R/pitchtier-wrapper.R` were replaced by the shared
  `unit_to_code()` helper.

- **Two changelog fragments removed** from `@param` documentation.

### 7.5 What did not change

Re-verified as byte- or measurement-identical to the v4.9.16 findings:

| Finding | v4.9.16 | v4.9.18 |
|---|---|---|
| Siegel share of CPPS profile | ~94 % | ~94 % (15 994 of ~17 000 non-idle leaf samples) |
| Spectrogram `get_power_at` relative Δ vs Praat | 2.36e-01 | 2.36e-01 |
| CPPS tier spread | 146–150 ms, identical values | 170–173 ms, identical values |
| SIMD toggle gain | 0.87×–1.19× | 0.98×–1.06× |
| `calculate_mean_simd_bridge` vs `mean()` | 0.50× | 0.87× |
| `calculate_quantile_simd_bridge` vs `quantile()` | 0.52× | 0.47× |
| Fully unreferenced `*_simd.cpp` | 6 files, 1 174 lines | 6 files, 1 174 lines |
| Native FLAC / MP3 read | fails, falls back to `av` | fails, falls back to `av` |
| `with_pladdrr_errors()` class | `simpleError` | `simpleError` |
| `extract_part(5, 10)` on 1 s Sound | 5 s of silence, no warning | 5 s of silence, no warning |
| `calculate_cpps_fast(qstart > qend)` | 10.4325, no error | 10.4325, no error |
| Rd with runnable examples | 9 of 370 | 9 of 370 |
| `AGENT_GUIDE.md` | 9 231 lines | 9 240 lines |
| `inst/signalfiles/` shipped | 3.2 MB | 3.2 MB |
| `@XSIMD_FLAG@ -DHAVE_XSIMD` double define | present | present |
| `FLAC_SRC` / `MP3_SRC` → removed `praat/` tree | present | present |
| macOS-only thread-count formula | present | present |

### 7.6 Note on local build flags

This machine's `~/.R/Makevars` sets `CXX17FLAGS = -O3 -march=native -ffp-contract=off`.
All timings in this report are therefore from an `-O3 -march=native` build, not a
CRAN-style `-O2` one. On arm64 that does not widen NEON (still 128-bit), so the SIMD
conclusions in §1.5 and §2.3 stand; it does mean the "pladdrr is slower than Praat"
comparisons in §2.1 and §7.5 are, if anything, generous to pladdrr.

---

## 8. v4.9.19 implementation log

Everything below was built, installed and measured on the same host and fixture
as §0. Full test suite after the work: **612 tests, 1,914 pass, 7 failures,
0 errors** (was 1,843 / 28 / 15). Faithfulness registry: **14 routines, all pass**
(was 10, of which 4 could not run).

### Done

| Item | Outcome |
|---|---|
| B1 build break | Fixed the `MelderThread_PARALLELIZE` brace misuse. |
| B2 stale glue | Regenerated `src/RcppExports.cpp`; package loads. |
| B3 broken fusion | `calculate_cpps_ultra(fused=)` removed, with a note at the call site explaining why the two trend fits are not interchangeable. |
| B4 faithfulness | 4 broken routines repaired, 4 new ones added (harmonicity, spectrogram, jitter, MFCC). All 14 pass. |
| B5 test harness | `pladdrr:::` prefixes for unexported internals; S3 lookup via `asNamespace()`. 11 test cases recovered. |
| B6 source-tree writes | Reports go to `tempdir()` unless `PLADDRR_FAITHFULNESS_OUTDIR` is set. |
| 4 spectrogram | **Root cause found and fixed**: `get_power_at` did nearest-cell lookup; Praat does bilinear `Matrix_getValueAtXY`. Relative Δ 2.4e-01 → 1.4e-08. |
| 5 robust-slow | Warns once per session, documented in every `fit_method` param. |
| 6 bridge copies | Copies removed. vs base R: mean 0.87×→**4.1×**, sd 1.10×→**2.8×**, range 2.33×→**15.4×**, quantile 0.47×→**1.8×** (the last also needed `nth_element` instead of a full sort). |
| 7 thread formula | Platform divisors restored for Windows/Linux. |
| 10 CPPS defaults | Deviation from Praat documented with a side-by-side table; defaults left as-is (AVQI convention) since changing them would silently alter existing analyses. |
| 12 dead code | 6 files / 1,174 lines deleted. |
| 13 build system | `configure`'s dead xsimd detection and the `FLAC_SRC`/`MP3_SRC` variables removed; FLAC/MP3 docs corrected. |
| 15 typed errors | Validators raise `pladdrr_input_error`; `extract_part()` raises `pladdrr_data_loss`; reversed quefrency ranges error. |
| 18 AGENT_GUIDE | 9,240 → 4,233 lines (366 KB → 191 KB); archive moved verbatim to `HISTORY.md`. |
| 19 stale claims | Removed from reference docs; broken example fixtures repointed; CPPS examples made runnable. |
| 20 SIMD vignette | Rewritten around what stock builds actually reach (SSE2 / NEON), with the measured toggle table. |

### Measured and rejected

**Item 1 (Siegel repeated median) — no viable exact optimisation at this level.**
`std::nth_element` in place of Praat's `num::NUMquantile_e` is bit-exact
(9.9205293139915 unchanged) but **25% slower**: 200.8 ms vs 172.6 ms
multi-threaded, 1190 ms vs 957 ms single-threaded. Siegel slopes are heavily
clustered, which is where median-of-3 introselect degrades and Alexandrescu's
median-of-ninthers wins. Reverted; recorded in `PRAAT_MODIFICATIONS.md` so it is
not retried. The profile is unchanged — ~94% of CPPS is still that selection —
so the only remaining avenue is an O(n log n) repeated-median estimator
(Matoušek/Mount/Netanyahu 1998). That is a research-grade change, not a local edit.

### Still open

| Item | Why it was not done |
|---|---|
| 8 threading thresholds | Needs a per-routine tuning sweep plus a user-facing thread-policy API; larger design change than the rest of this pass. |
| 9 collapse CPPS tiers | Deprecating two public entry points is an API break. The docs now state plainly that the tiers are equivalent, which removes the harm without breaking callers. |
| 11 multithreaded gap vs Praat | Still 0.57–0.93× on 6 of 7 routines. Diagnosis needs thread-QoS experiments on Apple Silicon; unbounded investigation. |
| 14 CRAN warnings | `-ffp-contract=off` is a deliberate fidelity choice needing a CRAN conversation, not a code change; the `stderr`/`exit` symbols are in vendored Praat objects and need the same patch-and-document treatment as v4.9.6's `rand()`/`sprintf()` cleanup. |
| 16 `inst/signalfiles/` (3.2 MB) | Seven test files and many doc examples resolve paths through it. Moving it risks breaking the suite for an install-size win; the broken *references* were fixed instead. |
| 17 runnable examples | Only the CPPS helpers converted. 370 Rd files is a mechanical but large pass. |
| `sound_pool.cpp` | Kept: unlike the deleted SIMD kernels it exports four public functions, so removing it is an API break. |

### Remaining test failures (5 cases, 7 assertions)

| Test | Assessment |
|---|---|
| `test-batch-vectorized-ops.R` — batch vs individual window ops | Real: ~5e-6 relative disagreement between the batch and per-window paths. Larger than FP noise; worth a dedicated look. |
| `test-formant-r6.R` — `as.data.frame` column set | Test expects 4 columns, implementation returns 11. Decide which is intended, then fix one side. |
| `test-formant-r6.R` — method vs data-frame value | Follows from the above. |
| `test-simd-autocorrelation.R` — "performance scales reasonably" | Wall-clock assertion; inherently flaky. Should be a skip-on-CI benchmark, not a test. |

### Files changed

pladdrr-owned sources only — the vendored `praat.github.io/` tree is untouched.
