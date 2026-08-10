# Get Audio File Durations via WAV Header Reading

Reads only the 44-byte WAV header to calculate duration, avoiding full
file loading via \`LongSound\$from_file()\$get_total_duration()\`.

This is a \*\*Tier 4 "Ultra"\*\* function for batch DSI (Dysphonia
Severity Index) calculations where file duration is the MPT (Maximum
Phonation Time) component.

## Usage

``` r
get_durations_batch(file_paths)
```

## Arguments

- file_paths:

  Character vector of .wav file paths

## Value

Numeric vector of durations (seconds). Returns \`NA\` for files that
cannot be read or are not valid WAV files.

## Performance

This function avoids the overhead of the standard LongSound approach by:

- Reading only the first 44-100 bytes of the WAV header

- Avoiding memory allocation for audio samples

- Skipping all Praat object construction

## API Tier

This is a \*\*Tier 4 "Ultra"\*\* function. Tier 4 functions keep entire
workflows in the C++ layer to minimize R\<-\>C++ boundary crossings,
returning only final scalar or simple vector results.

## See also

\[LongSound()\] for full audio file access when you need more than
duration

## Examples

``` r
wav1 <- tempfile(fileext = ".wav")
wav2 <- tempfile(fileext = ".wav")
Sound$create_tone(frequency = 150, duration = 0.3, sampling_rate = 16000)$save(wav1)
Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)$save(wav2)

# Multiple files (DSI workflow)
durations <- get_durations_batch(c(wav1, wav2))
max_mpt <- max(durations, na.rm = TRUE)
```
