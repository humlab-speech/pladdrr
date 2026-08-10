# Get Sound duration directly

Get Sound duration directly

## Usage

``` r
sound_get_duration_direct(sound_xptr)
```

## Arguments

- sound_xptr:

  External pointer to Sound

## Value

Duration in seconds

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.5)
pladdrr:::sound_get_duration_direct(sound$.xptr)
#> [1] 0.5
```
