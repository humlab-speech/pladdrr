# Pitch R6 Class
# Fundamental frequency (F0) contour representation
# Mirrors Praat's Pitch object

#' Pitch Object
#'
#' An R6 class representing a Praat Pitch object (fundamental frequency contour).
#' 
#' @description
#' The Pitch class represents the fundamental frequency (F0) contour of a sound.
#' It provides methods for querying pitch values, statistics, and transformations.
#' 
#' @export
Pitch <- R6::R6Class("Pitch",
  inherit = PraatObject,
  
  public = list(
    
    #' @description
    #' Create a new Pitch object
    #' @param .xptr External pointer to C++ Pitch object (internal use)
    initialize = function(.xptr = NULL) {
      if (is.null(.xptr)) {
        stop("Pitch objects must be created from a Sound object using sound$to_pitch()")
      }
      private$ptr <- .xptr
    },
    
    # ========================================================================
    # Query methods - Time domain
    # ========================================================================
    
    #' @description
    #' Get the time corresponding to a frame number
    #' @param frame_number Frame index (1-based)
    #' @return Time in seconds
    get_time_from_frame = function(frame_number) {
      .pitch_get_time_from_frame(private$ptr, as.integer(frame_number))
    },
    
    #' @description
    #' Get the frame number corresponding to a time
    #' @param time Time in seconds
    #' @return Frame number (integer)
    get_frame_from_time = function(time) {
      .pitch_get_frame_from_time(private$ptr, as.numeric(time))
    },
    
    #' @description
    #' Get the total number of frames
    #' @return Number of frames
    get_number_of_frames = function() {
      .pitch_get_number_of_frames(private$ptr)
    },
    
    #' @description
    #' Get the time step between frames
    #' @return Time step in seconds
    get_time_step = function() {
      .pitch_get_time_step(private$ptr)
    },
    
    # ========================================================================
    # Query methods - Pitch values
    # ========================================================================
    
    #' @description
    #' Get pitch value at a specific time
    #' @param time Time in seconds
    #' @param unit Unit: "hertz" (default), "semitones", "mel", "erb"
    #' @param interpolate Interpolate between frames (default TRUE)
    #' @return Pitch value in specified unit, or NA if unvoiced
    get_value_at_time = function(time, unit = "hertz", interpolate = TRUE) {
      unit_code <- switch(tolower(unit),
        "hertz" = 0L,
        "hz" = 0L,
        "semitones" = 1L,
        "mel" = 2L,
        "erb" = 3L,
        stop("Unknown unit: ", unit)
      )
      .pitch_get_value_at_time(private$ptr, as.numeric(time), unit_code, as.logical(interpolate))
    },
    
    #' @description
    #' Get mean pitch over a time range
    #' @param from_time Start time (default: start of pitch)
    #' @param to_time End time (default: end of pitch)
    #' @param unit Unit: "hertz" (default), "semitones", "mel", "erb"
    #' @return Mean pitch value
    get_mean = function(from_time = 0, to_time = 0, unit = "hertz") {
      unit_code <- switch(tolower(unit),
        "hertz" = 0L,
        "hz" = 0L,
        "semitones" = 1L,
        "mel" = 2L,
        "erb" = 3L,
        stop("Unknown unit: ", unit)
      )
      .pitch_get_mean(private$ptr, as.numeric(from_time), as.numeric(to_time), unit_code)
    },
    
    #' @description
    #' Get standard deviation of pitch over a time range
    #' @param from_time Start time (default: start of pitch)
    #' @param to_time End time (default: end of pitch)
    #' @param unit Unit: "hertz" (default), "semitones", "mel", "erb"
    #' @return Standard deviation
    get_standard_deviation = function(from_time = 0, to_time = 0, unit = "hertz") {
      unit_code <- switch(tolower(unit),
        "hertz" = 0L,
        "hz" = 0L,
        "semitones" = 1L,
        "mel" = 2L,
        "erb" = 3L,
        stop("Unknown unit: ", unit)
      )
      .pitch_get_standard_deviation(private$ptr, as.numeric(from_time), as.numeric(to_time), unit_code)
    },
    
    #' @description
    #' Get quantile of pitch distribution
    #' @param quantile Quantile (0-1)
    #' @param from_time Start time (default: start of pitch)
    #' @param to_time End time (default: end of pitch)
    #' @param unit Unit: "hertz" (default), "semitones", "mel", "erb"
    #' @return Pitch value at quantile
    get_quantile = function(quantile, from_time = 0, to_time = 0, unit = "hertz") {
      unit_code <- switch(tolower(unit),
        "hertz" = 0L,
        "hz" = 0L,
        "semitones" = 1L,
        "mel" = 2L,
        "erb" = 3L,
        stop("Unknown unit: ", unit)
      )
      .pitch_get_quantile(private$ptr, as.numeric(from_time), as.numeric(to_time), 
                          as.numeric(quantile), unit_code)
    },
    
    #' @description
    #' Get minimum pitch value in time range
    #' @param from_time Start time (default: start of pitch)
    #' @param to_time End time (default: end of pitch)
    #' @param unit Unit: "hertz" (default), "semitones", "mel", "erb"
    #' @param interpolate Interpolate between frames (default TRUE)
    #' @return Minimum pitch value
    get_minimum = function(from_time = 0, to_time = 0, unit = "hertz", interpolate = TRUE) {
      unit_code <- switch(tolower(unit),
        "hertz" = 0L,
        "hz" = 0L,
        "semitones" = 1L,
        "mel" = 2L,
        "erb" = 3L,
        stop("Unknown unit: ", unit)
      )
      .pitch_get_minimum(private$ptr, as.numeric(from_time), as.numeric(to_time), 
                         unit_code, as.logical(interpolate))
    },
    
    #' @description
    #' Get maximum pitch value in time range
    #' @param from_time Start time (default: start of pitch)
    #' @param to_time End time (default: end of pitch)
    #' @param unit Unit: "hertz" (default), "semitones", "mel", "erb"
    #' @param interpolate Interpolate between frames (default TRUE)
    #' @return Maximum pitch value
    get_maximum = function(from_time = 0, to_time = 0, unit = "hertz", interpolate = TRUE) {
      unit_code <- switch(tolower(unit),
        "hertz" = 0L,
        "hz" = 0L,
        "semitones" = 1L,
        "mel" = 2L,
        "erb" = 3L,
        stop("Unknown unit: ", unit)
      )
      .pitch_get_maximum(private$ptr, as.numeric(from_time), as.numeric(to_time), 
                         unit_code, as.logical(interpolate))
    },
    
    #' @description
    #' Get time of minimum pitch value
    #' @param from_time Start time (default: start of pitch)
    #' @param to_time End time (default: end of pitch)
    #' @param unit Unit: "hertz" (default), "semitones", "mel", "erb"
    #' @param interpolate Interpolate between frames (default TRUE)
    #' @return Time in seconds
    get_time_of_minimum = function(from_time = 0, to_time = 0, unit = "hertz", interpolate = TRUE) {
      unit_code <- switch(tolower(unit),
        "hertz" = 0L,
        "hz" = 0L,
        "semitones" = 1L,
        "mel" = 2L,
        "erb" = 3L,
        stop("Unknown unit: ", unit)
      )
      .pitch_get_time_of_minimum(private$ptr, as.numeric(from_time), as.numeric(to_time), 
                                  unit_code, as.logical(interpolate))
    },
    
    #' @description
    #' Get time of maximum pitch value
    #' @param from_time Start time (default: start of pitch)
    #' @param to_time End time (default: end of pitch)
    #' @param unit Unit: "hertz" (default), "semitones", "mel", "erb"
    #' @param interpolate Interpolate between frames (default TRUE)
    #' @return Time in seconds
    get_time_of_maximum = function(from_time = 0, to_time = 0, unit = "hertz", interpolate = TRUE) {
      unit_code <- switch(tolower(unit),
        "hertz" = 0L,
        "hz" = 0L,
        "semitones" = 1L,
        "mel" = 2L,
        "erb" = 3L,
        stop("Unknown unit: ", unit)
      )
      .pitch_get_time_of_maximum(private$ptr, as.numeric(from_time), as.numeric(to_time), 
                                  unit_code, as.logical(interpolate))
    },
    
    #' @description
    #' Count the number of voiced frames
    #' @return Number of voiced frames
    count_voiced_frames = function() {
      .pitch_count_voiced_frames(private$ptr)
    },
    
    # ========================================================================
    # Export methods
    # ========================================================================
    
    #' @description
    #' Convert pitch contour to matrix
    #' @return Matrix with columns: time, frequency
    as_matrix = function() {
      .pitch_as_matrix(private$ptr)
    },
    
    #' @description
    #' Convert pitch contour to data frame
    #' @return Data frame with columns: time, frequency, voiced
    as_data_frame = function() {
      .pitch_as_data_frame(private$ptr)
    },
    
    #' @description
    #' Save pitch to file
    #' @param path Output file path
    save = function(path) {
      .pitch_save(private$ptr, as.character(path))
      invisible(self)
    },
    
    # ========================================================================
    # Print method
    # ========================================================================
    
    #' @description
    #' Print pitch object summary
    print = function() {
      cat("<Praat Pitch>\n")
      
      n_frames <- self$get_number_of_frames()
      time_step <- self$get_time_step()
      n_voiced <- self$count_voiced_frames()
      
      cat(sprintf("  Frames: %d\n", n_frames))
      cat(sprintf("  Time step: %.4f s\n", time_step))
      cat(sprintf("  Voiced frames: %d (%.1f%%)\n", 
                  n_voiced, 100 * n_voiced / n_frames))
      
      tryCatch({
        mean_f0 <- self$get_mean(unit = "hertz")
        if (!is.na(mean_f0) && mean_f0 > 0) {
          min_f0 <- self$get_minimum(unit = "hertz")
          max_f0 <- self$get_maximum(unit = "hertz")
          sd_f0 <- self$get_standard_deviation(unit = "hertz")
          
          cat(sprintf("  Mean F0: %.1f Hz\n", mean_f0))
          cat(sprintf("  Range: %.1f - %.1f Hz\n", min_f0, max_f0))
          cat(sprintf("  SD: %.1f Hz\n", sd_f0))
        }
      }, error = function(e) {})
      
      invisible(self)
    }
  ),
  
  private = list(
    ptr = NULL
  )
)
