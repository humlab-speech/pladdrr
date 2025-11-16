#ifndef SIMD_UTILS_H
#define SIMD_UTILS_H

#include <Rcpp.h>

// SIMD support temporarily disabled - using scalar fallback
// TODO: Fix xsimd v7.1.3 API usage for batch<T, N> template
#define SPEAKER_USE_SIMD 0

namespace speaker {
namespace simd {

// Scalar sum implementation (SIMD TODO)
inline double sum_array(const double* data, size_t size) {
  double result = 0.0;
  for (size_t i = 0; i < size; i++) {
    result += data[i];
  }
  return result;
}

// Scalar minimum implementation (SIMD TODO)
inline double min_array(const double* data, size_t size) {
  if (size == 0) return NAN;
  
  double result = INFINITY;
  for (size_t i = 0; i < size; i++) {
    if (data[i] < result) result = data[i];
  }
  return result;
}

// Scalar maximum implementation (SIMD TODO)
inline double max_array(const double* data, size_t size) {
  if (size == 0) return NAN;
  
  double result = -INFINITY;
  for (size_t i = 0; i < size; i++) {
    if (data[i] > result) result = data[i];
  }
  return result;
}

} // namespace simd
} // namespace speaker

#endif // SIMD_UTILS_H
