# Formant Class

Formant objects represent vocal tract resonance frequencies over time.
Created from a Sound via formant tracking algorithms (Burg,
Split-Levinson, or Willems). Formant frequencies and bandwidths are the
primary acoustic correlates of vowel quality in speech.

## Value

A `Formant` object with methods for querying formant frequencies and
bandwidths at time points or across the full contour.

## Methods

\*\*Information:\*\* \* \`get_number_of_frames()\` — Number of analysis
frames \* \`get_time_step()\` — Time step between frames (s) \*
\`get_min_num_formants()\` / \`get_max_num_formants()\` — Formant count
range per frame

\*\*Point queries (single time):\*\* \*
\`get_value_at_time(formant_number, time, unit)\` — Formant frequency at
time \* \`get_bandwidth_at_time(formant_number, time, unit)\` — Formant
bandwidth at time \* \`get_all_values_at_time(time, max_formants,
unit)\` — All formant values at time point

\*\*Statistics (over time range):\*\* \* \`get_mean(formant_number,
from_time, to_time, unit)\` — Mean formant frequency \*
\`get_standard_deviation(formant_number, from_time, to_time, unit)\` —
SD \* \`get_minimum(formant_number, from_time, to_time, unit)\` —
Minimum value \* \`get_maximum(formant_number, from_time, to_time,
unit)\` — Maximum value \* \`get_quantile(formant_number, quantile,
from_time, to_time, unit)\` — Quantile \* \`get_time_of_minimum(...)\` /
\`get_time_of_maximum(...)\` — Time of extremum

\*\*Batch / vectorized:\*\* \* \`get_formant_track(formant_number,
unit)\` — Full track for one formant \*
\`get_bandwidth_track(formant_number, unit)\` — Full bandwidth track \*
\`get_values_at_times(formant_number, times, unit)\` — Values at
arbitrary vector of times \* \`get_all_formant_tracks(max_formants,
unit)\` — All formants as matrix

\*\*Export:\*\* \* \`as_data_frame(max_formants)\` — Export as
data.frame, long format: one row per (frame, formant number), columns
\`time\`, \`formant\`, \`frequency\` (Hz), \`bandwidth\` (Hz). Matches
\`FormantPath\$as_data_frame()\`. \* \`save(filepath)\` — Save to Praat
binary file

\*\*Transform:\*\* \* \`to_formant_tier(formant_number)\` — Extract one
formant as FormantTier \* \`to_formant_modeler()\` — Create polynomial
trajectory model \* \`down_to_formant_tier()\` — Extract all formants as
FormantTier

## See also

[`Sound`](https://humlab-speech.github.io/pladdrr/reference/Sound.md),
[`LPC`](https://humlab-speech.github.io/pladdrr/reference/LPC.md),
[`FormantPath`](https://humlab-speech.github.io/pladdrr/reference/FormantPath.md),
[`FormantModeler`](https://humlab-speech.github.io/pladdrr/reference/FormantModeler.md)

## Examples

``` r
# Self-contained example with generated tone
sound <- Sound$create_tone(duration = 1.0, frequency = 150, sampling_rate = 44100)
formant <- sound$to_formant_burg(
  time_step = 0.01, max_number_of_formants = 5,
  maximum_formant = 5500, window_length = 0.025, pre_emphasis_from = 50
)
f1 <- formant$get_value_at_time(formant_number = 1, time = 0.5, unit = "hertz")
if (FALSE) { # \dontrun{
# Example with external file
sound <- Sound("example.wav")
formant <- sound$to_formant_burg(
  time_step = 0.01, max_number_of_formants = 5,
  maximum_formant = 5500, window_length = 0.025, pre_emphasis_from = 50
)
f1_at_1s <- formant$get_value_at_time(formant_number = 1, time = 1.0, unit = "hertz")
mean_f1 <- formant$get_mean(formant_number = 1, from_time = 0, to_time = 0, unit = "hertz")
} # }
```
