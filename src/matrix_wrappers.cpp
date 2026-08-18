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
// matrix_wrappers.cpp
// Wrappers for Praat Matrix objects

#include <Rcpp.h>
#include <numeric>
#include <algorithm>
#include "praat_xptr_utils.h"
#include "praat_error_handling.h"
#include "simd_utils.h"
#include "fon/Matrix.h"

// Note: Don't use "using namespace Rcpp" to avoid Matrix type collision

// [[Rcpp::export(.matrix_create)]]
SEXP matrix_create(double xmin, double xmax, int nx, double dx, double x1,
                   double ymin, double ymax, int ny, double dy, double y1) {
  try {
    autoMatrix matrix = Matrix_create(xmin, xmax, nx, dx, x1, ymin, ymax, ny, dy, y1);
    return create_xptr_from_auto<structMatrix>(matrix);
  } catch (MelderError) {
    Melder_clearError();
    Rcpp::stop("Failed to create Matrix");
  }
}

// [[Rcpp::export(.matrix_create_simple)]]
SEXP matrix_create_simple(int numberOfRows, int numberOfColumns) {
  try {
    autoMatrix matrix = Matrix_createSimple(numberOfRows, numberOfColumns);
    return create_xptr_from_auto<structMatrix>(matrix);
  } catch (MelderError) {
    Melder_clearError();
    Rcpp::stop("Failed to create simple Matrix");
  }
}

// [[Rcpp::export(.matrix_to_r_matrix)]]
Rcpp::NumericMatrix matrix_to_r_matrix(SEXP xptr) {
  try {
  Matrix matrix = Rcpp::as<Rcpp::XPtr<structMatrix>>(xptr);
  Rcpp::NumericMatrix result(matrix->ny, matrix->nx);
  
  for (integer i = 1; i <= matrix->ny; i++) {
    for (integer j = 1; j <= matrix->nx; j++) {
      result(i-1, j-1) = matrix->z[i][j];
    }
  }
  return result;
  } catch (MelderError) { Melder_clearError(); Rcpp::stop("Matrix operation failed"); }
}

// [[Rcpp::export(.matrix_from_r_matrix)]]
SEXP matrix_from_r_matrix(Rcpp::NumericMatrix rmatrix) {
  try {
  int ny = rmatrix.nrow();
  int nx = rmatrix.ncol();

  autoMatrix matrix = Matrix_createSimple(ny, nx);

  for (int i = 0; i < ny; i++) {
    for (int j = 0; j < nx; j++) {
      matrix->z[i+1][j+1] = rmatrix(i, j);
    }
  }

  return create_xptr_from_auto<structMatrix>(matrix);
  } catch (MelderError) { Melder_clearError(); Rcpp::stop("Matrix operation failed"); }
}

// [[Rcpp::export(.matrix_read)]]
SEXP matrix_read(std::string path) {
  try {
    structMelderFile file = {};
    Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
    autoMatrix matrix = Data_readFromTextFile(&file).static_cast_move<structMatrix>();
    return create_xptr_from_auto<structMatrix>(matrix);
  } catch (MelderError) {
    Melder_clearError();
    Rcpp::stop("Failed to read Matrix");
  }
}

// Statistical operations

