# DTW

Temporal alignment between two acoustic signals.

## Usage

``` r
DTW(.xptr = NULL)
```

## Arguments

- .xptr:

  Not for direct use. External pointer to the underlying C++ DTW object;
  set internally when wrapping an existing alignment.

## Value

A DTW object wrapping the alignment path and distance matrix.

## Details

DTW aligns a candidate signal (x-axis) to a prototype or reference
(y-axis), computing an optimal path through a distance matrix that
minimizes the total distance while respecting slope constraints.

## Creating DTW objects

DTW objects are created by aligning two acoustic objects:

- `sounds_to_dtw(reference, candidate)` - align two sounds (most common)

- `mfccs_to_dtw(mfcc1, mfcc2)` - align MFCCs (speech recognition)

- `spectrograms_to_dtw(spec1, spec2)` - align spectrograms

- `pitches_to_dtw(pitch1, pitch2)` - align pitch contours

## Time mapping

- `$get_y_time_from_x_time(tx)` - map candidate time to reference time

- `$get_x_time_from_y_time(ty)` - map reference time to candidate time

- `$map_times(times, direction)` - vectorized time mapping

## TextGrid warping

- `$warp_textgrid(textgrid)` - warp annotation times

## Path analysis

- `$get_weighted_distance()` - global alignment distance

- `$get_path_length()` - number of cells in optimal path

- `$get_path()` - full path as a data.frame

- `$get_maximum_consecutive_steps("x"|"y")` - path regularity

## Slope constraints

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
