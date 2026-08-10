# Create an Electroglottogram object

Create an Electroglottogram object

## Usage

``` r
electroglottogram_create(xmin, xmax, nx, dx, x1)
```

## Arguments

- xmin:

  Start time in seconds

- xmax:

  End time in seconds

- nx:

  Number of samples

- dx:

  Sampling period in seconds

- x1:

  Time of first sample in seconds

## Value

Electroglottogram object

## Examples

``` r
egg <- electroglottogram_create(xmin = 0, xmax = 1, nx = 16000, dx = 1 / 16000, x1 = 0)
egg$get_duration()
#> [1] 1
```
