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
// spectrum_module.cpp
// Rcpp Module exposing Spectrum functionality (pladdrr 2.0)

#include <Rcpp.h>
#include "../praat_xptr_utils.h"
#include "module_common.h"
#include "../datatable_utils.h"
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

    // =========================================================================
    // Batch/Vectorized Operations (Phase 6: Pharyngeal - 150x speedup)
    // =========================================================================

    // Get all frequencies as vector
    NumericVector get_frequencies_vector() {
        VALIDATE_PTR(ptr, Spectrum);
        integer nx = ptr->nx;
        NumericVector freqs(nx);

        for (integer i = 1; i <= nx; i++) {
            freqs[i-1] = Matrix_columnToX(ptr.get(), i);
        }

        return freqs;
    }

    // Get all power values as vector
    NumericVector get_power_vector() {
        VALIDATE_PTR(ptr, Spectrum);
        integer nx = ptr->nx;
        NumericVector powers(nx);

        for (integer i = 1; i <= nx; i++) {
            double re = ptr->z[1][i];
            double im = ptr->z[2][i];
            powers[i-1] = re*re + im*im;
        }

        return powers;
    }

    // Get all real values as vector
    NumericVector get_real_vector() {
        VALIDATE_PTR(ptr, Spectrum);
        integer nx = ptr->nx;
        NumericVector reals(nx);

        for (integer i = 1; i <= nx; i++) {
            reals[i-1] = ptr->z[1][i];
        }

        return reals;
    }

    // Get all imaginary values as vector
    NumericVector get_imaginary_vector() {
        VALIDATE_PTR(ptr, Spectrum);
        integer nx = ptr->nx;
        NumericVector imags(nx);

        for (integer i = 1; i <= nx; i++) {
            imags[i-1] = ptr->z[2][i];
        }

        return imags;
    }

    // Get band energies for multiple frequency bands in one call
    NumericVector get_band_energies(NumericVector fmins, NumericVector fmaxs) {
        VALIDATE_PTR(ptr, Spectrum);

        int n = fmins.size();
        if (n != fmaxs.size()) {
            Rcpp::stop("fmins and fmaxs must have same length");
        }

        NumericVector energies(n);

        try {
            for (int i = 0; i < n; i++) {
                energies[i] = Spectrum_getBandEnergy(ptr.get(), fmins[i], fmaxs[i]);
            }
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to compute band energies");
        }

        return energies;
    }

    // Get band densities for multiple frequency bands in one call
    NumericVector get_band_densities(NumericVector fmins, NumericVector fmaxs) {
        VALIDATE_PTR(ptr, Spectrum);

        int n = fmins.size();
        if (n != fmaxs.size()) {
            Rcpp::stop("fmins and fmaxs must have same length");
        }

        NumericVector densities(n);

        try {
            for (int i = 0; i < n; i++) {
                densities[i] = Spectrum_getBandDensity(ptr.get(), fmins[i], fmaxs[i]);
            }
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to compute band densities");
        }

        return densities;
    }

    // Get power values at specific frequencies (interpolated)
    NumericVector get_power_at_frequencies(NumericVector frequencies) {
        VALIDATE_PTR(ptr, Spectrum);

        int n = frequencies.size();
        NumericVector powers(n);

        try {
            for (int i = 0; i < n; i++) {
                double freq = frequencies[i];
                int bin = static_cast<int>(Matrix_xToNearestColumn(ptr.get(), freq));
                if (bin >= 1 && bin <= ptr->nx) {
                    double re = ptr->z[1][bin];
                    double im = ptr->z[2][bin];
                    powers[i] = re*re + im*im;
                } else {
                    powers[i] = NA_REAL;
                }
            }
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to get power at frequencies");
        }

        return powers;
    }

    // Transform
    XPtr<structSound> to_sound_ptr() {
        VALIDATE_PTR(ptr, Spectrum);
        try {
            autoSound result = Spectrum_to_Sound(ptr.get());
            Sound raw = result.releaseToAmbiguousOwner();
            return make_praat_xptr(raw);
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
            return make_praat_xptr(raw);
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
        return pladdrr::dt::create_datatable(
            List::create(
                Named("frequency") = freqs,
                Named("real") = reals,
                Named("imaginary") = imags,
                Named("power") = powers
            ),
            CharacterVector::create("frequency", "real", "imaginary", "power"),
            CharacterVector::create("frequency")
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

        // Batch/Vectorized operations (150x speedup for Pharyngeal analysis)
        .method("get_frequencies_vector", &RSpectrum::get_frequencies_vector, "Get all frequencies as vector")
        .method("get_power_vector", &RSpectrum::get_power_vector, "Get all power values as vector")
        .method("get_real_vector", &RSpectrum::get_real_vector, "Get all real values as vector")
        .method("get_imaginary_vector", &RSpectrum::get_imaginary_vector, "Get all imaginary values as vector")
        .method("get_band_energies", &RSpectrum::get_band_energies, "Get energies for multiple bands")
        .method("get_band_densities", &RSpectrum::get_band_densities, "Get densities for multiple bands")
        .method("get_power_at_frequencies", &RSpectrum::get_power_at_frequencies, "Get power at specific frequencies")

        .method("to_sound_ptr", &RSpectrum::to_sound_ptr)
        .method("to_ltas_ptr", &RSpectrum::to_ltas_ptr)
        .method("as_data_frame", &RSpectrum::as_data_frame)
        .method("as_matrix", &RSpectrum::as_matrix)
        .method("save", &RSpectrum::save)
    ;
}
