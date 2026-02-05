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
#include "praat.github.io/fon/Sampled.h"
#include "praat.github.io/melder/melder.h"

using namespace Rcpp;

//' SIMD-optimized RMS calculation
//' @keywords internal
// [[Rcpp::export(.sound_get_rms_simd)]]
double sound_get_rms_simd(
    XPtr<structSound> xptr,
    double from_time,
    double to_time
) {
    structSound* sound = get_ptr(xptr, "Sound");
    
    if (from_time == 0.0) from_time = sound->xmin;
    if (to_time == 0.0) to_time = sound->xmax;
    
    // Convert times to sample indices
    integer i_start = Sampled_xToNearestIndex(sound, from_time);
    integer i_end = Sampled_xToNearestIndex(sound, to_time);
    if (i_start < 1) i_start = 1;
    if (i_end > sound->nx) i_end = sound->nx;
    
    double sum_squares = 0.0;
    integer total_samples = 0;
    
    // Process each channel
    for (integer ch = 1; ch <= sound->ny; ch++) {
        const double* data = &sound->z[ch][i_start];
        integer n_samples = i_end - i_start + 1;
        
#ifdef HAVE_XSIMD
        // SIMD sum of squares
        using batch = xsimd::batch<double>;
        constexpr size_t simd_size = batch::size;
        
        batch acc(0.0);
        integer i = 0;
        
        // Main SIMD loop
        for (; i + simd_size <= n_samples; i += simd_size) {
            batch x = xsimd::load_unaligned(&data[i]);
            acc = xsimd::fma(x, x, acc);  // acc += x * x
        }
        // Horizontal reduction using xsimd::reduce_add
        sum_squares += xsimd::reduce_add(acc);
        
        // Scalar remainder
        for (; i < n_samples; ++i) {
            sum_squares += data[i] * data[i];
        }
#else
        // Scalar fallback
        for (integer i = 0; i < n_samples; ++i) {
            sum_squares += data[i] * data[i];
        }
#endif
        
        total_samples += n_samples;
    }
    
    // RMS = sqrt(mean(x^2))
    double mean_square = sum_squares / total_samples;
    return std::sqrt(mean_square);
}

//' SIMD-optimized energy calculation
//' @keywords internal
// [[Rcpp::export(.sound_get_energy_simd)]]
double sound_get_energy_simd(
    XPtr<structSound> xptr,
    double from_time,
    double to_time
) {
    structSound* sound = get_ptr(xptr, "Sound");
    
    if (from_time == 0.0) from_time = sound->xmin;
    if (to_time == 0.0) to_time = sound->xmax;
    
    // Convert times to sample indices
    integer i_start = Sampled_xToNearestIndex(sound, from_time);
    integer i_end = Sampled_xToNearestIndex(sound, to_time);
    if (i_start < 1) i_start = 1;
    if (i_end > sound->nx) i_end = sound->nx;
    
    double sum_squares = 0.0;
    
    // Process each channel
    for (integer ch = 1; ch <= sound->ny; ch++) {
        const double* data = &sound->z[ch][i_start];
        integer n_samples = i_end - i_start + 1;
        
#ifdef HAVE_XSIMD
        using batch = xsimd::batch<double>;
        constexpr size_t simd_size = batch::size;
        
        batch acc(0.0);
        integer i = 0;
        
        // SIMD loop
        for (; i + simd_size <= n_samples; i += simd_size) {
            batch x = xsimd::load_unaligned(&data[i]);
            acc = xsimd::fma(x, x, acc);
        }
        // Horizontal reduction
        sum_squares += xsimd::reduce_add(acc);
        
        // Remainder
        for (; i < n_samples; ++i) {
            sum_squares += data[i] * data[i];
        }
#else
        // Scalar fallback
        for (integer i = 0; i < n_samples; ++i) {
            sum_squares += data[i] * data[i];
        }
#endif
    }
    
    // Energy = sum(x^2) * dx
    return sum_squares * sound->dx;
}

//' SIMD-optimized power calculation
//' @keywords internal
// [[Rcpp::export(.sound_get_power_simd)]]
double sound_get_power_simd(
    XPtr<structSound> xptr,
    double from_time,
    double to_time
) {
    structSound* sound = get_ptr(xptr, "Sound");
    
    if (from_time == 0.0) from_time = sound->xmin;
    if (to_time == 0.0) to_time = sound->xmax;
    
    double duration = to_time - from_time;
    if (duration <= 0.0) return 0.0;
    
    // Power = Energy / Duration
    double energy = sound_get_energy_simd(xptr, from_time, to_time);
    return energy / duration;
}

