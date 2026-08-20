# AmplitudeTier

A Praat AmplitudeTier: sound pressure amplitude in Pascals as a function
of time.

## Arguments

- .xptr:

  Not for direct use. External pointer to the underlying C++
  AmplitudeTier object; set internally when a method returns a new
  AmplitudeTier.

## Value

An `AmplitudeTier` object.

## Details

An AmplitudeTier stores amplitude as a sparse sequence of (time, value)
points rather than a dense signal, with linear interpolation between
points. It's the amplitude counterpart to an IntensityTier (which stores
dB instead of Pa), and the two convert into each other. A common use is
pulling amplitude at glottal pulse times (from a PointProcess) to
compute shimmer.

## Usage


    tier <- amplitude_tier_create(0, 1)
    tier <- amplitude_tier_from_point_process(point_process, sound)
    tier <- intensity_tier_to_amplitude_tier(intensity_tier)

## Query methods

- `get_start_time()`, `get_end_time()` - time domain in seconds

- `get_number_of_points()` - number of (time, value) points

- `get_time_from_index(index)` - time at a 1-based point index

- `get_value_at_index(index)` - amplitude at a 1-based point index (Pa)

- `get_value_at_time(time)` - interpolated amplitude at a time (Pa)

## Modification

- `add_point(time, value)` - add a (time, value) point

- `remove_point(index)` - remove the point at a 1-based index

## Conversion and export

- `to_intensity_tier(threshold_db)` - convert amplitude to an
  IntensityTier

- `as_data_frame()` - points as a data frame with `time` and
  `amplitude_pa` columns

- `save(path)` - write to file

## See also

\[amplitude_tier_create\], \[amplitude_tier_from_point_process\],
\[intensity_tier_to_amplitude_tier\]

## Examples

``` r
tier <- amplitude_tier_create(0, 1)
tier$add_point(0.25, 0.5)
tier$add_point(0.75, 0.8)
tier$get_number_of_points()
#> [1] 2
tier$get_value_at_time(0.5)
#> [1] 0.65
```
