# Get SIMD Capabilities

Reports the SIMD (Single Instruction Multiple Data) capabilities
available in the current installation, for diagnostics and debugging.

## Usage

``` r
simd_info()
```

## Value

A list with the following components:

- enabled:

  Logical indicating if SIMD is currently enabled

- available:

  Logical indicating if SIMD support was compiled in

- architecture:

  Character string describing the SIMD instruction set (e.g., "AVX2",
  "SSE4.2", "NEON")

- batch_size_double:

  Integer number of doubles processed per SIMD operation

- batch_size_float:

  Integer number of floats processed per SIMD operation

- version:

  Character string describing the SIMD library in use

- debug_build:

  Logical indicating the shared object was compiled without `NDEBUG`,
  i.e. by `devtools::load_all()` /
  [`pkgbuild::compile_dll()`](https://rdrr.io/pkg/pkgbuild/man/compile_dll.html),
  which force `-UNDEBUG -Wall -pedantic -g -O0`. Such a build is not
  representative of normal operation and must not be used for timing
  comparisons; reinstall with `R CMD INSTALL --preclean .` to get
  optimised objects.

## Details

The pladdrr package uses SIMD acceleration for computationally intensive
operations like autocorrelation, windowing, and statistical
computations. The effect varies by code path and platform; use
\[pladdrr_simd()\] to toggle SIMD at runtime and compare a given
workload directly.

Common SIMD instruction sets:

- **AVX2**: 256-bit vectors (4 doubles or 8 floats) - Intel/AMD x86_64

- **SSE4.2**: 128-bit vectors (2 doubles or 4 floats) - Older x86_64

- **NEON**: 128-bit vectors (2 doubles or 4 floats) - ARM (Apple
  Silicon)

Set `options(pladdrr.use_simd = FALSE)` before loading the package to
start in scalar mode, or use \[pladdrr_simd()\] after load for runtime
A/B checks. The option is read during `.onLoad`.

## Examples

``` r
# Check SIMD capabilities
info <- simd_info()
print(info)
#> $enabled
#> [1] TRUE
#> 
#> $available
#> [1] TRUE
#> 
#> $architecture
#> [1] "Generic"
#> 
#> $batch_size_double
#> [1] 2
#> 
#> $batch_size_float
#> [1] 4
#> 
#> $version
#> [1] "xsimd"
#> 
#> $debug_build
#> [1] FALSE
#> 

if (info$architecture == "AVX2") {
  message("AVX2 SIMD support detected")
}

# Disable SIMD temporarily for testing
pladdrr_simd(FALSE)
# ... run tests ...
pladdrr_simd(TRUE)
```
