# Convert IntensityTier to AmplitudeTier

Converts intensity values (dB) to amplitude values.

## Usage

``` r
intensity_tier_to_amplitude_tier(intensity_tier)
```

## Arguments

- intensity_tier:

  An IntensityTier object

## Value

An AmplitudeTier object

## Examples

``` r
it <- IntensityTier(0, 1)
it$add_point(0.25, 70)
it$add_point(0.75, 60)
at <- intensity_tier_to_amplitude_tier(it)
at$get_number_of_points()
#> [1] 2
```
