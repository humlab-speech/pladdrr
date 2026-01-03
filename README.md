# pladdrr

**Direct Access to Praat C Functionality from R**

[![Version](https://img.shields.io/badge/version-2.0.0-blue)]()
[![Performance](https://img.shields.io/badge/performance-optimized-brightgreen)]()
[![Rcpp Modules](https://img.shields.io/badge/modules-31-blue)]()
[![Coverage](https://img.shields.io/badge/Praat%20coverage-32%25-orange)]()
[![SIMD](https://img.shields.io/badge/SIMD-enabled-orange)]()

## Overview

`pladdrr` provides **direct, high-performance** access to Praat C functionality from R using Rcpp Modules. Designed for phonetic researchers who need fast, reliable acoustic analysis.

### Key Performance Features

- **Rcpp Modules Architecture** (v2.0.0): 31 Praat modules with direct C++ method dispatch
  - **10-15x faster** overhead vs traditional R6 classes
  - **~8-12µs dispatch** per method (module preloading)
  - **<1% overhead** in typical phonetic workflows
  - Reduces gap to Python's Parselmouth from 5-18x to 2-3x
- **SIMD Vectorization**: Optimized autocorrelation, FFT, formant detection
- **Zero-copy operations**: Efficient memory management for large files
- **Streaming support**: Process files too large for memory with LongSound
- **Advanced modules**: FormantPath (robust tracking), KlattGrid (synthesis), ComplexSpectrogram


## Installation

### Development Version (Recommended)

```r
# Install devtools if needed
if (!require("devtools")) install.packages("devtools")

# Install the humlab-speech fork of av (required for audio I/O)
devtools::install_github("humlab-speech/av")

# Install pladdrr from GitHub
devtools::install_github("humlab-speech/pladdrr")
```

### System Requirements

- **R** >= 4.0.0
- **C++ compiler** with C++17 support
  - macOS: Xcode Command Line Tools (`xcode-select --install`)
  - Linux: GCC >= 7 or Clang >= 5
  - Windows: Rtools >= 4.0
- **FFmpeg** libraries (for av package audio I/O)
  - macOS: `brew install ffmpeg`
  - Ubuntu/Debian: `sudo apt-get install libavfilter-dev`
  - Windows: Included with av package

### Audio I/O

The `pladdrr` package uses the [humlab-speech/av](https://github.com/humlab-speech/av) fork for all audio file operations. This provides:

- Support for **any audio/video format** via FFmpeg (MP3, WAV, FLAC, OGG, AAC, M4A, etc.)
- Fast, efficient audio reading and writing
- No external Praat installation required
- Cross-platform compatibility

### Optional Dependencies

For full functionality:

```r
# Visualization (used in examples)
install.packages("ggplot2")

# Data manipulation (used in vignettes)
install.packages("dplyr")

```

## Features

### Comprehensive Phonetic Analysis

- **Pitch extraction**: F0 tracking with autocorrelation and cross-correlation algorithms
- **Formant analysis**: Burg's algorithm, **FormantPath** (robust multi-ceiling tracking), normalization
- **Speech synthesis**: **KlattGrid** parametric synthesizer for vowel generation and voice morphing
- **Voice quality**: Harmonicity-to-Noise Ratio (HNR), jitter, shimmer measurements  
- **Spectral analysis**: Spectrogram, **ComplexSpectrogram** (phase), Spectrum, LTAS
- **Intensity**: Intensity contours and measurements
- **TextGrid support**: Full read/write with comprehensive annotation workflows
- **Sound operations**: Concatenation, filtering, convolution, time-stretching (9 operations)

### Research Workflows

See `inst/examples/` for complete, real-world workflows:

- **Vowel space analysis** (F1-F2 plots with Lobanov normalization)
- **Large-scale corpus processing** (batch analysis with performance benchmarking)
- **TextGrid-guided analysis** (segmentation + acoustic feature extraction)
- **Voice quality profiling** (HNR, jitter, shimmer, spectral moments)
- **Complete phonetic pipelines** (integrated analysis combining multiple measures)


## Quick Start

```r
library(pladdrr)

# Create a Sound object with a pure tone
sound <- Sound$create_tone(440, duration = 1.0, sampling_frequency = 44100)

# Extract pitch
pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")

# Extract formants (standard)
formant <- sound$to_formant_burg(
  time_step = 0.01,
  max_number_of_formants = 5,
  maximum_formant = 5500,
  window_length = 0.025,
  pre_emphasis_from = 50
)

# Get formant values at a specific time
f1 <- formant$get_value_at_time(formant_number = 1, time = 0.5, unit = "hertz")
f2 <- formant$get_value_at_time(formant_number = 2, time = 0.5, unit = "hertz")

# Voice quality analysis
harmonicity <- sound$to_harmonicity_cc(time_step = 0.01, minimum_pitch = 75)
hnr <- harmonicity$get_mean(from_time = 0, to_time = 0)
```

### NEW in v2.0: Advanced Features

```r
# Robust formant tracking with FormantPath (Phase 2.2)
fp <- sound$to_formant_path(
  time_step = 0.005,
  formant_ceiling = 5500,
  num_steps_up_down = 2L  # Test 5 different ceilings
)
formant_robust <- fp$extract_formant()  # Get optimal track

# Speech synthesis with KlattGrid (Phase 2.3)
kg <- KlattGrid_createFromVowel(
  duration = 0.5,
  f0start = 120,           # Pitch in Hz
  f1 = 730, b1 = 80,       # F1 + bandwidth
  f2 = 1090, b2 = 120,     # F2 + bandwidth
  f3 = 2440, b3 = 150      # F3 + bandwidth
)
synthetic_vowel <- kg$to_sound()

# Analysis-resynthesis workflow
fp <- sound$to_formant_path(num_steps_up_down = 2L)
formant <- fp$extract_formant()
df <- as.data.frame(formant)
f1_mean <- mean(df[df$formant == 1, "frequency"], na.rm = TRUE)
f2_mean <- mean(df[df$formant == 2, "frequency"], na.rm = TRUE)
f3_mean <- mean(df[df$formant == 3, "frequency"], na.rm = TRUE)

# Resynthesize with extracted formants
kg_resynth <- KlattGrid_createFromVowel(
  duration = 0.5, f0start = 120,
  f1 = f1_mean, b1 = 80,
  f2 = f2_mean, b2 = 120,
  f3 = f3_mean, b3 = 150
)
sound_resynth <- kg_resynth$to_sound()
```

## Usage Examples

### Object-Oriented Interface

All Praat objects are R6 classes with methods that mirror Praat's native commands:

```r
# Create Sound objects
sound <- Sound$create_tone(440, duration = 2.0, sampling_frequency = 44100)

# Praat: "To Pitch..." → R: to_pitch()
pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)

# Praat: "Get mean..." → R: get_mean()
mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")

# Chain operations
intensity <- sound$to_intensity(minimum_pitch = 100, time_step = 0.0, subtract_mean = TRUE)
mean_db <- intensity$get_mean(from_time = 0, to_time = 0)
```

### TextGrid Workflows

```r
# Create a TextGrid
tg <- TextGrid$create(tmin = 0, tmax = 2.0)

# Add interval tier
tg$insert_interval_tier(position = 1, name = "words")
tg$insert_boundary(tier = 1, time = 0.5)
tg$insert_boundary(tier = 1, time = 1.0)
tg$insert_boundary(tier = 1, time = 1.5)

# Set labels
tg$set_label(tier = 1, index = 1, text = "the")
tg$set_label(tier = 1, index = 2, text = "quick")
tg$set_label(tier = 1, index = 3, text = "brown")

# Query intervals
n_intervals <- tg$get_number_of_intervals(tier = 1)
label <- tg$get_label_of_interval(tier = 1, interval_number = 2)
```

### Batch Processing

```r
# Process multiple files
library(pladdrr)

process_file <- function(wav_path) {
  sound <- Sound$new(wav_path)
  
  # Extract multiple features
  pitch <- sound$to_pitch()
  formant <- sound$to_formant_burg()
  intensity <- sound$to_intensity()
  
  # Return data frame
  data.frame(
    file = basename(wav_path),
    mean_f0 = pitch$get_mean(),
    f1 = formant$get_value_at_time(1, sound$get_total_duration() / 2),
    f2 = formant$get_value_at_time(2, sound$get_total_duration() / 2),
    mean_intensity = intensity$get_mean()
  )
}

# Process corpus
results <- lapply(wav_files, process_file)
corpus_data <- do.call(rbind, results)
```

## Architecture

**Object-Oriented Design**: R6 classes with external pointers to Praat C++ objects

```
R User Code
    ↓
R6 Classes (Sound, Pitch, Formant, TextGrid, etc.)
    ↓
External Pointers (Rcpp XPtr - zero-copy)
    ↓
C++ Wrappers (src/*_wrappers.cpp)
    ↓
Praat C++ Objects (src/praat/ - native Praat code)
```

**Benefits**:
- Type-safe method calls with autocomplete support
- Automatic memory management (XPtr finalizers)
- No Python dependency (unlike Parselmouth)
- Direct C++ performance
- Familiar syntax for Praat users

## Implemented Objects

The package includes 17+ Praat object types with 300+ methods:

### Core Analysis
- **Sound** (~50 methods) - Audio I/O, manipulation, filtering
- **Pitch** (~30 methods) - F0 extraction and analysis
- **Formant** (~23 methods) - Formant tracking and queries
- **Intensity** (~15 methods) - Intensity contours
- **Harmonicity** (~15 methods) - Voice quality (HNR)

### Spectral Analysis
- **Spectrogram** (~15 methods) - Time-frequency representation
- **Spectrum** (~18 methods) - Frequency-domain analysis
- **Ltas** (~12 methods) - Long-term average spectrum

### Manipulation & Tiers
- **Manipulation** (~12 methods) - PSOLA pitch/duration modification
- **PitchTier** (~12 methods) - Pitch contour editing
- **IntensityTier** (~10 methods) - Intensity modification
- **DurationTier** (~10 methods) - Duration control
- **AmplitudeTier** (~10 methods) - Amplitude envelopes

### Annotation & Data
- **TextGrid** (~34 methods) - Annotation and segmentation
- **PointProcess** (~20 methods) - Time points (e.g., glottal pulses)
- **Matrix** (~18 methods) - 2D numerical arrays
- **Table** (~20 methods) - Tabular data structures

See `vignette("integrated-phonetic-analysis")` for complete workflow examples.


## Documentation

### Vignettes

Three comprehensive guides are available:

```r
# Complete phonetic analysis workflow
vignette("integrated-phonetic-analysis", package = "pladdrr")

# Vowel acoustics research pipeline  
vignette("vowel-space-analysis", package = "pladdrr")

# TextGrid annotation and corpus processing
vignette("textgrid-workflows", package = "pladdrr")
```

### Examples

Nine complete, real-world examples in `inst/examples/`:

1. **Basic Analysis** - Pitch, formant, intensity extraction
2. **Voice Quality** - HNR, jitter, shimmer measurements
3. **Spectral Analysis** - Spectrogram, spectrum, spectral moments
4. **Spectral Moments** - COG, standard deviation, skewness, kurtosis
5. **Complete Workflow** - Multi-measure feature extraction
6. **TextGrid Analysis** - Annotation-guided segmentation
7. **Comprehensive Phonetic Analysis** - Integrated TextGrid + acoustics
8. **Corpus Processing** - Large-scale batch analysis with benchmarking
9. **Vowel Space Analysis** - F1-F2 trajectories with normalization

Run examples:
```r
# View example code
file.show(system.file("examples", "07_comprehensive_phonetic_analysis.R", package = "pladdrr"))

# Run example (after installing pladdrr)
source(system.file("examples", "07_comprehensive_phonetic_analysis.R", package = "pladdrr"))
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

GPL-3

## References

- [Praat](https://www.fon.hum.uva.nl/praat/) - Doing phonetics by computer
- [Rcpp](https://www.rcpp.org/) - Seamless R and C++ Integration

## Contact

For questions and feedback, please open an issue on GitHub.
