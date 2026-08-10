# pladdrr: Direct Access to Praat C Functionality from R

The pladdrr package provides direct access to Praat's C phonetic
analysis functionality from R. Praat is a widely-used tool for speech
analysis in phonetics research and this package wraps Praat's core C
library using Rcpp, providing native access to Praat's analysis
capabilities without requiring external Praat installation or scripting.

## Core Features

**Sound Operations:**

- Create and manipulate sound objects

- Read and write audio files (WAV, AIFF, FLAC, MP3, NIST via native
  Praat)

- Extract basic sound properties (duration, sampling rate, etc.)

- Generate synthetic sounds (sine waves, white noise)

**Pitch Analysis:**

- Extract fundamental frequency (F0) contours

- Get pitch at specific time points

- Calculate pitch statistics (mean, median, range)

- Quality-aware pitch tracking with configurable parameters

**Formant Analysis:**

- Extract formant frequencies (F1-F5)

- Get formants at specific time points

- Calculate formant statistics and trajectories

- LPC-based formant estimation

**Intensity and Spectral Analysis:**

- Compute intensity contours

- Create spectrograms

- Extract spectral properties

## Design Principles

The pladdrr package follows these core principles:

1.  **Scientific Accuracy**: All analyses must match Praat's output
    within 0.1% relative error tolerance

2.  **R Package Standards**: Full compliance with CRAN requirements and
    R package best practices

3.  **Direct C++ Integration**: Direct C++ access via Rcpp, avoiding
    intermediate R-level translation layers

4.  **Test-Driven Development**: Comprehensive test coverage with
    reference validation

5.  **Comprehensive Documentation**: All functions fully documented with
    examples and vignettes

## Object Types

The package uses S3 classes to represent Praat objects:

- `praat_sound`:

  Sound object containing audio data and metadata

- `praat_pitch`:

  Pitch contour with time-frequency pairs

- `praat_formant`:

  Formant tracks (F1-F5) with bandwidths

- `praat_intensity`:

  Intensity contour over time

- `praat_spectrogram`:

  Time-frequency-power spectrogram

## Undefined Values

Following R conventions, undefined analysis values (e.g., pitch in
unvoiced segments, formants in silence) are returned as `NA`. Quality
warnings are issued when analysis results may be unreliable, but can be
suppressed using standard R warning control mechanisms.

## Getting Started

See `vignette("basic-usage", package = "pladdrr")` for an introduction
to the package. Additional vignettes cover specific analysis types:

- `vignette("pitch-analysis")` - Pitch extraction and analysis

- [`vignette("formant-analysis")`](https://humlab-speech.github.io/pladdrr/articles/formant-analysis.md) -
  Formant tracking

- `vignette("spectral-analysis")` - Spectrograms and spectral features

## License and Attribution

This package is licensed under GPL-3, compatible with Praat's GPL-2+
license. Praat was created by Paul Boersma and David Weenink of the
Institute of Phonetic Sciences, University of Amsterdam.

When using this package in publications, please cite both this package
and Praat:

Boersma, Paul & Weenink, David (2023). Praat: doing phonetics by
computer \[Computer program\]. Version 6.3.x, retrieved from
https://praat.org/

## See also

Useful links:

- <https://github.com/humlab-speech/pladdrr>

- Report bugs at <https://github.com/humlab-speech/pladdrr/issues>

## Author

**Maintainer**: Fredrik Nylén <fredrik.nylen@umu.se>
([ORCID](https://orcid.org/0000-0003-3373-0934))
