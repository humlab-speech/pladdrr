#' @title Praat Intensity Object
#' @description
#' R6 class representing a Praat Intensity object (sound power/loudness).
#' Wraps a Praat C++ Intensity object with automatic memory management.
#'
#' @details
#' An Intensity object represents the sound power or loudness in a sound over time,
#' measured in decibels (dB) relative to the auditory threshold. Higher values
#' indicate louder sounds.
#'
#' ## Creating Intensity Objects
#'
#' Intensity objects are typically created from Sound objects:
#' - `sound$to_intensity(...)` - Extract intensity contour
#'
#' ## Querying
#'
#' Query methods return intensity values:
#' - `$get_value_at_time(time)` - Intensity at specific time
#' - `$get_mean(from, to)` - Mean intensity
#' - `$get_minimum(from, to)` - Minimum intensity
#' - `$get_maximum(from, to)` - Maximum intensity
#' - `$get_standard_deviation(from, to)` - SD of intensity
#' - `$get_quantile(from, to, quantile)` - Quantile of intensity
#' - `$get_time_of_minimum(from, to)` - When intensity is lowest
#' - `$get_time_of_maximum(from, to)` - When intensity is highest
#'
#' ## Time Domain
#'
#' Time domain methods for navigating frames:
#' - `$get_time_from_frame(frame)` - Time of frame
#' - `$get_frame_from_time(time)` - Nearest frame to time
#' - `$get_number_of_frames()` - Total frames
#' - `$get_sampling_period()` - Time between frames
#' - `$get_start_time()` - First frame time
#' - `$get_end_time()` - Last frame time
#'
#' ## Export
#'
#' Export methods convert to R data structures:
#' - `$as_data_frame()` - Data frame with time and intensity columns
#' - `$as_matrix()` - Matrix with 2 rows: time and intensity
#'
#' @section Praat Equivalent:
#' This class wraps Praat's Intensity object, created via:
#' - "To Intensity..." menu command
#'
#' @examples
#' \dontrun{
#' # From Sound object
#' sound <- Sound$new("recording.wav")
#' intensity <- sound$to_intensity(minimum_pitch = 100, time_step = 0.0)
#'
#' # Query values
#' mean_int <- intensity$get_mean()
#' int_at_1s <- intensity$get_value_at_time(1.0)
#' max_int <- intensity$get_maximum()
#'
#' # Export to R
#' df <- intensity$as_data_frame()
#' plot(df$time, df$intensity_db, type = "l", 
#'      xlab = "Time (s)", ylab = "Intensity (dB)")
#' }
#'
#' @export
Intensity <- R6::R6Class(
  "Intensity",
  inherit = PraatObject,
  
  public = list(
    
    #' @description
    #' Create an Intensity object (internal use - use Sound$to_intensity() instead)
    #' @param .xptr External pointer to C++ Intensity object
    #' @return A new Intensity object
    initialize = function(.xptr) {
      if (is.null(.xptr)) {
        stop("Intensity objects should be created from Sound objects using to_intensity()")
      }
      super$initialize(.xptr)
    },
    
    # ========================================================================
    # Query Methods
    # ========================================================================
    
    #' @description Get intensity value at specific time
    #' @param time Time in seconds
    #' @param interpolation Interpolation method: "nearest", "linear", "cubic", "sinc70", "sinc700"
    #' @return Intensity in dB (or NA if undefined)
    get_value_at_time = function(time, interpolation = "cubic") {
      interpolation_code <- switch(interpolation,
        "nearest" = 0,
        "linear" = 1,
        "cubic" = 2,
        "sinc70" = 3,
        "sinc700" = 4,
        2  # default to cubic
      )
      .intensity_get_value_at_time(private$ptr, time, interpolation_code)
    },
    
    #' @description Get mean intensity
    #' @param from_time Start time (0 = start of object)
    #' @param to_time End time (0 = end of object)
    #' @return Mean intensity in dB
    get_mean = function(from_time = 0, to_time = 0) {
      .intensity_get_mean(private$ptr, from_time, to_time)
    },
    
    #' @description Get minimum intensity
    #' @param from_time Start time (0 = start of object)
    #' @param to_time End time (0 = end of object)
    #' @return Minimum intensity in dB
    get_minimum = function(from_time = 0, to_time = 0) {
      .intensity_get_minimum(private$ptr, from_time, to_time)
    },
    
    #' @description Get maximum intensity
    #' @param from_time Start time (0 = start of object)
    #' @param to_time End time (0 = end of object)
    #' @return Maximum intensity in dB
    get_maximum = function(from_time = 0, to_time = 0) {
      .intensity_get_maximum(private$ptr, from_time, to_time)
    },
    
    #' @description Get standard deviation of intensity
    #' @param from_time Start time (0 = start of object)
    #' @param to_time End time (0 = end of object)
    #' @return Standard deviation of intensity in dB
    get_standard_deviation = function(from_time = 0, to_time = 0) {
      .intensity_get_standard_deviation(private$ptr, from_time, to_time)
    },
    
    #' @description Get quantile of intensity
    #' @param from_time Start time (0 = start of object)
    #' @param to_time End time (0 = end of object)
    #' @param quantile Quantile (0-1, where 0.5 is median)
    #' @return Intensity quantile in dB
    get_quantile = function(from_time = 0, to_time = 0, quantile = 0.5) {
      .intensity_get_quantile(private$ptr, from_time, to_time, quantile)
    },
    
    #' @description Get time of minimum intensity
    #' @param from_time Start time (0 = start of object)
    #' @param to_time End time (0 = end of object)
    #' @return Time in seconds when intensity is minimum
    get_time_of_minimum = function(from_time = 0, to_time = 0) {
      .intensity_get_time_of_minimum(private$ptr, from_time, to_time)
    },
    
    #' @description Get time of maximum intensity
    #' @param from_time Start time (0 = start of object)
    #' @param to_time End time (0 = end of object)
    #' @return Time in seconds when intensity is maximum
    get_time_of_maximum = function(from_time = 0, to_time = 0) {
      .intensity_get_time_of_maximum(private$ptr, from_time, to_time)
    },
    
    # ========================================================================
    # Time Domain Methods
    # ========================================================================
    
    #' @description Get time from frame number
    #' @param frame Frame number (1-based)
    #' @return Time in seconds
    get_time_from_frame = function(frame) {
      .intensity_get_time_from_frame(private$ptr, frame)
    },
    
    #' @description Get frame number from time
    #' @param time Time in seconds
    #' @return Frame number (1-based, rounded)
    get_frame_from_time = function(time) {
      .intensity_get_frame_from_time(private$ptr, time)
    },
    
    #' @description Get number of frames
    #' @return Number of frames
    get_number_of_frames = function() {
      .intensity_get_number_of_frames(private$ptr)
    },
    
    #' @description Get sampling period (time step)
    #' @return Time step in seconds
    get_sampling_period = function() {
      .intensity_get_sampling_period(private$ptr)
    },
    
    #' @description Get start time
    #' @return Start time in seconds
    get_start_time = function() {
      .intensity_get_start_time(private$ptr)
    },
    
    #' @description Get end time
    #' @return End time in seconds
    get_end_time = function() {
      .intensity_get_end_time(private$ptr)
    },
    
    # ========================================================================
    # Export Methods
    # ========================================================================
    
    #' @description Convert to data frame
    #' @return Data frame with columns: time, intensity_db
    as_data_frame = function() {
      n_frames <- self$get_number_of_frames()
      
      if (n_frames == 0) {
        return(data.frame(time = numeric(0), intensity_db = numeric(0)))
      }
      
      times <- numeric(n_frames)
      intensities <- numeric(n_frames)
      
      for (i in 1:n_frames) {
        times[i] <- self$get_time_from_frame(i)
        intensities[i] <- self$get_value_at_time(times[i], "nearest")
      }
      
      data.frame(
        time = times,
        intensity_db = intensities,
        stringsAsFactors = FALSE
      )
    },
    
    #' @description Convert to matrix
    #' @return Matrix with 2 rows: time and intensity_db
    as_matrix = function() {
      df <- self$as_data_frame()
      rbind(
        time = df$time,
        intensity_db = df$intensity_db
      )
    },
    
    # ========================================================================
    # Display Methods
    # ========================================================================
    
    #' @description Print method
    #' @param ... Additional arguments (ignored)
    print = function(...) {
      cat("<Praat Intensity>\n")
      cat(sprintf("  Duration: %.3f s\n", self$get_end_time() - self$get_start_time()))
      cat(sprintf("  Number of frames: %d\n", self$get_number_of_frames()))
      cat(sprintf("  Time step: %.4f s\n", self$get_sampling_period()))
      cat(sprintf("  Mean intensity: %.2f dB\n", self$get_mean()))
      cat(sprintf("  Range: [%.2f, %.2f] dB\n", self$get_minimum(), self$get_maximum()))
      invisible(self)
    }
  ),
  
  private = list(
    finalize = function() {
      # XPtr finalizer handles C++ object cleanup
      private$ptr <- NULL
    }
  )
)
