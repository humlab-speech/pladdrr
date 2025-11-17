#ifndef SIMD_UTILS_H
#define SIMD_UTILS_H

#include <Rcpp.h>
#include <cmath>

// Platform-specific SIMD headers
#ifdef __ARM_NEON
  #include <arm_neon.h>
#endif

#ifdef __SSE2__
  #include <emmintrin.h>  // SSE2
#endif

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

// Sum of squares for RMS/energy calculations
inline double sum_of_squares_array(const double* data, size_t n) {
  double sum = 0.0;
  size_t i = 0;
  
#ifdef __ARM_NEON
  float64x2_t sum_vec = vdupq_n_f64(0.0);
  
  for (; i + 2 <= n; i += 2) {
    float64x2_t v = vld1q_f64(&data[i]);
    sum_vec = vfmaq_f64(sum_vec, v, v);  // sum += v * v
  }
  
  sum = vgetq_lane_f64(sum_vec, 0) + vgetq_lane_f64(sum_vec, 1);
  
#elif defined(__SSE2__)
  __m128d sum_vec = _mm_setzero_pd();
  
  for (; i + 2 <= n; i += 2) {
    __m128d v = _mm_loadu_pd(&data[i]);
    sum_vec = _mm_add_pd(sum_vec, _mm_mul_pd(v, v));
  }
  
  double sum_arr[2];
  _mm_storeu_pd(sum_arr, sum_vec);
  sum = sum_arr[0] + sum_arr[1];
#endif
  
  // Scalar remainder
  for (; i < n; i++) {
    sum += data[i] * data[i];
  }
  
  return sum;
}

// Maximum absolute value
inline double max_abs_array(const double* data, size_t n) {
  double max_val = 0.0;
  size_t i = 0;
  
#ifdef __ARM_NEON
  float64x2_t max_vec = vdupq_n_f64(0.0);
  
  for (; i + 2 <= n; i += 2) {
    float64x2_t v = vld1q_f64(&data[i]);
    float64x2_t v_abs = vabsq_f64(v);
    max_vec = vmaxq_f64(max_vec, v_abs);
  }
  
  max_val = std::max(vgetq_lane_f64(max_vec, 0), vgetq_lane_f64(max_vec, 1));
  
#elif defined(__SSE2__)
  __m128d max_vec = _mm_setzero_pd();
  __m128d sign_mask = _mm_castsi128_pd(_mm_set1_epi64x(0x7FFFFFFFFFFFFFFF));
  
  for (; i + 2 <= n; i += 2) {
    __m128d v = _mm_loadu_pd(&data[i]);
    __m128d v_abs = _mm_and_pd(v, sign_mask);
    max_vec = _mm_max_pd(max_vec, v_abs);
  }
  
  double max_arr[2];
  _mm_storeu_pd(max_arr, max_vec);
  max_val = std::max(max_arr[0], max_arr[1]);
#endif
  
  // Scalar remainder
  for (; i < n; i++) {
    double abs_val = std::abs(data[i]);
    if (abs_val > max_val) max_val = abs_val;
  }
  
  return max_val;
}

// Multiply array by scalar (in-place)
inline void multiply_scalar_array(double* data, size_t n, double scalar) {
  size_t i = 0;
  
#ifdef __ARM_NEON
  float64x2_t scalar_vec = vdupq_n_f64(scalar);
  
  for (; i + 2 <= n; i += 2) {
    float64x2_t v = vld1q_f64(&data[i]);
    v = vmulq_f64(v, scalar_vec);
    vst1q_f64(&data[i], v);
  }
  
#elif defined(__SSE2__)
  __m128d scalar_vec = _mm_set1_pd(scalar);
  
  for (; i + 2 <= n; i += 2) {
    __m128d v = _mm_loadu_pd(&data[i]);
    v = _mm_mul_pd(v, scalar_vec);
    _mm_storeu_pd(&data[i], v);
  }
#endif
  
  // Scalar remainder
  for (; i < n; i++) {
    data[i] *= scalar;
  }
}

// Copy array (optimized memcpy for doubles)
inline void copy_array(double* dst, const double* src, size_t n) {
  size_t i = 0;
  
#ifdef __ARM_NEON
  for (; i + 2 <= n; i += 2) {
    float64x2_t v = vld1q_f64(&src[i]);
    vst1q_f64(&dst[i], v);
  }
  
#elif defined(__SSE2__)
  for (; i + 2 <= n; i += 2) {
    __m128d v = _mm_loadu_pd(&src[i]);
    _mm_storeu_pd(&dst[i], v);
  }
#endif
  
  // Scalar remainder
  for (; i < n; i++) {
    dst[i] = src[i];
  }
}

} // namespace simd
} // namespace speaker

#endif // SIMD_UTILS_H
