// SIMD-optimized sound conversion operations
// Implements Priority 1, Task 1.2 from SIMD_OPTIMIZATION_PLAN.md

#include <Rcpp.h>
#include "praat.github.io/sys/oo.h"
#include "praat.github.io/fon/Sound.h"

#ifdef RCPPXSIMD_XSIMD_HPP
#include <xsimd/xsimd.hpp>

namespace {

// SIMD-optimized stereo to mono conversion
void convert_stereo_to_mono_simd(constVEC const& ch1, constVEC const& ch2, VEC output) {
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;
    
    const integer n = ch1.size;
    const batch scale(0.5);
    
    integer i = 1;
    
    // Process SIMD-aligned portions
    for (; i + simd_size <= n; i += simd_size) {
        batch a = xsimd::load_unaligned(&ch1[i]);
        batch b = xsimd::load_unaligned(&ch2[i]);
        batch result = scale * (a + b);
        xsimd::store_unaligned(&output[i], result);
    }
    
    // Process remainder scalar-wise
    for (; i <= n; ++i) {
        output[i] = 0.5 * (ch1[i] + ch2[i]);
    }
}

// SIMD-optimized multi-channel to mono conversion
void convert_multichannel_to_mono_simd(constMAT const& channels, VEC output) {
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;
    
    const integer n_samples = channels.ncol;
    const integer n_channels = channels.nrow;
    const double scale_factor = 1.0 / n_channels;
    const batch scale(scale_factor);
    
    integer i = 1;
    
    // Process SIMD-aligned portions
    for (; i + simd_size <= n_samples; i += simd_size) {
        batch sum(0.0);
        
        // Sum all channels
        for (integer ch = 1; ch <= n_channels; ++ch) {
            batch channel_data = xsimd::load_unaligned(&channels[ch][i]);
            sum += channel_data;
        }
        
        batch result = sum * scale;
        xsimd::store_unaligned(&output[i], result);
    }
    
    // Process remainder scalar-wise
    for (; i <= n_samples; ++i) {
        double sum = 0.0;
        for (integer ch = 1; ch <= n_channels; ++ch) {
            sum += channels[ch][i];
        }
        output[i] = sum * scale_factor;
    }
}

} // anonymous namespace

#endif // RCPPXSIMD_XSIMD_HPP

// Scalar fallback implementations
namespace {

void convert_stereo_to_mono_scalar(constVEC const& ch1, constVEC const& ch2, VEC output) {
    const integer n = ch1.size;
    for (integer i = 1; i <= n; ++i) {
        output[i] = 0.5 * (ch1[i] + ch2[i]);
    }
}

void convert_multichannel_to_mono_scalar(constMAT const& channels, VEC output) {
    const integer n_samples = channels.ncol;
    const integer n_channels = channels.nrow;
    const double scale_factor = 1.0 / n_channels;
    
    for (integer i = 1; i <= n_samples; ++i) {
        double sum = 0.0;
        for (integer ch = 1; ch <= n_channels; ++ch) {
            sum += channels[ch][i];
        }
        output[i] = sum * scale_factor;
    }
}

} // anonymous namespace

// Exported function for R
// [[Rcpp::export(.sound_convert_to_mono_simd)]]
SEXP sound_convert_to_mono(SEXP xptr) {
    Sound sound = (Sound) R_ExternalPtrAddr(xptr);
    if (!sound) {
        Rcpp::stop("Invalid Sound pointer");
    }
    
    try {
        // Optimization: if already mono, just copy
        if (sound->ny == 1) {
            autoSound mono = Data_copy(sound);
            return Rcpp::XPtr<structSound>(mono.releaseToAmbiguousOwner(), true);
        }
        
        // Create mono sound
        autoSound mono = Sound_create(1, sound->xmin, sound->xmax, 
                                       sound->nx, sound->dx, sound->x1);
        
        // Convert based on number of channels
        if (sound->ny == 2) {
            // Stereo optimization
#ifdef RCPPXSIMD_XSIMD_HPP
            convert_stereo_to_mono_simd(sound->z[1], sound->z[2], mono->z[1]);
#else
            convert_stereo_to_mono_scalar(sound->z[1], sound->z[2], mono->z[1]);
#endif
        } else {
            // Multi-channel
#ifdef RCPPXSIMD_XSIMD_HPP
            convert_multichannel_to_mono_simd(sound->z.all(), mono->z[1]);
#else
            convert_multichannel_to_mono_scalar(sound->z.all(), mono->z[1]);
#endif
        }
        
        return Rcpp::XPtr<structSound>(mono.releaseToAmbiguousOwner(), true);
        
    } catch (MelderError) {
        Melder_throw(sound, U": not converted to mono.");
        return R_NilValue;  // Never reached
    }
}
