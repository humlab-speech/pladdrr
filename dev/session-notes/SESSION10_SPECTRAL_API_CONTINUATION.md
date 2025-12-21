# pladdrr Spectral Analysis API Implementation - Continuation Prompt

## Context: What We've Done

### Session 9 Achievement: TextGrid Loading Fix ✅ COMPLETE
**Problem Solved**: Fixed critical segfault in TextGrid loading (SIGSEGV at address 0x68)
**Root Cause**: Static class registry in Praat source was invisible across shared library boundaries
**Solution**: Changed linkage from `static` to `extern` in `sys/Thing.cpp` and `sys/Thing.h`

**Key Changes Made**:
- `src/praat.github.io/sys/Thing.cpp` - extern class registry + null checks
- `src/praat.github.io/sys/Thing.h` - extern declarations  
- `src/praat.github.io/sys/Data.cpp` - debug headers
- `src/praat.github.io/melder/MelderReadText.cpp` - debug headers
- `src/praat.github.io/melder/NUMinterpol.cpp` - removed debug output

**Testing Results**:
- 32/33 tests passing (1 CRAN skip)
- Performance: 37MB file in 0.164s
- All TextGrid methods working

**Documentation Created** (9 files):
- DOCUMENTATION_INDEX.md - Navigation guide
- TEXTGRID_FIX_SUMMARY.md - Technical overview
- TEXTGRID_FIX_CHECKLIST.md - Verification
- docs/PRAAT_MODIFICATIONS.md - Source changes
- docs/praat_modifications.patch - Git patch
- And 4 more session docs

**Version**: Bumped to 1.2.9, committed to git ✅

---

## Current Task: Phase 1 - Critical Spectral Analysis API Implementation

### NEW REQUIREMENT: User Feedback Analysis
**Source**: `PLADDRR_API_GAPS_ASSESSMENT.md` (939 lines)
**Issue**: Attempting to implement pharyngeal voice quality analysis revealed **critical gaps** in pladdrr's spectral API that block standard phonetics workflows

### Three Critical Blockers Identified:

#### 1. `Spectrum$formula()` - CRITICAL
**Missing**: Cannot apply formulas to modify spectrum values
```r
# Needed but currently errors:
spectrum$formula("if x >= 50 then self*x else self fi")  # Pre-emphasis
```
**Praat equivalent**: `Formula: "..."`
**C function to wrap**: `Spectrum_formula()` in Praat source

#### 2. `Spectrum$to_ltas_1to1()` - CRITICAL
**Missing**: Cannot convert filtered Spectrum to LTAS
```r
# Needed but currently errors:
ltas <- spectrum$to_ltas_1to1()
```
**Praat equivalent**: `To Ltas (1-to-1)`
**C function to wrap**: `Spectrum_to_Ltas()` in Praat source

#### 3. LTAS Peak Finding - CRITICAL
**Missing**: Cannot find spectral peaks for harmonics/formants
```r
# Needed but currently errors:
h1 <- ltas$get_maximum(140, 160, "parabolic")
h1_freq <- ltas$get_frequency_of_maximum(140, 160, "parabolic")
```
**Praat equivalent**: `Get maximum:...` and `Get frequency of maximum:...`
**C functions to wrap**: `Ltas_getMaximum()`, `Ltas_getFrequencyOfMaximum()`

### Impact: BLOCKS ALL VOICE QUALITY ANALYSIS
Without these methods, cannot implement:
- H1-H2, H1-A1, H1-A2, H1-A3 measurements (pharyngeal analysis)
- Cepstral Peak Prominence (CPP)
- Spectral tilt measures
- Any research requiring spectral peak detection

---

## Implementation Plan Agreed Upon

### Phase 1 (CURRENT - 2 weeks): Fix 3 Critical Blockers
1. Implement `Spectrum$formula()`
2. Implement `Spectrum$to_ltas_1to1()`
3. Implement `LTAS$get_maximum()` and `$get_frequency_of_maximum()`

**Result**: Unblocks 80% of use cases

### Phase 2 (Follow-up - 2 weeks): Consistency + Accuracy
4. Add frame-based access to Formant/Pitch/Intensity
5. Add interpolation parameters to query methods

### Phase 3 (Polish - 1 week): Documentation + Testing
6. Roxygen2 docs for all new methods
7. Cross-validation test suite against Praat

**Total Effort**: 5 weeks to comprehensive solution

---

## Next Steps: Start Implementation

### Step 1: Locate Praat Source Functions
```bash
cd /Users/frkkan96/Documents/src/pladdrr/src/praat.github.io

# Find Spectrum functions
gemini -p "@fon/Spectrum.cpp @fon/Spectrum.h Find the implementation of: 
1. Spectrum_formula() - applies formula to spectrum
2. Spectrum_to_Ltas() or Spectrum_to_Ltas_1to1() - converts to LTAS
Show function signatures, parameters, return types, and usage patterns"

# Find LTAS functions  
gemini -p "@fon/Ltas.cpp @fon/Ltas.h Find the implementation of:
1. Ltas_getMaximum() - finds maximum in frequency range
2. Ltas_getFrequencyOfMaximum() - finds frequency of maximum
Show function signatures, parameters (especially interpolation), return types"
```
