// lpc_module.cpp
// Rcpp Module exposing LPC (Linear Predictive Coding) functionality (pladdrr 2.0)
//
// LPC analysis for formant estimation, inverse filtering, voice source extraction

#include <Rcpp.h>
#include "module_common.h"
#include "../datatable_utils.h"
#include "praat.github.io/LPC/LPC.h"
#include "praat.github.io/LPC/Sound_and_LPC.h"
#include "praat.github.io/LPC/LPC_to_Spectrum.h"
#include "praat.github.io/fon/Sound.h"
#include "praat.github.io/fon/Spectrum.h"
#include "praat.github.io/fon/Matrix.h"

using namespace Rcpp;

class RLPC {
private:
    XPtr<structLPC> ptr;

public:
    RLPC() : ptr(R_NilValue) {}
    RLPC(XPtr<structLPC> xptr) : ptr(xptr) {}

    bool is_valid() { return ptr.get() != nullptr; }

    // Time domain properties
    double get_xmin() { VALIDATE_PTR(ptr, LPC); return ptr->xmin; }
    double get_xmax() { VALIDATE_PTR(ptr, LPC); return ptr->xmax; }
    double get_duration() { VALIDATE_PTR(ptr, LPC); return ptr->xmax - ptr->xmin; }
    int get_nx() { VALIDATE_PTR(ptr, LPC); return static_cast<int>(ptr->nx); }
    double get_dx() { VALIDATE_PTR(ptr, LPC); return ptr->dx; }
    double get_x1() { VALIDATE_PTR(ptr, LPC); return ptr->x1; }

    // LPC-specific properties
    double get_sampling_period() { VALIDATE_PTR(ptr, LPC); return ptr->samplingPeriod; }
    double get_sampling_frequency() { VALIDATE_PTR(ptr, LPC); return 1.0 / ptr->samplingPeriod; }
    int get_max_num_coefficients() { VALIDATE_PTR(ptr, LPC); return static_cast<int>(ptr->maxnCoefficients); }

    // Aliases
    int get_number_of_frames() { return get_nx(); }
    double get_time_step() { return get_dx(); }

    // Frame-level queries
    double get_gain_at_frame(int frame_number) {
        VALIDATE_PTR(ptr, LPC);
        if (frame_number < 1 || frame_number > ptr->nx) {
            Rcpp::stop("Frame number out of range");
        }
        return ptr->d_frames[frame_number].gain;
    }

    int get_num_coefficients_at_frame(int frame_number) {
        VALIDATE_PTR(ptr, LPC);
        if (frame_number < 1 || frame_number > ptr->nx) {
            Rcpp::stop("Frame number out of range");
        }
        return static_cast<int>(ptr->d_frames[frame_number].nCoefficients);
    }

    NumericVector get_coefficients_at_frame(int frame_number) {
        VALIDATE_PTR(ptr, LPC);
        if (frame_number < 1 || frame_number > ptr->nx) {
            Rcpp::stop("Frame number out of range");
        }

        LPC_Frame frame = &ptr->d_frames[frame_number];
        integer n = frame->nCoefficients;

        NumericVector result(n);
        for (integer i = 1; i <= n; i++) {
            result[i-1] = frame->a[i];
        }
        return result;
    }

    // Bulk queries
    NumericVector get_all_gains() {
        VALIDATE_PTR(ptr, LPC);
        NumericVector result(ptr->nx);
        for (integer i = 1; i <= ptr->nx; i++) {
            result[i-1] = ptr->d_frames[i].gain;
        }
        return result;
    }

    NumericMatrix get_all_coefficients() {
        VALIDATE_PTR(ptr, LPC);
        NumericMatrix result(ptr->maxnCoefficients, ptr->nx);

        for (integer iframe = 1; iframe <= ptr->nx; iframe++) {
            LPC_Frame frame = &ptr->d_frames[iframe];
            for (integer icoef = 1; icoef <= frame->nCoefficients; icoef++) {
                result(icoef-1, iframe-1) = frame->a[icoef];
            }
        }
        return result;
    }

    // Frame/time conversion
    double get_time_from_frame(int frame) {
        VALIDATE_PTR(ptr, LPC);
        return Sampled_indexToX(ptr.get(), frame);
    }

    int get_frame_from_time(double time) {
        VALIDATE_PTR(ptr, LPC);
        return static_cast<int>(Sampled_xToNearestIndex(ptr.get(), time));
    }

    // Conversion methods
    XPtr<structSpectrum> to_spectrum_ptr(double time, double df_min,
                                          double bandwidth_reduction, double de_emphasis_frequency) {
        VALIDATE_PTR(ptr, LPC);
        try {
            autoSpectrum spectrum = LPC_to_Spectrum(
                ptr.get(), time, df_min, bandwidth_reduction, de_emphasis_frequency
            );
            structSpectrum* raw = spectrum.releaseToAmbiguousOwner();
            return XPtr<structSpectrum>(raw, true);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to convert LPC to Spectrum");
        }
    }

    XPtr<structMatrix> to_matrix_ptr() {
        VALIDATE_PTR(ptr, LPC);
        try {
            autoMatrix matrix = LPC_downto_Matrix_lpc(ptr.get());
            structMatrix* raw = matrix.releaseToAmbiguousOwner();
            return XPtr<structMatrix>(raw, true);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to convert LPC to Matrix");
        }
    }

    // Inverse filtering (voice source extraction)
    XPtr<structSound> filter_inverse_ptr(XPtr<structSound> sound) {
        VALIDATE_PTR(ptr, LPC);
        if (!sound || !sound.get()) Rcpp::stop("Invalid Sound pointer");
        try {
            autoSound source = LPC_Sound_filterInverse(ptr.get(), sound.get());
            structSound* raw = source.releaseToAmbiguousOwner();
            return XPtr<structSound>(raw, true);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to perform LPC inverse filtering");
        }
    }

    XPtr<structSound> filter_inverse_at_time_ptr(XPtr<structSound> sound, int channel, double time) {
        VALIDATE_PTR(ptr, LPC);
        if (!sound || !sound.get()) Rcpp::stop("Invalid Sound pointer");
        try {
            autoSound source = LPC_Sound_filterInverseWithFilterAtTime(
                ptr.get(), sound.get(), static_cast<integer>(channel), time
            );
            structSound* raw = source.releaseToAmbiguousOwner();
            return XPtr<structSound>(raw, true);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to perform LPC inverse filtering at specified time");
        }
    }

    // Export
    DataFrame as_data_frame() {
        VALIDATE_PTR(ptr, LPC);
        std::vector<double> times, gains;
        std::vector<int> num_coefs;

        for (integer i = 1; i <= ptr->nx; i++) {
            times.push_back(Sampled_indexToX(ptr.get(), i));
            gains.push_back(ptr->d_frames[i].gain);
            num_coefs.push_back(static_cast<int>(ptr->d_frames[i].nCoefficients));
        }

        return DataFrame::create(
            Named("time") = times,
            Named("gain") = gains,
            Named("n_coefficients") = num_coefs
        );
    }

    List get_info() {
        VALIDATE_PTR(ptr, LPC);
        return List::create(
            Named("xmin") = ptr->xmin,
            Named("xmax") = ptr->xmax,
            Named("nx") = ptr->nx,
            Named("dx") = ptr->dx,
            Named("x1") = ptr->x1,
            Named("sampling_period") = ptr->samplingPeriod,
            Named("max_n_coefficients") = ptr->maxnCoefficients
        );
    }

    void save(std::string path) {
        VALIDATE_PTR(ptr, LPC);
        try {
            structMelderFile file = {};
            Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
            Data_writeToTextFile(ptr.get(), &file);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to save LPC");
        }
    }
};

// Factory functions (Module_ prefix to avoid collision with legacy wrappers)
static XPtr<structLPC> Module_Sound_to_LPC_burg(
    XPtr<structSound> sound, int prediction_order, double analysis_width,
    double time_step, double pre_emphasis_frequency) {
    if (!sound || !sound.get()) Rcpp::stop("Invalid Sound pointer");
    try {
        autoLPC lpc = Sound_to_LPC_burg(
            sound.get(), prediction_order, analysis_width, time_step, pre_emphasis_frequency
        );
        structLPC* raw = lpc.releaseToAmbiguousOwner();
        return XPtr<structLPC>(raw, true);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to compute LPC (Burg method)");
    }
}

static XPtr<structLPC> Module_Sound_to_LPC_auto(
    XPtr<structSound> sound, int prediction_order, double analysis_width,
    double time_step, double pre_emphasis_frequency) {
    if (!sound || !sound.get()) Rcpp::stop("Invalid Sound pointer");
    try {
        autoLPC lpc = Sound_to_LPC_auto(
            sound.get(), prediction_order, analysis_width, time_step, pre_emphasis_frequency
        );
        structLPC* raw = lpc.releaseToAmbiguousOwner();
        return XPtr<structLPC>(raw, true);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to compute LPC (autocorrelation method)");
    }
}

static XPtr<structLPC> Module_Sound_to_LPC_covar(
    XPtr<structSound> sound, int prediction_order, double analysis_width,
    double time_step, double pre_emphasis_frequency) {
    if (!sound || !sound.get()) Rcpp::stop("Invalid Sound pointer");
    try {
        autoLPC lpc = Sound_to_LPC_covar(
            sound.get(), prediction_order, analysis_width, time_step, pre_emphasis_frequency
        );
        structLPC* raw = lpc.releaseToAmbiguousOwner();
        return XPtr<structLPC>(raw, true);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to compute LPC (covariance method)");
    }
}

static XPtr<structLPC> Module_Sound_to_LPC_marple(
    XPtr<structSound> sound, int prediction_order, double analysis_width,
    double time_step, double pre_emphasis_frequency, double tol1, double tol2) {
    if (!sound || !sound.get()) Rcpp::stop("Invalid Sound pointer");
    try {
        autoLPC lpc = Sound_to_LPC_marple(
            sound.get(), prediction_order, analysis_width, time_step,
            pre_emphasis_frequency, tol1, tol2
        );
        structLPC* raw = lpc.releaseToAmbiguousOwner();
        return XPtr<structLPC>(raw, true);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to compute LPC (Marple method)");
    }
}

RCPP_MODULE(lpc_module) {
    class_<RLPC>("RLPC")
        .constructor()
        .constructor<XPtr<structLPC>>()
        .method("is_valid", &RLPC::is_valid)
        // Time domain
        .method("get_xmin", &RLPC::get_xmin)
        .method("get_xmax", &RLPC::get_xmax)
        .method("get_duration", &RLPC::get_duration)
        .method("get_nx", &RLPC::get_nx)
        .method("get_dx", &RLPC::get_dx)
        .method("get_x1", &RLPC::get_x1)
        // LPC-specific
        .method("get_sampling_period", &RLPC::get_sampling_period)
        .method("get_sampling_frequency", &RLPC::get_sampling_frequency)
        .method("get_max_num_coefficients", &RLPC::get_max_num_coefficients)
        .method("get_number_of_frames", &RLPC::get_number_of_frames)
        .method("get_time_step", &RLPC::get_time_step)
        // Frame queries
        .method("get_gain_at_frame", &RLPC::get_gain_at_frame)
        .method("get_num_coefficients_at_frame", &RLPC::get_num_coefficients_at_frame)
        .method("get_coefficients_at_frame", &RLPC::get_coefficients_at_frame)
        .method("get_all_gains", &RLPC::get_all_gains)
        .method("get_all_coefficients", &RLPC::get_all_coefficients)
        // Frame/time conversion
        .method("get_time_from_frame", &RLPC::get_time_from_frame)
        .method("get_frame_from_time", &RLPC::get_frame_from_time)
        // Conversion
        .method("to_spectrum_ptr", &RLPC::to_spectrum_ptr)
        .method("to_matrix_ptr", &RLPC::to_matrix_ptr)
        // Inverse filtering
        .method("filter_inverse_ptr", &RLPC::filter_inverse_ptr)
        .method("filter_inverse_at_time_ptr", &RLPC::filter_inverse_at_time_ptr)
        // Export
        .method("as_data_frame", &RLPC::as_data_frame)
        .method("get_info", &RLPC::get_info)
        .method("save", &RLPC::save)
    ;

    // Factory functions
    function("Sound_to_LPC_burg", &Module_Sound_to_LPC_burg);
    function("Sound_to_LPC_auto", &Module_Sound_to_LPC_auto);
    function("Sound_to_LPC_covar", &Module_Sound_to_LPC_covar);
    function("Sound_to_LPC_marple", &Module_Sound_to_LPC_marple);
}
