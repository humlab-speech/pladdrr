/*
 * Minimal Sound file I/O stub for speaker package
 * Avoids FLAC/MP3/Ogg dependencies in Praat C code
 * 
 * All file I/O is handled via the av package (humlab-speech/av fork)
 * which supports many formats through FFmpeg (WAV, MP3, FLAC, OGG, M4A, etc.)
 */

#include "melder/melder.h"
#include "fon/Sound.h"
#include "sys/Collection.h"

/* File reader stub - directs users to use av package instead */
autoSound Sound_readFromSoundFile (MelderFile file) {
    Melder_throw (U"Direct audio file reading is not available in this build.\n"
        U"All file I/O is handled via the av package (humlab-speech/av fork).\n"
        U"Use Sound$new(path) to load audio files.\n"
        U"\nExample:\n"
        U"  sound <- Sound$new('audio.mp3')\n"
        U"  # Or from av data:\n"
        U"  audio_data <- av::read_audio_bin('file.wav')\n"
        U"  sound <- Sound$from_matrix(t(audio_data), sampling_rate = 44100)");
}

/* Write Sound to file - stub */
void Sound_writeToAudioFile (Sound me, MelderFile file, int audioFileType) {
    (void) me;
    (void) file;
    (void) audioFileType;
    Melder_throw (U"Direct audio file writing is not available in this build.\n"
        U"All file I/O is handled via the av package.\n"
        U"Use sound$save(path, format) to save audio files.");
}

void Sound_saveAsWavFile (Sound me, MelderFile file) {
    Sound_writeToAudioFile (me, file, 0);
}

void Sound_saveAsAiffFile (Sound me, MelderFile file) {
    Sound_writeToAudioFile (me, file, 0);
}

void Sound_saveAsAifcFile (Sound me, MelderFile file, int compressionType) {
    (void) compressionType;
    Sound_writeToAudioFile (me, file, 0);
}

void Sound_saveAsNextSunFile (Sound me, MelderFile file, int encoding) {
    (void) encoding;
    Sound_writeToAudioFile (me, file, 0);
}

void Sound_saveAsNistFile (Sound me, MelderFile file) {
    Sound_writeToAudioFile (me, file, 0);
}

void Sound_saveAsFlacFile (Sound me, MelderFile file) {
    Sound_writeToAudioFile (me, file, 0);
}

autoSound Sound_readFromRawFile (MelderFile file, int encoding, double sampleRate, integer numberOfChannels) {
    (void) file;
    (void) encoding;
    (void) sampleRate;
    (void) numberOfChannels;
    Melder_throw (U"Reading raw audio files is not supported in this build.");
}

/* Audio playback stubs - not supported in library mode (NO_AUDIO) */
void Sound_play (constSound me, Sound_PlayCallback playCallback, Thing playBoss) {
    (void) me;
    (void) playCallback;
    (void) playBoss;
    Melder_throw (U"Sound playback is not available in library mode.\n"
        U"This is a non-interactive R package for analysis, not playback.");
}

void Sound_playPart (constSound me, double tmin, double tmax, Sound_PlayCallback playCallback, Thing playBoss) {
    (void) me;
    (void) tmin;
    (void) tmax;
    (void) playCallback;
    (void) playBoss;
    Melder_throw (U"Sound playback is not available in library mode.\n"
        U"This is a non-interactive R package for analysis, not playback.");
}

void Sound_saveAsAudioFile (constSound me, MelderFile file, int audioFileType, int bitDepth) {
    (void) me;
    (void) file;
    (void) audioFileType;
    (void) bitDepth;
    Melder_throw (U"Direct audio file writing is not available in this build.\n"
        U"All file I/O is handled via the av package.\n"
        U"Use sound$save(path, format) to save audio files.");
}

void Melder_audiofiles_init () {
    // Audio file system initialization - no-op in NO_AUDIO build
}

void MelderFile_close_nothrow (MelderFile) {
    // No-op - file handling stubbed
}

void MelderFile_writeCharacter (MelderFile, char32_t) {
    Melder_throw (U"File writing not available in library mode.");
}

/* End of file */

void MelderFile__writeOneStringPart (MelderFile, conststring32) {
    Melder_throw (U"File writing not available in library mode.");
}

// Forward declare TextGrid
struct structTextGrid;
typedef structTextGrid* TextGrid;
typedef structTextGrid* autoTextGrid;

autoTextGrid TextGrid_readFromEspsLabelFile (MelderFile, bool, integer) {
    Melder_throw (U"TextGrid_readFromEspsLabelFile: File reading not available in library mode.");
}

autoTextGrid TextGrid_readFromTimitLabelFile (MelderFile, bool) {
    Melder_throw (U"TextGrid_readFromTimitLabelFile: File reading not available in library mode.");
}

// TextGrid collection functions
// (Moved to TextGrid_extensions.cpp)
