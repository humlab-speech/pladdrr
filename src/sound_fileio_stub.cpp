/*
 * Minimal Sound file I/O stub for speaker package
 * Avoids FLAC/MP3/Ogg dependencies
 * 
 * Users should use R packages (tuneR, seewave) to read audio files,
 * then create Sound objects from the numeric data using Sound$new_from_values()
 */

#include "melder/melder.h"
#include "fon/Sound.h"

/* File reader stub - directs users to create Sound from data instead */
autoSound Sound_readFromSoundFile (MelderFile file) {
    Melder_throw (U"Direct audio file reading is not available in this build.\n"
        U"Please use R packages (tuneR, seewave, or audio) to read ", file, U",\n"
        U"then create a Sound object using Sound$new_from_values(data, sampling_rate).\n"
        U"\nExample:\n"
        U"  library(tuneR)\n"
        U"  wav <- readWave('file.wav')\n"
        U"  sound <- Sound$new_from_values(wav@left / 32768, wav@samp.rate)");
}

/* Write Sound to file - stub */
void Sound_writeToAudioFile (Sound me, MelderFile file, int audioFileType) {
    (void) me;
    (void) file;
    (void) audioFileType;
    Melder_throw (U"Direct audio file writing is not available in this build.\n"
        U"Please use sound$as_matrix() to extract data, then write with tuneR or seewave.");
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

/* End of file */
