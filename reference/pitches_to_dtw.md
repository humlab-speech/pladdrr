# Create DTW from two Pitch objects

Create DTW from two Pitch objects

## Usage

``` r
pitches_to_dtw(
  pitch1,
  pitch2,
  vuv_costs = 24,
  time_weight = 10,
  match_start = TRUE,
  match_end = TRUE,
  slope = 1
)
```

## Arguments

- pitch1:

  First pitch contour (candidate)

- pitch2:

  Second pitch contour (reference)

- vuv_costs:

  Cost for voiced-unvoiced mismatches (default: 24)

- time_weight:

  Weight for temporal distance (default: 10)

- match_start:

  Force path to start at (1,1)

- match_end:

  Force path to end at (nx,ny)

- slope:

  Slope constraint (1-4)

## Value

A DTW object

## Examples

``` r
sound1 <- Sound$create_tone(frequency = 220, duration = 0.5)
sound2 <- Sound$create_tone(frequency = 440, duration = 0.5)
pitch1 <- sound1$to_pitch()
pitch2 <- sound2$to_pitch()
dtw <- pitches_to_dtw(pitch1, pitch2)
```
