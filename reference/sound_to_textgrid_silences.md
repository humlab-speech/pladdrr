# Detect Silences in Sound and Create TextGrid

Detects silent and sounding (voiced) intervals in a Sound object and
returns a TextGrid with labeled intervals. This is essential for AVQI
calculation, which requires extraction of voiced segments from
continuous speech.

## Usage

``` r
sound_to_textgrid_silences(
  sound,
  minimum_pitch = 100,
  time_step = 0,
  silence_threshold = -25,
  min_silent_interval = 0.1,
  min_sounding_interval = 0.1,
  silent_label = "silence",
  sounding_label = "sounding"
)
```

## Arguments

- sound:

  Sound object to analyze

- minimum_pitch:

  Numeric. Minimum pitch for intensity calculation (Hz, default: 100)

- time_step:

  Numeric. Time step for intensity calculation (s, default: 0.0 = auto)

- silence_threshold:

  Numeric. Silence threshold in dB below maximum (default: -25)

- min_silent_interval:

  Numeric. Minimum duration of silent interval (s, default: 0.1)

- min_sounding_interval:

  Numeric. Minimum duration of sounding interval (s, default: 0.1)

- silent_label:

  Character. Label for silent intervals (default: "silence")

- sounding_label:

  Character. Label for sounding intervals (default: "sounding")

## Value

TextGrid object with one interval tier containing silent and sounding
intervals

## Details

The function works by: 1. Computing the intensity contour of the sound
2. Identifying regions where intensity falls below \`silence_threshold\`
dB relative to the maximum intensity 3. Merging nearby silent/sounding
regions based on minimum duration criteria 4. Creating a TextGrid with
labeled intervals

For AVQI, use these parameters (matching Praat AVQI script): -
\`minimum_pitch = 50\` - \`time_step = 0.003\` - \`silence_threshold =
-25\` - \`min_silent_interval = 0.1\` - \`min_sounding_interval = 0.1\`

## Examples

``` r
# Synthetic speech-like sound: loud / near-silent / loud
sound <- sounds_append(
  sounds_append(
    Sound$create_tone(frequency = 200, duration = 0.5, amplitude = 0.8),
    Sound$create_tone(frequency = 200, duration = 0.3, amplitude = 0.001)
  ),
  Sound$create_tone(frequency = 200, duration = 0.5, amplitude = 0.8)
)

# Create TextGrid with voice activity detection
vad_grid <- sound_to_textgrid_silences(
  sound,
  minimum_pitch = 50,
  time_step = 0.003,
  silence_threshold = -25,
  min_silent_interval = 0.1,
  min_sounding_interval = 0.1
)

# Extract voiced intervals
voiced_intervals <- textgrid_get_intervals_where(
  vad_grid,
  tier = 1,
  condition = "equals",
  text = "sounding"
)

# Extract voiced parts
voiced_sounds <- sound_extract_parts(
  sound,
  voiced_intervals$xmin,
  voiced_intervals$xmax,
  window_shape = "rectangular",
  relative_width = 1.0,
  preserve_times = FALSE
)
```
