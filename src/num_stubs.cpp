/*
 * Stubs for Fisher distribution and Eigen functions
 * These are needed by some Praat code but not actually called at runtime
 * in our phonetic analysis workflows.
 */

#include "praat.github.io/melder/melder.h"
#include "praat.github.io/sys/Data.h"
#include "praat.github.io/sys/Interpreter.h"
#ifndef PLADDRR_FULL_PRAAT
    #include "praat.github.io/sys/ManPage.h"
    #include "praat.github.io/sys/ManPages.h"
#endif
#include "praat.github.io/fon/Vector.h"
#include "praat.github.io/dwsys/NUMmachar.h"
#include "praat.github.io/dwsys/NUMlapack.h"
#include <atomic>

#ifndef PLADDRR_FULL_PRAAT
// ManPage enum implementations (needed by ManPages class)
#include "praat.github.io/sys/enums_getText.h"
#include "praat.github.io/sys/ManPage_enums.h"
#include "praat.github.io/sys/enums_getValue.h"
#include "praat.github.io/sys/ManPage_enums.h"

// ManPage class implementation (needed by ManPages)
Thing_implement (ManPage, Thing, 0);
#endif

// Melder threading symbols needed for error handling
std::atomic<integer> theMelder_error_threadId (0);

// ManPages class implementation (needed by praat.cpp Thing_recognizeClassesByName)
// Skip if using full praat.cpp which includes real ManPages.cpp
#ifndef PLADDRR_FULL_PRAAT
Thing_implement (ManPages, Daata, 0);

void structManPages :: v9_destroy () noexcept {
    ManPages_Parent :: v9_destroy ();
}

void structManPages :: v1_readText (MelderReadText, int) {
    Melder_throw (U"ManPages reading not supported in library mode.");
}
#endif // PLADDRR_FULL_PRAAT

// NUMfpp initialization - static table for machine constants
static struct structmachar_Table machar_table_static;
static bool numfpp_initialized = false;

// Initialize NUMfpp on first use
void initialize_numfpp() {
    if (numfpp_initialized || NUMfpp != nullptr) return;
    
    NUMfpp = &machar_table_static;
    
    // Initialize using R's LAPACK dlamch function
    NUMfpp->base = (int) NUMlapack_dlamch_("Base");
    NUMfpp->t = (int) NUMlapack_dlamch_("Number of digits in mantissa");
    NUMfpp->emin = (int) NUMlapack_dlamch_("Minimum exponent");
    NUMfpp->emax = (int) NUMlapack_dlamch_("Largest exponent");
    NUMfpp->rnd = (int) NUMlapack_dlamch_("Rounding mode");
    NUMfpp->prec = NUMlapack_dlamch_("Precision");
    NUMfpp->eps = NUMlapack_dlamch_("Epsilon");
    NUMfpp->rmin = NUMlapack_dlamch_("Underflow threshold");
    NUMfpp->sfmin = NUMlapack_dlamch_("Safe minimum");
    NUMfpp->rmax = NUMlapack_dlamch_("Overflow threshold");
    
    numfpp_initialized = true;
}


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

// Note: theForegroundPraatApplication, theCurrentPraatApplication,
// theForegroundPraatObjects, and theCurrentPraatObjects are now
// defined in praat.github.io/sys/praat.cpp (which is being compiled).
// We don't define them here to avoid duplicate symbols.

// Demo mode stubs (GUI-only features not used in library mode)
void Demo_open () {
    Melder_throw (U"Demo_open not available in library mode.");
}

void Demo_close () {
    // No-op in library mode
}

bool Demo_input (conststring32 prompt) {
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

// Vector search functions
enum kVectorSearchDirection { kVectorSearchDirection_NEAREST = 0 };

/* End of file */


double Vector_getNearestLevelCrossing (Vector, integer, double, double, kVectorSearchDirection) {
    Melder_throw (U"Vector_getNearestLevelCrossing not available in this build.");
}


// Matrix statistics function needed by PowerCepstrogram
#include "fon/Matrix.h"

double Matrix_getMean (Matrix me, double xmin, double xmax, double ymin, double ymax) {
    if (xmin >= xmax) {
        xmin = my xmin;
        xmax = my xmax;
    }
    if (ymin >= ymax) {
        ymin = my ymin;
        ymax = my ymax;
    }
    
    // Convert x/y ranges to column/row indices
    integer ixmin = Melder_clippedLeft (integer(1), Matrix_xToNearestColumn (me, xmin));
    integer ixmax = Melder_clippedRight (Matrix_xToNearestColumn (me, xmax), my nx);
    integer iymin = Melder_clippedLeft (integer(1), Matrix_yToNearestRow (me, ymin));
    integer iymax = Melder_clippedRight (Matrix_yToNearestRow (me, ymax), my ny);
    
    if (ixmin > ixmax || iymin > iymax) {
        return undefined;
    }
    
    double sum = 0.0;
    integer count = 0;
    for (integer iy = iymin; iy <= iymax; iy++) {
        for (integer ix = ixmin; ix <= ixmax; ix++) {
            sum += my z [iy] [ix];
            count++;
        }
    }
    
    return count > 0 ? sum / count : undefined;
}
void Site_prefs () { /* No-op */ }
void praat_show () { /* No-op */ }

// Threading stubs
#include <atomic>
#include <functional>

void MelderThread_run (std::atomic<bool> *, long, long, const std::function<void(long, long, long)> &) {
    Melder_throw (U"MelderThread_run not available in library mode.");
}

// Threading range functions
void Melder_thisThread_setRange (long, long) { /* No-op */ }

bool MelderThread_getTraceThreads () { return false; }

integer Melder_thisThread_getUniqueID () { return 1; }

void MelderThread_debugMultithreading (bool, long, long, bool) { /* No-op */ }

integer MelderThread_getNumberOfProcessors () { return 1; }

double Melder_thisThread_estimateProgress () { return 0.0; }

void Melder_thisThread_setCurrentElement (long) { /* No-op */ }
