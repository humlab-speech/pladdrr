# Create DTW from two Sound objects

Aligns a candidate sound to a reference sound using MFCC-based dynamic
time warping.

## Usage

``` r
sounds_to_dtw(
  reference,
  candidate,
  analysis_width = 0.015,
  time_step = 0.005,
  band = 0,
  slope = 3
)
```

## Arguments

- reference:

  Reference sound (prototype, y-axis)

- candidate:

  Candidate sound (test, x-axis)

- analysis_width:

  Window length in seconds (default: 0.015)

- time_step:

  Time step between frames (default: 0.005)

- band:

  Sakoe-Chiba band width in seconds (0 = no constraint)

- slope:

  Slope constraint: 1=none, 2=1/3-3, 3=1/2-2, 4=2/3-3/2

## Value

A DTW object

## Examples

``` r
ref <- Sound$create_tone(frequency = 200, duration = 0.3, sampling_rate =
 16000)
test <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate =
 16000)
dtw <- sounds_to_dtw(ref, test)
print(dtw$get_weighted_distance())
#> [1] 93.25283
```
