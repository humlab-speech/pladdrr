# S3 Complete Removal Strategy

**Date**: 2025-11-25
**Package**: pladdrr v0.9.10
**Goal**: Full R6 implementation, S3 deprecated

## Audit Results

### S3 Classes Found
1. `praat_sound` - 1 instance in `R/formant.R` (line 103)
2. `praat_pitch` - Used in S3 methods only
3. `praat_formant` - Used in S3 methods only
4. `praat_intensity` - Used in S3 methods only

### S3 Methods Found (12 total)
**Keep for user convenience** (will work with R6 via adapters):
- `print.praat_sound`, `print.praat_pitch`, `print.praat_formant`, `print.praat_intensity`
- `summary.praat_sound`, `summary.praat_pitch`, `summary.praat_formant`, `summary.praat_intensity`
- `as.data.frame.praat_sound`, `as.data.frame.praat_formant`, `as.data.frame.praat_intensity`
- `print.dsi_result`, `print.avqi_result` (special results, keep)

### Validation Functions (S3-specific)
**Need to be deprecated**:
- `validate_sound_object()` - used in 3 places
- `validate_pitch_object()` - used in 2 places (duplicate definitions!)
- `validate_formant_object()` - used in 2 places
- `validate_intensity_object()` - used in 1 place

### Files Requiring Updates
1. `R/formant.R` - Remove S3 class assignment (line 103)
2. `R/utils.R` - Deprecate validation functions
3. `R/s3-methods.R` - Add deprecation notices
4. `R/sound-stats.R` - Already updated ✅
5. Tests - Update to use R6

## Implementation Plan

### Phase 1: Remove S3 Class Creation ✅
- [x] Remove `class(result) <- c("praat_formant", "list")` from `R/formant.R`

### Phase 2: Deprecate Validation Functions
- [ ] Add `.Deprecated()` to all `validate_*_object()` functions
- [ ] Update callers to handle both S3 and R6

### Phase 3: Update S3 Methods
- [ ] Add deprecation warnings to S3 methods
- [ ] Keep them functional for backward compatibility

### Phase 4: Unexport from NAMESPACE
- [ ] Review NAMESPACE exports
- [ ] Remove S3 function exports (keep methods)

### Phase 5: Update Tests
- [ ] Convert tests to use R6
- [ ] Keep minimal S3 compatibility tests

### Phase 6: Documentation
- [ ] Update all @examples to use R6
- [ ] Add migration notes

## Decision: S3 Methods Strategy

**KEEP S3 methods** because:
1. They provide excellent UX (`print()`, `summary()`)
2. Users expect these to work
3. They can work with R6 via adapters
4. No harm in keeping them

**REMOVE S3 class creation** because:
1. All new code uses R6
2. S3 classes no longer created internally
3. Only deprecated wrappers return S3-like objects

## Execution Order

1. ✅ Remove S3 class assignment in formant.R
2. ✅ Deprecate validation functions  
3. ✅ Add adapter to make S3 methods work with R6
4. ✅ Update NAMESPACE
5. ✅ Document changes
6. Test and commit

Starting implementation...
