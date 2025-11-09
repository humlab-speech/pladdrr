/*
 * LongSound stub - provides class definition without functionality
 * LongSound is for very long audio files and not used in typical analysis
 */

#include "melder/melder.h"
#include "fon/Sampled.h"

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

/* End of file */
