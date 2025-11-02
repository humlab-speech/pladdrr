#include <Rcpp.h>
using namespace Rcpp;

// This is a simple example of exporting a C++ function to R. You can
// source this function into an R session using the Rcpp::sourceCpp 
// function (or via the Source button on the editor toolbar). Learn
// more about Rcpp at:
//
//   http://www.rcpp.org/
//   http://adv-r.had.co.nz/Rcpp.html
//   http://gallery.rcpp.org/
//

//' Get Praat version information
//'
//' Returns the version string for the Praat implementation
//' 
//' @return Character string with version information
//' @export
// [[Rcpp::export]]
String praat_version() {
    // Placeholder for actual Praat version
    // In a full implementation, this would call Praat C API
    return "Praat wrapper v0.1.0 (placeholder - Praat C API integration pending)";
}

//' Calculate basic sound statistics
//'
//' Calculates basic statistics for a sound vector (placeholder implementation)
//' 
//' @param sound_data Numeric vector containing sound amplitude values
//' @return List containing mean, min, max, and length statistics
//' @export
// [[Rcpp::export]]
List sound_stats(NumericVector sound_data) {
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

//' Create a simple Sound object representation
//'
//' Creates a basic sound object structure (placeholder for Praat Sound object)
//' 
//' @param values Numeric vector of sound amplitude values
//' @param sampling_frequency Sampling frequency in Hz (default: 44100)
//' @return List representing a sound object with values and metadata
//' @export
// [[Rcpp::export]]
List create_sound(NumericVector values, double sampling_frequency = 44100.0) {
    int n_samples = values.size();
    double duration = n_samples / sampling_frequency;
    
    return List::create(
        Named("values") = values,
        Named("sampling_frequency") = sampling_frequency,
        Named("n_samples") = n_samples,
        Named("duration") = duration,
        Named("class") = "PraatSound"
    );
}

//' Get sound duration
//'
//' Calculate the duration of a sound object in seconds
//' 
//' @param sound_object List representing a sound object (from create_sound)
//' @return Numeric value representing duration in seconds
//' @export
// [[Rcpp::export]]
double get_sound_duration(List sound_object) {
    if (!sound_object.containsElementNamed("duration")) {
        stop("Invalid sound object: missing 'duration' field");
    }
    return sound_object["duration"];
}
