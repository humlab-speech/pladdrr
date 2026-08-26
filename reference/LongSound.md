# LongSound

Represents a Praat LongSound object: an audio file that stays on disk
instead of loading into memory.

## Arguments

- .xptr:

  Not for direct use. External pointer to the underlying C++ LongSound
  object; set internally when a method returns a new LongSound.

## Value

A LongSound object.

## Details

A regular Sound loads the whole recording into RAM, which can exceed
available memory on a multi-hour field recording, or just crowd out
everything else you're working on. LongSound opens the file, reads its
header, and streams samples on demand, so you can check duration,
inspect amplitude, or pull out short clips from a file far bigger than
memory allows. Use `extract_part()` whenever you need actual waveform
data for pitch, formant, or intensity analysis: it reads just the
requested time window and hands back a normal Sound.

## Usage


    ls <- LongSound$open("recording.wav")
    part <- ls$extract_part(10, 15)   # 5 seconds as a Sound

## Query methods

- [`get_duration()`](https://humlab-speech.github.io/pladdrr/reference/get_duration.md) -
  total duration in seconds

- `get_start_time()`, `get_end_time()` - time domain in seconds

- `get_sample_rate()` - sampling frequency in Hz

- `get_number_of_samples()` - number of samples per channel

- `get_number_of_channels()` - number of channels (1 = mono, 2 = stereo)

- `get_file_path()` - path to the underlying audio file

- `get_dx()` - sampling period in seconds (`1 / get_sample_rate()`)

- `get_x1()` - time of the first sample

## Time/sample conversion

- `get_time_from_sample(sample)` - time, in seconds, of a given sample
  index

- `get_sample_from_time(time)` - index of the sample nearest a given
  time

## Streaming

- `extract_part(from, to, preserve_times = FALSE)` - read a time range
  from disk and return it as a Sound. Set `preserve_times = TRUE` to
  keep the extracted Sound's time domain aligned with the original file
  instead of starting it at time 0.

- `have_window(from, to)` - TRUE if that time range is already held in
  the internal read buffer, so the next `extract_part()` over it will be
  fast

- `get_window_extrema(from, to, channel = 1)` - minimum and maximum
  amplitude in a time range, without building a Sound

## Save

- `save_part(from, to, path, format = "wav")` - write a time range
  straight to an audio file, without holding the whole clip in memory.
  `format` is one of `"wav"`, `"aiff"`, `"aifc"`, `"flac"`, or `"wav24"`
  (24-bit WAV).

- `save_channel(channel, path, format = "wav")` - write a single channel
  to an audio file

## Utility

- `is_valid()` - FALSE if the underlying file handle was closed or
  garbage collected

- [`print()`](https://rdrr.io/r/base/print.html) - summary of file path,
  duration, sample rate, and channel count

Streaming through a very large file repeatedly touches the same disk
regions; see
[`longsound_get_buffer_size_pref_seconds`](https://humlab-speech.github.io/pladdrr/reference/longsound_get_buffer_size_pref_seconds.md)
to tune how much Praat keeps cached between reads.

## See also

[`Sound`](https://humlab-speech.github.io/pladdrr/reference/Sound.md)

## Examples

``` r
# LongSound streams from disk, so the example writes a small WAV file first
tmp <- tempfile(fileext = ".wav")
Sound$create_tone(frequency = 150, duration = 1.0)$save(tmp)

ls <- LongSound$open(tmp)
print(ls)
#> <Praat LongSound>
#>   File: /tmp/Rtmp3mgcEQ/file24d85ad4b1a9.wav 
#>   Duration: 1.000 seconds
#>   Sample rate: 44100 Hz
#>   Channels: 1 
#>   Samples: 44100 

cat("Duration:", ls$get_duration(), "s\n")
#> Duration: 1 s
cat("Sample rate:", ls$get_sample_rate(), "Hz\n")
#> Sample rate: 44100 Hz

# Extract first 0.5 seconds as a Sound
sound <- ls$extract_part(0, 0.5)

# Convert a sample index to a time and back
t <- ls$get_time_from_sample(100)
ls$get_sample_from_time(t)
#> [1] 100

unlink(tmp)
```
