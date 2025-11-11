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
#' - `Sound$new(path)` - Read from file (any format via av/FFmpeg: MP3, WAV, FLAC, OGG, etc.)
#' - `Sound$from_values(values, sampling_rate)` - Create from numeric matrix
#' - `Sound$from_matrix(matrix, sampling_rate)` - Alias for from_values
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
#' - `$to_manipulation(...)` - Create manipulation for pitch/duration modification (returns Manipulation object)
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
#' # Read sound file (any format supported by av/FFmpeg)
#' sound <- Sound$new("recording.mp3")
#' sound_wav <- Sound$new("recording.wav")
#'
#' # Create from R matrix (e.g., from av package)
#' library(av)
#' audio_matrix <- t(av::read_audio_fft("audio.mp3", window = NULL, overlap = 0))
#' sound <- Sound$from_matrix(audio_matrix, sampling_rate = 44100)
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
    #' Create a Sound object from file or data
    #' @param path Path to audio file (any format supported by av/FFmpeg)
    #' @param .xptr Internal use only - external pointer to C++ Sound object
    #' @param use_av Use av package for loading (default: TRUE for non-WAV files)
    #' @return A new Sound object
    initialize = function(path = NULL, .xptr = NULL, use_av = NULL) {
      if (!is.null(.xptr)) {
        super$initialize(.xptr)
      } else if (!is.null(path)) {
        if (!file.exists(path)) {
          stop("Sound file not found: ", path)
        }
        
        # Determine if we should use av
        if (is.null(use_av)) {
          # Auto-detect: use av for non-WAV files
          ext <- tolower(tools::file_ext(path))
          use_av <- !(ext %in% c("wav", "aiff", "aif", "aifc"))
        }
        
        if (use_av) {
          # Load via av package
          if (!requireNamespace("av", quietly = TRUE)) {
            stop("Package 'av' is required for loading this audio format. Install it with: install.packages('av')")
          }
          
          # Read audio using av
          audio_info <- av::av_media_info(path)
          audio_data <- av::read_audio_fft(path, window = NULL, overlap = 0)
          
          # av returns samples × channels matrix, we need channels × samples
          if (is.matrix(audio_data)) {
            audio_data <- t(audio_data)
          } else {
            # Single channel vector
            audio_data <- matrix(audio_data, nrow = 1)
          }
          
          # Create Sound from matrix
          sampling_rate <- audio_info$audio$sample_rate
          ptr <- .sound_create_from_values(audio_data, sampling_rate)
          super$initialize(ptr)
        } else {
          # Use Praat's native file reading
          ptr <- .sound_read_from_file(path)
          super$initialize(ptr)
        }
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
    
    #' @description Extract formants using keep-all method
    #' @param time_step Time step in seconds (default: 0.005)
    #' @param max_formants Maximum number of formants to track (default: 5)
    #' @param max_frequency Maximum formant frequency in Hz (default: 5500)
    #' @param window_length Window length in seconds (default: 0.025)
    #' @param pre_emphasis_from Pre-emphasis frequency in Hz (default: 50)
    #' @return Formant object
    to_formant_keepall = function(
      time_step = 0.005,
      max_formants = 5.0,
      max_frequency = 5500.0,
      window_length = 0.025,
      pre_emphasis_from = 50.0
    ) {
      formant_ptr <- .formant_from_sound_keepall(
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
    
    #' @description Convert to Spectrum (FFT)
    #' @param fast Use fast FFT (rounds to power of 2, default: TRUE)
    #' @return Spectrum object
    to_spectrum = function(fast = TRUE) {
      spectrum_ptr <- .sound_to_spectrum(private$ptr, fast)
      Spectrum$new(.xptr = spectrum_ptr)
    },
    
    #' @description Create long-term average spectrum (Ltas)
    #' Corresponds to Praat: To Ltas: bandwidth
    #' @param bandwidth Frequency smoothing bandwidth in Hz (default: 100)
    #' @return Ltas object
    to_ltas = function(bandwidth = 100.0) {
      ltas_ptr <- .sound_to_ltas(private$ptr, bandwidth)
      Ltas$new(.xptr = ltas_ptr)
    },
    
    #' @description Create time-frequency spectrogram
    #' @param window_length Analysis window length in seconds (default: 0.005)
    #' @param max_frequency Maximum frequency to analyze in Hz (default: 5000)
    #' @param time_step Time step between frames in seconds (default: 0.002)
    #' @param frequency_step Frequency resolution in Hz (default: 20)
    #' @param window_shape Window shape: "square", "Hamming", "Bartlett", "Welch", "Hanning", "Gaussian" (default: "Gaussian")
    #' @return Spectrogram object
    to_spectrogram = function(
      window_length = 0.005,
      max_frequency = 5000.0,
      time_step = 0.002,
      frequency_step = 20.0,
      window_shape = "Gaussian"
    ) {
      spectrogram_ptr <- .sound_to_spectrogram(
        private$ptr,
        window_length,
        max_frequency,
        time_step,
        frequency_step,
        window_shape
      )
      Spectrogram$new(.xptr = spectrogram_ptr)
    },
    
    #' @description Create Manipulation for pitch/duration modification
    #' @param time_step Time step for pitch analysis (default: 0.01, 0 = auto)
    #' @param pitch_floor Minimum pitch in Hz (default: 75)
    #' @param pitch_ceiling Maximum pitch in Hz (default: 600)
    #' @return Manipulation object
    to_manipulation = function(
      time_step = 0.01,
      pitch_floor = 75.0,
      pitch_ceiling = 600.0
    ) {
      manip_ptr <- .manipulation_from_sound(
        private$ptr,
        time_step,
        pitch_floor,
        pitch_ceiling
      )
      Manipulation$new(.xptr = manip_ptr)
    },
    
    #' @description Extract glottal pulses using cross-correlation method
    #' @param time_step Time step in seconds (0 = auto: 0.75 / pitch_floor)
    #' @param pitch_floor Minimum pitch in Hz (default: 75)
    #' @param pitch_ceiling Maximum pitch in Hz (default: 600)
    #' @param max_period_factor Maximum period factor for pitch analysis (default: 1.3)
    #' @param max_amplitude_factor Maximum amplitude factor for pitch analysis (default: 1.6)
    #' @return PointProcess object containing glottal pulse times
    to_point_process_periodic_cc = function(
      time_step = 0.0,
      pitch_floor = 75.0,
      pitch_ceiling = 600.0,
      max_period_factor = 1.3,
      max_amplitude_factor = 1.6
    ) {
      pp_ptr <- .sound_to_point_process_periodic_cc(
        private$ptr,
        time_step,
        pitch_floor,
        pitch_ceiling,
        max_period_factor,
        max_amplitude_factor
      )
      PointProcess$new(.xptr = pp_ptr)
    },
    
    #' @description Extract peaks (positive extrema) from sound
    #' @param channel Channel number (1-based, default: 1)
    #' @param include_maxima Include positive peaks (default: TRUE)
    #' @param include_minima Include negative peaks (default: FALSE)
    #' @param interpolation Interpolation method: "None", "Parabolic", "Cubic", "Sinc70", "Sinc700"
    #' @return PointProcess object containing peak times
    to_point_process_extrema = function(
      channel = 1,
      include_maxima = TRUE,
      include_minima = FALSE,
      interpolation = c("None", "Parabolic", "Cubic", "Sinc70", "Sinc700")
    ) {
      interpolation <- match.arg(interpolation)
      interpolation_int <- switch(
        interpolation,
        "None" = 0,
        "Parabolic" = 1,
        "Cubic" = 2,
        "Sinc70" = 3,
        "Sinc700" = 4,
        1  # Default to parabolic
      )
      
      pp_ptr <- .sound_to_point_process_extrema(
        private$ptr,
        as.integer(channel),
        as.logical(include_maxima),
        as.logical(include_minima),
        interpolation_int
      )
      PointProcess$new(.xptr = pp_ptr)
    },
    
    #' @description Extract zero crossings from sound
    #' @param channel Channel number (1-based, default: 1)
    #' @param include_raisers Include positive-going zero crossings (default: TRUE)
    #' @param include_fallers Include negative-going zero crossings (default: FALSE)
    #' @return PointProcess object containing zero crossing times
    to_point_process_zeros = function(
      channel = 1,
      include_raisers = TRUE,
      include_fallers = FALSE
    ) {
      pp_ptr <- .sound_to_point_process_zeros(
        private$ptr,
        as.integer(channel),
        as.logical(include_raisers),
        as.logical(include_fallers)
      )
      PointProcess$new(.xptr = pp_ptr)
    },
    
    # ========================================================================
    # Extraction Methods
    # ========================================================================
    
    #' @description Extract a specific channel
    #' @param channel Channel number (1 for mono or left, 2 for right)
    #' @return New Sound object with extracted channel
    extract_channel = function(channel = 1) {
      private$check_valid()
      if (!is.numeric(channel) || channel < 1) {
        stop("channel must be a positive integer")
      }
      sound_ptr <- .sound_extract_channel(private$ptr, as.integer(channel))
      Sound$new(.xptr = sound_ptr)
    },
    
    #' @description Extract part of sound by time
    #' @param from_time Start time in seconds
    #' @param to_time End time in seconds
    #' @param window_shape Window shape: "rectangular", "hamming", "bartlett", "welch", "hanning"
    #' @param relative_width Relative width of window (default: 1.0)
    #' @param preserve_times Keep original time domain (default: FALSE)
    #' @return New Sound object with extracted part
    extract_part = function(
      from_time,
      to_time,
      window_shape = c("rectangular", "hamming", "bartlett", "welch", "hanning"),
      relative_width = 1.0,
      preserve_times = FALSE
    ) {
      private$check_valid()
      
      window_shape <- match.arg(window_shape)
      window_shape_int <- switch(
        window_shape,
        "rectangular" = 0,
        "hamming" = 1,
        "bartlett" = 2,
        "welch" = 3,
        "hanning" = 4,
        0
      )
      
      sound_ptr <- .sound_extract_part(
        private$ptr,
        from_time,
        to_time,
        window_shape_int,
        relative_width,
        preserve_times
      )
      Sound$new(.xptr = sound_ptr)
    },
    
    # ========================================================================
    # Modification Methods (in-place)
    # ========================================================================
    
    #' @description Scale intensity to target dB level
    #' @param new_intensity_db Target intensity in dB
    #' @return Self (invisibly) for method chaining
    scale_intensity = function(new_intensity_db) {
      private$check_valid()
      .sound_scale_intensity(private$ptr, new_intensity_db)
      invisible(self)
    },
    
    #' @description Scale peak amplitude
    #' @param new_peak Target peak amplitude (default: 0.99)
    #' @return Self (invisibly) for method chaining
    scale_peak = function(new_peak = 0.99) {
      private$check_valid()
      .sound_scale_peak(private$ptr, new_peak)
      invisible(self)
    },
    
    #' @description Apply pre-emphasis filter (high-pass)
    #' @param from_frequency Frequency from which to start pre-emphasis in Hz (default: 50)
    #' @return Self (invisibly) for method chaining
    pre_emphasize = function(from_frequency = 50.0) {
      private$check_valid()
      .sound_pre_emphasize(private$ptr, from_frequency)
      invisible(self)
    },
    
    #' @description Apply de-emphasis filter (low-pass)
    #' @param from_frequency Frequency from which to start de-emphasis in Hz (default: 50)
    #' @return Self (invisibly) for method chaining
    de_emphasize = function(from_frequency = 50.0) {
      private$check_valid()
      .sound_de_emphasize(private$ptr, from_frequency)
      invisible(self)
    },
    
    # ========================================================================
    # Advanced Modification Methods (return new Sound)
    # ========================================================================
    
    #' @description Resample to different sampling frequency
    #' @param new_frequency New sampling frequency in Hz
    #' @param precision Number of samples per zero crossing (50 = high quality, 1 = fast)
    #' @return New Sound object with resampled waveform
    resample = function(new_frequency, precision = 50) {
      private$check_valid()
      if (new_frequency <= 0) {
        stop("new_frequency must be positive")
      }
      sound_ptr <- .sound_resample(private$ptr, new_frequency, as.integer(precision))
      Sound$new(.xptr = sound_ptr)
    },
    
    #' @description Convert to mono by averaging all channels
    #' @return New Sound object with single channel
    convert_to_mono = function() {
      private$check_valid()
      if (self$get_number_of_channels() == 1) {
        message("Sound is already mono, returning copy")
      }
      sound_ptr <- .sound_convert_to_mono(private$ptr)
      Sound$new(.xptr = sound_ptr)
    },
    
    #' @description Convert mono sound to stereo by duplicating channel
    #' @return New Sound object with two identical channels
    convert_to_stereo = function() {
      private$check_valid()
      if (self$get_number_of_channels() > 1) {
        warning("Sound is already multi-channel, returning as-is")
        sound_ptr <- .sound_copy(private$ptr)
      } else {
        sound_ptr <- .sound_convert_to_stereo(private$ptr)
      }
      Sound$new(.xptr = sound_ptr)
    },
    
    #' @description Concatenate with another sound sequentially
    #' @param other_sound Sound object to append
    #' @param overlap Overlap duration in seconds (default: 0)
    #' @return New Sound object with concatenated audio
    concatenate = function(other_sound, overlap = 0) {
      private$check_valid()
      if (!inherits(other_sound, "Sound")) {
        stop("other_sound must be a Sound object")
      }
      if (!other_sound$is_valid()) {
        stop("other_sound is not a valid Sound object")
      }
      sound_ptr <- .sound_concatenate(
        private$ptr,
        other_sound$.__enclos_env__$private$ptr,
        overlap
      )
      Sound$new(.xptr = sound_ptr)
    },
    
    #' @description Mix (add) with another sound
    #' @param other_sound Sound object to mix with
    #' @param balance Mixing balance: 1 = equal mix, <1 = more of self, >1 = more of other
    #' @return New Sound object with mixed audio
    mix = function(other_sound, balance = 1.0) {
      private$check_valid()
      if (!inherits(other_sound, "Sound")) {
        stop("other_sound must be a Sound object")
      }
      if (!other_sound$is_valid()) {
        stop("other_sound is not a valid Sound object")
      }
      sound_ptr <- .sound_mix(
        private$ptr,
        other_sound$.__enclos_env__$private$ptr,
        balance
      )
      Sound$new(.xptr = sound_ptr)
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
#' @description Alias for from_values (matching av workflow)
#' @export
Sound$from_matrix <- Sound$from_values

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
