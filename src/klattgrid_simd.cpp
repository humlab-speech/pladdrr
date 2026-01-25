// klattgrid_simd.cpp - SIMD optimizations for KlattGrid synthesis
// Part of Phase 4, Task 4.4: KlattGrid SIMD
// Created: 2026-01-25

#include <Rcpp.h>
#include "praat.github.io/melder/melder.h"
#include "simd_utils.h"
#include <cmath>
#include <cstdint>

#ifdef HAVE_XSIMD
#include <xsimd/xsimd.hpp>
#endif

// =============================================================================
// KlattGrid SIMD Functions
// =============================================================================
// Key operations:
// 1. Sound addition (mixing): output[i] += input[i]
// 2. Sound differencing (pre-emphasis): output[i] = input[i] - input[i-1]
// 3. Scaling: output[i] = input[i] * scale
// 4. Glottal pulse generation: optimized waveform computation
// 5. Noise generation: random number generation for aspiration/frication
// =============================================================================

namespace klattgrid_simd {

#ifdef HAVE_XSIMD

using batch_double = xsimd::batch<double>;
constexpr size_t simd_size = batch_double::size;

/**
 * Add two sound arrays in-place (SIMD)
 *
 * Implements: output[i] += input[i]
 * Used in parallel filter mixing and frication addition.
 *
 * @param output Output/accumulator array (modified in-place)
 * @param input Input array to add
 * @param n Number of samples
 */
void sounds_add_inplace_simd(
    double* output,
    const double* input,
    integer n
) {
    integer i = 0;

    // SIMD loop
    for (; i + static_cast<integer>(simd_size) <= n; i += simd_size) {
        batch_double out = xsimd::load_unaligned(&output[i]);
        batch_double in = xsimd::load_unaligned(&input[i]);
        out = out + in;
        out.store_unaligned(&output[i]);
    }

    // Scalar remainder
    for (; i < n; i++) {
        output[i] += input[i];
    }
}

/**
 * First difference (differentiation) of sound (SIMD)
 *
 * Implements: output[i] = input[i] - input[i-1]
 * Used for pre-emphasis in parallel synthesis.
 *
 * @param input Input sound samples
 * @param output Output difference signal
 * @param n Number of samples
 */
void sound_diff_simd(
    const double* input,
    double* output,
    integer n
) {
    if (n <= 0) return;

    // First sample has no predecessor
    output[0] = 0.0;

    if (n == 1) return;

    integer i = 1;

    // SIMD loop - process consecutive differences
    // We load [i-1, i, i+1, i+2, ...] and [i, i+1, i+2, i+3, ...]
    // Then compute [i] - [i-1] for all positions
    for (; i + static_cast<integer>(simd_size) <= n; i += simd_size) {
        batch_double curr = xsimd::load_unaligned(&input[i]);
        batch_double prev = xsimd::load_unaligned(&input[i - 1]);
        batch_double diff = curr - prev;
        diff.store_unaligned(&output[i]);
    }

    // Scalar remainder
    for (; i < n; i++) {
        output[i] = input[i] - input[i - 1];
    }
}

/**
 * Scale sound array (SIMD)
 *
 * Implements: output[i] = input[i] * scale
 *
 * @param input Input sound samples
 * @param output Output scaled samples
 * @param scale Scale factor
 * @param n Number of samples
 */
void sound_scale_simd(
    const double* input,
    double* output,
    double scale,
    integer n
) {
    batch_double scale_batch(scale);
    integer i = 0;

    // SIMD loop
    for (; i + static_cast<integer>(simd_size) <= n; i += simd_size) {
        batch_double in = xsimd::load_unaligned(&input[i]);
        batch_double out = in * scale_batch;
        out.store_unaligned(&output[i]);
    }

    // Scalar remainder
    for (; i < n; i++) {
        output[i] = input[i] * scale;
    }
}

/**
 * Scale sound array in-place (SIMD)
 *
 * Implements: data[i] *= scale
 *
 * @param data Sound samples (modified in-place)
 * @param scale Scale factor
 * @param n Number of samples
 */
void sound_scale_inplace_simd(
    double* data,
    double scale,
    integer n
) {
    batch_double scale_batch(scale);
    integer i = 0;

    // SIMD loop
    for (; i + static_cast<integer>(simd_size) <= n; i += simd_size) {
        batch_double d = xsimd::load_unaligned(&data[i]);
        d = d * scale_batch;
        d.store_unaligned(&data[i]);
    }

    // Scalar remainder
    for (; i < n; i++) {
        data[i] *= scale;
    }
}

/**
 * Find extremum (max absolute value) (SIMD)
 *
 * Used for amplitude normalization.
 *
 * @param data Sound samples
 * @param n Number of samples
 * @return Maximum absolute value
 */
double find_extremum_simd(
    const double* data,
    integer n
) {
    batch_double max_batch(0.0);
    integer i = 0;

    // SIMD loop
    for (; i + static_cast<integer>(simd_size) <= n; i += simd_size) {
        batch_double d = xsimd::load_unaligned(&data[i]);
        batch_double abs_d = xsimd::abs(d);
        max_batch = xsimd::max(max_batch, abs_d);
    }

    // Reduce SIMD register to scalar
    double max_val = xsimd::reduce_max(max_batch);

    // Scalar remainder
    for (; i < n; i++) {
        double abs_val = std::abs(data[i]);
        if (abs_val > max_val) {
            max_val = abs_val;
        }
    }

    return max_val;
}

/**
 * Normalize sound to range [-1, 1] (SIMD)
 *
 * @param data Sound samples (modified in-place)
 * @param n Number of samples
 * @return Scale factor applied
 */
double normalize_sound_simd(
    double* data,
    integer n
) {
    double extremum = find_extremum_simd(data, n);
    if (extremum <= 0.0) return 1.0;

    double scale = 1.0 / extremum;
    sound_scale_inplace_simd(data, scale, n);
    return scale;
}

/**
 * Glottal pulse polynomial: y^n - y^m (SIMD)
 *
 * Computes the LF model glottal flow for multiple phase values.
 *
 * @param phases Phase values (0-1)
 * @param output Flow values
 * @param power1 First power (n)
 * @param power2 Second power (m), must be > power1
 * @param n Number of points
 */
void glottal_flow_polynomial_simd(
    const double* phases,
    double* output,
    double power1,
    double power2,
    integer n
) {
    batch_double p1(power1);
    batch_double p2(power2);
    integer i = 0;

    // SIMD loop
    for (; i + static_cast<integer>(simd_size) <= n; i += simd_size) {
        batch_double y = xsimd::load_unaligned(&phases[i]);

        // flow = y^n - y^m = exp(n*log(y)) - exp(m*log(y))
        // Only valid for y > 0
        batch_double log_y = xsimd::log(y);
        batch_double term1 = xsimd::exp(p1 * log_y);
        batch_double term2 = xsimd::exp(p2 * log_y);
        batch_double flow = term1 - term2;

        flow.store_unaligned(&output[i]);
    }

    // Scalar remainder
    for (; i < n; i++) {
        double y = phases[i];
        if (y > 0.0) {
            output[i] = std::pow(y, power1) - std::pow(y, power2);
        } else {
            output[i] = 0.0;
        }
    }
}

/**
 * Apply exponential decay (return phase of glottal pulse) (SIMD)
 *
 * flow = amplitude * exp(-alpha * (phase - collision_point))
 *
 * @param phases Phase values
 * @param output Flow values (modified in-place)
 * @param amplitude Peak amplitude at collision point
 * @param alpha Decay rate (1/collisionPhase)
 * @param collision_point Phase where decay begins
 * @param n Number of points
 */
void apply_exponential_decay_simd(
    const double* phases,
    double* output,
    double amplitude,
    double alpha,
    double collision_point,
    integer n
) {
    batch_double amp_batch(amplitude);
    batch_double neg_alpha(-alpha);
    batch_double cp_batch(collision_point);
    integer i = 0;

    // SIMD loop
    for (; i + static_cast<integer>(simd_size) <= n; i += simd_size) {
        batch_double y = xsimd::load_unaligned(&phases[i]);
        batch_double decay_arg = neg_alpha * (y - cp_batch);
        batch_double flow = amp_batch * xsimd::exp(decay_arg);
        flow.store_unaligned(&output[i]);
    }

    // Scalar remainder
    for (; i < n; i++) {
        double y = phases[i];
        output[i] = amplitude * std::exp(-alpha * (y - collision_point));
    }
}

/**
 * Weighted sum of two arrays (SIMD)
 *
 * output[i] = a * input1[i] + b * input2[i]
 *
 * @param input1 First input array
 * @param input2 Second input array
 * @param output Output array
 * @param a Weight for first input
 * @param b Weight for second input
 * @param n Number of samples
 */
void weighted_sum_simd(
    const double* input1,
    const double* input2,
    double* output,
    double a,
    double b,
    integer n
) {
    batch_double a_batch(a);
    batch_double b_batch(b);
    integer i = 0;

    // SIMD loop
    for (; i + static_cast<integer>(simd_size) <= n; i += simd_size) {
        batch_double in1 = xsimd::load_unaligned(&input1[i]);
        batch_double in2 = xsimd::load_unaligned(&input2[i]);
        batch_double out = xsimd::fma(a_batch, in1, b_batch * in2);
        out.store_unaligned(&output[i]);
    }

    // Scalar remainder
    for (; i < n; i++) {
        output[i] = a * input1[i] + b * input2[i];
    }
}

#endif // HAVE_XSIMD

} // namespace klattgrid_simd

// =============================================================================
// C-linkage Bridge Functions for Praat Code Integration
// =============================================================================

extern "C" {

/**
 * Check if SIMD should be used for KlattGrid operations
 */
bool should_use_simd_for_klattgrid() {
#ifdef HAVE_XSIMD
    // Check R option
    Rcpp::Environment base = Rcpp::Environment::base_env();
    Rcpp::Function getOption = base["getOption"];
    SEXP result = getOption("speaker.use_simd");
    if (result != R_NilValue && Rcpp::as<bool>(result) == false) {
        return false;
    }
    return true;
#else
    return false;
#endif
}

/**
 * Bridge: Add sounds in-place
 *
 * Praat Sound format:
 * - z[1][i] for mono sound (1-based indexing)
 *
 * @param output Output sound z row (output->z[1] - 1)
 * @param input Input sound z row (input->z[1] - 1)
 * @param start_sample Starting sample (1-based)
 * @param end_sample Ending sample (1-based)
 */
void sounds_add_inplace_simd_bridge(
    double* output,      // z[1] - 1 (1-based access)
    const double* input, // z[1] - 1 (1-based access)
    integer start_sample,
    integer end_sample
) {
#ifdef HAVE_XSIMD
    if (!should_use_simd_for_klattgrid()) {
        // Scalar fallback
        for (integer i = start_sample; i <= end_sample; i++) {
            output[i] += input[i];
        }
        return;
    }

    integer n = end_sample - start_sample + 1;
    if (n <= 0) return;

    klattgrid_simd::sounds_add_inplace_simd(
        &output[start_sample],
        &input[start_sample],
        n
    );
#else
    // Scalar fallback
    for (integer i = start_sample; i <= end_sample; i++) {
        output[i] += input[i];
    }
#endif
}

/**
 * Bridge: Compute sound difference
 *
 * @param input Input sound z row
 * @param output Output difference z row
 * @param start_sample Starting sample (1-based)
 * @param end_sample Ending sample (1-based)
 */
void sound_diff_simd_bridge(
    const double* input,
    double* output,
    integer start_sample,
    integer end_sample
) {
#ifdef HAVE_XSIMD
    if (!should_use_simd_for_klattgrid()) {
        // Scalar fallback
        output[start_sample] = 0.0;
        for (integer i = start_sample + 1; i <= end_sample; i++) {
            output[i] = input[i] - input[i - 1];
        }
        return;
    }

    integer n = end_sample - start_sample + 1;
    if (n <= 0) return;

    klattgrid_simd::sound_diff_simd(
        &input[start_sample],
        &output[start_sample],
        n
    );
#else
    // Scalar fallback
    output[start_sample] = 0.0;
    for (integer i = start_sample + 1; i <= end_sample; i++) {
        output[i] = input[i] - input[i - 1];
    }
#endif
}

/**
 * Bridge: Scale sound in-place
 */
void sound_scale_inplace_simd_bridge(
    double* data,
    double scale,
    integer start_sample,
    integer end_sample
) {
#ifdef HAVE_XSIMD
    if (!should_use_simd_for_klattgrid()) {
        // Scalar fallback
        for (integer i = start_sample; i <= end_sample; i++) {
            data[i] *= scale;
        }
        return;
    }

    integer n = end_sample - start_sample + 1;
    if (n <= 0) return;

    klattgrid_simd::sound_scale_inplace_simd(
        &data[start_sample],
        scale,
        n
    );
#else
    // Scalar fallback
    for (integer i = start_sample; i <= end_sample; i++) {
        data[i] *= scale;
    }
#endif
}

/**
 * Bridge: Find extremum (max absolute value)
 */
double find_extremum_simd_bridge(
    const double* data,
    integer start_sample,
    integer end_sample
) {
#ifdef HAVE_XSIMD
    if (!should_use_simd_for_klattgrid()) {
        // Scalar fallback
        double max_val = 0.0;
        for (integer i = start_sample; i <= end_sample; i++) {
            double abs_val = std::abs(data[i]);
            if (abs_val > max_val) max_val = abs_val;
        }
        return max_val;
    }

    integer n = end_sample - start_sample + 1;
    if (n <= 0) return 0.0;

    return klattgrid_simd::find_extremum_simd(
        &data[start_sample],
        n
    );
#else
    // Scalar fallback
    double max_val = 0.0;
    for (integer i = start_sample; i <= end_sample; i++) {
        double abs_val = std::abs(data[i]);
        if (abs_val > max_val) max_val = abs_val;
    }
    return max_val;
#endif
}

} // extern "C"

// =============================================================================
// R-accessible diagnostic function
// =============================================================================

//' Get KlattGrid SIMD implementation info
//'
//' @return List with SIMD availability and batch size
//' @keywords internal
// [[Rcpp::export(.klattgrid_simd_info)]]
Rcpp::List klattgrid_simd_info() {
#ifdef HAVE_XSIMD
    return Rcpp::List::create(
        Rcpp::Named("simd_available") = true,
        Rcpp::Named("batch_size") = static_cast<int>(xsimd::batch<double>::size),
        Rcpp::Named("architecture") = get_simd_arch(),
        Rcpp::Named("functions") = Rcpp::CharacterVector::create(
            "sounds_add_inplace_simd",
            "sound_diff_simd",
            "sound_scale_simd",
            "sound_scale_inplace_simd",
            "find_extremum_simd",
            "normalize_sound_simd",
            "glottal_flow_polynomial_simd",
            "apply_exponential_decay_simd",
            "weighted_sum_simd"
        )
    );
#else
    return Rcpp::List::create(
        Rcpp::Named("simd_available") = false,
        Rcpp::Named("batch_size") = 1,
        Rcpp::Named("architecture") = "scalar",
        Rcpp::Named("functions") = Rcpp::CharacterVector()
    );
#endif
}
