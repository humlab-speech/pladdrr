# Praat Graphics File Output Implementation Plan

## Executive Summary

This document details **exactly how** Praat writes PDF, PNG, and EPS files to disk. The file output is handled **automatically** when the Graphics context is destroyed - this is the key insight for R integration.

## File Output Mechanism: Destructor-Based

**Critical Architecture**: Praat graphics contexts write their output files **when they are destroyed**. This means:
- Create graphics context → draw stuff → destroy context → file appears on disk
- No explicit "save" or "flush" call needed
- R integration must ensure proper destruction via XPtr finalizers

```
┌────────────────────────────────────────────────────────────────────┐
│ Graphics Lifecycle                                                  │
│                                                                    │
│  1. Create    →  2. Draw    →  3. Destroy   →  4. File on disk    │
│  (open file)     (build)       (finalize)       (written)          │
└────────────────────────────────────────────────────────────────────┘
```

## Platform-Specific Implementation Details

### 1. PDF Output

#### Linux (Cairo)
```cpp
// Creation (Graphics_create_pdffile)
cairo_surface_t* surface = cairo_pdf_surface_create(
    filepath,           // file path
    width_points,       // width in points (72 per inch)
    height_points       // height in points
);
cairo_t* context = cairo_create(surface);

// Destruction (v9_destroy) → Writes file
cairo_destroy(context);
cairo_surface_flush(surface);
cairo_surface_destroy(surface);  // FILE IS WRITTEN HERE
```

#### macOS (Quartz/Core Graphics)
```cpp
// Creation (Graphics_create_pdffile)
CFURLRef url = CFURLCreateWithFileSystemPath(NULL, path, kCFURLPOSIXPathStyle, false);
CGRect rect = CGRectMake(0, 0, width_points, height_points);
CGContextRef context = CGPDFContextCreateWithURL(url, &rect, dictionary);

// Destruction (v9_destroy) → Writes file
CGContextEndPage(context);
CGContextRelease(context);  // FILE IS WRITTEN HERE
CFRelease(url);
```

### 2. PNG Output

#### Linux (Cairo)
```cpp
// Creation (Graphics_create_pngfile)
cairo_surface_t* surface = cairo_image_surface_create(
    CAIRO_FORMAT_ARGB32,
    width_pixels,
    height_pixels
);
cairo_t* context = cairo_create(surface);

// Destruction (v9_destroy) → Writes file
cairo_destroy(context);
cairo_surface_flush(surface);
cairo_surface_write_to_png(surface, filepath);  // FILE IS WRITTEN HERE
cairo_surface_destroy(surface);
```

#### macOS (Quartz/Core Graphics)
```cpp
// Creation (Graphics_create_pngfile)
uint8_t* bits = malloc(stride * height);
CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
CGContextRef context = CGBitmapContextCreate(bits, width, height, 8, stride,
    colorSpace, kCGImageAlphaPremultipliedLast);

// Destruction (v9_destroy) → Writes file
CGImageRef image = CGBitmapContextCreateImage(context);
CFURLRef url = CFURLCreateWithFileSystemPath(NULL, path, kCFURLPOSIXPathStyle, false);
CGImageDestinationRef dest = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
CGImageDestinationAddImage(dest, image, properties);
CGImageDestinationFinalize(dest);  // FILE IS WRITTEN HERE
// cleanup...
```

#### Windows (GDI+)
```cpp
// Creation (Graphics_create_pngfile)
HDC screenDC = GetDC(NULL);
HDC memDC = CreateCompatibleDC(screenDC);
HBITMAP bitmap = CreateCompatibleBitmap(screenDC, width, height);
SelectObject(memDC, bitmap);

// Destruction (v9_destroy) → Writes file
Gdiplus::Bitmap gdiplusBitmap(bitmapInfo, bits);
// Find PNG encoder
for (each encoder) {
    if (encoder.MimeType == "image/png") {
        gdiplusBitmap.Save(filepath, &encoder.Clsid, NULL);  // FILE IS WRITTEN HERE
    }
}
DeleteObject(bitmap);
DeleteDC(memDC);
```

### 3. EPS Output (PostScript)

```cpp
// Creation (Graphics_create_epsfile)
FILE* file = Melder_fopen(filepath, "w");  // Opens file immediately
fprintf(file, "%%!PS-Adobe-3.0 EPSF-3.0\n");
fprintf(file, "%%%%BoundingBox: %d %d %d %d\n", ...);
// ... write header ...

// Drawing - writes directly to file
fprintf(file, "newpath %g %g moveto\n", x, y);
fprintf(file, "%g %g lineto stroke\n", x2, y2);

// Destruction (v9_destroy) → Closes file
fprintf(file, "%%%%Trailer\n");
fprintf(file, "%%%%EOF\n");
fclose(file);  // FILE IS FINALIZED HERE
```

## C++ Wrapper Implementation

### Key Pattern: XPtr with Destructor

The R integration must use Rcpp's `XPtr` with a custom destructor to ensure proper file finalization:

```cpp
// src/graphics_wrappers.cpp

#include <Rcpp.h>
#include "Graphics.h"

// Custom destructor that ensures file is written
void graphics_destructor(Graphics* g) {
    if (g != nullptr) {
        forget(g);  // Praat's destructor mechanism - calls v9_destroy()
    }
}

// [[Rcpp::export(.graphics_create_pdf)]]
SEXP graphics_create_pdf(std::string path, int resolution,
                         double x1, double x2, double y1, double y2) {
    try {
        structMelderFile file {};
        Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);

        autoGraphics graphics = Graphics_create_pdffile(&file, resolution,
            x1, x2, y1, y2);

        Graphics* ptr = graphics.releaseToAmbiguousOwner();

        // Create XPtr with custom destructor
        Rcpp::XPtr<Graphics> xptr(ptr, true);  // true = register destructor
        xptr.attr("class") = "praat_graphics";
        return xptr;

    } catch (MelderError) {
        std::string msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        Rcpp::stop(msg);
    }
}

// Explicit close function (calls destructor immediately)
// [[Rcpp::export(.graphics_finalize)]]
void graphics_finalize(SEXP xptr) {
    if (TYPEOF(xptr) == EXTPTRSXP) {
        Rcpp::XPtr<Graphics> graphics(xptr);
        if (graphics.get() != nullptr) {
            // Calling forget() triggers v9_destroy() which writes the file
            forget(graphics.get());
            // Clear the pointer to prevent double-free
            R_ClearExternalPtr(xptr);
        }
    }
}
```

### PNG Creation Wrapper

```cpp
// [[Rcpp::export(.graphics_create_png)]]
SEXP graphics_create_png(std::string path, int resolution,
                         double x1, double x2, double y1, double y2) {
    try {
        structMelderFile file {};
        Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);

        autoGraphics graphics = Graphics_create_pngfile(&file, resolution,
            x1, x2, y1, y2);

        Graphics* ptr = graphics.releaseToAmbiguousOwner();
        Rcpp::XPtr<Graphics> xptr(ptr, true);
        xptr.attr("class") = "praat_graphics";
        xptr.attr("format") = "png";
        xptr.attr("path") = path;
        return xptr;

    } catch (MelderError) {
        std::string msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        Rcpp::stop(msg);
    }
}
```

### EPS Creation Wrapper

```cpp
// [[Rcpp::export(.graphics_create_eps)]]
SEXP graphics_create_eps(std::string path, int resolution,
                         double x1, double x2, double y1, double y2,
                         bool include_fonts = true) {
    try {
        structMelderFile file {};
        Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);

        autoGraphics graphics = Graphics_create_epsfile(&file, resolution,
            kGraphicsPostscript_spots::FINE,  // or PHOTOCOPYABLE
            x1, x2, y1, y2,
            include_fonts,
            false);  // useSilipaPS

        Graphics* ptr = graphics.releaseToAmbiguousOwner();
        Rcpp::XPtr<Graphics> xptr(ptr, true);
        xptr.attr("class") = "praat_graphics";
        xptr.attr("format") = "eps";
        return xptr;

    } catch (MelderError) {
        std::string msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        Rcpp::stop(msg);
    }
}
```

## R Interface Implementation

### Direct File Output (Recommended for Simple Cases)

```r
# R/graphics-output.R

#' Save Sound waveform to PDF
#'
#' @param sound A Sound R6 object
#' @param path Output file path
#' @param width Width in inches (default 6)
#' @param height Height in inches (default 3)
#' @param resolution DPI (default 300)
#' @param tmin Start time (0 = from beginning)
#' @param tmax End time (0 = to end)
#' @param ymin Minimum amplitude (-1)
#' @param ymax Maximum amplitude (1)
#' @param garnish Add axis labels and box
#' @export
praat_save_sound_pdf <- function(sound, path,
                                  width = 6, height = 3, resolution = 300,
                                  tmin = 0, tmax = 0, ymin = -1, ymax = 1,
                                  garnish = TRUE) {
    # Create PDF graphics context
    g <- .graphics_create_pdf(path, resolution, 0, width, 0, height)
    on.exit(.graphics_finalize(g))  # Ensure file is written even on error

    # Set viewport
    .graphics_set_viewport(g, 0.5, width - 0.5, 0.5, height - 0.5)

    # Draw the sound
    .graphics_draw_sound(g, sound$.xptr, tmin, tmax, ymin, ymax, garnish)

    # File is written when .graphics_finalize() is called (or when g is GC'd)
    invisible(path)
}

#' Save Spectrogram to PNG
#'
#' @param spectrogram A Spectrogram R6 object
#' @param path Output file path
#' @param width Width in inches
#' @param height Height in inches
#' @param resolution DPI (150 for web, 300 for print)
#' @export
praat_save_spectrogram_png <- function(spectrogram, path,
                                        width = 6, height = 4, resolution = 300,
                                        tmin = 0, tmax = 0, fmin = 0, fmax = 5000,
                                        dynamic_range = 50, garnish = TRUE) {
    g <- .graphics_create_png(path, resolution, 0, width, 0, height)
    on.exit(.graphics_finalize(g))

    .graphics_set_viewport(g, 0.7, width - 0.3, 0.7, height - 0.3)
    .graphics_paint_spectrogram(g, spectrogram$.xptr,
                                 tmin, tmax, fmin, fmax,
                                 100, TRUE, dynamic_range, 6, 0, garnish)

    invisible(path)
}
```

### Recording + Playback Pattern (For Complex Multi-Format Output)

```r
#' PraatCanvas class for complex drawings
#'
#' @export
PraatCanvas <- R6::R6Class(
  "PraatCanvas",

  public = list(
    initialize = function(width = 7, height = 5, resolution = 300) {
      private$width <- width
      private$height <- height
      private$resolution <- resolution

      # Create in-memory recording context
      private$ptr <- .graphics_create_memory(resolution)
      .graphics_start_recording(private$ptr)
      .graphics_set_viewport(private$ptr, 0, width, 0, height)
    },

    # ... drawing methods ...

    #' @description Save recorded drawing to PDF
    save_pdf = function(path) {
      # Stop recording
      .graphics_stop_recording(private$ptr)

      # Create PDF context
      pdf <- .graphics_create_pdf(path, private$resolution,
                                   0, private$width, 0, private$height)

      # Play recorded operations to PDF
      .graphics_play(private$ptr, pdf)

      # Finalize PDF (writes to disk)
      .graphics_finalize(pdf)

      # Resume recording for possible further use
      .graphics_start_recording(private$ptr)

      invisible(path)
    },

    #' @description Save recorded drawing to PNG
    save_png = function(path, resolution = NULL) {
      res <- resolution %||% private$resolution
      .graphics_stop_recording(private$ptr)

      png <- .graphics_create_png(path, res,
                                   0, private$width, 0, private$height)
      .graphics_play(private$ptr, png)
      .graphics_finalize(png)

      .graphics_start_recording(private$ptr)
      invisible(path)
    },

    #' @description Save recorded drawing to EPS
    save_eps = function(path, include_fonts = TRUE) {
      .graphics_stop_recording(private$ptr)

      eps <- .graphics_create_eps(path, private$resolution,
                                   0, private$width, 0, private$height,
                                   include_fonts)
      .graphics_play(private$ptr, eps)
      .graphics_finalize(eps)

      .graphics_start_recording(private$ptr)
      invisible(path)
    }
  ),

  private = list(
    ptr = NULL,
    width = 7,
    height = 5,
    resolution = 300,

    finalize = function() {
      # Ensure cleanup when object is garbage collected
      if (!is.null(private$ptr)) {
        .graphics_finalize(private$ptr)
      }
    }
  )
)
```

## Complete Workflow Examples

### Example 1: Direct PDF Output
```r
library(pladdrr)

# Load sound
sound <- Sound$new("voice.wav")

# Create PDF directly (simplest approach)
praat_save_sound_pdf(sound, "waveform.pdf", width = 6, height = 3)

# File is written when function returns
```

### Example 2: Multi-Panel with Recording
```r
# Create canvas
canvas <- PraatCanvas$new(width = 8, height = 10, resolution = 300)

# Load and analyze
sound <- Sound$new("voice.wav")
pitch <- sound$to_pitch()
spectrogram <- sound$to_spectrogram()

# Draw multiple panels
canvas$set_viewport(0.5, 7.5, 7.5, 9.5)
canvas$draw_sound(sound)

canvas$set_viewport(0.5, 7.5, 4.0, 7.0)
canvas$paint_spectrogram(spectrogram)

canvas$set_viewport(0.5, 7.5, 0.5, 3.5)
canvas$draw_pitch(pitch)

# Export to multiple formats from same recording
canvas$save_pdf("analysis.pdf")           # Vector, best for print
canvas$save_png("analysis.png", 150)      # Raster, good for web
canvas$save_eps("analysis.eps")           # Vector, for LaTeX
```

### Example 3: Batch Processing
```r
# Process multiple files
files <- list.files("audio/", pattern = "\\.wav$", full.names = TRUE)

for (f in files) {
    sound <- Sound$new(f)
    pitch <- sound$to_pitch()

    # Create output path
    out_pdf <- sub("\\.wav$", "_pitch.pdf", f)

    # Direct output
    g <- .graphics_create_pdf(out_pdf, 300, 0, 6, 0, 4)
    .graphics_set_viewport(g, 0.5, 5.5, 0.5, 3.5)
    .graphics_draw_pitch(g, pitch$.xptr, 0, 0, 50, 400, TRUE, FALSE, "Hertz")
    .graphics_finalize(g)  # Writes file

    message("Created: ", out_pdf)
}
```

## Error Handling

### Handling File Write Errors

```cpp
// [[Rcpp::export(.graphics_create_pdf)]]
SEXP graphics_create_pdf(std::string path, ...) {
    try {
        // Check if directory exists and is writable
        structMelderFile file {};
        Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);

        // This will throw MelderError if file can't be created
        autoGraphics graphics = Graphics_create_pdffile(&file, ...);

        // ...
    } catch (MelderError) {
        std::string msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        Rcpp::stop("Failed to create PDF: %s", msg.c_str());
    }
}
```

### R-Level Error Handling

```r
praat_save_pdf <- function(canvas, path) {
    # Validate path
    dir <- dirname(path)
    if (!dir.exists(dir)) {
        stop("Directory does not exist: ", dir)
    }

    # Try to save
    tryCatch({
        canvas$save_pdf(path)
    }, error = function(e) {
        stop("Failed to save PDF to ", path, ": ", conditionMessage(e))
    })

    # Verify file was created
    if (!file.exists(path)) {
        stop("File was not created: ", path)
    }

    invisible(path)
}
```

## Platform-Specific Notes

### Linux
- **Dependency**: libcairo2-dev, libpango1.0-dev
- PDF: Uses Cairo's PDF surface
- PNG: Uses Cairo's image surface + `cairo_surface_write_to_png()`
- Best format support

### macOS
- **Dependency**: Built-in (Core Graphics/Quartz)
- PDF: Uses `CGPDFContextCreateWithURL()`
- PNG: Uses `CGImageDestination` with `kUTTypePNG`
- No external dependencies

### Windows
- **Dependency**: Built-in (GDI+)
- PDF: Uses Cairo (if available) or falls back to EMF
- PNG: Uses GDI+ `Bitmap.Save()` with PNG encoder
- May need Rtools for Cairo support

## Testing Plan

### Unit Tests
```r
test_that("PDF output works", {
    sound <- Sound$new(system.file("extdata/test.wav", package = "pladdrr"))
    tmp <- tempfile(fileext = ".pdf")
    on.exit(unlink(tmp))

    praat_save_sound_pdf(sound, tmp)

    expect_true(file.exists(tmp))
    expect_gt(file.size(tmp), 0)
})

test_that("PNG output works", {
    sound <- Sound$new(system.file("extdata/test.wav", package = "pladdrr"))
    tmp <- tempfile(fileext = ".png")
    on.exit(unlink(tmp))

    praat_save_sound_png(sound, tmp, resolution = 72)

    expect_true(file.exists(tmp))
    expect_gt(file.size(tmp), 0)

    # Verify it's a valid PNG
    info <- png::readPNG(tmp, info = TRUE)
    expect_equal(attr(info, "dim")[1] > 0, TRUE)
})
```

## Summary: File Output Flow

```
┌────────────────────────────────────────────────────────────────────┐
│ PDF/PNG/EPS File Output                                            │
├────────────────────────────────────────────────────────────────────┤
│                                                                    │
│  R Code:                                                           │
│    g <- .graphics_create_pdf("out.pdf", 300, 0, 6, 0, 4)          │
│           │                                                        │
│           ▼                                                        │
│  C++ Wrapper:                                                      │
│    Graphics_create_pdffile() opens file/surface                    │
│           │                                                        │
│           ▼                                                        │
│  R Code:                                                           │
│    .graphics_draw_sound(g, sound, ...)                            │
│           │                                                        │
│           ▼                                                        │
│  C++ Wrapper:                                                      │
│    Sound_draw() renders to Graphics context                        │
│           │                                                        │
│           ▼                                                        │
│  R Code:                                                           │
│    .graphics_finalize(g)   # OR: g is garbage collected           │
│           │                                                        │
│           ▼                                                        │
│  C++ Wrapper:                                                      │
│    forget(graphics)  →  triggers v9_destroy()                     │
│           │                                                        │
│           ▼                                                        │
│  Praat Graphics:                                                   │
│    v9_destroy() writes file:                                       │
│      - PDF: CGContextEndPage + CGContextRelease (macOS)           │
│             cairo_surface_destroy (Linux)                          │
│      - PNG: CGImageDestinationFinalize (macOS)                    │
│             cairo_surface_write_to_png (Linux)                     │
│             gdiplusBitmap.Save (Windows)                           │
│      - EPS: fclose (all platforms)                                │
│           │                                                        │
│           ▼                                                        │
│  ════════════════════════════════════════════════════════         │
│  FILE IS NOW ON DISK                                               │
│  ════════════════════════════════════════════════════════         │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘
```

---

**Document Version**: 1.0
**Created**: 2025-12-20
**Author**: Claude (Opus 4.5)
