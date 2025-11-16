// lpc_clapack_stubs.cpp
// Stubs for LPC functions that require CLAPACK
// LPC_to_Formant is now compiled from actual Praat source

#include "praat.github.io/dwsys/Roots.h"
#include "praat.github.io/fon/Formant.h"

// Stub for Roots_into_Formant_Frame (requires CLAPACK)
// Note: LPC_to_Formant calls this, so we provide a stub that will throw an error
void Roots_into_Formant_Frame (constRoots me, Formant_Frame thee, double samplingFrequency, double margin) {
    Melder_throw (U"Roots_into_Formant_Frame is not available in this build (requires CLAPACK).");
}

/* End of file */
