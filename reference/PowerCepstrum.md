# PowerCepstrum

A PowerCepstrum is the power spectrum of the log power spectrum, a
representation that separates the source (glottal pulse, low quefrency)
from the filter (vocal tract, high quefrency). Created from a Spectrum
or extracted from a PowerCepstrogram at a specific time. The primary
voice quality metric from this object is CPP (Cepstral Peak Prominence).

## Value

A PowerCepstrum object.

## Query methods

- `get_qmin()`, `get_qmax()` - quefrency range (s)

- `get_quefrency_range()` - quefrency range as a vector

- `get_n_bins()` - number of quefrency bins

- `get_dq()` - quefrency step (s)

- `get_q1()` - starting quefrency value (s)

## Peak analysis

- `get_peak_prominence(pitch_floor, pitch_ceiling, ...)` - CPP value
  (dB), the main voice quality metric

- `get_peak_prominence_hillenbrand(pitch_floor, pitch_ceiling)` - CPP
  using the Hillenbrand algorithm

- `get_quefrency_of_peak(interpolation)` - quefrency of the cepstral
  peak (s)

- `get_value_at_quefrency(quefrency, interpolation, unit)` - cepstral
  amplitude at a quefrency

## Trend and smoothing

- `smooth(averaging_window)` - smooth the cepstrum

- `fit_trend_line(qmin, qmax, trend_type, fit_method)` - fit a
  regression trend line

- `get_trend_line_value(quefrency, ...)` - value of the fitted trend at
  a quefrency

- `subtract_trend(qstart_fit, qend_fit, ...)` - subtract the regression
  trend (returns a new PowerCepstrum)

- `subtract_trend_inplace(qstart_fit, qend_fit, ...)` - subtract the
  trend in place (mutates)

## Export and transform

- `as_matrix()`, `as_data_frame()` - export

- `to_spectrum(random_phases)` - convert back to Spectrum

- `to_matrix()` - export as a matrix

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
