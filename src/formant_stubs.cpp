// formant_stubs.cpp
// Stub implementations for missing Formant functions
// Part of pladdrr - Phase 2.2 FormantPath support

#include "praat_types.h"
#include "praat.github.io/melder/melder.h"
#include "praat.github.io/fon/Formant.h"

// Stub for Formant_extractPart - extracts time slice of Formant
// This function is referenced in FormantPath.cpp but not present in current Praat
autoFormant Formant_extractPart(constFormant me, double tmin, double tmax) {
    try {
        // Get frame range
        integer ifmin, ifmax;
        Sampled_getWindowSamples(me, tmin, tmax, &ifmin, &ifmax);
        
        if (ifmax < ifmin) {
            Melder_throw(U"No frames in specified time range [", tmin, U", ", tmax, U"]");
        }
        
        integer nt = ifmax - ifmin + 1;
        double t1 = Sampled_indexToX(me, ifmin);
        
        // Create new Formant with extracted time range
        autoFormant thee = Formant_create(tmin, tmax, nt, me->dx, t1, me->maxnFormants);
        
        // Copy frames
        for (integer iframe = ifmin; iframe <= ifmax; iframe++) {
            integer newFrameNum = iframe - ifmin + 1;
            constFormant_Frame oldFrame = &me->frames[iframe];
            Formant_Frame newFrame = &thy frames[newFrameNum];
            
            newFrame->intensity = oldFrame->intensity;
            newFrame->numberOfFormants = oldFrame->numberOfFormants;
            
            // Copy formants and bandwidths
            for (integer iformant = 1; iformant <= oldFrame->numberOfFormants; iformant++) {
                newFrame->formant[iformant].frequency = oldFrame->formant[iformant].frequency;
                newFrame->formant[iformant].bandwidth = oldFrame->formant[iformant].bandwidth;
            }
        }
        
        return thee;
    } catch (MelderError) {
        Melder_throw(me, U": not extracted.");
    }
}
