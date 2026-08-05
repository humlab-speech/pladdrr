#' @title Praat PitchTier Object
#' @description
#' Praat PitchTier object with direct C++ module binding for pitch manipulation.
#'
#' @details
#' PitchTiers are used in conjunction with Manipulation objects to modify the
#' pitch contour of sounds. Unlike Pitch objects (which contain sampled data),
#' PitchTiers contain discrete time-value pairs that can be edited.
#'
#' ## Creating PitchTier Objects
#'
#' - `PitchTier$new(path)` - Load from file
#' - `PitchTier(tmin, tmax)` - Create empty PitchTier
#' - `pitch$down_to_pitch_tier()` - Extract from Pitch object
#'
#' ## Querying
#'
#' - `$get_number_of_points()` - Number of pitch points
#' - `$get_value_at_time(time)` - Interpolated F0 at time
#' - `$get_value_at_index(index)` - F0 of specific point
#' - `$get_time_from_index(index)` - Time of specific point
#' - `$get_minimum()` - Minimum F0 value
#' - `$get_maximum()` - Maximum F0 value
#' - `$get_mean(tmin, tmax)` - Mean F0 (interpolated curve)
#' - `$get_standard_deviation(tmin, tmax)` - Standard deviation
#' - `$get_area(tmin, tmax)` - Area under curve
#'
#' ## Modification
#'
#' - `$add_point(time, value)` - Add pitch point (Hz)
#' - `$remove_point(index)` - Remove point by index
#' - `$remove_points_between(tmin, tmax)` - Remove points in time range
#' - `$multiply_frequencies(factor)` - Scale all frequencies
#' - `$multiply_frequencies_in_range(tmin, tmax, factor)` - Scale in range
#' - `$shift_frequencies(shift, unit)` - Add to all frequencies
#' - `$shift_frequencies_in_range(tmin, tmax, shift, unit)` - Shift in range
#' - `$stylize(frequency_resolution, use_semitones)` - Simplify contour
#' - `$interpolate_quadratically(points_per_parabola, logarithmically)` - Smooth
#'
#' ## Conversion
#'
#' - `$to_sound_pulse_train(sample_rate)` - Synthesize pulse train
#' - `$to_sound_phonation(sample_rate)` - Synthesize phonation
#' - `$to_sound_sine(sample_rate)` - Synthesize sine wave
#' - `$down_to_point_process()` - Extract time points
#' - `$to_pitch(time_step, pitch_floor, pitch_ceiling)` - Convert to Pitch
#'
#' ## Export
#'
#' - `$as_data_frame()` - Convert to data.table
#' - `$as_matrix()` - Convert to matrix
#' - `$save(path)` - Write to file
#'
#' @examples
#' \dontrun{
#' # Create empty PitchTier and add points
#' pt <- PitchTier(0, 1)
#' pt$add_point(0.1, 120)
#' pt$add_point(0.5, 150)
#' pt$add_point(0.9, 100)
#'
#' # Load from file
#' pt <- PitchTier$new("contour.PitchTier")
#'
#' # Create from Pitch
#' sound <- Sound$new("audio.wav")
#' pitch <- sound$to_pitch()
#' pitch_tier <- pitch$down_to_pitch_tier()
#'
#' # Modify pitch
#' pitch_tier$multiply_frequencies(1.5)  # Raise pitch 50%
#' pitch_tier$shift_frequencies(50)       # Add 50 Hz
#'
#' # Query
#' f0_at_1s <- pitch_tier$get_value_at_time(1.0)
#' n_points <- pitch_tier$get_number_of_points()
#' f0_min <- pitch_tier$get_minimum()
#' f0_max <- pitch_tier$get_maximum()
#'
#' # Synthesize
#' synth <- pitch_tier$to_sound_sine(16000)
#'
#' # Export
#' df <- pitch_tier$as_data_frame()
#' pitch_tier$save("modified.PitchTier")
#' }
#'
#' @name PitchTier
NULL

# ============================================================================
# Helpers
# ============================================================================


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
#' @keywords internal
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
}

#' @export
as.data.frame.PitchTier <- function(x, ...) {
  x$as_data_frame()
}
