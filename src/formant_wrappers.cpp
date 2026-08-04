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
// formant_wrappers.cpp
// C++ wrappers for Praat Formant object
// Part of the speaker package

// [[Rcpp::interfaces(r, cpp)]]
// [[Rcpp::plugins(cpp17)]]

#include "praat_types.h"
#include <Rcpp.h>
#include "praat_xptr_utils.h"
#include "praat_error_handling.h"
#include "datatable_utils.h"

// Praat headers
#include "fon/Formant.h"
#include "fon/Sound.h"
#include "fon/Sound_to_Formant.h"
#include "stat/Table.h"
#include "melder/melder.h"

using namespace Rcpp;

// Forward declarations
extern void NUMmachar();  // NUMfpp initialization
extern void NUMrandom_initializeSafelyAndUnpredictably();  // RNG initialization

// Helper function to ensure all numeric libraries are initialized
static void ensure_numeric_libs_initialized() {
    static bool initialized = false;
    if (!initialized) {
        NUMmachar();
        NUMrandom_initializeSafelyAndUnpredictably();
        initialized = true;
    }
}

// ============================================================================
// Creation methods
// ============================================================================

// [[Rcpp::export(.formant_from_sound_burg)]]
XPtr<structFormant> formant_from_sound_burg(
    XPtr<structSound> sound,
    double time_step,
    double max_number_of_formants,
    double maximum_formant,
    double window_length,
    double pre_emphasis_from
) {
    if (!sound) Rcpp::stop("Invalid Sound pointer");
    // Ensure NUMfpp and RNG are initialized before formant analysis
    ensure_numeric_libs_initialized();
    
    try {
        autoFormant formant = Sound_to_Formant_burg(
            sound.get(),
            time_step,
            max_number_of_formants,
            maximum_formant,
            window_length,
            pre_emphasis_from
        );
        return create_xptr_from_auto<structFormant>(formant);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to extract formants using Burg's algorithm");
    }
}

// [[Rcpp::export(.formant_from_sound_keepall)]]
XPtr<structFormant> formant_from_sound_keepall(
    XPtr<structSound> sound,
    double time_step,
    double max_number_of_formants,
    double maximum_formant,
    double window_length,
    double pre_emphasis_from
) {
    if (!sound) Rcpp::stop("Invalid Sound pointer");
    // Ensure NUMfpp is initialized
    ensure_numeric_libs_initialized();
    
    try {
        autoFormant formant = Sound_to_Formant_keepAll(
            sound.get(),
            time_step,
            max_number_of_formants,
            maximum_formant,
            window_length,
            pre_emphasis_from
        );
        return create_xptr_from_auto<structFormant>(formant);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to extract formants (keep all)");
    }
}

// [[Rcpp::export(.formant_from_sound_willems)]]
XPtr<structFormant> formant_from_sound_willems(
    XPtr<structSound> sound,
    double time_step,
    double number_of_formants,
    double maximum_formant,
    double window_length,
    double pre_emphasis_from
) {
    if (!sound) Rcpp::stop("Invalid Sound pointer");
    // Ensure NUMfpp is initialized
    ensure_numeric_libs_initialized();
    
    try {
        autoFormant formant = Sound_to_Formant_willems(
            sound.get(),
            time_step,
            number_of_formants,
            maximum_formant,
            window_length,
            pre_emphasis_from
        );
        return create_xptr_from_auto<structFormant>(formant);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to extract formants using Willems method");
    }
}

// [[Rcpp::export(.formant_from_sound_sl)]]
XPtr<structFormant> formant_from_sound_sl(
    XPtr<structSound> sound,
    double time_step,
    int number_of_poles,
    double maximum_formant,
    double window_length,
    double pre_emphasis_from
) {
    if (!sound) Rcpp::stop("Invalid Sound pointer");
    // Ensure NUMfpp is initialized
    ensure_numeric_libs_initialized();
    
    try {
        // which = 2 for Split-Levinson method
        autoFormant formant = Sound_to_Formant_any(
            sound.get(),
            time_step,
            number_of_poles,
            maximum_formant,
            window_length,
            2,  // Split-Levinson
            pre_emphasis_from,
            50.0  // safety margin
        );
        return create_xptr_from_auto<structFormant>(formant);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to extract formants using Split-Levinson method");
    }
}

// ============================================================================
// Query methods - Time domain
// ============================================================================

// [[Rcpp::export(.formant_get_number_of_frames)]]
int formant_get_number_of_frames(Rcpp::XPtr<structFormant> formant) {
    if (!formant) Rcpp::stop("Invalid Formant pointer");
    return formant->nx;
}

// [[Rcpp::export(.formant_get_time_step)]]
double formant_get_time_step(Rcpp::XPtr<structFormant> formant) {
    if (!formant) Rcpp::stop("Invalid Formant pointer");
    return formant->dx;
}

// [[Rcpp::export(.formant_get_min_num_formants)]]
int formant_get_min_num_formants(Rcpp::XPtr<structFormant> formant) {
    if (!formant) Rcpp::stop("Invalid Formant pointer");
    
    try {
        integer min_num = Formant_getMinNumFormants(formant.get());
        return (int)min_num;
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to get minimum number of formants");
    }
}

// [[Rcpp::export(.formant_get_max_num_formants)]]
int formant_get_max_num_formants(Rcpp::XPtr<structFormant> formant) {
    if (!formant) Rcpp::stop("Invalid Formant pointer");
    
    try {
        integer max_num = Formant_getMaxNumFormants(formant.get());
        return (int)max_num;
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to get maximum number of formants");
    }
}

// ============================================================================
// Query methods - Formant values
// ============================================================================

// [[Rcpp::export(.formant_get_value_at_time)]]
double formant_get_value_at_time(
    Rcpp::XPtr<structFormant> formant,
    int formant_number,
    double time,
    int unit
) {
    if (!formant) Rcpp::stop("Invalid Formant pointer");
    
    try {
        double value = Formant_getValueAtTime(
            formant.get(),
            formant_number,
            time,
            static_cast<kFormant_unit>(unit)
        );
        return value;
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to get formant value at time");
    }
}

// [[Rcpp::export(.formant_get_all_values_at_time)]]
Rcpp::NumericVector formant_get_all_values_at_time(
    Rcpp::XPtr<structFormant> formant,
    double time,
    int max_formants,
    int unit
) {
    if (!formant) Rcpp::stop("Invalid Formant pointer");

    try {
        Rcpp::NumericVector out(max_formants);
        for (int i = 0; i < max_formants; i++) {
            out[i] = Formant_getValueAtTime(
                formant.get(),
                i + 1,
                time,
                static_cast<kFormant_unit>(unit)
            );
        }
        return out;
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to get all formant values at time");
    }
}

// [[Rcpp::export(.formant_get_bandwidth_at_time)]]
double formant_get_bandwidth_at_time(
    Rcpp::XPtr<structFormant> formant,
    int formant_number,
    double time,
    int unit
) {
    if (!formant) Rcpp::stop("Invalid Formant pointer");
    
    try {
        double bandwidth = Formant_getBandwidthAtTime(
            formant.get(),
            formant_number,
            time,
            static_cast<kFormant_unit>(unit)
        );
        return bandwidth;
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to get formant bandwidth at time");
    }
}

// [[Rcpp::export(.formant_get_mean)]]
double formant_get_mean(
    Rcpp::XPtr<structFormant> formant,
    int formant_number,
    double from_time,
    double to_time,
    int unit
) {
    if (!formant) Rcpp::stop("Invalid Formant pointer");
    
    try {
        double mean = Formant_getMean(
            formant.get(),
            formant_number,
            from_time,
            to_time,
            static_cast<kFormant_unit>(unit)
        );
        return mean;
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to get mean formant");
    }
}

// [[Rcpp::export(.formant_get_standard_deviation)]]
double formant_get_standard_deviation(
    Rcpp::XPtr<structFormant> formant,
    int formant_number,
    double from_time,
    double to_time,
    int unit
) {
    if (!formant) Rcpp::stop("Invalid Formant pointer");
    
    try {
        double sd = Formant_getStandardDeviation(
            formant.get(),
            formant_number,
            from_time,
            to_time,
            static_cast<kFormant_unit>(unit)
        );
        return sd;
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to get formant standard deviation");
    }
}

// [[Rcpp::export(.formant_get_quantile)]]
double formant_get_quantile(
    Rcpp::XPtr<structFormant> formant,
    int formant_number,
    double quantile,
    double from_time,
    double to_time,
    int unit
) {
    if (!formant) Rcpp::stop("Invalid Formant pointer");
    
    try {
        double value = Formant_getQuantile(
            formant.get(),
            formant_number,
            quantile,
            from_time,
            to_time,
            static_cast<kFormant_unit>(unit)
        );
        return value;
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to get formant quantile");
    }
}

// [[Rcpp::export(.formant_get_minimum)]]
double formant_get_minimum(
    Rcpp::XPtr<structFormant> formant,
    int formant_number,
    double from_time,
    double to_time,
    int unit,
    bool interpolate
) {
    if (!formant) Rcpp::stop("Invalid Formant pointer");
    
    try {
        double minimum = Formant_getMinimum(
            formant.get(),
            formant_number,
            from_time,
            to_time,
            static_cast<kFormant_unit>(unit),
            interpolate ? 1 : 0
        );
        return minimum;
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to get minimum formant");
    }
}

// [[Rcpp::export(.formant_get_maximum)]]
double formant_get_maximum(
    Rcpp::XPtr<structFormant> formant,
    int formant_number,
    double from_time,
    double to_time,
    int unit,
    bool interpolate
) {
    if (!formant) Rcpp::stop("Invalid Formant pointer");
    
    try {
        double maximum = Formant_getMaximum(
            formant.get(),
            formant_number,
            from_time,
            to_time,
            static_cast<kFormant_unit>(unit),
            interpolate ? 1 : 0
        );
        return maximum;
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to get maximum formant");
    }
}

// [[Rcpp::export(.formant_get_time_of_minimum)]]
double formant_get_time_of_minimum(
    Rcpp::XPtr<structFormant> formant,
    int formant_number,
    double from_time,
    double to_time,
    int unit,
    bool interpolate
) {
    if (!formant) Rcpp::stop("Invalid Formant pointer");
    
    try {
        double time = Formant_getTimeOfMinimum(
            formant.get(),
            formant_number,
            from_time,
            to_time,
            static_cast<kFormant_unit>(unit),
            interpolate ? 1 : 0
        );
        return time;
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to get time of minimum formant");
    }
}

// [[Rcpp::export(.formant_get_time_of_maximum)]]
double formant_get_time_of_maximum(
    Rcpp::XPtr<structFormant> formant,
    int formant_number,
    double from_time,
    double to_time,
    int unit,
    bool interpolate
) {
    if (!formant) Rcpp::stop("Invalid Formant pointer");
    
    try {
        double time = Formant_getTimeOfMaximum(
            formant.get(),
            formant_number,
            from_time,
            to_time,
            static_cast<kFormant_unit>(unit),
            interpolate ? 1 : 0
        );
        return time;
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to get time of maximum formant");
    }
}

// ============================================================================
// Export methods
// ============================================================================

// [[Rcpp::export(.formant_as_data_frame)]]
Rcpp::DataFrame formant_as_data_frame(Rcpp::XPtr<structFormant> formant, int max_formants) {
    if (!formant) Rcpp::stop("Invalid Formant pointer");
    
    integer nx = formant->nx;
    
    Rcpp::NumericVector time(nx);
    Rcpp::NumericMatrix frequencies(nx, max_formants);
    Rcpp::NumericMatrix bandwidths(nx, max_formants);
    
    for (integer i = 1; i <= nx; i++) {
        double t = Sampled_indexToX(formant.get(), i);
        time[i-1] = t;
        
        for (int f = 1; f <= max_formants; f++) {
            double freq = Formant_getValueAtTime(formant.get(), f, t, kFormant_unit::HERTZ);
            double bw = Formant_getBandwidthAtTime(formant.get(), f, t, kFormant_unit::HERTZ);
            
            frequencies(i-1, f-1) = (freq > 0) ? freq : NA_REAL;
            bandwidths(i-1, f-1) = (bw > 0) ? bw : NA_REAL;
        }
    }
    
    // Create column names
    Rcpp::CharacterVector freq_names(max_formants);
    Rcpp::CharacterVector bw_names(max_formants);
    for (int f = 0; f < max_formants; f++) {
        freq_names[f] = "F" + std::to_string(f+1);
        bw_names[f] = "B" + std::to_string(f+1);
    }
    
    // Build data.table
    Rcpp::List df_list;
    df_list.push_back(time, "time");
    
    for (int f = 0; f < max_formants; f++) {
        df_list.push_back(frequencies(Rcpp::_, f), std::string(freq_names[f]));
    }
    for (int f = 0; f < max_formants; f++) {
        df_list.push_back(bandwidths(Rcpp::_, f), std::string(bw_names[f]));
    }
    
    // Create column name vector
    Rcpp::CharacterVector all_names(1 + 2*max_formants);
    all_names[0] = "time";
    for (int f = 0; f < max_formants; f++) {
        all_names[1 + f] = freq_names[f];
        all_names[1 + max_formants + f] = bw_names[f];
    }
    
    return pladdrr::dt::create_datatable(
        df_list,
        all_names,
        Rcpp::CharacterVector::create("time")  // Key on time
    );
}

// [[Rcpp::export(.formant_save)]]
void formant_save(Rcpp::XPtr<structFormant> formant, std::string path) {
    if (!formant) Rcpp::stop("Invalid Formant pointer");
    
    try {
        structMelderFile file {};
        Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
        Data_writeToTextFile(formant.get(), &file);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to save formant to file: " + path);
    }
}

// ============================================================================
// Formant tracking and export
// ============================================================================

// [[Rcpp::export(.formant_tracker)]]
Rcpp::XPtr<structFormant> formant_tracker(
    Rcpp::XPtr<structFormant> formant,
    int number_of_tracks,
    double ref_f1 = 550.0,
    double ref_f2 = 1650.0,
    double ref_f3 = 2750.0,
    double ref_f4 = 3850.0,
    double ref_f5 = 4950.0,
    double frequency_cost = 1.0,
    double bandwidth_cost = 1.0,
    double transition_cost = 1.0
) {
    if (!formant) Rcpp::stop("Invalid Formant pointer");
    
    try {
        autoFormant tracked = Formant_tracker(
            formant.get(),
            number_of_tracks,
            ref_f1, ref_f2, ref_f3, ref_f4, ref_f5,
            frequency_cost,
            bandwidth_cost,
            transition_cost
        );
        return create_xptr_from_auto<structFormant>(tracked);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to track formants");
    }
}

// [[Rcpp::export(.formant_down_to_table)]]
Rcpp::XPtr<structTable> formant_down_to_table(
    Rcpp::XPtr<structFormant> formant,
    bool include_frame_numbers = true,
    bool include_time = true,
    int time_decimals = 6,
    bool include_intensity = true,
    int intensity_decimals = 3,
    bool include_number_of_formants = true,
    int frequency_decimals = 3,
    bool include_bandwidths = true
) {
    if (!formant) Rcpp::stop("Invalid Formant pointer");
    
    try {
        autoTable table = Formant_downto_Table(
            formant.get(),
            include_frame_numbers,
            include_time, time_decimals,
            include_intensity, intensity_decimals,
            include_number_of_formants, frequency_decimals,
            include_bandwidths
        );
        return create_xptr_from_auto<structTable>(table);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to convert Formant to Table");
    }
}


