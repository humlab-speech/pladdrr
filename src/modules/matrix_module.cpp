// matrix_module.cpp
// Rcpp Module exposing Praat Matrix functionality (pladdrr 2.0)

#include <Rcpp.h>
#include "module_common.h"
#include "../datatable_utils.h"
#include "praat.github.io/fon/Matrix.h"

using namespace Rcpp;

class RMatrix {
private:
    XPtr<structMatrix> ptr;

public:
    RMatrix() : ptr(R_NilValue) {}
    RMatrix(XPtr<structMatrix> xptr) : ptr(xptr) {}

    bool is_valid() { return ptr.get() != nullptr; }

    // Dimension properties
    int get_nx() { VALIDATE_PTR(ptr, Matrix); return static_cast<int>(ptr->nx); }
    int get_ny() { VALIDATE_PTR(ptr, Matrix); return static_cast<int>(ptr->ny); }
    int get_nrow() { return get_ny(); }
    int get_ncol() { return get_nx(); }

    // Grid properties
    double get_dx() { VALIDATE_PTR(ptr, Matrix); return ptr->dx; }
    double get_dy() { VALIDATE_PTR(ptr, Matrix); return ptr->dy; }
    double get_x1() { VALIDATE_PTR(ptr, Matrix); return ptr->x1; }
    double get_y1() { VALIDATE_PTR(ptr, Matrix); return ptr->y1; }
    double get_xmin() { VALIDATE_PTR(ptr, Matrix); return ptr->xmin; }
    double get_xmax() { VALIDATE_PTR(ptr, Matrix); return ptr->xmax; }
    double get_ymin() { VALIDATE_PTR(ptr, Matrix); return ptr->ymin; }
    double get_ymax() { VALIDATE_PTR(ptr, Matrix); return ptr->ymax; }

    // Value access
    double get_value(int row, int col) {
        VALIDATE_PTR(ptr, Matrix);
        if (row < 1 || row > ptr->ny || col < 1 || col > ptr->nx) {
            Rcpp::stop("Index out of bounds: row=%d (1-%ld), col=%d (1-%ld)",
                       row, (long)ptr->ny, col, (long)ptr->nx);
        }
        return ptr->z[row][col];
    }

    void set_value(int row, int col, double value) {
        VALIDATE_PTR(ptr, Matrix);
        if (row < 1 || row > ptr->ny || col < 1 || col > ptr->nx) {
            Rcpp::stop("Index out of bounds: row=%d (1-%ld), col=%d (1-%ld)",
                       row, (long)ptr->ny, col, (long)ptr->nx);
        }
        ptr->z[row][col] = value;
    }

    double get_value_at_xy(double x, double y) {
        VALIDATE_PTR(ptr, Matrix);
        return Matrix_getValueAtXY(ptr.get(), x, y);
    }

    // Statistics
    double get_sum() {
        VALIDATE_PTR(ptr, Matrix);
        return Matrix_getSum(ptr.get());
    }

    double get_mean() {
        VALIDATE_PTR(ptr, Matrix);
        integer count = ptr->ny * ptr->nx;
        if (count == 0) return NA_REAL;
        return Matrix_getSum(ptr.get()) / count;
    }

    double get_minimum() {
        VALIDATE_PTR(ptr, Matrix);
        double min = INFINITY;
        for (integer i = 1; i <= ptr->ny; i++) {
            for (integer j = 1; j <= ptr->nx; j++) {
                if (ptr->z[i][j] < min) min = ptr->z[i][j];
            }
        }
        return min;
    }

    double get_maximum() {
        VALIDATE_PTR(ptr, Matrix);
        double max = -INFINITY;
        for (integer i = 1; i <= ptr->ny; i++) {
            for (integer j = 1; j <= ptr->nx; j++) {
                if (ptr->z[i][j] > max) max = ptr->z[i][j];
            }
        }
        return max;
    }

    // Coordinate conversion
    double column_to_x(int col) {
        VALIDATE_PTR(ptr, Matrix);
        return Matrix_columnToX(ptr.get(), col);
    }

    double row_to_y(int row) {
        VALIDATE_PTR(ptr, Matrix);
        return Matrix_rowToY(ptr.get(), row);
    }

    int x_to_nearest_column(double x) {
        VALIDATE_PTR(ptr, Matrix);
        return static_cast<int>(Matrix_xToNearestColumn(ptr.get(), x));
    }

    int y_to_nearest_row(double y) {
        VALIDATE_PTR(ptr, Matrix);
        return static_cast<int>(Matrix_yToNearestRow(ptr.get(), y));
    }

    // Export
    NumericMatrix as_matrix() {
        VALIDATE_PTR(ptr, Matrix);
        NumericMatrix result(ptr->ny, ptr->nx);
        for (integer i = 1; i <= ptr->ny; i++) {
            for (integer j = 1; j <= ptr->nx; j++) {
                result(i-1, j-1) = ptr->z[i][j];
            }
        }
        return result;
    }

    DataFrame as_data_frame() {
        VALIDATE_PTR(ptr, Matrix);
        // Flatten matrix to long format
        std::vector<double> rows, cols, values;
        for (integer i = 1; i <= ptr->ny; i++) {
            for (integer j = 1; j <= ptr->nx; j++) {
                rows.push_back(Matrix_rowToY(ptr.get(), i));
                cols.push_back(Matrix_columnToX(ptr.get(), j));
                values.push_back(ptr->z[i][j]);
            }
        }
        return DataFrame::create(
            Named("y") = rows,
            Named("x") = cols,
            Named("value") = values
        );
    }

    // Static factory methods
    static XPtr<structMatrix> create(double xmin, double xmax, int nx, double dx, double x1,
                                     double ymin, double ymax, int ny, double dy, double y1) {
        try {
            autoMatrix matrix = Matrix_create(xmin, xmax, nx, dx, x1, ymin, ymax, ny, dy, y1);
            structMatrix* raw = matrix.releaseToAmbiguousOwner();
            // Use proper deleter for Praat objects (calls forget() instead of delete)
            auto deleter = [](structMatrix* thing) {
                if (thing != nullptr) forget(thing);
            };
            return XPtr<structMatrix>(raw, deleter);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to create Matrix");
        }
    }

    static XPtr<structMatrix> create_simple(int numberOfRows, int numberOfColumns) {
        try {
            autoMatrix matrix = Matrix_createSimple(numberOfRows, numberOfColumns);
            structMatrix* raw = matrix.releaseToAmbiguousOwner();
            // Use proper deleter for Praat objects (calls forget() instead of delete)
            auto deleter = [](structMatrix* thing) {
                if (thing != nullptr) forget(thing);
            };
            return XPtr<structMatrix>(raw, deleter);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to create simple Matrix");
        }
    }

    static XPtr<structMatrix> from_r_matrix(NumericMatrix rmatrix) {
        try {
            int ny = rmatrix.nrow();
            int nx = rmatrix.ncol();
            autoMatrix matrix = Matrix_createSimple(ny, nx);
            for (int i = 0; i < ny; i++) {
                for (int j = 0; j < nx; j++) {
                    matrix->z[i+1][j+1] = rmatrix(i, j);
                }
            }
            structMatrix* raw = matrix.releaseToAmbiguousOwner();
            // Use proper deleter for Praat objects (calls forget() instead of delete)
            auto deleter = [](structMatrix* thing) {
                if (thing != nullptr) forget(thing);
            };
            return XPtr<structMatrix>(raw, deleter);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to create Matrix from R matrix");
        }
    }

    void save(std::string path) {
        VALIDATE_PTR(ptr, Matrix);
        try {
            structMelderFile file = {};
            Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
            Data_writeToTextFile(ptr.get(), &file);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to save Matrix");
        }
    }
};

RCPP_MODULE(matrix_module) {
    class_<RMatrix>("RMatrix")
        .constructor()
        .constructor<XPtr<structMatrix>>()
        .method("is_valid", &RMatrix::is_valid)
        // Dimensions
        .method("get_nx", &RMatrix::get_nx)
        .method("get_ny", &RMatrix::get_ny)
        .method("get_nrow", &RMatrix::get_nrow)
        .method("get_ncol", &RMatrix::get_ncol)
        // Grid
        .method("get_dx", &RMatrix::get_dx)
        .method("get_dy", &RMatrix::get_dy)
        .method("get_x1", &RMatrix::get_x1)
        .method("get_y1", &RMatrix::get_y1)
        .method("get_xmin", &RMatrix::get_xmin)
        .method("get_xmax", &RMatrix::get_xmax)
        .method("get_ymin", &RMatrix::get_ymin)
        .method("get_ymax", &RMatrix::get_ymax)
        // Value access
        .method("get_value", &RMatrix::get_value)
        .method("set_value", &RMatrix::set_value)
        .method("get_value_at_xy", &RMatrix::get_value_at_xy)
        // Statistics
        .method("get_sum", &RMatrix::get_sum)
        .method("get_mean", &RMatrix::get_mean)
        .method("get_minimum", &RMatrix::get_minimum)
        .method("get_maximum", &RMatrix::get_maximum)
        // Coordinate conversion
        .method("column_to_x", &RMatrix::column_to_x)
        .method("row_to_y", &RMatrix::row_to_y)
        .method("x_to_nearest_column", &RMatrix::x_to_nearest_column)
        .method("y_to_nearest_row", &RMatrix::y_to_nearest_row)
        // Export
        .method("as_matrix", &RMatrix::as_matrix)
        .method("as_data_frame", &RMatrix::as_data_frame)
        .method("save", &RMatrix::save)
    ;

    // Factory functions
    function("Matrix_create", &RMatrix::create);
    function("Matrix_create_simple", &RMatrix::create_simple);
    function("Matrix_from_r_matrix", &RMatrix::from_r_matrix);
}
