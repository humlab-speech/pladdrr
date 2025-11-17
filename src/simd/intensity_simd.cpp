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

#ifdef HAVE_XSIMD

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
    
    using batch = xsimd::batch<double, 2>;
    constexpr size_t simd_size = batch::size;
    
    double sum_squares = 0.0;
    integer total_samples = 0;
    
    // Process each channel
    for (integer ch = 1; ch <= sound->ny; ch++) {
        const double* data = &sound->z[ch][i_start];
        integer n_samples = i_end - i_start + 1;
        
        // SIMD sum of squares
        batch acc(0.0);
        integer i = 0;
        
        // Main SIMD loop
        for (; i + simd_size <= n_samples; i += simd_size) {
            batch x = xsimd::load_unaligned(&data[i]);
            acc = xsimd::fma(x, x, acc);  // acc += x * x
        }
        // Manual reduction (sum elements in acc)
        for (size_t j = 0; j < simd_size; ++j) {
            sum_squares += acc[j];
        }
        
        // Scalar remainder
        for (; i < n_samples; ++i) {
            sum_squares += data[i] * data[i];
        }
        
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
    
    using batch = xsimd::batch<double, 2>;
    constexpr size_t simd_size = batch::size;
    
    double sum_squares = 0.0;
    
    // Process each channel
    for (integer ch = 1; ch <= sound->ny; ch++) {
        const double* data = &sound->z[ch][i_start];
        integer n_samples = i_end - i_start + 1;
        
        batch acc(0.0);
        integer i = 0;
        
        // SIMD loop
        for (; i + simd_size <= n_samples; i += simd_size) {
            batch x = xsimd::load_unaligned(&data[i]);
            acc = xsimd::fma(x, x, acc);
        }
        // Manual reduction
        for (size_t j = 0; j < simd_size; ++j) {
            sum_squares += acc[j];
        }
        
        // Remainder
        for (; i < n_samples; ++i) {
            sum_squares += data[i] * data[i];
        }
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

#endif // HAVE_XSIMD
