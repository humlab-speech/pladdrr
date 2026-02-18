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
/* sound_extensions_minimal.cpp
 *
 * Minimal implementation of Sound_resampleAndOrPreemphasize
 * needed for PowerCepstrogram support.
 *
 * This is a subset extracted from praat.github.io/dwtools/Sound_extensions.cpp
 * to avoid dependencies on vorbis/opus/lame libraries.
 */

#include "praat.github.io/sys/Thing.h"
#include "praat.github.io/sys/Data.h"
#include "praat.github.io/fon/Sound.h"
#include "praat.github.io/fon/Sound_and_Spectrum.h"
#include "praat.github.io/fon/Sound_to_Pitch.h"
#include "praat.github.io/fon/Pitch.h"
#include "praat.github.io/fon/PitchTier.h"
#include "praat.github.io/fon/Pitch_to_PitchTier.h"
#include "praat.github.io/fon/Pitch_to_PointProcess.h"
#include "praat.github.io/fon/DurationTier.h"
#include "praat.github.io/fon/RealTier.h"
#include "praat.github.io/fon/Manipulation.h"
#include "praat.github.io/fon/Vector.h"

#define MAX_T  0.02000000001   /* Maximum interval between two voice pulses (otherwise voiceless). */

autoSound Sound_resampleAndOrPreemphasize (constSound me, double maximumFrequency, integer depth, double preEmphasisFrequency) {
	try {
		const double nyquistFrequency = 0.5 / my dx;
		autoSound sound;
		if (maximumFrequency <= 0.0 || fabs (maximumFrequency / nyquistFrequency - 1.0) < 1.0e-12)
			sound = Data_copy (me);
		else
			sound = Sound_resample (me, maximumFrequency * 2.0, depth);
		Sound_preEmphasize_inplace (sound.get(), preEmphasisFrequency);
		return sound;
	} catch (MelderError) {
		Melder_throw (me, U": could not resample.");
	}
}

/* Extracted from Sound_extensions.cpp to avoid codec (vorbis/opus/lame) dependencies */

static void PitchTier_modifyExcursionRange (PitchTier me, double tmin, double tmax, double multiplier, double fref_Hz) {
	if (! isdefined (fref_Hz) || fref_Hz <= 0.0) return;
	const double fref_st = 12.0 * log2 (fref_Hz);
	for (integer i = 1; i <= my points.size; i ++) {
		RealPoint point = my points.at [i];
		if (point -> number >= tmin && point -> number <= tmax) {
			const double f = point -> value;
			if (f > 0.0) {
				const double st = 12.0 * log2 (f) - fref_st;
				point -> value = fref_Hz * pow (2.0, multiplier * st / 12.0);
			}
		}
	}
}

static void Pitch_scaleDuration (Pitch me, double multiplier) {
	if (multiplier == 1.0) return;
	my xmin *= multiplier;
	my xmax *= multiplier;
	my x1 *= multiplier;
	my dx *= multiplier;
}

static void Pitch_scalePitch (Pitch me, double multiplier) {
	for (integer iframe = 1; iframe <= my nx; iframe ++) {
		Pitch_Frame frame = & my frames [iframe];
		for (integer icand = 1; icand <= frame -> nCandidates; icand ++) {
			Pitch_Candidate cand = & frame -> candidates [icand];
			if (cand -> frequency > 0.0 && cand -> frequency < my ceiling)
				cand -> frequency *= multiplier;
		}
	}
}

autoSound Sound_Pitch_changeSpeaker (Sound me, Pitch him,
	double formantMultiplier, double pitchMultiplier, double pitchRangeMultiplier, double durationMultiplier)
{
	try {
		const double samplingFrequency_old = 1.0 / my dx;
		Melder_require (my xmin == his xmin && my xmax == his xmax,
			U"The Pitch and the Sound object should have the same domain.");
		autoSound sound = Data_copy (me);
		Vector_subtractMean (sound.get());
		if (formantMultiplier != 1.0)
			Sound_overrideSamplingFrequency (sound.get(), samplingFrequency_old * formantMultiplier);
		autoPitch pitch = Data_copy (him);
		Pitch_scaleDuration (pitch.get(), 1.0 / formantMultiplier);
		Pitch_scalePitch (pitch.get(), formantMultiplier);
		autoPointProcess pulses = Sound_Pitch_to_PointProcess_cc (sound.get(), pitch.get());
		autoPitchTier pitchTier = Pitch_to_PitchTier (pitch.get());
		const double median = Pitch_getQuantile (pitch.get(), 0.0, 0.0, 0.5, kPitch_unit::HERTZ);
		if (isdefined (median) && median != 0.0) {
			PitchTier_multiplyFrequencies (pitchTier.get(), sound -> xmin, sound -> xmax,
				pitchMultiplier / formantMultiplier);
			PitchTier_modifyExcursionRange (pitchTier.get(), sound -> xmin, sound -> xmax,
				pitchRangeMultiplier, median);
		} else if (pitchMultiplier != 1) {
			Melder_warning (U"Pitch has not been changed because the sound was entirely voiceless.");
		}
		autoDurationTier duration = DurationTier_create (my xmin, my xmax);
		RealTier_addPoint (duration.get(), (my xmin + my xmax) / 2,
			formantMultiplier * durationMultiplier);
		autoSound thee = Sound_Point_Pitch_Duration_to_Sound (sound.get(), pulses.get(),
			pitchTier.get(), duration.get(), MAX_T);
		if (formantMultiplier != 1.0)
			thee = Sound_resample (thee.get(), samplingFrequency_old, 10);
		return thee;
	} catch (MelderError) {
		Melder_throw (U"Sound not created from Pitch & Sound.");
	}
}

autoSound Sound_changeSpeaker (Sound me, double pitchMin, double pitchMax,
	double formantMultiplier, double pitchMultiplier, double pitchRangeMultiplier, double durationMultiplier)
{
	try {
		autoPitch pitch = Sound_to_Pitch (me, 0.8 / pitchMin, pitchMin, pitchMax);
		return Sound_Pitch_changeSpeaker (me, pitch.get(), formantMultiplier,
			pitchMultiplier, pitchRangeMultiplier, durationMultiplier);
	} catch (MelderError) {
		Melder_throw (me, U": speaker not changed.");
	}
}
