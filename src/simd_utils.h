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

// SIMD support enabled
#define SPEAKER_USE_SIMD 1

namespace speaker {
namespace simd {

// SIMD-optimized sum implementation
inline double sum_array(const double* data, size_t n) {
  double sum = 0.0;
  size_t i = 0;
  
#ifdef __ARM_NEON
  float64x2_t sum_vec = vdupq_n_f64(0.0);
  
  for (; i + 2 <= n; i += 2) {
    float64x2_t v = vld1q_f64(&data[i]);
    sum_vec = vaddq_f64(sum_vec, v);
  }
  
  sum = vgetq_lane_f64(sum_vec, 0) + vgetq_lane_f64(sum_vec, 1);
  
#elif defined(__SSE2__)
  __m128d sum_vec = _mm_setzero_pd();
  
  for (; i + 2 <= n; i += 2) {
    __m128d v = _mm_loadu_pd(&data[i]);
    sum_vec = _mm_add_pd(sum_vec, v);
  }
  
  double sum_arr[2];
  _mm_storeu_pd(sum_arr, sum_vec);
  sum = sum_arr[0] + sum_arr[1];
#endif
  
  // Scalar remainder
  for (; i < n; i++) {
    sum += data[i];
  }
  
  return sum;
}

// SIMD-optimized minimum implementation
inline double min_array(const double* data, size_t n) {
  if (n == 0) return NAN;
  
  double min_val = INFINITY;
  size_t i = 0;
  
#ifdef __ARM_NEON
  float64x2_t min_vec = vdupq_n_f64(INFINITY);
  
  for (; i + 2 <= n; i += 2) {
    float64x2_t v = vld1q_f64(&data[i]);
    min_vec = vminq_f64(min_vec, v);
  }
  
  min_val = std::min(vgetq_lane_f64(min_vec, 0), vgetq_lane_f64(min_vec, 1));
  
#elif defined(__SSE2__)
  __m128d min_vec = _mm_set1_pd(INFINITY);
  
  for (; i + 2 <= n; i += 2) {
    __m128d v = _mm_loadu_pd(&data[i]);
    min_vec = _mm_min_pd(min_vec, v);
  }
  
  double min_arr[2];
  _mm_storeu_pd(min_arr, min_vec);
  min_val = std::min(min_arr[0], min_arr[1]);
#endif
  
  // Scalar remainder
  for (; i < n; i++) {
    if (data[i] < min_val) min_val = data[i];
  }
  
  return min_val;
}

// SIMD-optimized maximum implementation
inline double max_array(const double* data, size_t n) {
  if (n == 0) return NAN;
  
  double max_val = -INFINITY;
  size_t i = 0;
  
#ifdef __ARM_NEON
  float64x2_t max_vec = vdupq_n_f64(-INFINITY);
  
  for (; i + 2 <= n; i += 2) {
    float64x2_t v = vld1q_f64(&data[i]);
    max_vec = vmaxq_f64(max_vec, v);
  }
  
  max_val = std::max(vgetq_lane_f64(max_vec, 0), vgetq_lane_f64(max_vec, 1));
  
#elif defined(__SSE2__)
  __m128d max_vec = _mm_set1_pd(-INFINITY);
  
  for (; i + 2 <= n; i += 2) {
    __m128d v = _mm_loadu_pd(&data[i]);
    max_vec = _mm_max_pd(max_vec, v);
  }
  
  double max_arr[2];
  _mm_storeu_pd(max_arr, max_vec);
  max_val = std::max(max_arr[0], max_arr[1]);
#endif
  
  // Scalar remainder
  for (; i < n; i++) {
    if (data[i] > max_val) max_val = data[i];
  }
  
  return max_val;
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

// Generate sine wave: dst[i] = amplitude * sin(2*pi * frequency * (t_start + i * dt))
// This is optimized for tone generation
inline void generate_sine_wave(
    double* dst, 
    size_t n, 
    double t_start, 
    double dt, 
    double frequency, 
    double amplitude
) {
  const double two_pi_f = 2.0 * M_PI * frequency;
  const double amp = amplitude;
  
  // For very short arrays or when SIMD isn't beneficial, use scalar
  if (n < 8) {
    for (size_t i = 0; i < n; i++) {
      double t = t_start + i * dt;
      dst[i] = amp * std::sin(two_pi_f * t);
    }
    return;
  }
  
  // SIMD approach: compute times first, then sine
  // This is faster than computing sine in SIMD directly
  size_t i = 0;
  
#ifdef __ARM_NEON
  float64x2_t t_vec = vdupq_n_f64(t_start);
  float64x2_t dt_vec = {0.0, dt};
  float64x2_t dt2_vec = vdupq_n_f64(2.0 * dt);
  float64x2_t two_pi_f_vec = vdupq_n_f64(two_pi_f);
  float64x2_t amp_vec = vdupq_n_f64(amp);
  
  t_vec = vaddq_f64(t_vec, dt_vec);  // [t_start, t_start + dt]
  
  for (; i + 2 <= n; i += 2) {
    // Compute phase = 2*pi*f*t
    float64x2_t phase = vmulq_f64(two_pi_f_vec, t_vec);
    
    // Use scalar sin for now (NEON doesn't have vectorized sin)
    double phase_arr[2];
    vst1q_f64(phase_arr, phase);
    double result[2] = {amp * std::sin(phase_arr[0]), amp * std::sin(phase_arr[1])};
    vst1q_f64(&dst[i], vld1q_f64(result));
    
    t_vec = vaddq_f64(t_vec, dt2_vec);
  }
  
#elif defined(__SSE2__)
  __m128d t_vec = _mm_set_pd(t_start + dt, t_start);
  __m128d dt2_vec = _mm_set1_pd(2.0 * dt);
  __m128d two_pi_f_vec = _mm_set1_pd(two_pi_f);
  __m128d amp_vec = _mm_set1_pd(amp);
  
  for (; i + 2 <= n; i += 2) {
    // Compute phase = 2*pi*f*t
    __m128d phase = _mm_mul_pd(two_pi_f_vec, t_vec);
    
    // Use scalar sin (SSE2 doesn't have vectorized sin)
    double phase_arr[2];
    _mm_storeu_pd(phase_arr, phase);
    double result[2] = {amp * std::sin(phase_arr[0]), amp * std::sin(phase_arr[1])};
    _mm_storeu_pd(&dst[i], _mm_loadu_pd(result));
    
    t_vec = _mm_add_pd(t_vec, dt2_vec);
  }
#endif
  
  // Scalar remainder
  for (; i < n; i++) {
    double t = t_start + i * dt;
    dst[i] = amp * std::sin(two_pi_f * t);
  }
}

} // namespace simd
} // namespace speaker

#endif // SIMD_UTILS_H
