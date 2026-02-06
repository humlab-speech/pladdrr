/* formantpath_simd.cpp
 *
 * SIMD-optimized FormantPath operations for dynamic programming path finding
 *
 * Copyright (C) 2026 pladdrr development team
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or (at
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 */

#include "praat.github.io/melder/melder.h"

#ifdef HAVE_XSIMD
#include <xsimd/xsimd.hpp>
#include "xsimd_compat.h"
#endif

#include <cmath>
#include <algorithm>
#include <limits>

// ============================================================================
// SIMD-accelerated FormantPath operations
// ============================================================================

namespace formantpath_simd {

/**
 * Calculate Q-sum (frequency/bandwidth ratio) for multiple candidates with SIMD
 * Q-sum = sum(frequency[i] / bandwidth[i]) / numberOfFormants
 *
 * This function computes qsums for all candidates at a single time frame
 *
 * @param frequencies Array of frequencies [candidate][formant] (linearized)
 * @param bandwidths Array of bandwidths [candidate][formant] (linearized)
 * @param numberOfCandidates Number of ceiling candidates
 * @param numberOfFormants Number of formant tracks per candidate
 * @param formantCounts Actual number of formants per candidate (1-based)
 * @param qsums Output array for qsum values (1-based, size numberOfCandidates)
 */
#ifdef HAVE_XSIMD
void compute_qsums_simd(
    const double* frequencies,      // [candidate * maxFormants + formant]
    const double* bandwidths,
    integer numberOfCandidates,
    integer maxFormants,
    const integer* formantCounts,   // actual formant count per candidate (1-based)
    double* qsums                   // output (1-based)
) {
    using batch = XSIMD_BATCH(double);
    constexpr size_t simd_size = batch::size;

    // Process candidates in SIMD batches
    integer ic = 1;
    for (; ic + static_cast<integer>(simd_size) - 1 <= numberOfCandidates; ic += simd_size) {
        // For each batch of candidates, compute qsum
        // Note: We need to handle variable formant counts, so we fall back to scalar
        // within this outer SIMD loop since formant counts vary
        for (size_t b = 0; b < simd_size; b++) {
            integer cand = ic + b;
            integer nFormants = formantCounts[cand];
            if (nFormants <= 0) {
                qsums[cand] = 0.0;
                continue;
            }

            double qsum = 0.0;
            const double* freq = frequencies + (cand - 1) * maxFormants;
            const double* bw = bandwidths + (cand - 1) * maxFormants;

            // SIMD within formants if enough formants
            integer iformant = 0;
            for (; iformant + static_cast<integer>(simd_size) <= nFormants; iformant += simd_size) {
                batch f = xsimd::load_unaligned(&freq[iformant]);
                batch b_bw = xsimd::load_unaligned(&bw[iformant]);
                batch ratio = f / b_bw;
                qsum += xsimd_compat::reduce_add_compat(ratio);
            }

            // Scalar remainder
            for (; iformant < nFormants; iformant++) {
                qsum += freq[iformant] / bw[iformant];
            }

            qsums[cand] = qsum / nFormants;
        }
    }

    // Scalar remainder for candidates
    for (; ic <= numberOfCandidates; ic++) {
        integer nFormants = formantCounts[ic];
        if (nFormants <= 0) {
            qsums[ic] = 0.0;
            continue;
        }

        double qsum = 0.0;
        const double* freq = frequencies + (ic - 1) * maxFormants;
        const double* bw = bandwidths + (ic - 1) * maxFormants;

        for (integer iformant = 0; iformant < nFormants; iformant++) {
            qsum += freq[iformant] / bw[iformant];
        }

        qsums[ic] = qsum / nFormants;
    }
}
#else
void compute_qsums_simd(
    const double* frequencies,
    const double* bandwidths,
    integer numberOfCandidates,
    integer maxFormants,
    const integer* formantCounts,
    double* qsums
) {
    for (integer ic = 1; ic <= numberOfCandidates; ic++) {
        integer nFormants = formantCounts[ic];
        if (nFormants <= 0) {
            qsums[ic] = 0.0;
            continue;
        }

        double qsum = 0.0;
        const double* freq = frequencies + (ic - 1) * maxFormants;
        const double* bw = bandwidths + (ic - 1) * maxFormants;

        for (integer iformant = 0; iformant < nFormants; iformant++) {
            qsum += freq[iformant] / bw[iformant];
        }

        qsums[ic] = qsum / nFormants;
    }
}
#endif


/**
 * Find minimum value and its position in an array with SIMD
 * Used in Viterbi backtracking to find optimal previous state
 *
 * @param values Array of cost values (1-based indexing)
 * @param n Number of values
 * @param out_minPos Output: position of minimum (1-based)
 * @return Minimum value
 */
#ifdef HAVE_XSIMD
double find_min_with_position_simd(
    const double* values,
    integer n,
    integer* out_minPos
) {
    if (n <= 0) {
        *out_minPos = 0;
        return std::numeric_limits<double>::infinity();
    }

    using batch = XSIMD_BATCH(double);
    constexpr size_t simd_size = batch::size;

    // Initialize with first value
    double minVal = values[1];
    integer minPos = 1;

    // Process in SIMD batches, but we need positions so we track mins per lane
    if (n > static_cast<integer>(simd_size)) {
        // For each SIMD batch, find local min, then compare with global
        integer i = 1;
        for (; i + static_cast<integer>(simd_size) - 1 <= n; i += simd_size) {
            batch vals = xsimd::load_unaligned(&values[i]);

            // Find min in this batch using horizontal reduction
            double batchMin = xsimd::reduce_min(vals);

            if (batchMin < minVal) {
                // Find which lane has the minimum
                for (size_t lane = 0; lane < simd_size; lane++) {
                    if (values[i + lane] <= batchMin) {
                        minVal = values[i + lane];
                        minPos = i + lane;
                        batchMin = minVal; // Update for potential ties
                    }
                }
            }
        }

        // Scalar remainder
        for (; i <= n; i++) {
            if (values[i] < minVal) {
                minVal = values[i];
                minPos = i;
            }
        }
    } else {
        // Too few values for SIMD
        for (integer i = 2; i <= n; i++) {
            if (values[i] < minVal) {
                minVal = values[i];
                minPos = i;
            }
        }
    }

    *out_minPos = minPos;
    return minVal;
}
#else
double find_min_with_position_simd(
    const double* values,
    integer n,
    integer* out_minPos
) {
    if (n <= 0) {
        *out_minPos = 0;
        return std::numeric_limits<double>::infinity();
    }

    double minVal = values[1];
    integer minPos = 1;

    for (integer i = 2; i <= n; i++) {
        if (values[i] < minVal) {
            minVal = values[i];
            minPos = i;
        }
    }

    *out_minPos = minPos;
    return minVal;
}
#endif


/**
 * Compute transition costs between all pairs of candidates with SIMD
 *
 * For each pair (i,j), computes:
 *   fcost = sum_k( bw_k * |f_i_k - f_j_k| / (f_i_k + f_j_k) ) / ntracks
 *   + ceilingCost
 *
 * @param freqs_i Frequencies at time t for candidate i [formant]
 * @param freqs_j Frequencies at time t-1 for candidate j [formant]
 * @param bws_i Bandwidths at time t for candidate i [formant]
 * @param bws_j Bandwidths at time t-1 for candidate j [formant]
 * @param ntracks Number of formant tracks
 * @param frequencyChangeWeight Weight for frequency change cost
 * @param transitionCostCutoff Cutoff for cost clamping
 * @return Frequency change cost
 */
#ifdef HAVE_XSIMD
double compute_frequency_change_cost_simd(
    const double* freqs_i,
    const double* freqs_j,
    const double* bws_i,
    const double* bws_j,
    integer ntracks,
    double frequencyChangeWeight,
    double transitionCostCutoff
) {
    using batch = XSIMD_BATCH(double);
    constexpr size_t simd_size = batch::size;

    if (frequencyChangeWeight <= 0.0 || ntracks <= 0) {
        return 0.0;
    }

    double fcost = 0.0;
    integer itrack = 0;

    // SIMD loop
    for (; itrack + static_cast<integer>(simd_size) <= ntracks; itrack += simd_size) {
        batch fi = xsimd::load_unaligned(&freqs_i[itrack]);
        batch fj = xsimd::load_unaligned(&freqs_j[itrack]);
        batch bi = xsimd::load_unaligned(&bws_i[itrack]);
        batch bj = xsimd::load_unaligned(&bws_j[itrack]);

        batch diff = xsimd::abs(fi - fj);
        batch sum = fi + fj;
        batch bw_geom = xsimd::sqrt(bi * bj);

        // cost = bw * |diff| / sum
        batch cost = bw_geom * diff / sum;
        fcost += xsimd_compat::reduce_add_compat(cost);
    }

    // Scalar remainder
    for (; itrack < ntracks; itrack++) {
        double fi = freqs_i[itrack];
        double fj = freqs_j[itrack];
        double dif = std::fabs(fi - fj);
        double sum = fi + fj;
        double bw = std::sqrt(bws_i[itrack] * bws_j[itrack]);
        fcost += bw * dif / sum;
    }

    fcost /= ntracks;
    return frequencyChangeWeight * std::min(fcost / transitionCostCutoff, 1.0);
}
#else
double compute_frequency_change_cost_simd(
    const double* freqs_i,
    const double* freqs_j,
    const double* bws_i,
    const double* bws_j,
    integer ntracks,
    double frequencyChangeWeight,
    double transitionCostCutoff
) {
    if (frequencyChangeWeight <= 0.0 || ntracks <= 0) {
        return 0.0;
    }

    double fcost = 0.0;

    for (integer itrack = 0; itrack < ntracks; itrack++) {
        double fi = freqs_i[itrack];
        double fj = freqs_j[itrack];
        double dif = std::fabs(fi - fj);
        double sum = fi + fj;
        double bw = std::sqrt(bws_i[itrack] * bws_j[itrack]);
        fcost += bw * dif / sum;
    }

    fcost /= ntracks;
    return frequencyChangeWeight * std::min(fcost / transitionCostCutoff, 1.0);
}
#endif


/**
 * Compute static costs (stress + qsum) for all candidates at one time frame with SIMD
 *
 * @param stresses Stress values for each candidate (1-based, can be nullptr)
 * @param qsums Q-sum values for each candidate (1-based, can be nullptr)
 * @param intensities Intensity modulation weights (1-based)
 * @param numberOfCandidates Number of candidates
 * @param stressWeight Weight for stress term
 * @param qWeight Weight for qsum term
 * @param stressCutoff Cutoff for stress clamping
 * @param qCutoff Cutoff for qsum clamping
 * @param delta Output delta values (1-based)
 */
#ifdef HAVE_XSIMD
void compute_static_costs_simd(
    const double* stresses,
    const double* qsums,
    const double* intensities,
    integer numberOfCandidates,
    double stressWeight,
    double qWeight,
    double stressCutoff,
    double qCutoff,
    double* delta
) {
    using batch = XSIMD_BATCH(double);
    constexpr size_t simd_size = batch::size;

    const batch stress_w(stressWeight);
    const batch q_w(qWeight);
    const batch stress_cut(stressCutoff);
    const batch q_cut(qCutoff);
    const batch one(1.0);

    integer ic = 1;

    // SIMD loop
    for (; ic + static_cast<integer>(simd_size) - 1 <= numberOfCandidates; ic += simd_size) {
        batch costs(0.0);
        batch wIntensity = xsimd::load_unaligned(&intensities[ic]);

        if (stressWeight > 0.0 && stresses != nullptr) {
            batch stress = xsimd::load_unaligned(&stresses[ic]);
            // Clamp stress/stressCutoff to max 1.0
            batch stress_term = xsimd::min(stress / stress_cut, one);
            costs = costs + stress_w * stress_term;
        }

        if (qWeight > 0.0 && qsums != nullptr) {
            batch qsum = xsimd::load_unaligned(&qsums[ic]);
            // Clamp qsum/qCutoff to max 1.0
            batch q_term = xsimd::min(qsum / q_cut, one);
            costs = costs - q_w * q_term;  // Note: subtract for qsum (higher is better)
        }

        batch result = wIntensity * costs;

        // Add to existing delta values
        batch current_delta = xsimd::load_unaligned(&delta[ic]);
        result = result + current_delta;
        result.store_unaligned(&delta[ic]);
    }

    // Scalar remainder
    for (; ic <= numberOfCandidates; ic++) {
        double costs = 0.0;
        double wIntensity = intensities[ic];

        if (stressWeight > 0.0 && stresses != nullptr) {
            costs += stressWeight * std::min(stresses[ic] / stressCutoff, 1.0);
        }

        if (qWeight > 0.0 && qsums != nullptr) {
            costs -= qWeight * std::min(qsums[ic] / qCutoff, 1.0);
        }

        delta[ic] += wIntensity * costs;
    }
}
#else
void compute_static_costs_simd(
    const double* stresses,
    const double* qsums,
    const double* intensities,
    integer numberOfCandidates,
    double stressWeight,
    double qWeight,
    double stressCutoff,
    double qCutoff,
    double* delta
) {
    for (integer ic = 1; ic <= numberOfCandidates; ic++) {
        double costs = 0.0;
        double wIntensity = intensities[ic];

        if (stressWeight > 0.0 && stresses != nullptr) {
            costs += stressWeight * std::min(stresses[ic] / stressCutoff, 1.0);
        }

        if (qWeight > 0.0 && qsums != nullptr) {
            costs -= qWeight * std::min(qsums[ic] / qCutoff, 1.0);
        }

        delta[ic] += wIntensity * costs;
    }
}
#endif


/**
 * Find maximum position in array (for finding best final state in Viterbi)
 *
 * @param values Array of values (1-based)
 * @param n Number of values
 * @return Position of maximum value (1-based)
 */
#ifdef HAVE_XSIMD
integer find_max_position_simd(const double* values, integer n) {
    using batch = XSIMD_BATCH(double);
    constexpr size_t simd_size = batch::size;

    if (n <= 0) return 0;

    double maxVal = values[1];
    integer maxPos = 1;

    integer i = 1;
    for (; i + static_cast<integer>(simd_size) - 1 <= n; i += simd_size) {
        batch vals = xsimd::load_unaligned(&values[i]);
        double batchMax = xsimd::reduce_max(vals);

        if (batchMax > maxVal) {
            // Find which lane
            for (size_t lane = 0; lane < simd_size; lane++) {
                if (values[i + lane] > maxVal) {
                    maxVal = values[i + lane];
                    maxPos = i + lane;
                }
            }
        }
    }

    // Scalar remainder
    for (; i <= n; i++) {
        if (values[i] > maxVal) {
            maxVal = values[i];
            maxPos = i;
        }
    }

    return maxPos;
}
#else
integer find_max_position_simd(const double* values, integer n) {
    if (n <= 0) return 0;

    double maxVal = values[1];
    integer maxPos = 1;

    for (integer i = 2; i <= n; i++) {
        if (values[i] > maxVal) {
            maxVal = values[i];
            maxPos = i;
        }
    }

    return maxPos;
}
#endif


/**
 * Compute all transition costs from previous frame to current candidate
 * Returns minimum cost and its position
 *
 * @param prev_delta Previous frame delta values (1-based, numberOfCandidates)
 * @param freqs_current Frequencies for current candidate [maxFormants]
 * @param bws_current Bandwidths for current candidate [maxFormants]
 * @param all_prev_freqs All previous frame frequencies [numberOfCandidates * maxFormants]
 * @param all_prev_bws All previous frame bandwidths [numberOfCandidates * maxFormants]
 * @param numberOfCandidates Number of candidates
 * @param maxFormants Maximum formants per frame
 * @param ntracks_current Number of tracks for current candidate
 * @param prev_ntracks Number of tracks for each previous candidate (1-based)
 * @param numberOfTracks Maximum tracks to consider
 * @param frequencyChangeWeight Weight for frequency change
 * @param transitionCostCutoff Cost cutoff
 * @param ceilings Ceiling frequencies (1-based)
 * @param ceilingsRange Range of ceilings
 * @param ceilingChangeWeight Weight for ceiling change
 * @param currentCandidate Index of current candidate (1-based)
 * @param out_minPos Output: position of minimum
 * @return Minimum transition cost
 */
#ifdef HAVE_XSIMD
double compute_all_transitions_simd(
    const double* prev_delta,
    const double* freqs_current,
    const double* bws_current,
    const double* all_prev_freqs,
    const double* all_prev_bws,
    integer numberOfCandidates,
    integer maxFormants,
    integer ntracks_current,
    const integer* prev_ntracks,
    integer numberOfTracks,
    double frequencyChangeWeight,
    double transitionCostCutoff,
    const double* ceilings,
    double ceilingsRange,
    double ceilingChangeWeight,
    integer currentCandidate,
    integer* out_minPos
) {
    // Compute transition costs to each previous state
    autoVEC transitionCosts = zero_VEC(numberOfCandidates);

    for (integer jformant = 1; jformant <= numberOfCandidates; jformant++) {
        const integer ntracks = std::min(prev_ntracks[jformant], ntracks_current);
        double cost = prev_delta[jformant];

        if (frequencyChangeWeight > 0.0 && ntracks > 0) {
            const double* prev_freqs = all_prev_freqs + (jformant - 1) * maxFormants;
            const double* prev_bws = all_prev_bws + (jformant - 1) * maxFormants;

            cost += compute_frequency_change_cost_simd(
                freqs_current, prev_freqs,
                bws_current, prev_bws,
                ntracks,
                frequencyChangeWeight, transitionCostCutoff
            );
        }

        if (ceilingChangeWeight > 0.0) {
            double ceilingCost = std::fabs(ceilings[currentCandidate] - ceilings[jformant]) / ceilingsRange;
            cost += ceilingChangeWeight * ceilingCost;
        }

        transitionCosts[jformant] = cost;
    }

    // Find minimum
    return find_min_with_position_simd(&transitionCosts[0], numberOfCandidates, out_minPos);
}
#else
double compute_all_transitions_simd(
    const double* prev_delta,
    const double* freqs_current,
    const double* bws_current,
    const double* all_prev_freqs,
    const double* all_prev_bws,
    integer numberOfCandidates,
    integer maxFormants,
    integer ntracks_current,
    const integer* prev_ntracks,
    integer numberOfTracks,
    double frequencyChangeWeight,
    double transitionCostCutoff,
    const double* ceilings,
    double ceilingsRange,
    double ceilingChangeWeight,
    integer currentCandidate,
    integer* out_minPos
) {
    double minCost = std::numeric_limits<double>::infinity();
    integer minPos = 0;

    for (integer jformant = 1; jformant <= numberOfCandidates; jformant++) {
        const integer ntracks = std::min(prev_ntracks[jformant], ntracks_current);
        double cost = prev_delta[jformant];

        if (frequencyChangeWeight > 0.0 && ntracks > 0) {
            const double* prev_freqs = all_prev_freqs + (jformant - 1) * maxFormants;
            const double* prev_bws = all_prev_bws + (jformant - 1) * maxFormants;

            double fcost = 0.0;
            for (integer itrack = 0; itrack < ntracks; itrack++) {
                double fi = freqs_current[itrack];
                double fj = prev_freqs[itrack];
                double dif = std::fabs(fi - fj);
                double sum = fi + fj;
                double bw = std::sqrt(bws_current[itrack] * prev_bws[itrack]);
                fcost += bw * dif / sum;
            }
            fcost /= ntracks;
            cost += frequencyChangeWeight * std::min(fcost / transitionCostCutoff, 1.0);
        }

        if (ceilingChangeWeight > 0.0) {
            double ceilingCost = std::fabs(ceilings[currentCandidate] - ceilings[jformant]) / ceilingsRange;
            cost += ceilingChangeWeight * ceilingCost;
        }

        if (cost < minCost) {
            minCost = cost;
            minPos = jformant;
        }
    }

    *out_minPos = minPos;
    return minCost;
}
#endif

} // namespace formantpath_simd


// ============================================================================
// Bridge functions for Praat integration
// ============================================================================

extern "C" {

// Runtime SIMD enable/disable flag
static bool g_formantpath_simd_enabled = true;

bool should_use_simd_for_formantpath() {
    return g_formantpath_simd_enabled;
}

void set_formantpath_simd_enabled(bool enabled) {
    g_formantpath_simd_enabled = enabled;
}

// Expose namespace functions
void compute_qsums_simd_bridge(
    const double* frequencies,
    const double* bandwidths,
    integer numberOfCandidates,
    integer maxFormants,
    const integer* formantCounts,
    double* qsums
) {
    formantpath_simd::compute_qsums_simd(
        frequencies, bandwidths, numberOfCandidates, maxFormants, formantCounts, qsums
    );
}

double find_min_with_position_simd_bridge(
    const double* values,
    integer n,
    integer* out_minPos
) {
    return formantpath_simd::find_min_with_position_simd(values, n, out_minPos);
}

double compute_frequency_change_cost_simd_bridge(
    const double* freqs_i,
    const double* freqs_j,
    const double* bws_i,
    const double* bws_j,
    integer ntracks,
    double frequencyChangeWeight,
    double transitionCostCutoff
) {
    return formantpath_simd::compute_frequency_change_cost_simd(
        freqs_i, freqs_j, bws_i, bws_j, ntracks, frequencyChangeWeight, transitionCostCutoff
    );
}

void compute_static_costs_simd_bridge(
    const double* stresses,
    const double* qsums,
    const double* intensities,
    integer numberOfCandidates,
    double stressWeight,
    double qWeight,
    double stressCutoff,
    double qCutoff,
    double* delta
) {
    formantpath_simd::compute_static_costs_simd(
        stresses, qsums, intensities, numberOfCandidates,
        stressWeight, qWeight, stressCutoff, qCutoff, delta
    );
}

integer find_max_position_simd_bridge(const double* values, integer n) {
    return formantpath_simd::find_max_position_simd(values, n);
}

double compute_all_transitions_simd_bridge(
    const double* prev_delta,
    const double* freqs_current,
    const double* bws_current,
    const double* all_prev_freqs,
    const double* all_prev_bws,
    integer numberOfCandidates,
    integer maxFormants,
    integer ntracks_current,
    const integer* prev_ntracks,
    integer numberOfTracks,
    double frequencyChangeWeight,
    double transitionCostCutoff,
    const double* ceilings,
    double ceilingsRange,
    double ceilingChangeWeight,
    integer currentCandidate,
    integer* out_minPos
) {
    return formantpath_simd::compute_all_transitions_simd(
        prev_delta, freqs_current, bws_current,
        all_prev_freqs, all_prev_bws,
        numberOfCandidates, maxFormants,
        ntracks_current, prev_ntracks, numberOfTracks,
        frequencyChangeWeight, transitionCostCutoff,
        ceilings, ceilingsRange, ceilingChangeWeight,
        currentCandidate, out_minPos
    );
}

} // extern "C"

/* End of file formantpath_simd.cpp */
