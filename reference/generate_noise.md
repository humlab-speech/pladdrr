# Generate white noise

Creates a praat_sound object containing white noise (random values from
a normal distribution). Optionally specify a seed for reproducible
noise.

## Usage

``` r
generate_noise(duration, sampling_rate = 44100, amplitude = 1, seed = NULL)
```

## Arguments

- duration:

  Duration in seconds (must be positive)

- sampling_rate:

  Sampling rate in Hz (default: 44100)

- amplitude:

  Amplitude scaling factor (default: 1.0, must be positive). Controls
  the standard deviation of the noise.

- seed:

  Optional random seed for reproducible noise generation. If NULL
  (default), noise will be different each time.

## Value

A praat_sound object containing white noise

## Details

White noise is generated using
[`rnorm()`](https://rdrr.io/r/stats/Normal.html) with mean 0 and
standard deviation controlled by the amplitude parameter. For
reproducible results, specify a seed value.

## Examples

``` r
# Generate 1 second of random noise
noise <- generate_noise(1.0)

# Generate reproducible noise
noise1 <- generate_noise(0.5, seed = 42)
noise2 <- generate_noise(0.5, seed = 42)
identical(noise1$values, noise2$values)  # TRUE
#> [1] TRUE

# Generate quieter noise
quiet_noise <- generate_noise(1.0, amplitude = 0.1)
```
