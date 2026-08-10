# Get voice quality metrics in single call (Tier 4 Ultra)

Complete voice quality pipeline in C++: Sound -\> Pitch -\> PointProcess
-\> Jitter/Shimmer/HNR. Returns selected metrics.

## Usage

``` r
get_voice_quality_ultra_cpp(
  sound_xptr,
  metrics,
  min_pitch,
  max_pitch,
  time_step,
  pitch_method,
  very_accurate
)
```

## Arguments

- sound_xptr:

  External pointer to Sound object

- metrics:

  Character vector of metrics: "jitter", "shimmer", "hnr", or "all"

- min_pitch:

  Pitch floor (Hz)

- max_pitch:

  Pitch ceiling (Hz)

- time_step:

  Time step for pitch extraction

- pitch_method:

  Pitch algorithm for jitter/shimmer pitch extraction: "cc" or "ac"

- very_accurate:

  Whether to use Praat's very accurate pitch path for jitter/shimmer

## Value

Named list with requested voice quality metrics

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
pladdrr:::get_voice_quality_ultra_cpp(
  sound$.xptr, "jitter", 75, 600, 0, "cc", TRUE
)
#> $jitter_local
#> [1] 1.512692e-07
#> 
#> $jitter_local_abs
#> [1] 1.008462e-09
#> 
#> $jitter_rap
#> [1] 8.72759e-08
#> 
#> $jitter_ppq5
#> [1] 1.05952e-07
#> 
#> $jitter_ddp
#> [1] 2.618277e-07
#> 
```
