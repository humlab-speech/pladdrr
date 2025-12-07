#include <Rcpp.h>
#include "praat_xptr_utils.h"
#include "praat.github.io/fon/Sound.h"
#include "praat.github.io/fon/Pitch.h"

using namespace Rcpp;

// [[Rcpp::export]]
void debug_pitch_detection(SEXP sound_xptr) {
    Rcpp::XPtr<structSound> sound(sound_xptr);
    
    if (!sound) {
        Rcpp::Rcout << "ERROR: Invalid Sound pointer\n";
        return;
    }
    
    Rcpp::Rcout << "=== DEBUG PITCH DETECTION ===\n";
    Rcpp::Rcout << "Sound properties:\n";
    Rcpp::Rcout << "  nx (samples): " << sound->nx << "\n";
    Rcpp::Rcout << "  dx (sample period): " << sound->dx << "\n";
    Rcpp::Rcout << "  x1 (first sample time): " << sound->x1 << "\n";
    Rcpp::Rcout << "  xmin: " << sound->xmin << "\n";
    Rcpp::Rcout << "  xmax: " << sound->xmax << "\n";
    Rcpp::Rcout << "  ny (channels): " << sound->ny << "\n";
    
    // Check audio data
    if (sound->nx > 0 && sound->ny > 0) {
        double min_val = sound->z[1][1];
        double max_val = sound->z[1][1];
        double sum = 0.0;
        
        for (integer i = 1; i <= sound->nx; i++) {
            double val = sound->z[1][i];
            if (val < min_val) min_val = val;
            if (val > max_val) max_val = val;
            sum += val * val;
        }
        
        double rms = sqrt(sum / sound->nx);
        
        Rcpp::Rcout << "  Audio range: " << min_val << " to " << max_val << "\n";
        Rcpp::Rcout << "  RMS: " << rms << "\n";
        Rcpp::Rcout << "  First 5 samples: ";
        for (integer i = 1; i <= std::min((integer)5, sound->nx); i++) {
            Rcpp::Rcout << sound->z[1][i] << " ";
        }
        Rcpp::Rcout << "\n";
    }
    
    // Try pitch detection
    Rcpp::Rcout << "\nCalling Sound_to_Pitch...\n";
    try {
        autoPitch pitch = Sound_to_Pitch(sound.get(), 0.01, 75, 400);
        
        Rcpp::Rcout << "Pitch object created successfully!\n";
        Rcpp::Rcout << "  nx (frames): " << pitch->nx << "\n";
        Rcpp::Rcout << "  ceiling: " << pitch->ceiling << "\n";
        
        // Check first few frames
        Rcpp::Rcout << "  First 5 frames:\n";
        for (integer i = 1; i <= std::min((integer)5, pitch->nx); i++) {
            double f = pitch->frames[i].candidates[1].frequency;
            double s = pitch->frames[i].candidates[1].strength;
            int nc = pitch->frames[i].nCandidates;
            Rcpp::Rcout << "    Frame " << i << ": nCandidates=" << nc 
                       << " f=" << f << " Hz, strength=" << s << "\n";
        }
        
        integer voiced = Pitch_countVoicedFrames(pitch.get());
        Rcpp::Rcout << "  Voiced frames: " << voiced << "\n";
        
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::Rcout << "ERROR in Sound_to_Pitch\n";
    }
}
