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
/* Wrapper functions for R's LAPACK that match Praat's expected signatures */

/* Opt in to Fortran hidden character-length arguments so the declarations
   (and our explicit trailing length args below) are identical on all
   supported R versions; R-devel makes this the default. */
#ifndef USE_FC_LEN_T
#define USE_FC_LEN_T
#endif
#include <R_ext/BLAS.h>
#include <R_ext/Lapack.h>
#ifndef FCONE
#define FCONE
#endif

extern "C" {

/* R's LAPACK functions add FCLEN macros for character length, 
   but Praat's code doesn't expect them. We wrap them here.
   Note: R's LAPACK functions return void, but Praat expects int return values.
   We convert void to int (always returning 0). */

double dlamch_wrap_int(const char* cmach) {
    return F77_CALL(dlamch)(cmach, 1);
}

int dgeev_wrap_int(const char* jobvl, const char* jobvr, int* n, double* a, int* lda,
                   double* wr, double* wi, double* vl, int* ldvl,
                   double* vr, int* ldvr, double* work, int* lwork, int* info) {
    F77_CALL(dgeev)(jobvl, jobvr, n, a, lda, wr, wi, vl, ldvl, vr, ldvr, work, lwork, info, 1, 1);
    return 0;
}

int dgesvd_wrap_int(const char* jobu, const char* jobvt, int* m, int* n, double* a,
                    int* lda, double* s, double* u, int* ldu,
                    double* vt, int* ldvt, double* work, int* lwork, int* info) {
    F77_CALL(dgesvd)(jobu, jobvt, m, n, a, lda, s, u, ldu, vt, ldvt, work, lwork, info, 1, 1);
    return 0;
}

int dggsvd_wrap_int(const char* jobu, const char* jobv, const char* jobq, int* m, int* n, int* p,
                    int* k, int* l, double* a, int* lda, double* b, int* ldb,
                    double* alpha, double* beta, double* u, int* ldu,
                    double* v, int* ldv, double* q, int* ldq,
                    double* work, int* iwork, int* info) {
    F77_CALL(dggsvd)(jobu, jobv, jobq, m, n, p, k, l, a, lda, b, ldb,
                     alpha, beta, u, ldu, v, ldv, q, ldq, work, iwork, info, 1, 1, 1);
    return 0;
}

int dhseqr_wrap_int(const char* job, const char* compz, int* n, int* ilo, int* ihi,
                    double* h, int* ldh, double* wr, double* wi,
                    double* z, int* ldz, double* work, int* lwork, int* info) {
    F77_CALL(dhseqr)(job, compz, n, ilo, ihi, h, ldh, wr, wi, z, ldz, work, lwork, info, 1, 1);
    return 0;
}

int dsyev_wrap_int(const char* jobz, const char* uplo, int* n, double* a, int* lda,
                   double* w, double* work, int* lwork, int* info) {
    F77_CALL(dsyev)(jobz, uplo, n, a, lda, w, work, lwork, info, 1, 1);
    return 0;
}

int dtrtri_wrap_int(const char* uplo, const char* diag, int* n, double* a, int* lda, int* info) {
    F77_CALL(dtrtri)(uplo, diag, n, a, lda, info, 1, 1);
    return 0;
}

int dtrti2_wrap_int(const char* uplo, const char* diag, int* n, 
                    double* a, int* lda, int* info) {
    F77_CALL(dtrti2)(uplo, diag, n, a, lda, info, 1, 1);
    return 0;
}

int dsytrf_wrap_int(const char* uplo, int* n, double* a, int* lda,
                    int* ipiv, double* work, int* lwork, int* info) {
    F77_CALL(dsytrf)(uplo, n, a, lda, ipiv, work, lwork, info, 1);
    return 0;
}

int dsytri_wrap_int(const char* uplo, int* n, double* a, int* lda, int* ipiv,
                    double* work, int* info) {
    F77_CALL(dsytri)(uplo, n, a, lda, ipiv, work, info, 1);
    return 0;
}

int dpotf2_wrap_int(const char* uplo, int* n, double* a, int* lda, int* info) {
    F77_CALL(dpotf2)(uplo, n, a, lda, info, 1);
    return 0;
}

} // extern "C"
