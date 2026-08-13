# Create PointProcess from Sound and Pitch (Cross-Correlation)

Creates a PointProcess using BOTH Sound and refined Pitch contour. This
matches Praat's "To PointProcess (cc)" command when both Sound and Pitch
objects are selected.

\*\*IMPORTANT for VUV Analysis:\*\* This function uses the refined pitch
contour to guide period detection, which is more accurate than using
pitch range parameters alone. This is the correct method for voice
quality analysis (jitter, shimmer, VUV detection).

\*\*Algorithm Difference:\*\* -
\`sound\$to_point_process_periodic_cc(floor, ceiling)\` - Uses only
pitch range - \`to_point_process_from_sound_and_pitch(sound, pitch)\` -
Uses refined pitch contour (recommended)

## Usage

``` r
to_point_process_from_sound_and_pitch(sound, pitch)
```

## Arguments

- sound:

  Sound object or external pointer

- pitch:

  Pitch object or external pointer (from to_pitch_ac/cc)

## Value

External pointer to PointProcess

## See also

[`to_point_process_direct`](https://humlab-speech.github.io/pladdrr/reference/to_point_process_direct.md)
for the single-object Sound method

## Examples

``` r
sound <- Sound$create_tone(frequency = 200, duration = 0.5)

# Create refined pitch analysis
pitch <- sound$to_pitch_cc(
  time_step = 0,
  pitch_floor = 75,
  pitch_ceiling = 600,
  voicing_threshold = 0.45
)

# RECOMMENDED: Use both Sound and Pitch for accurate pulse detection
pp <- to_point_process_from_sound_and_pitch(sound, pitch)

# Now calculate jitter with accurate pulse times
pp_r6 <- PointProcess(.xptr = pp)
jitter <- pp_r6$get_jitter_local()
```
