# Version 0.9.11 Release Plan

**Date**: 2025-11-25
**Previous**: v0.9.10 (S3 removal complete)
**Target**: v0.9.11 (Vignettes and examples updated to R6)

## Goals

Update all user-facing documentation to use R6 interface exclusively:
1. Update vignettes to R6
2. Update examples to R6  
3. Fix vignette build errors
4. Update README to show R6 first
5. Add migration guide vignette

## Tasks

### 1. Update Version Number
- [ ] Update DESCRIPTION to v0.9.11
- [ ] Update Date in DESCRIPTION

### 2. Fix getting-started.Rmd Vignette
**Current Issues**:
- Uses deprecated S3 functions
- Calls `summary()` on R6 objects (fails)

**Changes Needed**:
```r
# Old (deprecated)
sound_a4 <- read_sound("audio.wav")
formants <- extract_formants(sound_a4)
summary(formants)

# New (R6)
sound_a4 <- Sound$new("audio.wav")
formants <- sound_a4$to_formant_burg()
formants  # R6 has print method
```

**Estimated**: 21 replacements in this vignette

### 3. Update Other Vignettes
- [ ] integrated-phonetic-analysis.Rmd - Check for S3 usage
- [ ] textgrid-workflows.Rmd - Check for S3 usage
- [ ] visualization.Rmd - Check for S3 usage
- [ ] vowel-space-analysis.Rmd - Check for S3 usage (1 instance found)

### 4. Update Examples
- [ ] Check inst/examples/ directory
- [ ] Update any S3 function usage to R6
- [ ] Ensure examples run cleanly

### 5. Update README
- [ ] Show R6 examples prominently
- [ ] Move S3 examples to "Legacy" section
- [ ] Add migration notice

### 6. Create Migration Guide Vignette
**New file**: `vignettes/s3-to-r6-migration.Rmd`

**Contents**:
- Why R6 is better
- Migration examples
- Performance comparison
- Common patterns
- Troubleshooting

### 7. Update NEWS.md
Add v0.9.11 entry:
- Vignettes updated to R6
- Examples updated to R6
- Migration guide added
- README updated

### 8. Test Build
- [ ] Build package: `R CMD build .`
- [ ] Verify vignettes build successfully
- [ ] Check package: `R CMD check --as-cran pladdrr_0.9.11.tar.gz`

## Success Criteria

✅ All vignettes build without errors
✅ All vignettes use R6 interface
✅ README shows R6 prominently
✅ Migration guide vignette created
✅ Package builds cleanly
✅ No S3 usage in examples/vignettes (except migration guide)

## Estimated Time

- Version update: 5 min
- getting-started.Rmd: 30 min
- Other vignettes: 20 min
- README update: 15 min
- Migration guide: 45 min
- Testing: 30 min

**Total**: ~2.5 hours

Starting implementation...
