# pladdrr Enhancement Wishlist

**Document Version:** 1.0.0  
**Date:** 2026-02-05  
**Project:** plabench (Multi-platform voice quality analysis toolkit)  
**Contact:** plabench maintainers  
**pladdrr Version Tested:** v4.8.12

---

## Purpose

This document provides a comprehensive list of enhancement requests and bug reports for the pladdrr R package, based on extensive performance profiling and cross-platform validation against Praat and Parselmouth (Python) implementations.

**Context:** plabench implements 7 voice analysis tools (AVQI, DSI, Tremor, VUV, VQ, Pharyngeal, Dysprosody) in three platforms: Praat scripts, Python (Parselmouth), and R (pladdrr). Performance profiling has identified specific areas where pladdrr could be improved.

---

## 🔴 **P0: CRITICAL** - CPPS Performance Regression

### Issue: `calculate_cpps_ultra()` is 37x slower than Parselmouth

**Priority:** **URGENT - BLOCKING**  
**Impact:** **CRITICAL** - Makes AVQI unusable for batch processing (9.5s vs Python's 1.8s)  
**Affected Function:** `calculate_cpps_ultra()`  
**pladdrr Version:** v4.8.12  

### Description

The "Ultra API" for CPPS (Smoothed Cepstral Peak Prominence) calculation is **catastrophically slow** compared to Parselmouth's implementation, despite being advertised as optimized.

**Benchmark Results:**
- **R (pladdrr v4.8.12):** 9.084s ± 0.061s
- **Python (Parselmouth):** 0.243s ± 0.003s  
- **Performance Gap:** **37.4x slower**
- **CPPS accounts for 95.6% of total R AVQI runtime** (9.084s out of 9.5s)

**Test Configuration:**
- Input: 5.89s audio (voiced speech + sustained vowel)
- Hardware: M1/M2 Mac
- Measurement: 10 iterations, warm session (libraries pre-loaded)

### Evidence

```r
# R implementation
library(pladdrr)
source("R_implementations/avqi.R")

avqi_sound <- Sound("test.wav")  # 5.89s duration

# Using calculate_cpps_ultra() - supposed to be optimized
system.time(cpps <- calculate_cpps(avqi_sound))
#   user  system elapsed 
#  9.084   0.020   9.104  

# Result: CPPS = 14.63
```

```python
# Python implementation
import parselmouth
from plabench.avqi import _calculate_cpps

avqi_sound = parselmouth.Sound("test.wav")  # Same 5.89s audio

# Using standard Parselmouth calls
import time
start = time.time()
cpps = _calculate_cpps(avqi_sound)
elapsed = time.time() - start
# elapsed = 0.243s

# Result: CPPS = 14.55 (matches R within tolerance)
```

**Breakdown:**
- Python: Cepstrogram creation = 0.054s, Get CPPS = 0.185s
- R: Single-call API (no breakdown possible)

### Current Implementation (plabench/R_implementations/avqi.R)

```r
calculate_cpps <- function(sound) {
  # OPTIMIZATION v4.6.4: Use Tier 4 Ultra API (pre-emphasis bug fixed)
  # Parameters match Python _calculate_cpps() in plabench/avqi.py:
  # call(cepstrogram, "Get CPPS", "no", 0.01, 0.001, 60, 330, 0.05, "Parabolic", 0.001, 0, "Straight", "Robust")
  calculate_cpps_ultra(
    sound,
    time_averaging_window = 0.01,
    quefrency_averaging_window = 0.001,
    pitch_floor = 60,
    pitch_ceiling = 330,
    subtract_trend = FALSE,  # "no" in Python
    time_step = 0.002,
    max_frequency = 5000,
    pre_emphasis_from = 50
  )
}
```

### Comparison with Parselmouth (plabench/plabench/avqi.py)

```python
def _calculate_cpps(sound: parselmouth.Sound) -> float:
    """Calculate Smoothed Cepstral Peak Prominence (CPPS)."""
    
    # Create power cepstrogram
    cepstrogram = call(sound, "To PowerCepstrogram", 60, 0.002, 5000, 50)
    
    # Calculate CPPS
    cpps = call(
        cepstrogram,
        "Get CPPS",
        "no",  # subtract_trend_before_smoothing
        0.01,  # time_averaging_window
        0.001,  # quefrency_averaging_window
        60,  # pitch_floor
        330,  # pitch_ceiling
        0.05,  # tolerance
        "Parabolic",  # interpolation
        0.001,  # qstep
        0,  # tilt_line_quefrency
        "Straight",  # line_type
        "Robust",  # fit_method
    )
    
    return cpps
```

**Both implementations call identical Praat functions with identical parameters, yet R is 37x slower!**

### Hypothesis

Possible causes:
1. **Data Marshalling Overhead:** Excessive R↔C++ conversions
2. **Missing Optimizations:** Parselmouth may use threading/SIMD that pladdrr lacks
3. **Algorithmic Bug:** pladdrr may implement CPPS differently than Praat
4. **Memory Allocation:** Inefficient memory handling in C++ layer
5. **Debug Code Left In:** Ultra API may have verbose logging/checks enabled

### Requested Actions

1. **Profile `calculate_cpps_ultra()` with Valgrind/perf** to identify bottleneck
2. **Compare C++ implementation** with Parselmouth's Praat bindings
3. **Verify threading:** Does Parselmouth use OpenMP/threading for CPPS?
4. **Check data marshalling:** How many R↔C++ conversions happen?
5. **Test alternative:** Is `calculate_cpps_fast()` actually faster than `calculate_cpps_ultra()`?

### Success Criteria

- **Minimum:** 4x speedup → CPPS < 2.5s (would make R AVQI acceptable at 3.5s total)
- **Target:** 10x speedup → CPPS < 1.0s (would make R AVQI competitive at 2.0s total)
- **Ideal:** 37x speedup → CPPS ≈ 0.25s (parity with Python)

### Related Evidence

**Proof that pladdrr CAN be fast:**
- `extract_voiced_segments_ultra()` is **126x FASTER** than Python (0.012s vs 1.514s)
- This proves pladdrr's Ultra APIs can achieve excellent performance when properly optimized
- The CPPS issue is an anomaly, not a fundamental limitation

---

## 🟡 **P1: HIGH** - Batch Shimmer API

### Issue: No batch API for shimmer calculations

**Priority:** HIGH  
**Impact:** MEDIUM - Multiple shimmer calls in VQ analysis are slow  
**Requested API:** `get_shimmer_batch()`  
**Similar to:** Existing `get_jitter_shimmer_batch()` in DSI

### Description

Current implementations require separate calls for each shimmer metric, resulting in repeated PointProcess creation overhead.

**Current Pattern (SLOW):**
```r
# Create PointProcess (expensive: 0.104s)
pp <- sound$to_point_process_periodic_cc(pitch_floor = 50, pitch_ceiling = 400)

# Access internal namespace for direct C++ calls
ns <- asNamespace("pladdrr")
pp_ptr <- get_ptr(pp)
sound_ptr <- get_ptr(sound)

# Calculate shimmer local (fast: 0.000s)
shimmer_local <- ns$.pointprocess_sound_get_shimmer_local(pp_ptr, sound_ptr, 0, 0, 0.0001, 0.02, 1.3, 1.6)

# Calculate shimmer dB (fast: 0.000s)
shimmer_db <- ns$.pointprocess_sound_get_shimmer_local_db(pp_ptr, sound_ptr, 0, 0, 0.0001, 0.02, 1.3, 1.6)
```

**Requested API (FAST):**
```r
# Create PointProcess once
pp <- sound$to_point_process_periodic_cc(pitch_floor = 50, pitch_ceiling = 400)

# Get all shimmer metrics in one call
shimmer_metrics <- get_shimmer_batch(
  pp, sound,
  tmin = 0, tmax = 0,
  shortest_period = 0.0001,
  longest_period = 0.02,
  max_period_factor = 1.3,
  max_amplitude_factor = 1.6
)

# Returns list with all shimmer variants:
# shimmer_metrics$local
# shimmer_metrics$local_db
# shimmer_metrics$apq3
# shimmer_metrics$apq5
# shimmer_metrics$apq11
# shimmer_metrics$dda
```

### Benefits

- **Reduces R6 method call overhead** (6 calls → 1 call)
- **Consistent with existing `get_jitter_shimmer_batch()` API** in DSI
- **Used in VQ analysis** which calculates multiple shimmer metrics per interval
- **Estimated speedup:** 2-3x for shimmer calculations

### Precedent

DSI already has batch jitter/shimmer API:
```r
# From DSI implementation (R_implementations/dsi.R:242)
jitter_shimmer <- get_jitter_shimmer_batch(
  pointprocess, sound,
  period_floor = 0.0001,
  period_ceiling = 0.02,
  maximum_period_factor = 1.3
)

jitter_ppq5 <- jitter_shimmer$jitter_ppq5
```

---

## 🟡 **P1: HIGH** - Direct API for PointProcess Creation

### Issue: PointProcess creation is slow (10x slower than Python)

**Priority:** HIGH  
**Impact:** MEDIUM - Affects shimmer (0.104s) and jitter calculations  
**Requested API:** `to_point_process_periodic_cc_direct()`  
**Similar to:** Existing `to_pitch_cc_direct()`, `to_harmonicity_direct()`

### Description

PointProcess creation via R6 method is significantly slower than Python:
- **R:** 0.104s ± 0.001s
- **Python:** 0.010s ± 0.000s
- **Gap:** 10.4x slower

**Current Implementation (SLOW):**
```r
# Uses R6 method dispatch (slow)
pp <- sound$to_point_process_periodic_cc(
  pitch_floor = 50,
  pitch_ceiling = 400
)
```

**Requested API (FAST):**
```r
# Uses Direct API (Tier 2) bypassing R6
pp_ptr <- to_point_process_periodic_cc_direct(
  sound,
  pitch_floor = 50,
  pitch_ceiling = 400
)

# Wrap in PointProcess object if needed
pp <- PointProcess(.xptr = pp_ptr)
```

### Precedent

pladdrr already has Direct APIs for:
- `to_pitch_cc_direct()` - 2-3x speedup for pitch
- `to_harmonicity_direct()` - 2-3x speedup for harmonicity
- `to_intensity_direct()` - 2-3x speedup for intensity

### Expected Impact

- **Shimmer:** 0.111s → 0.020s (5.5x faster)
- **Jitter:** Similar improvement in DSI
- **VQ analysis:** Significant speedup (creates PointProcess per interval)

---

## 🟢 **P2: MEDIUM** - CPPS API Flexibility

### Issue: `calculate_cpps_ultra()` is inflexible

**Priority:** MEDIUM  
**Impact:** LOW - Current API works, but limits experimentation  
**Requested:** Expose intermediate steps for custom CPPS workflows

### Description

Current `calculate_cpps_ultra()` is a black box - users cannot:
1. Reuse cepstrogram for multiple CPPS calculations
2. Experiment with different smoothing parameters
3. Debug CPPS calculation steps

**Requested API:**
```r
# Option 1: Expose cepstrogram creation
cepstro <- to_power_cepstrogram_direct(
  sound,
  pitch_floor = 60,
  time_step = 0.002,
  max_frequency = 5000,
  pre_emphasis_from = 50
)

# Option 2: Multiple CPPS calculations from same cepstrogram
cpps1 <- cepstro$get_cpps(time_averaging_window = 0.01, ...)
cpps2 <- cepstro$get_cpps(time_averaging_window = 0.02, ...)  # Different smoothing

# Option 3: Batch CPPS with multiple parameter sets
cpps_variants <- get_cpps_batch(cepstro, param_list)
```

### Use Cases

- **Research:** Experiment with CPPS parameters
- **Debugging:** Inspect cepstrogram before CPPS calculation
- **Optimization:** Reuse cepstrogram for multiple analyses
- **Custom metrics:** Derive new measures from cepstrogram

---

## 🟢 **P2: MEDIUM** - HNR Direct API Consistency

### Issue: HNR Direct API is 5.4x slower than Python

**Priority:** MEDIUM  
**Impact:** LOW - HNR is only 1.3% of runtime  
**Current API:** `to_harmonicity_direct()` (already using Direct API)

### Description

Despite using Direct API, R HNR is still significantly slower than Python:
- **R (Direct API):** 0.125s
- **Python:** 0.023s
- **Gap:** 5.4x slower

**Current Implementation:**
```r
calculate_hnr <- function(sound) {
  # v4.0.1: Direct API takes Sound object, returns XPtr
  harmonicity_ptr <- to_harmonicity_direct(
    sound,
    time_step = 0.01,
    minimum_pitch = 75,
    silence_threshold = 0.1,
    periods_per_window = 1.0
  )
  
  # Wrap in Harmonicity object using function factory
  harmonicity <- Harmonicity(.xptr = harmonicity_ptr)
  hnr <- harmonicity$get_mean(from_time = 0, to_time = 0)
  
  return(hnr)
}
```

### Hypothesis

The gap may be due to:
1. **R6 method overhead** in `harmonicity$get_mean()`
2. **Data marshalling** when converting harmonicity matrix to mean
3. **Missing SIMD optimizations** in C++ harmonicity calculation

### Requested Investigation

- Profile `to_harmonicity_direct()` and `Harmonicity$get_mean()`
- Compare with Parselmouth's implementation
- Consider batch HNR API if multiple calls are common

---

## 🟢 **P3: LOW** - API Documentation and Examples

### Issue: Limited documentation for Ultra/Direct APIs

**Priority:** LOW  
**Impact:** LOW - Usability improvement  

### Description

pladdrr's performance-critical APIs (Ultra, Direct) lack comprehensive documentation:
- When to use Ultra vs Direct vs Standard APIs?
- What are the performance characteristics?
- What are the limitations?
- How to profile R code to identify bottlenecks?

### Requested Documentation

1. **Performance Tier Guide:**
   ```
   Tier 1 (Standard): sound$to_pitch_cc()         - Baseline (1x)
   Tier 2 (Direct):   to_pitch_cc_direct()        - 2-3x faster
   Tier 3 (Pipeline): two_pass_adaptive_pitch()   - 2x faster
   Tier 4 (Ultra):    calculate_cpps_ultra()      - Task-specific
   ```

2. **API Comparison Table:** Which functions have Direct/Ultra variants?

3. **Profiling Guide:** How to identify bottlenecks in pladdrr code

4. **Migration Guide:** Converting Standard → Direct → Ultra APIs

5. **Performance Benchmarks:** Expected speedups for each API tier

---

## 🔵 **P3: LOW** - LTAS Performance

### Issue: LTAS creation is 7.5x slower than Python

**Priority:** LOW  
**Impact:** NEGLIGIBLE - LTAS is only 0.2% of runtime (0.015s)  
**Not blocking** but worth investigating

### Description

- **R:** 0.015s (LTAS creation: 0.008s, slope/tilt calc: 0.000s)
- **Python:** 0.002s (LTAS creation: 0.001s, slope/tilt calc: 0.001s)
- **Gap:** 7.5x slower

**Current Implementation:**
```r
ltas <- sound$to_ltas(bandwidth = 1)  # 0.008s
```

Given the small absolute time (15ms), this is not a priority. Only investigate if:
1. LTAS becomes a bottleneck in other analyses
2. Users report slow LTAS calculations
3. Easy optimization opportunity identified

---

## Summary of Priorities

| Priority | Issue | Impact | Speedup Potential | Effort |
|----------|-------|--------|-------------------|--------|
| **🔴 P0** | **CPPS Ultra API** | **CRITICAL** | **4-37x** | **HIGH** |
| 🟡 P1 | Batch Shimmer API | MEDIUM | 2-3x | LOW |
| 🟡 P1 | PointProcess Direct API | MEDIUM | 5-10x | MEDIUM |
| 🟢 P2 | CPPS API Flexibility | LOW | N/A | MEDIUM |
| 🟢 P2 | HNR Performance | LOW | 2-5x | MEDIUM |
| 🟢 P3 | API Documentation | LOW | N/A | LOW |
| 🔵 P3 | LTAS Performance | NEGLIGIBLE | 7x | LOW |

---

## Expected Outcomes

### If P0 (CPPS) is Fixed

**Current AVQI Performance:**
- R: 9.532s (CPPS: 9.084s + Other: 0.263s)
- Python: 1.772s

**After CPPS 4x Speedup (Conservative):**
- R: 2.534s (CPPS: 2.271s + Other: 0.263s)
- **Gap:** 1.4x slower than Python ✅ ACCEPTABLE

**After CPPS 10x Speedup (Optimistic):**
- R: 1.171s (CPPS: 0.908s + Other: 0.263s)
- **Gap:** 0.66x (FASTER than Python!) 🏆 EXCELLENT

### If P0 + P1 (CPPS + Secondary) are Fixed

**After CPPS 4x + Shimmer 2x + HNR 2x:**
- R: 2.379s
- **Gap:** 1.34x slower than Python ✅ GREAT

**After CPPS 10x + Shimmer 5x + HNR 5x:**
- R: 1.000s
- **Gap:** 0.56x (43% FASTER than Python!) 🚀 OUTSTANDING

---

## Contact and Collaboration

We are happy to:
- Provide additional profiling data
- Test patches and beta versions
- Contribute code if pladdrr is open to PRs
- Share benchmark harness for validation

**plabench Project:**
- GitHub: [Link to plabench repository]
- Documentation: See `CLAUDE.md`, `PLADDRR_PERFORMANCE_ASSESSMENT.md`
- Benchmark suite: `tests/test_performance_benchmark.py`, `benchmark_warm_r.R`

**Test Data:**
- Available in plabench repository: `signalfiles/AVQI/input/`
- Standardized benchmark config: `benchmark_config.json`
- Profiling scripts: `scripts/profile_avqi_components.{R,py}`

---

## Appendix: Profiling Methodology

### Hardware
- Apple M1/M2 Mac
- 16GB RAM
- macOS Sonoma

### Software Versions
- R: 4.3.0+
- pladdrr: v4.8.12
- Python: 3.12.9
- Parselmouth: 0.4.3

### Benchmark Methodology
- **Warm benchmarks:** Libraries pre-loaded, 10 iterations, mean ± SD reported
- **Standardized data:** `benchmark_config.json` v1.0.0 ensures identical test files
- **Cross-validation:** Results validated against Praat scripts (ground truth)
- **Profiling tools:** R `profvis`, Python `time`, system `time` command

### Reproducibility
All benchmarks are reproducible:
```bash
# Clone plabench
git clone [plabench-repo]
cd plabench

# Run Python component profiling
python3 scripts/profile_avqi_components.py

# Run R component profiling
Rscript scripts/profile_avqi_components.R

# Run full benchmark suite
./run_benchmarks.sh
pytest tests/test_performance_benchmark.py -v
```

---

**Thank you for maintaining pladdrr! This wishlist is provided in the spirit of collaboration to make pladdrr the best Praat interface for R.**
