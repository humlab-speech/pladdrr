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
