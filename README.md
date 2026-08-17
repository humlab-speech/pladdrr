# pladdrr

**Direct Access to Praat C Functionality from R**

<!-- badges: start -->
[![Project Status: Active – the project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![R-CMD-check](https://github.com/humlab-speech/pladdrr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/humlab-speech/pladdrr/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/humlab-speech/pladdrr/graph/badge.svg)](https://app.codecov.io/gh/humlab-speech/pladdrr)
[![lintr](https://github.com/humlab-speech/pladdrr/actions/workflows/lintr.yml/badge.svg?branch=main)](https://github.com/humlab-speech/pladdrr/actions/workflows/lintr.yml)
[![License: GPL v3](https://img.shields.io/badge/license-GPL--3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
![GitHub R package version](https://img.shields.io/github/r-package/v/humlab-speech/pladdrr?label=version)
![Rcpp Modules](https://img.shields.io/badge/modules-38-blue)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.21884218.svg)](https://doi.org/10.5281/zenodo.21884218)

<!-- badges: end -->

## Overview

The `pladdrr` package provides R users with direct access to the functionalities of [Praat](https://praat.org) through a consistent Object Oriented interface, enabling conversion of Praat scripts to self-contained R implementations. 

Direct access to Praat's C code base from R is achieved through Rcpp Modules and generated methods associated with Praat Objects of several types (38 Rcpp Modules in total):

### Speech Signal Analysis

- **Pitch extraction**: F0 tracking with autocorrelation and cross-correlation algorithms
- **Formant analysis**: Burg's algorithm, **FormantPath** (robust multi-ceiling tracking), **FormantModeler** (polynomial trajectory modeling)
- **Speech features**: **MFCC/LFCC** extraction for speech and speaker recognition
- **Speech synthesis**: **KlattGrid** parametric synthesizer for vowel generation and voice morphing
- **Voice quality**: Harmonicity-to-Noise Ratio (HNR), jitter, shimmer measurements
- **Spectral analysis**: Spectrogram, **ComplexSpectrogram** (phase), Spectrum, LTAS
- **Intensity**: Intensity contours and measurements
- **TextGrid support**: Read/write with comprehensive annotation workflows
- **Sound operations**: Concatenation, filtering, convolution, time-stretching (9 operations)

### Statistical Analysis

- **DTW**: Dynamic Time Warping for sound and cepstral coefficient alignment
- **PCA**: Principal Component Analysis from TableOfReal or Covariance matrices
- **Discriminant**: Linear discriminant analysis with classification tables
- **FormantModeler**: Polynomial modeling with outlier detection and optimal ceiling estimation


We have extended the media handling capabilities substantially to include all formats supported by the [libav C library](https://github.com/libav/libav) (using the [av](https://CRAN.R-project.org/package=av) R package), which is most audio and video formats and containers in mainstream use today. Media loading defaults to using Praat's native routines. However, if the format is not natively supported by Praat, the package falls back to the libav library, loading and converting formats in memory.


To provide optimized processing, the package leverages optimizations from the C/C++ code bases, including

- **SIMD Vectorization**: Optimized autocorrelation, FFT, formant detection
- **Zero-copy operations**: Avoid unnecessary data copying when processing large files
- **Streaming support**: Process files too large for memory with LongSound

The package provides three tiers of access to Praat's methods, with Tier 1 being most human friendly, Tier 2 provides more direct access to the C routines of Praat, and Tier 3 offers batch and parallel processing for common use cases. Tier 4 provides some abilities for parallel / batch processing of files, if beneficial. We provide coding agent friendly documentation of the package's capabilities in [inst/agents/AGENT_GUIDE.md](inst/agents/AGENT_GUIDE.md). 

## Limitations and caveats

The `pladdrr` package is developed to fill our own internal needs and is designed to support the development of R-based implementations of Praat scripts for use in R workflows and scripts. The package exposes all modules we have found a use for in our re-implementation efforts, but extensions to new Object type will require separate development effort. 

We do not expose a fully working interpreter that has been extensively tested. Further, we have opted to not expose the full graphics system of Praat to the user to avoid inclusion of platform specific graphics libraries that are not the core functionality uniquely contributed by Praat. Instead, we plan to make use of the already excellent plotting functionality of R for visualization.

## Other similar packages

This package was developed to serve our specific needs and does not suit everyone. If our needs do not overlap with yours, please consider these alternative routes to do what you want:

- [parselmouth](https://github.com/YannickJadoul/Parselmouth) is a Python package which directly exposes the abilities of the Praat C code base and also lets you run a full script. As a Python package, it can be called in R using the `reticulate` package. It provides all functionality of Praat as far as we can tell, but cannot produce for instance PDF versions of a Praat drawing.
- [speakr](https://github.com/stefanocoretta/speakr) makes the functionality of Praat available to R users by using the Praat executable as a DSP engine. As such it can be used to do all that Praat could do, but may struggle with parallelism and relies on callouts to the shell that can be inefficient and sensitive to errors in expectations at the handoff between R and Praat.

## Documentation

- Run `browseVignettes("pladdrr")` after installation for packaged articles
- See `inst/examples/` for end-to-end workflows
- Use `help(package = "pladdrr")` for the installed reference index


## Installation

### Development Version (Recommended)

```r
# Install devtools if needed
if (!require("devtools")) install.packages("devtools")

# Install the 'av' package for audio I/O. Our fork is recommended for all users who also want to use reindeer 
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


### Optional Dependencies

For full functionality:

```r
# Visualization (used in examples)
install.packages("ggplot2")

# Data manipulation (used in vignettes)
install.packages("dplyr")

```



## Quick Start

```r
library(pladdrr)

# Create a Sound object with a pure tone
sound <- Sound$create_tone(frequency = 440, duration = 1.0, sampling_rate = 44100)

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
harmonicity <- sound$to_harmonicity_cc(time_step = 0.01, min_pitch = 75)
hnr <- harmonicity$get_mean(from_time = 0, to_time = 0)
```

### Advanced Features

```r
# Robust formant tracking with FormantPath
fp <- sound$to_formant_path(
  time_step = 0.005,
  formant_ceiling = 5500,
  num_steps_up_down = 2L  # Test 5 different ceilings
)
formant_robust <- fp$extract_formant()  # Get optimal track

# MFCC extraction for speech recognition (v4.6.8)
mfcc <- sound$to_mfcc(
  num_coefficients = 13,    # Standard for ASR
  analysis_width = 0.025,   # 25ms window
  time_step = 0.01          # 10ms hop
)

# Speech synthesis with KlattGrid
kg <- KlattGrid_createFromVowel(
  duration = 0.5,
  f0start = 120,           # Pitch in Hz
  f1 = 730, b1 = 80,       # F1 + bandwidth
  f2 = 1090, b2 = 120,     # F2 + bandwidth
  f3 = 2440, b3 = 150      # F3 + bandwidth
)
synthetic_vowel <- kg$to_sound()
```

## Usage Examples

### Object-Oriented Interface

All Praat objects are exposed to as R objects with methods that mirror Praat's native commands:

```r
# Create Sound objects
sound <- Sound$create_tone(frequency = 440, duration = 2.0, sampling_rate = 44100)

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
# Create a TextGrid with one interval tier (tiers must exist at creation time)
tg <- TextGrid$create(tmin = 0, tmax = 2.0, tier_names = "words")

# Add boundaries
tg$insert_boundary(tier = 1, time = 0.5)
tg$insert_boundary(tier = 1, time = 1.0)
tg$insert_boundary(tier = 1, time = 1.5)

# Set labels
tg$set_interval_text(tier = 1, interval_number = 1, text = "the")
tg$set_interval_text(tier = 1, interval_number = 2, text = "quick")
tg$set_interval_text(tier = 1, interval_number = 3, text = "brown")

# Query intervals
n_intervals <- tg$get_number_of_intervals(tier = 1)
label <- tg$get_interval_text(tier = 1, interval_number = 2)
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

### More specialized research workflows

See `inst/examples/` for complete, real-world workflows:

- **Vowel space analysis** (F1-F2 plots with Lobanov normalization)
- **Large-scale corpus processing** (batch analysis with performance benchmarking)
- **TextGrid-guided analysis** (segmentation + acoustic feature extraction)
- **Voice quality profiling** (HNR, jitter, shimmer, spectral moments)
- **Complete phonetic pipelines** (integrated analysis combining multiple measures)



# Implmentation details

## Implemented Objects

The package includes 38 Rcpp modules covering 20+ Praat object types with 500+ methods:

### Core Analysis
- **Sound** (~50 methods) - Audio I/O, manipulation, filtering
- **Pitch** (~30 methods) - F0 extraction and analysis
- **Formant** (~23 methods) - Formant tracking and queries
- **Intensity** (~15 methods) - Intensity contours
- **Harmonicity** (~15 methods) - Voice quality (HNR)

### Spectral & Speech Features
- **Spectrogram** (~15 methods) - Time-frequency representation
- **Spectrum** (~18 methods) - Frequency-domain analysis
- **Ltas** (~12 methods) - Long-term average spectrum
- **MFCC/LFCC** (~15 methods) - Cepstral coefficients for speech recognition

### Statistical Analysis
- **PCA** - Principal Component Analysis
- **Discriminant** - Linear discriminant analysis with classification
- **DTW** - Dynamic Time Warping for signal alignment
- **FormantModeler** - Polynomial formant trajectory modeling

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

16 vignettes are available covering analysis workflows, resynthesis, formant tracking, speech synthesis, and migration guides. Highlights:

```r
# Complete phonetic analysis workflow
vignette("integrated-phonetic-analysis", package = "pladdrr")

# Vowel acoustics research pipeline  
vignette("vowel-space-analysis", package = "pladdrr")

# TextGrid annotation and corpus processing
vignette("textgrid-workflows", package = "pladdrr")
```

Run `browseVignettes("pladdrr")` for the full list.

### Examples

Ten complete, real-world examples in `inst/examples/`:

1. **Basic Analysis** - Pitch, formant, intensity extraction
2. **Voice Quality** - HNR, jitter, shimmer measurements
3. **Spectral Analysis** - Spectrogram, spectrum, spectral moments
4. **Spectral Moments** - COG, standard deviation, skewness, kurtosis
5. **Complete Workflow** - Multi-measure feature extraction
6. **TextGrid Analysis** - Annotation-guided segmentation
7. **Comprehensive Phonetic Analysis** - Integrated TextGrid + acoustics
8. **TextGrid Corpus Analysis** - Large-scale batch analysis over annotated corpora
9. **Vowel Space Analysis** - F1-F2 trajectories with normalization
10. **CPPS Analysis** - Cepstral peak prominence smoothed workflows

Run examples:
```r
# View example code
file.show(system.file("examples", "07_comprehensive_phonetic_analysis.R", package = "pladdrr"))

# Run example (after installing pladdrr)
source(system.file("examples", "07_comprehensive_phonetic_analysis.R", package = "pladdrr"))
```

## Troubleshooting

### Common Installation Issues

**C++ compilation errors:**
```
Error: C++17 standard requested but CXX17 is not defined
```
Solution: Update your compiler. On macOS: `xcode-select --install`. On Linux: install GCC >= 7.

**Missing FFmpeg:**
```
Error in loadNamespace(name) : there is no package called 'av'
```
Solution: Install FFmpeg libraries first:
- macOS: `brew install ffmpeg`
- Ubuntu: `sudo apt-get install libavfilter-dev`

**Module loading errors:**
```
Error: package or namespace load failed for 'pladdrr'
```
Solution: Reinstall with a clean build:
```r
remove.packages("pladdrr")
devtools::install_github("humlab-speech/pladdrr", force = TRUE)
```

### Runtime Issues

**"Praat error occurred" (generic message):**

Starting in v4.7.0, error messages include the actual Praat error. If you see generic errors, update to the latest version.

**NA values in analysis:**

This is expected for:
- Unvoiced regions in pitch extraction
- Out-of-range formants
- Regions below/above analysis thresholds

Use `na.rm = TRUE` when computing statistics:
```r
mean(pitch$get_values_vector(), na.rm = TRUE)
```

**Memory issues with large files:**

Use `LongSound` for files too large for memory:
```r
longsound <- LongSound$open("large_file.wav")
# Extract only the portion you need
sound_segment <- longsound$extract_part(tmin = 0, tmax = 10)
```

### Performance Tips

- Use Tier 4 "Ultra" functions for batch processing
- Use vectorized methods (`$get_values_vector()`) instead of loops
- For single-interval CPP, use `to_power_cepstrum()$get_peak_prominence()`; reserve `calculate_cpps_ultra()` for smoothed CPPS
- For >100 files, consider `calculate_cpps_ultra()` over standard API

### Getting Help

- Check the [Agent Guide](inst/agents/AGENT_GUIDE.md) for detailed API reference
- Contact the maintainer at `fredrik.nylen@umu.se`

## Citation

To cite **pladdrr** in publications, run `citation("pladdrr")` in R, or use:

> Nylén, Fredrik (2026). *pladdrr: Direct Access to the Core Algorithms of
> Praat*. R package version 5.0.3. <https://doi.org/10.5281/zenodo.21884218>

Please also cite Praat itself:

> Boersma, Paul & Weenink, David (2024). *Praat: doing phonetics by computer*
> [Computer program]. Version 6.4, retrieved from <https://praat.org/>

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](.github/CONTRIBUTING.md) for
how to get a working build (the vendored Praat sources are git submodules, and
GSL is required) and what a good pull request looks like.

Please note that this project is released with a
[Contributor Code of Conduct](.github/CODE_OF_CONDUCT.md). By participating in
this project you agree to abide by its terms.

## License

**pladdrr** is licensed under GPL-3 (GNU General Public License version 3 or later).

This package includes components from several third-party projects:

- **Praat** (GPL-2-or-later / GPL-3-or-later) - Core phonetic analysis engine
- **GNU Scientific Library** (GPL-3) - Statistical analysis functions
- **pocketfft** (BSD-3-Clause) - FFT implementation
- **Vorbis/Ogg & Opusfile** (BSD-3-Clause) - Audio codec support

All third-party components are compatible with GPL-3. For full licensing details, see:
- `LICENSE` - Copyright and GPL-3 license declaration
- `inst/COPYRIGHTS` - Third-party component attributions
- `COPYING` - Complete GPL-3 license text

## References

- [Praat](https://www.fon.hum.uva.nl/praat/) - Doing phonetics by computer
- [Rcpp](https://www.rcpp.org/) - Seamless R and C++ Integration

## Contact

For questions and feedback, please open an issue on GitHub.
