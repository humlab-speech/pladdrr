# Internal formant detection using Burg's method

Internal formant detection using Burg's method

## Usage

``` r
.detect_formants_burg(
  signal,
  sr,
  time_step,
  max_formant,
  n_formants,
  window_length,
  pre_emphasis_from
)
```

## Arguments

- signal:

  Numeric vector, the audio samples

- sr:

  Sampling rate in Hz

- time_step:

  Time between analysis frames in seconds

- max_formant:

  Maximum formant frequency (Hz)

- n_formants:

  Number of formants to detect per frame

- window_length:

  Analysis window length in seconds

- pre_emphasis_from:

  Pre-emphasis frequency in Hz

## Value

A data.table with columns `time`, `formant_number`, `frequency`,
`bandwidth` (one row per formant per frame)

## Examples

``` r
set.seed(1)
signal <- sin(2 * pi * 500 * seq(0, 0.5, by = 1 / 16000)) + rnorm(8001, sd = 0.01)
pladdrr:::.detect_formants_burg(signal, sr = 16000, time_step = 0.05,
                                 max_formant = 5500, n_formants = 4,
                                 window_length = 0.025, pre_emphasis_from = 50)
#> Key: <time, formant_number>
#>       time formant_number frequency bandwidth
#>      <num>          <int>     <num>     <num>
#>  1: 0.0125              1  2211.818  486.7134
#>  2: 0.0125              2        NA        NA
#>  3: 0.0125              3        NA        NA
#>  4: 0.0125              4        NA        NA
#>  5: 0.0625              1  2153.933  106.2282
#>  6: 0.0625              2        NA        NA
#>  7: 0.0625              3        NA        NA
#>  8: 0.0625              4        NA        NA
#>  9: 0.1125              1  2220.223  241.3457
#> 10: 0.1125              2        NA        NA
#> 11: 0.1125              3        NA        NA
#> 12: 0.1125              4        NA        NA
#> 13: 0.1625              1  2210.866  250.0558
#> 14: 0.1625              2        NA        NA
#> 15: 0.1625              3        NA        NA
#> 16: 0.1625              4        NA        NA
#> 17: 0.2125              1  2102.724  321.6366
#> 18: 0.2125              2        NA        NA
#> 19: 0.2125              3        NA        NA
#> 20: 0.2125              4        NA        NA
#> 21: 0.2625              1  2204.854  146.3130
#> 22: 0.2625              2        NA        NA
#> 23: 0.2625              3        NA        NA
#> 24: 0.2625              4        NA        NA
#> 25: 0.3125              1        NA        NA
#> 26: 0.3125              2        NA        NA
#> 27: 0.3125              3        NA        NA
#> 28: 0.3125              4        NA        NA
#> 29: 0.3625              1  2135.871  172.2408
#> 30: 0.3625              2        NA        NA
#> 31: 0.3625              3        NA        NA
#> 32: 0.3625              4        NA        NA
#> 33: 0.4125              1  2174.923  297.1457
#> 34: 0.4125              2        NA        NA
#> 35: 0.4125              3        NA        NA
#> 36: 0.4125              4        NA        NA
#> 37: 0.4625              1        NA        NA
#> 38: 0.4625              2        NA        NA
#> 39: 0.4625              3        NA        NA
#> 40: 0.4625              4        NA        NA
#>       time formant_number frequency bandwidth
#>      <num>          <int>     <num>     <num>
```
