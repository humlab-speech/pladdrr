#' @title Praat Electroglottogram Object
#'
#' @description
#' R6 class representing a Praat Electroglottogram (EGG) object. An Electroglottogram
#' measures the electrical impedance across the larynx, which varies with the degree
#' of vocal fold contact during phonation.
#'
#' Electroglottogram inherits from Sound and represents a specialized single-channel
#' sound that records vocal fold contact area. The EGG signal is used for:
#' - Determining glottal closure/opening instants
#' - Measuring closed quotient and open quotient
#' - Analyzing voice quality and phonation types
#' - Synchronizing with acoustic signals
#'
#' ## Creating Electroglottogram Objects
#'
#' Electroglottograms are typically extracted from a recorded channel:
#'
#' ```r
#' # Extract EGG from a specific channel of a recording
#' sound <- praat_read("recording_with_egg.wav")
#' egg <- sound$extract_electroglottogram(channel = 2, invert = FALSE)
#' ```
#'
#' ## Analysis Methods
#'
#' - `$to_textgrid_closed_glottis()` - Detect closed glottis intervals
#' - `$to_amplitude_tier_levels()` - Extract peak/valley amplitude levels
#' - `$derivative()` - Calculate derivative (DEGG)
#' - `$first_central_difference()` - Simple derivative approximation
#' - `$high_pass_filter()` - Remove DC drift
#' - `$to_sound()` - Convert back to generic Sound object
#'
#' ## The Derivative (DEGG)
#'
#' The derivative of the EGG signal (DEGG) shows the rate of change of vocal fold
#' contact. The negative peak in DEGG typically corresponds to the instant of
#' glottal closure (GCI), which is important for voice source analysis.
#'
#' @examples
#' \dontrun{
#' # Extract EGG from channel 2
#' sound <- praat_read("recording_with_egg.wav")
#' egg <- sound$extract_electroglottogram(2)
#'
#' # Remove DC drift
#' egg_filtered <- egg$high_pass_filter(from_freq = 100, smoothing = 100)
#'
#' # Get closed glottis intervals
#' tg <- egg_filtered$to_textgrid_closed_glottis(
#'   pitch_floor = 75,
#'   pitch_ceiling = 300,
#'   closing_threshold = 0.3
#' )
#'
#' # Calculate derivative (DEGG) for finding closure instants
#' degg <- egg$derivative(lowpass_freq = 5000, smoothing = 100)
#' }
#'
#' @export
Electroglottogram <- R6::R6Class(
  "Electroglottogram",
  inherit = Sound,

  public = list(
    #' @description
    #' Create an Electroglottogram object (internal use)
    #' @param .xptr External pointer to C++ Electroglottogram object
    #' @return A new Electroglottogram object
    initialize = function(.xptr = NULL) {
      if (is.null(.xptr)) {
        stop("Electroglottogram objects must be created using sound$extract_electroglottogram() or electroglottogram_create()")
      }
      super$initialize(.xptr)
    },

    #' @description
    #' Detect closed glottis intervals and return as TextGrid
    #' @param pitch_floor Minimum pitch in Hz (default 75)
    #' @param pitch_ceiling Maximum pitch in Hz (default 500)
    #' @param closing_threshold Fraction of peak-valley range for closure (default 0.3)
    #' @param peak_threshold Peak threshold fraction (default 0.05)
    #' @return TextGrid object with closed glottis intervals marked
    to_textgrid_closed_glottis = function(pitch_floor = 75,
                                          pitch_ceiling = 500,
                                          closing_threshold = 0.3,
                                          peak_threshold = 0.05) {
      ptr <- electroglottogram_to_textgrid_closed_glottis_cpp(
        self$.pointer,
        pitch_floor,
        pitch_ceiling,
        closing_threshold,
        peak_threshold
      )
      TextGrid$new(.xptr = ptr)
    },

    #' @description
    #' Extract amplitude level tiers (peak, valley, and closing levels)
    #' @param pitch_floor Minimum pitch in Hz (default 75)
    #' @param pitch_ceiling Maximum pitch in Hz (default 500)
    #' @param closing_threshold Fraction of peak-valley range for closure (default 0.3)
    #' @return List with three AmplitudeTier objects: levels, peaks, valleys
    to_amplitude_tier_levels = function(pitch_floor = 75,
                                        pitch_ceiling = 500,
                                        closing_threshold = 0.3) {
      result_list <- electroglottogram_to_amplitude_tier_levels_cpp(
        self$.pointer,
        pitch_floor,
        pitch_ceiling,
        closing_threshold
      )
      # Convert external pointers to AmplitudeTier objects
      list(
        levels = AmplitudeTier(.xptr = result_list$levels),
        peaks = AmplitudeTier(.xptr = result_list$peaks),
        valleys = AmplitudeTier(.xptr = result_list$valleys)
      )
    },

    #' @description
    #' Calculate the derivative (DEGG) of the EGG signal
    #' @param lowpass_freq Low-pass frequency in Hz (default 5000)
    #' @param smoothing Smoothing frequency in Hz (default 100)
    #' @param peak_amplitude New absolute peak value (0 = don't scale) (default 0)
    #' @return Sound object containing the derivative
    derivative = function(lowpass_freq = 5000,
                         smoothing = 100,
                         peak_amplitude = 0) {
      ptr <- electroglottogram_derivative_cpp(
        self$.pointer,
        lowpass_freq,
        smoothing,
        peak_amplitude
      )
      Sound$new(.xptr = ptr)
    },

    #' @description
    #' Calculate first central difference approximation of derivative
    #' @param peak_amplitude New absolute peak value (0 = don't scale) (default 0)
    #' @return Sound object containing the approximate derivative
    first_central_difference = function(peak_amplitude = 0) {
      ptr <- electroglottogram_first_central_difference_cpp(
        self$.pointer,
        peak_amplitude
      )
      Sound$new(.xptr = ptr)
    },

    #' @description
    #' Apply high-pass filter to remove DC drift
    #' @param from_freq Low frequency cutoff in Hz (default 100)
    #' @param smoothing Smoothing frequency in Hz (default 100)
    #' @return Filtered Electroglottogram object
    high_pass_filter = function(from_freq = 100, smoothing = 100) {
      ptr <- electroglottogram_high_pass_filter_cpp(
        self$.pointer,
        from_freq,
        smoothing
      )
      Electroglottogram$new(.xptr = ptr)
    },

    #' @description
    #' Convert to generic Sound object
    #' @return Sound object
    to_sound = function() {
      ptr <- electroglottogram_to_sound_cpp(self$.pointer)
      Sound$new(.xptr = ptr)
    }
  )
)

#' Create an Electroglottogram object
#'
#' @param xmin Start time in seconds
#' @param xmax End time in seconds
#' @param nx Number of samples
#' @param dx Sampling period in seconds
#' @param x1 Time of first sample in seconds
#' @return Electroglottogram object
#' @export
electroglottogram_create <- function(xmin, xmax, nx, dx, x1) {
  ptr <- electroglottogram_create_cpp(xmin, xmax, nx, dx, x1)
  Electroglottogram$new(.xptr = ptr)
}

#' Add extract_electroglottogram method to Sound class
#'
#' This is added as a method to the existing Sound R6 class during package load
#' @name Sound
NULL
