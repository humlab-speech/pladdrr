/*
 * Part of pladdrr: R interface to Praat
 *
 * Copyright (C) 2025 Fredrik Nylén
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */
// textgrid_batch_operations.cpp
// Batch operations for TextGrid interval extraction and analysis
// Part of Phase 3 Performance Enhancements (v2.0.7)
// Updated: Phase 3 Task 3.3 SIMD Integration (v4.5.3)
//
// Reduces R<->C++ boundary crossings for TextGrid-based workflows

// [[Rcpp::interfaces(r, cpp)]]
// [[Rcpp::plugins(cpp17)]]

#include "praat_types.h"
#include <Rcpp.h>
#include "praat_xptr_utils.h"

// Praat headers
#include "fon/TextGrid.h"
#include "fon/Sound.h"
#include "melder/melder.h"

using namespace Rcpp;

// Forward declarations from textgrid_simd.cpp for SIMD-accelerated operations
namespace textgrid_simd {
extern "C" {
    bool should_use_simd_for_textgrid();
    void calculate_durations_simd_0based(
        const double* start_times, const double* end_times, double* durations, size_t n
    );
}
}


//' Extract TextGrid Intervals by Label (Batch)
//'
//' Extract multiple intervals from a TextGrid tier that match specified
//' criteria, using:
//' - A single C++ call instead of 4n R<->C++ calls (n = number of intervals)
//' - Comparisons done at the C++ level
//' - A single memory allocation for the result
//'
//' @param textgrid_xptr External pointer to TextGrid object
//' @param sound_xptr External pointer to Sound object (optional, can be NULL)
//' @param tier_number Tier number (1-based)
//' @param comparison_type Type of comparison: "equals", "contains", "starts_with", "regex"
//' @param target_value Value to match against interval labels
//' @param extract_sounds If TRUE and sound_xptr provided, extract Sound parts
//'
//' @return List with components:
//'   - indices: Integer vector of matching interval indices
//'   - labels: Character vector of matching labels
//'   - start_times: Numeric vector of start times
//'   - end_times: Numeric vector of end times
//'   - sounds: List of Sound xptrs (if extract_sounds = TRUE)
//'
//' @details
//' **Comparison types:**
//' - "equals": Exact match (strcmp)
//' - "contains": Substring match (strstr)
//' - "starts_with": Prefix match
//' - "regex": Regular expression (future)
//'
//' @examples
//' \dontrun{
//' # Extract all "V" (voiced) intervals
//' result <- textgrid_extract_intervals_batch(
//'   textgrid$get_xptr(),
//'   sound$get_xptr(),
//'   tier_number = 1,
//'   comparison_type = "equals",
//'   target_value = "V",
//'   extract_sounds = TRUE
//' )
//'
//' # Access results
//' n_voiced <- length(result$indices)
//' voiced_durations <- result$end_times - result$start_times
//' voiced_sounds <- result$sounds  # List of Sound objects
//' }
//'
//' @export
// [[Rcpp::export]]
List textgrid_extract_intervals_batch(
    SEXP textgrid_xptr,
    SEXP sound_xptr,
    int tier_number,
    std::string comparison_type = "equals",
    std::string target_value = "",
    bool extract_sounds = false
) {
    BEGIN_RCPP
    
    // Validate TextGrid pointer
    Rcpp::XPtr<structTextGrid> tg(textgrid_xptr);
    if (!tg) {
        Rcpp::stop("Invalid TextGrid pointer");
    }
    
    // Use Praat's helper to validate and get tier
    IntervalTier interval_tier = TextGrid_checkSpecifiedTierIsIntervalTier(tg, tier_number);
    
    integer n_intervals = interval_tier->intervals.size;
    
    // Optional: Validate Sound pointer if extracting sounds
    structSound* sound = nullptr;
    if (extract_sounds) {
        Rcpp::XPtr<structSound> sound_ptr(sound_xptr);
        if (!sound_ptr) {
            Rcpp::stop("Invalid Sound pointer (required when extract_sounds = TRUE)");
        }
        sound = sound_ptr.get();
    }
    
    // Pre-allocate result vectors (assume 10% match rate for initial size)
    std::vector<int> indices;
    std::vector<std::string> labels;
    std::vector<double> start_times;
    std::vector<double> end_times;
    List sounds;
    
    indices.reserve(n_intervals / 10);
    labels.reserve(n_intervals / 10);
    start_times.reserve(n_intervals / 10);
    end_times.reserve(n_intervals / 10);
    
    // Single pass through intervals at C++ level
    for (integer i = 1; i <= n_intervals; i++) {
        TextInterval interval = interval_tier->intervals.at[i];
        
        // Get label (convert from Praat's char32 to std::string)
        std::string label = Melder_peek32to8(interval->text.get());
        
        // Comparison logic at C++ level (no R boundary crossing)
        bool matches = false;
        
        if (comparison_type == "equals") {
            matches = (label == target_value);
        } else if (comparison_type == "contains") {
            matches = (label.find(target_value) != std::string::npos);
        } else if (comparison_type == "starts_with") {
            matches = (label.compare(0, target_value.length(), target_value) == 0);
        } else {
            Rcpp::stop("Unknown comparison_type: %s (use 'equals', 'contains', or 'starts_with')", 
                      comparison_type.c_str());
        }
        
        if (matches) {
            // Extract interval metadata
            indices.push_back(i);
            labels.push_back(label);
            start_times.push_back(interval->xmin);
            end_times.push_back(interval->xmax);
            
            // Optionally extract sound part
            if (extract_sounds) {
                try {
                    autoSound part = Sound_extractPart(
                        sound,
                        interval->xmin,
                        interval->xmax,
                        kSound_windowShape::RECTANGULAR,
                        1.0,  // relative width
                        false  // preserve times
                    );
                    
                    // Transfer ownership to XPtr and add to list
                    sounds.push_back(XPtr<structSound>(part.releaseToAmbiguousOwner()));
                    
                } catch (...) {
                    Rcpp::warning("Failed to extract sound for interval %d [%.3f, %.3f]",
                                 i, interval->xmin, interval->xmax);
                    sounds.push_back(R_NilValue);
                }
            }
        }
    }
    
    // Return structured list
    List result = List::create(
        Named("indices") = IntegerVector(indices.begin(), indices.end()),
        Named("labels") = CharacterVector(labels.begin(), labels.end()),
        Named("start_times") = NumericVector(start_times.begin(), start_times.end()),
        Named("end_times") = NumericVector(end_times.begin(), end_times.end()),
        Named("n_total") = n_intervals,
        Named("n_matched") = static_cast<int>(indices.size())
    );
    
    if (extract_sounds) {
        result["sounds"] = sounds;
    }
    
    return result;
    
    END_RCPP
}


//' Get All Labels from TextGrid Tier (Batch)
//'
//' Extract all interval labels from a tier in a single call, instead of
//' calling `get_interval_text()` n times.
//'
//' @param textgrid_xptr External pointer to TextGrid object
//' @param tier_number Tier number (1-based)
//'
//' @return Character vector of all interval labels
//'
//' @examples
//' \dontrun{
//' labels <- textgrid_get_all_labels(textgrid$get_xptr(), tier = 1)
//' table(labels)  # Frequency of each label
//' }
//'
//' @export
// [[Rcpp::export]]
CharacterVector textgrid_get_all_labels(SEXP textgrid_xptr, int tier_number) {
    BEGIN_RCPP
    
    Rcpp::XPtr<structTextGrid> tg(textgrid_xptr);
    if (!tg) {
        Rcpp::stop("Invalid TextGrid pointer");
    }
    
    // Use Praat's helper to validate and get tier
    IntervalTier interval_tier = TextGrid_checkSpecifiedTierIsIntervalTier(tg, tier_number);
    
    integer n_intervals = interval_tier->intervals.size;
    CharacterVector result(n_intervals);
    
    for (integer i = 1; i <= n_intervals; i++) {
        TextInterval interval = interval_tier->intervals.at[i];
        result[i-1] = Melder_peek32to8(interval->text.get());
    }
    
    return result;
    
    END_RCPP
}


//' Compute Statistics for All Intervals (Batch, SIMD-Optimized)
//'
//' Compute statistics (duration, etc.) for all intervals in a tier.
//' Single C++ call instead of looping in R. Uses SIMD for duration
//' calculation when available.
//'
//' @param textgrid_xptr External pointer to TextGrid object
//' @param tier_number Tier number (1-based)
//'
//' @return Data frame with columns:
//'   - index: Interval index
//'   - label: Interval label
//'   - start: Start time
//'   - end: End time
//'   - duration: Duration (end - start)
//'
//' @details
//' Duration calculation uses SIMD vectorization when available, for
//' large interval counts (>100).
//'
//' @examples
//' \dontrun{
//' stats <- textgrid_interval_statistics_batch(textgrid$get_xptr(), tier = 1)
//' mean(stats$duration[stats$label == "V"])  # Mean voiced interval duration
//' }
//'
//' @export
// [[Rcpp::export]]
DataFrame textgrid_interval_statistics_batch(SEXP textgrid_xptr, int tier_number) {
    BEGIN_RCPP

    Rcpp::XPtr<structTextGrid> tg(textgrid_xptr);
    if (!tg) {
        Rcpp::stop("Invalid TextGrid pointer");
    }

    // Use Praat's helper to validate and get tier
    IntervalTier interval_tier = TextGrid_checkSpecifiedTierIsIntervalTier(tg.get(), tier_number);

    integer n = interval_tier->intervals.size;

    IntegerVector indices(n);
    CharacterVector labels(n);
    NumericVector starts(n);
    NumericVector ends(n);
    NumericVector durations(n);

    // Extract times into contiguous arrays for SIMD
    std::vector<double> start_arr(n);
    std::vector<double> end_arr(n);

    for (integer i = 1; i <= n; i++) {
        TextInterval interval = interval_tier->intervals.at[i];

        indices[i-1] = i;
        labels[i-1] = Melder_peek32to8(interval->text.get());

        start_arr[i-1] = interval->xmin;
        end_arr[i-1] = interval->xmax;
        starts[i-1] = interval->xmin;
        ends[i-1] = interval->xmax;
    }

    // SIMD-accelerated duration calculation
    if (textgrid_simd::should_use_simd_for_textgrid()) {
        textgrid_simd::calculate_durations_simd_0based(
            start_arr.data(), end_arr.data(), durations.begin(), n
        );
    } else {
        // Scalar fallback
        for (int i = 0; i < n; i++) {
            durations[i] = end_arr[i] - start_arr[i];
        }
    }

    return DataFrame::create(
        Named("index") = indices,
        Named("label") = labels,
        Named("start") = starts,
        Named("end") = ends,
        Named("duration") = durations
    );

    END_RCPP
}


// =============================================================================
// XPtr Predicate Filtering (v2.2.2 - Performance Enhancement)
// =============================================================================

// Type definition for user-compiled predicate functions
// Signature: bool predicate(const char* label, double start_time, double end_time)
typedef bool (*IntervalPredicateFunc)(const char*, double, double);

//' Extract TextGrid Intervals Using Custom XPtr Predicate
//'
//' Filter intervals using a user-compiled C++ predicate function.
//' The predicate executes entirely in C++ without any R boundary crossings.
//'
//' @param textgrid_xptr External pointer to TextGrid object
//' @param tier_number Tier number (1-based)
//' @param predicate_xptr External pointer to compiled predicate function
//'   created with `RcppXPtrUtils::cppXPtr()`. Signature must be:
//'   `bool(const char* label, double start, double end)`
//' @param sound_xptr Optional external pointer to Sound for extraction
//' @param extract_sounds If TRUE and sound_xptr provided, extract Sound parts
//'
//' @return List with components:
//'   - indices: Integer vector of matching interval indices
//'   - labels: Character vector of matching labels
//'   - start_times: Numeric vector of start times
//'   - end_times: Numeric vector of end times
//'   - sounds: List of Sound xptrs (if extract_sounds = TRUE)
//'
//' @details
//' **Compiling a custom predicate (requires RcppXPtrUtils):**
//'
//' ```r
//' # Example: Filter intervals with duration > 0.1s and label starting with 'V'
//' my_pred <- RcppXPtrUtils::cppXPtr(
//'   "bool pred(const char* label, double start, double end) \{
//'      double dur = end - start;
//'      return dur > 0.1 && label[0] == 'V';
//'    \}",
//'   signature = "bool(const char*, double, double)"
//' )
//'
//' result <- textgrid_filter_xptr(
//'   textgrid$.xptr,
//'   tier = 1,
//'   predicate_xptr = my_pred
//' )
//' ```
//'
//' @seealso [textgrid_extract_intervals_batch()] for simpler string matching
//'
//' @export
// [[Rcpp::export]]
List textgrid_filter_xptr(
    SEXP textgrid_xptr,
    int tier_number,
    SEXP predicate_xptr,
    SEXP sound_xptr = R_NilValue,
    bool extract_sounds = false
) {
    BEGIN_RCPP

    // Validate TextGrid pointer
    Rcpp::XPtr<structTextGrid> tg(textgrid_xptr);
    if (!tg || tg.get() == nullptr) {
        Rcpp::stop("Invalid TextGrid pointer");
    }

    // Validate and extract predicate function pointer
    if (TYPEOF(predicate_xptr) != EXTPTRSXP) {
        Rcpp::stop("predicate_xptr must be an external pointer (from RcppXPtrUtils::cppXPtr)");
    }

    void* pred_addr = R_ExternalPtrAddr(predicate_xptr);
    if (pred_addr == nullptr) {
        Rcpp::stop("predicate_xptr is NULL - predicate may have been garbage collected");
    }

    // Cast to function pointer (XPtr wraps IntervalPredicateFunc*, need to dereference)
    IntervalPredicateFunc predicate = *reinterpret_cast<IntervalPredicateFunc*>(pred_addr);

    // Get interval tier
    IntervalTier interval_tier = TextGrid_checkSpecifiedTierIsIntervalTier(tg.get(), tier_number);
    integer n_intervals = interval_tier->intervals.size;

    // Optional: Validate Sound pointer if extracting sounds
    structSound* sound = nullptr;
    if (extract_sounds && sound_xptr != R_NilValue) {
        Rcpp::XPtr<structSound> sound_ptr(sound_xptr);
        if (!sound_ptr || sound_ptr.get() == nullptr) {
            Rcpp::stop("Invalid Sound pointer");
        }
        sound = sound_ptr.get();
    }

    // Pre-allocate result vectors
    std::vector<int> indices;
    std::vector<std::string> labels;
    std::vector<double> start_times;
    std::vector<double> end_times;
    List sounds;

    indices.reserve(n_intervals / 5);  // Assume ~20% match rate
    labels.reserve(n_intervals / 5);
    start_times.reserve(n_intervals / 5);
    end_times.reserve(n_intervals / 5);

    // Single pass through intervals - predicate executes entirely in C++
    for (integer i = 1; i <= n_intervals; i++) {
        TextInterval interval = interval_tier->intervals.at[i];

        // Get label as C string
        const char* label_cstr = Melder_peek32to8(interval->text.get());
        double t_start = interval->xmin;
        double t_end = interval->xmax;

        // Call user predicate (no R boundary crossing!)
        bool matches = predicate(label_cstr, t_start, t_end);

        if (matches) {
            indices.push_back(i);
            labels.push_back(std::string(label_cstr));
            start_times.push_back(t_start);
            end_times.push_back(t_end);

            // Optionally extract sound part
            if (extract_sounds && sound != nullptr) {
                try {
                    autoSound part = Sound_extractPart(
                        sound,
                        t_start,
                        t_end,
                        kSound_windowShape::RECTANGULAR,
                        1.0,
                        false
                    );
                    sounds.push_back(XPtr<structSound>(part.releaseToAmbiguousOwner()));
                } catch (...) {
                    sounds.push_back(R_NilValue);
                }
            }
        }
    }

    // Return structured list
    List result = List::create(
        Named("indices") = IntegerVector(indices.begin(), indices.end()),
        Named("labels") = CharacterVector(labels.begin(), labels.end()),
        Named("start_times") = NumericVector(start_times.begin(), start_times.end()),
        Named("end_times") = NumericVector(end_times.begin(), end_times.end()),
        Named("n_total") = n_intervals,
        Named("n_matched") = static_cast<int>(indices.size())
    );

    if (extract_sounds) {
        result["sounds"] = sounds;
    }

    return result;

    END_RCPP
}


//' Create Built-in Interval Predicates
//'
//' Returns external pointers to pre-compiled predicates for common filtering tasks.
//' Use these instead of compiling your own for simple cases.
//'
//' @param type Predicate type: "non_empty", "min_duration", "max_duration"
//' @param threshold Numeric threshold (for duration predicates)
//'
//' @return External pointer to predicate function
//'
//' @details
//' Available predicates:
//' - "non_empty": Matches intervals with non-empty labels (label[0] != '\\0')
//' - "min_duration": Matches intervals with duration >= threshold
//' - "max_duration": Matches intervals with duration <= threshold
//'
//' @examples
//' tg <- TextGrid$create(0, 1, "words")
//' tg$insert_boundary(1, 0.5)
//' tg$set_interval_text(1, 2, "hello")
//'
//' # Get all non-empty intervals
//' pred <- get_interval_predicate("non_empty")
//' result <- textgrid_filter_xptr(tg$.xptr, 1, pred)
//'
//' # Get intervals longer than 100ms
//' pred <- get_interval_predicate("min_duration", 0.1)
//' result <- textgrid_filter_xptr(tg$.xptr, 1, pred)
//'
//' @export
// [[Rcpp::export]]
SEXP get_interval_predicate(std::string type, double threshold = 0.0) {
    // Built-in predicate: non-empty labels
    static auto pred_non_empty = [](const char* label, double, double) -> bool {
        return label != nullptr && label[0] != '\0';
    };

    // For duration thresholds, we use a closure-like approach with static variables
    // Note: This is a simplification; for true closure support, use cppXPtr
    static double min_dur_threshold = 0.0;
    static double max_dur_threshold = 1e10;

    static auto pred_min_duration = [](const char*, double start, double end) -> bool {
        return (end - start) >= min_dur_threshold;
    };

    static auto pred_max_duration = [](const char*, double start, double end) -> bool {
        return (end - start) <= max_dur_threshold;
    };

    if (type == "non_empty") {
        return XPtr<IntervalPredicateFunc>(
            new IntervalPredicateFunc(reinterpret_cast<IntervalPredicateFunc>(
                +pred_non_empty
            )),
            true
        );
    } else if (type == "min_duration") {
        min_dur_threshold = threshold;
        return XPtr<IntervalPredicateFunc>(
            new IntervalPredicateFunc(reinterpret_cast<IntervalPredicateFunc>(
                +pred_min_duration
            )),
            true
        );
    } else if (type == "max_duration") {
        max_dur_threshold = threshold;
        return XPtr<IntervalPredicateFunc>(
            new IntervalPredicateFunc(reinterpret_cast<IntervalPredicateFunc>(
                +pred_max_duration
            )),
            true
        );
    } else {
        Rcpp::stop("Unknown predicate type: %s (use 'non_empty', 'min_duration', or 'max_duration')",
                   type.c_str());
    }

    return R_NilValue;  // Never reached
}
