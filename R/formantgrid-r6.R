#' FormantGrid Class
#'
#' R6 class representing a Praat FormantGrid object. FormantGrid objects allow
#' manipulation of formant frequencies and bandwidths over time for voice
#' transformation and synthesis. This is the editable counterpart to the
#' read-only Formant object.
#'
#' @export
FormantGrid <- R6::R6Class("FormantGrid",
  inherit = PraatObject,
  
  public = list(
    #' @description
    #' Create a new FormantGrid object
    #' @param tmin Start time in seconds
    #' @param tmax End time in seconds
    #' @param number_of_formants Integer number of formant tiers to create
    #' @param initial_first_formant Frequency of F1 in Hz (default: 550)
    #' @param initial_formant_spacing Spacing between formants in Hz (default: 1100)
    #' @param initial_first_bandwidth Bandwidth of F1 in Hz (default: 60)
    #' @param initial_bandwidth_spacing Spacing between bandwidths in Hz (default: 50)
    #' @param .xptr Internal: external pointer to Praat FormantGrid object
    #' @return A new FormantGrid object
    initialize = function(tmin = NULL, tmax = NULL, number_of_formants = 10,
                         initial_first_formant = 550, initial_formant_spacing = 1100,
                         initial_first_bandwidth = 60, initial_bandwidth_spacing = 50,
                         .xptr = NULL) {
      if (!is.null(.xptr)) {
        # Created from existing pointer
        if (!inherits(.xptr, "externalptr")) {
          stop(".xptr must be an external pointer")
        }
        private$ptr <- .xptr
      } else {
        # Create new FormantGrid - validate parameters
        stopifnot(
          "tmin and tmax must be provided when creating a new FormantGrid" = 
            !is.null(tmin) && !is.null(tmax),
          "tmin must be less than tmax" = tmin < tmax,
          "number_of_formants must be positive" = number_of_formants > 0
        )
        private$ptr <- .formantgrid_create(
          tmin, tmax, as.integer(number_of_formants),
          initial_first_formant, initial_formant_spacing,
          initial_first_bandwidth, initial_bandwidth_spacing
        )
      }
    },
    
    # ========================================================================
    # Query methods - Time domain
    # ========================================================================
    
    #' @description Get the start time
    #' @return Start time in seconds
    get_start_time = function() {
      .formantgrid_get_start_time(private$ptr)
    },
    
    #' @description Get the end time
    #' @return End time in seconds
    get_end_time = function() {
      .formantgrid_get_end_time(private$ptr)
    },
    
    #' @description Get the number of formants
    #' @return Integer number of formant tiers
    get_number_of_formants = function() {
      .formantgrid_get_number_of_formants(private$ptr)
    },
    
    # ========================================================================
    # Query methods - Formant values
    # ========================================================================
    
    #' @description Get formant frequency at a specific time
    #' @param formant_number Integer formant number (1 = F1, 2 = F2, etc.)
    #' @param time Time in seconds
    #' @return Formant frequency in Hz, or NA if undefined
    get_formant_at_time = function(formant_number, time) {
      .formantgrid_get_formant_at_time(private$ptr, as.integer(formant_number), time)
    },
    
    #' @description Get formant bandwidth at a specific time
    #' @param formant_number Integer formant number (1 = F1, 2 = F2, etc.)
    #' @param time Time in seconds
    #' @return Formant bandwidth in Hz, or NA if undefined
    get_bandwidth_at_time = function(formant_number, time) {
      .formantgrid_get_bandwidth_at_time(private$ptr, as.integer(formant_number), time)
    },
    
    # ========================================================================
    # Modification methods
    # ========================================================================
    
    #' @description Add a formant frequency point
    #' @param formant_number Integer formant number (1 = F1, 2 = F2, etc.)
    #' @param time Time in seconds
    #' @param value Formant frequency in Hz
    #' @return Invisible self for method chaining
    add_formant_point = function(formant_number, time, value) {
      .formantgrid_add_formant_point(private$ptr, as.integer(formant_number), time, value)
      invisible(self)
    },
    
    #' @description Add a formant bandwidth point
    #' @param formant_number Integer formant number (1 = F1, 2 = F2, etc.)
    #' @param time Time in seconds
    #' @param value Formant bandwidth in Hz
    #' @return Invisible self for method chaining
    add_bandwidth_point = function(formant_number, time, value) {
      .formantgrid_add_bandwidth_point(private$ptr, as.integer(formant_number), time, value)
      invisible(self)
    },
    
    #' @description Remove formant frequency points in a time range
    #' @param formant_number Integer formant number (1 = F1, 2 = F2, etc.)
    #' @param tmin Start time in seconds
    #' @param tmax End time in seconds
    #' @return Invisible self for method chaining
    remove_formant_points_between = function(formant_number, tmin, tmax) {
      .formantgrid_remove_formant_points_between(private$ptr, as.integer(formant_number), tmin, tmax)
      invisible(self)
    },
    
    #' @description Remove formant bandwidth points in a time range
    #' @param formant_number Integer formant number (1 = F1, 2 = F2, etc.)
    #' @param tmin Start time in seconds
    #' @param tmax End time in seconds
    #' @return Invisible self for method chaining
    remove_bandwidth_points_between = function(formant_number, tmin, tmax) {
      .formantgrid_remove_bandwidth_points_between(private$ptr, as.integer(formant_number), tmin, tmax)
      invisible(self)
    },
    
    # ========================================================================
    # Conversion methods
    # ========================================================================
    
    #' @description Convert FormantGrid to Formant object
    #' @param time_step Time step for Formant frames in seconds (default: 0.01)
    #' @param intensity Intensity for formant extraction in dB (default: 70)
    #' @return A new Formant object
    to_formant = function(time_step = 0.01, intensity = 70) {
      formant_ptr <- .formantgrid_to_formant(private$ptr, time_step, intensity)
      Formant$new(.xptr = formant_ptr)
    },
    
    # ========================================================================
    # Synthesis methods
    # ========================================================================
    
    #' @description Synthesize sound from FormantGrid
    #' @param sampling_frequency Sampling frequency in Hz (default: 44100)
    #' @param t_start Time of first pitch point in seconds (default: 0)
    #' @param f0_start F0 at first pitch point in Hz (default: 100)
    #' @param t_mid Time of second pitch point in seconds (default: 0.5)
    #' @param f0_mid F0 at second pitch point in Hz (default: 100)
    #' @param t_end Time of third pitch point in seconds (default: 1.0)
    #' @param f0_end F0 at third pitch point in Hz (default: 100)
    #' @param adapt_factor Voicing adapt factor (default: 1.0)
    #' @param maximum_period Maximum period in seconds (default: 0.05)
    #' @param open_phase Open phase (default: 0.7)
    #' @param collision_phase Collision phase (default: 0.03)
    #' @param power1 Power 1 parameter (default: 3)
    #' @param power2 Power 2 parameter (default: 4)
    #' @return A new Sound object
    to_sound = function(sampling_frequency = 44100,
                       t_start = 0, f0_start = 100,
                       t_mid = 0.5, f0_mid = 100,
                       t_end = 1.0, f0_end = 100,
                       adapt_factor = 1.0, maximum_period = 0.05,
                       open_phase = 0.7, collision_phase = 0.03,
                       power1 = 3, power2 = 4) {
      sound_ptr <- .formantgrid_to_sound(
        private$ptr,
        sampling_frequency,
        t_start, f0_start,
        t_mid, f0_mid,
        t_end, f0_end,
        adapt_factor, maximum_period,
        open_phase, collision_phase,
        power1, power2
      )
      Sound$new(.xptr = sound_ptr)
    }
  )
)

# ============================================================================
# Constructor helpers
# ============================================================================

#' Create an empty FormantGrid
#'
#' Creates a FormantGrid with specified time range and number of formants,
#' but without any initial formant values.
#'
#' @param tmin Start time in seconds
#' @param tmax End time in seconds
#' @param number_of_formants Integer number of formant tiers to create
#' @return A new FormantGrid object
#' @export
praat_formantgrid_create_empty <- function(tmin, tmax, number_of_formants = 10) {
  grid_ptr <- .formantgrid_create_empty(tmin, tmax, as.integer(number_of_formants))
  FormantGrid$new(.xptr = grid_ptr)
}

# ============================================================================
# Sound filtering methods
# ============================================================================

#' Filter sound with FormantGrid
#'
#' @param sound A Sound object
#' @param formantgrid A FormantGrid object
#' @param scale Logical; whether to scale amplitude (default: TRUE)
#' @return A new filtered Sound object
#' @export
praat_sound_formantgrid_filter <- function(sound, formantgrid, scale = TRUE) {
  if (!inherits(sound, "Sound")) {
    stop("sound must be a Sound object")
  }
  if (!inherits(formantgrid, "FormantGrid")) {
    stop("formantgrid must be a FormantGrid object")
  }
  
  sound_ptr <- if (scale) {
    .sound_formantgrid_filter(sound$get_pointer(), formantgrid$get_pointer())
  } else {
    .sound_formantgrid_filter_noscale(sound$get_pointer(), formantgrid$get_pointer())
  }
  
  Sound$new(.xptr = sound_ptr)
}
