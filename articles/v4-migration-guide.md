# Migration Guide: pladdrr v4.0 (data.table)

## Overview

**pladdrr v4.0** migrates from `data.frame` to `data.table` for all data
outputs, changing some operations from quadratic to log-linear or linear
algorithmic complexity, while maintaining **full backward
compatibility** for most use cases.

### What Changed

#### All `as_data_frame()` Methods Now Return `data.table`

All 26 Rcpp modules that previously returned `data.frame` now return
`data.table`:

``` r

library(pladdrr)

# Example: Pitch extraction
snd <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
pitch <- snd$to_pitch()
df <- pitch$as_data_frame()

class(df)
# [1] "data.table" "data.frame"
```

#### Algorithmic Complexity Changes

| Operation          | v3.0       | v4.0     |
|--------------------|------------|----------|
| Formant extraction | O(n²)      | O(n)     |
| File pairing       | O(n²)      | O(n)     |
| TextGrid filtering | O(n log n) | O(log n) |
| Batch operations   | unkeyed    | keyed    |

------------------------------------------------------------------------

### Do You Need to Update Your Code?

#### Most Code Works Unchanged

If your code uses standard data.frame operations, it continues to work
without changes.

``` r

# All of these work exactly as before:
df$time              # Column access
df[df$frequency > 100, ]  # Row filtering
df[, c("time", "frequency")]  # Column selection
subset(df, time > 1.0)  # Filtering
df1 <- df
df2 <- df
merge(df1, df2, by = "time")  # Joining
library(ggplot2)
ggplot(df, aes(time, frequency))  # Plotting
```

**Why?** Because `data.table` **inherits from** `data.frame`:

``` r

library(data.table)
is.data.frame(df)  # TRUE
is.data.table(df)  # TRUE (requires library(data.table))
```

------------------------------------------------------------------------

#### Code That May Break

##### 1. Exact Class Comparison

**BREAKS:**

``` r

if (class(df) == "data.frame") {
  # class(df) is now c("data.table", "data.frame") - a length-2 vector.
  # On current R this raises "the condition has length > 1"
  # instead of comparing to a single string.
}
```

**FIX:**

``` r

# Use inherits() instead
if (inherits(df, "data.frame")) {
  # This works in both v3.0 and v4.0
}
```

##### 2. Expecting Single Class String

**BREAKS:**

``` r

stopifnot(class(df) == "data.frame")  # Fails
```

**FIX:**

``` r

stopifnot(inherits(df, "data.frame"))  # Works
# OR
stopifnot("data.frame" %in% class(df))  # Works
```

##### 3. Functions That Reject data.table

Some packages may explicitly reject `data.table` objects:

**SYMPTOM:**

``` r

some_function(df)
# Error: Expected data.frame, got data.table
```

**FIX:**

``` r

# Convert back to plain data.frame
some_function(as.data.frame(df))
```

------------------------------------------------------------------------

### Taking Advantage of data.table

#### Fast Operations with `data.table` Syntax

Once you have `data.table` loaded, you can use its syntax directly:

``` r

library(data.table)

# Fast filtering with keys
pitch_df <- pitch$as_data_frame()
setkey(pitch_df, time)  # Already done by pladdrr!

# Binary search (fast!)
pitch_df[time > 1.0 & time < 2.0]

# Fast aggregation
pitch_df[, .(mean_freq = mean(frequency, na.rm = TRUE)), by = voiced]

# In-place updates (no copies!)
pitch_df[voiced == TRUE, frequency_class := cut(frequency, breaks = 3)]
```

#### Efficient Batch Processing

``` r

library(data.table)

# Fast rbind for multiple files
file_list <- list.files("audio/", pattern = "\\.wav$", full.names = TRUE)
# (in this example, "audio/" is a directory of your own .wav files)

results <- rbindlist(lapply(file_list, function(f) {
  snd <- Sound$new(f)
  pitch <- snd$to_pitch()
  df <- pitch$as_data_frame()
  df[, file := basename(f)]
  df
}))

# Fast aggregation across all files
results[, .(
  mean_f0 = mean(frequency, na.rm = TRUE),
  sd_f0 = sd(frequency, na.rm = TRUE)
), by = file]
```

------------------------------------------------------------------------

### Migration Checklist

Use this checklist to update your code:

#### Step 1: Review Class Checks

Search your code for patterns like:

``` bash
# In your R scripts
grep -r "class.*== \"data.frame\"" your_code/
grep -r "class.*data.frame" your_code/
```

Replace with `inherits(x, "data.frame")`.

#### Step 2: Test Your Code

``` r

# Install v4.0
# install.packages("pladdrr")

# Run your existing tests (path is your own tests/ directory)
testthat::test_dir("tests/")

# Or test interactively
library(pladdrr)
# ... run your analysis pipeline ...
```

#### Step 3: Handle Incompatibilities

If you encounter errors:

1.  **Check if the function rejects data.table:**

    ``` r

    # Wrap in as.data.frame()
    problematic_function(as.data.frame(df))
    ```

2.  **Check class comparisons:**

    ``` r

    # Use inherits() instead of ==
    if (inherits(df, "data.frame")) {
      # your code here
    }
    ```

#### Step 4: (Optional) Optimize with data.table

If you’re processing large datasets:

``` r

library(data.table)

# Learn data.table syntax
vignette("datatable-intro")

# Use keys for fast lookups
setkey(df, time)
df[J(1.0)]  # Fast time lookup

# Use .SD for grouped operations
df[, lapply(.SD, mean), by = voiced]
```

------------------------------------------------------------------------

### Common Use Cases

#### Case 1: Formant Extraction

``` r

library(pladdrr)
library(data.table)

# Extract formants
snd <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
formant <- snd$to_formant_burg()
df <- formant$as_data_frame(max_formants = 4)

# data.table is already keyed by (time, formant)
# Fast filtering
f1_data <- df[formant == 1]
f2_vowels <- df[formant == 2 & time > 1.0 & time < 2.0]

# Fast aggregation by formant
df[, .(mean_freq = mean(frequency, na.rm = TRUE)), by = formant]
```

#### Case 2: TextGrid Analysis

``` r

library(pladdrr)
library(data.table)

# Load TextGrid
tg <- TextGrid$new(system.file("extdata", "test.TextGrid", package = "pladdrr"))
intervals <- tg$as_data_frame()

# Fast filtering by tier and label
vowels <- intervals[tier_name == "phones" & label %in% c("ɛ", "ɔ")]

# Calculate durations
vowels[, duration := end_time - start_time]

# Summary statistics
vowels[, .(
  mean_duration = mean(duration),
  n = .N
), by = label]
```

#### Case 3: Batch Processing

``` r

library(pladdrr)
library(data.table)

# Pair sound files with TextGrids
# (in this example, "audio/" and "annotations/" are your own directories)
pairs <- pair_sound_textgrid(
  sound_dir = "audio/",
  textgrid_dir = "annotations/",
  by = "basename"
)

# Process all pairs efficiently
results <- rbindlist(lapply(seq_len(nrow(pairs)), function(i) {
  snd <- Sound$new(pairs$sound_file[i])
  tg <- TextGrid$new(pairs$textgrid_file[i])
  
  # Extract measurements
  pitch <- snd$to_pitch()
  pitch_df <- pitch$as_data_frame()
  
  # Add metadata
  pitch_df[, basename := pairs$basename[i]]
  pitch_df
}))

# Analyze across all files
results[, .(
  mean_f0 = mean(frequency, na.rm = TRUE),
  voiced_percent = sum(voiced) / .N * 100
), by = basename]
```

------------------------------------------------------------------------

### Performance Tips

#### 1. Avoid Growing data.frames in Loops

**Avoid (v3.0 pattern):**

``` r

# Don't do this!
results <- data.frame()
for (file in files) {
  df <- process_file(file)
  results <- rbind(results, df)  # Grows a copy every iteration
}
```

**Prefer (v4.0 pattern):**

``` r

library(data.table)

# Pre-allocate and combine once
results <- rbindlist(lapply(files, process_file))
```

#### 2. Use Keys for Repeated Lookups

``` r

library(data.table)

# Set key once
setkey(df, time)

# Fast repeated lookups
time_points <- head(df$time, 3)
for (t in time_points) {
  value <- df[J(t), frequency]  # Binary search
}
```

#### 3. Use In-Place Updates

``` r

library(data.table)

# Creates a copy of the column
df$new_col <- transform(df$old_col)

# Updates in-place
df[, new_col := transform(old_col)]
```

------------------------------------------------------------------------

### Backward Compatibility Mode

If you need to temporarily revert to `data.frame` behavior:

``` r

# Option 1: Convert individual results
df_plain <- as.data.frame(pitch$as_data_frame())

# Option 2: Set package option (NOT RECOMMENDED)
options(pladdrr.return_datatable = FALSE)
# Note: This option may be removed in future versions
```

**Warning:** Disabling data.table loses all performance benefits!

------------------------------------------------------------------------

### FAQ

#### Q: Do I need to install data.table?

**A:** It’s automatically installed as a dependency of pladdrr v4.0.

#### Q: Will my ggplot2 code still work?

**A:** Yes, ggplot2 works with data.table because it inherits from
data.frame.

``` r

library(ggplot2)
df <- pitch$as_data_frame()
ggplot(df, aes(time, frequency)) + geom_line()
```

#### Q: Can I convert back to data.frame?

**A:** Yes, use
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html):

``` r

df_plain <- as.data.frame(df)
class(df_plain)  # "data.frame"
```

#### Q: Do I need to learn data.table syntax?

**A:** No! Your existing code should work. But learning data.table can
help you: - Write faster code for large datasets - Use more concise
syntax - Process data more efficiently

See: [data.table introduction](https://rdatatable.gitlab.io/data.table/)

#### Q: What if I find a bug?

**A:** Report it to the maintainer: <fredrik.nylen@umu.se>

------------------------------------------------------------------------

### Resources

- **data.table Introduction:**
  [`vignette("datatable-intro")`](https://cran.rstudio.com/web/packages/data.table/vignettes/datatable-intro.html)
- **data.table Cheatsheet:**
  <https://github.com/Rdatatable/data.table/wiki/Getting-started>
- **pladdrr Documentation:** <https://humlab-speech.github.io/pladdrr>
- **Maintainer:** <fredrik.nylen@umu.se>

------------------------------------------------------------------------

### Summary

- **Most code works unchanged** - data.table inherits from data.frame
- **Lower algorithmic complexity** for several batch operations
- **Update class checks** - Use
  [`inherits()`](https://rdrr.io/r/base/class.html) instead of `==`
- **Optional:** Learn data.table syntax for additional keyed-operation
  features

**Need help?** Open an issue on GitHub or consult the data.table
documentation.
