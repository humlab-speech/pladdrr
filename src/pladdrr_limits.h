/*
 * Part of pladdrr: R interface to Praat
 *
 * Copyright (C) 2026 Fredrik Nylén
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or (at
 * your option) any later version.
 */
// pladdrr_limits.h — upper bounds on allocations that an R-visible step size can
// request. Praat asks the allocator for whatever 25.6 / step comes to; with
// df = 1e-9 that is a 2.5 TB tensor. Linux refuses it and Praat reports an error,
// but macOS commits the pages and the kernel SIGKILLs the whole R session
// (exit 137, uncatchable), so the request has to be refused before it is made.
#ifndef PLADDRR_LIMITS_H
#define PLADDRR_LIMITS_H

// Cells (8 bytes each) of a Cochleagram: 2^29 = 4 GiB, i.e. about 5.8 hours of
// audio at the default 10 ms x 0.1 Bark steps.
#define PLADDRR_MAX_TENSOR_CELLS ((integer) 536870912)

// Bands of an Excitation. Spectrum_to_Excitation convolves in O(bands^2); the
// default 0.1 Bark step is 256 bands.
#define PLADDRR_MAX_EXCITATION_BANDS ((integer) 10000)

#endif // PLADDRR_LIMITS_H
