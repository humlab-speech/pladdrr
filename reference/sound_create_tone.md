# Create a pure tone Sound

Factory function to generate a pure sine wave tone. Use
\`Sound\$create_tone()\` for backward compatibility (calls this
function).

## Usage

``` r
sound_create_tone(
  duration = 1,
  sampling_rate = 44100,
  frequency = 440,
  amplitude = 0.99
)
```

## Arguments

- duration:

  Duration in seconds (default: 1.0)

- sampling_rate:

  Sampling rate in Hz (default: 44100)

- frequency:

  Frequency in Hz (default: 440)

- amplitude:

  Amplitude 0-1 (default: 0.99)

## Value

A Sound object

## Examples

``` r
# Create 440 Hz tone
sound <- sound_create_tone(frequency = 440, duration = 1.0)

# Or using Sound$create_tone() (same thing)
sound <- Sound$create_tone(frequency = 440, duration = 1.0)
```
