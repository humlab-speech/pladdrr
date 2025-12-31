// ltas_module.cpp
// Rcpp Module exposing Ltas (Long-Term Average Spectrum) functionality (pladdrr 2.0)

#include <Rcpp.h>
#include "module_common.h"
#include "praat.github.io/fon/Ltas.h"
#include "praat.github.io/fon/Matrix.h"

using namespace Rcpp;

class RLtas {
private:
    XPtr<structLtas> ptr;

public:
    RLtas() : ptr(R_NilValue) {}
    RLtas(XPtr<structLtas> xptr) : ptr(xptr) {}

    bool is_valid() { return ptr.get() != nullptr; }

    // Frequency domain properties
    double get_fmin() { VALIDATE_PTR(ptr, Ltas); return ptr->xmin; }
    double get_fmax() { VALIDATE_PTR(ptr, Ltas); return ptr->xmax; }
    double get_frequency_range() { VALIDATE_PTR(ptr, Ltas); return ptr->xmax - ptr->xmin; }
    int get_n_bins() { VALIDATE_PTR(ptr, Ltas); return static_cast<int>(ptr->nx); }
    double get_df() { VALIDATE_PTR(ptr, Ltas); return ptr->dx; }
    double get_f1() { VALIDATE_PTR(ptr, Ltas); return ptr->x1; }

    // Aliases
    int get_number_of_bins() { return get_n_bins(); }
    double get_bandwidth() { return get_df(); }

    // Frequency/bin conversion
    double get_frequency_from_bin(int bin) {
        VALIDATE_PTR(ptr, Ltas);
        return Matrix_columnToX(ptr.get(), bin);
    }

    int get_bin_from_frequency(double freq) {
        VALIDATE_PTR(ptr, Ltas);
        return static_cast<int>(Matrix_xToNearestColumn(ptr.get(), freq));
    }

    // Query methods
    double get_value_at_frequency(double freq, int interpolation) {
        VALIDATE_PTR(ptr, Ltas);
        return Vector_getValueAtX(ptr.get(), freq, 1, (kVector_valueInterpolation)interpolation);
    }

    double get_value_at_bin(int bin) {
        VALIDATE_PTR(ptr, Ltas);
        if (bin < 1 || bin > ptr->nx) Rcpp::stop("Bin out of range");
        return ptr->z[1][bin];
    }

    double get_minimum(double fmin, double fmax, int interpolation) {
        VALIDATE_PTR(ptr, Ltas);
        return Vector_getMinimum(ptr.get(), fmin, fmax, (kVector_peakInterpolation)interpolation);
    }

    double get_maximum(double fmin, double fmax, int interpolation) {
        VALIDATE_PTR(ptr, Ltas);
        return Vector_getMaximum(ptr.get(), fmin, fmax, (kVector_peakInterpolation)interpolation);
    }

    double get_frequency_of_minimum(double fmin, double fmax, int interpolation) {
        VALIDATE_PTR(ptr, Ltas);
        return Vector_getXOfMinimum(ptr.get(), fmin, fmax, (kVector_peakInterpolation)interpolation);
    }

    double get_frequency_of_maximum(double fmin, double fmax, int interpolation) {
        VALIDATE_PTR(ptr, Ltas);
        return Vector_getXOfMaximum(ptr.get(), fmin, fmax, (kVector_peakInterpolation)interpolation);
    }

    double get_mean(double fmin, double fmax, int averaging_units) {
        VALIDATE_PTR(ptr, Ltas);
        return Sampled_getMean(ptr.get(), fmin, fmax, 0, averaging_units, true);
    }

    double get_slope(double f1min, double f1max, double f2min, double f2max, int averaging_units) {
        VALIDATE_PTR(ptr, Ltas);
        return Ltas_getSlope(ptr.get(), f1min, f1max, f2min, f2max, averaging_units);
    }

    double get_local_peak_height(double env_min, double env_max, double peak_min, double peak_max, int averaging_units) {
        VALIDATE_PTR(ptr, Ltas);
        return Ltas_getLocalPeakHeight(ptr.get(), env_min, env_max, peak_min, peak_max, averaging_units);
    }

    double get_standard_deviation(double fmin, double fmax, int averaging_units) {
        VALIDATE_PTR(ptr, Ltas);
        return Sampled_getStandardDeviation(ptr.get(), fmin, fmax, 0, averaging_units, true);
    }

    // Transform
    XPtr<structLtas> compute_trend_line_ptr(double fmin, double fmax) {
        VALIDATE_PTR(ptr, Ltas);
        try {
            autoLtas result = Ltas_computeTrendLine(ptr.get(), fmin, fmax);
            Ltas raw = result.releaseToAmbiguousOwner();
            return XPtr<structLtas>(raw, true);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to compute trend line");
        }
    }

    XPtr<structLtas> subtract_trend_line_ptr(double fmin, double fmax) {
        VALIDATE_PTR(ptr, Ltas);
        try {
            autoLtas result = Ltas_subtractTrendLine(ptr.get(), fmin, fmax);
            Ltas raw = result.releaseToAmbiguousOwner();
            return XPtr<structLtas>(raw, true);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to subtract trend line");
        }
    }

    XPtr<structMatrix> to_matrix_ptr() {
        VALIDATE_PTR(ptr, Ltas);
        try {
            autoMatrix result = Ltas_to_Matrix(ptr.get());
            structMatrix* raw = result.releaseToAmbiguousOwner();
            return XPtr<structMatrix>(raw, true);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to convert to Matrix");
        }
    }

    // Export
    DataFrame as_data_frame() {
        VALIDATE_PTR(ptr, Ltas);
        std::vector<double> freqs, values;
        for (integer i = 1; i <= ptr->nx; i++) {
            freqs.push_back(Matrix_columnToX(ptr.get(), i));
            values.push_back(ptr->z[1][i]);
        }
        return DataFrame::create(
            Named("frequency") = freqs,
            Named("power_density") = values
        );
    }

    NumericMatrix as_matrix() {
        VALIDATE_PTR(ptr, Ltas);
        NumericMatrix mat(ptr->nx, 2);
        for (integer i = 1; i <= ptr->nx; i++) {
            mat(i-1, 0) = Matrix_columnToX(ptr.get(), i);
            mat(i-1, 1) = ptr->z[1][i];
        }
        return mat;
    }

    void save(std::string path) {
        VALIDATE_PTR(ptr, Ltas);
        try {
            structMelderFile file = {};
            Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
            Data_writeToTextFile(ptr.get(), &file);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to save Ltas");
        }
    }
};

RCPP_MODULE(ltas_module) {
    class_<RLtas>("RLtas")
        .constructor()
        .constructor<XPtr<structLtas>>()
        .method("is_valid", &RLtas::is_valid)
        .method("get_fmin", &RLtas::get_fmin)
        .method("get_fmax", &RLtas::get_fmax)
        .method("get_frequency_range", &RLtas::get_frequency_range)
        .method("get_n_bins", &RLtas::get_n_bins)
        .method("get_df", &RLtas::get_df)
        .method("get_f1", &RLtas::get_f1)
        .method("get_number_of_bins", &RLtas::get_number_of_bins)
        .method("get_bandwidth", &RLtas::get_bandwidth)
        .method("get_frequency_from_bin", &RLtas::get_frequency_from_bin)
        .method("get_bin_from_frequency", &RLtas::get_bin_from_frequency)
        .method("get_value_at_frequency", &RLtas::get_value_at_frequency)
        .method("get_value_at_bin", &RLtas::get_value_at_bin)
        .method("get_minimum", &RLtas::get_minimum)
        .method("get_maximum", &RLtas::get_maximum)
        .method("get_frequency_of_minimum", &RLtas::get_frequency_of_minimum)
        .method("get_frequency_of_maximum", &RLtas::get_frequency_of_maximum)
        .method("get_mean", &RLtas::get_mean)
        .method("get_slope", &RLtas::get_slope)
        .method("get_local_peak_height", &RLtas::get_local_peak_height)
        .method("get_standard_deviation", &RLtas::get_standard_deviation)
        .method("compute_trend_line_ptr", &RLtas::compute_trend_line_ptr)
        .method("subtract_trend_line_ptr", &RLtas::subtract_trend_line_ptr)
        .method("to_matrix_ptr", &RLtas::to_matrix_ptr)
        .method("as_data_frame", &RLtas::as_data_frame)
        .method("as_matrix", &RLtas::as_matrix)
        .method("save", &RLtas::save)
    ;
}
