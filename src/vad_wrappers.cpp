// vad_wrappers.cpp
// Voice Activity Detection wrappers for speaker package
// Provides functions for detecting voiced/unvoiced segments in audio

#include <Rcpp.h>
#include "praat_xptr_utils.h"
#include "praat_error_handling.h"

// Praat headers
#include "fon/Sound.h"
#include "fon/Intensity.h"
#include "fon/TextGrid.h"
#include "dwtools/Intensity_extensions.h"

using namespace Rcpp;

// =============================================================================
// Voice Activity Detection via Intensity
// =============================================================================

// [[Rcpp::export(.sound_to_textgrid_silences)]]
SEXP sound_to_textgrid_silences(SEXP sound_xptr,
                                double minimum_pitch,
                                double time_step,
                                double silence_threshold_db,
                                double min_silent_interval,
                                double min_sounding_interval,
                                std::string silent_label,
                                std::string sounding_label) {
    XPtr<structSound> sound(sound_xptr);
    if (!sound) stop("Invalid Sound pointer");
    
    try {
        // Step 1: Convert Sound to Intensity
        autoIntensity intensity = Sound_to_Intensity(
            sound.get(),
            minimum_pitch,
            time_step,
            true  // subtract mean
        );
        
        // Step 2: Detect silences using Intensity
        // The silence_threshold_db is relative to maximum intensity
        autoTextGrid textgrid = Intensity_to_TextGrid_detectSilences(
            intensity.get(),
            silence_threshold_db,
            min_silent_interval,
            min_sounding_interval,
            Melder_cat(silent_label.c_str()),
            Melder_cat(sounding_label.c_str())
        );
        
        return create_xptr_from_auto<structTextGrid>(textgrid);
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to detect silences in Sound");
    }
}

// =============================================================================
// Helper: Get intervals matching a criterion
// =============================================================================

// [[Rcpp::export(.textgrid_get_intervals_where)]]
List textgrid_get_intervals_where(SEXP xptr,
                                 int tier_number,
                                 std::string condition,
                                 std::string match_text) {
    XPtr<structTextGrid> textgrid(xptr);
    if (!textgrid) stop("Invalid TextGrid pointer");
    
    try {
        if (tier_number < 1 || tier_number > textgrid->tiers->size) {
            stop("Tier number out of range: %d (must be 1-%d)", 
                 tier_number, textgrid->tiers->size);
        }
        
        Function tier = textgrid->tiers->at [tier_number];
        
        // Check if it's an interval tier
        if (!tier->classInfo == classIntervalTier) {
            stop("Tier %d is not an interval tier", tier_number);
        }
        
        IntervalTier intervalTier = (IntervalTier) tier;
        
        // Collect matching intervals
        std::vector<double> starts;
        std::vector<double> ends;
        std::vector<std::string> labels;
        
        for (integer i = 1; i <= intervalTier->intervals.size; i++) {
            TextInterval interval = intervalTier->intervals.at [i];
            conststring32 label = interval->text.get();
            
            // Convert to std::string for comparison
            char32_t *labelCopy = Melder_dup(label);
            std::string label_str = Melder_peek32to8(labelCopy);
            Melder_free(labelCopy);
            
            bool matches = false;
            
            if (condition == "equals" || condition == "is equal to") {
                matches = (label_str == match_text);
            } else if (condition == "contains") {
                matches = (label_str.find(match_text) != std::string::npos);
            } else if (condition == "does not contain") {
                matches = (label_str.find(match_text) == std::string::npos);
            } else if (condition == "starts with") {
                matches = (label_str.find(match_text) == 0);
            } else if (condition == "ends with") {
                if (label_str.length() >= match_text.length()) {
                    matches = (label_str.compare(
                        label_str.length() - match_text.length(),
                        match_text.length(),
                        match_text
                    ) == 0);
                }
            } else {
                stop("Unknown condition: %s", condition.c_str());
            }
            
            if (matches) {
                starts.push_back(interval->xmin);
                ends.push_back(interval->xmax);
                labels.push_back(label_str);
            }
        }
        
        return List::create(
            Named("xmin") = starts,
            Named("xmax") = ends,
            Named("text") = labels,
            Named("count") = static_cast<int>(starts.size())
        );
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to extract intervals from TextGrid");
    }
}

// =============================================================================
// Extract sound parts based on time intervals
// =============================================================================

// [[Rcpp::export(.sound_extract_parts)]]
List sound_extract_parts(SEXP sound_xptr,
                        NumericVector start_times,
                        NumericVector end_times,
                        std::string window_shape,
                        double relative_width,
                        bool preserve_times) {
    XPtr<structSound> sound(sound_xptr);
    if (!sound) stop("Invalid Sound pointer");
    
    if (start_times.size() != end_times.size()) {
        stop("start_times and end_times must have the same length");
    }
    
    try {
        List result;
        
        for (int i = 0; i < start_times.size(); i++) {
            double t1 = start_times[i];
            double t2 = end_times[i];
            
            if (t2 <= t1) {
                warning("Skipping interval %d: end time <= start time", i + 1);
                continue;
            }
            
            // Map window shape string to enum
            kSound_windowShape shape = kSound_windowShape::RECTANGULAR;
            if (window_shape == "rectangular") {
                shape = kSound_windowShape::RECTANGULAR;
            } else if (window_shape == "triangular") {
                shape = kSound_windowShape::TRIANGULAR;
            } else if (window_shape == "parabolic") {
                shape = kSound_windowShape::PARABOLIC;
            } else if (window_shape == "hanning") {
                shape = kSound_windowShape::HANNING;
            } else if (window_shape == "hamming") {
                shape = kSound_windowShape::HAMMING;
            } else if (window_shape == "gaussian1") {
                shape = kSound_windowShape::GAUSSIAN_1;
            } else if (window_shape == "gaussian2") {
                shape = kSound_windowShape::GAUSSIAN_2;
            } else if (window_shape == "gaussian3") {
                shape = kSound_windowShape::GAUSSIAN_3;
            } else if (window_shape == "gaussian4") {
                shape = kSound_windowShape::GAUSSIAN_4;
            } else if (window_shape == "gaussian5") {
                shape = kSound_windowShape::GAUSSIAN_5;
            } else if (window_shape == "kaiser1") {
                shape = kSound_windowShape::KAISER_1;
            } else if (window_shape == "kaiser2") {
                shape = kSound_windowShape::KAISER_2;
            }
            
            autoSound part = Sound_extractPart(
                sound.get(),
                t1,
                t2,
                shape,
                relative_width,
                preserve_times
            );
            
            result.push_back(create_xptr_from_auto<structSound>(part));
        }
        
        return result;
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to extract sound parts");
    }
}
