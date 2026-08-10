# Format Audio Quality Report

Creates a human-readable text report from audio quality metrics.

## Usage

``` r
format_quality_report(quality_metrics, detailed = TRUE)
```

## Arguments

- quality_metrics:

  Output from check_audio_quality()

- detailed:

  Include detailed metrics (default TRUE)

## Value

Character string with formatted report

## Examples

``` r
# \donttest{
sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate = 16000)
quality <- check_audio_quality(sound)
report <- format_quality_report(quality)
cat(report)
#> === Audio Quality Report ===
#> Overall Status: FAIR
#> 
#> Issues:
#>   - Low dynamic range
#> 
#> Basic Properties:
#>   Duration: 0.50 seconds
#>   Sampling Rate: 16000 Hz
#> 
#> Amplitude Metrics:
#>   Max Amplitude: 0.990
#>   RMS Amplitude: 0.700
#>   Clipping: NO
#> 
#> Intensity Metrics:
#>   Mean: 90.9 dB
#>   Range: 0.0 dB
#>   Min: 90.9 dB
#>   Max: 90.9 dB
#> 
#> Recommendations:
#> ============================
# }
```
