# Praat Graphics System Implementation Assessment

**Date**: 2025-11-28
**Package**: pladdrr (speaker)
**Version**: 0.4.1+
**Status**: Feasibility Analysis for Future Release

---

## Executive Summary

This document assesses the feasibility of implementing Praat's Picture/Graphics plotting subsystem in the `speaker` R package for a future release (v2.0+).

### Key Findings

1. **Feasibility**: ✅ Technically feasible but resource-intensive
2. **Recommendation**: ⚠️ **NOT RECOMMENDED** - R graphics ecosystem is superior
3. **Estimated Effort**: 8-12 weeks full-time development
4. **Maintenance Cost**: High (platform-specific bugs, ongoing updates)
5. **Better Alternative**: Leverage R's ggplot2 + phonR + custom helpers

---

## 1. Current Graphics Status

### What's Implemented ✅

- **Graphics stubs**: All graphics functions stubbed in `src/graphics_stubs_comprehensive.cpp`
- **NO_GRAPHICS build**: Package compiles and runs without graphics subsystem
- **Object exports**: All analysis objects provide `as_data_frame()` and `as_matrix()` methods
- **Data availability**: Full access to underlying numerical data for plotting

### What's Missing ❌

- **Picture window**: No Praat Picture window equivalent
- **Drawing commands**: `Draw...`, `Paint...`, `Speckle...` methods not functional
- **Interactive plots**: No click-to-select, manual annotation
- **Direct PDF generation**: Cannot use Praat's `Save as PDF file...` command

---

## 2. Praat Graphics Architecture

### Core Components

#### 2.1 Graphics Device Backend (~8,500 lines)

**Files**:
- `sys/Graphics.cpp` (2,700 lines) - Core graphics primitives
- `sys/Graphics_text.cpp` (1,500 lines) - Text rendering
- `sys/Graphics_linesAndAreas.cpp` (800 lines) - Lines, polygons
- `sys/Graphics_image.cpp` (600 lines) - Raster images
- `sys/Graphics_colour.cpp` (400 lines) - Color management
- `sys/GraphicsPostscript.cpp` (1,500 lines) - PostScript backend
- `sys/GraphicsScreen.cpp` (1,000 lines) - Screen rendering

**Functionality**:
- Coordinate transformations (NDC → DC → WC)
- Viewport management
- Font management (multiple encodings)
- Color models (RGB, grey, HSV)
- Line styles, widths, arrow heads
- Shape primitives (lines, arcs, ellipses, polygons)
- Text layout and rendering
- Image rendering (raster, contour, surface)

#### 2.2 Platform-Specific Backends

**Cairo (Linux)** - ~3,000 lines:
- Uses `libcairo` for 2D graphics
- PDF, PNG, SVG export via Cairo surfaces
- Font rendering via Pango
- Anti-aliasing, sub-pixel rendering

**Quartz (macOS)** - ~2,500 lines:
- Uses Core Graphics (Quartz 2D)
- Native PDF generation (CGPDFContext)
- Native font rendering (CoreText)
- High-quality anti-aliasing

**GDI/GDI+ (Windows)** - ~2,000 lines:
- Uses Windows GDI/GDI+ API
- Metafile export (EMF)
- TrueType font handling
- Screen and printer contexts

#### 2.3 Picture Object (~2,000 lines)

**Files**:
- `sys/Picture.cpp` (600 lines)
- `sys/Picture.h` (115 lines)
- `fon/manual_Picture.cpp` (1,200 lines) - Drawing methods for objects

**Functionality**:
- Self-recording Graphics wrapper
- Selection management (viewport)
- Export to multiple formats:
  - EPS (Encapsulated PostScript)
  - PDF (via Cairo on Linux, Quartz on macOS)
  - PNG (raster at 300 or 600 DPI)
  - Praat Picture file format
  - Windows Metafile (EMF)
  - macOS clipboard (PICT)

#### 2.4 Object Drawing Methods (~15,000 lines)

**54 source files** with drawing methods for Praat objects:

- Sound: `Sound_draw()`, `Sound_paint()`
- Pitch: `Pitch_draw()`, `Pitch_speckle()`
- Formant: `Formant_draw()`, `Formant_speckle()`
- Spectrogram: `Spectrogram_paint()`
- Intensity: `Intensity_draw()`
- TextGrid: `TextGrid_draw()`
- PointProcess: `PointProcess_draw()`
- And ~50 more methods across all objects

**Total**: ~50 drawing method declarations in headers

---

## 3. PDF Generation Libraries

### Required for Full Implementation

#### 3.1 Cairo (Linux/Cross-Platform)

**Library**: `libcairo2-dev`

**Capabilities**:
```cpp
// Create PDF surface
cairo_surface_t *surface = cairo_pdf_surface_create(
    "output.pdf",
    width_inches * 72.0,
    height_inches * 72.0
);
cairo_t *cr = cairo_create(surface);

// Draw graphics
cairo_move_to(cr, x, y);
cairo_line_to(cr, x2, y2);
cairo_stroke(cr);

// Text rendering
cairo_select_font_face(cr, "Sans", ...);
cairo_show_text(cr, "Hello");

// Cleanup
cairo_destroy(cr);
cairo_surface_destroy(surface);
```

**Dependencies**:
- `libcairo2` - 2D graphics library
- `libpango1.0-dev` - Text layout and rendering
- `libfreetype6-dev` - Font engine
- `libfontconfig1-dev` - Font configuration

**Package Requirements** (DESCRIPTION):
```
SystemRequirements: cairo (>= 1.12), pango (>= 1.40), freetype2, fontconfig
```

#### 3.2 Quartz (macOS Native)

**Framework**: Core Graphics (built-in)

**Capabilities**:
```cpp
// Create PDF context
CGContextRef context = CGPDFContextCreateWithURL(
    fileURL,
    &pageRect,
    NULL
);

CGContextBeginPage(context, &pageRect);

// Draw graphics
CGContextMoveToPoint(context, x, y);
CGContextAddLineToPoint(context, x2, y2);
CGContextStrokePath(context);

// Text rendering via CoreText
CTLineDraw(line, context);

// Cleanup
CGContextEndPage(context);
CGContextRelease(context);
```

**Dependencies**: None (part of macOS SDK)

#### 3.3 Windows GDI+ (Optional)

**Library**: `gdiplus.lib` (part of Windows SDK)

**Capabilities**:
- Metafile export (EMF, WMF)
- Limited PDF export (via third-party libraries)
- Typically not used for PDF generation

**Note**: Windows users would likely rely on Cairo or R's graphics device

---

## 4. Implementation Complexity Analysis

### 4.1 Full Implementation Effort

| Component | Lines of Code | Effort (weeks) | Difficulty |
|-----------|--------------|----------------|------------|
| Graphics backend | 8,500 | 3-4 | High |
| Platform backends | 7,500 | 2-3 | Very High |
| Picture object | 2,000 | 1 | Medium |
| R integration layer | 3,000 | 1-2 | High |
| Drawing methods (18 objects) | 15,000 | 3-4 | Medium |
| Testing & validation | N/A | 1-2 | High |
| **TOTAL** | **~36,000** | **11-17 weeks** | **Very High** |

### 4.2 Challenges

#### Technical Challenges

1. **Platform Dependencies**:
   - Must support Linux (Cairo), macOS (Quartz), Windows (GDI+)
   - Different font rendering engines
   - Different coordinate systems
   - Cross-platform testing required

2. **R Graphics Integration**:
   - R has native graphics devices (X11, Quartz, Windows)
   - Praat uses different coordinate paradigm (NDC)
   - Need translation layer for R users
   - Conflicts with ggplot2/grid graphics

3. **Memory Management**:
   - Graphics contexts must be properly finalized
   - Cairo/Quartz contexts require manual cleanup
   - Risk of memory leaks with complex plots
   - XPtr finalizers for Graphics objects

4. **Font Handling**:
   - Praat uses custom font encoding (PraatEncoding)
   - Different font subsetting across platforms
   - IPA phonetic symbols require Unicode support
   - Font embedding in PDFs

#### Maintenance Challenges

1. **Platform-Specific Bugs**:
   - Graphics bugs are notoriously platform-dependent
   - Font rendering differs across systems
   - PDF viewers interpret standards differently
   - Continuous testing on all platforms required

2. **Dependency Management**:
   - Cairo/Pango versioning on Linux
   - macOS SDK version compatibility
   - CRAN check requirements (SystemRequirements)
   - User installation burden (libcairo-dev, etc.)

3. **Code Complexity**:
   - Graphics code is inherently complex
   - Coordinate transformations error-prone
   - Hard to debug visual issues
   - Large test surface area

---

## 5. Alternative: R Graphics Ecosystem

### Why R Graphics is Superior

#### 5.1 Mature Ecosystem

**Base R Graphics**:
```r
# Simple waveform plot
plot(sound$as_vector(), type = 'l',
     xlab = "Sample", ylab = "Amplitude")

# Spectrogram
spec_matrix <- spectrogram$as_matrix()
image(spec_matrix, col = heat.colors(256),
      xlab = "Time", ylab = "Frequency")
```

**ggplot2** (Publication Quality):
```r
library(ggplot2)

# F0 contour
pitch_df <- pitch$as_data_frame()
ggplot(pitch_df, aes(time, frequency)) +
  geom_line(color = "blue") +
  theme_minimal() +
  labs(title = "Fundamental Frequency",
       x = "Time (s)", y = "F0 (Hz)")

# Formant plot with multiple traces
formant_df <- formant$as_data_frame()
ggplot(formant_df, aes(time, frequency,
                       color = factor(formant_number))) +
  geom_line() +
  scale_color_brewer(palette = "Set1", name = "Formant") +
  theme_bw()
```

#### 5.2 Specialized Phonetics Packages

**phonR** - Vowel plots:
```r
library(phonR)

# F1-F2 vowel space
plotVowels(formants$F1, formants$F2, formants$vowel,
           plot.tokens = TRUE,
           ellipse.line = TRUE,
           pretty = TRUE)
```

**emuR** - EMU-SDMS visualizations:
```r
library(emuR)

# Spectrogram with formant overlay
# (specialized phonetic visualizations)
```

**phonTools** - Speech-specific plots:
```r
library(phonTools)

# F0 tracking, spectrograms, formant plots
```

#### 5.3 Composite Plots with patchwork

```r
library(patchwork)

# Waveform + Spectrogram + F0 composite
p1 <- ggplot(sound_df, aes(time, amplitude)) + geom_line()
p2 <- ggplot(spec_df, aes(time, freq, fill = power)) + geom_tile()
p3 <- ggplot(pitch_df, aes(time, f0)) + geom_line()

(p1 / p2 / p3) + plot_layout(heights = c(1, 2, 1))
```

#### 5.4 PDF Export (Native R)

```r
# High-quality PDF export
pdf("output.pdf", width = 8, height = 6)
print(my_plot)
dev.off()

# Or with ggplot2
ggsave("output.pdf", plot = my_plot,
       width = 8, height = 6, dpi = 300)
```

**Benefits**:
- ✅ No additional dependencies
- ✅ Works identically on all platforms
- ✅ Full R integration (tidyverse, RMarkdown)
- ✅ Publication-quality output
- ✅ Users already familiar with R plotting

---

## 6. Minimal Implementation Option

### If Graphics Support is Absolutely Required

#### 6.1 Minimal Picture Object (~2 weeks)

**Approach**: Implement Picture object with R graphics device backend only

**Scope**:
- Picture R6 class wrapping R graphics device
- Export methods: `to_pdf()`, `to_png()`, `to_svg()`
- NO platform-specific backends (Cairo/Quartz)
- Use R's internal PDF device

**Implementation**:

```r
# R/picture-r6.R
Picture <- R6Class("Picture",
  public = list(
    initialize = function(width = 8, height = 6, unit = "in") {
      private$width <- width
      private$height <- height
      private$device <- list()
    },

    to_pdf = function(file) {
      pdf(file, width = private$width, height = private$height)
      private$replay()
      dev.off()
    },

    add_plot = function(plot_fn) {
      private$device <- c(private$device, plot_fn)
    }
  ),

  private = list(
    width = NULL,
    height = NULL,
    device = NULL,
    replay = function() {
      for (fn in private$device) fn()
    }
  )
)
```

**Usage**:
```r
pic <- Picture$new(width = 10, height = 8)

# Add plots using R graphics
pic$add_plot(function() {
  plot(sound$as_vector(), type = 'l')
})

pic$add_plot(function() {
  pitch_df <- pitch$as_data_frame()
  lines(pitch_df$time, pitch_df$frequency, col = "blue")
})

# Export
pic$to_pdf("output.pdf")
```

**Pros**:
- ✅ Minimal implementation (2 weeks)
- ✅ Pure R, no external dependencies
- ✅ Cross-platform by default
- ✅ Works with all R plotting packages

**Cons**:
- ❌ Not true Praat Picture window
- ❌ Limited to R graphics primitives
- ❌ No Praat-specific drawing commands

#### 6.2 Helper Functions Approach (~1 week)

**Even simpler**: Provide convenience plotting functions

```r
# R/plot_helpers.R

#' Plot Sound waveform
#' @export
plot.Sound <- function(x, channel = 1, ...) {
  vec <- x$as_vector(channel = channel)
  duration <- x$get_duration()
  time <- seq(0, duration, length.out = length(vec))

  plot(time, vec, type = 'l',
       xlab = "Time (s)", ylab = "Amplitude",
       main = "Sound Waveform", ...)
}

#' Plot Pitch contour
#' @export
plot.Pitch <- function(x, range = NULL, ...) {
  df <- x$as_data_frame()

  if (!is.null(range)) {
    df <- df[df$frequency >= range[1] & df$frequency <= range[2], ]
  }

  plot(df$time, df$frequency, type = 'l',
       xlab = "Time (s)", ylab = "F0 (Hz)",
       main = "Pitch Contour", col = "blue", ...)
}

#' Plot Spectrogram
#' @export
plot.Spectrogram <- function(x, freq_range = NULL,
                             dynamic_range = 70, ...) {
  mat <- x$as_matrix()

  image(mat, col = rev(heat.colors(256)),
        xlab = "Time (s)", ylab = "Frequency (Hz)",
        main = "Spectrogram", ...)
}
```

**Pros**:
- ✅ Very quick to implement (1 week)
- ✅ Familiar R interface
- ✅ Users can extend easily
- ✅ Zero maintenance burden

**Cons**:
- ❌ Not comprehensive
- ❌ Limited customization
- ❌ Not Praat-compatible

---

## 7. Recommendation

### Primary Recommendation: **Do Not Implement Full Graphics** ❌

**Rationale**:

1. **R has superior plotting**: ggplot2, phonR, emuR are better tools
2. **High implementation cost**: 11-17 weeks for full system
3. **High maintenance burden**: Platform-specific bugs, dependencies
4. **User expectation**: R users expect ggplot2, not Praat Picture
5. **Better alternatives exist**: Helper functions + documentation

### Secondary Recommendation: **Provide Plotting Helpers** ✅

**Approach**:

1. **Add plot methods** for all objects (~1 week):
   - `plot.Sound()`, `plot.Pitch()`, `plot.Formant()`, etc.
   - Use base R graphics for simplicity
   - Provide ggplot2 examples in documentation

2. **Create comprehensive vignette** (~3 days):
   - `vignettes/plotting.Rmd`
   - Show ggplot2 patterns for all object types
   - Demonstrate composite plots (waveform + spectrogram + pitch)
   - Examples with phonR for vowel plots
   - PDF export with `ggsave()`

3. **Provide example gallery** (~2 days):
   - `inst/examples/plotting/`
   - Reproduce common Praat Picture window plots in ggplot2
   - Side-by-side Praat vs. ggplot2 comparisons
   - Publication-ready examples

**Total effort**: ~2 weeks vs. 11-17 weeks for full implementation

---

## 8. Implementation Roadmap (If Proceeding with Full Graphics)

### Only if absolutely required and funded

#### Phase 1: Foundation (3-4 weeks)

**Goal**: Graphics backend without platform specifics

- Implement core Graphics class (R6 wrapper)
- Coordinate transformation system
- Basic primitives (line, rectangle, text)
- R graphics device backend
- Test on single platform

**Deliverables**:
- `R/graphics-r6.R` - Graphics R6 class
- `src/graphics_backend.cpp` - C++ backend
- Basic plot methods for Sound, Pitch

#### Phase 2: PDF Export (2-3 weeks)

**Goal**: PDF generation via Cairo (Linux) and Quartz (macOS)

**Linux** (Cairo):
- Install and link libcairo
- Implement `Graphics_create_pdffile()` wrapper
- Font handling via Pango
- Test PDF output quality

**macOS** (Quartz):
- Use Core Graphics (CGPDFContext)
- Native font rendering
- Test on multiple macOS versions

**Windows**:
- Use Cairo (via Rtools or pre-built binaries)
- Or defer to R's graphics device

**Deliverables**:
- Cairo PDF backend
- Quartz PDF backend
- Cross-platform testing

#### Phase 3: Drawing Methods (3-4 weeks)

**Goal**: Implement drawing methods for all objects

- Sound: `draw()`, `paint()`
- Pitch: `draw()`, `speckle()`
- Formant: `draw_tracks()`, `speckle()`
- Spectrogram: `paint()`
- TextGrid: `draw()`
- And ~13 more objects

**Deliverables**:
- Drawing methods for 18 objects
- Validation against Praat desktop output

#### Phase 4: Picture Integration (1-2 weeks)

**Goal**: Picture object for compositing

- Picture R6 class
- Multi-layer drawing
- Viewport management
- Export methods (PDF, PNG, EPS)

**Deliverables**:
- `R/picture-r6.R`
- `src/picture_wrappers.cpp`
- Export to multiple formats

#### Phase 5: Testing & Documentation (2-3 weeks)

**Goal**: Comprehensive testing and user docs

- Cross-platform testing (Linux, macOS, Windows)
- Visual regression tests (compare to Praat output)
- Performance benchmarks
- User guide vignette
- Migration guide (Praat Picture → speaker)

**Deliverables**:
- Test suite with visual validation
- `vignettes/graphics.Rmd`
- Example gallery

---

## 9. Required Libraries Summary

### For Full PDF Generation

#### Linux (Cairo)

**System packages** (Ubuntu/Debian):
```bash
apt-get install libcairo2-dev libpango1.0-dev \
                libfreetype6-dev libfontconfig1-dev
```

**DESCRIPTION**:
```
SystemRequirements: cairo (>= 1.12.0), pango (>= 1.40.0),
                    freetype2, fontconfig
```

#### macOS (Quartz)

**No additional packages required** - Core Graphics is part of macOS SDK

**DESCRIPTION**:
```
SystemRequirements: macOS 10.12 or later
```

#### Windows

**Option A**: Use Cairo via Rtools
```
SystemRequirements: cairo (>= 1.12.0) via Rtools
```

**Option B**: Use pre-built Cairo binaries
- GTK+ bundle for Windows
- Or build from source

### For Minimal Implementation (R Graphics Device)

**No additional system requirements** - uses R's built-in graphics device

---

## 10. Cost-Benefit Analysis

### Full Implementation

**Costs**:
- 11-17 weeks development time
- ~$50,000-$85,000 developer cost (assuming $50/hour)
- Ongoing maintenance (1-2 days/month)
- Platform-specific testing infrastructure
- User support burden (graphics bugs are hard to debug)

**Benefits**:
- Full Praat script compatibility
- Direct PDF export from Praat commands
- Familiar to Praat users

**ROI**: ⚠️ Low - R users prefer ggplot2

### Helper Functions + Documentation

**Costs**:
- 2 weeks development time
- ~$4,000 developer cost
- Minimal maintenance
- No platform dependencies

**Benefits**:
- R users get familiar ggplot2 workflow
- Publication-quality plots
- Easy to extend
- Zero dependency issues

**ROI**: ✅ High - provides value with minimal cost

---

## 11. Decision Matrix

| Criteria | Full Graphics | Helper Functions | Status Quo |
|----------|--------------|------------------|------------|
| Development Time | 11-17 weeks | 2 weeks | 0 |
| Maintenance | High | Low | None |
| Platform Issues | High | None | None |
| User Familiarity (R) | Low | High | N/A |
| User Familiarity (Praat) | High | Medium | N/A |
| Publication Quality | High | Very High | N/A |
| CRAN Compatibility | Risky | Easy | N/A |
| Dependencies | Many | None | None |
| **Recommendation** | ❌ | ✅✅✅ | ⚠️ |

---

## 12. Conclusion

### Final Recommendation: **Helper Functions + Documentation**

**Implementation Plan** (2 weeks):

**Week 1**: Plot methods
- [ ] `plot.Sound()` - waveform
- [ ] `plot.Pitch()` - F0 contour
- [ ] `plot.Formant()` - formant tracks
- [ ] `plot.Spectrogram()` - spectrogram heatmap
- [ ] `plot.Intensity()` - intensity contour
- [ ] `plot.TextGrid()` - annotation tiers

**Week 2**: Documentation
- [ ] `vignettes/plotting-guide.Rmd` - comprehensive plotting guide
- [ ] ggplot2 examples for all object types
- [ ] Composite plots (waveform + spec + F0)
- [ ] phonR integration examples
- [ ] `inst/examples/plotting/` - example gallery

**Benefits**:
- ✅ Quick to implement (2 weeks vs. 11-17 weeks)
- ✅ Zero platform dependencies
- ✅ Works with R ecosystem (tidyverse, RMarkdown)
- ✅ Easy to maintain
- ✅ Users can extend easily
- ✅ Publication-quality output via ggplot2

### Future Consideration

**If graphics implementation is funded** (grant or significant user demand):
- Implement as **separate package**: `speaker.graphics`
- Maintain separately from core `speaker` package
- Users opt-in via installation
- Does not burden core package maintenance

**Estimated grant requirement**: $60,000-$100,000 for full implementation

---

## 13. Next Steps

### Immediate (v1.0.0)

1. ✅ Complete current object implementation
2. ✅ Export methods (`as_data_frame()`, `as_matrix()`) for all objects
3. ✅ Basic documentation showing data export

### v1.1.0 (Recommended)

1. Add plot methods for all objects (using base R graphics)
2. Create comprehensive plotting vignette
3. Provide ggplot2 examples
4. Example gallery

### v2.0.0+ (If Funded)

Consider full graphics implementation as separate package

---

**Document Status**: Final
**Last Updated**: 2025-11-28
**Prepared By**: Claude Code Assistant
**For Package**: pladdrr (speaker) v0.4.1+
