# pladdrr Functionality Gap Implementation Plan

**Date**: 2025-11-28
**Package Version**: 1.0.4
**Scope**: Non-interactive Praat functions not yet exposed

## Exclusions (Per User Request)

- ❌ Batch processing APIs
- ❌ Plotting/visualization
- ❌ User interaction (Editor window)
- ❌ Demo window functionality
- ❌ GUI applications

## Discovered: Existing Praat Functions NOT YET WRAPPED

### 1. TextGrid Automation (from TextGrid_extensions.h)

**Already in Praat C++**:
```cpp
// Label manipulation
void TextGrid_changeLabels(TextGrid, tier, from, to, search, replace, use_regexp, *nmatches, *nstringmatches);
void IntervalTier_removeBoundariesBetweenIdenticallyLabeledIntervals(IntervalTier, label);
void IntervalTier_combineIntervalsOnLabelMatch(IntervalTier, label);

// Time extension
void TextGrid_extendTime(TextGrid, delta_time, position);
void TextGrid_setEarlierStartTime(TextGrid, xmin, intervalMark, pointMark);
void TextGrid_setLaterEndTime(TextGrid, xmax, intervalMark, pointMark);

// Tier operations
void TextGrid_setTierName(TextGrid, itier, newName);
void TextGrids_append_inplace(TextGrid me, TextGrid thee, preserveTimes);

// Query
double TextGrid_getTotalDurationOfIntervalsWhere(TextGrid, tierNumber, which, criterion);
```

**Status**: ✅ **EXISTS IN PRAAT** - Need to wrap
**Priority**: 🔴 HIGH (60%+ of scripts use these)
**Effort**: 2-3 days

---

### 2. Sound to TextGrid (Silence Detection)

**Found in praat_Sound.cpp**:
```
FORM (CONVERT_EACH_TO_ONE__Sound_to_TextGrid, U"Sound: To TextGrid", ...)
```

**Need to investigate**:
- What does `Sound_to_TextGrid` actually do?
- Is it silence detection or just tier creation?
- Check the implementation

**Status**: ⏸️ **NEEDS INVESTIGATION**
**Priority**: 🔴 HIGH (if it's silence detection)

---

### 3. Functions We DON'T Need to Implement

**Pure R Implementations** (NOT in Praat):
- ❌ Formant normalization (Lobanov, Nearey, Watt & Fabricius)
- ❌ Audio quality metrics (SNR, spectral flatness)
- ❌ Trajectory extraction helpers

**Reason**: These are statistical transformations, not acoustic analysis.
**Implementation**: R-level utility functions using existing primitives.

---

## Implementation Strategy

### Phase 1: Wrap Existing Praat Functions (Week 1-2)

#### Task 1.1: TextGrid Extensions (3 days)
**Add to `src/textgrid_wrappers.cpp`**:

```cpp
// [[Rcpp::export]]
void praat_textgrid_change_labels(SEXP xptr, int tier, int from, int to,
                                    std::string search, std::string replace,
                                    bool use_regexp) {
  Rcpp::XPtr<structTextGrid> textgrid(xptr);
  integer nmatches, nstringmatches;
  TextGrid_changeLabels(textgrid, tier, from, to,
                       Melder_peek32to8(search.c_str()),
                       Melder_peek32to8(replace.c_str()),
                       use_regexp, &nmatches, &nstringmatches);
}

// [[Rcpp::export]]
void praat_interval_tier_remove_boundaries_between_identical(SEXP xptr, std::string label) {
  Rcpp::XPtr<structIntervalTier> tier(xptr);
  IntervalTier_removeBoundariesBetweenIdenticallyLabeledIntervals(
    tier, Melder_peek32to8(label.c_str())
  );
}

// [[Rcpp::export]]
double praat_textgrid_get_total_duration_where(SEXP xptr, int tier,
                                                 std::string which,
                                                 std::string criterion) {
  Rcpp::XPtr<structTextGrid> textgrid(xptr);
  return TextGrid_getTotalDurationOfIntervalsWhere(
    textgrid, tier,
    kMelder_string_from_string(which.c_str()),
    Melder_peek32to8(criterion.c_str())
  );
}
```

**Add to `R/textgrid-r6.R`**:
```r
TextGrid = R6Class("TextGrid",
  public = list(
    # ... existing methods ...
    
    change_labels = function(tier, search, replace, use_regexp = FALSE,
                            from = 1, to = -1) {
      praat_textgrid_change_labels(private$.xptr, as.integer(tier),
                                   as.integer(from), as.integer(to),
                                   search, replace, use_regexp)
      invisible(self)
    },
    
    merge_consecutive_intervals = function(tier, label) {
      # Get tier, call C++ merge function
      praat_interval_tier_remove_boundaries_between_identical(
        self$get_tier(tier)$.xptr, label
      )
      invisible(self)
    },
    
    get_total_duration_where = function(tier, criterion) {
      praat_textgrid_get_total_duration_where(
        private$.xptr, as.integer(tier), "is equal to", criterion
      )
    }
  )
)
```

**Tests**:
```r
testthat::test_that("TextGrid label operations work", {
  tg <- TextGrid$new(xmin = 0, xmax = 1)
  tg$insert_interval_tier(name = "words")
  tg$insert_boundary(tier = 1, time = 0.5)
  tg$set_interval_text(tier = 1, interval = 1, text = "old")
  tg$set_interval_text(tier = 1, interval = 2, text = "old")
  
  # Test change labels
  tg$change_labels(tier = 1, search = "old", replace = "new")
  expect_equal(tg$get_label_of_interval(1, 1), "new")
  
  # Test merge
  tg$merge_consecutive_intervals(tier = 1, label = "new")
  expect_equal(tg$get_number_of_intervals(1), 1)
})
```

---

#### Task 1.2: Sound to TextGrid Investigation (1 day)

**Check what exists**:
```bash
cd src/praat.github.io/fon
grep -A50 "Sound_to_TextGrid" praat_Sound.cpp
```

**If it's useful**: Wrap it
**If it's just UI**: Document that R has better alternatives

---

### Phase 2: R-Level Utilities (Week 3)

#### Task 2.1: Trajectory Extraction Helpers (2 days)

**File**: `R/trajectory_extraction.R`

```r
#' Extract formant trajectories from TextGrid intervals
#' 
#' @param formant Formant object
#' @param textgrid TextGrid object
#' @param tier Tier number
#' @param label_filter Optional label to filter intervals
#' @param formant_numbers Which formants to extract (default 1:3)
#' @param time_normalization Number of time points or "midpoint" (default 11)
#' @param time_range Proportion of interval to sample (default c(0.2, 0.8))
#' @export
extract_formant_trajectories <- function(formant, textgrid, tier,
                                          label_filter = NULL,
                                          formant_numbers = 1:3,
                                          time_normalization = 11,
                                          time_range = c(0.2, 0.8)) {
  
  n_intervals <- textgrid$get_number_of_intervals(tier)
  results <- list()
  
  for (i in seq_len(n_intervals)) {
    label <- textgrid$get_label_of_interval(tier, i)
    
    # Skip if label filter doesn't match
    if (!is.null(label_filter) && label != label_filter) next
    
    t_start <- textgrid$get_start_time_of_interval(tier, i)
    t_end <- textgrid$get_end_time_of_interval(tier, i)
    duration <- t_end - t_start
    
    # Calculate sampling points
    t_min <- t_start + duration * time_range[1]
    t_max <- t_start + duration * time_range[2]
    
    if (time_normalization == "midpoint") {
      times <- (t_min + t_max) / 2
    } else {
      times <- seq(t_min, t_max, length.out = time_normalization)
    }
    
    # Extract formant values
    for (t in times) {
      row <- data.frame(
        interval = i,
        label = label,
        time = t,
        rel_time = (t - t_start) / duration
      )
      
      for (fn in formant_numbers) {
        row[[paste0("F", fn)]] <- formant$get_value_at_time(
          formant_number = fn, time = t, unit = "hertz", interpolate = TRUE
        )
      }
      
      results[[length(results) + 1]] <- row
    }
  }
  
  do.call(rbind, results)
}

#' Extract pitch trajectories
#' @export
extract_pitch_trajectories <- function(pitch, textgrid, tier,
                                       label_filter = NULL,
                                       time_normalization = 11,
                                       time_range = c(0.2, 0.8)) {
  # Similar implementation for pitch
}
```

---

#### Task 2.2: Audio Quality Metrics (1 day)

**File**: `R/audio_quality.R`

```r
#' Check audio quality metrics
#' 
#' @param sound Sound object
#' @return List with quality metrics
#' @export
check_audio_quality <- function(sound) {
  max_amp <- sound$get_maximum()
  
  # Clipping detection
  is_clipped <- max_amp > 0.99
  
  # Get RMS for SNR estimation (requires Intensity)
  intensity <- sound$to_intensity(
    minimum_pitch = 100,
    time_step = 0.0,
    subtract_mean = TRUE
  )
  mean_intensity_db <- intensity$get_mean(from_time = 0, to_time = 0, unit = "DB")
  
  # Zero crossing rate (count sign changes in waveform)
  # Note: This would need a new C++ wrapper to access raw samples
  # For now, leave as TODO
  
  list(
    max_amplitude = max_amp,
    is_clipped = is_clipped,
    mean_intensity_db = mean_intensity_db,
    zero_crossing_rate = NA  # TODO: needs sample access
  )
}
```

---

#### Task 2.3: Formant Normalization (1 day)

**File**: `R/formant_normalization.R`

```r
#' Lobanov normalization for formants
#' 
#' @param formants Data frame with speaker, F1, F2, F3 columns
#' @export
normalize_formants_lobanov <- function(formants) {
  formants %>%
    group_by(speaker) %>%
    mutate(
      F1_lobanov = (F1 - mean(F1, na.rm = TRUE)) / sd(F1, na.rm = TRUE),
      F2_lobanov = (F2 - mean(F2, na.rm = TRUE)) / sd(F2, na.rm = TRUE),
      F3_lobanov = (F3 - mean(F3, na.rm = TRUE)) / sd(F3, na.rm = TRUE)
    ) %>%
    ungroup()
}

#' Nearey normalization
#' @export
normalize_formants_nearey <- function(formants) {
  # Implementation
}

#' Watt & Fabricius normalization
#' @export
normalize_formants_wattfabricius <- function(formants) {
  # Implementation
}
```

---

## Summary

### What We're Adding

**C++ Wrappers** (from existing Praat functions):
1. `TextGrid$change_labels()` - Find/replace labels
2. `TextGrid$merge_consecutive_intervals()` - Merge same-label intervals
3. `TextGrid$get_total_duration_where()` - Query total duration
4. `TextGrid$extend_time()` - Extend time domain
5. `TextGrid$set_tier_name()` - Rename tiers

**R-Level Utilities** (new implementations):
1. `extract_formant_trajectories()` - Time-normalized formant extraction
2. `extract_pitch_trajectories()` - Time-normalized pitch extraction
3. `check_audio_quality()` - Quality metrics
4. `normalize_formants_*()` - Speaker normalization methods

### What We're NOT Adding

- Batch processing (R is better)
- Visualization (separate release)
- Interactive features (Editor, Demo window)
- Pitch stylization (complex, low usage)

### Timeline

- **Week 1**: TextGrid C++ wrappers + tests
- **Week 2**: R trajectory extraction + tests
- **Week 3**: Audio quality + normalization + documentation

**Total**: ~3 weeks to ~95% coverage of programmatic use cases

