# Get the LongSound streaming buffer size preference

Controls how much audio Praat keeps resident in memory while streaming
from a LongSound. This is a global setting: it applies to every
LongSound opened after it is changed, not to one specific object. The
default is 60 seconds. Raise it to reduce disk re-reads when repeatedly
querying nearby windows of a very large file; lower it to shrink the
package's memory footprint when working with many LongSound objects at
once.

## Usage

``` r
longsound_get_buffer_size_pref_seconds()
```

## Value

Buffer size in seconds.

## Examples

``` r
longsound_get_buffer_size_pref_seconds()
#> [1] 600
```
