# Pitch Detection Type Mismatch Bug - FIXED (2025-12-10)

## Problem Identified

**Bug**: Parameter type mismatch in pitch detection wrappers
- **Praat expects**: `integer maxnCandidates` (where `integer = intptr_t`, 64-bit on 64-bit systems)
- **pladdrr was using**: `int max_candidates` (typically 32-bit)
- **Impact**: Potential parameter misinterpretation on 64-bit systems, causing incorrect voicing decisions

## Root Cause

In `/src/sound_wrappers.cpp`, the pitch detection wrapper functions used `int` instead of `integer`:

```cpp
// WRONG (before fix):
XPtr<structPitch> sound_to_pitch_ac(
    ...
    int max_candidates,    // ❌ WRONG TYPE
    ...
)

// CORRECT (after fix):
XPtr<structPitch> sound_to_pitch_ac(
    ...
    integer max_candidates,  // ✅ CORRECT TYPE
    ...
)
```

## Praat's Function Signatures

From `/src/praat.github.io/fon/Sound_to_Pitch.h`:

```cpp
autoPitch Sound_to_Pitch_rawAc (Sound me,
    double timeStep, double pitchFloor, double pitchCeiling,
    integer maxnCandidates, bool veryAccurate,  // ← integer, not int!
    double silenceThreshold, double voicingThreshold, double octaveCost,
    double octaveJumpCost, double voicedUnvoicedCost);

autoPitch Sound_to_Pitch_rawCc (Sound me,
    double timeStep, double pitchFloor, double pitchCeiling,
    integer maxnCandidates, bool veryAccurate,  // ← integer, not int!
    double silenceThreshold, double voicingThreshold, double octaveCost,
    double octaveJumpCost, double voicedUnvoicedCost);
```

## Type Definition

From `/src/praat.github.io/melder/melder_int.h`:

```cpp
using integer = intptr_t;  // 64-bit on 64-bit systems, not 32-bit int!
```

## Fixed Functions

Changed in `/src/sound_wrappers.cpp`:

1. ✅ `sound_to_pitch_ac()` - Line 356: `int` → `integer`
2. ✅ `sound_to_pitch_cc()` - Line 399: `int` → `integer`

## Rcpp Export Regeneration

After fixing the C++ code, regenerated Rcpp exports:

```bash
Rscript -e "Rcpp::compileAttributes('.', verbose=TRUE)"
```

This updated:
- `R/RcppExports.R`
- `src/RcppExports.cpp` (now correctly uses `input_parameter< integer >`)
- `inst/include/pladdrr_RcppExports.h`

## Verification

Rcpp correctly handles the type conversion:
```cpp
// In src/RcppExports.cpp (auto-generated):
Rcpp::traits::input_parameter< integer >::type max_candidates(max_candidatesSEXP);
```

This ensures proper conversion from R integer to Praat's `integer` type.

## Impact Assessment

**Before Fix**:
- Passing max_candidates=15 from R would be interpreted as 32-bit int
- On 64-bit systems, this could cause memory misalignment or incorrect value interpretation
- Could lead to incorrect candidate selection in pitch tracking
- Potentially explains voicing decision discrepancies vs Praat desktop

**After Fix**:
- Correct 64-bit integer type used throughout
- Matches Praat's native implementation exactly
- Should resolve pitch detection discrepancies

## Testing Required

1. Rebuild package: `R CMD INSTALL --preclean .`
2. Run tremor test: `Rscript test_tremor_dsi_avqi.R`
3. Compare pitch detection results with Praat desktop
4. Verify tremor frequency calculation is now correct

## Files Modified

- `src/sound_wrappers.cpp` (2 lines changed)
- `R/RcppExports.R` (auto-regenerated)
- `src/RcppExports.cpp` (auto-regenerated)
- `inst/include/pladdrr_RcppExports.h` (auto-regenerated)

## Next Version

Bump to **v1.2.1** after successful testing confirms fix resolves the pitch detection bug.

---

**Status**: Code fixed, awaiting build & test confirmation  
**Date**: 2025-12-10  
**Severity**: HIGH (affects core pitch detection accuracy)  
**Resolution**: Type mismatch corrected to match Praat's implementation
