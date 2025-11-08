// PointProcess R6 wrapper functions
// Wraps Praat PointProcess C++ object for R6 PointProcess class

#include <Rcpp.h>
#include "praat_xptr_utils.h"
#include "praat_error_handling.h"

// Praat includes
#include "praat.github.io/fon/PointProcess.h"
#include "praat.github.io/fon/PointProcess_and_Sound.h"
#include "praat.github.io/fon/VoiceAnalysis.h"
#include "praat.github.io/fon/Sound.h"

using namespace Rcpp;

// Finalizer for PointProcess XPtr
void pointprocess_finalizer(structPointProcess* pp) {
    if (pp != nullptr) {
        forget(pp);
    }
}

// =============================================================================
// Query Methods - Basic
// =============================================================================

// [[Rcpp::export(.pointprocess_get_number_of_points)]]
int pointprocess_get_number_of_points(SEXP xptr) {
    XPtr<structPointProcess> pp(xptr);
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    return pp->nt;
}

// [[Rcpp::export(.pointprocess_get_time_from_index)]]
double pointprocess_get_time_from_index(SEXP xptr, int index) {
    XPtr<structPointProcess> pp(xptr);
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    
    if (index < 1 || index > pp->nt) {
        stop("Index out of range: %d (must be between 1 and %d)", index, pp->nt);
    }
    
    // Praat uses 1-based indexing internally
    return pp->t[index];
}

// [[Rcpp::export(.pointprocess_get_nearest_index)]]
int pointprocess_get_nearest_index(SEXP xptr, double time) {
    XPtr<structPointProcess> pp(xptr);
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    
    try {
        integer index = PointProcess_getNearestIndex(pp, time);
        return static_cast<int>(index);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to get nearest index");
    }
}

// [[Rcpp::export(.pointprocess_get_low_index)]]
int pointprocess_get_low_index(SEXP xptr, double time) {
    XPtr<structPointProcess> pp(xptr);
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    
    try {
        integer index = PointProcess_getLowIndex(pp, time);
        return static_cast<int>(index);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to get low index");
    }
}

// [[Rcpp::export(.pointprocess_get_high_index)]]
int pointprocess_get_high_index(SEXP xptr, double time) {
    XPtr<structPointProcess> pp(xptr);
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    
    try {
        integer index = PointProcess_getHighIndex(pp, time);
        return static_cast<int>(index);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to get high index");
    }
}

// [[Rcpp::export(.pointprocess_get_interval)]]
double pointprocess_get_interval(SEXP xptr, double time) {
    XPtr<structPointProcess> pp(xptr);
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    
    try {
        double interval = PointProcess_getInterval(pp, time);
        return interval;
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}

// =============================================================================
// Voice Quality - Jitter (Period Perturbation)
// =============================================================================

// [[Rcpp::export(.pointprocess_get_jitter_local)]]
double pointprocess_get_jitter_local(
    SEXP xptr, 
    double from_time, 
    double to_time,
    double period_floor, 
    double period_ceiling, 
    double max_period_factor
) {
    XPtr<structPointProcess> pp(xptr);
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    
    try {
        double jitter = PointProcess_getJitter_local(
            pp, 
            from_time, 
            to_time, 
            period_floor, 
            period_ceiling, 
            max_period_factor
        );
        return jitter;
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}

// [[Rcpp::export(.pointprocess_get_jitter_local_absolute)]]
double pointprocess_get_jitter_local_absolute(
    SEXP xptr, 
    double from_time, 
    double to_time,
    double period_floor, 
    double period_ceiling, 
    double max_period_factor
) {
    XPtr<structPointProcess> pp(xptr);
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    
    try {
        double jitter = PointProcess_getJitter_local_absolute(
            pp, 
            from_time, 
            to_time, 
            period_floor, 
            period_ceiling, 
            max_period_factor
        );
        return jitter;
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}

// [[Rcpp::export(.pointprocess_get_jitter_rap)]]
double pointprocess_get_jitter_rap(
    SEXP xptr, 
    double from_time, 
    double to_time,
    double period_floor, 
    double period_ceiling, 
    double max_period_factor
) {
    XPtr<structPointProcess> pp(xptr);
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    
    try {
        double jitter = PointProcess_getJitter_rap(
            pp, 
            from_time, 
            to_time, 
            period_floor, 
            period_ceiling, 
            max_period_factor
        );
        return jitter;
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}

// [[Rcpp::export(.pointprocess_get_jitter_ppq5)]]
double pointprocess_get_jitter_ppq5(
    SEXP xptr, 
    double from_time, 
    double to_time,
    double period_floor, 
    double period_ceiling, 
    double max_period_factor
) {
    XPtr<structPointProcess> pp(xptr);
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    
    try {
        double jitter = PointProcess_getJitter_ppq5(
            pp, 
            from_time, 
            to_time, 
            period_floor, 
            period_ceiling, 
            max_period_factor
        );
        return jitter;
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}

// [[Rcpp::export(.pointprocess_get_jitter_ddp)]]
double pointprocess_get_jitter_ddp(
    SEXP xptr, 
    double from_time, 
    double to_time,
    double period_floor, 
    double period_ceiling, 
    double max_period_factor
) {
    XPtr<structPointProcess> pp(xptr);
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    
    try {
        double jitter = PointProcess_getJitter_ddp(
            pp, 
            from_time, 
            to_time, 
            period_floor, 
            period_ceiling, 
            max_period_factor
        );
        return jitter;
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}

// =============================================================================
// Voice Quality - Shimmer (Amplitude Perturbation - requires Sound)
// =============================================================================

// [[Rcpp::export(.pointprocess_sound_get_shimmer_local)]]
double pointprocess_sound_get_shimmer_local(
    SEXP pp_xptr,
    SEXP sound_xptr,
    double from_time, 
    double to_time,
    double period_floor, 
    double period_ceiling, 
    double max_period_factor,
    double max_amplitude_factor
) {
    XPtr<structPointProcess> pp(pp_xptr);
    XPtr<structSound> sound(sound_xptr);
    
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    if (!sound) {
        stop("Invalid Sound pointer");
    }
    
    try {
        double shimmer = PointProcess_Sound_getShimmer_local(
            pp, 
            sound,
            from_time, 
            to_time, 
            period_floor, 
            period_ceiling, 
            max_period_factor,
            max_amplitude_factor
        );
        return shimmer;
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}

// [[Rcpp::export(.pointprocess_sound_get_shimmer_local_db)]]
double pointprocess_sound_get_shimmer_local_db(
    SEXP pp_xptr,
    SEXP sound_xptr,
    double from_time, 
    double to_time,
    double period_floor, 
    double period_ceiling, 
    double max_period_factor,
    double max_amplitude_factor
) {
    XPtr<structPointProcess> pp(pp_xptr);
    XPtr<structSound> sound(sound_xptr);
    
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    if (!sound) {
        stop("Invalid Sound pointer");
    }
    
    try {
        double shimmer = PointProcess_Sound_getShimmer_local_dB(
            pp, 
            sound,
            from_time, 
            to_time, 
            period_floor, 
            period_ceiling, 
            max_period_factor,
            max_amplitude_factor
        );
        return shimmer;
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}

// [[Rcpp::export(.pointprocess_sound_get_shimmer_apq3)]]
double pointprocess_sound_get_shimmer_apq3(
    SEXP pp_xptr,
    SEXP sound_xptr,
    double from_time, 
    double to_time,
    double period_floor, 
    double period_ceiling, 
    double max_period_factor,
    double max_amplitude_factor
) {
    XPtr<structPointProcess> pp(pp_xptr);
    XPtr<structSound> sound(sound_xptr);
    
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    if (!sound) {
        stop("Invalid Sound pointer");
    }
    
    try {
        double shimmer = PointProcess_Sound_getShimmer_apq3(
            pp, 
            sound,
            from_time, 
            to_time, 
            period_floor, 
            period_ceiling, 
            max_period_factor,
            max_amplitude_factor
        );
        return shimmer;
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}

// [[Rcpp::export(.pointprocess_sound_get_shimmer_apq5)]]
double pointprocess_sound_get_shimmer_apq5(
    SEXP pp_xptr,
    SEXP sound_xptr,
    double from_time, 
    double to_time,
    double period_floor, 
    double period_ceiling, 
    double max_period_factor,
    double max_amplitude_factor
) {
    XPtr<structPointProcess> pp(pp_xptr);
    XPtr<structSound> sound(sound_xptr);
    
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    if (!sound) {
        stop("Invalid Sound pointer");
    }
    
    try {
        double shimmer = PointProcess_Sound_getShimmer_apq5(
            pp, 
            sound,
            from_time, 
            to_time, 
            period_floor, 
            period_ceiling, 
            max_period_factor,
            max_amplitude_factor
        );
        return shimmer;
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}

// [[Rcpp::export(.pointprocess_sound_get_shimmer_apq11)]]
double pointprocess_sound_get_shimmer_apq11(
    SEXP pp_xptr,
    SEXP sound_xptr,
    double from_time, 
    double to_time,
    double period_floor, 
    double period_ceiling, 
    double max_period_factor,
    double max_amplitude_factor
) {
    XPtr<structPointProcess> pp(pp_xptr);
    XPtr<structSound> sound(sound_xptr);
    
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    if (!sound) {
        stop("Invalid Sound pointer");
    }
    
    try {
        double shimmer = PointProcess_Sound_getShimmer_apq11(
            pp, 
            sound,
            from_time, 
            to_time, 
            period_floor, 
            period_ceiling, 
            max_period_factor,
            max_amplitude_factor
        );
        return shimmer;
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}

// [[Rcpp::export(.pointprocess_sound_get_shimmer_dda)]]
double pointprocess_sound_get_shimmer_dda(
    SEXP pp_xptr,
    SEXP sound_xptr,
    double from_time, 
    double to_time,
    double period_floor, 
    double period_ceiling, 
    double max_period_factor,
    double max_amplitude_factor
) {
    XPtr<structPointProcess> pp(pp_xptr);
    XPtr<structSound> sound(sound_xptr);
    
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    if (!sound) {
        stop("Invalid Sound pointer");
    }
    
    try {
        double shimmer = PointProcess_Sound_getShimmer_dda(
            pp, 
            sound,
            from_time, 
            to_time, 
            period_floor, 
            period_ceiling, 
            max_period_factor,
            max_amplitude_factor
        );
        return shimmer;
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}

// =============================================================================
// Period Statistics
// =============================================================================

// [[Rcpp::export(.pointprocess_get_mean_period)]]
double pointprocess_get_mean_period(
    SEXP xptr, 
    double from_time, 
    double to_time,
    double period_floor, 
    double period_ceiling, 
    double max_period_factor
) {
    XPtr<structPointProcess> pp(xptr);
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    
    try {
        double mean_period = PointProcess_getMeanPeriod(
            pp, 
            from_time, 
            to_time, 
            period_floor, 
            period_ceiling, 
            max_period_factor
        );
        return mean_period;
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}

// [[Rcpp::export(.pointprocess_get_stdev_period)]]
double pointprocess_get_stdev_period(
    SEXP xptr, 
    double from_time, 
    double to_time,
    double period_floor, 
    double period_ceiling, 
    double max_period_factor
) {
    XPtr<structPointProcess> pp(xptr);
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    
    try {
        double stdev_period = PointProcess_getStdevPeriod(
            pp, 
            from_time, 
            to_time, 
            period_floor, 
            period_ceiling, 
            max_period_factor
        );
        return stdev_period;
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}

// =============================================================================
// Modification Methods
// =============================================================================

// [[Rcpp::export(.pointprocess_add_point)]]
void pointprocess_add_point(SEXP xptr, double time) {
    XPtr<structPointProcess> pp(xptr);
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    
    try {
        PointProcess_addPoint(pp, time);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to add point at time %.6f", time);
    }
}

// [[Rcpp::export(.pointprocess_remove_point)]]
void pointprocess_remove_point(SEXP xptr, int index) {
    XPtr<structPointProcess> pp(xptr);
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    
    if (index < 1 || index > pp->nt) {
        stop("Index out of range: %d (must be between 1 and %d)", index, pp->nt);
    }
    
    try {
        PointProcess_removePoint(pp, index);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to remove point at index %d", index);
    }
}

// [[Rcpp::export(.pointprocess_remove_point_near)]]
void pointprocess_remove_point_near(SEXP xptr, double time) {
    XPtr<structPointProcess> pp(xptr);
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    
    try {
        PointProcess_removePointNear(pp, time);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to remove point near time %.6f", time);
    }
}

// [[Rcpp::export(.pointprocess_remove_points_between)]]
void pointprocess_remove_points_between(SEXP xptr, double from_time, double to_time) {
    XPtr<structPointProcess> pp(xptr);
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    
    try {
        PointProcess_removePointsBetween(pp, from_time, to_time);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to remove points between %.6f and %.6f", from_time, to_time);
    }
}

// =============================================================================
// I/O Methods
// =============================================================================

// [[Rcpp::export(.pointprocess_save)]]
void pointprocess_save(SEXP xptr, std::string path) {
    XPtr<structPointProcess> pp(xptr);
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    
    try {
        structMelderFile file {};
        Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
        Data_writeToTextFile(pp, &file);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to save PointProcess to: %s", path.c_str());
    }
}
