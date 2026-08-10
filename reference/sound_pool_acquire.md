# Acquire pooled Sound for segment extraction

Acquire pooled Sound for segment extraction

## Usage

``` r
sound_pool_acquire(xmin, xmax, nx, dx, x1, ny)
```

## Arguments

- xmin:

  Start time

- xmax:

  End time

- nx:

  Number of samples

- dx:

  Sample period

- x1:

  First sample time

- ny:

  Number of channels

## Value

External pointer to Sound

## Examples

``` r
xptr <- pladdrr:::sound_pool_acquire(0, 0.1, 4410, 1 / 44100, 0, 1)
pladdrr:::sound_pool_release(xptr)
```
