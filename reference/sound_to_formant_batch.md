# Extract Formants from Multiple Sounds in Single C++ Call

Extract Formants from Multiple Sounds in Single C++ Call

## Usage

``` r
sound_to_formant_batch(
  sounds,
  time_step = 0.005,
  max_formants = 5,
  max_frequency = 5500,
  window_length = 0.025,
  pre_emphasis_from = 50,
  return_r6 = TRUE
)
```

## Arguments

- sounds:

  List of Sound objects (R6) or external pointers

- time_step:

  Numeric. Time step in seconds (default: 0.005)

- max_formants:

  Numeric. Maximum number of formants (default: 5)

- max_frequency:

  Numeric. Maximum frequency in Hz (default: 5500)

- window_length:

  Numeric. Window length in seconds (default: 0.025)

- pre_emphasis_from:

  Numeric. Pre-emphasis from frequency (default: 50)

- return_r6:

  Logical. Return R6 Formant objects (TRUE) or raw xptrs (FALSE)

## Value

List of Formant objects (R6 or xptr depending on return_r6)

## Examples

``` r
sounds <- list(
  Sound$create_tone(frequency = 150, duration = 0.5),
  Sound$create_tone(frequency = 200, duration = 0.5)
)
formants <- sound_to_formant_batch(sounds)
```
