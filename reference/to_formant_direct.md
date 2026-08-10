# Create Formant from Sound Directly (returns XPtr)

Create Formant from Sound Directly (returns XPtr)

## Usage

``` r
to_formant_direct(
  sound,
  time_step = 0,
  max_formants = 5,
  max_formant = 5500,
  window_length = 0.025,
  pre_emphasis = 50,
  max_number_of_formants = NULL,
  maximum_formant = NULL,
  pre_emphasis_from = NULL
)
```

## Arguments

- sound:

  Sound object or external pointer

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

- max_number_of_formants:

  Alias for \`max_formants\` (maximum number of formants)

- maximum_formant:

  Alias for \`max_formant\` (maximum formant frequency, Hz)

- pre_emphasis_from:

  Alias for \`pre_emphasis\` (pre-emphasis frequency, Hz)

## Value

External pointer to Formant

## Examples

``` r
sound <- Sound$create_tone(frequency = 200, duration = 0.5)
formant_ptr <- to_formant_direct(sound)
f1 <- get_formant_value_direct(formant_ptr, 1, 0.25, "hertz")
```
