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
// pca_module.cpp
// Rcpp Module for PCA (Principal Component Analysis) - pladdrr 2.0
//
// PCA provides dimensionality reduction for vowel space analysis,
// speaker normalization, and other multivariate acoustic data.

#include <Rcpp.h>
#include "../praat_xptr_utils.h"
#include "module_common.h"
#include "../datatable_utils.h"

// Praat headers
#include "praat.github.io/dwtools/PCA.h"
#include "praat.github.io/dwtools/Configuration.h"
#include "praat.github.io/dwsys/Eigen.h"
#include "praat.github.io/stat/TableOfReal.h"
#include "praat.github.io/fon/Matrix.h"

using namespace Rcpp;

// ============================================================================
// RPCA Class
// ============================================================================

class RPCA {
private:
    XPtr<structPCA> ptr;

public:
    RPCA() : ptr(R_NilValue) {}
    RPCA(XPtr<structPCA> xptr) : ptr(xptr) {}

    bool is_valid() { return ptr.get() != nullptr; }

    // Basic properties
    int get_number_of_components() {
        VALIDATE_PTR(ptr, PCA);
        return static_cast<int>(Eigen_getNumberOfEigenvectors(ptr.get()));
    }

    int get_dimension() {
        VALIDATE_PTR(ptr, PCA);
        return static_cast<int>(Eigen_getDimensionOfComponents(ptr.get()));
    }

    int get_number_of_observations() {
        VALIDATE_PTR(ptr, PCA);
        return static_cast<int>(PCA_getNumberOfObservations(ptr.get()));
    }

    // Eigenvalues
    NumericVector get_eigenvalues() {
        VALIDATE_PTR(ptr, PCA);
        integer n = Eigen_getNumberOfEigenvectors(ptr.get());
        NumericVector result(n);
        for (integer i = 1; i <= n; i++) {
            result[i-1] = ptr->eigenvalues[i];
        }
        return result;
    }

    double get_eigenvalue(int component) {
        VALIDATE_PTR(ptr, PCA);
        if (component < 1 || component > Eigen_getNumberOfEigenvectors(ptr.get())) {
            Rcpp::stop("Component out of range");
        }
        return ptr->eigenvalues[component];
    }

    // Fraction of variance explained
    double get_fraction_variance(int from, int to) {
        VALIDATE_PTR(ptr, PCA);
        if (to == 0) to = static_cast<int>(Eigen_getNumberOfEigenvectors(ptr.get()));
        return Eigen_getCumulativeContributionOfComponents(ptr.get(), from, to);
    }

    int get_dimension_of_fraction(double fraction) {
        VALIDATE_PTR(ptr, PCA);
        return static_cast<int>(Eigen_getDimensionOfFraction(ptr.get(), fraction));
    }

    // Eigenvectors
    NumericVector get_eigenvector(int component) {
        VALIDATE_PTR(ptr, PCA);
        integer n = Eigen_getNumberOfEigenvectors(ptr.get());
        if (component < 1 || component > n) {
            Rcpp::stop("Component out of range");
        }
        integer dim = ptr->dimension;
        NumericVector result(dim);
        for (integer i = 1; i <= dim; i++) {
            result[i-1] = Eigen_getEigenvectorElement(ptr.get(), component, i);
        }
        return result;
    }

    NumericMatrix get_eigenvectors() {
        VALIDATE_PTR(ptr, PCA);
        integer n = Eigen_getNumberOfEigenvectors(ptr.get());
        integer dim = ptr->dimension;
        NumericMatrix result(dim, n);
        for (integer j = 1; j <= n; j++) {
            for (integer i = 1; i <= dim; i++) {
                result(i-1, j-1) = Eigen_getEigenvectorElement(ptr.get(), j, i);
            }
        }
        return result;
    }

    // Centroid
    NumericVector get_centroid() {
        VALIDATE_PTR(ptr, PCA);
        integer dim = ptr->dimension;
        NumericVector result(dim);
        for (integer i = 1; i <= dim; i++) {
            result[i-1] = ptr->centroid[i];
        }
        return result;
    }

    // Labels
    CharacterVector get_labels() {
        VALIDATE_PTR(ptr, PCA);
        integer dim = ptr->dimension;
        CharacterVector result(dim);
        for (integer i = 1; i <= dim; i++) {
            if (ptr->labels && ptr->labels[i]) {
                result[i-1] = Melder_peek32to8(ptr->labels[i].get());
            } else {
                result[i-1] = NA_STRING;
            }
        }
        return result;
    }

    // Project data
    NumericMatrix project(NumericMatrix data, int num_dimensions) {
        VALIDATE_PTR(ptr, PCA);
        integer n_rows = data.nrow();
        integer n_cols = data.ncol();

        if (n_cols != ptr->dimension) {
            Rcpp::stop("Data dimension mismatch: expected %d columns, got %d",
                       ptr->dimension, n_cols);
        }

        integer n_out = (num_dimensions == 0) ?
                        Eigen_getNumberOfEigenvectors(ptr.get()) : num_dimensions;

        NumericMatrix result(n_rows, n_out);

        for (integer row = 0; row < n_rows; row++) {
            // Center the data
            NumericVector centered(n_cols);
            for (integer col = 0; col < n_cols; col++) {
                centered[col] = data(row, col) - ptr->centroid[col + 1];
            }

            // Project onto each PC
            for (integer pc = 1; pc <= n_out; pc++) {
                double sum = 0.0;
                for (integer col = 0; col < n_cols; col++) {
                    sum += centered[col] * Eigen_getEigenvectorElement(ptr.get(), pc, col + 1);
                }
                result(row, pc - 1) = sum;
            }
        }

        return result;
    }

    // Export to data.frame
    DataFrame as_data_frame() {
        VALIDATE_PTR(ptr, PCA);
        integer n = Eigen_getNumberOfEigenvectors(ptr.get());

        IntegerVector components(n);
        NumericVector eigenvalues(n);
        NumericVector variance_fraction(n);
        NumericVector cumulative_variance(n);

        double total = Eigen_getSumOfEigenvalues(ptr.get(), 1, n);
        double cumsum = 0.0;

        for (integer i = 1; i <= n; i++) {
            components[i-1] = static_cast<int>(i);
            eigenvalues[i-1] = ptr->eigenvalues[i];
            variance_fraction[i-1] = ptr->eigenvalues[i] / total;
            cumsum += variance_fraction[i-1];
            cumulative_variance[i-1] = cumsum;
        }

        return DataFrame::create(
            Named("component") = components,
            Named("eigenvalue") = eigenvalues,
            Named("variance_fraction") = variance_fraction,
            Named("cumulative_variance") = cumulative_variance
        );
    }

    List get_info() {
        VALIDATE_PTR(ptr, PCA);
        return List::create(
            Named("n_components") = Eigen_getNumberOfEigenvectors(ptr.get()),
            Named("dimension") = ptr->dimension,
            Named("n_observations") = PCA_getNumberOfObservations(ptr.get()),
            Named("eigenvalues") = get_eigenvalues(),
            Named("centroid") = get_centroid()
        );
    }

    void save(std::string path) {
        VALIDATE_PTR(ptr, PCA);
        try {
            structMelderFile file = {};
            Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
            Data_writeToTextFile(ptr.get(), &file);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to save PCA");
        }
    }
};

// ============================================================================
// Factory Functions
// ============================================================================

// Matrix -> PCA (by rows)
static XPtr<structPCA> Module_Matrix_to_PCA_byRows(XPtr<structMatrix> matrix) {
    if (!matrix || !matrix.get()) Rcpp::stop("Invalid Matrix pointer");
    try {
        autoPCA pca = Matrix_to_PCA_byRows(matrix.get());
        structPCA* raw = pca.releaseToAmbiguousOwner();
        return make_praat_xptr(raw);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to compute PCA from Matrix");
    }
}

// Create PCA from R matrix data
static XPtr<structPCA> Module_PCA_from_matrix(NumericMatrix data) {
    try {
        // Create a Matrix from the R matrix
        integer n_rows = data.nrow();
        integer n_cols = data.ncol();

        autoMatrix matrix = Matrix_create(1.0, static_cast<double>(n_cols), n_cols, 1.0, 1.0,
                                         1.0, static_cast<double>(n_rows), n_rows, 1.0, 1.0);

        // Copy data (Matrix stores data as z[row][col] with 1-based indexing)
        for (integer row = 1; row <= n_rows; row++) {
            for (integer col = 1; col <= n_cols; col++) {
                matrix->z[row][col] = data(row - 1, col - 1);
            }
        }

        // Compute PCA
        autoPCA pca = Matrix_to_PCA_byRows(matrix.get());
        structPCA* raw = pca.releaseToAmbiguousOwner();
        return make_praat_xptr(raw);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to compute PCA from data matrix");
    }
}

// ============================================================================
// Module Registration
// ============================================================================

RCPP_MODULE(pca_module) {
    class_<RPCA>("RPCA")
        .constructor()
        .constructor<XPtr<structPCA>>()
        .method("is_valid", &RPCA::is_valid)
        // Properties
        .method("get_number_of_components", &RPCA::get_number_of_components)
        .method("get_dimension", &RPCA::get_dimension)
        .method("get_number_of_observations", &RPCA::get_number_of_observations)
        // Eigenvalues
        .method("get_eigenvalues", &RPCA::get_eigenvalues)
        .method("get_eigenvalue", &RPCA::get_eigenvalue)
        .method("get_fraction_variance", &RPCA::get_fraction_variance)
        .method("get_dimension_of_fraction", &RPCA::get_dimension_of_fraction)
        // Eigenvectors
        .method("get_eigenvector", &RPCA::get_eigenvector)
        .method("get_eigenvectors", &RPCA::get_eigenvectors)
        // Other
        .method("get_centroid", &RPCA::get_centroid)
        .method("get_labels", &RPCA::get_labels)
        // Project
        .method("project", &RPCA::project)
        // Export
        .method("as_data_frame", &RPCA::as_data_frame)
        .method("get_info", &RPCA::get_info)
        .method("save", &RPCA::save)
    ;

    // Factory functions
    function("Matrix_to_PCA", &Module_Matrix_to_PCA_byRows);
    function("PCA_from_matrix", &Module_PCA_from_matrix);
}
