/*
 * LPC stub - provides class definition for Linear Predictive Coding
 * LPC is used internally by some Praat algorithms but not exposed in our API
 */

#include "melder/melder.h"
#include "fon/Sampled.h"

// LPC_Frame structure stub
struct structLPC_Frame {
    integer nCoefficients;
    // Empty stub - only for compilation
};

// LPC is based on Sampled
Thing_define (LPC, Sampled) {
    double samplingPeriod;
    integer maxnCoefficients;
    // Simplified - actual has structvec of frames
};

Thing_implement (LPC, Sampled, 0);

/* End of file */
