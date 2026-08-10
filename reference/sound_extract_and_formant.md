# Extract Parts and Analyze Formants in Single C++ Call

Extract Parts and Analyze Formants in Single C++ Call

## Usage

``` r
sound_extract_and_formant(
  sound,
  from_times,
  to_times,
  time_step = 0.005,
  max_formants = 5,
  max_frequency = 5500,
  window_length = 0.025,
  pre_emphasis_from = 50,
  return_r6 = TRUE
)
```

## Arguments

- sound:

  Sound object (R6) or external pointer

- from_times:

  Numeric vector of start times

- to_times:

  Numeric vector of end times

- time_step:

  Numeric. Formant time step (default: 0.005)

- max_formants:

  Numeric. Maximum number of formants (default: 5)

- max_frequency:

  Numeric. Maximum frequency (default: 5500)

- window_length:

  Numeric. Window length (default: 0.025)

- pre_emphasis_from:

  Numeric. Pre-emphasis frequency (default: 50)

- return_r6:

  Logical. Return R6 Formant objects (TRUE) or raw xptrs (FALSE)

## Value

List of Formant objects (R6 or xptr depending on return_r6)

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 2.0)
from_times <- c(0.2, 1.0)
to_times <- c(0.6, 1.4)
formants <- sound_extract_and_formant(sound, from_times, to_times)
```
