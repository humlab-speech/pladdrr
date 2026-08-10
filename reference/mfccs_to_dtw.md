# Create DTW from two MFCC objects

Create DTW from two MFCC objects

## Usage

``` r
mfccs_to_dtw(
  mfcc1,
  mfcc2,
  coefficient_weight = 1,
  log_energy_weight = 0,
  coefficient_regression_weight = 0,
  log_energy_regression_weight = 0,
  regression_window_length = 0
)
```

## Arguments

- mfcc1:

  First MFCC object (candidate, x-axis)

- mfcc2:

  Second MFCC object (reference, y-axis)

- coefficient_weight:

  Weight for cepstral coefficients (default: 1.0)

- log_energy_weight:

  Weight for log energy (c0) (default: 0.0)

- coefficient_regression_weight:

  Weight for coefficient regression (default: 0.0)

- log_energy_regression_weight:

  Weight for energy regression (default: 0.0)

- regression_window_length:

  Window for regression calculation (default: 0.0)

## Value

A DTW object

## Examples

``` r
s1 <- Sound$create_tone(frequency = 200, duration = 0.3, sampling_rate = 16000)
s2 <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)
dtw <- mfccs_to_dtw(s1$to_mfcc(), s2$to_mfcc())
```
