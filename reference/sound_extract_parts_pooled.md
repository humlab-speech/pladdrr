# Extract multiple Sound parts using object pool

Batch extraction using pooled memory reuse, for large numbers of
segments.

## Usage

``` r
sound_extract_parts_pooled(sound_xptr, start_times, end_times, use_pool = TRUE)
```

## Arguments

- sound_xptr:

  External pointer to source Sound

- start_times:

  Numeric vector of start times

- end_times:

  Numeric vector of end times

- use_pool:

  Whether to use object pool (default TRUE)

## Value

List of external pointers to extracted Sound segments

## Details

When use_pool is TRUE, Sound objects are acquired from a pool and should
be released back with sound_pool_release() when done.

\*\*Important:\*\* Pool-acquired Sounds should not be modified as they
may be reused. Copy if modification is needed.

## Examples

``` r
sound <- Sound$create_tone(frequency = 200, duration = 2.0)
starts <- c(0.1, 0.5, 1.0)
ends <- c(0.3, 0.7, 1.2)

# Batch extraction with pooling
segments <- sound_extract_parts_pooled(sound$.xptr, starts, ends)

# Release back to pool when done
for (seg in segments) {
  pladdrr:::sound_pool_release(seg)
}
```
