/*
 * Part of pladdrr: R interface to Praat
 *
 * Copyright (C) 2025 Fredrik Nylen
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
// sound_fast_access.cpp
// Fast data access for Sound objects (direct pointer-range copy)
//
// NOTE: Despite the original "zerocopy" name, these functions DO copy data.
// Rcpp's two-iterator NumericVector constructor (ptr, ptr+n) allocates a
// new SEXP and memcpy's the data. The speedup vs get_values() comes from
// bypassing Praat's per-sample accessor overhead — not from avoiding copies.

// [[Rcpp::interfaces(r, cpp)]]
// [[Rcpp::plugins(cpp17)]]

#include "praat_types.h"
#include <Rcpp.h>
#include "praat_xptr_utils.h"

// Praat headers
#include "fon/Sound.h"
#include "melder/melder.h"

using namespace Rcpp;

//' Fast Sound Sample Access
//'
//' Copies Sound sample data via direct pointer access into Praat's
//' contiguous sample array, rather than going through the per-sample
//' accessor in a loop.
//'
//' @param sound_xptr External pointer to Sound object
//' @param channel Channel number (1-based, default 1)
//'
//' @return Numeric vector (independent copy of sample data).
//'   Has class `c("fast_vector", "numeric")` and a `readonly` attribute
//'   for backward compatibility with code that checked these.
//'
//' @details
//' The returned vector is an independent R copy — safe to modify,
//' store, or use after the Sound object is garbage collected.
//'
//' @examples
//' \dontrun{
//' sound <- Sound("large_file.wav")
//'
//' # Copy for read-only analysis
//' samples <- sound_values_fast(sound$get_xptr(), channel = 1)
//' rms <- sqrt(mean(samples^2))
//'
//' # Regular copy — equivalent output
//' samples2 <- sound$get_values(channel = 1)
//' }
//'
//' @export
// [[Rcpp::export]]
SEXP sound_values_fast(SEXP sound_xptr, int channel = 1) {
    BEGIN_RCPP

    // Validate pointer
    Rcpp::XPtr<structSound> ptr(sound_xptr);
    if (!ptr) {
        Rcpp::stop("Invalid Sound pointer");
    }

    // Validate channel
    if (channel < 1 || channel > ptr->ny) {
        Rcpp::stop("Channel %d out of range [1, %d]", channel, ptr->ny);
    }

    // Get pointer to Praat's sample array
    // Praat uses 1-based indexing: z[channel][1] to z[channel][nx]
    double* samples_start = &(ptr->z[channel][1]);
    integer n_samples = ptr->nx;

    // Copy via Rcpp's two-iterator constructor (memcpy under the hood).
    // This IS a copy — not zero-copy — but fast because it avoids
    // Praat's per-sample accessor overhead.
    NumericVector result(samples_start, samples_start + n_samples);

    // Attributes kept for backward compat (class name updated)
    result.attr("class") = CharacterVector::create("fast_vector", "numeric");
    result.attr("readonly") = true;
    result.attr("warning") = "Fast copy of Sound data";

    return result;

    END_RCPP
}


//' Fast Sound Time Vector
//'
//' Returns time values for each sample via optimized computation.
//'
//' @param sound_xptr External pointer to Sound object
//'
//' @return Numeric vector of sample times
//'
//' @details
//' Computes sample times directly from Sound metadata (t0 + i*dt)
//' rather than going through Praat's accessor functions.
//'
//' @export
// [[Rcpp::export]]
NumericVector sound_times_fast(SEXP sound_xptr) {
    BEGIN_RCPP

    Rcpp::XPtr<structSound> ptr(sound_xptr);
    if (!ptr) {
        Rcpp::stop("Invalid Sound pointer");
    }

    integer n_samples = ptr->nx;
    NumericVector times(n_samples);

    // Optimized computation (vectorized when possible)
    double t0 = ptr->x1;
    double dt = ptr->dx;

    for (integer i = 0; i < n_samples; i++) {
        times[i] = t0 + i * dt;
    }

    return times;

    END_RCPP
}


//' Get Sound Data as Matrix (Fast Copy)
//'
//' Copies Sound data into a matrix (samples x channels) via direct
//' pointer access.
//'
//' @param sound_xptr External pointer to Sound object
//' @param zerocopy Ignored (kept for backward compatibility). All paths copy.
//'
//' @return Numeric matrix with dimensions (n_samples x n_channels)
//'
//' @keywords internal
// [[Rcpp::export]]
NumericMatrix sound_as_matrix_fast_impl(SEXP sound_xptr, bool zerocopy = false) {
    BEGIN_RCPP

    Rcpp::XPtr<structSound> ptr(sound_xptr);
    if (!ptr) {
        Rcpp::stop("Invalid Sound pointer");
    }

    integer n_samples = ptr->nx;
    integer n_channels = ptr->ny;

    NumericMatrix result(n_samples, n_channels);

    for (int ch = 1; ch <= n_channels; ch++) {
        for (integer i = 1; i <= n_samples; i++) {
            result(i-1, ch-1) = ptr->z[ch][i];
        }
    }

    return result;

    END_RCPP
}


//' Check if Vector is a Fast-Access Vector
//'
//' @param x Numeric vector
//' @return TRUE if x has the fast_vector or zerocopy_vector class
//' @export
// [[Rcpp::export]]
bool is_fast_access(SEXP x) {
    if (TYPEOF(x) != REALSXP) {
        return false;
    }

    // Check for new or legacy class attribute
    if (Rf_inherits(x, "fast_vector") || Rf_inherits(x, "fast_matrix") ||
        Rf_inherits(x, "zerocopy_vector") || Rf_inherits(x, "zerocopy_matrix")) {
        return true;
    }

    return false;
}
