/*
 * Stubs for Fisher distribution and Eigen functions
 * These are needed by some Praat code but not actually called at runtime
 * in our phonetic analysis workflows.
 */

#include "melder/melder.h"
#include "sys/Data.h"

// Forward declare types
struct structManPages;
struct structEditor;

// Minimal PraatApplication structure - only what's needed for linking
struct structPraatApplication {
    structManPages *manPages;
    // Minimal fields
};

typedef struct structPraatApplication *PraatApplication;

// Minimal PraatObjects structure
struct structPraatObjects {
    int n;
    // Minimal fields
};

typedef struct structPraatObjects *PraatObjects;

// Provide the global variables that Formula.cpp and other code references
structPraatApplication theForegroundPraatApplication = { nullptr };
PraatApplication theCurrentPraatApplication = &theForegroundPraatApplication;

structPraatObjects theForegroundPraatObjects = { 0 };
PraatObjects theCurrentPraatObjects = &theForegroundPraatObjects;

// Eigen class stub - prevents linker errors for Matrix eigen decomposition
// which we don't use in phonetic analysis
Thing_define (Eigen, Daata) {
    // Empty - no fields needed for stub
};

Thing_implement (Eigen, Daata, 0);

/* Fisher's F distribution cumulative probability */
double NUMfisherP (double f, double df1, double df2) {
    (void) f;
    (void) df1;
    (void) df2;
    Melder_throw (U"Fisher P distribution function not available in this build.");
}

/* Fisher's F distribution Q function (complement of P) */
double NUMfisherQ (double f, double df1, double df2) {
    (void) f;
    (void) df1;
    (void) df2;
    Melder_throw (U"Fisher Q distribution function not available in this build.");
}

/* Inverse Fisher Q function */
double NUMinvFisherQ (double q, double df1, double df2) {
    (void) q;
    (void) df1;
    (void) df2;
    Melder_throw (U"Inverse Fisher Q function not available in this build.");
}

/* Random gamma variate */
double NUMrandomGamma (double shape, double scale) {
    (void) shape;
    (void) scale;
    Melder_throw (U"Random gamma function not available in this build.");
}

/* End of file */
