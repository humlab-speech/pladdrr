// UiForm subsystem stubs for NO_GUI builds
// These functions are referenced by Interpreter.cpp for interactive forms

#include "praat.github.io/melder/melder.h"

// Forward declarations - minimal types needed
typedef char32_t char32;
typedef const char32 *conststring32;

// Define minimal enums for UI vector formats
enum kUi_realVectorFormat { kUi_realVectorFormat_WHITESPACE_SEPARATED = 1 };
enum kUi_integerVectorFormat { kUi_integerVectorFormat_WHITESPACE_SEPARATED = 1 };

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

// Stub implementations - interactive forms are disabled in NO_GUI builds

UiForm UiForm_create (GuiWindow, Editor, conststring32,
    void (*)(UiForm, long, Stackel, conststring32, Interpreter, conststring32, bool, void *, Editor),
    void *, conststring32, conststring32) {
    return nullptr;  // Forms not supported in NO_GUI build
}

void UiForm_finish (UiForm) {}
UiField UiForm_addReal (UiForm, double *, conststring32, conststring32, conststring32) { return nullptr; }
UiField UiForm_addText (UiForm, conststring32 *, conststring32, conststring32, conststring32, long) { return nullptr; }
UiField UiForm_addWord (UiForm, conststring32 *, conststring32, conststring32, conststring32) { return nullptr; }
UiField UiForm_addSentence (UiForm, conststring32 *, conststring32, conststring32, conststring32) { return nullptr; }
UiField UiForm_addRealVector (UiForm, constVEC *, conststring32, conststring32, kUi_realVectorFormat, conststring32, long) { return nullptr; }
UiField UiForm_addIntegerVector (UiForm, constINTVEC *, conststring32, conststring32, kUi_integerVectorFormat, conststring32, long) { return nullptr; }
UiField UiForm_addNaturalVector (UiForm, constINTVEC *, conststring32, conststring32, kUi_integerVectorFormat, conststring32, long) { return nullptr; }
UiField UiForm_addPositiveVector (UiForm, constVEC *, conststring32, conststring32, kUi_realVectorFormat, conststring32, long) { return nullptr; }
void UiForm_addChoice (UiForm, int *, conststring32 *, conststring32, conststring32, int, int) {}
UiField UiForm_addFolder (UiForm, conststring32 *, conststring32, conststring32, conststring32, long) { return nullptr; }
UiField UiForm_addInfile (UiForm, conststring32 *, conststring32, conststring32, conststring32, long) { return nullptr; }
UiField UiForm_addOutfile (UiForm, conststring32 *, conststring32, conststring32, conststring32, long) { return nullptr; }
void UiForm_addOption (UiForm, conststring32) {}
UiField UiForm_addBoolean (UiForm, bool *, conststring32, conststring32, bool) { return nullptr; }
void UiForm_addLabel (UiForm, conststring32, conststring32) {}
UiField UiForm_addNatural (UiForm, long *, conststring32, conststring32, conststring32) { return nullptr; }
UiField UiForm_addInteger (UiForm, long *, conststring32, conststring32, conststring32) { return nullptr; }
UiField UiForm_addPositive (UiForm, double *, conststring32, conststring32, conststring32) { return nullptr; }
void UiForm_addRadio (UiForm, int *, conststring32, conststring32, conststring32, int) {}
void UiForm_addList (UiForm, long *, conststring32, conststring32 *, long, conststring32) {}
void UiForm_addOptionMenu (UiForm, int *, conststring32 *, conststring32, conststring32, int, int) {}
UiField UiForm_addCaption (UiForm, conststring32 *, conststring32) { return nullptr; }
UiField UiForm_addHeading (UiForm, conststring32 *, conststring32) { return nullptr; }
UiField UiForm_addComment (UiForm, conststring32 *, conststring32) { return nullptr; }

conststring32 UiForm_getString (UiForm, conststring32) { return U""; }
long UiForm_getInteger (UiForm, conststring32) { return 0; }
double UiForm_getReal (UiForm, conststring32) { return 0.0; }
double UiForm_getReal_check (UiForm, conststring32) { return 0.0; }
bool UiForm_getBoolean (UiForm, conststring32) { return false; }
constVEC UiForm_getRealVector (UiForm, conststring32) { 
    return constVEC();  // Return empty vector
}

constINTVEC UiForm_getIntegerVector (UiForm, conststring32) {
    return constINTVEC();  // Return empty vector
}

integer UiForm_getInteger_check (UiForm, conststring32) { return 0; }
conststring32 UiForm_getString_check (UiForm, conststring32) { return U""; }

void UiForm_do (UiForm, bool) {}

// Demo Editor stubs (for Demo namespace functions used by Formula.cpp)
bool Demo_clickedIn (double left, double right, double bottom, double top) {
    return false;  // Demo functions not supported in NO_GUI build
}

int Demo_peekInput (Interpreter interpreter) {
    return 0;  // Demo functions not supported in NO_GUI build
}

void Demo_windowTitle (conststring32) {
    // No-op
}

bool Demo_shiftKeyPressed () {
    return false; // Demo functions not supported in NO_GUI build
}

bool Demo_optionKeyPressed () {
    return false; // Demo functions not supported in NO_GUI build
}

bool Demo_commandKeyPressed () {
    return false; // Demo functions not supported in NO_GUI build
}

// UiPause stubs (for interactive pauses in scripts)
void UiPause_realvector (conststring32, kUi_realVectorFormat, conststring32, long) {}
void UiPause_positivevector (conststring32, kUi_realVectorFormat, conststring32, long) {}
void UiPause_integervector (conststring32, kUi_integerVectorFormat, conststring32, long) {}
void UiPause_naturalvector (conststring32, kUi_integerVectorFormat, conststring32, long) {}

// GUI file selection stubs
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

// Enum conversion functions
kUi_realVectorFormat kUi_realVectorFormat_getValue (conststring32) {
    return kUi_realVectorFormat_WHITESPACE_SEPARATED;
}

kUi_integerVectorFormat kUi_integerVectorFormat_getValue (conststring32) {
    return kUi_integerVectorFormat_WHITESPACE_SEPARATED;
}

void Demo_show () {}

struct structUiForm;
struct structStackel;

void UiForm_call (structUiForm *, integer, structStackel *, structInterpreter *) {
    Melder_throw (U"UiForm_call not available in library mode.");
}

// UI Pause system (used by pause command in scripts)
void UiPause_begin (GuiWindow, Editor, conststring32, Interpreter) {
    Melder_throw (U"UiPause_begin (pause command) not available in library mode.");
}

int UiPause_end (int, int, int, conststring32, conststring32, conststring32, 
                 conststring32, conststring32, conststring32, conststring32,
                 conststring32, conststring32, conststring32, structInterpreter *) {
    Melder_throw (U"UiPause_end (pause command) not available in library mode.");
}

// Auto-generated stub for missing symbol
// GuiTrust_get(structGuiWindow*, structEditor*, char32_t const*, char32_t const*, char32_t const*, char32_t const*, char32_t const*, char32_t const*, char32_t const*, char32_t const*, char32_t const*, char32_t const*, structInterpreter*)  
int GuiTrust_get (...) {
    Melder_throw (U"GuiTrust_get not available in library mode.");
}

// GUI Trust dialog (used for security prompts)
int GuiTrust_get (structGuiWindow *, structEditor *, conststring32, conststring32,
                  conststring32, conststring32, conststring32, conststring32,
                  conststring32, conststring32, conststring32, conststring32,
                  structInterpreter *) {
    Melder_throw (U"GuiTrust_get not available in library mode.");
}

// UiPause system - real number input
double UiPause_real (conststring32, conststring32) {
    Melder_throw (U"UiPause_real not available in library mode.");
}

// Additional UiPause functions
conststring32 UiPause_text (conststring32, conststring32, long) {
    Melder_throw (U"UiPause_text not available in library mode.");
}

integer UiPause_integer (conststring32, conststring32, long) {
    Melder_throw (U"UiPause_integer not available in library mode.");
}

conststring32 UiPause_choice (conststring32, int) {
    Melder_throw (U"UiPause_choice not available in library mode.");
}

int UiPause_boolean (conststring32, int) {
    Melder_throw (U"UiPause_boolean not available in library mode.");
}

void UiPause_comment (conststring32) { /* No-op */ }


conststring32 UiPause_word (conststring32, conststring32) {
    Melder_throw (U"UiPause_word not available in library mode.");
}


// GuiThing functions (GUI object system)
struct structGuiThing;
void GuiThing_show (structGuiThing *) { /* No-op */ }
void GuiThing_hide (structGuiThing *) { /* No-op */ }
void GuiThing_setSensitive (structGuiThing *, int) { /* No-op */ }


// UiFile functions (file selection dialogs)
conststring32 UiFile_getFile (structUiForm *, conststring32) {
    Melder_throw (U"UiFile_getFile not available.");
}

// Editor-related Gui functions
struct structDataEditor;
void DataEditor_create (conststring32, void *) {
    Melder_throw (U"DataEditor_create not available.");
}

conststring32 UiPause_folder (conststring32, conststring32, long) {
    Melder_throw (U"UiPause_folder not available in library mode.");
}

conststring32 UiPause_infile (conststring32, conststring32, long) {
    Melder_throw (U"UiPause_infile not available in library mode.");
}

conststring32 UiPause_outfile (conststring32, conststring32, long) {
    Melder_throw (U"UiPause_outfile not available in library mode.");
}

conststring32 UiPause_word (conststring32, conststring32, long) {
    Melder_throw (U"UiPause_word not available in library mode.");
}

conststring32 UiPause_sentence (conststring32, conststring32, long) {
    Melder_throw (U"UiPause_sentence not available in library mode.");
}

void UiPause_optionmenu (conststring32, int) {
    /* No-op */
}

void UiPause_radio (conststring32, int) {
    /* No-op */
}

void UiPause_list (conststring32, long) {
    /* No-op */
}

void UiPause_label (conststring32) {
    /* No-op */
}

void UiPause_option (conststring32) {
    /* No-op */
}

// Additional overloads for UiPause functions
bool UiPause_boolean (conststring32, bool) {
    Melder_throw (U"UiPause_boolean not available in library mode.");
}

long UiPause_natural (conststring32, conststring32, long) {
    Melder_throw (U"UiPause_natural not available in library mode.");
}

double UiPause_positive (conststring32, conststring32, long) {
    Melder_throw (U"UiPause_positive not available in library mode.");
}

conststring32 UiPause_heading (conststring32) {
    return U"";  // Return empty string
}

conststring32 UiPause_caption (conststring32) {
    return U"";
}

void UiPause_choice (conststring32) {
    /* No-op */
}

double UiPause_real_check (conststring32, conststring32, long) {
    Melder_throw (U"UiPause_real_check not available in library mode.");
}

integer UiPause_natural_check (conststring32, conststring32, long) {
    Melder_throw (U"UiPause_natural_check not available in library mode.");
}

integer UiPause_integer_check (conststring32, conststring32, long) {
    Melder_throw (U"UiPause_integer_check not available in library mode.");
}

double UiPause_positive_check (conststring32, conststring32, long) {
    Melder_throw (U"UiPause_positive_check not available in library mode.");
}

conststring32 UiPause_word_check (conststring32, conststring32, long) {
    Melder_throw (U"UiPause_word_check not available in library mode.");
}

conststring32 UiPause_sentence_check (conststring32, conststring32, long) {
    Melder_throw (U"UiPause_sentence_check not available in library mode.");
}

conststring32 UiPause_text_check (conststring32, conststring32, long) {
    Melder_throw (U"UiPause_text_check not available in library mode.");
}

// Simpler UiPause overloads (without long parameter)

// 2-parameter UiPause overloads (no long parameter)
integer UiPause_integer (conststring32, conststring32) {
    Melder_throw (U"UiPause_integer not available in library mode.");
}

long UiPause_natural (conststring32, conststring32) {
    Melder_throw (U"UiPause_natural not available in library mode.");
}

double UiPause_positive (conststring32, conststring32) {
    Melder_throw (U"UiPause_positive not available in library mode.");
}

conststring32 UiPause_sentence (conststring32, conststring32) {
    Melder_throw (U"UiPause_sentence not available in library mode.");
}


// GuiWindow creation - use concrete callback type
GuiWindow GuiWindow_create (int, int, int, int, int, int, conststring32, 
                            MelderCallback<void, structThing>, structThing *, unsigned int) {
    return nullptr;  // GUI windows not supported
}

// UiForm parsing/execution
void UiForm_parseString (UiForm, conststring32, Interpreter) {
    Melder_throw (U"UiForm_parseString not available in library mode.");
}

void UiForm_showAndWait (UiForm) {
    Melder_throw (U"UiForm_showAndWait not available in library mode.");
}

// GuiList functions
struct structGuiList;
struct structGuiList_SelectionChangedEvent;

void GuiList_setSelectionChangedCallback (structGuiList *, 
    MelderCallback<void, structThing, structGuiList_SelectionChangedEvent *>, 
    structThing *) 
{
    /* No-op - GUI callbacks not available */
}

void Ui_prefs () {
    /* No-op - UI preferences not needed in library mode */
}

// Editor preferences stub - forward declare class, implement static method
struct structEditor {
    static void f_preferences();
};

void structEditor::f_preferences() {
    /* No-op - Editor preferences not needed in library mode */
}

// DataGui preferences stub
struct structDataGui {
    static void f_preferences();
};

void structDataGui::f_preferences() {
    /* No-op - DataGui preferences not needed in library mode */
}

// HyperPage preferences stub
struct structHyperPage {
    static void f_preferences();
};

void structHyperPage::f_preferences() {
    /* No-op - HyperPage preferences not needed in library mode */
}

// Manual preferences stub (likely needed too)
struct structManual {
    static void f_preferences();
};

void structManual::f_preferences() {
    /* No-op - Manual preferences not needed in library mode */
}

// TextEditor preferences stub
struct structTextEditor {
    static void f_preferences();
};

void structTextEditor::f_preferences() {
    /* No-op - TextEditor preferences not needed in library mode */
}

// ScriptEditor preferences stub (probably needed)
struct structScriptEditor {
    static void f_preferences();
};

void structScriptEditor::f_preferences() {
    /* No-op - ScriptEditor preferences not needed in library mode */
}
