// complexspectrogram_module.cpp
// Rcpp Module for Praat ComplexSpectrogram object
// Part of the pladdrr package - Phase 2.4 extension

#include <Rcpp.h>
#include "module_common.h"

// Praat headers
#include "../praat.github.io/dwtools/ComplexSpectrogram.h"
#include "../praat.github.io/fon/Sound.h"
#include "../praat.github.io/fon/Spectrogram.h"
#include "../praat.github.io/fon/Spectrum.h"
#include "../praat.github.io/melder/melder.h"

using namespace Rcpp;

// Forward declaration - NUMfpp initialization
extern void NUMmachar();

// ============================================================================
// Free Functions for ComplexSpectrogram Creation
// ============================================================================

// Create ComplexSpectrogram from Sound
XPtr<structComplexSpectrogram> complexspectrogram_create_from_sound(
    XPtr<structSound> sound,
    double window_length,
    double maximum_frequency
) {
    if (sound.get() == nullptr) {
        Rcpp::stop("Invalid Sound object");
    }

    // Ensure NUMfpp is initialized
    NUMmachar();

    try {
        autoComplexSpectrogram cs = Sound_to_ComplexSpectrogram(
            sound.get(), window_length, maximum_frequency
        );
        return create_xptr_from_auto<structComplexSpectrogram>(cs);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to create ComplexSpectrogram from Sound");
    }
}

// ============================================================================
// RComplexSpectrogram Module Class
// ============================================================================

class RComplexSpectrogram {
public:
    Rcpp::XPtr<structComplexSpectrogram> ptr;

    // ========================================================================
    // Constructors
    // ========================================================================

    // Default constructor (empty/invalid object)
    RComplexSpectrogram() : ptr(R_NilValue) {}

    // Constructor from external pointer
    RComplexSpectrogram(Rcpp::XPtr<structComplexSpectrogram> p) : ptr(p) {}

    // ========================================================================
    // Validation
    // ========================================================================

    bool is_valid() {
        return ptr.get() != nullptr;
    }

    // ========================================================================
    // Properties - Time
    // ========================================================================

    double get_xmin() {
        if (!is_valid()) return NA_REAL;
        return ptr->xmin;
    }

    double get_xmax() {
        if (!is_valid()) return NA_REAL;
        return ptr->xmax;
    }

    int get_nx() {
        if (!is_valid()) return 0;
        return static_cast<int>(ptr->nx);
    }

    double get_dx() {
        if (!is_valid()) return NA_REAL;
        return ptr->dx;
    }

    double get_x1() {
        if (!is_valid()) return NA_REAL;
        return ptr->x1;
    }

    // ========================================================================
    // Properties - Frequency
    // ========================================================================

    double get_ymin() {
        if (!is_valid()) return NA_REAL;
        return ptr->ymin;
    }

    double get_ymax() {
        if (!is_valid()) return NA_REAL;
        return ptr->ymax;
    }

    int get_ny() {
        if (!is_valid()) return 0;
        return static_cast<int>(ptr->ny);
    }

    double get_dy() {
        if (!is_valid()) return NA_REAL;
        return ptr->dy;
    }

    double get_y1() {
        if (!is_valid()) return NA_REAL;
        return ptr->y1;
    }

    // ========================================================================
    // Query Methods
    // ========================================================================

    double get_amplitude(double time, double frequency) {
        VALIDATE_PTR(ptr, ComplexSpectrogram);
        
        try {
            integer itime = Matrix_xToColumn(ptr, time);
            integer ifreq = Matrix_yToRow(ptr, frequency);
            
            if (itime < 1 || itime > ptr->nx || ifreq < 1 || ifreq > ptr->ny) {
                return NA_REAL;
            }
            
            return ptr->z[ifreq][itime];
        } catch (MelderError) {
            Melder_clearError();
            return NA_REAL;
        }
    }

    double get_phase(double time, double frequency) {
        VALIDATE_PTR(ptr, ComplexSpectrogram);
        
        try {
            integer itime = Matrix_xToColumn(ptr, time);
            integer ifreq = Matrix_yToRow(ptr, frequency);
            
            if (itime < 1 || itime > ptr->nx || ifreq < 1 || ifreq > ptr->ny) {
                return NA_REAL;
            }
            
            return ptr->phase[ifreq][itime];
        } catch (MelderError) {
            Melder_clearError();
            return NA_REAL;
        }
    }

    // ========================================================================
    // Conversion Methods
    // ========================================================================

    XPtr<structSound> to_sound(double stretch_factor) {
        VALIDATE_PTR(ptr, ComplexSpectrogram);
        
        try {
            autoSound sound = ComplexSpectrogram_to_Sound(ptr.get(), stretch_factor);
            return create_xptr_from_auto<structSound>(sound);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to convert ComplexSpectrogram to Sound");
        }
    }

    XPtr<structSpectrogram> to_spectrogram() {
        VALIDATE_PTR(ptr, ComplexSpectrogram);
        
        try {
            autoSpectrogram spec = ComplexSpectrogram_to_Spectrogram(ptr.get());
            return create_xptr_from_auto<structSpectrogram>(spec);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to convert ComplexSpectrogram to Spectrogram");
        }
    }

    XPtr<structSpectrum> to_spectrum(double time) {
        VALIDATE_PTR(ptr, ComplexSpectrogram);
        
        try {
            autoSpectrum spectrum = ComplexSpectrogram_to_Spectrum(ptr.get(), time);
            return create_xptr_from_auto<structSpectrum>(spectrum);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to convert ComplexSpectrogram to Spectrum");
        }
    }

    DataFrame as_data_frame() {
        VALIDATE_PTR(ptr, ComplexSpectrogram);
        
        std::vector<double> times;
        std::vector<double> frequencies;
        std::vector<double> amplitudes;
        std::vector<double> phases;

        for (integer itime = 1; itime <= ptr->nx; itime++) {
            double time = Matrix_columnToX(ptr, itime);
            for (integer ifreq = 1; ifreq <= ptr->ny; ifreq++) {
                double freq = Matrix_rowToY(ptr, ifreq);
                times.push_back(time);
                frequencies.push_back(freq);
                amplitudes.push_back(ptr->z[ifreq][itime]);
                phases.push_back(ptr->phase[ifreq][itime]);
            }
        }

        return DataFrame::create(
            Named("time") = times,
            Named("frequency") = frequencies,
            Named("amplitude") = amplitudes,
            Named("phase") = phases
        );
    }
};

// ============================================================================
// Rcpp Module Definition
// ============================================================================

RCPP_MODULE(complexspectrogram_module) {
    using namespace Rcpp;

    class_<RComplexSpectrogram>("RComplexSpectrogram")
        // Constructors
        .constructor()
        .constructor<XPtr<structComplexSpectrogram>>()

        // Validation
        .method("is_valid", &RComplexSpectrogram::is_valid)

        // Properties - Time
        .method("get_xmin", &RComplexSpectrogram::get_xmin)
        .method("get_xmax", &RComplexSpectrogram::get_xmax)
        .method("get_nx", &RComplexSpectrogram::get_nx)
        .method("get_dx", &RComplexSpectrogram::get_dx)
        .method("get_x1", &RComplexSpectrogram::get_x1)

        // Properties - Frequency
        .method("get_ymin", &RComplexSpectrogram::get_ymin)
        .method("get_ymax", &RComplexSpectrogram::get_ymax)
        .method("get_ny", &RComplexSpectrogram::get_ny)
        .method("get_dy", &RComplexSpectrogram::get_dy)
        .method("get_y1", &RComplexSpectrogram::get_y1)

        // Query methods
        .method("get_amplitude", &RComplexSpectrogram::get_amplitude)
        .method("get_phase", &RComplexSpectrogram::get_phase)

        // Conversion
        .method("to_sound", &RComplexSpectrogram::to_sound)
        .method("to_spectrogram", &RComplexSpectrogram::to_spectrogram)
        .method("to_spectrum", &RComplexSpectrogram::to_spectrum)
        .method("as_data_frame", &RComplexSpectrogram::as_data_frame)
    ;
    
    // Factory functions (returns XPtr)
    function("complexspectrogram_create_from_sound", &complexspectrogram_create_from_sound);
}
