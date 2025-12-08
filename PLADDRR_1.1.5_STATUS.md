# pladdrr 1.1.5 Status Report - Critical Pitch Detection Crash

**Date:** 2025-12-07
**pladdrr Version:** 1.1.5
**Status:** ❌ **CRITICAL REGRESSION** - Universal segfault in pitch detection

## Executive Summary

pladdrr 1.1.5 attempted to fix the pitch detection bug from 1.1.4 (which returned 0 voiced frames), but introduced a **worse regression**: **all pitch detection now crashes with segmentation fault**.

This is a **universal crash** affecting all pitch detection methods (`to_pitch()`, `to_pitch_ac()`, `to_pitch_cc()`) with any parameters or input sounds.

## Critical Bug: Universal Pitch Detection Segfault

### The Problem

**ALL pitch detection methods crash with segmentation fault during Brent optimization:**

```r
library(pladdrr)

# Even simplest test crashes:
sound <- Sound$create_tone(frequency = 100, duration = 0.1, sampling_rate = 16000)
pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 50, pitch_ceiling = 800)

# *** caught segfault ***
# address 0x20, cause 'invalid permissions'
```

### Crash Location

**Crash point:** `NUMimproveMaximum` during Brent optimization in pitch candidate refinement

**Debug output shows:**
```
[PITCH_DEBUG] Calling NUMimproveMaximum with vec size=1763
[PITCH_DEBUG] Creating constVEC from &r[-881] size 1763
[PITCH_DEBUG] vecStart pointer=0x115efb588
[PITCH_DEBUG] constVEC created successfully
[NUMINTERPOL_DEBUG] Enter: ixmid=982 depth=3
[NUMINTERPOL_DEBUG] Check1 pass
[NUMINTERPOL_DEBUG] Check2 pass depth=3
[NUMINTERPOL_DEBUG] Check3 pass
[NUMINTERPOL_DEBUG] Check4 pass, doing sinc
[NUMINTERPOL_DEBUG] Calling brent

*** caught segfault ***
address 0x20, cause 'invalid permissions'
```

**Analysis:**
- Pitch detection initialization works
- Frame iteration works
- Autocorrelation peak detection works
- Crash occurs when calling Brent's method for sub-sample precision
- Address 0x20 suggests NULL or near-NULL pointer dereference
- Likely a function pointer or callback issue in the Brent optimization code

### Universality of Crash

**Tested and confirmed crashing:**

1. **Pure 440Hz tone** (1.0s, 44100 Hz) → CRASH
2. **Pure 100Hz tone** (0.1s, 16000 Hz) → CRASH
3. **Real sustained vowel** (`sv1.wav`) → CRASH
4. **Different pitch methods:**
   - `to_pitch()` → CRASH
   - `to_pitch_ac()` → CRASH
   - `to_pitch_cc()` → CRASH
5. **Different parameters:**
   - Wide range (50-800 Hz) → CRASH
   - Narrow range (75-600 Hz) → CRASH
   - Any time_step value → CRASH

**Conclusion:** This is not a parameter or input-specific issue. The crash is in core pitch optimization code.

## Comparison with 1.1.4

| Feature | 1.1.4 | 1.1.5 | Change |
|---------|-------|-------|--------|
| Pitch detection runs | ✅ Runs to completion | ❌ **Crashes** | **REGRESSION** |
| Returns voiced frames | ❌ Returns 0 | ❌ **N/A (crashes)** | **WORSE** |
| F0 values | ❌ All NaN | ❌ **N/A (crashes)** | **WORSE** |
| Usability | ⚠️ Runs but wrong results | ❌ **Completely unusable** | **CRITICAL REGRESSION** |
| `Pitch$to_pointprocess_cc(sound)` | ✅ Method exists | ❓ Unknown (can't test) | Unknown |

**Verdict:** 1.1.5 is **WORSE** than 1.1.4. At least 1.1.4 ran without crashing.

## Impact

This bug **completely blocks** all functionality in pladdrr:

- ❌ **DSI:** Cannot compute pitch → Cannot create PointProcess → **FAILS**
- ❌ **AVQI:** Cannot detect sounding segments → **FAILS**
- ❌ **Tremor:** Cannot analyze F0/amplitude modulations → **FAILS**
- ❌ **Any pitch-based analysis:** Jitter, shimmer, HNR, voice report → **FAILS**
- ❌ **Any voice quality measure:** All blocked by pitch detection crash

**Status of R implementations:** All blocked, cannot be tested.

## Root Cause Analysis

### Evidence from Debug Output

The crash occurs consistently at the same point:

1. ✅ Pitch object creation succeeds
2. ✅ Frame iteration works (processes all frames)
3. ✅ Autocorrelation computation succeeds
4. ✅ Peak detection finds candidates
5. ✅ constVEC creation succeeds
6. ✅ Brent optimization setup passes all checks
7. ❌ **CRASH when calling Brent function**

**Hypothesis:** The issue is in how the Brent optimization function is called or how the function pointer is set up. Address 0x20 suggests:
- NULL function pointer dereference
- Uninitialized callback
- Memory alignment issue in function pointer
- Incorrect calling convention between R/C boundary

### Likely Changed Code in 1.1.5

Given that 1.1.4 ran (but returned wrong values) and 1.1.5 crashes at the same point where 1.1.4 likely had its bug, the maintainers probably:

1. Attempted to fix the "returns 0 voiced frames" bug in 1.1.4
2. Modified the Brent optimization or peak refinement code
3. Introduced a memory/pointer bug in the process
4. The fix worked in their test environment but has a portability issue

## Recommendations

### For pladdrr Maintainers (URGENT - BLOCKING BUG)

**Priority: CRITICAL - Complete package failure**

**Bug location:** `NUMimproveMaximum` / Brent optimization in `Sound_into_PitchFrame`

**Specific issue:** Segfault at address 0x20 when calling Brent function

**Test case to reproduce:**
```r
library(pladdrr)
sound <- Sound$create_tone(frequency = 100, duration = 0.1, sampling_rate = 16000)
pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 50, pitch_ceiling = 800)
# *** caught segfault ***
```

**Suggested investigation:**
1. Check function pointer initialization for Brent's method
2. Verify callback function signatures match between caller and callee
3. Check memory alignment for function pointers
4. Verify constVEC lifetime (may be destroyed before Brent uses it)
5. Test if disabling Brent optimization (using raw peak) works as workaround

**Recommendation:** **Revert to 1.1.4** (or 1.1.3 if 1.1.4 needs fixes) and fix the "returns 0 voiced frames" bug more carefully. The current crash is worse than wrong results.

### For R Users

**Current workarounds:**

1. **Use pladdrr 1.1.3** - Pitch detection worked, but lacks `Pitch$to_pointprocess_cc(sound)` method
2. **Use Python/Parselmouth** - Fully functional, recommended
3. **Use reticulate** - Call Python from R
4. **Wait for pladdrr 1.1.6 or later** - Critical bug fix needed

**Do NOT use pladdrr 1.1.5** - It will crash on any pitch detection.

### For This Project

**Status:**
- ✅ Python implementations: Complete, validated, production-ready
- ❌ R implementations: Completely blocked by pladdrr 1.1.5 crash
- ⏳ Waiting for: pladdrr 1.1.6+ with pitch detection crash fixed

**Cannot proceed with R validation until crash is resolved.**

## Timeline

**pladdrr progress:**
- 1.1.0 → 1.1.1: Added TextGrid methods
- 1.1.1 → 1.1.2: Fixed `extract_intervals_where` segfault ✅
- 1.1.2 → 1.1.3: Added `PointProcess$to_textgrid_vuv` ✅
- 1.1.3 → 1.1.4: Added `Pitch$to_pointprocess_cc` ✅ BUT pitch detection returns 0 voiced frames ❌
- 1.1.4 → 1.1.5: Attempted pitch fix BUT introduced universal segfault ❌❌
- **1.1.5 → 1.1.6+ needed:** Fix segfault in Brent optimization during pitch detection

**We're back to square one.** The pitch detection that worked in 1.1.3 has been broken in two consecutive releases (1.1.4 and 1.1.5).

## Conclusion

pladdrr 1.1.5 represents a **critical regression** from 1.1.4. While 1.1.4 had incorrect results (0 voiced frames), 1.1.5 crashes completely.

**Bug severity:** **CRITICAL - BLOCKING**
**Bug type:** **Regression** + **Segmentation fault**
**Affected functionality:** **ALL pitch-based analysis**
**Estimated fix complexity:** **Medium-High** - Requires debugging C-level pointer/function call issue

**Immediate recommendation:** Maintainers should revert to 1.1.3 or 1.1.4 codebase and approach the pitch detection fix more carefully.

---

**Test files:**
- `test_pladdrr_1.1.5_pitch.R` - Comprehensive test demonstrating crash
- `test_minimal_pitch.R` - Minimal reproduction case
- `test_dsi_r.R` - Cannot run (would crash on pitch detection)

**Previous status:**
- `PLADDRR_1.1.4_STATUS.md` - Documents "0 voiced frames" bug
- `PLADDRR_FINAL_ASSESSMENT.md` - Documents architectural journey through 1.1.3

**Bug severity:** **CRITICAL** - Entire package unusable for voice analysis
**Bug type:** **Segmentation fault in core pitch detection**
**Recommendation:** **DO NOT USE pladdrr 1.1.5** - Use Python/Parselmouth or wait for fix
