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
// MP3 stub implementations (FLAC is decoded natively by the vendored libFLAC)
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

