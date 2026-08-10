# Calculate multi-band HNR in a single call

Optimized multi-band HNR calculation for VQ (Voice Quality)
measurements. Computes HNR (mean + standard deviation) for 5 frequency
bands in a single call: full spectrum, 0-500 Hz, 0-1500 Hz, 0-2500 Hz,
0-3500 Hz.

## Usage

``` r
calculate_multiband_hnr_ultra(
  sound,
  bands = c(0, 500, 1500, 2500, 3500),
  time_step = 0.005,
  min_pitch = 75,
  from_time = 0,
  to_time = 0
)
```

## Arguments

- sound:

  Sound object or external pointer

- bands:

  Numeric vector of upper frequency limits in Hz (default \`c(0, 500,
  1500, 2500, 3500)\`, where \`0\` = full spectrum)

- time_step:

  Time step for harmonicity in seconds (default \`0.005\`)

- min_pitch:

  Minimum pitch in Hz (default \`75\`)

- from_time:

  Start time for statistics extraction (default \`0\`)

- to_time:

  End time for statistics extraction (default \`0\`)

## Value

Named list with \`\*\_mean\` and \`\*\_sd\` values for each band.

## Details

Use this when you only need one interval or whole-sound summary. For
repeated interval queries on the same \`Sound\`, use
\[build_multiband_harmonicity()\] once and then
\[multiband_hnr_stats()\] for each interval.

## Algorithm choice

Harmonicity is always computed with \`Sound_to_Harmonicity_cc()\` (the
CC method) for every band — there is no AC alternative and no way to
configure it. This matches VQ_measurements_V2.praat lines 102-122. See
the Tier 4 Ultra algorithm table in \`inst/agents/AGENT_GUIDE.md\`.

## References

\- VQ_measurements_V2.praat (Voice Quality measurements) - Maryn &
Weenink (2015) - Multi-band HNR for voice quality

## See also

\[build_multiband_harmonicity()\] and \[multiband_hnr_stats()\] for the
reusable multi-interval path

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)

hnr_results <- calculate_multiband_hnr_ultra(sound)
hnr_results$full_mean
#> [1] 77.91375
```
