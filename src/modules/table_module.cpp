// table_module.cpp
// Rcpp Module exposing Praat Table functionality (pladdrr 2.0)
//
// Table: generic tabular data structure with rows and columns

#include <Rcpp.h>
#include "module_common.h"
#include "praat.github.io/stat/Table.h"
#include "praat.github.io/stat/TableOfReal.h"

using namespace Rcpp;

class RTable {
private:
    XPtr<structTable> ptr;

public:
    RTable() : ptr(R_NilValue) {}
    RTable(XPtr<structTable> xptr) : ptr(xptr) {}

    bool is_valid() { return ptr.get() != nullptr; }

    // Dimension properties
    int get_number_of_rows() {
        VALIDATE_PTR(ptr, Table);
        return static_cast<int>(ptr->rows.size);
    }

    int get_number_of_columns() {
        VALIDATE_PTR(ptr, Table);
        return static_cast<int>(ptr->numberOfColumns);
    }

    // Column names
    std::string get_column_label(int column_number) {
        VALIDATE_PTR(ptr, Table);
        if (column_number < 1 || column_number > ptr->numberOfColumns) {
            Rcpp::stop("Column number out of range");
        }
        return Melder_peek32to8(ptr->columnHeaders[column_number].label.get());
    }

    int get_column_index(std::string column_name) {
        VALIDATE_PTR(ptr, Table);
        conststring32 name = Melder_peek8to32(column_name.c_str());
        integer index = Table_columnNameToNumber_0(ptr.get(), name);
        return static_cast<int>(index);
    }

    void set_column_label(int column_number, std::string label) {
        VALIDATE_PTR(ptr, Table);
        try {
            conststring32 labelStr = Melder_peek8to32(label.c_str());
            Table_renameColumn_e(ptr.get(), column_number, labelStr);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to set column label");
        }
    }

    CharacterVector get_column_names() {
        VALIDATE_PTR(ptr, Table);
        CharacterVector result(ptr->numberOfColumns);
        for (integer i = 1; i <= ptr->numberOfColumns; i++) {
            result[i-1] = Melder_peek32to8(ptr->columnHeaders[i].label.get());
        }
        return result;
    }

    // Value access
    double get_numeric_value(int row, int column) {
        VALIDATE_PTR(ptr, Table);
        if (row < 1 || row > ptr->rows.size) Rcpp::stop("Row number out of range");
        if (column < 1 || column > ptr->numberOfColumns) Rcpp::stop("Column number out of range");
        return Table_getNumericValue_a(ptr.get(), row, column);
    }

    std::string get_string_value(int row, int column) {
        VALIDATE_PTR(ptr, Table);
        if (row < 1 || row > ptr->rows.size) Rcpp::stop("Row number out of range");
        if (column < 1 || column > ptr->numberOfColumns) Rcpp::stop("Column number out of range");
        conststring32 value = Table_getStringValue_a(ptr.get(), row, column);
        return Melder_peek32to8(value);
    }

    void set_numeric_value(int row, int column, double value) {
        VALIDATE_PTR(ptr, Table);
        try {
            Table_setNumericValue(ptr.get(), row, column, value);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to set numeric value");
        }
    }

    void set_string_value(int row, int column, std::string value) {
        VALIDATE_PTR(ptr, Table);
        try {
            conststring32 valueStr = Melder_peek8to32(value.c_str());
            Table_setStringValue(ptr.get(), row, column, valueStr);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to set string value");
        }
    }

    // Row/column manipulation
    void append_row() {
        VALIDATE_PTR(ptr, Table);
        try {
            Table_appendRow(ptr.get());
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to append row");
        }
    }

    void append_column(std::string column_name) {
        VALIDATE_PTR(ptr, Table);
        try {
            conststring32 name = Melder_peek8to32(column_name.c_str());
            Table_appendColumn(ptr.get(), name);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to append column");
        }
    }

    void insert_row(int row_position) {
        VALIDATE_PTR(ptr, Table);
        try {
            Table_insertRow(ptr.get(), row_position);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to insert row");
        }
    }

    void insert_column(int column_position, std::string column_name) {
        VALIDATE_PTR(ptr, Table);
        try {
            conststring32 name = Melder_peek8to32(column_name.c_str());
            Table_insertColumn(ptr.get(), column_position, name);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to insert column");
        }
    }

    void remove_row(int row_number) {
        VALIDATE_PTR(ptr, Table);
        try {
            Table_removeRow(ptr.get(), row_number);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to remove row");
        }
    }

    void remove_column(int column_number) {
        VALIDATE_PTR(ptr, Table);
        try {
            Table_removeColumn(ptr.get(), column_number);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to remove column");
        }
    }

    // Statistical functions
    double get_mean(int column) {
        VALIDATE_PTR(ptr, Table);
        try {
            return Table_getMean(ptr.get(), column);
        } catch (MelderError) {
            Melder_clearError();
            return NA_REAL;
        }
    }

    double get_stdev(int column) {
        VALIDATE_PTR(ptr, Table);
        try {
            return Table_getStdev(ptr.get(), column);
        } catch (MelderError) {
            Melder_clearError();
            return NA_REAL;
        }
    }

    double get_minimum(int column) {
        VALIDATE_PTR(ptr, Table);
        try {
            return Table_getMinimum(ptr.get(), column);
        } catch (MelderError) {
            Melder_clearError();
            return NA_REAL;
        }
    }

    double get_maximum(int column) {
        VALIDATE_PTR(ptr, Table);
        try {
            return Table_getMaximum(ptr.get(), column);
        } catch (MelderError) {
            Melder_clearError();
            return NA_REAL;
        }
    }

    double get_sum(int column) {
        VALIDATE_PTR(ptr, Table);
        try {
            return Table_getSum(ptr.get(), column);
        } catch (MelderError) {
            Melder_clearError();
            return NA_REAL;
        }
    }

    double get_quantile(int column, double quantile) {
        VALIDATE_PTR(ptr, Table);
        try {
            return Table_getQuantile(ptr.get(), column, quantile);
        } catch (MelderError) {
            Melder_clearError();
            return NA_REAL;
        }
    }

    // Export
    NumericMatrix as_matrix() {
        VALIDATE_PTR(ptr, Table);
        int nrow = ptr->rows.size;
        int ncol = ptr->numberOfColumns;

        NumericMatrix result(nrow, ncol);
        for (int i = 0; i < nrow; i++) {
            for (int j = 0; j < ncol; j++) {
                result(i, j) = Table_getNumericValue_a(ptr.get(), i+1, j+1);
            }
        }
        return result;
    }

    DataFrame as_data_frame() {
        VALIDATE_PTR(ptr, Table);
        int nrow = ptr->rows.size;
        int ncol = ptr->numberOfColumns;

        List columns(ncol);
        CharacterVector col_names(ncol);

        for (int j = 1; j <= ncol; j++) {
            NumericVector col(nrow);
            for (int i = 1; i <= nrow; i++) {
                col[i-1] = Table_getNumericValue_a(ptr.get(), i, j);
            }
            columns[j-1] = col;
            col_names[j-1] = Melder_peek32to8(ptr->columnHeaders[j].label.get());
        }

        columns.attr("names") = col_names;
        columns.attr("class") = "data.frame";
        columns.attr("row.names") = IntegerVector::create(NA_INTEGER, -nrow);
        return columns;
    }

    List get_info() {
        VALIDATE_PTR(ptr, Table);
        return List::create(
            Named("n_rows") = ptr->rows.size,
            Named("n_columns") = ptr->numberOfColumns,
            Named("column_names") = get_column_names()
        );
    }

    void save(std::string path) {
        VALIDATE_PTR(ptr, Table);
        try {
            structMelderFile file = {};
            Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
            Data_writeToTextFile(ptr.get(), &file);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to save Table");
        }
    }
};

// Factory functions
static XPtr<structTable> Module_Table_create(int n_rows, int n_columns) {
    try {
        autoTable table = Table_create(n_rows, n_columns);
        structTable* raw = table.releaseToAmbiguousOwner();
        // Use proper deleter for Praat objects (calls forget() instead of delete)
        auto deleter = [](structTable* thing) {
            if (thing != nullptr) forget(thing);
        };
        return XPtr<structTable>(raw, deleter);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to create Table");
    }
}

static XPtr<structTable> Module_Table_create_with_column_names(
    int n_rows, CharacterVector column_names) {
    try {
        autoTable table = Table_create(n_rows, column_names.size());
        for (int i = 0; i < column_names.size(); i++) {
            conststring32 name = Melder_peek8to32(
                Rcpp::as<std::string>(column_names[i]).c_str()
            );
            Table_renameColumn_e(table.get(), i+1, name);
        }
        structTable* raw = table.releaseToAmbiguousOwner();
        // Use proper deleter for Praat objects (calls forget() instead of delete)
        auto deleter = [](structTable* thing) {
            if (thing != nullptr) forget(thing);
        };
        return XPtr<structTable>(raw, deleter);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to create Table with column names");
    }
}

static XPtr<structTable> Module_Table_from_data_frame(DataFrame df) {
    try {
        int n_rows = df.nrows();
        int n_cols = df.size();
        CharacterVector col_names = df.names();

        autoTable table = Table_create(n_rows, n_cols);

        // Set column names
        for (int j = 0; j < n_cols; j++) {
            conststring32 name = Melder_peek8to32(
                Rcpp::as<std::string>(col_names[j]).c_str()
            );
            Table_renameColumn_e(table.get(), j+1, name);
        }

        // Fill data
        for (int j = 0; j < n_cols; j++) {
            SEXP col = df[j];
            if (TYPEOF(col) == REALSXP) {
                NumericVector v = as<NumericVector>(col);
                for (int i = 0; i < n_rows; i++) {
                    Table_setNumericValue(table.get(), i+1, j+1, v[i]);
                }
            } else if (TYPEOF(col) == INTSXP) {
                IntegerVector v = as<IntegerVector>(col);
                for (int i = 0; i < n_rows; i++) {
                    Table_setNumericValue(table.get(), i+1, j+1, (double)v[i]);
                }
            } else if (TYPEOF(col) == STRSXP) {
                CharacterVector v = as<CharacterVector>(col);
                for (int i = 0; i < n_rows; i++) {
                    conststring32 val = Melder_peek8to32(
                        Rcpp::as<std::string>(v[i]).c_str()
                    );
                    Table_setStringValue(table.get(), i+1, j+1, val);
                }
            }
        }

        structTable* raw = table.releaseToAmbiguousOwner();
        // Use proper deleter for Praat objects (calls forget() instead of delete)
        auto deleter = [](structTable* thing) {
            if (thing != nullptr) forget(thing);
        };
        return XPtr<structTable>(raw, deleter);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to create Table from data.frame");
    }
}

RCPP_MODULE(table_module) {
    class_<RTable>("RTable")
        .constructor()
        .constructor<XPtr<structTable>>()
        .method("is_valid", &RTable::is_valid)
        // Dimensions
        .method("get_number_of_rows", &RTable::get_number_of_rows)
        .method("get_number_of_columns", &RTable::get_number_of_columns)
        // Column names
        .method("get_column_label", &RTable::get_column_label)
        .method("get_column_index", &RTable::get_column_index)
        .method("set_column_label", &RTable::set_column_label)
        .method("get_column_names", &RTable::get_column_names)
        // Value access
        .method("get_numeric_value", &RTable::get_numeric_value)
        .method("get_string_value", &RTable::get_string_value)
        .method("set_numeric_value", &RTable::set_numeric_value)
        .method("set_string_value", &RTable::set_string_value)
        // Row/column manipulation
        .method("append_row", &RTable::append_row)
        .method("append_column", &RTable::append_column)
        .method("insert_row", &RTable::insert_row)
        .method("insert_column", &RTable::insert_column)
        .method("remove_row", &RTable::remove_row)
        .method("remove_column", &RTable::remove_column)
        // Statistics
        .method("get_mean", &RTable::get_mean)
        .method("get_stdev", &RTable::get_stdev)
        .method("get_minimum", &RTable::get_minimum)
        .method("get_maximum", &RTable::get_maximum)
        .method("get_sum", &RTable::get_sum)
        .method("get_quantile", &RTable::get_quantile)
        // Export
        .method("as_matrix", &RTable::as_matrix)
        .method("as_data_frame", &RTable::as_data_frame)
        .method("get_info", &RTable::get_info)
        .method("save", &RTable::save)
    ;

    // Factory functions
    function("Table_create", &Module_Table_create);
    function("Table_create_with_column_names", &Module_Table_create_with_column_names);
    function("Table_from_data_frame", &Module_Table_from_data_frame);
}
