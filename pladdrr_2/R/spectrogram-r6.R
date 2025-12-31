#' Spectrogram Object
#'
#' @description
#' Praat Spectrogram object with direct C++ module binding. Spectrograms provide
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
Spectrogram <- function(.xptr = NULL) {
  if (is.null(.xptr)) {
    stop("Spectrogram objects must be created from Sound$to_spectrogram()")
  }
  
  # Load module
  spectrogram_mod <- get_module("spectrogram_module")
  cpp_obj <- spectrogram_mod$RSpectrogram$new(.xptr)
  
  obj <- structure(list(
    .cpp = cpp_obj,
    .xptr = .xptr,
    
    # Time domain
    get_start_time = function() {
      cpp_obj$get_xmin()
    },
    
    get_end_time = function() {
      cpp_obj$get_xmax()
    },
    
    get_time_step = function() {
      cpp_obj$get_time_step()
    },
    
    get_number_of_time_bins = function() {
      cpp_obj$get_number_of_frames()
    },
    
    # Frequency domain
    get_lowest_frequency = function() {
      cpp_obj$get_ymin()
    },
    
    get_highest_frequency = function() {
      cpp_obj$get_ymax()
    },
    
    get_frequency_step = function() {
      cpp_obj$get_frequency_step()
    },
    
    get_number_of_frequency_bins = function() {
      cpp_obj$get_number_of_frequency_bins()
    },
    
    # Conversion
    get_time_from_frame = function(frame) {
      cpp_obj$get_time_from_frame(as.integer(frame))
    },
    
    get_frame_from_time = function(time) {
      cpp_obj$get_frame_from_time(as.numeric(time))
    },
    
    get_frequency_from_bin = function(bin) {
      cpp_obj$get_frequency_from_bin(as.integer(bin))
    },
    
    get_bin_from_frequency = function(frequency) {
      cpp_obj$get_bin_from_frequency(as.numeric(frequency))
    },
    
    # Query
    get_power_at = function(time, frequency) {
      cpp_obj$get_power_at(as.numeric(time), as.numeric(frequency))
    },
    
    # Transform
    to_spectrum = function(time) {
      spectrum_ptr <- cpp_obj$to_spectrum_ptr(as.numeric(time))
      Spectrum(.xptr = spectrum_ptr)
    },
    
    # Export
    as_matrix = function() {
      .spectrogram_as_matrix(.xptr)
    },
    
    as_data_frame = function() {
      mat <- obj$as_matrix()
      n_time <- cpp_obj$get_nx()
      n_freq <- cpp_obj$get_ny()
      
      times <- vapply(seq_len(n_time), function(i) obj$get_time_from_frame(i), numeric(1))
      freqs <- vapply(seq_len(n_freq), function(i) obj$get_frequency_from_bin(i), numeric(1))
      
      # Long format
      df <- expand.grid(time = times, frequency = freqs)
      df$power <- as.vector(t(mat))
      df
    },
    
    # Display
    print = function() {
      cat("<Praat Spectrogram>\n")
      cat(sprintf("  Time: %.3f - %.3f s (%d bins, step %.4f s)\n",
                  cpp_obj$get_xmin(), cpp_obj$get_xmax(),
                  cpp_obj$get_nx(), cpp_obj$get_dx()))
      cat(sprintf("  Frequency: %.2f - %.2f Hz (%d bins, step %.2f Hz)\n",
                  cpp_obj$get_ymin(), cpp_obj$get_ymax(),
                  cpp_obj$get_ny(), cpp_obj$get_dy()))
      invisible(obj)
    }
    
  ), class = c("Spectrogram", "PraatObject"))
  
  obj
}

# S3 methods
#' @export
print.Spectrogram <- function(x, ...) {
  x$print()
}

#' @export
as.data.frame.Spectrogram <- function(x, ...) {
  x$as_data_frame()
}
