# PowerCepstrum Class

A PowerCepstrum is the power spectrum of the log power spectrum — a
representation that separates the source (glottal pulse, low quefrency)
from the filter (vocal tract, high quefrency). Created from a Spectrum
or extracted from a PowerCepstrogram at a specific time. The primary
voice quality metric from this object is CPP (Cepstral Peak Prominence).

## Value

A `PowerCepstrum` object with methods for power cepstrum analysis
including CPP measurement.

## Methods

\*\*Information:\*\* \* \`get_qmin()\` / \`get_qmax()\` — Quefrency
range (s) \* \`get_quefrency_range()\` — Quefrency range as vector \*
\`get_n_bins()\` — Number of quefrency bins \* \`get_dq()\` — Quefrency
step (s) \* \`get_q1()\` — Starting quefrency value (s)

\*\*Peak analysis:\*\* \* \`get_peak_prominence(pitch_floor,
pitch_ceiling, ...)\` — CPP value (dB). Main voice quality metric. \*
\`get_peak_prominence_hillenbrand(pitch_floor, pitch_ceiling)\` — CPP
using Hillenbrand algorithm \* \`get_quefrency_of_peak(interpolation)\`
— Quefrency of cepstral peak (s) \* \`get_value_at_quefrency(quefrency,
interpolation, unit)\` — Cepstral amplitude at quefrency

\*\*Trend & smoothing:\*\* \* \`smooth(averaging_window)\` — Smooth the
cepstrum \* \`fit_trend_line(qmin, qmax, trend_type, fit_method)\` — Fit
regression trend line \* \`get_trend_line_value(quefrency, ...)\` —
Value of fitted trend at quefrency \* \`subtract_trend(qstart_fit,
qend_fit, ...)\` — Subtract regression trend (returns new PowerCepstrum)
\* \`subtract_trend_inplace(qstart_fit, qend_fit, ...)\` — Subtract
trend in-place (mutates)

\*\*Export / Transform:\*\* \* \`as_matrix()\` / \`as_data_frame()\` —
Export \* \`to_spectrum(random_phases)\` — Convert back to Spectrum \*
\`to_matrix()\` — Export as matrix

## See also

[`Spectrum`](https://humlab-speech.github.io/pladdrr/reference/Spectrum.md),
[`PowerCepstrogram`](https://humlab-speech.github.io/pladdrr/reference/PowerCepstrogram.md),
[`Sound`](https://humlab-speech.github.io/pladdrr/reference/Sound.md)

## Examples

``` r
sound <- Sound$create_tone(duration = 0.5, frequency = 200, sampling_rate = 44100)
spectrum <- sound$to_spectrum()
cepstrum <- spectrum$to_power_cepstrum()
cpp <- cepstrum$get_peak_prominence()

# The same analysis on a recording read from disk
wav <- system.file("extdata", "test.wav", package = "pladdrr")
cepstrum <- Sound(wav)$to_spectrum()$to_power_cepstrum()
```
