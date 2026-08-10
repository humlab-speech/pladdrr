# Get all common pitch statistics in single call

Get all common pitch statistics in single call

## Usage

``` r
pitch_get_all_stats_direct(pitch_xptr, from_time = 0, to_time = 0, unit = 0L)
```

## Arguments

- pitch_xptr:

  External pointer to Pitch

- from_time:

  Start time

- to_time:

  End time

- unit:

  Unit code

## Value

List with min, max, mean, stdev, median, q25, q75

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 1.0)
pitch <- sound$to_pitch()
stats <- pladdrr:::pitch_get_all_stats_direct(pitch$.xptr)
str(stats)
#> List of 8
#>  $ min         : num 150
#>  $ max         : num 150
#>  $ mean        : num 150
#>  $ stdev       : num 2.97e-09
#>  $ median      : num 150
#>  $ q25         : num 150
#>  $ q75         : num 150
#>  $ count_voiced: num 97
```
