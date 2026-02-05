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
// sound_operations_module.cpp
// Rcpp Module for standalone Sound operation functions
// Part of the pladdrr package - Phase 3.1

#include <Rcpp.h>
#include "module_common.h"

// Praat headers
#include "../praat.github.io/fon/Sound.h"
#include "../praat.github.io/fon/Sound_and_Spectrum.h"

using namespace Rcpp;

// Forward declaration
extern void NUMmachar();

// ============================================================================
// Sound Operations - Free Functions
// ============================================================================

// Concatenation
XPtr<structSound> sounds_append(
    XPtr<structSound> sound1,
    double silence_duration,
    XPtr<structSound> sound2
) {
    if (sound1.get() == nullptr || sound2.get() == nullptr) {
        Rcpp::stop("Invalid Sound objects");
    }
    
    NUMmachar();
    
    try {
        autoSound result = Sounds_append(
            sound1.get(),
            silence_duration,
            sound2.get()
        );
        return create_xptr_from_auto<structSound>(result);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to append sounds");
    }
}

// Time stretching (overlap-add)
XPtr<structSound> sound_lengthen(
    XPtr<structSound> sound,
    double fmin,
    double fmax,
    double factor
) {
    if (sound.get() == nullptr) {
        Rcpp::stop("Invalid Sound object");
    }
    
    try {
        autoSound result = Sound_lengthen_overlapAdd(
            sound.get(),
            fmin, fmax, factor
        );
        return create_xptr_from_auto<structSound>(result);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to lengthen sound");
    }
}

// Band modulation deepening
XPtr<structSound> sound_deepen_band_modulation(
    XPtr<structSound> sound,
    double enhancement_db,
    double flow,
    double fhigh,
    double slow_modulation,
    double fast_modulation,
    double band_smoothing
) {
    if (sound.get() == nullptr) {
        Rcpp::stop("Invalid Sound object");
    }
    
    try {
        autoSound result = Sound_deepenBandModulation(
            sound.get(),
            enhancement_db,
            flow, fhigh,
            slow_modulation, fast_modulation,
            band_smoothing
        );
        return create_xptr_from_auto<structSound>(result);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to deepen band modulation");
    }
}

// Convolution
XPtr<structSound> sounds_convolve(
    XPtr<structSound> sound1,
    XPtr<structSound> sound2,
    int scaling,
    int signal_outside
) {
    if (sound1.get() == nullptr || sound2.get() == nullptr) {
        Rcpp::stop("Invalid Sound objects");
    }
    
    try {
        autoSound result = Sounds_convolve(
            sound1.get(),
            sound2.get(),
            static_cast<kSounds_convolve_scaling>(scaling),
            static_cast<kSounds_convolve_signalOutsideTimeDomain>(signal_outside)
        );
        return create_xptr_from_auto<structSound>(result);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to convolve sounds");
    }
}

// Cross-correlation
XPtr<structSound> sounds_cross_correlate(
    XPtr<structSound> sound1,
    XPtr<structSound> sound2,
    int scaling,
    int signal_outside
) {
    if (sound1.get() == nullptr || sound2.get() == nullptr) {
        Rcpp::stop("Invalid Sound objects");
    }
    
    try {
        autoSound result = Sounds_crossCorrelate(
            sound1.get(),
            sound2.get(),
            static_cast<kSounds_convolve_scaling>(scaling),
            static_cast<kSounds_convolve_signalOutsideTimeDomain>(signal_outside)
        );
        return create_xptr_from_auto<structSound>(result);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to cross-correlate sounds");
    }
}

// Auto-correlation
XPtr<structSound> sound_auto_correlate(
    XPtr<structSound> sound,
    int scaling,
    int signal_outside
) {
    if (sound.get() == nullptr) {
        Rcpp::stop("Invalid Sound object");
    }
    
    try {
        autoSound result = Sound_autoCorrelate(
            sound.get(),
            static_cast<kSounds_convolve_scaling>(scaling),
            static_cast<kSounds_convolve_signalOutsideTimeDomain>(signal_outside)
        );
        return create_xptr_from_auto<structSound>(result);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to auto-correlate sound");
    }
}

// ============================================================================
// Rcpp Module Definition
// ============================================================================

RCPP_MODULE(sound_operations_module) {
    using namespace Rcpp;

    // Concatenation
    function("sounds_append", &sounds_append,
        "Append two sounds with optional silence between them");
    
    // Time manipulation
    function("sound_lengthen", &sound_lengthen,
        "Lengthen (or shorten) a sound using overlap-add");
    
    // Enhancement
    function("sound_deepen_band_modulation", &sound_deepen_band_modulation,
        "Deepen band modulation for hearing-impaired listeners");
    
    // Convolution operations
    function("sounds_convolve", &sounds_convolve,
        "Convolve two sounds");
    function("sounds_cross_correlate", &sounds_cross_correlate,
        "Cross-correlate two sounds");
    function("sound_auto_correlate", &sound_auto_correlate,
        "Auto-correlate a sound with itself");
}
