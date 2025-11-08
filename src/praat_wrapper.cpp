// praat_wrapper.cpp - Main Rcpp interface to Praat C functionality
//
// This file provides the core Rcpp wrapper functions that expose Praat's
// phonetic analysis capabilities to R. It serves as the bridge between
// R and the Praat C library.
//
// Note: Full Praat integration requires linking against Praat source files
// (configured in Makevars). This initial version provides placeholder
// implementations that will be replaced with actual Praat calls.

#include <Rcpp.h>
using namespace Rcpp;

// TODO: Once Praat headers are properly integrated, include:
// #include "praat/melder/melder.h"
// #include "praat/sys/Thing.h"
// #include "praat/fon/Sound.h"
// #include "praat/fon/Pitch.h"
// etc.

// ============================================================================
// Package Information and Initialization
// ============================================================================

//' Get Praat version information
//'
//' Returns the version string for the Praat library integration
//'
//' @return Character string with version information
//' @export
// [[Rcpp::export]]
String praat_version() {
    // TODO: Replace with actual Praat version from headers when integrated
    // Example: return String(PRAAT_VERSION);
    return "speaker v0.1.0 (Praat C library integration)";
}

//' Initialize Praat library
//'
//' Performs any necessary initialization for Praat components
//' This should be called when the package is loaded
//'
//' @return Logical indicating success
//' @keywords internal
// [[Rcpp::export]]
bool praat_initialize() {
    // TODO: Initialize Praat's memory management and error handling
    // For now, just return true
    return true;
}

// ============================================================================
// Sound Object Creation and Basic Operations
// ============================================================================

//' Calculate basic sound statistics
//'
//' Calculates basic statistics for a sound vector
//'
//' @param sound_data Numeric vector containing sound amplitude values
//' @return List containing mean, min, max, and length statistics
//' @keywords internal
// [[Rcpp::export]]
List sound_stats(NumericVector sound_data) {
    if (sound_data.size() == 0) {
        Rcpp::stop("Cannot calculate statistics for empty sound data");
    }

    double mean_val = mean(sound_data);
    double min_val = min(sound_data);
    double max_val = max(sound_data);
    int length = sound_data.size();

    return List::create(
        Named("mean") = mean_val,
        Named("min") = min_val,
        Named("max") = max_val,
        Named("length") = length
    );
}

//' Create a sound object from numeric vector
//'
//' Creates a praat_sound object structure from R numeric data
//'
//' @param values Numeric vector of sound amplitude values
//' @param sampling_rate Sampling rate in Hz (default: 44100)
//' @param start_time Start time in seconds (default: 0.0)
//' @return List representing a praat_sound object with values and metadata
//' @export
// [[Rcpp::export]]
List create_sound_from_values(NumericVector values, double sampling_rate = 44100.0,
                              double start_time = 0.0) {
    // Validate inputs
    if (values.size() == 0) {
        Rcpp::stop("Cannot create sound from empty values vector");
    }
    if (sampling_rate <= 0.0) {
        Rcpp::stop("Sampling rate must be positive, got: " + std::to_string(sampling_rate));
    }

    int n_samples = values.size();
    double duration = n_samples / sampling_rate;

    // Create time vector
    NumericVector time(n_samples);
    for (int i = 0; i < n_samples; i++) {
        time[i] = start_time + i / sampling_rate;
    }

    List result = List::create(
        Named("values") = values,
        Named("time") = time,
        Named("sampling_rate") = sampling_rate,
        Named("n_samples") = n_samples,
        Named("n_channels") = 1,  // Mono by default
        Named("channel") = 0,     // Left channel
        Named("duration") = duration,
        Named("start_time") = start_time,
        Named("end_time") = start_time + duration
    );

    // Set the class attribute for S3 dispatch
    result.attr("class") = CharacterVector::create("praat_sound", "list");

    return result;
}

//' Get sound duration
//'
//' Extract the duration of a sound object in seconds
//'
//' @param sound_obj List representing a praat_sound object
//' @return Numeric value representing duration in seconds
//' @keywords internal
// [[Rcpp::export]]
double get_sound_duration_cpp(List sound_obj) {
    if (!sound_obj.containsElementNamed("duration")) {
        Rcpp::stop("Invalid sound object: missing 'duration' field");
    }
    return sound_obj["duration"];
}

//' Get sound sampling rate
//'
//' Extract the sampling rate of a sound object
//'
//' @param sound_obj List representing a praat_sound object
//' @return Numeric value representing sampling rate in Hz
//' @keywords internal
// [[Rcpp::export]]
double get_sound_sampling_rate_cpp(List sound_obj) {
    if (!sound_obj.containsElementNamed("sampling_rate")) {
        Rcpp::stop("Invalid sound object: missing 'sampling_rate' field");
    }
    return sound_obj["sampling_rate"];
}

//' Get number of samples in sound
//'
//' Extract the number of samples in a sound object
//'
//' @param sound_obj List representing a praat_sound object
//' @return Integer number of samples
//' @keywords internal
// [[Rcpp::export]]
int get_sound_n_samples_cpp(List sound_obj) {
    if (!sound_obj.containsElementNamed("n_samples")) {
        Rcpp::stop("Invalid sound object: missing 'n_samples' field");
    }
    return sound_obj["n_samples"];
}
