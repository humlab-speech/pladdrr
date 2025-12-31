// spectrogram_module.cpp
// Rcpp Module exposing Spectrogram functionality (pladdrr 2.0)

#include <Rcpp.h>
#include "module_common.h"
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

    // Transform
    XPtr<structSpectrum> to_spectrum_ptr(double time) {
        VALIDATE_PTR(ptr, Spectrogram);
        try {
            autoSpectrum result = Spectrogram_to_Spectrum(ptr.get(), time);
            Spectrum raw = result.releaseToAmbiguousOwner();
            return XPtr<structSpectrum>(raw, true);
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
        return DataFrame::create(
            Named("time") = times,
            Named("frequency") = freqs,
            Named("power") = powers
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
        .method("to_spectrum_ptr", &RSpectrogram::to_spectrum_ptr)
        .method("as_matrix", &RSpectrogram::as_matrix)
        .method("as_data_frame", &RSpectrogram::as_data_frame)
        .method("save", &RSpectrogram::save)
    ;
}
