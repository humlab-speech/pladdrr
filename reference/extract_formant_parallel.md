# Parallel Formant Extraction

Extract formants from multiple files in parallel.

## Usage

``` r
extract_formant_parallel(
  files,
  n_cores = NULL,
  time_step = 0.005,
  max_formants = 5,
  max_frequency = 5500
)
```

## Arguments

- files:

  Character vector of file paths

- n_cores:

  Integer. Number of cores (default: auto)

- time_step:

  Numeric. Time step in seconds (default: 0.005)

- max_formants:

  Numeric. Max number of formants (default: 5)

- max_frequency:

  Numeric. Max frequency in Hz (default: 5500)

## Value

List of Formant objects

## Examples

``` r
audio_dir <- tempfile("audio_")
dir.create(audio_dir)
tone <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)
tone$save(file.path(audio_dir, "tone1.wav"))
files <- list.files(audio_dir, pattern = "\\.wav$", full.names = TRUE)

# n_cores = 1 keeps this a single-process example (CRAN-safe)
formants <- extract_formant_parallel(files, n_cores = 1)
#> Using single core (set n_cores > 1 for parallel processing)
```
