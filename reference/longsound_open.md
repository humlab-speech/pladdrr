# Open a LongSound from file

Open a LongSound from file

## Usage

``` r
longsound_open(path)
```

## Arguments

- path:

  Path to audio file (WAV, AIFF, FLAC, MP3, etc.)

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
#>   File: /tmp/Rtmp0mOWcC/file2603c2f380d.wav 
#>   Duration: 1.000 seconds
#>   Sample rate: 16000 Hz
#>   Channels: 1 
#>   Samples: 16000 

# Extract portion
sound <- ls$extract_part(0, 0.5)
```
