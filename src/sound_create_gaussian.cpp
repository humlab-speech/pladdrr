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
#include "praat.github.io/fon/Vector.h"
#include "praat.github.io/melder/NUM.h"
#include "praat.github.io/fon/Sound_and_Spectrum.h"

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

// Helper: create a Sound from minimumTime/maximumTime/samplingFrequency
// (replicated from Sound_extensions.cpp where it is static)
static autoSound Sound_create2 (double minimumTime, double maximumTime, double samplingFrequency) {
	return Sound_create (1, minimumTime, maximumTime, Melder_iround ( (maximumTime - minimumTime) * samplingFrequency),
		1.0 / samplingFrequency, minimumTime + 0.5 / samplingFrequency);
}

// Create a gamma-tone sound (needed for SPINET)
autoSound Sound_createGammaTone (double minimumTime, double maximumTime, double samplingFrequency, double gamma, double frequency, double bandwidth, double initialPhase, double addition, bool scaleAmplitudes) {
	try {
		autoSound me = Sound_create2 (minimumTime, maximumTime, samplingFrequency);
		for (integer i = 1; i <= my nx; i ++) {
			const double t = (i - 0.5) * my dx;
			const double f = frequency + addition / (NUM2pi * t);
			if (f > 0 && f < samplingFrequency / 2)
				my z [1] [i] = pow (t, gamma - 1.0) * exp (- NUM2pi * bandwidth * t) *
					cos (NUM2pi * frequency * t + addition * log (t) + initialPhase);
		}
		if (scaleAmplitudes)
			Vector_scale (me.get(), 0.99996948);
		return me;
	} catch (MelderError) {
		Melder_throw (U"Sound not created from gammatone function.");
	}
}

// Sound power (RMS-like measure, needed for SPINET)
double Sound_power (Sound me) {
	const double sumSq = NUMsum2 (my z.row (1));
	return sqrt (sumSq) * my dx / (my xmax - my xmin);
}

// Correlate two parts of a sound (needed for SHS)
double Sound_correlateParts (Sound me, double tx, double ty, double duration) {
	if (ty < tx)
		std::swap (tx, ty);
	const integer nbx = Sampled_xToNearestIndex (me, tx);
	const integer nby = Sampled_xToNearestIndex (me, ty);
	const integer ney = Sampled_xToNearestIndex (me, ty + duration);
	const integer increment = nbx < 1 ? 1 - nbx : 0;
	const integer decrement = ney > my nx ? ney - my nx : 0;
	const integer ns = Melder_ifloor (duration / my dx) - increment - decrement;
	if (ns < 1)
		return 0.0;

	const double *x = & my z [1] [nbx + increment - 1];
	const double *y = & my z [1] [nby + increment - 1];
	double xm = 0.0, ym = 0.0;
	for (integer i = 1; i <= ns; i ++) {
		xm += x [i];
		ym += y [i];
	}
	xm /= ns;
	ym /= ns;
	double sxx = 0.0, syy = 0.0, sxy = 0.0;
	for (integer i = 1; i <= ns; i ++) {
		const double xt = x [i] - xm, yt = y [i] - ym;
		sxx += xt * xt;
		syy += yt * yt;
		sxy += xt * yt;
	}
	const double denum = sxx * syy;
	const double rxy = ( denum > 0.0 ? sxy / sqrt (denum) : 0.0 );
	return rxy;
}

// Local peak of sound relative to reference (needed for SHS)
double Sound_localPeak (Sound me, double fromTime, double toTime, double reference) {
	integer n1 = Sampled_xToNearestIndex (me, fromTime);
	integer n2 = Sampled_xToNearestIndex (me, toTime);
	const double *s = & my z [1] [0];
	double peak = -1e308;
	if (fromTime <= toTime) {
		if (n1 < 1)
			n1 = 1;
		if (n2 > my nx)
			n2 = my nx;
		for (integer i = n1; i <= n2; i ++) {
			const double ds = fabs (s [i] - reference);
			if (ds > peak)
				peak = ds;
		}
	}
	return peak;
}
