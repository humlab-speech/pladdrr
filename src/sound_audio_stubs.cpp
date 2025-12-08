/*
 * Sound_audio.cpp stubs for pladdrr package
 * Audio playback not supported in non-interactive library mode
 */

#include "praat.github.io/fon/Sound.h"
#include "praat.github.io/melder/melder.h"

/* Stub Sound_play - throws error if called */
void Sound_play (constSound me, Sound_PlayCallback playCallback, Thing playBoss) {
    (void) me;
    (void) playCallback;
    (void) playBoss;
    Melder_throw (U"Sound playback is not available in library mode.\n"
        U"This is a non-interactive R package for analysis, not playback.");
}

/* Stub Sound_playPart - throws error if called */
void Sound_playPart (constSound me, double tmin, double tmax, Sound_PlayCallback playCallback, Thing playBoss) {
    (void) me;
    (void) tmin;
    (void) tmax;
    (void) playCallback;
    (void) playBoss;
    Melder_throw (U"Sound playback is not available in library mode.\n"
        U"This is a non-interactive R package for analysis, not playback.");
}

// ============================================================================
// FLAC/MP3 Status Strings (referenced by melder_audiofiles.cpp)
// ============================================================================

extern "C" {
    const char * const FLAC__StreamDecoderErrorStatusString[] = {
        "LOST_SYNC", "BAD_HEADER", "FRAME_CRC_MISMATCH", "UNPARSEABLE_STREAM", nullptr
    };

    const char * const FLAC__StreamDecoderInitStatusString[] = {
        "OK", "ERROR_OPENING_FILE", nullptr
    };

    const char * const FLAC__StreamEncoderInitStatusString[] = {
        "OK", "ENCODER_ERROR", nullptr
    };
}
