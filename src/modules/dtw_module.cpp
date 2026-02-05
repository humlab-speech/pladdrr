// dtw_module.cpp
// Rcpp Module for DTW (Dynamic Time Warping) - pladdrr 2.0
//
// DTW provides temporal alignment between acoustic signals for:
// - Sound-to-sound alignment
// - TextGrid annotation warping
// - Time mapping between signals

#include <Rcpp.h>
#include "module_common.h"
#include "../datatable_utils.h"

// Praat DTW headers
#include "praat.github.io/dwtools/DTW.h"
#include "praat.github.io/dwtools/Sounds_to_DTW.h"
#include "praat.github.io/dwtools/CCs_to_DTW.h"
#include "praat.github.io/dwtools/DTW_and_TextGrid.h"
#include "praat.github.io/fon/Sound.h"
#include "praat.github.io/fon/Pitch.h"
#include "praat.github.io/fon/Spectrogram.h"
#include "praat.github.io/fon/Matrix.h"
#include "praat.github.io/fon/Polygon.h"
#include "praat.github.io/fon/DurationTier.h"
#include "praat.github.io/fon/TextGrid.h"
#include "praat.github.io/dwtools/MFCC.h"

using namespace Rcpp;

// ============================================================================
// RDTW Class - Dynamic Time Warping
// ============================================================================

class RDTW {
private:
    XPtr<structDTW> ptr;

public:
    RDTW() : ptr(R_NilValue) {}
    RDTW(XPtr<structDTW> xptr) : ptr(xptr) {}

    bool is_valid() { return ptr.get() != nullptr; }

    // ========== Domain Properties (X = candidate, Y = reference) ==========
    double get_xmin() { VALIDATE_PTR(ptr, DTW); return ptr->xmin; }
    double get_xmax() { VALIDATE_PTR(ptr, DTW); return ptr->xmax; }
    double get_ymin() { VALIDATE_PTR(ptr, DTW); return ptr->ymin; }
    double get_ymax() { VALIDATE_PTR(ptr, DTW); return ptr->ymax; }
    double get_x_duration() { VALIDATE_PTR(ptr, DTW); return ptr->xmax - ptr->xmin; }
    double get_y_duration() { VALIDATE_PTR(ptr, DTW); return ptr->ymax - ptr->ymin; }

    // ========== Matrix Properties ==========
    int get_nx() { VALIDATE_PTR(ptr, DTW); return static_cast<int>(ptr->nx); }
    int get_ny() { VALIDATE_PTR(ptr, DTW); return static_cast<int>(ptr->ny); }
    double get_dx() { VALIDATE_PTR(ptr, DTW); return ptr->dx; }
    double get_dy() { VALIDATE_PTR(ptr, DTW); return ptr->dy; }

    // ========== Distance/Path Metrics ==========
    double get_weighted_distance() {
        VALIDATE_PTR(ptr, DTW);
        return ptr->weightedDistance;
    }

    int get_path_length() {
        VALIDATE_PTR(ptr, DTW);
        return static_cast<int>(ptr->pathLength);
    }

    // ========== Time Mapping (Core Functionality) ==========
    double get_y_time_from_x_time(double tx) {
        VALIDATE_PTR(ptr, DTW);
        try {
            return DTW_getYTimeFromXTime(ptr.get(), tx);
        } catch (MelderError) {
            Melder_clearError();
            return NA_REAL;
        }
    }

    double get_x_time_from_y_time(double ty) {
        VALIDATE_PTR(ptr, DTW);
        try {
            return DTW_getXTimeFromYTime(ptr.get(), ty);
        } catch (MelderError) {
            Melder_clearError();
            return NA_REAL;
        }
    }

    // Vectorized time mapping
    NumericVector get_y_times_from_x_times(NumericVector tx_vec) {
        VALIDATE_PTR(ptr, DTW);
        int n = tx_vec.size();
        NumericVector result(n);
        for (int i = 0; i < n; i++) {
            try {
                result[i] = DTW_getYTimeFromXTime(ptr.get(), tx_vec[i]);
            } catch (MelderError) {
                Melder_clearError();
                result[i] = NA_REAL;
            }
        }
        return result;
    }

    NumericVector get_x_times_from_y_times(NumericVector ty_vec) {
        VALIDATE_PTR(ptr, DTW);
        int n = ty_vec.size();
        NumericVector result(n);
        for (int i = 0; i < n; i++) {
            try {
                result[i] = DTW_getXTimeFromYTime(ptr.get(), ty_vec[i]);
            } catch (MelderError) {
                Melder_clearError();
                result[i] = NA_REAL;
            }
        }
        return result;
    }

    // ========== Path Analysis ==========
    int get_maximum_consecutive_steps(std::string direction) {
        VALIDATE_PTR(ptr, DTW);
        int dir_code;
        if (direction == "x" || direction == "horizontal") {
            dir_code = DTW_X;  // 4
        } else if (direction == "y" || direction == "vertical") {
            dir_code = DTW_Y;  // 6
        } else {
            Rcpp::stop("direction must be 'x'/'horizontal' or 'y'/'vertical'");
        }
        try {
            return static_cast<int>(DTW_getMaximumConsecutiveSteps(ptr.get(), dir_code));
        } catch (MelderError) {
            Melder_clearError();
            return NA_INTEGER;
        }
    }

    // Get alignment path as data.frame
    DataFrame get_path() {
        VALIDATE_PTR(ptr, DTW);
        integer n = ptr->pathLength;

        IntegerVector x_indices(n), y_indices(n);
        NumericVector x_times(n), y_times(n);

        for (integer i = 1; i <= n; i++) {
            x_indices[i-1] = static_cast<int>(ptr->path[i].x);
            y_indices[i-1] = static_cast<int>(ptr->path[i].y);
            x_times[i-1] = Matrix_columnToX(ptr.get(), ptr->path[i].x);
            y_times[i-1] = Matrix_rowToY(ptr.get(), ptr->path[i].y);
        }

        return pladdrr::dt::create_datatable(
            List::create(
                Named("x_index") = x_indices,
                Named("y_index") = y_indices,
                Named("x_time") = x_times,
                Named("y_time") = y_times
            ),
            CharacterVector::create("x_index", "y_index", "x_time", "y_time"),
            CharacterVector::create("x_time")
        );
    }

    // ========== Transformation Methods ==========
    XPtr<structDTW> swap_axes_ptr() {
        VALIDATE_PTR(ptr, DTW);
        try {
            autoDTW swapped = DTW_swapAxes(ptr.get());
            structDTW* raw = swapped.releaseToAmbiguousOwner();
            // Use proper deleter for Praat objects (calls forget() instead of delete)
            auto deleter = [](structDTW* thing) {
                if (thing != nullptr) forget(thing);
            };
            return XPtr<structDTW>(raw, deleter);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to swap DTW axes");
        }
    }

    XPtr<structPolygon> to_polygon_ptr(double band, int slope) {
        VALIDATE_PTR(ptr, DTW);
        try {
            autoPolygon poly = DTW_to_Polygon(ptr.get(), band, slope);
            structPolygon* raw = poly.releaseToAmbiguousOwner();
            // Use proper deleter for Praat objects (calls forget() instead of delete)
            auto deleter = [](structPolygon* thing) {
                if (thing != nullptr) forget(thing);
            };
            return XPtr<structPolygon>(raw, deleter);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to create Polygon from DTW");
        }
    }

    XPtr<structMatrix> to_matrix_distances_ptr() {
        VALIDATE_PTR(ptr, DTW);
        try {
            autoMatrix mat = DTW_to_Matrix_distances(ptr.get());
            structMatrix* raw = mat.releaseToAmbiguousOwner();
            // Use proper deleter for Praat objects (calls forget() instead of delete)
            auto deleter = [](structMatrix* thing) {
                if (thing != nullptr) forget(thing);
            };
            return XPtr<structMatrix>(raw, deleter);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to convert DTW to distance Matrix");
        }
    }

    XPtr<structMatrix> to_matrix_cumulative_distances_ptr(double band, int slope) {
        VALIDATE_PTR(ptr, DTW);
        try {
            autoMatrix mat = DTW_to_Matrix_cumulativeDistances(ptr.get(), band, slope);
            structMatrix* raw = mat.releaseToAmbiguousOwner();
            // Use proper deleter for Praat objects (calls forget() instead of delete)
            auto deleter = [](structMatrix* thing) {
                if (thing != nullptr) forget(thing);
            };
            return XPtr<structMatrix>(raw, deleter);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to convert DTW to cumulative distance Matrix");
        }
    }

    XPtr<structDurationTier> to_duration_tier_ptr() {
        VALIDATE_PTR(ptr, DTW);
        try {
            autoDurationTier tier = DTW_to_DurationTier(ptr.get());
            structDurationTier* raw = tier.releaseToAmbiguousOwner();
            // Use proper deleter for Praat objects (calls forget() instead of delete)
            auto deleter = [](structDurationTier* thing) {
                if (thing != nullptr) forget(thing);
            };
            return XPtr<structDurationTier>(raw, deleter);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to convert DTW to DurationTier");
        }
    }

    // ========== TextGrid Warping (Major Use Case) ==========
    XPtr<structTextGrid> warp_textgrid_ptr(XPtr<structTextGrid> textgrid, double precision) {
        VALIDATE_PTR(ptr, DTW);
        if (!textgrid || !textgrid.get()) Rcpp::stop("Invalid TextGrid pointer");
        try {
            autoTextGrid warped = DTW_TextGrid_to_TextGrid(ptr.get(), textgrid.get(), precision);
            structTextGrid* raw = warped.releaseToAmbiguousOwner();
            // Use proper deleter for Praat objects (calls forget() instead of delete)
            auto deleter = [](structTextGrid* thing) {
                if (thing != nullptr) forget(thing);
            };
            return XPtr<structTextGrid>(raw, deleter);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to warp TextGrid using DTW");
        }
    }

    // ========== Export Methods ==========
    NumericMatrix as_matrix() {
        VALIDATE_PTR(ptr, DTW);
        NumericMatrix mat(ptr->ny, ptr->nx);
        for (integer iy = 1; iy <= ptr->ny; iy++) {
            for (integer ix = 1; ix <= ptr->nx; ix++) {
                mat(iy-1, ix-1) = ptr->z[iy][ix];
            }
        }
        return mat;
    }

    List get_info() {
        VALIDATE_PTR(ptr, DTW);
        return List::create(
            Named("x_domain") = List::create(
                Named("min") = ptr->xmin,
                Named("max") = ptr->xmax,
                Named("duration") = ptr->xmax - ptr->xmin
            ),
            Named("y_domain") = List::create(
                Named("min") = ptr->ymin,
                Named("max") = ptr->ymax,
                Named("duration") = ptr->ymax - ptr->ymin
            ),
            Named("matrix") = List::create(
                Named("nx") = static_cast<int>(ptr->nx),
                Named("ny") = static_cast<int>(ptr->ny),
                Named("dx") = ptr->dx,
                Named("dy") = ptr->dy
            ),
            Named("path") = List::create(
                Named("length") = static_cast<int>(ptr->pathLength),
                Named("weighted_distance") = ptr->weightedDistance
            )
        );
    }

    void save(std::string path) {
        VALIDATE_PTR(ptr, DTW);
        try {
            structMelderFile file = {};
            Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
            Data_writeToTextFile(ptr.get(), &file);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to save DTW to file: %s", path.c_str());
        }
    }
};

// ============================================================================
// Factory Functions
// ============================================================================

// Sound + Sound -> DTW (Primary use case)
static XPtr<structDTW> Module_Sounds_to_DTW(
    XPtr<structSound> sound1,
    XPtr<structSound> sound2,
    double analysis_width,
    double dt,
    double band,
    int slope
) {
    if (!sound1 || !sound1.get()) Rcpp::stop("Invalid Sound1 pointer");
    if (!sound2 || !sound2.get()) Rcpp::stop("Invalid Sound2 pointer");
    try {
        autoDTW dtw = Sounds_to_DTW(
            sound1.get(), sound2.get(),
            analysis_width, dt, band, slope
        );
        structDTW* raw = dtw.releaseToAmbiguousOwner();
        // Use proper deleter for Praat objects (calls forget() instead of delete)
        auto deleter = [](structDTW* thing) {
            if (thing != nullptr) forget(thing);
        };
        return XPtr<structDTW>(raw, deleter);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to create DTW from Sounds");
    }
}

// MFCC + MFCC -> DTW (For speech recognition workflows)
static XPtr<structDTW> Module_MFCCs_to_DTW(
    XPtr<structMFCC> mfcc1,
    XPtr<structMFCC> mfcc2,
    double coefficient_weight,
    double log_energy_weight,
    double coefficient_regression_weight,
    double log_energy_regression_weight,
    double regression_window_length
) {
    if (!mfcc1 || !mfcc1.get()) Rcpp::stop("Invalid MFCC1 pointer");
    if (!mfcc2 || !mfcc2.get()) Rcpp::stop("Invalid MFCC2 pointer");
    try {
        // CCs_to_DTW works with CC (base class of MFCC)
        autoDTW dtw = CCs_to_DTW(
            reinterpret_cast<CC>(mfcc1.get()),
            reinterpret_cast<CC>(mfcc2.get()),
            coefficient_weight, log_energy_weight,
            coefficient_regression_weight, log_energy_regression_weight,
            regression_window_length
        );
        structDTW* raw = dtw.releaseToAmbiguousOwner();
        // Use proper deleter for Praat objects (calls forget() instead of delete)
        auto deleter = [](structDTW* thing) {
            if (thing != nullptr) forget(thing);
        };
        return XPtr<structDTW>(raw, deleter);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to create DTW from MFCCs");
    }
}

// Spectrogram + Spectrogram -> DTW
static XPtr<structDTW> Module_Spectrograms_to_DTW(
    XPtr<structSpectrogram> spec1,
    XPtr<structSpectrogram> spec2,
    bool match_start,
    bool match_end,
    int slope,
    double metric
) {
    if (!spec1 || !spec1.get()) Rcpp::stop("Invalid Spectrogram1 pointer");
    if (!spec2 || !spec2.get()) Rcpp::stop("Invalid Spectrogram2 pointer");
    try {
        autoDTW dtw = Spectrograms_to_DTW(
            spec1.get(), spec2.get(),
            match_start, match_end, slope, metric
        );
        structDTW* raw = dtw.releaseToAmbiguousOwner();
        // Use proper deleter for Praat objects (calls forget() instead of delete)
        auto deleter = [](structDTW* thing) {
            if (thing != nullptr) forget(thing);
        };
        return XPtr<structDTW>(raw, deleter);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to create DTW from Spectrograms");
    }
}

// Pitch + Pitch -> DTW
static XPtr<structDTW> Module_Pitches_to_DTW(
    XPtr<structPitch> pitch1,
    XPtr<structPitch> pitch2,
    double vuv_costs,
    double time_weight,
    bool match_start,
    bool match_end,
    int slope
) {
    if (!pitch1 || !pitch1.get()) Rcpp::stop("Invalid Pitch1 pointer");
    if (!pitch2 || !pitch2.get()) Rcpp::stop("Invalid Pitch2 pointer");
    try {
        autoDTW dtw = Pitches_to_DTW(
            pitch1.get(), pitch2.get(),
            vuv_costs, time_weight,
            match_start, match_end, slope
        );
        structDTW* raw = dtw.releaseToAmbiguousOwner();
        // Use proper deleter for Praat objects (calls forget() instead of delete)
        auto deleter = [](structDTW* thing) {
            if (thing != nullptr) forget(thing);
        };
        return XPtr<structDTW>(raw, deleter);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to create DTW from Pitches");
    }
}

// ============================================================================
// Module Registration
// ============================================================================

RCPP_MODULE(dtw_module) {
    class_<RDTW>("RDTW")
        .constructor()
        .constructor<XPtr<structDTW>>()
        .method("is_valid", &RDTW::is_valid)

        // Domain properties
        .method("get_xmin", &RDTW::get_xmin)
        .method("get_xmax", &RDTW::get_xmax)
        .method("get_ymin", &RDTW::get_ymin)
        .method("get_ymax", &RDTW::get_ymax)
        .method("get_x_duration", &RDTW::get_x_duration)
        .method("get_y_duration", &RDTW::get_y_duration)
        .method("get_nx", &RDTW::get_nx)
        .method("get_ny", &RDTW::get_ny)
        .method("get_dx", &RDTW::get_dx)
        .method("get_dy", &RDTW::get_dy)

        // Metrics
        .method("get_weighted_distance", &RDTW::get_weighted_distance)
        .method("get_path_length", &RDTW::get_path_length)

        // Time mapping (core)
        .method("get_y_time_from_x_time", &RDTW::get_y_time_from_x_time)
        .method("get_x_time_from_y_time", &RDTW::get_x_time_from_y_time)
        .method("get_y_times_from_x_times", &RDTW::get_y_times_from_x_times)
        .method("get_x_times_from_y_times", &RDTW::get_x_times_from_y_times)

        // Path analysis
        .method("get_maximum_consecutive_steps", &RDTW::get_maximum_consecutive_steps)
        .method("get_path", &RDTW::get_path)

        // Transformations
        .method("swap_axes_ptr", &RDTW::swap_axes_ptr)
        .method("to_polygon_ptr", &RDTW::to_polygon_ptr)
        .method("to_matrix_distances_ptr", &RDTW::to_matrix_distances_ptr)
        .method("to_matrix_cumulative_distances_ptr", &RDTW::to_matrix_cumulative_distances_ptr)
        .method("to_duration_tier_ptr", &RDTW::to_duration_tier_ptr)

        // TextGrid warping
        .method("warp_textgrid_ptr", &RDTW::warp_textgrid_ptr)

        // Export
        .method("as_matrix", &RDTW::as_matrix)
        .method("get_info", &RDTW::get_info)
        .method("save", &RDTW::save)
    ;

    // Factory functions
    function("Sounds_to_DTW", &Module_Sounds_to_DTW);
    function("MFCCs_to_DTW", &Module_MFCCs_to_DTW);
    function("Spectrograms_to_DTW", &Module_Spectrograms_to_DTW);
    function("Pitches_to_DTW", &Module_Pitches_to_DTW);
}
