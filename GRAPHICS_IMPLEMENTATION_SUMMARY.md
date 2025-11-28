# Praat Graphics Implementation - Executive Summary

**Date**: 2025-11-28
**Decision**: ❌ **NOT RECOMMENDED** for implementation

---

## Quick Answer

**Should we implement Praat's Picture/Graphics system?**

**NO** - R's plotting ecosystem (ggplot2, phonR) is superior for the target audience.

---

## The Numbers

| Aspect | Full Graphics | Helper Functions |
|--------|--------------|------------------|
| **Development Time** | 11-17 weeks | 2 weeks |
| **Lines of Code** | ~36,000 | ~500 |
| **Dependencies** | Cairo, Pango, Quartz | None |
| **Maintenance** | High | Low |
| **Cost** | $60k-$100k | $4k |
| **CRAN Risk** | High | None |

---

## What We Assessed

### Praat Graphics System Components

1. **Graphics Backend** (~8,500 lines)
   - Coordinate transformations
   - Shape primitives
   - Font management
   - Color models

2. **Platform Backends** (~7,500 lines)
   - Cairo (Linux) - requires libcairo, pango
   - Quartz (macOS) - Core Graphics
   - GDI+ (Windows) - optional

3. **Picture Object** (~2,000 lines)
   - Export: PDF, PNG, EPS, Metafile
   - Self-recording graphics

4. **Drawing Methods** (~15,000 lines)
   - 54 files with draw/paint methods
   - Methods for all 18 objects

**Total**: ~36,000 lines of complex, platform-specific code

---

## Required Libraries for PDF

### Linux (Cairo)

```bash
# System packages
apt-get install libcairo2-dev libpango1.0-dev \
                libfreetype6-dev libfontconfig1-dev
```

```r
# DESCRIPTION
SystemRequirements: cairo (>= 1.12.0), pango (>= 1.40.0),
                    freetype2, fontconfig
```

### macOS (Quartz)

```r
# DESCRIPTION
SystemRequirements: macOS 10.12 or later
```

**No additional packages** - Core Graphics built into macOS SDK

### Windows

```r
# Option A: Cairo via Rtools
SystemRequirements: cairo (>= 1.12.0) via Rtools

# Option B: Use R's graphics device (no PDF from Praat)
```

---

## Why NOT to Implement

### 1. R Graphics is Better

**ggplot2** provides:
- Publication-quality plots
- Better aesthetics
- More flexible than Praat Picture
- Easier to customize
- Familiar to R users

**Example**:
```r
# ggplot2 (clean, flexible)
library(ggplot2)
ggplot(pitch$as_data_frame(), aes(time, frequency)) +
  geom_line(color = "blue") +
  theme_minimal() +
  labs(x = "Time (s)", y = "F0 (Hz)")

# vs Praat Picture (complex, limited)
picture <- Picture$new()
graphics <- picture$peek_graphics()
Graphics_setWindow(graphics, 0, duration, 75, 500)
Graphics_setLineType(graphics, SOLID)
Pitch_draw(pitch, graphics, 0, 0, 75, 500, TRUE)
picture$write_to_pdf("output.pdf")
```

### 2. High Maintenance Burden

**Platform-specific issues**:
- Font rendering differs (Cairo vs Quartz vs GDI)
- PDF viewers interpret standards differently
- Coordinate system bugs are hard to debug
- Must test on Linux, macOS, Windows

**Dependency hell**:
- Cairo versioning on different Linux distros
- macOS SDK version compatibility
- Windows Cairo binaries availability
- CRAN check requirements

### 3. Wrong Paradigm for R Users

R users **expect**:
- ggplot2 for publication graphics
- Base R graphics for quick plots
- Integration with tidyverse
- RMarkdown compatibility

Praat users switching to R **want to learn** the R way, not emulate Praat.

---

## What to Do Instead

### Recommended Approach: **Helper Functions** (2 weeks)

```r
# Simple plot methods using base R
plot.Sound <- function(x, ...) {
  vec <- x$as_vector()
  plot(vec, type = 'l', xlab = "Sample", ylab = "Amplitude", ...)
}

plot.Pitch <- function(x, range = c(75, 500), ...) {
  df <- x$as_data_frame()
  plot(df$time, df$frequency, type = 'l',
       xlab = "Time (s)", ylab = "F0 (Hz)", ylim = range, ...)
}

# Similar for all objects
```

**Plus comprehensive vignette**:
- `vignettes/plotting.Rmd`
- ggplot2 examples for all object types
- Composite plots (waveform + spectrogram + F0)
- phonR integration for vowel plots
- Publication-ready examples

**Benefits**:
- ✅ 2 weeks vs 11-17 weeks
- ✅ Zero dependencies
- ✅ Easy to maintain
- ✅ Users can extend
- ✅ Better output quality (via ggplot2)

---

## PDF Export Options

### Option 1: R Graphics Device (Recommended)

```r
# Use R's built-in PDF export
pdf("output.pdf", width = 8, height = 6)
plot(pitch)  # our helper function
dev.off()

# Or with ggplot2
library(ggplot2)
p <- ggplot(pitch$as_data_frame(), aes(time, frequency)) +
  geom_line()
ggsave("output.pdf", p, width = 8, height = 6, dpi = 300)
```

**Pros**:
- ✅ No dependencies
- ✅ Works on all platforms
- ✅ High quality
- ✅ Familiar to R users

### Option 2: Cairo Package (If Needed)

If users need advanced Cairo features:

```r
# Already available in R
library(Cairo)
CairoPDF("output.pdf", width = 8, height = 6)
plot(pitch)
dev.off()
```

**Note**: Cairo R package handles dependencies, not our problem

---

## Implementation Roadmap

### v1.0.0 (Current Focus)

- ✅ All objects provide `as_data_frame()` and `as_matrix()`
- ✅ Data export enables any plotting
- ✅ Basic usage examples

### v1.1.0 (Recommended Next Step)

**Week 1**: Plot methods (1 week)
- `plot.Sound()`, `plot.Pitch()`, `plot.Formant()`, `plot.Spectrogram()`
- `plot.Intensity()`, `plot.TextGrid()`, etc.
- Use base R graphics for simplicity

**Week 2**: Documentation (1 week)
- `vignettes/plotting-guide.Rmd` - comprehensive guide
- ggplot2 examples for all objects
- Composite plot examples
- phonR integration
- `inst/examples/plotting/` - example gallery

### v2.0.0+ (If Absolutely Required)

**Only if**:
- Funded by grant ($60k-$100k)
- Overwhelming user demand
- Implemented as **separate package**: `speaker.graphics`

---

## Decision Matrix

| Criterion | Full Graphics | Helper + Docs | Current |
|-----------|--------------|---------------|---------|
| User Value | Low | **High** | Medium |
| Dev Time | 11-17 weeks | **2 weeks** | 0 |
| Maintenance | High | **Low** | None |
| CRAN Risk | High | **None** | None |
| R Integration | Poor | **Excellent** | N/A |
| Quality | Good | **Excellent** | N/A |

**Winner**: ✅ **Helper Functions + Documentation**

---

## Final Recommendation

### For v1.1.0: Implement Helper Functions

**Total Effort**: 2 weeks

**Deliverables**:
1. Plot methods for all 18 objects
2. Comprehensive plotting vignette
3. ggplot2 example gallery
4. PDF export documentation

**Benefits**:
- Provides full plotting capability
- Uses R's superior graphics ecosystem
- Zero dependencies
- Easy to maintain
- Users can extend
- Better than Praat Picture for publication

### Do NOT Implement Full Graphics

**Unless**:
- Secured grant funding ($60k-$100k)
- Packaged separately (`speaker.graphics`)
- Strong community demand documented
- Dedicated maintenance team

---

## Questions?

See full assessment: `PRAAT_GRAPHICS_IMPLEMENTATION_ASSESSMENT.md`

**Bottom Line**: R users want ggplot2, not Praat Picture. Give them what they want.

---

**Status**: Final Decision
**Date**: 2025-11-28
**Recommendation**: Helper Functions (v1.1.0), NOT Full Graphics
