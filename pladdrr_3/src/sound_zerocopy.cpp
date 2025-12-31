// sound_zerocopy.cpp
// Zero-copy sample access for Sound objects
// Part of pladdrr Phase 5: Zero-copy & SIMD expansion

#include <Rcpp.h>
#include "praat_xptr_utils.h"
#include "fon/Sound.h"

using namespace Rcpp;

// ============================================================================
// Zero-Copy Sample Access
// ============================================================================

//' Get a single sample from Sound (no copy)
//' @param xptr External pointer to Sound
//' @param channel Channel number (1-based)
//' @param sample Sample index (1-based)
//' @return Sample value
// [[Rcpp::export(.sound_get_sample)]]
double sound_get_sample(SEXP xptr, int channel, int sample) {
    XPtr<structSound> sound(xptr);
    if (!sound) stop("Invalid Sound pointer");

    if (channel < 1 || channel > sound->ny)
        stop("Channel %d out of range [1, %d]", channel, sound->ny);
    if (sample < 1 || sample > sound->nx)
        stop("Sample %d out of range [1, %d]", sample, sound->nx);

    return sound->z[channel][sample];
}

//' Set a single sample in Sound (in-place modification)
//' @param xptr External pointer to Sound
//' @param channel Channel number (1-based)
//' @param sample Sample index (1-based)
//' @param value New sample value
// [[Rcpp::export(.sound_set_sample)]]
void sound_set_sample(SEXP xptr, int channel, int sample, double value) {
    XPtr<structSound> sound(xptr);
    if (!sound) stop("Invalid Sound pointer");

    if (channel < 1 || channel > sound->ny)
        stop("Channel %d out of range [1, %d]", channel, sound->ny);
    if (sample < 1 || sample > sound->nx)
        stop("Sample %d out of range [1, %d]", sample, sound->nx);

    sound->z[channel][sample] = value;
}

//' Get a range of samples from Sound (minimal copy)
//' @param xptr External pointer to Sound
//' @param channel Channel number (1-based)
//' @param from_sample Start sample (1-based, inclusive)
//' @param to_sample End sample (1-based, inclusive)
//' @return Numeric vector of samples
// [[Rcpp::export(.sound_get_samples_range)]]
NumericVector sound_get_samples_range(SEXP xptr, int channel, int from_sample, int to_sample) {
    XPtr<structSound> sound(xptr);
    if (!sound) stop("Invalid Sound pointer");

    if (channel < 1 || channel > sound->ny)
        stop("Channel %d out of range [1, %d]", channel, sound->ny);
    if (from_sample < 1) from_sample = 1;
    if (to_sample > sound->nx) to_sample = sound->nx;
    if (from_sample > to_sample) stop("from_sample > to_sample");

    int n = to_sample - from_sample + 1;
    NumericVector result(n);

    // Direct memcpy from Sound buffer
    std::memcpy(REAL(result), &sound->z[channel][from_sample], n * sizeof(double));

    return result;
}

//' Set a range of samples in Sound (in-place modification)
//' @param xptr External pointer to Sound
//' @param channel Channel number (1-based)
//' @param from_sample Start sample (1-based, inclusive)
//' @param values Numeric vector of new values
// [[Rcpp::export(.sound_set_samples_range)]]
void sound_set_samples_range(SEXP xptr, int channel, int from_sample, NumericVector values) {
    XPtr<structSound> sound(xptr);
    if (!sound) stop("Invalid Sound pointer");

    if (channel < 1 || channel > sound->ny)
        stop("Channel %d out of range [1, %d]", channel, sound->ny);

    int n = values.size();
    int to_sample = from_sample + n - 1;

    if (from_sample < 1) stop("from_sample must be >= 1");
    if (to_sample > sound->nx)
        stop("Range extends beyond sound length (%d > %d)", to_sample, sound->nx);

    // Direct memcpy to Sound buffer
    std::memcpy(&sound->z[channel][from_sample], REAL(values), n * sizeof(double));
}

//' Get samples at specific time points (vectorized)
//' @param xptr External pointer to Sound
//' @param channel Channel number (1-based)
//' @param times Numeric vector of time points
//' @param interpolation 0=nearest, 1=linear, 2=cubic, 3=sinc70, 4=sinc700
//' @return Numeric vector of sample values
// [[Rcpp::export(.sound_get_values_at_times)]]
NumericVector sound_get_values_at_times(SEXP xptr, int channel, NumericVector times, int interpolation) {
    XPtr<structSound> sound(xptr);
    if (!sound) stop("Invalid Sound pointer");

    if (channel < 1 || channel > sound->ny)
        stop("Channel %d out of range [1, %d]", channel, sound->ny);

    int n = times.size();
    NumericVector result(n);

    kVector_valueInterpolation interp = static_cast<kVector_valueInterpolation>(interpolation);

    for (int i = 0; i < n; ++i) {
        result[i] = Vector_getValueAtX(sound.get(), times[i], channel, interp);
    }

    return result;
}

// ============================================================================
// In-Place Operations (avoid intermediate copies)
// ============================================================================

//' Scale samples in-place (no copy)
//' @param xptr External pointer to Sound
//' @param factor Scale factor
// [[Rcpp::export(.sound_scale_inplace)]]
void sound_scale_inplace(SEXP xptr, double factor) {
    XPtr<structSound> sound(xptr);
    if (!sound) stop("Invalid Sound pointer");

    for (integer ch = 1; ch <= sound->ny; ch++) {
        double* samples = &sound->z[ch][1];
        for (integer i = 0; i < sound->nx; i++) {
            samples[i] *= factor;
        }
    }
}

//' Add value to all samples in-place
//' @param xptr External pointer to Sound
//' @param value Value to add
// [[Rcpp::export(.sound_add_inplace)]]
void sound_add_inplace(SEXP xptr, double value) {
    XPtr<structSound> sound(xptr);
    if (!sound) stop("Invalid Sound pointer");

    for (integer ch = 1; ch <= sound->ny; ch++) {
        double* samples = &sound->z[ch][1];
        for (integer i = 0; i < sound->nx; i++) {
            samples[i] += value;
        }
    }
}

//' Apply gain in dB in-place
//' @param xptr External pointer to Sound
//' @param gain_db Gain in decibels
// [[Rcpp::export(.sound_apply_gain_db_inplace)]]
void sound_apply_gain_db_inplace(SEXP xptr, double gain_db) {
    double factor = std::pow(10.0, gain_db / 20.0);
    sound_scale_inplace(xptr, factor);
}

//' Normalize peak to value in-place
//' @param xptr External pointer to Sound
//' @param peak_value Target peak value (default 0.99)
// [[Rcpp::export(.sound_normalize_peak_inplace)]]
void sound_normalize_peak_inplace(SEXP xptr, double peak_value) {
    XPtr<structSound> sound(xptr);
    if (!sound) stop("Invalid Sound pointer");

    // Find current peak
    double current_peak = 0.0;
    for (integer ch = 1; ch <= sound->ny; ch++) {
        double* samples = &sound->z[ch][1];
        for (integer i = 0; i < sound->nx; i++) {
            double abs_val = std::fabs(samples[i]);
            if (abs_val > current_peak) current_peak = abs_val;
        }
    }

    if (current_peak > 0) {
        double factor = peak_value / current_peak;
        sound_scale_inplace(xptr, factor);
    }
}

// ============================================================================
// Windowed Processing (process in chunks without full copy)
// ============================================================================

//' Apply function to overlapping windows (zero-copy windowed processing)
//' @param xptr External pointer to Sound
//' @param channel Channel number (1-based)
//' @param window_size Window size in samples
//' @param hop_size Hop size in samples
//' @return Matrix with one column per window
// [[Rcpp::export(.sound_get_windows)]]
NumericMatrix sound_get_windows(SEXP xptr, int channel, int window_size, int hop_size) {
    XPtr<structSound> sound(xptr);
    if (!sound) stop("Invalid Sound pointer");

    if (channel < 1 || channel > sound->ny)
        stop("Channel %d out of range [1, %d]", channel, sound->ny);

    int n_samples = sound->nx;
    int n_windows = (n_samples - window_size) / hop_size + 1;
    if (n_windows < 1) n_windows = 1;

    NumericMatrix result(window_size, n_windows);

    for (int w = 0; w < n_windows; w++) {
        int start = w * hop_size + 1;  // 1-based
        if (start + window_size - 1 > n_samples) break;

        // Direct copy from Sound buffer to matrix column
        std::memcpy(&result(0, w), &sound->z[channel][start], window_size * sizeof(double));
    }

    return result;
}

//' Get Sound info without copying samples
//' @param xptr External pointer to Sound
//' @return List with sound properties
// [[Rcpp::export(.sound_info)]]
List sound_info(SEXP xptr) {
    XPtr<structSound> sound(xptr);
    if (!sound) stop("Invalid Sound pointer");

    return List::create(
        Named("xmin") = sound->xmin,
        Named("xmax") = sound->xmax,
        Named("duration") = sound->xmax - sound->xmin,
        Named("nx") = sound->nx,
        Named("dx") = sound->dx,
        Named("x1") = sound->x1,
        Named("ny") = sound->ny,
        Named("sampling_rate") = 1.0 / sound->dx
    );
}
