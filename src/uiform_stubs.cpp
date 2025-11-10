// UiForm subsystem stubs for NO_GUI builds
// These functions are referenced by Interpreter.cpp for interactive forms

// Forward declarations - minimal types needed
typedef char32_t char32;
typedef const char32 *conststring32;

struct structUiForm;
typedef struct structUiForm *UiForm;

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
void UiForm_addReal (UiForm, double *, conststring32, conststring32, conststring32) {}
void UiForm_addText (UiForm, conststring32 *, conststring32, conststring32, conststring32, long) {}
void UiForm_addWord (UiForm, conststring32 *, conststring32, conststring32, conststring32) {}
void UiForm_addChoice (UiForm, int *, conststring32 *, conststring32, conststring32, int, int) {}
void UiForm_addFolder (UiForm, conststring32 *, conststring32, conststring32, conststring32, long) {}
void UiForm_addInfile (UiForm, conststring32 *, conststring32, conststring32, conststring32, long) {}
void UiForm_addOutfile (UiForm, conststring32 *, conststring32, conststring32, conststring32, long) {}
void UiForm_addOption (UiForm, conststring32) {}
void UiForm_addBoolean (UiForm, bool *, conststring32, conststring32) {}
void UiForm_addLabel (UiForm, conststring32, conststring32) {}
void UiForm_addNatural (UiForm, long *, conststring32, conststring32, conststring32) {}
void UiForm_addInteger (UiForm, long *, conststring32, conststring32, conststring32) {}
void UiForm_addPositive (UiForm, double *, conststring32, conststring32, conststring32) {}
void UiForm_addRadio (UiForm, int *, conststring32, conststring32, conststring32, int) {}
void UiForm_addList (UiForm, long *, conststring32, conststring32 *, long, conststring32) {}

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
