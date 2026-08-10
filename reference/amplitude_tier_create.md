# Create an empty AmplitudeTier

Creates a new AmplitudeTier object with no points.

## Usage

``` r
amplitude_tier_create(tmin, tmax)
```

## Arguments

- tmin:

  Start time in seconds

- tmax:

  End time in seconds

## Value

An AmplitudeTier object

## Examples

``` r
tier <- amplitude_tier_create(0, 1)
tier$add_point(0.5, 0.8)
```
