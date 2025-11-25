#' Formant Class
#'
#' R6 class representing a Praat Formant object. Formant objects represent
#' the resonance frequencies of the vocal tract over time.
#'
#' @export
Formant <- R6::R6Class("Formant",
  inherit = PraatObject,
  
  public = list(
    #' @description
    #' Create a new Formant object
    #' @param .xptr Internal: external pointer to Praat Formant object
    #' @return A new Formant object
    initialize = function(.xptr = NULL) {
      if (is.null(.xptr)) {
        stop("Formant objects must be created from a Sound object using to_formant_burg() or to_formant_keepall()")
      }
      if (!inherits(.xptr, "externalptr")) {
        stop(".xptr must be an external pointer")
      }
      private$ptr <- .xptr
    },
    
    # ========================================================================
    # Query methods - Time domain
    # ========================================================================
    
    #' @description Get the number of time frames
    #' @return Integer number of frames
    get_number_of_frames = function() {
      .formant_get_number_of_frames(private$ptr)
    },
    
    #' @description Get the time step between frames
    #' @return Time step in seconds
    get_time_step = function() {
      .formant_get_time_step(private$ptr)
    },
    
    #' @description Get minimum number of formants across all frames
    #' @return Integer minimum number of formants
    get_min_num_formants = function() {
      .formant_get_min_num_formants(private$ptr)
    },
    
    #' @description Get maximum number of formants across all frames
    #' @return Integer maximum number of formants
    get_max_num_formants = function() {
      .formant_get_max_num_formants(private$ptr)
    },
    
    # ========================================================================
    # Query methods - Formant values
    # ========================================================================
    
    #' @description Get formant frequency at a specific time
    #' @param formant_number Integer formant number (1 = F1, 2 = F2, etc.)
    #' @param time Time in seconds
    #' @param unit Unit for return value: "hertz" (default) or "bark"
    #' @return Formant frequency value, or NA if undefined
    get_value_at_time = function(formant_number, time, unit = c("hertz", "bark")) {
      unit <- match.arg(unit)
      unit_code <- if (unit == "hertz") 1L else 2L
      .formant_get_value_at_time(private$ptr, as.integer(formant_number), time, unit_code)
    },
    
    #' @description Get formant bandwidth at a specific time
    #' @param formant_number Integer formant number (1 = F1, 2 = F2, etc.)
    #' @param time Time in seconds
    #' @param unit Unit for return value: "hertz" (default) or "bark"
    #' @return Formant bandwidth value, or NA if undefined
    get_bandwidth_at_time = function(formant_number, time, unit = c("hertz", "bark")) {
      unit <- match.arg(unit)
      unit_code <- if (unit == "hertz") 1L else 2L
      .formant_get_bandwidth_at_time(private$ptr, as.integer(formant_number), time, unit_code)
    },
    
    #' @description Get mean formant frequency over a time range
    #' @param formant_number Integer formant number (1 = F1, 2 = F2, etc.)
    #' @param from_time Start time in seconds (0 = start of file)
    #' @param to_time End time in seconds (0 = end of file)
    #' @param unit Unit for return value: "hertz" (default) or "bark"
    #' @return Mean formant frequency
    get_mean = function(formant_number, from_time = 0, to_time = 0, unit = c("hertz", "bark")) {
      unit <- match.arg(unit)
      unit_code <- if (unit == "hertz") 1L else 2L
      .formant_get_mean(private$ptr, as.integer(formant_number), from_time, to_time, unit_code)
    },
    
    #' @description Get standard deviation of formant frequency
    #' @param formant_number Integer formant number (1 = F1, 2 = F2, etc.)
    #' @param from_time Start time in seconds (0 = start of file)
    #' @param to_time End time in seconds (0 = end of file)
    #' @param unit Unit for return value: "hertz" (default) or "bark"
    #' @return Standard deviation of formant frequency
    get_standard_deviation = function(formant_number, from_time = 0, to_time = 0, unit = c("hertz", "bark")) {
      unit <- match.arg(unit)
      unit_code <- if (unit == "hertz") 1L else 2L
      .formant_get_standard_deviation(private$ptr, as.integer(formant_number), from_time, to_time, unit_code)
    },
    
    #' @description Get quantile of formant frequency distribution
    #' @param formant_number Integer formant number (1 = F1, 2 = F2, etc.)
    #' @param quantile Quantile to compute (0-1, e.g., 0.5 for median)
    #' @param from_time Start time in seconds (0 = start of file)
    #' @param to_time End time in seconds (0 = end of file)
    #' @param unit Unit for return value: "hertz" (default) or "bark"
    #' @return Formant frequency at the specified quantile
    get_quantile = function(formant_number, quantile, from_time = 0, to_time = 0, unit = c("hertz", "bark")) {
      unit <- match.arg(unit)
      unit_code <- if (unit == "hertz") 1L else 2L
      .formant_get_quantile(private$ptr, as.integer(formant_number), quantile, from_time, to_time, unit_code)
    },
    
    #' @description Get minimum formant frequency
    #' @param formant_number Integer formant number (1 = F1, 2 = F2, etc.)
    #' @param from_time Start time in seconds (0 = start of file)
    #' @param to_time End time in seconds (0 = end of file)
    #' @param unit Unit for return value: "hertz" (default) or "bark"
    #' @param interpolate Logical; interpolate between frames?
    #' @return Minimum formant frequency
    get_minimum = function(formant_number, from_time = 0, to_time = 0, unit = c("hertz", "bark"), interpolate = FALSE) {
      unit <- match.arg(unit)
      unit_code <- if (unit == "hertz") 1L else 2L
      .formant_get_minimum(private$ptr, as.integer(formant_number), from_time, to_time, unit_code, interpolate)
    },
    
    #' @description Get maximum formant frequency
    #' @param formant_number Integer formant number (1 = F1, 2 = F2, etc.)
    #' @param from_time Start time in seconds (0 = start of file)
    #' @param to_time End time in seconds (0 = end of file)
    #' @param unit Unit for return value: "hertz" (default) or "bark"
    #' @param interpolate Logical; interpolate between frames?
    #' @return Maximum formant frequency
    get_maximum = function(formant_number, from_time = 0, to_time = 0, unit = c("hertz", "bark"), interpolate = FALSE) {
      unit <- match.arg(unit)
      unit_code <- if (unit == "hertz") 1L else 2L
      .formant_get_maximum(private$ptr, as.integer(formant_number), from_time, to_time, unit_code, interpolate)
    },
    
    #' @description Get time of minimum formant frequency
    #' @param formant_number Integer formant number (1 = F1, 2 = F2, etc.)
    #' @param from_time Start time in seconds (0 = start of file)
    #' @param to_time End time in seconds (0 = end of file)
    #' @param unit Unit for value: "hertz" (default) or "bark"
    #' @param interpolate Logical; interpolate between frames?
    #' @return Time in seconds where formant is minimum
    get_time_of_minimum = function(formant_number, from_time = 0, to_time = 0, unit = c("hertz", "bark"), interpolate = FALSE) {
      unit <- match.arg(unit)
      unit_code <- if (unit == "hertz") 1L else 2L
      .formant_get_time_of_minimum(private$ptr, as.integer(formant_number), from_time, to_time, unit_code, interpolate)
    },
    
    #' @description Get time of maximum formant frequency
    #' @param formant_number Integer formant number (1 = F1, 2 = F2, etc.)
    #' @param from_time Start time in seconds (0 = start of file)
    #' @param to_time End time in seconds (0 = end of file)
    #' @param unit Unit for value: "hertz" (default) or "bark"
    #' @param interpolate Logical; interpolate between frames?
    #' @return Time in seconds where formant is maximum
    get_time_of_maximum = function(formant_number, from_time = 0, to_time = 0, unit = c("hertz", "bark"), interpolate = FALSE) {
      unit <- match.arg(unit)
      unit_code <- if (unit == "hertz") 1L else 2L
      .formant_get_time_of_maximum(private$ptr, as.integer(formant_number), from_time, to_time, unit_code, interpolate)
    },
    
    # ========================================================================
    # Export methods
    # ========================================================================
    
    #' @description Convert formant data to data frame
    #' @param max_formants Maximum number of formants to include (default: 5)
    #' @return Data frame with columns: time, F1, F2, ..., Fn, B1, B2, ..., Bn
    #'   where Fn = formant frequency and Bn = formant bandwidth
    as_data_frame = function(max_formants = 5) {
      .formant_as_data_frame(private$ptr, as.integer(max_formants))
    },
    
    #' @description Save formant object to file
    #' @param filepath Path to output file (Praat text format)
    #' @return Invisibly returns self for method chaining
    save = function(filepath) {
      .formant_save(private$ptr, filepath)
      invisible(self)
    },
    
    # ========================================================================
    # Advanced methods
    # ========================================================================
    
    #' @description Track formant trajectories across time
    #' @param number_of_tracks Number of formant tracks to keep (default: 3)
    #' @param ref_f1 Reference F1 in Hz (default: 550)
    #' @param ref_f2 Reference F2 in Hz (default: 1650)
    #' @param ref_f3 Reference F3 in Hz (default: 2750)
    #' @param ref_f4 Reference F4 in Hz (default: 3850)
    #' @param ref_f5 Reference F5 in Hz (default: 4950)
    #' @param frequency_cost Cost per kHz deviation from reference (default: 1.0)
    #' @param bandwidth_cost Cost for bandwidth (default: 1.0)
    #' @param transition_cost Cost for frequency transitions (default: 1.0)
    #' @return A new tracked Formant object
    track = function(
      number_of_tracks = 3,
      ref_f1 = 550.0,
      ref_f2 = 1650.0,
      ref_f3 = 2750.0,
      ref_f4 = 3850.0,
      ref_f5 = 4950.0,
      frequency_cost = 1.0,
      bandwidth_cost = 1.0,
      transition_cost = 1.0
    ) {
      tracked_ptr <- .formant_tracker(
        private$ptr,
        as.integer(number_of_tracks),
        ref_f1, ref_f2, ref_f3, ref_f4, ref_f5,
        frequency_cost,
        bandwidth_cost,
        transition_cost
      )
      Formant$new(.xptr = tracked_ptr)
    },
    
    #' @description Convert Formant to FormantGrid (editable formant contours)
    #' @return A new FormantGrid object
    to_formantgrid = function() {
      grid_ptr <- .formantgrid_from_formant(private$ptr)
      FormantGrid$new(.xptr = grid_ptr)
    },
    
    #' @description Convert Formant to Table object
    #' @param include_frame_numbers Include frame numbers (default: TRUE)
    #' @param include_time Include time column (default: TRUE)
    #' @param time_decimals Number of decimals for time (default: 6)
    #' @param include_intensity Include intensity values (default: TRUE)
    #' @param intensity_decimals Number of decimals for intensity (default: 3)
    #' @param include_number_of_formants Include formant count column (default: TRUE)
    #' @param frequency_decimals Number of decimals for frequencies (default: 3)
    #' @param include_bandwidths Include bandwidth columns (default: TRUE)
    #' @param bandwidth_decimals Number of decimals for bandwidths (default: 3)
    #' @return External pointer to Table object (Table R6 class not yet implemented)
    down_to_table = function(
      include_frame_numbers = TRUE,
      include_time = TRUE,
      time_decimals = 6,
      include_intensity = TRUE,
      intensity_decimals = 3,
      include_number_of_formants = TRUE,
      frequency_decimals = 3,
      include_bandwidths = TRUE
    ) {
      table_ptr <- .formant_down_to_table(
        private$ptr,
        include_frame_numbers,
        include_time, as.integer(time_decimals),
        include_intensity, as.integer(intensity_decimals),
        include_number_of_formants, as.integer(frequency_decimals),
        include_bandwidths
      )
      Table$new(.xptr = table_ptr)
    },
    
    # ========================================================================
    # Utility methods
    # ========================================================================
    
    #' @description Print method for Formant objects
    print = function() {
      cat("<Praat Formant object>\n")
      cat(sprintf("  Number of frames: %d\n", self$get_number_of_frames()))
      cat(sprintf("  Time step: %.6f s\n", self$get_time_step()))
      cat(sprintf("  Min formants: %d\n", self$get_min_num_formants()))
      cat(sprintf("  Max formants: %d\n", self$get_max_num_formants()))
      invisible(self)
    }
  ),
  
  private = list(
    ptr = NULL
  )
)
