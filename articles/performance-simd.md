# Performance Optimization and SIMD in pladdrr

## Introduction

pladdrr uses **SIMD (Single Instruction, Multiple Data)** acceleration
in several of its DSP kernels. This vignette explains how SIMD works in
pladdrr, what operations it covers, how to check what your build
supports, and how to measure the effect on your own hardware and
workload.

``` r

library(pladdrr)
#> pladdrr: direct access to Praat's core algorithms from R.
#> See ?pladdrr for an overview, or citation("pladdrr") for citation details.
```

## What is SIMD?

SIMD allows modern CPUs to process multiple data points simultaneously
using a single instruction:

- **Scalar**: Process 1 sample at a time
- **SIMD**: Process several samples simultaneously (the exact count
  depends on the CPU and instruction set)

### Example: Adding Two Vectors

**Scalar (traditional)**:

    for (i in 1:1000) {
      result[i] = a[i] + b[i]  # Process one element
    }

**SIMD (vectorized)**:

    for (i in 1:1000 step 4) {
      result[i:i+3] = a[i:i+3] + b[i:i+3]  # Process four elements
    }

SIMD is particularly effective for: - DSP algorithms (filtering, FFT,
convolution) - Matrix operations - Statistical computations - Audio
processing

## SIMD in pladdrr

### Automatic Detection

pladdrr selects its SIMD instruction set at **compile time**. This is
the single most important thing to understand about what a given
installation actually uses:

CRAN policy forbids `-march=native` and `-mavx2`, and pladdrr contains
no runtime CPU dispatch. A binary built the ordinary way therefore uses
only what the compiler guarantees for the target ABI:

- **arm64 (Apple Silicon, aarch64 Linux):** NEON, 2 doubles per vector.
- **x86_64:** SSE2, 2 doubles per vector. **AVX2 and AVX-512 code paths
  are never reached**, whatever the CPU supports, unless you rebuild
  from source with your own `~/.R/Makevars` adding `-march=native`.

Check what your installation actually built with:

``` r

# Get SIMD information
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
```

### What you actually get

| Extension   | Reached by a stock CRAN build?             | Doubles per vector |
|-------------|--------------------------------------------|--------------------|
| **NEON**    | Yes, on all arm64                          | 2                  |
| **SSE2**    | Yes, on all x86_64                         | 2                  |
| **AVX2**    | No — needs a source rebuild with `-march=` | 4                  |
| **AVX-512** | No — needs a source rebuild with `-march=` | 8                  |

### Measuring the effect on your hardware

Whole-routine runtime for a full analysis (`to_pitch()`,
`to_formant_burg()`,
[`calculate_cpps_fast()`](https://humlab-speech.github.io/pladdrr/reference/calculate_cpps_fast.md),
…) is usually dominated by work the SIMD kernels don’t touch. For CPPS
specifically, most of the time is spent in the per-frame robust trend
fit, which is branchy selection code rather than a vectorizable loop.
SIMD is most visible in narrow kernels that operate on long plain
vectors — for example the batch statistics bridges (`mean`, `range`,
`sd` over large numeric vectors).

[`pladdrr_simd()`](https://humlab-speech.github.io/pladdrr/reference/pladdrr_simd.md)
lets you toggle SIMD on and off at runtime so you can A/B your own
workload:

``` r

library(microbenchmark)

sound <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))

pladdrr_simd(FALSE)
scalar_time <- microbenchmark(sound$to_pitch(), times = 50)

pladdrr_simd(TRUE)
simd_time <- microbenchmark(sound$to_pitch(), times = 50)

print(scalar_time)
#> Unit: milliseconds
#>              expr      min       lq     mean   median       uq      max neval
#>  sound$to_pitch() 4.165483 4.288019 7.447008 4.320839 4.354228 160.4701    50
print(simd_time)
#> Unit: milliseconds
#>              expr      min       lq     mean  median       uq      max neval
#>  sound$to_pitch() 4.039101 4.320508 4.387884 4.36888 4.440045 5.100465    50
```

Gains vary by routine, CPU, compiler, and vector length — there is no
single number that applies across machines, so measure on the routine
and hardware you actually care about.

### What Operations Use SIMD?

#### Phase 1: Matrix and Data Operations

- Matrix multiplication
- Element-wise operations
- Data type conversions
- Transpose operations

#### Phase 2: Intensity Analysis

- RMS (Root Mean Square) calculation
- Energy and power computation
- Sound mixing and addition
- Amplitude scaling

#### Phase 3: Correlation and Windowing

- Autocorrelation (crucial for pitch detection)
- Cross-correlation
- Window function application (Hamming, Hanning, Gaussian)
- Pitch candidates computation

#### Phase 4: FFT and Formant Extraction

- **FFT operations** (Radix-2, Real FFT, Inverse FFT)
- **LPC coefficient calculation** (Burg’s algorithm)
- **Formant frequency estimation**
- **Bandwidth calculation**
- **Cochleagram filter banks**
- **Excitation pattern computation**

## Benchmarking Your Own Workloads

### FFT Performance

``` r

# Create test sound
sound <- Sound$create_pure_tone(frequency = 440, duration = 1.0, sampling_rate = 44100)

# Benchmark FFT (used in Spectrum creation)
library(microbenchmark)

result <- microbenchmark(
  spectrum = sound$to_spectrum(),
  times = 100
)

print(result)
```

The FFT itself is pocketfft, not a pladdrr SIMD kernel, so the
[`pladdrr_simd()`](https://humlab-speech.github.io/pladdrr/reference/pladdrr_simd.md)
toggle does not affect it. Run the chunk above on your own hardware
rather than relying on a quoted figure.

### Formant Extraction Performance

``` r

sound <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))

result <- microbenchmark(
  burg = sound$to_formant_burg(),
  willems = sound$to_formant_willems(),
  sl = sound$to_formant_sl(),
  times = 50
)

print(result)
```

Compare the three methods on your own machine and material — their
relative cost depends on formant order, time step, and signal length.

### Cochleagram Performance

``` r

# The EDB algorithm requires a sampling rate of at least 44.1 kHz
sound <- Sound$create_pure_tone(frequency = 440, duration = 2.0, sampling_rate = 44100)

result <- microbenchmark(
  standard = sound$to_cochleagram(dt = 0.01, df = 0.1),
  edb = sound$to_cochleagram_edb(dtime = 0.01, dfreq = 0.1),
  times = 20
)

print(result)
```

The EDB method does more per-channel work than the standard method;
measure the ratio on your own hardware if it matters for your pipeline.

## Optimization Tips

### 1. Use Appropriate Sample Rates

Higher sample rates mean more samples to process:

``` r

sound <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))

# For speech analysis, 16-22 kHz is often sufficient
sound_22k <- sound$resample(22050)
formant_22k <- sound_22k$to_formant_burg()

# 48 kHz only needed for music/high-quality audio
sound_48k <- sound$resample(48000)
formant_48k <- sound_48k$to_formant_burg()
```

### 2. Optimize Time Steps

Smaller time steps mean more frames to process:

``` r

# Standard time step (good balance)
formant_standard <- sound$to_formant_burg(time_step = 0.005)  # 5 ms

# Coarse time step (fewer frames, less temporal detail)
formant_coarse <- sound$to_formant_burg(time_step = 0.010)    # 10 ms

# Fine time step (more frames, more temporal detail)
formant_fine <- sound$to_formant_burg(time_step = 0.002)      # 2 ms
```

Pick the time step your analysis actually needs — finer steps cost more
frames to compute without necessarily adding useful information.

### 3. Process Multiple Files Together

``` r

# Load all sounds first
sound_files <- list.files("data/", pattern = "\\.wav$", full.names = TRUE)
sounds <- lapply(sound_files, Sound$new)

# Process as a batch
formants <- lapply(sounds, function(s) {
  s$to_formant_burg(time_step = 0.005)
})

# Extract F1 and F2
f1_f2 <- do.call(rbind, lapply(formants, function(f) {
  data.frame(
    f1 = f$get_mean(1, 0, 0, unit = "hertz"),
    f2 = f$get_mean(2, 0, 0, unit = "hertz")
  )
}))
```

### 4. Reuse Objects When Possible

``` r

wav_path <- system.file("extdata", "test.wav", package = "pladdrr")

# Good: Reuse sound object
sound <- Sound$new(wav_path)
pitch <- sound$to_pitch()
formant <- sound$to_formant_burg()
intensity <- sound$to_intensity()

# Avoid: Reloading and re-decoding the file for every analysis
pitch <- Sound$new(wav_path)$to_pitch()
formant <- Sound$new(wav_path)$to_formant_burg()
intensity <- Sound$new(wav_path)$to_intensity()
```

### 5. FFT Sizes

``` r

# pladdrr handles all FFT sizes correctly, including non-power-of-2 sizes

# If you can choose duration:
# Power-of-2 sample count:
duration_good <- 1024 / 16000  # 0.064 s, 1024 samples

# Also fine: any duration
duration_any <- 0.05  # 800 samples (not power of 2, still works)
```

## Platform Notes

### Apple Silicon (M1/M2/M3)

- Uses **ARM NEON** instructions
- Best practices:
  - Use a native (arm64) R installation, not Rosetta 2
  - Compile the package from source if you want to confirm which
    instruction set was selected

### Intel/AMD (x86_64)

- CRAN binaries reach SSE2 only (see the capability table above)
- A source build unlocks AVX2 where the compiler target allows it
- Optimized BLAS/LAPACK (Intel MKL, OpenBLAS) affects R’s own linear
  algebra, separately from pladdrr’s SIMD kernels

### Server CPUs with AVX-512

- Reachable only via a source rebuild with an explicit `-march=` target
  (see the capability table above)
- Relevant mainly for large-scale batch processing and high-throughput
  pipelines where you control the build

### Older CPUs

- Pre-2013 x86_64 CPUs still have SSE2, which pladdrr’s stock code path
  already targets
- Falls back to scalar code automatically if a targeted instruction set
  is unavailable at runtime

## Profiling Your Workloads

### Basic Timing

``` r

# Time a single operation
start_time <- Sys.time()
formant <- sound$to_formant_burg()
end_time <- Sys.time()
print(end_time - start_time)
```

### Detailed Profiling

``` r

library(profvis)

profvis({
  # Load sound
  sound <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))

  # Perform analysis
  pitch <- sound$to_pitch()
  formant <- sound$to_formant_burg()
  intensity <- sound$to_intensity()
  spectrum <- sound$to_spectrum()

  # Extract values
  f0_mean <- pitch$get_mean(0, 0, unit = "hertz")
  f1_mean <- formant$get_mean(1, 0, 0, unit = "hertz")
})
```

### Benchmarking Multiple Methods

``` r

library(microbenchmark)

sound <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))

# Compare formant extraction methods
result <- microbenchmark(
  burg = sound$to_formant_burg(),
  willems = sound$to_formant_willems(number_of_formants = 5),
  sl = sound$to_formant_sl(),
  times = 20
)

print(result)
boxplot(result)
```

## SIMD Accuracy

SIMD operations in pladdrr are **numerically equivalent** to scalar
operations:

``` r

sound <- Sound$create_pure_tone(frequency = 440, duration = 0.5, sampling_rate = 22050)

# Run same analysis twice
formant1 <- sound$to_formant_burg()
formant2 <- sound$to_formant_burg()

# Extract values
f1_1 <- formant1$get_value_at_time(1, 0.25, unit = "hertz")
f1_2 <- formant2$get_value_at_time(1, 0.25, unit = "hertz")

# Should be identical (within floating-point precision)
identical(f1_1, f1_2)  # TRUE
#> [1] TRUE
```

Tolerance: **1e-10** (virtually identical) — the SIMD and scalar code
paths are required to agree to within this bound, so switching between
them never changes your results in a way that matters.

## Fallback Behavior

If SIMD is not available:

1.  **Compile time**: Package detects CPU capabilities
2.  **No SIMD**: Falls back to scalar (non-vectorized) code
3.  **Same results**: Output is identical either way
4.  **No user action needed**: Everything works transparently

``` r

# This code works identically on all systems, with or without SIMD
formant <- sound$to_formant_burg()
```

## Compilation Notes

### Installing from Source

To reach instruction sets beyond what a stock CRAN binary targets
(e.g. AVX2 on x86_64, subject to CRAN’s `-march=native` restriction
still applying to CRAN’s own build), compile from source with your own
`~/.R/Makevars`:

``` r

# Install from source
install.packages("pladdrr", type = "source")

# Or from GitHub
remotes::install_github("humlab-speech/pladdrr")
```

### Binary Packages

CRAN binary packages are compiled per the capability table above: -
**Windows**: SSE2 baseline - **macOS**: ARM NEON (Apple Silicon) or SSE2
(Intel) - **Linux**: SSE2 baseline; detected at compile time

## Troubleshooting

### SIMD Not Detected

``` r

# Check SIMD availability
simd_info()$available
#> [1] TRUE

# If FALSE, possible reasons:
# 1. Binary package not compiled with SIMD
#    Solution: install.packages("pladdrr", type = "source")
#
# 2. Old CPU without SIMD support
#    Solution: Use package as-is (scalar fallback)
#
# 3. Rosetta 2 on Apple Silicon
#    Solution: Install ARM64 native R
```

### Not Sure Where Time Is Going?

1.  **Check what your build supports**:
    [`simd_info()`](https://humlab-speech.github.io/pladdrr/reference/simd_info.md)
2.  **Profile your code**: Use `profvis()` to find where time is
    actually spent
3.  **Review your parameters**: time step, sample rate, and formant
    order all affect frame count
4.  **Consider batching**: process multiple files together when your
    pipeline allows it

## Summary

- pladdrr uses **SIMD** in several of its DSP kernels, where the
  compile-time target allows it
- **Automatic**: No code changes needed to benefit from it
- **Accurate**: Numerically identical to scalar code, to within a tight
  tolerance
- **Portable**: Falls back gracefully on CPUs without the targeted
  instruction set
- **Coverage**: Phases 1-4 above cover the major DSP operations that use
  it

Focus your own optimization efforts on: 1. Choosing appropriate
parameters (sample rate, time step) 2. Batch processing when your
pipeline allows it 3. Reusing objects to avoid redundant I/O 4. Using
the right analysis method for your needs 5. Measuring your own workload
with `microbenchmark`/`profvis` rather than assuming

## Advanced Performance APIs

Beyond SIMD, pladdrr provides a set of **advanced APIs** for batch
processing workflows that would otherwise cross the R/C++ boundary once
per query.

### Batch Statistics API

When calculating statistics over multiple time intervals, use batch
functions instead of repeated R method calls:

``` r

# Create pitch object
sound <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
pitch <- sound$to_pitch_cc()

# Define 100 time intervals covering the file's duration
# (adjust the upper bound to your own recording's length)
from_times <- seq(0, sound$get_total_duration() - 0.1, length.out = 100)
to_times <- from_times + 0.1
metrics <- c("min", "max", "mean", "stdev", "q25", "q75")

# Individual R method calls (100 * 6 = 600 R<->C++ boundary crossings)
for (i in 1:100) {
  min_val <- pitch$get_minimum(from_times[i], to_times[i], "hertz")
  max_val <- pitch$get_maximum(from_times[i], to_times[i], "hertz")
  # ... etc
}

# Single C++ call (1 boundary crossing); pitch_get_statistics_batch()
# is an internal function, accessed with the ::: operator
stats_matrix <- pladdrr:::pitch_get_statistics_batch(
  pitch$.xptr,
  from_times,
  to_times,
  metrics,
  unit = 0L  # Hertz
)
# Returns: 100 x 6 matrix with all statistics
```

Similar functions exist for Intensity:

``` r

intensity <- sound$to_intensity()
intensity_stats <- pladdrr:::intensity_get_statistics_batch(
  intensity$.xptr,
  from_times,
  to_times,
  c("min", "max", "mean"),
  averaging_method = 0L  # Energy averaging
)
```

### Fast CPPS API

For AVQI and voice quality analysis, use the fast CPPS functions:

``` r

# R6 method dispatch
cpps_standard <- {
  pcep <- sound$to_powercepstrogram(60, 0.002, 5000, 50)
  pcep$get_cpps(subtract_tilt = FALSE, time_averaging_window = 0.01)
}

# Direct C++ call
cpps_fast <- calculate_cpps_fast(
  sound,
  subtract_tilt = FALSE,
  time_averaging_window = 0.01,
  quefrency_averaging_window = 0.001,
  pitch_floor = 60,
  pitch_ceiling = 330
)
```

### Adaptive Pitch Range (for VUV analysis)

For two-pass pitch analysis, get quartiles and adaptive range in a
single call:

``` r

# Create initial pitch estimate
pitch <- sound$to_pitch_cc(pitch_floor = 50, pitch_ceiling = 800)

# Get Q1, Q3, and adaptive range in one call
# pitch_get_adaptive_range() is an internal function, accessed with :::
adaptive <- pladdrr:::pitch_get_adaptive_range(
  pitch$.xptr,
  from_time = 0,
  to_time = 0,  # 0 = full duration
  q1_factor = 0.75,
  q3_factor = 1.5
)
# Returns: list(q1, q3, min_pitch, max_pitch)

# Second pass with refined range
pitch2 <- sound$to_pitch_cc(
  pitch_floor = adaptive$min_pitch,
  pitch_ceiling = adaptive$max_pitch
)
```

### XPtr Window Functions (RcppXPtrUtils)

For custom window functions or transforms, use compiled C++ functions
instead of an R callback evaluated once per sample:

``` r

# Requires: install.packages("RcppXPtrUtils")
library(RcppXPtrUtils)

# Create compiled Gaussian window function
gauss_window <- cppXPtr(
  "double window(double t) {
     double x = t - 0.5;
     return exp(-18.0 * x * x);
   }",
  includes = "#include <cmath>",
  depends = character()
)

# Apply to sound (no R call overhead per sample)
windowed <- apply_window_xptr(sound, gauss_window)

# Or use pre-defined window types
hamming <- create_window_xptr("hamming")
windowed2 <- apply_window_xptr(sound, hamming)
```

Custom transforms work similarly:

``` r

# Create soft clipping function
soft_clip <- cppXPtr(
  "double clip(double x) { return tanh(x * 2.0); }",
  includes = "#include <cmath>",
  depends = character()
)

clipped <- apply_transform_xptr(sound, soft_clip)
```

### When to Use Advanced APIs

| API | Use When |
|----|----|
| `pitch_get_statistics_batch()` | \>10 intervals, multiple metrics |
| `intensity_get_statistics_batch()` | \>10 intervals, multiple metrics |
| [`calculate_cpps_fast()`](https://humlab-speech.github.io/pladdrr/reference/calculate_cpps_fast.md) | AVQI, voice quality analysis |
| `pitch_get_adaptive_range()` | Two-pass pitch analysis |
| [`apply_window_xptr()`](https://humlab-speech.github.io/pladdrr/reference/apply_window_xptr.md) | Custom windowing on large files |
| [`apply_transform_xptr()`](https://humlab-speech.github.io/pladdrr/reference/apply_transform_xptr.md) | Custom DSP on large files |

## Further Reading

- Intel Intrinsics Guide:
  <https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html>
- ARM NEON Programming Guide
- RcppXPtrUtils: <https://github.com/Enchufa2/RcppXPtrUtils>
- RcppXsimd documentation

## Session Info

``` r

sessionInfo()
#> R version 4.6.1 (2026-06-24)
#> Platform: x86_64-pc-linux-gnu
#> Running under: Ubuntu 24.04.4 LTS
#> 
#> Matrix products: default
#> BLAS:   /usr/lib/x86_64-linux-gnu/openblas-pthread/libblas.so.3 
#> LAPACK: /usr/lib/x86_64-linux-gnu/openblas-pthread/libopenblasp-r0.3.26.so;  LAPACK version 3.12.0
#> 
#> locale:
#>  [1] LC_CTYPE=C.UTF-8       LC_NUMERIC=C           LC_TIME=C.UTF-8       
#>  [4] LC_COLLATE=C.UTF-8     LC_MONETARY=C.UTF-8    LC_MESSAGES=C.UTF-8   
#>  [7] LC_PAPER=C.UTF-8       LC_NAME=C              LC_ADDRESS=C          
#> [10] LC_TELEPHONE=C         LC_MEASUREMENT=C.UTF-8 LC_IDENTIFICATION=C   
#> 
#> time zone: UTC
#> tzcode source: system (glibc)
#> 
#> attached base packages:
#> [1] stats     graphics  grDevices utils     datasets  methods   base     
#> 
#> other attached packages:
#> [1] RcppXPtrUtils_0.1.3  microbenchmark_1.5.0 pladdrr_5.0.5       
#> 
#> loaded via a namespace (and not attached):
#>  [1] gtable_0.3.6        jsonlite_2.0.0      dplyr_1.2.1        
#>  [4] compiler_4.6.1      tidyselect_1.2.1    Rcpp_1.1.2         
#>  [7] jquerylib_0.1.4     systemfonts_1.3.2   scales_1.4.0       
#> [10] textshaping_1.0.5   yaml_2.3.12         fastmap_1.2.0      
#> [13] ggplot2_4.0.3       R6_2.6.1            generics_0.1.4     
#> [16] knitr_1.51          tibble_3.3.1        desc_1.4.3         
#> [19] bslib_0.12.0        pillar_1.11.1       RColorBrewer_1.1-3 
#> [22] rlang_1.3.0         cachem_1.1.0        xfun_0.60          
#> [25] fs_2.1.0            sass_0.4.10         S7_0.2.2           
#> [28] otel_0.2.0          cli_3.6.6           pkgdown_2.2.1      
#> [31] magrittr_2.0.5      digest_0.6.39       grid_4.6.1         
#> [34] lifecycle_1.0.5     vctrs_0.7.3         evaluate_1.0.5     
#> [37] glue_1.8.1          data.table_1.18.6.1 farver_2.1.2       
#> [40] codetools_0.2-20    ragg_1.5.2          rmarkdown_2.31     
#> [43] tools_4.6.1         pkgconfig_2.0.3     htmltools_0.5.9
```
