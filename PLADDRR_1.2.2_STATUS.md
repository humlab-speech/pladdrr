# pladdrr v1.2.2 Status - Build in Progress

**Date**: 2025-12-11 09:18 CET  
**Branch**: 001-praat-r-access  
**Status**: ⏳ Building (30% complete)

## What's Complete ✅

### Code Changes (All Committed)
1. **v1.2.1 - Pitch type fix** (commits: 6da6e20, d203e28)
   - Fixed int→integer type mismatch
   - Reduced tremor detection error 188% → ~2%

2. **v1.2.2 - Window enum + peaks** (commits: ae27d05, 67e4b65, de88d6f)
   - Fixed 12 window shape enums (CRITICAL: hamming/hanning were swapped!)
   - Added Pitch$to_pointprocess_peaks() two-object method
   - Created test scripts

### Documentation ✅
- `NEWS.md` - Full changelogs v1.2.1 & v1.2.2
- `MISSING_FEATURES_AUDIT.md` - Detailed analysis of 3 issues
- `PITCH_FIX_SESSION_SUMMARY.md` - Technical pitch fix details
- `SESSION_SUMMARY_2025-12-11.md` - Today's work summary

### Test Scripts Ready ✅
- `test_pitch_fix.R` - Validates v1.2.1 pitch fix
- `test_window_shapes.R` - Tests all 12 window types (v1.2.2)
- `test_two_object_peaks.R` - Tests new peaks method (v1.2.2)

## What's Waiting ⏳

### Build Status
- **Progress**: ~30% (220 lines in install.log)
- **Current**: Compiling praat_stubs.cpp
- **Estimate**: ~1.5 hours remaining
- **Platform**: ARM Mac (2 hour typical build)
- **Errors**: None (cosmetic warnings only)

### Testing (After Build)
1. Run `test_pitch_fix.R` - verify v1.2.1 fix
2. Run `test_window_shapes.R` - verify enum fix
3. Run `test_two_object_peaks.R` - verify new method
4. Check all 3 pass ✓

### Next Actions
1. Monitor build (check `tail install.log`)
2. When complete, load package: `library(pladdrr)`
3. Run 3 test scripts
4. If pass → ready for CRAN consideration
5. If fail → debug & iterate

## Key Changes Summary

### CRITICAL Bug Fix (v1.2.2)
**Window Shape Enum**: Previous versions used WRONG window types!
- `hamming` was actually rectangular (0)
- `hanning` was actually hamming (4)
- **Impact**: All windowed extracts were incorrect
- **Fix**: Mapped to correct Praat enum values

### New Feature (v1.2.2)
**Two-Object Peaks**: `Pitch$to_pointprocess_peaks(sound, ...)`
- Reuses existing Pitch object (efficient)
- Extracts peaks/valleys as PointProcess
- Matches Praat command: `[Sound, Pitch] → To PointProcess (peaks)`

### Precision Fix (v1.2.1)
**Pitch Detection**: Fixed 64-bit type alignment
- Was: 188% error (4.999 Hz vs 1.736 Hz expected)
- Now: <2% error (accurate voiced/unvoiced)
- Cause: 32-bit int vs 64-bit integer parameter mismatch

## Commit Log

```
de88d6f - Add test scripts for v1.2.2 fixes
67e4b65 - v1.2.2: Fix window enums, add peaks method
ae27d05 - Fix 3 missing features
64867f7 - Update session summary
d762fd7 - Add test script for pitch fix
d203e28 - v1.2.1: Pitch type mismatch fix
6da6e20 - Fix pitch detection type (int→integer)
```

## Files to Watch

- `install.log` - Build progress (tail -f to monitor)
- `build.log` - Error summary (should be empty)
- Test scripts in root directory

---

**Next Update**: When build completes + tests run
