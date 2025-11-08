#' @title Pitch Class
#' @description
#' R6 class representing a Praat Pitch object. Holds a pointer to a C++
#' Praat Pitch object for efficient queries.
#'
#' @details
#' The Pitch class wraps Praat's Pitch object, providing fundamental
#' frequency (F0) measurements over time. Typically created via
#' `sound$to_pitch()` rather than directly.
#'
#' @examples
#' \dontrun{
#' # Create from Sound
#' sound <- Sound$new("audio.wav")
#' pitch <- sound$to_pitch(pitch_floor = 75, pitch_ceiling = 600)
#'
#' # Query values
#' mean_f0 <- pitch$get_mean()
#' f0_at_time <- pitch$get_value_at_time(0.5)
#'
#' # Export to data.frame
#' df <- pitch$as_data_frame()
#' }
#'
#' @export
Pitch <- R6::R6Class(
  "Pitch",
  inherit = PraatObject,
  
  public = list(
    #' @description
    #' Create a new Pitch object
    #' @param path Path to Pitch file, or NULL if from_pointer
    #' @param from_pointer Internal: External pointer from C++
    #' @return A new Pitch object
    initialize = function(path = NULL, from_pointer = NULL) {
      if (!is.null(from_pointer)) {
        # Internal use: wrapping existing C++ object
        super$initialize(from_pointer)
      } else if (!is.null(path)) {
        # Read from file
        if (!file.exists(path)) {
          stop("File not found: ", path)
        }
        ptr <- .pitch_read_from_file(path)
        super$initialize(ptr)
      } else {
        stop("Must provide either 'path' or 'from_pointer'")
      }
    },
    
    #' @description
    #' Get the number of frames in the pitch object
    #' @return integer Number of frames
    get_number_of_frames = function() {
      private$check_valid()
      .pitch_get_number_of_frames(private$ptr)
    },
    
    #' @description
    #' Get the time step between frames
    #' @return numeric Time step in seconds
    get_time_step = function() {
      private$check_valid()
      .pitch_get_time_step(private$ptr)
    },
    
    #' @description
    #' Get pitch value at a specific time
    #' @param time Time in seconds
    #' @param unit Unit for pitch ("Hertz" or "semitones re 100 Hz")
    #' @return numeric Pitch value (or NA if unvoiced)
    get_value_at_time = function(time, unit = "Hertz") {
      private$check_valid()
      
      if (!is.numeric(time)) {
        stop("time must be numeric")
      }
      if (!is.character(unit) || !unit %in% c("Hertz", "semitones re 100 Hz")) {
        stop("unit must be 'Hertz' or 'semitones re 100 Hz'")
      }
      
      .pitch_get_value_at_time(private$ptr, time, unit)
    },
    
    #' @description
    #' Get mean pitch over a time range
    #' @param from_time Start time (0 = start of object)
    #' @param to_time End time (0 = end of object)
    #' @param unit Unit for pitch ("Hertz" or "semitones re 100 Hz")
    #' @return numeric Mean pitch value
    get_mean = function(from_time = 0, to_time = 0, unit = "Hertz") {
      private$check_valid()
      
      if (!is.numeric(from_time) || !is.numeric(to_time)) {
        stop("from_time and to_time must be numeric")
      }
      if (!is.character(unit) || !unit %in% c("Hertz", "semitones re 100 Hz")) {
        stop("unit must be 'Hertz' or 'semitones re 100 Hz'")
      }
      
      .pitch_get_mean(private$ptr, from_time, to_time, unit)
    },
    
    #' @description
    #' Get minimum pitch over a time range
    #' @param from_time Start time (0 = start of object)
    #' @param to_time End time (0 = end of object)
    #' @param unit Unit for pitch ("Hertz" or "semitones re 100 Hz")
    #' @return numeric Minimum pitch value
    get_minimum = function(from_time = 0, to_time = 0, unit = "Hertz") {
      private$check_valid()
      
      if (!is.numeric(from_time) || !is.numeric(to_time)) {
        stop("from_time and to_time must be numeric")
      }
      if (!is.character(unit) || !unit %in% c("Hertz", "semitones re 100 Hz")) {
        stop("unit must be 'Hertz' or 'semitones re 100 Hz'")
      }
      
      .pitch_get_minimum(private$ptr, from_time, to_time, unit)
    },
    
    #' @description
    #' Get maximum pitch over a time range
    #' @param from_time Start time (0 = start of object)
    #' @param to_time End time (0 = end of object)
    #' @param unit Unit for pitch ("Hertz" or "semitones re 100 Hz")
    #' @return numeric Maximum pitch value
    get_maximum = function(from_time = 0, to_time = 0, unit = "Hertz") {
      private$check_valid()
      
      if (!is.numeric(from_time) || !is.numeric(to_time)) {
        stop("from_time and to_time must be numeric")
      }
      if (!is.character(unit) || !unit %in% c("Hertz", "semitones re 100 Hz")) {
        stop("unit must be 'Hertz' or 'semitones re 100 Hz'")
      }
      
      .pitch_get_maximum(private$ptr, from_time, to_time, unit)
    },
    
    #' @description
    #' Get quantile of pitch distribution
    #' @param quantile Quantile to compute (0-1)
    #' @param from_time Start time (0 = start of object)
    #' @param to_time End time (0 = end of object)
    #' @param unit Unit for pitch ("Hertz" or "semitones re 100 Hz")
    #' @return numeric Quantile value
    get_quantile = function(quantile, from_time = 0, to_time = 0, unit = "Hertz") {
      private$check_valid()
      
      if (!is.numeric(quantile) || quantile < 0 || quantile > 1) {
        stop("quantile must be between 0 and 1")
      }
      if (!is.numeric(from_time) || !is.numeric(to_time)) {
        stop("from_time and to_time must be numeric")
      }
      if (!is.character(unit) || !unit %in% c("Hertz", "semitones re 100 Hz")) {
        stop("unit must be 'Hertz' or 'semitones re 100 Hz'")
      }
      
      .pitch_get_quantile(private$ptr, quantile, from_time, to_time, unit)
    },
    
    #' @description
    #' Export pitch data to R data.frame
    #' @return data.frame with columns: time, frequency, strength
    as_data_frame = function() {
      private$check_valid()
      .pitch_as_data_frame(private$ptr)
    },
    
    #' @description
    #' Save pitch to file
    #' @param path Output file path
    #' @return invisible(self)
    save = function(path) {
      private$check_valid()
      
      if (!is.character(path) || length(path) != 1) {
        stop("path must be a single character string")
      }
      
      .pitch_save(private$ptr, path)
      invisible(self)
    },
    
    #' @description
    #' Print method for Pitch objects
    print = function() {
      cat("<Praat Pitch>\n")
      
      if (!self$is_valid()) {
        cat("  [Invalid or deleted object]\n")
        return(invisible(self))
      }
      
      tryCatch({
        cat(sprintf("  Number of frames: %d\n", self$get_number_of_frames()))
        cat(sprintf("  Time step: %.6f s\n", self$get_time_step()))
        
        mean_pitch <- self$get_mean()
        if (!is.na(mean_pitch)) {
          cat(sprintf("  Mean pitch: %.1f Hz\n", mean_pitch))
        }
      }, error = function(e) {
        cat("  [Error retrieving properties]\n")
      })
      
      invisible(self)
    }
  ),
  
  private = list(
    # Check if pointer is still valid before operations
    check_valid = function() {
      if (!self$is_valid()) {
        stop("Pitch object is invalid or has been deleted")
      }
    }
  )
)
