# Getting Started with pladdrr: Phonetic Analysis in R

## Introduction

The `pladdrr` package provides direct access to Praat’s phonetic
analysis capabilities from R, without requiring Python. It implements
core phonetic analysis objects (Sound, Pitch, Formant, Intensity) with
an R6 object-oriented interface that follows Praat’s conventions.

## Installation

``` r

# Install from source
install.packages("pladdrr", type = "source")

# Or install from GitHub
# devtools::install_github("your-username/pladdrr")
```

``` r

library(pladdrr)
#> The pladdrr package provides direct access to Praat's DSP capabilities to R usersSee ?pladdrr for an overview and citation information.
#> Use citation('pladdrr') for citing this package in publications.
```

## Creating and Loading Sounds

### Generate Test Sounds

The package includes functions to generate test signals:

``` r

# Generate a 440 Hz sine wave (A4 note)
sound_a4 <- generate_sine_wave(frequency = 440, duration = 0.5, 
                               amplitude = 0.7, sampling_rate = 44100)

print(sound_a4)
#> <Praat Sound>
#>   Duration: 0.500 s
#>   Sampling frequency: 44100 Hz
#>   Number of samples: 22050
#>   Number of channels: 1
#>   Intensity: 87.9 dB
```

``` r

# Generate white noise
noise <- generate_noise(duration = 0.2, sampling_rate = 44100, 
                       amplitude = 0.3)

print(noise)
#> <Praat Sound>
#>   Duration: 0.200 s
#>   Sampling frequency: 44100 Hz
#>   Number of samples: 8820
#>   Number of channels: 1
#>   Intensity: 83.4 dB
```

### Load Audio Files

``` r

# Load a WAV file using the R6 interface
speech <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
speech
#> <Praat Sound>
#>   Duration: 1.000 s
#>   Sampling frequency: 44100 Hz
#>   Number of samples: 44100
#>   Number of channels: 1
#>   Intensity: 84.9 dB

# For a stereo file, select a channel (1-indexed):
# speech_left <- Sound$new("stereo.wav", channel = 1)
# speech_right <- Sound$new("stereo.wav", channel = 2)
```

## Basic Sound Properties

Extract basic information from sound objects using R6 methods:

``` r

# Duration in seconds
cat("Duration:", sound_a4$get_duration(), "seconds\n")
#> Duration: 0.5 seconds

# Sampling rate
cat("Sampling rate:", sound_a4$get_sampling_frequency(), "Hz\n")
#> Sampling rate: 44100 Hz

# Number of samples
cat("Samples:", sound_a4$get_number_of_samples(), "\n")
#> Samples: 22050

# Number of channels
cat("Channels:", sound_a4$get_number_of_channels(), "\n")
#> Channels: 1
```

## Sound Statistics

Calculate amplitude statistics:

``` r

# Individual statistics
cat("Mean amplitude:", sound_mean(sound_a4), "\n")
#> Mean amplitude: -2.783407e-17
cat("RMS amplitude:", sound_rms(sound_a4), "\n")
#> RMS amplitude: 0.4949747
cat("Min amplitude:", sound_min(sound_a4), "\n")
#> Min amplitude: -0.6999998
cat("Max amplitude:", sound_max(sound_a4), "\n")
#> Max amplitude: 0.6999998

# All statistics at once
stats <- sound_statistics(sound_a4)
print(stats)
#> $mean
#> [1] -2.783407e-17
#> 
#> $min
#> [1] -0.6999998
#> 
#> $max
#> [1] 0.6999998
#> 
#> $rms
#> [1] 0.4949747
#> 
#> $duration
#> [1] 0.5
#> 
#> $n_samples
#> [1] 22050
#> 
#> $sampling_rate
#> [1] 44100
```

## Pitch Analysis

Extract fundamental frequency (F0) from speech or sustained tones using
R6 methods:

``` r

# For speech, use typical settings
# pitch <- speech$to_pitch(pitch_floor = 75, pitch_ceiling = 600)

# For our test signal, we need to create a more complex sound
# (pure sine waves may not be detected as voiced)
# In real usage with speech:
# mean_f0 <- pitch$get_mean()
# min_f0 <- pitch$get_minimum()
# max_f0 <- pitch$get_maximum()
```

### Pitch Parameters

``` r

# Male voice
pitch_male <- speech$to_pitch(pitch_floor = 50, pitch_ceiling = 300)

# Female voice
pitch_female <- speech$to_pitch(pitch_floor = 100, pitch_ceiling = 600)

# Child voice
pitch_child <- speech$to_pitch(pitch_floor = 150, pitch_ceiling = 800)
```

### Querying Pitch Values

``` r

pitch <- speech$to_pitch(pitch_floor = 75, pitch_ceiling = 600)

# Get F0 at specific time point
f0_at_1s <- pitch$get_value_at_time(time = 0.5)

# Get mean F0 over time range
mean_f0_range <- pitch$get_mean(from_time = 0.1, to_time = 0.5)

# Get minimum and maximum
min_f0 <- pitch$get_minimum()
max_f0 <- pitch$get_maximum()
```

## Formant Analysis

Analyze vocal tract resonances (formants) for vowel characterization
using R6:

``` r

# Extract formants (default settings for adult female)
formants <- sound_a4$to_formant_burg(max_frequency = 5500, max_formants = 5)

# R6 objects print nicely
formants
#> <Praat Formant object>
#>   Number of frames: 90
#>   Time step: 0.005000 s
#>   Min formants: 3
#>   Max formants: 4
```

### Speaker-Specific Settings

``` r

# Adult male
formants_male <- speech$to_formant_burg(max_frequency = 5000, max_formants = 5)

# Adult female
formants_female <- speech$to_formant_burg(max_frequency = 5500, max_formants = 5)

# Child
formants_child <- speech$to_formant_burg(max_frequency = 8000, max_formants = 5)
```

### Querying Formant Values

``` r

# Get F1 and F2 at specific time (vowel quality)
f1 <- formants$get_value_at_time(formant_number = 1, time = 0.25)
f2 <- formants$get_value_at_time(formant_number = 2, time = 0.25)

cat("F1:", round(f1, 1), "Hz\n")
#> F1: 406.7 Hz
cat("F2:", round(f2, 1), "Hz\n")
#> F2: 444.7 Hz
```

``` r

# Get mean formant over time range
mean_f1 <- formants$get_mean(formant_number = 1, 
                             from_time = 0.1, to_time = 0.4)
mean_f2 <- formants$get_mean(formant_number = 2, 
                             from_time = 0.1, to_time = 0.4)

cat("Mean F1:", round(mean_f1, 1), "Hz\n")
#> Mean F1: 399 Hz
cat("Mean F2:", round(mean_f2, 1), "Hz\n")
#> Mean F2: 443.4 Hz
```

## Intensity Analysis

Measure sound power (loudness) over time using R6:

``` r

# Extract intensity
intensity <- sound_a4$to_intensity(minimum_pitch = 100)

# R6 objects print nicely
intensity
#> <Praat Intensity>
#>   Duration: 0.500 s
#>   Number of frames: 55
#>   Time step: 0.0080 s
#>   Mean intensity: 87.87 dB
#>   Range: [87.87, 87.87] dB
```

### Intensity Statistics

``` r

# Mean intensity
mean_db <- intensity$get_mean()
cat("Mean intensity:", round(mean_db, 2), "dB\n")
#> Mean intensity: 87.87 dB

# Intensity range
min_db <- intensity$get_minimum()
max_db <- intensity$get_maximum()
cat("Intensity range:", round(min_db, 2), "-", round(max_db, 2), "dB\n")
#> Intensity range: 87.87 - 87.87 dB

# Standard deviation
sd_db <- intensity$get_standard_deviation()
cat("SD intensity:", round(sd_db, 2), "dB\n")
#> SD intensity: 0 dB
```

### Intensity at Specific Time

``` r

# Query intensity at time point
int_at_time <- intensity$get_value_at_time(time = 0.25)
cat("Intensity at 0.25s:", round(int_at_time, 2), "dB\n")
#> Intensity at 0.25s: 87.87 dB

# With interpolation (cubic)
int_interp <- intensity$get_value_at_time(time = 0.25, interpolation = "cubic")
cat("Intensity (interpolated):", round(int_interp, 2), "dB\n")
#> Intensity (interpolated): 87.87 dB
```

## Working with Data Frames

All analysis objects can be converted to data frames for plotting and
further analysis:

``` r

# Convert to data frame using R6 method
formant_df <- formants$as_data_frame()
head(formant_df)
#> Key: <time, formant>
#>      time formant frequency bandwidth
#>     <num>   <int>     <num>     <num>
#> 1: 0.0275       1  406.7238 0.5967145
#> 2: 0.0275       2  444.7119 0.5712193
#> 3: 0.0275       3  482.7092 0.5496186
#> 4: 0.0325       1  406.7234 0.6126355
#> 5: 0.0325       2  444.7116 0.5865413
#> 6: 0.0325       3  482.7092 0.5644368
```

``` r

intensity_df <- intensity$as_data_frame()
head(intensity_df)
#> Key: <time>
#>     time intensity_db
#>    <num>        <num>
#> 1: 0.034     87.87108
#> 2: 0.042     87.87107
#> 3: 0.050     87.87106
#> 4: 0.058     87.87106
#> 5: 0.066     87.87107
#> 6: 0.074     87.87109
```

## Visualization

The `pladdrr` package provides ggplot2-based visualization functions
([`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)/[`autolayer()`](https://ggplot2.tidyverse.org/reference/autolayer.html)
methods, see
[`vignette("autoplot-autolayer")`](https://humlab-speech.github.io/pladdrr/articles/autoplot-autolayer.md))
for its analysis objects. For detailed examples of creating plots, see
[`vignette("visualization")`](https://humlab-speech.github.io/pladdrr/articles/visualization.md),
which covers:

- Voice quality visualization (AVQI, DSI, CPP)
- Formant analysis (vowel spaces, trajectories)
- Pitch and intensity contours
- Spectral analysis (spectrograms, spectra, LTAS)
- TextGrid annotations
- Multi-panel diagnostic reports

## Complete Workflow Example

Here’s a complete analysis workflow using R6:

``` r

# 1. Load sound
sound <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))

# 2. Extract all analyses
pitch <- sound$to_pitch(pitch_floor = 75, pitch_ceiling = 600)
formants <- sound$to_formant_burg(max_frequency = 5500, max_formants = 5)
intensity <- sound$to_intensity(minimum_pitch = 75)

# 3. Get measurements at vowel midpoint
midpoint <- sound$get_duration() / 2

f0 <- pitch$get_value_at_time(time = midpoint)
f1 <- formants$get_value_at_time(formant_number = 1, time = midpoint)
f2 <- formants$get_value_at_time(formant_number = 2, time = midpoint)
f3 <- formants$get_value_at_time(formant_number = 3, time = midpoint)
int <- intensity$get_value_at_time(time = midpoint)

# 4. Create summary
vowel_data <- data.frame(
  F0 = f0,
  F1 = f1,
  F2 = f2,
  F3 = f3,
  Intensity = int
)

print(vowel_data)
#>         F0       F1       F2      F3 Intensity
#> 1 440.0102 420.6663 464.6014 2998.34   84.9483
```

## Comparing with Praat Scripts

The package follows Praat’s conventions, making it easy to translate
Praat scripts:

### Praat Script

    # Praat
    sound = Read from file: "sound.wav"
    pitch = To Pitch: 0.01, 75, 600
    f0 = Get mean: 0, 0, "Hertz"

### pladdrr Equivalent (R6)

``` r

# R with pladdrr (R6 interface)
sound <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
pitch <- sound$to_pitch(time_step = 0.01,
                       pitch_floor = 75, pitch_ceiling = 600)
f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")
```

## Advanced Topics

### Custom Analysis Parameters

``` r

# Fine-tune formant detection
formants <- sound$to_formant_burg(
  time_step = 0.005,           # 5 ms steps
  max_frequency = 5500,        # Adult female range
  max_formants = 5,            # Track F1-F5
  window_length = 0.025,       # 25 ms window
  pre_emphasis_from = 50       # Pre-emphasis from 50 Hz
)

# Fine-tune intensity
intensity <- sound$to_intensity(
  minimum_pitch = 75,          # Affects window length
  time_step = 0.01,            # 10 ms steps (auto if 0)
  subtract_mean = FALSE        # Absolute intensity in dB SPL
)
```

### Handling NA Values

Analysis methods return `NA` for undefined values (e.g. unvoiced pitch
frames) rather than erroring:

``` r

# Pitch may be NA for unvoiced segments
f0 <- pitch$get_value_at_time(time = 0.5)
if (is.na(f0)) {
  cat("Unvoiced at this time point\n")
} else {
  cat("F0:", f0, "Hz\n")
}
#> F0: 440.0102 Hz

# Mean functions automatically exclude NA
mean_f0 <- pitch$get_mean()  # NA values excluded
```

## Package Information

``` r

# Package version
packageVersion("pladdrr")
#> [1] '5.0.1'

# Citation information
citation("pladdrr")
#> To cite pladdrr in publications use:
#> 
#>   Nylén, Fredrik (2026). pladdrr: Direct Access to the Core Algorithms
#>   of Praat. R package version 5.0.0.
#>   https://doi.org/10.5281/zenodo.21884218
#> 
#>   Boersma, Paul & Weenink, David (2024). Praat: doing phonetics by
#>   computer [Computer program]. Version 6.4, retrieved from
#>   https://praat.org/
#> 
#> Please also cite Praat itself:
#> 
#> To see these entries in BibTeX format, use 'print(<citation>,
#> bibtex=TRUE)', 'toBibtex(.)', or set
#> 'options(citation.bibtex.max=999)'.
```

## See Also

- Praat: <https://praat.org>
- Package documentation:
  [`help(package = "pladdrr")`](https://humlab-speech.github.io/pladdrr/reference)
- Function reference:
  [`?extract_pitch`](https://humlab-speech.github.io/pladdrr/reference/extract_pitch.md),
  [`?extract_formants`](https://humlab-speech.github.io/pladdrr/reference/extract_formants.md),
  [`?extract_intensity`](https://humlab-speech.github.io/pladdrr/reference/extract_intensity.md)

## Conclusion

This vignette covered the core `pladdrr` analysis objects: Sound, Pitch,
Formant, and Intensity. The package exposes 38 Praat modules with 500+
methods in total (see `DESCRIPTION` and
[`help(package = "pladdrr")`](https://humlab-speech.github.io/pladdrr/reference)
for the full list), including auditory modeling, TextGrid annotation,
voice quality assessment, and a persistent Praat script interpreter.

For more information, see the individual function documentation and the
package README.
