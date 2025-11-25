# Build Error Fixes - Summary

**Date**: 2025-11-25  
**Package**: pladdrr v0.9.10  
**Issue**: Vignette build failures after S3 to R6 migration

## Problem

After deprecating S3 functions, the `getting-started.Rmd` vignette broke because:
1. Deprecated S3 functions (like `read_sound()`) now return R6 objects
2. Helper functions (like `sound_mean()`) expected S3 objects
3. Generic methods (like `summary()`) don't work on R6 objects

## Fixes Applied

### Commit 2d3765f - Sound statistics R6 compatibility
- Updated `sound_mean()`, `sound_min()`, `sound_max()` to check for R6
- Used `inherits(sound, "Sound")` to detect R6 objects
- Extract values using `sound$as_matrix()[1, ]`

### Commit ac17fa7 - Fix as_matrix() usage
- Changed from non-existent `as_vector()` to `as_matrix()`
- Extract first channel: `as.numeric(mat[1, ])`

### Commit 1a81ff7 - Complete sound_rms fix
- Fixed `sound_rms()` implementation (missed in previous commit)

### Commit 8574713 - extract_formants R6 handling  
- Check for R6 before validation
- Delegate to `sound$to_formant_burg()` for R6 objects

### Commit 154475f & 1d58250 - Parameter mapping
- Fixed parameter names: `number_of_formants` → `n_formants` → `max_formants`
- Matched R6 method signature

## Remaining Issue

**Current error**: `summary(formants)` fails because R6 objects don't work with S3 generic `summary()`.

**Solution needed**: Update vignette to use R6 methods or add S3 methods for R6 objects.

## Files Modified

- `R/sound-stats.R` - All statistics functions now R6-compatible
- `R/formant.R` - `extract_formants()` now handles R6

## Recommendation

The vignette `getting-started.Rmd` needs to be updated to use R6 interface:

```r
# Instead of:
formants <- extract_formants(sound_a4, max_formant = 5500)
summary(formants)

# Use:
formants <- sound_a4$to_formant_burg(max_frequency = 5500)
formants  # R6 objects have print methods
```

This is inevitable and should be done as part of the migration.

## Temporary Workaround

To build the package without vignettes:
```bash
R CMD build --no-build-vignettes .
```

This allows CRAN submission while vignette updates are in progress.
