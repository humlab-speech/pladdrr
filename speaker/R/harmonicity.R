#' @title Praat Harmonicity Object
#' @description
#' R6 class representing a Praat Harmonicity object (Harmonics-to-Noise Ratio).
#' Wraps a Praat C++ Harmonicity object with automatic memory management.
#'
#' @details
#' A Harmonicity object represents the degree of acoustic periodicity (HNR)
#' in a sound over time, measured in decibels. Higher values indicate more
#' harmonic (periodic) structure, while lower values indicate more noise.
#'
#' ## Creating Harmonicity Objects
#'
#' Harmonicity objects are typically created from Sound objects:
#' - `sound$to_harmonicity_ac(...)` - Autocorrelation method (recommended)
#' - `sound$to_harmonicity_cc(...)` - Cross-correlation method
#'
#' ## Querying
#'
#' Query methods return HNR values:
#' - `$get_value_at_time(time)` - HNR at specific time
#' - `$get_mean(from, to)` - Mean HNR
#' - `$get_minimum(from, to)` - Minimum HNR
#' - `$get_maximum(from, to)` - Maximum HNR
#' - `$get_standard_deviation(from, to)` - SD of HNR
#' - `$get_time_of_minimum(from, to)` - When HNR is lowest
#' - `$get_time_of_maximum(from, to)` - When HNR is highest
#'
#' ## Export
#'
#' Export methods convert to R data structures:
#' - `$as_data_frame()` - Data frame with time and HNR columns
#' - `$as_matrix()` - Matrix with 2 rows: time and HNR
#'
#' @section Praat Equivalent:
#' This class wraps Praat's Harmonicity object, created via:
#' - "To Harmonicity (ac)..." - Autocorrelation method
#' - "To Harmonicity (cc)..." - Cross-correlation method
#'
#' @examples
#' \dontrun{
#' # From Sound object
#' sound <- Sound$new("recording.wav")
#' hnr <- sound$to_harmonicity_ac(time_step = 0.01, min_pitch = 75)
#'
#' # Query values
#' mean_hnr <- hnr$get_mean()
#' hnr_at_1s <- hnr$get_value_at_time(1.0)
#' min_hnr <- hnr$get_minimum()
#'
#' # Export to R
#' df <- hnr$as_data_frame()
#' plot(df$time, df$hnr_db, type = "l", xlab = "Time (s)", ylab = "HNR (dB)")
#' }
#'
#' @export
Harmonicity <- R6::R6Class(
  "Harmonicity",
  inherit = PraatObject,
  
  public = list(
    
    #' @description
    #' Create a Harmonicity object (internal use - use Sound$to_harmonicity_*() instead)
    #' @param .xptr External pointer to C++ Harmonicity object
    #' @return A new Harmonicity object
    initialize = function(.xptr) {
      if (is.null(.xptr)) {
        stop("Harmonicity objects should be created from Sound objects using to_harmonicity_ac() or to_harmonicity_cc()")
      }
      super$initialize(.xptr)
    },
    
    # ========================================================================
    # Query Methods
    # ========================================================================
    
    #' @description Get HNR value at specific time
    #' @param time Time in seconds
    #' @param interpolation Interpolation method: "nearest", "linear", "cubic", "sinc70", "sinc700"
    #' @return HNR in dB (or NA if undefined)
    get_value_at_time = function(time, interpolation = "cubic") {
      interpolation_code <- switch(interpolation,
        "nearest" = 0,
        "linear" = 1,
        "cubic" = 2,
        "sinc70" = 3,
        "sinc700" = 4,
        2  # default to cubic
      )
      .harmonicity_get_value_at_time(private$ptr, time, interpolation_code)
    },
    
    #' @description Get mean HNR
    #' @param from_time Start time (0 = start of object)
    #' @param to_time End time (0 = end of object)
    #' @return Mean HNR in dB
    get_mean = function(from_time = 0, to_time = 0) {
      .harmonicity_get_mean(private$ptr, from_time, to_time)
    },
    
    #' @description Get minimum HNR
    #' @param from_time Start time (0 = start of object)
    #' @param to_time End time (0 = end of object)
    #' @param interpolation Interpolation method: "parabolic" (recommended) or "none"
    #' @return Minimum HNR in dB
    get_minimum = function(from_time = 0, to_time = 0, interpolation = "parabolic") {
      interpolation_code <- if (interpolation == "parabolic") 2 else 0
      .harmonicity_get_minimum(private$ptr, from_time, to_time, interpolation_code)
    },
    
    #' @description Get maximum HNR
    #' @param from_time Start time (0 = start of object)
    #' @param to_time End time (0 = end of object)
    #' @param interpolation Interpolation method: "parabolic" (recommended) or "none"
    #' @return Maximum HNR in dB
    get_maximum = function(from_time = 0, to_time = 0, interpolation = "parabolic") {
      interpolation_code <- if (interpolation == "parabolic") 2 else 0
      .harmonicity_get_maximum(private$ptr, from_time, to_time, interpolation_code)
    },
    
    #' @description Get standard deviation of HNR
    #' @param from_time Start time (0 = start of object)
    #' @param to_time End time (0 = end of object)
    #' @return Standard deviation of HNR in dB
    get_standard_deviation = function(from_time = 0, to_time = 0) {
      .harmonicity_get_standard_deviation(private$ptr, from_time, to_time)
    },
    
    #' @description Get time of minimum HNR
    #' @param from_time Start time (0 = start of object)
    #' @param to_time End time (0 = end of object)
    #' @param interpolation Interpolation method: "parabolic" (recommended) or "none"
    #' @return Time in seconds where HNR is minimum
    get_time_of_minimum = function(from_time = 0, to_time = 0, interpolation = "parabolic") {
      interpolation_code <- if (interpolation == "parabolic") 2 else 0
      .harmonicity_get_time_of_minimum(private$ptr, from_time, to_time, interpolation_code)
    },
    
    #' @description Get time of maximum HNR
    #' @param from_time Start time (0 = start of object)
    #' @param to_time End time (0 = end of object)
    #' @param interpolation Interpolation method: "parabolic" (recommended) or "none"
    #' @return Time in seconds where HNR is maximum
    get_time_of_maximum = function(from_time = 0, to_time = 0, interpolation = "parabolic") {
      interpolation_code <- if (interpolation == "parabolic") 2 else 0
      .harmonicity_get_time_of_maximum(private$ptr, from_time, to_time, interpolation_code)
    },
    
    #' @description Get number of analysis frames
    #' @return Integer number of frames
    get_number_of_frames = function() {
      .harmonicity_get_number_of_frames(private$ptr)
    },
    
    #' @description Get time step between frames
    #' @return Time step in seconds
    get_time_step = function() {
      .harmonicity_get_time_step(private$ptr)
    },
    
    #' @description Get start time
    #' @return Start time in seconds
    get_start_time = function() {
      .harmonicity_get_start_time(private$ptr)
    },
    
    #' @description Get end time
    #' @return End time in seconds
    get_end_time = function() {
      .harmonicity_get_end_time(private$ptr)
    },
    
    # ========================================================================
    # Export Methods
    # ========================================================================
    
    #' @description Export to data frame
    #' @return Data frame with columns: time, hnr_db
    as_data_frame = function() {
      mat <- .harmonicity_as_matrix(private$ptr)
      data.frame(
        time = mat[1, ],
        hnr_db = mat[2, ],
        stringsAsFactors = FALSE
      )
    },
    
    #' @description Export as matrix
    #' @return Matrix with 2 rows: time and HNR values
    as_matrix = function() {
      .harmonicity_as_matrix(private$ptr)
    },
    
    # ========================================================================
    # Print Method
    # ========================================================================
    
    #' @description Print summary of Harmonicity object
    print = function() {
      cat("Praat Harmonicity object\n")
      cat(sprintf("  Duration: %.4f s\n", self$get_end_time() - self$get_start_time()))
      cat(sprintf("  Time step: %.4f s\n", self$get_time_step()))
      cat(sprintf("  Number of frames: %d\n", self$get_number_of_frames()))
      cat(sprintf("  Mean HNR: %.2f dB\n", self$get_mean()))
      cat(sprintf("  Min HNR: %.2f dB\n", self$get_minimum()))
      cat(sprintf("  Max HNR: %.2f dB\n", self$get_maximum()))
      invisible(self)
    }
  )
)
