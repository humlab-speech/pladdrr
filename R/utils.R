# utils.R - Utility functions for parameter validation and helpers
#
# This file provides R-level validation functions and utilities that complement
# the C++ layer. These functions ensure type safety and provide user-friendly
# error messages.

# ==============================================================================
# Parameter Validation Functions
# ==============================================================================

#' Validate positive numeric parameter
#'
#' Ensures a numeric parameter is positive (> 0)
#'
#' @param x Value to validate
#' @param name Parameter name for error messages
#' @return The validated value (invisibly)
#' @keywords internal
#' @examples
#' pladdrr:::validate_positive(2.5)
validate_positive <- function(x, name = deparse(substitute(x))) {
  if (!is.numeric(x) || length(x) != 1) {
    stop(sprintf("'%s' must be a single numeric value", name), call. = FALSE)
  }
  if (is.na(x)) {
    stop(sprintf("'%s' cannot be NA", name), call. = FALSE)
  }
  if (x <= 0) {
    stop(sprintf("'%s' must be positive, got: %g", name, x), call. = FALSE)
  }
  invisible(x)
}

#' Validate non-negative numeric parameter
#'
#' Ensures a numeric parameter is non-negative (>= 0)
#'
#' @param x Value to validate
#' @param name Parameter name for error messages
#' @return The validated value (invisibly)
#' @keywords internal
#' @examples
#' pladdrr:::validate_non_negative(0)
validate_non_negative <- function(x, name = deparse(substitute(x))) {
  if (!is.numeric(x) || length(x) != 1) {
    stop(sprintf("'%s' must be a single numeric value", name), call. = FALSE)
  }
  if (is.na(x)) {
    stop(sprintf("'%s' cannot be NA", name), call. = FALSE)
  }
  if (x < 0) {
    stop(sprintf("'%s' must be non-negative, got: %g", name, x), call. = FALSE)
  }
  invisible(x)
}

#' Validate numeric parameter is in range
#'
#' Ensures a numeric parameter falls within a specified range
#'
#' @param x Value to validate
#' @param min Minimum allowed value (inclusive)
#' @param max Maximum allowed value (inclusive)
#' @param name Parameter name for error messages
#' @return The validated value (invisibly)
#' @keywords internal
#' @examples
#' pladdrr:::validate_range(5, min = 0, max = 10)
validate_range <- function(x, min, max, name = deparse(substitute(x))) {
  if (!is.numeric(x) || length(x) != 1) {
    stop(sprintf("'%s' must be a single numeric value", name), call. = FALSE)
  }
  if (is.na(x)) {
    stop(sprintf("'%s' cannot be NA", name), call. = FALSE)
  }
  if (x < min || x > max) {
    stop(sprintf("'%s' must be in range [%g, %g], got: %g",
                 name, min, max, x), call. = FALSE)
  }
  invisible(x)
}

#' Validate positive integer parameter
#'
#' Ensures an integer parameter is positive (> 0)
#'
#' @param x Value to validate
#' @param name Parameter name for error messages
#' @return The validated value (invisibly)
#' @keywords internal
#' @examples
#' pladdrr:::validate_positive_int(3)
validate_positive_int <- function(x, name = deparse(substitute(x))) {
  if (!is.numeric(x) || length(x) != 1) {
    stop(sprintf("'%s' must be a single integer value", name), call. = FALSE)
  }
  if (is.na(x)) {
    stop(sprintf("'%s' cannot be NA", name), call. = FALSE)
  }
  if (x <= 0 || x != as.integer(x)) {
    stop(sprintf("'%s' must be a positive integer, got: %g", name, x),
         call. = FALSE)
  }
  invisible(as.integer(x))
}

#' Validate string parameter
#'
#' Ensures a parameter is a non-empty character string
#'
#' @param x Value to validate
#' @param name Parameter name for error messages
#' @param allow_na Allow NA values (default: FALSE)
#' @return The validated value (invisibly)
#' @keywords internal
#' @examples
#' pladdrr:::validate_string("hello")
validate_string <- function(x, name = deparse(substitute(x)),
                           allow_na = FALSE) {
  if (!is.character(x) || length(x) != 1) {
    stop(sprintf("'%s' must be a single character string", name),
         call. = FALSE)
  }
  if (is.na(x) && !allow_na) {
    stop(sprintf("'%s' cannot be NA", name), call. = FALSE)
  }
  if (!is.na(x) && nchar(x) == 0) {
    stop(sprintf("'%s' cannot be an empty string", name), call. = FALSE)
  }
  invisible(x)
}

#' Validate logical parameter
#'
#' Ensures a parameter is a logical value
#'
#' @param x Value to validate
#' @param name Parameter name for error messages
#' @return The validated value (invisibly)
#' @keywords internal
#' @examples
#' pladdrr:::validate_logical(TRUE)
validate_logical <- function(x, name = deparse(substitute(x))) {
  if (!is.logical(x) || length(x) != 1) {
    stop(sprintf("'%s' must be a single logical value (TRUE/FALSE)", name),
         call. = FALSE)
  }
  if (is.na(x)) {
    stop(sprintf("'%s' cannot be NA", name), call. = FALSE)
  }
  invisible(x)
}

# ==============================================================================
# Sound Object Validation
# ==============================================================================

#' Check if object is a valid Sound (R6 or legacy S3)
#'
#' Validates that an object is a Sound R6 object or legacy praat_sound
#'
#' @param x Object to check
#' @return Logical indicating validity
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate = 16000)
#' is_praat_sound(sound)
#' is_praat_sound(42)
#' @export
is_praat_sound <- function(x) {
  # Check for R6 Sound object first (preferred)
  if (inherits(x, "Sound")) {
    return(TRUE)
  }
  
  # Legacy S3 check (deprecated but still supported for now)
  if (!inherits(x, "praat_sound")) {
    return(FALSE)
  }
  if (!is.list(x)) {
    return(FALSE)
  }

  # Check required fields for legacy S3
  required_fields <- c("values", "time", "sampling_rate", "n_samples",
                      "duration", "start_time", "end_time")
  if (!all(required_fields %in% names(x))) {
    return(FALSE)
  }

  # Basic type checks
  if (!is.numeric(x$values) || !is.numeric(x$time)) {
    return(FALSE)
  }
  if (!is.numeric(x$sampling_rate) || !is.numeric(x$duration)) {
    return(FALSE)
  }
  if (!is.numeric(x$n_samples) || length(x$n_samples) != 1) {
    return(FALSE)
  }

  TRUE
}

#' Validate praat_sound object
#'
#' Ensures an object is a valid praat_sound, throwing an error if not
#'
#' @param x Object to validate
#' @param name Parameter name for error messages
#' @return The validated object (invisibly)
#' @keywords internal
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 0.2)
#' pladdrr:::validate_sound_object(sound)
validate_sound_object <- function(x, name = deparse(substitute(x))) {
  if (!is_praat_sound(x)) {
    stop(sprintf("'%s' must be a praat_sound object", name), call. = FALSE)
  }
  invisible(x)
}

# ==============================================================================
# Pitch Object Validation
# ==============================================================================

#' Check if object is a valid Pitch (R6 or legacy S3)
#'
#' Validates that an object is a Pitch R6 object or legacy praat_pitch
#'
#' @param x Object to check
#' @return Logical indicating validity
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
#' pitch <- sound$to_pitch()
#' is_praat_pitch(pitch)
#' is_praat_pitch(42)
#' @export
is_praat_pitch <- function(x) {
  # Check for R6 Pitch object first (preferred)
  if (inherits(x, "Pitch")) {
    return(TRUE)
  }
  
  # Legacy S3 check (deprecated but still supported for now)
  if (!inherits(x, "praat_pitch")) {
    return(FALSE)
  }
  if (!is.data.frame(x)) {
    return(FALSE)
  }

  # Check required columns
  required_cols <- c("time", "frequency")
  if (!all(required_cols %in% names(x))) {
    return(FALSE)
  }

  TRUE
}

#' Validate praat_pitch object
#'
#' Ensures an object is a valid praat_pitch, throwing an error if not
#'
#' @param x Object to validate
#' @param name Parameter name for error messages
#' @return The validated object (invisibly)
#' @keywords internal
#' @examples
#' pitch_df <- data.frame(time = c(0.1, 0.2), frequency = c(120, 130))
#' class(pitch_df) <- c("praat_pitch", "data.frame")
#' pladdrr:::validate_pitch_object(pitch_df)
validate_pitch_object <- function(x, name = deparse(substitute(x))) {
  if (!is_praat_pitch(x)) {
    stop(sprintf("'%s' must be a praat_pitch object", name), call. = FALSE)
  }
  invisible(x)
}

# ==============================================================================
# File Path Utilities
# ==============================================================================

#' Validate file path exists
#'
#' Ensures a file path points to an existing file
#'
#' @param path File path to validate
#' @param name Parameter name for error messages
#' @return The validated path (invisibly)
#' @keywords internal
#' @examples
#' path <- tempfile(fileext = ".wav")
#' file.create(path)
#' pladdrr:::validate_file_exists(path)
#' unlink(path)
validate_file_exists <- function(path, name = deparse(substitute(path))) {
  validate_string(path, name)
  if (!file.exists(path)) {
    stop(sprintf("File not found: %s", path), call. = FALSE)
  }
  if (!file.info(path)$isdir == FALSE) {
    stop(sprintf("Path is a directory, not a file: %s", path), call. = FALSE)
  }
  invisible(path)
}

#' Validate file has expected extension
#'
#' Ensures a file path has one of the expected extensions
#'
#' @param path File path to validate
#' @param extensions Character vector of allowed extensions (e.g., c("wav", "WAV"))
#' @param name Parameter name for error messages
#' @return The validated path (invisibly)
#' @keywords internal
#' @examples
#' pladdrr:::validate_file_extension("speech.wav", c("wav", "WAV"))
validate_file_extension <- function(path, extensions,
                                   name = deparse(substitute(path))) {
  validate_string(path, name)
  ext <- tools::file_ext(path)
  if (!ext %in% extensions) {
    stop(sprintf("'%s' must have one of these extensions: %s (got: %s)",
                 name, paste(extensions, collapse = ", "), ext),
         call. = FALSE)
  }
  invisible(path)
}

# ==============================================================================
# Message Utilities
# ==============================================================================

#' Issue a quality warning
#'
#' Issues a warning about potentially poor analysis quality
#' (Constitution Principle I: User should be warned about quality issues)
#'
#' @param message Warning message
#' @return The result of the underlying \code{warning()} call, invisibly;
#'   called for the side effect of issuing a warning.
#' @examples
#' withCallingHandlers(
#'   pladdrr:::quality_warning("example quality issue"),
#'   warning = function(w) {
#'     message("caught: ", conditionMessage(w))
#'     invokeRestart("muffleWarning")
#'   }
#' )
#' @keywords internal
quality_warning <- function(message) {
  warning(message, call. = FALSE, immediate. = TRUE)
}

#' Convert value to NA with warning
#'
#' Converts undefined analysis values to NA and issues a warning
#' (Per clarification: return NA for undefined values)
#'
#' @param message Reason for NA
#' @return NA_real_
#' @keywords internal
#' @examples
#' withCallingHandlers(
#'   pladdrr:::undefined_to_na("pitch could not be determined"),
#'   warning = function(w) invokeRestart("muffleWarning")
#' )
undefined_to_na <- function(message = NULL) {
  if (!is.null(message)) {
    quality_warning(paste("Undefined value:", message))
  }
  NA_real_
}

# ==============================================================================
# Formant Object Validation
# ==============================================================================

#' Check if object is a valid Formant (R6 or legacy S3)
#'
#' Validates that an object is a Formant R6 object or legacy praat_formant
#'
#' @param x Object to check
#' @return Logical indicating validity
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate = 16000)
#' formant <- sound$to_formant_burg()
#' is_praat_formant(formant)
#' is_praat_formant(42)
#' @export
is_praat_formant <- function(x) {
  # Check for R6 Formant object first (preferred)
  if (inherits(x, "Formant")) {
    return(TRUE)
  }
  
  # Legacy S3 check (deprecated but still supported for now)
  if (!inherits(x, "praat_formant")) {
    return(FALSE)
  }
  if (!is.list(x)) {
    return(FALSE)
  }
  
  # Check required fields
  required_fields <- c("values", "n_frames", "n_formants")
  if (!all(required_fields %in% names(x))) {
    return(FALSE)
  }
  
  # Check values is a data.frame with required columns
  if (!is.data.frame(x$values)) {
    return(FALSE)
  }
  
  required_cols <- c("time", "formant_number", "frequency", "bandwidth")
  if (!all(required_cols %in% names(x$values))) {
    return(FALSE)
  }
  
  TRUE
}

#' Validate praat_formant object
#'
#' Ensures an object is a valid praat_formant, throwing an error if not
#'
#' @param x Object to validate
#' @param name Parameter name for error messages
#' @return The validated object (invisibly)
#' @keywords internal
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 0.2, sampling_rate = 16000)
#' formant <- sound$to_formant_burg()
#' pladdrr:::validate_formant_object(formant)
validate_formant_object <- function(x, name = deparse(substitute(x))) {
  if (!is_praat_formant(x)) {
    stop(sprintf("'%s' must be a praat_formant object", name), call. = FALSE)
  }
  invisible(x)
}

# ==============================================================================
# Intensity Object Validation
# ==============================================================================

#' Check if object is a valid Intensity (R6 or legacy S3)
#'
#' Validates that an object is an Intensity R6 object or legacy praat_intensity
#'
#' @param x Object to check
#' @return Logical indicating validity
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate = 16000)
#' intensity <- sound$to_intensity()
#' is_praat_intensity(intensity)
#' is_praat_intensity(42)
#' @export
is_praat_intensity <- function(x) {
  # Check for R6 Intensity object first (preferred)
  if (inherits(x, "Intensity")) {
    return(TRUE)
  }
  
  # Legacy S3 check (deprecated but still supported for now)
  if (!inherits(x, "praat_intensity")) {
    return(FALSE)
  }
  if (!is.list(x)) {
    return(FALSE)
  }
  
  # Check required fields
  required_fields <- c("values", "n_frames")
  if (!all(required_fields %in% names(x))) {
    return(FALSE)
  }
  
  # Check values is a data.frame with required columns
  if (!is.data.frame(x$values)) {
    return(FALSE)
  }
  
  required_cols <- c("time", "intensity_db")
  if (!all(required_cols %in% names(x$values))) {
    return(FALSE)
  }
  
  TRUE
}

#' Validate praat_intensity object
#'
#' Ensures an object is a valid praat_intensity, throwing an error if not
#'
#' @param x Object to validate
#' @param name Parameter name for error messages
#' @return The validated object (invisibly)
#' @keywords internal
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 0.2)
#' intensity <- sound$to_intensity()
#' pladdrr:::validate_intensity_object(intensity)
validate_intensity_object <- function(x, name = deparse(substitute(x))) {
  if (!is_praat_intensity(x)) {
    stop(sprintf("'%s' must be a praat_intensity object", name), call. = FALSE)
  }
  invisible(x)
}

# ==============================================================================
# Shared Praat interpolation-method code lookups
# ==============================================================================
# Praat's curve-interpolation and peak-picking methods share the same integer
# codes everywhere they're used (Sound, Harmonicity, Intensity, Ltas); these
# were previously copy-pasted per wrapper file with an inconsistent default.

.praat_interpolation_code <- function(method, default = 2L) {
  switch(tolower(method),
    "nearest" = 0L, "linear" = 1L, "cubic" = 2L,
    "sinc70" = 3L, "sinc700" = 4L, as.integer(default))
}

.praat_peak_interpolation_code <- function(method, default = 1L) {
  switch(tolower(method),
    "none" = 0L, "parabolic" = 1L, "cubic" = 2L,
    "sinc70" = 3L, "sinc700" = 4L, as.integer(default))
}
