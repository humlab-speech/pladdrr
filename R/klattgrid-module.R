# klattgrid-module.R
# R wrapper for KlattGrid Rcpp module
# Phase 2.3 - Klatt formant synthesizer for articulatory speech synthesis

#' Create a KlattGrid object
#'
#' A KlattGrid is a speech synthesizer based on the Klatt formant synthesizer.
#' It allows detailed control over phonation, vocal tract resonances, frication,
#' and other articulatory parameters.
#'
#' @param tmin Start time in seconds
#' @param tmax End time in seconds
#' @param numberOfFormants Number of oral formants (typically 6)
#' @param numberOfNasalFormants Number of nasal formants (typically 1)
#' @param numberOfNasalAntiFormants Number of nasal antiformants (typically 1)
#' @param numberOfTrachealFormants Number of tracheal formants (typically 1)
#' @param numberOfTrachealAntiFormants Number of tracheal antiformants (typically 1)
#' @param numberOfFricationFormants Number of frication formants (typically 6)
#' @param numberOfDeltaFormants Number of delta formants (typically 1)
#'
#' @return KlattGrid object with S3 class
#' @export
#'
#' @examples
#' \dontrun{
#' # Create empty KlattGrid
#' kg <- KlattGrid(0, 1, numberOfFormants = 6)
#' 
#' # Set pitch contour
#' kg$add_pitch_point(0.5, 100)  # 100 Hz at 0.5s
#' 
#' # Set formant frequencies
#' kg$add_formant_point(0, 1, 0.5, 500)  # F1 = 500 Hz
#' kg$add_formant_point(0, 2, 0.5, 1500) # F2 = 1500 Hz
#' 
#' # Synthesize
#' sound <- kg$to_sound()
#' }
KlattGrid <- function(tmin = 0.0,
                      tmax = 1.0,
                      numberOfFormants = 6L,
                      numberOfNasalFormants = 1L,
                      numberOfNasalAntiFormants = 1L,
                      numberOfTrachealFormants = 1L,
                      numberOfTrachealAntiFormants = 1L,
                      numberOfFricationFormants = 6L,
                      numberOfDeltaFormants = 1L) {
    
    # Get module
    mod <- get_module("klattgrid_module")
    
    # Create KlattGrid
    xptr <- mod$klattgrid_create(
        tmin, tmax,
        as.integer(numberOfFormants),
        as.integer(numberOfNasalFormants),
        as.integer(numberOfNasalAntiFormants),
        as.integer(numberOfTrachealFormants),
        as.integer(numberOfTrachealAntiFormants),
        as.integer(numberOfFricationFormants),
        as.integer(numberOfDeltaFormants)
    )
    
    # Wrap in RKlattGrid class
    cpp_obj <- mod$RKlattGrid$new(xptr)
    
    # Create R object with methods
    obj <- structure(list(
        .cpp = cpp_obj,
        
        # Validation
        is_valid = function() cpp_obj$is_valid(),
        
        # Time domain
        get_xmin = function() cpp_obj$get_xmin(),
        get_xmax = function() cpp_obj$get_xmax(),
        get_duration = function() cpp_obj$get_duration(),
        
        # Synthesis
        to_sound = function() {
            sound_xptr <- cpp_obj$to_sound()
            Sound(.xptr = sound_xptr)
        },
        
        to_sound_phonation = function() {
            sound_xptr <- cpp_obj$to_sound_phonation()
            Sound(.xptr = sound_xptr)
        },
        
        # Pitch manipulation
        get_pitch_at_time = function(t) {
            cpp_obj$get_pitch_at_time(t)
        },
        
        add_pitch_point = function(t, value) {
            cpp_obj$add_pitch_point(t, value)
            invisible(obj)
        },
        
        remove_pitch_points = function(t1, t2) {
            cpp_obj$remove_pitch_points(t1, t2)
            invisible(obj)
        },
        
        # Voicing amplitude
        get_voicing_amplitude_at_time = function(t) {
            cpp_obj$get_voicing_amplitude_at_time(t)
        },
        
        add_voicing_amplitude_point = function(t, value) {
            cpp_obj$add_voicing_amplitude_point(t, value)
            invisible(obj)
        },
        
        # Formant manipulation
        # formantType: 0=oral, 1=nasal, 2=frication, 3=tracheal, 4=nasal_anti, 5=tracheal_anti, 6=delta
        get_formant_at_time = function(formantType, iformant, t) {
            cpp_obj$get_formant_at_time(as.integer(formantType), as.integer(iformant), t)
        },
        
        add_formant_point = function(formantType, iformant, t, value) {
            cpp_obj$add_formant_point(as.integer(formantType), as.integer(iformant), t, value)
            invisible(obj)
        },
        
        remove_formant_points = function(formantType, iformant, t1, t2) {
            cpp_obj$remove_formant_points(as.integer(formantType), as.integer(iformant), t1, t2)
            invisible(obj)
        },
        
        # Bandwidth manipulation
        get_bandwidth_at_time = function(formantType, iformant, t) {
            cpp_obj$get_bandwidth_at_time(as.integer(formantType), as.integer(iformant), t)
        },
        
        add_bandwidth_point = function(formantType, iformant, t, value) {
            cpp_obj$add_bandwidth_point(as.integer(formantType), as.integer(iformant), t, value)
            invisible(obj)
        },
        
        # File I/O
        save = function(path) {
            cpp_obj$save(path)
            invisible(obj)
        },
        
        # Print method
        print = function() {
            cat("KlattGrid object\n")
            cat("  Duration:", cpp_obj$get_duration(), "s\n")
            cat("  Time range: [", cpp_obj$get_xmin(), ",", cpp_obj$get_xmax(), "]\n")
            invisible(obj)
        }
    ), class = c("KlattGrid", "PraatObject"))
    
    obj
}

#' Create KlattGrid from vowel parameters
#'
#' Creates a KlattGrid pre-configured for synthesizing a vowel sound
#' with specified formant frequencies and bandwidths.
#'
#' @param duration Duration in seconds
#' @param f0start Starting F0 in Hz
#' @param f1 First formant frequency in Hz
#' @param b1 First formant bandwidth in Hz
#' @param f2 Second formant frequency in Hz
#' @param b2 Second formant bandwidth in Hz
#' @param f3 Third formant frequency in Hz
#' @param b3 Third formant bandwidth in Hz
#' @param f4 Fourth formant frequency in Hz (optional)
#' @param bandWidthFraction Bandwidth as fraction of frequency (default 0.05)
#' @param formantFrequencyInterval Formant spacing interval in Hz (default 1000)
#'
#' @return KlattGrid object configured for vowel
#' @export
KlattGrid_createFromVowel <- function(duration = 0.5,
                                      f0start = 100.0,
                                      f1 = 500.0, b1 = 50.0,
                                      f2 = 1500.0, b2 = 100.0,
                                      f3 = 2500.0, b3 = 150.0,
                                      f4 = 3500.0,
                                      bandWidthFraction = 0.05,
                                      formantFrequencyInterval = 1000.0) {
    
    mod <- get_module("klattgrid_module")
    
    xptr <- mod$klattgrid_create_from_vowel(
        duration, f0start,
        f1, b1, f2, b2, f3, b3, f4,
        bandWidthFraction,
        formantFrequencyInterval
    )
    
    cpp_obj <- mod$RKlattGrid$new(xptr)
    
    obj <- structure(list(
        .cpp = cpp_obj,
        is_valid = function() cpp_obj$is_valid(),
        get_xmin = function() cpp_obj$get_xmin(),
        get_xmax = function() cpp_obj$get_xmax(),
        get_duration = function() cpp_obj$get_duration(),
        to_sound = function() {
            sound_xptr <- cpp_obj$to_sound()
            Sound(.xptr = sound_xptr)
        },
        to_sound_phonation = function() {
            sound_xptr <- cpp_obj$to_sound_phonation()
            Sound(.xptr = sound_xptr)
        },
        get_pitch_at_time = function(t) cpp_obj$get_pitch_at_time(t),
        add_pitch_point = function(t, value) {
            cpp_obj$add_pitch_point(t, value)
            invisible(obj)
        },
        remove_pitch_points = function(t1, t2) {
            cpp_obj$remove_pitch_points(t1, t2)
            invisible(obj)
        },
        get_voicing_amplitude_at_time = function(t) cpp_obj$get_voicing_amplitude_at_time(t),
        add_voicing_amplitude_point = function(t, value) {
            cpp_obj$add_voicing_amplitude_point(t, value)
            invisible(obj)
        },
        get_formant_at_time = function(formantType, iformant, t) {
            cpp_obj$get_formant_at_time(as.integer(formantType), as.integer(iformant), t)
        },
        add_formant_point = function(formantType, iformant, t, value) {
            cpp_obj$add_formant_point(as.integer(formantType), as.integer(iformant), t, value)
            invisible(obj)
        },
        remove_formant_points = function(formantType, iformant, t1, t2) {
            cpp_obj$remove_formant_points(as.integer(formantType), as.integer(iformant), t1, t2)
            invisible(obj)
        },
        get_bandwidth_at_time = function(formantType, iformant, t) {
            cpp_obj$get_bandwidth_at_time(as.integer(formantType), as.integer(iformant), t)
        },
        add_bandwidth_point = function(formantType, iformant, t, value) {
            cpp_obj$add_bandwidth_point(as.integer(formantType), as.integer(iformant), t, value)
            invisible(obj)
        },
        save = function(path) {
            cpp_obj$save(path)
            invisible(obj)
        },
        print = function() {
            cat("KlattGrid object (from vowel)\n")
            cat("  Duration:", cpp_obj$get_duration(), "s\n")
            invisible(obj)
        }
    ), class = c("KlattGrid", "PraatObject"))
    
    obj
}

#' Create example KlattGrid
#'
#' Creates a demonstration KlattGrid with pre-configured parameters
#' for testing the synthesizer.
#'
#' @return KlattGrid example object
#' @export
KlattGrid_createExample <- function() {
    mod <- get_module("klattgrid_module")
    
    xptr <- mod$klattgrid_create_example()
    cpp_obj <- mod$RKlattGrid$new(xptr)
    
    obj <- structure(list(
        .cpp = cpp_obj,
        is_valid = function() cpp_obj$is_valid(),
        get_xmin = function() cpp_obj$get_xmin(),
        get_xmax = function() cpp_obj$get_xmax(),
        get_duration = function() cpp_obj$get_duration(),
        to_sound = function() {
            sound_xptr <- cpp_obj$to_sound()
            Sound(.xptr = sound_xptr)
        },
        to_sound_phonation = function() {
            sound_xptr <- cpp_obj$to_sound_phonation()
            Sound(.xptr = sound_xptr)
        },
        print = function() {
            cat("KlattGrid example\n")
            cat("  Duration:", cpp_obj$get_duration(), "s\n")
            invisible(obj)
        }
    ), class = c("KlattGrid", "PraatObject"))
    
    obj
}
