// speechsynthesizer_stubs.cpp
// Stubs for SpeechSynthesizer functionality (dwtools not compiled - espeak dependency)

#include "praat.github.io/melder/melder.h"
#include "praat.github.io/fon/TextGrid.h"
#include "praat.github.io/fon/Sound.h"

// Forward declarations
struct structSpeechSynthesizer;
typedef structSpeechSynthesizer* SpeechSynthesizer;

// Global variable stub (defined in SpeechSynthesizer.cpp line 827)
STRVEC theSpeechSynthesizerLanguageNames { };

// Stub implementation
autoTextGrid SpeechSynthesizer_Sound_TextInterval_align (
    SpeechSynthesizer /* me */,
    Sound /* sound */,
    TextInterval /* textInterval */,
    double /* silenceThreshold */,
    double /* minSilenceDuration */,
    double /* minSoundingDuration */)
{
    Melder_throw (U"SpeechSynthesizer: Speech synthesis not available in library mode (espeak not compiled).");
}
