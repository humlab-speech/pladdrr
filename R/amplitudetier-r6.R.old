#' @title Praat AmplitudeTier Object
#'
#' @description
#' R6 class representing a Praat AmplitudeTier object. An AmplitudeTier represents
#' sound pressure amplitude in Pascals as a function of time, stored as a sequence of
#' (time, value) points with interpolation between points.
#'
#' AmplitudeTier is derived from RealTier and is used for:
#' - Representing amplitude contours
#' - Analyzing amplitude perturbation (shimmer)
#' - Applying amplitude envelopes to sounds
#' - Storing peak/valley amplitudes from periodic signals
#'
#' ## Creating AmplitudeTier Objects
#'
#' AmplitudeTier objects can be created in several ways:
#'
#' ```r
#' # From PointProcess and Sound (e.g., for EGG analysis)
#' pp <- sound$to_point_process_peaks(75, 500, TRUE, FALSE)
#' amp_tier <- amplitude_tier_from_point_process(pp, sound)
#'
#' # From IntensityTier
#' int_tier <- sound$to_intensity(...)
#' amp_tier <- intensity_tier_to_amplitude_tier(int_tier)
#' ```
#'
#' ## Methods
#'
#' - `$add_point(time, value)` - Add a (time, amplitude) point
#' - `$get_value_at_time(time)` - Get interpolated value at time
#' - `$to_intensity_tier(threshold_db)` - Convert to IntensityTier (dB scale)
#' - `$get_shimmer_local(...)` - Calculate local shimmer
#' - `$get_shimmer_local_db(...)` - Calculate local shimmer in dB
#' - `$get_shimmer_apq3(...)` - Calculate 3-point amplitude perturbation quotient
#' - `$get_shimmer_apq5(...)` - Calculate 5-point amplitude perturbation quotient
#' - `$get_shimmer_apq11(...)` - Calculate 11-point amplitude perturbation quotient
#' - `$get_shimmer_dda(...)` - Calculate difference of differences of amplitudes
#' - `$multiply_sound(sound)` - Apply amplitude envelope to sound
#'
#' @examples
#' \dontrun{
#' # Example: Extract amplitude contour from periodic signal
#' sound <- praat_read("vowel.wav")
#' pp <- sound$to_point_process_peaks(75, 500, TRUE, FALSE)
#' amp_tier <- amplitude_tier_from_point_process(pp, sound)
#'
#' # Calculate shimmer
#' shimmer <- amp_tier$get_shimmer_local(0.0001, 0.02, 1.6)
#'
#' # Convert to dB scale
#' int_tier <- amp_tier$to_intensity_tier()
#' }
#'
#' @export
AmplitudeTier <- R6::R6Class(
  "AmplitudeTier",
  inherit = PraatObject,

  public = list(
    #' @description
    #' Create an AmplitudeTier object (internal use)
    #' @param .xptr External pointer to C++ AmplitudeTier object
    #' @return A new AmplitudeTier object
    initialize = function(.xptr = NULL) {
      if (is.null(.xptr)) {
        stop("AmplitudeTier objects must be created using amplitude_tier_create() or related functions")
      }
      super$initialize(.xptr)
    },

    #' @description
    #' Add a point to the tier
    #' @param time Time in seconds
    #' @param value Amplitude in Pascals
    add_point = function(time, value) {
      amplitude_tier_add_point_cpp(self$.pointer, time, value)
      invisible(self)
    },

    #' @description
    #' Get the interpolated amplitude value at a specific time
    #' @param time Time in seconds
    #' @return Amplitude in Pascals
    get_value_at_time = function(time) {
      amplitude_tier_get_value_at_time_cpp(self$.pointer, time)
    },

    #' @description
    #' Get the number of points in the tier
    #' @return Number of points
    get_number_of_points = function() {
      amplitude_tier_get_number_of_points_cpp(self$.pointer)
    },

    #' @description
    #' Convert to IntensityTier (dB scale)
    #' @param threshold_db Threshold in dB (default -200)
    #' @return IntensityTier object
    to_intensity_tier = function(threshold_db = -200) {
      ptr <- amplitude_tier_to_intensity_tier_cpp(self$.pointer, threshold_db)
      IntensityTier$new(.xptr = ptr)
    },

    #' @description
    #' Calculate local shimmer (amplitude perturbation)
    #' @param shortest_period Shortest period to consider (seconds)
    #' @param longest_period Longest period to consider (seconds)
    #' @param maximum_amplitude_factor Maximum amplitude factor
    #' @return Shimmer value (0-1) or NA if insufficient data
    get_shimmer_local = function(shortest_period = 0.0001,
                                  longest_period = 0.02,
                                  maximum_amplitude_factor = 1.6) {
      amplitude_tier_get_shimmer_local_cpp(
        self$.pointer,
        shortest_period,
        longest_period,
        maximum_amplitude_factor
      )
    },

    #' @description
    #' Calculate local shimmer in dB
    #' @param shortest_period Shortest period to consider (seconds)
    #' @param longest_period Longest period to consider (seconds)
    #' @param maximum_amplitude_factor Maximum amplitude factor
    #' @return Shimmer in dB or NA if insufficient data
    get_shimmer_local_db = function(shortest_period = 0.0001,
                                     longest_period = 0.02,
                                     maximum_amplitude_factor = 1.6) {
      amplitude_tier_get_shimmer_local_db_cpp(
        self$.pointer,
        shortest_period,
        longest_period,
        maximum_amplitude_factor
      )
    },

    #' @description
    #' Calculate 3-point amplitude perturbation quotient
    #' @param shortest_period Shortest period to consider (seconds)
    #' @param longest_period Longest period to consider (seconds)
    #' @param maximum_amplitude_factor Maximum amplitude factor
    #' @return APQ3 value or NA if insufficient data
    get_shimmer_apq3 = function(shortest_period = 0.0001,
                                 longest_period = 0.02,
                                 maximum_amplitude_factor = 1.6) {
      amplitude_tier_get_shimmer_apq3_cpp(
        self$.pointer,
        shortest_period,
        longest_period,
        maximum_amplitude_factor
      )
    },

    #' @description
    #' Calculate 5-point amplitude perturbation quotient
    #' @param shortest_period Shortest period to consider (seconds)
    #' @param longest_period Longest period to consider (seconds)
    #' @param maximum_amplitude_factor Maximum amplitude factor
    #' @return APQ5 value or NA if insufficient data
    get_shimmer_apq5 = function(shortest_period = 0.0001,
                                 longest_period = 0.02,
                                 maximum_amplitude_factor = 1.6) {
      amplitude_tier_get_shimmer_apq5_cpp(
        self$.pointer,
        shortest_period,
        longest_period,
        maximum_amplitude_factor
      )
    },

    #' @description
    #' Calculate 11-point amplitude perturbation quotient
    #' @param shortest_period Shortest period to consider (seconds)
    #' @param longest_period Longest period to consider (seconds)
    #' @param maximum_amplitude_factor Maximum amplitude factor
    #' @return APQ11 value or NA if insufficient data
    get_shimmer_apq11 = function(shortest_period = 0.0001,
                                  longest_period = 0.02,
                                  maximum_amplitude_factor = 1.6) {
      amplitude_tier_get_shimmer_apq11_cpp(
        self$.pointer,
        shortest_period,
        longest_period,
        maximum_amplitude_factor
      )
    },

    #' @description
    #' Calculate difference of differences of amplitudes (shimmer DDA)
    #' @param shortest_period Shortest period to consider (seconds)
    #' @param longest_period Longest period to consider (seconds)
    #' @param maximum_amplitude_factor Maximum amplitude factor
    #' @return DDA value or NA if insufficient data
    get_shimmer_dda = function(shortest_period = 0.0001,
                               longest_period = 0.02,
                               maximum_amplitude_factor = 1.6) {
      amplitude_tier_get_shimmer_dda_cpp(
        self$.pointer,
        shortest_period,
        longest_period,
        maximum_amplitude_factor
      )
    },

    #' @description
    #' Multiply a sound by this amplitude envelope
    #' @param sound Sound object to multiply
    #' @return New Sound object with amplitude envelope applied
    multiply_sound = function(sound) {
      if (!inherits(sound, "Sound")) {
        stop("Argument must be a Sound object")
      }
      ptr <- sound_amplitude_tier_multiply_cpp(sound$.pointer, self$.pointer)
      Sound$new(.xptr = ptr)
    }
  )
)

#' Create an empty AmplitudeTier
#'
#' @param tmin Start time in seconds
#' @param tmax End time in seconds
#' @return AmplitudeTier object
#' @export
amplitude_tier_create <- function(tmin, tmax) {
  ptr <- amplitude_tier_create_cpp(tmin, tmax)
  AmplitudeTier$new(.xptr = ptr)
}

#' Convert IntensityTier to AmplitudeTier
#'
#' Converts intensity values from dB to Pascals.
#'
#' @param intensity_tier IntensityTier object
#' @return AmplitudeTier object
#' @export
intensity_tier_to_amplitude_tier <- function(intensity_tier) {
  if (!inherits(intensity_tier, "IntensityTier")) {
    stop("Argument must be an IntensityTier object")
  }
  ptr <- intensity_tier_to_amplitude_tier_cpp(intensity_tier$.pointer)
  AmplitudeTier$new(.xptr = ptr)
}

#' Extract AmplitudeTier from PointProcess and Sound
#'
#' Extracts amplitude values from a Sound at times specified by a PointProcess.
#'
#' @param point_process PointProcess object specifying times
#' @param sound Sound object to extract amplitudes from
#' @return AmplitudeTier object
#' @export
amplitude_tier_from_point_process <- function(point_process, sound) {
  if (!inherits(point_process, "PointProcess")) {
    stop("First argument must be a PointProcess object")
  }
  if (!inherits(sound, "Sound")) {
    stop("Second argument must be a Sound object")
  }
  ptr <- point_process_sound_to_amplitude_tier_point_cpp(
    point_process$.pointer,
    sound$.pointer
  )
  AmplitudeTier$new(.xptr = ptr)
}
