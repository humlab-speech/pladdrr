# Get pitch value at time directly (no R6 dispatch)

Get pitch value at time directly (no R6 dispatch)

## Usage

``` r
pitch_get_value_direct(pitch_xptr, time, unit = 0L, interpolate = TRUE)
```

## Arguments

- pitch_xptr:

  External pointer to Pitch

- time:

  Time in seconds

- unit:

  0=Hertz, 1=Hertz_log, 2=mel, 3=logHertz, 4=semitones

- interpolate:

  Whether to interpolate

## Value

Pitch value

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 1.0)
pitch <- sound$to_pitch()
pladdrr:::pitch_get_value_direct(pitch$.xptr, 0.5)
#> [1] 150.0017
```
