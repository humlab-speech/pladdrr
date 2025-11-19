# Vignette Build Fix Summary

## Issues Identified

The package build is failing during vignette creation because:

1. **Method name inconsistencies**: Vignettes were using incorrect method names
   - `get_interval_label()` → Should be `get_interval_text()`
   - Named parameters in `insert_boundary()` → Should be positional

2. **Interval counting error**: Creating 5 boundaries creates 6 intervals, not 7

## Fixes Applied

### integrated-phonetic-analysis.Rmd
- Changed `tier_number = 1` to positional `1` in `insert_boundary()` calls
- Changed `interval = N` to positional in `set_interval_text()` calls  
- Changed `tg$get_interval_label()` to `tg$get_interval_text()`

### textgrid-workflows.Rmd
- Changed `tg$set_interval_label()` to `tg$set_interval_text()`
- Removed 7th interval label (only 6 intervals created)

### vowel-space-analysis.Rmd
- Changed `tg$set_interval_label()` to `tg$get_interval_text()`

## Build Instructions

The vignettes require the updated package to be installed first.

### Option 1: Build without vignettes first
```bash
cd /Users/frkkan96/Documents/src/speaker
R CMD build . --no-build-vignettes
R CMD INSTALL speaker_*.tar.gz
# Then rebuild with vignettes
R CMD build .
```

###  Option 2: Use devtools
```R
devtools::install(build_vignettes = FALSE)
devtools::build_vignettes()
```

### Option 3: Build with current installation
If the package is already installed with the ptr fixes:
```bash
R CMD build .
```

## Status

- ✅ All method name corrections applied
- ✅ Parameter corrections applied
- ✅ Interval counting fixed
- ⏳ Waiting for package installation to complete before vignette build
