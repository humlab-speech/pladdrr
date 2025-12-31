// voice_quality_simd.cpp
// SIMD-optimized jitter and shimmer calculations
// Part of pladdrr Phase 5: Zero-copy & SIMD expansion

#include <Rcpp.h>
#include <cmath>

#ifdef HAVE_XSIMD
#include <xsimd/xsimd.hpp>
#endif

using namespace Rcpp;

// ============================================================================
// SIMD Jitter Calculations
// ============================================================================

// Compute absolute period-to-period differences using SIMD
// This is the core operation for jitter calculations
#ifdef HAVE_XSIMD
inline void compute_period_diffs_simd(const double* periods, int n, double* diffs) {
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;

    int i = 0;
    int diff_count = n - 1;

    // SIMD loop - process consecutive pairs
    for (; i + static_cast<int>(simd_size) < diff_count; i += simd_size) {
        batch p1 = xsimd::load_unaligned(&periods[i]);
        batch p2 = xsimd::load_unaligned(&periods[i + 1]);
        batch diff = xsimd::abs(p1 - p2);
        xsimd::store_unaligned(&diffs[i], diff);
    }

    // Scalar remainder
    for (; i < diff_count; ++i) {
        diffs[i] = std::fabs(periods[i] - periods[i + 1]);
    }
}
#endif

// Scalar fallback
inline void compute_period_diffs_scalar(const double* periods, int n, double* diffs) {
    for (int i = 0; i < n - 1; ++i) {
        diffs[i] = std::fabs(periods[i] - periods[i + 1]);
    }
}

//' Compute jitter metrics from period array (SIMD-optimized)
//' @param periods Numeric vector of period durations
//' @return List with jitter_local, jitter_local_absolute, jitter_rap, jitter_ppq5, jitter_ddp
// [[Rcpp::export(.jitter_from_periods_simd)]]
List jitter_from_periods_simd(NumericVector periods) {
    int n = periods.size();

    if (n < 2) {
        return List::create(
            Named("jitter_local") = NA_REAL,
            Named("jitter_local_absolute") = NA_REAL,
            Named("jitter_rap") = NA_REAL,
            Named("jitter_ppq5") = NA_REAL,
            Named("jitter_ddp") = NA_REAL,
            Named("n_periods") = n
        );
    }

    const double* p = REAL(periods);
    std::vector<double> diffs(n - 1);

#ifdef HAVE_XSIMD
    compute_period_diffs_simd(p, n, diffs.data());
#else
    compute_period_diffs_scalar(p, n, diffs.data());
#endif

    // Mean period (for relative jitter)
    double mean_period = 0.0;
    for (int i = 0; i < n; ++i) {
        mean_period += p[i];
    }
    mean_period /= n;

    // Jitter local absolute = mean of |p[i] - p[i+1]|
    double sum_diffs = 0.0;
    for (int i = 0; i < n - 1; ++i) {
        sum_diffs += diffs[i];
    }
    double jitter_local_abs = sum_diffs / (n - 1);

    // Jitter local = jitter_local_abs / mean_period
    double jitter_local = jitter_local_abs / mean_period;

    // Jitter RAP (3-point running average perturbation)
    double jitter_rap = NA_REAL;
    if (n >= 3) {
        double sum_rap = 0.0;
        for (int i = 1; i < n - 1; ++i) {
            double avg3 = (p[i-1] + p[i] + p[i+1]) / 3.0;
            sum_rap += std::fabs(p[i] - avg3);
        }
        jitter_rap = (sum_rap / (n - 2)) / mean_period;
    }

    // Jitter PPQ5 (5-point running average perturbation)
    double jitter_ppq5 = NA_REAL;
    if (n >= 5) {
        double sum_ppq5 = 0.0;
        for (int i = 2; i < n - 2; ++i) {
            double avg5 = (p[i-2] + p[i-1] + p[i] + p[i+1] + p[i+2]) / 5.0;
            sum_ppq5 += std::fabs(p[i] - avg5);
        }
        jitter_ppq5 = (sum_ppq5 / (n - 4)) / mean_period;
    }

    // Jitter DDP = 3 * RAP (by definition)
    double jitter_ddp = (jitter_rap != NA_REAL) ? 3.0 * jitter_rap : NA_REAL;

    return List::create(
        Named("jitter_local") = jitter_local,
        Named("jitter_local_absolute") = jitter_local_abs,
        Named("jitter_rap") = jitter_rap,
        Named("jitter_ppq5") = jitter_ppq5,
        Named("jitter_ddp") = jitter_ddp,
        Named("mean_period") = mean_period,
        Named("n_periods") = n
    );
}

// ============================================================================
// SIMD Shimmer Calculations
// ============================================================================

#ifdef HAVE_XSIMD
inline void compute_amplitude_diffs_simd(const double* amps, int n, double* diffs) {
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;

    int i = 0;
    int diff_count = n - 1;

    for (; i + static_cast<int>(simd_size) < diff_count; i += simd_size) {
        batch a1 = xsimd::load_unaligned(&amps[i]);
        batch a2 = xsimd::load_unaligned(&amps[i + 1]);
        batch diff = xsimd::abs(a1 - a2);
        xsimd::store_unaligned(&diffs[i], diff);
    }

    for (; i < diff_count; ++i) {
        diffs[i] = std::fabs(amps[i] - amps[i + 1]);
    }
}
#endif

inline void compute_amplitude_diffs_scalar(const double* amps, int n, double* diffs) {
    for (int i = 0; i < n - 1; ++i) {
        diffs[i] = std::fabs(amps[i] - amps[i + 1]);
    }
}

//' Compute shimmer metrics from amplitude array (SIMD-optimized)
//' @param amplitudes Numeric vector of peak amplitudes per period
//' @return List with shimmer_local, shimmer_local_db, shimmer_apq3, shimmer_apq5, shimmer_apq11, shimmer_dda
// [[Rcpp::export(.shimmer_from_amplitudes_simd)]]
List shimmer_from_amplitudes_simd(NumericVector amplitudes) {
    int n = amplitudes.size();

    if (n < 2) {
        return List::create(
            Named("shimmer_local") = NA_REAL,
            Named("shimmer_local_db") = NA_REAL,
            Named("shimmer_apq3") = NA_REAL,
            Named("shimmer_apq5") = NA_REAL,
            Named("shimmer_apq11") = NA_REAL,
            Named("shimmer_dda") = NA_REAL,
            Named("n_amplitudes") = n
        );
    }

    const double* a = REAL(amplitudes);
    std::vector<double> diffs(n - 1);

#ifdef HAVE_XSIMD
    compute_amplitude_diffs_simd(a, n, diffs.data());
#else
    compute_amplitude_diffs_scalar(a, n, diffs.data());
#endif

    // Mean amplitude
    double mean_amp = 0.0;
    for (int i = 0; i < n; ++i) {
        mean_amp += a[i];
    }
    mean_amp /= n;

    // Shimmer local = mean |A[i] - A[i+1]| / mean amplitude
    double sum_diffs = 0.0;
    for (int i = 0; i < n - 1; ++i) {
        sum_diffs += diffs[i];
    }
    double shimmer_local = (sum_diffs / (n - 1)) / mean_amp;

    // Shimmer local dB = mean |20*log10(A[i+1]/A[i])|
    double sum_db = 0.0;
    int valid_db = 0;
    for (int i = 0; i < n - 1; ++i) {
        if (a[i] > 0 && a[i+1] > 0) {
            sum_db += std::fabs(20.0 * std::log10(a[i+1] / a[i]));
            valid_db++;
        }
    }
    double shimmer_local_db = (valid_db > 0) ? sum_db / valid_db : NA_REAL;

    // Shimmer APQ3 (3-point amplitude perturbation quotient)
    double shimmer_apq3 = NA_REAL;
    if (n >= 3) {
        double sum_apq3 = 0.0;
        for (int i = 1; i < n - 1; ++i) {
            double avg3 = (a[i-1] + a[i] + a[i+1]) / 3.0;
            sum_apq3 += std::fabs(a[i] - avg3);
        }
        shimmer_apq3 = (sum_apq3 / (n - 2)) / mean_amp;
    }

    // Shimmer APQ5 (5-point amplitude perturbation quotient)
    double shimmer_apq5 = NA_REAL;
    if (n >= 5) {
        double sum_apq5 = 0.0;
        for (int i = 2; i < n - 2; ++i) {
            double avg5 = (a[i-2] + a[i-1] + a[i] + a[i+1] + a[i+2]) / 5.0;
            sum_apq5 += std::fabs(a[i] - avg5);
        }
        shimmer_apq5 = (sum_apq5 / (n - 4)) / mean_amp;
    }

    // Shimmer APQ11 (11-point amplitude perturbation quotient)
    double shimmer_apq11 = NA_REAL;
    if (n >= 11) {
        double sum_apq11 = 0.0;
        for (int i = 5; i < n - 5; ++i) {
            double avg11 = 0.0;
            for (int j = -5; j <= 5; ++j) {
                avg11 += a[i + j];
            }
            avg11 /= 11.0;
            sum_apq11 += std::fabs(a[i] - avg11);
        }
        shimmer_apq11 = (sum_apq11 / (n - 10)) / mean_amp;
    }

    // Shimmer DDA = 3 * APQ3 (by definition)
    double shimmer_dda = (shimmer_apq3 != NA_REAL) ? 3.0 * shimmer_apq3 : NA_REAL;

    return List::create(
        Named("shimmer_local") = shimmer_local,
        Named("shimmer_local_db") = shimmer_local_db,
        Named("shimmer_apq3") = shimmer_apq3,
        Named("shimmer_apq5") = shimmer_apq5,
        Named("shimmer_apq11") = shimmer_apq11,
        Named("shimmer_dda") = shimmer_dda,
        Named("mean_amplitude") = mean_amp,
        Named("n_amplitudes") = n
    );
}

// ============================================================================
// Batch Voice Quality Analysis
// ============================================================================

//' Compute complete voice quality metrics from periods and amplitudes
//' @param periods Numeric vector of period durations
//' @param amplitudes Numeric vector of peak amplitudes per period
//' @return List with all jitter and shimmer metrics
// [[Rcpp::export(.voice_quality_metrics_simd)]]
List voice_quality_metrics_simd(NumericVector periods, NumericVector amplitudes) {
    List jitter = jitter_from_periods_simd(periods);
    List shimmer = shimmer_from_amplitudes_simd(amplitudes);

    return List::create(
        Named("jitter_local") = jitter["jitter_local"],
        Named("jitter_local_absolute") = jitter["jitter_local_absolute"],
        Named("jitter_rap") = jitter["jitter_rap"],
        Named("jitter_ppq5") = jitter["jitter_ppq5"],
        Named("jitter_ddp") = jitter["jitter_ddp"],
        Named("shimmer_local") = shimmer["shimmer_local"],
        Named("shimmer_local_db") = shimmer["shimmer_local_db"],
        Named("shimmer_apq3") = shimmer["shimmer_apq3"],
        Named("shimmer_apq5") = shimmer["shimmer_apq5"],
        Named("shimmer_apq11") = shimmer["shimmer_apq11"],
        Named("shimmer_dda") = shimmer["shimmer_dda"],
        Named("mean_period") = jitter["mean_period"],
        Named("mean_amplitude") = shimmer["mean_amplitude"],
        Named("n_periods") = jitter["n_periods"],
        Named("n_amplitudes") = shimmer["n_amplitudes"]
    );
}
