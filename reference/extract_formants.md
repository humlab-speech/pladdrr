# Extract formants from a sound object (DEPRECATED)

\*\*DEPRECATED:\*\* This function is deprecated in favor of the R6
interface. Use \`sound\$to_formant_burg()\` instead.

## Usage

``` r
extract_formants(
  sound,
  time_step = 0,
  max_formant = 5500,
  n_formants = 5,
  window_length = 0.025,
  pre_emphasis_from = 50
)
```

## Arguments

- sound:

  A praat_sound object created by
  [`read_sound`](https://humlab-speech.github.io/pladdrr/reference/read_sound.md)
  or
  [`create_sound`](https://humlab-speech.github.io/pladdrr/reference/create_sound.md)

- time_step:

  Time step in seconds for formant analysis (0 = auto: 4x Nyquist)

- max_formant:

  Maximum formant frequency in Hz (default: 5500 for adult female, use
  5000 for adult male, 8000 for child)

- n_formants:

  Number of formants to track (default: 5)

- window_length:

  Analysis window length in seconds (default: 0.025)

- pre_emphasis_from:

  Pre-emphasis frequency in Hz (default: 50)

## Value

Depends on the class of `sound`:

- If `sound` is an R6 `Sound` object (the normal case —
  [`Sound()`](https://humlab-speech.github.io/pladdrr/reference/Sound.md)/`Sound$create_tone()`
  always create one), this function delegates entirely to
  `sound$to_formant_burg()` and returns an R6 `Formant` object. *This is
  what
  [`get_formant_at_time`](https://humlab-speech.github.io/pladdrr/reference/get_formant_at_time.md)/[`get_mean_formant`](https://humlab-speech.github.io/pladdrr/reference/get_mean_formant.md)
  do NOT accept* — those two expect the legacy list below.

- If `sound` is a legacy (pre-R6) `praat_sound` list, returns a plain,
  **unclassed** list with elements `values` (a data.frame with columns
  `time`, `formant_number`, `frequency`, `bandwidth`), `n_frames`,
  `time_step`, `max_formant`, and `n_formants`. This list is no longer
  given a `"praat_formant"` class (removed when the package's S3 object
  system was fully migrated to R6), so it will not satisfy
  [`is_praat_formant()`](https://humlab-speech.github.io/pladdrr/reference/is_praat_formant.md)
  /
  [`get_formant_at_time`](https://humlab-speech.github.io/pladdrr/reference/get_formant_at_time.md)
  /
  [`get_mean_formant`](https://humlab-speech.github.io/pladdrr/reference/get_mean_formant.md)
  without manually adding `class(x) <- "praat_formant"` first.

## Details

Analyzes formant frequencies (vocal tract resonances) from a sound
object using Praat's Burg algorithm.

## Examples

``` r
# sound is an R6 Sound object here, so this delegates to to_formant_burg()
# and returns an R6 Formant object (see the second value's \value above).
sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate =
 16000)
formants <- extract_formants(sound, max_formant = 5500)
#> Warning: extract_formants() is deprecated and will be removed in v6.0.0. Use the R6 interface: sound$to_formant_burg()
f1_mean <- formants$get_mean(formant_number = 1)

# Equivalent, and the recommended way to spell it directly:
formants2 <- sound$to_formant_burg(max_frequency = 5500)
f1_mean2 <- formants2$get_mean(formant_number = 1)
```
