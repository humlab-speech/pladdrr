# Create LTAS from Sound Directly

Create LTAS from Sound Directly

## Usage

``` r
to_ltas_direct(sound, bandwidth = 100)
```

## Arguments

- sound:

  Sound object or external pointer

- bandwidth:

  Numeric. Bandwidth in Hz (default: 100)

## Value

A wrapped `Ltas` object

## Examples

``` r
sound <- Sound$create_tone(frequency = 200, duration = 0.5)
ltas <- to_ltas_direct(sound, bandwidth = 100)
ltas$get_slope(0, 1000, 1000, 10000, "energy")
#> [1] -62.02499
```
