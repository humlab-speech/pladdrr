# sound-r6-new.R - Sound object using Rcpp Modules (pladdrr 2.0)
# Converted from R6 to function wrapper for 5-10x faster method dispatch

#' Sound
#'
#' Represents a digitized acoustic signal (Praat Sound object).
#'
#' A Sound contains one or more channels of audio sampled at regular intervals.
#' This is the entry point for most acoustic analyses in pladdrr.
#'
#' @section File I/O:
#' The Sound constructor reads audio files using:
#' 1. **Native Praat reader** (fast path): WAV, AIFF, NIST formats
#' 2. **av package fallback**: Any FFmpeg-supported format (MP3, OGG, FLAC, etc.)
#'
#' @section Usage:
#' ```r
#' # From file
#' sound <- Sound(path = "audio.wav")
#'
#' # From numeric data
#' sound <- Sound$from_values(values, sampling_rate = 44100)
#'
#' # Create synthetic tone
#' sound <- Sound$create_tone(frequency = 440, duration = 1.0)
#' ```
#'
#' @section Query Methods:
#' - `get_duration()` - Duration in seconds
#' - `get_sampling_frequency()` - Sampling rate in Hz
#' - `get_number_of_samples()` - Number of samples
#' - `get_number_of_channels()` - Number of channels
#' - `get_value_at_time()` - Amplitude at specific time
#' - `get_rms()`, `get_energy()`, `get_power()` - Energy measures
#' - `get_intensity_db()` - Intensity in dB
#' - `get_minimum()`, `get_maximum()`, `get_mean()` - Amplitude statistics
#'
#' @section Analysis Methods:
#' - `to_pitch()` - Extract pitch contour (F0)
#' - `to_formant_burg()` - Extract formants (F1, F2, F3, ...)
#' - `to_intensity()` - Extract intensity contour
#' - `to_harmonicity_cc()` - Harmonics-to-noise ratio
#' - `to_harmonicity_gne()` - Glottal-to-Noise Excitation ratio (GNE)
#' - `to_spectrum()` - Frequency spectrum
#' - `to_spectrogram()` - Time-frequency representation
#' - `to_ltas()` - Long-term average spectrum
#' - `to_point_process_periodic_cc()` - Extract glottal pulses
#'
#' @section Extraction:
#' - `extract_channel()` - Extract single channel
#' - `extract_part()` - Extract time range
#'
#' @section Modification:
#' - `scale_intensity()` - Scale to target dB level (in-place)
#' - `scale_peak()` - Scale peak amplitude (in-place)
#' - `pre_emphasize()` - High-pass filter (in-place)
#' - `de_emphasize()` - Low-pass filter (in-place)
#' - `resample()` - Resample to different rate (new object)
#' - `convert_to_mono()` - Average channels to mono (new object)
#' - `concatenate()` - Append another sound (new object)
#' - `mix()` - Mix with another sound (new object)
#'
#' @section Export:
#' - `as_matrix()` - Export as numeric matrix
#' - `as_data_frame()` - Export as data.frame
#' - `save()` - Save to audio file
#'
#' @param path Path to audio file (native: WAV/AIFF/NIST, fallback: any FFmpeg format)
#' @param .xptr Internal use only - external pointer to C++ Sound object
#' @return A Sound object (function wrapper with methods)
#'
#' @examples
#' \dontrun{
#' # Basic workflow
#' sound <- Sound(path = "audio.wav")
#' pitch <- sound$to_pitch()
#' formants <- sound$to_formant_burg()
#'
#' # Query properties
#' cat("Duration:", sound$get_duration(), "s\n")
#' cat("Sample rate:", sound$get_sampling_frequency(), "Hz\n")
#'
#' # Extract portion
#' part <- sound$extract_part(1.0, 2.0)
#'
#' # Create synthetic tone
#' tone <- Sound$create_tone(frequency = 440, duration = 1.0)
#' }
#'
#' @seealso [Pitch], [Formant], [Intensity], [Spectrum]
#' @name Sound
NULL

#' @export
Sound <- function(path = NULL, .xptr = NULL) {
  # Handle initialization
  if (!is.null(.xptr)) {
    ptr <- .xptr
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
  } else {
    stop("Must provide either path or .xptr")
  }
  
  # Load Rcpp Module
  snd_mod <- get_module("sound_module")
  cpp_snd <- snd_mod$RSound$new(ptr)
  
  # Create wrapper
  snd <- structure(list(
    .cpp = cpp_snd,
    .xptr = ptr,
    .pointer = ptr,  # Compatibility
    
    # === Query Methods (from module - FAST) ===
    is_valid = function() cpp_snd$is_valid(),
    get_xptr = function() ptr,
    get_xmin = function() cpp_snd$get_xmin(),
    get_xmax = function() cpp_snd$get_xmax(),
    get_duration = function() cpp_snd$get_duration(),
    get_nx = function() cpp_snd$get_nx(),
    get_dx = function() cpp_snd$get_dx(),
    get_x1 = function() cpp_snd$get_x1(),
    get_sampling_frequency = function() cpp_snd$get_sampling_frequency(),
    get_number_of_samples = function() cpp_snd$get_number_of_samples(),
    get_number_of_channels = function() cpp_snd$get_number_of_channels(),
    get_time_from_sample = function(sample) cpp_snd$get_time_from_sample(as.integer(sample)),
    get_sample_from_time = function(time) cpp_snd$get_sample_from_time(as.numeric(time)),
    
    get_value_at_time = function(time, channel = 1, interpolation = "linear") {
      interp_code <- switch(tolower(interpolation),
        "nearest" = 0L, "linear" = 1L, "cubic" = 2L,
        "sinc70" = 3L, "sinc700" = 4L, 1L)
      cpp_snd$get_value_at_time(as.numeric(time), as.integer(channel), interp_code)
    },
    
    get_rms = function(from_time = 0.0, to_time = 0.0) {
      cpp_snd$get_rms(as.numeric(from_time), as.numeric(to_time))
    },
    
    get_energy = function(from_time = 0.0, to_time = 0.0) {
      cpp_snd$get_energy(as.numeric(from_time), as.numeric(to_time))
    },
    
    get_power = function(from_time = 0.0, to_time = 0.0) {
      cpp_snd$get_power(as.numeric(from_time), as.numeric(to_time))
    },
    
    get_intensity_db = function() cpp_snd$get_intensity_db(),
    
    get_minimum = function(from_time = 0.0, to_time = 0.0, channel = 1, interpolation = "parabolic") {
      interp_code <- switch(tolower(interpolation),
        "none" = 0L, "parabolic" = 1L, "cubic" = 2L,
        "sinc70" = 3L, "sinc700" = 4L, 1L)
      cpp_snd$get_minimum(as.numeric(from_time), as.numeric(to_time), interp_code)
    },
    
    get_maximum = function(from_time = 0.0, to_time = 0.0, channel = 1, interpolation = "parabolic") {
      interp_code <- switch(tolower(interpolation),
        "none" = 0L, "parabolic" = 1L, "cubic" = 2L,
        "sinc70" = 3L, "sinc700" = 4L, 1L)
      cpp_snd$get_maximum(as.numeric(from_time), as.numeric(to_time), interp_code)
    },
    
    get_mean = function(from_time = 0.0, to_time = 0.0, channel = 1) {
      cpp_snd$get_mean(as.numeric(from_time), as.numeric(to_time), as.integer(channel))
    },
    
    # === Core Transformations (from module - FAST) ===
    to_pitch = function(time_step = 0.0, pitch_floor = 75.0, pitch_ceiling = 600.0) {
      pitch_ptr <- cpp_snd$to_pitch_ptr(
        as.numeric(time_step),
        as.numeric(pitch_floor),
        as.numeric(pitch_ceiling)
      )
      Pitch(.xptr = pitch_ptr)
    },
    
    to_formant_burg = function(time_step = 0.005, max_formants = 5.0,
                               max_frequency = 5500.0, window_length = 0.025,
                               pre_emphasis_from = 50.0) {
      formant_ptr <- cpp_snd$to_formant_burg_ptr(
        as.numeric(time_step), as.numeric(max_formants),
        as.numeric(max_frequency), as.numeric(window_length),
        as.numeric(pre_emphasis_from)
      )
      Formant(.xptr = formant_ptr)
    },
    
    to_intensity = function(minimum_pitch = 100.0, time_step = 0.0, subtract_mean = TRUE) {
      intensity_ptr <- cpp_snd$to_intensity_ptr(
        as.numeric(minimum_pitch),
        as.numeric(time_step),
        as.logical(subtract_mean)
      )
      Intensity(.xptr = intensity_ptr)
    },
    
    to_harmonicity_cc = function(time_step = 0.01, min_pitch = 75.0,
                                 silence_threshold = 0.1, periods_per_window = 1.0) {
      harm_ptr <- cpp_snd$to_harmonicity_cc_ptr(
        as.numeric(time_step), as.numeric(min_pitch),
        as.numeric(silence_threshold), as.numeric(periods_per_window)
      )
      Harmonicity(.xptr = harm_ptr)
    },
    
    to_harmonicity_gne = function(fmin = 500, fmax = 4500, bandwidth = 1000, step = 80) {
      gne_ptr <- .sound_to_harmonicity_gne(
        ptr,  # Use ptr from parent scope instead of .xptr
        as.numeric(fmin),
        as.numeric(fmax),
        as.numeric(bandwidth),
        as.numeric(step)
      )
      Matrix(.xptr = gne_ptr)
    },
    
    to_spectrum = function(fast = TRUE) {
      spec_ptr <- cpp_snd$to_spectrum_ptr(as.logical(fast))
      Spectrum(.xptr = spec_ptr)
    },
    
    to_spectrogram = function(window_length = 0.005, max_frequency = 5000.0,
                             time_step = 0.002, frequency_step = 20.0,
                             window_shape = "Gaussian") {
      shape_code <- switch(tolower(window_shape),
        "square" = 0L, "hamming" = 1L, "bartlett" = 2L,
        "welch" = 3L, "hanning" = 4L, "gaussian" = 5L, 5L)
      
      spec_ptr <- cpp_snd$to_spectrogram_ptr(
        as.numeric(window_length), as.numeric(max_frequency),
        as.numeric(time_step), as.numeric(frequency_step),
        shape_code
      )
      Spectrogram(.xptr = spec_ptr)
    },
    
    to_point_process_periodic_cc = function(time_step = 0.0, pitch_floor = 75.0, 
                                            pitch_ceiling = 600.0, max_period_factor = 1.3,
                                            max_amplitude_factor = 1.6) {
      pp_ptr <- cpp_snd$to_point_process_periodic_cc_ptr(
        as.numeric(pitch_floor),
        as.numeric(pitch_ceiling)
      )
      PointProcess(.xptr = pp_ptr)
    },
    
    # === Extraction (from module - FAST) ===
    extract_channel = function(channel) {
      ptr_result <- cpp_snd$extract_channel_ptr(as.integer(channel))
      Sound(.xptr = ptr_result)
    },
    
    extract_part = function(from_time, to_time, window_shape = "rectangular",
                           relative_width = 1.0, preserve_times = FALSE) {
      # Map window shape strings to codes
      shape_code <- switch(tolower(window_shape),
        "rectangular" = 0L, "triangular" = 1L, "parabolic" = 2L,
        "hanning" = 3L, "hamming" = 4L, 
        "gaussian1" = 5L, "gaussian2" = 6L, "gaussian3" = 7L,
        "gaussian4" = 8L, "gaussian5" = 9L,
        "kaiser1" = 10L, "kaiser2" = 11L, 0L)
      
      ptr_result <- cpp_snd$extract_part_ptr(
        as.numeric(from_time), as.numeric(to_time),
        shape_code, as.numeric(relative_width),
        as.logical(preserve_times)
      )
      Sound(.xptr = ptr_result)
    },
    
    # === Export (from module - FAST) ===
    as_matrix = function() cpp_snd$as_matrix(),
    as_data_frame = function() cpp_snd$as_data_frame(),
    save = function(path, format = "WAV", bits_per_sample = 16) {
      # Praat Melder audio file type constants (melder_audiofiles.h)
      format_code <- switch(toupper(format),
        "AIFF" = 1L, "AIFC" = 2L, "WAV" = 3L,
        "NEXT" = 4L, "SUN" = 4L, "NIST" = 5L,
        "FLAC" = 6L, "MP3" = 7L, 3L)  # Default to WAV
      cpp_snd$save(as.character(path), as.integer(format_code))
      invisible(NULL)
    },
    
    # === Advanced Transformations (old wrappers - COMPLEX) ===
    to_pitch_ac = function(time_step = 0.0, pitch_floor = 75.0, pitch_ceiling = 600.0,
                          max_candidates = 15, very_accurate = FALSE,
                          silence_threshold = 0.03, voicing_threshold = 0.45,
                          octave_cost = 0.01, octave_jump_cost = 0.35,
                          voiced_unvoiced_cost = 0.14) {
      pitch_ptr <- .sound_to_pitch_ac(
        ptr, time_step, pitch_floor, pitch_ceiling,
        as.integer(max_candidates), very_accurate,
        silence_threshold, voicing_threshold,
        octave_cost, octave_jump_cost, voiced_unvoiced_cost
      )
      Pitch(.xptr = pitch_ptr)
    },
    
    to_pitch_cc = function(time_step = 0.0, pitch_floor = 75.0, pitch_ceiling = 600.0,
                          max_candidates = 15, very_accurate = FALSE,
                          silence_threshold = 0.03, voicing_threshold = 0.45,
                          octave_cost = 0.01, octave_jump_cost = 0.35,
                          voiced_unvoiced_cost = 0.14) {
      pitch_ptr <- .sound_to_pitch_cc(
        ptr, time_step, pitch_floor, pitch_ceiling,
        as.integer(max_candidates), very_accurate,
        silence_threshold, voicing_threshold,
        octave_cost, octave_jump_cost, voiced_unvoiced_cost
      )
      Pitch(.xptr = pitch_ptr)
    },
    
    to_formant_keepall = function(time_step = 0.005, max_formants = 5.0,
                                  max_frequency = 5500.0, window_length = 0.025,
                                  pre_emphasis_from = 50.0) {
      formant_ptr <- .formant_from_sound_keepall(
        ptr, time_step, max_formants, max_frequency,
        window_length, pre_emphasis_from
      )
      Formant(.xptr = formant_ptr)
    },
    
    to_formant_willems = function(time_step = 0.005, number_of_formants = 5.0,
                                  max_frequency = 5500.0, window_length = 0.025,
                                  pre_emphasis_from = 50.0) {
      formant_ptr <- .formant_from_sound_willems(
        ptr, time_step, number_of_formants, max_frequency,
        window_length, pre_emphasis_from
      )
      Formant(.xptr = formant_ptr)
    },
    
    to_formant_sl = function(time_step = 0.005, number_of_poles = 10L,
                             max_frequency = 5500.0, window_length = 0.025,
                             pre_emphasis_from = 50.0) {
      formant_ptr <- .formant_from_sound_sl(
        ptr, time_step, as.integer(number_of_poles),
        max_frequency, window_length, pre_emphasis_from
      )
      Formant(.xptr = formant_ptr)
    },
    
    to_harmonicity_ac = function(time_step = 0.01, min_pitch = 75.0,
                                 silence_threshold = 0.1, periods_per_window = 1.0) {
      hnr_ptr <- .harmonicity_to_sound_ac(
        ptr, time_step, min_pitch,
        silence_threshold, periods_per_window
      )
      Harmonicity(.xptr = hnr_ptr)
    },
    
    to_ltas = function(bandwidth = 100.0) {
      ltas_ptr <- .sound_to_ltas(ptr, bandwidth)
      Ltas(.xptr = ltas_ptr)
    },
    
    to_formant_path = function(time_step = 0.005,
                               max_num_formants = 5.0,
                               formant_ceiling = 5500.0,
                               window_length = 0.025,
                               preemphasis_from = 50.0,
                               ceiling_step_fraction = 0.05,
                               num_steps_up_down = 4L) {
      FormantPath(snd, time_step, max_num_formants, formant_ceiling,
                 window_length, preemphasis_from, ceiling_step_fraction,
                 num_steps_up_down)
    },
    
    to_complex_spectrogram = function(window_length = 0.005, maximum_frequency = 5000.0) {
      ComplexSpectrogram(snd, window_length, maximum_frequency)
    },
    
    to_textgrid_silences = function(min_pitch = 100.0, time_step = 0.0,
                                    silence_threshold = -25.0,
                                    min_silent_duration = 0.1,
                                    min_sounding_duration = 0.1,
                                    silent_label = "silent",
                                    sounding_label = "sounding") {
      tg_ptr <- .sound_to_textgrid_silences(
        ptr, min_pitch, time_step, silence_threshold,
        min_silent_duration, min_sounding_duration,
        silent_label, sounding_label
      )
      TextGrid(.xptr = tg_ptr)
    },
    
    to_cochleagram = function(dt = 0.01, df = 0.1, window_length = 0.03,
                              forward_masking_time = 0.03) {
      stopifnot(
        "dt must be a positive number" = is.numeric(dt) && length(dt) == 1 && dt > 0,
        "df must be a positive number" = is.numeric(df) && length(df) == 1 && df > 0,
        "window_length must be a positive number" = is.numeric(window_length) && length(window_length) == 1 && window_length > 0,
        "forward_masking_time must be a non-negative number" = is.numeric(forward_masking_time) && length(forward_masking_time) == 1 && forward_masking_time >= 0
      )
      cochleagram_ptr <- .sound_to_cochleagram(ptr, dt, df, window_length, forward_masking_time)
      Cochleagram(.xptr = cochleagram_ptr)
    },
    
    to_cochleagram_edb = function(dtime = 0.01, dfreq = 0.1, has_synapse = TRUE,
                                   replenishment_rate = 0.01, loss_rate = 0.1,
                                   return_rate = 0.05, reprocessing_rate = 0.01) {
      sampling_rate <- cpp_snd$get_sampling_frequency()
      if (sampling_rate < 44100) {
        stop(
          "Cochleagram EDB algorithm is unstable with sampling rates < 44.1kHz\n",
          sprintf("  Current rate: %.0f Hz\n", sampling_rate),
          "  Recommendation: Use $to_cochleagram() instead, which is more stable.",
          call. = FALSE
        )
      }
      cochleagram_ptr <- .sound_to_cochleagram_edb(
        ptr, dtime, dfreq, has_synapse,
        replenishment_rate, loss_rate, return_rate, reprocessing_rate
      )
      Cochleagram(.xptr = cochleagram_ptr)
    },
    
    to_powercepstrogram = function(pitch_floor = 60.0, time_step = 0.002,
                                   maximum_frequency = 5000.0, pre_emphasis_frequency = 50.0) {
      pcep_ptr <- .sound_to_powercepstrogram(ptr, pitch_floor, time_step, maximum_frequency, pre_emphasis_frequency)
      PowerCepstrogram(.xptr = pcep_ptr)
    },
    
    to_cepstrum = function() {
      xptr <- .sound_to_cepstrum(ptr)
      Cepstrum(.xptr = xptr)
    },
    
    to_cepstrum_bw = function() {
      xptr <- .sound_to_cepstrum_bw(ptr)
      Cepstrum(.xptr = xptr)
    },
    
    to_manipulation = function(time_step = 0.01, pitch_floor = 75.0, pitch_ceiling = 600.0) {
      manip_ptr <- .manipulation_from_sound(ptr, time_step, pitch_floor, pitch_ceiling)
      Manipulation(.xptr = manip_ptr)
    },
    
    to_lpc_burg = function(prediction_order = 16, analysis_width = 0.025,
                           time_step = 0.005, pre_emphasis_frequency = 50.0) {
      lpc_ptr <- .sound_to_lpc_burg(
        ptr, as.integer(prediction_order), analysis_width,
        time_step, pre_emphasis_frequency
      )
      LPC(.xptr = lpc_ptr)
    },
    
    to_lpc_auto = function(prediction_order = 16, analysis_width = 0.025,
                           time_step = 0.005, pre_emphasis_frequency = 50.0) {
      lpc_ptr <- .sound_to_lpc_auto(
        ptr, as.integer(prediction_order), analysis_width,
        time_step, pre_emphasis_frequency
      )
      LPC(.xptr = lpc_ptr)
    },
    
    to_lpc_covariance = function(prediction_order = 16, analysis_width = 0.025,
                                 time_step = 0.005, pre_emphasis_frequency = 50.0) {
      lpc_ptr <- .sound_to_lpc_covariance(
        ptr, as.integer(prediction_order), analysis_width,
        time_step, pre_emphasis_frequency
      )
      LPC(.xptr = lpc_ptr)
    },
    
    to_lpc_marple = function(prediction_order = 16, analysis_width = 0.025,
                             time_step = 0.005, pre_emphasis_frequency = 50.0,
                             tol1 = 1e-6, tol2 = 1e-6) {
      lpc_ptr <- .sound_to_lpc_marple(
        ptr, as.integer(prediction_order), analysis_width,
        time_step, pre_emphasis_frequency, tol1, tol2
      )
      LPC(.xptr = lpc_ptr)
    },
    
    to_point_process_extrema = function(channel = 1, include_maxima = TRUE,
                                        include_minima = FALSE,
                                        interpolation = c("None", "Parabolic", "Cubic", "Sinc70", "Sinc700")) {
      interpolation <- match.arg(interpolation)
      interpolation_int <- switch(interpolation,
        "None" = 0, "Parabolic" = 1, "Cubic" = 2,
        "Sinc70" = 3, "Sinc700" = 4, 1)
      
      pp_ptr <- .sound_to_point_process_extrema(
        ptr, as.integer(channel), as.logical(include_maxima),
        as.logical(include_minima), interpolation_int
      )
      PointProcess(.xptr = pp_ptr)
    },
    
    to_point_process_zeros = function(channel = 1, include_raisers = TRUE,
                                      include_fallers = FALSE) {
      pp_ptr <- .sound_to_point_process_zeros(
        ptr, as.integer(channel),
        as.logical(include_raisers), as.logical(include_fallers)
      )
      PointProcess(.xptr = pp_ptr)
    },
    
    to_point_process_periodic_peaks = function(pitch_floor = 75.0, pitch_ceiling = 600.0,
                                               include_maxima = TRUE, include_minima = FALSE) {
      pp_ptr <- .sound_to_pointprocess_periodic_peaks(
        ptr, pitch_floor, pitch_ceiling, include_maxima, include_minima
      )
      PointProcess(.xptr = pp_ptr)
    },
    
    # Aliases for backward compatibility
    to_pointprocess_periodic_cc = function(time_step = 0.0, pitch_floor = 75.0,
                                          pitch_ceiling = 600.0, max_period_factor = 1.3,
                                          max_amplitude_factor = 1.6) {
      snd$to_point_process_periodic_cc(time_step, pitch_floor, pitch_ceiling, 
                                       max_period_factor, max_amplitude_factor)
    },
    
    to_pointprocess_periodic_peaks = function(pitch_floor = 75.0, pitch_ceiling = 600.0,
                                             include_maxima = TRUE, include_minima = FALSE) {
      snd$to_point_process_periodic_peaks(pitch_floor, pitch_ceiling, include_maxima, include_minima)
    },
    
    # === Modification Methods (old wrappers) ===
    scale_intensity = function(new_intensity_db) {
      .sound_scale_intensity(ptr, new_intensity_db)
      invisible(snd)
    },
    
    scale_peak = function(new_peak = 0.99) {
      .sound_scale_peak(ptr, new_peak)
      invisible(snd)
    },
    
    pre_emphasize = function(from_frequency = 50.0) {
      .sound_pre_emphasize(ptr, from_frequency)
      invisible(snd)
    },
    
    de_emphasize = function(from_frequency = 50.0) {
      .sound_de_emphasize(ptr, from_frequency)
      invisible(snd)
    },
    
    filter_pass_hann_band = function(fmin, fmax, smooth = 100.0) {
      if (fmin < 0 || fmax <= fmin) {
        stop("Invalid frequency range: fmin must be >= 0 and fmax must be > fmin")
      }
      sound_ptr <- .sound_filter_pass_hann_band(ptr, fmin, fmax, smooth)
      Sound(.xptr = sound_ptr)
    },
    
    filter_stop_hann_band = function(fmin, fmax, smooth = 100.0) {
      if (fmin < 0 || fmax <= fmin) {
        stop("Invalid frequency range: fmin must be >= 0 and fmax must be > fmin")
      }
      sound_ptr <- .sound_filter_stop_hann_band(ptr, fmin, fmax, smooth)
      Sound(.xptr = sound_ptr)
    },
    
    resample = function(new_frequency, precision = 50) {
      if (new_frequency <= 0) {
        stop("new_frequency must be positive")
      }
      sound_ptr <- .sound_resample(ptr, new_frequency, as.integer(precision))
      Sound(.xptr = sound_ptr)
    },
    
    convert_to_mono = function() {
      if (cpp_snd$get_number_of_channels() == 1) {
        message("Sound is already mono, returning copy")
      }
      sound_ptr <- .sound_convert_to_mono(ptr)
      Sound(.xptr = sound_ptr)
    },
    
    convert_to_stereo = function() {
      if (cpp_snd$get_number_of_channels() > 1) {
        warning("Sound is already multi-channel, returning as-is")
        sound_ptr <- .sound_copy(ptr)
      } else {
        sound_ptr <- .sound_convert_to_stereo(ptr)
      }
      Sound(.xptr = sound_ptr)
    },
    
    concatenate = function(other_sound, overlap = 0) {
      if (!inherits(other_sound, "Sound")) {
        stop("other_sound must be a Sound object")
      }
      if (!other_sound$is_valid()) {
        stop("other_sound is not a valid Sound object")
      }
      sound_ptr <- .sound_concatenate(ptr, other_sound$.xptr, overlap)
      Sound(.xptr = sound_ptr)
    },
    
    mix = function(other_sound, balance = 1.0) {
      if (!inherits(other_sound, "Sound")) {
        stop("other_sound must be a Sound object")
      }
      if (!other_sound$is_valid()) {
        stop("other_sound is not a valid Sound object")
      }
      sound_ptr <- .sound_mix(ptr, other_sound$.xptr, balance)
      Sound(.xptr = sound_ptr)
    },
    
    extract_intervals_where = function(textgrid, tier_number, criterion = "is equal to", 
                                      text = "", preserve_times = FALSE) {
      if (!inherits(textgrid, "TextGrid")) {
        stop("textgrid must be a TextGrid object")
      }
      textgrid$extract_intervals_where(snd, tier_number, criterion, text, preserve_times)
    },
    
    # === Print Method ===
    print = function() {
      if (!cpp_snd$is_valid()) {
        cat("<Sound [invalid]>\n")
        return(invisible(snd))
      }
      
      cat("<Praat Sound>\n")
      cat(sprintf("  Duration: %.3f s\n", cpp_snd$get_duration()))
      cat(sprintf("  Sampling frequency: %.0f Hz\n", cpp_snd$get_sampling_frequency()))
      cat(sprintf("  Number of samples: %d\n", cpp_snd$get_number_of_samples()))
      cat(sprintf("  Number of channels: %d\n", cpp_snd$get_number_of_channels()))
      
      intensity_db <- tryCatch(cpp_snd$get_intensity_db(), error = function(e) NA)
      if (!is.na(intensity_db)) {
        cat(sprintf("  Intensity: %.1f dB\n", intensity_db))
      }
      
      invisible(snd)
    }
  ), class = c("Sound", "PraatObject"))
  
  snd
}

# ============================================================================
# Static Factory Methods
# ============================================================================

#' Create Sound from numeric values
#' 
#' Factory function to create a Sound object from a numeric vector or matrix.
#' Use `Sound$from_values()` for backward compatibility (calls this function).
#' 
#' @param values Numeric matrix with channels as rows, samples as columns (or vector for mono)
#' @param sampling_rate Sampling rate in Hz (default: 44100)
#' @param start_time Start time of the sound in seconds (default: 0.0)
#' @return A Sound object
#' @export
#' @examples
#' \dontrun{
#' # Create from vector (mono)
#' values <- sin(2 * pi * 440 * seq(0, 1, length.out = 44100))
#' sound <- sound_from_values(values, 44100)
#' 
#' # Or using Sound$from_values() (same thing)
#' sound <- Sound$from_values(values, 44100)
#' }
sound_from_values <- function(values, sampling_rate = 44100, start_time = 0.0) {
  if (is.vector(values)) {
    values <- matrix(values, nrow = 1)
  }
  
  if (!is.matrix(values)) {
    stop("values must be a numeric vector or matrix")
  }
  
  ptr <- .sound_create_from_values(values, sampling_rate, start_time)
  Sound(.xptr = ptr)
}

#' Create a pure tone Sound
#' 
#' Factory function to generate a pure sine wave tone.
#' Use `Sound$create_tone()` for backward compatibility (calls this function).
#' 
#' @param duration Duration in seconds (default: 1.0)
#' @param sampling_rate Sampling rate in Hz (default: 44100)
#' @param frequency Frequency in Hz (default: 440)
#' @param amplitude Amplitude 0-1 (default: 0.99)
#' @return A Sound object
#' @export
#' @examples
#' \dontrun{
#' # Create 440 Hz tone
#' sound <- sound_create_tone(frequency = 440, duration = 1.0)
#' 
#' # Or using Sound$create_tone() (same thing)
#' sound <- Sound$create_tone(frequency = 440, duration = 1.0)
#' }
sound_create_tone <- function(duration = 1.0, sampling_rate = 44100,
                              frequency = 440.0, amplitude = 0.99) {
  ptr <- .sound_create_tone(duration, sampling_rate, frequency, amplitude)
  Sound(.xptr = ptr)
}

# Make Sound "class" support $ for static methods (backward compatibility)
.sound_static_env <- new.env(parent = emptyenv())
.sound_static_env$from_values <- sound_from_values
.sound_static_env$from_matrix <- sound_from_values  # Alias
.sound_static_env$new_from_values <- sound_from_values  # Alias
.sound_static_env$create_tone <- sound_create_tone
.sound_static_env$new <- Sound  # Allow Sound$new() as well as Sound()

#' $ method for Sound constructor (enables Sound$create_tone(), etc.)
#' @param x The Sound constructor function
#' @param name Name of static method to access
#' @return The requested static method function
#' @exportS3Method $ sound_constructor
`$.sound_constructor` <- function(x, name) {
  val <- .sound_static_env[[name]]
  if (is.null(val)) {
    stop("Sound has no static method '", name, "'. Available: from_values, create_tone, new")
  }
  val
}

# Assign class to enable $ operator
class(Sound) <- c("sound_constructor", "function")

#' @exportS3Method print Sound
print.Sound <- function(x, ...) x$print()
