# Create File List (Replaces Praat's Strings Object)

Create a file list similar to Praat's "Create Strings as file list".
Returns a simple character vector of file paths.

## Usage

``` r
create_file_list(
  directory,
  pattern = NULL,
  full_names = TRUE,
  recursive = FALSE
)
```

## Arguments

- directory:

  Character path to directory

- pattern:

  Regular expression pattern to match files

- full_names:

  Logical, return full paths (default: TRUE)

- recursive:

  Logical, search recursively (default: FALSE)

## Value

Character vector of file paths

## Examples

``` r
audio_dir <- tempfile("audio_")
dir.create(audio_dir)
tone <- Sound$create_tone(frequency = 150, duration = 0.3, sampling_rate = 16000)
tone$save(file.path(audio_dir, "tone1.wav"))

# Equivalent to: Create Strings as file list: "list", "*.wav"
wav_files <- create_file_list(audio_dir, pattern = "\\.wav$")
```
