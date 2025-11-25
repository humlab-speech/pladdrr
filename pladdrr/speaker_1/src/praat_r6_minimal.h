// Minimal Praat wrapper header for R6 integration
// Includes only essential types and functions

#ifndef PRAAT_R6_MINIMAL_H
#define PRAAT_R6_MINIMAL_H

// C++ compatibility
#ifdef __cplusplus
extern "C" {
#endif

// Minimal type definitions from Praat
typedef long integer;
typedef double *double_ptr;

// Praat's autoThing template forward declaration
template <class T> class autoThing;

// Sound type forward declarations
struct structSound;
typedef struct structSound *Sound;
typedef autoThing<struct structSound> autoSound;

// Pitch type forward declarations  
struct structPitch;
typedef struct structPitch *Pitch;
typedef autoThing<struct structPitch> autoPitch;

// Essential Praat functions we need
// Note: These will need to be linked from Praat library

// Memory management
void forget (void *thing);

// Sound I/O
Sound Sound_readFromSoundFile (const char32 *path);
void Sound_writeToWavFile (Sound me, const char32 *path);
void Sound_writeToAiffFile (Sound me, const char32 *path);

// Sound creation - NOTE: Actual declaration is in fon/Sound.h
// autoSound Sound_create (...) - use the one from Sound.h

// Sound manipulation
void Sound_scaleIntensity (Sound me, double newAverageIntensity);
Sound Sound_extractPart (Sound me, double tmin, double tmax,
                        int windowShape, double relativeWidth, int preserveTimes);

// Pitch analysis
Pitch Sound_to_Pitch_ac (Sound me, double timeStep, double pitchFloor,
                        double maxnCandidates, int veryAccurate,
                        double silenceThreshold, double voicingThreshold,
                        double octaveCost, double octaveJumpCost,
                        double voicedUnvoicedCost, double pitchCeiling);

// Pitch queries
double Pitch_getMean (Pitch me, double tmin, double tmax, int unit);
double Pitch_getMinimum (Pitch me, double tmin, double tmax, int unit, int interpolate);
double Pitch_getMaximum (Pitch me, double tmin, double tmax, int unit, int interpolate);
double Pitch_getQuantile (Pitch me, double tmin, double tmax, double quantile, int unit);
double Pitch_getValueAtTime (Pitch me, double time, int unit, int interpolate);

// Utility functions
double Sampled_indexToX (void *me, integer i);
double Vector_getValueAtX (void *me, double x, integer channel, int interpolation);

// String conversion
const char32 * Melder_peek8to32 (const char *string);

// Constants
#define undefined 1e308
#define kPitch_unit_HERTZ 1
#define kPitch_unit_SEMITONES_100 2
#define kSound_windowShape_RECTANGULAR 1
#define Vector_VALUE_INTERPOLATION_LINEAR 1

#ifdef __cplusplus
}
#endif

#endif // PRAAT_R6_MINIMAL_H
