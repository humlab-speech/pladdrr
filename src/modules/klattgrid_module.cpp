// klattgrid_module.cpp
// Rcpp Module for Praat KlattGrid object (speech synthesis)
// Phase 2.3 - Articulatory speech synthesis with Klatt formant synthesizer

#include <Rcpp.h>
#include "module_common.h"

// Praat headers
#include "../praat.github.io/dwtools/KlattGrid.h"
#include "../praat.github.io/fon/Sound.h"
#include "../praat.github.io/melder/melder.h"

using namespace Rcpp;

// Forward declarations
extern void NUMmachar();

// ============================================================================
// Free Functions for KlattGrid Creation
// ============================================================================

// Create empty KlattGrid
XPtr<structKlattGrid> klattgrid_create(
    double tmin,
    double tmax,
    int numberOfFormants,
    int numberOfNasalFormants,
    int numberOfNasalAntiFormants,
    int numberOfTrachealFormants,
    int numberOfTrachealAntiFormants,
    int numberOfFricationFormants,
    int numberOfDeltaFormants
) {
    NUMmachar();
    
    try {
        autoKlattGrid kg = KlattGrid_create(
            tmin, tmax,
            numberOfFormants,
            numberOfNasalFormants,
            numberOfNasalAntiFormants,
            numberOfTrachealFormants,
            numberOfTrachealAntiFormants,
            numberOfFricationFormants,
            numberOfDeltaFormants
        );
        
        if (!kg) {
            Rcpp::stop("KlattGrid_create returned null");
        }
        
        return create_xptr_from_auto<structKlattGrid>(kg);
    } catch (MelderError) {
        conststring32 err = Melder_getError();
        std::string errmsg = err ? Melder_peek32to8(err) : "Unknown error";
        Melder_clearError();
        Rcpp::stop("KlattGrid creation failed: " + errmsg);
    }
}

// Create KlattGrid from vowel parameters
XPtr<structKlattGrid> klattgrid_create_from_vowel(
    double duration,
    double f0start,
    double f1, double b1,
    double f2, double b2,
    double f3, double b3,
    double f4,
    double bandWidthFraction,
    double formantFrequencyInterval
) {
    NUMmachar();
    
    try {
        autoKlattGrid kg = KlattGrid_createFromVowel(
            duration, f0start,
            f1, b1, f2, b2, f3, b3, f4,
            bandWidthFraction,
            formantFrequencyInterval
        );
        
        if (!kg) {
            Rcpp::stop("KlattGrid_createFromVowel returned null");
        }
        
        return create_xptr_from_auto<structKlattGrid>(kg);
    } catch (MelderError) {
        conststring32 err = Melder_getError();
        std::string errmsg = err ? Melder_peek32to8(err) : "Unknown error";
        Melder_clearError();
        Rcpp::stop("KlattGrid_createFromVowel failed: " + errmsg);
    }
}

// Create example KlattGrid
XPtr<structKlattGrid> klattgrid_create_example() {
    NUMmachar();
    
    try {
        autoKlattGrid kg = KlattGrid_createExample();
        
        if (!kg) {
            Rcpp::stop("KlattGrid_createExample returned null");
        }
        
        return create_xptr_from_auto<structKlattGrid>(kg);
    } catch (MelderError) {
        conststring32 err = Melder_getError();
        std::string errmsg = err ? Melder_peek32to8(err) : "Unknown error";
        Melder_clearError();
        Rcpp::stop("KlattGrid_createExample failed: " + errmsg);
    }
}

// ============================================================================
// RKlattGrid Module Class
// ============================================================================

class RKlattGrid {
public:
    Rcpp::XPtr<structKlattGrid> ptr;
    
    // Constructors
    RKlattGrid() : ptr(R_NilValue) {}
    RKlattGrid(Rcpp::XPtr<structKlattGrid> p) : ptr(p) {}
    
    // Validation
    bool is_valid() const {
        return ptr.get() != nullptr;
    }
    
    // Time domain properties
    double get_xmin() const {
        if (!is_valid()) Rcpp::stop("Invalid KlattGrid");
        return ptr->xmin;
    }
    
    double get_xmax() const {
        if (!is_valid()) Rcpp::stop("Invalid KlattGrid");
        return ptr->xmax;
    }
    
    double get_duration() const {
        return get_xmax() - get_xmin();
    }
    
    // Synthesis to Sound
    Rcpp::XPtr<structSound> to_sound() {
        if (!is_valid()) Rcpp::stop("Invalid KlattGrid");
        
        try {
            autoSound sound = KlattGrid_to_Sound(ptr.get());
            
            if (!sound) {
                Rcpp::stop("KlattGrid_to_Sound returned null");
            }
            
            return create_xptr_from_auto<structSound>(sound);
        } catch (MelderError) {
            conststring32 err = Melder_getError();
            std::string errmsg = err ? Melder_peek32to8(err) : "Unknown error";
            Melder_clearError();
            Rcpp::stop("to_sound failed: " + errmsg);
        }
    }
    
    // Synthesis - phonation only
    Rcpp::XPtr<structSound> to_sound_phonation() {
        if (!is_valid()) Rcpp::stop("Invalid KlattGrid");
        
        try {
            autoSound sound = KlattGrid_to_Sound_phonation(ptr.get());
            
            if (!sound) {
                Rcpp::stop("KlattGrid_to_Sound_phonation returned null");
            }
            
            return create_xptr_from_auto<structSound>(sound);
        } catch (MelderError) {
            conststring32 err = Melder_getError();
            std::string errmsg = err ? Melder_peek32to8(err) : "Unknown error";
            Melder_clearError();
            Rcpp::stop("to_sound_phonation failed: " + errmsg);
        }
    }
    
    // Pitch manipulation
    double get_pitch_at_time(double t) {
        if (!is_valid()) Rcpp::stop("Invalid KlattGrid");
        return KlattGrid_getPitchAtTime(ptr.get(), t);
    }
    
    void add_pitch_point(double t, double value) {
        if (!is_valid()) Rcpp::stop("Invalid KlattGrid");
        
        try {
            KlattGrid_addPitchPoint(ptr.get(), t, value);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("add_pitch_point failed");
        }
    }
    
    void remove_pitch_points(double t1, double t2) {
        if (!is_valid()) Rcpp::stop("Invalid KlattGrid");
        
        try {
            KlattGrid_removePitchPoints(ptr.get(), t1, t2);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("remove_pitch_points failed");
        }
    }
    
    // Voicing amplitude
    double get_voicing_amplitude_at_time(double t) {
        if (!is_valid()) Rcpp::stop("Invalid KlattGrid");
        return KlattGrid_getVoicingAmplitudeAtTime(ptr.get(), t);
    }
    
    void add_voicing_amplitude_point(double t, double value) {
        if (!is_valid()) Rcpp::stop("Invalid KlattGrid");
        
        try {
            KlattGrid_addVoicingAmplitudePoint(ptr.get(), t, value);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("add_voicing_amplitude_point failed");
        }
    }
    
    // Formant frequency manipulation (formantType: 0=oral, 1=nasal, etc.)
    double get_formant_at_time(int formantType, int iformant, double t) {
        if (!is_valid()) Rcpp::stop("Invalid KlattGrid");
        return KlattGrid_getFormantAtTime(
            ptr.get(),
            static_cast<kKlattGridFormantType>(formantType),
            iformant,
            t
        );
    }
    
    void add_formant_point(int formantType, int iformant, double t, double value) {
        if (!is_valid()) Rcpp::stop("Invalid KlattGrid");
        
        try {
            KlattGrid_addFormantPoint(
                ptr.get(),
                static_cast<kKlattGridFormantType>(formantType),
                iformant,
                t,
                value
            );
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("add_formant_point failed");
        }
    }
    
    void remove_formant_points(int formantType, int iformant, double t1, double t2) {
        if (!is_valid()) Rcpp::stop("Invalid KlattGrid");
        
        try {
            KlattGrid_removeFormantPoints(
                ptr.get(),
                static_cast<kKlattGridFormantType>(formantType),
                iformant,
                t1,
                t2
            );
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("remove_formant_points failed");
        }
    }
    
    // Bandwidth manipulation
    double get_bandwidth_at_time(int formantType, int iformant, double t) {
        if (!is_valid()) Rcpp::stop("Invalid KlattGrid");
        return KlattGrid_getBandwidthAtTime(
            ptr.get(),
            static_cast<kKlattGridFormantType>(formantType),
            iformant,
            t
        );
    }
    
    void add_bandwidth_point(int formantType, int iformant, double t, double value) {
        if (!is_valid()) Rcpp::stop("Invalid KlattGrid");
        
        try {
            KlattGrid_addBandwidthPoint(
                ptr.get(),
                static_cast<kKlattGridFormantType>(formantType),
                iformant,
                t,
                value
            );
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("add_bandwidth_point failed");
        }
    }
    
    // File I/O
    void save(std::string path) {
        if (!is_valid()) Rcpp::stop("Invalid KlattGrid");
        
        try {
            autoMelderString fullPath;
            MelderString_copy(&fullPath, Melder_peek8to32(path.c_str()));
            structMelderFile file {};
            Melder_pathToFile(fullPath.string, &file);
            Data_writeToTextFile(ptr.get(), &file);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("save failed");
        }
    }
};

// ============================================================================
// Module Registration
// ============================================================================

RCPP_MODULE(klattgrid_module) {
    class_<RKlattGrid>("RKlattGrid")
        // Constructors
        .constructor()
        .constructor<XPtr<structKlattGrid>>()
        
        // Validation
        .method("is_valid", &RKlattGrid::is_valid)
        
        // Time domain
        .method("get_xmin", &RKlattGrid::get_xmin)
        .method("get_xmax", &RKlattGrid::get_xmax)
        .method("get_duration", &RKlattGrid::get_duration)
        
        // Synthesis
        .method("to_sound", &RKlattGrid::to_sound)
        .method("to_sound_phonation", &RKlattGrid::to_sound_phonation)
        
        // Pitch
        .method("get_pitch_at_time", &RKlattGrid::get_pitch_at_time)
        .method("add_pitch_point", &RKlattGrid::add_pitch_point)
        .method("remove_pitch_points", &RKlattGrid::remove_pitch_points)
        
        // Voicing
        .method("get_voicing_amplitude_at_time", &RKlattGrid::get_voicing_amplitude_at_time)
        .method("add_voicing_amplitude_point", &RKlattGrid::add_voicing_amplitude_point)
        
        // Formants
        .method("get_formant_at_time", &RKlattGrid::get_formant_at_time)
        .method("add_formant_point", &RKlattGrid::add_formant_point)
        .method("remove_formant_points", &RKlattGrid::remove_formant_points)
        
        // Bandwidths
        .method("get_bandwidth_at_time", &RKlattGrid::get_bandwidth_at_time)
        .method("add_bandwidth_point", &RKlattGrid::add_bandwidth_point)
        
        // File I/O
        .method("save", &RKlattGrid::save)
    ;
    
    // Factory functions
    function("klattgrid_create", &klattgrid_create);
    function("klattgrid_create_from_vowel", &klattgrid_create_from_vowel);
    function("klattgrid_create_example", &klattgrid_create_example);
}
