# Create Spectrogram from Sound Directly (returns XPtr)

Create Spectrogram from Sound Directly (returns XPtr)

## Usage

``` r
to_spectrogram_direct(
  sound,
  window_length = 0.005,
  max_frequency = 5000,
  time_step = 0.002,
  frequency_step = 20,
  window_shape = "Gaussian"
)
```

## Arguments

- sound:

  Sound object or external pointer

- window_length:

  Numeric. Window length in seconds (default: 0.005)

- max_frequency:

  Numeric. Maximum frequency in Hz (default: 5000)

- time_step:

  Numeric. Time step in seconds (default: 0.002)

- frequency_step:

  Numeric. Frequency step in Hz (default: 20)

- window_shape:

  Character. Window shape (default: "Gaussian")

## Value

External pointer to Spectrogram

## Examples

``` r
sound <- Sound$create_tone(frequency = 200, duration = 0.5)
spg_ptr <- to_spectrogram_direct(sound, window_length = 0.005)
spg <- Spectrogram(.xptr = spg_ptr)
spg$get_number_of_time_bins()
#> [1] 246
```
