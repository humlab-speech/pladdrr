# Create a FormantPath object from a Sound

A FormantPath object represents multiple formant tracking candidates
with different ceiling frequencies, allowing for robust formant analysis
by automatically selecting the optimal tracking path.

## Arguments

- sound:

  A Sound object or path to audio file

- time_step:

  Time step for analysis in seconds (must be \> 0, typically 0.005)

- max_num_formants:

  Maximum number of formants to track (typically 5)

- formant_ceiling:

  Maximum formant frequency in Hz (typically 5000-5500)

- window_length:

  Analysis window length in seconds (typically 0.025)

- preemphasis_from:

  Preemphasis frequency in Hz (typically 50)

- ceiling_step_fraction:

  Step size for ceiling frequency variation (0.05-0.1)

- num_steps_up_down:

  Number of steps above/below ceiling (typically 2-4)

## Value

An object of class `FormantPath` wrapping the set of candidate formant
tracks (list with methods; dispatched via the shared `PraatObject`
pattern).

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.3)
fp <- FormantPath(sound)
fp$get_duration()
#> [1] 0.3
```
