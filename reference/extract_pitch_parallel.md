# Parallel Pitch Extraction

Extract pitch from multiple files in parallel. Convenience wrapper
around analyze_files_parallel.

## Usage

``` r
extract_pitch_parallel(
  files,
  n_cores = NULL,
  pitch_floor = 75,
  pitch_ceiling = 600,
  time_step = 0
)
```

## Arguments

- files:

  Character vector of file paths

- n_cores:

  Integer. Number of cores (default: auto)

- pitch_floor:

  Numeric. Minimum pitch in Hz (default: 75)

- pitch_ceiling:

  Numeric. Maximum pitch in Hz (default: 600)

- time_step:

  Numeric. Time step (default: 0, auto)

## Value

List of Pitch objects

## Examples

``` r
audio_dir <- tempfile("audio_")
dir.create(audio_dir)
tone <- Sound$create_tone(frequency = 150, duration = 0.3, sampling_rate = 16000)
tone$save(file.path(audio_dir, "tone1.wav"))
files <- list.files(audio_dir, pattern = "\\.wav$", full.names = TRUE)

# n_cores = 1 keeps this a single-process example (CRAN-safe)
pitches <- extract_pitch_parallel(files, n_cores = 1)
#> Using single core (set n_cores > 1 for parallel processing)
```
