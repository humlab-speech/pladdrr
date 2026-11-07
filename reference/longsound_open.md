# Open a LongSound from file

Open a LongSound from file

## Usage

``` r
longsound_open(path)
```

## Arguments

- path:

  Path to audio file in a format Praat's own streaming reader accepts
  (WAV, AIFF, NIST). FLAC and MP3 do NOT work here: their decoders were
  dropped from the vendored Praat tree, and the `av` fallback that
  covers them exists only in `Sound(path = )`, which reads the whole
  file into memory.

## Value

LongSound object

## Examples

``` r
wav <- tempfile(fileext = ".wav")
Sound$create_tone(frequency = 220, duration = 1, sampling_rate =
 16000)$save(wav)

ls <- longsound_open(wav)
print(ls)
#> <Praat LongSound>
#>   File: /tmp/RtmppimeU1/file229b38277c49.wav 
#>   Duration: 1.000 seconds
#>   Sample rate: 16000 Hz
#>   Channels: 1 
#>   Samples: 16000 

# Extract portion
sound <- ls$extract_part(0, 0.5)
```
