# Create a pure tone with fade in/out

Creates a sinusoidal pure tone with optional fade in/out envelopes.

## Usage

``` r
sound_create_pure_tone(
  frequency = 440,
  duration = 1,
  sampling_rate = 44100,
  amplitude = 0.99,
  fade_in_duration = 0.01,
  fade_out_duration = 0.01,
  channels = 1L
)
```

## Arguments

- frequency:

  Frequency in Hz (default: 440)

- duration:

  Duration in seconds (default: 1.0)

- sampling_rate:

  Sampling rate in Hz (default: 44100)

- amplitude:

  Peak amplitude (default: 0.99)

- fade_in_duration:

  Fade-in duration in seconds (default: 0.01)

- fade_out_duration:

  Fade-out duration in seconds (default: 0.01)

- channels:

  Number of channels (default: 1)

## Value

A Sound object

## Examples

``` r
tone <- sound_create_pure_tone(frequency = 440, duration = 0.5)
tone <- Sound$create_pure_tone(frequency = 880, fade_in_duration = 0.05)
```
