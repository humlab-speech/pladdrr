// lpc_wrappers.cpp
// C++ wrappers for Praat LPC (Linear Predictive Coding) objects
// Provides R interface to LPC analysis and synthesis

#include <Rcpp.h>
#include "praat_xptr_utils.h"
#include "praat_error_handling.h"

// Praat headers for LPC
#include "praat.github.io/LPC/LPC.h"
#include "praat.github.io/LPC/Sound_and_LPC.h"
#include "praat.github.io/LPC/LPC_and_Formant.h"
#include "praat.github.io/LPC/LPC_to_Spectrum.h"
#include "praat.github.io/fon/Sound.h"
#include "praat.github.io/fon/Formant.h"
#include "praat.github.io/fon/Spectrum.h"

// ============================================================================
// LPC Creation from Sound
// ============================================================================

// [[Rcpp::export(.sound_to_lpc_burg)]]
Rcpp::XPtr<structLPC> sound_to_lpc_burg(
    Rcpp::XPtr<structSound> sound,
    int prediction_order = 16,
    double analysis_width = 0.025,
    double time_step = 0.005,
    double pre_emphasis_frequency = 50.0
) {
    try {
        autoLPC lpc = Sound_to_LPC_burg(
            sound.get(),
            prediction_order,
            analysis_width,
            time_step,
            pre_emphasis_frequency
        );
        return create_xptr_from_auto<structLPC>(lpc);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to compute LPC (Burg method)");
    }
}

// [[Rcpp::export(.sound_to_lpc_covariance)]]
Rcpp::XPtr<structLPC> sound_to_lpc_covariance(
    Rcpp::XPtr<structSound> sound,
    int prediction_order = 16,
    double analysis_width = 0.025,
    double time_step = 0.005,
    double pre_emphasis_frequency = 50.0
) {
    try {
        autoLPC lpc = Sound_to_LPC_covar(
            sound.get(),
            prediction_order,
            analysis_width,
            time_step,
            pre_emphasis_frequency
        );
        return create_xptr_from_auto<structLPC>(lpc);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to compute LPC (covariance method)");
    }
}

// [[Rcpp::export(.sound_to_lpc_auto)]]
Rcpp::XPtr<structLPC> sound_to_lpc_auto(
    Rcpp::XPtr<structSound> sound,
    int prediction_order = 16,
    double analysis_width = 0.025,
    double time_step = 0.005,
    double pre_emphasis_frequency = 50.0
) {
    try {
        autoLPC lpc = Sound_to_LPC_auto(
            sound.get(),
            prediction_order,
            analysis_width,
            time_step,
            pre_emphasis_frequency
        );
        return create_xptr_from_auto<structLPC>(lpc);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to compute LPC (autocorrelation method)");
    }
}

// [[Rcpp::export(.sound_to_lpc_marple)]]
Rcpp::XPtr<structLPC> sound_to_lpc_marple(
    Rcpp::XPtr<structSound> sound,
    int prediction_order = 16,
    double analysis_width = 0.025,
    double time_step = 0.005,
    double pre_emphasis_frequency = 50.0,
    double tol1 = 1e-6,
    double tol2 = 1e-6
) {
    try {
        autoLPC lpc = Sound_to_LPC_marple(
            sound.get(),
            prediction_order,
            analysis_width,
            time_step,
            pre_emphasis_frequency,
            tol1,
            tol2
        );
        return create_xptr_from_auto<structLPC>(lpc);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to compute LPC (Marple method)");
    }
}

// ============================================================================
// LPC Query Methods
// ============================================================================

// [[Rcpp::export(.lpc_get_number_of_frames)]]
int lpc_get_number_of_frames(Rcpp::XPtr<structLPC> lpc) {
    return lpc->nx;
}

// [[Rcpp::export(.lpc_get_time_step)]]
double lpc_get_time_step(Rcpp::XPtr<structLPC> lpc) {
    return lpc->dx;
}

// [[Rcpp::export(.lpc_get_sampling_period)]]
double lpc_get_sampling_period(Rcpp::XPtr<structLPC> lpc) {
    return lpc->samplingPeriod;
}

// [[Rcpp::export(.lpc_get_max_num_coefficients)]]
int lpc_get_max_num_coefficients(Rcpp::XPtr<structLPC> lpc) {
    return lpc->maxnCoefficients;
}

// [[Rcpp::export(.lpc_get_gain_at_frame)]]
double lpc_get_gain_at_frame(Rcpp::XPtr<structLPC> lpc, int frame_number) {
    if (frame_number < 1 || frame_number > lpc->nx) {
        Rcpp::stop("Frame number out of range");
    }
    return lpc->d_frames[frame_number].gain;
}

// [[Rcpp::export(.lpc_get_coefficients_at_frame)]]
Rcpp::NumericVector lpc_get_coefficients_at_frame(Rcpp::XPtr<structLPC> lpc, int frame_number) {
    if (frame_number < 1 || frame_number > lpc->nx) {
        Rcpp::stop("Frame number out of range");
    }
    
    LPC_Frame frame = &lpc->d_frames[frame_number];
    integer n = frame->nCoefficients;
    
    Rcpp::NumericVector result(n);
    for (integer i = 1; i <= n; i++) {
        result[i-1] = frame->a[i];
    }
    
    return result;
}

// [[Rcpp::export(.lpc_get_all_gains)]]
Rcpp::NumericVector lpc_get_all_gains(Rcpp::XPtr<structLPC> lpc) {
    Rcpp::NumericVector result(lpc->nx);
    for (integer i = 1; i <= lpc->nx; i++) {
        result[i-1] = lpc->d_frames[i].gain;
    }
    return result;
}

// [[Rcpp::export(.lpc_get_all_coefficients)]]
Rcpp::NumericMatrix lpc_get_all_coefficients(Rcpp::XPtr<structLPC> lpc) {
    Rcpp::NumericMatrix result(lpc->maxnCoefficients, lpc->nx);
    
    for (integer iframe = 1; iframe <= lpc->nx; iframe++) {
        LPC_Frame frame = &lpc->d_frames[iframe];
        for (integer icoef = 1; icoef <= frame->nCoefficients; icoef++) {
            result(icoef-1, iframe-1) = frame->a[icoef];
        }
    }
    
    return result;
}

// ============================================================================
// LPC Conversion Methods
// ============================================================================

// [[Rcpp::export(.lpc_to_formant)]]
Rcpp::XPtr<structFormant> lpc_to_formant(Rcpp::XPtr<structLPC> lpc, double margin = 50.0) {
    try {
        autoFormant formant = LPC_to_Formant(lpc.get(), margin);
        return create_xptr_from_auto<structFormant>(formant);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to convert LPC to Formant");
    }
}

// [[Rcpp::export(.lpc_to_spectrum)]]
Rcpp::XPtr<structSpectrum> lpc_to_spectrum(
    Rcpp::XPtr<structLPC> lpc,
    double time,
    double df_min = 20.0,
    double bandwidth_reduction = 0.0,
    double de_emphasis_frequency = 50.0
) {
    try {
        autoSpectrum spectrum = LPC_to_Spectrum(
            lpc.get(),
            time,
            df_min,
            bandwidth_reduction,
            de_emphasis_frequency
        );
        return create_xptr_from_auto<structSpectrum>(spectrum);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to convert LPC to Spectrum");
    }
}

// [[Rcpp::export(.lpc_to_matrix)]]
Rcpp::XPtr<structMatrix> lpc_to_matrix(Rcpp::XPtr<structLPC> lpc) {
    try {
        autoMatrix matrix = LPC_downto_Matrix_lpc(lpc.get());
        return create_xptr_from_auto<structMatrix>(matrix);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to convert LPC to Matrix");
    }
}

/* End of file */
