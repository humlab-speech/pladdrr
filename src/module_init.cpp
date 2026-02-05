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
// module_init.cpp
// Rcpp Module initialization hook (pladdrr 2.0)
// Enables dynamic symbol lookup for Rcpp Module boot functions

#include <Rcpp.h>
#include <R_ext/Rdynload.h>

// [[Rcpp::init]]
void register_module_entries(DllInfo* dll) {
    // Enable dynamic symbol lookup so Module() can find boot functions
    // This is called AFTER RcppExports registration, so it augments rather than replaces
    R_useDynamicSymbols(dll, TRUE);
}
