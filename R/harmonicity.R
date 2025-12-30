#' @title Praat Harmonicity Object
#' @description
#' Praat Harmonicity object with direct C++ module binding (Harmonics-to-Noise Ratio).
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
Harmonicity <- function(.xptr = NULL) {
  if (is.null(.xptr)) {
    stop("Harmonicity objects should be created from Sound objects using to_harmonicity_ac() or to_harmonicity_cc()")
  }
  
  # Load module
  harmonicity_mod <- get_module("harmonicity_module")
  cpp_obj <- harmonicity_mod$RHarmonicity$new(.xptr)
  
  # Helper
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
  
  peak_interpolation_code <- function(method) {
    switch(tolower(method),
      "none" = 0,
      "parabolic" = 1,
      "cubic" = 2,
      "sinc70" = 3,
      "sinc700" = 4,
      1  # default parabolic
    )
  }
  
  obj <- structure(list(
    .cpp = cpp_obj,
    
    # Query methods
    get_value_at_time = function(time, interpolation = "cubic") {
      cpp_obj$get_value_at_time(time, interpolation_code(interpolation))
    },
    
    get_mean = function(from_time = 0, to_time = 0) {
      cpp_obj$get_mean(from_time, to_time)
    },
    
    get_minimum = function(from_time = 0, to_time = 0, interpolation = "parabolic") {
      cpp_obj$get_minimum(from_time, to_time, peak_interpolation_code(interpolation))
    },
    
    get_maximum = function(from_time = 0, to_time = 0, interpolation = "parabolic") {
      cpp_obj$get_maximum(from_time, to_time, peak_interpolation_code(interpolation))
    },
    
    get_standard_deviation = function(from_time = 0, to_time = 0) {
      cpp_obj$get_standard_deviation(from_time, to_time)
    },
    
    get_time_of_minimum = function(from_time = 0, to_time = 0, interpolation = "parabolic") {
      cpp_obj$get_time_of_minimum(from_time, to_time, peak_interpolation_code(interpolation))
    },
    
    get_time_of_maximum = function(from_time = 0, to_time = 0, interpolation = "parabolic") {
      cpp_obj$get_time_of_maximum(from_time, to_time, peak_interpolation_code(interpolation))
    },
    
    # Time domain
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
    
    get_time_from_frame = function(frame) {
      cpp_obj$get_time_from_frame(frame)
    },
    
    get_frame_from_time = function(time) {
      cpp_obj$get_frame_from_time(time)
    },
    
    # Export
    as_data_frame = function() {
      df <- cpp_obj$as_data_frame()
      names(df) <- c("time", "hnr_db", "voiced")
      df
    },
    
    as_matrix = function() {
      mat <- cpp_obj$as_matrix()
      rbind(
        time = mat[, 1],
        hnr_db = mat[, 2]
      )
    },
    
    # Display
    print = function(...) {
      cat("<Praat Harmonicity>\n")
      cat(sprintf("  Duration: %.3f s\n", cpp_obj$get_duration()))
      cat(sprintf("  Number of frames: %d\n", cpp_obj$get_number_of_frames()))
      cat(sprintf("  Time step: %.4f s\n", cpp_obj$get_time_step()))
      cat(sprintf("  Mean HNR: %.2f dB\n", cpp_obj$get_mean(0, 0)))
      cat(sprintf("  Range: [%.2f, %.2f] dB\n",
                  cpp_obj$get_minimum(0, 0, 1),
                  cpp_obj$get_maximum(0, 0, 1)))
      invisible(obj)
    }
    
  ), class = c("Harmonicity", "PraatObject"))
  
  obj
}

# S3 methods
#' @export
print.Harmonicity <- function(x, ...) {
  x$print(...)
}

#' @export
as.data.frame.Harmonicity <- function(x, ...) {
  x$as_data_frame()
}
