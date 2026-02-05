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
/* Sound_extensions stubs
 * Stubs for Sound extension functions that require unavailable dependencies
 */

#include "praat.github.io/fon/Sound.h"
#include "melder.h"

autoSound Sound_resampleAndOrPreemphasize (constSound me, double maximumFrequency, integer depth, double preEmphasisFrequency) {
	Melder_throw (U"Sound_resampleAndOrPreemphasize: This advanced resampling function is not available.");
}
