#' @title Praat LPC Object
#' @description
#' R6 class representing a Praat LPC (Linear Predictive Coding) object.
#' LPC provides a parametric representation of the spectral envelope using
#' linear prediction coefficients.
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
#' sound <- Sound$new("audio.wav")
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
LPC <- R6::R6Class(
  "LPC",
  inherit = PraatObject,
  
  public = list(
    
    #' @description
    #' Create a new LPC object (internal use only)
    #' @param .xptr External pointer to C++ LPC object
    #' @return A new LPC object
    initialize = function(.xptr = NULL) {
      if (is.null(.xptr)) {
        stop("LPC objects must be created from a Sound object using sound$to_lpc_burg() or similar methods")
      }
      if (!inherits(.xptr, "externalptr")) {
        stop(".xptr must be an external pointer")
      }
      private$ptr <- .xptr
    },
    
    # ========================================================================
    # Query methods - Basic properties
    # ========================================================================
    
    #' @description Get the number of analysis frames
    #' @return Integer number of frames
    get_number_of_frames = function() {
      .lpc_get_number_of_frames(private$ptr)
    },
    
    #' @description Get the time step between frames
    #' @return Time step in seconds
    get_time_step = function() {
      .lpc_get_time_step(private$ptr)
    },
    
    #' @description Get the sampling period of the original sound
    #' @return Sampling period in seconds
    get_sampling_period = function() {
      .lpc_get_sampling_period(private$ptr)
    },
    
    #' @description Get the maximum number of LPC coefficients
    #' @return Integer maximum number of coefficients
    get_max_num_coefficients = function() {
      .lpc_get_max_num_coefficients(private$ptr)
    },
    
    # ========================================================================
    # Query methods - LPC values
    # ========================================================================
    
    #' @description Get gain value at specific frame
    #' @param frame_number Frame number (1-based)
    #' @return Gain value
    get_gain_at_frame = function(frame_number) {
      .lpc_get_gain_at_frame(private$ptr, as.integer(frame_number))
    },
    
    #' @description Get LPC coefficients at specific frame
    #' @param frame_number Frame number (1-based)
    #' @return Numeric vector of LPC coefficients
    get_coefficients_at_frame = function(frame_number) {
      .lpc_get_coefficients_at_frame(private$ptr, as.integer(frame_number))
    },
    
    #' @description Get all gain values across all frames
    #' @return Numeric vector of gain values
    get_all_gains = function() {
      .lpc_get_all_gains(private$ptr)
    },
    
    #' @description Get all LPC coefficients as a matrix
    #' @return Numeric matrix (coefficients × frames)
    get_all_coefficients = function() {
      .lpc_get_all_coefficients(private$ptr)
    },
    
    # ========================================================================
    # Conversion methods
    # ========================================================================
    
    #' @description Convert LPC to Formant object (DISABLED)
    #' @param margin Safety margin for formant extraction (Hz)
    #' @return A new Formant object
    #' @note This method is disabled in this build to avoid CLAPACK dependency.
    #'   Use Sound$to_formant_burg() for formant extraction instead.
    to_formant = function(margin = 50.0) {
      stop("LPC$to_formant() is not available in this build (requires CLAPACK).\n",
           "Use Sound$to_formant_burg() for formant extraction instead.")
    },
    
    #' @description Convert LPC to Spectrum at specific time
    #' @param time Time point (seconds) at which to extract spectrum
    #' @param df_min Minimum frequency resolution (Hz)
    #' @param bandwidth_reduction Bandwidth reduction factor
    #' @param de_emphasis_frequency De-emphasis frequency (Hz)
    #' @return A new Spectrum object
    to_spectrum = function(
      time,
      df_min = 20.0,
      bandwidth_reduction = 0.0,
      de_emphasis_frequency = 50.0
    ) {
      spectrum_ptr <- .lpc_to_spectrum(
        private$ptr,
        time,
        df_min,
        bandwidth_reduction,
        de_emphasis_frequency
      )
      Spectrum$new(.xptr = spectrum_ptr)
    },
    
    #' @description Convert LPC coefficients to Matrix object
    #' @return A new Matrix object containing LPC coefficients
    to_matrix = function() {
      matrix_ptr <- .lpc_to_matrix(private$ptr)
      Matrix$new(.xptr = matrix_ptr)
    },
    
    # ========================================================================
    # Inverse Filtering - Voice Source Extraction
    # ========================================================================
    
    #' @description Extract voice source via inverse filtering
    #' Applies LPC inverse filtering to remove vocal tract resonances from the
    #' speech signal, leaving the glottal flow waveform (voice source).
    #' This is fundamental for voice source analysis and vocal fold dynamics research.
    #' 
    #' Corresponds to Praat: To Sound (inverse filter)
    #' 
    #' @param sound Sound object to filter
    #' @return A new Sound object containing the extracted voice source (glottal flow)
    #' 
    #' @details
    #' The inverse filter applies the formula: E(z) = X(z)A(z), where:
    #' - X(z) is the input speech signal
    #' - A(z) is the LPC filter (1 + sum of a_k * z^-k)
    #' - E(z) is the output excitation signal (voice source)
    #' 
    #' This removes the vocal tract resonances (formants) from the speech signal,
    #' revealing the glottal flow waveform. The result can be used for:
    #' - Glottal flow analysis
    #' - Voice quality assessment
    #' - Vocal fold dynamics research
    #' - Source-filter separation
    #' 
    #' @examples
    #' \dontrun{
    #' # Load speech
    #' sound <- Sound$new("vowel.wav")
    #' 
    #' # Compute LPC
    #' lpc <- sound$to_lpc_burg(
    #'   prediction_order = 16,
    #'   analysis_width = 0.025,
    #'   time_step = 0.005,
    #'   pre_emphasis_frequency = 50.0
    #' )
    #' 
    #' # Extract voice source
    #' glottal_flow <- lpc$filter_inverse(sound)
    #' 
    #' # Save result
    #' glottal_flow$save("glottal_flow.wav")
    #' }
    filter_inverse = function(sound) {
      if (!inherits(sound, "Sound")) {
        stop("sound must be a Sound object")
      }
      
      source_ptr <- .lpc_sound_filter_inverse_r6(private$ptr, sound)
      Sound$new(.xptr = source_ptr)
    },
    
    #' @description Extract voice source using filter at specific time
    #' Similar to filter_inverse() but uses the LPC filter coefficients from
    #' a single time point for the entire signal. Useful for stationary signals.
    #' 
    #' Corresponds to Praat: To Sound (inverse filter, at time)
    #' 
    #' @param sound Sound object to filter
    #' @param time Time point (seconds) at which to extract LPC filter
    #' @param channel Channel number (1 for mono or left, 2 for right)
    #' @return A new Sound object containing the extracted voice source
    #' 
    #' @details
    #' Instead of using time-varying LPC coefficients, this method extracts
    #' the filter at a single time point and applies it to the entire signal.
    #' This is appropriate when:
    #' - The signal is relatively stationary (e.g., sustained vowel)
    #' - You want a consistent filter across the entire signal
    #' - Comparing different analysis time points
    #' 
    #' @examples
    #' \dontrun{
    #' # Extract voice source using filter at vowel midpoint
    #' sound <- Sound$new("vowel.wav")
    #' lpc <- sound$to_lpc_burg(prediction_order = 16)
    #' 
    #' midpoint <- sound$get_duration() / 2
    #' glottal_flow <- lpc$filter_inverse_at_time(sound, time = midpoint)
    #' }
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
        private$ptr,
        sound$get_xptr(),
        as.integer(channel),
        as.numeric(time)
      )
      Sound$new(.xptr = source_ptr)
    },
    
    # ========================================================================
    # Print method
    # ========================================================================
    
    #' @description Print LPC object information
    #' @param ... Additional arguments (ignored)
    print = function(...) {
      cat("Praat LPC object\n")
      cat("  Number of frames:", self$get_number_of_frames(), "\n")
      cat("  Time step:", self$get_time_step(), "seconds\n")
      cat("  Max coefficients:", self$get_max_num_coefficients(), "\n")
      cat("  Sampling period:", self$get_sampling_period(), "seconds\n")
      invisible(self)
    }
  )
)
