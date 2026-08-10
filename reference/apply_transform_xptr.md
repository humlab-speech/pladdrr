# Apply Compiled Transform Function (Advanced Performance API)

Apply a user-defined C++ transform function to sample values, compiled
via RcppXPtrUtils, instead of calling an R callback per sample. Requires
the RcppXPtrUtils package.

## Usage

``` r
apply_transform_xptr(sound, transform_func)
```

## Arguments

- sound:

  Sound object or external pointer

- transform_func:

  External pointer from RcppXPtrUtils::cppXPtr()

## Value

Sound object with transform function applied

## Details

\*\*ADVANCED API\*\* - Requires RcppXPtrUtils package.

The transform function receives sample amplitude and returns transformed
amplitude. Common transforms:

- Clipping: \`x \> threshold ? threshold : (x \< -threshold ? -threshold
  : x)\`

- Soft clipping: \`tanh(x \* gain)\`

- Rectification: \`fabs(x)\`

- Squaring: \`x \* x\`

## Examples

``` r
# \donttest{
# Compiling a C++ transform function takes a few seconds
if (requireNamespace("RcppXPtrUtils", quietly = TRUE)) {
  soft_clip <- RcppXPtrUtils::cppXPtr(
    "double softclip(double x) { return tanh(x * 2.0); }",
    depends = character()
  )

  sound <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)
  clipped <- apply_transform_xptr(sound, soft_clip)
}
# }
```
