# Enable/Disable SIMD for TextGrid Operations

Enable/Disable SIMD for TextGrid Operations

## Usage

``` r
set_textgrid_simd_enabled_bridge(enabled)
```

## Arguments

- enabled:

  Logical, TRUE to enable SIMD, FALSE for scalar

## Value

Invisibly returns `NULL`.

## Examples

``` r
set_textgrid_simd_enabled_bridge(TRUE)
textgrid_simd_enabled()
#> [1] TRUE
set_textgrid_simd_enabled_bridge(FALSE)
```
