# Pitch Module R Interface
# Part of pladdrr 2.0 - Rcpp Modules architecture
#
# This file provides the R-level interface to the Pitch module.
# It wraps the RPitch C++ class exposed via Rcpp Modules.

# Environment to hold module references
.pitch_module_env <- new.env(parent = emptyenv())

#' @keywords internal
#' @noRd
.load_pitch_module <- function() {
  if (is.null(.pitch_module_env$module)) {
    .pitch_module_env$module <- Rcpp::Module("pitch_module", PACKAGE = "pladdrr")
  }
  .pitch_module_env$module
}

#' Get Pitch Module Reference
#'
#' @return The loaded pitch module
#' @keywords internal
#' @examples
#' mod <- pladdrr:::get_pitch_module()
#' @noRd
get_pitch_module <- function() {
  .load_pitch_module()
}

# ============================================================================
# Unit Code Conversion Helper
# ============================================================================

#' Convert unit string to integer code
#' @param unit Unit string: "hertz", "hz", "semitones", "mel", "erb"
#' @return Integer unit code for Praat API
#' @examples
#' pladdrr:::pitch_unit_code("hertz")
#' pladdrr:::pitch_unit_code("semitones")
#' @keywords internal
#' @noRd
pitch_unit_code <- function(unit) {
  switch(tolower(unit),
    "hertz" = 0L,
    "hz" = 0L,
    "semitones" = 1L,
    "mel" = 2L,
    "erb" = 3L,
    stop("Unknown unit: ", unit)
  )
}

# ============================================================================
# PitchModule Class (New API)
# ============================================================================

#' Create a Pitch Object from Module
#'
#' @description
#' Creates a Pitch object using the new Rcpp Modules architecture.
#' This is the constructor function for Pitch objects in pladdrr 2.0.
#'
#' @param .ptr External pointer to a Praat Pitch object (internal use)
#' @return A Pitch object (reference class from Rcpp Module)
#'
#' @details
#' Pitch objects are typically created via `Sound$to_pitch()` rather than
#' directly. The returned object provides methods for querying pitch values,
#' statistics, and conversions.
#'
#' @section Methods:
#' \describe{
#'   \item{`get_value_at_time(time, unit, interpolate)`}{Get pitch at time}
#'   \item{`get_mean(from_time, to_time, unit)`}{Get mean pitch}
#'   \item{`get_standard_deviation(from_time, to_time, unit)`}{Get pitch SD}
#'   \item{`get_minimum(from_time, to_time, unit, interpolate)`}{Get min pitch}
#'   \item{`get_maximum(from_time, to_time, unit, interpolate)`}{Get max pitch}
#'   \item{`count_voiced_frames()`}{Count voiced frames}
#'   \item{`as_data_frame(include_strength, include_intensity)`}{Convert to data.frame}
#' }
#'
#' @section Properties:
#' \describe{
#'   \item{`duration`}{Duration in seconds}
#'   \item{`nx`}{Number of frames}
#'   \item{`dx`}{Time step between frames}
#'   \item{`xmin`, `xmax`}{Start and end times}
#'   \item{`ceiling`}{Pitch ceiling (Hz)}
#' }
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 0.5)
#' pitch <- sound$to_pitch()
#'
#' # Properties
#' pitch$duration
#' pitch$nx
#'
#' # Query methods
#' pitch$get_mean(0, 0, "hertz")  # Mean F0 in Hz
#' pitch$count_voiced_frames()
#'
#' # Export
#' df <- pitch$as_data_frame(FALSE, FALSE)
#'
#' @export
PitchModule <- function(.ptr = NULL) {
  if (is.null(.ptr)) {
    stop("Pitch objects must be created from Sound$to_pitch()")
  }

  mod <- get_pitch_module()
  obj <- mod$RPitch$new(.ptr)

  # Add convenience wrapper methods with unit conversion
  # These provide the user-friendly API matching the R6 version

  # Store the module object
  env <- new.env(parent = emptyenv())
  env$.mod <- obj

  # Create wrapper class
  structure(env, class = c("PitchModule", "PraatObjectModule"))
}

# ============================================================================
# S3 Methods for PitchModule
# ============================================================================

#' @export
print.PitchModule <- function(x, ...) {
  obj <- x[[".mod"]]
  cat("<Praat Pitch (Module)>\n")

  if (obj$is_valid()) {
    n_frames <- obj$nx
    time_step <- obj$dx
    n_voiced <- obj$count_voiced_frames()

    cat(sprintf("  Duration: %.3f s\n", obj$duration))
    cat(sprintf("  Frames: %d\n", n_frames))
    cat(sprintf("  Time step: %.4f s\n", time_step))
    cat(sprintf("  Voiced frames: %d (%.1f%%)\n",
                n_voiced, 100 * n_voiced / n_frames))

    tryCatch({
      mean_f0 <- obj$get_mean(0, 0, 0L)  # 0 = Hertz
      if (!is.na(mean_f0) && mean_f0 > 0) {
        min_f0 <- obj$get_minimum(0, 0, 0L, TRUE)
        max_f0 <- obj$get_maximum(0, 0, 0L, TRUE)
        sd_f0 <- obj$get_standard_deviation(0, 0, 0L)

        cat(sprintf("  Mean F0: %.1f Hz\n", mean_f0))
        cat(sprintf("  Range: %.1f - %.1f Hz\n", min_f0, max_f0))
        cat(sprintf("  SD: %.1f Hz\n", sd_f0))
      }
    }, error = function(e) {})
  } else {
    cat("  [Invalid object]\n")
  }

  invisible(x)
}

#' @export
as.data.frame.PitchModule <- function(x, row.names = NULL, optional = FALSE,
                                       include_strength = FALSE,
                                       include_intensity = FALSE, ...) {
  x[[".mod"]]$as_data_frame(include_strength, include_intensity)
}

.pitch_module_methods <- list(
  get_value_at_time = function(obj) function(time, unit = "hertz", interpolate = TRUE) {
      obj$get_value_at_time(as.numeric(time), pitch_unit_code(unit), as.logical(interpolate))
    },
  get_mean = function(obj) function(from_time = 0, to_time = 0, unit = "hertz") {
      obj$get_mean(as.numeric(from_time), as.numeric(to_time), pitch_unit_code(unit))
    },
  get_standard_deviation = function(obj) function(from_time = 0, to_time = 0, unit = "hertz") {
      obj$get_standard_deviation(as.numeric(from_time), as.numeric(to_time), pitch_unit_code(unit))
    },
  get_quantile = function(obj) function(from_time = 0, to_time = 0, quantile = 0.5, unit = "hertz") {
      obj$get_quantile(as.numeric(from_time), as.numeric(to_time),
                       as.numeric(quantile), pitch_unit_code(unit))
    },
  get_minimum = function(obj) function(from_time = 0, to_time = 0, unit = "hertz", interpolate = TRUE) {
      obj$get_minimum(as.numeric(from_time), as.numeric(to_time),
                      pitch_unit_code(unit), as.logical(interpolate))
    },
  get_maximum = function(obj) function(from_time = 0, to_time = 0, unit = "hertz", interpolate = TRUE) {
      obj$get_maximum(as.numeric(from_time), as.numeric(to_time),
                      pitch_unit_code(unit), as.logical(interpolate))
    },
  get_time_of_minimum = function(obj) function(from_time = 0, to_time = 0, unit = "hertz", interpolate = TRUE) {
      obj$get_time_of_minimum(as.numeric(from_time), as.numeric(to_time),
                               pitch_unit_code(unit), as.logical(interpolate))
    },
  get_time_of_maximum = function(obj) function(from_time = 0, to_time = 0, unit = "hertz", interpolate = TRUE) {
      obj$get_time_of_maximum(as.numeric(from_time), as.numeric(to_time),
                               pitch_unit_code(unit), as.logical(interpolate))
    },
  get_strength_at_time = function(obj) function(time, unit = "hertz", interpolate = TRUE) {
      obj$get_strength_at_time(as.numeric(time), pitch_unit_code(unit), as.logical(interpolate))
    },
  get_mean_strength = function(obj) function(from_time = 0, to_time = 0, unit = "hertz") {
      obj$get_mean_strength(as.numeric(from_time), as.numeric(to_time), pitch_unit_code(unit))
    },
  as_data_frame = function(obj) function(include_strength = FALSE, include_intensity = FALSE) {
      obj$as_data_frame(as.logical(include_strength), as.logical(include_intensity))
    },
  to_point_process = function(obj) function() {
      pp_ptr <- obj$to_point_process_ptr()
      PointProcess(.xptr = pp_ptr)
    },
  down_to_pitch_tier = function(obj) function() {
      tier_ptr <- obj$down_to_pitch_tier_ptr()
      PitchTier(.xptr = tier_ptr)
    },
  to_textgrid_vuv = function(obj) function() {
      tg_ptr <- obj$to_textgrid_vuv_ptr()
      TextGrid(.xptr = tg_ptr)
    },
  to_textgrid_silences = function(obj) function(min_silent_duration = 0.1, min_sounding_duration = 0.1) {
      tg_ptr <- obj$to_textgrid_silences_ptr(min_silent_duration, min_sounding_duration)
      TextGrid(.xptr = tg_ptr)
    }
)

#' @method $ PitchModule
#' @export
`$.PitchModule` <- function(x, name) {
  # First check for direct module properties/methods.
  # Must use [[ (not $) to fetch .mod: $ on a PitchModule dispatches back
  # into this method, causing infinite recursion / C stack overflow.
  obj <- x[[".mod"]]

  # Properties (direct access)
  if (name %in% c("xmin", "xmax", "duration", "nx", "dx", "x1", "ceiling")) {
    return(obj[[name]])
  }

  # is_valid is a .method(), not a .property(), in the underlying module
  # (see src/modules/pitch_module.cpp) - must be called, not accessed as a field.
  if (name == "is_valid") {
    return(obj$is_valid())
  }

  # Unit-conversion / transform wrappers (looked up in the shared factory list)
  if (name %in% names(.pitch_module_methods)) return(.pitch_module_methods[[name]](obj))

  # Direct passthrough for other methods
  # Direct passthrough for other methods
  if (name %in% c("get_time_from_frame", "get_frame_from_time",
                  "get_number_of_frames", "get_time_step",
                  "count_voiced_frames", "get_intensity_at_time",
                  "get_mean_intensity", "as_matrix", "get_all_candidates",
                  "save", "debug_candidates")) {
    return(obj[[name]])
  }

  # Fallback to module object
  obj[[name]]
}

# ============================================================================
# Module Integration Helpers
# ============================================================================
