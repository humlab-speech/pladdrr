# Praat TextGrid Object

R wrapper for a Praat TextGrid object for linguistic annotation. Uses
shared dispatch table for minimal memory per object.

## Arguments

- path:

  Path to a TextGrid file (Praat text or binary format). See the
  Creating TextGrid objects section for details.

- .xptr:

  Not for direct use. External pointer to the underlying C++ TextGrid
  object; set internally when a method returns a new TextGrid.

## Value

A `TextGrid` object with methods for tier and interval/point annotation
access.

## Details

TextGrids are the primary tool for linguistic annotation in Praat. They
contain one or more tiers, where each tier can be:

- `IntervalTier`: consecutive time intervals with labels (e.g.,
  phonemes, words)

- `PointTier` (TextTier): time points with labels (e.g., events, tones)

## Creating TextGrid objects

- `TextGrid(path)` - read from file (Praat text or binary format)

- `textgrid_create(tmin, tmax, tier_names, point_tiers)` - create an
  empty grid

## Querying tiers

- `get_number_of_tiers()` - number of tiers

- `get_tier_names()` - names of all tiers

- `tier_is_interval_tier(tier)` - check if a tier is an IntervalTier

- `tier_is_point_tier(tier)` - check if a tier is a PointTier

## IntervalTier operations

- `get_number_of_intervals(tier)` - number of intervals in a tier

- `get_interval_text(tier, n)` - get the label of interval n

- `get_label_at_time(tier, time)` - get the label at a specific time

- `get_all_intervals(tier)` - get all intervals as a data.frame (fast)

- `extract_intervals_batch(tier, ...)` - extract matching intervals
  (fast)

- `extract_intervals_where(sound, tier, criterion, text, preserve_times)` -
  extract Sound intervals matching a text criterion

- `set_interval_text(tier, n, text)` - set the label of interval n

- `insert_boundary(tier, time)` - insert a new boundary

- `remove_boundary(tier, time)` - remove a boundary

## PointTier operations

- `get_number_of_points(tier)` - number of points in a tier

- `get_point_text(tier, n)` - get the label of point n

- `insert_point(tier, time, mark)` - insert a new point

- `set_point_text(tier, n, text)` - set the label of point n

- `remove_point(tier, n)` - remove a point

## Tier management

- `add_interval_tier(name)` - add a new IntervalTier

- `add_point_tier(name)` - add a new PointTier

- `remove_tier(tier)` - remove a tier

- `set_tier_name(tier, name)` - rename a tier

- `duplicate_tier(tier, new_name)` - duplicate a tier with a new name

## Export

- `as_data_frame(tiers)` - convert to a long-format data frame

- `save(path)` - write to a file

- `extract_part(start, end)` - extract a time range

## Examples
