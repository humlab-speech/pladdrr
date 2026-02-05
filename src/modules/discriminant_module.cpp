// discriminant_module.cpp
// Rcpp Module for Discriminant Analysis (Linear Discriminant Analysis) - pladdrr 2.0
//
// Discriminant analysis is commonly used in phonetics for:
// - Vowel classification
// - Speaker identification
// - Dialect/accent classification
// - Phoneme recognition

#include <Rcpp.h>
#include "module_common.h"

// Praat headers
#include "praat.github.io/dwtools/Discriminant.h"
#include "praat.github.io/dwtools/TableOfReal_and_Discriminant.h"
#include "praat.github.io/stat/TableOfReal.h"
#include "praat.github.io/dwsys/Eigen.h"

using namespace Rcpp;

// ============================================================================
// RDiscriminant Class
// ============================================================================

class RDiscriminant {
private:
    XPtr<structDiscriminant> ptr;

public:
    RDiscriminant() : ptr(R_NilValue) {}
    RDiscriminant(XPtr<structDiscriminant> xptr) : ptr(xptr) {}

    bool is_valid() { return ptr.get() != nullptr; }

    // Basic properties
    int get_number_of_groups() {
        VALIDATE_PTR(ptr, Discriminant);
        return static_cast<int>(Discriminant_getNumberOfGroups(ptr.get()));
    }

    int get_number_of_functions() {
        VALIDATE_PTR(ptr, Discriminant);
        return static_cast<int>(Discriminant_getNumberOfFunctions(ptr.get()));
    }

    int get_dimension() {
        VALIDATE_PTR(ptr, Discriminant);
        return static_cast<int>(ptr->eigen->dimension);
    }

    int get_number_of_observations(int group) {
        VALIDATE_PTR(ptr, Discriminant);
        if (group < 1 || group > Discriminant_getNumberOfGroups(ptr.get())) {
            Rcpp::stop("Group index out of range");
        }
        return static_cast<int>(Discriminant_getNumberOfObservations(ptr.get(), group));
    }

    int get_total_observations() {
        VALIDATE_PTR(ptr, Discriminant);
        integer total = 0;
        for (integer i = 1; i <= Discriminant_getNumberOfGroups(ptr.get()); i++) {
            total += Discriminant_getNumberOfObservations(ptr.get(), i);
        }
        return static_cast<int>(total);
    }

    // Eigenvalues
    NumericVector get_eigenvalues() {
        VALIDATE_PTR(ptr, Discriminant);
        integer n = Eigen_getNumberOfEigenvectors(ptr->eigen.get());
        NumericVector result(n);
        for (integer i = 1; i <= n; i++) {
            result[i-1] = ptr->eigen->eigenvalues[i];
        }
        return result;
    }

    double get_eigenvalue(int function) {
        VALIDATE_PTR(ptr, Discriminant);
        integer n = Eigen_getNumberOfEigenvectors(ptr->eigen.get());
        if (function < 1 || function > n) {
            Rcpp::stop("Function index out of range");
        }
        return ptr->eigen->eigenvalues[function];
    }

    // Fraction of variance explained
    double get_fraction_variance(int from, int to) {
        VALIDATE_PTR(ptr, Discriminant);
        if (to == 0) to = static_cast<int>(Eigen_getNumberOfEigenvectors(ptr->eigen.get()));
        return Eigen_getCumulativeContributionOfComponents(ptr->eigen.get(), from, to);
    }

    // Statistical significance
    double get_wilks_lambda(int from) {
        VALIDATE_PTR(ptr, Discriminant);
        return Discriminant_getWilksLambda(ptr.get(), from);
    }

    List get_partial_discrimination_probability(int num_dimensions) {
        VALIDATE_PTR(ptr, Discriminant);
        double probability, chisq, df;
        Discriminant_getPartialDiscriminationProbability(ptr.get(), num_dimensions,
            &probability, &chisq, &df);
        return List::create(
            Named("probability") = probability,
            Named("chi_squared") = chisq,
            Named("df") = df
        );
    }

    double get_ln_determinant_group(int group) {
        VALIDATE_PTR(ptr, Discriminant);
        if (group < 1 || group > Discriminant_getNumberOfGroups(ptr.get())) {
            Rcpp::stop("Group index out of range");
        }
        return Discriminant_getLnDeterminant_group(ptr.get(), group);
    }

    double get_ln_determinant_total() {
        VALIDATE_PTR(ptr, Discriminant);
        return Discriminant_getLnDeterminant_total(ptr.get());
    }

    // Get eigenvector (discriminant function coefficients)
    NumericVector get_eigenvector(int function) {
        VALIDATE_PTR(ptr, Discriminant);
        integer n = Eigen_getNumberOfEigenvectors(ptr->eigen.get());
        if (function < 1 || function > n) {
            Rcpp::stop("Function index out of range");
        }
        integer dim = ptr->eigen->dimension;
        NumericVector result(dim);
        for (integer i = 1; i <= dim; i++) {
            result[i-1] = Eigen_getEigenvectorElement(ptr->eigen.get(), function, i);
        }
        return result;
    }

    NumericMatrix get_eigenvectors() {
        VALIDATE_PTR(ptr, Discriminant);
        integer n = Eigen_getNumberOfEigenvectors(ptr->eigen.get());
        integer dim = ptr->eigen->dimension;
        NumericMatrix result(dim, n);
        for (integer j = 1; j <= n; j++) {
            for (integer i = 1; i <= dim; i++) {
                result(i-1, j-1) = Eigen_getEigenvectorElement(ptr->eigen.get(), j, i);
            }
        }
        return result;
    }

    // Group centroids
    NumericMatrix get_group_centroids() {
        VALIDATE_PTR(ptr, Discriminant);
        try {
            autoTableOfReal centroids = Discriminant_extractGroupCentroids(ptr.get());
            integer n_groups = centroids->numberOfRows;
            integer dim = centroids->numberOfColumns;
            NumericMatrix result(n_groups, dim);
            for (integer i = 1; i <= n_groups; i++) {
                for (integer j = 1; j <= dim; j++) {
                    result(i-1, j-1) = centroids->data[i][j];
                }
            }
            // Set row names from group labels
            CharacterVector rownames(n_groups);
            for (integer i = 1; i <= n_groups; i++) {
                if (centroids->rowLabels && centroids->rowLabels[i]) {
                    rownames[i-1] = Melder_peek32to8(centroids->rowLabels[i].get());
                } else {
                    rownames[i-1] = std::to_string(i);
                }
            }
            result.attr("dimnames") = List::create(rownames, R_NilValue);
            return result;
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to extract group centroids");
        }
    }

    // Group labels
    CharacterVector get_group_labels() {
        VALIDATE_PTR(ptr, Discriminant);
        try {
            autoStrings labels = Discriminant_extractGroupLabels(ptr.get());
            integer n = labels->numberOfStrings;
            CharacterVector result(n);
            for (integer i = 1; i <= n; i++) {
                result[i-1] = Melder_peek32to8(labels->strings[i].get());
            }
            return result;
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to extract group labels");
        }
    }

    // A priori probabilities
    NumericVector get_apriori_probabilities() {
        VALIDATE_PTR(ptr, Discriminant);
        integer n = Discriminant_getNumberOfGroups(ptr.get());
        NumericVector result(n);
        for (integer i = 1; i <= n; i++) {
            result[i-1] = ptr->aprioriProbabilities[i];
        }
        return result;
    }

    void set_apriori_probability(int group, double p) {
        VALIDATE_PTR(ptr, Discriminant);
        if (group < 1 || group > Discriminant_getNumberOfGroups(ptr.get())) {
            Rcpp::stop("Group index out of range");
        }
        if (p < 0 || p > 1) {
            Rcpp::stop("Probability must be between 0 and 1");
        }
        Discriminant_setAprioriProbability(ptr.get(), group, p);
    }

    // Info summary
    List get_info() {
        VALIDATE_PTR(ptr, Discriminant);
        return List::create(
            Named("n_groups") = Discriminant_getNumberOfGroups(ptr.get()),
            Named("n_functions") = Discriminant_getNumberOfFunctions(ptr.get()),
            Named("dimension") = ptr->eigen->dimension,
            Named("n_observations") = get_total_observations(),
            Named("eigenvalues") = get_eigenvalues(),
            Named("group_labels") = get_group_labels(),
            Named("apriori_probabilities") = get_apriori_probabilities()
        );
    }

    // Export to data.frame
    DataFrame as_data_frame() {
        VALIDATE_PTR(ptr, Discriminant);
        integer n = Eigen_getNumberOfEigenvectors(ptr->eigen.get());

        IntegerVector functions(n);
        NumericVector eigenvalues(n);
        NumericVector variance_fraction(n);
        NumericVector cumulative_variance(n);
        NumericVector wilks_lambda(n);

        double total = Eigen_getSumOfEigenvalues(ptr->eigen.get(), 1, n);
        double cumsum = 0.0;

        for (integer i = 1; i <= n; i++) {
            functions[i-1] = static_cast<int>(i);
            eigenvalues[i-1] = ptr->eigen->eigenvalues[i];
            variance_fraction[i-1] = ptr->eigen->eigenvalues[i] / total;
            cumsum += variance_fraction[i-1];
            cumulative_variance[i-1] = cumsum;
            wilks_lambda[i-1] = Discriminant_getWilksLambda(ptr.get(), i);
        }

        return DataFrame::create(
            Named("function") = functions,
            Named("eigenvalue") = eigenvalues,
            Named("variance_fraction") = variance_fraction,
            Named("cumulative_variance") = cumulative_variance,
            Named("wilks_lambda") = wilks_lambda
        );
    }

    void save(std::string path) {
        VALIDATE_PTR(ptr, Discriminant);
        try {
            structMelderFile file = {};
            Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
            Data_writeToTextFile(ptr.get(), &file);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to save Discriminant");
        }
    }
};

// ============================================================================
// Factory Functions
// ============================================================================

// Create Discriminant from labeled data matrix
// Rows are observations, columns are variables
// labels vector assigns each row to a group
static XPtr<structDiscriminant> Module_Discriminant_from_labeled_matrix(
    NumericMatrix data,
    CharacterVector labels
) {
    if (data.nrow() != labels.size()) {
        Rcpp::stop("Number of rows in data must match length of labels");
    }

    try {
        integer n_rows = data.nrow();
        integer n_cols = data.ncol();

        // Create TableOfReal
        autoTableOfReal table = TableOfReal_create(n_rows, n_cols);

        // Copy data and set row labels
        for (integer row = 1; row <= n_rows; row++) {
            // Set row label (group membership)
            std::string label = Rcpp::as<std::string>(labels[row - 1]);
            TableOfReal_setRowLabel(table.get(), row, Melder_peek8to32(label.c_str()));

            // Copy data
            for (integer col = 1; col <= n_cols; col++) {
                table->data[row][col] = data(row - 1, col - 1);
            }
        }

        // Create Discriminant from TableOfReal
        autoDiscriminant discriminant = TableOfReal_to_Discriminant(table.get());
        structDiscriminant* raw = discriminant.releaseToAmbiguousOwner();
        // Use proper deleter for Praat objects (calls forget() instead of delete)
        auto deleter = [](structDiscriminant* thing) {
            if (thing != nullptr) forget(thing);
        };
        return XPtr<structDiscriminant>(raw, deleter);

    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to create Discriminant from labeled matrix");
    }
}

// Create from TableOfReal pointer (if user already has one)
static XPtr<structDiscriminant> Module_TableOfReal_to_Discriminant(
    XPtr<structTableOfReal> table
) {
    if (!table || !table.get()) Rcpp::stop("Invalid TableOfReal pointer");

    try {
        autoDiscriminant discriminant = TableOfReal_to_Discriminant(table.get());
        structDiscriminant* raw = discriminant.releaseToAmbiguousOwner();
        // Use proper deleter for Praat objects (calls forget() instead of delete)
        auto deleter = [](structDiscriminant* thing) {
            if (thing != nullptr) forget(thing);
        };
        return XPtr<structDiscriminant>(raw, deleter);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to create Discriminant from TableOfReal");
    }
}

// ============================================================================
// Module Registration
// ============================================================================

RCPP_MODULE(discriminant_module) {
    class_<RDiscriminant>("RDiscriminant")
        .constructor()
        .constructor<XPtr<structDiscriminant>>()
        .method("is_valid", &RDiscriminant::is_valid)
        // Properties
        .method("get_number_of_groups", &RDiscriminant::get_number_of_groups)
        .method("get_number_of_functions", &RDiscriminant::get_number_of_functions)
        .method("get_dimension", &RDiscriminant::get_dimension)
        .method("get_number_of_observations", &RDiscriminant::get_number_of_observations)
        .method("get_total_observations", &RDiscriminant::get_total_observations)
        // Eigenvalues
        .method("get_eigenvalues", &RDiscriminant::get_eigenvalues)
        .method("get_eigenvalue", &RDiscriminant::get_eigenvalue)
        .method("get_fraction_variance", &RDiscriminant::get_fraction_variance)
        // Statistical significance
        .method("get_wilks_lambda", &RDiscriminant::get_wilks_lambda)
        .method("get_partial_discrimination_probability", &RDiscriminant::get_partial_discrimination_probability)
        .method("get_ln_determinant_group", &RDiscriminant::get_ln_determinant_group)
        .method("get_ln_determinant_total", &RDiscriminant::get_ln_determinant_total)
        // Eigenvectors
        .method("get_eigenvector", &RDiscriminant::get_eigenvector)
        .method("get_eigenvectors", &RDiscriminant::get_eigenvectors)
        // Group info
        .method("get_group_centroids", &RDiscriminant::get_group_centroids)
        .method("get_group_labels", &RDiscriminant::get_group_labels)
        .method("get_apriori_probabilities", &RDiscriminant::get_apriori_probabilities)
        .method("set_apriori_probability", &RDiscriminant::set_apriori_probability)
        // Export
        .method("as_data_frame", &RDiscriminant::as_data_frame)
        .method("get_info", &RDiscriminant::get_info)
        .method("save", &RDiscriminant::save)
    ;

    // Factory functions
    function("Discriminant_from_labeled_matrix", &Module_Discriminant_from_labeled_matrix);
    function("TableOfReal_to_Discriminant", &Module_TableOfReal_to_Discriminant);
}
