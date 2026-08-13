# Load Sound Window from File with Optional Resampling

Extracts a time window from a sound file without loading the entire
file. Optionally resamples the window to a target sampling rate. Uses
LongSound for lazy loading - only the requested window is loaded from
disk.

## Usage

``` r
sound_load_window(path, start, end, resample_to = NULL, preserve_times = FALSE)
```

## Arguments

- path:

  Path to sound file (WAV, AIFF, FLAC, MP3, etc.)

- start:

  Start time of window in seconds

- end:

  End time of window in seconds

- resample_to:

  Target sampling rate in Hz (optional). If NULL, no resampling.

- preserve_times:

  If TRUE, keep original time domain. If FALSE, shift to start at 0
  (default: FALSE)

## Value

Sound object containing the windowed (and optionally resampled) audio

## Details

A traditional workflow loads the entire file, resamples the entire file,
and then extracts the window of interest — reading and processing far
more samples than needed. This function instead opens the file as a
\`LongSound\` (lazily, reading only the header), extracts just the
requested window from disk, and resamples only that window.

\*\*Use cases:\*\* - Pharyngeal analysis: extracting short vowel windows
from long recordings - Formant tracking: analyzing specific time
points - Batch extraction: processing windows from multiple files -
Large file processing: working with hours-long recordings

## See also

[`Sound`](https://humlab-speech.github.io/pladdrr/reference/Sound.md),
[`LongSound`](https://humlab-speech.github.io/pladdrr/reference/LongSound.md)

Other batch-ops:
[`textgrid_merge()`](https://humlab-speech.github.io/pladdrr/reference/textgrid_merge.md)

## Examples

``` r
# Write a short synthetic recording, then load only part of it
sound <- Sound$create_tone(frequency = 220, duration = 2.0)
path <- tempfile(fileext = ".wav")
sound$save(path)

window <- sound_load_window(path, start = 0.5, end = 0.6)

# Extract and resample (for spectral analysis)
window_10k <- sound_load_window(path, start = 0.5, end = 0.6, resample_to = 10000)

# Preserve original time domain (window starts at 0.5, not 0.0)
window_timed <- sound_load_window(path, start = 0.5, end = 0.6, preserve_times = TRUE)

unlink(path)
```
