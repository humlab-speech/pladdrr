# Read sound from audio file (DEPRECATED)

\*\*DEPRECATED:\*\* This S3 function is deprecated. Use the R6 interface
instead: `Sound$new(file_path)`

## Usage

``` r
read_sound(file_path, channel = 0)
```

## Arguments

- file_path:

  Path to audio file (WAV/AIFF/FLAC/MP3 via Praat, others via av
  fallback)

- channel:

  Channel to read (0 = left, 1 = right) - ignored in R6

## Value

Sound R6 object

## Examples

``` r
tmp <- tempfile(fileext = ".wav")
Sound$create_tone(frequency = 440, duration = 0.2)$save(tmp)

# Old S3 approach (DEPRECATED)
sound <- read_sound(tmp)
#> Warning: read_sound() is deprecated and will be removed in v5.0.0. Use Sound$new(file_path) instead. For channel extraction, use sound$extract_channel(channel).

# New R6 approach (RECOMMENDED)
sound <- Sound$new(tmp)
unlink(tmp)
```
