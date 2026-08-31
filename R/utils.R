# utils.R - Utility functions for parameter validation and helpers
#
# This file provides R-level validation functions and utilities that complement
# the C++ layer. These functions ensure type safety and provide user-friendly
# error messages.

# Raise a classed pladdrr_input_error (consistent with R/validators.R).
.stop_validate <- function(routine, name, message) {
  stop(pladdrr_error_cond("pladdrr_input_error", routine, name, message,
                          call = sys.call(-1L)))
}

# ==============================================================================
# Parameter Validation Functions
# ==============================================================================

#' Validate positive numeric parameter
#'
#' Ensures a numeric parameter is positive (> 0)
#'
#' @inheritParams pladdrr_shared_params x
#' @inheritParams pladdrr_shared_params name
#' @return The validated value (invisibly)
#' @keywords internal
#' @examples
#' pladdrr:::validate_positive(2.5)
#' @noRd
validate_positive <- function(x, name = deparse(substitute(x))) {
  if (!is.numeric(x) || length(x) != 1) {
    .stop_validate("validate_positive", name,
      sprintf("'%s' must be a single numeric value", name))
  }
  if (is.na(x)) {
    .stop_validate("validate_positive", name,
      sprintf("'%s' cannot be NA", name))
  }
  if (x <= 0) {
    .stop_validate("validate_positive", name,
      sprintf("'%s' must be positive, got: %g", name, x))
  }
  invisible(x)
}

#' Validate non-negative numeric parameter
#'
#' Ensures a numeric parameter is non-negative (>= 0)
#'
#' @inheritParams pladdrr_shared_params x
#' @inheritParams pladdrr_shared_params name
#' @return The validated value (invisibly)
#' @keywords internal
#' @examples
#' pladdrr:::validate_non_negative(0)
#' @noRd
validate_non_negative <- function(x, name = deparse(substitute(x))) {
  if (!is.numeric(x) || length(x) != 1) {
    .stop_validate("validate_non_negative", name,
      sprintf("'%s' must be a single numeric value", name))
  }
  if (is.na(x)) {
    .stop_validate("validate_non_negative", name,
      sprintf("'%s' cannot be NA", name))
  }
  if (x < 0) {
    .stop_validate("validate_non_negative", name,
      sprintf("'%s' must be non-negative, got: %g", name, x))
  }
  invisible(x)
}

#' Validate positive integer parameter
#'
#' Ensures an integer parameter is positive (> 0)
#'
#' @inheritParams pladdrr_shared_params x
#' @inheritParams pladdrr_shared_params name
#' @return The validated value (invisibly)
#' @keywords internal
#' @examples
#' pladdrr:::validate_positive_int(3)
#' @noRd
validate_positive_int <- function(x, name = deparse(substitute(x))) {
  if (!is.numeric(x) || length(x) != 1) {
    .stop_validate("validate_positive_int", name,
      sprintf("'%s' must be a single integer value", name))
  }
  if (is.na(x)) {
    .stop_validate("validate_positive_int", name,
      sprintf("'%s' cannot be NA", name))
  }
  if (x <= 0 || x != as.integer(x)) {
    .stop_validate("validate_positive_int", name,
      sprintf("'%s' must be a positive integer, got: %g", name, x))
  }
  invisible(as.integer(x))
}


# ==============================================================================
# Sound Object Validation
# ==============================================================================


# Validate a legacy praat_sound-shaped object (deprecated S3 path).
.is_valid_praat_sound_legacy <- function(x) {
  if (!inherits(x, "praat_sound")) return(FALSE)
  if (!is.list(x)) return(FALSE)
  required_fields <- c("values", "time", "sampling_rate", "n_samples",
                       "duration", "start_time", "end_time")
  if (!all(required_fields %in% names(x))) return(FALSE)
  numeric_fields <- c("values", "time", "sampling_rate", "duration")
  if (!all(vapply(x[numeric_fields], is.numeric, logical(1)))) return(FALSE)
  if (!is.numeric(x$n_samples) || length(x$n_samples) != 1) return(FALSE)
  TRUE
}

#' Check if object is a valid Sound (R6 or legacy S3)
#'
#' Validates that an object is a Sound R6 object or legacy praat_sound
#'
#' @inheritParams pladdrr_shared_params x
#' @return Logical indicating validity
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate =
#'  16000)
#' is_praat_sound(sound)
#' is_praat_sound(42)
#' @export
is_praat_sound <- function(x) {
  # Check for R6 Sound object first (preferred)
  if (inherits(x, "Sound")) {
    return(TRUE)
  }
  
  # Legacy S3 check (deprecated but still supported for now)
  .is_valid_praat_sound_legacy(x)
}

#' Validate praat_sound object
#'
#' Ensures an object is a valid praat_sound, throwing an error if not
#'
#' @param x Object to validate
#' @inheritParams pladdrr_shared_params name
#' @return The validated object (invisibly)
#' @keywords internal
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 0.2)
#' pladdrr:::validate_sound_object(sound)
#' @noRd
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
#' @inheritParams pladdrr_shared_params x
#' @return Logical indicating validity
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate =
#'  16000)
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

# ==============================================================================
# File Path Utilities
# ==============================================================================

# Message Utilities
# ==============================================================================


# ==============================================================================
# Formant Object Validation
# ==============================================================================

#' Check if object is a valid Formant (R6 or legacy S3)
#'
#' Validates that an object is a Formant R6 object or legacy praat_formant
#'
#' @inheritParams pladdrr_shared_params x
#' @return Logical indicating validity
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate =
#'  16000)
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
#' @inheritParams pladdrr_shared_params name
#' @return The validated object (invisibly)
#' @keywords internal
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 0.2, sampling_rate =
#'  16000)
#' formant <- sound$to_formant_burg()
#' pladdrr:::validate_formant_object(formant)
#' @noRd
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
#' @inheritParams pladdrr_shared_params x
#' @return Logical indicating validity
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate =
#'  16000)
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
