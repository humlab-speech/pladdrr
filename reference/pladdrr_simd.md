# Get or set runtime SIMD usage

Get or set runtime SIMD usage

## Usage

``` r
pladdrr_simd(enabled = NULL)
```

## Arguments

- enabled:

  Logical scalar to enable or disable SIMD at runtime. Use \`NULL\`
  (default) to query the current state without changing it.

## Value

Invisibly, the same list returned by \[simd_info()\].

## Examples

``` r
pladdrr_simd()      # query current state
pladdrr_simd(FALSE) # force scalar fallbacks when available
pladdrr_simd(TRUE)  # restore SIMD
```
