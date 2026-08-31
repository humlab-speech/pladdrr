# Get All Jitter and Shimmer Measures in One Call

Returns 11 voice quality measures (5 jitter, 6 shimmer) in a single C++
call, instead of calling individual methods separately for each measure.

\*\*Jitter measures\*\* (period perturbation): - \`jitter_local\`: Local
jitter (relative, fraction) - \`jitter_local_abs\`: Local absolute
jitter (seconds) - \`jitter_rap\`: Relative average perturbation -
\`jitter_ppq5\`: 5-point period perturbation quotient - \`jitter_ddp\`:
Difference of differences of periods

\*\*Shimmer measures\*\* (amplitude perturbation): - \`shimmer_local\`:
Local shimmer (relative, fraction) - \`shimmer_local_db\`: Local shimmer
(dB) - \`shimmer_apq3\`: 3-point amplitude perturbation quotient -
\`shimmer_apq5\`: 5-point amplitude perturbation quotient -
\`shimmer_apq11\`: 11-point amplitude perturbation quotient -
\`shimmer_dda\`: Difference of differences of amplitudes

## Usage

``` r
get_jitter_shimmer_batch(
  pointprocess,
  sound,
  from_time = 0,
  to_time = 0,
  period_floor = 1e-04,
  period_ceiling = 0.02,
  max_period_factor = 1.3,
  max_amplitude_factor = 1.6
)
```

## Arguments

- pointprocess:

  PointProcess object or external pointer (glottal pulses)

- sound:

  Sound object or external pointer (required for shimmer)

- from_time:

  Start time (0 = beginning)

- to_time:

  End time (0 = end)

- period_floor:

  Minimum period in seconds (default 0.0001 = 10000 Hz)

- period_ceiling:

  Maximum period in seconds (default 0.02 = 50 Hz)

- max_period_factor:

  Maximum period factor (default 1.3)

- max_amplitude_factor:

  Maximum amplitude factor (default 1.6)

## Value

Named list with 11 voice quality measures

## Performance

This function reduces R\<-\>C++ boundary crossings from 11 calls to 1
call.

## Workflow

For accurate voice quality analysis, use
\`to_point_process_from_sound_and_pitch()\` which uses the refined pitch
contour to guide period detection: “\`r \# Recommended workflow sound
\<- Sound("voice.wav") pitch \<- sound\$to_pitch_cc(voicing_threshold =
0.45) pp \<- to_point_process_from_sound_and_pitch(sound, pitch) metrics
\<- get_jitter_shimmer_batch(pp, sound) “\`

## See also

\[two_pass_adaptive_pitch()\] for robust pitch extraction
\[to_point_process_from_sound_and_pitch()\] for accurate pulse detection

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate =
 16000)
pp <- sound$to_point_process_periodic_cc(75, 600)

# Get all voice quality measures at once
metrics <- get_jitter_shimmer_batch(pp, sound)

# Access individual measures
cat("Jitter (local):", metrics$jitter_local * 100, "%\n")
#> Jitter (local): 1.226397e-05 %
cat("Shimmer (local):", metrics$shimmer_local * 100, "%\n")
#> Shimmer (local): 5.722082e-07 %
cat("Shimmer (dB):", metrics$shimmer_local_db, "dB\n")
#> Shimmer (dB): 4.970137e-08 dB
```
