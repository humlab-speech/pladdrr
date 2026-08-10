# Get pitch adaptive range (quartiles with factors) in single call

Calculate Q1, Q3, and adaptive min/max pitch range in single C++ call.
Used for VUV two-pass pitch analysis.

## Usage

``` r
pitch_get_adaptive_range(
  pitch_xptr,
  from_time = 0,
  to_time = 0,
  q1_factor = 0.75,
  q3_factor = 1.5,
  unit = 0L
)
```

## Arguments

- pitch_xptr:

  External pointer to Pitch object

- from_time:

  Start time (0 for full)

- to_time:

  End time (0 for full)

- q1_factor:

  Factor to multiply Q1 for min_pitch (e.g., 0.75)

- q3_factor:

  Factor to multiply Q3 for max_pitch (e.g., 1.5)

- unit:

  Integer code for unit

## Value

List with q1, q3, min_pitch, max_pitch

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 1.0)
pitch <- sound$to_pitch()
range_info <- pladdrr:::pitch_get_adaptive_range(pitch$.xptr)
str(range_info)
#> List of 4
#>  $ q1       : num 150
#>  $ q3       : num 150
#>  $ min_pitch: num 113
#>  $ max_pitch: num 225
```
