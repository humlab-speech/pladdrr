// matrix_wrappers.cpp
// Wrappers for Praat Matrix objects

#include <Rcpp.h>
#include "praat_xptr_utils.h"
#include "praat_error_handling.h"
#include "../praat/fon/Matrix.h"

using namespace Rcpp;

// [[Rcpp::export(.matrix_create)]]
SEXP matrix_create(double xmin, double xmax, int nx, double dx, double x1,
                   double ymin, double ymax, int ny, double dy, double y1) {
  BEGIN_RCPP_PRAAT
  autoMatrix matrix = Matrix_create(xmin, xmax, nx, dx, x1, ymin, ymax, ny, dy, y1);
  return Rcpp::XPtr<structMatrix>(matrix.releaseToAmbiguousOwner(), true);
  END_RCPP_PRAAT
}

// [[Rcpp::export(.matrix_create_simple)]]
SEXP matrix_create_simple(int numberOfRows, int numberOfColumns) {
  BEGIN_RCPP_PRAAT
  autoMatrix matrix = Matrix_createSimple(numberOfRows, numberOfColumns);
  return Rcpp::XPtr<structMatrix>(matrix.releaseToAmbiguousOwner(), true);
  END_RCPP_PRAAT
}

// [[Rcpp::export(.matrix_get_nx)]]
int matrix_get_nx(SEXP xptr) {
  BEGIN_RCPP_PRAAT
  Matrix matrix = GET_PRAAT_OBJECT(Matrix, xptr);
  return matrix->nx;
  END_RCPP_PRAAT
}

// [[Rcpp::export(.matrix_get_ny)]]
int matrix_get_ny(SEXP xptr) {
  BEGIN_RCPP_PRAAT
  Matrix matrix = GET_PRAAT_OBJECT(Matrix, xptr);
  return matrix->ny;
  END_RCPP_PRAAT
}

// [[Rcpp::export(.matrix_get_dx)]]
double matrix_get_dx(SEXP xptr) {
  BEGIN_RCPP_PRAAT
  Matrix matrix = GET_PRAAT_OBJECT(Matrix, xptr);
  return matrix->dx;
  END_RCPP_PRAAT
}

// [[Rcpp::export(.matrix_get_dy)]]
double matrix_get_dy(SEXP xptr) {
  BEGIN_RCPP_PRAAT
  Matrix matrix = GET_PRAAT_OBJECT(Matrix, xptr);
  return matrix->dy;
  END_RCPP_PRAAT
}

// [[Rcpp::export(.matrix_get_x1)]]
double matrix_get_x1(SEXP xptr) {
  BEGIN_RCPP_PRAAT
  Matrix matrix = GET_PRAAT_OBJECT(Matrix, xptr);
  return matrix->x1;
  END_RCPP_PRAAT
}

// [[Rcpp::export(.matrix_get_y1)]]
double matrix_get_y1(SEXP xptr) {
  BEGIN_RCPP_PRAAT
  Matrix matrix = GET_PRAAT_OBJECT(Matrix, xptr);
  return matrix->y1;
  END_RCPP_PRAAT
}

// [[Rcpp::export(.matrix_get_xmin)]]
double matrix_get_xmin(SEXP xptr) {
  BEGIN_RCPP_PRAAT
  Matrix matrix = GET_PRAAT_OBJECT(Matrix, xptr);
  return matrix->xmin;
  END_RCPP_PRAAT
}

// [[Rcpp::export(.matrix_get_xmax)]]
double matrix_get_xmax(SEXP xptr) {
  BEGIN_RCPP_PRAAT
  Matrix matrix = GET_PRAAT_OBJECT(Matrix, xptr);
  return matrix->xmax;
  END_RCPP_PRAAT
}

// [[Rcpp::export(.matrix_get_ymin)]]
double matrix_get_ymin(SEXP xptr) {
  BEGIN_RCPP_PRAAT
  Matrix matrix = GET_PRAAT_OBJECT(Matrix, xptr);
  return matrix->ymin;
  END_RCPP_PRAAT
}

// [[Rcpp::export(.matrix_get_ymax)]]
double matrix_get_ymax(SEXP xptr) {
  BEGIN_RCPP_PRAAT
  Matrix matrix = GET_PRAAT_OBJECT(Matrix, xptr);
  return matrix->ymax;
  END_RCPP_PRAAT
}

// [[Rcpp::export(.matrix_get_value_at_xy)]]
double matrix_get_value_at_xy(SEXP xptr, double x, double y) {
  BEGIN_RCPP_PRAAT
  Matrix matrix = GET_PRAAT_OBJECT(Matrix, xptr);
  return Matrix_getValueAtXY(matrix, x, y);
  END_RCPP_PRAAT
}

// [[Rcpp::export(.matrix_get_value)]]
double matrix_get_value(SEXP xptr, int row, int col) {
  BEGIN_RCPP_PRAAT
  Matrix matrix = GET_PRAAT_OBJECT(Matrix, xptr);
  if (row < 1 || row > matrix->ny || col < 1 || col > matrix->nx) {
    Rf_error("Index out of bounds: row=%d (1-%ld), col=%d (1-%ld)", 
             row, (long)matrix->ny, col, (long)matrix->nx);
  }
  return matrix->z[row][col];
  END_RCPP_PRAAT
}

// [[Rcpp::export(.matrix_set_value)]]
void matrix_set_value(SEXP xptr, int row, int col, double value) {
  BEGIN_RCPP_PRAAT
  Matrix matrix = GET_PRAAT_OBJECT(Matrix, xptr);
  if (row < 1 || row > matrix->ny || col < 1 || col > matrix->nx) {
    Rf_error("Index out of bounds: row=%d (1-%ld), col=%d (1-%ld)", 
             row, (long)matrix->ny, col, (long)matrix->nx);
  }
  matrix->z[row][col] = value;
  END_RCPP_PRAAT
}

// [[Rcpp::export(.matrix_to_r_matrix)]]
NumericMatrix matrix_to_r_matrix(SEXP xptr) {
  BEGIN_RCPP_PRAAT
  Matrix matrix = GET_PRAAT_OBJECT(Matrix, xptr);
  NumericMatrix result(matrix->ny, matrix->nx);
  
  for (integer i = 1; i <= matrix->ny; i++) {
    for (integer j = 1; j <= matrix->nx; j++) {
      result(i-1, j-1) = matrix->z[i][j];
    }
  }
  return result;
  END_RCPP_PRAAT
}

// [[Rcpp::export(.matrix_from_r_matrix)]]
SEXP matrix_from_r_matrix(NumericMatrix rmatrix) {
  BEGIN_RCPP_PRAAT
  int ny = rmatrix.nrow();
  int nx = rmatrix.ncol();
  
  autoMatrix matrix = Matrix_createSimple(ny, nx);
  
  for (int i = 0; i < ny; i++) {
    for (int j = 0; j < nx; j++) {
      matrix->z[i+1][j+1] = rmatrix(i, j);
    }
  }
  
  return Rcpp::XPtr<structMatrix>(matrix.releaseToAmbiguousOwner(), true);
  END_RCPP_PRAAT
}

// [[Rcpp::export(.matrix_formula)]]
void matrix_formula(SEXP xptr, std::string formula) {
  BEGIN_RCPP_PRAAT
  Matrix matrix = GET_PRAAT_OBJECT(Matrix, xptr);
  autostring32 formulaStr = Melder_peek8to32(formula.c_str());
  Matrix_formula(matrix, formulaStr.get(), nullptr, nullptr);
  END_RCPP_PRAAT
}

// Statistical operations

// [[Rcpp::export(.matrix_get_sum)]]
double matrix_get_sum(SEXP xptr) {
  BEGIN_RCPP_PRAAT
  Matrix matrix = GET_PRAAT_OBJECT(Matrix, xptr);
  double sum = 0.0;
  for (integer i = 1; i <= matrix->ny; i++) {
    for (integer j = 1; j <= matrix->nx; j++) {
      sum += matrix->z[i][j];
    }
  }
  return sum;
  END_RCPP_PRAAT
}

// [[Rcpp::export(.matrix_get_mean)]]
double matrix_get_mean(SEXP xptr) {
  BEGIN_RCPP_PRAAT
  Matrix matrix = GET_PRAAT_OBJECT(Matrix, xptr);
  double sum = 0.0;
  integer count = 0;
  for (integer i = 1; i <= matrix->ny; i++) {
    for (integer j = 1; j <= matrix->nx; j++) {
      sum += matrix->z[i][j];
      count++;
    }
  }
  return count > 0 ? sum / count : NAN;
  END_RCPP_PRAAT
}

// [[Rcpp::export(.matrix_get_minimum)]]
double matrix_get_minimum(SEXP xptr) {
  BEGIN_RCPP_PRAAT
  Matrix matrix = GET_PRAAT_OBJECT(Matrix, xptr);
  double min = INFINITY;
  for (integer i = 1; i <= matrix->ny; i++) {
    for (integer j = 1; j <= matrix->nx; j++) {
      if (matrix->z[i][j] < min) {
        min = matrix->z[i][j];
      }
    }
  }
  return min;
  END_RCPP_PRAAT
}

// [[Rcpp::export(.matrix_get_maximum)]]
double matrix_get_maximum(SEXP xptr) {
  BEGIN_RCPP_PRAAT
  Matrix matrix = GET_PRAAT_OBJECT(Matrix, xptr);
  double max = -INFINITY;
  for (integer i = 1; i <= matrix->ny; i++) {
    for (integer j = 1; j <= matrix->nx; j++) {
      if (matrix->z[i][j] > max) {
        max = matrix->z[i][j];
      }
    }
  }
  return max;
  END_RCPP_PRAAT
}
