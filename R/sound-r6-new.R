#' @title Praat Sound Object
#' @description
#' R6 class representing a Praat Sound object. Wraps a Praat C++ Sound
#' object with automatic memory management via external pointers.
#'
#' @details
#' A Sound object represents a sampled acoustic waveform with one or more channels.
#' This class provides methods for reading, creating, querying, and transforming
#' sound data using Praat's underlying C implementation.
#'
#' ## Creating Sound Objects
#'
#' - `Sound$new(path)` - Read from file (WAV, AIFF, etc.)
#' - `Sound$from_values(values, sampling_rate)` - Create from numeric matrix
#' - `Sound$create_tone(duration, frequency, ...)` - Generate pure tone
#'
#' ## Querying
#'
#' Query methods return properties of the sound:
#' - `$get_duration()` - Duration in seconds
#' - `$get_sampling_frequency()` - Sampling rate in Hz
#' - `$get_number_of_samples()` - Number of samples
#' - `$get_number_of_channels()` - Number of channels
#' - `$get_value_at_time(time, channel)` - Amplitude at specific time
#' - `$get_rms(from, to)` - RMS amplitude
#' - `$get_energy(from, to)` - Total energy
#' - `$get_power(from, to)` - Average power
#' - `$get_intensity_db()` - Intensity in decibels
#'
#' ## Transformation
#'
#' Transformation methods create new Praat objects:
#' - `$to_pitch(...)` - Extract pitch contour (returns Pitch object)
#' - `$to_formant_burg(...)` - Extract formants (returns Formant object)
#' - `$to_intensity(...)` - Extract intensity contour (returns Intensity object)
#' - `$to_harmonicity_cc(...)` - Compute HNR (returns Harmonicity object)
#' - `$to_spectrogram(...)` - Create spectrogram (returns Spectrogram object)
#' - `$to_spectrum(...)` - Compute spectrum (returns Spectrum object)
#'
#' ## Export
#'
#' Export methods convert to R data structures:
#' - `$as_data_frame()` - Long-format data frame (time, channel, value)
#' - `$as_matrix()` - Matrix with channels as rows, samples as columns
#' - `$save(path, format)` - Write to audio file
#'
#' @examples
#' \dontrun{
#' # Read sound file
#' sound <- Sound$new("recording.wav")
#'
#' # Query properties
#' duration <- sound$get_duration()
#' sr <- sound$get_sampling_frequency()
#'
#' # Extract features
#' pitch <- sound$to_pitch()
#' formants <- sound$to_formant_burg()
#' intensity <- sound$to_intensity()
#'
#' # Export to R
#' df <- sound$as_data_frame()
#'
#' # Create synthetic sound
#' tone <- Sound$create_tone(duration = 1.0, frequency = 440)
#' tone$save("A440.wav")
#' }
#'
#' @export
Sound <- R6::R6Class(
  "Sound",
  inherit = PraatObject,
  
  public = list(
    
    #' @description
    #' Create a Sound object from file
    #' @param path Path to audio file (WAV, AIFF, NeXT/Sun, NIST, FLAC)
    #' @param .xptr Internal use only - external pointer to C++ Sound object
    #' @return A new Sound object
    initialize = function(path = NULL, .xptr = NULL) {
      if (!is.null(.xptr)) {
        super$initialize(.xptr)
      } else if (!is.null(path)) {
        if (!file.exists(path)) {
          stop("Sound file not found: ", path)
        }
        ptr <- .sound_read_from_file(path)
        super$initialize(ptr)
      } else {
        stop("Must provide either path or .xptr")
      }
    },
    
    # ========================================================================
    # Query Methods
    # ========================================================================
    
    #' @description Get duration in seconds
    #' @return Numeric duration in seconds
    get_duration = function() {
      .sound_get_duration(private$ptr)
    },
    
    #' @description Get sampling frequency in Hz
    #' @return Numeric sampling frequency
    get_sampling_frequency = function() {
      .sound_get_sampling_frequency(private$ptr)
    },
    
    #' @description Get number of samples
    #' @return Integer number of samples
    get_number_of_samples = function() {
      .sound_get_number_of_samples(private$ptr)
    },
    
    #' @description Get number of channels
    #' @return Integer number of channels
    get_number_of_channels = function() {
      .sound_get_number_of_channels(private$ptr)
    },
    
    #' @description Get amplitude value at specific time
    #' @param time Time in seconds
    #' @param channel Channel number (1-based, default: 1)
    #' @return Numeric amplitude value
    get_value_at_time = function(time, channel = 1) {
      .sound_get_value_at_time(private$ptr, time, channel)
    },
    
    #' @description Get root-mean-square amplitude
    #' @param from_time Start time in seconds (default: beginning)
    #' @param to_time End time in seconds (default: end)
    #' @return Numeric RMS value
    get_rms = function(from_time = 0.0, to_time = 0.0) {
      .sound_get_rms(private$ptr, from_time, to_time)
    },
    
    #' @description Get total energy
    #' @param from_time Start time in seconds (default: beginning)
    #' @param to_time End time in seconds (default: end)
    #' @return Numeric energy value
    get_energy = function(from_time = 0.0, to_time = 0.0) {
      .sound_get_energy(private$ptr, from_time, to_time)
    },
    
    #' @description Get average power
    #' @param from_time Start time in seconds (default: beginning)
    #' @param to_time End time in seconds (default: end)
    #' @return Numeric power value
    get_power = function(from_time = 0.0, to_time = 0.0) {
      .sound_get_power(private$ptr, from_time, to_time)
    },
    
    #' @description Get intensity in decibels (dB SPL)
    #' @return Numeric intensity in dB
    get_intensity_db = function() {
      .sound_get_intensity_db(private$ptr)
    },
    
    # ========================================================================
    # Transformation Methods (return new objects)
    # ========================================================================
    
    #' @description Extract pitch contour
    #' @param time_step Time step in seconds (0 = auto)
    #' @param pitch_floor Minimum pitch in Hz (default: 75)
    #' @param pitch_ceiling Maximum pitch in Hz (default: 600)
    #' @return Pitch object
    to_pitch = function(time_step = 0.0, pitch_floor = 75.0, pitch_ceiling = 600.0) {
      pitch_ptr <- .sound_to_pitch(private$ptr, time_step, pitch_floor, pitch_ceiling)
      Pitch$new(.xptr = pitch_ptr)
    },
    
    #' @description Extract formants using Burg's method
    #' @param time_step Time step in seconds (default: 0.005)
    #' @param max_formants Maximum number of formants (default: 5)
    #' @param max_frequency Maximum formant frequency in Hz (default: 5500)
    #' @param window_length Window length in seconds (default: 0.025)
    #' @param pre_emphasis_from Pre-emphasis frequency in Hz (default: 50)
    #' @return Formant object
    to_formant_burg = function(
      time_step = 0.005,
      max_formants = 5.0,
      max_frequency = 5500.0,
      window_length = 0.025,
      pre_emphasis_from = 50.0
    ) {
      formant_ptr <- .sound_to_formant_burg(
        private$ptr,
        time_step,
        max_formants,
        max_frequency,
        window_length,
        pre_emphasis_from
      )
      Formant$new(.xptr = formant_ptr)
    },
    
    #' @description Extract intensity contour
    #' @param minimum_pitch Minimum pitch for accurate intensity (default: 100 Hz)
    #' @param time_step Time step in seconds (0 = auto)
    #' @param subtract_mean Subtract mean intensity (default: TRUE)
    #' @return Intensity object
    to_intensity = function(
      minimum_pitch = 100.0,
      time_step = 0.0,
      subtract_mean = TRUE
    ) {
      intensity_ptr <- .sound_to_intensity(
        private$ptr,
        minimum_pitch,
        time_step,
        subtract_mean
      )
      Intensity$new(.xptr = intensity_ptr)
    },
    
    #' @description Compute harmonics-to-noise ratio (autocorrelation method)
    #' @param time_step Time step in seconds (default: 0.01)
    #' @param min_pitch Minimum pitch in Hz (default: 75)
    #' @param silence_threshold Silence threshold (default: 0.1)
    #' @param periods_per_window Periods per window (default: 1.0)
    #' @return Harmonicity object
    to_harmonicity_ac = function(
      time_step = 0.01,
      min_pitch = 75.0,
      silence_threshold = 0.1,
      periods_per_window = 1.0
    ) {
      hnr_ptr <- .harmonicity_to_sound_ac(
        private$ptr,
        time_step,
        min_pitch,
        silence_threshold,
        periods_per_window
      )
      Harmonicity$new(.xptr = hnr_ptr)
    },
    
    #' @description Compute harmonics-to-noise ratio (cross-correlation method)
    #' @param time_step Time step in seconds (default: 0.01)
    #' @param min_pitch Minimum pitch in Hz (default: 75)
    #' @param silence_threshold Silence threshold (default: 0.1)
    #' @param periods_per_window Periods per window (default: 1.0)
    #' @return Harmonicity object
    to_harmonicity_cc = function(
      time_step = 0.01,
      min_pitch = 75.0,
      silence_threshold = 0.1,
      periods_per_window = 1.0
    ) {
      hnr_ptr <- .harmonicity_to_sound_cc(
        private$ptr,
        time_step,
        min_pitch,
        silence_threshold,
        periods_per_window
      )
      Harmonicity$new(.xptr = hnr_ptr)
    },
    
    #' @description Create spectrogram
    #' @param window_length Window length in seconds (default: 0.005)
    #' @param maximum_frequency Maximum frequency in Hz (default: 5000)
    #' @param time_step Time step in seconds (default: 0.002)
    #' @param frequency_step Frequency step in Hz (default: 20)
    #' @param window_shape Window shape: "Gaussian" (default), "Square", "Hamming", "Bartlett", "Welch", "Hanning"
    #' @return Spectrogram object
    to_spectrogram = function(
      window_length = 0.005,
      maximum_frequency = 5000.0,
      time_step = 0.002,
      frequency_step = 20.0,
      window_shape = c("Gaussian", "Square", "Hamming", "Bartlett", "Welch", "Hanning")
    ) {
      window_shape <- match.arg(window_shape)
      window_shape_int <- switch(
        window_shape,
        "Square" = 1,
        "Hamming" = 2,
        "Bartlett" = 3,
        "Welch" = 4,
        "Hanning" = 5,
        "Gaussian" = 6,
        6  # Default to Gaussian
      )
      
      spec_ptr <- .sound_to_spectrogram(
        private$ptr,
        window_length,
        maximum_frequency,
        time_step,
        frequency_step,
        window_shape_int
      )
      Spectrogram$new(.xptr = spec_ptr)
    },
    
    #' @description Compute frequency spectrum
    #' @param fast Use fast FFT (default: TRUE)
    #' @return Spectrum object
    to_spectrum = function(fast = TRUE) {
      spectrum_ptr <- .sound_to_spectrum(private$ptr, fast)
      Spectrum$new(.xptr = spectrum_ptr)
    },
    
    # ========================================================================
    # Export Methods
    # ========================================================================
    
    #' @description Export as data frame
    #' @return data.frame with columns: time, channel, value
    as_data_frame = function() {
      .sound_as_data_frame(private$ptr)
    },
    
    #' @description Export as matrix
    #' @return Numeric matrix with channels as rows, samples as columns
    as_matrix = function() {
      .sound_as_matrix(private$ptr)
    },
    
    #' @description Save to audio file
    #' @param path Output file path
    #' @param format File format: "WAV" (default), "AIFF", "AIFC", "NeXT", "NIST", "FLAC"
    save = function(
      path,
      format = c("WAV", "AIFF", "AIFC", "NeXT", "NIST", "FLAC")
    ) {
      format <- match.arg(format)
      format_int <- switch(
        format,
        "WAV" = 0,
        "AIFF" = 1,
        "AIFC" = 2,
        "NeXT" = 3,
        "NIST" = 4,
        "FLAC" = 5,
        0  # Default to WAV
      )
      
      .sound_save(private$ptr, path, format_int)
      invisible(self)
    },
    
    # ========================================================================
    # Print Method
    # ========================================================================
    
    #' @description Print Sound object
    print = function() {
      if (!self$is_valid()) {
        cat("<Sound [invalid]>\n")
        return(invisible(self))
      }
      
      cat("<Praat Sound>\n")
      cat(sprintf("  Duration: %.3f s\n", self$get_duration()))
      cat(sprintf("  Sampling frequency: %.0f Hz\n", self$get_sampling_frequency()))
      cat(sprintf("  Number of samples: %d\n", self$get_number_of_samples()))
      cat(sprintf("  Number of channels: %d\n", self$get_number_of_channels()))
      
      # Show intensity if available
      intensity_db <- tryCatch(
        self$get_intensity_db(),
        error = function(e) NA
      )
      if (!is.na(intensity_db)) {
        cat(sprintf("  Intensity: %.1f dB\n", intensity_db))
      }
      
      invisible(self)
    }
  )
)

# ============================================================================
# Static Factory Methods
# ============================================================================

#' @rdname Sound
#' @description Create Sound from numeric values
#' @param values Numeric matrix with channels as rows, samples as columns (or vector for mono)
#' @param sampling_rate Sampling rate in Hz (default: 44100)
#' @export
Sound$from_values <- function(values, sampling_rate = 44100) {
  # Convert vector to matrix if needed
  if (is.vector(values)) {
    values <- matrix(values, nrow = 1)
  }
  
  if (!is.matrix(values)) {
    stop("values must be a numeric vector or matrix")
  }
  
  ptr <- .sound_create_from_values(values, sampling_rate)
  Sound$new(.xptr = ptr)
}

#' @rdname Sound
#' @description Create a pure tone
#' @param duration Duration in seconds (default: 1.0)
#' @param frequency Frequency in Hz (default: 440)
#' @param sampling_rate Sampling rate in Hz (default: 44100)
#' @param amplitude Amplitude 0-1 (default: 0.99)
#' @export
Sound$create_tone <- function(
  duration = 1.0,
  frequency = 440.0,
  sampling_rate = 44100,
  amplitude = 0.99
) {
  ptr <- .sound_create_tone(duration, sampling_rate, frequency, amplitude)
  Sound$new(.xptr = ptr)
}
