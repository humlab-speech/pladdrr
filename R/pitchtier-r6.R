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
#' - `PitchTier(tmin, tmax)` - Create empty PitchTier
#' - `pitch$down_to_pitch_tier()` - Extract from Pitch object
#'
#' ## Querying
#'
#' - `$get_number_of_points()` - Number of pitch points
#' - `$get_value_at_time(time)` - Interpolated F0 at time
#' - `$get_value_at_index(index)` - F0 of specific point
#' - `$get_time_from_index(index)` - Time of specific point
#'
#' ## Modification
#'
#' - `$add_point(time, value)` - Add pitch point (Hz)
#' - `$remove_point(index)` - Remove point
#' - `$multiply_frequencies(factor)` - Scale all frequencies
#' - `$shift_frequencies(shift)` - Add to all frequencies (Hz)
#' - `$stylize(frequency_resolution)` - Simplify contour
#'
#' ## Export
#'
#' - `$as_data_frame()` - Convert to data frame
#' - `$save(path)` - Write to file
#'
#' @examples
#' \dontrun{
#' # Create from Pitch
#' sound <- Sound("audio.wav")
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
    
    # Query Methods
    get_start_time = function() {
      cpp_obj$get_xmin()
    },
    
    get_end_time = function() {
      cpp_obj$get_xmax()
    },
    
    get_number_of_points = function() {
      cpp_obj$get_number_of_points()
    },
    
    get_time_from_index = function(index) {
      cpp_obj$get_time(as.integer(index))
    },
    
    get_value_at_index = function(index) {
      cpp_obj$get_value(as.integer(index))
    },
    
    get_value_at_time = function(time) {
      cpp_obj$get_value_at_time(as.numeric(time))
    },
    
    get_mean = function(tmin = NULL, tmax = NULL) {
      if (is.null(tmin)) tmin <- cpp_obj$get_xmin()
      if (is.null(tmax)) tmax <- cpp_obj$get_xmax()
      cpp_obj$get_mean_curve(as.numeric(tmin), as.numeric(tmax))
    },
    
    # Modification Methods
    add_point = function(time, value) {
      cpp_obj$add_point(as.numeric(time), as.numeric(value))
      invisible(obj)
    },
    
    remove_point = function(index) {
      cpp_obj$remove_point(as.integer(index))
      invisible(obj)
    },
    
    remove_points_between = function(tmin, tmax) {
      cpp_obj$remove_points_between(as.numeric(tmin), as.numeric(tmax))
      invisible(obj)
    },
    
    multiply_frequencies = function(factor) {
      cpp_obj$multiply_frequencies(as.numeric(factor))
      invisible(obj)
    },
    
    shift_frequencies = function(shift) {
      cpp_obj$shift_frequencies(as.numeric(shift))
      invisible(obj)
    },
    
    stylize = function(frequency_resolution = 2.0, use_semitones = FALSE) {
      cpp_obj$stylize(as.numeric(frequency_resolution), as.logical(use_semitones))
      invisible(obj)
    },
    
    # Export Methods
    as_data_frame = function() {
      df <- cpp_obj$as_data_frame()
      names(df) <- c("time", "frequency")
      df
    },
    
    save = function(path) {
      cpp_obj$save(as.character(path))
      invisible(obj)
    },
    
    # Utility
    get_xptr = function() {
      .xptr
    },
    
    # Print
    print = function() {
      cat("<Praat PitchTier>\n")
      cat(sprintf("  Time domain: %.3f to %.3f s\n", 
                  cpp_obj$get_xmin(), cpp_obj$get_xmax()))
      n_points <- cpp_obj$get_number_of_points()
      cat(sprintf("  Number of points: %d\n", n_points))
      if (n_points > 0) {
        mean_f0 <- cpp_obj$get_mean_curve(cpp_obj$get_xmin(), cpp_obj$get_xmax())
        cat(sprintf("  Mean frequency: %.1f Hz\n", mean_f0))
      }
      invisible(obj)
    }
    
  ), class = c("PitchTier", "PraatObject"))
  
  obj
}

#' @export
print.PitchTier <- function(x, ...) {
  x$print()
}

#' @export
as.data.frame.PitchTier <- function(x, ...) {
  x$as_data_frame()
}
