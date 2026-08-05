/* simd_bridge.h — Unified SIMD↔Rcpp bridge utilities
 *
 * All SIMD bridge files (batch_queries_simd_bridge.cpp, textgrid_simd_bridge.cpp,
 * pitch_simd_bridge.cpp, formant_simd_bridge.cpp, mfcc_simd_bridge.cpp,
 * window_simd_bridge.cpp) repeat the same pattern: copy R vector to 1-indexed C
 * array, call SIMD function, return result. This header provides common helpers.
 *
 * Usage in bridge files:
 *   #include "simd_bridge.h"
 *   // [[Rcpp::export]]
 *   double my_mean_bridge(Rcpp::NumericVector values) {
 *       return simd_bridge_stat(values, my_mean_simd);
 *   }
 */

#ifndef PLADDRR_SIMD_BRIDGE_H
#define PLADDRR_SIMD_BRIDGE_H

#include <Rcpp.h>
#include <vector>

namespace pladdrr {

inline std::vector<double> rvec_to_indexed(const Rcpp::NumericVector& rv) {
    Rcpp::IntegerVector::size_type n = rv.size();
    if (n == 0) return {};
    std::vector<double> arr(n + 1);
    for (R_xlen_t i = 0; i < n; i++) {
        arr[i + 1] = rv[i];
    }
    return arr;
}

inline Rcpp::NumericVector indexed_to_rvec(const double* arr, int n) {
    Rcpp::NumericVector out(n);
    for (int i = 0; i < n; i++) {
        out[i] = arr[i + 1];
    }
    return out;
}

// Unary stat bridge: convert R vector → call SIMD fn → return double
template <typename F>
double simd_bridge_stat(const Rcpp::NumericVector& values, F simd_fn) {
    int n = values.size();
    if (n == 0) return NA_REAL;
    // Small inputs: scalar fallback avoids SIMD dispatch overhead (allocation + copy).
    // NEON gains are modest on arm64; below 16 elements the overhead dominates.
    if (n < 16) {
        double sum = 0.0;
        for (int i = 0; i < n; i++) sum += values[i];
        return sum / n;
    }
    std::vector<double> arr = rvec_to_indexed(values);
    return simd_fn(arr.data(), n);
}

// Direct unary bridge: pass R vector raw pointer (0-based) without copying.
// Only use with SIMD functions that accept 0-based arrays (not 1-based Praat).
// Avoids the allocation + memcpy of rvec_to_indexed for large vectors.
template <typename F>
double simd_bridge_stat_direct(const Rcpp::NumericVector& values, F simd_fn) {
    int n = values.size();
    if (n == 0) return NA_REAL;
    if (n < 16) {
        double sum = 0.0;
        for (int i = 0; i < n; i++) sum += values[i];
        return sum / n;
    }
    return simd_fn(&values[0], n);
}

// Binary op bridge: two vectors → SIMD → double
template <typename F>
double simd_bridge_binary(const Rcpp::NumericVector& a, const Rcpp::NumericVector& b, F simd_fn) {
    int n = a.size();
    if (n == 0 || b.size() != n) return NA_REAL;
    // Small inputs: scalar fallback avoids 2× allocation + copy overhead
    if (n < 16) {
        double sum = 0.0;
        for (int i = 0; i < n; i++) sum += a[i] * b[i];
        return sum;
    }
    std::vector<double> arr_a = rvec_to_indexed(a);
    std::vector<double> arr_b = rvec_to_indexed(b);
    return simd_fn(arr_a.data(), arr_b.data(), n);
}

} // namespace pladdrr

#endif // PLADDRR_SIMD_BRIDGE_H
