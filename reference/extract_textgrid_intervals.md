# Extract Intervals Matching Criteria (Batch)

Extract all intervals from a TextGrid tier that match specified text
criteria, in a single call instead of a manual R loop.

## Usage

``` r
extract_textgrid_intervals(
  textgrid,
  sound = NULL,
  tier,
  text_equals = NULL,
  text_contains = NULL,
  text_starts_with = NULL,
  extract_sounds = FALSE
)
```

## Arguments

- textgrid:

  A TextGrid object

- sound:

  A Sound object (optional, required if extract_sounds = TRUE)

- tier:

  Tier number (1-based) or tier name

- text_equals:

  Exact label match (e.g., "V" for voiced)

- text_contains:

  Substring match (e.g., "vowel")

- text_starts_with:

  Prefix match (e.g., "IPA\_")

- extract_sounds:

  Logical. If TRUE, extract Sound parts for matched intervals

## Value

List with components: - \`indices\`: Integer vector of matching interval
indices - \`labels\`: Character vector of matching labels -
\`start_times\`: Numeric vector of start times - \`end_times\`: Numeric
vector of end times - \`n_total\`: Total number of intervals in tier -
\`n_matched\`: Number of matching intervals - \`sounds\`: List of Sound
objects (if extract_sounds = TRUE)

## How It Works

A manual R loop makes one R\<-\>C++ call per interval; this function
does the whole tier scan in a single C++ call.

## Comparison Types

Specify exactly ONE comparison criterion: - \`text_equals\`: Exact match
(fastest) - \`text_contains\`: Substring search - \`text_starts_with\`:
Prefix match

## See also

\- \[get_textgrid_labels_all()\] to get all labels from a tier -
\[get_textgrid_interval_stats()\] to compute statistics for all
intervals

## Examples

``` r
# Create sound and a voiced/unvoiced TextGrid
sound <- Sound$create_tone(frequency = 150, duration = 1, sampling_rate = 16000)
pitch <- sound$to_pitch()
tg <- pitch$to_textgrid_vuv(0.02, 0.01)

# Extract all voiced intervals (batch), with the matching Sound parts
result <- extract_textgrid_intervals(
  textgrid = tg,
  sound = sound,
  tier = 1,
  text_equals = "V",
  extract_sounds = TRUE
)
voiced_sounds <- result$sounds

# Get interval durations without extracting sounds
result2 <- extract_textgrid_intervals(
  textgrid = tg,
  tier = 1,
  text_equals = "V",
  extract_sounds = FALSE
)
voiced_durations <- result2$end_times - result2$start_times
```
