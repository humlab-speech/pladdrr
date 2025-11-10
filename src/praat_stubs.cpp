// Stubs for Praat GUI functions
// These are needed for linking but not used in library mode

#include "melder/melder.h"
#include "sys/Interpreter.h"

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

/* End of file */
