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

#endif // PRAAT_TYPES_H
