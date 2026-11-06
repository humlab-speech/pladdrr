/*
 * Part of pladdrr: R interface to Praat
 *
 * Copyright (C) 2026 Fredrik Nylén
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or (at
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */
// pladdrr_thread_thresholds.h — minimum work per thread at the two frame-parallel
// analysis sites that pladdrr retunes (see audit/2026-11/fixes/F-power-02.md).
//
// MelderThread_computeNumberOfThreads() turns a work size into a thread count by
// dividing the frame count by 1.5 times this threshold, then clipping to the
// concurrent-thread cap. The constant is therefore a floor *per grain*: the
// amount of work a thread must be handed to be worth waking. It is deliberately
// not scaled by the number of cores - what a grain has to cover is the cost of
// one spawn plus that thread's own buffers, which does not depend on how many
// cores exist; the core count only limits how many grains run at once, and the
// cap already handles that.
//
// Both values are a small multiple of the measured break-even (grain cost ==
// thread cost), rounded: 3x for the cepstrogram, 5x for the formant. Medians of
// 5 blocks of 20 calls on a 3 s / 16 kHz clip, 8 physical CPUs
// (`taskset -c 8-15`), from audit/2026-11/evidence/012/throff012.R
// (output: cost-curve-base.txt):
//
//   cepstrogram  23.1 ms serial over 1451 frames = 16 us/frame, and 1.25 ms of
//                extra CPU for each thread added (T=1..8: 23.1, 23.9, 24.2, 25.5,
//                26.7, 28.4, ..., 31.9 ms - that is its own NUMFourierTable,
//                Sound, Spectrum and PowerCepstrum) => break-even ~79 frames.
//   formant      23.3 ms serial over 591 frames = 39 us/frame, and 0.31 ms per
//                thread added (T=1..8: 23.3, 24.1, 24.5, 25.1, 25.5, 25.4, ...,
//                25.5 ms - two VECs) => break-even ~8 frames.
//
// The previous values (40 and 3) sat below break-even: one 3 s clip asked for 24
// and 32 threads, costing 7.0x and 1.8x the serial CPU-seconds while being
// *slower* in wall clock than a 4-8 thread cap. Threads only partition frames and
// each frame is written independently, so changing the count cannot change
// results - asserted in tests/testthat/test-thread-granularity.R.

#ifndef PLADDRR_THREAD_THRESHOLDS_H
#define PLADDRR_THREAD_THRESHOLDS_H

// LPC/Sound_to_PowerCepstrogram.cpp. A 3 s clip at the default
// time_step = 0.002 (1451 frames) gets 4 threads instead of the 24 it used to
// ask for (6x less CPU); clips under ~1.22 s (563 frames is the first grain the
// review re-measured empirically) stay on the calling thread, and from ~24 s on
// the machine is full again.
#define PLADDRR_CEPSTROGRAM_FRAMES_PER_THREAD 250

// fon/Sound_to_Formant.cpp. Also the value every sibling LPC/formant site
// (LPC_and_Formant.cpp, Sound_and_LPC.cpp, Sound_to_Formant_mt.cpp,
// LPC_and_LineSpectralFrequencies.cpp) already uses. A 3 s clip at the default
// time_step = 0.005 (596 frames) gets 10 threads instead of all 32; clips under
// ~0.50 s (90 frames is the first grain measured to parallelise) stay on the
// calling thread.
//
// The 1.25 ms/thread above is pinned to 8 physical CPUs. Unpinned on this 32
// logical core box the marginal cost is superlinear (cap 8 = 40.3 ms, 16 = 82.3,
// 24 = 163.7 CPU-ms), which would put break-even nearer 300-400 frames; 250 is
// right for the pinned/physical-core case the audit measured and conservative
// (never slower than serial) for the other.
#define PLADDRR_FORMANT_FRAMES_PER_THREAD 40

#endif // PLADDRR_THREAD_THRESHOLDS_H
