# Praat Plotting Capabilities: Gap Analysis

**Date**: 2025-11-29
**Package Version**: 1.0.6
**Status**: Comprehensive plotting capability assessment

## Executive Summary

The pladdrr package currently relies on R's ggplot2 for visualization rather than exposing Praat's native Graphics API. This analysis identifies gaps between Praat's plotting capabilities and what pladdrr currently provides.

**Overall Coverage**: ~45% (based on core object types)

**Strategy**: Continue using ggplot2 but ensure ALL Praat plot types can be replicated through exported methods and helper functions.

---

## 1. Current State: pladdrr Plotting

### ✅ Implemented Plotting Functions

#### Voice Quality Metrics
- ✅ **AVQI plots** (`plot_avqi()`)
  - Component bar charts
  - Waveform visualization
  - Spectrogram visualization
  
- ✅ **DSI plots** (`plot_dsi()`)
  - Score visualization
  - Component values
  - Contour plots

#### Cepstral Analysis
- ✅ **PowerCepstrum** (`plot_powercepstrum()`)
  - Cepstrum with peak annotation
  - Trend line overlay
  - CPP highlighting
  
- ✅ **PowerCepstrogram** (`plot_powercepstrogram()`)
  - Time-quefrency heatmap
  - Color-coded power levels
  - Optional CPP contour
  
- ✅ **CPP Time Series** (`plot_cpp_timeseries()`)
  - CPP over time
  - Smoothing options
  - Reference lines

#### Basic Object Plotting (via manual ggplot2 - shown in vignettes)
- ✅ **Pitch contours** (via `as_data_frame()`)
- ✅ **Intensity contours** (via `as_data_frame()`)
- ✅ **Formant trajectories** (via `as_data_frame()`)
- ✅ **Formant vowel spaces** (F1-F2 plots)
- ✅ **Spectrum** (via `as_data_frame()`)
- ✅ **LTAS** (via `as_data_frame()`)
- ✅ **TextGrid tier visualization** (manual)

### Current Approach

pladdrr provides two plotting strategies:

1. **Dedicated plotting functions** for complex analyses (AVQI, DSI, Cepstrum)
2. **Data export + manual ggplot2** for basic objects via `as_data_frame()`

This approach is documented in `vignettes/visualization.Rmd` (690 lines).

---

## 2. Praat's Plotting Capabilities

### Praat Drawing Functions (from source code analysis)

Based on analysis of `src/praat.github.io/fon/*.h`, Praat provides 60+ drawing functions:

#### Sound & Waveforms
- `Sound_draw()` - Waveform drawing
- `Sound_drawWhere()` - Conditional waveform
- `LongSound_drawWhere()` - Long audio files

#### Pitch
- `Pitch_draw()` - Pitch contour with garnish
- `Pitch_drawInside()` - Pitch without axes
- `Pitch_speckle()` - Speckle plot (candidate points)
- `Pitch_Intensity_draw()` - Combined pitch-intensity
- `TextGrid_Pitch_draw()` - Pitch with annotations
- `TextGrid_Pitch_drawSeparately()` - Multiple tiers
- `PitchTier_draw()` - Editable pitch tier
- `PitchTier_Pitch_draw()` - Overlay with voicing

#### Formants
- `Formant_drawTracks()` - Formant trajectories
- `Formant_drawSpeckles()` - Formant candidate points
- `Formant_drawSpeckles_inside()` - No axes version

#### Intensity
- `Intensity_draw()` - Intensity contour with garnish
- `Intensity_drawInside()` - Without axes
- `IntensityTier_draw()` - Editable tier

#### Spectral
- `Spectrogram_paint()` - Spectrogram heatmap
- `Spectrogram_paintInside()` - Without axes
- `Spectrum_draw()` - Spectrum with garnish
- `Spectrum_drawInside()` - Without axes
- `Spectrum_drawLogFreq()` - Logarithmic frequency scale
- `Ltas_draw()` - Long-term average spectrum

#### Other
- `Harmonicity_draw()` - HNR contours
- `PointProcess_draw()` - Point marks (pulses)
- `Cochleagram_paint()` - Auditory filterbank output
- `Excitation_draw()` - Excitation pattern
- `Matrix_paint*()` - 6 different matrix visualizations
- `AmplitudeTier_draw()` - Amplitude modification
- `DurationTier_draw()` - Duration modification

#### Combined Visualizations
- `TextGrid_Sound_draw()` - Annotation + waveform
- `TextGrid_Pitch_draw()` - Annotation + pitch
- `TextGrid_Pitch_drawSeparately()` - Multi-tier + pitch

---

## 3. Gap Analysis

### ❌ Category 1: Missing Plot Type Functions (HIGH PRIORITY)

These are plot types that Praat provides that pladdrr cannot easily replicate:

#### Sound Plotting
- ❌ **`plot.Sound()`** - Direct waveform plotting method
  - Praat: `Sound_draw()`
  - pladdrr: Must use `as_data_frame()` + manual ggplot2
  - **Gap**: No one-liner for waveform plots
  - **Implementation**: Add `plot()` method to Sound R6 class

#### Pitch Plotting
- ❌ **`plot.Pitch()`** - Direct pitch contour plotting
  - Praat: `Pitch_draw()`, `Pitch_drawInside()`
  - pladdrr: Manual via `as_data_frame()`
  - **Gap**: No built-in pitch plotting
  - **Implementation**: Add `plot()` method to Pitch R6 class

- ❌ **`plot_pitch_speckle()`** - Pitch candidate visualization
  - Praat: Shows all F0 candidates, not just selected track
  - pladdrr: Not available
  - **Gap**: Cannot visualize pitch detection algorithm's raw output
  - **Implementation**: Expose pitch candidates from Praat C++ layer

#### Formant Plotting  
- ❌ **`plot.Formant()`** - Direct formant track plotting
  - Praat: `Formant_drawTracks()`
  - pladdrr: Manual via `as_data_frame()`
  - **Gap**: No built-in formant plotting
  - **Implementation**: Add `plot()` method to Formant R6 class

- ❌ **`plot_formant_speckles()`** - Formant candidate visualization
  - Praat: `Formant_drawSpeckles()`
  - pladdrr: Not available
  - **Gap**: Cannot see formant tracking algorithm's raw candidates
  - **Implementation**: Would need to expose Formant frame data

#### Intensity Plotting
- ❌ **`plot.Intensity()`** - Direct intensity contour
  - Praat: `Intensity_draw()`
  - pladdrr: Manual plotting required
  - **Implementation**: Add `plot()` method to Intensity R6 class

#### Spectrogram Plotting
- ❌ **`plot.Spectrogram()`** - Direct spectrogram heatmap
  - Praat: `Spectrogram_paint()`
  - pladdrr: Must convert matrix manually
  - **Gap**: No built-in spectrogram plotting (despite being fundamental)
  - **Implementation**: Add `plot()` method to Spectrogram R6 class

#### Spectrum Plotting
- ❌ **`plot.Spectrum()`** - Direct spectrum plotting
  - Praat: `Spectrum_draw()`, `Spectrum_drawLogFreq()`
  - pladdrr: Manual via `as_data_frame()`
  - **Implementation**: Add `plot()` method to Spectrum R6 class with log frequency option

#### LTAS Plotting
- ❌ **`plot.Ltas()`** - Direct LTAS plotting
  - Praat: `Ltas_draw()`
  - pladdrr: Manual plotting
  - **Implementation**: Add `plot()` method to Ltas R6 class

#### Harmonicity Plotting
- ❌ **`plot.Harmonicity()`** - Direct HNR contour
  - Praat: `Harmonicity_draw()`
  - pladdrr: Manual plotting
  - **Implementation**: Add `plot()` method to Harmonicity R6 class

#### PointProcess Plotting
- ❌ **`plot.PointProcess()`** - Event markers
  - Praat: `PointProcess_draw()`
  - pladdrr: Not implemented
  - **Gap**: Cannot visualize glottal pulse timing
  - **Implementation**: Add `plot()` method showing vertical lines at event times

### ❌ Category 2: Missing Combined Visualizations (MEDIUM PRIORITY)

#### Multi-Object Plots
- ❌ **`plot_textgrid_sound()`** - Waveform + annotation tiers
  - Praat: `TextGrid_Sound_draw()`
  - pladdrr: Not available as single function
  - **Use case**: Standard phonetic visualization
  - **Workaround**: Can be built manually with ggplot2 + gridExtra
  - **Implementation**: Convenience function combining waveform + tier rectangles

- ❌ **`plot_textgrid_pitch()`** - Pitch + annotation tiers
  - Praat: `TextGrid_Pitch_draw()`
  - pladdrr: Not available
  - **Use case**: Prosodic analysis with segmentation
  - **Implementation**: Combine pitch contour + tier visualization

- ❌ **`plot_pitch_intensity()`** - Dual-axis pitch-intensity
  - Praat: `Pitch_Intensity_draw()`
  - pladdrr: Shown in vignette but not a function
  - **Gap**: No ready-made function
  - **Implementation**: Dedicated function for common use case

- ❌ **`plot_spectrogram_formants()`** - Spectrogram + formant overlay
  - Praat: Common pattern (separate commands)
  - pladdrr: Must combine manually
  - **Use case**: Vowel quality visualization
  - **Implementation**: Heatmap + formant track overlay

### ❌ Category 3: Missing Advanced Features (LOW PRIORITY)

#### Auditory Models
- ❌ **`plot.Cochleagram()`** - Auditory filterbank visualization
  - Praat: `Cochleagram_paint()`
  - pladdrr: Cochleagram class exists but no plot method
  - **Implementation**: Similar to Spectrogram heatmap

- ❌ **`plot.Excitation()`** - Excitation pattern
  - Praat: `Excitation_draw()`
  - pladdrr: Excitation class exists but no plot method
  - **Implementation**: Similar to Spectrum plot

#### Manipulation Tiers
- ❌ **`plot.AmplitudeTier()`** - Amplitude modification points
  - Praat: `AmplitudeTier_draw()`
  - pladdrr: Class exists, no plot method
  - **Implementation**: Point + line plot

- ❌ **`plot.DurationTier()`** - Duration tier visualization
  - Praat: `DurationTier_draw()`
  - pladdrr: Class exists, no plot method
  - **Implementation**: Point + line plot

#### Matrix Visualizations
- ❌ **Matrix drawing functions** - 6 different styles
  - Praat: `Matrix_paintImage()`, `Matrix_paintContours()`, `Matrix_paintSurface()`, etc.
  - pladdrr: Generic Matrix class but no specialized drawing
  - **Note**: Most users will use R's built-in matrix plotting
  - **Priority**: LOW (R provides better alternatives)

### ✅ Category 4: Adequately Covered (NO ACTION)

These Praat functions are adequately handled by existing pladdrr + ggplot2 approach:

- ✅ **TextGrid tiers** - Manual ggplot2 approach works well
- ✅ **Vowel spaces** - Better in ggplot2 with custom aesthetics
- ✅ **Multi-panel layouts** - gridExtra / patchwork superior to Praat
- ✅ **Custom color schemes** - ggplot2 scales much more powerful
- ✅ **Publication output** - ggsave() handles all formats

---

## 4. Recommended Implementation Strategy

### Phase 1: Core Plot Methods (HIGH PRIORITY - Week 1)

Add S3 `plot()` methods for all major object types. These should be **convenience wrappers** around ggplot2, not direct Praat Graphics API exposure.

**Implementation pattern**:
```r
#' @export
plot.Sound <- function(x, from_time = NULL, to_time = NULL, 
                      garnish = TRUE, title = NULL, ...) {
  # Convert to data frame
  df <- x$as_data_frame()
  
  # Filter time range
  if (!is.null(from_time)) df <- df[df$time >= from_time, ]
  if (!is.null(to_time)) df <- df[df$time <= to_time, ]
  
  # Create plot
  p <- ggplot2::ggplot(df, ggplot2::aes(x = time, y = amplitude)) +
    ggplot2::geom_line(color = "steelblue", linewidth = 0.5)
  
  # Add garnish (axes labels, title)
  if (garnish) {
    p <- p + ggplot2::labs(
      title = title %||% "Sound",
      x = "Time (s)",
      y = "Amplitude"
    ) + ggplot2::theme_minimal()
  }
  
  p
}
```

**Objects needing `plot()` methods** (8 implementations):

1. ✅ Already has: PowerCepstrum (via `plot_powercepstrum()`)
2. ❌ **Sound** - Waveform
3. ❌ **Pitch** - F0 contour
4. ❌ **Formant** - Formant tracks (F1-F3)
5. ❌ **Intensity** - Intensity contour
6. ❌ **Spectrogram** - Time-frequency heatmap
7. ❌ **Spectrum** - Frequency spectrum
8. ❌ **Ltas** - Long-term average spectrum
9. ❌ **Harmonicity** - HNR contour
10. ❌ **PointProcess** - Event markers

**Estimated effort**: ~2-3 hours (copy pattern from `plot_powercepstrum()`)

### Phase 2: Combined Visualization Functions (MEDIUM PRIORITY - Week 2)

Add convenience functions for common multi-object visualizations:

```r
#' @export
plot_textgrid_sound <- function(textgrid, sound, tier = 1, 
                                from_time = NULL, to_time = NULL,
                                waveform_color = "steelblue",
                                tier_colors = NULL, ...) {
  # Combine waveform + tier rectangles using gridExtra
  # Return combined plot
}

#' @export  
plot_pitch_intensity <- function(pitch, intensity,
                                 from_time = NULL, to_time = NULL, ...) {
  # Dual-axis plot
}

#' @export
plot_spectrogram_formants <- function(spectrogram, formant,
                                      n_formants = 3,
                                      formant_colors = NULL, ...) {
  # Heatmap + formant overlay
}
```

**Estimated effort**: ~4-5 hours

### Phase 3: Advanced Features (LOW PRIORITY - Future)

- Speckle plots (pitch/formant candidates)
- Cochleagram/Excitation plotting
- Manipulation tier visualization

**Estimated effort**: ~3-4 hours

---

## 5. Technical Implementation Notes

### Design Principles

1. **Use ggplot2, not Praat Graphics API**
   - R users expect ggplot2 objects they can customize
   - Better than trying to wrap Praat's Graphics system
   - Allows integration with tidyverse workflow

2. **S3 `plot()` methods, not `$plot()` R6 methods**
   - Follows R conventions (` plot(object)`)
   - Consistent with base R and other packages
   - Can still add `$plot()` wrappers if desired

3. **Always return ggplot objects**
   - Users can add layers: `plot(sound) + geom_vline(xintercept = 1.5)`
   - Can save with `ggsave()`
   - Compatible with gridExtra/patchwork

4. **Provide sensible defaults, allow customization**
   - `garnish = TRUE` adds labels/axes
   - Color arguments for consistency
   - `...` passed to ggplot for advanced users

### Code Organization

Create new file: `R/plotting-methods.R`

```r
# S3 plot methods for pladdrr objects
# Provides convenient wrappers around ggplot2 for Praat object visualization

#' @export
plot.Sound <- function(...) { }

#' @export  
plot.Pitch <- function(...) { }

# ... etc
```

Add to `NAMESPACE`:
```
S3method(plot, Sound)
S3method(plot, Pitch)
S3method(plot, Formant)
# ... etc
```

### Documentation Strategy

1. **Update `visualization.Rmd` vignette**
   - Show both manual ggplot2 approach AND new `plot()` methods
   - Emphasize that plot methods return customizable ggplot objects

2. **Add section to `getting-started.Rmd`**
   - Quick plotting examples using `plot()`
   - Show most common use cases

3. **Function documentation**
   - Each `plot()` method needs full @param, @return, @examples
   - Link to visualization vignette for advanced usage

---

## 6. Comparison with Parselmouth

Parselmouth (Python) does NOT provide plotting functions - users must use matplotlib manually. 

**pladdrr advantage**: By providing plot() methods, we offer better out-of-box experience than Parselmouth while maintaining customization power.

---

## 7. Summary of Gaps

| Category | Praat Functions | pladdrr Coverage | Gap |
|----------|----------------|------------------|-----|
| **Sound/waveform** | Sound_draw | Manual ggplot2 | No `plot.Sound()` |
| **Pitch** | Pitch_draw, speckles | Manual ggplot2 | No `plot.Pitch()` |
| **Formant** | Formant_drawTracks, speckles | Manual ggplot2 | No `plot.Formant()` |
| **Intensity** | Intensity_draw | Manual ggplot2 | No `plot.Intensity()` |
| **Spectrogram** | Spectrogram_paint | Manual ggplot2 | No `plot.Spectrogram()` |
| **Spectrum** | Spectrum_draw, drawLogFreq | Manual ggplot2 | No `plot.Spectrum()` |
| **LTAS** | Ltas_draw | Manual ggplot2 | No `plot.Ltas()` |
| **Harmonicity** | Harmonicity_draw | Manual ggplot2 | No `plot.Harmonicity()` |
| **PointProcess** | PointProcess_draw | Not implemented | No `plot.PointProcess()` |
| **Cepstrum** | (N/A in Praat Picture) | ✅ `plot_powercepstrum()` | **Better than Praat** |
| **Combined plots** | TextGrid_Sound_draw, etc. | Manual combination | No convenience functions |
| **AVQI/DSI** | (N/A - not in Praat) | ✅ `plot_avqi/dsi()` | **Better than Praat** |

**Overall**: pladdrr provides ~45% coverage of Praat's plotting capabilities, but provides some advanced plots (AVQI, DSI, Cepstrum) that Praat Picture window doesn't have.

---

## 8. Action Items

### Immediate (for v1.0.7)

1. ✅ Document current plotting approach in vignette (already done)
2. ❌ Implement `plot()` S3 methods for 9 core object types
3. ❌ Add `plot_textgrid_sound()` convenience function
4. ❌ Add `plot_pitch_intensity()` convenience function
5. ❌ Update DESCRIPTION Suggests: ggplot2, gridExtra

### Near-term (for v1.1.0)

6. ❌ Implement `plot_spectrogram_formants()`
7. ❌ Add speckle plot support (requires exposing candidate data)
8. ❌ Implement `plot.Cochleagram()` and `plot.Excitation()`

### Documentation

9. ❌ Create `vignettes/plotting-reference.Rmd` - comprehensive plot gallery
10. ❌ Add plotting section to README.md with examples
11. ❌ Update NEWS.md with plotting improvements

---

## 9. Conclusion

**Current Status**: pladdrr's ggplot2-based approach is sound and superior to Praat's Picture window for publication-quality graphics. However, we lack convenience functions that Praat users expect.

**Recommendation**: Implement Phase 1 (core plot() methods) immediately. This is ~3 hours of work for significant UX improvement. The methods should be thin wrappers around ggplot2, allowing full customization while providing sensible defaults.

**Key Insight**: We don't need to replicate Praat's Graphics API - we need to ensure every Praat plot TYPE can be easily created with pladdrr + ggplot2.
