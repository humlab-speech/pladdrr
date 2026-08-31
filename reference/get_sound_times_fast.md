# Get Sound Sample Times (Fast Computation)

Returns time values for each sample using a direct computation, instead
of \`sound\$get_sample_times()\`. Still allocates memory for the result.

## Usage

``` r
get_sound_times_fast(sound)
```

## Arguments

- sound:

  A Sound object

## Value

Numeric vector of sample times (in seconds)

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate =
 16000)
times <- get_sound_times_fast(sound)
```
