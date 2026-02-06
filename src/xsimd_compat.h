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

/*
 * xsimd_compat.h - Compatibility layer for xsimd API versions
 *
 * xsimd v7 (old): batch<T> with 1 template argument
 * xsimd v8+ (new): batch<T, N> with 2 template arguments
 *
 * This header provides macros to write code compatible with both versions.
 */

#ifndef XSIMD_COMPAT_H
#define XSIMD_COMPAT_H

#ifdef HAVE_XSIMD
#include <xsimd/xsimd.hpp>
#include <functional>  // for std::plus

// Compatibility layer for xsimd API differences
// Uses simd_traits to get the correct batch type for the platform
namespace xsimd_compat {
    // Get the default batch type for type T using simd_traits
    // This works with both RcppXsimd (batch<T, N>) and modern xsimd (batch<T, Arch>)
    template<typename T>
    using batch = typename xsimd::simd_traits<T>::type;
}

// Compatibility macros for common operations
#define XSIMD_BATCH(T) xsimd_compat::batch<T>
#define XSIMD_BATCH_SIZE(batch_var) batch_var.size

// reduce_add compatibility wrapper
// RcppXsimd (xsimd v7) doesn't have reduce_add, so we implement it
namespace xsimd_compat {
    template<typename T>
    inline T reduce_add_compat(const typename xsimd::simd_traits<T>::type& b) {
        // Extract elements and sum manually
        alignas(XSIMD_DEFAULT_ALIGNMENT) T data[xsimd::simd_traits<T>::type::size];
        b.store_aligned(data);
        
        T sum = T(0);
        for (size_t i = 0; i < xsimd::simd_traits<T>::type::size; ++i) {
            sum += data[i];
        }
        return sum;
    }
}

#endif // HAVE_XSIMD

#endif // XSIMD_COMPAT_H
