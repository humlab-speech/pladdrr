// lpc_clapack_stubs.cpp
// Stubs for LPC functions that require CLAPACK (Roots, LPC_to_Formant, etc.)
// These are disabled to avoid the CLAPACK dependency

#include "praat.github.io/LPC/LPC.h"
#include "praat.github.io/fon/Formant.h"
#include "praat.github.io/dwsys/Roots.h"

// Stub for LPC_to_Formant (requires Roots which needs CLAPACK)
autoFormant LPC_to_Formant (constLPC me, double margin) {
    Melder_throw (U"LPC_to_Formant is not available in this build.\n"
                  U"Use Sound$to_formant_burg() instead for formant extraction.");
}

// Stub for Roots_into_Formant_Frame (requires CLAPACK)
void Roots_into_Formant_Frame (constRoots me, Formant_Frame thee, double samplingFrequency, double margin) {
    Melder_throw (U"Roots_into_Formant_Frame is not available in this build (requires CLAPACK).");
}

/* End of file */
