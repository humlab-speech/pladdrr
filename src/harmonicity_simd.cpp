// harmonicity_simd.cpp
// SIMD-optimized functions for harmonicity/pitch computation
// Part of pladdrr package SIMD Phase 4.2
//
// Optimizes key loops in Sound_to_Pitch.cpp:
// 1. Power spectrum computation (FFT-based autocorrelation)
// 2. Cross-correlation inner loop (FCC method)
// 3. Local mean computation
// 4. Windowed DC removal + window application
// 5. Local peak finding (max absolute value)

#ifdef HAVE_XSIMD
#include <xsimd/xsimd.hpp>
#endif

#include <cmath>
#include <cstdint>
#include <algorithm>

// ============================================================================
// SIMD Configuration
// ============================================================================

#ifdef HAVE_XSIMD
using batch_double = xsimd::batch<double>;
constexpr size_t simd_size = batch_double::size;
#endif

// ============================================================================
// Runtime SIMD toggle (matches other SIMD modules)
// ============================================================================

static bool g_harmonicity_simd_enabled = true;

extern "C" {

void set_harmonicity_simd_enabled(bool enabled) {
    g_harmonicity_simd_enabled = enabled;
}

bool get_harmonicity_simd_enabled() {
    return g_harmonicity_simd_enabled;
}

bool should_use_simd_for_harmonicity() {
#ifdef HAVE_XSIMD
    return g_harmonicity_simd_enabled;
#else
    return false;
#endif
}

} // extern "C"

// ============================================================================
// 1. Power Spectrum Computation (for AC method autocorrelation)
// ============================================================================
// After FFT, compute power spectrum: ac[i] = Re² + Im²
// Input: complex spectrum pairs at even/odd indices
// Output: power values accumulated into ac array

#ifdef HAVE_XSIMD
namespace harmonicity_simd_direct {

// Accumulate power spectrum from complex FFT output
// frame: FFT output (Re, Im pairs at indices 2, 3, 4, 5, ...)
// ac: accumulator for power spectrum
// start: first index to process (typically 2)
// end: last index to process (typically nsampFFT-1)
void accumulate_power_spectrum_simd(
    const double* frame,
    double* ac,
    int start,
    int end
) {
    int i = start;

    // Process pairs (Re, Im) with SIMD
    // We process 2 complex numbers per iteration on AVX (4 doubles)
    // Each complex: ac[i] += Re² + Im²
    for (; i + static_cast<int>(2 * simd_size) <= end; i += 2 * simd_size) {
        // Load 4 (or 2) complex pairs
        batch_double data1 = xsimd::load_unaligned(&frame[i]);
        batch_double data2 = xsimd::load_unaligned(&frame[i + simd_size]);

        // Square elements
        batch_double sq1 = data1 * data1;
        batch_double sq2 = data2 * data2;

        // Load existing ac values
        batch_double ac1 = xsimd::load_unaligned(&ac[i]);
        batch_double ac2 = xsimd::load_unaligned(&ac[i + simd_size]);

        // Accumulate: we need Re² + Im² for each pair
        // This is trickier - we have [Re0, Im0, Re1, Im1] layout
        // For now, just accumulate squares at same positions
        // The caller will handle the pairing
        ac1 += sq1;
        ac2 += sq2;

        ac1.store_unaligned(&ac[i]);
        ac2.store_unaligned(&ac[i + simd_size]);
    }

    // Scalar remainder - process Re/Im pairs
    for (; i < end; i += 2) {
        ac[i] += frame[i] * frame[i] + frame[i+1] * frame[i+1];
    }
}

// Optimized version that processes Re/Im pairs correctly
// Returns power at each frequency bin (half the size)
void compute_power_spectrum_paired_simd(
    const double* frame,
    double* power,
    int n_complex_pairs  // Number of complex numbers (excluding DC and Nyquist)
) {
    int i = 0;

    // Process pairs efficiently
    for (; i + static_cast<int>(simd_size) <= n_complex_pairs; i += simd_size) {
        // We need to gather Re and Im from interleaved layout
        // For AVX with simd_size=4: indices 0,2,4,6 (Re) and 1,3,5,7 (Im)

        // Manual deinterleaving for double pairs
        double re_arr[simd_size];
        double im_arr[simd_size];

        for (size_t j = 0; j < simd_size; ++j) {
            re_arr[j] = frame[2 * (i + j)];
            im_arr[j] = frame[2 * (i + j) + 1];
        }

        batch_double re = xsimd::load_unaligned(re_arr);
        batch_double im = xsimd::load_unaligned(im_arr);

        // Power = Re² + Im²
        batch_double p = xsimd::fma(re, re, im * im);

        // Load existing and accumulate
        batch_double existing = xsimd::load_unaligned(&power[i]);
        existing += p;
        existing.store_unaligned(&power[i]);
    }

    // Scalar remainder
    for (; i < n_complex_pairs; ++i) {
        double re = frame[2 * i];
        double im = frame[2 * i + 1];
        power[i] += re * re + im * im;
    }
}

// ============================================================================
// 2. Cross-Correlation Inner Loop (for FCC method)
// ============================================================================
// This is the critical bottleneck: O(maximumLag × nsamp_window) per frame
// product = sum(x[j] * y[j]) where y is offset by lag

double cross_correlation_with_mean_simd(
    const double* amp,       // Signal samples (1-indexed in Praat, 0-indexed here)
    double mean,             // Local mean to subtract
    int nsamp_window,        // Window size
    int lag                  // Lag offset
) {
    batch_double mean_batch(mean);
    batch_double acc(0.0);

    int j = 0;

    // SIMD main loop
    for (; j + static_cast<int>(simd_size) <= nsamp_window; j += simd_size) {
        // Load x[j] - mean
        batch_double x = xsimd::load_unaligned(&amp[j]);
        x -= mean_batch;

        // Load y[j + lag] - mean
        batch_double y = xsimd::load_unaligned(&amp[j + lag]);
        y -= mean_batch;

        // Accumulate product
        acc = xsimd::fma(x, y, acc);
    }

    double product = xsimd::reduce_add(acc);

    // Scalar remainder
    for (; j < nsamp_window; ++j) {
        double x = amp[j] - mean;
        double y = amp[j + lag] - mean;
        product += x * y;
    }

    return product;
}

// Multi-channel cross-correlation (stereo support)
double cross_correlation_multichannel_simd(
    const double* const* channels,  // Array of channel pointers
    const double* means,            // Per-channel means
    int n_channels,
    int nsamp_window,
    int lag
) {
    double total_product = 0.0;

    for (int ch = 0; ch < n_channels; ++ch) {
        total_product += cross_correlation_with_mean_simd(
            channels[ch], means[ch], nsamp_window, lag
        );
    }

    return total_product;
}

// ============================================================================
// 3. Local Mean Computation
// ============================================================================

double compute_local_mean_simd(
    const double* data,
    int start,      // Start index (inclusive)
    int end         // End index (inclusive)
) {
    int count = end - start + 1;
    if (count <= 0) return 0.0;

    batch_double acc(0.0);
    int i = start;

    // SIMD accumulation
    for (; i + static_cast<int>(simd_size) <= end + 1; i += simd_size) {
        batch_double data_batch = xsimd::load_unaligned(&data[i]);
        acc += data_batch;
    }

    double sum = xsimd::reduce_add(acc);

    // Scalar remainder
    for (; i <= end; ++i) {
        sum += data[i];
    }

    return sum / count;
}

// ============================================================================
// 4. Windowed DC Removal (mean subtraction + window application)
// ============================================================================
// frame[j] = (signal[i++] - localMean) * window[j]

void apply_window_with_dc_removal_simd(
    const double* signal,    // Input signal
    int signal_start,        // Starting index in signal
    double local_mean,       // Mean to subtract
    const double* window,    // Window coefficients
    double* frame,           // Output frame
    int frame_length         // Number of samples
) {
    batch_double mean_batch(local_mean);
    int j = 0;

    // SIMD main loop
    for (; j + static_cast<int>(simd_size) <= frame_length; j += simd_size) {
        // Load signal samples
        batch_double sig = xsimd::load_unaligned(&signal[signal_start + j]);

        // Load window coefficients
        batch_double win = xsimd::load_unaligned(&window[j]);

        // Compute (signal - mean) * window
        batch_double result = (sig - mean_batch) * win;

        result.store_unaligned(&frame[j]);
    }

    // Scalar remainder
    for (; j < frame_length; ++j) {
        frame[j] = (signal[signal_start + j] - local_mean) * window[j];
    }
}

// DC removal only (for FCC method - no windowing)
void apply_dc_removal_simd(
    const double* signal,
    int signal_start,
    double local_mean,
    double* frame,
    int frame_length
) {
    batch_double mean_batch(local_mean);
    int j = 0;

    for (; j + static_cast<int>(simd_size) <= frame_length; j += simd_size) {
        batch_double sig = xsimd::load_unaligned(&signal[signal_start + j]);
        batch_double result = sig - mean_batch;
        result.store_unaligned(&frame[j]);
    }

    for (; j < frame_length; ++j) {
        frame[j] = signal[signal_start + j] - local_mean;
    }
}

// ============================================================================
// 5. Local Peak Finding (max absolute value)
// ============================================================================

double find_local_peak_simd(
    const double* data,
    int start,
    int end
) {
    batch_double max_batch(0.0);
    int i = start;

    // SIMD main loop
    for (; i + static_cast<int>(simd_size) <= end + 1; i += simd_size) {
        batch_double data_batch = xsimd::load_unaligned(&data[i]);
        batch_double abs_batch = xsimd::abs(data_batch);
        max_batch = xsimd::max(max_batch, abs_batch);
    }

    // Reduce SIMD max to scalar
    double max_val = xsimd::reduce_max(max_batch);

    // Scalar remainder
    for (; i <= end; ++i) {
        double abs_val = std::fabs(data[i]);
        if (abs_val > max_val) max_val = abs_val;
    }

    return max_val;
}

// Multi-channel peak finding
double find_local_peak_multichannel_simd(
    const double* const* channels,
    int n_channels,
    int start,
    int end
) {
    double global_peak = 0.0;

    for (int ch = 0; ch < n_channels; ++ch) {
        double ch_peak = find_local_peak_simd(channels[ch], start, end);
        if (ch_peak > global_peak) global_peak = ch_peak;
    }

    return global_peak;
}

// ============================================================================
// 6. Sum of Squares (for normalization)
// ============================================================================

double compute_sum_of_squares_simd(
    const double* data,
    double mean,
    int start,
    int end
) {
    batch_double mean_batch(mean);
    batch_double acc(0.0);
    int i = start;

    for (; i + static_cast<int>(simd_size) <= end + 1; i += simd_size) {
        batch_double d = xsimd::load_unaligned(&data[i]);
        batch_double x = d - mean_batch;
        acc = xsimd::fma(x, x, acc);  // acc += x²
    }

    double sum = xsimd::reduce_add(acc);

    for (; i <= end; ++i) {
        double x = data[i] - mean;
        sum += x * x;
    }

    return sum;
}

// ============================================================================
// 7. Autocorrelation Normalization
// ============================================================================
// r[i] = ac[i+1] / (ac[1] * windowR[i+1])

void normalize_autocorrelation_simd(
    const double* ac,        // Autocorrelation values (1-indexed)
    const double* windowR,   // Window autocorrelation (1-indexed)
    double* r,               // Output normalized autocorrelation
    int max_lag,             // Maximum lag to compute
    double ac0               // ac[1] value (for normalization)
) {
    batch_double ac0_batch(ac0);
    int i = 1;

    for (; i + static_cast<int>(simd_size) <= max_lag + 1; i += simd_size) {
        // Load ac[i+1..i+simd_size]
        batch_double ac_batch = xsimd::load_unaligned(&ac[i]);

        // Load windowR[i+1..i+simd_size]
        batch_double wr_batch = xsimd::load_unaligned(&windowR[i]);

        // Compute ac / (ac0 * windowR)
        batch_double denom = ac0_batch * wr_batch;
        batch_double result = ac_batch / denom;

        result.store_unaligned(&r[i]);
    }

    // Scalar remainder
    for (; i <= max_lag; ++i) {
        r[i] = ac[i] / (ac0 * windowR[i]);
    }
}

// ============================================================================
// 8. Zero fill (for FFT padding)
// ============================================================================

void zero_fill_simd(double* data, int start, int end) {
    batch_double zero(0.0);
    int i = start;

    for (; i + static_cast<int>(simd_size) <= end + 1; i += simd_size) {
        zero.store_unaligned(&data[i]);
    }

    for (; i <= end; ++i) {
        data[i] = 0.0;
    }
}

} // namespace harmonicity_simd_direct
#endif // HAVE_XSIMD

// ============================================================================
// Scalar Fallbacks (when SIMD not available)
// ============================================================================

namespace harmonicity_scalar {

double compute_local_mean_scalar(const double* data, int start, int end) {
    int count = end - start + 1;
    if (count <= 0) return 0.0;

    double sum = 0.0;
    for (int i = start; i <= end; ++i) {
        sum += data[i];
    }
    return sum / count;
}

double cross_correlation_with_mean_scalar(
    const double* amp,
    double mean,
    int nsamp_window,
    int lag
) {
    double product = 0.0;
    for (int j = 0; j < nsamp_window; ++j) {
        double x = amp[j] - mean;
        double y = amp[j + lag] - mean;
        product += x * y;
    }
    return product;
}

void apply_window_with_dc_removal_scalar(
    const double* signal,
    int signal_start,
    double local_mean,
    const double* window,
    double* frame,
    int frame_length
) {
    for (int j = 0; j < frame_length; ++j) {
        frame[j] = (signal[signal_start + j] - local_mean) * window[j];
    }
}

void apply_dc_removal_scalar(
    const double* signal,
    int signal_start,
    double local_mean,
    double* frame,
    int frame_length
) {
    for (int j = 0; j < frame_length; ++j) {
        frame[j] = signal[signal_start + j] - local_mean;
    }
}

double find_local_peak_scalar(const double* data, int start, int end) {
    double max_val = 0.0;
    for (int i = start; i <= end; ++i) {
        double abs_val = std::fabs(data[i]);
        if (abs_val > max_val) max_val = abs_val;
    }
    return max_val;
}

double compute_sum_of_squares_scalar(
    const double* data,
    double mean,
    int start,
    int end
) {
    double sum = 0.0;
    for (int i = start; i <= end; ++i) {
        double x = data[i] - mean;
        sum += x * x;
    }
    return sum;
}

void normalize_autocorrelation_scalar(
    const double* ac,
    const double* windowR,
    double* r,
    int max_lag,
    double ac0
) {
    for (int i = 1; i <= max_lag; ++i) {
        r[i] = ac[i] / (ac0 * windowR[i]);
    }
}

void zero_fill_scalar(double* data, int start, int end) {
    for (int i = start; i <= end; ++i) {
        data[i] = 0.0;
    }
}

} // namespace harmonicity_scalar

// ============================================================================
// Bridge Functions for Praat Integration
// ============================================================================
// These adapt between Praat's 1-indexed VEC and our 0-indexed SIMD functions

extern "C" {

// Local mean computation bridge
double compute_local_mean_simd_bridge(
    const double* data,  // 1-indexed Praat array
    int start,           // 1-indexed start
    int end              // 1-indexed end
) {
    // Convert to 0-indexed for SIMD
    const double* data0 = data - 1;  // Adjust for 1-indexing

#ifdef HAVE_XSIMD
    if (g_harmonicity_simd_enabled) {
        return harmonicity_simd_direct::compute_local_mean_simd(data0, start, end);
    }
#endif
    return harmonicity_scalar::compute_local_mean_scalar(data0, start, end);
}

// Cross-correlation bridge for FCC method
double cross_correlation_fcc_simd_bridge(
    const double* amp,   // Signal pointer (already offset for channel)
    double mean,
    int nsamp_window,
    int lag
) {
#ifdef HAVE_XSIMD
    if (g_harmonicity_simd_enabled) {
        return harmonicity_simd_direct::cross_correlation_with_mean_simd(
            amp, mean, nsamp_window, lag
        );
    }
#endif
    return harmonicity_scalar::cross_correlation_with_mean_scalar(
        amp, mean, nsamp_window, lag
    );
}

// Windowed DC removal bridge (for AC method)
void apply_window_dc_removal_simd_bridge(
    const double* signal,  // 1-indexed signal
    int signal_start,      // 1-indexed start
    double local_mean,
    const double* window,  // 1-indexed window
    double* frame,         // 1-indexed output
    int frame_length
) {
    // Convert to 0-indexed
    const double* signal0 = signal - 1;
    const double* window0 = window - 1;
    double* frame0 = frame - 1;

#ifdef HAVE_XSIMD
    if (g_harmonicity_simd_enabled) {
        harmonicity_simd_direct::apply_window_with_dc_removal_simd(
            signal0, signal_start, local_mean, window0, frame0, frame_length
        );
        return;
    }
#endif
    harmonicity_scalar::apply_window_with_dc_removal_scalar(
        signal0, signal_start, local_mean, window0, frame0, frame_length
    );
}

// DC removal bridge (for FCC method - no windowing)
void apply_dc_removal_simd_bridge(
    const double* signal,
    int signal_start,
    double local_mean,
    double* frame,
    int frame_length
) {
    const double* signal0 = signal - 1;
    double* frame0 = frame - 1;

#ifdef HAVE_XSIMD
    if (g_harmonicity_simd_enabled) {
        harmonicity_simd_direct::apply_dc_removal_simd(
            signal0, signal_start, local_mean, frame0, frame_length
        );
        return;
    }
#endif
    harmonicity_scalar::apply_dc_removal_scalar(
        signal0, signal_start, local_mean, frame0, frame_length
    );
}

// Local peak finding bridge
double find_local_peak_simd_bridge(
    const double* data,  // Frame data (1-indexed)
    int start,           // 1-indexed
    int end              // 1-indexed
) {
    const double* data0 = data - 1;

#ifdef HAVE_XSIMD
    if (g_harmonicity_simd_enabled) {
        return harmonicity_simd_direct::find_local_peak_simd(data0, start, end);
    }
#endif
    return harmonicity_scalar::find_local_peak_scalar(data0, start, end);
}

// Sum of squares bridge (for FCC normalization)
double compute_sum_of_squares_simd_bridge(
    const double* data,
    double mean,
    int start,
    int end
) {
    const double* data0 = data - 1;

#ifdef HAVE_XSIMD
    if (g_harmonicity_simd_enabled) {
        return harmonicity_simd_direct::compute_sum_of_squares_simd(
            data0, mean, start, end
        );
    }
#endif
    return harmonicity_scalar::compute_sum_of_squares_scalar(
        data0, mean, start, end
    );
}

// Autocorrelation normalization bridge
void normalize_autocorrelation_simd_bridge(
    const double* ac,
    const double* windowR,
    double* r,
    int max_lag
) {
    // ac, windowR, r are all 1-indexed in Praat
    const double* ac0 = ac - 1;
    const double* windowR0 = windowR - 1;
    double* r0 = r - 1;
    double ac_zero = ac[1];  // ac[1] is the zero-lag value

#ifdef HAVE_XSIMD
    if (g_harmonicity_simd_enabled) {
        harmonicity_simd_direct::normalize_autocorrelation_simd(
            ac0, windowR0, r0, max_lag, ac_zero
        );
        return;
    }
#endif
    harmonicity_scalar::normalize_autocorrelation_scalar(
        ac0, windowR0, r0, max_lag, ac_zero
    );
}

// Zero fill bridge (for FFT padding)
void zero_fill_simd_bridge(double* data, int start, int end) {
    double* data0 = data - 1;

#ifdef HAVE_XSIMD
    if (g_harmonicity_simd_enabled) {
        harmonicity_simd_direct::zero_fill_simd(data0, start, end);
        return;
    }
#endif
    harmonicity_scalar::zero_fill_scalar(data0, start, end);
}

// Power spectrum accumulation bridge
// Computes ac[i] += frame[i]² + frame[i+1]² for complex FFT pairs
void harmonicity_accumulate_power_spectrum_simd_bridge(
    const double* frame,  // 1-indexed FFT output
    double* ac,           // 1-indexed accumulator
    int n_fft             // FFT size
) {
#ifdef HAVE_XSIMD
    if (g_harmonicity_simd_enabled) {
        // Process interior complex pairs (indices 2 to n_fft-1)
        // DC (index 1) and Nyquist (index n_fft) are real-only
        const double* frame0 = frame - 1;
        double* ac0 = ac - 1;

        int i = 2;
        for (; i + static_cast<int>(2 * simd_size) < n_fft; i += 2 * simd_size) {
            // Load batches of FFT data
            batch_double f1 = xsimd::load_unaligned(&frame0[i]);
            batch_double f2 = xsimd::load_unaligned(&frame0[i + simd_size]);

            // Square
            batch_double sq1 = f1 * f1;
            batch_double sq2 = f2 * f2;

            // Accumulate into ac
            batch_double a1 = xsimd::load_unaligned(&ac0[i]);
            batch_double a2 = xsimd::load_unaligned(&ac0[i + simd_size]);

            a1 += sq1;
            a2 += sq2;

            a1.store_unaligned(&ac0[i]);
            a2.store_unaligned(&ac0[i + simd_size]);
        }

        // Scalar remainder - process Re/Im pairs correctly
        for (; i < n_fft; i += 2) {
            ac[i] += frame[i] * frame[i] + frame[i+1] * frame[i+1];
        }
        return;
    }
#endif
    // Scalar fallback
    for (int i = 2; i < n_fft; i += 2) {
        ac[i] += frame[i] * frame[i] + frame[i+1] * frame[i+1];
    }
}

} // extern "C"

// ============================================================================
// SIMD Capability Query
// ============================================================================

extern "C" {

const char* get_harmonicity_simd_info() {
#ifdef HAVE_XSIMD
    #if defined(__AVX512F__)
        return "AVX-512";
    #elif defined(__AVX2__)
        return "AVX2";
    #elif defined(__AVX__)
        return "AVX";
    #elif defined(__SSE4_2__)
        return "SSE4.2";
    #elif defined(__ARM_NEON) || defined(__aarch64__)
        return "NEON";
    #else
        return "Generic SIMD";
    #endif
#else
    return "None (scalar only)";
#endif
}

int get_harmonicity_simd_width() {
#ifdef HAVE_XSIMD
    return static_cast<int>(simd_size);
#else
    return 1;
#endif
}

} // extern "C"
