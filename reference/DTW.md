# Dynamic Time Warping Object

Temporal alignment between two acoustic signals.

DTW aligns a candidate signal (x-axis) to a prototype/reference
(y-axis), computing an optimal path through a distance matrix that
minimizes the total distance while respecting slope constraints.

## Usage

``` r
DTW(.xptr = NULL)
```

## Arguments

- .xptr:

  Internal external pointer to wrap an existing DTW object; not for
  direct use.

## Value

An object of class `DTW` wrapping the alignment path and distance matrix
(list with methods; dispatched via the shared `PraatObject` pattern).

## Creating DTW Objects

DTW objects are created by aligning two acoustic objects:

- `sounds_to_dtw(reference, candidate)` - Align two sounds (most common)

- `mfccs_to_dtw(mfcc1, mfcc2)` - Align MFCCs (speech recognition)

- `spectrograms_to_dtw(spec1, spec2)` - Align spectrograms

- `pitches_to_dtw(pitch1, pitch2)` - Align pitch contours

## Time Mapping (Core Use Case)

- `$get_y_time_from_x_time(tx)` - Map candidate time to reference time

- `$get_x_time_from_y_time(ty)` - Map reference time to candidate time

- `$map_times(times, direction)` - Vectorized time mapping

## TextGrid Warping (Major Use Case)

- `$warp_textgrid(textgrid)` - Warp annotation times

## Path Analysis

- `$get_weighted_distance()` - Global alignment distance

- `$get_path_length()` - Number of cells in optimal path

- `$get_path()` - Full path as data.frame

- `$get_maximum_consecutive_steps("x"|"y")` - Path regularity

## Slope Constraints

Controls path flexibility:

- 1: No constraint (any slope)

- 2: 1/3 \< slope \< 3

- 3: 1/2 \< slope \< 2 (recommended)

- 4: 2/3 \< slope \< 3/2 (strict)

## See also

[`Sound`](https://humlab-speech.github.io/pladdrr/reference/Sound.md),
[`Pitch`](https://humlab-speech.github.io/pladdrr/reference/Pitch.md),
[`Spectrogram`](https://humlab-speech.github.io/pladdrr/reference/Spectrogram.md),
[`MFCC`](https://humlab-speech.github.io/pladdrr/reference/MFCC.md)

## Examples

``` r
# Basic alignment workflow
reference <- Sound$create_tone(frequency = 150, duration = 0.3)
candidate <- Sound$create_tone(frequency = 160, duration = 0.3)

# Create DTW alignment
dtw <- sounds_to_dtw(reference, candidate,
  analysis_width = 0.015,
  time_step = 0.005,
  band = 0.0,
  slope = 3
)

# Check alignment quality
cat("Distance:", dtw$get_weighted_distance(), "\n")
#> Distance: 115.0691 

# Map time point from candidate to reference
ref_time <- dtw$get_y_time_from_x_time(0.1)
```
