# pladdrr Current Status - 2025-12-14

## Package Information
- **Version**: 1.2.5
- **Branch**: 001-praat-r-access (8 commits ahead of origin)
- **Build Status**: ✅ Compiles cleanly
- **Test Status**: ✅ Tests pass

## Recent Work Completed

### Dec 13-14: Rcpp Modules POC ✅ COMPLETE
- Evaluated migrating to Rcpp Modules for code size reduction
- **Result**: 58% code reduction possible BUT integration blocked
- **Decision**: Keep current R6 + wrapper architecture
- **Status**: All changes committed, POC archived

### Dec 11-13: Tremor Analysis ⚠️ MOSTLY COMPLETE
- ✅ Fixed FTrI calculation (added `start_time` parameter)
- ✅ Implemented Pitch intensity API (`get_intensity_at_time`, `get_mean_intensity`)
- ✅ Implemented `analyze_tremor()` function (18 metrics)
- ✅ Fixed `Pitch$to_pointprocess_peaks()` method
- ⚠️ **Remaining Issue**: FCoM/ACoM values too low (0.15 vs expected 0.5-0.6)

### Dec 13: Performance Optimization ✅ COMPLETE
- 6.16x DSI speedup via compiler optimization
- pladdrr now faster than Python Parselmouth
- Released as v1.2.4

## Issues Previously Thought to Exist - ALL FIXED ✅

### Issue #1: Window Shape Enum Bug ✅ FIXED
- **Status**: Fixed in v1.2.2 (commit 67e4b65, Dec 11)
- **Verified**: All 12 window shapes working correctly
- **Note**: MISSING_FEATURES_AUDIT.md was outdated (written before fix)

### Issue #2: Interpolation Parameter ✅ FIXED
- **Status**: Working correctly, always was

### Issue #3: Pitch$to_pointprocess_peaks() ✅ FIXED
- **Status**: Fixed in v1.2.2 (commit 67e4b65, Dec 11)
- **Verified**: Method exists and works (R/pitch-r6.R line 389)

## Actual Current Issue

### FCoM/ACoM Tremor Metrics Too Low ⚠️

**Problem**: Frequency/Amplitude Contour Magnitude values incorrect
- **Current**: FCoM = 0.15, ACoM = 0.16
- **Expected**: FCoM = 0.599, ACoM = 0.442
- **Error**: ~75% underestimation

**Possible Causes**:
1. Window shape (should use "Gaussian1" not "hanning") - documented fix exists
2. Contour normalization method
3. Pitch parameter tuning for tremor range
4. Interpretation of "intensity" in Brückl protocol

**Current Implementation** (R/tremor.R line 271-274):
```r
# Don't filter by voiced - contour signals are not periodic, use all frames
# Use frame 1 intensity (following Brückl's readPitchOb.praat implementation)
fcom <- ifelse(nrow(f0_pitch_df) > 0 && "intensity" %in% names(f0_pitch_df) &&
               !is.na(f0_pitch_df$intensity[1]),
               f0_pitch_df$intensity[1],
               0.0)
```

**Documentation References**:
- TREMOR_ISSUES_STATUS.md - Shows Gaussian1 fix and intensity API exist
- SESSION_SUMMARY_2025-12-11_TREMOR_METRICS.md - Details current state
- TREMOR_ALGORITHM_ANALYSIS.md - Algorithm analysis

**Next Steps for Investigation**:
1. Review Brückl (2012, 2015) papers for exact protocol
2. Check if Gaussian1 window is being used (may need code update)
3. Test with multiple audio files
4. Compare with reference Praat tremor script implementation
5. Verify contour normalization formula

**Estimated Time**: 4-6 hours research + implementation

## Clean-Up Items

### LOW PRIORITY 📋

1. **Remove Debug Logging** (30 min)
   - Files: `src/praat.github.io/fon/Sound_to_Pitch.cpp`, `src/praat.github.io/melder/NUMinterpol.cpp`
   - Impact: Console pollution with thousands of debug lines

2. **Update Outdated Documentation** (15 min)
   - ✅ MISSING_FEATURES_AUDIT.md - Updated to show issues fixed
   - NEXT_STEPS.md - Update to current priorities

3. **Silent/Sounding Duration Filtering** (2-3 hours)
   - TODO in `src/sound_wrappers.cpp`
   - Feature: Filter short intervals in `Sound$to_textgrid_silences()`

## Recommended Next Action

**PRIORITY**: Investigate FCoM/ACoM calculation issue

**Approach**:
1. Check if Gaussian1 window is actually being used in current code
2. Add diagnostic output to show intermediate values
3. Compare step-by-step with reference implementation
4. Test with sv1.wav file that has known expected values

**Command to test current state**:
```bash
cd /Users/frkkan96/Documents/src/pladdrr
R_LIBS=/tmp/pladdrr-test Rscript test_fcom_fix.R
```

## Git Status

- Clean working directory except:
  - `build.log` (modified) - Can be ignored
  - `valgrind_output.txt` (untracked) - Can be ignored or committed
  - `test_window_shapes.R` (untracked) - Verification script, can commit

**Ready to commit**:
- Updated MISSING_FEATURES_AUDIT.md (shows all issues fixed)

## Build Information

**Last successful build**:
- Location: `/tmp/pladdrr-test`
- Time: ~5 minutes
- Status: All 12 window shapes tested and working

**To rebuild**:
```bash
cd /Users/frkkan96/Documents/src/pladdrr
rm -f /Library/Frameworks/R.framework/Versions/4.4-arm64/Resources/library/00LOCK-pladdrr
R CMD INSTALL --preclean --library=/tmp/pladdrr-test .
```

## Summary

✅ **Good News**: Window shape bug and Pitch methods were already fixed in v1.2.2

⚠️ **Current Focus**: FCoM/ACoM tremor calculation needs investigation

📋 **Clean-Up**: Minor documentation updates and debug logging removal

🎯 **Package Maturity**: Core functionality complete, addressing specialized metrics accuracy
