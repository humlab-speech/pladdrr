// formantpath_module.cpp
// Rcpp Module for Praat FormantPath object
// Part of the pladdrr package - Phase 2.2 extension

#include <Rcpp.h>
#include "module_common.h"
#include "../datatable_utils.h"

// Praat headers
#include "../praat.github.io/LPC/FormantPath.h"
#include "../praat.github.io/fon/Sound.h"
#include "../praat.github.io/melder/melder.h"

using namespace Rcpp;

// Forward declaration - NUMfpp initialization
extern void NUMmachar();

// ============================================================================
// Free Functions for FormantPath Creation
// ============================================================================

// Create FormantPath from Sound using Burg method
XPtr<structFormantPath> formantpath_create_from_sound_burg(
    XPtr<structSound> sound,
    double time_step,
    double max_num_formants,
    double formant_ceiling,
    double window_length,
    double preemphasis_from,
    double ceiling_step_fraction,
    int num_steps_up_down
) {
    if (sound.get() == nullptr) {
        Rcpp::stop("Invalid Sound object");
    }

    // Ensure NUMfpp is initialized
    NUMmachar();

    try {
        autoFormantPath fp = Sound_to_FormantPath_burg(
            sound.get(),
            time_step,
            max_num_formants,
            formant_ceiling,
            window_length,
            preemphasis_from,
            ceiling_step_fraction,
            num_steps_up_down
        );
        
        if (!fp) {
            Rcpp::stop("Sound_to_FormantPath_burg returned null");
        }
        
        return create_xptr_from_auto<structFormantPath>(fp);
    } catch (MelderError) {
        // Try to get error message
        conststring32 err = Melder_getError();
        std::string errmsg = err ? Melder_peek32to8(err) : "Unknown error";
        Melder_clearError();
        Rcpp::stop("FormantPath creation failed: " + errmsg);
    }
}

// ============================================================================
// RFormantPath Module Class
// ============================================================================

class RFormantPath {
public:
    Rcpp::XPtr<structFormantPath> ptr;

    // ========================================================================
    // Constructors
    // ========================================================================

    // Default constructor (empty/invalid object)
    RFormantPath() : ptr(R_NilValue) {}

    // Constructor from external pointer
    RFormantPath(Rcpp::XPtr<structFormantPath> p) : ptr(p) {}

    // ========================================================================
    // Validation
    // ========================================================================

    bool is_valid() {
        return ptr.get() != nullptr;
    }

    // ========================================================================
    // Time Domain Properties (inherited from Sampled)
    // ========================================================================

    double get_xmin() {
        VALIDATE_PTR(ptr, FormantPath);
        return ptr->xmin;
    }

    double get_xmax() {
        VALIDATE_PTR(ptr, FormantPath);
        return ptr->xmax;
    }

    double get_duration() {
        VALIDATE_PTR(ptr, FormantPath);
        return ptr->xmax - ptr->xmin;
    }

    int get_nx() {
        VALIDATE_PTR(ptr, FormantPath);
        return static_cast<int>(ptr->nx);
    }

    double get_dx() {
        VALIDATE_PTR(ptr, FormantPath);
        return ptr->dx;
    }

    double get_x1() {
        VALIDATE_PTR(ptr, FormantPath);
        return ptr->x1;
    }

    // ========================================================================
    // Candidate/Track Properties
    // ========================================================================

    int get_number_of_candidates() {
        VALIDATE_PTR(ptr, FormantPath);
        return static_cast<int>(ptr->formantCandidates.size);
    }

    int get_number_of_formant_tracks() {
        VALIDATE_PTR(ptr, FormantPath);
        try {
            return static_cast<int>(FormantPath_getNumberOfFormantTracks(ptr.get()));
        } catch (MelderError) {
            Melder_clearError();
            return 0;
        }
    }

    double get_ceiling_frequency(int candidate) {
        VALIDATE_PTR(ptr, FormantPath);
        if (candidate < 1 || candidate > ptr->ceilings.size) {
            Rcpp::stop("Candidate index out of range");
        }
        return ptr->ceilings[candidate];
    }

    NumericVector get_all_ceiling_frequencies() {
        VALIDATE_PTR(ptr, FormantPath);
        NumericVector result(ptr->ceilings.size);
        for (integer i = 1; i <= ptr->ceilings.size; i++) {
            result[i-1] = ptr->ceilings[i];
        }
        return result;
    }

    // ========================================================================
    // Path Query Methods
    // ========================================================================

    int get_candidate_in_frame(int frame_number) {
        VALIDATE_PTR(ptr, FormantPath);
        if (frame_number < 1 || frame_number > ptr->nx) {
            Rcpp::stop("Frame number out of range");
        }
        try {
            return static_cast<int>(FormantPath_getCandidateInFrame(ptr.get(), frame_number));
        } catch (MelderError) {
            Melder_clearError();
            return NA_INTEGER;
        }
    }

    // ========================================================================
    // Stress and Optimization Methods
    // ========================================================================

    double get_stress_of_candidate(
        double tmin, 
        double tmax,
        int from_formant,
        int to_formant,
        NumericVector parameters,
        double powerf,
        int candidate
    ) {
        VALIDATE_PTR(ptr, FormantPath);
        
        try {
            // Convert R vector to Praat INTVEC
            autoINTVEC params = raw_INTVEC(parameters.size());
            for (integer i = 1; i <= parameters.size(); i++) {
                params[i] = static_cast<integer>(parameters[i-1]);
            }
            
            return FormantPath_getStressOfCandidate(
                ptr.get(),
                tmin, tmax,
                from_formant, to_formant,
                params.get(),
                powerf,
                candidate
            );
        } catch (MelderError) {
            Melder_clearError();
            return NA_REAL;
        }
    }

    double get_optimal_ceiling(
        double tmin,
        double tmax,
        NumericVector parameters,
        double powerf
    ) {
        VALIDATE_PTR(ptr, FormantPath);
        
        try {
            // Convert R vector to Praat INTVEC
            autoINTVEC params = raw_INTVEC(parameters.size());
            for (integer i = 1; i <= parameters.size(); i++) {
                params[i] = static_cast<integer>(parameters[i-1]);
            }
            
            return FormantPath_getOptimalCeiling(
                ptr.get(),
                tmin, tmax,
                params.get(),
                powerf
            );
        } catch (MelderError) {
            Melder_clearError();
            return NA_REAL;
        }
    }

    // ========================================================================
    // Path Manipulation
    // ========================================================================

    void set_path(double tmin, double tmax, int selected_candidate) {
        VALIDATE_PTR(ptr, FormantPath);
        try {
            FormantPath_setPath(ptr.get(), tmin, tmax, selected_candidate);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to set path");
        }
    }

    void set_optimal_path(
        double tmin,
        double tmax,
        NumericVector parameters,
        double powerf
    ) {
        VALIDATE_PTR(ptr, FormantPath);
        
        try {
            // Convert R vector to Praat INTVEC
            autoINTVEC params = raw_INTVEC(parameters.size());
            for (integer i = 1; i <= parameters.size(); i++) {
                params[i] = static_cast<integer>(parameters[i-1]);
            }
            
            FormantPath_setOptimalPath(
                ptr.get(),
                tmin, tmax,
                params.get(),
                powerf
            );
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to set optimal path");
        }
    }

    void path_finder(
        double q_weight,
        double frequency_change_weight,
        double stress_weight,
        double ceiling_change_weight,
        double intensity_modulation_step_size,
        double window_length,
        NumericVector parameters,
        double powerf
    ) {
        VALIDATE_PTR(ptr, FormantPath);
        
        try {
            // Convert R vector to Praat INTVEC
            autoINTVEC params = raw_INTVEC(parameters.size());
            for (integer i = 1; i <= parameters.size(); i++) {
                params[i] = static_cast<integer>(parameters[i-1]);
            }
            
            FormantPath_pathFinder(
                ptr.get(),
                q_weight,
                frequency_change_weight,
                stress_weight,
                ceiling_change_weight,
                intensity_modulation_step_size,
                window_length,
                params.get(),
                powerf
            );
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to run path finder");
        }
    }

    // ========================================================================
    // Extraction Methods
    // ========================================================================

    XPtr<structFormant> extract_formant() {
        VALIDATE_PTR(ptr, FormantPath);
        try {
            autoFormant formant = FormantPath_extractFormant(ptr.get());
            return create_xptr_from_auto<structFormant>(formant);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to extract Formant");
        }
    }

    // ========================================================================
    // Export Methods
    // ========================================================================

    DataFrame as_data_frame(int max_formants) {
        VALIDATE_PTR(ptr, FormantPath);
        
        // Extract the optimal formant and convert to data frame
        try {
            autoFormant formant = FormantPath_extractFormant(ptr.get());
            
            std::vector<double> times;
            std::vector<int> formant_nums;
            std::vector<double> frequencies;
            std::vector<double> bandwidths;

            for (integer iframe = 1; iframe <= formant->nx; iframe++) {
                double time = Sampled_indexToX(formant.get(), iframe);
                Formant_Frame frame = &formant->frames[iframe];

                integer nFormants = std::min(frame->numberOfFormants, (integer)max_formants);
                for (integer iformant = 1; iformant <= nFormants; iformant++) {
                    times.push_back(time);
                    formant_nums.push_back(iformant);
                    frequencies.push_back(frame->formant[iformant].frequency);
                    bandwidths.push_back(frame->formant[iformant].bandwidth);
                }
            }

            return pladdrr::dt::create_datatable(
                List::create(
                    Named("time") = times,
                    Named("formant") = formant_nums,
                    Named("frequency") = frequencies,
                    Named("bandwidth") = bandwidths
                ),
                CharacterVector::create("time", "formant", "frequency", "bandwidth"),
                CharacterVector::create("time", "formant")
            );
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to export FormantPath as data frame");
        }
    }

    // ========================================================================
    // File I/O
    // ========================================================================

    void save(std::string path) {
        VALIDATE_PTR(ptr, FormantPath);
        try {
            structMelderFile file { };
            Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
            Data_writeToTextFile(ptr.get(), &file);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to save FormantPath");
        }
    }
};

// ============================================================================
// Rcpp Module Definition
// ============================================================================

RCPP_MODULE(formantpath_module) {
    using namespace Rcpp;

    class_<RFormantPath>("RFormantPath")
        // Constructors
        .constructor()
        .constructor<XPtr<structFormantPath>>()

        // Validation
        .method("is_valid", &RFormantPath::is_valid)

        // Time domain properties
        .method("get_xmin", &RFormantPath::get_xmin)
        .method("get_xmax", &RFormantPath::get_xmax)
        .method("get_duration", &RFormantPath::get_duration)
        .method("get_nx", &RFormantPath::get_nx)
        .method("get_dx", &RFormantPath::get_dx)
        .method("get_x1", &RFormantPath::get_x1)

        // Candidate/track properties
        .method("get_number_of_candidates", &RFormantPath::get_number_of_candidates)
        .method("get_number_of_formant_tracks", &RFormantPath::get_number_of_formant_tracks)
        .method("get_ceiling_frequency", &RFormantPath::get_ceiling_frequency)
        .method("get_all_ceiling_frequencies", &RFormantPath::get_all_ceiling_frequencies)

        // Path query
        .method("get_candidate_in_frame", &RFormantPath::get_candidate_in_frame)

        // Stress and optimization
        .method("get_stress_of_candidate", &RFormantPath::get_stress_of_candidate)
        .method("get_optimal_ceiling", &RFormantPath::get_optimal_ceiling)

        // Path manipulation
        .method("set_path", &RFormantPath::set_path)
        .method("set_optimal_path", &RFormantPath::set_optimal_path)
        .method("path_finder", &RFormantPath::path_finder)

        // Extraction
        .method("extract_formant", &RFormantPath::extract_formant)

        // Export
        .method("as_data_frame", &RFormantPath::as_data_frame)
        .method("save", &RFormantPath::save)
    ;
    
    // Factory function (returns XPtr)
    function("formantpath_create_from_sound_burg", &formantpath_create_from_sound_burg);
}
