// Test if Praat's pitch detection works directly in C++
#include <Rcpp.h>
#include "praat_xptr_utils.h"
#include "praat.github.io/fon/Sound.h"
#include "praat.github.io/fon/Sound_to_Pitch.h"

using namespace Rcpp;

// [[Rcpp::export]]
void test_pitch_direct_cpp() {
  try {
    // Create 200 Hz tone, 0.5s
    double fs = 16000.0;
    double duration = 0.5;
    integer nsamples = (integer)(duration * fs);
    
    autoSound sound = Sound_create(1, 0.0, duration, nsamples, 1.0/fs, 0.5/fs);
    
    // Fill with 200 Hz sine
    for (integer i = 1; i <= sound->nx; i++) {
      double t = sound->x1 + (i-1) * sound->dx;
      sound->z[1][i] = 0.8 * sin(2.0 * M_PI * 200.0 * t);
    }
    
    Rcpp::Rcout << "Sound created:\n";
    Rcpp::Rcout << "  nx = " << sound->nx << "\n";
    Rcpp::Rcout << "  dx = " << sound->dx << "\n";
    Rcpp::Rcout << "  xmin = " << sound->xmin << "\n";
    Rcpp::Rcout << "  xmax = " << sound->xmax << "\n";
    
    // Extract pitch
    autoPitch pitch = Sound_to_Pitch(sound.get(), 0.01, 75.0, 600.0);
    
    Rcpp::Rcout << "\nPitch created:\n";
    Rcpp::Rcout << "  nx (frames) = " << pitch->nx << "\n";
    Rcpp::Rcout << "  dx (time step) = " << pitch->dx << "\n";
    
    // Count voiced frames
    integer voiced_count = 0;
    for (integer iframe = 1; iframe <= pitch->nx; iframe++) {
      auto& frame = pitch->frames[iframe];
      if (frame.nCandidates > 0 && frame.candidates[1].frequency > 0) {
        voiced_count++;
      }
    }
    
    Rcpp::Rcout << "  Voiced frames = " << voiced_count << "\n";
    
    // Print first few frames
    Rcpp::Rcout << "\nFirst 5 frames:\n";
    for (integer i = 1; i <= std::min((integer)5, pitch->nx); i++) {
      auto& frame = pitch->frames[i];
      Rcpp::Rcout << "  Frame " << i << ": nCandidates=" << frame.nCandidates;
      if (frame.nCandidates > 0) {
        Rcpp::Rcout << ", f=" << frame.candidates[1].frequency << " Hz";
      }
      Rcpp::Rcout << "\n";
    }
    
  } catch (MelderError) {
    Melder_clearError();
    Rcpp::stop("Praat error occurred");
  }
}
