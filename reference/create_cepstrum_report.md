# Create Cepstrum Report Plot

Creates a multi-panel diagnostic plot combining power cepstrum,
cepstrogram, and CPP time series for comprehensive analysis.

## Usage

``` r
create_cepstrum_report(
  cepstrogram,
  time_slice = NULL,
  save_path = NULL,
  format = c("png", "pdf", "svg"),
  dpi = 300
)
```

## Arguments

- cepstrogram:

  PowerCepstrogram object

- time_slice:

  Numeric. Time point for extracting single cepstrum (default: middle)

- save_path:

  Character. Path to save plot (optional)

- format:

  Character. Output format: "png", "pdf", "svg" (default: "png")

- dpi:

  Numeric. Resolution for raster formats (default: 300)

## Value

A combined plot object (invisibly)

## Examples

``` r
if (requireNamespace("gridExtra", quietly = TRUE)) {
  sound <- Sound$create_tone(frequency = 150, duration = 0.6, sampling_rate = 16000)
  cepstrogram <- sound$to_powercepstrogram(pitch_floor = 60)

  # Create comprehensive report at t = 0.3s (mid-signal)
  create_cepstrum_report(cepstrogram, time_slice = 0.3)
}
#> Warning: Could not compute peak: unused arguments (qmin = 0.001, qmax = 0)

```
