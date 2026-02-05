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
// sound_module.cpp
// Rcpp Module exposing Sound functionality (pladdrr 2.0)

#include <Rcpp.h>
#include "module_common.h"
#include "../datatable_utils.h"

// Praat headers
#include "praat.github.io/fon/Sound.h"
#include "praat.github.io/fon/Pitch.h"
#include "praat.github.io/fon/Formant.h"
#include "praat.github.io/fon/Intensity.h"
#include "praat.github.io/fon/Harmonicity.h"
#include "praat.github.io/fon/Spectrum.h"
#include "praat.github.io/fon/Spectrogram.h"
#include "praat.github.io/fon/Ltas.h"
#include "praat.github.io/fon/PointProcess.h"
#include "praat.github.io/fon/Sound_to_Pitch.h"
#include "praat.github.io/fon/Sound_to_Formant.h"
#include "praat.github.io/fon/Sound_to_Intensity.h"
#include "praat.github.io/fon/Sound_to_Harmonicity.h"
#include "praat.github.io/fon/Sound_and_Spectrum.h"
#include "praat.github.io/fon/Sound_and_Spectrogram.h"
#include "praat.github.io/fon/Sound_to_PointProcess.h"

using namespace Rcpp;

// Custom deleter for Praat objects
template<typename T>
void praat_deleter(T* obj) {
    if (obj) forget(obj);
}

// =============================================================================
// RSound Class - Wraps Sound XPtr with methods
// =============================================================================

class RSound {
private:
    XPtr<structSound> ptr;

public:
    // Default constructor (empty)
    RSound() : ptr(R_NilValue) {}

    // Constructor from XPtr
    RSound(XPtr<structSound> xptr) : ptr(xptr) {}

    // =========================================================================
    // Validation
    // =========================================================================

    bool is_valid() {
        return ptr.get() != nullptr;
    }

    // =========================================================================
    // Time Domain Properties (inherited from Function/Sampled)
    // =========================================================================

    double get_xmin() {
        VALIDATE_PTR(ptr, Sound);
        return ptr->xmin;
    }

    double get_xmax() {
        VALIDATE_PTR(ptr, Sound);
        return ptr->xmax;
    }

    double get_duration() {
        VALIDATE_PTR(ptr, Sound);
        return ptr->xmax - ptr->xmin;
    }

    // =========================================================================
    // Sampling Properties
    // =========================================================================

    int get_nx() {
        VALIDATE_PTR(ptr, Sound);
        return static_cast<int>(ptr->nx);
    }

    double get_dx() {
        VALIDATE_PTR(ptr, Sound);
        return ptr->dx;
    }

    double get_x1() {
        VALIDATE_PTR(ptr, Sound);
        return ptr->x1;
    }

    double get_sampling_frequency() {
        VALIDATE_PTR(ptr, Sound);
        return 1.0 / ptr->dx;
    }

    int get_number_of_samples() {
        VALIDATE_PTR(ptr, Sound);
        return static_cast<int>(ptr->nx);
    }

    int get_number_of_channels() {
        VALIDATE_PTR(ptr, Sound);
        return static_cast<int>(ptr->ny);
    }

    // =========================================================================
    // Query Methods
    // =========================================================================

    double get_value_at_time(double time, int channel, int interpolation) {
        VALIDATE_PTR(ptr, Sound);
        if (channel < 1 || channel > ptr->ny) {
            Rcpp::stop("Channel out of range [1, %d]: %d", ptr->ny, channel);
        }
        // Convert channel to 0-based for indexing
        return Vector_getValueAtX(ptr.get(), time, channel, (kVector_valueInterpolation) interpolation);
    }

    double get_rms(double from_time, double to_time) {
        VALIDATE_PTR(ptr, Sound);
        if (from_time == 0 && to_time == 0) {
            from_time = ptr->xmin;
            to_time = ptr->xmax;
        }
        return Sound_getRootMeanSquare(ptr.get(), from_time, to_time);
    }

    double get_energy(double from_time, double to_time) {
        VALIDATE_PTR(ptr, Sound);
        if (from_time == 0 && to_time == 0) {
            from_time = ptr->xmin;
            to_time = ptr->xmax;
        }
        return Sound_getEnergy(ptr.get(), from_time, to_time);
    }

    double get_power(double from_time, double to_time) {
        VALIDATE_PTR(ptr, Sound);
        if (from_time == 0 && to_time == 0) {
            from_time = ptr->xmin;
            to_time = ptr->xmax;
        }
        return Sound_getPower(ptr.get(), from_time, to_time);
    }

    double get_intensity_db() {
        VALIDATE_PTR(ptr, Sound);
        return Sound_getIntensity_dB(ptr.get());
    }

    double get_minimum(double from_time, double to_time, int interpolation) {
        VALIDATE_PTR(ptr, Sound);
        if (from_time == 0 && to_time == 0) {
            from_time = ptr->xmin;
            to_time = ptr->xmax;
        }
        return Vector_getMinimum(ptr.get(), from_time, to_time, (kVector_peakInterpolation) interpolation);
    }

    double get_maximum(double from_time, double to_time, int interpolation) {
        VALIDATE_PTR(ptr, Sound);
        if (from_time == 0 && to_time == 0) {
            from_time = ptr->xmin;
            to_time = ptr->xmax;
        }
        return Vector_getMaximum(ptr.get(), from_time, to_time, (kVector_peakInterpolation) interpolation);
    }

    double get_mean(double from_time, double to_time, int channel) {
        VALIDATE_PTR(ptr, Sound);
        if (from_time == 0 && to_time == 0) {
            from_time = ptr->xmin;
            to_time = ptr->xmax;
        }
        return Vector_getMean(ptr.get(), from_time, to_time, channel);
    }

    // =========================================================================
    // Direct Data Access (NEW - Performance Enhancement)
    // =========================================================================

    NumericVector get_values(int channel = 1) {
        VALIDATE_PTR(ptr, Sound);
        
        if (channel < 1 || channel > ptr->ny) {
            Rcpp::stop("Channel out of range [1, %d]: %d", ptr->ny, channel);
        }
        
        integer n_samples = ptr->nx;
        NumericVector values(n_samples);
        
        // Direct memory access to Praat's sample array
        for (integer i = 1; i <= n_samples; i++) {
            values[i-1] = ptr->z[channel][i];  // Convert to 0-based indexing for R
        }
        
        return values;
    }

    NumericVector get_sample_times() {
        VALIDATE_PTR(ptr, Sound);
        
        integer n_samples = ptr->nx;
        NumericVector times(n_samples);
        
        // Calculate time for each sample: t = x1 + (i-1) * dx
        double time = ptr->x1;
        for (integer i = 0; i < n_samples; i++) {
            times[i] = time;
            time += ptr->dx;
        }
        
        return times;
    }

    // =========================================================================
    // Time/Sample Conversion
    // =========================================================================

    double get_time_from_sample(int sample) {
        VALIDATE_PTR(ptr, Sound);
        return Sampled_indexToX(ptr.get(), sample);
    }

    int get_sample_from_time(double time) {
        VALIDATE_PTR(ptr, Sound);
        return static_cast<int>(Sampled_xToNearestIndex(ptr.get(), time));
    }

    // =========================================================================
    // Transform Methods (return XPtrs for R-side wrapping)
    // =========================================================================

    XPtr<structPitch> to_pitch_ptr(double time_step, double pitch_floor, double pitch_ceiling) {
        VALIDATE_PTR(ptr, Sound);
        try {
            autoPitch result = Sound_to_Pitch(
                ptr.get(),
                time_step,
                pitch_floor,
                pitch_ceiling
            );
            Pitch raw = result.releaseToAmbiguousOwner();
            // Use proper deleter for Praat objects (calls forget() instead of delete)
            auto deleter = [](structPitch* thing) {
                if (thing != nullptr) forget(thing);
            };
            return XPtr<structPitch>(raw, deleter);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to create Pitch from Sound");
        }
    }

    XPtr<structFormant> to_formant_burg_ptr(
        double time_step,
        double max_formants,
        double max_frequency,
        double window_length,
        double pre_emphasis_from
    ) {
        VALIDATE_PTR(ptr, Sound);
        try {
            autoFormant result = Sound_to_Formant_burg(
                ptr.get(),
                time_step,
                max_formants,
                max_frequency,
                window_length,
                pre_emphasis_from
            );
            Formant raw = result.releaseToAmbiguousOwner();
            // Use proper deleter for Praat objects (calls forget() instead of delete)
            auto deleter = [](structFormant* thing) {
                if (thing != nullptr) forget(thing);
            };
            return XPtr<structFormant>(raw, deleter);
        } catch (MelderError) {
            std::string error_msg = "Failed to create Formant from Sound: ";
            conststring32 praat_error = Melder_getError();
            if (praat_error) {
                error_msg += Melder_peek32to8(praat_error);
            }
            Melder_clearError();
            Rcpp::stop(error_msg);
        }
    }

    XPtr<structIntensity> to_intensity_ptr(double minimum_pitch, double time_step, bool subtract_mean) {
        VALIDATE_PTR(ptr, Sound);
        try {
            autoIntensity result = Sound_to_Intensity(
                ptr.get(),
                minimum_pitch,
                time_step,
                subtract_mean
            );
            Intensity raw = result.releaseToAmbiguousOwner();
            // Use proper deleter for Praat objects (calls forget() instead of delete)
            auto deleter = [](structIntensity* thing) {
                if (thing != nullptr) forget(thing);
            };
            return XPtr<structIntensity>(raw, deleter);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to create Intensity from Sound");
        }
    }

    XPtr<structHarmonicity> to_harmonicity_cc_ptr(double time_step, double minimum_pitch, double silence_threshold, double periods_per_window) {
        VALIDATE_PTR(ptr, Sound);
        try {
            autoHarmonicity result = Sound_to_Harmonicity_cc(
                ptr.get(),
                time_step,
                minimum_pitch,
                silence_threshold,
                periods_per_window
            );
            Harmonicity raw = result.releaseToAmbiguousOwner();
            // Use proper deleter for Praat objects (calls forget() instead of delete)
            auto deleter = [](structHarmonicity* thing) {
                if (thing != nullptr) forget(thing);
            };
            return XPtr<structHarmonicity>(raw, deleter);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to create Harmonicity from Sound");
        }
    }

    XPtr<structSpectrum> to_spectrum_ptr(bool fast) {
        VALIDATE_PTR(ptr, Sound);
        try {
            autoSpectrum result = Sound_to_Spectrum(ptr.get(), fast);
            Spectrum raw = result.releaseToAmbiguousOwner();
            // Use proper deleter for Praat objects (calls forget() instead of delete)
            auto deleter = [](structSpectrum* thing) {
                if (thing != nullptr) forget(thing);
            };
            return XPtr<structSpectrum>(raw, deleter);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to create Spectrum from Sound");
        }
    }

    XPtr<structSpectrogram> to_spectrogram_ptr(
        double window_length,
        double maximum_frequency,
        double time_step,
        double frequency_step,
        int window_shape
    ) {
        VALIDATE_PTR(ptr, Sound);
        try {
            autoSpectrogram result = Sound_to_Spectrogram_e(
                ptr.get(),
                window_length,
                maximum_frequency,
                time_step,
                frequency_step,
                (kSound_to_Spectrogram_windowShape) window_shape,
                8.0,  // maximumTimeOversampling
                8.0   // maximumFreqOversampling
            );
            Spectrogram raw = result.releaseToAmbiguousOwner();
            // Use proper deleter for Praat objects (calls forget() instead of delete)
            auto deleter = [](structSpectrogram* thing) {
                if (thing != nullptr) {
                    forget(thing);
                }
            };
            return XPtr<structSpectrogram>(raw, deleter);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to create Spectrogram from Sound");
        }
    }

    XPtr<structPointProcess> to_point_process_periodic_cc_ptr(double minimum_pitch, double maximum_pitch) {
        VALIDATE_PTR(ptr, Sound);
        try {
            autoPointProcess result = Sound_to_PointProcess_periodic_cc(
                ptr.get(),
                minimum_pitch,
                maximum_pitch
            );
            PointProcess raw = result.releaseToAmbiguousOwner();
            // Use proper deleter for Praat objects (calls forget() instead of delete)
            auto deleter = [](structPointProcess* thing) {
                if (thing != nullptr) forget(thing);
            };
            return XPtr<structPointProcess>(raw, deleter);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to create PointProcess from Sound");
        }
    }

    // =========================================================================
    // Modification Methods (return new Sound XPtrs)
    // =========================================================================

    XPtr<structSound> extract_channel_ptr(int channel) {
        VALIDATE_PTR(ptr, Sound);
        if (channel < 1 || channel > ptr->ny) {
            Rcpp::stop("Channel out of range [1, %d]: %d", ptr->ny, channel);
        }
        try {
            autoSound result = Sound_extractChannel(ptr.get(), channel);
            Sound raw = result.releaseToAmbiguousOwner();
            // Use proper deleter for Praat objects (calls forget() instead of delete)
            auto deleter = [](structSound* thing) {
                if (thing != nullptr) forget(thing);
            };
            return XPtr<structSound>(raw, deleter);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to extract channel");
        }
    }

    XPtr<structSound> extract_part_ptr(double from_time, double to_time, int window_shape, double relative_width, bool preserve_times) {
        VALIDATE_PTR(ptr, Sound);
        try {
            autoSound result = Sound_extractPart(
                ptr.get(),
                from_time,
                to_time,
                (kSound_windowShape) window_shape,
                relative_width,
                preserve_times
            );
            Sound raw = result.releaseToAmbiguousOwner();
            // Use proper deleter for Praat objects (calls forget() instead of delete)
            auto deleter = [](structSound* thing) {
                if (thing != nullptr) forget(thing);
            };
            return XPtr<structSound>(raw, deleter);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to extract part");
        }
    }

    // =========================================================================
    // Advanced Performance API: XPtr Window Functions
    // These methods accept compiled C++ function pointers from RcppXPtrUtils
    // for 70x speedup over R function callbacks
    // =========================================================================

    // Apply user-defined window function via compiled XPtr (normalized time 0-1)
    // Usage: window_fn <- cppXPtr("double gauss(double t) { return exp(-t*t*16); }")
    //        sound$apply_window_xptr(window_fn)
    XPtr<structSound> apply_window_xptr(SEXP window_func_xptr) {
        VALIDATE_PTR(ptr, Sound);

        // Validate XPtr
        if (TYPEOF(window_func_xptr) != EXTPTRSXP) {
            Rcpp::stop("window_func must be an external pointer from cppXPtr()");
        }

        // Cast to function pointer type: double(*)(double)
        typedef double (*WindowFunc)(double);
        WindowFunc window_fn = *reinterpret_cast<WindowFunc*>(R_ExternalPtrAddr(window_func_xptr));

        if (!window_fn) {
            Rcpp::stop("Invalid window function pointer (NULL)");
        }

        try {
            // Create copy of sound to modify
            autoSound result = Data_copy(ptr.get());

            integer nchannels = result->ny;
            integer nsamples = result->nx;
            double duration = result->xmax - result->xmin;

            // Apply window function to each sample
            for (integer ch = 1; ch <= nchannels; ch++) {
                for (integer s = 1; s <= nsamples; s++) {
                    double t = Sampled_indexToX(result.get(), s);
                    // Normalize time to [0, 1] for window function
                    double t_norm = (t - result->xmin) / duration;
                    result->z[ch][s] *= window_fn(t_norm);
                }
            }

            Sound raw = result.releaseToAmbiguousOwner();
            // Use proper deleter for Praat objects (calls forget() instead of delete)
            auto deleter = [](structSound* thing) {
                if (thing != nullptr) forget(thing);
            };
            return XPtr<structSound>(raw, deleter);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to apply window function");
        }
    }

    // Apply user-defined sample transformation via XPtr (operates on amplitude)
    // Usage: transform_fn <- cppXPtr("double clip(double x) { return x > 0.5 ? 0.5 : x; }")
    //        sound$apply_transform_xptr(transform_fn)
    XPtr<structSound> apply_transform_xptr(SEXP transform_func_xptr) {
        VALIDATE_PTR(ptr, Sound);

        if (TYPEOF(transform_func_xptr) != EXTPTRSXP) {
            Rcpp::stop("transform_func must be an external pointer from cppXPtr()");
        }

        typedef double (*TransformFunc)(double);
        TransformFunc transform_fn = *reinterpret_cast<TransformFunc*>(R_ExternalPtrAddr(transform_func_xptr));

        if (!transform_fn) {
            Rcpp::stop("Invalid transform function pointer (NULL)");
        }

        try {
            autoSound result = Data_copy(ptr.get());

            integer nchannels = result->ny;
            integer nsamples = result->nx;

            for (integer ch = 1; ch <= nchannels; ch++) {
                for (integer s = 1; s <= nsamples; s++) {
                    result->z[ch][s] = transform_fn(result->z[ch][s]);
                }
            }

            Sound raw = result.releaseToAmbiguousOwner();
            // Use proper deleter for Praat objects (calls forget() instead of delete)
            auto deleter = [](structSound* thing) {
                if (thing != nullptr) forget(thing);
            };
            return XPtr<structSound>(raw, deleter);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to apply transform function");
        }
    }

    // =========================================================================
    // Batch/Vectorized Operations (Phase 1: Window Operations)
    // These methods loop in C++ instead of R for 50-150x speedup
    // =========================================================================

    // Get power for multiple time windows in a single call
    NumericVector get_power_windows(NumericVector window_starts, NumericVector window_ends) {
        VALIDATE_PTR(ptr, Sound);

        int n = window_starts.size();
        if (n != window_ends.size()) {
            Rcpp::stop("window_starts and window_ends must have same length");
        }

        NumericVector result(n);

        try {
            for (int i = 0; i < n; i++) {
                double from = window_starts[i];
                double to = window_ends[i];
                // Use 0,0 convention for full range
                if (from == 0 && to == 0) {
                    from = ptr->xmin;
                    to = ptr->xmax;
                }
                result[i] = Sound_getPower(ptr.get(), from, to);
            }
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to compute power windows");
        }

        return result;
    }

    // Get RMS for multiple time windows in a single call
    NumericVector get_rms_windows(NumericVector window_starts, NumericVector window_ends) {
        VALIDATE_PTR(ptr, Sound);

        int n = window_starts.size();
        if (n != window_ends.size()) {
            Rcpp::stop("window_starts and window_ends must have same length");
        }

        NumericVector result(n);

        try {
            for (int i = 0; i < n; i++) {
                double from = window_starts[i];
                double to = window_ends[i];
                if (from == 0 && to == 0) {
                    from = ptr->xmin;
                    to = ptr->xmax;
                }
                result[i] = Sound_getRootMeanSquare(ptr.get(), from, to);
            }
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to compute RMS windows");
        }

        return result;
    }

    // Get energy for multiple time windows in a single call
    NumericVector get_energy_windows(NumericVector window_starts, NumericVector window_ends) {
        VALIDATE_PTR(ptr, Sound);

        int n = window_starts.size();
        if (n != window_ends.size()) {
            Rcpp::stop("window_starts and window_ends must have same length");
        }

        NumericVector result(n);

        try {
            for (int i = 0; i < n; i++) {
                double from = window_starts[i];
                double to = window_ends[i];
                if (from == 0 && to == 0) {
                    from = ptr->xmin;
                    to = ptr->xmax;
                }
                result[i] = Sound_getEnergy(ptr.get(), from, to);
            }
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to compute energy windows");
        }

        return result;
    }

    // Get zero-crossing rate for multiple time windows
    NumericVector get_zcr_windows(NumericVector window_starts, NumericVector window_ends, int channel) {
        VALIDATE_PTR(ptr, Sound);

        int n = window_starts.size();
        if (n != window_ends.size()) {
            Rcpp::stop("window_starts and window_ends must have same length");
        }
        if (channel < 1 || channel > ptr->ny) {
            Rcpp::stop("Channel out of range [1, %d]: %d", ptr->ny, channel);
        }

        NumericVector result(n);

        try {
            for (int i = 0; i < n; i++) {
                double from = window_starts[i];
                double to = window_ends[i];
                if (from == 0 && to == 0) {
                    from = ptr->xmin;
                    to = ptr->xmax;
                }

                // Calculate zero-crossing rate manually
                integer i1 = Sampled_xToHighIndex(ptr.get(), from);
                integer i2 = Sampled_xToLowIndex(ptr.get(), to);
                if (i1 < 1) i1 = 1;
                if (i2 > ptr->nx) i2 = ptr->nx;

                integer crossings = 0;
                integer count = 0;
                for (integer j = i1; j < i2; j++) {
                    double v1 = ptr->z[channel][j];
                    double v2 = ptr->z[channel][j+1];
                    if ((v1 >= 0 && v2 < 0) || (v1 < 0 && v2 >= 0)) {
                        crossings++;
                    }
                    count++;
                }

                // ZCR = crossings per second
                double duration = (i2 - i1 + 1) * ptr->dx;
                result[i] = (duration > 0) ? (crossings / duration) : NA_REAL;
            }
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to compute ZCR windows");
        }

        return result;
    }

    // =========================================================================
    // Batch/Vectorized Operations (Phase 2: Value Extraction)
    // =========================================================================

    // Get sample values at multiple time points (with interpolation)
    NumericVector get_values_at_times(NumericVector times, int channel, int interpolation) {
        VALIDATE_PTR(ptr, Sound);

        if (channel < 1 || channel > ptr->ny) {
            Rcpp::stop("Channel out of range [1, %d]: %d", ptr->ny, channel);
        }

        int n = times.size();
        NumericVector result(n);

        try {
            kVector_valueInterpolation interp = static_cast<kVector_valueInterpolation>(interpolation);
            for (int i = 0; i < n; i++) {
                result[i] = Vector_getValueAtX(ptr.get(), times[i], channel, interp);
            }
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to get values at times");
        }

        return result;
    }

    // Get all sample values in a time range (fast, no interpolation)
    NumericVector get_values_in_range(double from_time, double to_time, int channel) {
        VALIDATE_PTR(ptr, Sound);

        if (channel < 1 || channel > ptr->ny) {
            Rcpp::stop("Channel out of range [1, %d]: %d", ptr->ny, channel);
        }

        if (from_time == 0 && to_time == 0) {
            from_time = ptr->xmin;
            to_time = ptr->xmax;
        }

        // Get sample indices for range
        integer i1 = Sampled_xToHighIndex(ptr.get(), from_time);
        integer i2 = Sampled_xToLowIndex(ptr.get(), to_time);
        if (i1 < 1) i1 = 1;
        if (i2 > ptr->nx) i2 = ptr->nx;
        if (i1 > i2) {
            return NumericVector(0);  // Empty range
        }

        integer n = i2 - i1 + 1;
        NumericVector result(n);

        for (integer i = i1; i <= i2; i++) {
            result[i - i1] = ptr->z[channel][i];
        }

        return result;
    }

    // Get sample times in a range (companion to get_values_in_range)
    NumericVector get_times_in_range(double from_time, double to_time) {
        VALIDATE_PTR(ptr, Sound);

        if (from_time == 0 && to_time == 0) {
            from_time = ptr->xmin;
            to_time = ptr->xmax;
        }

        integer i1 = Sampled_xToHighIndex(ptr.get(), from_time);
        integer i2 = Sampled_xToLowIndex(ptr.get(), to_time);
        if (i1 < 1) i1 = 1;
        if (i2 > ptr->nx) i2 = ptr->nx;
        if (i1 > i2) {
            return NumericVector(0);
        }

        integer n = i2 - i1 + 1;
        NumericVector result(n);

        for (integer i = i1; i <= i2; i++) {
            result[i - i1] = Sampled_indexToX(ptr.get(), i);
        }

        return result;
    }

    // =========================================================================
    // Batch/Filtered Window Extraction (Phase 2b: AVQI 2.9x -> 1.5x speedup)
    // Extract multiple windows, filter by power/ZCR, concatenate passing windows
    // =========================================================================

    // Helper: Calculate zero-crossing rate for a sample range
    double calculate_zcr(integer i1, integer i2, integer channel) {
        if (i1 >= i2) return 0.0;

        integer crossings = 0;
        for (integer j = i1; j < i2; j++) {
            double v1 = ptr->z[channel][j];
            double v2 = ptr->z[channel][j+1];
            if ((v1 >= 0 && v2 < 0) || (v1 < 0 && v2 >= 0)) {
                crossings++;
            }
        }

        double duration = (i2 - i1 + 1) * ptr->dx;
        return (duration > 0) ? (crossings / duration) : 0.0;
    }

    // Extract windows, filter by power and ZCR thresholds, concatenate passing windows
    // Returns a single Sound containing only the windows that pass the filter criteria
    XPtr<structSound> extract_windows_filtered_ptr(
        NumericVector window_starts,
        NumericVector window_ends,
        double min_power,
        double max_zcr,
        double overlap_time,
        int window_shape
    ) {
        VALIDATE_PTR(ptr, Sound);

        int n = window_starts.size();
        if (n != window_ends.size()) {
            Rcpp::stop("window_starts and window_ends must have same length");
        }

        try {
            // Collect passing windows
            autoSoundList list = SoundList_create();

            for (int i = 0; i < n; i++) {
                double from = window_starts[i];
                double to = window_ends[i];

                // Check power threshold
                double power = Sound_getPower(ptr.get(), from, to);
                if (min_power > 0 && power < min_power) {
                    continue;  // Skip window with insufficient power
                }

                // Check ZCR threshold if specified
                if (max_zcr > 0) {
                    integer i1 = Sampled_xToHighIndex(ptr.get(), from);
                    integer i2 = Sampled_xToLowIndex(ptr.get(), to);
                    if (i1 < 1) i1 = 1;
                    if (i2 > ptr->nx) i2 = ptr->nx;

                    double zcr = calculate_zcr(i1, i2, 1);  // Channel 1
                    if (zcr > max_zcr) {
                        continue;  // Skip window with too high ZCR (likely unvoiced)
                    }
                }

                // Extract this window and add to list
                autoSound part = Sound_extractPart(
                    ptr.get(),
                    from,
                    to,
                    (kSound_windowShape) window_shape,
                    1.0,   // relative width
                    false  // preserve times
                );
                list->addItem_move(part.move());
            }

            // If no windows passed, return empty sound
            if (list->size == 0) {
                // Create minimal silent sound
                autoSound empty = Sound_create(ptr->ny, 0.0, 0.001, 1, ptr->dx, 0.0005);
                Sound raw = empty.releaseToAmbiguousOwner();
                // Use proper deleter for Praat objects (calls forget() instead of delete)
                auto deleter = [](structSound* thing) {
                    if (thing != nullptr) forget(thing);
                };
                return XPtr<structSound>(raw, deleter);
            }

            // Concatenate all passing windows
            autoSound result = Sounds_concatenate(list.get(), overlap_time);
            Sound raw = result.releaseToAmbiguousOwner();
            // Use proper deleter for Praat objects (calls forget() instead of delete)
            auto deleter = [](structSound* thing) {
                if (thing != nullptr) forget(thing);
            };
            return XPtr<structSound>(raw, deleter);

        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to extract and filter windows");
        }
    }

    // Return filter results as a logical vector (which windows pass)
    // Useful when user wants to know which windows passed without extraction
    LogicalVector get_windows_passing_filter(
        NumericVector window_starts,
        NumericVector window_ends,
        double min_power,
        double max_zcr
    ) {
        VALIDATE_PTR(ptr, Sound);

        int n = window_starts.size();
        if (n != window_ends.size()) {
            Rcpp::stop("window_starts and window_ends must have same length");
        }

        LogicalVector passes(n);

        try {
            for (int i = 0; i < n; i++) {
                double from = window_starts[i];
                double to = window_ends[i];
                bool pass = true;

                // Check power threshold
                if (min_power > 0) {
                    double power = Sound_getPower(ptr.get(), from, to);
                    if (power < min_power) {
                        pass = false;
                    }
                }

                // Check ZCR threshold if specified
                if (pass && max_zcr > 0) {
                    integer i1 = Sampled_xToHighIndex(ptr.get(), from);
                    integer i2 = Sampled_xToLowIndex(ptr.get(), to);
                    if (i1 < 1) i1 = 1;
                    if (i2 > ptr->nx) i2 = ptr->nx;

                    double zcr = calculate_zcr(i1, i2, 1);
                    if (zcr > max_zcr) {
                        pass = false;
                    }
                }

                passes[i] = pass;
            }
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to check window filters");
        }

        return passes;
    }

    // Concatenate extracted parts batch - given already-extracted parts,
    // concatenate them with overlap
    XPtr<structSound> concatenate_parts_ptr(
        List sound_ptrs,
        double overlap_time
    ) {
        VALIDATE_PTR(ptr, Sound);

        try {
            autoSoundList list = SoundList_create();

            for (int i = 0; i < sound_ptrs.size(); i++) {
                XPtr<structSound> part_ptr = sound_ptrs[i];
                if (part_ptr && part_ptr.get()) {
                    // Need to copy since SoundList takes ownership
                    autoSound copy = Data_copy(part_ptr.get());
                    list->addItem_move(copy.move());
                }
            }

            if (list->size == 0) {
                // Create minimal silent sound
                autoSound empty = Sound_create(ptr->ny, 0.0, 0.001, 1, ptr->dx, 0.0005);
                Sound raw = empty.releaseToAmbiguousOwner();
                // Use proper deleter for Praat objects (calls forget() instead of delete)
                auto deleter = [](structSound* thing) {
                    if (thing != nullptr) forget(thing);
                };
                return XPtr<structSound>(raw, deleter);
            }

            autoSound result = Sounds_concatenate(list.get(), overlap_time);
            Sound raw = result.releaseToAmbiguousOwner();
            // Use proper deleter for Praat objects (calls forget() instead of delete)
            auto deleter = [](structSound* thing) {
                if (thing != nullptr) forget(thing);
            };
            return XPtr<structSound>(raw, deleter);

        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to concatenate sound parts");
        }
    }

    // =========================================================================
    // Export Methods
    // =========================================================================

    NumericMatrix as_matrix() {
        VALIDATE_PTR(ptr, Sound);
        integer nchannels = ptr->ny;
        integer nsamples = ptr->nx;

        NumericMatrix mat(nchannels, nsamples);
        for (integer ch = 1; ch <= nchannels; ch++) {
            for (integer s = 1; s <= nsamples; s++) {
                mat(ch - 1, s - 1) = ptr->z[ch][s];
            }
        }
        return mat;
    }

    DataFrame as_data_frame() {
        VALIDATE_PTR(ptr, Sound);
        integer nchannels = ptr->ny;
        integer nsamples = ptr->nx;

        // Long format: time, channel, value
        std::vector<double> times;
        std::vector<int> channels;
        std::vector<double> values;

        times.reserve(nchannels * nsamples);
        channels.reserve(nchannels * nsamples);
        values.reserve(nchannels * nsamples);

        for (integer ch = 1; ch <= nchannels; ch++) {
            for (integer s = 1; s <= nsamples; s++) {
                times.push_back(Sampled_indexToX(ptr.get(), s));
                channels.push_back(ch);
                values.push_back(ptr->z[ch][s]);
            }
        }

        return pladdrr::dt::create_datatable(
            List::create(
                Named("time") = times,
                Named("channel") = channels,
                Named("value") = values
            ),
            CharacterVector::create("time", "channel", "value"),
            CharacterVector::create("time", "channel")
        );
    }

    // =========================================================================
    // Save Method
    // =========================================================================

    void save(std::string path, int format) {
        VALIDATE_PTR(ptr, Sound);
        try {
            structMelderFile file = {};
            Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
            Sound_saveAsAudioFile(ptr.get(), &file, format, 16);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to save Sound to file: %s", path.c_str());
        }
    }
};

// =============================================================================
// Module Registration
// =============================================================================

RCPP_MODULE(sound_module) {
    using namespace Rcpp;

    class_<RSound>("RSound")
        // Constructors
        .constructor()
        .constructor<XPtr<structSound>>()

        // Validation
        .method("is_valid", &RSound::is_valid, "Check if pointer is valid")

        // Time domain properties (PROPERTIES for 2-3x faster access)
        .property("xmin", &RSound::get_xmin, "Start time")
        .property("xmax", &RSound::get_xmax, "End time")
        .property("duration", &RSound::get_duration, "Duration in seconds")
        
        // Sampling properties (PROPERTIES for faster access)
        .property("nx", &RSound::get_nx, "Number of samples")
        .property("dx", &RSound::get_dx, "Sample period")
        .property("x1", &RSound::get_x1, "Time of first sample")
        .property("sampling_frequency", &RSound::get_sampling_frequency, "Sampling frequency in Hz")
        .property("number_of_samples", &RSound::get_number_of_samples, "Number of samples")
        .property("number_of_channels", &RSound::get_number_of_channels, "Number of channels")
        
        // Keep old method names for backward compatibility
        .method("get_xmin", &RSound::get_xmin, "Get start time")
        .method("get_xmax", &RSound::get_xmax, "Get end time")
        .method("get_duration", &RSound::get_duration, "Get duration")
        .method("get_nx", &RSound::get_nx, "Get number of samples")
        .method("get_dx", &RSound::get_dx, "Get sample period")
        .method("get_x1", &RSound::get_x1, "Get time of first sample")
        .method("get_sampling_frequency", &RSound::get_sampling_frequency, "Get sampling frequency")
        .method("get_number_of_samples", &RSound::get_number_of_samples, "Get number of samples")
        .method("get_number_of_channels", &RSound::get_number_of_channels, "Get number of channels")

        // Query methods
        .method("get_value_at_time", &RSound::get_value_at_time, "Get amplitude at time")
        .method("get_rms", &RSound::get_rms, "Get RMS amplitude")
        .method("get_energy", &RSound::get_energy, "Get energy")
        .method("get_power", &RSound::get_power, "Get power")
        .method("get_intensity_db", &RSound::get_intensity_db, "Get intensity in dB")
        .method("get_minimum", &RSound::get_minimum, "Get minimum amplitude")
        .method("get_maximum", &RSound::get_maximum, "Get maximum amplitude")
        .method("get_mean", &RSound::get_mean, "Get mean amplitude")

        // Direct data access (fast, no data frame overhead)
        .method("get_values", &RSound::get_values, "Get sample values as vector")
        .method("get_sample_times", &RSound::get_sample_times, "Get sample times as vector")

        // Batch/Vectorized window operations (50-150x faster than R loops)
        .method("get_power_windows", &RSound::get_power_windows, "Get power for multiple windows")
        .method("get_rms_windows", &RSound::get_rms_windows, "Get RMS for multiple windows")
        .method("get_energy_windows", &RSound::get_energy_windows, "Get energy for multiple windows")
        .method("get_zcr_windows", &RSound::get_zcr_windows, "Get ZCR for multiple windows")

        // Batch/Vectorized value extraction (20x faster than R loops)
        .method("get_values_at_times", &RSound::get_values_at_times, "Get values at multiple times")
        .method("get_values_in_range", &RSound::get_values_in_range, "Get all values in time range")
        .method("get_times_in_range", &RSound::get_times_in_range, "Get sample times in range")

        // Batch/Filtered window extraction (AVQI 2.9x -> 1.5x speedup)
        .method("extract_windows_filtered_ptr", &RSound::extract_windows_filtered_ptr, "Extract and concatenate windows passing power/ZCR filter")
        .method("get_windows_passing_filter", &RSound::get_windows_passing_filter, "Check which windows pass power/ZCR filter")
        .method("concatenate_parts_ptr", &RSound::concatenate_parts_ptr, "Concatenate list of Sound parts")

        // Time/sample conversion
        .method("get_time_from_sample", &RSound::get_time_from_sample, "Convert sample to time")
        .method("get_sample_from_time", &RSound::get_sample_from_time, "Convert time to sample")

        // Transform methods (return XPtrs)
        .method("to_pitch_ptr", &RSound::to_pitch_ptr, "Create Pitch from Sound")
        .method("to_formant_burg_ptr", &RSound::to_formant_burg_ptr, "Create Formant from Sound")
        .method("to_formant_burg", &RSound::to_formant_burg_ptr, "Create Formant from Sound (alias)")
        .method("to_intensity_ptr", &RSound::to_intensity_ptr, "Create Intensity from Sound")
        .method("to_harmonicity_cc_ptr", &RSound::to_harmonicity_cc_ptr, "Create Harmonicity from Sound")
        .method("to_spectrum_ptr", &RSound::to_spectrum_ptr, "Create Spectrum from Sound")
        .method("to_spectrogram_ptr", &RSound::to_spectrogram_ptr, "Create Spectrogram from Sound")
        .method("to_point_process_periodic_cc_ptr", &RSound::to_point_process_periodic_cc_ptr, "Create PointProcess from Sound")

        // Modification methods
        .method("extract_channel_ptr", &RSound::extract_channel_ptr, "Extract single channel")
        .method("extract_part_ptr", &RSound::extract_part_ptr, "Extract time range")

        // Advanced Performance API: XPtr functions (70x faster than R callbacks)
        // Requires RcppXPtrUtils: window_fn <- cppXPtr("double f(double t) { return 1-t*t; }")
        .method("apply_window_xptr", &RSound::apply_window_xptr,
                "Apply compiled window function (t normalized 0-1)")
        .method("apply_transform_xptr", &RSound::apply_transform_xptr,
                "Apply compiled transform function to sample values")

        // Export methods
        .method("as_matrix", &RSound::as_matrix, "Export as matrix")
        .method("as_data_frame", &RSound::as_data_frame, "Export as data frame")

        // Save method
        .method("save", &RSound::save, "Save to file")
    ;
}
