# pladdrr Performance Enhancement Plan

**Target Version:** pladdrr 2.2.0 or 3.0.0
**Document Date:** 2026-01-08
**Authors:** plabench development team
**Status:** Proposal for pladdrr developers

---

## Executive Summary

This document proposes performance enhancements for pladdrr to reduce the R ↔ C++ boundary crossing overhead that currently makes R implementations 5-20x slower than equivalent Python/Parselmouth code. The proposals focus on **batch operations** and **compound methods** that return multiple values in single C++ calls.

**Current State:** R/pladdrr is 5-20x slower than Python/Parselmouth
**Target State:** R/pladdrr within 2-5x of Python/Parselmouth
**Primary Bottleneck:** R↔C++ boundary crossings in iterative workflows

---

## Table of Contents

1. [Problem Analysis](#1-problem-analysis)
2. [Proposed Enhancements](#2-proposed-enhancements)
   - [2.1 Vectorized TextGrid Interval Extraction](#21-vectorized-textgrid-interval-extraction)
   - [2.2 Compound Statistics Methods](#22-compound-statistics-methods)
   - [2.3 Direct Numeric Vector Access](#23-direct-numeric-vector-access)
   - [2.4 Fix sound_concatenate_all()](#24-fix-sound_concatenate_all)
   - [2.5 Batch Sound Extraction](#25-batch-sound-extraction)
   - [2.6 Combined Analysis Methods](#26-combined-analysis-methods)
3. [Implementation Priority](#3-implementation-priority)
4. [API Specifications](#4-api-specifications)
5. [Testing Requirements](#5-testing-requirements)
6. [Backwards Compatibility](#6-backwards-compatibility)

---

## 1. Problem Analysis

### 1.1 Profiling Results

Profiling plabench R implementations reveals these hotspots:

| Operation | Calls per Analysis | Time per Call | Total % |
|-----------|-------------------|---------------|---------|
| TextGrid interval iteration | 50-500 | ~1ms | 25-40% |
| Pitch/Intensity statistics | 5-20 | ~2ms | 15-25% |
| Sound concatenation | 2-10 | ~5ms | 10-20% |
| as_data_frame() conversion | 3-10 | ~5-20ms | 15-30% |

### 1.2 Root Cause: R↔C++ Boundary Overhead

Each R6 method call incurs:
1. R6 environment dispatch lookup (~20μs)
2. Argument marshaling R→C++ (~10-50μs depending on types)
3. C++ execution (varies)
4. Result marshaling C++→R (~10-100μs depending on result size)
5. R6 result wrapping (~10μs)

**Total overhead: ~50-200μs per call** (vs ~1-10μs for Python/pybind11)

### 1.3 Impact by Workflow

```
AVQI Analysis (current):
├── TextGrid interval extraction: 150 calls × 1ms = 150ms
├── Pitch statistics: 8 calls × 2ms = 16ms
├── as_data_frame(): 5 calls × 15ms = 75ms
├── Sound concatenation: 20 calls × 5ms = 100ms
└── Actual DSP computation: ~200ms
TOTAL: ~540ms (DSP is only 37% of time)

AVQI Analysis (proposed):
├── TextGrid get_all_intervals(): 1 call × 5ms = 5ms
├── Pitch get_statistics(): 1 call × 3ms = 3ms
├── Direct vector access: 5 calls × 1ms = 5ms
├── Sound concatenate_all(): 1 call × 10ms = 10ms
└── Actual DSP computation: ~200ms
TOTAL: ~223ms (DSP is now 90% of time)
```

**Expected improvement: 2.4x faster**

---

## 2. Proposed Enhancements

### 2.1 Vectorized TextGrid Interval Extraction

#### Problem
Current API requires N+1 R↔C++ calls to extract N intervals:

```r
# Current: O(n) R↔C++ calls
n <- textgrid$get_number_of_intervals(tier)  # 1 call
for (i in 1:n) {
  start <- textgrid$get_interval_start_time(tier, i)  # n calls
  end <- textgrid$get_interval_end_time(tier, i)      # n calls
  text <- textgrid$get_interval_text(tier, i)         # n calls
}
# Total: 3n + 1 calls for n intervals
```

#### Proposed Solution

Add `get_all_intervals()` method returning all interval data in single call:

```r
# Proposed: O(1) R↔C++ calls
intervals <- textgrid$get_all_intervals(tier = 1)
# Returns data.frame with columns: start, end, text
# Single C++ call extracts everything
```

#### C++ Implementation Sketch

```cpp
// In TextGrid.cpp
Rcpp::DataFrame TextGrid_get_all_intervals(SEXP textgrid_ptr, int tier) {
    auto tg = Rcpp::XPtr<TextGrid>(textgrid_ptr);

    int n = tg->numberOfIntervals(tier);
    Rcpp::NumericVector starts(n);
    Rcpp::NumericVector ends(n);
    Rcpp::CharacterVector texts(n);

    for (int i = 1; i <= n; i++) {
        starts[i-1] = tg->intervalStartTime(tier, i);
        ends[i-1] = tg->intervalEndTime(tier, i);
        texts[i-1] = tg->intervalText(tier, i);
    }

    return Rcpp::DataFrame::create(
        Rcpp::Named("start") = starts,
        Rcpp::Named("end") = ends,
        Rcpp::Named("text") = texts,
        Rcpp::Named("stringsAsFactors") = false
    );
}
```

#### R6 Method Addition

```r
# In TextGrid R6 class
get_all_intervals = function(tier = 1L) {
  .textgrid_get_all_intervals(private$ptr, as.integer(tier))
}
```

#### Expected Impact
- **AVQI:** 2-3x speedup in voiced segment detection
- **VUV:** 2x speedup in interval processing
- **VQ:** 1.5x speedup in segment iteration

---

### 2.2 Compound Statistics Methods

#### Problem
Extracting multiple statistics requires multiple R↔C++ calls:

```r
# Current: 6 R↔C++ calls for common VUV workflow
q1 <- pitch$get_quantile(0.25, 0, 0, "hertz")
q3 <- pitch$get_quantile(0.75, 0, 0, "hertz")
min_f0 <- pitch$get_minimum(0, 0, "hertz")
max_f0 <- pitch$get_maximum(0, 0, "hertz")
mean_f0 <- pitch$get_mean(0, 0, "hertz")
n_voiced <- pitch$count_voiced_frames()
```

#### Proposed Solution

Add compound statistics method:

```r
# Proposed: 1 R↔C++ call
stats <- pitch$get_statistics(
  from_time = 0,
  to_time = 0,
  unit = "hertz",
  metrics = c("min", "max", "mean", "stdev", "q1", "q3", "median", "count_voiced")
)
# Returns named list: list(min=75.2, max=245.8, mean=142.3, ...)
```

#### C++ Implementation Sketch

```cpp
// In Pitch.cpp
Rcpp::List Pitch_get_statistics(
    SEXP pitch_ptr,
    double from_time,
    double to_time,
    const std::string& unit,
    Rcpp::CharacterVector metrics
) {
    auto pitch = Rcpp::XPtr<Pitch>(pitch_ptr);
    Rcpp::List result;

    // Convert unit string to Praat enum
    int unit_enum = parse_pitch_unit(unit);

    for (int i = 0; i < metrics.size(); i++) {
        std::string metric = Rcpp::as<std::string>(metrics[i]);

        if (metric == "min") {
            result["min"] = Pitch_getMinimum(pitch, from_time, to_time, unit_enum, true);
        } else if (metric == "max") {
            result["max"] = Pitch_getMaximum(pitch, from_time, to_time, unit_enum, true);
        } else if (metric == "mean") {
            result["mean"] = Pitch_getMean(pitch, from_time, to_time, unit_enum);
        } else if (metric == "stdev") {
            result["stdev"] = Pitch_getStandardDeviation(pitch, from_time, to_time, unit_enum);
        } else if (metric == "q1") {
            result["q1"] = Pitch_getQuantile(pitch, from_time, to_time, 0.25, unit_enum);
        } else if (metric == "q3") {
            result["q3"] = Pitch_getQuantile(pitch, from_time, to_time, 0.75, unit_enum);
        } else if (metric == "median") {
            result["median"] = Pitch_getQuantile(pitch, from_time, to_time, 0.50, unit_enum);
        } else if (metric == "count_voiced") {
            result["count_voiced"] = Pitch_countVoicedFrames(pitch);
        }
    }

    return result;
}
```

#### Also Add for Other Classes

```r
# Intensity
stats <- intensity$get_statistics(metrics = c("min", "max", "mean", "stdev"))

# Harmonicity
stats <- harmonicity$get_statistics(metrics = c("mean", "stdev", "min", "max"))

# PointProcess
stats <- pointprocess$get_statistics(
  metrics = c("mean_period", "stdev_period", "jitter_local", "jitter_ppq5", "jitter_rap")
)
```

#### Expected Impact
- **VUV:** 40-50% speedup (quartile extraction is main bottleneck)
- **DSI:** 20-30% speedup
- **All tools:** 10-20% general improvement

---

### 2.3 Direct Numeric Vector Access

#### Problem
`as_data_frame()` creates full data.frame with overhead:

```r
# Current: Creates data.frame, copies twice
df <- pitch$as_data_frame()  # ~15ms for 1000 frames
values <- df$frequency       # Extract column

# Or via .cpp$ (better but still creates intermediate)
n <- pitch$.cpp$nx
```

#### Proposed Solution

Add direct vector accessors that return numeric vectors without data.frame wrapping:

```r
# Proposed: Direct numeric vector, minimal overhead
times <- pitch$get_times_vector()      # NumericVector, ~0.5ms
values <- pitch$get_values_vector()    # NumericVector, ~0.5ms

# Or as active binding
times <- pitch$.times   # Direct access
values <- pitch$.values
```

#### C++ Implementation Sketch

```cpp
// In Pitch.cpp
Rcpp::NumericVector Pitch_get_values_vector(SEXP pitch_ptr) {
    auto pitch = Rcpp::XPtr<Pitch>(pitch_ptr);
    int n = pitch->nx;

    Rcpp::NumericVector values(n);
    for (int i = 1; i <= n; i++) {
        // Get F0 value, NA for unvoiced
        double f0 = Pitch_getValueAtIndex(pitch, i, kPitch_unit_HERTZ);
        values[i-1] = (f0 == undefined) ? NA_REAL : f0;
    }

    return values;
}

Rcpp::NumericVector Pitch_get_times_vector(SEXP pitch_ptr) {
    auto pitch = Rcpp::XPtr<Pitch>(pitch_ptr);
    int n = pitch->nx;

    Rcpp::NumericVector times(n);
    for (int i = 1; i <= n; i++) {
        times[i-1] = Sampled_indexToX(pitch, i);
    }

    return times;
}
```

#### Also Add for Other Classes

```r
# Sound
samples <- sound$get_samples_vector(channel = 1)
times <- sound$get_times_vector()

# Intensity
values <- intensity$get_values_vector()
times <- intensity$get_times_vector()

# Spectrum
real_parts <- spectrum$get_real_vector()
imag_parts <- spectrum$get_imaginary_vector()
frequencies <- spectrum$get_frequencies_vector()
```

#### Expected Impact
- **Tremor:** 30-40% speedup (heavy contour processing)
- **AVQI v3.01:** 25-35% speedup (windowed power calculation)
- **VQ:** 20-30% speedup

---

### 2.4 Fix sound_concatenate_all()

#### Problem
Current `sound_concatenate_all()` doesn't accept Sound R6 objects:

```r
# Documented API (doesn't work)
sounds <- list(sound1, sound2, sound3)
combined <- sound_concatenate_all(sounds)
# Error: expects external pointers, not R6 objects

# Current workaround: sequential concatenation
combined <- sounds[[1]]
for (i in 2:length(sounds)) {
  combined <- combined$concatenate(sounds[[i]])  # N-1 R↔C++ calls
}
```

#### Proposed Solution

Fix to accept both R6 objects and raw pointers:

```r
# Should work with R6 objects
sounds <- list(sound1, sound2, sound3)
combined <- sound_concatenate_all(sounds)  # Single C++ call

# Also support extracting from list of files
combined <- sound_concatenate_files(c("file1.wav", "file2.wav", "file3.wav"))
```

#### C++ Implementation Fix

```cpp
// In Sound.cpp
SEXP sound_concatenate_all(Rcpp::List sounds) {
    // Handle both R6 objects and raw pointers
    std::vector<Sound> sound_ptrs;

    for (int i = 0; i < sounds.size(); i++) {
        SEXP item = sounds[i];

        if (Rf_isEnvironment(item)) {
            // R6 object - extract pointer from private$ptr or .xptr
            Rcpp::Environment env(item);
            SEXP ptr;

            // Try .xptr field first (pladdrr convention)
            if (env.exists(".xptr")) {
                ptr = env[".xptr"];
            } else {
                // Try private$ptr via .__enclos_env__
                Rcpp::Environment enclos = env[".__enclos_env__"];
                Rcpp::Environment priv = enclos["private"];
                ptr = priv["ptr"];
            }

            sound_ptrs.push_back(Rcpp::XPtr<Sound>(ptr));
        } else if (TYPEOF(item) == EXTPTRSXP) {
            // Raw external pointer
            sound_ptrs.push_back(Rcpp::XPtr<Sound>(item));
        } else {
            Rcpp::stop("Element %d is not a Sound object or pointer", i + 1);
        }
    }

    // Concatenate all sounds
    autoSound result = Sounds_concatenate(sound_ptrs, 0.0);

    return wrap_sound(result.move());
}
```

#### Expected Impact
- **DSI:** 15-25% speedup (concatenates 4 file types)
- **AVQI:** 20-30% speedup (concatenates many voiced segments)

---

### 2.5 Batch Sound Extraction

#### Problem
Extracting multiple segments requires multiple R↔C++ calls:

```r
# Current: N R↔C++ calls for N segments
segments <- lapply(1:n, function(i) {
  sound$extract_part(starts[i], ends[i], "rectangular", 1, FALSE)
})
```

#### Proposed Solution

Add batch extraction method:

```r
# Proposed: 1 R↔C++ call for N segments
segments <- sound$extract_parts_batch(
  starts = c(0.5, 1.2, 2.1),
  ends = c(0.8, 1.5, 2.4),
  window_shape = "rectangular"
)
# Returns list of Sound objects
```

#### C++ Implementation Sketch

```cpp
// In Sound.cpp
Rcpp::List Sound_extract_parts_batch(
    SEXP sound_ptr,
    Rcpp::NumericVector starts,
    Rcpp::NumericVector ends,
    const std::string& window_shape,
    double relative_width,
    bool preserve_times
) {
    auto sound = Rcpp::XPtr<Sound>(sound_ptr);
    int n = starts.size();

    Rcpp::List result(n);

    for (int i = 0; i < n; i++) {
        autoSound part = Sound_extractPart(
            sound, starts[i], ends[i],
            parse_window_shape(window_shape),
            relative_width, preserve_times
        );
        result[i] = wrap_sound(part.move());
    }

    return result;
}
```

#### Expected Impact
- **AVQI v2.03:** 30-40% speedup (extracts 50-200 voiced segments)
- **VQ:** 20-30% speedup (extracts segments per interval)

---

### 2.6 Combined Analysis Methods

#### Problem
Common workflows require creating multiple intermediate objects:

```r
# Current VUV workflow: 4 R↔C++ calls + object creation
pitch <- sound$to_pitch_cc(...)           # Create Pitch
pp <- pitch$to_point_process()            # Create PointProcess
mean_period <- pp$get_mean_period(...)    # Query
tg <- pitch$to_textgrid_vuv()             # Create TextGrid
```

#### Proposed Solution

Add combined methods for common workflows:

```r
# Proposed: Single call for VUV analysis
vuv_result <- sound$analyze_vuv(
  time_step = 0.005,
  pitch_floor = 50,
  pitch_ceiling = 800,
  ...
)
# Returns list with:
#   textgrid: TextGrid with VUV tier
#   pitch: Pitch object (if requested)
#   mean_period: numeric
#   statistics: list of pitch stats
```

```r
# Proposed: Single call for jitter/shimmer
perturbation <- sound$analyze_perturbation(
  pitch_floor = 75,
  pitch_ceiling = 600,
  metrics = c("jitter_local", "jitter_ppq5", "shimmer_local", "shimmer_db")
)
# Returns named list of all requested metrics
```

#### C++ Implementation Sketch

```cpp
// In Sound.cpp
Rcpp::List Sound_analyze_perturbation(
    SEXP sound_ptr,
    double pitch_floor,
    double pitch_ceiling,
    Rcpp::CharacterVector metrics,
    double period_floor,
    double period_ceiling,
    double max_period_factor,
    double max_amplitude_factor
) {
    auto sound = Rcpp::XPtr<Sound>(sound_ptr);

    // Create PointProcess internally (not returned to R)
    autoPointProcess pp = Sound_to_PointProcess_periodic_cc(
        sound, pitch_floor, pitch_ceiling
    );

    Rcpp::List result;

    for (int i = 0; i < metrics.size(); i++) {
        std::string metric = Rcpp::as<std::string>(metrics[i]);

        if (metric == "jitter_local") {
            result["jitter_local"] = PointProcess_getJitter_local(
                pp.get(), 0, 0, period_floor, period_ceiling, max_period_factor
            );
        } else if (metric == "jitter_ppq5") {
            result["jitter_ppq5"] = PointProcess_getJitter_ppq5(
                pp.get(), 0, 0, period_floor, period_ceiling, max_period_factor
            );
        } else if (metric == "shimmer_local") {
            result["shimmer_local"] = PointProcess_Sound_getShimmer_local(
                pp.get(), sound, 0, 0, period_floor, period_ceiling,
                max_period_factor, max_amplitude_factor
            );
        } else if (metric == "shimmer_db") {
            result["shimmer_db"] = PointProcess_Sound_getShimmer_local_dB(
                pp.get(), sound, 0, 0, period_floor, period_ceiling,
                max_period_factor, max_amplitude_factor
            );
        }
        // ... other metrics
    }

    return result;
}
```

#### Expected Impact
- **VQ:** 40-50% speedup (currently creates many intermediate objects)
- **DSI:** 30-40% speedup (jitter calculation workflow)

---

## 3. Implementation Priority

### Priority 1: Critical (2.0x+ expected impact)

| Enhancement | Estimated Effort | Expected Speedup | Affected Tools |
|-------------|------------------|------------------|----------------|
| 2.1 `get_all_intervals()` | 2-3 days | 2-3x | AVQI, VUV, VQ |
| 2.4 Fix `sound_concatenate_all()` | 1-2 days | 1.5x | DSI, AVQI |

### Priority 2: High (1.3-1.5x expected impact)

| Enhancement | Estimated Effort | Expected Speedup | Affected Tools |
|-------------|------------------|------------------|----------------|
| 2.2 `get_statistics()` | 3-4 days | 1.3-1.5x | All |
| 2.3 Direct vector access | 2-3 days | 1.3-1.4x | Tremor, AVQI |

### Priority 3: Medium (1.2-1.3x expected impact)

| Enhancement | Estimated Effort | Expected Speedup | Affected Tools |
|-------------|------------------|------------------|----------------|
| 2.5 Batch extraction | 2-3 days | 1.2-1.3x | AVQI, VQ |
| 2.6 Combined methods | 4-5 days | 1.3-1.4x | VQ, DSI |

---

## 4. API Specifications

### 4.1 TextGrid Methods

```r
# NEW: Get all intervals from a tier
textgrid$get_all_intervals(tier = 1L)
# Returns: data.frame(start = numeric, end = numeric, text = character)

# NEW: Get all point times from a tier
textgrid$get_all_points(tier = 1L)
# Returns: data.frame(time = numeric, text = character)
```

### 4.2 Pitch Methods

```r
# NEW: Get multiple statistics in single call
pitch$get_statistics(
  from_time = 0,
  to_time = 0,
  unit = "hertz",
  metrics = c("min", "max", "mean", "stdev", "q1", "q3", "median", "count_voiced")
)
# Returns: named list

# NEW: Get all F0 values as vector
pitch$get_values_vector(unit = "hertz")
# Returns: NumericVector (NA for unvoiced frames)

# NEW: Get all frame times as vector
pitch$get_times_vector()
# Returns: NumericVector
```

### 4.3 Intensity Methods

```r
# NEW: Get statistics
intensity$get_statistics(
  from_time = 0,
  to_time = 0,
  metrics = c("min", "max", "mean", "stdev")
)

# NEW: Direct vector access
intensity$get_values_vector()
intensity$get_times_vector()
```

### 4.4 Sound Methods

```r
# NEW: Batch segment extraction
sound$extract_parts_batch(
  starts = numeric_vector,
  ends = numeric_vector,
  window_shape = "rectangular",
  relative_width = 1.0,
  preserve_times = FALSE
)
# Returns: list of Sound objects

# NEW: Combined perturbation analysis
sound$analyze_perturbation(
  pitch_floor = 75,
  pitch_ceiling = 600,
  metrics = c("jitter_local", "jitter_ppq5", "shimmer_local", "shimmer_db", ...),
  period_floor = 0.0001,
  period_ceiling = 0.02,
  max_period_factor = 1.3,
  max_amplitude_factor = 1.6
)
# Returns: named list of metrics

# FIXED: Accept R6 objects
sound_concatenate_all(sounds)
# Now accepts: list of Sound R6 objects OR list of external pointers
```

### 4.5 PointProcess Methods

```r
# NEW: Get all perturbation metrics
pointprocess$get_perturbation_metrics(
  sound = NULL,  # Required for shimmer
  from_time = 0,
  to_time = 0,
  metrics = c("jitter_local", "jitter_ppq5", "shimmer_local", ...),
  period_floor = 0.0001,
  period_ceiling = 0.02,
  max_period_factor = 1.3,
  max_amplitude_factor = 1.6
)
# Returns: named list
```

---

## 5. Testing Requirements

### 5.1 Unit Tests for Each Enhancement

```r
# Test get_all_intervals()
test_that("get_all_intervals returns correct data", {
  tg <- TextGrid("test.TextGrid")
  intervals <- tg$get_all_intervals(1)

  expect_s3_class(intervals, "data.frame")
  expect_equal(names(intervals), c("start", "end", "text"))
  expect_equal(nrow(intervals), tg$get_number_of_intervals(1))

  # Verify values match individual calls
  for (i in 1:nrow(intervals)) {
    expect_equal(intervals$start[i], tg$get_interval_start_time(1, i))
    expect_equal(intervals$end[i], tg$get_interval_end_time(1, i))
    expect_equal(intervals$text[i], tg$get_interval_text(1, i))
  }
})

# Test get_statistics()
test_that("get_statistics returns correct values", {
  pitch <- sound$to_pitch_cc(0, 75, 600)
  stats <- pitch$get_statistics(metrics = c("min", "max", "mean", "q1", "q3"))

  expect_type(stats, "list")
  expect_equal(stats$min, pitch$get_minimum(0, 0, "hertz"), tolerance = 1e-10)
  expect_equal(stats$max, pitch$get_maximum(0, 0, "hertz"), tolerance = 1e-10)
  expect_equal(stats$mean, pitch$get_mean(0, 0, "hertz"), tolerance = 1e-10)
})

# Test sound_concatenate_all() with R6 objects
test_that("sound_concatenate_all accepts R6 objects", {
  s1 <- Sound("test1.wav")
  s2 <- Sound("test2.wav")

  combined <- sound_concatenate_all(list(s1, s2))

  expect_s3_class(combined, "Sound")
  expected_duration <- s1$.cpp$duration + s2$.cpp$duration
  expect_equal(combined$.cpp$duration, expected_duration, tolerance = 0.001)
})
```

### 5.2 Performance Benchmarks

```r
# Benchmark get_all_intervals vs individual calls
bench::mark(
  individual = {
    n <- tg$get_number_of_intervals(1)
    starts <- numeric(n)
    ends <- numeric(n)
    texts <- character(n)
    for (i in 1:n) {
      starts[i] <- tg$get_interval_start_time(1, i)
      ends[i] <- tg$get_interval_end_time(1, i)
      texts[i] <- tg$get_interval_text(1, i)
    }
  },
  batch = {
    intervals <- tg$get_all_intervals(1)
  },
  check = FALSE
)
# Expected: batch should be 5-20x faster
```

### 5.3 Numerical Validation

All new methods must produce results identical to existing individual methods:

```r
# Validation test
validate_statistics <- function(pitch) {
  stats <- pitch$get_statistics(metrics = c("min", "max", "mean", "stdev"))

  expect_equal(stats$min, pitch$get_minimum(0, 0, "hertz"))
  expect_equal(stats$max, pitch$get_maximum(0, 0, "hertz"))
  expect_equal(stats$mean, pitch$get_mean(0, 0, "hertz"))
  expect_equal(stats$stdev, pitch$get_standard_deviation(0, 0, "hertz"))
}
```

---

## 6. Backwards Compatibility

### 6.1 No Breaking Changes

All proposed enhancements are **additive**:
- New methods added to existing classes
- Existing methods remain unchanged
- No changes to method signatures

### 6.2 Deprecation Path (if needed)

If any existing behavior must change:

```r
# Example deprecation warning
get_old_method <- function(...) {
  .Deprecated("get_new_method",
              msg = "get_old_method() is deprecated. Use get_new_method() instead.")
  # ... existing implementation
}
```

### 6.3 Version Requirements

- **Minimum R:** 4.0.0 (for native pipe support in examples)
- **Minimum Rcpp:** 1.0.0
- **Praat version:** No changes required (uses existing Praat C API)

---

## Appendix A: Benchmark Data

### Current plabench Performance (pladdrr 2.1.2)

| Tool | Python (s) | R (s) | R/Python Ratio |
|------|------------|-------|----------------|
| DSI | 0.12 | 0.98 | 7.5x |
| AVQI v2.03 | 0.39 | 7.48 | 18.9x |
| AVQI v3.01 | 2.06 | 6.19 | 3.0x |
| Tremor | 0.05 | 0.30 | 6.8x |
| VUV | 0.02 | 0.36 | 17.9x |
| VQ | 1.86 | 3.06 | 1.6x |

### Expected Performance After Enhancements

| Tool | Current R (s) | Expected R (s) | Expected Improvement |
|------|---------------|----------------|---------------------|
| DSI | 0.98 | 0.45 | 2.2x |
| AVQI v2.03 | 7.48 | 2.5 | 3.0x |
| AVQI v3.01 | 6.19 | 3.0 | 2.1x |
| Tremor | 0.30 | 0.15 | 2.0x |
| VUV | 0.36 | 0.10 | 3.6x |
| VQ | 3.06 | 1.5 | 2.0x |

---

## Appendix B: Related Issues/PRs

- [ ] Issue: `sound_concatenate_all()` doesn't accept R6 objects
- [ ] Feature request: Vectorized TextGrid interval extraction
- [ ] Feature request: Compound statistics methods
- [ ] Feature request: Direct numeric vector access

---

## Contact

For questions about this proposal:
- **plabench repository:** https://github.com/humlab-speech/plabench
- **Test cases:** Available in `tests/test_3way_validation.py`

---

**Document Version:** 1.0
**Last Updated:** 2026-01-08
