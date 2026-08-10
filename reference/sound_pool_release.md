# Release pooled Sound back to pool

Release pooled Sound back to pool

## Usage

``` r
sound_pool_release(sound_xptr)
```

## Arguments

- sound_xptr:

  External pointer to Sound

## Value

Invisibly returns `NULL`.

## Examples

``` r
xptr <- pladdrr:::sound_pool_acquire(0, 0.1, 4410, 1 / 44100, 0, 1)
pladdrr:::sound_pool_release(xptr)
```
