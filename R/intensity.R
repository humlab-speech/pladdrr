# intensity.R - Legacy S3 interface for intensity extraction (DEPRECATED)
#
#' Extract intensity from a sound object (DEPRECATED)
#'
#' **DEPRECATED:** Use \code{sound$to_intensity()} instead.
#'
#' @param sound A Sound R6 object
#' @param time_step Time step in seconds
#' @param minimum_pitch Minimum pitch in Hz
#' @param subtract_mean Subtract mean intensity
#' @return Intensity R6 object
#' @export
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate = 16000)
#' intensity <- extract_intensity(sound)
#' intensity$get_mean(from_time = 0, to_time = 0)
extract_intensity <- function(sound, time_step = 0.0, minimum_pitch = 100, subtract_mean = TRUE) {
  .Deprecated(
    "sound$to_intensity()",
    package = "pladdrr",
    msg = paste(
      "extract_intensity() is deprecated and will be removed in v5.0.0.",
      "Use sound$to_intensity(minimum_pitch, time_step, subtract_mean) instead."
    )
  )
  
  sound$to_intensity(minimum_pitch = minimum_pitch, time_step = time_step, subtract_mean = subtract_mean)
}

#' Get intensity at a specific time (DEPRECATED)
#'
#' **DEPRECATED:** Use \code{intensity$get_value_at_time(time)} instead.
#'
#' @param intensity An Intensity R6 object
#' @param time Time in seconds
#' @param interpolate Whether to interpolate
#' @return Intensity in dB
#' @export
get_intensity_at_time <- function(intensity, time, interpolate = FALSE) {
  .Deprecated("intensity$get_value_at_time()", package = "pladdrr")
  intensity$get_value_at_time(time)
}

#' Get mean intensity (DEPRECATED)
#'
#' **DEPRECATED:** Use \code{intensity$get_mean()} instead.
#'
#' @param intensity An Intensity R6 object
#' @param time_range Optional time range c(start, end)
#' @return Mean intensity in dB
#' @export
get_mean_intensity <- function(intensity, time_range = NULL) {
  .Deprecated("intensity$get_mean()", package = "pladdrr")
  
  from_time <- if (!is.null(time_range)) time_range[1] else 0.0
  to_time <- if (!is.null(time_range)) time_range[2] else 0.0
  
  intensity$get_mean(from_time, to_time)
}

#' Get minimum intensity (DEPRECATED)
#'
#' **DEPRECATED:** Use \code{intensity$get_minimum()} instead.
#'
#' @param intensity An Intensity R6 object
#' @param time_range Optional time range
#' @return Minimum intensity in dB
#' @export
get_min_intensity <- function(intensity, time_range = NULL) {
  .Deprecated("intensity$get_minimum()", package = "pladdrr")
  
  from_time <- if (!is.null(time_range)) time_range[1] else 0.0
  to_time <- if (!is.null(time_range)) time_range[2] else 0.0
  
  intensity$get_minimum(from_time, to_time, interpolation = "none")
}

#' Get maximum intensity (DEPRECATED)
#'
#' **DEPRECATED:** Use \code{intensity$get_maximum()} instead.
#'
#' @param intensity An Intensity R6 object
#' @param time_range Optional time range
#' @return Maximum intensity in dB
#' @export
get_max_intensity <- function(intensity, time_range = NULL) {
  .Deprecated("intensity$get_maximum()", package = "pladdrr")
  
  from_time <- if (!is.null(time_range)) time_range[1] else 0.0
  to_time <- if (!is.null(time_range)) time_range[2] else 0.0
  
  intensity$get_maximum(from_time, to_time, interpolation = "none")
}

#' Get standard deviation of intensity (DEPRECATED)
#'
#' **DEPRECATED:** Use \code{intensity$get_standard_deviation()} instead.
#'
#' @param intensity An Intensity R6 object
#' @param time_range Optional time range
#' @return Standard deviation in dB
#' @export
get_sd_intensity <- function(intensity, time_range = NULL) {
  .Deprecated("intensity$get_standard_deviation()", package = "pladdrr")
  
  from_time <- if (!is.null(time_range)) time_range[1] else 0.0
  to_time <- if (!is.null(time_range)) time_range[2] else 0.0
  
  intensity$get_standard_deviation(from_time, to_time)
}
