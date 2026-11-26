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
// table_wrappers.cpp
// Wrappers for Praat Table objects

#include <Rcpp.h>
#include "praat_xptr_utils.h"
#include "praat_error_handling.h"
#include "praat.github.io/stat/Table.h"
#include "praat.github.io/stat/TableOfReal.h"

using namespace Rcpp;

// [[Rcpp::export(.table_create)]]
SEXP table_create(int numberOfRows, int numberOfColumns) {
  try {
    autoTable table = Table_create(numberOfRows, numberOfColumns);
    return create_xptr_from_auto<structTable>(table);
  } catch (MelderError) {
    Melder_clearError();
    stop("Failed to create table");
  }
}

// [[Rcpp::export(.table_create_with_column_names)]]
SEXP table_create_with_column_names(int numberOfRows, CharacterVector columnNames) {
  try {
    autoTable table = Table_create(numberOfRows, columnNames.size());
    for (int i = 0; i < columnNames.size(); i++) {
      conststring32 name = Melder_peek8to32(Rcpp::as<std::string>(columnNames[i]).c_str());
      Table_renameColumn_e(table.get(), i+1, name);
    }
    return create_xptr_from_auto<structTable>(table);
  } catch (MelderError) {
    Melder_clearError();
    stop("Failed to create table with column names");
  }
}

// Statistical functions

// [[Rcpp::export(.table_get_column_numbers)]]
NumericVector table_get_column_numbers(SEXP xptr) {
  try {
    Rcpp::XPtr<structTable> ptr(xptr);
    validate_xptr(ptr, "Table");
    NumericVector result(ptr->numberOfColumns);
    for (integer i = 1; i <= ptr->numberOfColumns; i++) {
      result[i-1] = (double)i;
    }
    return result;
  } catch (MelderError) {
    Melder_clearError();
    stop("Failed to get column numbers");
  }
}

// [[Rcpp::export(.table_to_matrix)]]
NumericMatrix table_to_matrix(SEXP xptr) {
  try {
    Rcpp::XPtr<structTable> ptr(xptr);
    validate_xptr(ptr, "Table");
    int nrow = ptr->rows.size;
    int ncol = ptr->numberOfColumns;
    
    NumericMatrix result(nrow, ncol);
    for (int i = 0; i < nrow; i++) {
      for (int j = 0; j < ncol; j++) {
        result(i, j) = Table_getNumericValue_a(ptr.get(), i+1, j+1);
      }
    }
    return result;
  } catch (MelderError) {
    Melder_clearError();
    stop("Failed to convert table to matrix");
  }
}

//' Table: Sort rows (internal)
//' @noRd
// [[Rcpp::export(.table_sort_rows)]]
void table_sort_rows(SEXP xptr, Rcpp::CharacterVector columns) {
  try {
    Rcpp::XPtr<structTable> ptr(xptr);
    validate_xptr(ptr, "Table");

    int n = columns.size();
    autoSTRVEC col_names (n);
    for (int i = 0; i < n; i++) {
      col_names [i + 1] = Melder_dup(Melder_peek8to32(
        Rcpp::as<std::string>(columns[i]).c_str()));
    }
    Table_sortRows(ptr.get(), col_names.get());

  } catch (MelderError) {
    Melder_clearError();
    stop("Failed to sort table rows");
  }
}

//' Table: Extract rows where column number (internal)
//' @noRd
// [[Rcpp::export(.table_extract_rows_where_column_number)]]
SEXP table_extract_rows_where_column_number(
    SEXP xptr,
    int column,
    int which,
    double criterion
) {
  try {
    Rcpp::XPtr<structTable> ptr(xptr);
    validate_xptr(ptr, "Table");

    autoTable result = Table_extractRowsWhereColumn_number(
      ptr.get(), (integer) column,
      static_cast<kMelder_number>(which),
      criterion
    );
    return Rcpp::XPtr<structTable>(result.releaseToAmbiguousOwner());

  } catch (MelderError) {
    Melder_clearError();
    stop("Failed to extract table rows");
  }
}

//' Table: Extract rows where column string (internal)
//' @noRd
// [[Rcpp::export(.table_extract_rows_where_column_string)]]
SEXP table_extract_rows_where_column_string(
    SEXP xptr,
    int column,
    int which,
    std::string criterion
) {
  try {
    Rcpp::XPtr<structTable> ptr(xptr);
    validate_xptr(ptr, "Table");

    autoTable result = Table_extractRowsWhereColumn_string(
      ptr.get(), (integer) column,
      static_cast<kMelder_string>(which),
      Melder_peek8to32(criterion.c_str())
    );
    return Rcpp::XPtr<structTable>(result.releaseToAmbiguousOwner());

  } catch (MelderError) {
    Melder_clearError();
    stop("Failed to extract table rows");
  }
}
