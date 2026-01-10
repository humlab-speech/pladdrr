# SIMD Voice Quality Removal - Rationale

## Decision: Remove SIMD Jitter/Shimmer Implementation

**Date**: 2026-01-03  
**Status**: Completed  
**Impact**: No user-facing changes (functions were never used)

---

## Background

During Phase 5 development, SIMD-optimized jitter and shimmer calculations were implemented in `src/voice_quality_simd.cpp`:

- `.jitter_from_periods_simd()`
- `.shimmer_from_amplitudes_simd()`
- `.voice_quality_metrics_simd()`

These functions were **exported** but **never used** in the package. The actual package always used Praat's native implementations via `src/pointprocess_wrappers.cpp`.

---

## Critical Issues Identified

### 1. **Algorithmic Differences (CRITICAL)**

The SIMD implementation **fundamentally differs** from Praat:

| Aspect | Praat Implementation | SIMD Implementation |
|--------|---------------------|-------------------|
| **Period Filtering** | YES - filters by `pmin`, `pmax`, `maximumPeriodFactor` | NO - processes all periods |
| **Outlier Handling** | Excludes invalid periods | Includes all periods |
| **Accuracy for Clean Voice** | Reference | 0.1-5% difference |
| **Accuracy for Creaky Voice** | Reference | 10-100%+ difference |

**Root Cause**: Missing lines 15-25 from `VoiceAnalysis.cpp`:
```cpp
// Praat filters each period
if (pmin == pmax || (p1 >= pmin && p1 <= pmax && 
                     p2 >= pmin && p2 <= pmax && 
                     intervalFactor <= maximumPeriodFactor)) {
    sum += fabs(p1 - p2);
} else {
    numberOfPeriods--;  // Exclude outlier
}
```

**SIMD Version** (no filtering):
```cpp
// Unconditionally includes ALL periods
for (int i = 0; i < n - 1; ++i) {
    sum_diffs += diffs[i];
}
```

### 2. **User Expectation**

Users expect pladdrr to **faithfully reproduce Praat output**. The SIMD version violates this core requirement.

### 3. **Maintenance Burden**

Maintaining two algorithms with different outputs:
- Confuses users
- Requires extensive documentation
- Creates support burden explaining discrepancies

---

## Files Removed

```bash
src/voice_quality_simd.cpp              # SIMD implementation (297 lines)
man/dot-jitter_from_periods_simd.Rd     # Documentation
man/dot-shimmer_from_amplitudes_simd.Rd # Documentation
man/dot-voice_quality_metrics_simd.Rd   # Documentation
R/RcppExports.R                         # Auto-updated by Rcpp
src/RcppExports.cpp                     # Auto-updated by Rcpp
```

---

## What Remains (Correct Implementations)

All Praat-faithful implementations in `src/pointprocess_wrappers.cpp`:

### Jitter Functions
- `PointProcess_getJitter_local()` - Local jitter (relative)
- `PointProcess_getJitter_local_absolute()` - Local jitter (absolute)
- `PointProcess_getJitter_rap()` - 3-point RAP
- `PointProcess_getJitter_ppq5()` - 5-point PPQ5
- `PointProcess_getJitter_ddp()` - DDP (3 × RAP)

### Shimmer Functions
- `PointProcess_Sound_getShimmer_local()` - Local shimmer
- `PointProcess_Sound_getShimmer_local_dB()` - Local shimmer (dB)
- `PointProcess_Sound_getShimmer_apq3()` - 3-point APQ
- `PointProcess_Sound_getShimmer_apq5()` - 5-point APQ
- `PointProcess_Sound_getShimmer_apq11()` - 11-point APQ
- `PointProcess_Sound_getShimmer_dda()` - DDA (3 × APQ3)

All exposed via R6 methods in `R/pointprocess-r6.R`:
```r
pp$get_jitter_local(from_time, to_time, period_floor, period_ceiling, max_period_factor)
pp$get_shimmer_local(sound, from_time, to_time, ...)
```

---

## Performance Considerations

**Q**: Don't we lose SIMD speedup?  
**A**: No. Praat's jitter/shimmer are **already fast** (<1ms per analysis):

```r
# Typical jitter calculation time
system.time({
  pp <- sound$to_point_process_periodic(75, 600)
  jitter <- pp$get_jitter_local(0, 0, 0.0001, 0.02, 1.3)
})
#   user  system elapsed 
#  0.001   0.000   0.001   # <1ms
```

Bottleneck is **pitch/period detection** (50-200ms), not jitter calculation.

---

## Alternative Considered: Fix SIMD Implementation

### Option: Add Period Filtering to SIMD

**Pros**:
- Could match Praat output
- Retain SIMD benefit for difference computation

**Cons**:
- Complex branching reduces SIMD benefit
- Still have precision differences (longdouble vs double)
- Maintenance burden for minimal gain (~0.5ms speedup)
- Risk of subtle bugs in filtering logic

**Verdict**: Not worth complexity for sub-millisecond speedup

---

## Verification

After removal:

1. ✅ Package still compiles
2. ✅ All Praat jitter/shimmer functions available
3. ✅ No references to SIMD functions in codebase
4. ✅ RcppExports regenerated successfully
5. ✅ No user-facing API changes (functions were never documented publicly)

---

## Lessons Learned

1. **Praat fidelity is non-negotiable** for voice analysis functions
2. **Profile before optimizing** - jitter isn't the bottleneck
3. **Document API contracts clearly** - users expect exact Praat reproduction
4. **Remove unused code promptly** - exported but unused functions create confusion

---

## Related Documentation

- Technical assessment: `.planning/SIMD_JITTER_ACCURACY_ASSESSMENT.md`
- Praat reference: `src/praat/fon/VoiceAnalysis.cpp`
- Current wrappers: `src/pointprocess_wrappers.cpp`
- R6 interface: `R/pointprocess-r6.R`

---

## Commit Message

```
refactor: Remove SIMD jitter/shimmer (Praat fidelity required)

SIMD voice quality implementation had fundamental algorithmic differences:
- Missing period filtering (pmin/pmax/maximumPeriodFactor)
- Unconditional inclusion of all periods
- 0.1-100%+ output differences vs Praat (voice quality dependent)

Package always used Praat's native implementations - SIMD versions
were exported but never called. Removing to eliminate maintenance
burden and potential user confusion.

All Praat-faithful implementations remain intact in pointprocess_wrappers.cpp

See .planning/SIMD_JITTER_ACCURACY_ASSESSMENT.md for technical details.
```
