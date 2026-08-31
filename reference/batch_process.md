# Batch Process Audio Files

Process multiple audio files with a custom function. This replaces
Praat's pattern of creating Strings objects and looping over files.

## Usage

``` r
batch_process(
  directory,
  pattern = "\\.wav$",
  func,
  recursive = FALSE,
  parallel = FALSE,
  ncores = NULL,
  progress = TRUE,
  ...
)
```

## Arguments

- directory:

  Character path to directory containing audio files

- pattern:

  Regular expression pattern to match files (default: "\\.wav\$")

- func:

  Function to apply to each file. Should accept a Sound object as first
  argument and return a named list or data frame row

- recursive:

  Logical, search directories recursively (default: FALSE)

- parallel:

  Logical, use parallel processing (default: FALSE)

- ncores:

  Integer, number of cores for parallel processing (default: NULL =
  all-1)

- progress:

  Logical, show progress bar (default: TRUE)

- ...:

  Additional arguments passed to func

## Value

Data frame with results from all files

## Examples

``` r
audio_dir <- tempfile("audio_")
dir.create(audio_dir)
tone <- Sound$create_tone(frequency = 150, duration = 0.3, sampling_rate =
 16000)
tone$save(file.path(audio_dir, "tone1.wav"))

results <- batch_process(
  directory = audio_dir,
  pattern = "\\.wav$",
  progress = FALSE,
  func = function(sound) {
    pitch <- sound$to_pitch()
    list(
      mean_f0 = pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz"),
sd_f0 = pitch$get_standard_deviation(from_time = 0, to_time = 0, unit =
 "hertz")
    )
  }
)
```
