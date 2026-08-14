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
#include "../praat_xptr_utils.h"
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

    double get_dx() {
        VALIDATE_PTR(ptr, LongSound);
        return ptr->dx;
    }

    double get_x1() {
        VALIDATE_PTR(ptr, LongSound);
        return ptr->x1;
    }

    double get_time_from_sample(int sample) {
        VALIDATE_PTR(ptr, LongSound);
        return Sampled_indexToX(ptr.get(), sample);
    }

    int get_sample_from_time(double time) {
        VALIDATE_PTR(ptr, LongSound);
        return static_cast<int>(Sampled_xToNearestIndex(ptr.get(), time));
    }

    std::string get_file_path() {
        VALIDATE_PTR(ptr, LongSound);
        if (!ptr->file.path[0]) {   // path is a fixed-size array; test emptiness via first char
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
            return make_praat_xptr(raw);
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

    // Save methods
    void save_part(int audio_file_type, double tmin, double tmax,
                    std::string path, int bits_per_sample) {
        VALIDATE_PTR(ptr, LongSound);
        try {
            structMelderFile file {};
            Melder_relativePathToFile(Melder_8to32(path.c_str()).get(), &file);
            LongSound_savePartAsAudioFile(ptr.get(), audio_file_type, tmin, tmax, &file, bits_per_sample);
        } catch (MelderError) {
            std::string error_msg = Melder_peek32to8(Melder_getError());
            Melder_clearError();
            Rcpp::stop("Failed to save part: " + error_msg);
        }
    }

    void save_channel(int audio_file_type, int channel, std::string path) {
        VALIDATE_PTR(ptr, LongSound);
        try {
            structMelderFile file {};
            Melder_relativePathToFile(Melder_8to32(path.c_str()).get(), &file);
            LongSound_saveChannelAsAudioFile(ptr.get(), audio_file_type, channel, &file);
        } catch (MelderError) {
            std::string error_msg = Melder_peek32to8(Melder_getError());
            Melder_clearError();
            Rcpp::stop("Failed to save channel: " + error_msg);
        }
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
        .method("get_dx", &RLongSound::get_dx)
        .method("get_x1", &RLongSound::get_x1)
        .method("get_time_from_sample", &RLongSound::get_time_from_sample)
        .method("get_sample_from_time", &RLongSound::get_sample_from_time)
        .method("get_file_path", &RLongSound::get_file_path)
        .method("extract_part_ptr", &RLongSound::extract_part_ptr)
        .method("have_window", &RLongSound::have_window)
        .method("get_window_extrema", &RLongSound::get_window_extrema)
        .method("save_part", &RLongSound::save_part)
        .method("save_channel", &RLongSound::save_channel)
    ;
}
