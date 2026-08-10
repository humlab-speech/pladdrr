# Get audio file durations via WAV header reading

Reads only the 44-byte WAV header to calculate duration, avoiding full
file loading.

## Usage

``` r
get_durations_batch_cpp(file_paths)
```

## Arguments

- file_paths:

  Character vector of .wav file paths

## Value

Numeric vector of durations (seconds), NA for errors

## Examples

``` r
wav <- tempfile(fileext = ".wav")
Sound$create_tone(frequency = 150, duration = 0.3, sampling_rate = 16000)$save(wav)
pladdrr:::get_durations_batch_cpp(wav)
#> [1] 0.3
```
