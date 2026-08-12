# Praat Harmonicity Object

A Harmonicity object represents the degree of acoustic periodicity — the
Harmonics-to-Noise Ratio (HNR) — in a sound over time, measured in
decibels. Created from a Sound via cross-correlation (CC) or
glottal-to-noise excitation (GNE) analysis. Higher values indicate more
periodic (voiced) speech.

## Value

A `Harmonicity` object with methods for harmonics-to-noise ratio (HNR)
analysis.

## Methods

\*\*Information:\*\* \* \`get_start_time()\` / \`get_end_time()\` — Time
range (s) \* \`get_sampling_period()\` — Time step between frames (s) \*
\`get_number_of_frames()\` — Number of analysis frames \*
\`get_time_from_frame(frame)\` — Time for frame index \*
\`get_frame_from_time(time)\` — Frame index for time

\*\*Point queries:\*\* \* \`get_value_at_time(time, interpolation)\` —
HNR at time point (dB) \* \`get_values_at_times(times, interpolation)\`
— HNR at vector of times (batch) \* \`get_values_vector()\` — Raw HNR
values for all frames \* \`get_times_vector()\` — Frame time points

\*\*Statistics (over time range):\*\* \* \`get_mean(from_time,
to_time)\` — Mean HNR (dB) \* \`get_minimum(from_time, to_time,
interpolation)\` — Minimum HNR \* \`get_maximum(from_time, to_time,
interpolation)\` — Maximum HNR \* \`get_standard_deviation(from_time,
to_time)\` — Standard deviation \* \`get_time_of_minimum(...)\` /
\`get_time_of_maximum(...)\` — Time of extremum

\*\*Batch:\*\* \* \`get_statistics_batch(from_times, to_times)\` —
Statistics for multiple intervals (single C++ call)

\*\*Export:\*\* \* \`as_data_frame()\` / \`as_matrix()\` — Export as
data.frame or matrix

## See also

[`Sound`](https://humlab-speech.github.io/pladdrr/reference/Sound.md),
[`Pitch`](https://humlab-speech.github.io/pladdrr/reference/Pitch.md),
[`PointProcess`](https://humlab-speech.github.io/pladdrr/reference/PointProcess.md)

## Examples

``` r
sound <- Sound$create_tone(duration = 1.0, frequency = 200, sampling_rate = 44100)
hnr <- sound$to_harmonicity_cc(time_step = 0.01, min_pitch = 75)
mean_hnr <- hnr$get_mean()
hnr_at_05 <- hnr$get_value_at_time(0.5)

# The same analysis on a recording read from disk
sound <- Sound(system.file("extdata", "test.wav", package = "pladdrr"))
hnr <- sound$to_harmonicity_ac(time_step = 0.01, min_pitch = 75)
df <- hnr$as_data_frame()
```
