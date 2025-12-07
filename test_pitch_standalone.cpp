// Standalone pitch detection debug test
// Compile: g++ -std=c++17 -I. -Iinst/include test_pitch_standalone.cpp -o test_pitch

#include <Rcpp.h>
#include "inst/include/praat.github.io/fon/Sound.h"
#include "inst/include/praat.github.io/fon/Pitch.h"
#include "inst/include/praat.github.io/melder/melder.h"

using namespace Rcpp;

// [[Rcpp::export]]
void debug_pitch_detection() {
    try {
        // Create simple 200 Hz sine wave
        double duration = 1.0;
        double sampleRate = 16000.0;
        integer nSamples = (integer)(duration * sampleRate);
        
        autoSound sound = Sound_createSimple(1, duration, sampleRate);
        
        // Fill with 200 Hz sine
        double freq = 200.0;
        for (integer i = 1; i <= nSamples; i++) {
            double t = (i - 1) / sampleRate;
            sound->z[1][i] = 0.9 * sin(2.0 * NUMpi * freq * t);
        }
        
        Rcout << "=== SOUND OBJECT ===" << "\n";
        Rcout << "nx (samples): " << sound->nx << "\n";
        Rcout << "dx (sample period): " << sound->dx << "\n";
        Rcout << "x1 (start time): " << sound->x1 << "\n";
        Rcout << "xmax (end time): " << sound->xmax << "\n";
        
        // Check actual audio data
        double minVal = 1e10, maxVal = -1e10, sumSq = 0.0;
        for (integer i = 1; i <= nSamples; i++) {
            double val = sound->z[1][i];
            if (val < minVal) minVal = val;
            if (val > maxVal) maxVal = val;
            sumSq += val * val;
        }
        double rms = sqrt(sumSq / nSamples);
        
        Rcout << "Audio range: [" << minVal << ", " << maxVal << "]" << "\n";
        Rcout << "Audio RMS: " << rms << "\n";
        Rcout << "Sample[1]: " << sound->z[1][1] << "\n";
        Rcout << "Sample[100]: " << sound->z[1][100] << "\n";
        
        // Create pitch object
        Rcout << "\n=== PITCH DETECTION ===" << "\n";
        double timeStep = 0.01;
        double pitchFloor = 75.0;
        double pitchCeiling = 600.0;
        
        autoPitch pitch = Sound_to_Pitch(sound.get(), timeStep, pitchFloor, pitchCeiling);
        
        Rcout << "Pitch object created" << "\n";
        Rcout << "nx (frames): " << pitch->nx << "\n";
        Rcout << "dx (frame step): " << pitch->dx << "\n";
        Rcout << "x1 (first frame): " << pitch->x1 << "\n";
        Rcout << "ceiling: " << pitch->ceiling << "\n";
        Rcout << "maxnCandidates: " << pitch->maxnCandidates << "\n";
        
        // Check first 10 frames
        Rcout << "\n=== FRAME ANALYSIS (first 10) ===" << "\n";
        integer framesToCheck = pitch->nx < 10 ? pitch->nx : 10;
        
        for (integer i = 1; i <= framesToCheck; i++) {
            Pitch_Frame frame = &pitch->frames[i];
            double time = pitch->x1 + (i - 1) * pitch->dx;
            
            Rcout << "Frame " << i << " (t=" << time << "s):" << "\n";
            Rcout << "  nCandidates: " << frame->nCandidates << "\n";
            
            if (frame->nCandidates > 0) {
                for (integer j = 1; j <= frame->nCandidates; j++) {
                    Rcout << "  Candidate " << j << ": freq=" << frame->candidates[j].frequency 
                          << " Hz, strength=" << frame->candidates[j].strength << "\n";
                }
                
                // Check voicing logic
                double f = frame->candidates[1].frequency;
                bool voiced = (f > 0.0 && f < pitchCeiling);
                Rcout << "  Voiced: " << (voiced ? "YES" : "NO") 
                      << " (f=" << f << ", ceiling=" << pitchCeiling << ")" << "\n";
            }
        }
        
        // Count voiced frames
        integer voicedCount = 0;
        for (integer i = 1; i <= pitch->nx; i++) {
            double f = pitch->frames[i].candidates[1].frequency;
            if (f > 0.0 && f < pitchCeiling) {
                voicedCount++;
            }
        }
        
        Rcout << "\n=== SUMMARY ===" << "\n";
        Rcout << "Total frames: " << pitch->nx << "\n";
        Rcout << "Voiced frames: " << voicedCount << "\n";
        Rcout << "Voicing %: " << (100.0 * voicedCount / pitch->nx) << "%" << "\n";
        
    } catch (MelderError) {
        Rcout << "ERROR: " << Melder_getError() << "\n";
        Melder_clearError();
    }
}
