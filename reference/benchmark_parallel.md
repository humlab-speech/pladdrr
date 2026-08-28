# Benchmark Parallel vs Sequential Processing

Compare performance of parallel vs sequential processing. Useful for
determining optimal core count for your workload.

## Usage

``` r
benchmark_parallel(files, analysis_func, core_counts = c(1, 2, 4))
```

## Arguments

- files:

  Character vector of files (use subset for quick test)

- analysis_func:

  Function to benchmark

- core_counts:

  Integer vector. Core counts to test (default: c(1, 2, 4))

## Value

Data frame with timing results

## Examples

``` r
# \donttest{
audio_dir <- tempfile("audio_")
dir.create(audio_dir)
tone <- Sound$create_tone(frequency = 150, duration = 0.3, sampling_rate = 16000)
tone$save(file.path(audio_dir, "tone1.wav"))
files <- list.files(audio_dir, pattern = "\\.wav$", full.names = TRUE)

# CRAN examples should use at most 2 cores
results <- benchmark_parallel(
  files,
  function(s) s$to_pitch()$get_mean(0, 0, "hertz"),
  core_counts = c(1, 2)
)
#> Testing with 1 core(s)...
#> Using single core (set n_cores > 1 for parallel processing)
#> Testing with 2 core(s)...
#> Processing 1 files using 2 cores (2 thread(s)/worker)
print(results)
#>   cores    time_sec   speedup
#> 1     1 0.002175808 1.0000000
#> 2     2 0.005701303 0.3816334
# }
```
