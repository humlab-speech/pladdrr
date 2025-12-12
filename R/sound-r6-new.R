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
#' **File I/O**: All file operations use the `av` package (humlab-speech/av fork)
#' which supports a wide range of audio and video formats via FFmpeg, including:
#' WAV, MP3, FLAC, OGG, AAC, M4A, WMA, AIFF, and many more.
#'
#' ## Creating Sound Objects
#'
#' - `Sound$new(path)` - Read from file (any format via av/FFmpeg: MP3, WAV, FLAC, OGG, etc.)
#' - `Sound$from_values(values, sampling_rate)` - Create from numeric matrix
#' - `Sound$from_matrix(matrix, sampling_rate)` - Alias for from_values
#' - `Sound$create_tone(duration, sampling_rate, frequency, ...)` - Generate pure tone
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
#' - `$to_pitch_ac(...)` - Extract pitch with autocorrelation and full voicing parameters (returns Pitch object)
#' - `$to_pitch_cc(...)` - Extract pitch with cross-correlation and full voicing parameters (returns Pitch object)
#' - `$to_formant_burg(...)` - Extract formants using Burg's method (returns Formant object)
#' - `$to_formant_keepall(...)` - Extract formants, keep all (returns Formant object)
#' - `$to_formant_willems(...)` - Extract formants using Willems method (returns Formant object)
#' - `$to_formant_sl(...)` - Extract formants using Split-Levinson method (returns Formant object)
#' - `$to_intensity(...)` - Extract intensity contour (returns Intensity object)
#' - `$to_harmonicity_cc(...)` - Compute HNR (returns Harmonicity object)
#' - `$to_spectrogram(...)` - Create spectrogram (returns Spectrogram object)
#' - `$to_spectrum(...)` - Compute spectrum (returns Spectrum object)
#' - `$to_manipulation(...)` - Create manipulation for pitch/duration modification (returns Manipulation object)
#' - `$to_textgrid_silences(...)` - Detect silences and create annotated TextGrid (returns TextGrid object)
#'
#' ## Export
#'
#' Export methods convert to R data structures or save to files:
#' - `$as_data_frame()` - Long-format data frame (time, channel, value)
#' - `$as_matrix()` - Matrix with channels as rows, samples as columns
#' - `$save(path, format, ...)` - Write to audio file (any format supported by av/FFmpeg)
#'
#' @examples
#' \dontrun{
#' # Read sound file (any format supported by av/FFmpeg)
#' sound <- Sound$new("recording.mp3")
#' sound_wav <- Sound$new("recording.wav")
#' sound_flac <- Sound$new("recording.flac")
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
#' formants <- sound$to_formant_burg()        # Standard Burg's method
#' formants_w <- sound$to_formant_willems()   # Willems method (better for synthesis)
#' formants_sl <- sound$to_formant_sl()       # Split-Levinson (alternative algorithm)
#' intensity <- sound$to_intensity()
#'
#' # Export to R
#' df <- sound$as_data_frame()
#'
#' # Save to various formats
#' sound$save("output.wav")
#' sound$save("output.mp3", format = "mp3")
#' sound$save("output.flac", format = "flac")
#'
#' # Create synthetic sound
#' tone <- Sound$create_tone(duration = 1.0, sampling_rate = 44100, frequency = 440)
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
    #' @param path Path to audio file (native: WAV/AIFF/NIST, fallback: any av/FFmpeg format)
    #' @param .xptr Internal use only - external pointer to C++ Sound object
    #' @return A new Sound object
    initialize = function(path = NULL, .xptr = NULL) {
      if (!is.null(.xptr)) {
        super$initialize(.xptr)
      } else if (!is.null(path)) {
        if (!file.exists(path)) {
          stop("Sound file not found: ", path)
        }
        
        # Try native Praat reader first (fast path for common formats)
        ptr <- tryCatch({
          .sound_read_from_file_native(path)
        }, error = function(e) {
          # Native failed - fallback to av package for exotic formats
          if (!requireNamespace("av", quietly = TRUE)) {
            stop("Native reader failed and 'av' package not available.\n",
                 "Install av: remotes::install_github('humlab-speech/av')\n",
                 "Native error: ", e$message)
          }
          
          # Read audio using av
          audio_info <- av::av_media_info(path)
          audio_data <- av::read_audio_bin(path)
          
          # Normalize PCM integers to [-1, 1] range
          max_value <- max(abs(audio_data))
          if (max_value > 0) {
            audio_data <- audio_data / max_value
          }
          
          # av returns samples × channels matrix, we need channels × samples
          if (is.matrix(audio_data)) {
            audio_data <- t(audio_data)
          } else {
            audio_data <- matrix(audio_data, nrow = 1)
          }
          
          # Create Sound from matrix
          sampling_rate <- audio_info$audio$sample_rate
          .sound_create_from_values(audio_data, sampling_rate)
        })
        
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

    to_powercepstrogram_MOVED = function(pitch_floor = 60.0, time_step = 0.002, maximum_frequency = 5000.0, pre_emphasis_frequency = 50.0) {
      pcep_ptr <- .sound_to_powercepstrogram(private$ptr, pitch_floor, time_step, maximum_frequency, pre_emphasis_frequency)
      PowerCepstrogram$new(.xptr = pcep_ptr)
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
    #' @param interpolation Interpolation method: "nearest", "linear", "cubic", "sinc70", "sinc700" (default: "linear")
    #' @return Numeric amplitude value
    get_value_at_time = function(time, channel = 1, interpolation = "linear") {
      .sound_get_value_at_time(private$ptr, time, channel, interpolation)
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
    
    #' @description Extract pitch using autocorrelation with full voicing parameters
    #' @param time_step Time step in seconds (0 = auto) (default: 0.0)
    #' @param pitch_floor Minimum pitch in Hz (default: 75)
    #' @param pitch_ceiling Maximum pitch in Hz (default: 600)
    #' @param max_candidates Maximum number of pitch candidates (default: 15)
    #' @param very_accurate Use accurate algorithm (slower) (default: FALSE)
    #' @param silence_threshold Silence threshold relative to max amplitude (default: 0.03)
    #' @param voicing_threshold Voicing threshold (default: 0.45)
    #' @param octave_cost Cost for octave jumps (default: 0.01)
    #' @param octave_jump_cost Cost for octave jumps between frames (default: 0.35)
    #' @param voiced_unvoiced_cost Cost for voicing changes (default: 0.14)
    #' @return Pitch object
    to_pitch_ac = function(
      time_step = 0.0,
      pitch_floor = 75.0,
      pitch_ceiling = 600.0,
      max_candidates = 15,
      very_accurate = FALSE,
      silence_threshold = 0.03,
      voicing_threshold = 0.45,
      octave_cost = 0.01,
      octave_jump_cost = 0.35,
      voiced_unvoiced_cost = 0.14
    ) {
      pitch_ptr <- .sound_to_pitch_ac(
        private$ptr,
        time_step,
        pitch_floor,
        pitch_ceiling,
        as.integer(max_candidates),
        very_accurate,
        silence_threshold,
        voicing_threshold,
        octave_cost,
        octave_jump_cost,
        voiced_unvoiced_cost
      )
      Pitch$new(.xptr = pitch_ptr)
    },
    
    #' @description Extract pitch using cross-correlation with full voicing parameters
    #' @param time_step Time step in seconds (0 = auto) (default: 0.0)
    #' @param pitch_floor Minimum pitch in Hz (default: 75)
    #' @param pitch_ceiling Maximum pitch in Hz (default: 600)
    #' @param max_candidates Maximum number of pitch candidates (default: 15)
    #' @param very_accurate Use accurate algorithm (slower) (default: FALSE)
    #' @param silence_threshold Silence threshold relative to max amplitude (default: 0.03)
    #' @param voicing_threshold Voicing threshold (default: 0.45)
    #' @param octave_cost Cost for octave jumps (default: 0.01)
    #' @param octave_jump_cost Cost for octave jumps between frames (default: 0.35)
    #' @param voiced_unvoiced_cost Cost for voicing changes (default: 0.14)
    #' @return Pitch object
    to_pitch_cc = function(
      time_step = 0.0,
      pitch_floor = 75.0,
      pitch_ceiling = 600.0,
      max_candidates = 15,
      very_accurate = FALSE,
      silence_threshold = 0.03,
      voicing_threshold = 0.45,
      octave_cost = 0.01,
      octave_jump_cost = 0.35,
      voiced_unvoiced_cost = 0.14
    ) {
      pitch_ptr <- .sound_to_pitch_cc(
        private$ptr,
        time_step,
        pitch_floor,
        pitch_ceiling,
        as.integer(max_candidates),
        very_accurate,
        silence_threshold,
        voicing_threshold,
        octave_cost,
        octave_jump_cost,
        voiced_unvoiced_cost
      )
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
    
    #' @description Extract formants using Willems method
    #' @details The Willems method is optimized for extracting a specific
    #'   number of formants with more accurate bandwidth estimates. Better
    #'   suited for formant synthesis applications.
    #' @param time_step Time step in seconds (default: 0.005)
    #' @param number_of_formants Target number of formants (default: 5)
    #' @param max_frequency Maximum formant frequency in Hz (default: 5500)
    #' @param window_length Window length in seconds (default: 0.025)
    #' @param pre_emphasis_from Pre-emphasis frequency in Hz (default: 50)
    #' @return Formant object
    to_formant_willems = function(
      time_step = 0.005,
      number_of_formants = 5.0,
      max_frequency = 5500.0,
      window_length = 0.025,
      pre_emphasis_from = 50.0
    ) {
      formant_ptr <- .formant_from_sound_willems(
        private$ptr,
        time_step,
        number_of_formants,
        max_frequency,
        window_length,
        pre_emphasis_from
      )
      Formant$new(.xptr = formant_ptr)
    },
    
    #' @description Extract formants using Split-Levinson method
    #' @details The Split-Levinson (SL) method is an alternative to Burg's
    #'   algorithm with different numerical characteristics. Useful for
    #'   comparison and verification studies.
    #' @param time_step Time step in seconds (default: 0.005)
    #' @param number_of_poles Number of LPC poles (default: 10)
    #' @param max_frequency Maximum formant frequency in Hz (default: 5500)
    #' @param window_length Window length in seconds (default: 0.025)
    #' @param pre_emphasis_from Pre-emphasis frequency in Hz (default: 50)
    #' @return Formant object
    to_formant_sl = function(
      time_step = 0.005,
      number_of_poles = 10L,
      max_frequency = 5500.0,
      window_length = 0.025,
      pre_emphasis_from = 50.0
    ) {
      formant_ptr <- .formant_from_sound_sl(
        private$ptr,
        time_step,
        as.integer(number_of_poles),
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
    
    #' @description Detect silences and create TextGrid
    #' 
    #' Creates a TextGrid with one IntervalTier marking silent and sounding intervals.
    #' Uses intensity-based silence detection. Corresponds to Praat menu:
    #' Annotate > To TextGrid (silences)...
    #' 
    #' @param min_pitch Minimum pitch for intensity analysis (default: 100 Hz)
    #' @param time_step Time step for intensity analysis in seconds (0 = auto: 0.8 / min_pitch)
    #' @param silence_threshold Silence threshold in dB relative to maximum intensity (default: -25.0)
    #'   More negative = stricter silence detection (e.g., -35 dB detects only very quiet parts)
    #' @param min_silent_duration Minimum duration of silent intervals in seconds (default: 0.1)
    #'   Shorter silent periods are ignored
    #' @param min_sounding_duration Minimum duration of sounding intervals in seconds (default: 0.1)
    #'   Shorter sounding periods are ignored
    #' @param silent_label Label for silent intervals (default: "silent")
    #' @param sounding_label Label for sounding intervals (default: "sounding")
    #' @return TextGrid object with one tier containing silence/sound annotations
    #' 
    #' @details
    #' The function:
    #' 1. Converts Sound to Intensity using min_pitch and time_step
    #' 2. Finds maximum intensity value
    #' 3. Marks frames below (max_intensity + silence_threshold) as silent
    #' 4. Merges adjacent silent/sounding intervals
    #' 5. Removes intervals shorter than minimum durations
    #' 
    #' Critical for AVQI analysis where accurate silence detection affects quality metrics.
    #' 
    #' @examples
    #' \dontrun{
    #' # Detect silences with default parameters
    #' sound <- Sound$new("voice.wav")
    #' tg <- sound$to_textgrid_silences()
    #' 
    #' # Stricter silence detection for AVQI
    #' tg <- sound$to_textgrid_silences(
    #'   min_pitch = 75,
    #'   silence_threshold = -30.0,  # Only very quiet parts
    #'   min_silent_duration = 0.2,
    #'   min_sounding_duration = 0.3
    #' )
    #' }
    to_textgrid_silences = function(
      min_pitch = 100.0,
      time_step = 0.0,
      silence_threshold = -25.0,
      min_silent_duration = 0.1,
      min_sounding_duration = 0.1,
      silent_label = "silent",
      sounding_label = "sounding"
    ) {
      tg_ptr <- .sound_to_textgrid_silences(
        private$ptr,
        min_pitch,
        time_step,
        silence_threshold,
        min_silent_duration,
        min_sounding_duration,
        silent_label,
        sounding_label
      )
      TextGrid$new(.xptr = tg_ptr)
    },
    
    #' @description Create Cochleagram (auditory filterbank representation)
    #' Corresponds to Praat: To Cochleagram
    #' Models the basilar membrane response using Bark frequency scale.
    #' @param dt Time step in seconds (default: 0.01)
    #' @param df Frequency step in Bark (default: 0.1)
    #' @param window_length Analysis window length in seconds (default: 0.03)
    #' @param forward_masking_time Forward masking time constant in seconds (default: 0.03)
    #' @return Cochleagram object
    to_cochleagram = function(dt = 0.01, df = 0.1, window_length = 0.03, 
                              forward_masking_time = 0.03) {
      cochleagram_ptr <- .sound_to_cochleagram(
        private$ptr, dt, df, window_length, forward_masking_time
      )
      Cochleagram$new(.xptr = cochleagram_ptr)
    },
    
    #' @description Create Cochleagram using Ear-Drum-Brain model
    #' Corresponds to Praat: To Cochleagram (edb)
    #' More realistic auditory model including synaptic processing.
    #' @param dtime Time step in seconds (default: 0.01)
    #' @param dfreq Frequency step in Bark (default: 0.1)
    #' @param has_synapse Include synaptic processing (default: TRUE)
    #' @param replenishment_rate Neurotransmitter replenishment rate (default: 0.01)
    #' @param loss_rate Neurotransmitter loss rate (default: 0.1)
    #' @param return_rate Calcium return rate (default: 0.05)
    #' @param reprocessing_rate Reprocessing rate (default: 0.01)
    #' @return Cochleagram object
    to_cochleagram_edb = function(dtime = 0.01, dfreq = 0.1, has_synapse = TRUE,
                                   replenishment_rate = 0.01, loss_rate = 0.1,
                                   return_rate = 0.05, reprocessing_rate = 0.01) {
      cochleagram_ptr <- .sound_to_cochleagram_edb(
        private$ptr, dtime, dfreq, has_synapse, 
        replenishment_rate, loss_rate, return_rate, reprocessing_rate
      )
      Cochleagram$new(.xptr = cochleagram_ptr)
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
    
    to_power_cepstrogram_NEW = function(pitch_floor = 60.0, time_step = 0.002, maximum_frequency = 5000.0, pre_emphasis_frequency = 50.0) {
      pcep_ptr <- .sound_to_powercepstrogram(private$ptr, pitch_floor, time_step, maximum_frequency, pre_emphasis_frequency)
      PowerCepstrogram$new(.xptr = pcep_ptr)
    },

    to_powercepstrogram = function(pitch_floor = 60.0, time_step = 0.002, maximum_frequency = 5000.0, pre_emphasis_frequency = 50.0) {
      self$to_power_cepstrogram_NEW(pitch_floor, time_step, maximum_frequency, pre_emphasis_frequency)
    },
    
    #' @description
    #' Convert Sound to Cepstrum
    #' 
    #' Computes the complex cepstrum from the sound. This is different from
    #' PowerCepstrum - the Cepstrum is the inverse Fourier transform of the
    #' logarithm of the spectrum, preserving phase information.
    #' 
    #' @return Cepstrum object
    to_cepstrum = function() {
      xptr <- .sound_to_cepstrum(private$ptr)
      Cepstrum$new(xptr)
    },
    
    #' @description
    #' Convert Sound to bandwidth-weighted Cepstrum
    #' 
    #' Computes a bandwidth-weighted cepstrum, which applies additional
    #' weighting based on frequency bandwidth characteristics.
    #' 
    #' @return Cepstrum object
    to_cepstrum_bw = function() {
      xptr <- .sound_to_cepstrum_bw(private$ptr)
      Cepstrum$new(xptr)
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
    
    #' @description Compute Linear Predictive Coding (Burg method)
    #' @param prediction_order Number of LPC coefficients (default: 16)
    #' @param analysis_width Analysis window length in seconds (default: 0.025)
    #' @param time_step Time step between frames in seconds (default: 0.005)
    #' @param pre_emphasis_frequency Pre-emphasis frequency in Hz (default: 50)
    #' @return LPC object
    to_lpc_burg = function(
      prediction_order = 16,
      analysis_width = 0.025,
      time_step = 0.005,
      pre_emphasis_frequency = 50.0
    ) {
      lpc_ptr <- .sound_to_lpc_burg(
        private$ptr,
        as.integer(prediction_order),
        analysis_width,
        time_step,
        pre_emphasis_frequency
      )
      LPC$new(.xptr = lpc_ptr)
    },
    
    #' @description Compute Linear Predictive Coding (autocorrelation method)
    #' @param prediction_order Number of LPC coefficients (default: 16)
    #' @param analysis_width Analysis window length in seconds (default: 0.025)
    #' @param time_step Time step between frames in seconds (default: 0.005)
    #' @param pre_emphasis_frequency Pre-emphasis frequency in Hz (default: 50)
    #' @return LPC object
    to_lpc_auto = function(
      prediction_order = 16,
      analysis_width = 0.025,
      time_step = 0.005,
      pre_emphasis_frequency = 50.0
    ) {
      lpc_ptr <- .sound_to_lpc_auto(
        private$ptr,
        as.integer(prediction_order),
        analysis_width,
        time_step,
        pre_emphasis_frequency
      )
      LPC$new(.xptr = lpc_ptr)
    },
    
    #' @description Compute Linear Predictive Coding (covariance method)
    #' @param prediction_order Number of LPC coefficients (default: 16)
    #' @param analysis_width Analysis window length in seconds (default: 0.025)
    #' @param time_step Time step between frames in seconds (default: 0.005)
    #' @param pre_emphasis_frequency Pre-emphasis frequency in Hz (default: 50)
    #' @return LPC object
    to_lpc_covariance = function(
      prediction_order = 16,
      analysis_width = 0.025,
      time_step = 0.005,
      pre_emphasis_frequency = 50.0
    ) {
      lpc_ptr <- .sound_to_lpc_covariance(
        private$ptr,
        as.integer(prediction_order),
        analysis_width,
        time_step,
        pre_emphasis_frequency
      )
      LPC$new(.xptr = lpc_ptr)
    },
    
    #' @description Compute Linear Predictive Coding (Marple method)
    #' @param prediction_order Number of LPC coefficients (default: 16)
    #' @param analysis_width Analysis window length in seconds (default: 0.025)
    #' @param time_step Time step between frames in seconds (default: 0.005)
    #' @param pre_emphasis_frequency Pre-emphasis frequency in Hz (default: 50)
    #' @param tol1 Tolerance parameter 1 (default: 1e-6)
    #' @param tol2 Tolerance parameter 2 (default: 1e-6)
    #' @return LPC object
    to_lpc_marple = function(
      prediction_order = 16,
      analysis_width = 0.025,
      time_step = 0.005,
      pre_emphasis_frequency = 50.0,
      tol1 = 1e-6,
      tol2 = 1e-6
    ) {
      lpc_ptr <- .sound_to_lpc_marple(
        private$ptr,
        as.integer(prediction_order),
        analysis_width,
        time_step,
        pre_emphasis_frequency,
        tol1,
        tol2
      )
      LPC$new(.xptr = lpc_ptr)
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
    
    #' @description Extract periodic PointProcess using cross-correlation
    #' Detects periodic pulses (e.g., glottal pulses) using pitch-synchronous analysis.
    #' Corresponds to Praat: To PointProcess (periodic, cc)
    #' @param pitch_floor Minimum pitch in Hz (default: 75)
    #' @param pitch_ceiling Maximum pitch in Hz (default: 600)
    #' @return PointProcess object with detected pulses
    #' @description Alias for backward compatibility
    to_pointprocess_periodic_cc = function(
      time_step = 0.0,
      pitch_floor = 75.0,
      pitch_ceiling = 600.0,
      max_period_factor = 1.3,
      max_amplitude_factor = 1.6
    ) {
      self$to_point_process_periodic_cc(time_step, pitch_floor, pitch_ceiling, max_period_factor, max_amplitude_factor)
    },
    
    #' @description Extract periodic PointProcess using peak detection
    #' Detects periodic pulses by finding peaks in the signal.
    #' Corresponds to Praat: To PointProcess (periodic, peaks)
    #' @param pitch_floor Minimum pitch in Hz (default: 75)
    #' @param pitch_ceiling Maximum pitch in Hz (default: 600)
    #' @param include_maxima Include positive peaks (default: TRUE)
    #' @param include_minima Include negative peaks (default: FALSE)
    #' @return PointProcess object with detected pulses
    to_point_process_periodic_peaks = function(
      pitch_floor = 75.0,
      pitch_ceiling = 600.0,
      include_maxima = TRUE,
      include_minima = FALSE
    ) {
      pp_ptr <- .sound_to_pointprocess_periodic_peaks(
        private$ptr,
        pitch_floor,
        pitch_ceiling,
        include_maxima,
        include_minima
      )
      PointProcess$new(.xptr = pp_ptr)
    },
    
    #' @description Alias for backward compatibility
    to_pointprocess_periodic_peaks = function(
      pitch_floor = 75.0,
      pitch_ceiling = 600.0,
      include_maxima = TRUE,
      include_minima = FALSE
    ) {
      self$to_point_process_periodic_peaks(pitch_floor, pitch_ceiling, include_maxima, include_minima)
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
    #' @param window_shape Window shape (Praat enum): "rectangular", "triangular", "parabolic",
    #'   "hanning", "hamming", "Gaussian1" through "Gaussian5", "Kaiser1", "Kaiser2"
    #' @param relative_width Relative width of window (default: 1.0)
    #' @param preserve_times Keep original time domain (default: FALSE)
    #' @return New Sound object with extracted part
    extract_part = function(
      from_time,
      to_time,
      window_shape = c("rectangular", "triangular", "parabolic", "hanning", "hamming", 
                       "Gaussian1", "Gaussian2", "Gaussian3", "Gaussian4", "Gaussian5",
                       "Kaiser1", "Kaiser2"),
      relative_width = 1.0,
      preserve_times = FALSE
    ) {
      private$check_valid()
      
      window_shape <- match.arg(window_shape)
      # Praat kSound_windowShape enum (Sound_enums.h)
      window_shape_int <- switch(
        window_shape,
        "rectangular" = 0L,
        "triangular"  = 1L,
        "parabolic"   = 2L,
        "hanning"     = 3L,
        "hamming"     = 4L,
        "Gaussian1"   = 5L,
        "Gaussian2"   = 6L,
        "Gaussian3"   = 7L,
        "Gaussian4"   = 8L,
        "Gaussian5"   = 9L,
        "Kaiser1"     = 10L,
        "Kaiser2"     = 11L,
        0L
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

    #' @description Apply pass Hann band filter (passes frequencies between fmin and fmax)
    #' @param fmin Minimum frequency of pass band in Hz
    #' @param fmax Maximum frequency of pass band in Hz  
    #' @param smooth Smoothing parameter (100 Hz is typical)
    #' @return New Sound object with filtered waveform
    filter_pass_hann_band = function(fmin, fmax, smooth = 100.0) {
      private$check_valid()
      if (fmin < 0 || fmax <= fmin) {
        stop("Invalid frequency range: fmin must be >= 0 and fmax must be > fmin")
      }
      sound_ptr <- .sound_filter_pass_hann_band(private$ptr, fmin, fmax, smooth)
      Sound$new(.xptr = sound_ptr)
    },
    
    #' @description Apply stop Hann band filter (stops frequencies between fmin and fmax)
    #' @param fmin Minimum frequency of stop band in Hz
    #' @param fmax Maximum frequency of stop band in Hz
    #' @param smooth Smoothing parameter (100 Hz is typical)
    #' @return New Sound object with filtered waveform
    filter_stop_hann_band = function(fmin, fmax, smooth = 100.0) {
      private$check_valid()
      if (fmin < 0 || fmax <= fmin) {
        stop("Invalid frequency range: fmin must be >= 0 and fmax must be > fmin")
      }
      sound_ptr <- .sound_filter_stop_hann_band(private$ptr, fmin, fmax, smooth)
      Sound$new(.xptr = sound_ptr)
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
    },
    
    #' @description Extract intervals from TextGrid matching criterion
    #' @param textgrid TextGrid object containing annotation
    #' @param tier_number Tier number (1-based) or tier name
    #' @param criterion Matching criterion: "is equal to", "is not equal to", "contains", "starts with", "ends with", "matches regex"
    #' @param text Text to match against
    #' @param preserve_times If TRUE, keep original time stamps; if FALSE, center at 0
    #' @return List of Sound objects, one per matching interval
    extract_intervals_where = function(textgrid, tier_number, criterion = "is equal to", text = "", preserve_times = FALSE) {
      if (!inherits(textgrid, "TextGrid")) {
        stop("textgrid must be a TextGrid object")
      }
      
      # Use TextGrid's method to do the extraction
      textgrid$extract_intervals_where(self, tier_number, criterion, text, preserve_times)
    },
    
    # ========================================================================
    # File I/O Methods
    # ========================================================================
    
    #' @description Save Sound to audio file using native Praat writers
    #' @param path Output file path
    #' @param format Audio format: "WAV", "AIFF", "AIFC", "NIST", "NEXT", "SUN" (default: "WAV")
    #' @param bits_per_sample Bits per sample: 16, 24, or 32 (default: 16)
    #' @return Invisible self for method chaining
    #' @examples
    #' \dontrun{
    #' sound <- Sound$new("input.wav")
    #' sound$save("output.wav")  # Save as 16-bit WAV
    #' sound$save("output.aiff", format = "AIFF", bits_per_sample = 24)  # 24-bit AIFF
    #' }
    save = function(path, format = "WAV", bits_per_sample = 16) {
      .sound_write_to_file_native(private$ptr, path, format, as.integer(bits_per_sample))
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
  sampling_rate = 44100,
  frequency = 440.0,
  amplitude = 0.99
) {
  ptr <- .sound_create_tone(duration, sampling_rate, frequency, amplitude)
  Sound$new(.xptr = ptr)
}
