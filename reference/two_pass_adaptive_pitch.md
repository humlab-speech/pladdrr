# Two-Pass Adaptive Pitch Extraction

Performs a two-pass pitch extraction where the first pass uses a wide
range (50-800 Hz by default) to estimate the speaker's pitch
distribution, then the second pass uses an adaptive range based on
quartiles (Q1\*0.75 to Q3\*1.5).

This is a standard technique for robust pitch extraction across speakers
with different voice ranges. Returns both the refined pitch contour and
the computed range parameters for transparency.

## Usage

``` r
two_pass_adaptive_pitch(
  sound,
  time_step = 0,
  initial_floor = 50,
  initial_ceiling = 800,
  voicing_threshold = 0.45,
  silence_threshold = 0.03,
  octave_cost = 0.01,
  octave_jump_cost = 0.35,
  voiced_unvoiced_cost = 0.14,
  q1_factor = 0.75,
  q3_factor = 1.5,
  method = c("cc", "ac")
)
```

## Arguments

- sound:

  Sound object or external pointer

- time_step:

  Time step (0 = auto, typically 0.75/pitch_floor)

- initial_floor:

  Initial pitch floor for pass 1 (default 50 Hz)

- initial_ceiling:

  Initial pitch ceiling for pass 1 (default 800 Hz)

- voicing_threshold:

  Voicing threshold (default 0.45)

- silence_threshold:

  Silence threshold (default 0.03)

- octave_cost:

  Octave cost (default 0.01)

- octave_jump_cost:

  Octave jump cost (default 0.35)

- voiced_unvoiced_cost:

  Voiced/unvoiced transition cost (default 0.14)

- q1_factor:

  Factor to multiply Q1 for min_pitch (default 0.75)

- q3_factor:

  Factor to multiply Q3 for max_pitch (default 1.5)

- method:

  Pitch method: "cc" (cross-correlation, default) or "ac"
  (autocorrelation)

## Value

Named list with: - \`pitch\`: External pointer to the refined Pitch
object - \`min_pitch\`: Computed minimum pitch (Q1 \* q1_factor) -
\`max_pitch\`: Computed maximum pitch (Q3 \* q3_factor) - \`q1\`: First
quartile of pass 1 pitch values - \`q3\`: Third quartile of pass 1 pitch
values

## Algorithm

1\. Pass 1: Extract pitch with wide range (initial_floor to
initial_ceiling) 2. Compute Q1 and Q3 from voiced frames 3. Pass 2:
Re-extract with adaptive range (Q1\*0.75 to Q3\*1.5)

## Performance

This is a pure R wrapper calling existing direct functions. No C++
overhead beyond the two pitch extractions. Suitable for batch
processing.

## See also

\[to_pitch_cc_direct()\], \[to_pitch_ac_direct()\] for single-pass
extraction \[pitch_get_adaptive_range()\] for the single-call quartile +
range computation \[get_pitch_quantiles_batch()\] for batch quartile
extraction

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 1.0)

# Basic usage (returns XPtr)
result <- two_pass_adaptive_pitch(sound)
pitch_refined <- Pitch(.xptr = result$pitch)
cat("Adaptive range:", result$min_pitch, "-", result$max_pitch, "Hz\n")
#> Adaptive range: 112.5 - 225 Hz

# With custom parameters
result <- two_pass_adaptive_pitch(sound,
  voicing_threshold = 0.6,  # Stricter voicing
  q1_factor = 0.7,          # Wider lower bound
  q3_factor = 1.6           # Wider upper bound
)
```
