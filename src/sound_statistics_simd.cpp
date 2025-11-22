// SIMD-optimized sound statistics computations
// Implements Priority 1, Task 1.1 from SIMD_OPTIMIZATION_PLAN.md

#include <Rcpp.h>
#include "praat.github.io/sys/oo.h"
#include "praat.github.io/fon/Sound.h"

#ifdef RCPPXSIMD_XSIMD_HPP
#include <xsimd/xsimd.hpp>

namespace {

// SIMD-optimized statistics computation for a single channel
struct ChannelStatistics {
    double min_val;
    double max_val;
    double sum;
    double sum_of_squares;
    integer count;
};

ChannelStatistics compute_channel_statistics_simd(constVEC const& data) {
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;
    
    const integer n = data.size;
    if (n == 0) {
        return {0.0, 0.0, 0.0, 0.0, 0};
    }
    
    // Initialize with first element
    batch min_batch(data[1]);
    batch max_batch(data[1]);
    batch sum_batch(0.0);
    batch sum_sq_batch(0.0);
    
    // Process SIMD-aligned portions
    integer i = 1;
    for (; i + simd_size <= n; i += simd_size) {
        // Load data (Praat uses 1-based indexing)
        batch values = xsimd::load_unaligned(&data[i]);
        
        // Update statistics
        min_batch = xsimd::min(min_batch, values);
        max_batch = xsimd::max(max_batch, values);
        sum_batch += values;
        sum_sq_batch = xsimd::fma(values, values, sum_sq_batch);
    }
    
    // Reduce SIMD results
    double min_val = xsimd::reduce_min(min_batch);
    double max_val = xsimd::reduce_max(max_batch);
    double sum = xsimd::reduce_add(sum_batch);
    double sum_of_squares = xsimd::reduce_add(sum_sq_batch);
    
    // Process remainder scalar-wise
    for (; i <= n; ++i) {
        const double value = data[i];
        if (value < min_val) min_val = value;
        if (value > max_val) max_val = value;
        sum += value;
        sum_of_squares += value * value;
    }
    
    return {min_val, max_val, sum, sum_of_squares, n};
}

// SIMD-optimized multi-channel statistics
struct MultiChannelStatistics {
    double min_val;
    double max_val;
    double sum;
    double sum_of_squares;
    integer total_count;
};

MultiChannelStatistics compute_sound_statistics_simd(constSound sound) {
    MultiChannelStatistics overall = {
        std::numeric_limits<double>::infinity(),
        -std::numeric_limits<double>::infinity(),
        0.0,
        0.0,
        0
    };
    
    for (integer channel = 1; channel <= sound->ny; ++channel) {
        auto channel_stats = compute_channel_statistics_simd(sound->z[channel]);
        
        if (channel_stats.count > 0) {
            overall.min_val = std::min(overall.min_val, channel_stats.min_val);
            overall.max_val = std::max(overall.max_val, channel_stats.max_val);
            overall.sum += channel_stats.sum;
            overall.sum_of_squares += channel_stats.sum_of_squares;
            overall.total_count += channel_stats.count;
        }
    }
    
    return overall;
}

} // anonymous namespace

#endif // RCPPXSIMD_XSIMD_HPP

// Scalar fallback implementation
namespace {

struct MultiChannelStatistics {
    double min_val;
    double max_val;
    double sum;
    double sum_of_squares;
    integer total_count;
};

MultiChannelStatistics compute_sound_statistics_scalar(constSound sound) {
    MultiChannelStatistics stats = {
        sound->z[1][1],
        sound->z[1][1],
        0.0,
        0.0,
        0
    };
    
    for (integer channel = 1; channel <= sound->ny; ++channel) {
        constVEC const& waveform = sound->z[channel];
        for (integer i = 1; i <= sound->nx; ++i) {
            const double value = waveform[i];
            if (value < stats.min_val) stats.min_val = value;
            if (value > stats.max_val) stats.max_val = value;
            stats.sum += value;
            stats.sum_of_squares += value * value;
        }
    }
    
    stats.total_count = sound->nx * sound->ny;
    return stats;
}

} // anonymous namespace

// Exported functions for R
// [[Rcpp::export(.sound_get_statistics_simd)]]
Rcpp::List sound_get_statistics(SEXP xptr) {
    Sound sound = (Sound) R_ExternalPtrAddr(xptr);
    if (!sound) {
        Rcpp::stop("Invalid Sound pointer");
    }
    
    if (sound->nx * sound->ny == 0) {
        return Rcpp::List::create(
            Rcpp::Named("min") = R_NaReal,
            Rcpp::Named("max") = R_NaReal,
            Rcpp::Named("mean") = R_NaReal,
            Rcpp::Named("rms") = R_NaReal,
            Rcpp::Named("energy") = R_NaReal
        );
    }
    
    MultiChannelStatistics stats;
    
#ifdef RCPPXSIMD_XSIMD_HPP
    stats = compute_sound_statistics_simd(sound);
#else
    stats = compute_sound_statistics_scalar(sound);
#endif
    
    const double mean = stats.sum / stats.total_count;
    const double mean_square = stats.sum_of_squares / stats.total_count;
    const double rms = sqrt(mean_square);
    const double energy = stats.sum_of_squares * sound->dx / sound->ny;
    
    return Rcpp::List::create(
        Rcpp::Named("min") = stats.min_val,
        Rcpp::Named("max") = stats.max_val,
        Rcpp::Named("mean") = mean,
        Rcpp::Named("rms") = rms,
        Rcpp::Named("energy") = energy,
        Rcpp::Named("total_samples") = stats.total_count
    );
}
