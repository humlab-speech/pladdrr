// batch_queries.cpp
// Batch query operations - NEW functions for Phase 5
// pladdrr v2.0.9

#include <Rcpp.h>
#include "praat.github.io/fon/Formant.h"
#include "praat.github.io/fon/Pitch.h"
#include "praat.github.io/fon/Intensity.h"
#include "praat.github.io/fon/PointProcess.h"

using namespace Rcpp;

// =============================================================================
// Formant Multi-Formant Batch Queries (NEW - queries MULTIPLE formants at once)
// =============================================================================

//' Batch query MULTIPLE formant frequencies at multiple time points
//' 
//' @param formant_xptr External pointer to Formant object
//' @param times Numeric vector of time points
//' @param formant_numbers Integer vector of formant numbers (1=F1, 2=F2, etc)
//' @param unit Integer code for unit (0=HERTZ, 1=BARK)
//' @return List with one element per formant number, each containing a numeric vector
//' @keywords internal
// [[Rcpp::export]]
List formant_get_multiple_formants_at_times(SEXP formant_xptr, NumericVector times, 
                                             IntegerVector formant_numbers, int unit = 0) {
    XPtr<structFormant> formant(formant_xptr);
    if (!formant || formant.get() == nullptr) {
        stop("Invalid Formant pointer");
    }
    
    int n_times = times.size();
    int n_formants = formant_numbers.size();
    kFormant_unit f_unit = static_cast<kFormant_unit>(unit);
    
    List result;
    
    try {
        // For each formant number, query all times
        for (int f = 0; f < n_formants; f++) {
            int formant_num = formant_numbers[f];
            NumericVector values(n_times);
            
            for (int i = 0; i < n_times; i++) {
                values[i] = Formant_getValueAtTime(
                    formant.get(), 
                    formant_num, 
                    times[i], 
                    f_unit
                );
            }
            
            // Use formant label (F1, F2, etc)
            std::string name = "F" + std::to_string(formant_num);
            result[name] = values;
        }
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to query formant values");
    }
    
    return result;
}

//' Batch query MULTIPLE formant bandwidths at multiple time points
//' 
//' @param formant_xptr External pointer to Formant object
//' @param times Numeric vector of time points
//' @param formant_numbers Integer vector of formant numbers
//' @param unit Integer code for unit
//' @return List with bandwidth vectors for each formant
//' @keywords internal
// [[Rcpp::export]]
List formant_get_multiple_bandwidths_at_times(SEXP formant_xptr, NumericVector times, 
                                                IntegerVector formant_numbers, int unit = 0) {
    XPtr<structFormant> formant(formant_xptr);
    if (!formant || formant.get() == nullptr) {
        stop("Invalid Formant pointer");
    }
    
    int n_times = times.size();
    int n_formants = formant_numbers.size();
    kFormant_unit f_unit = static_cast<kFormant_unit>(unit);
    
    List result;
    
    try {
        for (int f = 0; f < n_formants; f++) {
            int formant_num = formant_numbers[f];
            NumericVector bandwidths(n_times);
            
            for (int i = 0; i < n_times; i++) {
                bandwidths[i] = Formant_getBandwidthAtTime(
                    formant.get(), 
                    formant_num, 
                    times[i], 
                    f_unit
                );
            }
            
            std::string name = "B" + std::to_string(formant_num);
            result[name] = bandwidths;
        }
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to query formant bandwidths");
    }
    
    return result;
}

// =============================================================================
// Pitch Batch Strength Queries (NEW - strength not in sound_wrappers.cpp)
// =============================================================================

//' Batch query pitch strengths at multiple time points
//' 
//' @param pitch_xptr External pointer to Pitch object
//' @param times Numeric vector of time points
//' @param unit Integer code for unit
//' @param interpolate Logical, whether to interpolate
//' @return Numeric vector of pitch strengths
//' @keywords internal
// [[Rcpp::export]]
NumericVector pitch_get_strengths_at_times(SEXP pitch_xptr, NumericVector times,
                                            int unit = 0, bool interpolate = true) {
    XPtr<structPitch> pitch(pitch_xptr);
    if (!pitch || pitch.get() == nullptr) {
        stop("Invalid Pitch pointer");
    }
    
    int n = times.size();
    NumericVector strengths(n);
    kPitch_unit p_unit = static_cast<kPitch_unit>(unit);
    
    try {
        for (int i = 0; i < n; i++) {
            strengths[i] = Pitch_getStrengthAtTime(
                pitch.get(), 
                times[i], 
                p_unit, 
                interpolate
            );
        }
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to query pitch strengths");
    }
    
    return strengths;
}

// =============================================================================
// PointProcess Batch Operations (ALL NEW)
// =============================================================================

//' Get all point times from PointProcess as vector
//' 
//' @param pp_xptr External pointer to PointProcess object
//' @return Numeric vector of all point times
//' @keywords internal
// [[Rcpp::export]]
NumericVector pointprocess_get_all_times(SEXP pp_xptr) {
    XPtr<structPointProcess> pp(pp_xptr);
    if (!pp || pp.get() == nullptr) {
        stop("Invalid PointProcess pointer");
    }
    
    integer n = pp->nt;
    NumericVector times(n);
    
    // PointProcess uses 1-based indexing
    for (integer i = 1; i <= n; i++) {
        times[i-1] = pp->t[i];
    }
    
    return times;
}

//' Get inter-point intervals from PointProcess
//' 
//' @param pp_xptr External pointer to PointProcess object
//' @return Numeric vector of intervals (length = n_points - 1)
//' @keywords internal
// [[Rcpp::export]]
NumericVector pointprocess_get_intervals(SEXP pp_xptr) {
    XPtr<structPointProcess> pp(pp_xptr);
    if (!pp || pp.get() == nullptr) {
        stop("Invalid PointProcess pointer");
    }
    
    integer n = pp->nt;
    if (n < 2) {
        return NumericVector(0); // Empty vector
    }
    
    NumericVector intervals(n - 1);
    
    for (integer i = 1; i < n; i++) {
        intervals[i-1] = pp->t[i+1] - pp->t[i];
    }
    
    return intervals;
}

//' Query PointProcess at multiple times to get nearest indices
//' 
//' @param pp_xptr External pointer to PointProcess object
//' @param times Numeric vector of query times
//' @return Integer vector of nearest point indices (1-based)
//' @keywords internal
// [[Rcpp::export]]
IntegerVector pointprocess_get_nearest_indices(SEXP pp_xptr, NumericVector times) {
    XPtr<structPointProcess> pp(pp_xptr);
    if (!pp || pp.get() == nullptr) {
        stop("Invalid PointProcess pointer");
    }
    
    int n = times.size();
    IntegerVector indices(n);
    
    try {
        for (int i = 0; i < n; i++) {
            indices[i] = static_cast<int>(
                PointProcess_getNearestIndex(pp.get(), times[i])
            );
        }
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to query PointProcess indices");
    }
    
    return indices;
}
