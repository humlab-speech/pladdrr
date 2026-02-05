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
// polygon_module.cpp
// Rcpp Module for Praat Polygon object
// Part of the pladdrr package - Phase 2 extension

#include <Rcpp.h>
#include "module_common.h"
#include "../datatable_utils.h"

// Praat headers
#include "../praat.github.io/fon/Polygon.h"
#include "../praat.github.io/melder/melder.h"

using namespace Rcpp;

// Forward declaration - NUMfpp initialization
extern void NUMmachar();

// ============================================================================
// Free Functions for Polygon Creation
// ============================================================================

XPtr<structPolygon> polygon_create_xptr(NumericVector x, NumericVector y) {
    if (x.size() != y.size()) {
        Rcpp::stop("x and y must have same length");
    }
    if (x.size() < 1) {
        Rcpp::stop("Must have at least 1 point");
    }

    // Ensure NUMfpp is initialized
    NUMmachar();

    try {
        integer n = x.size();
        autoPolygon polygon = Polygon_create(n);
        
        // Copy data
        for (integer i = 1; i <= n; i++) {
            polygon->x[i] = x[i-1];  // R is 0-based, Praat is 1-based
            polygon->y[i] = y[i-1];
        }
        
        return create_xptr_from_auto<structPolygon>(polygon);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to create Polygon");
    }
}

// ============================================================================
// RPolygon Module Class
// ============================================================================

class RPolygon {
public:
    Rcpp::XPtr<structPolygon> ptr;

    // ========================================================================
    // Constructors
    // ========================================================================

    // Default constructor (empty/invalid object)
    RPolygon() : ptr(R_NilValue) {}

    // Constructor from external pointer
    RPolygon(Rcpp::XPtr<structPolygon> p) : ptr(p) {}

    // ========================================================================
    // Properties (read-only)
    // ========================================================================

    bool is_valid() {
        return ptr.get() != nullptr;
    }

    int get_number_of_points() {
        if (!is_valid()) return 0;
        return static_cast<int>(ptr->numberOfPoints);
    }

    // ========================================================================
    // Data Access
    // ========================================================================

    double get_x(int i) {
        if (!is_valid()) return NA_REAL;
        if (i < 1 || i > ptr->numberOfPoints) {
            Rcpp::stop("Point index out of range");
        }
        return ptr->x[i];
    }

    double get_y(int i) {
        if (!is_valid()) return NA_REAL;
        if (i < 1 || i > ptr->numberOfPoints) {
            Rcpp::stop("Point index out of range");
        }
        return ptr->y[i];
    }

    NumericVector get_all_x() {
        if (!is_valid()) return NumericVector(0);
        NumericVector result(ptr->numberOfPoints);
        for (integer i = 1; i <= ptr->numberOfPoints; i++) {
            result[i-1] = ptr->x[i];
        }
        return result;
    }

    NumericVector get_all_y() {
        if (!is_valid()) return NumericVector(0);
        NumericVector result(ptr->numberOfPoints);
        for (integer i = 1; i <= ptr->numberOfPoints; i++) {
            result[i-1] = ptr->y[i];
        }
        return result;
    }

    // ========================================================================
    // Geometry Operations
    // ========================================================================

    double get_perimeter() {
        if (!is_valid()) return NA_REAL;
        try {
            return Polygon_perimeter(ptr.get());
        } catch (MelderError) {
            Melder_clearError();
            return NA_REAL;
        }
    }

    void randomize() {
        if (!is_valid()) return;
        try {
            Polygon_randomize(ptr.get());
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to randomize polygon");
        }
    }

    void optimize_salesperson(int iterations) {
        if (!is_valid()) return;
        try {
            Polygon_salesperson(ptr.get(), iterations);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to optimize polygon");
        }
    }

    // ========================================================================
    // Export
    // ========================================================================

    DataFrame as_data_frame() {
        if (!is_valid()) {
            return DataFrame::create(
                Named("x") = NumericVector(0),
                Named("y") = NumericVector(0)
            );
        }

        NumericVector x_vec(ptr->numberOfPoints);
        NumericVector y_vec(ptr->numberOfPoints);

        for (integer i = 1; i <= ptr->numberOfPoints; i++) {
            x_vec[i-1] = ptr->x[i];
            y_vec[i-1] = ptr->y[i];
        }

        return DataFrame::create(
            Named("x") = x_vec,
            Named("y") = y_vec
        );
    }

    NumericMatrix as_matrix() {
        if (!is_valid()) return NumericMatrix(0, 2);
        
        NumericMatrix mat(ptr->numberOfPoints, 2);
        for (integer i = 1; i <= ptr->numberOfPoints; i++) {
            mat(i-1, 0) = ptr->x[i];
            mat(i-1, 1) = ptr->y[i];
        }
        return mat;
    }

    // ========================================================================
    // File I/O
    // ========================================================================

    void save(std::string path) {
        if (!is_valid()) {
            Rcpp::stop("Cannot save invalid Polygon");
        }
        try {
            structMelderFile file { };
            Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
            Data_writeToTextFile(ptr.get(), &file);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to save Polygon");
        }
    }
};

// ============================================================================
// Rcpp Module Definition
// ============================================================================

RCPP_MODULE(polygon_module) {
    using namespace Rcpp;

    class_<RPolygon>("RPolygon")
        // Constructors
        .constructor()
        .constructor<XPtr<structPolygon>>()

        // Properties
        .method("is_valid", &RPolygon::is_valid)
        .method("get_number_of_points", &RPolygon::get_number_of_points)

        // Data access
        .method("get_x", &RPolygon::get_x)
        .method("get_y", &RPolygon::get_y)
        .method("get_all_x", &RPolygon::get_all_x)
        .method("get_all_y", &RPolygon::get_all_y)

        // Geometry
        .method("get_perimeter", &RPolygon::get_perimeter)
        .method("randomize", &RPolygon::randomize)
        .method("optimize_salesperson", &RPolygon::optimize_salesperson)

        // Export
        .method("as_data_frame", &RPolygon::as_data_frame)
        .method("as_matrix", &RPolygon::as_matrix)
        .method("save", &RPolygon::save)
    ;
    
    // Factory function (returns XPtr)
    function("polygon_create_xptr", &polygon_create_xptr);
}
