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

// [[Rcpp::export(.table_get_number_of_rows)]]
int table_get_number_of_rows(SEXP xptr) {
  try {
    Rcpp::XPtr<structTable> ptr(xptr);
    validate_xptr(ptr, "Table");
    return ptr->rows.size;
  } catch (MelderError) {
    Melder_clearError();
    stop("Failed to get number of rows");
  }
}

// [[Rcpp::export(.table_get_number_of_columns)]]
int table_get_number_of_columns(SEXP xptr) {
  try {
    Rcpp::XPtr<structTable> ptr(xptr);
    validate_xptr(ptr, "Table");
    return ptr->numberOfColumns;
  } catch (MelderError) {
    Melder_clearError();
    stop("Failed to get number of columns");
  }
}

// [[Rcpp::export(.table_get_numeric_value)]]
double table_get_numeric_value(SEXP xptr, int rowNumber, int columnNumber) {
  try {
    Rcpp::XPtr<structTable> ptr(xptr);
    validate_xptr(ptr, "Table");
    return Table_getNumericValue_a(ptr.get(), rowNumber, columnNumber);
  } catch (MelderError) {
    Melder_clearError();
    stop("Failed to get numeric value");
  }
}

// [[Rcpp::export(.table_get_string_value)]]
std::string table_get_string_value(SEXP xptr, int rowNumber, int columnNumber) {
  try {
    Rcpp::XPtr<structTable> ptr(xptr);
    validate_xptr(ptr, "Table");
    conststring32 value = Table_getStringValue_a(ptr.get(), rowNumber, columnNumber);
    return Melder_peek32to8(value);
  } catch (MelderError) {
    Melder_clearError();
    stop("Failed to get string value");
  }
}

// [[Rcpp::export(.table_set_numeric_value)]]
void table_set_numeric_value(SEXP xptr, int rowNumber, int columnNumber, double value) {
  try {
    Rcpp::XPtr<structTable> ptr(xptr);
    validate_xptr(ptr, "Table");
    Table_setNumericValue(ptr.get(), rowNumber, columnNumber, value);
  } catch (MelderError) {
    Melder_clearError();
    stop("Failed to set numeric value");
  }
}

// [[Rcpp::export(.table_remove_row)]]
void table_remove_row(SEXP xptr, int rowNumber) {
  try {
    Rcpp::XPtr<structTable> ptr(xptr);
    validate_xptr(ptr, "Table");
    Table_removeRow(ptr.get(), rowNumber);
  } catch (MelderError) {
    Melder_clearError();
    stop("Failed to remove row");
  }
}

// [[Rcpp::export(.table_remove_column)]]
void table_remove_column(SEXP xptr, int columnNumber) {
  try {
    Rcpp::XPtr<structTable> ptr(xptr);
    validate_xptr(ptr, "Table");
    Table_removeColumn(ptr.get(), columnNumber);
  } catch (MelderError) {
    Melder_clearError();
    stop("Failed to remove column");
  }
}

// [[Rcpp::export(.table_insert_column)]]
void table_insert_column(SEXP xptr, int columnPosition, std::string columnName) {
  try {
    Rcpp::XPtr<structTable> ptr(xptr);
    validate_xptr(ptr, "Table");
    conststring32 name = Melder_peek8to32(columnName.c_str());
    Table_insertColumn(ptr.get(), columnPosition, name);
  } catch (MelderError) {
    Melder_clearError();
    stop("Failed to insert column");
  }
}

// Statistical functions

// [[Rcpp::export(.table_get_mean)]]
double table_get_mean(SEXP xptr, int columnNumber) {
  try {
    Rcpp::XPtr<structTable> ptr(xptr);
    validate_xptr(ptr, "Table");
    return Table_getMean(ptr.get(), columnNumber);
  } catch (MelderError) {
    Melder_clearError();
    stop("Failed to get mean");
  }
}

// [[Rcpp::export(.table_get_stdev)]]
double table_get_stdev(SEXP xptr, int columnNumber) {
  try {
    Rcpp::XPtr<structTable> ptr(xptr);
    validate_xptr(ptr, "Table");
    return Table_getStdev(ptr.get(), columnNumber);
  } catch (MelderError) {
    Melder_clearError();
    stop("Failed to get standard deviation");
  }
}

// [[Rcpp::export(.table_get_minimum)]]
double table_get_minimum(SEXP xptr, int columnNumber) {
  try {
    Rcpp::XPtr<structTable> ptr(xptr);
    validate_xptr(ptr, "Table");
    return Table_getMinimum(ptr.get(), columnNumber);
  } catch (MelderError) {
    Melder_clearError();
    stop("Failed to get minimum");
  }
}

// [[Rcpp::export(.table_get_maximum)]]
double table_get_maximum(SEXP xptr, int columnNumber) {
  try {
    Rcpp::XPtr<structTable> ptr(xptr);
    validate_xptr(ptr, "Table");
    return Table_getMaximum(ptr.get(), columnNumber);
  } catch (MelderError) {
    Melder_clearError();
    stop("Failed to get maximum");
  }
}

// [[Rcpp::export(.table_get_sum)]]
double table_get_sum(SEXP xptr, int columnNumber) {
  try {
    Rcpp::XPtr<structTable> ptr(xptr);
    validate_xptr(ptr, "Table");
    return Table_getSum(ptr.get(), columnNumber);
  } catch (MelderError) {
    Melder_clearError();
    stop("Failed to get sum");
  }
}

// [[Rcpp::export(.table_get_quantile)]]
double table_get_quantile(SEXP xptr, int columnNumber, double quantile) {
  try {
    Rcpp::XPtr<structTable> ptr(xptr);
    validate_xptr(ptr, "Table");
    return Table_getQuantile(ptr.get(), columnNumber, quantile);
  } catch (MelderError) {
    Melder_clearError();
    stop("Failed to get quantile");
  }
}

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

// [[Rcpp::export(.table_get_column_names)]]
CharacterVector table_get_column_names(SEXP xptr) {
  try {
    Rcpp::XPtr<structTable> ptr(xptr);
    validate_xptr(ptr, "Table");
    CharacterVector result(ptr->numberOfColumns);
    for (integer i = 1; i <= ptr->numberOfColumns; i++) {
      result[i-1] = Melder_peek32to8(ptr->columnHeaders[i].label.get());
    }
    return result;
  } catch (MelderError) {
    Melder_clearError();
    stop("Failed to get column names");
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
