# Calculate F0 statistic in single C++ call (Tier 4 Ultra)

Performs pitch extraction AND statistic calculation entirely in C++,
avoiding intermediate R6 object creation.

## Usage

``` r
calculate_f0_stats_ultra_cpp(
  sound_xptr,
  stat,
  time_step,
  min_pitch,
  max_pitch,
  voicing_threshold
)
```

## Arguments

- sound_xptr:

  External pointer to Sound object

- stat:

  Statistic to compute: "max", "min", "mean", "median", "sd"

- time_step:

  Time step for pitch extraction

- min_pitch:

  Pitch floor (Hz)

- max_pitch:

  Pitch ceiling (Hz)

- voicing_threshold:

  Voicing threshold (default 0.45)

## Value

Single double value of the requested statistic

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 1, sampling_rate = 16000)
pladdrr:::calculate_f0_stats_ultra_cpp(sound$.xptr, "mean", 0, 75, 600, 0.45)
#> [1] 150.0001
```
