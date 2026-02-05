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
// SIMD-optimized distance and similarity calculations
// Implements Priority 2, Task 2.3 from SIMD_OPTIMIZATION_PLAN.md

#include <Rcpp.h>
#include "praat.github.io/sys/oo.h"
#include "praat.github.io/dwsys/NUM2.h"

#ifdef HAVE_XSIMD
#include <xsimd/xsimd.hpp>

namespace {

// SIMD-optimized matrix-vector product for Mahalanobis distance
// Computes: sum_i sum_j (lowerInverse[i][j] * v[j])^2
double mahalanobis_distance_squared_simd(constMAT const& lowerInverse, constVEC const& v) {
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;
    
    const integer n = v.size;
    double totalSum = 0.0;
    
    // For each row of lowerInverse
    for (integer i = 1; i <= n; i++) {
        batch acc(0.0);
        integer j = 1;
        
        // Vectorized dot product
        for (; j + simd_size <= n; j += simd_size) {
            batch mat = xsimd::load_unaligned(&lowerInverse[i][j]);
            batch vec = xsimd::load_unaligned(&v[j]);
            acc = xsimd::fma(mat, vec, acc);
        }
        
        double rowSum = xsimd::reduce_add(acc);
        
        // Scalar remainder
        for (; j <= n; ++j) {
            rowSum += lowerInverse[i][j] * v[j];
        }
        
        // Square and accumulate
        totalSum += rowSum * rowSum;
    }
    
    return totalSum;
}

// SIMD-optimized Euclidean distance
double euclidean_distance_simd(constVEC const& x, constVEC const& y) {
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;
    
    const integer n = x.size;
    batch acc(0.0);
    integer i = 1;
    
    // Vectorized squared difference sum
    for (; i + simd_size <= n; i += simd_size) {
        batch a = xsimd::load_unaligned(&x[i]);
        batch b = xsimd::load_unaligned(&y[i]);
        batch diff = a - b;
        acc = xsimd::fma(diff, diff, acc);
    }
    
    double sum = xsimd::reduce_add(acc);
    
    // Scalar remainder
    for (; i <= n; ++i) {
        double diff = x[i] - y[i];
        sum += diff * diff;
    }
    
    return std::sqrt(sum);
}

// SIMD-optimized cosine similarity
double cosine_similarity_simd(constVEC const& x, constVEC const& y) {
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;
    
    const integer n = x.size;
    batch dot_acc(0.0);
    batch norm_x_acc(0.0);
    batch norm_y_acc(0.0);
    integer i = 1;
    
    // Vectorized computation of dot product and norms
    for (; i + simd_size <= n; i += simd_size) {
        batch a = xsimd::load_unaligned(&x[i]);
        batch b = xsimd::load_unaligned(&y[i]);
        
        dot_acc = xsimd::fma(a, b, dot_acc);
        norm_x_acc = xsimd::fma(a, a, norm_x_acc);
        norm_y_acc = xsimd::fma(b, b, norm_y_acc);
    }
    
    double dot = xsimd::reduce_add(dot_acc);
    double norm_x = xsimd::reduce_add(norm_x_acc);
    double norm_y = xsimd::reduce_add(norm_y_acc);
    
    // Scalar remainder
    for (; i <= n; ++i) {
        dot += x[i] * y[i];
        norm_x += x[i] * x[i];
        norm_y += y[i] * y[i];
    }
    
    return dot / (std::sqrt(norm_x) * std::sqrt(norm_y));
}

} // anonymous namespace

#endif // HAVE_XSIMD

// Scalar fallback implementations
namespace {

double mahalanobis_distance_squared_scalar(constMAT const& lowerInverse, constVEC const& v) {
    const integer n = v.size;
    double totalSum = 0.0;
    
    for (integer i = 1; i <= n; i++) {
        double rowSum = 0.0;
        for (integer j = 1; j <= n; ++j) {
            rowSum += lowerInverse[i][j] * v[j];
        }
        totalSum += rowSum * rowSum;
    }
    
    return totalSum;
}

double euclidean_distance_scalar(constVEC const& x, constVEC const& y) {
    const integer n = x.size;
    double sum = 0.0;
    
    for (integer i = 1; i <= n; ++i) {
        double diff = x[i] - y[i];
        sum += diff * diff;
    }
    
    return std::sqrt(sum);
}

double cosine_similarity_scalar(constVEC const& x, constVEC const& y) {
    const integer n = x.size;
    double dot = 0.0;
    double norm_x = 0.0;
    double norm_y = 0.0;
    
    for (integer i = 1; i <= n; ++i) {
        dot += x[i] * y[i];
        norm_x += x[i] * x[i];
        norm_y += y[i] * y[i];
    }
    
    return dot / (std::sqrt(norm_x) * std::sqrt(norm_y));
}

} // anonymous namespace

// Exported functions for R
// [[Rcpp::export(.euclidean_distance_simd)]]
double euclidean_distance(Rcpp::NumericVector x, Rcpp::NumericVector y) {
    if (x.size() != y.size()) {
        Rcpp::stop("Vectors must have the same length");
    }
    
    const integer n = x.size();
    constVEC vx = constVEC(x.begin(), n);
    constVEC vy = constVEC(y.begin(), n);
    
#ifdef HAVE_XSIMD
    return euclidean_distance_simd(vx, vy);
#else
    return euclidean_distance_scalar(vx, vy);
#endif
}

// [[Rcpp::export(.cosine_similarity_simd)]]
double cosine_similarity(Rcpp::NumericVector x, Rcpp::NumericVector y) {
    if (x.size() != y.size()) {
        Rcpp::stop("Vectors must have the same length");
    }
    
    const integer n = x.size();
    constVEC vx = constVEC(x.begin(), n);
    constVEC vy = constVEC(y.begin(), n);
    
#ifdef HAVE_XSIMD
    return cosine_similarity_simd(vx, vy);
#else
    return cosine_similarity_scalar(vx, vy);
#endif
}
