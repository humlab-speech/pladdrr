# PowerCepstrogram

A Praat PowerCepstrogram: a power cepstrum computed at every time frame
of a sound, forming a quefrency-by-time surface.

## Arguments

- .xptr:

  Not for direct use. External pointer to the underlying C++
  PowerCepstrogram object; set internally when a method returns a new
  PowerCepstrogram.

## Value

A `PowerCepstrogram` object.

## Details

It's the standard input for CPPS (cepstral peak prominence, smoothed), a
widely used measure of voice quality: high CPPS means a strong, regular
harmonic structure, low CPPS means a noisy or aperiodic voice. Create
one with `sound$to_powercepstrogram()`, then either read `get_cpps()`
directly or slice out a single frame as a PowerCepstrum for closer
inspection.

## Usage


    cepstrogram <- sound$to_powercepstrogram(pitch_floor = 60)

## Query methods

- `get_cpp_at_time(time, interpolation, qmin, qmax, fit_method, tolerance)` -
  cepstral peak prominence at a single time

- `get_mean_cpp(from_time, to_time, qmin, qmax, fit_method, tolerance)` -
  mean cepstral peak prominence over a time range

- `get_cpps(subtract_tilt, time_averaging_window, quefrency_averaging_window, pitch_floor, pitch_ceiling, delta_f0, interpolation, qstart_fit, qend_fit, trend_type, fit_method)` -
  CPPS, smoothed over time and quefrency

## Transformation and export

- `get_power_cepstrum_at_time(time)` - single frame as a PowerCepstrum
  object

- `smooth(time_averaging_window, quefrency_averaging_window)` - smoothed
  copy as a new PowerCepstrogram

- `to_matrix()` - values as a Matrix object

- `as_matrix()` - values as a plain numeric matrix (quefrency x time)

## See also

\[PowerCepstrum\], \[Sound\], \[get_cpps_fast\]

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.3)
cepstrogram <- sound$to_powercepstrogram(pitch_floor = 60)
mean_cpp <- cepstrogram$get_mean_cpp()
```
