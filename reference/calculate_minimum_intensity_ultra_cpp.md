# Calculate minimum intensity in voiced regions (Tier 4 Ultra)

DSI-compliant intensity pipeline: Sound -\> Pitch -\> PointProcess -\>
TextGrid (VUV) -\> Extract voiced intervals -\> Concatenate -\>
Intensity -\> Minimum. Matches Praat DSI script algorithm.

## Usage

``` r
calculate_minimum_intensity_ultra_cpp(
  sound_xptr,
  min_pitch,
  max_pitch,
  time_step,
  subtract_mean
)
```

## Arguments

- sound_xptr:

  External pointer to Sound object

- min_pitch:

  Pitch floor (Hz) for pitch extraction

- max_pitch:

  Pitch ceiling (Hz) for pitch extraction

- time_step:

  Time step for analysis

- subtract_mean:

  Whether to subtract mean for intensity calculation

## Value

Minimum intensity in dB (from concatenated voiced regions)

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 1, sampling_rate = 16000)
pladdrr:::calculate_minimum_intensity_ultra_cpp(sound$.xptr, 75, 600, 0, TRUE)
#> [1] 90.8818
```
