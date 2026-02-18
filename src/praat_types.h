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
// praat_types.h - Forward declarations for Praat types used in Rcpp
//
// This header provides forward declarations and type definitions for Praat
// types used in Rcpp exported functions. It must be included before RcppExports.cpp

#ifndef PRAAT_TYPES_H
#define PRAAT_TYPES_H

#include <cstdint>  // For intptr_t

// Praat's integer type (must match melder_int.h)
using integer = intptr_t;

// Forward declarations for Praat structs
struct structSound;
struct structPitch;
struct structFormant;
struct structIntensity;
struct structHarmonicity;
struct structSpectrogram;
struct structSpectrum;
struct structTextGrid;
struct structPointProcess;
struct structManipulation;
struct structLPC;
struct structLtas;
struct structInterpreter;
struct structPitchTier;
struct structFormantTier;
struct structIntensityTier;
struct structDurationTier;
struct structMelSpectrogram;
struct structBarkSpectrogram;
struct structBandFilterSpectrogram;
struct structMFCC;
struct structMatrix;
struct structAmplitudeTier;

#endif // PRAAT_TYPES_H
