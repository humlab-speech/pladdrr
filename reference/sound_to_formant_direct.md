# Create Formant from Sound directly (Burg method)

Create Formant from Sound directly (Burg method)

## Usage

``` r
sound_to_formant_direct(
  sound_xptr,
  time_step = 0,
  max_formants = 5,
  max_formant = 5500,
  window_length = 0.025,
  pre_emphasis = 50
)
```

## Arguments

- sound_xptr:

  External pointer to Sound

- time_step:

  Time step (0 = auto)

- max_formants:

  Maximum number of formants

- max_formant:

  Maximum formant frequency (Hz)

- window_length:

  Window length (seconds)

- pre_emphasis:

  Pre-emphasis frequency (Hz)

## Value

External pointer to Formant

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.5)
formant_xptr <- pladdrr:::sound_to_formant_direct(sound$.xptr)
formant <- Formant(.xptr = formant_xptr)
```
