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
Electroglottogram <- function(.xptr = NULL) {
  if (is.null(.xptr)) {
    stop("Electroglottogram objects must be created using sound$extract_electroglottogram() or electroglottogram_create()")
  }
  
  # Load Rcpp Module
  egg_mod <- get_module("electroglottogram_module")
  cpp_egg <- egg_mod$RElectroglottogram$new(.xptr)
  
  # Create wrapper
  egg <- structure(list(
    .cpp = cpp_egg,
    .xptr = .xptr,
    .pointer = .xptr,  # For Sound compatibility
    
    # Query methods (inherited from Sound via module)
    get_xmin = function() cpp_egg$get_xmin(),
    get_xmax = function() cpp_egg$get_xmax(),
    get_duration = function() cpp_egg$get_duration(),
    get_nx = function() cpp_egg$get_nx(),
    get_dx = function() cpp_egg$get_dx(),
    get_x1 = function() cpp_egg$get_x1(),
    get_number_of_samples = function() cpp_egg$get_number_of_samples(),
    get_sample_period = function() cpp_egg$get_sample_period(),
    get_sample_rate = function() cpp_egg$get_sample_rate(),
    get_value_at_sample = function(sample) cpp_egg$get_value_at_sample(as.integer(sample)),
    get_value_at_time = function(time) cpp_egg$get_value_at_time(as.numeric(time)),
    get_time_from_sample = function(sample) cpp_egg$get_time_from_sample(as.integer(sample)),
    get_sample_from_time = function(time) cpp_egg$get_sample_from_time(as.numeric(time)),
    is_valid = function() cpp_egg$is_valid(),
    
    # @description
    # Detect closed glottis intervals and return as TextGrid
    # @param pitch_floor Minimum pitch in Hz (default 75)
    # @param pitch_ceiling Maximum pitch in Hz (default 500)
    # @param closing_threshold Fraction of peak-valley range for closure (default 0.3)
    # @param peak_threshold Peak threshold fraction (default 0.05)
    # @return TextGrid object with closed glottis intervals marked
    to_textgrid_closed_glottis = function(pitch_floor = 75,
                                          pitch_ceiling = 500,
                                          closing_threshold = 0.3,
                                          peak_threshold = 0.05) {
      ptr <- cpp_egg$to_textgrid_closed_glottis_ptr(
        as.numeric(pitch_floor),
        as.numeric(pitch_ceiling),
        as.numeric(closing_threshold),
        as.numeric(peak_threshold)
      )
      TextGrid(.xptr = ptr)
    },
    
    # @description
    # Extract amplitude level tiers (peak, valley, and closing levels)
    # @param pitch_floor Minimum pitch in Hz (default 75)
    # @param pitch_ceiling Maximum pitch in Hz (default 500)
    # @param closing_threshold Fraction of peak-valley range for closure (default 0.3)
    # @return List with three AmplitudeTier objects: levels, peaks, valleys
    to_amplitude_tier_levels = function(pitch_floor = 75,
                                        pitch_ceiling = 500,
                                        closing_threshold = 0.3) {
      result_list <- cpp_egg$to_amplitude_tier_levels(
        as.numeric(pitch_floor),
        as.numeric(pitch_ceiling),
        as.numeric(closing_threshold)
      )
      # Convert external pointers to AmplitudeTier objects
      list(
        levels = AmplitudeTier(.xptr = result_list$levels),
        peaks = AmplitudeTier(.xptr = result_list$peaks),
        valleys = AmplitudeTier(.xptr = result_list$valleys)
      )
    },
    
    # @description
    # Calculate the derivative (DEGG) of the EGG signal
    # @param lowpass_freq Low-pass frequency in Hz (default 5000)
    # @param smoothing Smoothing frequency in Hz (default 100)
    # @param peak_amplitude New absolute peak value (0 = don't scale) (default 0)
    # @return Sound object containing the derivative
    derivative = function(lowpass_freq = 5000,
                         smoothing = 100,
                         peak_amplitude = 0) {
      ptr <- cpp_egg$derivative_ptr(
        as.numeric(lowpass_freq),
        as.numeric(smoothing),
        as.numeric(peak_amplitude)
      )
      Sound(.xptr = ptr)
    },
    
    # @description
    # Calculate first central difference approximation of derivative
    # @param peak_amplitude New absolute peak value (0 = don't scale) (default 0)
    # @return Sound object containing the approximate derivative
    first_central_difference = function(peak_amplitude = 0) {
      ptr <- cpp_egg$first_central_difference_ptr(as.numeric(peak_amplitude))
      Sound(.xptr = ptr)
    },
    
    # @description
    # Apply high-pass filter to remove DC drift
    # @param from_freq Low frequency cutoff in Hz (default 100)
    # @param smoothing Smoothing frequency in Hz (default 100)
    # @return Filtered Electroglottogram object
    high_pass_filter = function(from_freq = 100, smoothing = 100) {
      ptr <- cpp_egg$high_pass_filter_ptr(
        as.numeric(from_freq),
        as.numeric(smoothing)
      )
      Electroglottogram(.xptr = ptr)
    },
    
    # @description
    # Convert to generic Sound object
    # @return Sound object
    to_sound = function() {
      ptr <- cpp_egg$to_sound_ptr()
      Sound(.xptr = ptr)
    },
    
    # Export methods
    as_vector = function() cpp_egg$as_vector(),
    as_data_frame = function() cpp_egg$as_data_frame(),
    get_info = function() cpp_egg$get_info(),
    save = function(path) cpp_egg$save(as.character(path)),
    get_xptr = function() .xptr,
    
    print = function() {
      info <- cpp_egg$get_info()
      cat("<Praat Electroglottogram>\n")
      cat(sprintf("  Duration: %.3f s\n", cpp_egg$get_duration()))
      cat(sprintf("  Samples: %d\n", cpp_egg$get_number_of_samples()))
      cat(sprintf("  Sample rate: %.1f Hz\n", cpp_egg$get_sample_rate()))
      invisible(egg)
    }
  ), class = c("Electroglottogram", "Sound", "PraatObject"))
  
  egg
}

#' @export
print.Electroglottogram <- function(x, ...) x$print()

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
  Electroglottogram(.xptr = ptr)
}

# extract_electroglottogram is added as a method to the Sound wrapper during package load
