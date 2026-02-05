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
// [[Rcpp::plugins(cpp17)]]

#ifdef HAVE_XSIMD
#include <xsimd/xsimd.hpp>
#endif

#include <Rcpp.h>
#include "../praat_types.h"
#include "../praat_xptr_utils.h"

// Praat headers
#include "praat.github.io/fon/Sound.h"
#include "praat.github.io/fon/Vector.h"
#include "praat.github.io/fon/Sampled.h"
#include "praat.github.io/melder/melder.h"

using namespace Rcpp;

//' SIMD-optimized sound scaling (peak amplitude)
//' @keywords internal
// [[Rcpp::export(.sound_scale_peak_simd)]]
void sound_scale_peak_simd(
    XPtr<structSound> xptr,
    double new_peak
) {
    structSound* sound = get_ptr(xptr, "Sound");
    
    try {
        // Find current maximum absolute value
        double current_max = 0.0;
        for (integer ch = 1; ch <= sound->ny; ch++) {
            for (integer i = 1; i <= sound->nx; i++) {
                double abs_val = std::abs(sound->z[ch][i]);
                if (abs_val > current_max) {
                    current_max = abs_val;
                }
            }
        }
        
        if (current_max == 0.0) return;  // Silence, nothing to scale
        
        double scale_factor = new_peak / current_max;
        
#ifdef HAVE_XSIMD
        using batch = xsimd::batch<double>;
        constexpr size_t simd_size = batch::size;
        batch scale_vec(scale_factor);
        
        // Scale all samples
        for (integer ch = 1; ch <= sound->ny; ch++) {
            double* data = &sound->z[ch][1];
            integer i = 0;
            
            // SIMD loop
            for (; i + simd_size <= sound->nx; i += simd_size) {
                batch x = xsimd::load_unaligned(&data[i]);
                batch scaled = x * scale_vec;
                xsimd::store_unaligned(&data[i], scaled);
            }
            
            // Remainder
            for (; i < sound->nx; ++i) {
                data[i] *= scale_factor;
            }
        }
#else
        // Scalar fallback
        for (integer ch = 1; ch <= sound->ny; ch++) {
            for (integer i = 1; i <= sound->nx; i++) {
                sound->z[ch][i] *= scale_factor;
            }
        }
#endif
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to scale peak (SIMD)");
    }
}

//' SIMD-optimized sound mixing with balance
//' @keywords internal
// [[Rcpp::export(.sound_mix_simd)]]
XPtr<structSound> sound_mix_simd(
    XPtr<structSound> xptr1,
    XPtr<structSound> xptr2,
    double balance
) {
    structSound* sound1 = get_ptr(xptr1, "Sound");
    structSound* sound2 = get_ptr(xptr2, "Sound");
    
    try {
        // Ensure sounds have same sampling frequency
        if (sound1->dx != sound2->dx) {
            Melder_throw(U"Sounds must have same sampling frequency to mix");
        }
        
        // Create result with duration = max of the two
        double xmax = std::max(sound1->xmax, sound2->xmax);
        double xmin = std::min(sound1->xmin, sound2->xmin);
        integer nx = Melder_iceiling((xmax - xmin) / sound1->dx);
        integer ny = std::max(sound1->ny, sound2->ny);
        
        autoSound mixed = Sound_create(ny, xmin, xmax, nx, sound1->dx, sound1->x1);
        
#ifdef HAVE_XSIMD
        using batch = xsimd::batch<double>;
        constexpr size_t simd_size = batch::size;

        batch balance_vec(balance);
        batch norm_factor(1.0 / (1.0 + balance));
#endif
        
        // Mix channels with balance
        for (integer ich = 1; ich <= ny; ich++) {
            // Check if we can use fast path (sounds aligned and same duration)
            bool aligned = (sound1->xmin == sound2->xmin && 
                           sound1->xmax == sound2->xmax &&
                           sound1->nx == sound2->nx &&
                           ich <= sound1->ny && ich <= sound2->ny);
            
            if (aligned) {
                // Fast path (SIMD if available)
                const double* data1 = &sound1->z[ich][1];
                const double* data2 = &sound2->z[ich][1];
                double* result = &mixed->z[ich][1];
                
#ifdef HAVE_XSIMD
                integer i = 0;
                // SIMD mixing: (s1 + balance * s2) / (1 + balance)
                for (; i + simd_size <= sound1->nx; i += simd_size) {
                    batch v1 = xsimd::load_unaligned(&data1[i]);
                    batch v2 = xsimd::load_unaligned(&data2[i]);
                    batch mixed_val = xsimd::fma(balance_vec, v2, v1) * norm_factor;
                    xsimd::store_unaligned(&result[i], mixed_val);
                }
                
                // Remainder
                for (; i < sound1->nx; ++i) {
                    result[i] = (data1[i] + balance * data2[i]) * (1.0 / (1.0 + balance));
                }
#else
                // Scalar fallback
                for (integer i = 0; i < sound1->nx; ++i) {
                    result[i] = (data1[i] + balance * data2[i]) / (1.0 + balance);
                }
#endif
                
            } else {
                // Slow path for misaligned sounds
                for (integer i = 1; i <= nx; i++) {
                    double t = mixed->x1 + (i - 1) * mixed->dx;
                    double val1 = 0.0, val2 = 0.0;
                    
                    // Get value from sound1 if time is within range
                    if (t >= sound1->xmin && t <= sound1->xmax && ich <= sound1->ny) {
                        integer i1 = Sampled_xToNearestIndex(sound1, t);
                        if (i1 >= 1 && i1 <= sound1->nx) {
                            val1 = sound1->z[ich][i1];
                        }
                    }
                    
                    // Get value from sound2 if time is within range
                    if (t >= sound2->xmin && t <= sound2->xmax && ich <= sound2->ny) {
                        integer i2 = Sampled_xToNearestIndex(sound2, t);
                        if (i2 >= 1 && i2 <= sound2->nx) {
                            val2 = sound2->z[ich][i2];
                        }
                    }
                    
                    mixed->z[ich][i] = (val1 + balance * val2) / (1.0 + balance);
                }
            }
        }
        
        return create_xptr_from_auto<structSound>(mixed);
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to mix sounds (SIMD)");
    }
}

