# LongSound Class

Function wrapper for Praat LongSound objects representing large audio
files. Unlike Sound objects which load entirely into memory, LongSound
streams from disk, making it suitable for very long recordings.

## Arguments

- .xptr:

  External pointer to LongSound (for internal use)

## Value

LongSound object (list with methods)

## Details

A LongSound keeps the audio file open and reads portions on demand. This
allows working with files that would be too large to load into memory.
Use \`extract_part()\` to get a Sound object for a specific time window.

## Examples

``` r
# LongSound streams from disk, so the example writes a small WAV file first
tmp <- tempfile(fileext = ".wav")
Sound$create_tone(frequency = 150, duration = 1.0)$save(tmp)

ls <- LongSound$open(tmp)
print(ls)
#> <Praat LongSound>
#>   File: /tmp/RtmpZhyu4P/file239c4b9f9b60.wav 
#>   Duration: 1.000 seconds
#>   Sample rate: 44100 Hz
#>   Channels: 1 
#>   Samples: 44100 

# Extract first 0.5 seconds as Sound
sound <- ls$extract_part(0, 0.5)

unlink(tmp)
```
