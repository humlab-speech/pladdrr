# Parallel Intensity Extraction

Extract intensity from multiple files in parallel.

## Usage

``` r
extract_intensity_parallel(
  files,
  n_cores = NULL,
  minimum_pitch = 100,
  time_step = 0
)
```

## Arguments

- files:

  Character vector of file paths

- n_cores:

  Integer. Number of cores (default: auto)

- minimum_pitch:

  Numeric. Minimum pitch for analysis (default: 100)

- time_step:

  Numeric. Time step (default: 0, auto)

## Value

List of Intensity objects

## Examples

``` r
audio_dir <- tempfile("audio_")
dir.create(audio_dir)
tone <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate =
 16000)
tone$save(file.path(audio_dir, "tone1.wav"))
files <- list.files(audio_dir, pattern = "\\.wav$", full.names = TRUE)

# n_cores = 1 keeps this a single-process example (CRAN-safe)
intensities <- extract_intensity_parallel(files, n_cores = 1)
#> Using single core (set n_cores > 1 for parallel processing)
```
