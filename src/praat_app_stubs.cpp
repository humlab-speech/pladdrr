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
 * Stubs for Praat application/GUI functions
 * These are needed by praat.cpp and praat_script.cpp when compiled
 * but not actually used in library mode.
 * 
 * REMOVED DUPLICATES (2025-12-20):
 * - Site_prefs() - already in melderthread_impl.cpp
 * - praat_show() - already in melderthread_impl.cpp
 * - UiForm_do(), UiForm_finish(), UiForm_addComment() - already in uiform_stubs.cpp  
 * - folderNames_STRVEC() - provided by real Praat (STRVEC.o)
 * - quote_doubleSTR() - provided by real Praat (STR.o)
 * - praat_executeCommandFromStandardInput() - provided by real Praat (praat_script.o)
 * - ManPages_create() - provided by real Praat (ManPages.o)
 * - Interpreter_getArgumentsFromDialog() - provided by real Praat (Interpreter.o)
 */

#include "praat.github.io/melder/melder.h"
#include "praat.github.io/sys/Interpreter.h"
#include "praat.github.io/sys/ManPages.h"

// Forward declarations
struct structUiForm;
struct structGuiWindow;
struct structGuiList;
struct structGuiForm;
struct structStackel;
struct structEditor;

// REMOVED: Site_prefs() - already in melderthread_impl.cpp

// Graphics preferences
void Graphics_prefs () { /* No-op */ }
void Printer_prefs () { /* No-op */ }

// App control
// REMOVED: praat_show() - already in melderthread_impl.cpp
// REMOVED: praat_background, praat_foreground - now in praat_actions.cpp

// Picture functions
void praat_picture_init (bool) { /* No-op */ }
void praat_picture_exit () { /* No-op */ }
void praat_picture_prefs () { /* No-op */ }
void praat_picture_prefsChanged () { /* No-op */ }

// Statistics functions
void praat_statistics_exit () { /* No-op */ }
void praat_statistics_prefs () { /* No-op */ }
void praat_statistics_prefsChanged () { /* No-op */ }

// Menu/action functions
void praat_addMenus (structGuiWindow *) { /* No-op */ }
void praat_addMenus2 () { /* No-op */ }
// REMOVED: praat_sortActions, praat_sortMenuCommands - now in praat_actions.cpp/praat_menuCommands.cpp
void praat_addFixedButtons (structGuiWindow *) { /* No-op */ }
// REMOVED: praat_actions_exit_optimizeByLeaking, praat_menuCommands_exit_optimizeByLeaking - now in real files
void Preferences_exit_optimizeByLeaking () { /* No-op */ }

// UiForm functions
void UiForm_info (structUiForm *, integer) {
    Melder_throw (U"UiForm_info not available in library mode.");
}

// REMOVED: UiForm_do() - already in uiform_stubs.cpp
// REMOVED: UiForm_finish() - already in uiform_stubs.cpp
// REMOVED: UiForm_addComment() - already in uiform_stubs.cpp

void UiForm_destroyWhenUnmanaged (structUiForm *) { /* No-op */ }

void UiForm_setString (structUiForm *, conststring32 *, conststring32) { /* No-op */ }

void UiOutfile_do (structUiForm *, conststring32) {
    Melder_throw (U"UiOutfile_do not available in library mode.");
}

structUiForm * Interpreter_createForm (structInterpreter *, structGuiWindow *, structEditor *,
    conststring32, void (*) (structUiForm *, integer, structStackel *, constInterpreter, conststring32, Interpreter, conststring32, bool, void *), void *, bool)
{
    Melder_throw (U"Interpreter_createForm not available in library mode.");
}

// REMOVED: Interpreter_getArgumentsFromDialog() - provided by real Praat (Interpreter.o)

// Gui functions
structGuiList * GuiList_create (structGuiForm *, int, int, int, int, bool, conststring32) {
    Melder_throw (U"GuiList_create not available in library mode.");
}

void GuiList_deleteItem (structGuiList *, integer) { /* No-op */ }
void GuiList_insertItem (structGuiList *, conststring32, integer) { /* No-op */ }
void GuiList_selectItem (structGuiList *, integer) { /* No-op */ }
void GuiList_deselectItem (structGuiList *, integer) { /* No-op */ }
void GuiList_replaceItem (structGuiList *, conststring32, integer) { /* No-op */ }

autoINTVEC GuiList_getSelectedPositions (structGuiList *) {
    Melder_throw (U"GuiList_getSelectedPositions not available in library mode.");
}

structGuiLabel * GuiLabel_createShown (structGuiForm *, int, int, int, int, conststring32, unsigned int) {
    Melder_throw (U"GuiLabel_createShown not available in library mode.");
}

void GuiWindow_addMenuBar (structGuiWindow *) { /* No-op */ }

void Gui_injectMessageProcs (structGuiWindow *) { /* No-op */ }

void Gui_getWindowPositioningBounds (double *, double *, double *, double *) { /* No-op */ }

// Machine functions
void Machine_initLookAndFeel (int, char **) { /* No-op */ }
int Machine_getMenuBarBottom () { return 0; }

// REMOVED: ManPages_create() - provided by real Praat (ManPages.o)

// UiHistory
void UiHistory_write (conststring32) { /* No-op */ }
void UiHistory_write_expandQuotes (conststring32) { /* No-op */ }

// REMOVED: folderNames_STRVEC() - provided by real Praat (STRVEC.o)
// REMOVED: quote_doubleSTR() - provided by real Praat (STR.o)

// REMOVED: praat_actions_createDynamicMenu - now in praat_actions.cpp

// REMOVED: praat_executeCommandFromStandardInput() - provided by real Praat (praat_script.o)

void NotebookEditors_dirty () { /* No-op */ }
void InfoEditor_injectInformationProc () { /* No-op */ }

/* End of praat_app_stubs.cpp */

// Manual and help system
struct structManual;
typedef struct structManual *Manual;

Manual Manual_create (conststring32, structInterpreter *, structManPages *, bool, bool) {
    Melder_throw (U"Manual_create not available in library mode.");
}

// Editor functions
void TextEditor_showOpen () {
    Melder_throw (U"TextEditor_showOpen not available.");
}

void ScriptEditors_reload () { /* No-op */ }

// Preferences functions not yet added
void TextEditor_prefs () { /* No-op */ }

// Demo/GUI window functions (Demo_open/Demo_close already in melderthread_impl.cpp)

// Object list/browser functions  
void praat_list_renameObject () {
    Melder_throw (U"Object browser not available.");
}

// More GUI functions as needed
void GuiObject_destroy (void *) { /* No-op */ }

// GuiMenu functions needed by praat_actions.cpp and praat_menuCommands.cpp
struct structGuiMenu;
struct structGuiMenuItem;
struct structGuiMenuItemEvent;

structGuiMenuItem * GuiMenu_addItem (structGuiMenu *, conststring32, unsigned int,
    MelderCallback<void, structThing, structGuiMenuItemEvent*>, Thing) {
    return nullptr;  // No GUI in library mode
}

structGuiMenuItem * GuiMenu_addSeparator (structGuiMenu *) {
    return nullptr;  // No GUI in library mode
}

structGuiMenu * GuiMenu_createInWindow (structGuiWindow *, conststring32, unsigned int) {
    return nullptr;  // No GUI in library mode
}

structGuiMenu * GuiMenu_createInMenu (structGuiMenu *, conststring32, unsigned int) {
    return nullptr;  // No GUI in library mode
}

void GuiThing_show (void *) { /* No-op */ }
void GuiThing_hide (void *) { /* No-op */ }

// GuiButton functions
struct structGuiButton;
struct structGuiButtonEvent;

structGuiButton * GuiButton_create (structGuiForm *, int, int, int, int, conststring32,
    MelderCallback<void, structThing, structGuiButtonEvent*>, Thing, unsigned int) {
    return nullptr;  // No GUI in library mode
}

structGuiButton * GuiButton_createShown (structGuiForm *, int, int, int, int, conststring32,
    MelderCallback<void, structThing, structGuiButtonEvent*>, Thing, unsigned int) {
    return nullptr;  // No GUI in library mode
}

// REMOVED: praat_doAction - now provided by praat_actions.cpp

// Preferences I/O stubs
struct structMelderFile;

void Preferences_read (structMelderFile *) { /* No-op */ }
void Preferences_write (structMelderFile *) { /* No-op */ }

// Melder audio/preferences stubs
void Melder_audio_prefs () { /* No-op */ }
void Melder_audio_open () { /* No-op */ }
void Melder_audio_close () { /* No-op */ }

// Editor functions
struct structEditor;
typedef struct structEditor *Editor;

void Editor_raise (Editor) { /* No-op */ }
void Editor_save (Editor, conststring32) { /* No-op */ }

// Object browser/selection functions
// Object browser/selection functions (praat_updateSelection already in praat_stubs.cpp)
integer praat_getIdOfSelected (void *, int) { return 0; }
int praat_selection (void *) { return 0; }

// Action visibility functions
// REMOVED: praat_actions_show - now in praat_actions.cpp
void ScriptEditors_dirty () { /* No-op */ }
// REMOVED: praat_doMenuCommand - now provided by praat_menuCommands.cpp
void Editor_doMenuCommand (Editor, conststring32, integer, Stackel, conststring32, Interpreter) { /* No-op */ }

// FunctionEditor GUI entry point; referenced but never called in library mode.
struct structFunctionEditor;
typedef struct structFunctionEditor *FunctionEditor;
struct structFunction;
typedef struct structFunction *Function;
void FunctionEditor_init (FunctionEditor, conststring32, Function) {
	Melder_throw (U"FunctionEditor not available in library mode.");
}

// Preferences functions (for enums and other types)
void _Preferences_addEnum (conststring32, int *, int, int, 
    conststring32 (*getValue) (int), 
    int (*getIntValue) (conststring32), 
    int) 
{
    /* No-op */
}

// REMOVED: praat_addMenuCommand_, praat_addCommandsToEditor, praat_removeAction - now in praat_actions.cpp/praat_menuCommands.cpp
// REMOVED: praat_saveAddedActions, praat_saveToggledActions, praat_saveAddedMenuCommands, praat_saveToggledMenuCommands - now in real files

// Speech synthesis (espeak integration - not available in library mode)
struct structSpeechSynthesizer;
typedef struct structSpeechSynthesizer *SpeechSynthesizer;
SpeechSynthesizer SpeechSynthesizer_create (conststring32, conststring32) {
    return nullptr;  // Speech synthesis not available
}
