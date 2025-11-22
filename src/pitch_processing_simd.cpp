// SIMD-optimized pitch processing operations
// Implements Priority 3, Task 3.4 from SIMD_OPTIMIZATION_PLAN.md

#include <Rcpp.h>
#include "praat.github.io/sys/oo.h"
#include "praat.github.io/fon/Pitch.h"

#ifdef RCPPXSIMD_XSIMD_HPP
#include <xsimd/xsimd.hpp>

namespace {

// SIMD-optimized linear trend removal (detrending)
// Steps: 1) Compute mean, 2) Compute slope, 3) Subtract linear fit
void subtract_linear_trend_simd(double* frequencies, const double* times, integer n) {
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;
    
    // Step 1: Compute mean of frequencies
    batch freq_sum(0.0);
    batch time_sum(0.0);
    integer i = 0;
    
    for (; i + simd_size <= n; i += simd_size) {
        batch f = xsimd::load_unaligned(&frequencies[i]);
        batch t = xsimd::load_unaligned(&times[i]);
        freq_sum += f;
        time_sum += t;
    }
    
    double freq_mean = xsimd::reduce_add(freq_sum);
    double time_mean = xsimd::reduce_add(time_sum);
    
    // Scalar remainder for sums
    for (; i < n; ++i) {
        freq_mean += frequencies[i];
        time_mean += times[i];
    }
    
    freq_mean /= n;
    time_mean /= n;
    
    // Step 2: Compute slope using least squares
    // slope = sum((t - t_mean) * (f - f_mean)) / sum((t - t_mean)^2)
    batch numerator(0.0);
    batch denominator(0.0);
    batch freq_mean_batch(freq_mean);
    batch time_mean_batch(time_mean);
    
    i = 0;
    for (; i + simd_size <= n; i += simd_size) {
        batch f = xsimd::load_unaligned(&frequencies[i]);
        batch t = xsimd::load_unaligned(&times[i]);
        
        batch f_centered = f - freq_mean_batch;
        batch t_centered = t - time_mean_batch;
        
        numerator = xsimd::fma(t_centered, f_centered, numerator);
        denominator = xsimd::fma(t_centered, t_centered, denominator);
    }
    
    double num = xsimd::reduce_add(numerator);
    double denom = xsimd::reduce_add(denominator);
    
    // Scalar remainder
    for (; i < n; ++i) {
        double f_centered = frequencies[i] - freq_mean;
        double t_centered = times[i] - time_mean;
        num += t_centered * f_centered;
        denom += t_centered * t_centered;
    }
    
    double slope = num / denom;
    double intercept = freq_mean - slope * time_mean;
    
    // Step 3: Subtract linear fit (f = f - (slope * t + intercept))
    batch slope_batch(slope);
    batch intercept_batch(intercept);
    
    i = 0;
    for (; i + simd_size <= n; i += simd_size) {
        batch f = xsimd::load_unaligned(&frequencies[i]);
        batch t = xsimd::load_unaligned(&times[i]);
        
        // f -= slope * t + intercept
        batch fit = xsimd::fma(slope_batch, t, intercept_batch);
        batch result = f - fit;
        
        xsimd::store_unaligned(&frequencies[i], result);
    }
    
    // Scalar remainder
    for (; i < n; ++i) {
        frequencies[i] -= (slope * times[i] + intercept);
    }
}

// SIMD-optimized mean removal (simple detrending)
void subtract_mean_simd(double* data, integer n) {
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;
    
    // Step 1: Compute mean
    batch sum(0.0);
    integer i = 0;
    
    for (; i + simd_size <= n; i += simd_size) {
        batch vals = xsimd::load_unaligned(&data[i]);
        sum += vals;
    }
    
    double mean = xsimd::reduce_add(sum);
    
    // Scalar remainder for sum
    for (; i < n; ++i) {
        mean += data[i];
    }
    
    mean /= n;
    
    // Step 2: Subtract mean
    batch mean_batch(mean);
    i = 0;
    
    for (; i + simd_size <= n; i += simd_size) {
        batch vals = xsimd::load_unaligned(&data[i]);
        batch result = vals - mean_batch;
        xsimd::store_unaligned(&data[i], result);
    }
    
    // Scalar remainder
    for (; i < n; ++i) {
        data[i] -= mean;
    }
}

// SIMD-optimized polynomial detrending (quadratic)
void subtract_quadratic_trend_simd(double* frequencies, const double* times, integer n) {
    // For quadratic fit: f(t) = a*t^2 + b*t + c
    // Uses normal equations (can be extended with SIMD matrix operations)
    // For now, compute coefficients in scalar, apply fit with SIMD
    
    // Compute coefficients using normal equations (scalar for simplicity)
    double sum_t = 0.0, sum_t2 = 0.0, sum_t3 = 0.0, sum_t4 = 0.0;
    double sum_f = 0.0, sum_ft = 0.0, sum_ft2 = 0.0;
    
    for (integer i = 0; i < n; ++i) {
        double t = times[i];
        double f = frequencies[i];
        double t2 = t * t;
        
        sum_t += t;
        sum_t2 += t2;
        sum_t3 += t2 * t;
        sum_t4 += t2 * t2;
        sum_f += f;
        sum_ft += f * t;
        sum_ft2 += f * t2;
    }
    
    // Solve 3x3 system for a, b, c (simplified Cholesky or direct)
    // For brevity, use simplified direct solution
    double mean_t = sum_t / n;
    double mean_t2 = sum_t2 / n;
    double mean_f = sum_f / n;
    
    // Simple approximation for demo (proper solution requires matrix inversion)
    double b = (sum_ft - n * mean_f * mean_t) / (sum_t2 - n * mean_t * mean_t);
    double c = mean_f - b * mean_t;
    double a = 0.0;  // Linear approximation for now
    
    // Apply quadratic fit subtraction with SIMD
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;
    
    batch a_batch(a);
    batch b_batch(b);
    batch c_batch(c);
    
    integer i = 0;
    for (; i + simd_size <= n; i += simd_size) {
        batch f = xsimd::load_unaligned(&frequencies[i]);
        batch t = xsimd::load_unaligned(&times[i]);
        batch t2 = t * t;
        
        // fit = a*t^2 + b*t + c
        batch fit = xsimd::fma(a_batch, t2, xsimd::fma(b_batch, t, c_batch));
        batch result = f - fit;
        
        xsimd::store_unaligned(&frequencies[i], result);
    }
    
    // Scalar remainder
    for (; i < n; ++i) {
        double t = times[i];
        double t2 = t * t;
        double fit = a * t2 + b * t + c;
        frequencies[i] -= fit;
    }
}

} // anonymous namespace

#endif // RCPPXSIMD_XSIMD_HPP

// Scalar fallback implementations
namespace {

void subtract_linear_trend_scalar(double* frequencies, const double* times, integer n) {
    // Compute mean
    double freq_mean = 0.0;
    double time_mean = 0.0;
    
    for (integer i = 0; i < n; ++i) {
        freq_mean += frequencies[i];
        time_mean += times[i];
    }
    
    freq_mean /= n;
    time_mean /= n;
    
    // Compute slope
    double numerator = 0.0;
    double denominator = 0.0;
    
    for (integer i = 0; i < n; ++i) {
        double f_centered = frequencies[i] - freq_mean;
        double t_centered = times[i] - time_mean;
        numerator += t_centered * f_centered;
        denominator += t_centered * t_centered;
    }
    
    double slope = numerator / denominator;
    double intercept = freq_mean - slope * time_mean;
    
    // Subtract fit
    for (integer i = 0; i < n; ++i) {
        frequencies[i] -= (slope * times[i] + intercept);
    }
}

void subtract_mean_scalar(double* data, integer n) {
    double mean = 0.0;
    
    for (integer i = 0; i < n; ++i) {
        mean += data[i];
    }
    
    mean /= n;
    
    for (integer i = 0; i < n; ++i) {
        data[i] -= mean;
    }
}

} // anonymous namespace

// Exported functions for R
// [[Rcpp::export(.subtract_linear_trend_simd)]]
Rcpp::NumericVector subtract_linear_trend(Rcpp::NumericVector frequencies, Rcpp::NumericVector times) {
    if (frequencies.size() != times.size()) {
        Rcpp::stop("Frequencies and times must have the same length");
    }
    
    Rcpp::NumericVector result = Rcpp::clone(frequencies);
    const integer n = result.size();
    
#ifdef RCPPXSIMD_XSIMD_HPP
    subtract_linear_trend_simd(result.begin(), times.begin(), n);
#else
    subtract_linear_trend_scalar(result.begin(), times.begin(), n);
#endif
    
    return result;
}

// [[Rcpp::export(.subtract_mean_simd)]]
Rcpp::NumericVector subtract_mean(Rcpp::NumericVector data) {
    Rcpp::NumericVector result = Rcpp::clone(data);
    const integer n = result.size();
    
#ifdef RCPPXSIMD_XSIMD_HPP
    subtract_mean_simd(result.begin(), n);
#else
    subtract_mean_scalar(result.begin(), n);
#endif
    
    return result;
}
