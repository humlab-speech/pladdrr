/* DTW stubs - Dynamic Time Warping not implemented */
/* DTW is used for some advanced Praat features but not required for AVQI/DSI */

#include "praat.github.io/dwtools/DTW.h"
#include "praat.github.io/fon/Matrix.h"

/* Stub all DTW functions to throw not-implemented errors */

autoDTW DTW_create (double, double, integer, double, double,
                     double, double, integer, double, double) {
    Melder_throw (U"DTW is not implemented in the speaker package.");
}

void DTW_setWeights (DTW, double, double, double) {
    Melder_throw (U"DTW is not implemented in the speaker package.");
}

autoDTW DTW_swapAxes (DTW) {
    Melder_throw (U"DTW is not implemented in the speaker package.");
}

void DTW_findPath_bandAndSlope (DTW, double, int, autoMatrix *) {
    Melder_throw (U"DTW is not implemented in the speaker package.");
}

void DTW_findPath (DTW, bool, bool, int) {
    Melder_throw (U"DTW is not implemented in the speaker package.");
}

void DTW_Path_recode (DTW) {
    Melder_throw (U"DTW is not implemented in the speaker package.");
}

double DTW_getYTimeFromXTime (DTW, double) {
    Melder_throw (U"DTW is not implemented in the speaker package.");
}

double DTW_getXTimeFromYTime (DTW, double) {
    Melder_throw (U"DTW is not implemented in the speaker package.");
}

double DTW_getPathY (DTW, double) {
    Melder_throw (U"DTW is not implemented in the speaker package.");
}

integer DTW_getMaximumConsecutiveSteps (DTW, int) {
    Melder_throw (U"DTW is not implemented in the speaker package.");
}

void DTW_pathRemoveRedundantNodes (DTW) {
    Melder_throw (U"DTW is not implemented in the speaker package.");
}

void DTW_pathQueryRecode (DTW) {
    Melder_throw (U"DTW is not implemented in the speaker package.");
}
