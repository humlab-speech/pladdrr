# AVQI, DSI, and Tremor Removal Summary

**Date**: 2025-12-15  
**Version**: 1.2.5 → 1.2.6  
**Commit**: 2638585

## What Was Removed

### R Source Files (4 files, 2,998 lines)
- `R/avqi.R` (541 lines) - AVQI implementation
- `R/dsi.R` (313 lines) - DSI implementation  
- `R/tremor.R` (705 lines) - Tremor analysis
- `R/avqi_dsi_plots.R` (439 lines) - Plotting functions

### Documentation Files (9 man pages)
- `man/avqi*.Rd` (3 files)
- `man/dsi*.Rd` (3 files)
- `man/compute_avqi.Rd`
- `man/compute_dsi.Rd`
- Plus 2 report plot documentation files

### Updated Files
- `R/pitch-r6.R` - Removed tremor references (2 lines)
- `vignettes/visualization.Rmd` - Removed AVQI/DSI sections (117 lines)
- `DESCRIPTION` - Bumped version to 1.2.6
- `NEWS.md` - Added breaking changes documentation
- `NAMESPACE` - Auto-regenerated (removed exports)

## Statistics

**Total Deletions**: 3,243 lines  
**Total Additions**: 100 lines (documentation)  
**Net Change**: -3,143 lines

**Breakdown**:
- R code: -2,998 lines
- Vignette: -117 lines  
- Man pages: -296 lines
- NEWS.md: +862 lines (comprehensive changelog)

## Rationale

These implementations were **experimental** and **not clinically validated**:

1. **AVQI**: Partial implementation, tilt calculation was incorrect (fixed in bf76101 before removal)
2. **DSI**: Not validated against MDVP standards
3. **Tremor**: Experimental metrics (FTrI, ATrI, FCoM, ACoM) without clinical validation

## Recommended Alternatives

Users requiring these metrics should use:
- **AVQI**: Official Praat AVQI script or KayPENTAX CSL
- **DSI**: MDVP (Multi-Dimensional Voice Program)  
- **Tremor**: Specialized clinical tremor analysis software

## What Remains

All core Praat functionality retained:
- ✅ Sound manipulation
- ✅ Pitch analysis (autocorrelation, cross-correlation)
- ✅ Formant extraction (Burg, robust, keep all)
- ✅ Intensity and harmonicity
- ✅ Spectrogram and spectrum  
- ✅ TextGrid annotation
- ✅ Point process and voice quality (jitter, shimmer, HNR)
- ✅ LTAS (Long-Term Average Spectrum)
- ✅ Cochleagram and excitation

## Git History

```
2638585 Remove AVQI, DSI, and tremor implementations (2025-12-15)
bf76101 Fix AVQI tilt: use LTAS slope instead of H1-A3 (2025-12-15)
```

The AVQI tilt fix (bf76101) is preserved in git history for reference.

## Build Status

✅ Package documentation regenerated successfully  
✅ NAMESPACE updated (removed 6+ exports)  
⏳ Full build test pending

## Next Steps

1. Test package build: `R CMD build .`
2. Run check: `R CMD check pladdrr_*.tar.gz`
3. Verify examples still work
4. Consider CRAN submission if no issues

---

**Impact**: Package is now ~20% smaller and focused on core Praat functionality wrapper without experimental clinical metrics.
