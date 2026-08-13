# FormantTier

Praat FormantTier object: formant frequencies and bandwidths at discrete
time points, with interpolation between points.

## Arguments

- tmin:

  Start time in seconds. Default 0.

- tmax:

  End time in seconds. Default 1.

- .xptr:

  Not for direct use. External pointer to the underlying C++ FormantTier
  object; set internally when a method returns a new FormantTier.

## Value

A `FormantTier` object with methods for formant frequency and bandwidth
manipulation via time-value points.

## Details

The interpolated contour can be used to filter sounds for vowel
modification or resynthesis.

## Usage


    FormantTier(tmin, tmax)              # create an empty FormantTier
    FormantTier$from_formant(formant)    # convert from a Formant object

## Query methods

- `get_start_time()`, `get_end_time()`,
  [`get_duration()`](https://humlab-speech.github.io/pladdrr/reference/get_duration.md) -
  time range in seconds

- `get_number_of_points()` - number of time points

- `get_min_num_formants()`, `get_max_num_formants()` - formant count
  across points

- `get_value_at_time(formant_number, time)` - formant frequency in Hz

- `get_bandwidth_at_time(formant_number, time)` - bandwidth in Hz

## Transformation

- `filter_sound(sound, scale = TRUE)` - filter a sound through the
  formants

- `as_data_frame()` - export to a data frame

- `save(path)` - save to file

## Examples

``` r
# Create from Formant analysis
sound <- Sound$create_tone(frequency = 150, duration = 0.5)
formant <- sound$to_formant_burg()
ft <- FormantTier$from_formant(formant)

# Query formant values
f1 <- ft$get_value_at_time(1, 0.25)  # F1 at 0.25s
f2 <- ft$get_value_at_time(2, 0.25)  # F2 at 0.25s

# Filter a source sound
source <- Sound$create_tone(frequency = 100, duration = 0.5)  # Buzz
vowel <- ft$filter_sound(source)
```
