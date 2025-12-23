# Plan: R-Native Graphics for Praat Objects

## Executive Summary

This document outlines the plan to provide plotting capabilities for Praat objects using **R's native graphics system** (base R and ggplot2), rather than Praat's built-in graphics system.

### Why R-Native Graphics?

After attempting to integrate Praat's native graphics system, we discovered that it cannot be easily incorporated into an R package due to **deep platform-specific dependencies**:

| Platform | Praat Graphics Backend | Issue |
|----------|----------------------|-------|
| macOS | Quartz/Cocoa | Requires Objective-C++ compilation (.mm files) |
| Linux | Cairo/Pango | Requires external `libcairo2-dev`, `libpango1.0-dev` |
| Windows | GDI+ | Requires Windows SDK |

These dependencies would significantly complicate the package build process and reduce portability.

### The Better Alternative: R Graphics

R has **superior plotting capabilities** through:
- **Base R graphics**: Simple, universal, no dependencies
- **ggplot2**: Publication-quality, highly customizable
- **grid/patchwork**: Multi-panel compositions

This approach:
- ✅ Works on all platforms with no extra dependencies
- ✅ Integrates naturally with R workflows (tidyverse, RMarkdown)
- ✅ Produces publication-quality output
- ✅ Users already know R plotting

---

## Implementation Plan

### Phase 1: Data Extraction Methods (Existing)

All Praat objects already have data export methods that return R-native structures:

```r
# Already implemented
sound$as_matrix()           # Returns numeric matrix
pitch$as_data_frame()       # Returns data.frame with time, frequency
formant$as_data_frame()     # Returns data.frame with F1, F2, F3...
intensity$as_data_frame()   # Returns data.frame with time, intensity
spectrum$as_data_frame()    # Returns data.frame with frequency, power
spectrogram$as_matrix()     # Returns time-frequency matrix
ltas$as_data_frame()        # Returns data.frame with frequency, power
```

### Phase 2: Add plot() S3 Methods (2-3 days)

Create S3 `plot()` methods for each Praat class that use base R graphics.

#### 2.1 Sound plotting

```r
# R/plot-methods.R

#' Plot Sound waveform
#' @export
plot.Sound <- function(x, tmin = NULL, tmax = NULL,
                       ymin = NULL, ymax = NULL,
                       main = "Sound waveform",
                       xlab = "Time (s)", ylab = "Amplitude",
                       col = "black", ...) {
  # Get waveform data
  mat <- x$as_matrix()
  times <- x$get_times()

  # Time range
  if (is.null(tmin)) tmin <- min(times)
  if (is.null(tmax)) tmax <- max(times)
  idx <- times >= tmin & times <= tmax

  # Amplitude range
  samples <- mat[1, idx]  # First channel
  if (is.null(ymin)) ymin <- min(samples)
  if (is.null(ymax)) ymax <- max(samples)

  plot(times[idx], samples, type = "l", col = col,
       xlim = c(tmin, tmax), ylim = c(ymin, ymax),
       main = main, xlab = xlab, ylab = ylab, ...)
}
```

#### 2.2 Pitch plotting

```r
#' Plot Pitch contour
#' @export
plot.Pitch <- function(x, tmin = NULL, tmax = NULL,
                       fmin = 50, fmax = 500,
                       main = "Pitch contour",
                       xlab = "Time (s)", ylab = "Frequency (Hz)",
                       col = "blue", pch = 16, cex = 0.5, ...) {
  df <- x$as_data_frame()

  # Time range
  if (is.null(tmin)) tmin <- min(df$time)
  if (is.null(tmax)) tmax <- max(df$time)
  df <- df[df$time >= tmin & df$time <= tmax, ]

  # Remove unvoiced frames
  df <- df[!is.na(df$frequency) & df$frequency > 0, ]

  plot(df$time, df$frequency, type = "p", col = col,
       xlim = c(tmin, tmax), ylim = c(fmin, fmax),
       main = main, xlab = xlab, ylab = ylab,
       pch = pch, cex = cex, ...)
}
```

#### 2.3 Spectrum plotting

```r
#' Plot Spectrum
#' @export
plot.Spectrum <- function(x, fmin = 0, fmax = 5000,
                          main = "Spectrum",
                          xlab = "Frequency (Hz)",
                          ylab = "Power (dB/Hz)",
                          col = "black", ...) {
  df <- x$as_data_frame()
  df <- df[df$frequency >= fmin & df$frequency <= fmax, ]

  plot(df$frequency, df$power_db, type = "l", col = col,
       xlim = c(fmin, fmax),
       main = main, xlab = xlab, ylab = ylab, ...)
}
```

#### 2.4 Spectrogram plotting

```r
#' Plot Spectrogram
#' @export
plot.Spectrogram <- function(x, tmin = NULL, tmax = NULL,
                             fmin = 0, fmax = 5000,
                             dynamic_range = 70,
                             main = "Spectrogram",
                             xlab = "Time (s)",
                             ylab = "Frequency (Hz)",
                             col = gray.colors(256, start = 1, end = 0), ...) {
  mat <- x$as_matrix()
  times <- x$get_times()
  freqs <- x$get_frequencies()

  # Convert to dB
  mat_db <- 10 * log10(mat + 1e-30)
  max_db <- max(mat_db)
  mat_db[mat_db < max_db - dynamic_range] <- max_db - dynamic_range

  # Normalize to 0-1 for color mapping
  mat_norm <- (mat_db - (max_db - dynamic_range)) / dynamic_range

  # Time and frequency subsetting
  if (is.null(tmin)) tmin <- min(times)
  if (is.null(tmax)) tmax <- max(times)
  t_idx <- times >= tmin & times <= tmax
  f_idx <- freqs >= fmin & freqs <= fmax

  image(times[t_idx], freqs[f_idx], t(mat_norm[f_idx, t_idx]),
        col = col, xlim = c(tmin, tmax), ylim = c(fmin, fmax),
        main = main, xlab = xlab, ylab = ylab, ...)
}
```

#### 2.5 Additional plot methods

Similar `plot()` methods for:
- `plot.Intensity()` - Intensity contour
- `plot.Formant()` - Formant tracks (F1, F2, F3...)
- `plot.Ltas()` - Long-term average spectrum
- `plot.Harmonicity()` - HNR over time
- `plot.PointProcess()` - Vertical lines at point times
- `plot.TextGrid()` - Tier annotations

### Phase 3: ggplot2 Helper Functions (2-3 days)

Create ggplot2-based functions for users who prefer the tidyverse ecosystem.

#### 3.1 Core ggplot2 functions

```r
# R/ggplot-helpers.R

#' Create ggplot2 pitch plot
#' @export
ggplot_pitch <- function(pitch, fmin = 50, fmax = 500) {
  df <- pitch$as_data_frame()
  df <- df[!is.na(df$frequency) & df$frequency > 0, ]

  ggplot2::ggplot(df, ggplot2::aes(x = time, y = frequency)) +
    ggplot2::geom_point(size = 0.5, color = "blue") +
    ggplot2::ylim(fmin, fmax) +
    ggplot2::labs(x = "Time (s)", y = "Frequency (Hz)",
                  title = "Pitch contour") +
    ggplot2::theme_minimal()
}

#' Create ggplot2 spectrogram
#' @export
ggplot_spectrogram <- function(spectrogram, fmax = 5000,
                                dynamic_range = 70) {
  mat <- spectrogram$as_matrix()
  times <- spectrogram$get_times()
  freqs <- spectrogram$get_frequencies()

  # Convert to long format
  df <- expand.grid(time = times, frequency = freqs[freqs <= fmax])
  f_idx <- freqs <= fmax
  df$power <- as.vector(mat[f_idx, ])
  df$power_db <- 10 * log10(df$power + 1e-30)

  max_db <- max(df$power_db)
  df$power_db[df$power_db < max_db - dynamic_range] <- NA

  ggplot2::ggplot(df, ggplot2::aes(x = time, y = frequency, fill = power_db)) +
    ggplot2::geom_raster() +
    ggplot2::scale_fill_viridis_c(option = "inferno", na.value = "white") +
    ggplot2::labs(x = "Time (s)", y = "Frequency (Hz)",
                  fill = "Power (dB)", title = "Spectrogram") +
    ggplot2::theme_minimal()
}

#' Create ggplot2 formant plot
#' @export
ggplot_formant <- function(formant, fmax = 5500, num_formants = 3) {
  df <- formant$as_data_frame()

  # Reshape to long format for ggplot2
  formant_cols <- paste0("F", 1:num_formants)
  df_long <- tidyr::pivot_longer(df, cols = all_of(formant_cols),
                                  names_to = "formant", values_to = "frequency")
  df_long <- df_long[!is.na(df_long$frequency), ]

  ggplot2::ggplot(df_long, ggplot2::aes(x = time, y = frequency, color = formant)) +
    ggplot2::geom_point(size = 0.3) +
    ggplot2::ylim(0, fmax) +
    ggplot2::labs(x = "Time (s)", y = "Frequency (Hz)",
                  title = "Formant tracks") +
    ggplot2::theme_minimal()
}
```

### Phase 4: Multi-Panel Composition (1-2 days)

#### 4.1 Base R multi-panel

```r
#' Plot Sound with analysis panels
#' @export
plot_analysis <- function(sound, pitch = NULL, spectrogram = NULL,
                          formant = NULL, intensity = NULL) {
  # Count panels
  n_panels <- 1 + !is.null(pitch) + !is.null(spectrogram) +
              !is.null(formant) + !is.null(intensity)

  old_par <- par(mfrow = c(n_panels, 1), mar = c(2, 4, 1, 1))
  on.exit(par(old_par))

  # Sound waveform (always)
  plot(sound, main = "")

  # Optional panels
  if (!is.null(spectrogram)) {
    plot(spectrogram, main = "")
  }
  if (!is.null(pitch)) {
    plot(pitch, main = "")
  }
  if (!is.null(formant)) {
    plot(formant, main = "")
  }
  if (!is.null(intensity)) {
    plot(intensity, main = "")
  }
}
```

#### 4.2 ggplot2 with patchwork

```r
#' Compose ggplot2 analysis panels
#' @export
ggplot_analysis <- function(sound, pitch = NULL, spectrogram = NULL) {
  plots <- list()

  # Sound waveform
  df_sound <- data.frame(
    time = sound$get_times(),
    amplitude = sound$as_matrix()[1, ]
  )
  plots$sound <- ggplot2::ggplot(df_sound, ggplot2::aes(x = time, y = amplitude)) +
    ggplot2::geom_line() +
    ggplot2::labs(x = NULL, y = "Amplitude") +
    ggplot2::theme_minimal()

  # Spectrogram
  if (!is.null(spectrogram)) {
    plots$spectrogram <- ggplot_spectrogram(spectrogram)
  }

  # Pitch
  if (!is.null(pitch)) {
    plots$pitch <- ggplot_pitch(pitch)
  }

  # Combine with patchwork
  patchwork::wrap_plots(plots, ncol = 1)
}
```

### Phase 5: Documentation and Examples (1-2 days)

#### 5.1 Vignette: Plotting Praat Objects

Create `vignettes/plotting.Rmd`:

```markdown
---
title: "Plotting Praat Objects in R"
output: rmarkdown::html_vignette
vignette: >
  %\VignetteIndexEntry{Plotting Praat Objects in R}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---

## Overview

pladdrr provides plotting capabilities through R's native graphics system,
giving you full flexibility with base R graphics or ggplot2.

## Basic Plotting with base R

### Waveform

sound <- Sound$new("speech.wav")
plot(sound)

### Pitch Contour

pitch <- sound$to_pitch()
plot(pitch)

### Spectrogram

spectrogram <- sound$to_spectrogram()
plot(spectrogram)

## Publication-Quality with ggplot2

library(ggplot2)

# Pitch contour
ggplot_pitch(pitch) +
  theme_classic() +
  labs(title = "F0 Contour")

# Spectrogram with custom colors
ggplot_spectrogram(spectrogram) +
  scale_fill_viridis_c(option = "magma")

## Multi-Panel Analysis

# Base R
plot_analysis(sound, pitch = pitch, spectrogram = spectrogram)

# ggplot2 with patchwork
library(patchwork)
ggplot_analysis(sound, pitch = pitch, spectrogram = spectrogram)

## Saving Plots

# Base R
pdf("analysis.pdf", width = 8, height = 10)
plot_analysis(sound, pitch = pitch, spectrogram = spectrogram)
dev.off()

# ggplot2
p <- ggplot_analysis(sound, pitch = pitch, spectrogram = spectrogram)
ggsave("analysis.pdf", p, width = 8, height = 10)
```

---

## File Structure

```
R/
  plot-methods.R        # S3 plot() methods for all classes
  ggplot-helpers.R      # ggplot2-based plotting functions

vignettes/
  plotting.Rmd          # Comprehensive plotting vignette
```

## Implementation Timeline

| Phase | Duration | Description |
|-------|----------|-------------|
| Phase 1 | Done | Data extraction methods (existing) |
| Phase 2 | 2-3 days | Base R plot() S3 methods |
| Phase 3 | 2-3 days | ggplot2 helper functions |
| Phase 4 | 1-2 days | Multi-panel composition |
| Phase 5 | 1-2 days | Documentation and vignette |
| **Total** | **6-10 days** | |

## Advantages Over Praat Graphics

| Feature | Praat Graphics | R Graphics |
|---------|---------------|------------|
| Cross-platform | Complex deps | ✅ Built-in |
| Customization | Limited | ✅ Unlimited |
| Publication quality | Good | ✅ Excellent |
| Integration | Praat only | ✅ Full R ecosystem |
| User familiarity | Must learn | ✅ Already know |
| RMarkdown/Quarto | ❌ No | ✅ Native |
| Interactive (plotly) | ❌ No | ✅ Easy |

## Success Criteria

1. ✅ `plot()` works for all major Praat objects
2. ✅ ggplot2 helpers produce publication-quality output
3. ✅ Multi-panel plots work correctly
4. ✅ Output matches expected representations
5. ✅ No external dependencies required
6. ✅ Comprehensive documentation with examples

---

## Historical Note: Why Not Praat's Native Graphics?

An initial attempt was made to integrate Praat's built-in graphics system (`Graphics.cpp`, `GraphicsPostscript.cpp`, etc.). This approach was abandoned because:

1. **macOS**: Requires Objective-C++ compilation for Cocoa/Quartz
   - Praat's `Gui.h` includes `<Cocoa/Cocoa.h>` which uses `@class`, `@protocol` syntax
   - Cannot compile in standard C++ mode

2. **Linux**: Requires Cairo and Pango external libraries
   - `Gui.h` includes `<cairo/cairo.h>` when `UNIX` is defined
   - Would need `libcairo2-dev`, `libpango1.0-dev` as SystemRequirements

3. **Deep GUI coupling**: Graphics system intertwined with GUI code
   - Removing `-DNO_GRAPHICS` flag exposes many GUI dependencies
   - Would require extensive stubbing or rewriting

The R-native approach is superior because it leverages R's mature, portable, and flexible graphics system that users already know.
