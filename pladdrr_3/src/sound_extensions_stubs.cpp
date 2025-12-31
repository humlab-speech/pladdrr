/* Sound_extensions stubs
 * Stubs for Sound extension functions that require unavailable dependencies
 */

#include "praat.github.io/fon/Sound.h"
#include "melder.h"

autoSound Sound_resampleAndOrPreemphasize (constSound me, double maximumFrequency, integer depth, double preEmphasisFrequency) {
	Melder_throw (U"Sound_resampleAndOrPreemphasize: This advanced resampling function is not available.");
}
