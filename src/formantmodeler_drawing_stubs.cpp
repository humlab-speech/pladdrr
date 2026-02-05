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
// formantmodeler_drawing_stubs.cpp
// Stub for FormantModeler drawing functions that have signature mismatches
// These are not needed in library mode (NO_GRAPHICS)

// Forward declarations only
struct structGraphics;
typedef structGraphics* Graphics;
struct structFormantModeler;
typedef structFormantModeler* FormantModeler;

// MelderColour is struct with rgba components
struct MelderColour {
    double red, green, blue, transparency;
};

// Stub for FormantModeler_speckle_inside with header signature
// Header: (..., bool, integer, bool, ...)
// Implementation: (..., bool, bool, ...)  
// We provide the header signature to satisfy FormantModelerList.o
extern "C" void FormantModeler_speckle_inside(FormantModeler me, Graphics g, double xmin, double xmax, double fmax,
    long fromTrack, long toTrack, bool useEstimatedTrack, long numberOfParameters, bool errorBars,
    MelderColour oddTracks, MelderColour evenTracks) {
    // Drawing function not needed for library mode
    (void) me; (void) g; (void) xmin; (void) xmax; (void) fmax;
    (void) fromTrack; (void) toTrack; (void) useEstimatedTrack; (void) numberOfParameters;
    (void) errorBars; (void) oddTracks; (void) evenTracks;
}
