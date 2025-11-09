/*
 * Stubs for Fisher distribution and Eigen functions
 * These are needed by some Praat code but not actually called at runtime
 * in our phonetic analysis workflows.
 */

#include "melder/melder.h"
#include "sys/Data.h"
#include "sys/Interpreter.h"
#include <atomic>

// Melder threading symbols needed for error handling
std::atomic<integer> theMelder_error_threadId (0);

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

// Demo mode stubs (GUI-only features not used in library mode)
double Demo_input (conststring32 prompt) {
    (void) prompt;
    Melder_throw (U"Demo_input not available in library mode.");
}

void Demo_waitForInput (Interpreter interpreter) {
    (void) interpreter;
    Melder_throw (U"Demo_waitForInput not available in library mode.");
}

bool Demo_clicked () {
    return false;
}

double Demo_x () {
    return 0.0;
}

double Demo_y () {
    return 0.0;
}

bool Demo_keyPressed () {
    return false;
}

char32 Demo_key () {
    return U'\0';
}

int Demo_getKey () {
    return 0;
}

void Demo_peekInput (conststring32 keys) {
    (void) keys;
    // No-op in library mode
}

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

/* Ridders root finding */
double NUMridders (double (*f) (double x, void *closure), double xmin, double xmax, void *closure) {
    (void) f;
    (void) xmin;
    (void) xmax;
    (void) closure;
    Melder_throw (U"Ridders root finding not available in this build.");
}

/* Student's t distribution */
double NUMstudentP (double t, double df) {
    (void) t;
    (void) df;
    Melder_throw (U"Student's t distribution not available in this build.");
}

double NUMstudentQ (double t, double df) {
    (void) t;
    (void) df;
    Melder_throw (U"Student's t Q function not available in this build.");
}

double NUMinvStudentQ (double q, double df) {
    (void) q;
    (void) df;
    Melder_throw (U"Inverse Student's t Q function not available in this build.");
}

/* Inverse Gaussian distribution (only inverses, P/Q are in NUMspecfunc) */
double NUMinvGaussQ (double q) {
    (void) q;
    Melder_throw (U"Inverse Gaussian Q function not available in this build.");
}

/* Inverse Chi-square distribution (only inverses, P/Q are in NUMspecfunc) */
double NUMinvChiSquareQ (double q, double df) {
    (void) q;
    (void) df;
    Melder_throw (U"Inverse chi-square Q function not available in this build.");
}

/* End of file */
