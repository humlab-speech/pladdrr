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
 * LongSound stub - provides class definition without functionality
 * LongSound is for very long audio files and not used in typical analysis
 */

#include "melder/melder.h"
#include "fon/Sampled.h"
#include "fon/Sound.h"

// LongSound is based on Sampled, which inherits from Function
// Only define if not already compiled from LongSound.cpp
#ifndef LONGSOUND_ALREADY_DEFINED
Thing_define (LongSound, Sampled) {
    // Empty - stub only
};

Thing_implement (LongSound, Sampled, 0);
#endif

// Note: SoundList, SoundSet, SoundAndLongSoundList are already defined
// in Sound.h and compiled from Sound.cpp - no need to redefine

// Stub for LongSound_extractPart
autoSound LongSound_extractPart (LongSound, double, double, bool) {
    Melder_throw (U"LongSound_extractPart: LongSound is not available in this build.");
}

/* End of file */
