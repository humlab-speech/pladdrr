# Get minimum intensity with time information

Get minimum intensity with time information

## Usage

``` r
intensity_get_minimum_with_time(intensity_xptr, from_time = 0, to_time = 0)
```

## Arguments

- intensity_xptr:

  External pointer to Intensity object

- from_time:

  Start time

- to_time:

  End time

## Value

List with value (dB) and time

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
intensity <- sound$to_intensity()
pladdrr:::intensity_get_minimum_with_time(intensity$.xptr)
#> $value
#> [1] 90.88181
#> 
#> $time
#> [1] 0.05
#> 
```
