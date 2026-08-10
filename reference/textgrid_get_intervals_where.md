# Extract Intervals from TextGrid Matching Criteria

Extracts intervals from a TextGrid tier that match a specified
criterion. Returns time boundaries and labels of matching intervals.

## Usage

``` r
textgrid_get_intervals_where(
  textgrid,
  tier = 1,
  condition = c("equals", "contains", "does not contain", "starts with", "ends with"),
  text
)
```

## Arguments

- textgrid:

  TextGrid object

- tier:

  Integer. Tier number (1-indexed)

- condition:

  Character. Matching condition: - "equals" or "is equal to" - Exact
  match - "contains" - Label contains text - "does not contain" - Label
  does not contain text - "starts with" - Label starts with text - "ends
  with" - Label ends with text

- text:

  Character. Text to match

## Value

Named list with: - \`xmin\`: Numeric vector of interval start times -
\`xmax\`: Numeric vector of interval end times - \`text\`: Character
vector of interval labels - \`count\`: Integer number of matching
intervals

## Examples

``` r
sound <- sounds_append(
  Sound$create_tone(frequency = 200, duration = 0.5, amplitude = 0.8),
  Sound$create_tone(frequency = 200, duration = 0.3, amplitude = 0.001)
)
vad_grid <- sound_to_textgrid_silences(sound)

# Get all "sounding" intervals
voiced <- textgrid_get_intervals_where(
  vad_grid,
  tier = 1,
  condition = "equals",
  text = "sounding"
)

cat("Found", voiced$count, "voiced segments\n")
#> Found 1 voiced segments
cat("Total voiced duration:", sum(voiced$xmax - voiced$xmin), "s\n")
#> Total voiced duration: 0.52 s
```
