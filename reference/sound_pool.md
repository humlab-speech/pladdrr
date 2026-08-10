# Sound Object Pool for Batch Processing

Memory optimization for batch operations that extract many Sound
segments. Reuses Sound object allocations instead of creating/destroying
each time.

\*\*Numerical Impact:\*\* None - output is identical to non-pooled
version

## Usage

``` r
sound_pool_stats()

sound_pool_clear()

sound_pool_resize(max_size)
```

## Arguments

- max_size:

  Maximum number of Sound objects to keep in pool

## Value

`sound_pool_stats()` returns a named list with elements `hits`,
`misses`, `hit_rate`, `pool_size`, and `in_use`.

Invisibly returns `NULL`.

Invisibly returns `NULL`.

## Details

The pool automatically manages Sound object reuse: -
\`sound_pool_acquire()\` - get a Sound from pool (or create new) -
\`sound_pool_release()\` - return Sound to pool for reuse -
\`sound_pool_stats()\` - get hit/miss statistics -
\`sound_pool_clear()\` - clear the pool - \`sound_pool_resize()\` -
change pool capacity

## Examples

``` r
# Pool is used automatically by batch extraction functions
# For manual control:

# Check pool statistics
stats <- sound_pool_stats()
stats$hits
#> [1] 0
stats$misses
#> [1] 3

# Clear pool to free memory
sound_pool_clear()
```
