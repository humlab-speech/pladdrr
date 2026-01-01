# formantpath-module.R
# R wrapper for FormantPath Rcpp module
# Phase 2.2 - Robust formant tracking with multiple candidates

#' Create a FormantPath object from a Sound
#'
#' A FormantPath object represents multiple formant tracking candidates with
#' different ceiling frequencies, allowing for robust formant analysis by
#' automatically selecting the optimal tracking path.
#'
#' @param sound A Sound object or path to audio file
#' @param time_step Time step for analysis in seconds (0 = auto)
#' @param max_num_formants Maximum number of formants to track (typically 5)
#' @param formant_ceiling Maximum formant frequency in Hz (typically 5000-5500)
#' @param window_length Analysis window length in seconds (typically 0.025)
#' @param preemphasis_from Preemphasis frequency in Hz (typically 50)
#' @param ceiling_step_fraction Step size for ceiling frequency variation (0.05-0.1)
#' @param num_steps_up_down Number of steps above/below ceiling (typically 2-4)
#'
#' @return FormantPath object with S3 class
#' @export
#'
#' @examples
#' \dontrun{
#' sound <- Sound("vowel.wav")
#' fp <- FormantPath(sound, max_num_formants = 5, formant_ceiling = 5500)
#' 
#' # Get number of candidate tracks
#' fp$get_number_of_candidates()
#' 
#' # Extract optimal formant
#' formant <- fp$extract_formant()
#' 
#' # Export to data frame
#' df <- as.data.frame(fp)
#' }
FormantPath <- function(sound,
                        time_step = 0.0,
                        max_num_formants = 5.0,
                        formant_ceiling = 5500.0,
                        window_length = 0.025,
                        preemphasis_from = 50.0,
                        ceiling_step_fraction = 0.05,
                        num_steps_up_down = 4L) {
    
    # Get the module
    mod <- get_module("formantpath_module")
    
    # Handle sound input
    if (is.character(sound)) {
        sound <- Sound(sound)
    }
    
    if (!inherits(sound, "Sound")) {
        stop("sound must be a Sound object or path to audio file")
    }
    
    # Get the C++ Sound pointer
    sound_ptr <- sound$.cpp$ptr
    
    # Create FormantPath
    xptr <- mod$formantpath_create_from_sound_burg(
        sound_ptr,
        time_step,
        max_num_formants,
        formant_ceiling,
        window_length,
        preemphasis_from,
        ceiling_step_fraction,
        as.integer(num_steps_up_down)
    )
    
    # Wrap in RFormantPath class
    cpp_obj <- mod$RFormantPath$new(xptr)
    
    # Create R object with methods
    obj <- structure(list(
        .cpp = cpp_obj,
        
        # Validation
        is_valid = function() cpp_obj$is_valid(),
        
        # Time domain properties
        get_xmin = function() cpp_obj$get_xmin(),
        get_xmax = function() cpp_obj$get_xmax(),
        get_duration = function() cpp_obj$get_duration(),
        get_nx = function() cpp_obj$get_nx(),
        get_dx = function() cpp_obj$get_dx(),
        get_x1 = function() cpp_obj$get_x1(),
        
        # Candidate/track properties
        get_number_of_candidates = function() cpp_obj$get_number_of_candidates(),
        get_number_of_formant_tracks = function() cpp_obj$get_number_of_formant_tracks(),
        get_ceiling_frequency = function(candidate) cpp_obj$get_ceiling_frequency(as.integer(candidate)),
        get_all_ceiling_frequencies = function() cpp_obj$get_all_ceiling_frequencies(),
        
        # Path query
        get_candidate_in_frame = function(frame_number) {
            cpp_obj$get_candidate_in_frame(as.integer(frame_number))
        },
        
        # Stress and optimization
        get_stress_of_candidate = function(tmin = NULL, tmax = NULL, 
                                          from_formant = 1L, to_formant = 5L,
                                          parameters = c(1L, 1L, 1L, 1L, 1L),
                                          powerf = 1.25, candidate = 1L) {
            if (is.null(tmin)) tmin <- cpp_obj$get_xmin()
            if (is.null(tmax)) tmax <- cpp_obj$get_xmax()
            cpp_obj$get_stress_of_candidate(
                tmin, tmax,
                as.integer(from_formant), as.integer(to_formant),
                as.numeric(parameters), powerf, as.integer(candidate)
            )
        },
        
        get_optimal_ceiling = function(tmin = NULL, tmax = NULL,
                                      parameters = c(1L, 1L, 1L, 1L, 1L),
                                      powerf = 1.25) {
            if (is.null(tmin)) tmin <- cpp_obj$get_xmin()
            if (is.null(tmax)) tmax <- cpp_obj$get_xmax()
            cpp_obj$get_optimal_ceiling(tmin, tmax, as.numeric(parameters), powerf)
        },
        
        # Path manipulation
        set_path = function(tmin = NULL, tmax = NULL, selected_candidate = 1L) {
            if (is.null(tmin)) tmin <- cpp_obj$get_xmin()
            if (is.null(tmax)) tmax <- cpp_obj$get_xmax()
            cpp_obj$set_path(tmin, tmax, as.integer(selected_candidate))
            invisible(obj)
        },
        
        set_optimal_path = function(tmin = NULL, tmax = NULL,
                                   parameters = c(1L, 1L, 1L, 1L, 1L),
                                   powerf = 1.25) {
            if (is.null(tmin)) tmin <- cpp_obj$get_xmin()
            if (is.null(tmax)) tmax <- cpp_obj$get_xmax()
            cpp_obj$set_optimal_path(tmin, tmax, as.numeric(parameters), powerf)
            invisible(obj)
        },
        
        path_finder = function(q_weight = 1.0,
                              frequency_change_weight = 1.0,
                              stress_weight = 1.0,
                              ceiling_change_weight = 1.0,
                              intensity_modulation_step_size = 5.0,
                              window_length = 0.035,
                              parameters = c(1L, 1L, 1L, 1L, 1L),
                              powerf = 1.25) {
            cpp_obj$path_finder(
                q_weight, frequency_change_weight, stress_weight,
                ceiling_change_weight, intensity_modulation_step_size,
                window_length, as.numeric(parameters), powerf
            )
            invisible(obj)
        },
        
        # Extraction
        extract_formant = function() {
            formant_xptr <- cpp_obj$extract_formant()
            formant_mod <- get_module("formant_module")
            formant_cpp <- formant_mod$RFormant$new(formant_xptr)
            
            # Wrap in R Formant object
            # Note: This reuses the existing Formant wrapper structure
            formant_obj <- structure(list(
                .cpp = formant_cpp,
                get_xmin = function() formant_cpp$get_xmin(),
                get_xmax = function() formant_cpp$get_xmax(),
                get_duration = function() formant_cpp$get_duration(),
                get_number_of_frames = function() formant_cpp$get_number_of_frames(),
                get_value_at_time = function(formant_number, time, unit = 0L) {
                    formant_cpp$get_value_at_time(as.integer(formant_number), time, as.integer(unit))
                },
                as_data_frame = function(max_formants = 5L) {
                    formant_cpp$as_data_frame(as.integer(max_formants))
                }
            ), class = c("Formant", "PraatObject"))
            
            formant_obj
        },
        
        # Export
        as_data_frame = function(max_formants = 5L) {
            cpp_obj$as_data_frame(as.integer(max_formants))
        },
        
        # I/O
        save = function(path) {
            cpp_obj$save(path)
            invisible(obj)
        },
        
        # Printing
        print = function() {
            cat("FormantPath object\n")
            cat(sprintf("  Time domain: %.3f - %.3f s (duration: %.3f s)\n",
                       cpp_obj$get_xmin(), cpp_obj$get_xmax(), cpp_obj$get_duration()))
            cat(sprintf("  Number of frames: %d\n", cpp_obj$get_nx()))
            cat(sprintf("  Time step: %.6f s\n", cpp_obj$get_dx()))
            cat(sprintf("  Number of candidates: %d\n", cpp_obj$get_number_of_candidates()))
            
            ceilings <- cpp_obj$get_all_ceiling_frequencies()
            cat(sprintf("  Ceiling frequencies: %.0f - %.0f Hz\n", 
                       min(ceilings), max(ceilings)))
            invisible(obj)
        }
    ), class = c("FormantPath", "PraatObject"))
    
    obj
}

#' @export
print.FormantPath <- function(x, ...) {
    x$print()
}

#' @export
as.data.frame.FormantPath <- function(x, row.names = NULL, optional = FALSE, 
                                      max_formants = 5L, ...) {
    x$as_data_frame(max_formants = max_formants)
}
