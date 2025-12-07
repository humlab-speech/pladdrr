/*
 * Stubs for Fisher distribution and Eigen functions
 * These are needed by some Praat code but not actually called at runtime
 * in our phonetic analysis workflows.
 */

#include "melder/melder.h"
#include "sys/Data.h"
#include "sys/Interpreter.h"
#include "fon/Vector.h"
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

/* End of file */

// Vector search functions
enum kVectorSearchDirection { kVectorSearchDirection_NEAREST = 0 };

double Vector_getNearestLevelCrossing (Vector, integer, double, double, kVectorSearchDirection) {
    Melder_throw (U"Vector_getNearestLevelCrossing not available in this build.");
}

void NUMmachar () {
    // Machine characteristics - no-op in library mode
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
