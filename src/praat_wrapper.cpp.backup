// praat_wrapper.cpp - Main Rcpp interface to Praat C functionality
//
// This file provides the core Rcpp wrapper functions that expose Praat's
// phonetic analysis capabilities to R. It serves as the bridge between
// R and the Praat C library.
//
// Note: Full Praat integration requires linking against Praat source files
// (configured in Makevars). This initial version provides placeholder
// implementations that will be replaced with actual Praat calls.

// Praat headers for initialization
#include "praat.github.io/sys/Thing.h"
#include "praat.github.io/sys/Data.h"
#include "praat.github.io/melder/melder_alloc.h"  // For Melder_alloc_init()
#include "praat.github.io/melder/melder_textencoding.h"  // For Melder_setInputEncoding()
#include "praat.github.io/melder/NUMrandom.h"     // For NUMrandom_initializeSafelyAndUnpredictably()
#include "praat.github.io/dwsys/NUMmachar.h"      // For NUMmachar()
#include "praat.github.io/fon/Sound.h"
#include "praat.github.io/fon/Pitch.h"
#include "praat.github.io/fon/Formant.h"
#include "praat.github.io/fon/Intensity.h"
#include "praat.github.io/fon/Spectrum.h"
#include "praat.github.io/fon/Spectrogram.h"
#include "praat.github.io/fon/Harmonicity.h"
#include "praat.github.io/fon/TextGrid.h"
#include "praat.github.io/fon/PointProcess.h"
#include "praat.github.io/fon/Matrix.h"
#include "praat.github.io/fon/Ltas.h"
#include "praat.github.io/LPC/LPC.h"
#include "praat.github.io/stat/Table.h"

#include <Rcpp.h>
using namespace Rcpp;

// Praat library headers are integrated via individual wrapper files
// Each wrapper includes the specific Praat headers needed for that object type
// This modular approach provides better compilation times and dependency management

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
    // Returns pladdrr package version with Praat integration note
    // The integrated Praat source is from github.com/praat/praat
    return "pladdrr v0.9.11 (Praat C library integration)";
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
    // Initialize Praat numerical library (must come BEFORE Melder_alloc_init)
    // This sets up machine precision constants and random number generator
    NUMmachar();
    NUMrandom_initializeSafelyAndUnpredictably();

    // Critical: Initialize Melder memory allocator (theRainyDayFund)
    // This MUST be called before any Praat object operations
    Melder_alloc_init();
    
    // Initialize text encoding (required for file reading)
    #if defined (macintosh) || defined (__APPLE__)
        Melder_setInputEncoding(kMelder_textInputEncoding::UTF8_THEN_MACROMAN);
    #elif defined (_WIN32)
        Melder_setInputEncoding(kMelder_textInputEncoding::UTF8_THEN_WINDOWS_LATIN1);
    #else
        Melder_setInputEncoding(kMelder_textInputEncoding::UTF8_THEN_ISO_LATIN1);
    #endif
    Melder_setOutputEncoding(kMelder_textOutputEncoding::UTF8);
    
    // Register all Praat classes for file I/O
    // This is required for Data_readFromFile to work correctly
    Thing_recognizeClassesByName(classSound,
                                  classPitch,
                                  classFormant,
                                  classIntensity,
                                  classSpectrum,
                                  classSpectrogram,
                                  classHarmonicity,
                                  classTextGrid,
                                  classPointProcess,
                                  classMatrix,
                                  classLtas,
                                  classLPC,
                                  classTable,
                                  nullptr);   // nullptr terminates the list
    
    // Register additional TextGrid-related classes
    Thing_recognizeClassesByName(classTextPoint,
                                  classTextInterval,
                                  classTextTier,
                                  classIntervalTier,
                                  nullptr);
    
    // Note: Thing_listReadableClasses() call removed - was causing segfault
    // The registry is working correctly (classes are being registered)
    return true;
}

// Expose the registry variables for testing
extern integer theNumberOfReadableClasses;
extern ClassInfo theReadableClasses [1 + 1000];

// [[Rcpp::export(.test_class_registry)]]
int test_class_registry() {
    Rcpp::Rcout << "Registry address: " << &theNumberOfReadableClasses << "\n";
    Rcpp::Rcout << "Number of classes: " << theNumberOfReadableClasses << "\n";
    
    for (integer i = 1; i <= theNumberOfReadableClasses && i <= 10; i++) {
        ClassInfo klas = theReadableClasses[i];
        if (klas) {
            Rcpp::Rcout << "  [" << i << "] " << Melder_peek32to8(klas->className) << "\n";
        } else {
            Rcpp::Rcout << "  [" << i << "] NULL\n";
        }
    }
    
    return theNumberOfReadableClasses;
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
