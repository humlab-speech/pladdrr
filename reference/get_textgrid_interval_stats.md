# Get Interval Statistics for All Intervals (Batch)

Compute statistics (start, end, duration, label) for all intervals in a
tier in a single call, instead of a manual loop. Returns a data frame
ready for analysis.

## Usage

``` r
get_textgrid_interval_stats(textgrid, tier)
```

## Arguments

- textgrid:

  A TextGrid object

- tier:

  Tier number (1-based) or tier name

## Value

Data frame with columns: - \`index\`: Interval index (1-based) -
\`label\`: Interval label - \`start\`: Start time (seconds) - \`end\`:
End time (seconds) - \`duration\`: Duration (seconds)

## Examples

``` r
tg <- TextGrid$create(0, 1, "words")
tg$insert_boundary(1, 0.5)
tg$set_interval_text(1, 2, "hello")
stats <- get_textgrid_interval_stats(tg, tier = 1)

# Analysis with base R
voiced <- stats[stats$label == "hello", ]
mean(voiced$duration)
#> [1] 0.5
```
