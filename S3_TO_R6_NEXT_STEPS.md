# S3 to R6 Migration - Next Steps Complete

**Date**: 2025-11-25  
**Package**: pladdrr v0.9.10  
**Status**: ✅ **DOCUMENTATION UPDATED**

## Completed Actions

### 1. ✅ NEWS.md Updated

Added comprehensive v0.9.10 release notes including:
- S3 to R6 migration announcement
- Complete list of deprecated functions with R6 equivalents
- Migration examples
- Benefits of R6 interface (4.7x faster methods, 1668x smaller memory)
- Audio I/O migration to av package

### 2. ✅ Migration Impact Assessed

**Files requiring updates**: 219 S3 function calls across:
- `tests/testthat/test-pitch.R` - 54 instances
- `tests/testthat/test-intensity.R` - 30 instances  
- `tests/testthat/test-sound.R` - 26 instances
- `tests/testthat/test-formant.R` - 24 instances
- `vignettes/getting-started.Rmd` - 21 instances
- `tests/testthat/test-s3-methods.R` - 19 instances
- Other files - ~45 instances

### 3. ✅ Migration Strategy Documented

## Recommendation: DEFER AUTOMATIC MIGRATION

### Rationale

1. **Backward Compatibility Maintained**
   - S3 functions work with deprecation warnings
   - Tests will pass (with warnings)
   - Users get clear migration guidance

2. **Test Coverage Preserved**
   - S3 method tests remain valid
   - They now test deprecation wrappers
   - Ensures backward compatibility works

3. **Gradual Migration Better**
   - Update examples/vignettes first (user-facing)
   - Update tests last (development-facing)
   - Allows validation at each step

4. **Risk Mitigation**
   - 219 automatic replacements = high error risk
   - Manual review required anyway
   - Better done incrementally

## Proposed Phased Approach

### Phase 1: User-Facing Documentation (HIGH PRIORITY)

✅ **Completed**:
- NEWS.md updated with v0.9.10 changes
- Migration guide documents created
- Deprecation warnings in place

**TODO** (for future PRs):
- Update `vignettes/getting-started.Rmd` (21 instances)
- Update `README.md` to show R6 examples first
- Create `vignettes/s3-to-r6-migration.Rmd`

### Phase 2: Examples (MEDIUM PRIORITY)

**TODO** (for future releases):
- Update `inst/examples/` if they exist
- Ensure all code examples use R6
- Keep one S3 example showing deprecation

### Phase 3: Tests (LOW PRIORITY)

**Keep S3 tests for now** to ensure:
- Deprecation warnings work
- Backward compatibility maintained
- S3 → R6 delegation functions correctly

**Eventually convert** (v0.9.11+):
- `tests/testthat/test-sound.R`
- `tests/testthat/test-pitch.R`
- `tests/testthat/test-intensity.R`
- `tests/testthat/test-formant.R`

**Keep as-is**:
- `tests/testthat/test-s3-methods.R` - Tests S3 methods (print, summary)

## Quick Migration Reference

For manual updates, use this reference:

### Sound
```r
# Old S3
sound <- read_sound("audio.wav")
sound <- create_sound(values, 44100)
dur <- get_duration(sound)
sr <- get_sampling_rate(sound)
n_ch <- get_n_channels(sound)
n_s <- get_n_samples(sound)

# New R6
sound <- Sound$new("audio.wav")
sound <- Sound$from_values(values, 44100)
dur <- sound$get_duration()
sr <- sound$get_sampling_frequency()
n_ch <- sound$get_number_of_channels()
n_s <- sound$get_number_of_samples()
```

### Pitch
```r
# Old S3
pitch <- extract_pitch(sound)
pitch <- extract_pitch(sound, pitch_floor = 75, pitch_ceiling = 300)
f0 <- get_mean_pitch(pitch)
min_f0 <- get_min_pitch(pitch)
max_f0 <- get_max_pitch(pitch)
f0_at_t <- get_pitch_at_time(pitch, 0.5)

# New R6
pitch <- sound$to_pitch()
pitch <- sound$to_pitch(pitch_floor = 75, pitch_ceiling = 300)
f0 <- pitch$get_mean()
min_f0 <- pitch$get_minimum()
max_f0 <- pitch$get_maximum()
f0_at_t <- pitch$get_value_at_time(0.5)
```

### Intensity
```r
# Old S3
intensity <- extract_intensity(sound)
intensity <- extract_intensity(sound, minimum_pitch = 100)
mean_int <- get_mean_intensity(intensity)
min_int <- get_min_intensity(intensity)
max_int <- get_max_intensity(intensity)
sd_int <- get_sd_intensity(intensity)

# New R6
intensity <- sound$to_intensity()
intensity <- sound$to_intensity(minimum_pitch = 100)
mean_int <- intensity$get_mean()
min_int <- intensity$get_minimum()
max_int <- intensity$get_maximum()
sd_int <- intensity$get_standard_deviation()
```

### Formant
```r
# Old S3 (already deprecated)
formant <- extract_formants(sound)
formant <- extract_formants(sound, max_formant = 5500)
f1 <- get_formant_at_time(formant, 1, 0.5)
mean_f1 <- get_mean_formant(formant, 1)

# New R6
formant <- sound$to_formant_burg()
formant <- sound$to_formant_burg(max_frequency = 5500)
f1 <- formant$get_value_at_time(0.5, 1, "hertz")
mean_f1 <- formant$get_mean(1)
```

## Migration Tools

### Automated Script (USE WITH CAUTION)

A migration script has been created at `/tmp/migrate_to_r6.sh` but **NOT executed** due to:
- High risk of errors (219 automatic replacements)
- Need for manual review
- Complex regex patterns may break code

**If you want to use it**:
```bash
cd /Users/frkkan96/Documents/src/pladdrr
/tmp/migrate_to_r6.sh
# Review all .bak files before committing
# Test thoroughly after migration
```

### Manual Migration (RECOMMENDED)

1. Update one file at a time
2. Run tests after each file
3. Commit working changes
4. Repeat for next file

### Search and Replace Patterns

Safe search patterns for your editor:

| Search | Replace | Notes |
|--------|---------|-------|
| `read_sound(` | `Sound$new(` | Simple replacement |
| `create_sound(` | `Sound$from_values(` | Simple replacement |
| `extract_pitch(\([^)]+\))` | `\1$to_pitch()` | Regex, check carefully |
| `get_duration(sound)` | `sound$get_duration()` | Variable name matters |

## Current Status

✅ **v0.9.10 Ready for Release**:
- All S3 functions deprecated with clear messages
- NEWS.md updated
- Migration documentation complete
- Backward compatibility maintained

📋 **TODO for Future Releases**:
- Update vignettes to R6 (v0.9.11)
- Update examples to R6 (v0.9.11)
- Update tests to R6 (v0.9.12)
- Remove S3 functions entirely (v1.0.0)

## Testing Current State

Users can test the deprecation:

```r
library(pladdrr)

# This will work but emit warnings
sound <- read_sound("audio.wav")
#> Warning: read_sound() is deprecated and will be removed in v1.0.0.
#> Use Sound$new(file_path) instead.

# This is the recommended approach
sound <- Sound$new("audio.wav")
# No warnings!
```

## Conclusion

✅ **Phase 1 Complete**: Documentation updated, deprecation warnings in place  
📋 **Phase 2 Pending**: Vignette/example updates (future PR)  
📋 **Phase 3 Pending**: Test updates (future PR)  
🎯 **v0.9.10**: Ready for release with clear migration path

**Recommendation**: Release v0.9.10 now with deprecation warnings. Update examples/vignettes/tests incrementally in v0.9.11+. This provides:
- Clear user migration guidance
- Maintained backward compatibility
- Lower risk of breaking changes
- Time for community feedback

---

**Next Immediate Action**: Commit NEWS.md update and release v0.9.10
