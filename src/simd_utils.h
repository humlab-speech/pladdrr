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

#include <Rcpp.h>
#include <string>

// Check if SIMD should be used
inline bool use_simd() {
#ifdef HAVE_XSIMD
    // Check global option
    Rcpp::Environment base_env = Rcpp::Environment::namespace_env("base");
    Rcpp::Function getOption = base_env["getOption"];
    
    SEXP opt = getOption("speaker.use_simd", Rcpp::LogicalVector::create(true));
    
    if (Rcpp::is<Rcpp::LogicalVector>(opt)) {
        Rcpp::LogicalVector lv = Rcpp::as<Rcpp::LogicalVector>(opt);
        if (lv.size() > 0 && !Rcpp::LogicalVector::is_na(lv[0])) {
            return lv[0];
        }
    }
    return true;  // Default to using SIMD if available
#else
    return false;  // SIMD not available
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
