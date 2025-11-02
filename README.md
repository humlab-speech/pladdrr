# speaker

Direct Access to Praat C Functionality from R

## Overview

The `speaker` package provides direct, efficient access to Praat C implemented functionality from R using Rcpp. Similar to the [parselmouth](https://github.com/YannickJadoul/Parselmouth) package for Python, this package enables R users to leverage Praat's powerful phonetic analysis capabilities directly from R.

## Installation

You can install the development version of speaker from GitHub:

```r
# install.packages("devtools")
devtools::install_github("humlab-speech/speaker")
```

## Features

- **Direct C++ Integration**: Uses Rcpp for efficient access to Praat functionality
- **Sound Object Manipulation**: Create and manipulate sound objects
- **Phonetic Analysis**: Access to Praat's phonetic analysis tools (framework in place)
- **R-friendly Interface**: Familiar R syntax and data structures

## Quick Start

```r
library(speaker)

# Check the version
praat_version()

# Generate a sine wave (440 Hz A4 note)
sound <- generate_sine_wave(frequency = 440, duration = 1.0)

# Get sound properties
duration <- get_sound_duration(sound)
print(duration)

# Calculate statistics
stats <- sound_stats(sound$values)
print(stats)
```

## Usage Examples

### Creating Sound Objects

```r
# Create a sound from a numeric vector
values <- rnorm(44100)  # 1 second of random noise at 44.1 kHz
sound <- create_sound(values, sampling_frequency = 44100)

# Check if it's a valid sound object
is_praat_sound(sound)
```

### Generating Test Signals

```r
# Generate a pure tone
tone <- generate_sine_wave(
    frequency = 440,           # A4 note
    duration = 2.0,            # 2 seconds
    sampling_frequency = 44100,
    amplitude = 0.5
)

# View sound information
print(tone)
```

### Computing Statistics

```r
# Calculate basic statistics on sound data
sound <- generate_sine_wave(440, 1.0)
stats <- sound_stats(sound$values)

cat("Mean:", stats$mean, "\n")
cat("Min:", stats$min, "\n")
cat("Max:", stats$max, "\n")
cat("Length:", stats$length, "\n")
```

## Architecture

The package is built on three main components:

1. **C++ Layer** (`src/praat_wrapper.cpp`): Rcpp-based interface to Praat C functionality
2. **R Interface** (`R/sound_utils.R`): R functions providing convenient access
3. **Integration** (`R/speaker-package.R`): Package-level documentation and exports

## Development Status

This is an initial implementation providing the framework for Praat integration. Currently implemented:

- ✅ Basic package structure with Rcpp integration
- ✅ Sound object creation and manipulation
- ✅ Basic statistical functions
- ✅ Test suite
- 🔄 Full Praat C API integration (planned)
- 🔄 Pitch analysis (planned)
- 🔄 Formant analysis (planned)
- 🔄 Intensity analysis (planned)
- 🔄 Spectral analysis (planned)

## Similar Projects

- [parselmouth](https://github.com/YannickJadoul/Parselmouth) - Python interface to Praat
- [PraatR](https://github.com/usagi5886/PraatR) - R interface calling Praat scripts

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

GPL-3

## References

- [Praat](https://www.fon.hum.uva.nl/praat/) - Doing phonetics by computer
- [Rcpp](https://www.rcpp.org/) - Seamless R and C++ Integration

## Contact

For questions and feedback, please open an issue on GitHub.