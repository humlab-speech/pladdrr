# Generate a sine wave

Creates a praat_sound object containing a pure sine wave at a specified
frequency. Useful for testing and creating reference signals.

## Usage

``` r
generate_sine_wave(frequency, duration, sampling_rate = 44100, amplitude = 1)
```

## Arguments

- frequency:

  Frequency in Hz (must be positive)

- duration:

  Duration in seconds (must be positive)

- sampling_rate:

  Sampling rate in Hz (default: 44100)

- amplitude:

  Peak amplitude (default: 1.0, must be positive)

## Value

A praat_sound object containing the sine wave

## Details

The generated sine wave follows the formula:
`amplitude * sin(2 * pi * frequency * t)` where t is time. The wave
starts at phase 0 (value 0 at t=0).

## Examples

``` r
# Generate A4 note (440 Hz) for 1 second
sine_a4 <- generate_sine_wave(440, 1.0)
#> Warning: create_sound() is deprecated and will be removed in v5.0.0. Use Sound$from_values(values, sampling_rate) instead. The R6 interface provides better performance and more features.

# Generate lower amplitude sine at 1000 Hz
sine_quiet <- generate_sine_wave(1000, 0.5, amplitude = 0.3)
#> Warning: create_sound() is deprecated and will be removed in v5.0.0. Use Sound$from_values(values, sampling_rate) instead. The R6 interface provides better performance and more features.
```
