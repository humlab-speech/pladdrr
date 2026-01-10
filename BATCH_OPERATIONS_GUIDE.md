# Batch Operations Guide

**pladdrr v2.3.0** - High-Performance Batch Processing

This guide explains how to use batch operations in pladdrr for maximum performance when processing multiple files or querying multiple time points.

---

## Why Use Batch Operations?

**Problem:** Traditional loops cross the R↔C++ boundary repeatedly, adding overhead.

```r
# SLOW: 100 R→C crossings for 100 time points
times <- seq(0.1, 1.0, by = 0.01)
f1_values <- numeric(length(times))
for (i in seq_along(times)) {
  f1_values[i] <- formant$get_value_at_time(1, times[i], "hertz")  # R→C
}
```

**Solution:** Batch operations process everything in a single C++ call.

```r
# FAST: 1 R→C crossing for 100 time points (10-20x faster)
f1_values <- formant_get_values_at_times(formant, times, formant_number = 1)
```

---

## Types of Batch Operations

### 1. Batch Conversions

Convert multiple sounds to analysis objects in one call.

**Functions:**
- `sound_to_pitch_batch(sounds, ...)` - Extract pitch from multiple sounds
- `sound_to_pitch_ac_batch(sounds, ...)` - Autocorrelation pitch (batch)
- `sound_to_pitch_cc_batch(sounds, ...)` - Cross-correlation pitch (batch)
- `sound_to_formant_batch(sounds, ...)` - Extract formants (batch)
- `sound_to_intensity_batch(sounds, ...)` - Extract intensity (batch)

**Example:**

```r
# Load multiple sounds
files <- list.files("audio/", pattern = "\\.wav$", full.names = TRUE)
sounds <- lapply(files, Sound)

# SLOW: Loop approach
pitches <- lapply(sounds, function(s) s$to_pitch())  # n R→C crossings

# FAST: Batch approach (5-10x faster)
pitches <- sound_to_pitch_batch(sounds)  # 1 R→C crossing
```

### 2. Extract-and-Analyze Combinations

Extract segments from a sound and analyze them in a single call.

**Functions:**
- `sound_extract_and_pitch(sound, from_times, to_times, ...)` - Extract + pitch
- `sound_extract_and_formant(sound, from_times, to_times, ...)` - Extract + formant

**Example:**

```r
# Analyze multiple intervals from a long recording
sound <- Sound("long_recording.wav")
textgrid <- TextGrid("annotations.TextGrid")

# Get interval times
intervals <- textgrid$get_all_intervals(tier = 1)
from_times <- intervals$start
to_times <- intervals$end

# SLOW: Extract then analyze (2n R→C crossings)
parts <- lapply(seq_along(from_times), function(i) {
  sound$extract_part(from_times[i], to_times[i])
})
pitches <- lapply(parts, function(p) p$to_pitch())

# FAST: Combined operation (1 R→C crossing, 5-10x faster)
pitches <- sound_extract_and_pitch(sound, from_times, to_times)
```

### 3. Vectorized Queries

Extract values at multiple time points in one call.

**Functions:**
- `pitch_get_values_at_times(pitch, times, ...)` - Pitch at multiple times
- `formant_get_values_at_times(formant, times, ...)` - Single formant at multiple times
- `get_formants_at_times(formant, times, ...)` - All formants (F1-F4) at multiple times
- `intensity_get_values_at_times(intensity, times, ...)` - Intensity at multiple times
- `get_formant_bandwidths_at_times(formant, times, ...)` - Bandwidths at multiple times
- `get_pitch_strengths_at_times(pitch, times, ...)` - Pitch strength at multiple times

**Example: Formant Tracking**

```r
sound <- Sound("vowel.wav")
formant <- sound$to_formant()

# Define time points
times <- seq(0.1, 0.5, by = 0.001)  # 400 points

# SLOW: Loop (400 R→C crossings, ~800ms)
f1_values <- sapply(times, function(t) {
  formant$get_value_at_time(1, t, "hertz")
})

# FAST: Vectorized (1 R→C crossing, ~40ms, 20x faster)
f1_values <- formant_get_values_at_times(formant, times, formant_number = 1)

# EVEN BETTER: Get all formants at once
all_formants <- get_formants_at_times(formant, times, formant_numbers = 1:4)
f1_values <- all_formants$F1
f2_values <- all_formants$F2
f3_values <- all_formants$F3
f4_values <- all_formants$F4
```

### 4. Batch Aggregation

Get multiple measurements in a single call.

**Functions:**
- `sound_concatenate_all(sounds, ...)` - Concatenate multiple sounds

**Example:**

```r
# Concatenate multiple recordings
sounds <- lapply(files, Sound)

# SLOW: Sequential concatenation (O(n) operations)
result <- Reduce(function(a, b) a$concatenate(b), sounds)

# FAST: Batch concatenation (O(1) operation)
result <- sound_concatenate_all(sounds)
```

---

## Complete Workflow Examples

### Example 1: AVQI Voice Quality Analysis

Acoustic Voice Quality Index (AVQI) requires multiple measurements from sustained vowels and continuous speech.

```r
library(pladdrr)

# Load recording
sound <- Sound("patient_voice.wav")

# Get TextGrid with intervals
tg <- TextGrid("annotations.TextGrid")
vowel_intervals <- tg$get_all_intervals(tier = "vowels")

# Extract vowel portions and analyze in batch
vowel_sounds <- sound_extract_and_formant(
  sound,
  vowel_intervals$start,
  vowel_intervals$end,
  time_step = 0.005
)

# Get F1-F4 trajectories for all vowels
vowel_formants <- lapply(vowel_sounds, function(f) {
  times <- seq(f$get_start_time(), f$get_end_time(), by = 0.001)
  get_formants_at_times(f, times, formant_numbers = 1:4)
})

# Process results
all_f1 <- unlist(lapply(vowel_formants, function(x) x$F1))
mean_f1 <- mean(all_f1, na.rm = TRUE)
```

### Example 2: Tremor Analysis

Analyze voice tremor by tracking pitch and intensity modulation.

```r
sound <- Sound("tremor_sample.wav")

# Extract pitch and intensity
pitch <- sound$to_pitch()
intensity <- sound$to_intensity()

# Define high-resolution time grid
times <- seq(pitch$get_start_time(), 
             pitch$get_end_time(), 
             by = 0.001)  # 1ms resolution

# Get values at all time points (vectorized)
f0_values <- pitch_get_values_at_times(pitch, times, unit = "hertz")
int_values <- intensity_get_values_at_times(intensity, times)

# Analyze modulation
f0_range <- diff(range(f0_values, na.rm = TRUE))
f0_sd <- sd(f0_values, na.rm = TRUE)

# Spectral analysis of modulation
f0_clean <- na.omit(f0_values)
f0_detrended <- f0_clean - mean(f0_clean)
tremor_spectrum <- stats::spectrum(f0_detrended, plot = FALSE)

# Identify tremor frequency (typically 4-7 Hz)
tremor_freq_idx <- which(tremor_spectrum$freq >= 4/44100 & 
                          tremor_spectrum$freq <= 7/44100)
tremor_power <- max(tremor_spectrum$spec[tremor_freq_idx])
```

### Example 3: Large-Scale Corpus Analysis

Process hundreds of files efficiently.

```r
# Get all files
corpus_files <- list.files("corpus/", pattern = "\\.wav$", full.names = TRUE)
cat(sprintf("Processing %d files\n", length(corpus_files)))

# Parallel batch processing
library(parallel)

results <- analyze_files_parallel(corpus_files, function(sound) {
  # Extract pitch
  pitch <- sound$to_pitch(pitch_floor = 75, pitch_ceiling = 300)
  
  # Get comprehensive statistics in one call (Tier 2 Direct API)
  pitch_stats <- get_pitch_stats_direct(pitch)
  
  # Extract formants
  formant <- sound$to_formant()
  
  # Get formants at 10 evenly-spaced time points
  duration <- sound$get_total_duration()
  times <- seq(0.1 * duration, 0.9 * duration, length.out = 10)
  formant_values <- get_formants_at_times(formant, times, formant_numbers = 1:4)
  
  # Return aggregated results
  list(
    file = basename(sound$get_name()),
    duration = duration,
    pitch_mean = pitch_stats$mean,
    pitch_sd = pitch_stats$stdev,
    f1_mean = mean(formant_values$F1, na.rm = TRUE),
    f2_mean = mean(formant_values$F2, na.rm = TRUE),
    f3_mean = mean(formant_values$F3, na.rm = TRUE)
  )
}, n_cores = 4)

# Convert to data frame
results_df <- do.call(rbind, lapply(results, as.data.frame))
write.csv(results_df, "corpus_analysis_results.csv", row.names = FALSE)
```

---

## Performance Benchmarks

Real-world performance improvements from batch operations:

| Operation | Traditional Loop | Batch Operation | Speedup |
|-----------|------------------|-----------------|---------|
| Extract pitch (100 sounds) | 15.0s | 3.0s | **5x** |
| Get F1 at 400 time points | 0.8s | 0.04s | **20x** |
| Extract + analyze 50 intervals | 12.0s | 1.5s | **8x** |
| Get F1-F4 at 100 times | 1.6s | 0.12s | **13x** |
| Concatenate 20 sounds | 2.5s | 0.3s | **8x** |

System: Apple M1, macOS, pladdrr v2.3.0

---

## Best Practices

### 1. Always Vectorize Time Queries

```r
# ❌ NEVER do this in production code
for (t in times) {
  val <- pitch$get_value_at_time(t, "hertz")
}

# ✅ ALWAYS use vectorized queries
values <- pitch_get_values_at_times(pitch, times)
```

### 2. Combine Batch Operations

```r
# ❌ Separate operations
parts <- sound$extract_parts_batch(starts, ends)
pitches <- lapply(parts, function(p) p$to_pitch())

# ✅ Combined operation
pitches <- sound_extract_and_pitch(sound, starts, ends)
```

### 3. Use Batch for TextGrid Workflows

```r
# Extract intervals from TextGrid
tg <- TextGrid("annotations.TextGrid")
intervals <- tg$get_all_intervals(tier = "words")

# Batch extract and analyze
formants <- sound_extract_and_formant(
  sound,
  intervals$start,
  intervals$end
)
```

### 4. Leverage Return Types

```r
# Batch functions support return_r6 parameter
# Set to FALSE to get raw pointers (fastest)
pitch_ptrs <- sound_to_pitch_batch(sounds, return_r6 = FALSE)

# Use with Direct API for maximum speed
stats <- lapply(pitch_ptrs, get_pitch_stats_direct)
```

---

## Function Reference Table

| Function | Input | Output | Use Case |
|----------|-------|--------|----------|
| `sound_to_pitch_batch()` | List of Sounds | List of Pitch | Batch pitch extraction |
| `sound_to_formant_batch()` | List of Sounds | List of Formant | Batch formant extraction |
| `sound_extract_and_pitch()` | Sound + times | List of Pitch | Interval analysis |
| `pitch_get_values_at_times()` | Pitch + times | Numeric vector | F0 tracking |
| `get_formants_at_times()` | Formant + times | List (F1,F2,F3,F4) | Formant tracking |
| `formant_get_values_at_times()` | Formant + times | Numeric vector | Single formant tracking |
| `sound_concatenate_all()` | List of Sounds | Sound | Concatenation |

---

## Troubleshooting

### "Could not extract pointer" Error

This error occurs with legacy code. Update to use function wrappers:

```r
# Old R6 style (may fail)
sound <- Sound$new("file.wav")

# New function wrapper style (always works)
sound <- Sound("file.wav")
```

### NA Values in Results

Batch query functions return NA when measurements fail (e.g., pitch unvoiced):

```r
# Handle NA values appropriately
f0_values <- pitch_get_values_at_times(pitch, times)
f0_clean <- na.omit(f0_values)
mean_f0 <- mean(f0_values, na.rm = TRUE)
```

### Memory Issues with Large Batches

Process in chunks if you run out of memory:

```r
# Process 1000 files in chunks of 100
chunk_size <- 100
n_chunks <- ceiling(length(files) / chunk_size)

results <- list()
for (i in seq_len(n_chunks)) {
  idx_start <- (i - 1) * chunk_size + 1
  idx_end <- min(i * chunk_size, length(files))
  chunk_files <- files[idx_start:idx_end]
  
  results[[i]] <- analyze_files_parallel(chunk_files, analysis_func)
}

all_results <- unlist(results, recursive = FALSE)
```

---

## See Also

- `vignette("performance-optimization")` - Complete performance guide
- `?analyze_files_parallel` - Parallel processing documentation
- `?get_pitch_stats_direct` - Direct API reference
- `PLADDRR_IMPROVEMENT_PLAN.md` - Architecture details
