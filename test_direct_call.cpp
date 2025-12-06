#include <Rcpp.h>
#include "praat.github.io/fon/Sound.h"
#include "praat.github.io/fon/TextGrid.h"
#include "praat.github.io/dwtools/Sound_and_TextGrid_extensions.h"

// [[Rcpp::export]]
void test_direct_silence_detection() {
    try {
        Rcpp::Rcout << "Loading Sound from file...\n";
        autoSound sound = Sound_readFromSoundFile(Melder_peek8to32("inst/extdata/test.wav"));
        
        Rcpp::Rcout << "Sound duration: " << sound->xmax << " seconds\n";
        
        Rcpp::Rcout << "Calling Sound_to_TextGrid_detectSilences...\n";
        autoTextGrid tg = Sound_to_TextGrid_detectSilences(
            sound.get(),
            100.0,        // min_pitch
            0.01,         // time_step
            -25.0,        // silence_threshold
            0.1,          // min_silent_duration
            0.1,          // min_sounding_duration
            U"silent",    // silent_label
            U"sounding"   // sounding_label
        );
        
        Rcpp::Rcout << "SUCCESS! TextGrid created\n";
        Rcpp::Rcout << "Number of tiers: " << tg->tiers->size << "\n";
        
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Praat error occurred");
    }
}
