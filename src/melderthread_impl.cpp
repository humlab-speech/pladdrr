/*
 * Part of pladdrr: R interface to Praat
 *
 * Copyright (C) 2025 Fredrik Nylén
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */
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
#include "praat.github.io/melder/NUMrandom.h"
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

// NOTE: Matrix_getMean is now provided by Matrix_extensions.cpp - stub removed

void Site_prefs () { /* No-op */ }
void praat_show () { /* No-op */ }

// =============================================================================
// Real multi-threaded MelderThread implementation for pladdrr
// Replaces single-threaded stubs - enables parallel PowerCepstrogram analysis
// Based on praat.github.io/melder/MelderThread.cpp (Paul Boersma, 2025)
// =============================================================================

#include <thread>
#include <vector>
#include <functional>

static struct {
    bool useMultithreading = true;
    integer maximumNumberOfConcurrentThreads = 0;   // 0 = auto
    integer minimumNumberOfElementsPerThread = 0;    // 0 = factory-tuned
    bool traceThreads = false;
} melderthread_prefs;

integer MelderThread_getNumberOfProcessors () {
    return Melder_clippedLeft (1_integer,
        (integer) std::thread::hardware_concurrency ());
}

bool MelderThread_getUseMultithreading () {
    return melderthread_prefs.useMultithreading;
}

integer MelderThread_getMaximumNumberOfConcurrentThreads () {
    if (! melderthread_prefs.useMultithreading)
        return 1;
    if (melderthread_prefs.maximumNumberOfConcurrentThreads <= 0)
        return MelderThread_getNumberOfProcessors ();
    return melderthread_prefs.maximumNumberOfConcurrentThreads;
}

integer MelderThread_getMinimumNumberOfElementsPerThread () {
    if (! melderthread_prefs.useMultithreading)
        return 1;
    if (melderthread_prefs.minimumNumberOfElementsPerThread <= 0)
        return 0;   // signals factory tuning
    return melderthread_prefs.minimumNumberOfElementsPerThread;
}

bool MelderThread_getTraceThreads () {
    return melderthread_prefs.traceThreads;
}

void MelderThread_debugMultithreading (bool useMultithreading,
    integer maximumNumberOfConcurrentThreads,
    integer minimumNumberOfElementsPerThread, bool traceThreads)
{
    melderthread_prefs.useMultithreading = useMultithreading;
    melderthread_prefs.maximumNumberOfConcurrentThreads = maximumNumberOfConcurrentThreads;
    melderthread_prefs.minimumNumberOfElementsPerThread = minimumNumberOfElementsPerThread;
    melderthread_prefs.traceThreads = traceThreads;
}

integer MelderThread_computeNumberOfThreads (
    integer numberOfElements,
    integer thresholdNumberOfElementsPerThread)
{
    if (! MelderThread_getUseMultithreading ())
        return 1;
    integer minimumNumberOfElementsPerThread = MelderThread_getMinimumNumberOfElementsPerThread ();
    if (minimumNumberOfElementsPerThread <= 0)
        minimumNumberOfElementsPerThread = thresholdNumberOfElementsPerThread;
    // macOS-style: round down, first spawned thread is costliest
    integer numberOfThreads = Melder_iroundDown (
        (double) numberOfElements / minimumNumberOfElementsPerThread);
    Melder_clipRight (& numberOfThreads, MelderThread_getMaximumNumberOfConcurrentThreads ());
    Melder_clipRight (& numberOfThreads, NUMrandom_maximumNumberOfParallelThreads);
    Melder_clipLeft (1_integer, & numberOfThreads);
    return numberOfThreads;
}

integer Melder_thisThread_getUniqueID () {
    static std::atomic <integer> uniqueID = 0;
    static thread_local integer thisThread_uniqueID = uniqueID ++;
    return thisThread_uniqueID;
}

static thread_local integer thisThread_firstElement { 0 },
    thisThread_lastElement { 0 }, thisThread_currentElement { 0 };

void Melder_thisThread_setRange (integer firstElement, integer lastElement) {
    thisThread_firstElement = firstElement;
    thisThread_lastElement = lastElement;
}

void Melder_thisThread_setCurrentElement (integer currentElement) {
    thisThread_currentElement = currentElement;
}

double Melder_thisThread_estimateProgress () {
    return (thisThread_currentElement - thisThread_firstElement + 0.5)
        / (thisThread_lastElement - thisThread_firstElement + 1.0);
}

void MelderThread_run (
    std::atomic <bool> *p_errorFlag,
    integer numberOfElements,
    integer thresholdNumberOfElementsPerThread,
    std::function <void (integer, integer, integer)> const& threadFunction)
{
    const integer numberOfThreads = MelderThread_computeNumberOfThreads (
        numberOfElements, thresholdNumberOfElementsPerThread);
    if (numberOfThreads == 1) {
        threadFunction (0, 1, numberOfElements);
    } else {
        const integer numberOfExtraThreads = numberOfThreads - 1;
        std::vector <std::thread> spawns;
        try {
            spawns.resize ((size_t) numberOfExtraThreads);
        } catch (...) {
            Melder_throw (U"Out of memory creating thread vector.");
        }
        const integer base = numberOfElements / numberOfThreads;
        const integer remainder = numberOfElements % numberOfThreads;
        integer firstElement = 1;
        try {
            for (integer ispawn1 = 1; ispawn1 <= numberOfExtraThreads; ispawn1 ++) {
                const integer lastElement = firstElement + base - 1 + ( ispawn1 <= remainder );
                spawns [(size_t)(ispawn1 - 1)] = std::thread (threadFunction, ispawn1, firstElement, lastElement);
                firstElement = lastElement + 1;
            }
        } catch (...) {
            *p_errorFlag = true;
            for (size_t i = 0; i < spawns.size(); i ++)
                if (spawns [i].joinable ())
                    spawns [i].join ();
            Melder_throw (U"Couldn't start a thread.");
        }
        threadFunction (0, firstElement, numberOfElements);
        for (size_t i = 0; i < spawns.size(); i ++)
            spawns [i].join ();
    }
    if (*p_errorFlag) {
        theMelder_error_threadId = Melder_thisThread_getUniqueID ();
        throw MelderError ();
    }
}
