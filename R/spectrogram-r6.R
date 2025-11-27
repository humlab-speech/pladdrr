#' Spectrogram R6 Class
#'
#' @description
#' An R6 class representing a Praat Spectrogram object. Spectrograms provide
#' time-frequency representations of sounds, showing how spectral content
#' varies over time.
#'
#' @details
#' The Spectrogram class wraps Praat's Spectrogram object, providing access to
#' time-frequency analysis. Spectrograms are typically created from Sound objects
#' using the `to_spectrogram()` method.
#'
#' @examples
#' \dontrun{
#' # Create a sound and compute spectrogram
#' snd <- Sound$new("audio.wav")
#' spec <- snd$to_spectrogram(window_length = 0.005, maximum_frequency = 5000)
#' 
#' # Query spectral properties
#' power <- spec$get_power_at(time = 0.5, frequency = 1000)
#' 
#' # Get time-frequency dimensions
#' tmin <- spec$get_start_time()
#' tmax <- spec$get_end_time()
#' fmin <- spec$get_lowest_frequency()
#' fmax <- spec$get_highest_frequency()
#' }
#'
#' @export
Spectrogram <- R6::R6Class("Spectrogram",
  public = list(
    #' @field .xptr External pointer to Praat Spectrogram object
    .xptr = NULL,
    
    #' @description
    #' Create a new Spectrogram object
    #' @param .xptr External pointer from C++ (internal use)
    #' @return A new Spectrogram object
    initialize = function(.xptr = NULL) {
      if (is.null(.xptr)) {
        stop("Spectrogram objects must be created from Sound$to_spectrogram()")
      }
      private$ptr <- .xptr
    },
    
    # ---- TIME/FREQUENCY DOMAIN QUERIES ----
    
    #' @description Get the start time of the spectrogram
    #' @return Start time in seconds
    get_start_time = function() {
      .spectrogram_get_start_time(private$ptr)
    },
    
    #' @description Get the end time of the spectrogram
    #' @return End time in seconds
    get_end_time = function() {
      .spectrogram_get_end_time(private$ptr)
    },
    
    #' @description Get the time step between frames
    #' @return Time step in seconds
    get_time_step = function() {
      .spectrogram_get_time_step(private$ptr)
    },
    
    #' @description Get the number of time frames
    #' @return Number of frames
    get_number_of_time_bins = function() {
      .spectrogram_get_number_of_time_bins(private$ptr)
    },
    
    #' @description Get the lowest frequency
    #' @return Minimum frequency in Hz
    get_lowest_frequency = function() {
      .spectrogram_get_lowest_frequency(private$ptr)
    },
    
    #' @description Get the highest frequency
    #' @return Maximum frequency in Hz
    get_highest_frequency = function() {
      .spectrogram_get_highest_frequency(private$ptr)
    },
    
    #' @description Get the frequency step
    #' @return Frequency step in Hz
    get_frequency_step = function() {
      .spectrogram_get_frequency_step(private$ptr)
    },
    
    #' @description Get the number of frequency bins
    #' @return Number of frequency bins
    get_number_of_frequency_bins = function() {
      .spectrogram_get_number_of_frequency_bins(private$ptr)
    },
    
    # ---- CONVERSION METHODS ----
    
    #' @description Get time from frame index
    #' @param frame Frame number (1-indexed)
    #' @return Time in seconds
    get_time_from_frame = function(frame) {
      .spectrogram_get_time_from_frame(private$ptr, frame)
    },
    
    #' @description Get frequency from bin index
    #' @param bin Frequency bin number (1-indexed)
    #' @return Frequency in Hz
    get_frequency_from_bin = function(bin) {
      .spectrogram_get_frequency_from_bin(private$ptr, bin)
    },
    
    # ---- QUERY METHODS ----
    
    #' @description Get power at specific time and frequency
    #' @param time Time in seconds
    #' @param frequency Frequency in Hz
    #' @return Power spectral density (Pa²/Hz)
    get_power_at = function(time, frequency) {
      .spectrogram_get_power_at(private$ptr, time, frequency)
    },
    
    # ---- TRANSFORMATION METHODS ----
    
    #' @description Extract spectrum at a specific time
    #' @param time Time in seconds
    #' @return A Spectrum object
    to_spectrum = function(time) {
      spectrum_ptr <- .spectrogram_to_spectrum(private$ptr, time)
      Spectrum$new(.xptr = spectrum_ptr)
    },
    
    # ---- EXPORT METHODS ----
    
    #' @description Convert to R matrix (time × frequency)
    #' @return Numeric matrix with power values
    as_matrix = function() {
      .spectrogram_as_matrix(private$ptr)
    },
    
    #' @description Convert to data frame
    #' @return Data frame with columns: time, frequency, power
    as_data_frame = function() {
      mat <- self$as_matrix()
      n_times <- self$get_number_of_time_bins()
      n_freqs <- self$get_number_of_frequency_bins()
      
      times <- numeric(n_times)
      for (i in seq_len(n_times)) {
        times[i] <- self$get_time_from_frame(i)
      }
      
      freqs <- numeric(n_freqs)
      for (i in seq_len(n_freqs)) {
        freqs[i] <- self$get_frequency_from_bin(i)
      }
      
      # Convert to long format
      df <- expand.grid(
        time = times,
        frequency = freqs,
        KEEP.OUT.ATTRS = FALSE,
        stringsAsFactors = FALSE
      )
      df$power <- as.vector(t(mat))  # mat is freq × time, transpose for time × freq
      
      df
    },
    
    # ---- PRINT METHOD ----
    
    #' @description Print spectrogram information
    print = function() {
      cat("<Praat Spectrogram>\n")
      cat(sprintf("  Time domain: %.3f to %.3f s\n", 
                  self$get_start_time(), self$get_end_time()))
      cat(sprintf("  Time frames: %d (step = %.4f s)\n",
                  self$get_number_of_time_bins(), self$get_time_step()))
      cat(sprintf("  Frequency domain: %.1f to %.1f Hz\n",
                  self$get_lowest_frequency(), self$get_highest_frequency()))
      cat(sprintf("  Frequency bins: %d (step = %.2f Hz)\n",
                  self$get_number_of_frequency_bins(), self$get_frequency_step()))
      invisible(self)
    }
  ),
  
  # ---- ACTIVE BINDINGS ----
  active = list(
    #' @field start_time Start time (read-only)
    start_time = function() self$get_start_time(),
    
    #' @field end_time End time (read-only)
    end_time = function() self$get_end_time(),
    
    #' @field n_times Number of time bins (read-only)
    n_times = function() self$get_number_of_time_bins(),
    
    #' @field n_freqs Number of frequency bins (read-only)
    n_freqs = function() self$get_number_of_frequency_bins()
  )
)
