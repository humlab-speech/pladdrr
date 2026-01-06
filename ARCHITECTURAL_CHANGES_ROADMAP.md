# pladdrr Architectural Changes Roadmap

**Document Version:** 1.0  
**Date:** 2026-01-06  
**Purpose:** Future Implementation Planning  
**Context:** User feedback analysis from PERFORMANCE_OPTIMIZATION_SUMMARY.md and related documents

---

## Executive Summary

This document outlines **architectural changes to pladdrr** that are beyond the scope of immediate bug fixes and require significant refactoring or redesign of the package infrastructure. These changes represent long-term performance improvement opportunities that could achieve **2-5x speedup** over current implementations.

### Current Status
- **Immediate fixes available:** 30-40% improvement (see main implementation plan)
- **Architectural changes needed:** Additional 2-3x improvement potential
- **Current performance gap vs Python/Parselmouth:** 5-56x slower
- **After all changes:** Potentially 1-12x slower (acceptable for R ecosystem)

---

## 1. R6 → Rcpp Architecture Migration

### 🎯 **Priority: HIGH**
### 📊 **Expected Impact: 2-3x overall speedup**
### ⏱️ **Effort Estimate: 3-6 months (major version)**

### Current Architecture Problem

**Current dispatch chain (R6-based):**
```
R function call
  → R6 environment lookup for method name
  → R6 method dispatch through environments
  → Find C++ wrapper function in environment
  → Call C++ via .Call()
  → Return to R6 environment
  → Wrap result in R6 object
```

**Measured overhead:** ~15-20 microseconds per method call

**Why this is slow:**
- R6 uses environment-based dispatch (dynamic lookup at runtime)
- Every method call traverses environment chains
- Reference semantics add complexity
- No compile-time optimization possible

### Proposed Rcpp Architecture

**New dispatch chain (Rcpp Modules or S4):**
```
R function call
  → Rcpp S4/Module method dispatch (compiled)
  → Direct C++ call
  → Return wrapped result
```

**Expected overhead:** ~5-8 microseconds per method call

**Advantages:**
- Compiled dispatch (2-3x faster method calls)
- Better memory management (ref counting vs GC)
- More familiar to R package developers
- Rcpp::NumericVector can wrap data without copies

### Implementation Approach

#### Phase 1: Prototype (1-2 months)
1. **Choose approach:**
   - **Option A:** Rcpp Modules (similar to current, easier migration)
   - **Option B:** Pure Rcpp with S4 classes (more traditional R package)
   - **Recommendation:** Start with Rcpp Modules for Sound class

2. **Create prototype Sound class:**
```cpp
// Example: sound_rcpp.cpp
#include <Rcpp.h>
using namespace Rcpp;

RCPP_MODULE(sound_module) {
    class_<Sound>("Sound")
    
    .constructor<std::string>("Create Sound from file path")
    
    // Fast property access
    .property("duration", &Sound::get_duration)
    .property("sampling_frequency", &Sound::get_sampling_frequency)
    
    // Methods with direct dispatch
    .method("get_values", &Sound::get_values)
    .method("get_sample_times", &Sound::get_sample_times)
    .method("to_pitch", &Sound::to_pitch)
    
    // ... etc
    ;
}
```

3. **Benchmark against R6 implementation:**
```r
# Benchmark script
library(microbenchmark)

# Current R6
sound_r6 <- pladdrr::Sound("test.wav")
bench_r6 <- microbenchmark(
  property = sound_r6$get_duration(),
  method = sound_r6$get_rms(),
  times = 10000
)

# New Rcpp
sound_rcpp <- pladdrr2::Sound("test.wav")
bench_rcpp <- microbenchmark(
  property = sound_rcpp$duration,  # or $get_duration()
  method = sound_rcpp$get_rms(),
  times = 10000
)

# Target: 2-3x speedup in method dispatch
```

#### Phase 2: Incremental Migration (2-3 months)
1. Migrate core classes in order:
   - Sound (most used)
   - Pitch
   - Formant
   - Intensity
   - TextGrid
   - [... remaining classes]

2. Maintain backward compatibility:
   - Keep R6 interfaces as wrappers during transition
   - Deprecation warnings for old API
   - Dual implementation phase

3. Update all existing R code to use new classes

#### Phase 3: Complete Migration (1 month)
1. Remove R6 wrappers
2. Update documentation
3. Major version bump (3.0.0)
4. Performance validation

### Risks and Mitigation

**Risk 1: Breaking changes for users**
- *Mitigation:* Maintain compatibility layer for 6-12 months
- *Mitigation:* Provide migration guide and automated conversion tools

**Risk 2: Loss of R6 flexibility**
- *Mitigation:* Rcpp Modules provide similar OOP capabilities
- *Mitigation:* Can mix Rcpp and R6 for advanced features

**Risk 3: Increased maintenance complexity**
- *Mitigation:* Rcpp is more standard in R ecosystem
- *Mitigation:* Better documentation and tooling available

### Success Criteria

- [ ] Method dispatch 2-3x faster (measured via microbenchmark)
- [ ] Overall analysis workflows 30-50% faster
- [ ] Memory usage comparable or better
- [ ] All tests pass with new implementation
- [ ] API remains intuitive and R-like

---

## 2. Zero-Copy Data Access

### 🎯 **Priority: MEDIUM-HIGH**
### 📊 **Expected Impact: 20-30% speedup for data-intensive operations**
### ⏱️ **Effort Estimate: 1-2 months**

### Current Data Access Problem

**Current implementation:**
```cpp
// sound_module.cpp - as_data_frame() method
DataFrame as_data_frame() {
    VALIDATE_PTR(ptr, Sound);
    
    integer n_samples = ptr->nx;
    integer n_channels = ptr->ny;
    
    // Creates NEW R vectors (full memory copy)
    NumericVector times(n_samples);
    NumericVector values(n_samples * n_channels);
    
    // Copy data from Praat structures to R vectors
    for (integer i = 0; i < n_samples; i++) {
        times[i] = ptr->x1 + i * ptr->dx;  // Copy 1
        for (integer ch = 1; ch <= n_channels; ch++) {
            values[...] = ptr->z[ch][i];   // Copy 2
        }
    }
    
    return DataFrame::create(_["time"] = times, _["value"] = values);
}
```

**Problems:**
- Full memory allocation for times and values
- Complete copy of all sample data
- Data frame overhead (names, attributes, etc.)
- Called repeatedly in loops = many copies

**User impact:**
- AVQI v3.01 calls `as_data_frame()` 100-300 times per analysis
- Each call allocates and copies entire sound

### Proposed Zero-Copy Implementation

**Concept:** Expose Praat's internal memory directly to R without copying

```cpp
// New implementation: sound_zerocopy_access.cpp

// [[Rcpp::export]]
SEXP sound_values_zerocopy(SEXP xptr, int channel = 1) {
    Rcpp::XPtr<structSound> ptr(xptr);
    
    if (channel < 1 || channel > ptr->ny) {
        Rcpp::stop("Channel out of range");
    }
    
    // Get pointer to Praat's sample array
    double* samples = &(ptr->z[channel][1]);  // Praat uses 1-based indexing
    integer n_samples = ptr->nx;
    
    // Wrap WITHOUT copying (Rcpp::wrap with no_copy flag)
    // IMPORTANT: Data lifetime tied to Sound object
    Rcpp::NumericVector result = Rcpp::NumericVector(
        samples, 
        samples + n_samples
    );
    
    // Mark as read-only to prevent R from modifying Praat's data
    result.attr("class") = "readonly_vector";
    
    return result;
}
```

### Implementation Challenges

**Challenge 1: Memory Management**
- Praat uses custom allocators (forget/Thing)
- R uses garbage collection
- Must ensure Sound object isn't freed while R holds vector reference

**Solution:**
```cpp
// Approach 1: Reference counting
class SoundVectorView {
    XPtr<structSound> sound_ptr;  // Keeps Sound alive
    double* data_ptr;
    size_t length;
public:
    // Ensure Sound isn't garbage collected while view exists
    SoundVectorView(XPtr<structSound> snd, int channel) 
        : sound_ptr(snd) {
        // ... initialize data_ptr and length
    }
};

// Approach 2: Copy-on-write
// Return read-only view by default
// Copy only if user tries to modify
```

**Challenge 2: Praat's 1-based vs R's 0-based indexing**
- Praat arrays: `z[channel][1..n]`
- R vectors: `[0..n-1]`

**Solution:** Offset pointer appropriately

**Challenge 3: Safety - preventing crashes**
- If Sound is modified/deleted, view becomes invalid
- Need mechanism to invalidate views or prevent modification

**Solution:**
```cpp
// Add validation flag
struct SoundView {
    XPtr<structSound> ptr;
    uint64_t version;  // Incremented on Sound modification
    
    void validate() {
        if (ptr->version != version) {
            Rcpp::stop("Sound has been modified, view is invalid");
        }
    }
};
```

### API Design

```r
# Safe API for users
sound <- Sound("audio.wav")

# Zero-copy access (fast, read-only)
values <- sound$get_values_zerocopy(channel = 1)
# Returns: readonly numeric vector view

# Traditional copy (safe, modifiable)
values_copy <- sound$get_values(channel = 1)
# Returns: normal numeric vector

# Automatic copy-on-write
values <- sound$get_values_zerocopy()
values[1] <- 0.5  # Triggers automatic copy, then modifies
```

### Risks and Mitigation

**Risk 1: Crashes from invalid memory access**
- *Mitigation:* Extensive testing and validation
- *Mitigation:* Make zero-copy opt-in, not default
- *Mitigation:* Clear documentation about lifetime

**Risk 2: User confusion about mutability**
- *Mitigation:* Clear naming (`_zerocopy` suffix)
- *Mitigation:* Warnings in documentation
- *Mitigation:* Automatic copy-on-write if possible

**Risk 3: Platform-specific memory layout issues**
- *Mitigation:* Thorough testing on Windows/Mac/Linux
- *Mitigation:* Fallback to copy if zero-copy fails

### Success Criteria

- [ ] 50%+ reduction in memory allocations for data access
- [ ] 20-30% speedup for windowed analysis (AVQI v3.01)
- [ ] No crashes in extensive testing
- [ ] Clear documentation and examples
- [ ] Graceful fallback to copy mode if issues detected

---

## 3. Batch Operation Framework

### 🎯 **Priority: MEDIUM**
### 📊 **Expected Impact: 15-25% speedup for multi-operation workflows**
### ⏱️ **Effort Estimate: 2-3 months**

### Current Multi-Operation Problem

**Typical user workflow:**
```r
# DSI analysis - multiple operations on same sound
sound <- Sound("vowel.wav")

# Operation 1: Get pitch statistics
pitch <- sound$to_pitch_cc(...)           # R→C++ call 1
max_f0 <- pitch$get_maximum(0, 0, "Hz")   # R→C++ call 2
mean_f0 <- pitch$get_mean(0, 0, "Hz")     # R→C++ call 3

# Operation 2: Get intensity statistics
intensity <- sound$to_intensity(...)      # R→C++ call 4
max_db <- intensity$get_maximum(0, 0)     # R→C++ call 5
min_db <- intensity$get_minimum(0, 0)     # R→C++ call 6

# Total: 6 R↔C++ boundary crossings
# Pitch object created, used, then discarded
# Intensity object created, used, then discarded
```

**Problems:**
- Each R→C++ call has overhead (~5-10μs with Rcpp, ~15-20μs with R6)
- Intermediate objects kept in memory unnecessarily
- No opportunity for C++-level optimization

### Proposed Batch Operations

**Concept:** Single R→C++ call performs multiple operations and returns aggregate results

```cpp
// Example: sound_batch_analysis.cpp

// [[Rcpp::export]]
List sound_voice_quality_analysis(
    SEXP sound_xptr,
    double pitch_floor = 75.0,
    double pitch_ceiling = 600.0,
    double minimum_pitch_intensity = 100.0
) {
    XPtr<structSound> sound(sound_xptr);
    
    // Single pass: extract pitch and intensity together
    autoPitch pitch = Sound_to_Pitch_cc(
        sound.get(), 0.01, pitch_floor, pitch_ceiling, ...
    );
    
    autoIntensity intensity = Sound_to_Intensity(
        sound.get(), minimum_pitch_intensity, 0.01, true
    );
    
    // Compute all statistics at C++ level (no R boundary crossings)
    double pitch_mean = Pitch_getMean(pitch.get(), 0, 0, kPitch_unit::HERTZ);
    double pitch_max = Pitch_getMaximum(pitch.get(), 0, 0, kPitch_unit::HERTZ, false);
    double pitch_min = Pitch_getMinimum(pitch.get(), 0, 0, kPitch_unit::HERTZ, false);
    double pitch_stdev = Pitch_getStandardDeviation(pitch.get(), 0, 0, kPitch_unit::HERTZ);
    
    double intensity_mean = Intensity_getMean(intensity.get(), 0, 0);
    double intensity_max = Intensity_getMaximum(intensity.get(), 0, 0, kVector_peakInterpolation::PARABOLIC);
    double intensity_min = Intensity_getMinimum(intensity.get(), 0, 0, kVector_peakInterpolation::PARABOLIC);
    
    // Return aggregated results (single R object)
    return List::create(
        _["pitch"] = List::create(
            _["mean"] = pitch_mean,
            _["max"] = pitch_max,
            _["min"] = pitch_min,
            _["stdev"] = pitch_stdev
        ),
        _["intensity"] = List::create(
            _["mean"] = intensity_mean,
            _["max"] = intensity_max,
            _["min"] = intensity_min
        )
    );
    
    // Pitch and Intensity objects auto-deleted (not returned to R)
}
```

**R wrapper:**
```r
#' Voice Quality Batch Analysis
#'
#' Efficient extraction of common voice quality measures in a single call.
#'
#' @export
sound_voice_quality <- function(sound, pitch_floor = 75, pitch_ceiling = 600) {
  sound_voice_quality_analysis(
    sound$get_xptr(),
    pitch_floor,
    pitch_ceiling
  )
}

# Usage
sound <- Sound("vowel.wav")
vq <- sound_voice_quality(sound)
# Returns: list with pitch and intensity statistics
# 1 R↔C++ call instead of 6+
```

### Proposed Batch Operations

**High Priority (most common workflows):**

1. **`sound_voice_quality_batch()`** - DSI, AVQI use case
   - Input: Sound
   - Output: Pitch stats, Intensity stats, HNR mean
   - Saves: 8-12 R↔C++ calls → 1 call

2. **`sound_formant_analysis_batch()`** - Vowel analysis
   - Input: Sound, time_range, formant_numbers
   - Output: F1/F2/F3/F4 means, stdevs
   - Saves: 12-16 calls → 1 call

3. **`sound_extract_and_analyze_intervals()`** - TextGrid-based
   - Input: Sound, TextGrid, tier, label_filter
   - Output: List of interval analyses
   - Saves: n * (3 + k) calls → 1 call

4. **`pitch_and_harmonicity_combined()`** - Shared autocorrelation
   - Input: Sound
   - Output: Pitch object, Harmonicity object
   - Optimization: Share autocorrelation computation
   - Saves: Redundant autocorrelation + 2 R↔C++ calls

### Implementation Strategy

#### Phase 1: Framework Setup (2-4 weeks)
```cpp
// batch_operations_framework.h

// Base template for batch operations
template<typename ResultType>
class BatchOperation {
public:
    virtual ResultType execute(XPtr<structSound> sound) = 0;
    virtual List execute_and_return_list(XPtr<structSound> sound) = 0;
};

// Registry for batch operations
class BatchOperationRegistry {
    std::map<std::string, std::shared_ptr<BatchOperation>> operations;
public:
    void register_operation(const std::string& name, std::shared_ptr<BatchOperation> op);
    List execute(const std::string& name, SEXP sound_xptr, List params);
};
```

#### Phase 2: Implement Common Operations (4-6 weeks)
- Start with top 5 most-used workflows from user feedback
- Each operation thoroughly tested
- Performance benchmarks vs manual approach

#### Phase 3: User-Facing API (2 weeks)
```r
# High-level R functions
sound_voice_quality(sound, ...)
sound_formant_analysis(sound, ...)
sound_spectral_analysis(sound, ...)

# Generic batch interface for advanced users
sound_batch_analyze(sound, operations = list(
  pitch_stats = list(floor = 75, ceiling = 600),
  intensity_stats = list(min_pitch = 100),
  hnr_mean = list(periods = 1.0)
))
```

### Risks and Mitigation

**Risk 1: API inflexibility**
- Users may need operations not covered by batch functions
- *Mitigation:* Keep individual methods available
- *Mitigation:* Make batch operations optional, not mandatory

**Risk 2: Maintenance burden**
- Each batch operation is custom C++ code
- *Mitigation:* Template-based framework
- *Mitigation:* Code generation for common patterns

**Risk 3: Limited adoption**
- Users may stick with familiar individual methods
- *Mitigation:* Clear performance benefits in documentation
- *Mitigation:* Helper functions suggest batch operations

### Success Criteria

- [ ] 5-8 commonly-used batch operations implemented
- [ ] 15-25% speedup for workflows using batch operations
- [ ] Clear documentation with performance comparisons
- [ ] Unit tests for each batch operation
- [ ] Backward compatibility maintained (batch is addition, not replacement)

---

## 4. TextGrid Interval Extraction Optimization

### 🎯 **Priority: MEDIUM**
### 📊 **Expected Impact: 15-20% speedup for TextGrid-based analyses**
### ⏱️ **Effort Estimate: 3-4 weeks**

### Current TextGrid Workflow Problem

**Typical interval extraction (from user feedback):**
```r
# DSI: Extract all voiced intervals from TextGrid
textgrid <- point_process$to_textgrid_vuv(...)
n_intervals <- textgrid$get_number_of_intervals(1)

voiced_sounds <- list()
for (i in 1:n_intervals) {
  text <- textgrid$get_interval_text(1, i)        # R→C++ call 1
  
  if (text == "V") {
    start <- textgrid$get_interval_start_time(1, i)  # R→C++ call 2
    end <- textgrid$get_interval_end_time(1, i)      # R→C++ call 3
    part <- sound$extract_part(start, end, ...)      # R→C++ call 4
    
    voiced_sounds <- c(voiced_sounds, list(part))
  }
}

# Total: 4n R↔C++ calls for n intervals (even non-matching ones)
```

**Problems:**
- High R↔C++ boundary crossing overhead
- R loop iterating over potentially hundreds of intervals
- Inefficient list growth with `c()`
- Must extract part for each matching interval separately

### Proposed Optimized Implementation

**Approach 1: Batch interval extraction in C++**

```cpp
// textgrid_batch_operations.cpp

// [[Rcpp::export]]
List textgrid_extract_intervals_where(
    SEXP textgrid_xptr,
    SEXP sound_xptr,
    int tier_number,
    std::string comparison_type,  // "equals", "contains", "starts_with", "matches"
    std::string target_value
) {
    XPtr<structTextGrid> tg(textgrid_xptr);
    XPtr<structSound> sound(sound_xptr);
    
    // Get tier
    if (tier_number < 1 || tier_number > tg->tiers->size) {
        Rcpp::stop("Tier number out of range");
    }
    
    IntervalTier tier = (IntervalTier) tg->tiers->at[tier_number];
    List result;
    
    // Single pass through intervals at C++ level
    for (integer i = 1; i <= tier->intervals.size; i++) {
        TextInterval interval = tier->intervals.at[i];
        const char* label = interval->text.get();
        
        // Comparison logic at C++ level (no R boundary crossing)
        bool matches = false;
        if (comparison_type == "equals") {
            matches = (strcmp(label, target_value.c_str()) == 0);
        } else if (comparison_type == "contains") {
            matches = (strstr(label, target_value.c_str()) != nullptr);
        }
        // ... other comparison types
        
        if (matches) {
            // Extract sound part at C++ level
            double start = interval->xmin;
            double end = interval->xmax;
            
            autoSound part = Sound_extractPart(
                sound.get(), start, end,
                kSound_windowShape::RECTANGULAR, 1.0, false
            );
            
            // Store extracted part
            result.push_back(XPtr<structSound>(part.releaseToAmbiguousOwner()));
        }
    }
    
    return result;
}
```

**R wrapper:**
```r
#' Extract Intervals Matching Criteria
#'
#' Efficiently extract all sound intervals from TextGrid that match criteria.
#' Much faster than manual R loop.
#'
#' @export
textgrid_extract_intervals <- function(sound, textgrid, tier, 
                                       text_equals = NULL,
                                       text_contains = NULL,
                                       text_starts_with = NULL) {
  # Determine comparison type
  if (!is.null(text_equals)) {
    comp_type <- "equals"
    target <- text_equals
  } else if (!is.null(text_contains)) {
    comp_type <- "contains"
    target <- text_contains
  } else {
    stop("Must specify one comparison criterion")
  }
  
  # Single C++ call extracts all matching intervals
  xptrs <- textgrid_extract_intervals_where(
    textgrid$get_xptr(),
    sound$get_xptr(),
    as.integer(tier),
    comp_type,
    target
  )
  
  # Wrap in Sound objects
  lapply(xptrs, function(xptr) Sound(.xptr = xptr))
}

# Usage example
voiced_sounds <- textgrid_extract_intervals(
  sound = sound,
  textgrid = textgrid,
  tier = 1,
  text_equals = "V"
)
# Returns: list of Sound objects for voiced intervals
# 1 R↔C++ call instead of 4n calls
```

**Approach 2: Extract and concatenate in single call**

```cpp
// [[Rcpp::export]]
SEXP textgrid_extract_and_concatenate(
    SEXP textgrid_xptr,
    SEXP sound_xptr,
    int tier_number,
    std::string comparison_type,
    std::string target_value,
    double overlap = 0.0
) {
    // Similar to above, but also concatenates at C++ level
    
    // ... extract matching intervals ...
    
    // Concatenate all at once (Praat function)
    autoSoundList collection = SoundList_create();
    for (auto& part : extracted_parts) {
        collection->addItem_move(part.move());
    }
    
    autoSound concatenated = Sounds_concatenate(
        collection.get(), overlap
    );
    
    return XPtr<structSound>(concatenated.releaseToAmbiguousOwner());
}
```

**R wrapper:**
```r
#' Extract and Concatenate Intervals
#'
#' Most efficient approach: extract matching intervals and concatenate
#' in a single C++ call.
#'
#' @export
textgrid_concatenate_intervals <- function(sound, textgrid, tier, 
                                          text_equals = NULL,
                                          overlap = 0) {
  # Single C++ call: extract + concatenate
  result_xptr <- textgrid_extract_and_concatenate(
    textgrid$get_xptr(),
    sound$get_xptr(),
    as.integer(tier),
    "equals",
    text_equals,
    as.numeric(overlap)
  )
  
  Sound(.xptr = result_xptr)
}

# Usage - most common DSI/AVQI pattern
voiced_sound <- textgrid_concatenate_intervals(
  sound, textgrid, tier = 1, text_equals = "V"
)
# Single concatenated Sound of all voiced intervals
# 1 R↔C++ call total (vs 4n + n-1 concatenate calls)
```

### Additional TextGrid Optimizations

**1. Batch interval queries:**
```cpp
// Get all interval metadata in single call
// [[Rcpp::export]]
DataFrame textgrid_get_intervals_dataframe(SEXP textgrid_xptr, int tier) {
    // Return data frame with: start, end, text for all intervals
    // Single R↔C++ call instead of 3n calls
}
```

**2. Filtered interval tables:**
```cpp
// [[Rcpp::export]]
DataFrame textgrid_get_intervals_where(
    SEXP textgrid_xptr, 
    int tier,
    std::string filter_type,
    std::string filter_value
) {
    // Return data frame of matching intervals only
    // Filtering at C++ level
}
```

### Risks and Mitigation

**Risk 1: Complex API with many options**
- *Mitigation:* Start with simple equals/contains
- *Mitigation:* Add advanced filters only if requested

**Risk 2: Memory usage for large TextGrids**
- *Mitigation:* Option to return iterators instead of full lists
- *Mitigation:* Streaming/chunked processing for huge files

### Success Criteria

- [ ] 15-20% speedup for TextGrid-based workflows (DSI, AVQI)
- [ ] 3-5 common extraction patterns implemented
- [ ] Clear documentation with before/after examples
- [ ] Handles edge cases (empty intervals, boundaries, etc.)

---

## 5. Combined Analysis Methods

### 🎯 **Priority: LOW-MEDIUM**
### 📊 **Expected Impact: 5-10% speedup**
### ⏱️ **Effort Estimate: 2-3 weeks per combination**

### Concept

Some Praat analyses share computational steps. Combining them at C++ level eliminates redundant work.

### Example 1: Pitch + Harmonicity

**Current approach:**
```r
pitch <- sound$to_pitch_cc(...)        # Autocorrelation computation 1
harmonicity <- sound$to_harmonicity_cc(...)  # Autocorrelation computation 2
```

**Both use autocorrelation** - computing twice is wasteful.

**Proposed:**
```cpp
// [[Rcpp::export]]
List sound_to_pitch_and_harmonicity_cc(
    SEXP sound_xptr,
    double time_step = 0.01,
    double pitch_floor = 75.0,
    double pitch_ceiling = 600.0,
    double periods_per_window = 1.0
) {
    XPtr<structSound> sound(sound_xptr);
    
    // Compute autocorrelation ONCE
    autoSound autocorr = Sound_autoCorrelate(sound.get(), ...);
    
    // Use same autocorrelation for both
    autoPitch pitch = Pitch_from_autoCorrelation(autocorr.get(), ...);
    autoHarmonicity hnr = Harmonicity_from_autoCorrelation(autocorr.get(), ...);
    
    return List::create(
        _["pitch"] = XPtr<structPitch>(pitch.releaseToAmbiguousOwner()),
        _["harmonicity"] = XPtr<structHarmonicity>(hnr.releaseToAmbiguousOwner())
    );
}
```

**R wrapper:**
```r
sound_pitch_and_harmonicity <- function(sound, ...) {
  result <- sound_to_pitch_and_harmonicity_cc(sound$get_xptr(), ...)
  list(
    pitch = Pitch(.xptr = result$pitch),
    harmonicity = Harmonicity(.xptr = result$harmonicity)
  )
}
```

### Other Candidates

**Example 2: Formant + LPC**
- Both use LPC (Linear Predictive Coding)
- Could share computation

**Example 3: Spectrum + Spectrogram**
- Spectrogram is series of spectra
- Could optimize if both needed

### Implementation Notes

- Only implement if there's measurable benefit (>5% speedup)
- Document shared computation in code comments
- Benchmark before and after

### Success Criteria

- [ ] 2-3 combined methods implemented
- [ ] Measurable speedup (>5%) in benchmarks
- [ ] No accuracy loss vs separate computations

---

## 6. Advanced Memory Management

### 🎯 **Priority: LOW**
### 📊 **Expected Impact: Variable (10-30% for large files)**
### ⏱️ **Effort Estimate: 1-2 months**

### Opportunities

**1. Object pooling**
- Reuse Praat objects instead of constant allocation/deallocation
- Particularly useful for batch processing

**2. Lazy evaluation**
- Don't compute full Pitch/Formant if user only needs one statistic
- Store parameters, compute on first access

**3. Memory-mapped file I/O**
- For very large files (>100MB), don't load entirely into memory
- Process in chunks

**4. Result caching**
- Cache commonly-requested statistics
- Invalidate on object modification

### Implementation Complexity

- **High:** Requires careful lifetime management
- **High:** Interaction with R's garbage collector
- **High:** Platform-specific considerations

### Recommendation

- **Defer until after other optimizations**
- **Implement only if profiling shows significant benefit**
- **Start with simple caching for proof-of-concept**

---

## Implementation Priority Matrix

### Immediate (Package-level fixes - Current PR)
✅ Fix `sound_concatenate_all()` bug  
✅ Add `get_values()` / `get_sample_times()` methods  
✅ Add batch statistics methods (`Pitch/Intensity/Formant$get_statistics()`)

**Expected improvement:** 30-40%  
**Effort:** 1-2 days  
**Risk:** Low

---

### Short-term (3-6 months - Version 2.1)
🎯 Zero-copy data access  
🎯 TextGrid interval extraction optimization  
🎯 Batch operation framework (basic)

**Expected improvement:** Additional 20-30% (cumulative: 50-70%)  
**Effort:** 2-3 months  
**Risk:** Medium

---

### Mid-term (6-12 months - Version 2.5 or 3.0)
🎯 R6 → Rcpp architecture migration (phased)  
🎯 Batch operation framework (complete)  
🎯 Combined analysis methods (top 3)

**Expected improvement:** Additional 2-3x (cumulative: 2-4x total)  
**Effort:** 6-8 months  
**Risk:** Medium-High

---

### Long-term (12+ months - Version 3.x+)
🎯 Advanced memory management  
🎯 Performance monitoring framework  
🎯 Additional combined methods

**Expected improvement:** Additional 10-30% (cumulative: 2-5x total)  
**Effort:** 12+ months  
**Risk:** High

---

## Performance Validation Strategy

For each architectural change:

1. **Microbenchmarks:** Individual method call overhead
2. **Workflow benchmarks:** Real analysis scripts (DSI, AVQI, etc.)
3. **Memory profiling:** Ensure no memory leaks
4. **Cross-platform testing:** Windows, Mac, Linux
5. **Comparison to Parselmouth:** Track progress toward parity

**Target after all changes:**
- R pladdrr: **1-12x slower than Python/Parselmouth** (acceptable)
- Current gap: 5-56x slower
- Goal: Close the gap to where R's overhead is acceptable given ecosystem benefits

---

## Resource Requirements

### Developer Time

- **Full-time dedicated developer:** 12-18 months for complete roadmap
- **Part-time (20%):** 3-5 years
- **Community contributions:** Could parallelize some efforts

### Skills Required

- **C++ expertise** (Praat API, Rcpp)
- **R package development**
- **Performance optimization** experience
- **Understanding of DSP/phonetics** (for validation)

### Testing Infrastructure

- **CI/CD:** Automated benchmarks on each commit
- **Reference datasets:** Validated against Praat/Parselmouth
- **Performance regression detection**

---

## Conclusion

This roadmap represents a **multi-year effort** to bring pladdrr to performance parity with Python/Parselmouth. The changes are architectural and require significant engineering effort, but the potential benefits are substantial:

- **2-5x overall speedup** achievable
- **R ecosystem integration** maintained
- **User-friendly API** preserved
- **Opens new use cases** (large-scale batch processing in R)

The immediate fixes (30-40% improvement) are achievable quickly. The larger architectural changes require commitment but would establish pladdrr as the premier R interface to Praat, competitive with Python for performance while maintaining R's strengths.

---

**Next Steps:**
1. Review and prioritize this roadmap
2. Secure resources (developer time, infrastructure)
3. Begin with Phase 1: Immediate fixes (current PR)
4. Prototype R6→Rcpp migration for Sound class
5. Gather community feedback on API design

---

**Document Maintenance:**
- Review quarterly
- Update with new findings from profiling
- Adjust priorities based on user feedback
- Track progress against targets

---

**End of Roadmap Document**
