# Extract Multiple Parts from a Sound

Extracts multiple time intervals from a Sound object and returns them as
a list of Sound objects. Useful for extracting voiced segments
identified by voice activity detection.

## Usage

``` r
sound_extract_parts(
  sound,
  start_times,
  end_times,
  window_shape = "rectangular",
  relative_width = 1,
  preserve_times = FALSE,
  return_r6 = TRUE
)
```

## Arguments

- sound:

  Sound object

- start_times:

  Numeric vector of interval start times (seconds)

- end_times:

  Numeric vector of interval end times (seconds)

- window_shape:

  Character. Window shape for extraction (default: "rectangular"). See
  details for all options.

- relative_width:

  Numeric. Relative width of window (default: 1.0). For
  gaussian2/kaiser2, use 2.0. For gaussian3-5, use 3.0-5.0 respectively.

- preserve_times:

  Logical. Preserve original time stamps (default: FALSE)

- return_r6:

  Logical. Return R6 Sound objects (TRUE) or raw xptrs (FALSE). Using
  FALSE skips R6 wrapper construction.

## Value

List of Sound objects, one for each extracted interval

## Details

This function is vectorized to extract multiple intervals efficiently.
Each extracted sound can then be concatenated or analyzed separately.

Available window shapes (see Praat manual for details): - "rectangular"
(default) - No tapering - "triangular" - Triangular (Bartlett) taper -
"parabolic" - Parabolic (Welch) taper - "hanning" - Hanning window -
"hamming" - Hamming window - "gaussian1" - Gaussian window
(sd=0.42466) - "gaussian2" - Narrower Gaussian (sd=0.21233), use
relative_width=2.0 - "gaussian3" - Even narrower (sd=0.14155), use
relative_width=3.0 - "gaussian4" - Very narrow (sd=0.10616), use
relative_width=4.0 - "gaussian5" - Extremely narrow (sd=0.08493), use
relative_width=5.0 - "kaiser1" - Kaiser-Bessel window (alpha=20.7) -
"kaiser2" - Narrower Kaiser-Bessel (alpha=40.5), use relative_width=2.0

## References

Praat documentation:
<https://www.fon.hum.uva.nl/praat/manual/Sound__Extract_part___.html>

## Examples

``` r
sound <- sounds_append(
  Sound$create_tone(frequency = 200, duration = 0.5, amplitude = 0.8),
  Sound$create_tone(frequency = 200, duration = 0.3, amplitude = 0.001)
)
vad_grid <- sound_to_textgrid_silences(sound)
voiced_intervals <- textgrid_get_intervals_where(vad_grid, 1, "equals", "sounding")

voiced_sounds <- sound_extract_parts(
  sound,
  voiced_intervals$xmin,
  voiced_intervals$xmax
)

# Analyze each segment separately
for (i in seq_along(voiced_sounds)) {
  cat("Segment", i, "duration:", voiced_sounds[[i]]$get_total_duration(), "s\n")
}
#> Segment 1 duration: 0.52 s
```
