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

/* Stub SoundList_play - throws error if called */
void SoundList_play (SoundList me, Sound_PlayCallback playCallback, Thing playClosure) {
    (void) me;
    (void) playCallback;
    (void) playClosure;
    Melder_throw (U"SoundList playback is not available in library mode.\n"
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

void MelderAudio_play16 (short *, long, long, long, bool (*)(void*, long), void*) {
    // No-op - audio playback not supported
}

void SoundRecorder_create (int) {
    // No-op - audio recording not supported
}

short mp3f_sample_to_short (int sample) {
    // No-op - MP3 encoding not supported
    return 0;
}

autoSound Sound_record_fixedTime (int inputSource, double gain, double balance, 
                               double samplingFrequency, double duration) {
    // No-op - recording not supported
    return autoSound();
}

bool MelderAudio_stopPlaying (bool immediately) {
    // No-op
    return false;
}

void SoundRecorder_preferences () {
    // No-op
}

enum kMelder_inputSoundSystem MelderAudio_getInputSoundSystem () {
    return static_cast<kMelder_inputSoundSystem>(0);  // No audio input
}

void MelderAudio_setInputSoundSystem (kMelder_inputSoundSystem) {
    // No-op - no audio input
}

enum kMelder_outputSoundSystem MelderAudio_getOutputSoundSystem () {
    return static_cast<kMelder_outputSoundSystem>(0);
}

void MelderAudio_setOutputSoundSystem (kMelder_outputSoundSystem) {}

double MelderAudio_getOutputSilenceAfter () {
    return 0.0;
}

void MelderAudio_setOutputSilenceAfter (double) {}

double MelderAudio_getOutputSilenceBefore () { return 0.0; }
void MelderAudio_setOutputSilenceBefore (double) {}

double SoundRecorder_getBufferSizePref_MB () { return 20.0; }
void SoundRecorder_setBufferSizePref_MB (long) {}

integer MelderAudio_getOutputBestSampleRate (integer) { return 44100; }
integer MelderAudio_getSamplingPrecision () { return 16; }
void MelderAudio_setSamplingPrecision (integer) {}

enum kMelder_asynchronicityLevel MelderAudio_getOutputMaximumAsynchronicity () { return static_cast<kMelder_asynchronicityLevel>(0); }
void MelderAudio_setOutputMaximumAsynchronicity (enum kMelder_asynchronicityLevel) {}
double MelderAudio_getUseInternalSpeaker () { return 0; }
void MelderAudio_setUseInternalSpeaker (int) {}
