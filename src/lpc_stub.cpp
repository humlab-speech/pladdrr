/*
 * LPC stub - provides minimal stub implementations for LPC functions
 * LPC is not currently exposed in the R API but is referenced by Praat internals
 */

#include "melder/melder.h"
#include "fon/Sampled.h"
#include "fon/Sound.h"

// Forward declaration of LPC
#define LPC_STUB_ONLY
Thing_declare (LPC);

// LPC_Frame structure stub
struct structLPC_Frame {
    integer nCoefficients;
};

// LPC is based on Sampled
Thing_define (LPC, Sampled) {
    double samplingPeriod;
    integer maxnCoefficients;
};

Thing_implement (LPC, Sampled, 0);

// Stub implementations for LPC functions (throw errors if called)
autoLPC Sound_to_LPC_auto (constSound me, int predictionOrder, double effectiveAnalysisWidth, double dt, double preEmphasisFrequency) {
    Melder_throw (U"Sound_to_LPC_auto not implemented in this build.");
}

autoLPC Sound_to_LPC_covariance (constSound me, int predictionOrder, double effectiveAnalysisWidth, double dt, double preEmphasisFrequency) {
    Melder_throw (U"Sound_to_LPC_covariance not implemented in this build.");
}

autoLPC Sound_to_LPC_burg (constSound me, int predictionOrder, double effectiveAnalysisWidth, double dt, double preEmphasisFrequency) {
    Melder_throw (U"Sound_to_LPC_burg not implemented in this build.");
}

autoLPC Sound_to_LPC_marple (constSound me, int predictionOrder, double effectiveAnalysisWidth, double dt, double preEmphasisFrequency, double tol1, double tol2) {
    Melder_throw (U"Sound_to_LPC_marple not implemented in this build.");
}

autoSound LPC_Sound_filter (constLPC me, constSound thee, bool useGain) {
    Melder_throw (U"LPC_Sound_filter not implemented in this build.");
}

/* End of file */
