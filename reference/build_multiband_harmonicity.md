# Build reusable multi-band Harmonicity objects

Compute the 5 Harmonicity objects used by VQ's multiband HNR workflow
once, then reuse them across repeated interval queries with
\[multiband_hnr_stats()\].

## Usage

``` r
build_multiband_harmonicity(
  sound,
  bands = c(0, 500, 1500, 2500, 3500),
  time_step = 0.005,
  min_pitch = 75
)
```

## Arguments

- sound:

  Sound object or external pointer

- bands:

  Numeric vector of upper frequency limits in Hz (default \`c(0, 500,
  1500, 2500, 3500)\`)

- time_step:

  Time step for harmonicity in seconds (default \`0.005\`)

- min_pitch:

  Minimum pitch in Hz (default \`75\`)

## Value

Named list of 5 \`Harmonicity\` objects: \`full\`, \`band500\`,
\`band1500\`, \`band2500\`, \`band3500\` (or names derived from custom
bands).

## Details

Use this when the same \`Sound\` is queried over many \`\[from_time,
to_time\]\` windows, e.g. a TextGrid with multiple voiced intervals. The
expensive band-pass filtering and Harmonicity computation are done once;
only the summary stats are repeated.

## References

\- VQ_measurements_V2.praat (Voice Quality measurements) - Maryn &
Weenink (2015) - Multi-band HNR for voice quality

## See also

\[multiband_hnr_stats()\] and \[calculate_multiband_hnr_ultra()\]

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)

built <- build_multiband_harmonicity(sound)
hnr_full <- multiband_hnr_stats(built)
```
