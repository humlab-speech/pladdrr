# Functionality Gaps - Final Assessment and Recommendations

**Date**: 2025-11-28
**Package Version**: 1.0.4
**Assessment Source**: PRAAT_ARCHIVE_REIMPLEMENTATION_ASSESSMENT_2025-11-27.md

## Executive Summary

After analyzing the Praat source code and comparing against the gap analysis document, we found:

✅ **Key TextGrid automation functions ALREADY EXIST in Praat source but are NOT YET WRAPPED**
✅ **Most "gaps" can be filled with R-level utilities using existing primitives**
❌ **NO new C++ code needs to be written - only wrappers for existing Praat functions**

## Findings

### ✅ Category 1: Existing Praat Functions - Need Wrapping Only

**File**: `src/praat.github.io/dwtools/TextGrid_extensions.cpp` (556 lines, REAL CODE)
**Status**: ✅ Already compiled in package (line 112 of Makevars.in)
**Action**: Add C++ wrappers + R6 methods

| Function | Use Case | Archive Usage |
|----------|----------|---------------|
| `TextGrid_changeLabels()` | Find/replace labels with regex | 60%+ |
| `IntervalTier_removeBoundariesBetweenIdenticallyLabeledIntervals()` | Merge consecutive same-label intervals | 40%+ |
| `TextGrid_getTotalDurationOfIntervalsWhere()` | Get total duration matching criterion | 30%+ |
| `TextGrid_extendTime()` | Extend time domain (begin/end) | 20%+ |
| `TextGrid_setTierName()` | Rename tiers | 15%+ |

**Implementation Effort**: 2-3 days
- Add 5-6 Rcpp wrappers to `src/textgrid_wrappers.cpp`
- Add 5-6 methods to `R/textgrid-r6.R`
- Add tests

**Priority**: 🔴 **CRITICAL** - These are heavily used and trivial to expose

---

### ✅ Category 2: R-Level Utilities - No C++ Needed

**Trajectory Extraction**:
- `extract_formant_trajectories(formant, textgrid, tier, ...)` 
- `extract_pitch_trajectories(pitch, textgrid, tier, ...)`

**Reason**: These are just loops over existing `$get_value_at_time()` methods
**Implementation**: Pure R using existing primitives
**Effort**: 1 day

**Formant Normalization**:
- `normalize_formants_lobanov(df)`
- `normalize_formants_nearey(df)`
- `normalize_formants_wattfabricius(df)`

**Reason**: Statistical transformations, NOT acoustic analysis
**Implementation**: Pure R (z-scores and group operations)
**Effort**: 1 day

**Audio Quality Metrics**:
- `check_audio_quality(sound)` → clipping, mean intensity

**Reason**: Combinations of existing methods
**Implementation**: Pure R wrapper around existing Sound/Intensity methods
**Effort**: 0.5 days

---

### ❌ Category 3: NOT Implementing (Per User Request)

**Excluded**:
- Batch processing APIs (R has superior native support)
- Plotting/visualization (planned for separate release)
- User interaction (Editor window, manual annotation)
- Demo window functionality
- GUI applications (Shiny is separate)
- Pitch stylization (complex, low usage <5%)

---

## Recommended Implementation Plan

### Phase 1: TextGrid Extensions Wrappers (Week 1)

**Tasks**:
1. ✅ Verify `TextGrid_extensions.cpp` is compiled (CONFIRMED - line 112 Makevars.in)
2. Add C++ wrappers to `src/textgrid_wrappers.cpp`:
   - `praat_textgrid_change_labels()`
   - `praat_textgrid_merge_consecutive_intervals()`
   - `praat_textgrid_get_total_duration_where()`
   - `praat_textgrid_extend_time()`
   - `praat_textgrid_set_tier_name()`

3. Add R6 methods to `R/textgrid-r6.R`:
   - `TextGrid$change_labels(tier, search, replace, use_regexp)`
   - `TextGrid$merge_consecutive_intervals(tier, label)`
   - `TextGrid$get_total_duration_where(tier, criterion)`
   - `TextGrid$extend_time(delta, position)`
   - `TextGrid$set_tier_name(tier, name)`

4. Add tests to `tests/testthat/test-textgrid.R`

**Deliverable**: 5 new TextGrid methods, all backed by real Praat C++ code

---

### Phase 2: R-Level Utilities (Week 2)

**Tasks**:
1. Create `R/trajectory_extraction.R`:
   - `extract_formant_trajectories()`
   - `extract_pitch_trajectories()`
   - `extract_intensity_trajectories()`

2. Create `R/formant_normalization.R`:
   - `normalize_formants_lobanov()`
   - `normalize_formants_nearey()`
   - `normalize_formants_wattfabricius()`

3. Create `R/audio_quality.R`:
   - `check_audio_quality()`

4. Add documentation and examples
5. Add tests

**Deliverable**: 7 new R utility functions

---

### Phase 3: Documentation & Examples (Week 3)

**Tasks**:
1. Update vignette: "Working with TextGrids"
2. Update vignette: "Formant Analysis Workflows"
3. Add example scripts from Praat archive
4. Update NEWS.md for v1.0.5

---

## Impact Assessment

### Coverage Improvement

**Before**: 85% of programmatic use cases
**After**: ~95% of programmatic use cases

**Remaining 5%**:
- Pitch stylization (complex algorithms, <5% usage)
- Professional DSP (out of scope - use gsignal, seewave)
- Interactive features (excluded by design)

### What This Enables

**Common Research Workflows**:
1. ✅ Vowel formant extraction with time normalization
2. ✅ Bulk TextGrid label corrections
3. ✅ Cross-speaker formant comparison
4. ✅ Pitch trajectory analysis
5. ✅ Recording quality control

**Example**:
```r
# Complete vowel analysis workflow
sound <- Sound$new("audio.wav")
textgrid <- TextGrid$read("audio.TextGrid")

# Fix labels
textgrid$change_labels(tier = 1, search = "ae", replace = "æ")
textgrid$merge_consecutive_intervals(tier = 1, label = "")

# Extract formants
formant <- sound$to_formant_burg(max_num_formants = 5, max_formant_hz = 5500)
vowels <- extract_formant_trajectories(
  formant, textgrid, tier = 1,
  label_filter = "æ",
  time_normalization = 11,
  time_range = c(0.2, 0.8)
)

# Normalize across speakers
vowels_norm <- normalize_formants_lobanov(vowels)
```

---

## Verification Checklist

Before implementing, verify:

- [x] TextGrid_extensions.cpp is compiled (CONFIRMED)
- [x] Functions are real implementations, not stubs (CONFIRMED: 556 lines)
- [x] Functions are non-interactive (CONFIRMED: all programmatic)
- [ ] Test that wrapped functions work correctly
- [ ] Document parameters and return values
- [ ] Add roxygen documentation
- [ ] Update NAMESPACE exports

---

## Timeline

**Week 1**: TextGrid wrappers (2-3 days actual work)
**Week 2**: R utilities (2-3 days actual work)
**Week 3**: Documentation (1-2 days actual work)

**Total Effort**: ~1.5 weeks full-time equivalent
**Calendar Time**: 3 weeks with testing and review

**Release**: v1.0.5 with ~95% coverage of programmatic Praat use cases

---

## Conclusion

The gap analysis identified real needs, but the solution is simpler than expected:

1. **Most "missing" functionality already exists in compiled Praat code** - we just need to expose it through R6 methods
2. **Statistical/workflow utilities belong in R** - not Praat wrappers
3. **No new C++ implementation needed** - only thin wrappers

This is a low-risk, high-value addition that will make pladdrr suitable for ~95% of Praat script re-implementations.

---

**Assessment by**: Claude (GitHub Copilot CLI)
**Date**: 2025-11-28
**Recommendation**: ✅ Proceed with implementation
**Complexity**: 🟢 LOW (wrappers only, no new algorithms)
**Value**: 🔴 HIGH (addresses 60%+ of script patterns)
**Risk**: 🟢 LOW (using proven Praat code)

