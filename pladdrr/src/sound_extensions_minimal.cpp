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
