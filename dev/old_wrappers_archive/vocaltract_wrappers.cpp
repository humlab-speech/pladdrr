// vocaltract_wrappers.cpp
// Rcpp wrappers for Praat VocalTract functionality

#include <Rcpp.h>
#include "praat_types.h"
#include "praat_xptr_utils.h"
#include "praat_error_handling.h"

#include "fon/VocalTract.h"
#include "fon/VocalTract_to_Spectrum.h"

using namespace Rcpp;

// ==============================================================================
// Creation
// ==============================================================================

//' Create a VocalTract with specified sections
//' @param nx Number of sections
//' @param dx Section length in metres
//' @return External pointer to VocalTract
//' @keywords internal
// [[Rcpp::export(.vocaltract_create)]]
SEXP vocaltract_create(int nx, double dx) {
    if (nx < 1) stop("nx must be >= 1");
    if (dx <= 0.0) stop("dx must be > 0");

    try {
        autoVocalTract vt = VocalTract_create(nx, dx);
        return create_xptr_from_auto<structVocalTract>(vt);
    } catch (MelderError) {
        std::string error_msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        stop("Failed to create VocalTract: " + error_msg);
    }
    return R_NilValue;
}

//' Create VocalTract from phone specification
//' @param phone Phone name (a, e, i, o, u, y1, y2, y3, jery, p, t, k, x, pa, ta, ka, pi, ti, ki, pu, tu, ku)
//' @return External pointer to VocalTract
//' @keywords internal
// [[Rcpp::export(.vocaltract_create_from_phone)]]
SEXP vocaltract_create_from_phone(std::string phone) {
    try {
        autostring32 phone32 = Melder_8to32(phone.c_str());
        autoVocalTract vt = VocalTract_createFromPhone(phone32.get());
        return create_xptr_from_auto<structVocalTract>(vt);
    } catch (MelderError) {
        std::string error_msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        stop("Failed to create VocalTract from phone: " + error_msg);
    }
    return R_NilValue;
}

// ==============================================================================
// Query
// ==============================================================================

//' Get VocalTract total length
//' @param xptr External pointer to VocalTract
//' @return Total length in metres
//' @keywords internal
// [[Rcpp::export(.vocaltract_get_length)]]
double vocaltract_get_length(SEXP xptr) {
    XPtr<structVocalTract> vt(xptr);
    if (!vt) stop("Invalid VocalTract pointer");
    return vt->xmax;
}

//' Get number of sections
//' @param xptr External pointer to VocalTract
//' @return Number of sections
//' @keywords internal
// [[Rcpp::export(.vocaltract_get_number_of_sections)]]
int vocaltract_get_number_of_sections(SEXP xptr) {
    XPtr<structVocalTract> vt(xptr);
    if (!vt) stop("Invalid VocalTract pointer");
    return vt->nx;
}

//' Get section length
//' @param xptr External pointer to VocalTract
//' @return Section length in metres
//' @keywords internal
// [[Rcpp::export(.vocaltract_get_section_length)]]
double vocaltract_get_section_length(SEXP xptr) {
    XPtr<structVocalTract> vt(xptr);
    if (!vt) stop("Invalid VocalTract pointer");
    return vt->dx;
}

//' Get area at section
//' @param xptr External pointer to VocalTract
//' @param section Section index (1-based)
//' @return Area in square metres
//' @keywords internal
// [[Rcpp::export(.vocaltract_get_area)]]
double vocaltract_get_area(SEXP xptr, int section) {
    XPtr<structVocalTract> vt(xptr);
    if (!vt) stop("Invalid VocalTract pointer");
    if (section < 1 || section > vt->nx) {
        stop("Section index out of range: " + std::to_string(section));
    }
    return vt->z[1][section];
}

//' Set area at section
//' @param xptr External pointer to VocalTract
//' @param section Section index (1-based)
//' @param area Area in square metres
//' @keywords internal
// [[Rcpp::export(.vocaltract_set_area)]]
void vocaltract_set_area(SEXP xptr, int section, double area) {
    XPtr<structVocalTract> vt(xptr);
    if (!vt) stop("Invalid VocalTract pointer");
    if (section < 1 || section > vt->nx) {
        stop("Section index out of range: " + std::to_string(section));
    }
    if (area <= 0) stop("Area must be positive");
    vt->z[1][section] = area;
}

//' Get all areas as vector
//' @param xptr External pointer to VocalTract
//' @return Numeric vector of areas
//' @keywords internal
// [[Rcpp::export(.vocaltract_get_areas)]]
NumericVector vocaltract_get_areas(SEXP xptr) {
    XPtr<structVocalTract> vt(xptr);
    if (!vt) stop("Invalid VocalTract pointer");

    NumericVector areas(vt->nx);
    for (int i = 1; i <= vt->nx; i++) {
        areas[i-1] = vt->z[1][i];
    }
    return areas;
}

//' Set all areas from vector
//' @param xptr External pointer to VocalTract
//' @param areas Numeric vector of areas
//' @keywords internal
// [[Rcpp::export(.vocaltract_set_areas)]]
void vocaltract_set_areas(SEXP xptr, NumericVector areas) {
    XPtr<structVocalTract> vt(xptr);
    if (!vt) stop("Invalid VocalTract pointer");

    if (areas.length() != vt->nx) {
        stop("Areas vector length must match number of sections");
    }

    for (int i = 1; i <= vt->nx; i++) {
        if (areas[i-1] <= 0) stop("All areas must be positive");
        vt->z[1][i] = areas[i-1];
    }
}

// ==============================================================================
// Conversion
// ==============================================================================

//' Convert VocalTract to Spectrum
//' @param xptr External pointer to VocalTract
//' @param number_of_frequencies Number of frequency bins
//' @param maximum_frequency Maximum frequency in Hz
//' @param glottal_damping Glottal damping coefficient
//' @param radiation_damping Include radiation damping
//' @param internal_damping Include internal damping
//' @return External pointer to Spectrum
//' @keywords internal
// [[Rcpp::export(.vocaltract_to_spectrum)]]
SEXP vocaltract_to_spectrum(SEXP xptr, int number_of_frequencies,
                            double maximum_frequency, double glottal_damping,
                            bool radiation_damping, bool internal_damping) {
    XPtr<structVocalTract> vt(xptr);
    if (!vt) stop("Invalid VocalTract pointer");

    try {
        autoSpectrum spectrum = VocalTract_to_Spectrum(
            vt.get(), number_of_frequencies, maximum_frequency,
            glottal_damping, radiation_damping, internal_damping
        );
        return create_xptr_from_auto<structSpectrum>(spectrum);
    } catch (MelderError) {
        std::string error_msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        stop("Failed to convert VocalTract to Spectrum: " + error_msg);
    }
    return R_NilValue;
}

//' Convert VocalTract to Matrix
//' @param xptr External pointer to VocalTract
//' @return External pointer to Matrix
//' @keywords internal
// [[Rcpp::export(.vocaltract_to_matrix)]]
SEXP vocaltract_to_matrix(SEXP xptr) {
    XPtr<structVocalTract> vt(xptr);
    if (!vt) stop("Invalid VocalTract pointer");

    try {
        autoMatrix mat = VocalTract_to_Matrix(vt.get());
        return create_xptr_from_auto<structMatrix>(mat);
    } catch (MelderError) {
        std::string error_msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        stop("Failed to convert VocalTract to Matrix: " + error_msg);
    }
    return R_NilValue;
}
