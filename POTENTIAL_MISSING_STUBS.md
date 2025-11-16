# Potential Missing Stub Functions

Based on Gemini CLI analysis of Praat headers, here are functions that may still need stub implementations:

## Graphics Functions (Graphics.h)

### Already Implemented ✅
- Graphics_textWidth
- Graphics_textWidth_ps
- Graphics_inqFontSize
- Graphics_inqLineType
- Graphics_inqLineWidth
- Graphics_inqSpeckleSize
- Graphics_marks*Every (all 4 variants)

### Potentially Needed
```cpp
// Viewport/Window management
void Graphics_setViewport (Graphics, double, double, double, double);
void Graphics_setWindow (Graphics, double, double, double, double);

// Drawing primitives
void Graphics_line (Graphics, double, double, double, double);
void Graphics_polyline (Graphics, integer, const double*, const double*);
void Graphics_text (Graphics, double, double, conststring32);
void Graphics_fillArea (Graphics, integer, double const*, double const*);

// Shapes
void Graphics_rectangle (Graphics, double, double, double, double);
void Graphics_fillRectangle (Graphics, double, double, double, double);
void Graphics_circle (Graphics, double, double, double);
void Graphics_fillCircle (Graphics, double, double, double);
void Graphics_ellipse (Graphics, double, double, double, double);
void Graphics_fillEllipse (Graphics, double, double, double, double);
void Graphics_arrow (Graphics, double, double, double, double);

// Style/Color
void Graphics_setColour (Graphics, MelderColour);
void Graphics_setGrey (Graphics, double);
void Graphics_setFont (Graphics, kGraphics_font);
void Graphics_setFontSize (Graphics, double);
void Graphics_setFontStyle (Graphics, int);
void Graphics_setLineType (Graphics, int);
void Graphics_setLineWidth (Graphics, double);

// Axes
void Graphics_textLeft (Graphics, bool, conststring32);
void Graphics_textBottom (Graphics, bool, conststring32);
void Graphics_textRight (Graphics, bool, conststring32);
void Graphics_textTop (Graphics, bool, conststring32);
void Graphics_marksLeft (Graphics, ...);
void Graphics_marksBottom (Graphics, ...);
void Graphics_marksRight (Graphics, ...);
void Graphics_marksTop (Graphics, ...);
void Graphics_markLeft (Graphics, ...);
void Graphics_markBottom (Graphics, ...);

// Inquiry functions
MelderColour Graphics_inqColour (Graphics);
double Graphics_inqGrey (Graphics);
kGraphics_font Graphics_inqFont (Graphics);
int Graphics_inqFontStyle (Graphics);

// Rendering control  
bool Graphics_startRecording (Graphics);
bool Graphics_stopRecording (Graphics);
void Graphics_play (Graphics, Graphics);
```

## UiForm Functions (Ui.h)

### Already Implemented ✅
- UiForm_addSentence
- UiForm_addRealVector
- UiForm_addIntegerVector
- UiForm_addOptionMenu
- UiForm_getReal_check
- UiForm_getRealVector
- UiPause_* variants

### Potentially Needed
```cpp
// Form field addition
UiField UiForm_addPositiveVector (UiForm, constVEC*, ...);
UiField UiForm_addNaturalVector (UiForm, constINTVEC*, ...);
UiField UiForm_addLabel (UiForm, conststring32);
UiField UiForm_addRadio (UiForm, int*, ...);
UiField UiForm_addOptionMenu (UiForm, int*, ...);

// Form value retrieval
conststring32 UiForm_getString (UiForm, conststring32);
integer UiForm_getInteger (UiForm, conststring32);
integer UiForm_getInteger_check (UiForm, conststring32);
double UiForm_getReal (UiForm, conststring32);
bool UiForm_getBoolean (UiForm, conststring32);
constINTVEC UiForm_getIntegerVector (UiForm, conststring32);

// File dialogs
MelderFile UiFile_getFile (UiForm);
void UiInfile_do (UiForm);
void UiOutfile_do (UiForm, conststring32);

// History
void UiHistory_write (conststring32);
char32* UiHistory_get ();
```

## Praat Application Functions (praat.h)

### Already Implemented ✅
- praat_idOfSelected
- praat_idsOfAllSelected  
- praat_numberOfSelected
- praat_nameOfSelected
- praat_removeObject
- praat_doMenuCommand
- praat_executeCommand
- praat_findEditorById
- Editor_doMenuCommand

### Potentially Needed
```cpp
// Application lifecycle
void praat_init (...);
void praat_run ();
void praat_exit (int);

// Menu/Action registration
void praat_addAction1_ (...);
void praat_addAction2_ (...);
void praat_addAction3_ (...);
void praat_addAction4_ (...);
GuiMenuItem praat_addMenuCommand_ (...);

// Object management
void praat_new (autoDaata);
void praat_newWithFile (autoDaata, MelderFile, conststring32);
void praat_show ();
void praat_updateSelection ();
void praat_dataChanged (Daata);

// Selection queries
Daata praat_onlyObject (ClassInfo);
Daata praat_onlyObject_generic (ClassInfo);
autoVEC praat_getVector (ClassInfo, integer);

// Editor management
void praat_installEditor (Editor, integer);
void praat_installEditor2 (Editor, integer, integer);
void praat_installEditorN (Editor, Ordered);
void praat_installEditor3 (Editor, integer, integer, integer);

// Picture window
void praat_picture_open ();
void praat_picture_close ();

// Preferences
void Preferences_read (MelderFile);
void Preferences_write (MelderFile);
```

## Demo Functions

### Already Implemented ✅
- Demo_shiftKeyPressed
- Demo_optionKeyPressed
- Demo_commandKeyPressed
- Demo_clickedIn
- Demo_peekInput  
- Demo_windowTitle

### Potentially Needed
```cpp
bool Demo_input (conststring32);
bool Demo_waitForInput (Interpreter);
double Demo_x ();
double Demo_y ();
void Demo_open ();
void Demo_close ();
```

## Quick Stub Template

To add any of these, use this pattern:

### For void functions:
```cpp
void FunctionName (params...) {
    // No-op stub for NO_GUI/NO_GRAPHICS build
}
```

### For query functions:
```cpp
ReturnType FunctionName (params...) {
    return DefaultValue;  // 0, 0.0, false, nullptr, etc.
}
```

### For functions that should error:
```cpp
ReturnType FunctionName (params...) {
    Melder_throw (U"FunctionName not available in library mode.");
}
```

## Priority Order

1. **HIGH**: Any symbol that appears in link errors
2. **MEDIUM**: UiForm_*, Graphics inquiry functions  
3. **LOW**: praat_init/run/exit (never called in library mode)

