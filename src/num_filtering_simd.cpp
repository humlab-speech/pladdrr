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
// SIMD-optimized IIR filtering operations
// Implements Priority 2, Task 2.2 from SIMD_OPTIMIZATION_PLAN.md

#include <Rcpp.h>
#include "praat.github.io/sys/oo.h"
#include "praat.github.io/dwsys/NUM2.h"

#ifdef HAVE_XSIMD
#include <xsimd/xsimd.hpp>

namespace {

// SIMD-optimized inverse IIR filter
// Note: Main loop has loop-carried dependency (serial), but inner dot product is vectorizable
void filter_inverse_inplace_simd(VEC const& s, constVEC const& filter, VEC const& filterMemory) {
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;
    
    const integer filter_size = filter.size;
    
    // Initialize filter memory
    filterMemory.part(1, filter_size) <<= 0.0;
    
    // Main loop must be serial due to dependency
    for (integer i = 1; i <= s.size; i++) {
        const double y0 = s[i];
        
        // Vectorize the dot product: filter[j] * filterMemory[j]
        batch acc(0.0);
        integer j = 1;
        
        for (; j + simd_size <= filter_size; j += simd_size) {
            batch f = xsimd::load_unaligned(&filter[j]);
            batch m = xsimd::load_unaligned(&filterMemory[j]);
            acc = xsimd::fma(f, m, acc);
        }
        
        double sum = xsimd::reduce_add(acc);
        
        // Scalar remainder
        for (; j <= filter_size; ++j) {
            sum += filter[j] * filterMemory[j];
        }
        
        s[i] += sum;
        
        // Update filter memory (shift operation - not vectorizable)
        for (integer k = filter_size; k > 1; k--) {
            filterMemory[k] = filterMemory[k - 1];
        }
        filterMemory[1] = y0;
    }
}

} // anonymous namespace

#endif // HAVE_XSIMD

// Scalar fallback (just call original Praat implementation)
namespace {

void filter_inverse_inplace_scalar(VEC const& s, constVEC const& filter, VEC const& filterMemory) {
    // Use original Praat implementation
    VECfilterInverse_inplace(s, filter, filterMemory);
}

} // anonymous namespace

// Public interface (for potential R export if needed)
// For now, these SIMD functions are used internally by modifying NUM2.cpp wrappers
extern "C" {

void speaker_filter_inverse_inplace(double* s_data, integer s_size,
                                      const double* filter_data, integer filter_size,
                                      double* memory_data, integer memory_size) {
    VEC s = VEC(s_data, s_size);
    constVEC filter = constVEC(filter_data, filter_size);
    VEC memory = VEC(memory_data, memory_size);
    
#ifdef HAVE_XSIMD
    filter_inverse_inplace_simd(s, filter, memory);
#else
    filter_inverse_inplace_scalar(s, filter, memory);
#endif
}

} // extern "C"
