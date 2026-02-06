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

// Detect xsimd version by checking if batch needs 2 template arguments
// In xsimd v8+, batch<double> fails, batch<double, arch> works
// In xsimd v7, batch<double> works

// Create an alias that works with both versions
namespace xsimd_compat {
    // Use default architecture batch type
    template<typename T>
    using batch = xsimd::batch<T, xsimd::default_arch>;
    
    // For older xsimd that might not have default_arch, we can fallback
    // but this should work for most cases since RcppXsimd provides modern xsimd
}

// Compatibility macros for common operations
#define XSIMD_BATCH(T) xsimd_compat::batch<T>
#define XSIMD_BATCH_SIZE(batch_var) batch_var.size

// reduce_add was renamed to reduce in newer versions, check both
namespace xsimd_compat {
    template<typename T, typename A>
    inline T reduce_add_compat(const xsimd::batch<T, A>& b) {
        #if defined(XSIMD_VERSION_MAJOR) && XSIMD_VERSION_MAJOR >= 8
            return xsimd::reduce(b, std::plus<T>());
        #else
            // Try both names for compatibility
            #ifdef XSIMD_HAS_REDUCE_ADD
                return xsimd::reduce_add(b);
            #else
                return xsimd::reduce(b, std::plus<T>());
            #endif
        #endif
    }
}

#endif // HAVE_XSIMD

#endif // XSIMD_COMPAT_H
