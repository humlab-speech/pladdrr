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
// cochleagram_module.cpp
// Rcpp Module exposing Praat Cochleagram functionality (pladdrr 2.0)
//
// Cochleagram: auditory spectrogram representation in Bark scale

#include <Rcpp.h>
#include "module_common.h"
#include "praat.github.io/fon/Cochleagram.h"
#include "praat.github.io/fon/Sound_to_Cochleagram.h"
#include "praat.github.io/fon/Cochleagram_and_Excitation.h"

using namespace Rcpp;

class RCochleagram {
private:
    XPtr<structCochleagram> ptr;

public:
    RCochleagram() : ptr(R_NilValue) {}
    RCochleagram(XPtr<structCochleagram> xptr) : ptr(xptr) {}

    bool is_valid() { return ptr.get() != nullptr; }

    // Time domain properties
    double get_xmin() { VALIDATE_PTR(ptr, Cochleagram); return ptr->xmin; }
    double get_xmax() { VALIDATE_PTR(ptr, Cochleagram); return ptr->xmax; }
    double get_duration() { VALIDATE_PTR(ptr, Cochleagram); return ptr->xmax - ptr->xmin; }
    int get_nx() { VALIDATE_PTR(ptr, Cochleagram); return static_cast<int>(ptr->nx); }
    double get_dx() { VALIDATE_PTR(ptr, Cochleagram); return ptr->dx; }
    double get_x1() { VALIDATE_PTR(ptr, Cochleagram); return ptr->x1; }

    // Frequency domain properties (Bark scale)
    double get_ymin() { VALIDATE_PTR(ptr, Cochleagram); return ptr->ymin; }
    double get_ymax() { VALIDATE_PTR(ptr, Cochleagram); return ptr->ymax; }
    int get_ny() { VALIDATE_PTR(ptr, Cochleagram); return static_cast<int>(ptr->ny); }
    double get_dy() { VALIDATE_PTR(ptr, Cochleagram); return ptr->dy; }
    double get_y1() { VALIDATE_PTR(ptr, Cochleagram); return ptr->y1; }

    // Aliases
    int get_number_of_frames() { return get_nx(); }
    int get_number_of_frequency_bands() { return get_ny(); }
    double get_time_step() { return get_dx(); }
    double get_frequency_step() { return get_dy(); }

    // Query methods
    double get_value_at_time_and_frequency(double time, double freq_bark) {
        VALIDATE_PTR(ptr, Cochleagram);
        integer ifreq = Melder_iround((freq_bark - ptr->y1) / ptr->dy + 1);
        integer itime = Melder_iround((time - ptr->x1) / ptr->dx + 1);

        if (ifreq < 1 || ifreq > ptr->ny || itime < 1 || itime > ptr->nx) {
            return NA_REAL;
        }
        return ptr->z[ifreq][itime];
    }

    double get_time_from_column(int col) {
        VALIDATE_PTR(ptr, Cochleagram);
        if (col < 1 || col > ptr->nx) Rcpp::stop("Column index out of range");
        return ptr->x1 + (col - 1) * ptr->dx;
    }

    double get_frequency_from_row(int row) {
        VALIDATE_PTR(ptr, Cochleagram);
        if (row < 1 || row > ptr->ny) Rcpp::stop("Row index out of range");
        return ptr->y1 + (row - 1) * ptr->dy;
    }

    int get_column_from_time(double time) {
        VALIDATE_PTR(ptr, Cochleagram);
        return Melder_iround((time - ptr->x1) / ptr->dx + 1);
    }

    int get_row_from_frequency(double freq_bark) {
        VALIDATE_PTR(ptr, Cochleagram);
        return Melder_iround((freq_bark - ptr->y1) / ptr->dy + 1);
    }

    // Comparison
    double get_difference(XPtr<structCochleagram> other, double tmin, double tmax) {
        VALIDATE_PTR(ptr, Cochleagram);
        if (!other || !other.get()) Rcpp::stop("Invalid Cochleagram for comparison");
        try {
            return Cochleagram_difference(ptr.get(), other.get(), tmin, tmax);
        } catch (MelderError) {
            Melder_clearError();
            return NA_REAL;
        }
    }

    // Conversion to Excitation
    XPtr<structExcitation> to_excitation_ptr(double time) {
        VALIDATE_PTR(ptr, Cochleagram);
        try {
            autoExcitation result = Cochleagram_to_Excitation(ptr.get(), time);
            structExcitation* raw = result.releaseToAmbiguousOwner();
            // Use proper deleter for Praat objects (calls forget() instead of delete)
            auto deleter = [](structExcitation* thing) {
                if (thing != nullptr) forget(thing);
            };
            return XPtr<structExcitation>(raw, deleter);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to create Excitation from Cochleagram");
        }
    }

    // Export
    List as_list() {
        VALIDATE_PTR(ptr, Cochleagram);
        int nrow = ptr->ny;
        int ncol = ptr->nx;

        NumericMatrix mat(nrow, ncol);
        NumericVector times(ncol);
        NumericVector freqs(nrow);

        for (int i = 1; i <= nrow; i++) {
            for (int j = 1; j <= ncol; j++) {
                mat(i-1, j-1) = ptr->z[i][j];
            }
        }

        for (int j = 1; j <= ncol; j++) {
            times(j-1) = ptr->x1 + (j - 1) * ptr->dx;
        }

        for (int i = 1; i <= nrow; i++) {
            freqs(i-1) = ptr->y1 + (i - 1) * ptr->dy;
        }

        return List::create(
            Named("values") = mat,
            Named("times") = times,
            Named("frequencies_bark") = freqs,
            Named("tmin") = ptr->xmin,
            Named("tmax") = ptr->xmax,
            Named("fmin_bark") = ptr->ymin,
            Named("fmax_bark") = ptr->ymax
        );
    }

    NumericMatrix as_matrix() {
        VALIDATE_PTR(ptr, Cochleagram);
        NumericMatrix mat(ptr->ny, ptr->nx);
        for (integer i = 1; i <= ptr->ny; i++) {
            for (integer j = 1; j <= ptr->nx; j++) {
                mat(i-1, j-1) = ptr->z[i][j];
            }
        }
        return mat;
    }

    List get_info() {
        VALIDATE_PTR(ptr, Cochleagram);
        return List::create(
            Named("xmin") = ptr->xmin,
            Named("xmax") = ptr->xmax,
            Named("nx") = ptr->nx,
            Named("dx") = ptr->dx,
            Named("x1") = ptr->x1,
            Named("ymin") = ptr->ymin,
            Named("ymax") = ptr->ymax,
            Named("ny") = ptr->ny,
            Named("dy") = ptr->dy,
            Named("y1") = ptr->y1
        );
    }

    void save(std::string path) {
        VALIDATE_PTR(ptr, Cochleagram);
        try {
            structMelderFile file = {};
            Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
            Data_writeToTextFile(ptr.get(), &file);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to save Cochleagram");
        }
    }
};

// Factory functions (Module_ prefix to avoid collision with legacy wrappers)
static XPtr<structCochleagram> Module_Sound_to_Cochleagram(
    XPtr<structSound> sound, double dt, double df,
    double window_length, double forward_masking_time) {

    if (!sound || !sound.get()) Rcpp::stop("Invalid Sound pointer");
    try {
        autoCochleagram result = Sound_to_Cochleagram(
            sound.get(), dt, df, window_length, forward_masking_time
        );
        structCochleagram* raw = result.releaseToAmbiguousOwner();
        // Use proper deleter for Praat objects (calls forget() instead of delete)
        auto deleter = [](structCochleagram* thing) {
            if (thing != nullptr) forget(thing);
        };
        return XPtr<structCochleagram>(raw, deleter);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to create Cochleagram from Sound");
    }
}

static XPtr<structCochleagram> Module_Sound_to_Cochleagram_edb(
    XPtr<structSound> sound, double dtime, double dfreq,
    bool has_synapse, double replenishment_rate, double loss_rate,
    double return_rate, double reprocessing_rate) {

    if (!sound || !sound.get()) Rcpp::stop("Invalid Sound pointer");
    try {
        autoCochleagram result = Sound_to_Cochleagram_edb(
            sound.get(), dtime, dfreq, has_synapse ? 1 : 0,
            replenishment_rate, loss_rate, return_rate, reprocessing_rate
        );
        structCochleagram* raw = result.releaseToAmbiguousOwner();
        // Use proper deleter for Praat objects (calls forget() instead of delete)
        auto deleter = [](structCochleagram* thing) {
            if (thing != nullptr) forget(thing);
        };
        return XPtr<structCochleagram>(raw, deleter);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to create Cochleagram (EDB method) from Sound");
    }
}

static XPtr<structCochleagram> Module_Cochleagram_create(
    double tmin, double tmax, int nt, double dt, double t1,
    double df, int nf) {

    try {
        autoCochleagram result = Cochleagram_create(tmin, tmax, nt, dt, t1, df, nf);
        structCochleagram* raw = result.releaseToAmbiguousOwner();
        // Use proper deleter for Praat objects (calls forget() instead of delete)
        auto deleter = [](structCochleagram* thing) {
            if (thing != nullptr) forget(thing);
        };
        return XPtr<structCochleagram>(raw, deleter);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to create Cochleagram");
    }
}

RCPP_MODULE(cochleagram_module) {
    class_<RCochleagram>("RCochleagram")
        .constructor()
        .constructor<XPtr<structCochleagram>>()
        .method("is_valid", &RCochleagram::is_valid)
        // Time domain
        .method("get_xmin", &RCochleagram::get_xmin)
        .method("get_xmax", &RCochleagram::get_xmax)
        .method("get_duration", &RCochleagram::get_duration)
        .method("get_nx", &RCochleagram::get_nx)
        .method("get_dx", &RCochleagram::get_dx)
        .method("get_x1", &RCochleagram::get_x1)
        // Frequency domain
        .method("get_ymin", &RCochleagram::get_ymin)
        .method("get_ymax", &RCochleagram::get_ymax)
        .method("get_ny", &RCochleagram::get_ny)
        .method("get_dy", &RCochleagram::get_dy)
        .method("get_y1", &RCochleagram::get_y1)
        // Aliases
        .method("get_number_of_frames", &RCochleagram::get_number_of_frames)
        .method("get_number_of_frequency_bands", &RCochleagram::get_number_of_frequency_bands)
        .method("get_time_step", &RCochleagram::get_time_step)
        .method("get_frequency_step", &RCochleagram::get_frequency_step)
        // Query
        .method("get_value_at_time_and_frequency", &RCochleagram::get_value_at_time_and_frequency)
        .method("get_time_from_column", &RCochleagram::get_time_from_column)
        .method("get_frequency_from_row", &RCochleagram::get_frequency_from_row)
        .method("get_column_from_time", &RCochleagram::get_column_from_time)
        .method("get_row_from_frequency", &RCochleagram::get_row_from_frequency)
        // Comparison
        .method("get_difference", &RCochleagram::get_difference)
        // Conversion
        .method("to_excitation_ptr", &RCochleagram::to_excitation_ptr)
        // Export
        .method("as_list", &RCochleagram::as_list)
        .method("as_matrix", &RCochleagram::as_matrix)
        .method("get_info", &RCochleagram::get_info)
        .method("save", &RCochleagram::save)
    ;

    // Factory functions
    function("Sound_to_Cochleagram", &Module_Sound_to_Cochleagram);
    function("Sound_to_Cochleagram_edb", &Module_Sound_to_Cochleagram_edb);
    function("Cochleagram_create", &Module_Cochleagram_create);
}
