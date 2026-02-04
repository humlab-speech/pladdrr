# pladdrr Performance Improvement Requests

Upstream issues identified via plabench benchmarking (warm session, pladdrr v4.8.8).

## Context

plabench reimplements 7 Praat-based voice analysis tools in both Python/Parselmouth and R/pladdrr. R/pladdrr is **faster than Python for VQ** (0.73x) thanks to batch APIs, but **5.9x slower for DSI** due to slower core pitch extraction.

---

## Issue 1: Core pitch extraction speed (~5x slower than Parselmouth)

**Severity:** High — root cause of DSI's 5.9x slowdown

**Evidence from per-operation profiling (DSI):**

DSI calls pitch extraction 3 times on different sounds. Profiling each Ultra API call individually shows the time is spent in real computation (pitch extraction), not in API overhead:

```
calculate_f0_stats_ultra():     110ms   ← pitch extraction internally
calculate_minimum_intensity():   79ms   ← pitch + VUV + intensity
get_voice_quality_ultra():       51ms   ← pitch + jitter

Direct API alternative:
to_pitch_cc_direct()+get_max():  95ms   ← only 15ms faster (no overhead savings)
```

The Python equivalent (Parselmouth `sound.to_pitch_cc()`) completes each pitch extraction in ~10-20ms. The ~5x difference appears to be in pladdrr's C++ pitch implementation.

**Impact:** All tools that rely on pitch extraction are affected:
- DSI: 5.9x slower (3 pitch extractions on small files)
- VUV: 3.5x slower (2-pass pitch)
- Pharyngeal: 2.3x slower (2-pass pitch)
- Tremor: 1.7x slower (mitigated by vectorized contour extraction)
- VQ: R wins despite pitch overhead (batch APIs compensate)

**Requested investigation:** Profile `to_pitch_cc_direct()` at the C++ level to identify why it's slower than Praat's internal pitch computation (which Parselmouth wraps directly).

---

## Issue 2: Formant extraction bug (polynomial root finding)

**Severity:** High — correctness issue

**Location:** `pladdrr/src/formant_lpc_simd.cpp:272-285`

**Symptoms:** F1/F2/F3 values 35-55% too low:
- F1: 570 Hz (should be 874 Hz)
- F2: 1144 Hz (should be 2533 Hz)

**Root cause:** Incomplete LPC polynomial root finding in the C++ SIMD formant code.

**Impact:** Pharyngeal R implementation cannot produce correct formant-dependent measures. Primary outputs H1-H2 and H1-A1 are unaffected.

**Full report:** See `PLADDRR_FORMANT_BUG_REPORT.md`.

---

## Issue 3: AVQI voiced extraction Ultra API accuracy bug

**Severity:** Medium — forced revert to manual implementation

**Function:** `extract_windows_filtered()` (or equivalent Ultra API for windowed power + ZCR filtering)

**Symptoms:** Voiced segment extraction produced different results than Praat's algorithm when using the Ultra API. Reverted to manual vectorized R implementation (see `R_implementations/avqi.R` line 160).

**Impact:** AVQI R implementation is ~1.2s slower than it could be.

**Requested fix:** Fix accuracy of windowed extraction to match Praat's 30ms sliding window with dual filtering (power threshold + ZCR < 3000 Hz).

---

## Issue 4: CPPS computation speed

**Severity:** Low — algorithm-bound, not a bug

**Context:** CPPS takes 93% of AVQI runtime (~11.8s/12.7s). R/Python ratio is only 1.57x, so pladdrr's implementation is reasonable.

**Possible optimization:** Threading or SIMD in PowerCepstrogram computation.

---

## What's Working Well

These batch APIs are excellent — they make VQ **faster in R than Python**:

| API | Speedup vs Individual | Used In |
|-----|----------------------|---------|
| `get_jitter_shimmer_batch()` | 5-10x | VQ, DSI |
| `calculate_multiband_hnr_ultra()` | 2-2.5x | VQ |
| `get_peaks_batch()` | 18x | Pharyngeal |
| `sound_concatenate_all()` | 19x | DSI, AVQI |
| `get_values_vector()` / `get_voiced_mask()` / `get_values_detrended()` | 5-10x | Tremor |
| `two_pass_adaptive_pitch()` | 2x (code reduction) | VUV, VQ, Pharyngeal |

**Design pattern:** APIs that batch many operations into one C++ call dominate. This pattern should be applied to more operations (e.g., batch pitch extraction across multiple sounds for DSI).

---

## Benchmark Data

**From bench.log** (run_benchmarks.sh, 10 iterations per tool):

| Tool | Python (s) | R (s) | Ratio | Bottleneck |
|------|-----------|-------|-------|------------|
| VQ | 1.837 | 1.337 | 0.73x | batch jitter/shimmer + HNR ultra |
| Tremor | 0.061 | 0.094 | 1.54x | pitch direct + vectorized contours |
| AVQI v2.03 | 2.102 | 3.316 | 1.58x | CPPS (93% of time) |
| AVQI v3.01 | 2.108 | 3.307 | 1.57x | CPPS (93% of time) |
| Pharyngeal | 0.019 | 0.044 | 2.31x | pitch extraction speed |
| VUV | 0.018 | 0.055 | 2.97x | pitch extraction speed |
| DSI | 0.116 | 0.629 | 5.43x | 3 pitch extractions on small files |

**Fresh in-session benchmark** (single R process, warm):

| Tool | Python (ms) | R (ms) | Ratio |
|------|------------|--------|-------|
| DSI | 42 | 246 | 5.9x |
| Tremor | 57 | 95 | 1.7x |
| VUV | 16 | 56 | 3.5x |
| Pharyngeal | 19 | 44 | 2.3x |

**Methodology:** Warm session (libraries pre-loaded, warm-up run). Python `time.perf_counter()`, R `proc.time()`. File I/O included, interpreter startup excluded.
