// spectrum_module.cpp
// Rcpp Module exposing Spectrum functionality (pladdrr 2.0)

#include <Rcpp.h>
#include "module_common.h"
#include "praat.github.io/fon/Spectrum.h"
#include "praat.github.io/fon/Sound.h"
#include "praat.github.io/fon/Sound_and_Spectrum.h"
#include "praat.github.io/fon/Ltas.h"

using namespace Rcpp;

class RSpectrum {
private:
    XPtr<structSpectrum> ptr;

public:
    RSpectrum() : ptr(R_NilValue) {}
    RSpectrum(XPtr<structSpectrum> xptr) : ptr(xptr) {}

    bool is_valid() { return ptr.get() != nullptr; }

    // Frequency domain properties
    double get_fmin() { VALIDATE_PTR(ptr, Spectrum); return ptr->xmin; }
    double get_fmax() { VALIDATE_PTR(ptr, Spectrum); return ptr->xmax; }
    double get_frequency_range() { VALIDATE_PTR(ptr, Spectrum); return ptr->xmax - ptr->xmin; }
    int get_n_bins() { VALIDATE_PTR(ptr, Spectrum); return static_cast<int>(ptr->nx); }
    double get_df() { VALIDATE_PTR(ptr, Spectrum); return ptr->dx; }
    double get_f1() { VALIDATE_PTR(ptr, Spectrum); return ptr->x1; }

    // Frequency/bin conversion
    double get_frequency_from_bin(int bin) {
        VALIDATE_PTR(ptr, Spectrum);
        return Matrix_columnToX(ptr.get(), bin);
    }
    int get_bin_from_frequency(double freq) {
        VALIDATE_PTR(ptr, Spectrum);
        return static_cast<int>(Matrix_xToNearestColumn(ptr.get(), freq));
    }

    // Query methods
    double get_real_value_at_bin(int bin) {
        VALIDATE_PTR(ptr, Spectrum);
        if (bin < 1 || bin > ptr->nx) Rcpp::stop("Bin out of range");
        return ptr->z[1][bin];
    }
    double get_imaginary_value_at_bin(int bin) {
        VALIDATE_PTR(ptr, Spectrum);
        if (bin < 1 || bin > ptr->nx) Rcpp::stop("Bin out of range");
        return ptr->z[2][bin];
    }

    double get_power_at_bin(int bin) {
        VALIDATE_PTR(ptr, Spectrum);
        if (bin < 1 || bin > ptr->nx) Rcpp::stop("Bin out of range");
        double re = ptr->z[1][bin];
        double im = ptr->z[2][bin];
        return re*re + im*im;
    }

    double get_band_energy(double fmin, double fmax) {
        VALIDATE_PTR(ptr, Spectrum);
        return Spectrum_getBandEnergy(ptr.get(), fmin, fmax);
    }

    double get_band_density(double fmin, double fmax) {
        VALIDATE_PTR(ptr, Spectrum);
        return Spectrum_getBandDensity(ptr.get(), fmin, fmax);
    }

    double get_band_energy_difference(double flow1, double fhigh1, double flow2, double fhigh2) {
        VALIDATE_PTR(ptr, Spectrum);
        return Spectrum_getBandEnergyDifference(ptr.get(), flow1, fhigh1, flow2, fhigh2);
    }

    double get_centre_of_gravity(double power) {
        VALIDATE_PTR(ptr, Spectrum);
        return Spectrum_getCentreOfGravity(ptr.get(), power);
    }

    double get_standard_deviation(double power) {
        VALIDATE_PTR(ptr, Spectrum);
        return Spectrum_getStandardDeviation(ptr.get(), power);
    }

    double get_skewness(double power) {
        VALIDATE_PTR(ptr, Spectrum);
        return Spectrum_getSkewness(ptr.get(), power);
    }

    double get_kurtosis(double power) {
        VALIDATE_PTR(ptr, Spectrum);
        return Spectrum_getKurtosis(ptr.get(), power);
    }

    double get_central_moment(double moment, double power) {
        VALIDATE_PTR(ptr, Spectrum);
        return Spectrum_getCentralMoment(ptr.get(), moment, power);
    }

    // Transform
    XPtr<structSound> to_sound_ptr() {
        VALIDATE_PTR(ptr, Spectrum);
        try {
            autoSound result = Spectrum_to_Sound(ptr.get());
            Sound raw = result.releaseToAmbiguousOwner();
            return XPtr<structSound>(raw, true);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to convert to Sound");
        }
    }

    XPtr<structLtas> to_ltas_ptr(double bandwidth) {
        VALIDATE_PTR(ptr, Spectrum);
        try {
            autoLtas result = Spectrum_to_Ltas(ptr.get(), bandwidth);
            Ltas raw = result.releaseToAmbiguousOwner();
            return XPtr<structLtas>(raw, true);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to convert to Ltas");
        }
    }

    // Export
    DataFrame as_data_frame() {
        VALIDATE_PTR(ptr, Spectrum);
        std::vector<double> freqs, reals, imags, powers;
        for (integer i = 1; i <= ptr->nx; i++) {
            freqs.push_back(Matrix_columnToX(ptr.get(), i));
            reals.push_back(ptr->z[1][i]);
            imags.push_back(ptr->z[2][i]);
            powers.push_back(ptr->z[1][i]*ptr->z[1][i] + ptr->z[2][i]*ptr->z[2][i]);
        }
        return DataFrame::create(
            Named("frequency") = freqs,
            Named("real") = reals,
            Named("imaginary") = imags,
            Named("power") = powers
        );
    }

    NumericMatrix as_matrix() {
        VALIDATE_PTR(ptr, Spectrum);
        NumericMatrix mat(ptr->nx, 4);
        for (integer i = 1; i <= ptr->nx; i++) {
            mat(i-1, 0) = Matrix_columnToX(ptr.get(), i);
            mat(i-1, 1) = ptr->z[1][i];
            mat(i-1, 2) = ptr->z[2][i];
            mat(i-1, 3) = ptr->z[1][i]*ptr->z[1][i] + ptr->z[2][i]*ptr->z[2][i];
        }
        return mat;
    }

    void save(std::string path) {
        VALIDATE_PTR(ptr, Spectrum);
        try {
            structMelderFile file = {};
            Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
            Data_writeToTextFile(ptr.get(), &file);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to save Spectrum");
        }
    }
};

RCPP_MODULE(spectrum_module) {
    class_<RSpectrum>("RSpectrum")
        .constructor()
        .constructor<XPtr<structSpectrum>>()
        .method("is_valid", &RSpectrum::is_valid)
        
        // Properties for fast access
        .property("fmin", &RSpectrum::get_fmin, "Minimum frequency (Hz)")
        .property("fmax", &RSpectrum::get_fmax, "Maximum frequency (Hz)")
        .property("n_bins", &RSpectrum::get_n_bins, "Number of frequency bins")
        .property("df", &RSpectrum::get_df, "Frequency step (Hz)")
        .property("f1", &RSpectrum::get_f1, "First bin frequency (Hz)")
        
        // Keep methods for backward compatibility
        .method("get_fmin", &RSpectrum::get_fmin)
        .method("get_fmax", &RSpectrum::get_fmax)
        .method("get_frequency_range", &RSpectrum::get_frequency_range)
        .method("get_n_bins", &RSpectrum::get_n_bins)
        .method("get_df", &RSpectrum::get_df)
        .method("get_f1", &RSpectrum::get_f1)
        .method("get_frequency_from_bin", &RSpectrum::get_frequency_from_bin)
        .method("get_bin_from_frequency", &RSpectrum::get_bin_from_frequency)
        .method("get_real_value_at_bin", &RSpectrum::get_real_value_at_bin)
        .method("get_imaginary_value_at_bin", &RSpectrum::get_imaginary_value_at_bin)
        .method("get_power_at_bin", &RSpectrum::get_power_at_bin)
        .method("get_band_energy", &RSpectrum::get_band_energy)
        .method("get_band_density", &RSpectrum::get_band_density)
        .method("get_band_energy_difference", &RSpectrum::get_band_energy_difference)
        .method("get_centre_of_gravity", &RSpectrum::get_centre_of_gravity)
        .method("get_standard_deviation", &RSpectrum::get_standard_deviation)
        .method("get_skewness", &RSpectrum::get_skewness)
        .method("get_kurtosis", &RSpectrum::get_kurtosis)
        .method("get_central_moment", &RSpectrum::get_central_moment)
        .method("to_sound_ptr", &RSpectrum::to_sound_ptr)
        .method("to_ltas_ptr", &RSpectrum::to_ltas_ptr)
        .method("as_data_frame", &RSpectrum::as_data_frame)
        .method("as_matrix", &RSpectrum::as_matrix)
        .method("save", &RSpectrum::save)
    ;
}
