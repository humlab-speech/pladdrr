#!/bin/bash
# Build minimal CLAPACK library for speaker package

# Core LAPACK functions needed by Praat (from NUMlapack.h):
# dlamch, dgeev, dgesvd, dggsvd, dhseqr, dpotf2, dsyev, dtrtri, dtrti2, dsytrf, dsytri

cd clapack

# These are the core routines we need from SRC
LAPACK_FUNCS="dlamch dgeev dgesvd dggsvd dhseqr dpotf2 dsyev dtrtri dtrti2 dsytrf dsytri"

echo "Building minimal CLAPACK for speaker package..."
echo "Required functions: $LAPACK_FUNCS"

# Note: Each of these functions depends on many other BLAS and LAPACK helpers
# We would need to trace all dependencies recursively

