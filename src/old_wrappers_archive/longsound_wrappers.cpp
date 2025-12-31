// longsound_wrappers.cpp
// Rcpp wrappers for Praat LongSound functionality

#include <Rcpp.h>
#include "praat_types.h"
#include "praat_xptr_utils.h"
#include "praat_error_handling.h"

#include "fon/LongSound.h"

using namespace Rcpp;

// ==============================================================================
// Creation
// ==============================================================================

//' Open a LongSound from file
//' @param path Path to audio file
//' @return External pointer to LongSound
//' @keywords internal
// [[Rcpp::export(.longsound_open)]]
SEXP longsound_open(std::string path) {
    try {
        structMelderFile file;
        Melder_relativePathToFile(Melder_8to32(path.c_str()).get(), &file);
        autoLongSound ls = LongSound_open(&file);
        return create_xptr_from_auto<structLongSound>(ls);
    } catch (MelderError) {
        std::string error_msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        stop("Failed to open LongSound: " + error_msg);
    }
    return R_NilValue;
}

// ==============================================================================
// Query
// ==============================================================================

//' Get LongSound duration
//' @param xptr External pointer to LongSound
//' @return Duration in seconds
//' @keywords internal
// [[Rcpp::export(.longsound_get_duration)]]
double longsound_get_duration(SEXP xptr) {
    XPtr<structLongSound> ls(xptr);
    if (!ls) stop("Invalid LongSound pointer");
    return ls->xmax - ls->xmin;
}

//' Get LongSound start time
//' @param xptr External pointer to LongSound
//' @return Start time in seconds
//' @keywords internal
// [[Rcpp::export(.longsound_get_start_time)]]
double longsound_get_start_time(SEXP xptr) {
    XPtr<structLongSound> ls(xptr);
    if (!ls) stop("Invalid LongSound pointer");
    return ls->xmin;
}

//' Get LongSound end time
//' @param xptr External pointer to LongSound
//' @return End time in seconds
//' @keywords internal
// [[Rcpp::export(.longsound_get_end_time)]]
double longsound_get_end_time(SEXP xptr) {
    XPtr<structLongSound> ls(xptr);
    if (!ls) stop("Invalid LongSound pointer");
    return ls->xmax;
}

//' Get LongSound sample rate
//' @param xptr External pointer to LongSound
//' @return Sample rate in Hz
//' @keywords internal
// [[Rcpp::export(.longsound_get_sample_rate)]]
double longsound_get_sample_rate(SEXP xptr) {
    XPtr<structLongSound> ls(xptr);
    if (!ls) stop("Invalid LongSound pointer");
    return ls->sampleRate;
}

//' Get LongSound number of channels
//' @param xptr External pointer to LongSound
//' @return Number of channels
//' @keywords internal
// [[Rcpp::export(.longsound_get_number_of_channels)]]
int longsound_get_number_of_channels(SEXP xptr) {
    XPtr<structLongSound> ls(xptr);
    if (!ls) stop("Invalid LongSound pointer");
    return static_cast<int>(ls->numberOfChannels);
}

//' Get LongSound number of samples
//' @param xptr External pointer to LongSound
//' @return Number of samples
//' @keywords internal
// [[Rcpp::export(.longsound_get_number_of_samples)]]
int longsound_get_number_of_samples(SEXP xptr) {
    XPtr<structLongSound> ls(xptr);
    if (!ls) stop("Invalid LongSound pointer");
    return static_cast<int>(ls->nx);
}

//' Get LongSound file path
//' @param xptr External pointer to LongSound
//' @return File path
//' @keywords internal
// [[Rcpp::export(.longsound_get_file_path)]]
std::string longsound_get_file_path(SEXP xptr) {
    XPtr<structLongSound> ls(xptr);
    if (!ls) stop("Invalid LongSound pointer");
    return Melder_peek32to8(ls->file.path);
}

// ==============================================================================
// Extraction
// ==============================================================================

//' Extract part of LongSound as Sound
//' @param xptr External pointer to LongSound
//' @param tmin Start time
//' @param tmax End time
//' @param preserve_times If TRUE, keep original time domain
//' @return External pointer to Sound
//' @keywords internal
// [[Rcpp::export(.longsound_extract_part)]]
SEXP longsound_extract_part(SEXP xptr, double tmin, double tmax, bool preserve_times) {
    XPtr<structLongSound> ls(xptr);
    if (!ls) stop("Invalid LongSound pointer");

    try {
        autoSound sound = LongSound_extractPart(ls.get(), tmin, tmax, preserve_times);
        return create_xptr_from_auto<structSound>(sound);
    } catch (MelderError) {
        std::string error_msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        stop("Failed to extract part: " + error_msg);
    }
    return R_NilValue;
}

//' Check if window is available in buffer
//' @param xptr External pointer to LongSound
//' @param tmin Start time
//' @param tmax End time
//' @return TRUE if window is in buffer
//' @keywords internal
// [[Rcpp::export(.longsound_have_window)]]
bool longsound_have_window(SEXP xptr, double tmin, double tmax) {
    XPtr<structLongSound> ls(xptr);
    if (!ls) stop("Invalid LongSound pointer");
    return LongSound_haveWindow(ls.get(), tmin, tmax);
}

//' Get window extrema
//' @param xptr External pointer to LongSound
//' @param tmin Start time
//' @param tmax End time
//' @param channel Channel number (1-based)
//' @return Named vector with minimum and maximum
//' @keywords internal
// [[Rcpp::export(.longsound_get_window_extrema)]]
NumericVector longsound_get_window_extrema(SEXP xptr, double tmin, double tmax, int channel) {
    XPtr<structLongSound> ls(xptr);
    if (!ls) stop("Invalid LongSound pointer");

    double minimum, maximum;
    LongSound_getWindowExtrema(ls.get(), tmin, tmax, channel, &minimum, &maximum);

    NumericVector result = NumericVector::create(
        Named("minimum") = minimum,
        Named("maximum") = maximum
    );
    return result;
}

// ==============================================================================
// Save
// ==============================================================================

//' Save part of LongSound to audio file
//' @param xptr External pointer to LongSound
//' @param audio_file_type Audio file type (1=WAV, 2=AIFF, etc.)
//' @param tmin Start time
//' @param tmax End time
//' @param path Output file path
//' @param bits_per_sample Bits per sample (16 or 24)
//' @keywords internal
// [[Rcpp::export(.longsound_save_part)]]
void longsound_save_part(SEXP xptr, int audio_file_type, double tmin, double tmax,
                         std::string path, int bits_per_sample) {
    XPtr<structLongSound> ls(xptr);
    if (!ls) stop("Invalid LongSound pointer");

    try {
        structMelderFile file;
        Melder_relativePathToFile(Melder_8to32(path.c_str()).get(), &file);
        LongSound_savePartAsAudioFile(ls.get(), audio_file_type, tmin, tmax, &file, bits_per_sample);
    } catch (MelderError) {
        std::string error_msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        stop("Failed to save part: " + error_msg);
    }
}

//' Save single channel of LongSound to audio file
//' @param xptr External pointer to LongSound
//' @param audio_file_type Audio file type
//' @param channel Channel number (1-based)
//' @param path Output file path
//' @keywords internal
// [[Rcpp::export(.longsound_save_channel)]]
void longsound_save_channel(SEXP xptr, int audio_file_type, int channel, std::string path) {
    XPtr<structLongSound> ls(xptr);
    if (!ls) stop("Invalid LongSound pointer");

    try {
        structMelderFile file;
        Melder_relativePathToFile(Melder_8to32(path.c_str()).get(), &file);
        LongSound_saveChannelAsAudioFile(ls.get(), audio_file_type, channel, &file);
    } catch (MelderError) {
        std::string error_msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        stop("Failed to save channel: " + error_msg);
    }
}
