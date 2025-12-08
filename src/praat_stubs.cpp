// Stubs for Praat GUI functions
// These are needed for linking but not used in library mode

#include "melder/melder.h"
#include "sys/Interpreter.h"
#include "fon/Sound.h"
#include "fon/PointProcess.h"

// Forward declare GUI types
struct structGuiWindow;
struct structEditor;
typedef int kUi_realVectorFormat;
typedef int kUi_integerVectorFormat;
typedef structGuiWindow* GuiWindow;
typedef structEditor* Editor;

// GUI stub - called by some Praat functions to update display
void praat_show () {
    // No-op in library mode (no GUI)
}

void praat_updateSelection () {
    // No-op in library mode  
}

void praat_dataChanged (void *) {
    // No-op in library mode
}

void praat_select (integer) {
    // No-op in library mode
}

void praat_deselect (integer) {
    // No-op in library mode
}

void praat_deselectAll () {
    // No-op in library mode
}

void praat_selectAll () {
    // No-op in library mode
}

// Praat action/command stubs
void praat_doAction (conststring32, integer, Stackel, Interpreter) {
    // No-op in library mode
}

void praat_doCommand (conststring32, integer, Stackel, Interpreter) {
    // No-op in library mode
}

void praat_runScript (conststring32, integer, Stackel, Editor) {
    // No-op in library mode
}

// UI Pause stubs (interactive dialogs) - matching UiPause.h signatures
void UiPause_begin (GuiWindow, Editor, conststring32, Interpreter) {
    // No-op
}

void UiPause_comment (conststring32) {
    // No-op
}

void UiPause_heading (conststring32) {
    // No-op
}

void UiPause_real (conststring32, conststring32) {
    // No-op
}

void UiPause_positive (conststring32, conststring32) {
    // No-op
}

void UiPause_integer (conststring32, conststring32) {
    // No-op
}

void UiPause_natural (conststring32, conststring32) {
    // No-op
}

void UiPause_word (conststring32, conststring32) {
    // No-op
}

void UiPause_sentence (conststring32, conststring32) {
    // No-op
}

void UiPause_text (conststring32, conststring32, integer) {
    // No-op
}

void UiPause_boolean (conststring32, bool) {
    // No-op
}

void UiPause_infile (conststring32, conststring32, integer) {
    // No-op
}

void UiPause_outfile (conststring32, conststring32, integer) {
    // No-op
}

void UiPause_folder (conststring32, conststring32, integer) {
    // No-op
}

void UiPause_realvector (conststring32, kUi_realVectorFormat, conststring32, integer) {
    // No-op
}

void UiPause_positivevector (conststring32, kUi_realVectorFormat, conststring32, integer) {
    // No-op
}

void UiPause_integervector (conststring32, kUi_integerVectorFormat, conststring32, integer) {
    // No-op
}

void UiPause_naturalvector (conststring32, kUi_integerVectorFormat, conststring32, integer) {
    // No-op
}

void UiPause_choice (conststring32, int) {
    // No-op
}

void UiPause_optionmenu (conststring32, int) {
    // No-op
}

void UiPause_option (conststring32) {
    // No-op
}

int UiPause_end (int, int, int, conststring32, conststring32, conststring32, 
                  conststring32, conststring32, conststring32, conststring32,
                  conststring32, conststring32, conststring32, Interpreter) {
    Melder_throw (U"Interactive pause dialogs not available in library mode.");
}

// Forward declare GUI types
struct structGuiWindow;
struct structEditor;

// GuiTrust stubs (secure dialog prompts)
int GuiTrust_get (structGuiWindow *, structEditor *, conststring32, conststring32, conststring32,
                  conststring32, conststring32, conststring32, conststring32,
                  conststring32, conststring32, conststring32, Interpreter) {
    Melder_throw (U"Secure trust dialogs not available in library mode.");
}

// MelderFile_close and MelderFile_create now provided by MelderFile.cpp (not stubs)

// Stub for threading functions (used by Praat's parallel processing)
void MelderThread_run (std::atomic<bool> *p_errorFlag, integer numberOfElements, integer thresholdNumberOfElementsPerThread, const std::function<void(integer, integer, integer)>& threadFunction) {
    // Single-threaded execution for library mode
    // Call the function once for all elements (thread 0, elements 1 to numberOfElements)
    fprintf(stderr, "STUB MelderThread_run: calling threadFunction(0, 1, %ld)\n", (long)numberOfElements); fflush(stderr);
    try {
        threadFunction(0, 1, numberOfElements);
        fprintf(stderr, "STUB MelderThread_run: threadFunction returned successfully\n"); fflush(stderr);
    } catch (MelderError) {
        fprintf(stderr, "STUB MelderThread_run: MelderError caught\n"); fflush(stderr);
        if (p_errorFlag) *p_errorFlag = true;
        Melder_throw(U"Error in parallel computation");
    } catch (std::exception& e) {
        fprintf(stderr, "STUB MelderThread_run: std::exception caught: %s\n", e.what()); fflush(stderr);
        if (p_errorFlag) *p_errorFlag = true;
        Melder_throw(U"C++ exception in parallel computation");
    } catch (...) {
        fprintf(stderr, "STUB MelderThread_run: unknown exception caught\n"); fflush(stderr);
        if (p_errorFlag) *p_errorFlag = true;
        Melder_throw(U"Unknown exception in parallel computation");
    }
    // If the function set the error flag, throw
    if (p_errorFlag && *p_errorFlag) {
        Melder_throw(U"Error flag set in parallel computation");
    }
}

void praat_runNotebook (const char32_t *, long, structStackel *, structEditor *) {
    // Notebook execution not supported in library mode
}

integer praat_idOfSelected (ClassInfo, integer) {
    Melder_throw (U"Object selection not available in library mode.");
}

void praat_removeObject (integer) {
    Melder_throw (U"Object removal not available in library mode.");
}

void praat_doMenuCommand (conststring32, integer, Stackel, Interpreter) {
    Melder_throw (U"Menu commands not available in library mode.");
}

void Editor_doMenuCommand (Editor, conststring32, integer, Stackel, conststring32, Interpreter) {
    Melder_throw (U"Editor menu commands not available in library mode.");
}

void _Preferences_addEnum (conststring32, int *, int, int, conststring32 (*)(int), int (*)(conststring32), int) {
    // Preferences system not available in library mode - do nothing
}

void praat_executeCommand (Interpreter, char32_t *) {
    Melder_throw (U"Script execution not available in library mode.");
}

Editor praat_findEditorById (integer) {
    Melder_throw (U"Editor lookup not available in library mode.");
}

conststring32 praat_nameOfSelected (ClassInfo, integer) {
    Melder_throw (U"Object name lookup not available in library mode.");
}

autoINTVEC praat_idsOfAllSelected (ClassInfo) {
    Melder_throw (U"Object selection not available in library mode.");
}

autoSTRVEC praat_namesOfAllSelected (ClassInfo) {
    Melder_throw (U"Object selection not available in library mode.");
}

integer praat_numberOfSelected (ClassInfo) {
    Melder_throw (U"Object selection not available in library mode.");
}

void praat_runScriptWithForm (conststring32) {
    Melder_throw (U"Script execution not available in library mode.");
}

void praat_new (autoDaata) {
    Melder_throw (U"Object creation not available in library mode.");
}

void praat_newWithFile (autoDaata, MelderFile, conststring32) {
    Melder_throw (U"Object creation not available in library mode.");
}

Daata praat_onlyObject (ClassInfo) {
    Melder_throw (U"Object selection not available in library mode.");
}

autoCollection praat_getSelectedObjects () {
    Melder_throw (U"Object selection not available in library mode.");
}

// Speech synthesis stubs (espeak integration)
struct structSpeechSynthesizer;
typedef structSpeechSynthesizer* SpeechSynthesizer;
typedef structSpeechSynthesizer* autoSpeechSynthesizer;

autoSpeechSynthesizer SpeechSynthesizer_create (conststring32, conststring32) {
    Melder_throw (U"Speech synthesis not available in this build.");
}

/* End of file */

// Threading stubs
void Melder_thisThread_setRange (integer, integer) {
    // No-op - threading disabled in library mode
}


Editor praat_findEditorFromString (conststring32) {
    Melder_throw (U"Editor lookup not available in library mode.");
}


bool MelderThread_getTraceThreads () {
    return false;  // Threading disabled in library mode
}

integer Melder_thisThread_getUniqueID () {
    return 0;  // Single-threaded mode
}

double Melder_thisThread_estimateProgress () {
    return 0.0;  // No progress tracking in library mode
}

void Melder_thisThread_setCurrentElement (integer) {}

// Voice analysis stubs
struct structAmplitudeTier;
typedef structAmplitudeTier* AmplitudeTier;
typedef structAmplitudeTier* autoAmplitudeTier;

autoAmplitudeTier PointProcess_Sound_to_H1minusH2Tier (PointProcess, Sound, double, double, double, double, double) {
    Melder_throw (U"PointProcess_Sound_to_H1minusH2Tier: Voice quality analysis not available.");
}

struct structTextInterval;
typedef structTextInterval* TextInterval;

void SpeechSynthesizer_Sound_TextInterval_align (SpeechSynthesizer, Sound, TextInterval, double, double, double) {
    Melder_throw (U"SpeechSynthesizer_Sound_TextInterval_align: Speech synthesis not available.");
}

bool praat_commandsWithExternalSideEffectsAreAllowed () {
    return false;  // External side effects disabled in library mode
}

// Portable character classification stubs
extern "C" {
int iswlower_portable (int) { return 0; }
int iswupper_portable (int) { return 0; }
int iswalpha_portable (int) { return 0; }
int iswdigit_portable (int) { return 0; }
int iswspace_portable (int) { return 0; }
int towlower_portable (int c) { return c; }
int towupper_portable (int c) { return c; }
}

// Additional multithreading stubs
void MelderThread_debugMultithreading (bool useMultithreading, integer numberOfConcurrentThreadsToUse,
	integer minimumNumberOfElementsPerThread, bool extraAnalysisInfo) {
	// No-op in library mode (no debug UI)
}

integer MelderThread_getNumberOfProcessors () {
	return 1;  // Single-threaded mode
}

bool MelderThread_getUseMultithreading () {
	return false;  // Disable multithreading in library mode
}
