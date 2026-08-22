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
// UiForm subsystem stubs for NO_GUI builds
// UiForm_create, UiForm_addXXX, UiForm_finish, UiForm_call, UiForm_parseString
// are now provided by uiform_libmode.cpp

#include "praat.github.io/melder/melder.h"

// Forward declarations - minimal types needed
typedef char32_t char32;
typedef const char32 *conststring32;

struct structUiForm;
typedef struct structUiForm *UiForm;

struct structUiField;
typedef struct structUiField *UiField;

struct structGuiWindow;
typedef struct structGuiWindow *GuiWindow;

struct structEditor;
typedef struct structEditor *Editor;

struct structStackel;
typedef struct structStackel *Stackel;

struct structInterpreter;
typedef struct structInterpreter *Interpreter;

// ============================================================================
// Functions NOT in uiform_libmode.cpp (GUI-only functionality)
// ============================================================================

// Getter functions (return empty values in library mode)
// Whole file excluded from coverage measurement via .covrignore (see repo root).
conststring32 UiForm_getString (UiForm, conststring32) { return U""; }
integer UiForm_getInteger (UiForm, conststring32) { return 0; }
double UiForm_getReal (UiForm, conststring32) { return 0.0; }
double UiForm_getReal_check (UiForm, conststring32) { return 0.0; }
bool UiForm_getBoolean (UiForm, conststring32) { return false; }
constVEC UiForm_getRealVector (UiForm, conststring32) { return constVEC(); }
constINTVEC UiForm_getIntegerVector (UiForm, conststring32) { return constINTVEC(); }
integer UiForm_getInteger_check (UiForm, conststring32) { return 0; }
conststring32 UiForm_getString_check (UiForm, conststring32) { return U""; }

// Interactive form display (not available in library mode)
void UiForm_do (UiForm, bool) {}
void UiForm_showAndWait (UiForm) {
    Melder_throw (U"UiForm_showAndWait not available in library mode.");
}

// ============================================================================
// Demo Editor stubs (for Demo namespace functions used by Formula.cpp)
// ============================================================================

bool Demo_clickedIn (double, double, double, double) { return false; }
int Demo_peekInput (Interpreter) { return 0; }
void Demo_windowTitle (conststring32) {}
bool Demo_shiftKeyPressed () { return false; }
bool Demo_optionKeyPressed () { return false; }
bool Demo_commandKeyPressed () { return false; }
void Demo_show () {}

// ============================================================================
// UiPause stubs (interactive pauses not available in library mode)
// ============================================================================

// Define minimal enums for UI vector formats
enum kUi_realVectorFormat { kUi_realVectorFormat_WHITESPACE_SEPARATED = 1 };
enum kUi_integerVectorFormat { kUi_integerVectorFormat_WHITESPACE_SEPARATED = 1 };

void UiPause_realvector (conststring32, kUi_realVectorFormat, conststring32, integer) {}
void UiPause_positivevector (conststring32, kUi_realVectorFormat, conststring32, integer) {}
void UiPause_integervector (conststring32, kUi_integerVectorFormat, conststring32, integer) {}
void UiPause_naturalvector (conststring32, kUi_integerVectorFormat, conststring32, integer) {}

void UiPause_begin (GuiWindow, Editor, conststring32, Interpreter) {
    Melder_throw (U"UiPause_begin (pause command) not available in library mode.");
}

int UiPause_end (int, int, int, conststring32, conststring32, conststring32,
                 conststring32, conststring32, conststring32, conststring32,
                 conststring32, conststring32, conststring32, structInterpreter *) {
    Melder_throw (U"UiPause_end (pause command) not available in library mode.");
}

double UiPause_real (conststring32, conststring32) {
    Melder_throw (U"UiPause_real not available in library mode.");
}

conststring32 UiPause_text (conststring32, conststring32, integer) {
    Melder_throw (U"UiPause_text not available in library mode.");
}

integer UiPause_integer (conststring32, conststring32, integer) {
    Melder_throw (U"UiPause_integer not available in library mode.");
}

conststring32 UiPause_choice (conststring32, int) {
    Melder_throw (U"UiPause_choice not available in library mode.");
}

int UiPause_boolean (conststring32, int) {
    Melder_throw (U"UiPause_boolean not available in library mode.");
}

void UiPause_comment (conststring32) {}

conststring32 UiPause_word (conststring32, conststring32) {
    Melder_throw (U"UiPause_word not available in library mode.");
}

conststring32 UiPause_folder (conststring32, conststring32, integer) {
    Melder_throw (U"UiPause_folder not available in library mode.");
}

conststring32 UiPause_infile (conststring32, conststring32, integer) {
    Melder_throw (U"UiPause_infile not available in library mode.");
}

conststring32 UiPause_outfile (conststring32, conststring32, integer) {
    Melder_throw (U"UiPause_outfile not available in library mode.");
}

conststring32 UiPause_word (conststring32, conststring32, integer) {
    Melder_throw (U"UiPause_word not available in library mode.");
}

conststring32 UiPause_sentence (conststring32, conststring32, integer) {
    Melder_throw (U"UiPause_sentence not available in library mode.");
}

void UiPause_optionmenu (conststring32, int) {}
void UiPause_radio (conststring32, int) {}
void UiPause_list (conststring32, integer) {}
void UiPause_label (conststring32) {}
void UiPause_option (conststring32) {}

bool UiPause_boolean (conststring32, bool) {
    Melder_throw (U"UiPause_boolean not available in library mode.");
}

integer UiPause_natural (conststring32, conststring32, integer) {
    Melder_throw (U"UiPause_natural not available in library mode.");
}

double UiPause_positive (conststring32, conststring32, integer) {
    Melder_throw (U"UiPause_positive not available in library mode.");
}

conststring32 UiPause_heading (conststring32) { return U""; }
conststring32 UiPause_caption (conststring32) { return U""; }
void UiPause_choice (conststring32) {}

double UiPause_real_check (conststring32, conststring32, integer) {
    Melder_throw (U"UiPause_real_check not available in library mode.");
}

integer UiPause_natural_check (conststring32, conststring32, integer) {
    Melder_throw (U"UiPause_natural_check not available in library mode.");
}

integer UiPause_integer_check (conststring32, conststring32, integer) {
    Melder_throw (U"UiPause_integer_check not available in library mode.");
}

double UiPause_positive_check (conststring32, conststring32, integer) {
    Melder_throw (U"UiPause_positive_check not available in library mode.");
}

conststring32 UiPause_word_check (conststring32, conststring32, integer) {
    Melder_throw (U"UiPause_word_check not available in library mode.");
}

conststring32 UiPause_sentence_check (conststring32, conststring32, integer) {
    Melder_throw (U"UiPause_sentence_check not available in library mode.");
}

conststring32 UiPause_text_check (conststring32, conststring32, integer) {
    Melder_throw (U"UiPause_text_check not available in library mode.");
}

integer UiPause_integer (conststring32, conststring32) {
    Melder_throw (U"UiPause_integer not available in library mode.");
}

integer UiPause_natural (conststring32, conststring32) {
    Melder_throw (U"UiPause_natural not available in library mode.");
}

double UiPause_positive (conststring32, conststring32) {
    Melder_throw (U"UiPause_positive not available in library mode.");
}

conststring32 UiPause_sentence (conststring32, conststring32) {
    Melder_throw (U"UiPause_sentence not available in library mode.");
}

// ============================================================================
// GUI file selection stubs
// ============================================================================

conststring32 GuiFileSelect_getFolderName (GuiWindow, conststring32) {
    Melder_throw (U"File selection dialogs not available in NO_GUI build.");
}

autoSTRVEC GuiFileSelect_getInfileNames (GuiWindow, conststring32, bool) {
    Melder_throw (U"File selection dialogs not available in NO_GUI build.");
}

conststring32 GuiFileSelect_getOutfileName (GuiWindow, conststring32, conststring32) {
    Melder_throw (U"File selection dialogs not available in NO_GUI build.");
}

conststring32 GuiFileSelect_getInfileName (GuiWindow, conststring32, bool) {
    Melder_throw (U"File selection dialogs not available in NO_GUI build.");
}

// ============================================================================
// Enum conversion functions
// ============================================================================

kUi_realVectorFormat kUi_realVectorFormat_getValue (conststring32) {
    return kUi_realVectorFormat_WHITESPACE_SEPARATED;
}

kUi_integerVectorFormat kUi_integerVectorFormat_getValue (conststring32) {
    return kUi_integerVectorFormat_WHITESPACE_SEPARATED;
}

// ============================================================================
// GUI Trust dialog
// ============================================================================

int GuiTrust_get (...) {
    Melder_throw (U"GuiTrust_get not available in library mode.");
}

int GuiTrust_get (structGuiWindow *, structEditor *, conststring32, conststring32,
                  conststring32, conststring32, conststring32, conststring32,
                  conststring32, conststring32, conststring32, conststring32,
                  structInterpreter *) {
    Melder_throw (U"GuiTrust_get not available in library mode.");
}

// ============================================================================
// GuiThing functions
// ============================================================================

struct structGuiThing;
void GuiThing_show (structGuiThing *) {}
void GuiThing_hide (structGuiThing *) {}
void GuiThing_setSensitive (structGuiThing *, int) {}

// ============================================================================
// UiFile functions
// ============================================================================

MelderFile UiFile_getFile (structUiForm *) {
    Melder_throw (U"UiFile_getFile not available.");
}

conststring32 UiFile_getFile (structUiForm *, conststring32) {
    Melder_throw (U"UiFile_getFile not available.");
}

// ============================================================================
// Editor-related stubs
// ============================================================================

struct structDataEditor;
void DataEditor_create (conststring32, void *) {
    Melder_throw (U"DataEditor_create not available.");
}

// ============================================================================
// GuiWindow creation
// ============================================================================

GuiWindow GuiWindow_create (int, int, int, int, int, int, conststring32,
                            MelderCallback<void, structThing>, structThing *, unsigned int) {
    return nullptr;
}

// ============================================================================
// GuiList functions
// ============================================================================

struct structGuiList;
struct structGuiList_SelectionChangedEvent;

void GuiList_setSelectionChangedCallback (structGuiList *,
    MelderCallback<void, structThing, structGuiList_SelectionChangedEvent *>,
    structThing *)
{}

// ============================================================================
// Preferences
// ============================================================================

void Ui_prefs () {}

struct structEditor { static void f_preferences(); };
void structEditor::f_preferences() {}

struct structDataGui { static void f_preferences(); };
void structDataGui::f_preferences() {}

struct structHyperPage { static void f_preferences(); };
void structHyperPage::f_preferences() {}

struct structManual { static void f_preferences(); };
void structManual::f_preferences() {}

struct structTextEditor { static void f_preferences(); };
void structTextEditor::f_preferences() {}

struct structScriptEditor { static void f_preferences(); };
void structScriptEditor::f_preferences() {}

// ============================================================================
// UiInfile/UiOutfile stubs
// ============================================================================

void UiInfile_do (UiForm) {}

void UiFile_addHistory (conststring32) {}

UiForm UiInfile_create (GuiWindow, Editor, conststring32,
    void (*)(UiForm, integer, Stackel, conststring32, Interpreter, conststring32, bool, void *, Editor),
    void *, conststring32, conststring32, bool) {
    return nullptr;
}

void UiOutfile_create (structGuiWindow *, structEditor *, conststring32,
                       void (*)(structUiForm*, integer, structStackel*, conststring32,
                               structInterpreter*, conststring32, bool, void*, structEditor*),
                       void *, conststring32, conststring32) {}

// ============================================================================
// UiForm setter stubs
// ============================================================================

void UiForm_setReal (structUiForm *, double *, double) {}
void UiForm_setBoolean (structUiForm *, bool *, bool) {}
void UiForm_setInteger (structUiForm *, integer *, integer) {}
void UiForm_setOption (structUiForm *, int *, int) {}
void UiForm_setOptionMenuStr (structUiForm *, const char32 *, const char32 *) {}
void UiForm_addIntegerOrLabeledRadioButtons (structUiForm *, integer *, const char32 *, const char32 *, integer, const char32 *) {}
