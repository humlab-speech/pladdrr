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
// longsound_module.cpp
// Rcpp Module exposing LongSound functionality (pladdrr 2.0)

#include <Rcpp.h>
#include "module_common.h"
#include "praat.github.io/fon/LongSound.h"
#include "praat.github.io/fon/Sound.h"

using namespace Rcpp;

class RLongSound {
private:
    XPtr<structLongSound> ptr;

public:
    RLongSound() : ptr(R_NilValue) {}
    RLongSound(XPtr<structLongSound> xptr) : ptr(xptr) {}

    bool is_valid() { return ptr.get() != nullptr; }

    // Query methods - duration and timing
    double get_duration() {
        VALIDATE_PTR(ptr, LongSound);
        return ptr->xmax - ptr->xmin;
    }

    double get_start_time() {
        VALIDATE_PTR(ptr, LongSound);
        return ptr->xmin;
    }

    double get_end_time() {
        VALIDATE_PTR(ptr, LongSound);
        return ptr->xmax;
    }

    // Query methods - audio properties
    double get_sample_rate() {
        VALIDATE_PTR(ptr, LongSound);
        return ptr->sampleRate;
    }

    int get_number_of_channels() {
        VALIDATE_PTR(ptr, LongSound);
        return ptr->numberOfChannels;
    }

    double get_number_of_samples() {
        VALIDATE_PTR(ptr, LongSound);
        return ptr->nx;
    }

    std::string get_file_path() {
        VALIDATE_PTR(ptr, LongSound);
        if (!ptr->file.path || !ptr->file.path[0]) {
            return "";
        }
        return Melder_peek32to8(ptr->file.path);
    }

    // Streaming methods - extract_part
    XPtr<structSound> extract_part_ptr(double tmin, double tmax, bool preserve_times) {
        VALIDATE_PTR(ptr, LongSound);
        try {
            autoSound result = LongSound_extractPart(ptr.get(), tmin, tmax, preserve_times);
            structSound* raw = result.releaseToAmbiguousOwner();
            // Use proper deleter for Praat objects (calls forget() instead of delete)
            auto deleter = [](structSound* thing) {
                if (thing != nullptr) forget(thing);
            };
            return XPtr<structSound>(raw, deleter);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to extract part from LongSound");
        }
    }

    // Streaming methods - have_window
    bool have_window(double tmin, double tmax) {
        VALIDATE_PTR(ptr, LongSound);
        return LongSound_haveWindow(ptr.get(), tmin, tmax);
    }

    // Streaming methods - get_window_extrema
    NumericVector get_window_extrema(double tmin, double tmax, int channel) {
        VALIDATE_PTR(ptr, LongSound);
        double minimum = 0.0, maximum = 0.0;
        LongSound_getWindowExtrema(ptr.get(), tmin, tmax, channel, &minimum, &maximum);
        NumericVector result = NumericVector::create(
            Named("minimum") = minimum,
            Named("maximum") = maximum
        );
        return result;
    }
};

RCPP_MODULE(longsound_module) {
    class_<RLongSound>("RLongSound")
        .constructor()
        .constructor<XPtr<structLongSound>>()
        .method("is_valid", &RLongSound::is_valid)
        .method("get_duration", &RLongSound::get_duration)
        .method("get_start_time", &RLongSound::get_start_time)
        .method("get_end_time", &RLongSound::get_end_time)
        .method("get_sample_rate", &RLongSound::get_sample_rate)
        .method("get_number_of_channels", &RLongSound::get_number_of_channels)
        .method("get_number_of_samples", &RLongSound::get_number_of_samples)
        .method("get_file_path", &RLongSound::get_file_path)
        .method("extract_part_ptr", &RLongSound::extract_part_ptr)
        .method("have_window", &RLongSound::have_window)
        .method("get_window_extrema", &RLongSound::get_window_extrema)
    ;
}
