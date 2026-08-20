#' PitchTier
#'
#' Praat PitchTier object: a sequence of time-value points describing a pitch contour.
#'
#' PitchTiers are used together with Manipulation objects to modify the pitch
#' contour of sounds. Unlike Pitch objects, which hold sampled data, PitchTiers
#' hold discrete time-value pairs that can be edited directly.
#'
#' @section Usage:
#' \preformatted{
#' PitchTier$new(path)          # load from file
#' PitchTier(tmin, tmax)        # create an empty PitchTier
#' pitch$down_to_pitch_tier()   # extract from a Pitch object
#' }
#'
#' @section Query methods:
#' \itemize{
#'   \item \code{get_number_of_points()} - number of pitch points
#'   \item \code{get_value_at_time(time)} - interpolated F0 at a time
#'   \item \code{get_value_at_index(index)} - F0 of a specific point
#'   \item \code{get_time_from_index(index)} - time of a specific point
#'   \item \code{get_minimum()}, \code{get_maximum()} - F0 range
#'   \item \code{get_mean(tmin, tmax)} - mean F0 (interpolated curve)
#'   \item \code{get_standard_deviation(tmin, tmax)} - standard deviation
#'   \item \code{get_area(tmin, tmax)} - area under the curve
#' }
#'
#' @section Modification:
#' \itemize{
#'   \item \code{add_point(time, value)} - add a pitch point (Hz)
#'   \item \code{remove_point(index)} - remove a point by index
#'   \item \code{remove_points_between(tmin, tmax)} - remove points in a time range
#'   \item \code{multiply_frequencies(factor)} - scale all frequencies
#'   \item \code{multiply_frequencies_in_range(tmin, tmax, factor)} - scale in a range
#'   \item \code{shift_frequencies(shift, unit)} - add to all frequencies
#'   \item \code{shift_frequencies_in_range(tmin, tmax, shift, unit)} - shift in a range
#'   \item \code{stylize(frequency_resolution, use_semitones)} - simplify the contour
#'   \item \code{interpolate_quadratically(points_per_parabola, logarithmically)} - smooth the contour
#' }
#'
#' @section Conversion:
#' \itemize{
#'   \item \code{to_sound_pulse_train(sample_rate)} - synthesize a pulse train
#'   \item \code{to_sound_phonation(sample_rate)} - synthesize phonation
#'   \item \code{to_sound_sine(sample_rate)} - synthesize a sine wave
#'   \item \code{down_to_point_process()} - extract time points
#'   \item \code{to_pitch(time_step, pitch_floor, pitch_ceiling)} - convert to a Pitch object
#' }
#'
#' @section Export:
#' \itemize{
#'   \item \code{as_data_frame()} - convert to a data.table
#'   \item \code{as_matrix()} - convert to a matrix
#'   \item \code{save(path)} - write to file
#' }
#'
#' @param tmin Start time in seconds, for creating an empty PitchTier.
#' @param tmax End time in seconds, for creating an empty PitchTier.
#' @param .xptr Not for direct use. External pointer to the underlying C++
#'   PitchTier object; set internally when a method returns a new PitchTier.
#' @return A \code{PitchTier} object with methods for pitch-contour manipulation
#'   via time-value points.
#'
#' @examples
#' # Create empty PitchTier and add points
#' pt <- PitchTier(0, 1)
#' pt$add_point(0.1, 120)
#' pt$add_point(0.5, 150)
#' pt$add_point(0.9, 100)
#'
#' # Create from Pitch
#' sound <- Sound$create_tone(frequency = 150, duration = 0.5)
#' pitch <- sound$to_pitch()
#' pitch_tier <- pitch$down_to_pitch_tier()
#'
#' # Modify pitch
#' pitch_tier$multiply_frequencies(1.5)  # Raise pitch 50%
#'
#' # Query
#' f0_at_mid <- pitch_tier$get_value_at_time(0.25)
#' n_points <- pitch_tier$get_number_of_points()
#' f0_min <- pitch_tier$get_minimum()
#' f0_max <- pitch_tier$get_maximum()
#'
#' # Synthesize
#' synth <- pitch_tier$to_sound_sine(16000)
#'
#' # Export
#' df <- pitch_tier$as_data_frame()
#'
#' @name PitchTier
NULL

# ============================================================================
# Helpers
# ============================================================================

# Helper: pitch unit string -> integer code.
# Same mapping as .pitch_unit_code() in pitch-wrapper.R — delegate to avoid drift.
.pitchtier_unit_code <- function(unit) {
  .pitch_unit_code(unit)
}

# ============================================================================
# Shared Method Dispatch Table
# ============================================================================

.pitchtier_methods <- new.env(hash = TRUE, parent = emptyenv())

# Query
.pitchtier_methods$get_start_time <- function(.self) .self$.cpp$get_xmin()
.pitchtier_methods$get_end_time <- function(.self) .self$.cpp$get_xmax()
.pitchtier_methods$get_duration <- function(.self) .self$.cpp$get_duration()
.pitchtier_methods$get_number_of_points <- function(.self) .self$.cpp$get_number_of_points()
.pitchtier_methods$get_time_from_index <- function(.self, index) .self$.cpp$get_time(as.integer(index))
.pitchtier_methods$get_value_at_index <- function(.self, index) .self$.cpp$get_value(as.integer(index))
.pitchtier_methods$get_value_at_time <- function(.self, time) .self$.cpp$get_value_at_time(as.numeric(time))
.pitchtier_methods$get_minimum <- function(.self) .self$.cpp$get_minimum()
.pitchtier_methods$get_maximum <- function(.self) .self$.cpp$get_maximum()

.pitchtier_methods$get_mean <- function(.self, tmin = NULL, tmax = NULL) {
  if (is.null(tmin)) tmin <- .self$.cpp$get_xmin()
  if (is.null(tmax)) tmax <- .self$.cpp$get_xmax()
  .self$.cpp$get_mean_curve(as.numeric(tmin), as.numeric(tmax))
}

.pitchtier_methods$get_mean_points <- function(.self, tmin = NULL, tmax = NULL) {
  if (is.null(tmin)) tmin <- .self$.cpp$get_xmin()
  if (is.null(tmax)) tmax <- .self$.cpp$get_xmax()
  .self$.cpp$get_mean_points(as.numeric(tmin), as.numeric(tmax))
}

.pitchtier_methods$get_standard_deviation <- function(.self, tmin = NULL, tmax = NULL) {
  if (is.null(tmin)) tmin <- .self$.cpp$get_xmin()
  if (is.null(tmax)) tmax <- .self$.cpp$get_xmax()
  .self$.cpp$get_standard_deviation_curve(as.numeric(tmin), as.numeric(tmax))
}

.pitchtier_methods$get_standard_deviation_points <- function(.self, tmin = NULL, tmax = NULL) {
  if (is.null(tmin)) tmin <- .self$.cpp$get_xmin()
  if (is.null(tmax)) tmax <- .self$.cpp$get_xmax()
  .self$.cpp$get_standard_deviation_points(as.numeric(tmin), as.numeric(tmax))
}

.pitchtier_methods$get_area <- function(.self, tmin = NULL, tmax = NULL) {
  if (is.null(tmin)) tmin <- .self$.cpp$get_xmin()
  if (is.null(tmax)) tmax <- .self$.cpp$get_xmax()
  .self$.cpp$get_area(as.numeric(tmin), as.numeric(tmax))
}

# Modification (self-returning)
.pitchtier_methods$add_point <- function(.self, time, value) {
  .self$.cpp$add_point(as.numeric(time), as.numeric(value))
  invisible(.self)
}

.pitchtier_methods$remove_point <- function(.self, index) {
  .self$.cpp$remove_point(as.integer(index))
  invisible(.self)
}

.pitchtier_methods$remove_points_between <- function(.self, tmin, tmax) {
  .self$.cpp$remove_points_between(as.numeric(tmin), as.numeric(tmax))
  invisible(.self)
}

.pitchtier_methods$multiply_frequencies <- function(.self, factor) {
  tmin <- .self$.cpp$get_xmin()
  tmax <- .self$.cpp$get_xmax()
  .self$.cpp$multiply_frequencies(as.numeric(tmin), as.numeric(tmax), as.numeric(factor))
  invisible(.self)
}

.pitchtier_methods$multiply_frequencies_in_range <- function(.self, tmin, tmax, factor) {
  .self$.cpp$multiply_frequencies(as.numeric(tmin), as.numeric(tmax), as.numeric(factor))
  invisible(.self)
}

.pitchtier_methods$shift_frequencies <- function(.self, shift, unit = "hertz") {
  tmin <- .self$.cpp$get_xmin()
  tmax <- .self$.cpp$get_xmax()
  unit_code <- .pitchtier_unit_code(unit)
  .self$.cpp$shift_frequencies(as.numeric(tmin), as.numeric(tmax), as.numeric(shift), unit_code)
  invisible(.self)
}

.pitchtier_methods$shift_frequencies_in_range <- function(.self, tmin, tmax, shift, unit = "hertz") {
  unit_code <- .pitchtier_unit_code(unit)
  .self$.cpp$shift_frequencies(as.numeric(tmin), as.numeric(tmax), as.numeric(shift), unit_code)
  invisible(.self)
}

.pitchtier_methods$stylize <- function(.self, frequency_resolution = 2.0, use_semitones = FALSE) {
  .self$.cpp$stylize(as.numeric(frequency_resolution), as.logical(use_semitones))
  invisible(.self)
}

.pitchtier_methods$interpolate_quadratically <- function(.self, points_per_parabola = 4, logarithmically = FALSE) {
  .pitchtier_interpolate_quadratically(.self$.xptr, as.integer(points_per_parabola), as.logical(logarithmically))
  invisible(.self)
}

# Conversion
.pitchtier_methods$down_to_point_process <- function(.self) {
  pp_ptr <- .self$.cpp$down_to_point_process_ptr()
  PointProcess(.xptr = pp_ptr)
}

.pitchtier_methods$to_sound_pulse_train <- function(.self, sample_rate = 44100, adaptation_factor = 1.0,
                                                     adaptation_time = 0.05, interpolation_depth = 2000) {
  snd_ptr <- .pitchtier_to_sound_pulse_train(.self$.xptr, as.numeric(sample_rate),
                                              as.numeric(adaptation_factor),
                                              as.numeric(adaptation_time),
                                              as.integer(interpolation_depth))
  Sound(.xptr = snd_ptr)
}

.pitchtier_methods$to_sound_phonation <- function(.self, sample_rate = 44100, adaptation_factor = 1.0,
                                                   maximum_period = 0.05, open_phase = 0.7,
                                                   collision_phase = 0.03, power1 = 3.0, power2 = 4.0) {
  snd_ptr <- .pitchtier_to_sound_phonation(.self$.xptr, as.numeric(sample_rate),
                                            as.numeric(adaptation_factor),
                                            as.numeric(maximum_period),
                                            as.numeric(open_phase),
                                            as.numeric(collision_phase),
                                            as.numeric(power1), as.numeric(power2))
  Sound(.xptr = snd_ptr)
}

.pitchtier_methods$to_sound_sine <- function(.self, sample_rate = 44100, tmin = NULL, tmax = NULL) {
  if (is.null(tmin)) tmin <- .self$.cpp$get_xmin()
  if (is.null(tmax)) tmax <- .self$.cpp$get_xmax()
  snd_ptr <- .pitchtier_to_sound_sine(.self$.xptr, as.numeric(tmin), as.numeric(tmax),
                                       as.numeric(sample_rate))
  Sound(.xptr = snd_ptr)
}

.pitchtier_methods$to_pitch <- function(.self, time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600) {
  pitch_ptr <- .pitchtier_to_pitch(.self$.xptr, as.numeric(time_step),
                                    as.numeric(pitch_floor), as.numeric(pitch_ceiling))
  Pitch(.xptr = pitch_ptr)
}

# Export
.pitchtier_methods$as_data_frame <- function(.self) {
  df <- .self$.cpp$as_data_frame()
  names(df) <- c("time", "frequency")
  df
}

.pitchtier_methods$as_matrix <- function(.self) {
  mat <- .self$.cpp$as_matrix()
  colnames(mat) <- c("time", "frequency")
  mat
}

.pitchtier_methods$save <- function(.self, path) {
  .self$.cpp$save(as.character(path))
  invisible(.self)
}

# Utility
.pitchtier_methods$get_xptr <- function(.self) .self$.xptr

# Display
.pitchtier_methods$print <- function(.self) {
  cat("<Praat PitchTier>\n")
  cat(sprintf("  Time domain: %.3f to %.3f s\n",
              .self$.cpp$get_xmin(), .self$.cpp$get_xmax()))
  n_points <- .self$.cpp$get_number_of_points()
  cat(sprintf("  Number of points: %d\n", n_points))
  if (n_points > 0) {
    cat(sprintf("  F0 range: %.1f - %.1f Hz\n", .self$.cpp$get_minimum(), .self$.cpp$get_maximum()))
    mean_f0 <- .self$.cpp$get_mean_curve(.self$.cpp$get_xmin(), .self$.cpp$get_xmax())
    cat(sprintf("  Mean frequency: %.1f Hz\n", mean_f0))
  }
  invisible(.self)
}

.pitchtier_methods$is_valid <- function(.self) .self$.cpp$is_valid()
lockEnvironment(.pitchtier_methods, bindings = TRUE)

# ============================================================================
# S3 Dispatch
# ============================================================================

#' @method $ PitchTier
#' @export
`$.PitchTier` <- function(x, name) {
  # Fast path: fields
  val <- .subset2(x, name)
  if (!is.null(val)) return(val)
  # Method lookup
  method <- .pitchtier_methods[[name]]
  if (is.null(method)) return(NULL)
  function(...) method(x, ...)
}

# ============================================================================
# Constructor
# ============================================================================

#' @export
PitchTier <- function(tmin = NULL, tmax = NULL, .xptr = NULL) {
  if (!is.null(.xptr)) {
    ptr <- .xptr
  } else if (!is.null(tmin) && !is.null(tmax)) {
    ptr <- .pitchtier_create(as.numeric(tmin), as.numeric(tmax))
  } else {
    stop("Must provide either (tmin, tmax) or .xptr")
  }

  tier_mod <- get_module("pitchtier_module")
  cpp_obj <- tier_mod$RPitchTier$new(ptr)

  structure(list(
    .cpp = cpp_obj,
    .xptr = ptr
  ), class = c("PitchTier", "PraatObject"))
}

# ============================================================================
# Static Methods (backward compatibility: PitchTier$new)
# ============================================================================

#' @title Load PitchTier from file
#' @description Static method to load PitchTier from file
#' @param path Path to PitchTier file
#' @return PitchTier object
#' @examples
#' tier <- PitchTier(0, 1)
#' tier$add_point(0.5, 150)
#' tmp <- tempfile(fileext = ".PitchTier")
#' tier$save(tmp)
#' loaded <- pladdrr:::pitchtier_from_file(tmp)
#' unlink(tmp)
#' @keywords internal
#' @noRd
pitchtier_from_file <- function(path) {
  ptr <- .pitchtier_read(as.character(path))
  PitchTier(.xptr = ptr)
}

.pitchtier_static_env <- new.env(parent = emptyenv())
.pitchtier_static_env$new <- pitchtier_from_file

#' @exportS3Method "$" pitchtier_constructor
`$.pitchtier_constructor` <- function(x, name) {
  val <- .pitchtier_static_env[[name]]
  if (is.null(val)) {
    stop("PitchTier has no static method '", name, "'. Available: new")
  }
  val
}

class(PitchTier) <- c("pitchtier_constructor", "function")

# ============================================================================
# S3 Methods
# ============================================================================

#' @export
print.PitchTier <- function(x, ...) {
  x$print()
  invisible(x)
}

#' @export
as.data.frame.PitchTier <- function(x, ...) {
  x$as_data_frame()
}
