// manipulation_module.cpp
// Rcpp Module exposing Praat Manipulation functionality (pladdrr 2.0)
//
// Manipulation: pitch/duration modification via PSOLA

#include <Rcpp.h>
#include "module_common.h"
#include "praat.github.io/fon/Manipulation.h"
#include "praat.github.io/fon/PitchTier.h"
#include "praat.github.io/fon/DurationTier.h"
#include "praat.github.io/fon/PointProcess.h"
#include "praat.github.io/fon/Sound.h"

using namespace Rcpp;

class RManipulation {
private:
    XPtr<structManipulation> ptr;

public:
    RManipulation() : ptr(R_NilValue) {}
    RManipulation(XPtr<structManipulation> xptr) : ptr(xptr) {}

    bool is_valid() { return ptr.get() != nullptr; }

    // Time domain properties
    double get_xmin() { VALIDATE_PTR(ptr, Manipulation); return ptr->xmin; }
    double get_xmax() { VALIDATE_PTR(ptr, Manipulation); return ptr->xmax; }
    double get_duration() { VALIDATE_PTR(ptr, Manipulation); return ptr->xmax - ptr->xmin; }

    // Check for tiers
    bool has_pitch_tier() {
        VALIDATE_PTR(ptr, Manipulation);
        return !!ptr->pitch;
    }

    bool has_duration_tier() {
        VALIDATE_PTR(ptr, Manipulation);
        return !!ptr->duration;
    }

    bool has_pulses() {
        VALIDATE_PTR(ptr, Manipulation);
        return !!ptr->pulses;
    }

    bool has_original_sound() {
        VALIDATE_PTR(ptr, Manipulation);
        return !!ptr->sound;
    }

    // Extract tiers
    XPtr<structPitchTier> extract_pitch_tier_ptr() {
        VALIDATE_PTR(ptr, Manipulation);
        if (!ptr->pitch) Rcpp::stop("No pitch tier in Manipulation");
        try {
            autoPitchTier tier = Data_copy(ptr->pitch.get());
            structPitchTier* raw = tier.releaseToAmbiguousOwner();
            return XPtr<structPitchTier>(raw, true);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to extract PitchTier");
        }
    }

    XPtr<structDurationTier> extract_duration_tier_ptr() {
        VALIDATE_PTR(ptr, Manipulation);
        if (!ptr->duration) Rcpp::stop("No duration tier in Manipulation");
        try {
            autoDurationTier tier = Data_copy(ptr->duration.get());
            structDurationTier* raw = tier.releaseToAmbiguousOwner();
            return XPtr<structDurationTier>(raw, true);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to extract DurationTier");
        }
    }

    XPtr<structPointProcess> extract_pulses_ptr() {
        VALIDATE_PTR(ptr, Manipulation);
        if (!ptr->pulses) Rcpp::stop("No pulses in Manipulation");
        try {
            autoPointProcess pp = Data_copy(ptr->pulses.get());
            structPointProcess* raw = pp.releaseToAmbiguousOwner();
            return XPtr<structPointProcess>(raw, true);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to extract pulses");
        }
    }

    XPtr<structSound> extract_original_sound_ptr() {
        VALIDATE_PTR(ptr, Manipulation);
        if (!ptr->sound) Rcpp::stop("No original sound in Manipulation");
        try {
            autoSound sound = Data_copy(ptr->sound.get());
            structSound* raw = sound.releaseToAmbiguousOwner();
            return XPtr<structSound>(raw, true);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to extract original sound");
        }
    }

    // Replace tiers
    void replace_pitch_tier(XPtr<structPitchTier> pitch_tier) {
        VALIDATE_PTR(ptr, Manipulation);
        if (!pitch_tier || !pitch_tier.get()) Rcpp::stop("Invalid PitchTier pointer");
        try {
            autoPitchTier tier_copy = Data_copy(pitch_tier.get());
            ptr->pitch = tier_copy.move();
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to replace PitchTier");
        }
    }

    void replace_duration_tier(XPtr<structDurationTier> duration_tier) {
        VALIDATE_PTR(ptr, Manipulation);
        if (!duration_tier || !duration_tier.get()) Rcpp::stop("Invalid DurationTier pointer");
        try {
            autoDurationTier tier_copy = Data_copy(duration_tier.get());
            ptr->duration = tier_copy.move();
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to replace DurationTier");
        }
    }

    void replace_pulses(XPtr<structPointProcess> pulses) {
        VALIDATE_PTR(ptr, Manipulation);
        if (!pulses || !pulses.get()) Rcpp::stop("Invalid PointProcess pointer");
        try {
            autoPointProcess pp_copy = Data_copy(pulses.get());
            ptr->pulses = pp_copy.move();
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to replace pulses");
        }
    }

    // Resynthesis methods
    XPtr<structSound> get_resynthesis_overlap_add_ptr() {
        VALIDATE_PTR(ptr, Manipulation);
        try {
            autoSound sound = Manipulation_to_Sound(ptr.get(), Manipulation_OVERLAPADD);
            structSound* raw = sound.releaseToAmbiguousOwner();
            return XPtr<structSound>(raw, true);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to resynthesize sound (overlap-add)");
        }
    }

    XPtr<structSound> get_resynthesis_pulses_ptr() {
        VALIDATE_PTR(ptr, Manipulation);
        try {
            autoSound sound = Manipulation_to_Sound(ptr.get(), Manipulation_PULSES);
            structSound* raw = sound.releaseToAmbiguousOwner();
            return XPtr<structSound>(raw, true);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to resynthesize sound (pulses)");
        }
    }

    XPtr<structSound> get_resynthesis_pulses_hum_ptr() {
        VALIDATE_PTR(ptr, Manipulation);
        try {
            autoSound sound = Manipulation_to_Sound(ptr.get(), Manipulation_PULSES_HUM);
            structSound* raw = sound.releaseToAmbiguousOwner();
            return XPtr<structSound>(raw, true);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to resynthesize sound (pulses hum)");
        }
    }

    // Export
    List get_info() {
        VALIDATE_PTR(ptr, Manipulation);
        return List::create(
            Named("xmin") = ptr->xmin,
            Named("xmax") = ptr->xmax,
            Named("has_pitch_tier") = !!ptr->pitch,
            Named("has_duration_tier") = !!ptr->duration,
            Named("has_pulses") = !!ptr->pulses,
            Named("has_sound") = !!ptr->sound
        );
    }

    void save(std::string path) {
        VALIDATE_PTR(ptr, Manipulation);
        try {
            structMelderFile file = {};
            Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
            Data_writeToTextFile(ptr.get(), &file);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to save Manipulation");
        }
    }
};

// Factory functions
static XPtr<structManipulation> Module_Sound_to_Manipulation(
    XPtr<structSound> sound, double time_step,
    double pitch_floor, double pitch_ceiling) {
    if (!sound || !sound.get()) Rcpp::stop("Invalid Sound pointer");
    try {
        autoManipulation manip = Sound_to_Manipulation(
            sound.get(), time_step, pitch_floor, pitch_ceiling
        );
        structManipulation* raw = manip.releaseToAmbiguousOwner();
        return XPtr<structManipulation>(raw, true);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to create Manipulation from Sound");
    }
}

static XPtr<structManipulation> Module_Manipulation_create(
    double tmin, double tmax) {
    try {
        autoManipulation manip = Manipulation_create(tmin, tmax);
        structManipulation* raw = manip.releaseToAmbiguousOwner();
        return XPtr<structManipulation>(raw, true);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to create Manipulation");
    }
}

RCPP_MODULE(manipulation_module) {
    class_<RManipulation>("RManipulation")
        .constructor()
        .constructor<XPtr<structManipulation>>()
        .method("is_valid", &RManipulation::is_valid)
        // Time domain
        .method("get_xmin", &RManipulation::get_xmin)
        .method("get_xmax", &RManipulation::get_xmax)
        .method("get_duration", &RManipulation::get_duration)
        // Tier checks
        .method("has_pitch_tier", &RManipulation::has_pitch_tier)
        .method("has_duration_tier", &RManipulation::has_duration_tier)
        .method("has_pulses", &RManipulation::has_pulses)
        .method("has_original_sound", &RManipulation::has_original_sound)
        // Extract tiers
        .method("extract_pitch_tier_ptr", &RManipulation::extract_pitch_tier_ptr)
        .method("extract_duration_tier_ptr", &RManipulation::extract_duration_tier_ptr)
        .method("extract_pulses_ptr", &RManipulation::extract_pulses_ptr)
        .method("extract_original_sound_ptr", &RManipulation::extract_original_sound_ptr)
        // Replace tiers
        .method("replace_pitch_tier", &RManipulation::replace_pitch_tier)
        .method("replace_duration_tier", &RManipulation::replace_duration_tier)
        .method("replace_pulses", &RManipulation::replace_pulses)
        // Resynthesis
        .method("get_resynthesis_overlap_add_ptr", &RManipulation::get_resynthesis_overlap_add_ptr)
        .method("get_resynthesis_pulses_ptr", &RManipulation::get_resynthesis_pulses_ptr)
        .method("get_resynthesis_pulses_hum_ptr", &RManipulation::get_resynthesis_pulses_hum_ptr)
        // Export
        .method("get_info", &RManipulation::get_info)
        .method("save", &RManipulation::save)
    ;

    // Factory functions
    function("Sound_to_Manipulation", &Module_Sound_to_Manipulation);
    function("Manipulation_create", &Module_Manipulation_create);
}
