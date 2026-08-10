# Create Sound from numeric values

Factory function to create a Sound object from a numeric vector or
matrix. Use \`Sound\$from_values()\` for backward compatibility (calls
this function).

## Usage

``` r
sound_from_values(values, sampling_rate = 44100, start_time = 0)
```

## Arguments

- values:

  Numeric matrix with channels as rows, samples as columns (or vector
  for mono)

- sampling_rate:

  Sampling rate in Hz (default: 44100)

- start_time:

  Start time of the sound in seconds (default: 0.0)

## Value

A Sound object

## Examples

``` r
# Create from vector (mono)
values <- sin(2 * pi * 440 * seq(0, 1, length.out = 4410))
sound <- sound_from_values(values, 4410)

# Or using Sound$from_values() (same thing)
sound <- Sound$from_values(values, 4410)
```
