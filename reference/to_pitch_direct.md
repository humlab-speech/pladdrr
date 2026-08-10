# Create Pitch from Sound Directly (returns XPtr) - Basic Parameters

Create Pitch analysis directly, returning raw external pointer. This is
a simplified version with basic parameters only.

\*\*NOTE:\*\* For full control over voicing parameters
(silence_threshold, voicing_threshold, etc.), use
\`to_pitch_ac_direct()\` or \`to_pitch_cc_direct()\` instead.

## Usage

``` r
to_pitch_direct(sound, time_step = 0, pitch_floor = 75, pitch_ceiling = 600)
```

## Arguments

- sound:

  Sound object or external pointer

- time_step:

  Time step (0 = auto)

- pitch_floor:

  Minimum pitch (Hz)

- pitch_ceiling:

  Maximum pitch (Hz)

## Value

External pointer to Pitch (NOT R6 object)

## See also

\[to_pitch_ac_direct()\], \[to_pitch_cc_direct()\] for full parameter
control

## Examples

``` r
sound <- Sound$create_tone(frequency = 200, duration = 0.5)

# Returns raw pointer (basic parameters)
pitch_ptr <- to_pitch_direct(sound)

# Use with other direct query functions
stats <- get_pitch_stats_direct(pitch_ptr)
```
