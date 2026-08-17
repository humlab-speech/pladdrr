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
#ifndef SIMD_UTILS_H
#define SIMD_UTILS_H

#include <string>
#include <atomic>

// ============================================================================
// Global SIMD toggle — thread-safe, no R API calls
// Set once from R .onLoad() via set_global_simd_enabled()
// ============================================================================

// Defined in simd_utils.cpp
extern std::atomic<bool> g_simd_enabled;

inline bool use_simd() {
#ifdef HAVE_XSIMD
    return g_simd_enabled.load(std::memory_order_relaxed);
#else
    return false;
#endif
}

// Get SIMD architecture in use
inline std::string get_simd_arch() {
#ifdef HAVE_XSIMD
  #if defined(__AVX2__)
    return "AVX2";
  #elif defined(__AVX__)
    return "AVX";
  #elif defined(__SSE4_2__)
    return "SSE4.2";
  #elif defined(__SSE4_1__)
    return "SSE4.1";
  #elif defined(__ARM_NEON)
    return "NEON";
  #else
    return "Generic";
  #endif
#else
  return "Disabled";
#endif
}

// Check if pointer is aligned to given alignment (default 32 bytes for AVX2)
inline bool is_aligned(const void* ptr, size_t alignment = 32) {
  return (reinterpret_cast<uintptr_t>(ptr) % alignment) == 0;
}

#endif // SIMD_UTILS_H
