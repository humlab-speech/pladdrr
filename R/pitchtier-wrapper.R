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
#' @export
PitchTier <- function(tmin = NULL, tmax = NULL, .xptr = NULL) {

  # Handle creation modes
  if (!is.null(.xptr)) {
    # From existing C++ object
    ptr <- .xptr
  } else if (!is.null(tmin) && !is.null(tmax)) {
    # Create new empty tier
    ptr <- .pitchtier_create(as.numeric(tmin), as.numeric(tmax))
  } else {
    stop("Must provide either (tmin, tmax) or .xptr")
  }

  tier_mod <- get_module("pitchtier_module")
  cpp_obj <- tier_mod$RPitchTier$new(ptr)

  obj <- structure(list(
    .cpp = cpp_obj,
    .xptr = ptr,

    # =========================================================================
    # Query Methods
    # =========================================================================

    #' @description Get start time of tier domain
    get_start_time = function() {
      cpp_obj$get_xmin()
    },

    #' @description Get end time of tier domain
    get_end_time = function() {
      cpp_obj$get_xmax()
    },

    #' @description Get duration of tier domain
    get_duration = function() {
      cpp_obj$get_duration()
    },

    #' @description Get number of pitch points
    get_number_of_points = function() {
      cpp_obj$get_number_of_points()
    },

    #' @description Get time of point at index (1-based)
    get_time_from_index = function(index) {
      cpp_obj$get_time(as.integer(index))
    },

    #' @description Get frequency value at index (1-based)
    get_value_at_index = function(index) {
      cpp_obj$get_value(as.integer(index))
    },

    #' @description Get interpolated frequency at time
    get_value_at_time = function(time) {
      cpp_obj$get_value_at_time(as.numeric(time))
    },

    #' @description Get minimum frequency value
    get_minimum = function() {
      cpp_obj$get_minimum()
    },

    #' @description Get maximum frequency value
    get_maximum = function() {
      cpp_obj$get_maximum()
    },

    #' @description Get mean frequency (curve interpolation)
    get_mean = function(tmin = NULL, tmax = NULL) {
      if (is.null(tmin)) tmin <- cpp_obj$get_xmin()
      if (is.null(tmax)) tmax <- cpp_obj$get_xmax()
      cpp_obj$get_mean_curve(as.numeric(tmin), as.numeric(tmax))
    },

    #' @description Get mean frequency (points only)
    get_mean_points = function(tmin = NULL, tmax = NULL) {
      if (is.null(tmin)) tmin <- cpp_obj$get_xmin()
      if (is.null(tmax)) tmax <- cpp_obj$get_xmax()
      cpp_obj$get_mean_points(as.numeric(tmin), as.numeric(tmax))
    },

    #' @description Get standard deviation (curve interpolation)
    get_standard_deviation = function(tmin = NULL, tmax = NULL) {
      if (is.null(tmin)) tmin <- cpp_obj$get_xmin()
      if (is.null(tmax)) tmax <- cpp_obj$get_xmax()
      cpp_obj$get_standard_deviation_curve(as.numeric(tmin), as.numeric(tmax))
    },

    #' @description Get standard deviation (points only)
    get_standard_deviation_points = function(tmin = NULL, tmax = NULL) {
      if (is.null(tmin)) tmin <- cpp_obj$get_xmin()
      if (is.null(tmax)) tmax <- cpp_obj$get_xmax()
      cpp_obj$get_standard_deviation_points(as.numeric(tmin), as.numeric(tmax))
    },

    #' @description Get area under interpolated curve
    get_area = function(tmin = NULL, tmax = NULL) {
      if (is.null(tmin)) tmin <- cpp_obj$get_xmin()
      if (is.null(tmax)) tmax <- cpp_obj$get_xmax()
      cpp_obj$get_area(as.numeric(tmin), as.numeric(tmax))
    },

    # =========================================================================
    # Modification Methods
    # =========================================================================

    #' @description Add a pitch point at time with frequency value (Hz)
    add_point = function(time, value) {
      cpp_obj$add_point(as.numeric(time), as.numeric(value))
      invisible(obj)
    },

    #' @description Remove point at index (1-based)
    remove_point = function(index) {
      cpp_obj$remove_point(as.integer(index))
      invisible(obj)
    },

    #' @description Remove all points in time range
    remove_points_between = function(tmin, tmax) {
      cpp_obj$remove_points_between(as.numeric(tmin), as.numeric(tmax))
      invisible(obj)
    },

    #' @description Multiply all frequencies by factor
    multiply_frequencies = function(factor) {
      tmin <- cpp_obj$get_xmin()
      tmax <- cpp_obj$get_xmax()
      cpp_obj$multiply_frequencies(as.numeric(tmin), as.numeric(tmax), as.numeric(factor))
      invisible(obj)
    },

    #' @description Multiply frequencies in time range by factor
    multiply_frequencies_in_range = function(tmin, tmax, factor) {
      cpp_obj$multiply_frequencies(as.numeric(tmin), as.numeric(tmax), as.numeric(factor))
      invisible(obj)
    },

    #' @description Shift all frequencies by amount
    #' @param shift Amount to shift (Hz or semitones)
    #' @param unit Unit: "hertz" (0), "mel" (1), "log_hertz" (2), "semitones" (3), "erb" (4)
    shift_frequencies = function(shift, unit = "hertz") {
      tmin <- cpp_obj$get_xmin()
      tmax <- cpp_obj$get_xmax()
      unit_code <- switch(tolower(unit),
        "hertz" = 0, "hz" = 0,
        "mel" = 1,
        "log_hertz" = 2, "loghertz" = 2,
        "semitones" = 3, "st" = 3,
        "erb" = 4,
        0  # default to Hertz
      )
      cpp_obj$shift_frequencies(as.numeric(tmin), as.numeric(tmax), as.numeric(shift), as.integer(unit_code))
      invisible(obj)
    },

    #' @description Shift frequencies in time range by amount
    shift_frequencies_in_range = function(tmin, tmax, shift, unit = "hertz") {
      unit_code <- switch(tolower(unit),
        "hertz" = 0, "hz" = 0,
        "mel" = 1,
        "log_hertz" = 2, "loghertz" = 2,
        "semitones" = 3, "st" = 3,
        "erb" = 4,
        0
      )
      cpp_obj$shift_frequencies(as.numeric(tmin), as.numeric(tmax), as.numeric(shift), as.integer(unit_code))
      invisible(obj)
    },

    #' @description Stylize (simplify) pitch contour
    stylize = function(frequency_resolution = 2.0, use_semitones = FALSE) {
      cpp_obj$stylize(as.numeric(frequency_resolution), as.logical(use_semitones))
      invisible(obj)
    },

    #' @description Interpolate quadratically between points
    interpolate_quadratically = function(points_per_parabola = 4, logarithmically = FALSE) {
      .pitchtier_interpolate_quadratically(ptr, as.integer(points_per_parabola), as.logical(logarithmically))
      invisible(obj)
    },

    # =========================================================================
    # Conversion Methods
    # =========================================================================

    #' @description Convert to PointProcess (extract time points)
    down_to_point_process = function() {
      pp_ptr <- cpp_obj$down_to_point_process_ptr()
      PointProcess(.xptr = pp_ptr)
    },

    #' @description Synthesize pulse train sound
    to_sound_pulse_train = function(sample_rate = 44100, adaptation_factor = 1.0,
                                     adaptation_time = 0.05, interpolation_depth = 2000) {
      snd_ptr <- .pitchtier_to_sound_pulse_train(ptr, as.numeric(sample_rate),
                                                  as.numeric(adaptation_factor),
                                                  as.numeric(adaptation_time),
                                                  as.integer(interpolation_depth))
      Sound(.xptr = snd_ptr)
    },

    #' @description Synthesize phonation sound
    to_sound_phonation = function(sample_rate = 44100, adaptation_factor = 1.0,
                                   maximum_period = 0.05, open_phase = 0.7,
                                   collision_phase = 0.03, power1 = 3.0, power2 = 4.0) {
      snd_ptr <- .pitchtier_to_sound_phonation(ptr, as.numeric(sample_rate),
                                                as.numeric(adaptation_factor),
                                                as.numeric(maximum_period),
                                                as.numeric(open_phase),
                                                as.numeric(collision_phase),
                                                as.numeric(power1), as.numeric(power2))
      Sound(.xptr = snd_ptr)
    },

    #' @description Synthesize sine wave sound
    to_sound_sine = function(sample_rate = 44100, tmin = NULL, tmax = NULL) {
      if (is.null(tmin)) tmin <- cpp_obj$get_xmin()
      if (is.null(tmax)) tmax <- cpp_obj$get_xmax()
      snd_ptr <- .pitchtier_to_sound_sine(ptr, as.numeric(tmin), as.numeric(tmax),
                                           as.numeric(sample_rate))
      Sound(.xptr = snd_ptr)
    },

    #' @description Convert to Pitch object
    to_pitch = function(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600) {
      pitch_ptr <- .pitchtier_to_pitch(ptr, as.numeric(time_step),
                                        as.numeric(pitch_floor), as.numeric(pitch_ceiling))
      Pitch(.xptr = pitch_ptr)
    },

    # =========================================================================
    # Export Methods
    # =========================================================================

    #' @description Convert to data.table with time and frequency columns
    as_data_frame = function() {
      df <- cpp_obj$as_data_frame()
      names(df) <- c("time", "frequency")
      df
    },

    #' @description Convert to matrix (n x 2: time, frequency)
    as_matrix = function() {
      mat <- cpp_obj$as_matrix()
      colnames(mat) <- c("time", "frequency")
      mat
    },

    #' @description Save to file
    save = function(path) {
      cpp_obj$save(as.character(path))
      invisible(obj)
    },

    # =========================================================================
    # Utility
    # =========================================================================

    #' @description Get internal pointer
    get_xptr = function() {
      ptr
    },

    #' @description Print summary
    print = function() {
      cat("<Praat PitchTier>\n")
      cat(sprintf("  Time domain: %.3f to %.3f s\n",
                  cpp_obj$get_xmin(), cpp_obj$get_xmax()))
      n_points <- cpp_obj$get_number_of_points()
      cat(sprintf("  Number of points: %d\n", n_points))
      if (n_points > 0) {
        cat(sprintf("  F0 range: %.1f - %.1f Hz\n", cpp_obj$get_minimum(), cpp_obj$get_maximum()))
        mean_f0 <- cpp_obj$get_mean_curve(cpp_obj$get_xmin(), cpp_obj$get_xmax())
        cat(sprintf("  Mean frequency: %.1f Hz\n", mean_f0))
      }
      invisible(obj)
    }

  ), class = c("PitchTier", "PraatObject"))

  obj
}

#' @title Load PitchTier from file
#' @description Static method to load PitchTier from file
#' @param path Path to PitchTier file
#' @return PitchTier object
#' @keywords internal
pitchtier_from_file <- function(path) {
  ptr <- .pitchtier_read(as.character(path))
  PitchTier(.xptr = ptr)
}

# Make PitchTier "class" support $ for static methods (backward compatibility)
.pitchtier_static_env <- new.env(parent = emptyenv())
.pitchtier_static_env$new <- pitchtier_from_file

#' $ method for PitchTier constructor (enables PitchTier$new(), etc.)
#' @param x The PitchTier constructor function
#' @param name Name of static method to access
#' @return The requested static method function
#' @exportS3Method "$" pitchtier_constructor
`$.pitchtier_constructor` <- function(x, name) {
  val <- .pitchtier_static_env[[name]]
  if (is.null(val)) {
    stop("PitchTier has no static method '", name, "'. Available: new")
  }
  val
}

# Assign class to enable $ operator
class(PitchTier) <- c("pitchtier_constructor", "function")

#' @export
print.PitchTier <- function(x, ...) {
  x$print()
}

#' @export
as.data.frame.PitchTier <- function(x, ...) {
  x$as_data_frame()
}
