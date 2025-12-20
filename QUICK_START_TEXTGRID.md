# TextGrid Quick Start Guide

## Installation Status
✅ **READY** - TextGrid file reading fully functional as of 2025-12-19

## Basic Usage

```r
library(pladdrr)

# Load TextGrid file
tg <- TextGrid$new('path/to/file.TextGrid')

# Basic information
tg$get_total_duration()    # Total duration in seconds
tg$get_number_of_tiers()   # Number of tiers
tg$get_tier_names()        # Vector of tier names
```

## Working with Interval Tiers

```r
# Check if tier is an interval tier
tg$tier_is_interval_tier(1)  # TRUE/FALSE

# Get number of intervals
n <- tg$get_number_of_intervals(tier = 1)

# Get interval information
start <- tg$get_interval_start_time(tier = 1, interval_number = 1)
end <- tg$get_interval_end_time(tier = 1, interval_number = 1)
text <- tg$get_interval_text(tier = 1, interval_number = 1)

# Find interval at specific time
idx <- tg$get_interval_at_time(tier = 1, time = 30.0)
label <- tg$get_label_at_time(tier = 1, time = 30.0)
```

## Working with Point Tiers

```r
# Check if tier is a point tier
tg$tier_is_point_tier(5)  # TRUE/FALSE

# Get number of points
n <- tg$get_number_of_points(tier = 5)

# Get point information
time <- tg$get_point_time(tier = 5, point_number = 1)
text <- tg$get_point_text(tier = 5, point_number = 1)
```

## Performance

Excellent loading speed for all file sizes:
- 1 MB: ~0.01s
- 12 MB: ~0.05s  
- 37 MB: ~0.16s

## Status
All methods tested and working. Package is production-ready.

For complete documentation, see: `TEXTGRID_FIX_COMPLETE.md`
