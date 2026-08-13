# PitchTier

Praat PitchTier object: a sequence of time-value points describing a
pitch contour.

## Arguments

- tmin:

  Start time in seconds, for creating an empty PitchTier.

- tmax:

  End time in seconds, for creating an empty PitchTier.

- .xptr:

  Not for direct use. External pointer to the underlying C++ PitchTier
  object; set internally when a method returns a new PitchTier.

## Value

A `PitchTier` object with methods for pitch-contour manipulation via
time-value points.

## Details

PitchTiers are used together with Manipulation objects to modify the
pitch contour of sounds. Unlike Pitch objects, which hold sampled data,
PitchTiers hold discrete time-value pairs that can be edited directly.

## Usage


    PitchTier$new(path)          # load from file
    PitchTier(tmin, tmax)        # create an empty PitchTier
    pitch$down_to_pitch_tier()   # extract from a Pitch object

## Query methods

- `get_number_of_points()` - number of pitch points

- `get_value_at_time(time)` - interpolated F0 at a time

- `get_value_at_index(index)` - F0 of a specific point

- `get_time_from_index(index)` - time of a specific point

- `get_minimum()`, `get_maximum()` - F0 range

- `get_mean(tmin, tmax)` - mean F0 (interpolated curve)

- `get_standard_deviation(tmin, tmax)` - standard deviation

- `get_area(tmin, tmax)` - area under the curve

## Modification

- `add_point(time, value)` - add a pitch point (Hz)

- `remove_point(index)` - remove a point by index

- `remove_points_between(tmin, tmax)` - remove points in a time range

- `multiply_frequencies(factor)` - scale all frequencies

- `multiply_frequencies_in_range(tmin, tmax, factor)` - scale in a range

- `shift_frequencies(shift, unit)` - add to all frequencies

- `shift_frequencies_in_range(tmin, tmax, shift, unit)` - shift in a
  range

- `stylize(frequency_resolution, use_semitones)` - simplify the contour

- `interpolate_quadratically(points_per_parabola, logarithmically)` -
  smooth the contour

## Conversion

- `to_sound_pulse_train(sample_rate)` - synthesize a pulse train

- `to_sound_phonation(sample_rate)` - synthesize phonation

- `to_sound_sine(sample_rate)` - synthesize a sine wave

- `down_to_point_process()` - extract time points

- `to_pitch(time_step, pitch_floor, pitch_ceiling)` - convert to a Pitch
  object

## Export

- `as_data_frame()` - convert to a data.table

- `as_matrix()` - convert to a matrix

- `save(path)` - write to file

## Examples

``` r
# Create empty PitchTier and add points
pt <- PitchTier(0, 1)
pt$add_point(0.1, 120)
pt$add_point(0.5, 150)
pt$add_point(0.9, 100)

# Create from Pitch
sound <- Sound$create_tone(frequency = 150, duration = 0.5)
pitch <- sound$to_pitch()
pitch_tier <- pitch$down_to_pitch_tier()

# Modify pitch
pitch_tier$multiply_frequencies(1.5)  # Raise pitch 50%

# Query
f0_at_mid <- pitch_tier$get_value_at_time(0.25)
n_points <- pitch_tier$get_number_of_points()
f0_min <- pitch_tier$get_minimum()
f0_max <- pitch_tier$get_maximum()

# Synthesize
synth <- pitch_tier$to_sound_sine(16000)

# Export
df <- pitch_tier$as_data_frame()
```
