# pladdrr performance spec — CPPS trend-fit CPU inflation (+ point-process floor)

**Author:** plabench maintainer (Fredrik Nylén, via Claude Code)
**Date:** 2026-07-30
**pladdrr version measured:** 4.9.14 (`.so` mtime 2026-07-30 16:29:45)
**Correctness status:** unaffected — all 15 plabench 3-way validations pass; R CPPS matches
Praat to **0.00 dB**. This is a **pure speed** request. Any change here MUST keep the
bit-exact-vs-Praat guarantee (see Constraints).

---

## TL;DR

1. **PRIMARY — `calculate_cpps_ultra()` is ~13× slower than the identical parselmouth
   operation** (R 2.15 s vs Python 0.166 s per call on the same 2.9 s file). The
   cepstrogram *build* is cheap (~0.12 s). The cost is the two per-frame **robust
   trend-fit** passes inside `PowerCepstrogram_getCPPS_fast`. **It is already
   multi-threaded ~8×** (user 31.7 s / elapsed 4.07 s over 3 calls) — so this is **not** a
   missing-threads problem, it is **~9.9 s of CPU work per call** that Praat/parselmouth do
   in a fraction of that. Closing this is the single highest-value change and lands entirely
   in pladdrr code you own.

2. **SECONDARY — a cluster of tiny point-process tools runs ~5× Python** (VUV, DSI,
   Pharyngeal, Voice Report), but all are **70–130 ms absolute**. Fully attributed to
   per-primitive DSP cost (no glue waste), dominated by `to_point_process_periodic_cc`
   (~42 ms/call, only ~2.3× threaded) plus the `-O2 -ffp-contract=off` CRAN/fidelity floor.
   Low upside; documented for completeness, not urgent.

Everywhere else pladdrr already **wins or ties**: R beats Python on Pitch, Formant,
Intensity, Spectral Moments, Tremor, and ties on AVQI/VQ/PraatSauce. pladdrr's C++ is not
broadly slow — the loss is concentrated in the CPPS per-frame fit.

---

## 1. Measurements (reproducible)

Input: `signalfiles/DSI/input/ppq1.wav` (2.918 s, 16 kHz) — same file the plabench CPP and
Pitch benchmarks use. Machine: 10-core Apple Silicon. All numbers **warm** (one untimed
call first).

### 1.1 End-to-end benchmark (plabench `results/benchmarks_260730.txt`, 10 iters, warm)

| Tool | R | Python | R/Py | comment |
|---|---|---|---|---|
| **CPP** | **2.151 s** | **0.166 s** | **12.9×** | the target |
| VUV | 0.117 s | 0.017 s | 7.0× | 100 ms absolute |
| Pharyngeal | 0.125 s | 0.022 s | 5.6× | 103 ms absolute |
| DSI | 0.272 s | 0.049 s | 5.5× | 223 ms absolute |
| Voice Report | 0.092 s | 0.017 s | 5.4× | 75 ms absolute |
| Pitch | 0.074 s | 0.123 s | 0.60× | R wins |
| Formant | 0.106 s | 0.367 s | 0.29× | R wins |
| Intensity | 0.014 s | 0.021 s | 0.67× | R wins |
| Spectral Moments | 0.043 s | 0.278 s | 0.15× | R wins |
| Tremor | 0.087 s | 0.104 s | 0.84× | R wins |

### 1.2 CPP decomposition (warm, `system.time`, this file)

```
calculate_cpps_ultra ts=.002  ×3 :  user 31.69 s   elapsed 4.07 s   → 7.8× threaded
   ⇒ per call: elapsed 1.36 s ,  CPU ≈ 10.6 s
to_powercepstrogram (build)   ×5 :  user  3.47 s   elapsed 0.58 s   → 6.0× threaded
   ⇒ per call: elapsed 0.115 s,  CPU ≈ 0.69 s
```

**Attribution:** getCPPS-only (subtractTrend + smooth + to_Matrix_CPP) ≈ **1.24 s elapsed /
~9.9 s CPU** per call. The build is 8 % of wall time. Cost scales **linearly** with frame
count (`time_step=0.01` → 0.31 s, 5× fewer frames → ~5× cheaper).

Params are **identical** to the parselmouth path (`time_step=0.002`, `pitch_floor=60`,
`pitch_ceiling=333`, `fit_method="Robust"` = enum `ROBUST_FAST`). Verified there is **no
fit-method mapping bug** (both sides use `kCepstrum_trendFit` value 1, `Cepstrum_enums.h:31`).

### 1.3 Point-process primitives (warm, `system.time`)

```
to_point_process_periodic_cc  ×20 : user 1.93 s  elapsed 0.84 s → 2.3× threaded (~42 ms/call)
to_pitch_cc_direct (va=TRUE)  ×20 : user 6.62 s  elapsed 0.90 s → 7.3× threaded (~45 ms/call)
```

### 1.4 Repro harness

```r
suppressPackageStartupMessages(library(pladdrr))
s <- Sound("signalfiles/DSI/input/ppq1.wav")
invisible(calculate_cpps_ultra(s, 60, 333, time_step=0.002))          # warm
print(system.time(for (i in 1:3) calculate_cpps_ultra(s, 60, 333, time_step=0.002)))
print(system.time(for (i in 1:5) s$to_powercepstrogram(60, 0.002, 5000, 50)))
```
Parselmouth reference (`0.166 s` wall) — same op:
```python
import parselmouth; from parselmouth.praat import call
s = parselmouth.Sound("signalfiles/DSI/input/ppq1.wav")
part = call(s,"Extract part",0,0,"Hanning",1,False)
pc = call(part,"To PowerCepstrogram",60,0.002,5000,50)
call(pc,"Get CPPS", True,0.02,0.0005,60,333,0.05,"Parabolic",0.001,0.05,"Exponential decay","Robust")
```

---

## 2. PRIMARY: reduce CPU work in the CPPS per-frame trend fit

### 2.1 Code path (all in this repo)

```
.calculate_cpps_ultra_cpp                       src/batch_queries.cpp:1382
 └─ Sound_to_PowerCepstrogram (build, ~0.12s)   src/praat.github.io/LPC/Sound_to_PowerCepstrogram.cpp
 └─ PowerCepstrogram_getCPPS_fast               src/batch_queries.cpp:1326
     ├─ PowerCepstrogram_subtractTrend          src/praat.github.io/LPC/PowerCepstrogram.cpp:221
     │    └─ SampledIntoSampled_mt(…, 40)        src/praat.github.io/dwtools/SampledIntoSampled.cpp:24
     │         └─ PowerCepstrogramFrameIntoMatrixFrame  (per-frame robust fit)
     ├─ PowerCepstrogram_smooth_fast            src/batch_queries.cpp (already threaded, OK)
     └─ PowerCepstrogram_to_Matrix_CPP          src/batch_queries.cpp:50
          └─ PowerCepstrogram_into_Matrix_CPP   src/praat.github.io/LPC/PowerCepstrogram.cpp:263
               └─ SampledIntoSampled_mt(…, 40)  (per-frame robust fit + peak, 2nd pass)
```

The two `SampledIntoSampled_mt` passes (subtract-trend and to-Matrix-CPP) are where the
~9.9 s CPU lives. They already thread via `MelderThread_PARALLELIZE`
(`SampledIntoSampled.cpp:41`); threading is confirmed engaged (§1.2). So the fix is to cut
**total work**, not to add threads.

### 2.2 Requested investigations, in priority order

Each is a hypothesis + how to test + expected payoff. You own this code and can profile with
Instruments/`perf`; I could only measure from R.

**(A) Quantify the `-O2 -ffp-contract=off` contribution with a throwaway build.**
Build a *non-shipped* experimental `.so` with `PKG_CXXFLAGS = -O3` and, separately,
`-O2 -ffp-contract=fast`, re-run §1.4, and check both (i) the speed delta and (ii) whether
CPPS still matches Praat to 0.00 dB (`tests/` fidelity). This cleanly separates "flags" from
"algorithm." Expectation: flags explain ~2–3× (pladdrr is 2.15 s vs a Praat.app CPP script's
~0.93 s, consistent with a ~2.3× flag penalty). If `-ffp-contract=fast` breaks bit-exactness
(likely — that is exactly why it is off), it is **not** a shippable fix, but the number tells
you how much of the 13× is unavoidable flag floor vs. addressable algorithm. **Do not ship
`-O3`/`-ffp-contract=fast`** (CRAN + fidelity); this build is diagnostic only.

**(B) Profile per-frame allocation inside the `_mt` frame loop.** `SampledIntoSampled_mt`
does `Thing_newFromClass` + `copyBasic` + `initHeap` per thread (fine), but confirm
`getInputFrame` / `inputFrameIntoOutputFrame` (the robust fit) do **no per-frame heap
allocation**. 1460 frames × 2 passes × any malloc in the IRLS inner loop is a prime suspect
for the ~4–6× that flags do not explain. Payoff: potentially large; hoist buffers to the
per-thread workspace (`initHeap`) if found.

**(C) Check per-frame `Melder_progress` overhead in the headless embedding.**
`SampledIntoSampled_mt` (`SampledIntoSampled.cpp:31-40`) calls `Melder_progress(…)` with
string construction on the master thread **every frame**. In the GUI app this throttles; in
the pladdrr R embedding, confirm it is a cheap no-op and is not serializing the master
chunk or building strings 1460×. If non-trivial, gate it behind a "quiet" flag for the
fused Tier-4 calls. Payoff: small–medium; cheap to check.

**(D) Confirm the robust solver is not superlinear per frame.** The IRLS trend fit runs over
the quefrency fit window (`[0.001, 0.05]` s here ≈ few-hundred points) per frame. Verify it
is O(points·iterations), not O(points²) (e.g. a linear scan or re-sort inside the reweight
loop). The linear-in-frames scaling (§1.2) rules out an O(frames²) outer bug, but says
nothing about the per-frame inner cost. Payoff: potentially large if a hidden O(n²) exists.

**(E) Is `subtractTrend` redundant with `to_Matrix_CPP`'s own trend handling?**
`getCPPS_fast` runs a full `subtractTrend` pass **and** `to_Matrix_CPP` with
`trendSubtracted=true`. Both instantiate `PowerCepstrogramFrameIntoMatrixFrame` and fit a
trend per frame. Confirm the second pass genuinely needs the first (i.e. the fit is not being
computed twice). If the trend from pass 1 can be reused by pass 2, you eliminate one of the
two per-frame fits outright. Payoff: **up to ~2×** if they can be fused — verify against
Praat semantics first (must stay bit-exact).

### 2.3 Acceptance criteria (PRIMARY)

- CPPS on `ppq1.wav` (and `cpp.R`'s own reference file) still matches Praat to **< 0.01 dB**;
  all 15 `tests/test_3way_validation.py` stay green.
- `calculate_cpps_ultra(s, 60, 333, time_step=0.002)` warm elapsed drops from **1.36 s**
  toward the flag floor. Target: **≤ 0.5 s** (≈ 2.7× the parselmouth 0.166 s) — i.e. recover
  the addressable ~4–6× beyond flags. Stretch: ≤ 0.35 s.
- No new CRAN-forbidden flags; `-ffp-contract=off` retained.

---

## 3. SECONDARY: the point-process floor (low priority)

The 5× cluster (VUV/DSI/Pharyngeal/Voice Report) is 70–130 ms absolute and fully attributed
to primitive DSP cost — **no plabench glue waste** (DSI's three ultra calls sum to its
total; Voice Report is pitch 0.041 s + `to_point_process_periodic_cc` 0.043 s + the native
voice-report call 0.001 s). The recurring primitive is `to_point_process_periodic_cc`
(§1.3), only ~2.3× threaded.

Optional asks (only if cheap):
- Raise `to_point_process_periodic_cc` threading beyond 2.3×, or reduce its constant.
- Otherwise this cluster is the accepted `-O2 -ffp-contract=off` fidelity floor on tiny
  absolute times. Recommend documenting it as expected in `inst/agents/AGENT_GUIDE.md`
  rather than chasing it. **No action expected unless (A) above yields a broadly shippable
  win.**

---

## 4. Constraints (do not break)

- **Bit-exact vs Praat is the package's primary guarantee.** `-ffp-contract=off` stays.
  Every speed change must be validated to keep CPPS within < 0.01 dB of Praat (plabench
  `tests/` are the oracle; happy to re-run against any branch build).
- **CRAN:** no `-O3`, `-flto`, `-march=native`, no re-added `-Wno-*`. Threading via the
  existing `MelderThread`/`parallel_for_range` infra only.
- **API stability:** `calculate_cpps_ultra()` / `.calculate_cpps_ultra_cpp` signature and
  defaults must not change (plabench `avqi.R` and `cpp.R` depend on them, and the AVQI CPPS
  accuracy fix relies on the v4.9.10 param threading).

## 5. Verification I can run for you

Point me at a branch build and I will run, on the real reference signals:
- `python -m pytest tests/test_3way_validation.py -v` (15/15 must stay green; CPPS 0.00 dB),
- `python tests/test_performance_benchmark.py` (or `./run_benchmarks.sh cpp`) for the
  before/after ratio,
- the §1.4 `system.time` decomposition to confirm the CPU-work reduction and that threading
  is still engaged.
