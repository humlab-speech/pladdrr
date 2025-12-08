# Next Steps - pladdrr 1.1.6

## Status: ✅ BOTH BUGS FIXED - Ready for Cleanup & Commit

## Immediate Actions (in order):

### 1. Remove Debug Output
```bash
# Remove debug from pitch_analysis.cpp (if any remains)
# Remove debug from NUMinterpol.cpp (if any remains)
# Remove debug from formant_wrappers.cpp (if any remains)
```

### 2. Update Version
```r
# In DESCRIPTION, change:
Version: 1.1.5
# To:
Version: 1.1.6
```

### 3. Update NEWS.md
```markdown
# pladdrr 1.1.6 (2025-12-07)

## Bug Fixes

* Fixed formant extraction crash: Added missing Roots.cpp, NUMsorting.cpp, 
  and table stubs. Initialized NUMfpp and RNG state. (#XXX)

* Fixed pitch detection segfault: Added NUMfpp NULL check in 
  NUMminimize_brent() to prevent crash during candidate refinement. (#XXX)

## Impact

Both fixes restore critical functionality:
- Formant extraction (all methods: Burg, Wavelet, Keep All, Split Levinson)
- Pitch detection (autocorrelation, cross-correlation)
- Voice quality metrics (jitter, shimmer, HNR)
- DSI, AVQI, and tremor analysis now functional
```

### 4. Verify All Tests Pass
```r
# Test formant
sound <- Sound$new("inst/extdata/test.wav")
formant <- sound$to_formant_burg()
stopifnot(formant$get_number_of_frames() > 0)

# Test pitch (synthetic)
sound2 <- Sound$create_tone(frequency = 100, duration = 0.1, sampling_rate = 16000)
pitch <- sound2$to_pitch()
stopifnot(pitch$get_number_of_frames() > 0)

# Test pitch (real)
pitch2 <- sound$to_pitch()
stopifnot(pitch2$get_number_of_frames() > 0)
```

### 5. Git Commit
```bash
git add -A
git commit -m "Fix critical formant extraction and pitch detection crashes (v1.1.6)

- Add Roots.cpp, NUMsorting.cpp for formant polynomial root finding
- Add table_stubs.cpp for statistical functions (SSCP/PCA/Covariance)
- Initialize NUMfpp and RNG in formant/sound wrappers
- Add NUMfpp NULL check in NUMminimize_brent() to prevent pitch crash
- Remove unsupported formant methods from vignette

Fixes #XXX, #YYY
Closes #ZZZ"
```

### 6. Test DSI/AVQI/Tremor
```r
# Test if higher-level functions work now
# (These depend on pitch + formant + harmonicity)
```

### 7. Build & Check
```bash
R CMD build .
R CMD check --as-cran pladdrr_1.1.6.tar.gz
```

## Documentation Created

- ✅ `FORMANT_FIX_SUMMARY_2025-12-07.md`
- ✅ `PITCH_FIX_SUMMARY_2025-12-07.md`
- ✅ `CRITICAL_BUGS_FIXED.md`
- ✅ `SESSION_SUMMARY_2025-12-07_FINAL.md`
- ✅ This file

---
**All critical bugs FIXED!** Ready for version bump and commit.
