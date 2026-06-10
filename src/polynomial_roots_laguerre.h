/*
 * polynomial_roots_laguerre.h — Laguerre's method for polynomial root-finding
 * Part of pladdrr: R interface to Praat
 *
 * Used as fallback in burg() when LAPACK dhseqr_ fails to find all eigenvalues
 * on ill-conditioned Hessenberg matrices from short audio windows (BUG-1 fix).
 *
 * Algorithm: Laguerre's method with polynomial deflation.
 * This is numerically robust for polynomials whose companion matrix is ill-conditioned,
 * which is exactly the failure mode of dhseqr_ on short-window LPC.
 *
 * Functions extracted from formant_lpc_simd.cpp (was gated by HAVE_XSIMD
 * but contains no SIMD code — only std::complex<double> arithmetic).
 */

#pragma once
#include <complex>
#include <cmath>
#include <vector>

static inline void prl_eval_and_derivs(
    const std::vector<std::complex<double>>& coeffs,
    std::complex<double> x,
    std::complex<double>& p,
    std::complex<double>& p1,
    std::complex<double>& p2
) {
    int n = (int)coeffs.size() - 1;
    p  = coeffs[n];
    p1 = {0.0, 0.0};
    p2 = {0.0, 0.0};
    for (int i = n - 1; i >= 0; --i) {
        p2 = p2 * x + 2.0 * p1;
        p1 = p1 * x + p;
        p  = p  * x + coeffs[i];
    }
}

static inline std::complex<double> prl_laguerre_step(
    const std::vector<std::complex<double>>& coeffs,
    std::complex<double> x0,
    int max_iter = 100,
    double tol   = 1e-10
) {
    std::complex<double> x = x0;
    int n = (int)coeffs.size() - 1;
    for (int iter = 0; iter < max_iter; ++iter) {
        std::complex<double> p, p1, p2;
        prl_eval_and_derivs(coeffs, x, p, p1, p2);
        if (std::abs(p) < tol) return x;
        std::complex<double> G = p1 / p;
        std::complex<double> H = G * G - p2 / p;
        std::complex<double> sq = std::sqrt(std::complex<double>(n - 1) * (std::complex<double>(n) * H - G * G));
        std::complex<double> d1 = G + sq, d2 = G - sq;
        std::complex<double> d = (std::abs(d1) > std::abs(d2)) ? d1 : d2;
        if (std::abs(d) < 1e-14) break;
        std::complex<double> dx = std::complex<double>(n) / d;
        x = x - dx;
        if (std::abs(dx) < tol) return x;
    }
    return x;
}

static inline void prl_deflate(
    std::vector<std::complex<double>>& coeffs,
    std::complex<double> root
) {
    int n = (int)coeffs.size() - 1;
    std::vector<std::complex<double>> q(n);
    q[n - 1] = coeffs[n];
    for (int i = n - 2; i >= 0; --i)
        q[i] = coeffs[i + 1] + root * q[i + 1];
    coeffs = q;
}

/*
 * polynomial_roots_laguerre — find all n roots of a degree-n polynomial.
 *
 * @param coeffs  Coefficients in ascending degree order: coeffs[0] + coeffs[1]*z + ... + coeffs[n]*z^n
 * @param roots   Output array of length n_roots
 * @param n_roots Degree of polynomial (number of roots to find)
 *
 * Uses evenly-spaced initial guesses on the unit circle and deflation after each root.
 */
inline void polynomial_roots_laguerre(
    const std::vector<std::complex<double>>& coeffs,
    std::complex<double>* roots,
    int n_roots
) {
    std::vector<std::complex<double>> working = coeffs;
    for (int i = 0; i < n_roots; ++i) {
        double angle = 2.0 * M_PI * (i + 0.5) / n_roots;
        std::complex<double> x0{std::cos(angle), std::sin(angle)};
        std::complex<double> root = prl_laguerre_step(working, x0);
        roots[i] = root;
        if (i < n_roots - 1)
            prl_deflate(working, root);
    }
}
