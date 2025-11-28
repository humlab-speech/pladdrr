# pladdrr Functionality Gaps - Filtered Analysis

**Date**: 2025-11-28
**Package Version**: 1.0.4
**Scope**: Non-interactive, programmatic functionality only

## Exclusions Applied

The following categories are EXCLUDED from implementation:
- ❌ **Batch processing APIs** - R has native batch processing superiority
- ❌ **Plotting/visualization** - Planned for separate release
- ❌ **User interaction** - Editor window, manual annotation
- ❌ **Demo window** - Interactive demonstrations
- ❌ **GUI applications** - Shiny apps are separate

## Critical Gaps to Address

Based on PRAAT_ARCHIVE_REIMPLEMENTATION_ASSESSMENT_2025-11-27.md:

### Gap 1: Trajectory Extraction (CRITICAL)
**Status**: Partially implemented (30%)
**Archive Usage**: 70%+ of advanced scripts
**Issue**: No convenient method to extract formant/pitch trajectories over time intervals

**What Exists**:
- ✅ `Formant$get_value_at_time()` - Single time point
- ✅ `Pitch$get_value_at_time()` - Single time point
- ✅ `Intensity$get_value_at_time()` - Single time point

**What's Missing**:
- ❌ Trajectory extraction over time ranges
- ❌ Time-normalized sampling (e.g., 11 points from 20%-80%)
- ❌ Interval-based extraction from TextGrid

**Praat Source Capability**:
Check if Praat has native trajectory extraction functions we can wrap.

---

### Gap 2: TextGrid Automation (HIGH)
**Status**: Basic operations exist (40%)
**Archive Usage**: 60%+ of scripts
**Issue**: Missing automation helpers for common patterns

**What Exists**:
- ✅ `TextGrid$insert_boundary()` - Manual boundary insertion
- ✅ `TextGrid$set_interval_text()` - Set labels
- ✅ `TextGrid$get_label_at_time()` - Query labels
- ✅ `TextGrid$get_interval_at_time()` - Get interval index

**What's Missing** (check Praat source):
- ? `Sound$to_textgrid_silences()` - Auto-segment by silence
- ? `TextGrid$replace_interval_text()` - Bulk find/replace
- ❌ `TextGrid$merge_consecutive_intervals()` - Merge same labels
- ❌ `TextGrid$validate()` - Check for empty/invalid intervals

---

### Gap 3: Advanced Prosody Analysis (MEDIUM)
**Status**: Basic pitch exists (40%)
**Archive Usage**: 30%+ of discourse research
**Issue**: Missing specialized pitch analysis beyond basic F0

**What Exists**:
- ✅ `Sound$to_pitch()` - Pitch extraction
- ✅ `Pitch$get_mean()`, `$get_minimum()`, `$get_maximum()`
- ✅ `Pitch$to_pitch_tier()` - Convert to modifiable tier

**What's Missing** (check Praat source):
- ? Pitch stylization (Momel, ProsodyPro)
- ? Turning point detection
- ? Slope calculation
- ❌ Pitch range/span calculations per interval

---

### Gap 4: Audio Quality Assessment (MEDIUM)
**Status**: Minimal (20%)
**Archive Usage**: 50%+ of production pipelines
**Issue**: No quality control utilities

**What Exists**:
- ✅ `Sound$get_maximum()` - Can detect clipping
- ✅ `Intensity` object - RMS calculations

**What's Missing**:
- ❌ SNR estimation
- ❌ Clipping detection helper
- ❌ Zero-crossing rate
- ❌ Spectral flatness

**Note**: Most of these can be R-level implementations using existing primitives.

---

### Gap 5: Formant Normalization (MEDIUM)
**Status**: None (0%)
**Archive Usage**: 40%+ of vowel studies
**Issue**: No speaker normalization methods

**What Exists**:
- ✅ `Formant` extraction with all methods
- ✅ Raw formant values

**What's Missing**:
- ❌ Lobanov normalization
- ❌ Nearey normalization
- ❌ Watt & Fabricius normalization

**Note**: These are R-level statistical transformations, NOT Praat functions.
**Decision**: Implement as standalone R functions, not C++ wrappers.

---

## Implementation Plan

### Phase 1: Verify Praat Source Capabilities
Check what actually exists in Praat C++ that we haven't wrapped yet:
1. TextGrid silence detection (`Sound_to_TextGrid`)
2. TextGrid text replacement
3. Pitch stylization functions
4. Any trajectory extraction helpers

### Phase 2: Implement C++ Wrappers (if Praat has them)
Only wrap functions that:
- Exist in `src/praat.github.io`
- Are non-interactive
- Are not stubs

### Phase 3: R-Level Utilities (if no Praat equivalent)
Implement in R using existing primitives:
- Formant normalization (pure R statistics)
- Audio quality metrics (R + existing Sound methods)
- Trajectory extraction helpers (R loops over existing methods)

---

## Next Steps

1. ✅ Search Praat source for missing functions
2. ⏸️ Identify which are already implemented but not exposed
3. ⏸️ Add C++ wrappers for unexposed Praat functions
4. ⏸️ Create R-level utilities for non-Praat functionality
5. ⏸️ Document and test

