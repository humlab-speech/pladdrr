#' @title Praat Intensity Object
#' @description
#' Praat Intensity object (sound power/loudness) with direct C++ module binding.
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
Intensity <- function(.xptr = NULL) {
  if (is.null(.xptr)) {
    stop("Intensity objects should be created from Sound objects using to_intensity()")
  }
  
  # Load module and create C++ object
  intensity_mod <- get_module("intensity_module")
  cpp_obj <- intensity_mod$RIntensity$new(.xptr)
  
  # Helper functions
  interpolation_code <- function(method) {
    switch(tolower(method),
      "nearest" = 0,
      "linear" = 1,
      "cubic" = 2,
      "sinc70" = 3,
      "sinc700" = 4,
      2  # default cubic
    )
  }
  
  averaging_code <- function(method) {
    switch(tolower(method),
      "energy" = 0,
      "sones" = 1,
      "db" = 2,
      0  # default energy
    )
  }
  
  # Create object with methods
  obj <- structure(list(
    .cpp = cpp_obj,
    .xptr = .xptr,  # Store raw pointer for legacy exports
    
    # Query methods
    get_value_at_time = function(time, interpolation = "cubic") {
      cpp_obj$get_value_at_time(time, interpolation_code(interpolation))
    },
    
    get_mean = function(from_time = 0, to_time = 0, averaging_method = "energy") {
      cpp_obj$get_mean(from_time, to_time, averaging_code(averaging_method))
    },
    
    get_minimum = function(from_time = 0, to_time = 0, interpolation = "parabolic") {
      interp_code <- switch(tolower(interpolation),
        "none" = 0,
        "parabolic" = 1,
        "cubic" = 2,
        "sinc70" = 3,
        "sinc700" = 4,
        1
      )
      cpp_obj$get_minimum(from_time, to_time, interp_code)
    },
    
    get_maximum = function(from_time = 0, to_time = 0, interpolation = "parabolic") {
      interp_code <- switch(tolower(interpolation),
        "none" = 0,
        "parabolic" = 1,
        "cubic" = 2,
        "sinc70" = 3,
        "sinc700" = 4,
        1
      )
      cpp_obj$get_maximum(from_time, to_time, interp_code)
    },
    
    get_standard_deviation = function(from_time = 0, to_time = 0) {
      cpp_obj$get_standard_deviation(from_time, to_time)
    },
    
    get_quantile = function(from_time = 0, to_time = 0, quantile = 0.5) {
      cpp_obj$get_quantile(from_time, to_time, quantile)
    },
    
    get_time_of_minimum = function(from_time = 0, to_time = 0, interpolation = "parabolic") {
      interp_code <- switch(tolower(interpolation),
        "none" = 0,
        "parabolic" = 1,
        "cubic" = 2,
        "sinc70" = 3,
        "sinc700" = 4,
        1
      )
      cpp_obj$get_time_of_minimum(from_time, to_time, interp_code)
    },
    
    get_time_of_maximum = function(from_time = 0, to_time = 0, interpolation = "parabolic") {
      interp_code <- switch(tolower(interpolation),
        "none" = 0,
        "parabolic" = 1,
        "cubic" = 2,
        "sinc70" = 3,
        "sinc700" = 4,
        1
      )
      cpp_obj$get_time_of_maximum(from_time, to_time, interp_code)
    },
    
    # Time domain methods
    get_time_from_frame = function(frame) {
      cpp_obj$get_time_from_frame(frame)
    },
    
    get_frame_from_time = function(time) {
      cpp_obj$get_frame_from_time(time)
    },
    
    get_number_of_frames = function() {
      cpp_obj$get_number_of_frames()
    },
    
    get_sampling_period = function() {
      cpp_obj$get_time_step()
    },
    
    get_start_time = function() {
      cpp_obj$get_xmin()
    },
    
    get_end_time = function() {
      cpp_obj$get_xmax()
    },
    
    get_xmin = function() {
      cpp_obj$get_xmin()
    },
    
    get_xmax = function() {
      cpp_obj$get_xmax()
    },
    
    # Transform methods
    down_to_intensity_tier = function() {
      tier_ptr <- cpp_obj$down_to_intensity_tier_ptr()
      IntensityTier(.xptr = tier_ptr)
    },
    
    # Direct vector access (faster than as_data_frame when you only need one column)
    get_times_vector = function() {
      cpp_obj$get_times_vector()
    },
    
    get_values_vector = function() {
      cpp_obj$get_values_vector()
    },
    
    get_statistics = function(from_time = 0, to_time = 0,
                              metrics = c("mean", "stdev", "min", "max", "median")) {
      cpp_obj$get_statistics(as.numeric(from_time), as.numeric(to_time),
                             as.character(metrics))
    },
    
    # Export methods
    as_data_frame = function() {
      df <- cpp_obj$as_data_frame()
      names(df) <- c("time", "intensity_db")
      df
    },
    
    as_matrix = function() {
      df <- cpp_obj$as_data_frame()
      rbind(
        time = df$time,
        intensity_db = df$intensity
      )
    },
    
    # Display
    print = function(...) {
      cat("<Praat Intensity>\n")
      cat(sprintf("  Duration: %.3f s\n", cpp_obj$get_duration()))
      cat(sprintf("  Number of frames: %d\n", cpp_obj$get_number_of_frames()))
      cat(sprintf("  Time step: %.4f s\n", cpp_obj$get_time_step()))
      cat(sprintf("  Mean intensity: %.2f dB\n", 
                  cpp_obj$get_mean(0, 0, 0)))  # energy averaging
      cat(sprintf("  Range: [%.2f, %.2f] dB\n", 
                  cpp_obj$get_minimum(0, 0, 1),  # parabolic
                  cpp_obj$get_maximum(0, 0, 1)))
      invisible(obj)
    }
    
  ), class = c("Intensity", "PraatObject"))
  
  obj
}

# S3 methods
#' @export
print.Intensity <- function(x, ...) {
  x$print(...)
}

#' @export
as.data.frame.Intensity <- function(x, ...) {
  x$as_data_frame()
}
