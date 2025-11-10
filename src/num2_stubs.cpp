// num2_stubs.cpp
// Minimal stubs for NUM2 functions needed by Praat objects
// Avoids dependency on full NUM2.cpp which requires CLAPACK and GSL

#include "praat.github.io/melder/melder.h"
#include "praat.github.io/melder/NUMrandom.h"
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

