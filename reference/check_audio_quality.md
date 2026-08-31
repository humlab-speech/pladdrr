# Check Audio Quality Metrics

Analyzes a Sound object for common quality issues and returns diagnostic
metrics. This function provides basic quality control checks useful for
validating recording quality in production pipelines.

## Usage

``` r
check_audio_quality(
  sound,
  clipping_threshold = 0.99,
  intensity_floor = 100,
  time_step = 0
)
```

## Arguments

- sound:

  A Sound object to analyze

- clipping_threshold:

  Amplitude threshold for clipping detection (default 0.99)

- intensity_floor:

  Minimum pitch for intensity calculation (default 100 Hz)

- time_step:

  Time step for intensity analysis (0 = auto, default 0.0)

## Value

A list with the following components:

- max_amplitude:

  Maximum absolute amplitude in the recording

- is_clipped:

  Logical: TRUE if amplitude exceeds clipping_threshold

- n_clipping_samples:

  Number of samples above clipping threshold

- clipping_percentage:

  Percentage of samples that clip

- mean_intensity_db:

  Mean intensity in dB

- min_intensity_db:

  Minimum intensity in dB

- max_intensity_db:

  Maximum intensity in dB

- intensity_range_db:

  Dynamic range (max - min intensity)

- rms_amplitude:

  Root mean square amplitude

- duration:

  Total duration in seconds

- sampling_frequency:

  Sampling frequency in Hz

## Details

This function is designed to catch common recording problems:

\*\*Clipping Detection\*\*: Identifies if the signal exceeds a threshold
(default 0.99). Clipped recordings have distorted peaks and should
typically be re-recorded.

\*\*Intensity Analysis\*\*: Uses Praat's intensity measurement to assess
signal strength. Very low mean intensity may indicate recording level
problems.

\*\*Dynamic Range\*\*: The difference between maximum and minimum
intensity can help identify recordings with poor signal-to-noise ratio
or excessive compression.

\*\*Quality Criteria\*\* (general guidelines): - No clipping (is_clipped
= FALSE) - Mean intensity: -20 to -10 dB for speech - Dynamic range: \>
20 dB - Max amplitude: 0.7-0.9 range (good headroom without clipping)

## Examples

``` r
# \donttest{
sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate =
 16000)
quality <- check_audio_quality(sound)

cat("Audio Quality Report:\n")
#> Audio Quality Report:
cat("  Duration:", quality$duration, "seconds\n")
#>   Duration: 0.5 seconds
cat("  Sampling rate:", quality$sampling_frequency, "Hz\n")
#>   Sampling rate: 16000 Hz
cat("  Clipped:", quality$is_clipped, "\n")
#>   Clipped: FALSE 
cat("  Max amplitude:", round(quality$max_amplitude, 3), "\n")
#>   Max amplitude: 0.99 
cat("  Mean intensity:", round(quality$mean_intensity_db, 1), "dB\n")
#>   Mean intensity: 90.9 dB
cat("  Dynamic range:", round(quality$intensity_range_db, 1), "dB\n")
#>   Dynamic range: 0 dB
# }
```
