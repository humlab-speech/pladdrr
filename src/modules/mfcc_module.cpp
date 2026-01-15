// mfcc_module.cpp
// Rcpp Module for MFCC/LFCC (Cepstral Coefficients) - pladdrr 2.0
//
// MFCC: Mel Frequency Cepstral Coefficients - for speech/speaker recognition
// LFCC: Linear Frequency Cepstral Coefficients - alternative representation

#include <Rcpp.h>
#include "module_common.h"
#include "../datatable_utils.h"

// Praat headers for cepstral coefficients
#include "praat.github.io/dwtools/CC.h"
#include "praat.github.io/dwtools/MFCC.h"
#include "praat.github.io/dwtools/LFCC.h"
#include "praat.github.io/dwtools/Sound_to_MFCC.h"
#include "praat.github.io/LPC/LPC_and_LFCC.h"
#include "praat.github.io/fon/Sound.h"
#include "praat.github.io/fon/Matrix.h"
#include "praat.github.io/LPC/LPC.h"

using namespace Rcpp;

// ============================================================================
// RMFCC Class - Mel Frequency Cepstral Coefficients
// ============================================================================

class RMFCC {
private:
    XPtr<structMFCC> ptr;

public:
    RMFCC() : ptr(R_NilValue) {}
    RMFCC(XPtr<structMFCC> xptr) : ptr(xptr) {}

    bool is_valid() { return ptr.get() != nullptr; }

    // Time domain properties
    double get_xmin() { VALIDATE_PTR(ptr, MFCC); return ptr->xmin; }
    double get_xmax() { VALIDATE_PTR(ptr, MFCC); return ptr->xmax; }
    double get_duration() { VALIDATE_PTR(ptr, MFCC); return ptr->xmax - ptr->xmin; }
    int get_nx() { VALIDATE_PTR(ptr, MFCC); return static_cast<int>(ptr->nx); }
    double get_dx() { VALIDATE_PTR(ptr, MFCC); return ptr->dx; }
    double get_x1() { VALIDATE_PTR(ptr, MFCC); return ptr->x1; }

    // CC-specific properties
    double get_fmin() { VALIDATE_PTR(ptr, MFCC); return ptr->fmin; }
    double get_fmax() { VALIDATE_PTR(ptr, MFCC); return ptr->fmax; }
    int get_max_num_coefficients() { VALIDATE_PTR(ptr, MFCC); return static_cast<int>(ptr->maximumNumberOfCoefficients); }

    // Aliases
    int get_number_of_frames() { return get_nx(); }
    double get_time_step() { return get_dx(); }

    // Frame-level queries
    double get_c0_at_frame(int frame_number) {
        VALIDATE_PTR(ptr, MFCC);
        if (frame_number < 1 || frame_number > ptr->nx) {
            Rcpp::stop("Frame number out of range");
        }
        return CC_getC0ValueInFrame(ptr.get(), frame_number);
    }

    int get_num_coefficients_at_frame(int frame_number) {
        VALIDATE_PTR(ptr, MFCC);
        return static_cast<int>(CC_getNumberOfCoefficients(ptr.get(), frame_number));
    }

    double get_value_in_frame(int frame_number, int coeff_number) {
        VALIDATE_PTR(ptr, MFCC);
        return CC_getValueInFrame(ptr.get(), frame_number, coeff_number);
    }

    double get_value_at_time(double time, int coeff_number) {
        VALIDATE_PTR(ptr, MFCC);
        return CC_getValue(ptr.get(), time, coeff_number);
    }

    NumericVector get_coefficients_at_frame(int frame_number) {
        VALIDATE_PTR(ptr, MFCC);
        if (frame_number < 1 || frame_number > ptr->nx) {
            Rcpp::stop("Frame number out of range");
        }

        CC_Frame cf = &ptr->frame[frame_number];
        integer n = cf->numberOfCoefficients;

        NumericVector result(n + 1);  // Include c0
        result[0] = cf->c0;
        for (integer i = 1; i <= n; i++) {
            result[i] = cf->c[i];
        }
        return result;
    }

    // Bulk queries
    NumericVector get_all_c0() {
        VALIDATE_PTR(ptr, MFCC);
        NumericVector result(ptr->nx);
        for (integer i = 1; i <= ptr->nx; i++) {
            result[i-1] = ptr->frame[i].c0;
        }
        return result;
    }

    NumericMatrix get_all_coefficients() {
        VALIDATE_PTR(ptr, MFCC);
        int max_coef = static_cast<int>(CC_getMaximumNumberOfCoefficientsUsed(ptr.get()));
        NumericMatrix result(max_coef + 1, ptr->nx);  // +1 for c0

        for (integer iframe = 1; iframe <= ptr->nx; iframe++) {
            CC_Frame cf = &ptr->frame[iframe];
            result(0, iframe-1) = cf->c0;
            for (integer icoef = 1; icoef <= cf->numberOfCoefficients; icoef++) {
                result(icoef, iframe-1) = cf->c[icoef];
            }
        }
        return result;
    }

    // Frame/time conversion
    double get_time_from_frame(int frame) {
        VALIDATE_PTR(ptr, MFCC);
        return Sampled_indexToX(ptr.get(), frame);
    }

    int get_frame_from_time(double time) {
        VALIDATE_PTR(ptr, MFCC);
        return static_cast<int>(Sampled_xToNearestIndex(ptr.get(), time));
    }

    // Liftering (cepstral weighting)
    void lifter(int lifter_coefficient) {
        VALIDATE_PTR(ptr, MFCC);
        try {
            MFCC_lifter(ptr.get(), lifter_coefficient);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to apply liftering");
        }
    }

    // Conversion methods
    XPtr<structMatrix> to_matrix_ptr() {
        VALIDATE_PTR(ptr, MFCC);
        try {
            autoMatrix matrix = CC_to_Matrix(ptr.get());
            structMatrix* raw = matrix.releaseToAmbiguousOwner();
            return XPtr<structMatrix>(raw, true);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to convert MFCC to Matrix");
        }
    }

    // Export as data.frame
    DataFrame as_data_frame(bool include_c0) {
        VALIDATE_PTR(ptr, MFCC);

        integer nx = ptr->nx;
        int max_coef = static_cast<int>(CC_getMaximumNumberOfCoefficientsUsed(ptr.get()));

        NumericVector times(nx);
        for (integer i = 1; i <= nx; i++) {
            times[i-1] = Sampled_indexToX(ptr.get(), i);
        }

        List columns;
        CharacterVector col_names;

        columns.push_back(times);
        col_names.push_back("time");

        if (include_c0) {
            NumericVector c0_vals(nx);
            for (integer i = 1; i <= nx; i++) {
                c0_vals[i-1] = ptr->frame[i].c0;
            }
            columns.push_back(c0_vals);
            col_names.push_back("c0");
        }

        for (int c = 1; c <= max_coef; c++) {
            NumericVector coef_vals(nx);
            for (integer i = 1; i <= nx; i++) {
                CC_Frame cf = &ptr->frame[i];
                coef_vals[i-1] = (c <= cf->numberOfCoefficients) ? cf->c[c] : NA_REAL;
            }
            columns.push_back(coef_vals);
            col_names.push_back("c" + std::to_string(c));
        }

        return pladdrr::dt::create_datatable(
            columns,
            col_names,
            CharacterVector::create("time")
        );
    }

    List get_info() {
        VALIDATE_PTR(ptr, MFCC);
        return List::create(
            Named("xmin") = ptr->xmin,
            Named("xmax") = ptr->xmax,
            Named("nx") = ptr->nx,
            Named("dx") = ptr->dx,
            Named("x1") = ptr->x1,
            Named("fmin_mel") = ptr->fmin,
            Named("fmax_mel") = ptr->fmax,
            Named("max_n_coefficients") = ptr->maximumNumberOfCoefficients,
            Named("max_n_coefficients_used") = CC_getMaximumNumberOfCoefficientsUsed(ptr.get())
        );
    }

    void save(std::string path) {
        VALIDATE_PTR(ptr, MFCC);
        try {
            structMelderFile file = {};
            Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
            Data_writeToTextFile(ptr.get(), &file);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to save MFCC");
        }
    }
};

// ============================================================================
// RLFCC Class - Linear Frequency Cepstral Coefficients
// ============================================================================

class RLFCC {
private:
    XPtr<structLFCC> ptr;

public:
    RLFCC() : ptr(R_NilValue) {}
    RLFCC(XPtr<structLFCC> xptr) : ptr(xptr) {}

    bool is_valid() { return ptr.get() != nullptr; }

    // Time domain properties (same as MFCC - CC base class)
    double get_xmin() { VALIDATE_PTR(ptr, LFCC); return ptr->xmin; }
    double get_xmax() { VALIDATE_PTR(ptr, LFCC); return ptr->xmax; }
    double get_duration() { VALIDATE_PTR(ptr, LFCC); return ptr->xmax - ptr->xmin; }
    int get_nx() { VALIDATE_PTR(ptr, LFCC); return static_cast<int>(ptr->nx); }
    double get_dx() { VALIDATE_PTR(ptr, LFCC); return ptr->dx; }
    double get_x1() { VALIDATE_PTR(ptr, LFCC); return ptr->x1; }

    // CC-specific properties
    double get_fmin() { VALIDATE_PTR(ptr, LFCC); return ptr->fmin; }
    double get_fmax() { VALIDATE_PTR(ptr, LFCC); return ptr->fmax; }
    int get_max_num_coefficients() { VALIDATE_PTR(ptr, LFCC); return static_cast<int>(ptr->maximumNumberOfCoefficients); }

    // Aliases
    int get_number_of_frames() { return get_nx(); }
    double get_time_step() { return get_dx(); }

    // Frame-level queries
    double get_c0_at_frame(int frame_number) {
        VALIDATE_PTR(ptr, LFCC);
        if (frame_number < 1 || frame_number > ptr->nx) {
            Rcpp::stop("Frame number out of range");
        }
        return CC_getC0ValueInFrame(ptr.get(), frame_number);
    }

    int get_num_coefficients_at_frame(int frame_number) {
        VALIDATE_PTR(ptr, LFCC);
        return static_cast<int>(CC_getNumberOfCoefficients(ptr.get(), frame_number));
    }

    double get_value_in_frame(int frame_number, int coeff_number) {
        VALIDATE_PTR(ptr, LFCC);
        return CC_getValueInFrame(ptr.get(), frame_number, coeff_number);
    }

    double get_value_at_time(double time, int coeff_number) {
        VALIDATE_PTR(ptr, LFCC);
        return CC_getValue(ptr.get(), time, coeff_number);
    }

    NumericVector get_coefficients_at_frame(int frame_number) {
        VALIDATE_PTR(ptr, LFCC);
        if (frame_number < 1 || frame_number > ptr->nx) {
            Rcpp::stop("Frame number out of range");
        }

        CC_Frame cf = &ptr->frame[frame_number];
        integer n = cf->numberOfCoefficients;

        NumericVector result(n + 1);
        result[0] = cf->c0;
        for (integer i = 1; i <= n; i++) {
            result[i] = cf->c[i];
        }
        return result;
    }

    NumericMatrix get_all_coefficients() {
        VALIDATE_PTR(ptr, LFCC);
        int max_coef = static_cast<int>(CC_getMaximumNumberOfCoefficientsUsed(ptr.get()));
        NumericMatrix result(max_coef + 1, ptr->nx);

        for (integer iframe = 1; iframe <= ptr->nx; iframe++) {
            CC_Frame cf = &ptr->frame[iframe];
            result(0, iframe-1) = cf->c0;
            for (integer icoef = 1; icoef <= cf->numberOfCoefficients; icoef++) {
                result(icoef, iframe-1) = cf->c[icoef];
            }
        }
        return result;
    }

    // Frame/time conversion
    double get_time_from_frame(int frame) {
        VALIDATE_PTR(ptr, LFCC);
        return Sampled_indexToX(ptr.get(), frame);
    }

    int get_frame_from_time(double time) {
        VALIDATE_PTR(ptr, LFCC);
        return static_cast<int>(Sampled_xToNearestIndex(ptr.get(), time));
    }

    // Conversion to LPC
    XPtr<structLPC> to_lpc_ptr(int num_coefficients) {
        VALIDATE_PTR(ptr, LFCC);
        try {
            autoLPC lpc = LFCC_to_LPC(ptr.get(), num_coefficients);
            structLPC* raw = lpc.releaseToAmbiguousOwner();
            return XPtr<structLPC>(raw, true);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to convert LFCC to LPC");
        }
    }

    // Conversion to Matrix
    XPtr<structMatrix> to_matrix_ptr() {
        VALIDATE_PTR(ptr, LFCC);
        try {
            autoMatrix matrix = CC_to_Matrix(ptr.get());
            structMatrix* raw = matrix.releaseToAmbiguousOwner();
            return XPtr<structMatrix>(raw, true);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to convert LFCC to Matrix");
        }
    }

    // Export as data.frame
    DataFrame as_data_frame(bool include_c0) {
        VALIDATE_PTR(ptr, LFCC);

        integer nx = ptr->nx;
        int max_coef = static_cast<int>(CC_getMaximumNumberOfCoefficientsUsed(ptr.get()));

        NumericVector times(nx);
        for (integer i = 1; i <= nx; i++) {
            times[i-1] = Sampled_indexToX(ptr.get(), i);
        }

        List columns;
        CharacterVector col_names;

        columns.push_back(times);
        col_names.push_back("time");

        if (include_c0) {
            NumericVector c0_vals(nx);
            for (integer i = 1; i <= nx; i++) {
                c0_vals[i-1] = ptr->frame[i].c0;
            }
            columns.push_back(c0_vals);
            col_names.push_back("c0");
        }

        for (int c = 1; c <= max_coef; c++) {
            NumericVector coef_vals(nx);
            for (integer i = 1; i <= nx; i++) {
                CC_Frame cf = &ptr->frame[i];
                coef_vals[i-1] = (c <= cf->numberOfCoefficients) ? cf->c[c] : NA_REAL;
            }
            columns.push_back(coef_vals);
            col_names.push_back("c" + std::to_string(c));
        }

        return pladdrr::dt::create_datatable(
            columns,
            col_names,
            CharacterVector::create("time")
        );
    }

    List get_info() {
        VALIDATE_PTR(ptr, LFCC);
        return List::create(
            Named("xmin") = ptr->xmin,
            Named("xmax") = ptr->xmax,
            Named("nx") = ptr->nx,
            Named("dx") = ptr->dx,
            Named("x1") = ptr->x1,
            Named("fmin") = ptr->fmin,
            Named("fmax") = ptr->fmax,
            Named("max_n_coefficients") = ptr->maximumNumberOfCoefficients,
            Named("max_n_coefficients_used") = CC_getMaximumNumberOfCoefficientsUsed(ptr.get())
        );
    }

    void save(std::string path) {
        VALIDATE_PTR(ptr, LFCC);
        try {
            structMelderFile file = {};
            Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
            Data_writeToTextFile(ptr.get(), &file);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to save LFCC");
        }
    }
};

// ============================================================================
// Factory Functions
// ============================================================================

// Sound -> MFCC
static XPtr<structMFCC> Module_Sound_to_MFCC(
    XPtr<structSound> sound,
    int num_coefficients,
    double analysis_width,
    double dt,
    double f1_mel,
    double fmax_mel,
    double df_mel
) {
    if (!sound || !sound.get()) Rcpp::stop("Invalid Sound pointer");
    try {
        autoMFCC mfcc = Sound_to_MFCC(
            sound.get(),
            num_coefficients,
            analysis_width,
            dt,
            f1_mel,
            fmax_mel,
            df_mel
        );
        structMFCC* raw = mfcc.releaseToAmbiguousOwner();
        return XPtr<structMFCC>(raw, true);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to compute MFCC from Sound");
    }
}

// LPC -> LFCC
static XPtr<structLFCC> Module_LPC_to_LFCC(
    XPtr<structLPC> lpc,
    int num_coefficients
) {
    if (!lpc || !lpc.get()) Rcpp::stop("Invalid LPC pointer");
    try {
        autoLFCC lfcc = LPC_to_LFCC(lpc.get(), num_coefficients);
        structLFCC* raw = lfcc.releaseToAmbiguousOwner();
        return XPtr<structLFCC>(raw, true);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to convert LPC to LFCC");
    }
}

// ============================================================================
// Module Registration
// ============================================================================

RCPP_MODULE(mfcc_module) {
    // MFCC class
    class_<RMFCC>("RMFCC")
        .constructor()
        .constructor<XPtr<structMFCC>>()
        .method("is_valid", &RMFCC::is_valid)
        // Time domain
        .method("get_xmin", &RMFCC::get_xmin)
        .method("get_xmax", &RMFCC::get_xmax)
        .method("get_duration", &RMFCC::get_duration)
        .method("get_nx", &RMFCC::get_nx)
        .method("get_dx", &RMFCC::get_dx)
        .method("get_x1", &RMFCC::get_x1)
        // CC properties
        .method("get_fmin", &RMFCC::get_fmin)
        .method("get_fmax", &RMFCC::get_fmax)
        .method("get_max_num_coefficients", &RMFCC::get_max_num_coefficients)
        .method("get_number_of_frames", &RMFCC::get_number_of_frames)
        .method("get_time_step", &RMFCC::get_time_step)
        // Frame queries
        .method("get_c0_at_frame", &RMFCC::get_c0_at_frame)
        .method("get_num_coefficients_at_frame", &RMFCC::get_num_coefficients_at_frame)
        .method("get_value_in_frame", &RMFCC::get_value_in_frame)
        .method("get_value_at_time", &RMFCC::get_value_at_time)
        .method("get_coefficients_at_frame", &RMFCC::get_coefficients_at_frame)
        .method("get_all_c0", &RMFCC::get_all_c0)
        .method("get_all_coefficients", &RMFCC::get_all_coefficients)
        // Frame/time conversion
        .method("get_time_from_frame", &RMFCC::get_time_from_frame)
        .method("get_frame_from_time", &RMFCC::get_frame_from_time)
        // Transform
        .method("lifter", &RMFCC::lifter)
        .method("to_matrix_ptr", &RMFCC::to_matrix_ptr)
        // Export
        .method("as_data_frame", &RMFCC::as_data_frame)
        .method("get_info", &RMFCC::get_info)
        .method("save", &RMFCC::save)
    ;

    // LFCC class
    class_<RLFCC>("RLFCC")
        .constructor()
        .constructor<XPtr<structLFCC>>()
        .method("is_valid", &RLFCC::is_valid)
        // Time domain
        .method("get_xmin", &RLFCC::get_xmin)
        .method("get_xmax", &RLFCC::get_xmax)
        .method("get_duration", &RLFCC::get_duration)
        .method("get_nx", &RLFCC::get_nx)
        .method("get_dx", &RLFCC::get_dx)
        .method("get_x1", &RLFCC::get_x1)
        // CC properties
        .method("get_fmin", &RLFCC::get_fmin)
        .method("get_fmax", &RLFCC::get_fmax)
        .method("get_max_num_coefficients", &RLFCC::get_max_num_coefficients)
        .method("get_number_of_frames", &RLFCC::get_number_of_frames)
        .method("get_time_step", &RLFCC::get_time_step)
        // Frame queries
        .method("get_c0_at_frame", &RLFCC::get_c0_at_frame)
        .method("get_num_coefficients_at_frame", &RLFCC::get_num_coefficients_at_frame)
        .method("get_value_in_frame", &RLFCC::get_value_in_frame)
        .method("get_value_at_time", &RLFCC::get_value_at_time)
        .method("get_coefficients_at_frame", &RLFCC::get_coefficients_at_frame)
        .method("get_all_coefficients", &RLFCC::get_all_coefficients)
        // Frame/time conversion
        .method("get_time_from_frame", &RLFCC::get_time_from_frame)
        .method("get_frame_from_time", &RLFCC::get_frame_from_time)
        // Convert
        .method("to_lpc_ptr", &RLFCC::to_lpc_ptr)
        .method("to_matrix_ptr", &RLFCC::to_matrix_ptr)
        // Export
        .method("as_data_frame", &RLFCC::as_data_frame)
        .method("get_info", &RLFCC::get_info)
        .method("save", &RLFCC::save)
    ;

    // Factory functions
    function("Sound_to_MFCC", &Module_Sound_to_MFCC);
    function("LPC_to_LFCC", &Module_LPC_to_LFCC);
}
