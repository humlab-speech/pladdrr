# Pitch Object

Fundamental frequency (F0) contour representation. Created from a Sound
via autocorrelation or cross-correlation pitch tracking. Supports
multiple unit systems: hertz, semitones (re 1 Hz, 100 Hz, or custom),
mel, and erb.

## Arguments

- .xptr:

  External pointer to C++ Pitch object (internal use)

## Value

Pitch object with methods for querying pitch values and statistics

## Methods

\*\*Information:\*\* \* \`get_number_of_frames()\` — Number of analysis
frames \* \`get_time_step()\` — Time step between frames (s) \*
\`count_voiced_frames()\` — Number of frames with voiced (non-zero)
pitch

\*\*Point queries:\*\* \* \`get_value_at_time(time, unit, interpolate)\`
— F0 at time point \* \`get_values_at_times(times, unit, interpolate)\`
— F0 at vector of times (batch) \* \`get_strength_at_time(time)\` —
Strength (voicing likelihood) at time \*
\`get_strengths_at_times(times)\` — Strengths at vector of times (batch)

\*\*Statistics (over time range):\*\* \* \`get_mean(from_time, to_time,
unit)\` — Mean F0 \* \`get_standard_deviation(from_time, to_time,
unit)\` — Standard deviation \* \`get_minimum(from_time, to_time, unit,
interpolate)\` — Minimum F0 \* \`get_maximum(from_time, to_time, unit,
interpolate)\` — Maximum F0 \* \`get_quantile(quantile, from_time,
to_time, unit)\` — Quantile of F0 \* \`get_time_of_minimum(...)\` /
\`get_time_of_maximum(...)\` — Time of extremum

\*\*Export:\*\* \* \`as_vector()\` / \`as_data_frame()\` — Export as
vector or data.frame \* \`get_times_vector()\` — Frame time points \*
\`as_matrix()\` — F0 values as matrix (frames × candidates)

\*\*Transform:\*\* \* \`to_point_process(voicing_threshold, octave_cost,
...)\` — Convert to PointProcess (glottal pulses) \*
\`down_to_pitch_tier()\` — Convert to PitchTier (editable pitch contour)

## Units

F0 unit codes: \`"hertz"\` (0), \`"semitones re 1 Hz"\` (1),
\`"semitones re 100 Hz"\` (2), \`"semitones re 200 Hz"\` (3),
\`"semitones re 440 Hz"\` (4), \`"mel"\` (5), \`"log hertz"\` (6),
\`"erb"\` (7). Default is \`"hertz"\`.

## See also

[`Sound`](https://humlab-speech.github.io/pladdrr/reference/Sound.md),
[`PointProcess`](https://humlab-speech.github.io/pladdrr/reference/PointProcess.md),
[`PitchTier`](https://humlab-speech.github.io/pladdrr/reference/PitchTier.md)

## Examples

``` r
sound <- Sound$create_tone(duration = 1.0, frequency = 200, sampling_rate = 44100)
pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")
min_f0 <- pitch$get_minimum(from_time = 0, to_time = 0, unit = "hertz")
df <- as.data.frame(pitch)
if (FALSE) { # \dontrun{
sound <- Sound("voice.wav")
pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
n_voiced <- pitch$count_voiced_frames()
} # }
```
