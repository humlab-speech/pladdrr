# Count voiced frames directly

Count voiced frames directly

## Usage

``` r
pitch_count_voiced_direct(pitch_xptr)
```

## Arguments

- pitch_xptr:

  External pointer to Pitch

## Value

Number of voiced frames

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
pitch <- sound$to_pitch()
pladdrr:::pitch_count_voiced_direct(pitch$.xptr)
#> [1] 47
```
