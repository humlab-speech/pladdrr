# Project Overview

This is the `speaker` R package, a powerful and efficient tool for phonetic analysis. It provides a direct, object-oriented interface to the core functionality of the Praat phonetics software, implemented in C++. The package is designed for performance, leveraging Rcpp for seamless R-to-C++ integration and SIMD optimizations for significant speed-ups on modern CPUs.

The `speaker` package is analogous to the `parselmouth` package in Python, allowing R users to perform complex phonetic analyses without leaving the R environment. It supports a wide range of phonetic analysis tasks, including:

*   **Pitch analysis**: F0 tracking and manipulation.
*   **Formant analysis**: Formant tracking and vowel space analysis.
*   **Voice quality analysis**: Jitter, shimmer, and Harmonicity-to-Noise Ratio (HNR).
*   **Spectral analysis**: Spectrograms, spectra, and Long-Term Average Spectrum (LTAS).
*   **TextGrid support**: Full creation, manipulation, and annotation of TextGrids.

The package is structured as a standard R package, with R source code in the `R/` directory, C++ source code in the `src/` directory, documentation in `man/`, and vignettes in `vignettes/`.

# Building and Running

## Installation

To install the `speaker` package, you need a C++17 compatible compiler and the `devtools` R package. The package also depends on the `av` package for audio file I/O, and it is recommended to install a specific fork of `av` from GitHub.

```r
# Install devtools if you haven't already
if (!requireNamespace("devtools", quietly = TRUE)) {
    install.packages("devtools")
}

# Install the required fork of the av package
devtools::install_github("humlab-speech/av")

# Install the speaker package from GitHub
devtools::install_github("humlab-speech/speaker")
```

## Running Tests

The package uses the `testthat` framework for unit testing. To run the tests, you can use the `devtools::test()` function:

```r
# Load the devtools package
library(devtools)

# Run the tests
test()
```

## Building from Source

To build and install the package from the local source, you can use the `devtools::install()` function:

```r
# Load the devtools package
library(devtools)

# Install the package from the local directory
install()
```

# Development Conventions

## Coding Style

*   **R**: The R code follows the tidyverse style guide.
*   **C++**: The C++ code follows the Google C++ Style Guide.

## Documentation

*   **Roxygen**: The R functions are documented using `roxygen2` syntax. After making changes to the R code or documentation, you should run `devtools::document()` to update the `NAMESPACE` and `.Rd` files.
*   **Vignettes**: The package includes several vignettes that provide detailed examples and workflows. These are written in R Markdown and can be found in the `vignettes/` directory.
*   **NEWS.md**: The `NEWS.md` file is used to document changes between package versions.

## Versioning

The package follows semantic versioning.

## Praat Integration

The Praat C++ source code is included as a submodule in the `src/praat` directory. The C++ wrapper code that interfaces with the Praat code is located in the `src/` directory. The naming of the R6 classes and methods in the `speaker` package is designed to be consistent with the Praat user interface.
