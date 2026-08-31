# Create Common Window Function XPtr

Convenience function to create pre-defined window functions as compiled
XPtrs. Requires the RcppXPtrUtils package.

## Usage

``` r
create_window_xptr(
  type = c("hamming", "hanning", "gaussian", "triangular", "blackman", "rectangular"),
  sigma = 0.25
)
```

## Arguments

- type:

  Character, one of "hamming", "hanning", "gaussian", "triangular",
  "blackman", "rectangular"

- sigma:

  Numeric, standard deviation for Gaussian window (default 0.25)

## Value

External pointer to compiled window function

## Examples

``` r
# \donttest{
# Compiling a C++ window function takes a few seconds
if (requireNamespace("RcppXPtrUtils", quietly = TRUE)) {
  hamming <- create_window_xptr("hamming")

sound <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate =
 16000)
  windowed <- apply_window_xptr(sound, hamming)
}
# }
```
