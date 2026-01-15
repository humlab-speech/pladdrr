#' @title Praat LPC Object
#' @description
#' Praat LPC object with direct C++ module binding for linear predictive coding analysis.
#'
#' @details
#' LPC (Linear Predictive Coding) is a method for estimating the spectral
#' envelope of a sound by modeling it as an autoregressive process. The LPC
#' coefficients describe the vocal tract filter and can be converted to
#' formants, spectra, or other representations.
#'
#' ## Creating LPC Objects
#'
#' LPC objects are created from Sound objects using one of several methods:
#' - `sound$to_lpc_burg()` - Burg method (fastest, most robust)
#' - `sound$to_lpc_auto()` - Autocorrelation method
#' - `sound$to_lpc_covariance()` - Covariance method
#' - `sound$to_lpc_marple()` - Marple method (slowest, most accurate)
#'
#' ## Querying LPC Properties
#'
#' - `$get_number_of_frames()` - Number of analysis frames
#' - `$get_time_step()` - Time step between frames
#' - `$get_sampling_period()` - Sampling period of original sound
#' - `$get_max_num_coefficients()` - Maximum number of LPC coefficients
#' - `$get_gain_at_frame(frame)` - Gain value for specific frame
#' - `$get_coefficients_at_frame(frame)` - LPC coefficients for specific frame
#' - `$get_all_gains()` - Vector of all gain values
#' - `$get_all_coefficients()` - Matrix of all LPC coefficients
#'
#' ## Converting to Other Objects
#'
#' - `$to_formant(margin)` - Convert to Formant object
#' - `$to_spectrum(time, ...)` - Convert to Spectrum at specific time
#' - `$to_matrix()` - Convert to Matrix object
#'
#' ## Voice Source Extraction (Inverse Filtering)
#'
#' - `$filter_inverse(sound)` - Extract glottal flow by inverse filtering
#' - `$filter_inverse_at_time(sound, time, channel)` - Use filter from specific time
#'
#' These methods remove vocal tract resonances to reveal the voice source (glottal
#' flow waveform). Essential for voice quality research and vocal fold dynamics.
#'
#' @examples
#' \dontrun{
#' # Load sound
#' sound <- Sound("audio.wav")
#'
#' # Compute LPC (Burg method is recommended)
#' lpc <- sound$to_lpc_burg(
#'   prediction_order = 16,
#'   analysis_width = 0.025,
#'   time_step = 0.005,
#'   pre_emphasis_frequency = 50.0
#' )
#'
#' # Query properties
#' n_frames <- lpc$get_number_of_frames()
#' gains <- lpc$get_all_gains()
#' coeffs <- lpc$get_all_coefficients()
#'
#' # Get coefficients for specific frame
#' coef_frame10 <- lpc$get_coefficients_at_frame(10)
#'
#' # Convert to other representations
#' spectrum <- lpc$to_spectrum(time = 0.5, df_min = 20)
#' 
#' # Extract voice source (glottal flow) via inverse filtering
#' glottal_flow <- lpc$filter_inverse(sound)
#' 
#' # Or use filter from a specific time (e.g., vowel midpoint)
#' midpoint <- sound$get_duration() / 2
#' glottal_flow_fixed <- lpc$filter_inverse_at_time(sound, time = midpoint)
#' }
#'
#' @export
LPC <- function(.xptr = NULL) {
  if (is.null(.xptr)) {
    stop("LPC objects must be created from a Sound object using sound$to_lpc_burg() or similar methods")
  }
  
  lpc_mod <- get_module("lpc_module")
  cpp_obj <- lpc_mod$RLPC$new(.xptr)
  
  obj <- structure(list(
    .cpp = cpp_obj,
    .xptr = .xptr,  # Keep for legacy exports
    
    # Query - Basic properties
    get_number_of_frames = function() {
      cpp_obj$get_number_of_frames()
    },
    
    get_time_step = function() {
      cpp_obj$get_time_step()
    },
    
    get_sampling_period = function() {
      cpp_obj$get_sampling_period()
    },
    
    get_max_num_coefficients = function() {
      cpp_obj$get_max_num_coefficients()
    },
    
    # Query - LPC values
    get_gain_at_frame = function(frame_number) {
      cpp_obj$get_gain_at_frame(as.integer(frame_number))
    },
    
    get_coefficients_at_frame = function(frame_number) {
      cpp_obj$get_coefficients_at_frame(as.integer(frame_number))
    },
    
    get_all_gains = function() {
      cpp_obj$get_all_gains()
    },
    
    get_all_coefficients = function() {
      cpp_obj$get_all_coefficients()
    },
    
    # Conversion methods
    to_formant = function(margin = 50.0) {
      stop("LPC$to_formant() is not available in this build (requires CLAPACK).\n",
           "Use Sound$to_formant_burg() for formant extraction instead.")
    },
    
    to_spectrum = function(
      time,
      df_min = 20.0,
      bandwidth_reduction = 0.0,
      de_emphasis_frequency = 50.0
    ) {
      spectrum_ptr <- .lpc_to_spectrum(
        .xptr,
        time,
        df_min,
        bandwidth_reduction,
        de_emphasis_frequency
      )
      Spectrum(.xptr = spectrum_ptr)
    },
    
    to_matrix = function() {
      matrix_ptr <- .lpc_to_matrix(.xptr)
      Matrix(.xptr = matrix_ptr)
    },

    # LFCC extraction (Linear Frequency Cepstral Coefficients)
    to_lfcc = function(num_coefficients = 12) {
      mfcc_mod <- get_module("mfcc_module")
      lfcc_ptr <- mfcc_mod$LPC_to_LFCC(.xptr, as.integer(num_coefficients))
      LFCC(.xptr = lfcc_ptr)
    },

    # Inverse Filtering - Voice Source Extraction
    filter_inverse = function(sound) {
      if (!inherits(sound, "Sound")) {
        stop("sound must be a Sound object")
      }
      
      source_ptr <- .lpc_sound_filter_inverse_r6(.xptr, sound)
      Sound(.xptr = source_ptr)
    },
    
    filter_inverse_at_time = function(sound, time, channel = 1) {
      if (!inherits(sound, "Sound")) {
        stop("sound must be a Sound object")
      }
      if (!is.numeric(time) || length(time) != 1) {
        stop("time must be a single numeric value")
      }
      if (!is.numeric(channel) || length(channel) != 1 || channel < 1) {
        stop("channel must be a positive integer")
      }
      
      source_ptr <- .lpc_sound_filter_inverse_at_time(
        .xptr,
        sound$get_xptr(),
        as.integer(channel),
        as.numeric(time)
      )
      Sound(.xptr = source_ptr)
    },
    
    # Utility methods
    get_xptr = function() {
      .xptr
    },
    
    # Display
    print = function() {
      cat("<Praat LPC>\n")
      cat(sprintf("  Number of frames: %d\n", cpp_obj$get_number_of_frames()))
      cat(sprintf("  Time step: %.6f s\n", cpp_obj$get_time_step()))
      cat(sprintf("  Max coefficients: %d\n", cpp_obj$get_max_num_coefficients()))
      cat(sprintf("  Sampling period: %.6f s\n", cpp_obj$get_sampling_period()))
      invisible(obj)
    }
    
  ), class = c("LPC", "PraatObject"))
  
  obj
}

#' @export
print.LPC <- function(x, ...) {
  x$print()
}
