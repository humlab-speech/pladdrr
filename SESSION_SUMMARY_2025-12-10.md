# pladdrr v1.2.1 Status - Pitch Detection Fixed (2025-12-11)

## ✅ COMPLETED

### Bug Fix: Pitch Detection Type Mismatch
**Issue**: Pitch detection returned incorrect F0 values (188% error in tremor analysis)
**Cause**: Parameter type mismatch - `int` vs Praat's `integer` (intptr_t)
**Fix**: Use `static_cast<integer>()` when calling Praat functions
**Impact**: CRITICAL - Affects all pitch-based analysis

### Changes
- ✅ Fixed 4 pitch methods: `to_pitch()`, `to_pitch_ac()`, `to_pitch_cc()`, `to_pitch_filtered()`
- ✅ Version bumped: 1.2.0 → 1.2.1
- ✅ NEWS.md updated with detailed fix description
- ✅ Test script created: `test_pitch_fix.R`
- ✅ All changes committed

### Commits
1. `6da6e20` - Fix pitch: cast int→integer for max_candidates in C++ calls
2. `d203e28` - v1.2.1: Pitch detection type mismatch fix  
3. `d762fd7` - Add test script & summary for pitch fix

## ⏳ PENDING

### Build Status
- **Started**: ~08:00 (ARM Mac)
- **Duration**: ~2 hours expected
- **Status**: Compiling (no errors, cosmetic warnings only)
- **Log**: `install.log`

### Testing Plan
Once build completes:
```bash
# 1. Quick pitch test
Rscript test_pitch_fix.R

# 2. Full tremor/DSI/AVQI test
Rscript test_tremor_dsi_avqi.R
```

**Expected Results**:
- Frames 4-9 mostly unvoiced (matching Praat)
- Tremor frequency ~1.7 Hz (not 4.999 Hz)
- All pitch methods work correctly

## 📋 NEXT ACTIONS

1. ⏳ **Wait for build** (~90 min remaining)
2. ▶ **Run tests** when build finishes
3. ✓ **Verify fix** matches Praat output
4. 🚀 **Consider CRAN submission** if tests pass

## 📊 Package Status

- **Version**: 1.2.1
- **Objects**: 19+ Praat objects  
- **Methods**: 330+ methods
- **Test Coverage**: Comprehensive
- **Platform**: macOS ARM64 (primary), cross-platform ready

## 🔧 Technical Details

**Type System Issue**:
```cpp
// Praat definition
using integer = intptr_t;  // 64-bit

// Old (wrong)
int max_candidates  // 32-bit → misalignment

// New (fixed)
int max_candidates                      // R interface
static_cast<integer>(max_candidates)   // Praat call
```

**Why Not Use `integer` Directly?**
Rcpp code generation fails with custom types. Solution: Keep interface simple, cast internally.

## 📚 Documentation

- `PITCH_FIX_SESSION_SUMMARY.md` - Full technical details
- `PITCH_DETECTION_TYPE_MISMATCH_FIX.md` - Initial bug analysis
- `NEWS.md` - User-facing changelog
- `test_pitch_fix.R` - Verification script

---

**Last Updated**: 2025-12-11 09:30 UTC  
**Status**: Fix complete, testing pending
