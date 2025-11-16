// num2_stubs.cpp
// Minimal stubs for NUM2 functions needed by Praat objects
// Avoids dependency on full NUM2.cpp which requires CLAPACK and GSL

#include "praat.github.io/melder/melder.h"
#include "praat.github.io/melder/NUMrandom.h"
#include "praat.github.io/melder/VEC.h"
#include <cmath>

// Stub implementation of sinc functions (without GSL dependency)
double NUMsinc (const double x) {
    // sinc(x) = sin(x) / x, with sinc(0) = 1
    if (fabs(x) < 1e-10) return 1.0;
    return sin(x) / x;
}

double NUMsincpi (const double x) {
    // sincpi(x) = sin(pi*x) / (pi*x)
    if (fabs(x) < 1e-10) return 1.0;
    double pix = NUMpi * x;
    return sin(pix) / pix;
}

// Stub implementation of NUMrandomBinomial_real
// This is used by some PointProcess functions
double NUMrandomBinomial_real (double p, integer n) {
    // Simple implementation without CLAPACK dependency
    // For small n, use direct simulation
    if (n <= 0) return 0.0;
    if (p <= 0.0) return 0.0;
    if (p >= 1.0) return (double) n;
    
    // For larger n, use normal approximation
    if (n > 100) {
        double mean = n * p;
        double sd = sqrt(n * p * (1.0 - p));
        return mean + NUMrandomGauss(0.0, sd);
    }
    
    // For small n, use exact simulation
    integer count = 0;
    for (integer i = 1; i <= n; i++) {
        if (NUMrandomUniform(0.0, 1.0) < p) {
            count++;
        }
    }
    return (double) count;
}

// Stub for NUMrandomBinomial (integer version)
integer NUMrandomBinomial (double p, integer n) {
    return Melder_iround(NUMrandomBinomial_real(p, n));
}

// Beta function stub (simplified implementation)
double NUMbeta2 (double z, double w) {
    // beta(z,w) = gamma(z) * gamma(w) / gamma(z+w)
    // Using log gamma to avoid overflow: exp(lgamma(z) + lgamma(w) - lgamma(z+w))
    if (z <= 0.0 || w <= 0.0) return undefined;
    return exp(lgamma(z) + lgamma(w) - lgamma(z + w));
}

double NUMlnBeta (double a, double b) {
    // log(beta(a,b)) = lgamma(a) + lgamma(b) - lgamma(a+b)
    if (a <= 0.0 || b <= 0.0) return undefined;
    return lgamma(a) + lgamma(b) - lgamma(a + b);
}

// Stub for VECrc_from_lpc - converts LPC coefficients to reflection coefficients
// This is a complex numerical algorithm that would need full NUM2 implementation
void VECrc_from_lpc (VEC rc, constVEC lpc) {
    Melder_throw (U"VECrc_from_lpc is not available in this build (requires full NUM2 implementation).");
}

// Area-to-reflection coefficient conversion (needed by LPC)
void VECarea_from_rc (VEC area, constVEC rc) {
    Melder_assert (area.size == rc.size);
    longdouble s = 0.0001; // 1.0 cm^2 at glottis
    for (integer i = area.size; i > 0; i --) {
        s *= (1.0 + rc [i]) / (1.0 - rc [i]);
        area [i] = s;
    }
}

void VECrc_from_area (VEC rc, constVEC area) {
    Melder_assert (rc.size == area.size);
    double ar;
    for (integer j = 1; j <= rc.size - 1; j ++) {
        ar = area [j + 1] / area [j];
        rc [j] = (1.0 - ar) / (1.0 + ar);
    }
    ar = 0.0001 / area [rc.size];  // 1.0 cm^2 at glottis
    rc [rc.size] = (1.0 - ar) / (1.0 + ar);
}

void VECsolveSparse_IHT (VECVU const&, constMATVU const&, constVECVU const&, integer, integer, double, integer) {
    Melder_throw (U"VECsolveSparse_IHT is not available in this build (requires full NUM2 implementation).");
}

autoVEC solveSparse_IHT_VEC (constMATVU const&, constVECVU const&, integer, integer, double, integer) {
    Melder_throw (U"solveSparse_IHT_VEC is not available in this build (requires full NUM2 implementation).");
}

void windowShape_into_VEC (int, VEC) {
    Melder_throw (U"windowShape_into_VEC is not available in this build.");
}

// Define kSound_windowShape enum stub
enum kSound_windowShape { kSound_windowShape_SQUARE = 0 };
void windowShape_into_VEC (kSound_windowShape, VEC) {
    Melder_throw (U"windowShape_into_VEC is not available in this build.");
}

void VECfilterInverse_inplace (VEC const&, constVEC const&, VEC const&) {
    Melder_throw (U"VECfilterInverse_inplace is not available in this build.");
}


void VECsolveNonnegativeLeastSquaresRegression (VECVU const&, constMATVU const&, constVECVU const&, integer, double, integer) {
    Melder_throw (U"VECsolveNonnegativeLeastSquaresRegression is not available in this build.");
}

void solveWeaklyConstrainedLinearRegression_VEC (constMAT const&, constVEC const&, double, double) {
    Melder_throw (U"solveWeaklyConstrainedLinearRegression_VEC is not available in this build.");
}

void VECburg (VEC const&, constVEC const&) {
    Melder_throw (U"VECburg (Burg algorithm) is not available in this build.");
}

void solve_MAT (constMATVU const&, constMATVU const&, double) {
    Melder_throw (U"solve_MAT is not available in this build.");
}

void solve_VEC (constMATVU const&, constVECVU const&, double) {
    Melder_throw (U"solve_VEC is not available in this build.");
}
