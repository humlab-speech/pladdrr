/*
 * Part of pladdrr: R interface to Praat
 *
 * Copyright (C) 2025 Fredrik Nylén
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 */
#include <Rcpp.h>
#include "simd_utils.h"

// Global SIMD toggle — default ON
bool g_simd_enabled = true;

// [[Rcpp::export]]
void set_global_simd_enabled(bool enabled) {
    g_simd_enabled = enabled;
}

// [[Rcpp::export]]
bool get_global_simd_enabled() {
    return g_simd_enabled;
}
