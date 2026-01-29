# pitch.R - Legacy S3 interface for pitch extraction (DEPRECATED)
#
# All S3 functions have been replaced by the R6 Pitch class.
# Use sound$to_pitch() and Pitch methods instead.

#' Extract pitch contour from sound (DEPRECATED)
#'
#' **DEPRECATED:** This S3 function is deprecated. Use the R6 interface instead:
#' \code{sound$to_pitch(time_step, pitch_floor, pitch_ceiling)}
#'
#' @param sound A Sound R6 object
#' @param pitch_floor Minimum pitch in Hz (default: 75)
#' @param pitch_ceiling Maximum pitch in Hz (default: 600)
#' @param time_step Time step in seconds (default: 0.01)
#'
#' @return Pitch R6 object
#'
#' @examples
#' \dontrun{
#' # Old S3 approach (DEPRECATED)
#' sound <- read_sound("speech.wav")
#' pitch <- extract_pitch(sound, pitch_floor = 75, pitch_ceiling = 300)
#'
#' # New R6 approach (RECOMMENDED)
#' sound <- Sound$new("speech.wav")
#' pitch <- sound$to_pitch(pitch_floor = 75, pitch_ceiling = 300)
#' mean_f0 <- pitch$get_mean()
#' }
#'
#' @export
extract_pitch <- function(sound, pitch_floor = 75, pitch_ceiling = 600, time_step = 0.01) {
  .Deprecated(
    "sound$to_pitch()",
    package = "pladdrr",
    msg = paste(
      "extract_pitch() is deprecated and will be removed in v5.0.0.",
      "Use sound$to_pitch(time_step, pitch_floor, pitch_ceiling) instead."
    )
  )
  
  sound$to_pitch(time_step = time_step, pitch_floor = pitch_floor, pitch_ceiling = pitch_ceiling)
}

#' Get pitch at specific time point (DEPRECATED)
#'
#' **DEPRECATED:** Use \code{pitch$get_value_at_time(time, unit)} instead.
#'
#' @param pitch A Pitch R6 object
#' @param time Time in seconds
#' @param unit Unit: "Hz" or "semitones"
#' @param interpolate Whether to interpolate
#' @return Pitch value or NA
#' @export
get_pitch_at_time <- function(pitch, time, unit = "Hz", interpolate = FALSE) {
  .Deprecated("pitch$get_value_at_time()", package = "pladdrr")
  
  # R6 uses lowercase "hertz" not "Hz"
  r6_unit <- if (tolower(unit) == "hz") "hertz" else tolower(unit)
  pitch$get_value_at_time(time, r6_unit)
}

#' Get mean pitch (DEPRECATED)
#'
#' **DEPRECATED:** Use \code{pitch$get_mean(unit)} instead.
#'
#' @param pitch A Pitch R6 object
#' @param unit Unit: "Hz" or "semitones"
#' @param time_range Optional time range c(start, end)
#' @return Mean pitch value
#' @export
get_mean_pitch <- function(pitch, unit = "Hz", time_range = NULL) {
  .Deprecated("pitch$get_mean()", package = "pladdrr")
  
  from_time <- if (!is.null(time_range)) time_range[1] else 0.0
  to_time <- if (!is.null(time_range)) time_range[2] else 0.0
  r6_unit <- if (tolower(unit) == "hz") "hertz" else tolower(unit)
  
  pitch$get_mean(from_time, to_time, r6_unit)
}

#' Get minimum pitch (DEPRECATED)
#'
#' **DEPRECATED:** Use \code{pitch$get_minimum(unit)} instead.
#'
#' @param pitch A Pitch R6 object
#' @param unit Unit: "Hz" or "semitones"
#' @param time_range Optional time range
#' @return Minimum pitch value
#' @export
get_min_pitch <- function(pitch, unit = "Hz", time_range = NULL) {
  .Deprecated("pitch$get_minimum()", package = "pladdrr")
  
  from_time <- if (!is.null(time_range)) time_range[1] else 0.0
  to_time <- if (!is.null(time_range)) time_range[2] else 0.0
  r6_unit <- if (tolower(unit) == "hz") "hertz" else tolower(unit)
  
  pitch$get_minimum(from_time, to_time, r6_unit, interpolation = "none")
}

#' Get maximum pitch (DEPRECATED)
#'
#' **DEPRECATED:** Use \code{pitch$get_maximum(unit)} instead.
#'
#' @param pitch A Pitch R6 object
#' @param unit Unit: "Hz" or "semitones"
#' @param time_range Optional time range
#' @return Maximum pitch value
#' @export
get_max_pitch <- function(pitch, unit = "Hz", time_range = NULL) {
  .Deprecated("pitch$get_maximum()", package = "pladdrr")
  
  from_time <- if (!is.null(time_range)) time_range[1] else 0.0
  to_time <- if (!is.null(time_range)) time_range[2] else 0.0
  r6_unit <- if (tolower(unit) == "hz") "hertz" else tolower(unit)
  
  pitch$get_maximum(from_time, to_time, r6_unit, interpolation = "none")
}
