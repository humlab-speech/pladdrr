# Create AmplitudeTier from PointProcess and Sound

Extracts amplitude values from a Sound at the times specified by a
PointProcess.

## Usage

``` r
amplitude_tier_from_point_process(point_process, sound)
```

## Arguments

- point_process:

  A PointProcess object

- sound:

  A Sound object

## Value

An AmplitudeTier object with amplitudes at each point time

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate =
 16000)
pp <- sound$to_point_process_periodic_cc(75, 600)
tier <- amplitude_tier_from_point_process(pp, sound)
tier$get_number_of_points()
#> [1] 72
```
