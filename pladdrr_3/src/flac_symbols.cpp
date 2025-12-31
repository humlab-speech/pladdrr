/* FLAC status string symbols required by melder_audiofiles.cpp
 * Defined as C file to ensure proper linkage
 */

const char * const FLAC__StreamDecoderErrorStatusString[] = {
    "LOST_SYNC", "BAD_HEADER", "FRAME_CRC_MISMATCH", "UNPARSEABLE_STREAM", (const char*)0
};

const char * const FLAC__StreamDecoderInitStatusString[] = {
    "OK", "ERROR_OPENING_FILE", (const char*)0
};

const char * const FLAC__StreamEncoderInitStatusString[] = {
    "OK", "ENCODER_ERROR", (const char*)0
};
