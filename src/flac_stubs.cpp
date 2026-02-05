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
// FLAC/MP3 stub implementations
// Headers already included by melder_audiofiles.cpp - we just provide stubs

#include <cstdio>
#include <cstdint>

// Praat integer type (from melder_int.h)
using integer = intptr_t;

// MP3 types (from mp3.h) - manually defined to avoid missing header during R install
typedef struct _MP3_FILE *MP3_FILE;
typedef int MP3F_SAMPLE;
#if defined (_OFF_T) || defined (__off_t_defined)
typedef off_t MP3F_OFFSET;
#else
typedef unsigned long MP3F_OFFSET;
#endif

#define MP3F_MAX_CHANNELS 2
#define MP3F_MAX_SAMPLES  1152

typedef void (*MP3F_CALLBACK) (
    const MP3F_SAMPLE *channels [MP3F_MAX_CHANNELS],
    integer num_samples,
    void *context);

// Forward declarations for FLAC types
typedef struct FLAC__StreamDecoder FLAC__StreamDecoder;
typedef struct FLAC__StreamEncoder FLAC__StreamEncoder;
typedef struct FLAC__StreamMetadata FLAC__StreamMetadata;
typedef int FLAC__bool;
typedef unsigned long long FLAC__uint64;
typedef int FLAC__int32;

// FLAC callback types
typedef void* FLAC__StreamDecoderReadCallback;
typedef void* FLAC__StreamDecoderSeekCallback;
typedef void* FLAC__StreamDecoderTellCallback;
typedef void* FLAC__StreamDecoderLengthCallback;
typedef void* FLAC__StreamDecoderEofCallback;
typedef void* FLAC__StreamDecoderWriteCallback;
typedef void* FLAC__StreamDecoderMetadataCallback;
typedef void* FLAC__StreamDecoderErrorCallback;
typedef void* FLAC__StreamEncoderProgressCallback;

// FLAC status enums
typedef enum {
    FLAC__STREAM_DECODER_INIT_STATUS_OK = 0,
    FLAC__STREAM_DECODER_INIT_STATUS_ERROR_OPENING_FILE
} FLAC__StreamDecoderInitStatus;

typedef enum {
    FLAC__STREAM_ENCODER_INIT_STATUS_OK = 0,
    FLAC__STREAM_ENCODER_INIT_STATUS_ENCODER_ERROR
} FLAC__StreamEncoderInitStatus;

// ============================================================================
// FLAC Decoder Stubs
// ============================================================================

extern "C" {

FLAC__StreamDecoder *FLAC__stream_decoder_new(void) {
    return nullptr;
}

void FLAC__stream_decoder_delete(FLAC__StreamDecoder *) {}

FLAC__StreamDecoderInitStatus FLAC__stream_decoder_init_stream(
    FLAC__StreamDecoder *, FLAC__StreamDecoderReadCallback,
    FLAC__StreamDecoderSeekCallback, FLAC__StreamDecoderTellCallback,
    FLAC__StreamDecoderLengthCallback, FLAC__StreamDecoderEofCallback,
    FLAC__StreamDecoderWriteCallback, FLAC__StreamDecoderMetadataCallback,
    FLAC__StreamDecoderErrorCallback, void *
) {
    return FLAC__STREAM_DECODER_INIT_STATUS_ERROR_OPENING_FILE;
}

FLAC__bool FLAC__stream_decoder_process_until_end_of_stream(FLAC__StreamDecoder *) {
    return false;
}

FLAC__bool FLAC__stream_decoder_finish(FLAC__StreamDecoder *) {
    return false;
}

// Additional FLAC functions for LongSound support
typedef enum {
    FLAC__STREAM_DECODER_SEARCH_FOR_METADATA = 0,
    FLAC__STREAM_DECODER_READ_METADATA,
    FLAC__STREAM_DECODER_SEARCH_FOR_FRAME_SYNC,
    FLAC__STREAM_DECODER_READ_FRAME,
    FLAC__STREAM_DECODER_END_OF_STREAM,
    FLAC__STREAM_DECODER_OGG_ERROR,
    FLAC__STREAM_DECODER_SEEK_ERROR,
    FLAC__STREAM_DECODER_ABORTED,
    FLAC__STREAM_DECODER_MEMORY_ALLOCATION_ERROR,
    FLAC__STREAM_DECODER_UNINITIALIZED
} FLAC__StreamDecoderState;

FLAC__StreamDecoderState FLAC__stream_decoder_get_state(const FLAC__StreamDecoder *) {
    return FLAC__STREAM_DECODER_UNINITIALIZED;
}

FLAC__StreamDecoderInitStatus FLAC__stream_decoder_init_FILE(
    FLAC__StreamDecoder *,
    FILE *,
    FLAC__StreamDecoderWriteCallback,
    FLAC__StreamDecoderMetadataCallback,
    FLAC__StreamDecoderErrorCallback,
    void *
) {
    return FLAC__STREAM_DECODER_INIT_STATUS_ERROR_OPENING_FILE;
}

FLAC__bool FLAC__stream_decoder_seek_absolute(FLAC__StreamDecoder *, FLAC__uint64) {
    return false;
}

FLAC__bool FLAC__stream_decoder_process_single(FLAC__StreamDecoder *) {
    return false;
}

} // extern "C"

// ============================================================================
// FLAC Encoder Stubs
// ============================================================================

extern "C" {

FLAC__StreamEncoder *FLAC__stream_encoder_new(void) {
    return nullptr;
}

void FLAC__stream_encoder_delete(FLAC__StreamEncoder *) {}

FLAC__bool FLAC__stream_encoder_set_bits_per_sample(FLAC__StreamEncoder *, unsigned) {
    return false;
}

FLAC__bool FLAC__stream_encoder_set_channels(FLAC__StreamEncoder *, unsigned) {
    return false;
}

FLAC__bool FLAC__stream_encoder_set_sample_rate(FLAC__StreamEncoder *, unsigned) {
    return false;
}

FLAC__bool FLAC__stream_encoder_set_total_samples_estimate(FLAC__StreamEncoder *, FLAC__uint64) {
    return false;
}

FLAC__StreamEncoderInitStatus FLAC__stream_encoder_init_FILE(
    FLAC__StreamEncoder *, FILE *, FLAC__StreamEncoderProgressCallback, void *
) {
    return FLAC__STREAM_ENCODER_INIT_STATUS_ENCODER_ERROR;
}

FLAC__bool FLAC__stream_encoder_process_interleaved(FLAC__StreamEncoder *, const FLAC__int32 *, unsigned) {
    return false;
}

FLAC__bool FLAC__stream_encoder_finish(FLAC__StreamEncoder *) {
    return false;
}

} // extern "C"

// ============================================================================
// FLAC Metadata Stubs
// ============================================================================

extern "C" {

FLAC__bool FLAC__metadata_get_streaminfo(const char *, FLAC__StreamMetadata *) {
    return false;
}

} // extern "C"

// ============================================================================
// MP3 Decoder Stubs (C++ linkage, not extern "C")
// ============================================================================

int mp3_recognize(int, const char *) {
    return 0;
}

MP3_FILE mp3f_new() {
    return nullptr;
}

void mp3f_delete(MP3_FILE) {}

void mp3f_set_file(MP3_FILE, FILE *) {}

int mp3f_analyze(MP3_FILE) {
    return -1;
}

unsigned mp3f_frequency(MP3_FILE) {
    return 0;
}

unsigned mp3f_channels(MP3_FILE) {
    return 0;
}

MP3F_OFFSET mp3f_samples(MP3_FILE) {
    return 0;
}

void mp3f_set_callback(MP3_FILE, MP3F_CALLBACK, void *) {}

int mp3f_seek(MP3_FILE, MP3F_OFFSET) {
    return -1;
}

int mp3f_read(MP3_FILE, MP3F_OFFSET) {
    return -1;
}

// ============================================================================
// Status Strings - Must be extern arrays visible to linker
// ============================================================================

// Define FLAC_API for visibility
#ifndef FLAC_API
#  if defined(__GNUC__) && __GNUC__ >= 4
#    define FLAC_API __attribute__ ((visibility ("default")))
#  else
#    define FLAC_API
#  endif
#endif

// These arrays are referenced by melder_audiofiles.cpp
// NOTE: Must NOT be const to ensure external linkage in C++
extern "C" {
FLAC_API const char* FLAC__StreamDecoderErrorStatusString[] = {
    "LOST_SYNC", "BAD_HEADER", "FRAME_CRC_MISMATCH", "UNPARSEABLE_STREAM"
};

FLAC_API const char* FLAC__StreamDecoderInitStatusString[] = {
    "OK", "ERROR_OPENING_FILE"
};

FLAC_API const char* FLAC__StreamEncoderInitStatusString[] = {
    "OK", "ENCODER_ERROR"
};
}
