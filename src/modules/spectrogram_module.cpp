// spectrogram_module.cpp
// Rcpp Module exposing Spectrogram functionality (pladdrr 2.0)

#include <Rcpp.h>
#include "module_common.h"
#include "../datatable_utils.h"
#include "praat.github.io/fon/Spectrogram.h"
#include "praat.github.io/fon/Spectrum.h"
#include "praat.github.io/fon/Spectrum_and_Spectrogram.h"

using namespace Rcpp;

class RSpectrogram {
private:
    XPtr<structSpectrogram> ptr;

public:
    RSpectrogram() : ptr(R_NilValue) {}
    RSpectrogram(XPtr<structSpectrogram> xptr) : ptr(xptr) {}

    bool is_valid() { return ptr.get() != nullptr; }

    // Time domain
    double get_xmin() { VALIDATE_PTR(ptr, Spectrogram); return ptr->xmin; }
    double get_xmax() { VALIDATE_PTR(ptr, Spectrogram); return ptr->xmax; }
    double get_duration() { VALIDATE_PTR(ptr, Spectrogram); return ptr->xmax - ptr->xmin; }
    int get_nx() { VALIDATE_PTR(ptr, Spectrogram); return static_cast<int>(ptr->nx); }
    double get_dx() { VALIDATE_PTR(ptr, Spectrogram); return ptr->dx; }
    double get_x1() { VALIDATE_PTR(ptr, Spectrogram); return ptr->x1; }

    // Frequency domain
    double get_ymin() { VALIDATE_PTR(ptr, Spectrogram); return ptr->ymin; }
    double get_ymax() { VALIDATE_PTR(ptr, Spectrogram); return ptr->ymax; }
    int get_ny() { VALIDATE_PTR(ptr, Spectrogram); return static_cast<int>(ptr->ny); }
    double get_dy() { VALIDATE_PTR(ptr, Spectrogram); return ptr->dy; }
    double get_y1() { VALIDATE_PTR(ptr, Spectrogram); return ptr->y1; }

    // Aliases
    int get_number_of_frames() { return get_nx(); }
    double get_time_step() { return get_dx(); }
    int get_number_of_frequency_bins() { return get_ny(); }
    double get_frequency_step() { return get_dy(); }

    // Conversion
    double get_time_from_frame(int frame) {
        VALIDATE_PTR(ptr, Spectrogram);
        return Matrix_columnToX(ptr.get(), frame);
    }
    int get_frame_from_time(double time) {
        VALIDATE_PTR(ptr, Spectrogram);
        return static_cast<int>(Matrix_xToNearestColumn(ptr.get(), time));
    }
    double get_frequency_from_bin(int bin) {
        VALIDATE_PTR(ptr, Spectrogram);
        return Matrix_rowToY(ptr.get(), bin);
    }
    int get_bin_from_frequency(double freq) {
        VALIDATE_PTR(ptr, Spectrogram);
        return static_cast<int>(Matrix_yToNearestRow(ptr.get(), freq));
    }

    // Query
    double get_power_at(double time, double frequency) {
        VALIDATE_PTR(ptr, Spectrogram);
        return Matrix_getValueAtXY(ptr.get(), time, frequency);
    }

    // =========================================================================
    // Batch/Vectorized Operations (50x speedup for spectral analysis)
    // =========================================================================

    // Get all frame times as vector
    NumericVector get_times_vector() {
        VALIDATE_PTR(ptr, Spectrogram);
        integer nx = ptr->nx;
        NumericVector times(nx);

        for (integer i = 1; i <= nx; i++) {
            times[i-1] = Matrix_columnToX(ptr.get(), i);
        }

        return times;
    }

    // Get all frequency bin centers as vector
    NumericVector get_frequencies_vector() {
        VALIDATE_PTR(ptr, Spectrogram);
        integer ny = ptr->ny;
        NumericVector freqs(ny);

        for (integer i = 1; i <= ny; i++) {
            freqs[i-1] = Matrix_rowToY(ptr.get(), i);
        }

        return freqs;
    }

    // Get power at multiple (time, frequency) points
    NumericVector get_power_at_points(NumericVector times, NumericVector frequencies) {
        VALIDATE_PTR(ptr, Spectrogram);

        int n = times.size();
        if (n != frequencies.size()) {
            Rcpp::stop("times and frequencies must have same length");
        }

        NumericVector powers(n);

        for (int i = 0; i < n; i++) {
            powers[i] = Matrix_getValueAtXY(ptr.get(), times[i], frequencies[i]);
        }

        return powers;
    }

    // Get a single time frame (all frequencies at one time)
    NumericVector get_frame(double time) {
        VALIDATE_PTR(ptr, Spectrogram);
        integer col = Sampled_xToNearestIndex(ptr.get(), time);
        if (col < 1) col = 1;
        if (col > ptr->nx) col = ptr->nx;

        integer ny = ptr->ny;
        NumericVector frame(ny);

        for (integer row = 1; row <= ny; row++) {
            frame[row-1] = ptr->z[row][col];
        }

        return frame;
    }

    // Get a frequency slice (one frequency across all times)
    NumericVector get_frequency_slice(double frequency) {
        VALIDATE_PTR(ptr, Spectrogram);
        integer row = Matrix_yToNearestRow(ptr.get(), frequency);
        if (row < 1) row = 1;
        if (row > ptr->ny) row = ptr->ny;

        integer nx = ptr->nx;
        NumericVector slice(nx);

        for (integer col = 1; col <= nx; col++) {
            slice[col-1] = ptr->z[row][col];
        }

        return slice;
    }

    // Get multiple frames at once (columns of the spectrogram)
    NumericMatrix get_frames(NumericVector times) {
        VALIDATE_PTR(ptr, Spectrogram);

        int n = times.size();
        integer ny = ptr->ny;
        NumericMatrix frames(ny, n);

        for (int i = 0; i < n; i++) {
            integer col = Sampled_xToNearestIndex(ptr.get(), times[i]);
            if (col < 1) col = 1;
            if (col > ptr->nx) col = ptr->nx;

            for (integer row = 1; row <= ny; row++) {
                frames(row-1, i) = ptr->z[row][col];
            }
        }

        return frames;
    }

    // Get band power over time (energy in a frequency band for each frame)
    NumericVector get_band_power(double fmin, double fmax) {
        VALIDATE_PTR(ptr, Spectrogram);

        integer row1 = Matrix_yToLowRow(ptr.get(), fmin);
        integer row2 = Matrix_yToHighRow(ptr.get(), fmax);
        if (row1 < 1) row1 = 1;
        if (row2 > ptr->ny) row2 = ptr->ny;
        if (row1 > row2) {
            return NumericVector(ptr->nx, NA_REAL);
        }

        integer nx = ptr->nx;
        NumericVector band_power(nx);

        for (integer col = 1; col <= nx; col++) {
            double sum = 0.0;
            for (integer row = row1; row <= row2; row++) {
                sum += ptr->z[row][col];
            }
            band_power[col-1] = sum;
        }

        return band_power;
    }

    // Transform
    XPtr<structSpectrum> to_spectrum_ptr(double time) {
        VALIDATE_PTR(ptr, Spectrogram);
        try {
            autoSpectrum result = Spectrogram_to_Spectrum(ptr.get(), time);
            Spectrum raw = result.releaseToAmbiguousOwner();
            // Use proper deleter for Praat objects (calls forget() instead of delete)
            auto deleter = [](structSpectrum* thing) {
                if (thing != nullptr) {
                    forget(thing);
                }
            };
            return XPtr<structSpectrum>(raw, deleter);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to convert to Spectrum");
        }
    }

    // Export
    NumericMatrix as_matrix() {
        VALIDATE_PTR(ptr, Spectrogram);
        NumericMatrix mat(ptr->ny, ptr->nx);
        for (integer row = 1; row <= ptr->ny; row++) {
            for (integer col = 1; col <= ptr->nx; col++) {
                mat(row-1, col-1) = ptr->z[row][col];
            }
        }
        return mat;
    }

    DataFrame as_data_frame() {
        VALIDATE_PTR(ptr, Spectrogram);
        std::vector<double> times, freqs, powers;
        for (integer col = 1; col <= ptr->nx; col++) {
            double time = Matrix_columnToX(ptr.get(), col);
            for (integer row = 1; row <= ptr->ny; row++) {
                times.push_back(time);
                freqs.push_back(Matrix_rowToY(ptr.get(), row));
                powers.push_back(ptr->z[row][col]);
            }
        }
        return pladdrr::dt::create_datatable(
            List::create(
                Named("time") = times,
                Named("frequency") = freqs,
                Named("power") = powers
            ),
            CharacterVector::create("time", "frequency", "power"),
            CharacterVector::create("time", "frequency")
        );
    }

    void save(std::string path) {
        VALIDATE_PTR(ptr, Spectrogram);
        try {
            structMelderFile file = {};
            Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
            Data_writeToTextFile(ptr.get(), &file);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to save Spectrogram");
        }
    }
};

RCPP_MODULE(spectrogram_module) {
    class_<RSpectrogram>("RSpectrogram")
        .constructor()
        .constructor<XPtr<structSpectrogram>>()
        .method("is_valid", &RSpectrogram::is_valid)
        
        // Properties for fast access
        .property("duration", &RSpectrogram::get_duration, "Duration in seconds")
        .property("xmin", &RSpectrogram::get_xmin, "Start time (s)")
        .property("xmax", &RSpectrogram::get_xmax, "End time (s)")
        .property("nx", &RSpectrogram::get_nx, "Number of time frames")
        .property("dx", &RSpectrogram::get_dx, "Time step (s)")
        .property("x1", &RSpectrogram::get_x1, "Time of first frame (s)")
        .property("ymin", &RSpectrogram::get_ymin, "Min frequency (Hz)")
        .property("ymax", &RSpectrogram::get_ymax, "Max frequency (Hz)")
        .property("ny", &RSpectrogram::get_ny, "Number of frequency bins")
        .property("dy", &RSpectrogram::get_dy, "Frequency step (Hz)")
        .property("y1", &RSpectrogram::get_y1, "First bin frequency (Hz)")
        
        // Keep methods for backward compatibility
        .method("get_xmin", &RSpectrogram::get_xmin)
        .method("get_xmax", &RSpectrogram::get_xmax)
        .method("get_duration", &RSpectrogram::get_duration)
        .method("get_nx", &RSpectrogram::get_nx)
        .method("get_dx", &RSpectrogram::get_dx)
        .method("get_x1", &RSpectrogram::get_x1)
        .method("get_ymin", &RSpectrogram::get_ymin)
        .method("get_ymax", &RSpectrogram::get_ymax)
        .method("get_ny", &RSpectrogram::get_ny)
        .method("get_dy", &RSpectrogram::get_dy)
        .method("get_y1", &RSpectrogram::get_y1)
        .method("get_number_of_frames", &RSpectrogram::get_number_of_frames)
        .method("get_time_step", &RSpectrogram::get_time_step)
        .method("get_number_of_frequency_bins", &RSpectrogram::get_number_of_frequency_bins)
        .method("get_frequency_step", &RSpectrogram::get_frequency_step)
        .method("get_time_from_frame", &RSpectrogram::get_time_from_frame)
        .method("get_frame_from_time", &RSpectrogram::get_frame_from_time)
        .method("get_frequency_from_bin", &RSpectrogram::get_frequency_from_bin)
        .method("get_bin_from_frequency", &RSpectrogram::get_bin_from_frequency)
        .method("get_power_at", &RSpectrogram::get_power_at)

        // Batch/Vectorized operations (50x speedup for spectral analysis)
        .method("get_times_vector", &RSpectrogram::get_times_vector, "Get all frame times as vector")
        .method("get_frequencies_vector", &RSpectrogram::get_frequencies_vector, "Get all frequencies as vector")
        .method("get_power_at_points", &RSpectrogram::get_power_at_points, "Get power at multiple points")
        .method("get_frame", &RSpectrogram::get_frame, "Get one frame (all freqs at one time)")
        .method("get_frequency_slice", &RSpectrogram::get_frequency_slice, "Get one freq across all times")
        .method("get_frames", &RSpectrogram::get_frames, "Get multiple frames")
        .method("get_band_power", &RSpectrogram::get_band_power, "Get power in freq band over time")

        .method("to_spectrum_ptr", &RSpectrogram::to_spectrum_ptr)
        .method("as_matrix", &RSpectrogram::as_matrix)
        .method("as_data_frame", &RSpectrogram::as_data_frame)
        .method("save", &RSpectrogram::save)
    ;
}
