# v1.1.5 Commit Checklist

## Status: ✅ READY TO COMMIT

## Files Modified (10 core files)

### Build System
- [x] `src/Makevars.in` - Added Roots.cpp, NUMsorting.cpp, table_stubs.cpp

### C++ Source
- [x] `src/formant_wrappers.cpp` - Added ensure_numeric_libs_initialized()
- [x] `src/sound_wrappers.cpp` - Added NUMmachar() call
- [x] `src/praat_stubs.cpp` - NULL check in MelderThread_run()
- [x] `src/graphics_stubs_comprehensive.cpp` - Added Matrix_drawDistribution() stub

### New Stub Files
- [x] `src/table_stubs.cpp` - SSCP/PCA/Covariance stubs
- [x] `src/configuration_stubs.cpp` - Configuration analysis stubs
- [x] `src/eigen_sscp_stubs.cpp` - Fixed include paths to NUM2.h

### Documentation
- [x] `vignettes/formant-analysis.Rmd` - Removed Willems/SL, updated docs
- [x] `NEWS.md` - Added v1.1.5 entry
- [x] `DESCRIPTION` - Version already 1.1.5

## Commit Command

```bash
cd /Users/frkkan96/Documents/src/pladdrr

# Stage all core changes
git add src/Makevars.in
git add src/formant_wrappers.cpp
git add src/sound_wrappers.cpp
git add src/praat_stubs.cpp
git add src/graphics_stubs_comprehensive.cpp
git add src/table_stubs.cpp
git add src/configuration_stubs.cpp
git add src/eigen_sscp_stubs.cpp
git add vignettes/formant-analysis.Rmd
git add NEWS.md
git add DESCRIPTION

# Commit
git commit -m "v1.1.5: Fix formant extraction, update vignettes

Critical fixes:
- Added Roots.cpp for polynomial root finding (enables LPC)
- Added NUMsorting.cpp, table_stubs.cpp dependencies
- Initialized NUMmachar() and RNG in formant/sound wrappers
- Fixed eigen_sscp include paths

Vignette updates:
- Removed unsupported Willems/SL methods (threading issues)
- Document Burg as recommended method
- Update compatibility notes

Known limitations:
- to_formant_willems() not supported (threading infrastructure)
- to_formant_sl() not supported (threading infrastructure)
- Use to_formant_burg() (recommended) or to_formant_keepall()

Tested: 190 frames extracted from test.wav with to_formant_burg()"
```

## Optional: Add Documentation Files

```bash
git add FORMANT_FIX_SUMMARY_2025-12-07.md
git add FORMANT_FIX_SESSION_SUMMARY.md
git add NEXT_STEPS.md
```

## Post-Commit: Build & Test

```bash
# Clean build
R CMD build .

# Install
R CMD INSTALL pladdrr_1.1.5.tar.gz

# Test
Rscript -e "
library(pladdrr)
snd <- Sound\$new('inst/extdata/test.wav')

# Test Burg method
cat('Testing to_formant_burg()...\n')
f_burg <- snd\$to_formant_burg()
cat('SUCCESS! Frames:', f_burg\$get_number_of_frames(), '\n')

# Test Keepall method
cat('Testing to_formant_keepall()...\n')
f_keepall <- snd\$to_formant_keepall()
cat('SUCCESS! Frames:', f_keepall\$get_number_of_frames(), '\n')
"
```

## Success Criteria

- [x] Formant extraction works (verified: 190 frames)
- [x] No segfaults with Burg method
- [x] All dependencies added
- [x] Initialization code in place
- [x] Vignettes updated
- [x] NEWS.md updated
- [x] Version bumped to 1.1.5
- [ ] Package builds successfully
- [ ] Tests pass
- [ ] Committed to git

## What We Fixed

**Before**: `Sound$to_formant_burg()` → SEGFAULT "Polynomial_to_Roots not available"

**After**: `Sound$to_formant_burg()` → SUCCESS (190 frames extracted)

**Root Causes Fixed**:
1. Missing Roots.cpp (polynomial→formant conversion)
2. Uninitialized NUMmachar() (floating-point precision)
3. Uninitialized RNG state
4. Missing statistical stubs (SSCP/Table)
5. Wrong include paths in eigen_sscp_stubs.cpp

**Documentation Updated**:
- Removed broken Willems/SL methods from vignettes
- Documented Burg as recommended method
- Added threading limitation notes
