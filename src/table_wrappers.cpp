// table_wrappers.cpp
// Wrappers for Praat Table objects

#include <Rcpp.h>
#include "praat_xptr_utils.h"
#include "praat_error_handling.h"
#include "../praat.github.io/stat/Table.h"
#include "../praat.github.io/stat/TableOfReal.h"

using namespace Rcpp;

// [[Rcpp::export(.table_create)]]
SEXP table_create(int numberOfRows, int numberOfColumns) {
  BEGIN_RCPP_PRAAT
  autoTable table = Table_create(numberOfRows, numberOfColumns);
  return Rcpp::XPtr<structTable>(table.releaseToAmbiguousOwner(), true);
  END_RCPP_PRAAT
}

// [[Rcpp::export(.table_create_with_column_names)]]
SEXP table_create_with_column_names(int numberOfRows, CharacterVector columnNames) {
  BEGIN_RCPP_PRAAT
  autoSTRVEC names = autoSTRVEC(columnNames.size());
  for (int i = 0; i < columnNames.size(); i++) {
    names[i] = Melder_dup(Rcpp::as<std::string>(columnNames[i]).c_str()).releaseToAmbiguousOwner();
  }
  autoTable table = Table_createWithColumnNames(numberOfRows, names.get());
  return Rcpp::XPtr<structTable>(table.releaseToAmbiguousOwner(), true);
  END_RCPP_PRAAT
}

// [[Rcpp::export(.table_get_number_of_rows)]]
int table_get_number_of_rows(SEXP xptr) {
  BEGIN_RCPP_PRAAT
  Table table = GET_PRAAT_OBJECT(Table, xptr);
  return table->rows.size;
  END_RCPP_PRAAT
}

// [[Rcpp::export(.table_get_number_of_columns)]]
int table_get_number_of_columns(SEXP xptr) {
  BEGIN_RCPP_PRAAT
  Table table = GET_PRAAT_OBJECT(Table, xptr);
  return table->numberOfColumns;
  END_RCPP_PRAAT
}

// [[Rcpp::export(.table_get_column_label)]]
std::string table_get_column_label(SEXP xptr, int columnNumber) {
  BEGIN_RCPP_PRAAT
  Table table = GET_PRAAT_OBJECT(Table, xptr);
  if (columnNumber < 1 || columnNumber > table->numberOfColumns) {
    Rf_error("Column number %d out of range [1, %ld]", columnNumber, (long)table->numberOfColumns);
  }
  return Melder_peek32to8(table->columnHeaders[columnNumber].label.get());
  END_RCPP_PRAAT
}

// [[Rcpp::export(.table_get_column_index)]]
int table_get_column_index(SEXP xptr, std::string columnName) {
  BEGIN_RCPP_PRAAT
  Table table = GET_PRAAT_OBJECT(Table, xptr);
  autostring32 name = Melder_peek8to32(columnName.c_str());
  integer index = Table_columnNameToNumber_0(table, name.get());
  return (int)index;
  END_RCPP_PRAAT
}

// [[Rcpp::export(.table_set_column_label)]]
void table_set_column_label(SEXP xptr, int columnNumber, std::string label) {
  BEGIN_RCPP_PRAAT
  Table table = GET_PRAAT_OBJECT(Table, xptr);
  autostring32 labelStr = Melder_peek8to32(label.c_str());
  Table_renameColumn_e(table, columnNumber, labelStr.get());
  END_RCPP_PRAAT
}

// [[Rcpp::export(.table_get_numeric_value)]]
double table_get_numeric_value(SEXP xptr, int rowNumber, int columnNumber) {
  BEGIN_RCPP_PRAAT
  Table table = GET_PRAAT_OBJECT(Table, xptr);
  return Table_getNumericValue_a(table, rowNumber, columnNumber);
  END_RCPP_PRAAT
}

// [[Rcpp::export(.table_get_string_value)]]
std::string table_get_string_value(SEXP xptr, int rowNumber, int columnNumber) {
  BEGIN_RCPP_PRAAT
  Table table = GET_PRAAT_OBJECT(Table, xptr);
  conststring32 value = Table_getStringValue_a(table, rowNumber, columnNumber);
  return Melder_peek32to8(value);
  END_RCPP_PRAAT
}

// [[Rcpp::export(.table_set_numeric_value)]]
void table_set_numeric_value(SEXP xptr, int rowNumber, int columnNumber, double value) {
  BEGIN_RCPP_PRAAT
  Table table = GET_PRAAT_OBJECT(Table, xptr);
  Table_setNumericValue(table, rowNumber, columnNumber, value);
  END_RCPP_PRAAT
}

// [[Rcpp::export(.table_set_string_value)]]
void table_set_string_value(SEXP xptr, int rowNumber, int columnNumber, std::string value) {
  BEGIN_RCPP_PRAAT
  Table table = GET_PRAAT_OBJECT(Table, xptr);
  autostring32 valueStr = Melder_peek8to32(value.c_str());
  Table_setStringValue(table, rowNumber, columnNumber, valueStr.get());
  END_RCPP_PRAAT
}

// [[Rcpp::export(.table_append_row)]]
void table_append_row(SEXP xptr) {
  BEGIN_RCPP_PRAAT
  Table table = GET_PRAAT_OBJECT(Table, xptr);
  Table_appendRow(table);
  END_RCPP_PRAAT
}

// [[Rcpp::export(.table_append_column)]]
void table_append_column(SEXP xptr, std::string columnName) {
  BEGIN_RCPP_PRAAT
  Table table = GET_PRAAT_OBJECT(Table, xptr);
  autostring32 name = Melder_peek8to32(columnName.c_str());
  Table_appendColumn(table, name.get());
  END_RCPP_PRAAT
}

// [[Rcpp::export(.table_remove_row)]]
void table_remove_row(SEXP xptr, int rowNumber) {
  BEGIN_RCPP_PRAAT
  Table table = GET_PRAAT_OBJECT(Table, xptr);
  Table_removeRow(table, rowNumber);
  END_RCPP_PRAAT
}

// [[Rcpp::export(.table_remove_column)]]
void table_remove_column(SEXP xptr, int columnNumber) {
  BEGIN_RCPP_PRAAT
  Table table = GET_PRAAT_OBJECT(Table, xptr);
  Table_removeColumn(table, columnNumber);
  END_RCPP_PRAAT
}

// [[Rcpp::export(.table_insert_row)]]
void table_insert_row(SEXP xptr, int rowPosition) {
  BEGIN_RCPP_PRAAT
  Table table = GET_PRAAT_OBJECT(Table, xptr);
  Table_insertRow(table, rowPosition);
  END_RCPP_PRAAT
}

// [[Rcpp::export(.table_insert_column)]]
void table_insert_column(SEXP xptr, int columnPosition, std::string columnName) {
  BEGIN_RCPP_PRAAT
  Table table = GET_PRAAT_OBJECT(Table, xptr);
  autostring32 name = Melder_peek8to32(columnName.c_str());
  Table_insertColumn(table, columnPosition, name.get());
  END_RCPP_PRAAT
}

// Statistical functions

// [[Rcpp::export(.table_get_mean)]]
double table_get_mean(SEXP xptr, int columnNumber) {
  BEGIN_RCPP_PRAAT
  Table table = GET_PRAAT_OBJECT(Table, xptr);
  return Table_getMean(table, columnNumber);
  END_RCPP_PRAAT
}

// [[Rcpp::export(.table_get_stdev)]]
double table_get_stdev(SEXP xptr, int columnNumber) {
  BEGIN_RCPP_PRAAT
  Table table = GET_PRAAT_OBJECT(Table, xptr);
  return Table_getStdev(table, columnNumber);
  END_RCPP_PRAAT
}

// [[Rcpp::export(.table_get_minimum)]]
double table_get_minimum(SEXP xptr, int columnNumber) {
  BEGIN_RCPP_PRAAT
  Table table = GET_PRAAT_OBJECT(Table, xptr);
  return Table_getMinimum(table, columnNumber);
  END_RCPP_PRAAT
}

// [[Rcpp::export(.table_get_maximum)]]
double table_get_maximum(SEXP xptr, int columnNumber) {
  BEGIN_RCPP_PRAAT
  Table table = GET_PRAAT_OBJECT(Table, xptr);
  return Table_getMaximum(table, columnNumber);
  END_RCPP_PRAAT
}

// [[Rcpp::export(.table_get_sum)]]
double table_get_sum(SEXP xptr, int columnNumber) {
  BEGIN_RCPP_PRAAT
  Table table = GET_PRAAT_OBJECT(Table, xptr);
  return Table_getSum(table, columnNumber);
  END_RCPP_PRAAT
}

// [[Rcpp::export(.table_get_quantile)]]
double table_get_quantile(SEXP xptr, int columnNumber, double quantile) {
  BEGIN_RCPP_PRAAT
  Table table = GET_PRAAT_OBJECT(Table, xptr);
  return Table_getQuantile(table, columnNumber, quantile);
  END_RCPP_PRAAT
}

// [[Rcpp::export(.table_get_column_numbers)]]
NumericVector table_get_column_numbers(SEXP xptr) {
  BEGIN_RCPP_PRAAT
  Table table = GET_PRAAT_OBJECT(Table, xptr);
  NumericVector result(table->numberOfColumns);
  for (integer i = 1; i <= table->numberOfColumns; i++) {
    result[i-1] = (double)i;
  }
  return result;
  END_RCPP_PRAAT
}

// [[Rcpp::export(.table_get_column_names)]]
CharacterVector table_get_column_names(SEXP xptr) {
  BEGIN_RCPP_PRAAT
  Table table = GET_PRAAT_OBJECT(Table, xptr);
  CharacterVector result(table->numberOfColumns);
  for (integer i = 1; i <= table->numberOfColumns; i++) {
    result[i-1] = Melder_peek32to8(table->columnHeaders[i].label.get());
  }
  return result;
  END_RCPP_PRAAT
}

// [[Rcpp::export(.table_to_matrix)]]
NumericMatrix table_to_matrix(SEXP xptr) {
  BEGIN_RCPP_PRAAT
  Table table = GET_PRAAT_OBJECT(Table, xptr);
  int nrow = table->rows.size;
  int ncol = table->numberOfColumns;
  
  NumericMatrix result(nrow, ncol);
  for (int i = 0; i < nrow; i++) {
    for (int j = 0; j < ncol; j++) {
      result(i, j) = Table_getNumericValue_a(table, i+1, j+1);
    }
  }
  return result;
  END_RCPP_PRAAT
}
