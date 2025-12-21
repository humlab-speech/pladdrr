/* area_stubs.cpp
 * Stub implementations for Praat GUI Area classes
 * These are editor/viewer components not needed for script execution
 */

#include "praat.github.io/sys/Thing.h"


// Forward declarations
struct structPointProcess;
struct structPitch;
struct structSound;
struct structTextGrid;
struct structPitchTier;
struct structSpectrogram;
struct structDurationTier;
struct structIntensityTier;
struct structFormantGrid;
struct structAmplitudeTier;
struct structRealTier;
struct structSpectrum;
struct structTable;
struct structData;
struct structStrings;

// Declare Area classes as Thing subclasses
Thing_define (FunctionArea, Thing) {
    public: static void f_preferences();
};
Thing_implement (FunctionArea, Thing, 0);

Thing_define (SpectrumArea, FunctionArea) {
    public: static void f_preferences();
};
Thing_implement (SpectrumArea, FunctionArea, 0);

Thing_define (PointArea, FunctionArea) {
    public: static void f_preferences();
};
Thing_implement (PointArea, FunctionArea, 0);

Thing_define (RealTierArea, FunctionArea) {
    public: static void f_preferences();
};
Thing_implement (RealTierArea, FunctionArea, 0);

Thing_define (PitchTierArea, RealTierArea) {
    public: static void f_preferences();
};
Thing_implement (PitchTierArea, RealTierArea, 0);

Thing_define (IntensityTierArea, RealTierArea) {
    public: static void f_preferences();
};
Thing_implement (IntensityTierArea, RealTierArea, 0);

Thing_define (DurationTierArea, RealTierArea) {
    public: static void f_preferences();
};
Thing_implement (DurationTierArea, RealTierArea, 0);

Thing_define (AmplitudeTierArea, RealTierArea) {
    public: static void f_preferences();
};
Thing_implement (AmplitudeTierArea, RealTierArea, 0);

Thing_define (FormantGridArea, FunctionArea) {
    public: static void f_preferences();
};
Thing_implement (FormantGridArea, FunctionArea, 0);

Thing_define (ManipulationPitchTierArea, FunctionArea) {
    public: static void f_preferences();
};
Thing_implement (ManipulationPitchTierArea, FunctionArea, 0);

Thing_define (SoundArea, FunctionArea) {
    public: static void f_preferences();
};
Thing_implement (SoundArea, FunctionArea, 0);

Thing_define (TextGridArea, FunctionArea) {
    public: static void f_preferences();
};
Thing_implement (TextGridArea, FunctionArea, 0);

Thing_define (SoundAnalysisArea, FunctionArea) {
    public: static void f_preferences();
};
Thing_implement (SoundAnalysisArea, FunctionArea, 0);

Thing_define (SoundRecorder, Thing) {
    public: static void f_preferences();
};
Thing_implement (SoundRecorder, Thing, 0);

Thing_define (Editor, Thing) {
};
Thing_implement (Editor, Thing, 0);

Thing_define (FunctionEditor, Editor) {
    public: static void f_preferences();
};
Thing_implement (FunctionEditor, Editor, 0);

Thing_define (FormantGridEditor, FunctionEditor) {
};
Thing_implement (FormantGridEditor, FunctionEditor, 0);

Thing_define (SoundEditor, FunctionEditor) {
};
Thing_implement (SoundEditor, FunctionEditor, 0);

Thing_define (SpectrogramEditor, FunctionEditor) {
};
Thing_implement (SpectrogramEditor, FunctionEditor, 0);

Thing_define (TextGridEditor, FunctionEditor) {
    public: static void f_preferences();
};
Thing_implement (TextGridEditor, FunctionEditor, 0);

Thing_define (PitchEditor, FunctionEditor) {
};
Thing_implement (PitchEditor, FunctionEditor, 0);

Thing_define (PointEditor, FunctionEditor) {
};
Thing_implement (PointEditor, FunctionEditor, 0);

Thing_define (SpectrumEditor, FunctionEditor) {
    public: static void f_preferences();
};
Thing_implement (SpectrumEditor, FunctionEditor, 0);

Thing_define (ManipulationEditor, FunctionEditor) {
};
Thing_implement (ManipulationEditor, FunctionEditor, 0);

Thing_define (RealTierEditor, FunctionEditor) {
};
Thing_implement (RealTierEditor, FunctionEditor, 0);

Thing_define (PitchTierEditor, RealTierEditor) {
};
Thing_implement (PitchTierEditor, RealTierEditor, 0);

Thing_define (DurationTierEditor, RealTierEditor) {
};
Thing_implement (DurationTierEditor, RealTierEditor, 0);

Thing_define (IntensityTierEditor, RealTierEditor) {
};
Thing_implement (IntensityTierEditor, RealTierEditor, 0);

Thing_define (AmplitudeTierEditor, RealTierEditor) {
};
Thing_implement (AmplitudeTierEditor, RealTierEditor, 0);

Thing_define (TableEditor, Editor) {
};
Thing_implement (TableEditor, Editor, 0);

Thing_define (DataEditor, Editor) {
};
Thing_implement (DataEditor, Editor, 0);

Thing_define (TextEditor, Editor) {
};
Thing_implement (TextEditor, Editor, 0);

Thing_define (ScriptEditor, TextEditor) {
};
Thing_implement (ScriptEditor, TextEditor, 0);

Thing_define (VowelEditor, Editor) {
};
Thing_implement (VowelEditor, Editor, 0);

Thing_define (StringsEditor, Editor) {
};
Thing_implement (StringsEditor, Editor, 0);

// Stub editor creation functions - all return empty autoptr
struct structSampledXY;
struct structSpellingChecker;
struct structManipulation;

autoTextGridEditor TextGridEditor_create (conststring32, structTextGrid *, structSampledXY *, structSpellingChecker *, conststring32) {
    return autoTextGridEditor();
}

autoPitchEditor PitchEditor_create (conststring32, structPitch *) {
    return autoPitchEditor();
}

autoRealTierEditor RealTierEditor_create (conststring32, structRealTier *, structSound *) {
    return autoRealTierEditor();
}

autoSpectrumEditor SpectrumEditor_create (conststring32, structSpectrum *) {
    return autoSpectrumEditor();
}

autoPitchTierEditor PitchTierEditor_create (conststring32, structPitchTier *, structSound *) {
    return autoPitchTierEditor();
}

autoSpectrogramEditor SpectrogramEditor_create (conststring32, structSpectrogram *) {
    return autoSpectrogramEditor();
}

autoDurationTierEditor DurationTierEditor_create (conststring32, structDurationTier *, structSound *) {
    return autoDurationTierEditor();
}

autoIntensityTierEditor IntensityTierEditor_create (conststring32, structIntensityTier *, structSound *) {
    return autoIntensityTierEditor();
}

autoFormantGridEditor FormantGridEditor_create (conststring32, structFormantGrid *) {
    return autoFormantGridEditor();
}

autoManipulationEditor ManipulationEditor_create (conststring32, structManipulation *) {
    return autoManipulationEditor();
}

autoAmplitudeTierEditor AmplitudeTierEditor_create (conststring32, structAmplitudeTier *, structSound *) {
    return autoAmplitudeTierEditor();
}

autoPointEditor PointEditor_create (conststring32, structPointProcess *, structSound *) {
    return autoPointEditor();
}

autoSoundEditor SoundEditor_create (conststring32, structSampledXY *) {
    return autoSoundEditor();
}

// Additional editor creators
autoTableEditor TableEditor_create (conststring32, structTable *) {
    return autoTableEditor();
}

autoDataEditor DataEditor_create (conststring32, structData *) {
    return autoDataEditor();
}

autoScriptEditor ScriptEditor_create (conststring32, autostring32) {
    return autoScriptEditor();
}

autoTextEditor TextEditor_create (conststring32) {
    return autoTextEditor();
}

autoVowelEditor VowelEditor_create (conststring32, structData *) {
    return autoVowelEditor();
}

autoStringsEditor StringsEditor_create (conststring32, structStrings *) {
    return autoStringsEditor();
}

// External implementations of f_preferences() for Area classes called by praat_uvafon_init
void structFunctionArea::f_preferences() { }
void structSpectrumArea::f_preferences() { }
void structPointArea::f_preferences() { }
void structRealTierArea::f_preferences() { }
void structPitchTierArea::f_preferences() { }
void structIntensityTierArea::f_preferences() { }
void structDurationTierArea::f_preferences() { }
void structAmplitudeTierArea::f_preferences() { }
void structFormantGridArea::f_preferences() { }
void structManipulationPitchTierArea::f_preferences() { }
void structSoundArea::f_preferences() { }

// Additional Area and Editor f_preferences
void structTextGridArea::f_preferences() { }
void structSoundAnalysisArea::f_preferences() { }
void structSoundRecorder::f_preferences() { }
void structFunctionEditor::f_preferences() { }
void structTextGridEditor::f_preferences() { }
void structSpectrumEditor::f_preferences() { }
