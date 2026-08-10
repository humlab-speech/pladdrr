# Create DTW from two Spectrogram objects

Create DTW from two Spectrogram objects

## Usage

``` r
spectrograms_to_dtw(
  spectrogram1,
  spectrogram2,
  match_start = TRUE,
  match_end = TRUE,
  slope = 1,
  metric = 2
)
```

## Arguments

- spectrogram1:

  First spectrogram (candidate)

- spectrogram2:

  Second spectrogram (reference)

- match_start:

  Force path to start at (1,1)

- match_end:

  Force path to end at (nx,ny)

- slope:

  Slope constraint (1-4)

- metric:

  Distance metric power (default: 2 = Euclidean)

## Value

A DTW object

## Examples

``` r
s1 <- Sound$create_tone(frequency = 200, duration = 0.3, sampling_rate = 16000)
s2 <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)
dtw <- spectrograms_to_dtw(s1$to_spectrogram(), s2$to_spectrogram())
```
