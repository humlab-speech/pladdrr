# Praat Intensity Object

Intensity objects represent sound power (loudness) over time, measured
in decibels (dB) relative to the auditory threshold. Created from a
Sound using intensity contour extraction.

## Value

An `Intensity` object with methods for querying intensity values (in dB)
at time points or across the full contour.

## Methods

\*\*Information:\*\* \* \`get_duration()\` — Duration of the intensity
contour (s) \* \`get_time_step()\` — Time step between frames (s)

\*\*Point queries:\*\* \* \`get_value_at_time(time, interpolation)\` —
Intensity at time point (dB) \* \`get_values_at_times(times,
interpolation)\` — Intensity at vector of times (batch)

\*\*Statistics (over time range):\*\* \* \`get_mean(from_time, to_time,
averaging_method)\` — Mean intensity (dB) \*
\`get_standard_deviation(from_time, to_time)\` — Standard deviation (dB)
\* \`get_minimum(from_time, to_time, interpolation)\` — Minimum
intensity \* \`get_maximum(from_time, to_time, interpolation)\` —
Maximum intensity \* \`get_quantile(quantile, from_time, to_time)\` —
Quantile \* \`get_time_of_minimum(...)\` / \`get_time_of_maximum(...)\`
— Time of extremum

\*\*Export:\*\* \* \`as_vector()\` — Raw intensity values (dB) \*
\`as_data_frame()\` — Export as data.frame (time, intensity) \*
\`save(filepath)\` — Save to Praat binary file

## Interpolation

Codes: \`"nearest"\` (0), \`"linear"\` (1), \`"cubic"\` (2, default),
\`"sinc70"\` (3), \`"sinc700"\` (4). Averaging methods: \`"energy"\` (0,
default), \`"sones"\` (1), \`"db"\` (2).

## See also

[`Sound`](https://humlab-speech.github.io/pladdrr/reference/Sound.md),
[`Pitch`](https://humlab-speech.github.io/pladdrr/reference/Pitch.md),
[`IntensityTier`](https://humlab-speech.github.io/pladdrr/reference/IntensityTier.md)

## Examples

``` r
sound <- Sound$create_tone(duration = 1.0, frequency = 200, sampling_rate = 44100)
intensity <- sound$to_intensity(minimum_pitch = 100, time_step = 0.0)
mean_int <- intensity$get_mean()
df <- intensity$as_data_frame()
if (FALSE) { # \dontrun{
sound <- Sound("recording.wav")
intensity <- sound$to_intensity(minimum_pitch = 100, time_step = 0.0)
int_at_1s <- intensity$get_value_at_time(1.0)
} # }
```
