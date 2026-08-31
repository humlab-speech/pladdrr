# Pair Sound and TextGrid Files

Find matching pairs of Sound and TextGrid files based on filename
matching. Equivalent to Praat's manual file pairing but automated.

## Usage

``` r
pair_files(
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

  Character. Directory containing sound files.

- textgrid_dir:

  Character. Directory containing TextGrid files (default: same as
  sound_dir).

- sound_pattern:

  Character. Pattern for sound files (default: "\\.wav\$").

- textgrid_pattern:

  Character. Pattern for TextGrid files (default: "\\.TextGrid\$").

- by:

  Character. Matching strategy: "basename" (default), "exact", or a
  custom function.

- require_both:

  Logical. Require both files to exist (default: TRUE).

## Value

Data frame with columns: sound_file, textgrid_file, basename.

## Examples

``` r
audio_dir <- tempfile("audio_")
dir.create(audio_dir)
Sound$create_tone(frequency = 150, duration = 0.3, sampling_rate =
 16000)$save(
  file.path(audio_dir, "utt1.wav")
)
tg <- TextGrid$create(0, 0.3, "words")
tg$save(file.path(audio_dir, "utt1.TextGrid"))

# Find all matching pairs
pairs <- pair_files(sound_dir = audio_dir)
#> Found 1 matching file pairs

# Process each pair
results <- lapply(seq_len(nrow(pairs)), function(i) {
  sound <- Sound(pairs$sound_file[i])
  textgrid <- TextGrid(pairs$textgrid_file[i])
  # ... analysis ...
})
```
