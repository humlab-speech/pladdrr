/* mfcc_simd_bridge.cpp
 *
 * Bridge functions for integrating SIMD MFCC operations with Praat VEC interface
 *
 * Copyright (C) 2026 pladdrr development team
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or (at
 * your option) any later version.
 */

#include "praat.github.io/melder/melder.h"
#include <cmath>

// Forward declarations of SIMD functions
extern "C" {
    double triangular_filter_simd(
        const double* spectrum_power,
        const double* frequencies,
        integer ifrom,
        integer ito,
        double fl_hz,
        double fc_hz,
        double fh_hz
    );
    void dct_simd(
        double* target,
        const double* x,
        const double* const* cosinesTable,
        integer size
    );
    bool should_use_simd_for_mfcc();
}

// ============================================================================
// Bridge Functions for Praat VEC Interface
// ============================================================================

/**
 * Bridge: Triangular filter for Mel spectrogram
 * Applies triangular Mel filter to power spectrum
 *
 * @param spectrum_power Power spectrum (VEC)
 * @param frequencies Frequency array for each bin (VEC)
 * @param ifrom Starting bin index (1-based)
 * @param ito Ending bin index (1-based)
 * @param fl_hz Lower frequency bound
 * @param fc_hz Center frequency
 * @param fh_hz Upper frequency bound
 * @return Filtered power value
 */
extern "C" double triangular_filter_simd_bridge(
    constVEC const& spectrum_power,
    constVEC const& frequencies,
    integer ifrom,
    integer ito,
    double fl_hz,
    double fc_hz,
    double fh_hz
) {
    Melder_assert(spectrum_power.size == frequencies.size);
    Melder_assert(ifrom >= 1 && ito <= spectrum_power.size);

    const double* power_ptr = &spectrum_power[1];
    const double* freq_ptr = &frequencies[1];

    return triangular_filter_simd(
        power_ptr - 1,  // Adjust for 1-based indexing
        freq_ptr - 1,
        ifrom,
        ito,
        fl_hz,
        fc_hz,
        fh_hz
    );
}

/**
 * Bridge: DCT with Praat VEC and MAT
 * Computes discrete cosine transform using precomputed cosine table
 *
 * @param target Output DCT coefficients (VEC)
 * @param x Input signal (VEC)
 * @param cosinesTable Precomputed cosine table (MAT)
 */
extern "C" void dct_simd_bridge(
    VEC const& target,
    constVEC const& x,
    constMAT const& cosinesTable
) {
    Melder_assert(target.size == x.size);
    Melder_assert(cosinesTable.nrow == cosinesTable.ncol);
    Melder_assert(x.size == cosinesTable.nrow);

    integer size = x.size;

    // Create pointer array for 2D cosinesTable access
    // Note: Praat MAT is 1-based, so we need to adjust
    const double** cosine_ptrs = new const double*[size + 1];
    for (integer k = 1; k <= size; k++) {
        cosine_ptrs[k] = &cosinesTable[k][1] - 1;  // Adjust for 1-based indexing
    }

    double* target_ptr = &target[1];
    const double* x_ptr = &x[1];

    dct_simd(
        target_ptr - 1,  // Adjust for 1-based indexing
        x_ptr - 1,
        cosine_ptrs,
        size
    );

    delete[] cosine_ptrs;
}

/* End of file mfcc_simd_bridge.cpp */
