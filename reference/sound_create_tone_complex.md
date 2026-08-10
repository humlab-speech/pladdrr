# Create a tone complex (harmonic series)

Creates a sound consisting of multiple sinusoids at equal frequency
intervals.

## Usage

``` r
sound_create_tone_complex(
  frequency_step = 100,
  duration = 1,
  sampling_rate = 44100,
  phase = c("sine", "cosine"),
  first_frequency = 0,
  ceiling = 0,
  number_of_components = 0L
)
```

## Arguments

- frequency_step:

  Step between harmonics in Hz (default: 100)

- duration:

  Duration in seconds (default: 1.0)

- sampling_rate:

  Sampling rate in Hz (default: 44100)

- phase:

  Phase type: "sine" or "cosine" (default: "sine")

- first_frequency:

  Lowest component frequency in Hz (default: 0, uses frequency_step)

- ceiling:

  Maximum frequency to include in Hz (default: Nyquist)

- number_of_components:

  Number of components (default: 0 = all up to ceiling)

## Value

A Sound object

## Examples

``` r
# Harmonic tone with 10 components at 100 Hz intervals
tone <- sound_create_tone_complex(frequency_step = 100, number_of_components = 10)
tone <- Sound$create_tone_complex(frequency_step = 200, phase = "cosine")
```
