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
// vocaltract_module.cpp
// Rcpp Module exposing VocalTract functionality (pladdrr 2.0)

#include <Rcpp.h>
#include "module_common.h"
#include "praat.github.io/fon/VocalTract.h"
#include "praat.github.io/fon/VocalTract_to_Spectrum.h"
#include "praat.github.io/fon/Spectrum.h"
#include "praat.github.io/fon/Matrix.h"

using namespace Rcpp;

class RVocalTract {
private:
    XPtr<structVocalTract> ptr;

public:
    RVocalTract() : ptr(R_NilValue) {}
    RVocalTract(XPtr<structVocalTract> xptr) : ptr(xptr) {}

    bool is_valid() { return ptr.get() != nullptr; }

    // Geometry queries
    double get_length() {
        VALIDATE_PTR(ptr, VocalTract);
        return ptr->xmax - ptr->xmin;
    }

    int get_number_of_sections() {
        VALIDATE_PTR(ptr, VocalTract);
        return static_cast<int>(ptr->nx);
    }

    double get_section_length() {
        VALIDATE_PTR(ptr, VocalTract);
        return ptr->dx;
    }

    // Area access
    double get_area(int section) {
        VALIDATE_PTR(ptr, VocalTract);
        if (section < 1 || section > ptr->nx)
            Rcpp::stop("Section index out of range");
        return ptr->z[1][section];  // VocalTract is Matrix subclass
    }

    void set_area(int section, double area) {
        VALIDATE_PTR(ptr, VocalTract);
        if (section < 1 || section > ptr->nx)
            Rcpp::stop("Section index out of range");
        if (area <= 0.0)
            Rcpp::stop("Area must be positive");
        ptr->z[1][section] = area;
    }

    NumericVector get_areas() {
        VALIDATE_PTR(ptr, VocalTract);
        NumericVector areas(ptr->nx);
        for (integer i = 1; i <= ptr->nx; i++) {
            areas[i-1] = ptr->z[1][i];
        }
        return areas;
    }

    void set_areas(NumericVector areas) {
        VALIDATE_PTR(ptr, VocalTract);
        if (areas.size() != ptr->nx)
            Rcpp::stop("Length mismatch: areas vector must have %d elements", ptr->nx);
        for (integer i = 1; i <= ptr->nx; i++) {
            if (areas[i-1] <= 0.0)
                Rcpp::stop("All areas must be positive");
            ptr->z[1][i] = areas[i-1];
        }
    }

    // Transform - to_spectrum
    XPtr<structSpectrum> to_spectrum_ptr(int number_of_frequencies, 
                                         double maximum_frequency,
                                         double glottal_damping,
                                         bool radiation_damping,
                                         bool internal_damping) {
        VALIDATE_PTR(ptr, VocalTract);
        try {
            autoSpectrum result = VocalTract_to_Spectrum(
                ptr.get(),
                static_cast<integer>(number_of_frequencies),
                maximum_frequency,
                glottal_damping,
                radiation_damping,
                internal_damping
            );
            Spectrum raw = result.releaseToAmbiguousOwner();
            // Use proper deleter for Praat objects (calls forget() instead of delete)
            auto deleter = [](structSpectrum* thing) {
                if (thing != nullptr) forget(thing);
            };
            return XPtr<structSpectrum>(raw, deleter);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to convert VocalTract to Spectrum");
        }
    }

    // Transform - to_matrix
    XPtr<structMatrix> to_matrix_ptr() {
        VALIDATE_PTR(ptr, VocalTract);
        try {
            autoMatrix result = VocalTract_to_Matrix(ptr.get());
            structMatrix* raw = result.releaseToAmbiguousOwner();
            // Use proper deleter for Praat objects (calls forget() instead of delete)
            auto deleter = [](structMatrix* thing) {
                if (thing != nullptr) forget(thing);
            };
            return XPtr<structMatrix>(raw, deleter);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to convert VocalTract to Matrix");
        }
    }
};

RCPP_MODULE(vocaltract_module) {
    class_<RVocalTract>("RVocalTract")
        .constructor()
        .constructor<XPtr<structVocalTract>>()
        .method("is_valid", &RVocalTract::is_valid)
        .method("get_length", &RVocalTract::get_length)
        .method("get_number_of_sections", &RVocalTract::get_number_of_sections)
        .method("get_section_length", &RVocalTract::get_section_length)
        .method("get_area", &RVocalTract::get_area)
        .method("set_area", &RVocalTract::set_area)
        .method("get_areas", &RVocalTract::get_areas)
        .method("set_areas", &RVocalTract::set_areas)
        .method("to_spectrum_ptr", &RVocalTract::to_spectrum_ptr)
        .method("to_matrix_ptr", &RVocalTract::to_matrix_ptr)
    ;
}
