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
// Minimal implementation of Sound_createGaussian for PowerCepstrogram support
// Extracted from praat.github.io/dwtools/Sound_extensions.cpp

#include "praat.github.io/fon/Sound.h"
#include "praat.github.io/melder/NUM.h"

// Fill window with window shape values
void windowShape_into_VEC (kSound_windowShape windowShape, VEC inout_window) {
	const integer size = inout_window.size;
	const double imid = 0.5 * (double) (size + 1);
	double edge, onebyedge, factor;
	switch (windowShape) {
		case kSound_windowShape::RECTANGULAR:
			inout_window  <<=  1.0;
			break; 
		case kSound_windowShape::TRIANGULAR:
			for (integer i = 1; i <= size; i ++) {
				const double phase = (double) (i - 0.5) / size;
				inout_window [i] = 1.0 - fabs ((2.0 * phase - 1.0));
			}
			break;
		case kSound_windowShape::PARABOLIC:
			for (integer i = 1; i <= size; i ++) { 
				const double phase = (double) (i - 0.5) / size;
				inout_window [i] = 1.0 - (2.0 * phase - 1.0) * (2.0 * phase - 1.0);
			}
			break;
		case kSound_windowShape::HANNING:
			for (integer i = 1; i <= size; i ++) {
				const double phase = (double) (i - 0.5) / size;
				inout_window [i] = 0.5 * (1.0 - cos (NUM2pi * phase));
			}
			break;
		case kSound_windowShape::HAMMING:
			for (integer i = 1; i <= size; i ++) { 
				const double phase = (double) (i - 0.5) / size;
				inout_window [i] = 0.54 - 0.46 * cos (NUM2pi * phase);
			}
			break;
		case kSound_windowShape::GAUSSIAN_1:
			edge = exp (-3.0);
			onebyedge = 1.0 / (1.0 - edge);
			for (integer i = 1; i <= size; i ++) {
				const double phase = ((double) i - imid) / size;
				inout_window [i] = (exp (-12.0 * phase * phase) - edge) * onebyedge;
			}
			break;
		case kSound_windowShape::GAUSSIAN_2:
			edge = exp (-12.0);
			onebyedge = 1.0 / (1.0 - edge);
			for (integer i = 1; i <= size; i ++) {
				const double phase = ((double) i - imid) / size;
				inout_window [i] = (exp (-48.0 * phase * phase) - edge) * onebyedge;
			}
			break;
		case kSound_windowShape::GAUSSIAN_3:
			edge = exp (-27.0);
			onebyedge = 1.0 / (1.0 - edge);
			for (integer i = 1; i <= size; i ++) {
				const double phase = ((double) i - imid) / size;
				inout_window [i] = (exp (-108.0 * phase * phase) - edge) * onebyedge;
			}
			break;
		case kSound_windowShape::GAUSSIAN_4:
			edge = exp (-48.0);
			onebyedge = 1.0 / (1.0 - edge);
			for (integer i = 1; i <= size; i ++) { 
				const double phase = ((double) i - imid) / size;
				inout_window [i] = (exp (-192.0 * phase * phase) - edge) * onebyedge; 
			}
			break;
		case kSound_windowShape::GAUSSIAN_5:
			edge = exp (-75.0);
			onebyedge = 1.0 / (1.0 - edge);
			for (integer i = 1; i <= size; i ++) {
				const double phase = ((double) i - imid) / size;
				inout_window [i] = (exp (-300.0 * phase * phase) - edge) * onebyedge;
			}
			break;
		case kSound_windowShape::KAISER_1:
			factor = 1.0 / NUMbessel_i0_f (NUM2pi);
			for (integer i = 1; i <= size; i ++) {
				const double phase = 2.0 * ((double) i - imid) / size;
				const double root = 1.0 - phase * phase;
				inout_window [i] = ( root <= 0.0 ? 0.0 : factor * NUMbessel_i0_f (NUM2pi * sqrt (root)) );
			}
			break;
		case kSound_windowShape::KAISER_2:
			factor = 1.0 / NUMbessel_i0_f (NUM2pi * NUMpi + 0.5);
			for (integer i = 1; i <= size; i ++) {
				const double phase = 2.0 * ((double) i - imid) / size;
				const double root = 1.0 - phase * phase;
				inout_window [i] = ( root <= 0.0 ? 0.0 : factor * NUMbessel_i0_f ((NUM2pi * NUMpi + 0.5) * sqrt (root)) ); 
			}
			break;
		default:
			inout_window  <<=  1.0;
	}
}

// Create a Gaussian window sound
autoSound Sound_createGaussian (double windowDuration, double samplingFrequency) {
	try {
		autoSound me = Sound_createSimple (1, windowDuration, samplingFrequency);
		VEC s = my z.row (1);
		const double imid = 0.5 * (my nx + 1), edge = exp (-12.0);
		for (integer i = 1; i <= my nx; i ++) {
			const double phase = (i - imid) / my nx;
			s [i] = (exp (-48.0 * phase * phase) - edge) / (1 - edge);
		}
		return me;
	} catch (MelderError) {
		Melder_throw (U"Sound not created from Gaussian function.");
	}
}

// Create a Hamming window sound
autoSound Sound_createHamming (double windowDuration, double samplingFrequency) {
	try {
		autoSound me = Sound_createSimple (1, windowDuration, samplingFrequency);
		const double p = NUM2pi / (my nx - 1);
		for (integer i = 1; i <= my nx; i ++)
			my z [1] [i] = 0.54 - 0.46 * cos ((i - 1) * p);
		return me;
	} catch (MelderError) {
		Melder_throw (U"Sound not created from Hamming function.");
	};
}

// Multiply two sounds element-wise
void Sounds_multiply (Sound me, Sound thee) {
	const integer n = std::min (my nx, thy nx );
	my z.row (1).part (1, n)  *=  thy z.row (1).part (1, n);
}

// Copy portion of sound into another sound
void Sound_into_Sound (Sound me, Sound to, double startTime) {
	const integer index = Sampled_xToNearestIndex (me, startTime);
	for (integer i = 1; i <= to -> nx; i ++) {
		const integer j = index - 1 + i;
		to -> z [1] [i] = (j < 1 || j > my nx ? 0.0 : my z [1] [j]);
	}
}
