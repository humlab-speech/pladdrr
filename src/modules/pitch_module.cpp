// pitch_module.cpp
// Rcpp Module for Praat Pitch object
// Part of the pladdrr package - 2.0 module-based architecture

#include <Rcpp.h>
#include "module_common.h"

// Praat headers
#include "../praat.github.io/fon/Pitch.h"
#include "../praat.github.io/fon/Sound.h"
#include "../praat.github.io/fon/Sound_to_Pitch.h"
#include "../praat.github.io/fon/Pitch_to_PointProcess.h"
#include "../praat.github.io/fon/Pitch_to_PitchTier.h"
#include "../praat.github.io/fon/PitchTier.h"
#include "../praat.github.io/fon/PointProcess.h"
#include "../praat.github.io/fon/TextGrid.h"
#include "../praat.github.io/melder/melder.h"

using namespace Rcpp;

// Forward declaration - NUMfpp initialization
extern void NUMmachar();

// ============================================================================
// RPitch Module Class
// ============================================================================

class RPitch {
public:
    Rcpp::XPtr<structPitch> ptr;

    // ========================================================================
    // Constructors
    // ========================================================================

    // Default constructor (empty/invalid object)
    RPitch() : ptr(R_NilValue) {}

    // Constructor from external pointer
    RPitch(Rcpp::XPtr<structPitch> p) : ptr(p) {}

    // ========================================================================
    // Factory: Create from Sound
    // ========================================================================

    static RPitch from_sound(
        Rcpp::XPtr<structSound> sound,
        double time_step,
        double pitch_floor,
        double pitch_ceiling
    ) {
        if (!sound) Rcpp::stop("Invalid Sound pointer");

        // Ensure NUMfpp is initialized
        NUMmachar();

        try {
            autoPitch pitch = Sound_to_Pitch(
                sound.get(),
                time_step,
                pitch_floor,
                pitch_ceiling
            );
            return RPitch(create_xptr_from_auto<structPitch>(pitch));
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to extract pitch from sound");
        }
    }

    // ========================================================================
    // Properties (read-only)
    // ========================================================================

    bool is_valid() {
        return ptr.get() != nullptr;
    }

    double get_xmin() {
        if (!is_valid()) return NA_REAL;
        return ptr->xmin;
    }

    double get_xmax() {
        if (!is_valid()) return NA_REAL;
        return ptr->xmax;
    }

    double get_duration() {
        if (!is_valid()) return NA_REAL;
        return ptr->xmax - ptr->xmin;
    }

    int get_nx() {
        if (!is_valid()) return NA_INTEGER;
        return ptr->nx;
    }

    double get_dx() {
        if (!is_valid()) return NA_REAL;
        return ptr->dx;
    }

    double get_x1() {
        if (!is_valid()) return NA_REAL;
        return ptr->x1;
    }

    double get_ceiling() {
        if (!is_valid()) return NA_REAL;
        return ptr->ceiling;
    }

    // ========================================================================
    // Time Domain Query Methods
    // ========================================================================

    double get_time_from_frame(int frame_number) {
        VALIDATE_PTR(ptr, Pitch);
        VALIDATE_FRAME_RANGE(ptr, frame_number);
        return Sampled_indexToX(ptr.get(), frame_number);
    }

    int get_frame_from_time(double time) {
        VALIDATE_PTR(ptr, Pitch);
        return (int)Sampled_xToNearestIndex(ptr.get(), time);
    }

    int get_number_of_frames() {
        VALIDATE_PTR(ptr, Pitch);
        return ptr->nx;
    }

    double get_time_step() {
        VALIDATE_PTR(ptr, Pitch);
        return ptr->dx;
    }

    // ========================================================================
    // Pitch Value Query Methods
    // ========================================================================

    double get_value_at_time(double time, int unit, bool interpolate) {
        VALIDATE_PTR(ptr, Pitch);
        try {
            return Pitch_getValueAtTime(
                ptr.get(),
                time,
                static_cast<kPitch_unit>(unit),
                interpolate
            );
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to get pitch value at time");
        }
    }

    double get_mean(double from_time, double to_time, int unit) {
        VALIDATE_PTR(ptr, Pitch);
        try {
            return Pitch_getMean(
                ptr.get(),
                from_time,
                to_time,
                static_cast<kPitch_unit>(unit)
            );
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to get mean pitch");
        }
    }

    double get_standard_deviation(double from_time, double to_time, int unit) {
        VALIDATE_PTR(ptr, Pitch);
        try {
            return Pitch_getStandardDeviation(
                ptr.get(),
                from_time,
                to_time,
                static_cast<kPitch_unit>(unit)
            );
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to get pitch standard deviation");
        }
    }

    double get_quantile(double from_time, double to_time, double quantile, int unit) {
        VALIDATE_PTR(ptr, Pitch);
        try {
            return Pitch_getQuantile(
                ptr.get(),
                from_time,
                to_time,
                quantile,
                static_cast<kPitch_unit>(unit)
            );
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to get pitch quantile");
        }
    }

    double get_minimum(double from_time, double to_time, int unit, bool interpolate) {
        VALIDATE_PTR(ptr, Pitch);
        try {
            return Pitch_getMinimum(
                ptr.get(),
                from_time,
                to_time,
                static_cast<kPitch_unit>(unit),
                interpolate
            );
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to get minimum pitch");
        }
    }

    double get_maximum(double from_time, double to_time, int unit, bool interpolate) {
        VALIDATE_PTR(ptr, Pitch);
        try {
            return Pitch_getMaximum(
                ptr.get(),
                from_time,
                to_time,
                static_cast<kPitch_unit>(unit),
                interpolate
            );
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to get maximum pitch");
        }
    }

    double get_time_of_minimum(double from_time, double to_time, int unit, bool interpolate) {
        VALIDATE_PTR(ptr, Pitch);
        try {
            return Pitch_getTimeOfMinimum(
                ptr.get(),
                from_time,
                to_time,
                static_cast<kPitch_unit>(unit),
                interpolate
            );
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to get time of minimum pitch");
        }
    }

    double get_time_of_maximum(double from_time, double to_time, int unit, bool interpolate) {
        VALIDATE_PTR(ptr, Pitch);
        try {
            return Pitch_getTimeOfMaximum(
                ptr.get(),
                from_time,
                to_time,
                static_cast<kPitch_unit>(unit),
                interpolate
            );
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to get time of maximum pitch");
        }
    }

    int count_voiced_frames() {
        VALIDATE_PTR(ptr, Pitch);
        try {
            return (int)Pitch_countVoicedFrames(ptr.get());
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to count voiced frames");
        }
    }

    // ========================================================================
    // Batch Statistics (NEW - Performance Enhancement)
    // ========================================================================

    List get_statistics(double from_time, double to_time, int unit, 
                        CharacterVector metrics) {
        VALIDATE_PTR(ptr, Pitch);
        
        if (from_time == 0 && to_time == 0) {
            from_time = ptr->xmin;
            to_time = ptr->xmax;
        }
        
        List result;
        kPitch_unit pitch_unit = static_cast<kPitch_unit>(unit);
        
        try {
            for (int i = 0; i < metrics.size(); i++) {
                std::string metric = Rcpp::as<std::string>(metrics[i]);
                
                if (metric == "minimum" || metric == "min") {
                    double val = Pitch_getMinimum(ptr.get(), from_time, to_time, 
                                                 pitch_unit, false);
                    result[metric] = val;
                    
                } else if (metric == "maximum" || metric == "max") {
                    double val = Pitch_getMaximum(ptr.get(), from_time, to_time, 
                                                 pitch_unit, false);
                    result[metric] = val;
                    
                } else if (metric == "mean") {
                    double val = Pitch_getMean(ptr.get(), from_time, to_time, 
                                              pitch_unit);
                    result[metric] = val;
                    
                } else if (metric == "stdev" || metric == "standard_deviation" || metric == "sd") {
                    double val = Pitch_getStandardDeviation(ptr.get(), from_time, to_time, 
                                                           pitch_unit);
                    result[metric] = val;
                    
                } else if (metric == "median") {
                    double val = Pitch_getQuantile(ptr.get(), from_time, to_time, 
                                                  0.5, pitch_unit);
                    result[metric] = val;
                    
                } else if (metric == "quantile25" || metric == "q25" || metric == "q1") {
                    double val = Pitch_getQuantile(ptr.get(), from_time, to_time, 
                                                  0.25, pitch_unit);
                    result[metric] = val;
                    
                } else if (metric == "quantile75" || metric == "q75" || metric == "q3") {
                    double val = Pitch_getQuantile(ptr.get(), from_time, to_time, 
                                                  0.75, pitch_unit);
                    result[metric] = val;
                    
                } else if (metric == "count_voiced" || metric == "voiced_frames") {
                    int val = (int)Pitch_countVoicedFrames(ptr.get());
                    result[metric] = val;
                    
                } else {
                    Rcpp::warning("Unknown metric: %s", metric.c_str());
                }
            }
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to calculate pitch statistics");
        }
        
        return result;
    }

    List get_adaptive_range(double q1_factor, double q3_factor, 
                           double from_time, double to_time, int unit) {
        VALIDATE_PTR(ptr, Pitch);
        
        if (from_time == 0 && to_time == 0) {
            from_time = ptr->xmin;
            to_time = ptr->xmax;
        }
        
        kPitch_unit pitch_unit = static_cast<kPitch_unit>(unit);
        
        try {
            // Get quartiles using Praat functions
            double q1 = Pitch_getQuantile(ptr.get(), from_time, to_time, 
                                         0.25, pitch_unit);
            double q3 = Pitch_getQuantile(ptr.get(), from_time, to_time, 
                                         0.75, pitch_unit);
            
            // Calculate adaptive range in C++ (no R boundary crossing)
            double min_pitch = q1 * q1_factor;
            double max_pitch = q3 * q3_factor;
            
            return List::create(
                Named("q1") = q1,
                Named("q3") = q3,
                Named("min_pitch") = min_pitch,
                Named("max_pitch") = max_pitch
            );
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to calculate adaptive pitch range");
        }
    }

    // ========================================================================
    // Strength Query Methods
    // ========================================================================

    double get_strength_at_time(double time, int unit, bool interpolate) {
        VALIDATE_PTR(ptr, Pitch);
        try {
            return Pitch_getStrengthAtTime(
                ptr.get(),
                time,
                static_cast<kPitch_unit>(unit),
                interpolate
            );
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to get pitch strength at time");
        }
    }

    double get_mean_strength(double from_time, double to_time, int unit) {
        VALIDATE_PTR(ptr, Pitch);
        try {
            return Pitch_getMeanStrength(
                ptr.get(),
                from_time,
                to_time,
                unit
            );
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to get mean pitch strength");
        }
    }

    // ========================================================================
    // Intensity Query Methods (frame intensity, not Intensity object)
    // ========================================================================

    double get_intensity_at_time(double time) {
        VALIDATE_PTR(ptr, Pitch);
        integer iframe = Sampled_xToNearestIndex(ptr.get(), time);
        if (iframe < 1 || iframe > ptr->nx) {
            return NA_REAL;
        }
        Pitch_Frame frame = &ptr->frames[iframe];
        return frame->intensity;
    }

    double get_mean_intensity(double from_time, double to_time) {
        VALIDATE_PTR(ptr, Pitch);
        integer ifrom = Sampled_xToHighIndex(ptr.get(), from_time);
        integer ito = Sampled_xToLowIndex(ptr.get(), to_time);

        if (ifrom < 1) ifrom = 1;
        if (ito > ptr->nx) ito = ptr->nx;
        if (ifrom > ito) return NA_REAL;

        double sum = 0.0;
        integer count = 0;
        for (integer i = ifrom; i <= ito; i++) {
            Pitch_Frame frame = &ptr->frames[i];
            if (frame->intensity > 0.0) {
                sum += frame->intensity;
                count++;
            }
        }
        return (count > 0) ? (sum / count) : NA_REAL;
    }

    // ========================================================================
    // Export Methods
    // ========================================================================

    // Direct vector access (NEW - Performance Enhancement)
    // Faster than as_data_frame() when you only need times or values
    Rcpp::NumericVector get_times_vector() {
        VALIDATE_PTR(ptr, Pitch);
        integer nx = ptr->nx;
        Rcpp::NumericVector times(nx);
        
        for (integer i = 1; i <= nx; i++) {
            times[i-1] = Sampled_indexToX(ptr.get(), i);
        }
        
        return times;
    }
    
    Rcpp::NumericVector get_values_vector(int unit = 0) {
        VALIDATE_PTR(ptr, Pitch);
        integer nx = ptr->nx;
        Rcpp::NumericVector values(nx);
        kPitch_unit pitch_unit = static_cast<kPitch_unit>(unit);
        
        for (integer i = 1; i <= nx; i++) {
            double t = Sampled_indexToX(ptr.get(), i);
            double val = Pitch_getValueAtTime(ptr.get(), t, pitch_unit, false);
            // Return NA for unvoiced frames
            values[i-1] = (val > 0 && val < ptr->ceiling) ? val : NA_REAL;
        }
        
        return values;
    }

    Rcpp::NumericMatrix as_matrix() {
        VALIDATE_PTR(ptr, Pitch);
        integer nx = ptr->nx;
        Rcpp::NumericMatrix result(nx, 2);

        for (integer i = 1; i <= nx; i++) {
            double time = Sampled_indexToX(ptr.get(), i);
            double freq = Pitch_getValueAtTime(ptr.get(), time, kPitch_unit::HERTZ, false);
            result(i-1, 0) = time;
            result(i-1, 1) = (freq > 0 && freq < ptr->ceiling) ? freq : NA_REAL;
        }

        colnames(result) = CharacterVector::create("time", "frequency");
        return result;
    }

    Rcpp::DataFrame as_data_frame(bool include_strength, bool include_intensity) {
        VALIDATE_PTR(ptr, Pitch);
        integer nx = ptr->nx;

        Rcpp::NumericVector time(nx);
        Rcpp::NumericVector frequency(nx);
        Rcpp::LogicalVector voiced(nx);
        Rcpp::NumericVector strength(nx);
        Rcpp::NumericVector intensity(nx);

        for (integer i = 1; i <= nx; i++) {
            double t = Sampled_indexToX(ptr.get(), i);
            double freq = Pitch_getValueAtTime(ptr.get(), t, kPitch_unit::HERTZ, false);
            bool is_voiced = (freq > 0 && freq < ptr->ceiling);

            time[i-1] = t;
            frequency[i-1] = is_voiced ? freq : NA_REAL;
            voiced[i-1] = is_voiced;

            if (include_strength) {
                double str = Pitch_getStrengthAtTime(ptr.get(), t, kPitch_unit::HERTZ, false);
                strength[i-1] = (str >= 0) ? str : NA_REAL;
            }

            if (include_intensity) {
                Pitch_Frame frame = &ptr->frames[i];
                intensity[i-1] = frame->intensity;
            }
        }

        if (include_strength && include_intensity) {
            return DataFrame::create(
                Named("time") = time,
                Named("frequency") = frequency,
                Named("voiced") = voiced,
                Named("strength") = strength,
                Named("intensity") = intensity
            );
        } else if (include_strength) {
            return DataFrame::create(
                Named("time") = time,
                Named("frequency") = frequency,
                Named("voiced") = voiced,
                Named("strength") = strength
            );
        } else if (include_intensity) {
            return DataFrame::create(
                Named("time") = time,
                Named("frequency") = frequency,
                Named("voiced") = voiced,
                Named("intensity") = intensity
            );
        } else {
            return DataFrame::create(
                Named("time") = time,
                Named("frequency") = frequency,
                Named("voiced") = voiced
            );
        }
    }

    Rcpp::DataFrame get_all_candidates() {
        VALIDATE_PTR(ptr, Pitch);

        // Count total candidates
        integer total_candidates = 0;
        for (integer i = 1; i <= ptr->nx; i++) {
            Pitch_Frame frame = &ptr->frames[i];
            total_candidates += frame->nCandidates;
        }

        // Allocate vectors
        Rcpp::NumericVector times(total_candidates);
        Rcpp::IntegerVector frame_nums(total_candidates);
        Rcpp::IntegerVector candidate_nums(total_candidates);
        Rcpp::NumericVector frequencies(total_candidates);
        Rcpp::NumericVector strengths(total_candidates);

        // Fill vectors
        integer idx = 0;
        for (integer i = 1; i <= ptr->nx; i++) {
            Pitch_Frame frame = &ptr->frames[i];
            double t = Sampled_indexToX(ptr.get(), i);

            for (integer j = 1; j <= frame->nCandidates; j++) {
                times[idx] = t;
                frame_nums[idx] = (int)i;
                candidate_nums[idx] = (int)j;
                frequencies[idx] = frame->candidates[j].frequency;
                strengths[idx] = frame->candidates[j].strength;
                idx++;
            }
        }

        return DataFrame::create(
            Named("time") = times,
            Named("frame") = frame_nums,
            Named("candidate") = candidate_nums,
            Named("frequency") = frequencies,
            Named("strength") = strengths
        );
    }

    // ========================================================================
    // Save Method
    // ========================================================================

    void save(std::string path) {
        VALIDATE_PTR(ptr, Pitch);
        try {
            structMelderFile file = {};
            Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
            Data_writeToTextFile(ptr.get(), &file);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to save pitch to file: " + path);
        }
    }

    // ========================================================================
    // Transform Methods - Return XPtrs for R-side wrapping
    // ========================================================================

    Rcpp::XPtr<structPointProcess> to_point_process_ptr() {
        VALIDATE_PTR(ptr, Pitch);
        try {
            autoPointProcess pp = Pitch_to_PointProcess(ptr.get());
            return create_xptr_from_auto<structPointProcess>(pp);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to convert Pitch to PointProcess");
        }
    }

    Rcpp::XPtr<structPitchTier> down_to_pitch_tier_ptr() {
        VALIDATE_PTR(ptr, Pitch);
        try {
            autoPitchTier tier = Pitch_to_PitchTier(ptr.get());
            return create_xptr_from_auto<structPitchTier>(tier);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to convert Pitch to PitchTier");
        }
    }

    Rcpp::XPtr<structTextGrid> to_textgrid_vuv_ptr() {
        VALIDATE_PTR(ptr, Pitch);
        try {
            autoTextGrid tg = TextGrid_create(
                ptr->xmin,
                ptr->xmax,
                U"vuv", U""
            );

            IntervalTier tier = TextGrid_checkSpecifiedTierIsIntervalTier(tg.get(), 1);
            tier->intervals.removeAllItems();

            double start = ptr->xmin;
            bool voiced = false;

            for (integer i = 1; i <= ptr->nx; i++) {
                double t = Sampled_indexToX(ptr.get(), i);
                double f = Pitch_getValueAtTime(ptr.get(), t, kPitch_unit::HERTZ, false);
                bool v = isdefined(f) && f > 0.0;

                if (i == 1) {
                    voiced = v;
                } else if (v != voiced || i == ptr->nx) {
                    double end = (i == ptr->nx) ? ptr->xmax : t;
                    autoTextInterval iv = TextInterval_create(start, end, voiced ? U"V" : U"U");
                    tier->intervals.addItem_move(iv.move());
                    start = t;
                    voiced = v;
                }
            }

            return create_xptr_from_auto<structTextGrid>(tg);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to create VUV TextGrid");
        }
    }

    Rcpp::XPtr<structTextGrid> to_textgrid_silences_ptr(
        double min_silent_dur, double min_sounding_dur
    ) {
        VALIDATE_PTR(ptr, Pitch);
        try {
            autoTextGrid tg = TextGrid_create(ptr->xmin, ptr->xmax, U"silences", U"");
            IntervalTier tier = TextGrid_checkSpecifiedTierIsIntervalTier(tg.get(), 1);
            tier->intervals.removeAllItems();

            double start = ptr->xmin;
            bool silent = true;

            for (integer i = 1; i <= ptr->nx; i++) {
                double t = Sampled_indexToX(ptr.get(), i);
                double f = Pitch_getValueAtTime(ptr.get(), t, kPitch_unit::HERTZ, false);
                bool s = !isdefined(f) || f <= 0.0;

                if (i == 1) {
                    silent = s;
                } else if (s != silent) {
                    double dur = t - start;
                    bool add = silent ? (dur >= min_silent_dur) : (dur >= min_sounding_dur);
                    if (add) {
                        autoTextInterval iv = TextInterval_create(start, t, silent ? U"silent" : U"sounding");
                        tier->intervals.addItem_move(iv.move());
                    }
                    start = t;
                    silent = s;
                }
            }

            // Final interval
            double dur = ptr->xmax - start;
            bool add = silent ? (dur >= min_silent_dur) : (dur >= min_sounding_dur);
            if (add) {
                autoTextInterval iv = TextInterval_create(start, ptr->xmax, silent ? U"silent" : U"sounding");
                tier->intervals.addItem_move(iv.move());
            }

            return create_xptr_from_auto<structTextGrid>(tg);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to create silence TextGrid");
        }
    }

    // ========================================================================
    // Debug Methods
    // ========================================================================

    Rcpp::List debug_candidates(int max_frames) {
        VALIDATE_PTR(ptr, Pitch);
        Rcpp::List result;
        integer n_frames = ptr->nx < max_frames ? ptr->nx : max_frames;

        for (integer i = 1; i <= n_frames; i++) {
            Pitch_Frame frame = &ptr->frames[i];
            double t = Sampled_indexToX(ptr.get(), i);

            Rcpp::NumericVector freqs(frame->nCandidates);
            Rcpp::NumericVector strengths(frame->nCandidates);

            for (integer j = 1; j <= frame->nCandidates; j++) {
                freqs[j-1] = frame->candidates[j].frequency;
                strengths[j-1] = frame->candidates[j].strength;
            }

            result.push_back(Rcpp::List::create(
                Named("time") = t,
                Named("nCandidates") = (int)frame->nCandidates,
                Named("frequencies") = freqs,
                Named("strengths") = strengths,
                Named("ceiling") = ptr->ceiling
            ));
        }

        return result;
    }
};

// ============================================================================
// Module Registration
// ============================================================================

RCPP_MODULE(pitch_module) {
    using namespace Rcpp;

    class_<RPitch>("RPitch")
        // Constructors
        .constructor()
        .constructor<XPtr<structPitch>>()

        // Properties (FAST ACCESS - 2-3x faster than methods)
        .property("xmin", &RPitch::get_xmin, "Start time")
        .property("xmax", &RPitch::get_xmax, "End time")
        .property("duration", &RPitch::get_duration, "Duration in seconds")
        .property("nx", &RPitch::get_nx, "Number of frames")
        .property("dx", &RPitch::get_dx, "Time step")
        .property("x1", &RPitch::get_x1, "Time of first frame")
        .property("ceiling", &RPitch::get_ceiling, "Pitch ceiling")
        
        // Backward compatible method names
        .method("is_valid", &RPitch::is_valid, "Check if pointer is valid")
        .method("get_xmin", &RPitch::get_xmin, "Start time")
        .method("get_xmax", &RPitch::get_xmax, "End time")
        .method("get_duration", &RPitch::get_duration, "Duration in seconds")
        .method("get_nx", &RPitch::get_nx, "Number of frames")
        .method("get_dx", &RPitch::get_dx, "Time step")
        .method("get_x1", &RPitch::get_x1, "Time of first frame")
        .method("get_ceiling", &RPitch::get_ceiling, "Pitch ceiling")

        // Time domain methods
        .method("get_time_from_frame", &RPitch::get_time_from_frame, "Get time from frame number")
        .method("get_frame_from_time", &RPitch::get_frame_from_time, "Get frame number from time")
        .method("get_number_of_frames", &RPitch::get_number_of_frames, "Get total number of frames")
        .method("get_time_step", &RPitch::get_time_step, "Get time step between frames")

        // Pitch value methods
        .method("get_value_at_time", &RPitch::get_value_at_time, "Get pitch at time")
        .method("get_mean", &RPitch::get_mean, "Get mean pitch in time range")
        .method("get_standard_deviation", &RPitch::get_standard_deviation, "Get pitch SD")
        .method("get_quantile", &RPitch::get_quantile, "Get pitch quantile")
        .method("get_minimum", &RPitch::get_minimum, "Get minimum pitch")
        .method("get_maximum", &RPitch::get_maximum, "Get maximum pitch")
        .method("get_time_of_minimum", &RPitch::get_time_of_minimum, "Get time of min pitch")
        .method("get_time_of_maximum", &RPitch::get_time_of_maximum, "Get time of max pitch")
        .method("count_voiced_frames", &RPitch::count_voiced_frames, "Count voiced frames")

        // Batch statistics (fast - single call for multiple metrics)
        .method("get_statistics", &RPitch::get_statistics, "Get multiple statistics in one call")
        .method("get_adaptive_range", &RPitch::get_adaptive_range, "Calculate adaptive pitch range from quartiles")

        // Strength methods
        .method("get_strength_at_time", &RPitch::get_strength_at_time, "Get pitch strength at time")
        .method("get_mean_strength", &RPitch::get_mean_strength, "Get mean pitch strength")

        // Intensity methods (frame intensity)
        .method("get_intensity_at_time", &RPitch::get_intensity_at_time, "Get frame intensity at time")
        .method("get_mean_intensity", &RPitch::get_mean_intensity, "Get mean frame intensity")

        // Direct vector access (fast - avoids data.frame overhead)
        .method("get_times_vector", &RPitch::get_times_vector, "Get all frame times as vector")
        .method("get_values_vector", &RPitch::get_values_vector, "Get all F0 values as vector")

        // Export methods
        .method("as_matrix", &RPitch::as_matrix, "Convert to matrix")
        .method("as_data_frame", &RPitch::as_data_frame, "Convert to data frame")
        .method("get_all_candidates", &RPitch::get_all_candidates, "Get all pitch candidates")

        // Save method
        .method("save", &RPitch::save, "Save to Praat text file")

        // Transform methods (return XPtrs for R-side wrapping)
        .method("to_point_process_ptr", &RPitch::to_point_process_ptr, "Convert to PointProcess")
        .method("down_to_pitch_tier_ptr", &RPitch::down_to_pitch_tier_ptr, "Convert to PitchTier")
        .method("to_textgrid_vuv_ptr", &RPitch::to_textgrid_vuv_ptr, "Create VUV TextGrid")
        .method("to_textgrid_silences_ptr", &RPitch::to_textgrid_silences_ptr, "Create silence TextGrid")

        // Debug methods
        .method("debug_candidates", &RPitch::debug_candidates, "Debug: show candidates")
    ;
}
