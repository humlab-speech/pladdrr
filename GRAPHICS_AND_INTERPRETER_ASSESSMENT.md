# Graphics System and Interpreter Assessment
**Date**: 2025-11-13  
**Package Version**: 0.4.1  
**Status**: Feasibility Analysis and Roadmap

---

## Executive Summary

Assessment of two major Praat features currently excluded from the `speaker` package:
1. **Praat Graphics System** - The Picture window plotting functionality
2. **Praat Script Interpreter** - Ability to execute unmodified Praat scripts

### Key Findings

1. **Graphics System**: Technically feasible but unnecessary - R has superior plotting
2. **Interpreter**: Extremely complex - systematic transcoding is better approach

---

## Part 1: Praat Graphics System

### Current Status

✅ **Graphics stubs implemented** in `src/graphics_stubs.cpp`:
- ~20 stub functions for NO_GRAPHICS builds
- Prevent compilation errors when Praat code calls graphics functions
- All graphics calls are no-ops

### What Praat Graphics Provides

The Praat Picture window offers:

1. **Specialized Phonetic Plots**:
   - Spectrograms with formant overlay
   - Pitch contours with time alignment
   - Waveform + spectrogram + pitch composite plots
   - TextGrid alignment visualization
   - IPA charts, vowel plots

2. **Publication-Ready Output**:
   - EPS, PDF, PNG export
   - Precise control of sizes, fonts, colors
   - Layer-based drawing system
   - PostScript-quality output

3. **Interactive Drawing**:
   - Click-and-drag annotations
   - Manual markup of spectrograms
   - Custom shapes and text

### Implementation Requirements

**If we were to fully implement Praat graphics**:

#### Required Components

1. **Graphics Device Backend** (~10,000 lines)
   - `src/praat/sys/Graphics.cpp` (2,700 lines)
   - `src/praat/sys/Graphics_*.cpp` (many files)
   - PostScript/PDF rendering engine
   - Coordinate transformations
   - Font management
   - Color management

2. **Picture Window Integration** (~5,000 lines)
   - `src/praat/sys/praat_picture.cpp` (2,600 lines)
   - Window management (X11/Quartz/Win32)
   - Event handling (mouse, keyboard)
   - Selection and editing tools

3. **R Graphics Device** (~2,000 lines)
   - Custom R graphics device implementation
   - Translation layer: Praat drawing → R grid/graphics
   - Device driver in C++ using R's graphics API

4. **Plotting Methods** (~20,000 lines)
   - All `paint()`, `draw()`, `speckle()` methods
   - For every Praat object (Sound, Pitch, Formant, Spectrogram, etc.)
   - Currently stubbed out in NO_GRAPHICS builds

**Total Effort**: ~40,000 lines of code, 6-8 weeks

#### Challenges

1. **Platform Dependencies**:
   - Different windowing systems (X11, Quartz, Win32)
   - Font rendering varies by platform
   - Testing on all platforms required

2. **R Integration**:
   - R has its own graphics system (grid, graphics, ggplot2)
   - Need translation layer between Praat and R paradigms
   - Coordinate system mismatches

3. **Maintenance Burden**:
   - Graphics code is complex and fragile
   - Platform-specific bugs common
   - Ongoing maintenance required

### Alternative: Use R Graphics

**Recommended Approach**: Leverage R's excellent plotting ecosystem

#### R Plotting Capabilities

1. **Base R Graphics**:
   ```r
   # Waveform
   plot(sound$as_matrix()[,1], type='l', xlab="Time", ylab="Amplitude")
   
   # Spectrogram
   spec <- sound$to_spectrogram()
   image(spec$as_matrix(), col=heat.colors(256))
   ```

2. **ggplot2** (publication quality):
   ```r
   library(ggplot2)
   
   # Pitch contour
   pitch_df <- pitch$as_data_frame()
   ggplot(pitch_df, aes(time, frequency)) +
     geom_line() +
     theme_minimal() +
     labs(title="F0 Contour", x="Time (s)", y="F0 (Hz)")
   
   # Formant plot
   formant_df <- formant$as_data_frame()
   ggplot(formant_df, aes(time, frequency, color=factor(formant_number))) +
     geom_line() +
     scale_color_discrete(name="Formant")
   ```

3. **phonR package** (vowel plots):
   ```r
   library(phonR)
   plotVowels(f1, f2, vowel, plot.tokens=TRUE, ellipse.line=TRUE)
   ```

4. **emuR package** (EMU-SDMS, spectrogram overlays):
   ```r
   library(emuR)
   # Specialized phonetic visualizations
   ```

5. **Custom composite plots**:
   ```r
   library(patchwork)
   
   p1 <- ggplot(wave_df) + geom_line(aes(time, amplitude))
   p2 <- ggplot(spec_df) + geom_raster(aes(time, freq, fill=power))
   p3 <- ggplot(pitch_df) + geom_line(aes(time, f0))
   
   p1 / p2 / p3  # Stacked composite plot
   ```

#### Advantages of R Graphics

✅ **Better than Praat graphics**:
- ggplot2 produces publication-quality output
- More flexible and customizable
- Wider range of plot types
- Better statistical graphics integration
- Active development and support
- Works seamlessly with tidyverse
- Export to any format (PDF, PNG, SVG, TIFF, etc.)

✅ **Already familiar to R users**:
- No new syntax to learn
- Uses standard R plotting workflows
- Integrates with RStudio's plot viewer
- Works with knitr/rmarkdown

✅ **Zero maintenance burden**:
- We don't need to maintain graphics code
- R Core handles platform differences
- Package updates are automatic

### Decision: Graphics System

**❌ DO NOT IMPLEMENT** Praat graphics system

**✅ INSTEAD**:
1. Provide `as_data_frame()` and `as_matrix()` for all objects
2. Create vignette showing common plotting patterns with ggplot2
3. Provide example plotting functions in `inst/examples/plotting.R`
4. Document R graphics alternatives in README

**Rationale**:
- R graphics are superior to Praat graphics
- Users already know ggplot2
- Massive implementation cost for inferior result
- Maintenance burden too high

---

## Part 2: Praat Script Interpreter

### Current Status

❌ **Not implemented** - Users must transcode Praat scripts to R

### What the Interpreter Would Provide

Ability to run unmodified Praat scripts:

```praat
# Original Praat script
sound = Read from file: "audio.wav"
pitch = To Pitch: 0.01, 75, 600
meanF0 = Get mean: 0, 0, "Hertz"
writeInfoLine: "Mean F0: ", meanF0
```

Would execute directly in R without conversion.

### Implementation Requirements

#### Core Components

1. **Lexer** (~1,000 lines)
   - Tokenize Praat script syntax
   - Handle string literals, numbers, identifiers
   - Line continuation, comments

2. **Parser** (~3,000 lines)
   - Build abstract syntax tree (AST)
   - Handle all Praat syntax:
     - Variable assignments
     - Object creation and method calls
     - Control flow (if, for, while, repeat)
     - Procedures and functions
     - Form definitions (user input dialogs)
     - String interpolation
   - Operator precedence
   - Error reporting

3. **Object Store** (~1,000 lines)
   - Manage Praat's object window
   - Object selection and naming
   - Object ID generation
   - Plus/minus selection

4. **Method Dispatcher** (~2,000 lines)
   - Map Praat command strings to C++ methods
   - Handle all commands for all object types
   - Variable argument parsing
   - Return value handling
   - Example: `"To Pitch: 0.01, 75, 600"` → `sound_to_pitch_ac(...)`

5. **Runtime Environment** (~2,000 lines)
   - Variable scoping
   - String and number operations
   - Array handling
   - Procedure call stack
   - Info window output

6. **Built-in Functions** (~1,000 lines)
   - Math: sin, cos, exp, log, sqrt, abs, round, etc.
   - String: index, rindex, replace$, left$, right$, mid$, etc.
   - File I/O: readFile, writeFile, appendFile, etc.
   - System: date$, chooseReadFile$, etc.

7. **Control Flow** (~1,000 lines)
   - if...elsif...else...endif
   - for...endfor
   - while...endwhile
   - repeat...until
   - Break and next

8. **Form System** (~1,000 lines)
   - Define user input dialogs
   - Field types: real, integer, text, boolean, choice, etc.
   - Default values
   - Generate R Shiny equivalent or use tcltk

**Total Effort**: ~12,000 lines of code, 8-12 weeks

#### Example: What Needs to Be Parsed

```praat
# Complex Praat script example
form Voice analysis
  sentence Sound_file audio.wav
  positive Pitch_floor 75
  positive Pitch_ceiling 600
  comment Analysis settings
  boolean Include_voicing 1
endform

# Read sound
sound = Read from file: sound_file$

# Extract pitch
selectObject: sound
pitch = To Pitch: 0.01, pitch_floor, pitch_ceiling

# Get statistics
meanF0 = Get mean: 0, 0, "Hertz"
sdF0 = Get standard deviation: 0, 0, "Hertz"

# Conditional logic
if include_voicing
  pointProcess = To PointProcess
  selectObject: sound, pointProcess
  voiceReport$ = Voice report: 0, 0, 75, 600, 1.3, 1.6, 0.03, 0.45
  appendInfoLine: voiceReport$
endif

# Output
writeInfoLine: "Mean F0: ", meanF0, " Hz"
appendInfoLine: "SD F0: ", sdF0, " Hz"

# Cleanup
removeObject: sound, pitch
if include_voicing
  removeObject: pointProcess
endif
```

All of this syntax would need parsing, execution, and runtime support.

#### Challenges

1. **Syntax Complexity**:
   - Praat has many syntactic quirks
   - String vs numeric context switching
   - Implicit type conversions
   - Unusual scoping rules

2. **Object Model Mismatch**:
   - Praat: Object window with IDs and selection
   - R: Variables with object references
   - Need to simulate Praat's object management

3. **Form System**:
   - Interactive dialogs don't fit batch processing
   - Would need R GUI integration (tcltk or Shiny)
   - Or command-line parameter conversion

4. **Info Window**:
   - Praat outputs to "Info" window
   - Would need to capture and display
   - Or redirect to R console

5. **File Paths**:
   - Praat uses its own path conventions
   - Need translation to R/OS paths

6. **Testing Complexity**:
   - Need large corpus of Praat scripts for testing
   - Every syntax edge case must be handled
   - Regression testing for compatibility

7. **Maintenance**:
   - Praat syntax may change
   - Must stay compatible with Praat updates
   - Bug reports for interpreter vs. actual code

### Alternative: Systematic Transcoding

**Recommended Approach**: Provide tools and documentation for manual conversion

#### Transcoding Patterns

The package already provides 1:1 mapping for most Praat commands:

| Praat Command | R Equivalent |
|---------------|--------------|
| `Read from file: "audio.wav"` | `Sound$new("audio.wav")` |
| `To Pitch: 0.01, 75, 600` | `sound$to_pitch(time_step=0.01, pitch_floor=75, pitch_ceiling=600)` |
| `Get mean: 0, 0, "Hertz"` | `pitch$get_mean(from_time=0, to_time=0, unit="hertz")` |
| `selectObject: sound` | (not needed - use variable directly) |
| `removeObject: sound` | `rm(sound)` (automatic GC) |

#### Conversion Tools

1. **Naming Convention Documentation**:
   - Complete mapping table in vignette
   - Search functionality by Praat command name
   - Examples for every common pattern

2. **Semi-Automated Converter** (Simple):
   - R script to assist conversion (not full interpreter)
   - Pattern matching for common commands
   - Requires manual review and editing
   - ~500 lines, 1 week effort

Example semi-automated tool:
```r
convert_praat_script <- function(praat_file, output_file) {
  # Read Praat script
  lines <- readLines(praat_file)
  
  # Simple pattern replacements
  r_code <- lines %>%
    str_replace("Read from file: \"(.+)\"", "Sound$new(\"\\1\")") %>%
    str_replace("To Pitch: (.+)", "to_pitch(\\1)") %>%
    str_replace("Get mean: (.+)", "get_mean(\\1)") %>%
    # ... more patterns
    
  # Write R code
  writeLines(r_code, output_file)
  message("Manual review required - see ", output_file)
}
```

3. **Migration Guide Vignette**:
   - Step-by-step conversion examples
   - Before/after code samples
   - Common pitfalls and solutions
   - Control flow conversion patterns

#### Advantages of Transcoding

✅ **Better code quality**:
- Native R code, not emulated
- Easier to debug
- More performant
- Can use R's full capabilities

✅ **Better integration**:
- Works with tidyverse
- Can mix Praat and R functions
- Use R's control flow and functions
- Easier to extend and modify

✅ **Learning opportunity**:
- Users learn R properly
- Not locked into Praat paradigm
- Can improve their analysis

✅ **Zero maintenance**:
- No interpreter to maintain
- No syntax compatibility issues
- No runtime bugs

### Decision: Script Interpreter

**❌ DO NOT IMPLEMENT** full Praat script interpreter (for v1.0)

**✅ INSTEAD**:
1. Complete naming convention documentation
2. Create comprehensive migration guide vignette
3. Provide semi-automated conversion assistant tool
4. Include before/after examples for common patterns
5. Document all differences in script-to-R mapping

**Consider for v2.0+**:
- If there is overwhelming user demand
- If grant funding available
- As separate package `speaker.interpreter`
- Using formal parsing library (Rcpp + Boost.Spirit, or antlr4)

**Rationale**:
- Huge implementation cost (12,000+ lines, 8-12 weeks)
- High maintenance burden
- Limited benefit (R code is better)
- Most users want integration, not emulation
- Semi-automated conversion is sufficient

---

## Part 3: LPC Synthesis

### Current Status

⚠️ **Partially implemented**:
- LPC analysis: ❌ Not available
- LPC synthesis for Manipulation: ❌ Stubbed out
- Alternative (PSOLA): ✅ Fully functional

### What LPC Would Provide

**Linear Predictive Coding**:
1. Vocal tract modeling
2. Alternative formant extraction
3. LPC-based resynthesis (inferior to PSOLA)
4. Speech coding applications

### Implementation Requirements

#### Required Praat Modules

1. **LPC Class** (~2,000 lines)
   - `src/praat/LPC/LPC.cpp`
   - `src/praat/LPC/LPC.h`
   - Coefficient storage and queries

2. **LPC Analysis** (~3,000 lines)
   - `src/praat/LPC/Sound_and_LPC.cpp`
   - `src/praat/LPC/Sound_and_LPC_robust.cpp`
   - Burg algorithm, covariance method
   - Requires NUM (numerical) library

3. **LPC Synthesis** (~1,000 lines)
   - `src/praat/LPC/LPC_and_Formant.cpp`
   - `src/praat/LPC/LPC_and_Polynomial.cpp`
   - Requires Formant, Polynomial modules

4. **Dependencies**:
   - NUM library (numerical methods)
   - Polynomial class
   - Additional matrix operations

**Total Effort**: ~6,000 lines, 2-3 weeks

### Alternative: Focus on PSOLA

PSOLA (Pitch-Synchronous Overlap-Add) is superior to LPC for:
- Pitch modification ✅
- Time-stretching ✅
- Voice quality preservation ✅
- Industry-standard method ✅

LPC synthesis is mainly used for:
- Historical compatibility
- Some research applications
- Not commonly used anymore

### Decision: LPC Module

**⏸️ DEFER to v1.1.0** or later

**✅ CURRENT VERSION**:
- Keep PSOLA synthesis (already implemented)
- Document that LPC is not available
- Note in DESCRIPTION: "PSOLA resynthesis only"

**Consider for v1.1.0**:
- If users request LPC analysis specifically
- Separate PR focused on LPC module
- Full integration with dependencies

**Rationale**:
- PSOLA is superior and already works
- LPC rarely used in modern workflows
- Adds complexity and dependencies
- Can add later if needed

---

## Recommended Roadmap

### v1.0.0 (Current Focus)

✅ **Include**:
- All core Praat objects (Sound, Pitch, Formant, etc.) - DONE
- PSOLA synthesis via Manipulation - DONE
- Data export methods (as_data_frame, as_matrix) - DONE
- Examples directory with common analyses - DONE

❌ **Exclude**:
- Praat graphics system → Use R graphics
- Script interpreter → Use transcoding
- LPC module → Use PSOLA

📝 **Documentation**:
- Create vignette: "Plotting with ggplot2"
- Create vignette: "Converting Praat Scripts to R"
- Create semi-automated conversion tool
- Document all transcoding patterns

### v1.1.0 (Future)

**Potential Additions**:
- LPC module (if requested)
- Enhanced conversion tools
- More example scripts
- Performance optimizations

### v2.0.0 (Far Future)

**Major Features** (if demand exists):
- Script interpreter as separate package
- Integration with other phonetic tools
- Advanced analysis pipelines

---

## Documentation Updates Needed

### 1. CLAUDE.md

Add section:

```markdown
## Excluded Features and Alternatives

### Praat Graphics System

**Status**: Not implemented  
**Alternative**: Use R graphics (ggplot2, phonR)

Praat's Picture window is not available. Instead:
- Use `as_data_frame()` to get data
- Plot with ggplot2 for publication quality
- See `vignettes/plotting.Rmd` for examples

### Praat Script Interpreter

**Status**: Not implemented  
**Alternative**: Transcode scripts to R

Cannot run Praat scripts directly. Instead:
- Use systematic naming conventions for conversion
- See `vignettes/praat-to-r.Rmd` for migration guide
- Use `convert_praat_script()` helper for semi-automation

### LPC Synthesis

**Status**: Not implemented  
**Alternative**: Use PSOLA (better quality)

LPC-based resynthesis is not available. Use PSOLA instead:
- `manipulation$get_resynthesis_overlap_add()` ✅
- PSOLA is industry standard and higher quality
```

### 2. README.md

Add "Features" section:

```markdown
## Features

✅ **Included**:
- 18 Praat objects as R6 classes
- ~330 methods covering core phonetic analysis
- PSOLA-based pitch/duration modification
- Full TextGrid support
- Voice quality metrics (jitter, shimmer, HNR)
- Spectral analysis (spectrograms, formants, etc.)
- Zero Python dependency

❌ **Not Included** (use R alternatives):
- Praat graphics → Use ggplot2
- Praat script interpreter → Use transcoding guide
- LPC synthesis → Use PSOLA (superior)

## Advantages over Parselmouth

- 🚀 Faster (no Python overhead)
- 💡 Better R integration (autocomplete, type safety)
- 📚 Native R documentation
- 🔧 Direct method calls (no praat.call dispatcher)
- 🎯 Systematic naming for easy script conversion
```

### 3. New Vignette: `vignettes/plotting.Rmd`

```markdown
---
title: "Plotting Phonetic Data with ggplot2"
output: rmarkdown::html_vignette
---

This vignette shows how to create publication-quality plots using
speaker package data and R's graphics ecosystem.

## Why R Graphics Instead of Praat Graphics?

- Better quality output
- More flexible and customizable
- Familiar to R users
- Integration with tidyverse

## Common Plots

### Waveform
### Pitch Contour
### Spectrogram
### Formant Tracks
### Composite Plots (wave + spec + pitch)
### Vowel Spaces
```

### 4. New Vignette: `vignettes/praat-to-r.Rmd`

```markdown
---
title: "Converting Praat Scripts to R"
output: rmarkdown::html_vignette
---

Guide to migrating Praat scripts to speaker R code.

## Naming Conventions
## Object Management
## Control Flow
## Form Dialogs → Function Parameters
## Before/After Examples
## Semi-Automated Conversion Tool
```

---

## Summary and Recommendations

### Graphics System: ❌ Do Not Implement

- **Effort**: 6-8 weeks
- **Benefit**: Low (R graphics are better)
- **Maintenance**: High
- **Decision**: Document R graphics alternatives instead

### Script Interpreter: ❌ Do Not Implement (v1.0)

- **Effort**: 8-12 weeks
- **Benefit**: Medium (convenience only)
- **Maintenance**: Very high
- **Decision**: Provide transcoding guide and semi-automated tools
- **Future**: Consider for v2.0+ if high demand

### LPC Module: ⏸️ Defer to v1.1.0

- **Effort**: 2-3 weeks
- **Benefit**: Low (PSOLA is better)
- **Maintenance**: Medium
- **Decision**: Keep PSOLA, add LPC later if requested

### Next Steps

1. ✅ Create assessment document (this file)
2. ⬜ Update CLAUDE.md with decisions
3. ⬜ Update README.md with features list
4. ⬜ Create `vignettes/plotting.Rmd`
5. ⬜ Create `vignettes/praat-to-r.Rmd`
6. ⬜ Create semi-automated conversion tool
7. ⬜ Document in NEWS.md
8. ⬜ Proceed with v1.0.0 finalization

---

**Conclusion**: Focus on completing what we have (18 objects, 330+ methods), document alternatives for excluded features, and create excellent migration guides. This delivers maximum value with minimal maintenance burden.
