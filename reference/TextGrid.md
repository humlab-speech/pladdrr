# Praat TextGrid Object

R wrapper for a Praat TextGrid object for linguistic annotation. Uses
shared dispatch table for minimal memory per object.

## Value

A `TextGrid` object with methods for tier and interval/point annotation
access.

## Details

TextGrids are the primary tool for linguistic annotation in Praat. They
contain one or more tiers, where each tier can be: -
\*\*IntervalTier\*\*: Consecutive time intervals with labels (e.g.,
phonemes, words) - \*\*PointTier\*\* (TextTier): Time points with labels
(e.g., events, tones)

\## Creating TextGrid Objects

\- \`TextGrid(path)\` - Read from file (Praat text or binary format) -
\`textgrid_create(tmin, tmax, tier_names, point_tiers)\` - Create empty
grid

\## Querying Tiers

\- \`\$get_number_of_tiers()\` - Number of tiers -
\`\$get_tier_names()\` - Names of all tiers -
\`\$tier_is_interval_tier(tier)\` - Check if tier is IntervalTier -
\`\$tier_is_point_tier(tier)\` - Check if tier is PointTier

\## IntervalTier Operations

\- \`\$get_number_of_intervals(tier)\` - Number of intervals in tier -
\`\$get_interval_text(tier, n)\` - Get label of interval n -
\`\$get_label_at_time(tier, time)\` - Get label at specific time -
\`\$get_all_intervals(tier)\` - Get all intervals as data.frame (fast) -
\`\$extract_intervals_batch(tier, ...)\` - Extract matching intervals
(fast) - \`\$extract_intervals_where(sound, tier, criterion, text,
preserve_times)\` - Extract Sound intervals matching a text criterion -
\`\$set_interval_text(tier, n, text)\` - Set label of interval n -
\`\$insert_boundary(tier, time)\` - Insert new boundary -
\`\$remove_boundary(tier, time)\` - Remove boundary

\## PointTier Operations

\- \`\$get_number_of_points(tier)\` - Number of points in tier -
\`\$get_point_text(tier, n)\` - Get label of point n -
\`\$insert_point(tier, time, mark)\` - Insert new point -
\`\$set_point_text(tier, n, text)\` - Set label of point n -
\`\$remove_point(tier, n)\` - Remove point

\## Tier Management

\- \`\$add_interval_tier(name)\` - Add new IntervalTier -
\`\$add_point_tier(name)\` - Add new PointTier -
\`\$remove_tier(tier)\` - Remove tier - \`\$set_tier_name(tier,
name)\` - Rename a tier - \`\$duplicate_tier(tier, new_name)\` -
Duplicate tier with new name

\## Export

\- \`\$as_data_frame(tiers)\` - Convert to long-format data frame -
\`\$save(path)\` - Write to file - \`\$extract_part(start, end)\` -
Extract time range

## Examples

``` r
# Create new TextGrid with one interval tier and one point tier
# (tier_names lists all tiers; point_tiers names the subset that are point tiers)
tg <- textgrid_create(0, 1, "words tones", "tones")
tg$get_tier_names()
#> [1] "words" "tones"

# Add boundaries and labels (IntervalTier)
tg$insert_boundary("words", 0.4)
tg$insert_boundary("words", 0.7)
tg$set_interval_text("words", 1, "hello")
tg$set_interval_text("words", 2, "world")

# Add points and labels (PointTier)
tg$insert_point("tones", 0.2, "H*")
tg$insert_point("tones", 0.8, "L-L%")

# Query
tg$get_number_of_intervals("words")
#> [1] 3
label <- tg$get_label_at_time("words", 0.5)

# Export to R
df <- tg$as_data_frame()
```
