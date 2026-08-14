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
// spectrumtier_module.cpp
// Rcpp Module exposing SpectrumTier functionality (pladdrr 5.0)
// SpectrumTier holds the frequency/power-density pairs picked out by
// Ltas_to_SpectrumTier_peaks() (Praat: Ltas > Analyse > To SpectrumTier (peaks)).
// Read-only: this object is analysis output, not something users build by hand.

#include <Rcpp.h>
#include "../praat_xptr_utils.h"
#include "module_common.h"
#include "praat.github.io/fon/SpectrumTier.h"

using namespace Rcpp;

class RSpectrumTier {
private:
    XPtr<structSpectrumTier> ptr;

public:
    RSpectrumTier() : ptr(R_NilValue) {}
    RSpectrumTier(XPtr<structSpectrumTier> xptr) : ptr(xptr) {}

    bool is_valid() { return ptr.get() != nullptr; }

    // Frequency domain
    double get_fmin() { VALIDATE_PTR(ptr, SpectrumTier); return ptr->xmin; }
    double get_fmax() { VALIDATE_PTR(ptr, SpectrumTier); return ptr->xmax; }

    // Point access
    int get_number_of_points() {
        VALIDATE_PTR(ptr, SpectrumTier);
        return static_cast<int>(ptr->points.size);
    }

    double get_frequency(int point_number) {
        VALIDATE_PTR(ptr, SpectrumTier);
        if (point_number < 1 || point_number > ptr->points.size)
            Rcpp::stop("Point number out of range");
        return ptr->points.at[point_number]->number;
    }

    double get_value(int point_number) {
        VALIDATE_PTR(ptr, SpectrumTier);
        if (point_number < 1 || point_number > ptr->points.size)
            Rcpp::stop("Point number out of range");
        return ptr->points.at[point_number]->value;
    }

    // Export
    DataFrame as_data_frame() {
        VALIDATE_PTR(ptr, SpectrumTier);
        std::vector<double> freqs, values;
        for (integer i = 1; i <= ptr->points.size; i++) {
            freqs.push_back(ptr->points.at[i]->number);
            values.push_back(ptr->points.at[i]->value);
        }
        return DataFrame::create(
            Named("frequency") = freqs,
            Named("power_db") = values
        );
    }

    NumericMatrix as_matrix() {
        VALIDATE_PTR(ptr, SpectrumTier);
        NumericMatrix mat(ptr->points.size, 2);
        for (integer i = 1; i <= ptr->points.size; i++) {
            mat(i-1, 0) = ptr->points.at[i]->number;
            mat(i-1, 1) = ptr->points.at[i]->value;
        }
        return mat;
    }

    void save(std::string path) {
        VALIDATE_PTR(ptr, SpectrumTier);
        try {
            structMelderFile file = {};
            Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
            Data_writeToTextFile(ptr.get(), &file);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to save SpectrumTier");
        }
    }
};

RCPP_MODULE(spectrumtier_module) {
    class_<RSpectrumTier>("RSpectrumTier")
        .constructor()
        .constructor<XPtr<structSpectrumTier>>()
        .method("is_valid", &RSpectrumTier::is_valid)
        .method("get_fmin", &RSpectrumTier::get_fmin)
        .method("get_fmax", &RSpectrumTier::get_fmax)
        .method("get_number_of_points", &RSpectrumTier::get_number_of_points)
        .method("get_frequency", &RSpectrumTier::get_frequency)
        .method("get_value", &RSpectrumTier::get_value)
        .method("as_data_frame", &RSpectrumTier::as_data_frame)
        .method("as_matrix", &RSpectrumTier::as_matrix)
        .method("save", &RSpectrumTier::save)
    ;
}
