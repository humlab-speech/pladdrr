# Pair Sound and TextGrid Files

Find matching Sound and TextGrid files in directories. This replaces
Praat's pattern of manually pairing files based on naming conventions.

## Usage

``` r
pair_sound_textgrid(
  sound_dir,
  textgrid_dir = sound_dir,
  sound_pattern = "\\.wav$",
  textgrid_pattern = "\\.TextGrid$",
  by = "basename",
  require_both = TRUE
)
```

## Arguments

- sound_dir:

  Character path to directory containing audio files

- textgrid_dir:

  Character path to directory containing TextGrid files (default: same
  as sound_dir)

- sound_pattern:

  Pattern to match sound files (default: "\\.wav\$")

- textgrid_pattern:

  Pattern to match TextGrid files (default: "\\.TextGrid\$")

- by:

  Matching strategy: "basename" (default), "full", or a custom function

- require_both:

  Logical, only return pairs where both files exist (default: TRUE)

## Value

Data frame with columns: sound_file, textgrid_file, basename

## Examples

``` r
audio_dir <- tempfile("audio_")
dir.create(audio_dir)
Sound$create_tone(frequency = 150, duration = 0.3, sampling_rate = 16000)$save(
  file.path(audio_dir, "utt1.wav")
)
tg <- TextGrid$create(0, 0.3, "words")
tg$save(file.path(audio_dir, "utt1.TextGrid"))

# Find all matching pairs
pairs <- pair_sound_textgrid(sound_dir = audio_dir)

# Process each pair
for (i in seq_len(nrow(pairs))) {
  sound <- Sound(pairs$sound_file[i])
  textgrid <- TextGrid(pairs$textgrid_file[i])
  # ... process ...
}
```
