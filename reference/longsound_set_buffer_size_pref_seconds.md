# Set the LongSound streaming buffer size preference

Set the LongSound streaming buffer size preference

## Usage

``` r
longsound_set_buffer_size_pref_seconds(seconds)
```

## Arguments

- seconds:

  Buffer size in seconds. See
  [`longsound_get_buffer_size_pref_seconds`](https://humlab-speech.github.io/pladdrr/reference/longsound_get_buffer_size_pref_seconds.md)
  for what this controls.

## Value

Invisibly, the previous buffer size in seconds.

## Examples

``` r
old <- longsound_set_buffer_size_pref_seconds(120)
longsound_get_buffer_size_pref_seconds()
#> [1] 120
longsound_set_buffer_size_pref_seconds(old)
```
