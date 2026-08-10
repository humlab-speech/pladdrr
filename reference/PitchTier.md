# Praat PitchTier Object

Praat PitchTier object with direct C++ module binding for pitch
manipulation.

## Value

A `PitchTier` object with methods for pitch-contour manipulation via
time-value points.

## Details

PitchTiers are used in conjunction with Manipulation objects to modify
the pitch contour of sounds. Unlike Pitch objects (which contain sampled
data), PitchTiers contain discrete time-value pairs that can be edited.

\## Creating PitchTier Objects

\- \`PitchTier\$new(path)\` - Load from file - \`PitchTier(tmin,
tmax)\` - Create empty PitchTier - \`pitch\$down_to_pitch_tier()\` -
Extract from Pitch object

\## Querying

\- \`\$get_number_of_points()\` - Number of pitch points -
\`\$get_value_at_time(time)\` - Interpolated F0 at time -
\`\$get_value_at_index(index)\` - F0 of specific point -
\`\$get_time_from_index(index)\` - Time of specific point -
\`\$get_minimum()\` - Minimum F0 value - \`\$get_maximum()\` - Maximum
F0 value - \`\$get_mean(tmin, tmax)\` - Mean F0 (interpolated curve) -
\`\$get_standard_deviation(tmin, tmax)\` - Standard deviation -
\`\$get_area(tmin, tmax)\` - Area under curve

\## Modification

\- \`\$add_point(time, value)\` - Add pitch point (Hz) -
\`\$remove_point(index)\` - Remove point by index -
\`\$remove_points_between(tmin, tmax)\` - Remove points in time range -
\`\$multiply_frequencies(factor)\` - Scale all frequencies -
\`\$multiply_frequencies_in_range(tmin, tmax, factor)\` - Scale in
range - \`\$shift_frequencies(shift, unit)\` - Add to all frequencies -
\`\$shift_frequencies_in_range(tmin, tmax, shift, unit)\` - Shift in
range - \`\$stylize(frequency_resolution, use_semitones)\` - Simplify
contour - \`\$interpolate_quadratically(points_per_parabola,
logarithmically)\` - Smooth

\## Conversion

\- \`\$to_sound_pulse_train(sample_rate)\` - Synthesize pulse train -
\`\$to_sound_phonation(sample_rate)\` - Synthesize phonation -
\`\$to_sound_sine(sample_rate)\` - Synthesize sine wave -
\`\$down_to_point_process()\` - Extract time points -
\`\$to_pitch(time_step, pitch_floor, pitch_ceiling)\` - Convert to Pitch

\## Export

\- \`\$as_data_frame()\` - Convert to data.table - \`\$as_matrix()\` -
Convert to matrix - \`\$save(path)\` - Write to file

## Examples

``` r
# Create empty PitchTier and add points
pt <- PitchTier(0, 1)
pt$add_point(0.1, 120)
pt$add_point(0.5, 150)
pt$add_point(0.9, 100)

# Create from Pitch
sound <- Sound$create_tone(frequency = 150, duration = 0.5)
pitch <- sound$to_pitch()
pitch_tier <- pitch$down_to_pitch_tier()

# Modify pitch
pitch_tier$multiply_frequencies(1.5)  # Raise pitch 50%

# Query
f0_at_mid <- pitch_tier$get_value_at_time(0.25)
n_points <- pitch_tier$get_number_of_points()
f0_min <- pitch_tier$get_minimum()
f0_max <- pitch_tier$get_maximum()

# Synthesize
synth <- pitch_tier$to_sound_sine(16000)

# Export
df <- pitch_tier$as_data_frame()
```
