# pladdrr Development Recommendations

**To:** pladdrr Development Team  
**From:** plabench Performance Optimization Project  
**Date:** 2026-01-06  
**pladdrr Version Tested:** 2.0.4  
**Test Platform:** macOS ARM64 (NEON SIMD enabled)

---

## Executive Summary

We conducted comprehensive performance optimization work on clinical voice analysis tools (DSI, AVQI, Tremor, VUV, VQ, Pharyngeal) implemented using pladdrr 2.0.4. Despite implementing multiple algorithmic optimizations, R implementations remain **5-56x slower** than equivalent Python/Parselmouth implementations, despite both using the same Praat C codebase.

This document provides detailed findings and actionable recommendations to help pladdrr achieve better performance parity with Parselmouth.

**Key Finding:** The performance gap is primarily due to:
1. R language overhead (R6 dispatch, data frame operations, boundary crossings)
2. Missing optimization opportunities in pladdrr API design
3. One critical bug in batch concatenation function
4. Lack of fast-path APIs for common workflows

---

## 🐛 Critical Bugs Discovered

### Bug #1: `sound_concatenate_all()` Fails with Sound Objects

**Status:** 🔴 **CRITICAL** - Documented API does not work

**Description:**
The `sound_concatenate_all()` function is documented to accept "List of Sound objects (R6) or external pointers" but fails when passed Sound R6 objects.

**Reproduction:**
```r
library(pladdrr)

# Load two sounds
s1 <- Sound("file1.wav")
s2 <- Sound("file2.wav")

# This SHOULD work according to documentation
result <- sound_concatenate_all(list(s1, s2))
# Error in .sound_concatenate_all(xptrs, overlap) : 
#   Expecting an external pointer: [type=NULL].
```

**Root Cause:**
The internal `.sound_concatenate_all()` function appears to extract `.xptr` from Sound objects incorrectly, getting NULL instead of the actual external pointer.

**Expected Behavior:**
Should accept Sound R6 objects and automatically extract their pointers.

**Current Workaround:**
Users must use sequential concatenation:
```r
result <- s1$concatenate(s2)  # Slow, O(n) boundary crossings
```

**Impact:**
- 10-20% performance penalty for multi-file operations
- DSI, AVQI, VUV, VQ all concatenate multiple files
- Forces suboptimal sequential concatenation pattern

**Suggested Fix:**
```r
# In sound_concatenate_all() function
sound_concatenate_all <- function(sounds, overlap = 0, return_r6 = TRUE) {
  # Extract xptrs robustly
  xptrs <- lapply(sounds, function(s) {
    if (inherits(s, "Sound")) {
      # Try multiple extraction methods
      ptr <- s$.xptr
      if (is.null(ptr)) ptr <- s$get_xptr()
      if (is.null(ptr) && ".cpp" %in% names(s)) ptr <- s$.cpp
      return(ptr)
    } else {
      return(s)  # Already an xptr
    }
  })
  .sound_concatenate_all(xptrs, overlap)
}
```

**Test Case Needed:**
```r
test_that("sound_concatenate_all accepts Sound objects", {
  s1 <- Sound("test1.wav")
  s2 <- Sound("test2.wav")
  
  # Should not error
  result <- sound_concatenate_all(list(s1, s2))
  
  expect_s3_class(result, "Sound")
  expect_equal(result$get_duration(), s1$get_duration() + s2$get_duration())
})
```

---

## 🚀 Missing Optimization Opportunities

### Opportunity #1: Direct Numeric Vector Access

**Priority:** 🔴 **HIGH** - Would provide 20-30% speedup for signal processing code

**Problem:**
Currently, accessing sample values requires creating a full data frame:
```r
sound <- Sound("vowel.wav")
df <- sound$as_data_frame()  # ❌ Creates full data frame with copy
values <- df$value            # Extract values column
times <- df$time              # Extract times column
```

**Performance Impact:**
- `as_data_frame()` creates full R data frame (memory allocation + copy)
- Includes row names, column names, attributes
- Type checking and coercion
- Called repeatedly in tight loops (e.g., AVQI v3.01: ~100-300 times)

**Comparison to Python/Parselmouth:**
```python
sound = parselmouth.Sound("vowel.wav")
values = sound.values[0]  # ✅ Zero-copy numpy array view
times = sound.ts()        # Direct access, minimal overhead
```

**Proposed API:**
```r
# Fast path: Direct numeric vector (no data frame overhead)
sound$get_values()        # Returns numeric vector of sample values
sound$get_sample_times()  # Returns numeric vector of time points

# Or maintain naming consistency:
sound$as_numeric_vector()  # Sample values
sound$get_times()          # Time vector

# Advanced: Channel selection for stereo
sound$get_values(channel = 1)
sound$get_values(channel = 2)
```

**Implementation Notes:**
- Should return R numeric vectors with minimal copying
- Consider using `Rcpp::NumericVector` for zero-copy where possible
- Add `start_time` and `end_time` parameters for partial extraction
- Cache time vector since it's derived from metadata (start, duration, sampling_rate)

**Expected Impact:**
- AVQI v3.01: 20-30% faster (eliminates data frame overhead in windowing loop)
- VQ: 15-20% faster (multiple sample access operations)
- All tools with signal processing: 10-20% faster

**Test Case:**
```r
test_that("get_values returns correct sample data", {
  sound <- Sound("test.wav")
  
  # Direct vector access
  values <- sound$get_values()
  times <- sound$get_sample_times()
  
  # Compare with data frame method
  df <- sound$as_data_frame()
  expect_equal(values, df$value)
  expect_equal(times, df$time)
  
  # Should be much faster
  bench <- microbenchmark(
    direct = sound$get_values(),
    dataframe = sound$as_data_frame()$value,
    times = 100
  )
  expect_lt(median(bench$time[bench$expr == "direct"]), 
            median(bench$time[bench$expr == "dataframe"]) * 0.5)
})
```

---

### Opportunity #2: Batch Statistics Methods

**Priority:** 🟡 **MEDIUM** - Would provide 10-15% speedup for multi-statistic queries

**Problem:**
Common workflows need multiple statistics from same object, requiring multiple R ↔ C++ crossings:

```r
# Current: Multiple method calls (slow)
pitch <- sound$to_pitch_cc(...)
max_f0 <- pitch$get_maximum(0, 0, "Hertz")    # Call 1
mean_f0 <- pitch$get_mean(0, 0, "Hertz")      # Call 2  
min_f0 <- pitch$get_minimum(0, 0, "Hertz")    # Call 3
stdev_f0 <- pitch$get_standard_deviation(0, 0, "Hertz")  # Call 4
# 4 R→C++ boundary crossings, each with dispatch overhead
```

**Python/Parselmouth has no advantage here** - same issue exists. This is an opportunity for pladdrr to be BETTER than Parselmouth!

**Proposed API:**
```r
# Batch statistics: Single C++ call
pitch <- sound$to_pitch_cc(...)
stats <- pitch$get_statistics(
  from_time = 0,
  to_time = 0,
  unit = "Hertz",
  metrics = c("minimum", "maximum", "mean", "stdev")
)
# Returns: list(minimum = 75.2, maximum = 245.3, mean = 156.8, stdev = 42.1)

# Or even better: Bundle pitch creation + statistics
stats <- sound$pitch_statistics_cc(
  time_step = 0,
  pitch_floor = 70,
  pitch_ceiling = 600,
  metrics = c("minimum", "maximum", "mean", "stdev")
)
# Single R→C++ call, pitch object not kept in memory
```

**Objects to support:**
- `Pitch$get_statistics()` - min, max, mean, stdev, median, quantiles
- `Intensity$get_statistics()` - min, max, mean, stdev
- `Formant$get_statistics()` - statistics per formant (F1, F2, F3, F4)
- `Harmonicity$get_statistics()` - mean, stdev, min, max HNR

**Expected Impact:**
- DSI: 10-15% faster (pitch statistics + intensity statistics)
- VQ: 10-12% faster (multiple HNR band statistics)
- All tools: Reduced method call overhead

**Implementation Notes:**
```cpp
// In C++ binding
List Pitch::get_statistics(
    double from_time, 
    double to_time, 
    const std::string& unit,
    const std::vector<std::string>& metrics
) {
    List result;
    
    // Single traversal of Pitch frames for all metrics
    for (const auto& metric : metrics) {
        if (metric == "minimum") {
            result[metric] = Pitch_getMinimum(this->ptr, from_time, to_time, unit);
        } else if (metric == "maximum") {
            result[metric] = Pitch_getMaximum(this->ptr, from_time, to_time, unit);
        }
        // ... etc
    }
    
    return result;
}
```

---

### Opportunity #3: Fast Interval Extraction from TextGrid

**Priority:** 🟡 **MEDIUM** - Would provide 15-20% speedup for TextGrid-based analysis

**Problem:**
Extracting intervals matching criteria requires manual R loops:

```r
# Current: Manual loop (slow)
textgrid <- point_process$to_textgrid_vuv(...)
n_intervals <- textgrid$get_number_of_intervals(1)

voiced_sounds <- list()
for (i in 1:n_intervals) {
  text <- textgrid$get_interval_text(1, i)  # R→C++ call
  if (text == "V") {
    start <- textgrid$get_interval_start_time(1, i)  # R→C++ call
    end <- textgrid$get_interval_end_time(1, i)      # R→C++ call
    part <- sound$extract_part(start, end, "rectangular", 1, FALSE)
    voiced_sounds <- c(voiced_sounds, list(part))
  }
}
# Total: 3n R→C++ calls for n intervals
```

**Python/Parselmouth Solution:**
```python
# Batch extraction with Praat call
intervals = parselmouth.praat.call(
    [sound, textgrid], 
    "Extract intervals where", 
    1,        # tier
    "no",     # preserve times
    "is equal to", 
    "V"       # criterion
)
voiced_sound = parselmouth.praat.call(intervals, "Concatenate")
# 2 Praat calls total (batch operations)
```

**Proposed pladdrr API:**
```r
# Option 1: TextGrid method
intervals <- textgrid$extract_intervals_where(
  tier_number = 1,
  comparison = "is equal to",  # or "contains", "matches regex"
  value = "V"
)
# Returns: list of data frames with (start, end, text)

# Option 2: Sound + TextGrid method (even better)
voiced_parts <- sound$extract_intervals(
  textgrid = textgrid,
  tier_number = 1,
  text_matches = "V"
)
# Returns: list of Sound objects

# Option 3: Extract and concatenate in one call
voiced_sound <- sound$extract_and_concatenate_intervals(
  textgrid = textgrid,
  tier_number = 1,
  text_matches = "V"
)
# Returns: Single concatenated Sound object
```

**Use Cases:**
- DSI: Extract voiced intervals (text == "V")
- AVQI: Extract sounding intervals (text != "silent")
- VQ: Extract labeled phoneme intervals
- Pharyngeal: Extract specific phoneme types

**Expected Impact:**
- DSI: 15-20% faster (voiced interval extraction)
- AVQI v2.03: 10-15% faster (sounding interval extraction)
- VQ: 10-12% faster (interval-based analysis)

**Implementation Notes:**
```cpp
// C++ implementation
List Sound::extract_intervals(
    const TextGrid& textgrid,
    int tier_number,
    const std::string& text_matches
) {
    List result;
    int n_intervals = TextGrid_numberOfIntervals(textgrid.ptr, tier_number);
    
    for (int i = 1; i <= n_intervals; i++) {
        const char* text = TextGrid_getIntervalText(textgrid.ptr, tier_number, i);
        if (strcmp(text, text_matches.c_str()) == 0) {
            double start = TextGrid_getIntervalStartTime(textgrid.ptr, tier_number, i);
            double end = TextGrid_getIntervalEndTime(textgrid.ptr, tier_number, i);
            
            Sound* part = Sound_extractPart(this->ptr, start, end, 
                                           kSound_windowShape::RECTANGULAR, 
                                           1.0, false);
            result.push_back(wrap_sound(part));
        }
    }
    
    return result;
}
```

---

### Opportunity #4: Combined Pitch + Harmonicity Extraction

**Priority:** 🟢 **LOW** - Would provide 5-10% speedup for voice quality analysis

**Problem:**
Many voice quality measures need both pitch and harmonicity from same sound:

```r
# Current: Two separate analyses
pitch <- sound$to_pitch_cc(...)         # Full pitch analysis
harmonicity <- sound$to_harmonicity_cc(...) # Full harmonicity analysis (redundant work)
```

**Optimization:**
Both use autocorrelation - can share computation:

```r
# Proposed: Combined extraction
result <- sound$to_pitch_and_harmonicity_cc(
  time_step = 0.01,
  pitch_floor = 75,
  pitch_ceiling = 600,
  # ... pitch params ...
  periods_per_window = 1.0  # harmonicity param
)
# Returns: list(pitch = Pitch object, harmonicity = Harmonicity object)
```

**Use Cases:**
- AVQI: Needs pitch for point process + harmonicity for HNR
- VQ: Calculates both pitch and harmonicity-based measures
- DSI: Uses pitch for multiple operations

**Expected Impact:**
- AVQI: 5-8% faster
- VQ: 5-10% faster
- Reduced redundant autocorrelation computation

---

### Opportunity #5: Window-Based Power Calculation

**Priority:** 🟢 **LOW** - Would provide 5-10% speedup for windowed analysis

**Problem:**
AVQI v3.01 extracts 100-300 windows and calculates power for each:

```r
# Current: Create Sound object for each window
for (i in 1:num_windows) {
  window_part <- sound$extract_part(from_times[i], to_times[i], ...)  # Slow
  partial_power <- window_part$get_power()  # Another call
}
```

**Proposed API:**
```r
# Option 1: Calculate power directly from window bounds
window_powers <- sound$get_window_powers(
  window_starts = from_times,
  window_ends = to_times
)
# Returns: numeric vector of power values (one per window)

# Option 2: Sliding window statistics
stats <- sound$sliding_window_statistics(
  window_width = 0.03,      # 30ms
  window_shift = 0.03,      # No overlap
  metrics = c("power", "zcr", "energy")
)
# Returns: data frame with columns: time, power, zcr, energy
```

**Use Cases:**
- AVQI v3.01: Windowed power + ZCR filtering
- Voice activity detection
- Spectral analysis with overlapping windows

**Expected Impact:**
- AVQI v3.01: 5-10% faster
- Custom signal processing workflows

---

### Opportunity #6: Formant Tracking with Time Selection

**Priority:** 🟢 **LOW** - Correctness issue (reference mismatch)

**Problem:**
Current formant tracking API doesn't expose window width parameter that affects tracking behavior:

```r
# Current
formant <- sound$to_formant_burg(
  time_step = 0,
  max_formants = 5,
  max_frequency = 5500,
  window_length = 0.025,  # This parameter exists
  pre_emphasis = 50
)

# But tracking vs non-tracking is determined by window_length
# Users can't easily replicate Praat's "Get formant at time" 
# which uses different algorithm than formant tracking
```

**Request:**
Document the relationship between window_length and tracking behavior more clearly, or expose separate methods:

```r
# For single-point queries (no tracking)
f1 <- sound$get_formant_at_time(
  time = 0.5,
  formant_number = 1,
  max_formants = 5,
  max_frequency = 5500,
  window_length = 0.04  # Gaussian window width
)

# For tracking over time
formant <- sound$to_formant_burg(
  time_step = 0.005,  # Small step = tracking
  # ...
)
```

**Context:**
We discovered formant reference mismatches were due to different algorithms (tracking vs single-point), not calculation errors. Better API would prevent user confusion.

---

## 🏗️ Architectural Recommendations

### Recommendation #1: Consider Rcpp-Based Implementation Alternative

**Priority:** 🔴 **HIGH** - Could provide 2-3x overall speedup

**Current Architecture:**
```
R function call
  → R6 environment lookup
  → R6 method dispatch
  → Find C++ wrapper function
  → Call C++ via .Call()
  → Return to R6
  → Wrap result in R6 object
```

**Proposed Rcpp Architecture:**
```
R function call
  → Rcpp S4 method dispatch (compiled)
  → Direct C++ call
  → Return wrapped result
```

**Performance Comparison:**
```r
# Benchmark: R6 vs Rcpp dispatch
library(microbenchmark)

# R6 (current)
sound_r6 <- Sound("test.wav")
microbenchmark(sound_r6$get_duration(), times = 1000)
# Median: ~15-20 microseconds

# Hypothetical Rcpp S4
sound_s4 <- SoundS4("test.wav")
microbenchmark(duration(sound_s4), times = 1000)
# Expected median: ~5-8 microseconds
```

**Trade-offs:**
- **Pro:** 2-3x faster method dispatch
- **Pro:** Better memory management (ref counting)
- **Pro:** More familiar to R package developers
- **Con:** Larger rewrite effort
- **Con:** S4 is less flexible than R6 for inheritance

**Suggestion:**
- Prototype Rcpp implementation for Sound class
- Benchmark against R6 implementation
- If 2x+ faster, consider migrating

**Example Rcpp Skeleton:**
```cpp
// [[Rcpp::export]]
SEXP sound_create(std::string path) {
    Sound* sound = Sound_readFromFile(path.c_str());
    Rcpp::XPtr<Sound> ptr(sound, true);
    return ptr;
}

// [[Rcpp::export]]
double sound_duration(SEXP xptr) {
    Rcpp::XPtr<Sound> ptr(xptr);
    return Sound_getTotalDuration(ptr);
}
```

---

### Recommendation #2: Zero-Copy Data Access

**Priority:** 🟡 **MEDIUM** - Would eliminate memory allocation overhead

**Current Behavior:**
```r
# Every data access creates new R vector
values <- sound$as_data_frame()$value  # Full copy
```

**Proposed:**
Expose C++ data directly using Rcpp's memory-mapped vectors:

```cpp
// [[Rcpp::export]]
Rcpp::NumericVector sound_get_values_zerocopy(SEXP xptr) {
    Rcpp::XPtr<Sound> ptr(xptr);
    
    // Get direct pointer to Praat's sample data
    double* samples = Sound_getSamples(ptr);
    int n_samples = Sound_getNumberOfSamples(ptr);
    
    // Wrap without copying (Rcpp will handle lifetime)
    return Rcpp::NumericVector(samples, samples + n_samples, false);
}
```

**Safety Considerations:**
- Document that returned vector is invalidated if Sound object is modified
- Consider copy-on-write semantics
- Add memory protection guards

**Expected Impact:**
- 20-30% faster for signal processing workflows
- Reduced memory usage for large files

---

### Recommendation #3: Compiled Fast Paths for Common Workflows

**Priority:** 🟡 **MEDIUM** - Pre-built workflow functions

**Concept:**
Create C++-level implementations of common analysis workflows:

```r
# Instead of multiple R calls:
sound <- Sound("vowel.wav")
pitch <- sound$to_pitch_cc(...)
max_f0 <- pitch$get_maximum(0, 0, "Hertz")

# Single compiled workflow:
max_f0 <- sound$get_max_pitch_cc(
  pitch_floor = 70,
  pitch_ceiling = 600
)
# Everything happens in C++, only final result returned
```

**Workflows to implement:**
```r
# Voice quality bundle
vq_results <- sound$voice_quality_report(
  pitch_floor = 75,
  pitch_ceiling = 600,
  periods_per_window = 1.0
)
# Returns: list with jitter, shimmer, HNR, etc.

# Formant statistics
formant_stats <- sound$formant_statistics(
  time_start = 0.2,
  time_end = 0.8,
  formants = c(1, 2, 3, 4)
)
# Returns: means, stdevs for F1-F4

# Intensity envelope
intensity_stats <- sound$intensity_statistics(
  minimum_pitch = 60,
  time_step = 0.01
)
# Returns: min, max, mean, stdev intensity
```

**Benefits:**
- Reduces R ↔ C++ boundary crossings to single call
- Easier API for common tasks
- 15-25% faster than multi-step R code

---

### Recommendation #4: Lazy Evaluation for Object Creation

**Priority:** 🟢 **LOW** - Advanced optimization

**Concept:**
Defer expensive computations until results are accessed:

```r
# Current: Immediate computation
pitch <- sound$to_pitch_cc(...)  # Full computation happens here
# Even if user only needs one statistic

# Proposed: Lazy evaluation
pitch <- sound$to_pitch_cc(..., lazy = TRUE)  # Just stores parameters
max_f0 <- pitch$get_maximum(0, 0, "Hertz")   # Computation happens here
```

**Use Case:**
User might create Pitch object but only use one method. No need to compute entire pitch contour if only maximum is needed.

**Implementation Complexity:** High (requires caching strategy)

---

## 📊 Performance Testing Framework

### Request: Add Built-In Benchmarking

**Suggestion:**
Include performance testing utilities in pladdrr:

```r
library(pladdrr)

# Run standard benchmarks
pladdrr::benchmark_suite()
# Output:
# Sound creation: 0.5ms
# Pitch extraction: 12.3ms
# Formant tracking: 8.7ms
# ...

# Compare with baseline
pladdrr::benchmark_compare(
  baseline = "2.0.4",
  current = "2.1.0"
)
# Output: Improvement matrix
```

**Benefits:**
- Track performance across versions
- Identify regressions
- Validate optimizations
- Compare against Parselmouth

---

## 🧪 Suggested Test Cases

### Test Suite for New Features

```r
# tests/testthat/test-performance.R

test_that("sound_concatenate_all works with Sound objects", {
  s1 <- Sound(test_wav_1)
  s2 <- Sound(test_wav_2)
  
  result <- sound_concatenate_all(list(s1, s2))
  
  expect_s3_class(result, "Sound")
  expect_equal(
    result$get_duration(), 
    s1$get_duration() + s2$get_duration(),
    tolerance = 0.001
  )
})

test_that("get_values is faster than as_data_frame", {
  sound <- Sound(test_wav)
  
  bench <- microbenchmark(
    get_values = sound$get_values(),
    data_frame = sound$as_data_frame()$value,
    times = 100
  )
  
  median_direct <- median(bench$time[bench$expr == "get_values"])
  median_df <- median(bench$time[bench$expr == "data_frame"])
  
  expect_lt(median_direct, median_df * 0.5)  # At least 2x faster
})

test_that("pitch statistics returns all metrics", {
  sound <- Sound(test_wav)
  pitch <- sound$to_pitch_cc(0, 75, 15, FALSE, 0.03, 0.45, 0.01, 0.35, 0.14, 600)
  
  stats <- pitch$get_statistics(
    from_time = 0,
    to_time = 0,
    unit = "Hertz",
    metrics = c("minimum", "maximum", "mean", "stdev")
  )
  
  expect_type(stats, "list")
  expect_named(stats, c("minimum", "maximum", "mean", "stdev"))
  expect_true(all(sapply(stats, is.numeric)))
  expect_true(stats$minimum <= stats$mean)
  expect_true(stats$mean <= stats$maximum)
})

test_that("extract_intervals_where returns correct intervals", {
  sound <- Sound(test_wav)
  textgrid <- sound$to_textgrid_silences(50, 0.003, -25, 0.1, 0.1)
  
  intervals <- textgrid$extract_intervals_where(
    tier_number = 1,
    comparison = "is not equal to",
    value = "silent"
  )
  
  expect_type(intervals, "list")
  expect_true(length(intervals) > 0)
  expect_true(all(sapply(intervals, function(x) inherits(x, "Sound"))))
})
```

---

## 📈 Expected Performance Improvements

### If All Recommendations Implemented

| Feature | Expected Speedup | Cumulative |
|---------|------------------|------------|
| Fix `sound_concatenate_all()` | 1.1x | 1.1x |
| Direct numeric vector access | 1.25x | 1.38x |
| Batch statistics methods | 1.12x | 1.54x |
| Fast interval extraction | 1.15x | 1.77x |
| Combined pitch+harmonicity | 1.08x | 1.91x |
| **Rcpp architecture** | 2.5x | **4.78x** |

**Projected Performance vs Python:**
- Current gap: 5-56x slower
- With all fixes: **1-12x slower** (acceptable for R)
- With Rcpp rewrite: **0.5-6x slower** (competitive!)

---

## 🎯 Priority Roadmap

### Short-Term (Next Release)

1. ✅ Fix `sound_concatenate_all()` bug (CRITICAL)
2. ✅ Add `Sound$get_values()` and `Sound$get_sample_times()` (HIGH)
3. ✅ Add `Pitch$get_statistics()`, `Intensity$get_statistics()` (MEDIUM)
4. ✅ Add `TextGrid$extract_intervals_where()` (MEDIUM)

**Expected outcome:** 30-40% overall speedup

### Mid-Term (Future Releases)

5. ✅ Add combined extraction methods (pitch+harmonicity)
6. ✅ Add windowed statistics methods
7. ✅ Implement fast-path workflow functions
8. ✅ Add performance benchmarking suite

**Expected outcome:** 50-60% overall speedup

### Long-Term (Major Version)

9. ✅ Prototype Rcpp-based architecture
10. ✅ Implement zero-copy data access
11. ✅ Add lazy evaluation for expensive objects

**Expected outcome:** 2-3x overall speedup (R competitive with Praat)

---

## 📝 Documentation Improvements

### Request: Performance Best Practices Guide

Add documentation section:

```markdown
# pladdrr Performance Guide

## Fastest Methods for Common Tasks

### Accessing Sample Data
✅ DO: sound$get_values()
❌ AVOID: sound$as_data_frame()$value

### Concatenating Multiple Files
✅ DO: sound_concatenate_all(sound_list)
❌ AVOID: Reduce(function(a,b) a$concatenate(b), sound_list)

### Getting Multiple Statistics
✅ DO: pitch$get_statistics(metrics = c("min", "max", "mean"))
❌ AVOID: Three separate get_minimum(), get_maximum(), get_mean() calls

### Processing Multiple Files
✅ DO: Use batch functions (sound_to_pitch_batch)
❌ AVOID: lapply with single-file functions
```

---

## 🤝 Collaboration Offer

The **plabench project** is happy to:

1. ✅ **Test alpha/beta versions** of pladdrr with new features
2. ✅ **Provide real-world benchmarks** for voice analysis workflows
3. ✅ **Contribute pull requests** for documentation improvements
4. ✅ **Share performance profiling data** from our use cases
5. ✅ **Validate correctness** of optimizations against Praat reference

**Contact:** plabench project maintainers  
**Test Platform:** macOS ARM64, Linux x86_64 available

---

## 📚 References

**Benchmarking Methodology:**
- Baseline: pladdrr 2.0.4 (current)
- Comparison: Python/Parselmouth 0.4.3
- Reference: Praat 6.4.x scripts
- Test suite: 6 clinical voice analysis tools (DSI, AVQI v2.03, AVQI v3.01, Tremor, VUV, VQ)
- Full validation: 3-way comparison (Praat vs Python vs R)

**Performance Data:**
- Located in: `bench_baseline.log`, `bench_optimized.log`
- Detailed analysis: `R_OPTIMIZATION_SUMMARY.md`
- Test suite: `tests/test_3way_validation.py`

---

## Conclusion

pladdrr 2.0.4 is a **solid, correct implementation** with excellent API coverage. The performance gap vs Parselmouth is primarily due to R language overhead, not bugs in pladdrr.

**Implementing the recommended optimizations would:**
1. ✅ Fix critical bugs (concatenation)
2. ✅ Provide 30-60% speedup with minor API additions
3. ✅ Achieve 2-3x speedup with Rcpp rewrite
4. ✅ Make pladdrr competitive with Praat (potentially faster)
5. ✅ Establish pladdrr as the premier R interface to Praat

We believe these changes would significantly benefit the broader phonetics and speech research community using R.

**Thank you for developing and maintaining pladdrr!** 🙏

---

**Questions or need clarification?**  
Contact: plabench development team  
Repository: https://github.com/[plabench-repo]  
Full report: `PLADDRR_DEVELOPMENT_RECOMMENDATIONS.md`
