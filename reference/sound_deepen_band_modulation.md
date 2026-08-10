# Deepen band modulation (hearing enhancement)

Deepen band modulation (hearing enhancement)

## Usage

``` r
sound_deepen_band_modulation(
  sound,
  enhancement_db = 10,
  flow = 300,
  fhigh = 4000,
  slow_modulation = 3,
  fast_modulation = 30,
  band_smoothing = 100
)
```

## Arguments

- sound:

  Sound object

- enhancement_db:

  Enhancement in dB

- flow:

  Low frequency bound (Hz)

- fhigh:

  High frequency bound (Hz)

- slow_modulation:

  Slow modulation frequency (Hz)

- fast_modulation:

  Fast modulation frequency (Hz)

- band_smoothing:

  Band smoothing (Hz)

## Value

New Sound object

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 1.0)
enhanced <- sound_deepen_band_modulation(sound, enhancement_db = 10)
```
