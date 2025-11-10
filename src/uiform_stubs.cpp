// UiForm subsystem stubs for NO_GUI builds
// These functions are referenced by Interpreter.cpp for interactive forms

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
UiField UiForm_addCaption (UiForm, conststring32 *, conststring32) { return nullptr; }
UiField UiForm_addHeading (UiForm, conststring32 *, conststring32) { return nullptr; }
UiField UiForm_addComment (UiForm, conststring32 *, conststring32) { return nullptr; }

conststring32 UiForm_getString (UiForm, conststring32) { return U""; }
long UiForm_getInteger (UiForm, conststring32) { return 0; }
double UiForm_getReal (UiForm, conststring32) { return 0.0; }
bool UiForm_getBoolean (UiForm, conststring32) { return false; }

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
