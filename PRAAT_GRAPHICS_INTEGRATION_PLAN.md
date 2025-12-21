# Praat Virtual Graphics Integration Plan for pladdrr

## Executive Summary

This plan outlines how to expose Praat's graphics system for **off-screen/virtual rendering** - generating PDF, PNG, and EPS files without any GUI windows. Praat has a complete, production-ready graphics pipeline that can render any phonetic object to publication-quality output files.

## Architecture Overview

```
R User Code
    │
    ▼
┌─────────────────────────────────────────────────────────────────────┐
│ R Interface Layer (R6 Classes)                                      │
│  PraatCanvas$new() - Virtual drawing canvas                         │
│  canvas$draw_sound() / canvas$draw_pitch() / etc.                   │
│  canvas$save_pdf() / canvas$save_png()                              │
└─────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────┐
│ C++ Wrapper Layer (src/graphics_wrappers.cpp)                       │
│  - Graphics_create_* for PDF/PNG/EPS                                │
│  - Object drawing dispatch (Sound_draw, Pitch_draw, etc.)           │
│  - Recording and playback                                           │
│  - Error handling                                                   │
└─────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────┐
│ Praat Graphics System                                               │
│  Graphics.h/cpp     - Base graphics abstraction                     │
│  GraphicsScreen.cpp - PDF/PNG output (Cairo/Quartz)                 │
│  GraphicsPostscript.cpp - EPS output                                │
│  Graphics_record.cpp - Recording/playback system                    │
└─────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────┐
│ Object Drawing Methods (fon/*.cpp)                                  │
│  Sound_draw(), Pitch_draw(), Formant_drawTracks(),                  │
│  Spectrogram_paint(), Intensity_draw(), TextGrid_Sound_draw(), etc. │
└─────────────────────────────────────────────────────────────────────┘
```

## Key Entry Points (Already Exist in Praat Source)

### 1. Graphics Context Creation
**Location**: `src/praat.github.io/sys/Graphics.h` (lines 139-153)

```cpp
// Create PDF file output (no GUI needed)
autoGraphics Graphics_create_pdffile (MelderFile file, int resolution,
    double x1inches, double x2inches, double y1inches, double y2inches);

// Create PNG file output (no GUI needed)
autoGraphics Graphics_create_pngfile (MelderFile file, int resolution,
    double x1inches, double x2inches, double y1inches, double y2inches);

// Create EPS file output (no GUI needed)
autoGraphics Graphics_create_epsfile (MelderFile file, int resolution,
    kGraphicsPostscript_spots spots,
    double xmin, double xmax, double ymin, double ymax,
    bool includeFonts, bool useSilipaPS);

// Create in-memory recording context
autoGraphics Graphics_create (int resolution);
```

### 2. Recording and Playback System
**Location**: `src/praat.github.io/sys/Graphics_record.cpp`

```cpp
// Record drawing operations to memory
bool Graphics_startRecording (Graphics me);
bool Graphics_stopRecording (Graphics me);
void Graphics_clearRecording (Graphics me);

// Replay recorded operations to another graphics context
void Graphics_play (Graphics from, Graphics to);
```

### 3. Object Drawing Functions
**Location**: Various files in `src/praat.github.io/fon/`

| Object | Function | File |
|--------|----------|------|
| Sound | `Sound_draw()` | Sound.h:197 |
| Pitch | `Pitch_draw()`, `Pitch_drawInside()` | Pitch.cpp:679-683 |
| Formant | `Formant_drawTracks()`, `Formant_drawSpeckles()` | Formant.cpp:110 |
| Spectrogram | `Spectrogram_paint()`, `Spectrogram_paintInside()` | Spectrogram.cpp:55-141 |
| Intensity | `Intensity_draw()`, `Intensity_drawInside()` | Intensity.h:52 |
| Spectrum | `Spectrum_draw()`, `Spectrum_drawLogFreq()` | Spectrum.cpp:117-175 |
| Ltas | `Ltas_draw()` | Ltas.h:65 |
| TextGrid | `TextGrid_Sound_draw()` | TextGrid_Sound.cpp:381 |
| PitchTier | `PitchTier_draw()` | PitchTier.h:46 |
| IntensityTier | `IntensityTier_draw()` | IntensityTier.cpp:33 |
| PointProcess | `PointProcess_draw()` | PointProcess.cpp:254 |
| Cochleagram | `Cochleagram_paint()` | Cochleagram.cpp:34 |
| Matrix | `Matrix_paintImage()`, `Matrix_drawContours()` | Matrix.h:247 |

### 4. Graphics State Functions
```cpp
// Viewport and window (coordinate system)
void Graphics_setViewport (Graphics me, double x1NDC, double x2NDC, double y1NDC, double y2NDC);
void Graphics_setWindow (Graphics me, double x1, double x2, double y1, double y2);
void Graphics_setInner (Graphics me);
void Graphics_unsetInner (Graphics me);

// Drawing style
void Graphics_setColour (Graphics me, MelderColour colour);
void Graphics_setLineWidth (Graphics me, double lineWidth);
void Graphics_setLineType (Graphics me, int lineType);  // DRAWN, DOTTED, DASHED
void Graphics_setFont (Graphics me, enum kGraphics_font font);
void Graphics_setFontSize (Graphics me, double height);
void Graphics_setFontStyle (Graphics me, int style);  // NORMAL, BOLD, ITALIC

// Axis decorations
void Graphics_drawInnerBox (Graphics me);
void Graphics_marksLeft (Graphics me, integer n, bool numbers, bool ticks, bool dotted);
void Graphics_marksBottom (Graphics me, integer n, bool numbers, bool ticks, bool dotted);
void Graphics_textLeft (Graphics me, bool farr, conststring32 text);
void Graphics_textBottom (Graphics me, bool farr, conststring32 text);
```

## Implementation Phases

### Phase 1: Basic Graphics Context (1 week)

#### 1.1 Create Graphics Wrapper Functions
```cpp
// src/graphics_wrappers.cpp

#include <Rcpp.h>
#include "Graphics.h"
#include "melder.h"

// [[Rcpp::export(.graphics_create_pdf)]]
SEXP graphics_create_pdf(std::string path, int resolution,
                         double x1, double x2, double y1, double y2) {
    try {
        structMelderFile file {};
        Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);

        autoGraphics graphics = Graphics_create_pdffile(&file, resolution,
            x1, x2, y1, y2);

        Graphics* ptr = graphics.releaseToAmbiguousOwner();
        return Rcpp::XPtr<Graphics>(ptr, true);
    } catch (MelderError) {
        std::string msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        Rcpp::stop(msg);
    }
}

// [[Rcpp::export(.graphics_create_png)]]
SEXP graphics_create_png(std::string path, int resolution,
                         double x1, double x2, double y1, double y2) {
    try {
        structMelderFile file {};
        Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);

        autoGraphics graphics = Graphics_create_pngfile(&file, resolution,
            x1, x2, y1, y2);

        Graphics* ptr = graphics.releaseToAmbiguousOwner();
        return Rcpp::XPtr<Graphics>(ptr, true);
    } catch (MelderError) {
        std::string msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        Rcpp::stop(msg);
    }
}

// [[Rcpp::export(.graphics_create_memory)]]
SEXP graphics_create_memory(int resolution) {
    autoGraphics graphics = Graphics_create(resolution);
    Graphics_startRecording(graphics.get());

    Graphics* ptr = graphics.releaseToAmbiguousOwner();
    return Rcpp::XPtr<Graphics>(ptr, true);
}
```

#### 1.2 Graphics Finalization (auto-save on destroy)
```cpp
// [[Rcpp::export(.graphics_close)]]
void graphics_close(SEXP xptr) {
    Rcpp::XPtr<Graphics> graphics(xptr);
    // Graphics destructor writes file (for PDF/PNG contexts)
    // Explicit call to ensure file is written
    forget(graphics.get());
}
```

### Phase 2: Object Drawing Integration (2-3 weeks)

#### 2.1 Sound Drawing
```cpp
// [[Rcpp::export(.graphics_draw_sound)]]
void graphics_draw_sound(SEXP graphics_xptr, SEXP sound_xptr,
                         double tmin, double tmax,
                         double ymin, double ymax,
                         bool garnish) {
    Rcpp::XPtr<Graphics> graphics(graphics_xptr);
    Rcpp::XPtr<structSound> sound(sound_xptr);

    try {
        Sound_draw(sound.get(), graphics.get(),
                   tmin, tmax, ymin, ymax, garnish, U"curve");
    } catch (MelderError) {
        std::string msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        Rcpp::stop(msg);
    }
}
```

#### 2.2 Pitch Drawing
```cpp
// [[Rcpp::export(.graphics_draw_pitch)]]
void graphics_draw_pitch(SEXP graphics_xptr, SEXP pitch_xptr,
                         double tmin, double tmax,
                         double fmin, double fmax,
                         bool garnish, bool speckle,
                         std::string unit) {
    Rcpp::XPtr<Graphics> graphics(graphics_xptr);
    Rcpp::XPtr<structPitch> pitch(pitch_xptr);

    kPitch_unit kunit = kPitch_unit::HERTZ;  // default
    if (unit == "mel") kunit = kPitch_unit::MEL;
    else if (unit == "logHertz") kunit = kPitch_unit::LOG_HERTZ;
    else if (unit == "semitones") kunit = kPitch_unit::SEMITONES_100;
    else if (unit == "ERB") kunit = kPitch_unit::ERB;

    try {
        Pitch_draw(pitch.get(), graphics.get(),
                   tmin, tmax, fmin, fmax, garnish, speckle, kunit);
    } catch (MelderError) {
        std::string msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        Rcpp::stop(msg);
    }
}
```

#### 2.3 Spectrogram Painting
```cpp
// [[Rcpp::export(.graphics_paint_spectrogram)]]
void graphics_paint_spectrogram(SEXP graphics_xptr, SEXP spectrogram_xptr,
                                double tmin, double tmax,
                                double fmin, double fmax,
                                double maximum, bool autoscaling,
                                double dynamic_range,
                                double preemphasis, double dynamic_compression,
                                bool garnish) {
    Rcpp::XPtr<Graphics> graphics(graphics_xptr);
    Rcpp::XPtr<structSpectrogram> spectrogram(spectrogram_xptr);

    try {
        Spectrogram_paint(spectrogram.get(), graphics.get(),
                          tmin, tmax, fmin, fmax,
                          maximum, autoscaling,
                          dynamic_range, preemphasis, dynamic_compression,
                          garnish);
    } catch (MelderError) {
        std::string msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        Rcpp::stop(msg);
    }
}
```

#### 2.4 Formant Drawing
```cpp
// [[Rcpp::export(.graphics_draw_formant_tracks)]]
void graphics_draw_formant_tracks(SEXP graphics_xptr, SEXP formant_xptr,
                                  double tmin, double tmax,
                                  double fmax, bool garnish) {
    Rcpp::XPtr<Graphics> graphics(graphics_xptr);
    Rcpp::XPtr<structFormant> formant(formant_xptr);

    try {
        Formant_drawTracks(formant.get(), graphics.get(),
                           tmin, tmax, fmax, garnish);
    } catch (MelderError) {
        std::string msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        Rcpp::stop(msg);
    }
}
```

### Phase 3: Viewport and State Management (1 week)

```cpp
// [[Rcpp::export(.graphics_set_viewport)]]
void graphics_set_viewport(SEXP xptr, double x1, double x2, double y1, double y2) {
    Rcpp::XPtr<Graphics> graphics(xptr);
    Graphics_setViewport(graphics.get(), x1, x2, y1, y2);
}

// [[Rcpp::export(.graphics_set_window)]]
void graphics_set_window(SEXP xptr, double x1, double x2, double y1, double y2) {
    Rcpp::XPtr<Graphics> graphics(xptr);
    Graphics_setWindow(graphics.get(), x1, x2, y1, y2);
}

// [[Rcpp::export(.graphics_set_inner)]]
void graphics_set_inner(SEXP xptr) {
    Rcpp::XPtr<Graphics> graphics(xptr);
    Graphics_setInner(graphics.get());
}

// [[Rcpp::export(.graphics_unset_inner)]]
void graphics_unset_inner(SEXP xptr) {
    Rcpp::XPtr<Graphics> graphics(xptr);
    Graphics_unsetInner(graphics.get());
}

// [[Rcpp::export(.graphics_draw_inner_box)]]
void graphics_draw_inner_box(SEXP xptr) {
    Rcpp::XPtr<Graphics> graphics(xptr);
    Graphics_drawInnerBox(graphics.get());
}

// [[Rcpp::export(.graphics_set_colour)]]
void graphics_set_colour(SEXP xptr, double red, double green, double blue) {
    Rcpp::XPtr<Graphics> graphics(xptr);
    MelderColour colour = MelderColour(red, green, blue);
    Graphics_setColour(graphics.get(), colour);
}

// [[Rcpp::export(.graphics_set_line_width)]]
void graphics_set_line_width(SEXP xptr, double width) {
    Rcpp::XPtr<Graphics> graphics(xptr);
    Graphics_setLineWidth(graphics.get(), width);
}

// [[Rcpp::export(.graphics_set_font)]]
void graphics_set_font(SEXP xptr, std::string font, double size) {
    Rcpp::XPtr<Graphics> graphics(xptr);

    kGraphics_font kfont = kGraphics_font::HELVETICA;
    if (font == "Times") kfont = kGraphics_font::TIMES;
    else if (font == "Courier") kfont = kGraphics_font::COURIER;
    else if (font == "Palatino") kfont = kGraphics_font::PALATINO;

    Graphics_setFont(graphics.get(), kfont);
    Graphics_setFontSize(graphics.get(), size);
}

// [[Rcpp::export(.graphics_text)]]
void graphics_text(SEXP xptr, double x, double y, std::string text) {
    Rcpp::XPtr<Graphics> graphics(xptr);
    Graphics_text(graphics.get(), x, y, Melder_peek8to32(text.c_str()));
}

// [[Rcpp::export(.graphics_marks_left)]]
void graphics_marks_left(SEXP xptr, int n, bool numbers, bool ticks, bool dotted) {
    Rcpp::XPtr<Graphics> graphics(xptr);
    Graphics_marksLeft(graphics.get(), n, numbers, ticks, dotted);
}

// [[Rcpp::export(.graphics_marks_bottom)]]
void graphics_marks_bottom(SEXP xptr, int n, bool numbers, bool ticks, bool dotted) {
    Rcpp::XPtr<Graphics> graphics(xptr);
    Graphics_marksBottom(graphics.get(), n, numbers, ticks, dotted);
}

// [[Rcpp::export(.graphics_text_left)]]
void graphics_text_left(SEXP xptr, bool far, std::string text) {
    Rcpp::XPtr<Graphics> graphics(xptr);
    Graphics_textLeft(graphics.get(), far, Melder_peek8to32(text.c_str()));
}

// [[Rcpp::export(.graphics_text_bottom)]]
void graphics_text_bottom(SEXP xptr, bool far, std::string text) {
    Rcpp::XPtr<Graphics> graphics(xptr);
    Graphics_textBottom(graphics.get(), far, Melder_peek8to32(text.c_str()));
}
```

### Phase 4: Recording/Playback (Advanced) (1 week)

```cpp
// [[Rcpp::export(.graphics_start_recording)]]
void graphics_start_recording(SEXP xptr) {
    Rcpp::XPtr<Graphics> graphics(xptr);
    Graphics_startRecording(graphics.get());
}

// [[Rcpp::export(.graphics_stop_recording)]]
void graphics_stop_recording(SEXP xptr) {
    Rcpp::XPtr<Graphics> graphics(xptr);
    Graphics_stopRecording(graphics.get());
}

// [[Rcpp::export(.graphics_clear_recording)]]
void graphics_clear_recording(SEXP xptr) {
    Rcpp::XPtr<Graphics> graphics(xptr);
    Graphics_clearRecording(graphics.get());
}

// [[Rcpp::export(.graphics_play)]]
void graphics_play(SEXP from_xptr, SEXP to_xptr) {
    Rcpp::XPtr<Graphics> from(from_xptr);
    Rcpp::XPtr<Graphics> to(to_xptr);
    Graphics_play(from.get(), to.get());
}
```

### Phase 5: R6 Interface (1 week)

```r
# R/praat-canvas.R

#' Praat Virtual Canvas
#'
#' R6 class for off-screen/virtual Praat drawing.
#'
#' @export
PraatCanvas <- R6::R6Class(
  "PraatCanvas",

  public = list(
    #' @description Create a new virtual canvas
    #' @param width Width in inches (default 7)
    #' @param height Height in inches (default 5)
    #' @param resolution DPI resolution (default 300)
    initialize = function(width = 7, height = 5, resolution = 300) {
      private$width <- width
      private$height <- height
      private$resolution <- resolution

      # Create memory graphics for recording
      private$ptr <- .graphics_create_memory(resolution)

      # Set default viewport
      .graphics_set_viewport(private$ptr, 0, width, 0, height)
      .graphics_set_window(private$ptr, 0, 1, 0, 1)
    },

    #' @description Set viewport (normalized device coordinates)
    set_viewport = function(x1, x2, y1, y2) {
      .graphics_set_viewport(private$ptr, x1, x2, y1, y2)
      invisible(self)
    },

    #' @description Set window (world coordinates)
    set_window = function(x1, x2, y1, y2) {
      .graphics_set_window(private$ptr, x1, x2, y1, y2)
      invisible(self)
    },

    #' @description Enter inner drawing mode (margins for axes)
    set_inner = function() {
      .graphics_set_inner(private$ptr)
      invisible(self)
    },

    #' @description Exit inner drawing mode
    unset_inner = function() {
      .graphics_unset_inner(private$ptr)
      invisible(self)
    },

    #' @description Draw box around inner area
    draw_inner_box = function() {
      .graphics_draw_inner_box(private$ptr)
      invisible(self)
    },

    #' @description Set drawing colour
    set_colour = function(colour) {
      if (is.character(colour)) {
        rgb <- col2rgb(colour) / 255
        .graphics_set_colour(private$ptr, rgb[1], rgb[2], rgb[3])
      } else if (length(colour) == 3) {
        .graphics_set_colour(private$ptr, colour[1], colour[2], colour[3])
      }
      invisible(self)
    },

    #' @description Set line width
    set_line_width = function(width) {
      .graphics_set_line_width(private$ptr, width)
      invisible(self)
    },

    #' @description Set font
    set_font = function(family = "Helvetica", size = 12) {
      .graphics_set_font(private$ptr, family, size)
      invisible(self)
    },

    #' @description Draw text
    text = function(x, y, label) {
      .graphics_text(private$ptr, x, y, label)
      invisible(self)
    },

    #' @description Draw axis marks on left
    marks_left = function(n = 5, numbers = TRUE, ticks = TRUE, dotted = FALSE) {
      .graphics_marks_left(private$ptr, n, numbers, ticks, dotted)
      invisible(self)
    },

    #' @description Draw axis marks on bottom
    marks_bottom = function(n = 5, numbers = TRUE, ticks = TRUE, dotted = FALSE) {
      .graphics_marks_bottom(private$ptr, n, numbers, ticks, dotted)
      invisible(self)
    },

    #' @description Draw axis label on left
    text_left = function(label, far = TRUE) {
      .graphics_text_left(private$ptr, far, label)
      invisible(self)
    },

    #' @description Draw axis label on bottom
    text_bottom = function(label, far = TRUE) {
      .graphics_text_bottom(private$ptr, far, label)
      invisible(self)
    },

    #' @description Draw Sound waveform
    draw_sound = function(sound, tmin = 0, tmax = 0, ymin = -1, ymax = 1, garnish = TRUE) {
      .graphics_draw_sound(private$ptr, sound$.xptr, tmin, tmax, ymin, ymax, garnish)
      invisible(self)
    },

    #' @description Draw Pitch contour
    draw_pitch = function(pitch, tmin = 0, tmax = 0, fmin = 0, fmax = 500,
                          garnish = TRUE, speckle = FALSE, unit = "Hertz") {
      .graphics_draw_pitch(private$ptr, pitch$.xptr, tmin, tmax, fmin, fmax,
                           garnish, speckle, unit)
      invisible(self)
    },

    #' @description Draw Formant tracks
    draw_formant = function(formant, tmin = 0, tmax = 0, fmax = 5500, garnish = TRUE) {
      .graphics_draw_formant_tracks(private$ptr, formant$.xptr, tmin, tmax, fmax, garnish)
      invisible(self)
    },

    #' @description Paint Spectrogram
    paint_spectrogram = function(spectrogram, tmin = 0, tmax = 0, fmin = 0, fmax = 0,
                                  maximum = 100, autoscaling = TRUE,
                                  dynamic_range = 50, preemphasis = 6,
                                  dynamic_compression = 0, garnish = TRUE) {
      .graphics_paint_spectrogram(private$ptr, spectrogram$.xptr,
                                   tmin, tmax, fmin, fmax,
                                   maximum, autoscaling,
                                   dynamic_range, preemphasis, dynamic_compression,
                                   garnish)
      invisible(self)
    },

    #' @description Draw Intensity contour
    draw_intensity = function(intensity, tmin = 0, tmax = 0, minimum = 0, maximum = 0,
                              garnish = TRUE) {
      .graphics_draw_intensity(private$ptr, intensity$.xptr,
                                tmin, tmax, minimum, maximum, garnish)
      invisible(self)
    },

    #' @description Draw Spectrum
    draw_spectrum = function(spectrum, fmin = 0, fmax = 0, minimum = 0, maximum = 0,
                             garnish = TRUE) {
      .graphics_draw_spectrum(private$ptr, spectrum$.xptr,
                               fmin, fmax, minimum, maximum, garnish)
      invisible(self)
    },

    #' @description Save to PDF file
    save_pdf = function(path, resolution = NULL) {
      res <- resolution %||% private$resolution
      pdf_ptr <- .graphics_create_pdf(path, res, 0, private$width, 0, private$height)
      .graphics_play(private$ptr, pdf_ptr)
      .graphics_close(pdf_ptr)
      invisible(self)
    },

    #' @description Save to PNG file
    save_png = function(path, resolution = NULL) {
      res <- resolution %||% private$resolution
      png_ptr <- .graphics_create_png(path, res, 0, private$width, 0, private$height)
      .graphics_play(private$ptr, png_ptr)
      .graphics_close(png_ptr)
      invisible(self)
    },

    #' @description Save to EPS file
    save_eps = function(path, resolution = NULL) {
      res <- resolution %||% private$resolution
      eps_ptr <- .graphics_create_eps(path, res, 0, private$width, 0, private$height)
      .graphics_play(private$ptr, eps_ptr)
      .graphics_close(eps_ptr)
      invisible(self)
    },

    #' @description Clear all recorded drawings
    clear = function() {
      .graphics_clear_recording(private$ptr)
      invisible(self)
    }
  ),

  private = list(
    ptr = NULL,
    width = 7,
    height = 5,
    resolution = 300
  )
)
```

## Usage Examples

### Example 1: Simple Waveform to PDF
```r
library(pladdrr)

# Load sound
sound <- Sound$new("audio.wav")

# Create canvas
canvas <- PraatCanvas$new(width = 6, height = 3)

# Draw waveform
canvas$draw_sound(sound, garnish = TRUE)

# Save to PDF
canvas$save_pdf("waveform.pdf")
```

### Example 2: Multi-Panel Analysis (AVQI-style)
```r
library(pladdrr)

# Load and analyze
sound <- Sound$new("voice.wav")
pitch <- sound$to_pitch()
spectrogram <- sound$to_spectrogram()
formant <- sound$to_formant_burg()

# Create large canvas
canvas <- PraatCanvas$new(width = 8, height = 10, resolution = 300)

# Panel 1: Waveform (top)
canvas$set_viewport(0.5, 7.5, 7.5, 9.5)
canvas$draw_sound(sound)

# Panel 2: Spectrogram with formants (middle)
canvas$set_viewport(0.5, 7.5, 4.0, 7.0)
canvas$paint_spectrogram(spectrogram, fmax = 5000)
canvas$set_colour("red")
canvas$draw_formant(formant, garnish = FALSE)

# Panel 3: Pitch contour (bottom)
canvas$set_viewport(0.5, 7.5, 0.5, 3.5)
canvas$set_colour("blue")
canvas$draw_pitch(pitch, fmax = 400)

# Save
canvas$save_pdf("voice_analysis.pdf")
canvas$save_png("voice_analysis.png", resolution = 150)  # lower res for web
```

### Example 3: TextGrid with Sound
```r
# Draw sound with aligned TextGrid
canvas <- PraatCanvas$new(width = 8, height = 5)

canvas$set_viewport(0.5, 7.5, 2.5, 4.5)
canvas$draw_sound(sound)

canvas$set_viewport(0.5, 7.5, 0.5, 2.5)
canvas$draw_textgrid(textgrid)

canvas$save_pdf("annotated_sound.pdf")
```

## Platform Dependencies

### Linux (Cairo)
- **Required**: `libcairo2-dev`, `libpango1.0-dev`
- PDF: `cairo_pdf_surface_create()`
- PNG: `cairo_image_surface_create()` + `cairo_surface_write_to_png()`

### macOS (Quartz/Core Graphics)
- **Built-in**: No additional dependencies
- PDF: `CGPDFContextCreateWithURL()`
- PNG: `CGBitmapContextCreate()` + `CGImageDestination`

### Windows (GDI+)
- **Built-in**: No additional dependencies
- Uses GDI+ for raster, can export to EMF/WMF

## Timeline Estimate

| Phase | Description | Duration |
|-------|-------------|----------|
| **Phase 1** | Basic graphics context (PDF/PNG/EPS creation) | 1 week |
| **Phase 2** | Object drawing (Sound, Pitch, Spectrogram, Formant, etc.) | 2-3 weeks |
| **Phase 3** | Viewport/state management | 1 week |
| **Phase 4** | Recording/playback system | 1 week |
| **Phase 5** | R6 interface + polish | 1 week |
| **Testing** | Comprehensive testing, documentation | 1 week |
| **TOTAL** | | **7-9 weeks** |

## Advantages Over R Graphics

1. **Praat-native rendering**: Spectrograms, pitch tracks look identical to Praat
2. **Vector output**: PDF/EPS are true vector graphics (scalable)
3. **Recording system**: Draw once, export to multiple formats
4. **Consistency**: Same code produces same output across platforms
5. **No coordinate translation**: Use Praat's coordinate system directly

## Comparison with R Plotting

| Feature | PraatCanvas | R (ggplot2) |
|---------|-------------|-------------|
| Spectrogram quality | Native Praat | Requires manual reimplementation |
| Formant overlay | Built-in | Manual |
| TextGrid alignment | Built-in | Very difficult |
| Publication quality | Yes | Yes |
| Customizability | Moderate | Very high |
| Learning curve | Low (Praat users) | Moderate |
| Integration | Direct with Praat objects | Needs data export |

## Files to Create/Modify

### New Files
- `src/graphics_wrappers.cpp` - C++ wrapper functions
- `R/praat-canvas.R` - PraatCanvas R6 class

### Modify
- `src/Makevars` - Ensure Graphics*.cpp compiled
- `NAMESPACE` - Export PraatCanvas
- `DESCRIPTION` - Version bump

## Success Criteria

1. **PDF Output**: Generate publication-quality PDF files
2. **PNG Output**: Generate web-ready raster images
3. **Multi-panel layouts**: Support complex figure arrangements
4. **All objects drawable**: Sound, Pitch, Formant, Spectrogram, Intensity, Spectrum, TextGrid
5. **Axis decorations**: Labels, tick marks, titles work correctly
6. **Cross-platform**: Works on Linux, macOS, Windows

---

**Document Version**: 1.0
**Created**: 2025-12-20
**Author**: Claude (Opus 4.5)
