# sound-wrapper.R - Sound object using shared dispatch table (pladdrr 4.8.32)
# Architecture: minimal list + $.Sound S3 dispatch → shared method env
# ~160x less memory per Sound, ~9x faster construction vs per-instance closures

#' Sound
#'
#' Represents a digitized acoustic signal (Praat Sound object).
#'
#' A Sound contains one or more channels of audio sampled at regular intervals.
#' This is the entry point for most acoustic analyses in pladdrr.
#'
#' @section File I/O:
#' The Sound constructor reads audio files using:
#' 1. **Native Praat reader** (primary): WAV, AIFF, AIFC, FLAC, MP3, NIST, NeXT/Sun
#' 2. **av package fallback**: Only used for formats Praat doesn't support (OGG Vorbis, etc.)
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
#' - `get_values(channel)` - **NEW**: Get sample values as numeric vector (fast, no data frame)
#' - `get_sample_times()` - **NEW**: Get sample times as numeric vector (fast, no data frame)
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
#' - `to_ltas_pitch_corrected()` - Pitch-corrected LTAS (voice quality)
#' - `to_formant_robust()` - Outlier-resistant formant tracking
#' - `to_mel_spectrogram()` - Mel-scale spectrogram
#' - `to_bark_spectrogram()` - Bark-scale spectrogram
#' - `to_point_process_periodic_cc()` - Extract glottal pulses
#'
#' @section Signal Processing:
#' - `lengthen()` - Time-stretch using overlap-add
#' - `autocorrelate()` - Autocorrelation function
#' - `convolve()` - Convolve with another sound
#' - `cross_correlate()` - Cross-correlate with another sound
#' - `deepen_band_modulation()` - Hearing enhancement
#' - `filter_by_formant()` - Filter with Formant object
#' - `filter_by_formant_noscale()` - Filter without scaling
#'
#' @section Extraction:
#' - `extract_channel()` - Extract single channel
#' - `extract_part(from, to, window_shape, relative_width, preserve_times)` - Extract time range with optional windowing
#'   * Supports 12 window shapes: rectangular, triangular, parabolic, hanning, hamming,
#'     gaussian1-5, kaiser1-2
#'   * See \url{https://www.fon.hum.uva.nl/praat/manual/Sound__Extract_part___.html}
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
#' @param path Path to audio file (native: WAV/AIFF/FLAC/MP3/NIST, fallback: av for unsupported formats)
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

# ============================================================================
# Shared Method Dispatch Table
# ============================================================================
# All Sound methods defined once, shared across all instances.
# Each method receives .self (the Sound object) as first arg via $.Sound.
# Access fields: .self$.cpp (Rcpp module), .self$.xptr (external pointer).

.sound_methods <- new.env(hash = TRUE, parent = emptyenv())

# --- Helpers (package-level, not per-instance) ---
.interp_code <- function(interpolation) {
  switch(tolower(interpolation),
    "nearest" = 0L, "linear" = 1L, "cubic" = 2L,
    "sinc70" = 3L, "sinc700" = 4L, 1L)
}

.peak_interp_code <- function(interpolation) {
  switch(tolower(interpolation),
    "none" = 0L, "parabolic" = 1L, "cubic" = 2L,
    "sinc70" = 3L, "sinc700" = 4L, 1L)
}

.window_shape_code <- function(window_shape) {
  switch(tolower(window_shape),
    "rectangular" = 0L, "triangular" = 1L, "parabolic" = 2L,
    "hanning" = 3L, "hamming" = 4L,
    "gaussian1" = 5L, "gaussian2" = 6L, "gaussian3" = 7L,
    "gaussian4" = 8L, "gaussian5" = 9L,
    "kaiser1" = 10L, "kaiser2" = 11L, 0L)
}

# --- Query Methods ---
.sound_methods$is_valid <- function(.self) .self$.cpp$is_valid()
.sound_methods$get_xptr <- function(.self) .self$.xptr
.sound_methods$get_xmin <- function(.self) .self$.cpp$get_xmin()
.sound_methods$get_xmax <- function(.self) .self$.cpp$get_xmax()
.sound_methods$get_start_time <- function(.self) .self$.cpp$get_xmin()
.sound_methods$get_end_time <- function(.self) .self$.cpp$get_xmax()
.sound_methods$get_total_duration <- function(.self) .self$.cpp$get_duration()
.sound_methods$get_duration <- function(.self) .self$.cpp$get_duration()
.sound_methods$get_nx <- function(.self) .self$.cpp$get_nx()
.sound_methods$get_dx <- function(.self) .self$.cpp$get_dx()
.sound_methods$get_x1 <- function(.self) .self$.cpp$get_x1()
.sound_methods$get_sampling_frequency <- function(.self) .self$.cpp$get_sampling_frequency()
.sound_methods$get_number_of_samples <- function(.self) .self$.cpp$get_number_of_samples()
.sound_methods$get_number_of_channels <- function(.self) .self$.cpp$get_number_of_channels()
.sound_methods$get_time_from_sample <- function(.self, sample) .self$.cpp$get_time_from_sample(as.integer(sample))
.sound_methods$get_sample_from_time <- function(.self, time) .self$.cpp$get_sample_from_time(as.numeric(time))

.sound_methods$get_value_at_time <- function(.self, time, channel = 1, interpolation = "linear") {
  .self$.cpp$get_value_at_time(as.numeric(time), as.integer(channel), .interp_code(interpolation))
}

.sound_methods$get_rms <- function(.self, from_time = 0.0, to_time = 0.0) {
  .self$.cpp$get_rms(as.numeric(from_time), as.numeric(to_time))
}

.sound_methods$get_energy <- function(.self, from_time = 0.0, to_time = 0.0) {
  .self$.cpp$get_energy(as.numeric(from_time), as.numeric(to_time))
}

.sound_methods$get_power <- function(.self, from_time = 0.0, to_time = 0.0) {
  .self$.cpp$get_power(as.numeric(from_time), as.numeric(to_time))
}

.sound_methods$get_intensity_db <- function(.self) .self$.cpp$get_intensity_db()

.sound_methods$get_minimum <- function(.self, from_time = 0.0, to_time = 0.0, channel = 1, interpolation = "parabolic") {
  .self$.cpp$get_minimum(as.numeric(from_time), as.numeric(to_time), .peak_interp_code(interpolation))
}

.sound_methods$get_maximum <- function(.self, from_time = 0.0, to_time = 0.0, channel = 1, interpolation = "parabolic") {
  .self$.cpp$get_maximum(as.numeric(from_time), as.numeric(to_time), .peak_interp_code(interpolation))
}

.sound_methods$get_mean <- function(.self, from_time = 0.0, to_time = 0.0, channel = 1) {
  .self$.cpp$get_mean(as.numeric(from_time), as.numeric(to_time), as.integer(channel))
}

# --- Direct Data Access ---
.sound_methods$get_values <- function(.self, channel = 1) {
  .self$.cpp$get_values(as.integer(channel))
}

.sound_methods$get_sample_times <- function(.self) {
  .self$.cpp$get_sample_times()
}

# --- Batch/Vectorized Window Operations ---
.sound_methods$get_power_windows <- function(.self, window_starts, window_ends) {
  .self$.cpp$get_power_windows(as.numeric(window_starts), as.numeric(window_ends))
}

.sound_methods$get_rms_windows <- function(.self, window_starts, window_ends) {
  .self$.cpp$get_rms_windows(as.numeric(window_starts), as.numeric(window_ends))
}

.sound_methods$get_energy_windows <- function(.self, window_starts, window_ends) {
  .self$.cpp$get_energy_windows(as.numeric(window_starts), as.numeric(window_ends))
}

.sound_methods$get_zcr_windows <- function(.self, window_starts, window_ends, channel = 1) {
  .self$.cpp$get_zcr_windows(as.numeric(window_starts), as.numeric(window_ends), as.integer(channel))
}

# --- Batch/Vectorized Value Extraction ---
.sound_methods$get_values_at_times <- function(.self, times, channel = 1, interpolation = "linear") {
  .self$.cpp$get_values_at_times(as.numeric(times), as.integer(channel), .interp_code(interpolation))
}

.sound_methods$get_values_in_range <- function(.self, from_time = 0.0, to_time = 0.0, channel = 1) {
  .self$.cpp$get_values_in_range(as.numeric(from_time), as.numeric(to_time), as.integer(channel))
}

.sound_methods$get_times_in_range <- function(.self, from_time = 0.0, to_time = 0.0) {
  .self$.cpp$get_times_in_range(as.numeric(from_time), as.numeric(to_time))
}

# --- Batch/Filtered Window Extraction ---
.sound_methods$extract_windows_filtered <- function(.self, window_starts, window_ends,
                                                     min_power = 0.0, max_zcr = -1.0,
                                                     overlap_time = 0.0, window_shape = "rectangular") {
  sound_ptr <- .self$.cpp$extract_windows_filtered_ptr(
    as.numeric(window_starts), as.numeric(window_ends),
    as.numeric(min_power), as.numeric(max_zcr),
    as.numeric(overlap_time), .window_shape_code(window_shape))
  Sound(.xptr = sound_ptr)
}

.sound_methods$get_windows_passing_filter <- function(.self, window_starts, window_ends,
                                                       min_power = 0.0, max_zcr = -1.0) {
  .self$.cpp$get_windows_passing_filter(
    as.numeric(window_starts), as.numeric(window_ends),
    as.numeric(min_power), as.numeric(max_zcr))
}

.sound_methods$concatenate_sounds <- function(.self, sounds, overlap_time = 0.0) {
  if (!is.list(sounds)) stop("sounds must be a list of Sound objects")
  sound_ptrs <- lapply(sounds, function(s) {
    if (!inherits(s, "Sound")) stop("All elements must be Sound objects")
    s$.xptr
  })
  sound_ptr <- .self$.cpp$concatenate_parts_ptr(sound_ptrs, as.numeric(overlap_time))
  Sound(.xptr = sound_ptr)
}

# --- Analysis Methods (module-based) ---
.sound_methods$to_pitch <- function(.self, time_step = 0.0, pitch_floor = 75.0, pitch_ceiling = 600.0) {
  .check_pitch_range(pitch_floor, pitch_ceiling)
  pitch_ptr <- .self$.cpp$to_pitch_ptr(as.numeric(time_step), as.numeric(pitch_floor), as.numeric(pitch_ceiling))
  Pitch(.xptr = pitch_ptr)
}

.sound_methods$to_formant_burg <- function(.self, time_step = 0.005, max_formants = 5.0,
                                            max_frequency = 5500.0, window_length = 0.025,
                                            pre_emphasis_from = 50.0,
                                            max_number_of_formants = NULL,
                                            maximum_formant = NULL,
                                            pre_emphasis = NULL) {
  max_formants <- max_number_of_formants %||% max_formants
  max_frequency <- maximum_formant %||% max_frequency
  pre_emphasis_from <- pre_emphasis %||% pre_emphasis_from
  formant_ptr <- .self$.cpp$to_formant_burg(
    as.numeric(time_step), as.numeric(max_formants),
    as.numeric(max_frequency), as.numeric(window_length),
    as.numeric(pre_emphasis_from))
  if (is.null(formant_ptr) || !inherits(formant_ptr, "externalptr")) {
    stop("Failed to create Formant from Sound")
  }
  Formant(.xptr = formant_ptr)
}

.sound_methods$to_formant_optimal <- function(.self,
    start_time = 0.0, end_time = 0.0,
    window_length = 0.025, time_step = 0.005,
    min_freq = 4500.0, max_freq = 6500.0, num_freq_steps = 11,
    preemphasis_freq = 50.0,
    num_formant_tracks = 4, num_params_per_track = 5,
    weigh_formants = "bandwidth",
    num_sigmas = 1.0, power = 1.25,
    use_constraints = FALSE,
    min_f1 = 0.0, max_f1 = 0.0,
    min_f2 = 0.0, max_f2 = 0.0,
    min_f3 = 0.0) {
  weigh_code <- switch(tolower(weigh_formants),
    "equal" = 1L, "bandwidth" = 2L, "sqrt_bandwidth" = 3L, "q_factor" = 4L, 2L)
  fm_mod <- get_module("formantmodeler_module")
  result <- fm_mod$Sound_to_Formant_interval(
    .self$.xptr, start_time, end_time,
    window_length, time_step,
    min_freq, max_freq, as.integer(num_freq_steps),
    preemphasis_freq,
    as.integer(num_formant_tracks), as.integer(num_params_per_track),
    weigh_code,
    num_sigmas, power,
    use_constraints, min_f1, max_f1, min_f2, max_f2, min_f3)
  list(formant = Formant(.xptr = result$formant_ptr), optimal_ceiling = result$optimal_ceiling)
}

.sound_methods$get_optimal_formant_ceiling <- function(.self,
    start_time = 0.0, end_time = 0.0,
    window_length = 0.025, time_step = 0.005,
    min_freq = 4500.0, max_freq = 6500.0, num_freq_steps = 11,
    preemphasis_freq = 50.0,
    num_formant_tracks = 4, num_params_per_track = 5,
    weigh_formants = "bandwidth",
    num_sigmas = 1.0, power = 1.25) {
  weigh_code <- switch(tolower(weigh_formants),
    "equal" = 1L, "bandwidth" = 2L, "sqrt_bandwidth" = 3L, "q_factor" = 4L, 2L)
  fm_mod <- get_module("formantmodeler_module")
  fm_mod$Sound_get_optimal_formant_ceiling(
    .self$.xptr, start_time, end_time,
    window_length, time_step,
    min_freq, max_freq, as.integer(num_freq_steps),
    preemphasis_freq,
    as.integer(num_formant_tracks), as.integer(num_params_per_track),
    weigh_code, num_sigmas, power)
}

.sound_methods$to_intensity <- function(.self, minimum_pitch = 100.0, time_step = 0.0, subtract_mean = TRUE) {
  intensity_ptr <- .self$.cpp$to_intensity_ptr(as.numeric(minimum_pitch), as.numeric(time_step), as.logical(subtract_mean))
  Intensity(.xptr = intensity_ptr)
}

.sound_methods$to_harmonicity_cc <- function(.self, time_step = 0.01, min_pitch = 75.0,
                                              silence_threshold = 0.1, periods_per_window = 1.0) {
  harm_ptr <- .self$.cpp$to_harmonicity_cc_ptr(
    as.numeric(time_step), as.numeric(min_pitch),
    as.numeric(silence_threshold), as.numeric(periods_per_window))
  Harmonicity(.xptr = harm_ptr)
}

.sound_methods$to_harmonicity_gne <- function(.self, fmin = 500, fmax = 4500, bandwidth = 1000, step = 80) {
  gne_ptr <- .sound_to_harmonicity_gne(
    .self$.xptr, as.numeric(fmin), as.numeric(fmax), as.numeric(bandwidth), as.numeric(step))
  Matrix(.xptr = gne_ptr)
}

.sound_methods$to_spectrum <- function(.self, fast = TRUE) {
  spec_ptr <- .self$.cpp$to_spectrum_ptr(as.logical(fast))
  Spectrum(.xptr = spec_ptr)
}

.sound_methods$to_spectrogram <- function(.self, window_length = 0.005, max_frequency = 5000.0,
                                           time_step = 0.002, frequency_step = 20.0,
                                           window_shape = "Gaussian") {
  shape_code <- switch(tolower(window_shape),
    "square" = 0L, "hamming" = 1L, "bartlett" = 2L,
    "welch" = 3L, "hanning" = 4L, "gaussian" = 5L, 5L)
  spec_ptr <- .self$.cpp$to_spectrogram_ptr(
    as.numeric(window_length), as.numeric(max_frequency),
    as.numeric(time_step), as.numeric(frequency_step), shape_code)
  Spectrogram(.xptr = spec_ptr)
}

.sound_methods$to_point_process_periodic_cc <- function(.self, pitch_floor = 75.0, pitch_ceiling = 600.0,
                                                         time_step = NULL, max_period_factor = NULL,
                                                         max_amplitude_factor = NULL) {
  .check_pitch_range(pitch_floor, pitch_ceiling)
  if (!is.null(time_step) || !is.null(max_period_factor) || !is.null(max_amplitude_factor)) {
    warning("time_step, max_period_factor, and max_amplitude_factor are not used by ",
            "Sound_to_PointProcess_periodic_cc(). Only pitch_floor and pitch_ceiling are used.",
            call. = FALSE)
  }
  pp_ptr <- .self$.cpp$to_point_process_periodic_cc_ptr(as.numeric(pitch_floor), as.numeric(pitch_ceiling))
  PointProcess(.xptr = pp_ptr)
}

.sound_methods$pitch_to_pointprocess_peaks <- function(.self, pitch, include_maxima = TRUE, include_minima = FALSE) {
  if (!inherits(pitch, "Pitch")) stop("pitch must be a Pitch object (created with sound$to_pitch())")
  if (!pitch$is_valid()) stop("Invalid Pitch object")
  pp_ptr <- .sound_pitch_to_pointprocess_peaks(
    .self$.xptr, pitch$.xptr, as.logical(include_maxima), as.logical(include_minima))
  PointProcess(.xptr = pp_ptr)
}

# --- Extraction ---
.sound_methods$extract_channel <- function(.self, channel) {
  ptr_result <- .self$.cpp$extract_channel_ptr(as.integer(channel))
  Sound(.xptr = ptr_result)
}

.sound_methods$extract_part <- function(.self, from_time, to_time, window_shape = "rectangular",
                                         relative_width = 1.0, preserve_times = FALSE) {
  ptr_result <- .self$.cpp$extract_part_ptr(
    as.numeric(from_time), as.numeric(to_time),
    .window_shape_code(window_shape), as.numeric(relative_width), as.logical(preserve_times))
  Sound(.xptr = ptr_result)
}

.sound_methods$extract_parts_batch <- function(.self, from_times, to_times, window_shape = "rectangular",
                                                relative_width = 1.0, preserve_times = FALSE) {
  xptrs <- .sound_extract_parts_batch(
    .self$.xptr, as.numeric(from_times), as.numeric(to_times),
    .window_shape_code(window_shape), as.numeric(relative_width), as.logical(preserve_times))
  lapply(xptrs, function(xptr) Sound(.xptr = xptr))
}

# --- Export ---
.sound_methods$as_matrix <- function(.self) .self$.cpp$as_matrix()
.sound_methods$as_data_frame <- function(.self) .self$.cpp$as_data_frame()

.sound_methods$save <- function(.self, path, format = "WAV", bits_per_sample = 16) {
  format_code <- switch(toupper(format),
    "AIFF" = 1L, "AIFC" = 2L, "WAV" = 3L,
    "NEXT" = 4L, "SUN" = 4L, "NIST" = 5L,
    "FLAC" = 6L, "MP3" = 7L, 3L)
  .self$.cpp$save(as.character(path), as.integer(format_code))
  invisible(NULL)
}

# --- Advanced Analysis (standalone Rcpp functions) ---
.sound_methods$to_pitch_ac <- function(.self, time_step = 0.0, pitch_floor = 75.0, pitch_ceiling = 600.0,
                                        max_candidates = 15, very_accurate = FALSE,
                                        silence_threshold = 0.03, voicing_threshold = 0.45,
                                        octave_cost = 0.01, octave_jump_cost = 0.35,
                                        voiced_unvoiced_cost = 0.14,
                                        max_number_of_candidates = NULL) {
  .check_pitch_range(pitch_floor, pitch_ceiling)
  max_candidates <- max_number_of_candidates %||% max_candidates
  pitch_ptr <- .sound_to_pitch_ac(
    .self$.xptr, time_step, pitch_floor, pitch_ceiling,
    as.integer(max_candidates), very_accurate,
    silence_threshold, voicing_threshold,
    octave_cost, octave_jump_cost, voiced_unvoiced_cost)
  Pitch(.xptr = pitch_ptr)
}

.sound_methods$to_pitch_cc <- function(.self, time_step = 0.0, pitch_floor = 75.0, pitch_ceiling = 600.0,
                                        max_candidates = 15, very_accurate = FALSE,
                                        silence_threshold = 0.03, voicing_threshold = 0.45,
                                        octave_cost = 0.01, octave_jump_cost = 0.35,
                                        voiced_unvoiced_cost = 0.14,
                                        max_number_of_candidates = NULL) {
  .check_pitch_range(pitch_floor, pitch_ceiling)
  max_candidates <- max_number_of_candidates %||% max_candidates
  pitch_ptr <- .sound_to_pitch_cc(
    .self$.xptr, time_step, pitch_floor, pitch_ceiling,
    as.integer(max_candidates), very_accurate,
    silence_threshold, voicing_threshold,
    octave_cost, octave_jump_cost, voiced_unvoiced_cost)
  Pitch(.xptr = pitch_ptr)
}

.sound_methods$to_pitch_shs <- function(.self, time_step = 0.01, pitch_floor = 50.0,
                                         max_frequency = 1250.0, pitch_ceiling = 500.0,
                                         max_subharmonics = 15L, max_candidates = 15L,
                                         compression_factor = 0.84,
                                         n_points_per_octave = 48L) {
  .check_pitch_range(pitch_floor, pitch_ceiling)
  pitch_ptr <- .sound_to_pitch_shs(
    .self$.xptr, time_step, pitch_floor, max_frequency, pitch_ceiling,
    as.integer(max_subharmonics), as.integer(max_candidates),
    compression_factor, as.integer(n_points_per_octave))
  Pitch(.xptr = pitch_ptr)
}

.sound_methods$to_pitch_spinet <- function(.self, time_step = 0.005, window_duration = 0.04,
                                            min_frequency = 70.0, max_frequency = 5000.0,
                                            n_filters = 250L, pitch_ceiling = 500.0,
                                            max_candidates = 15L) {
  pitch_ptr <- .sound_to_pitch_spinet(
    .self$.xptr, time_step, window_duration, min_frequency, max_frequency,
    as.integer(n_filters), pitch_ceiling, as.integer(max_candidates))
  Pitch(.xptr = pitch_ptr)
}

.sound_methods$to_formant_keepall <- function(.self, time_step = 0.005, max_formants = 5.0,
                                               max_frequency = 5500.0, window_length = 0.025,
                                               pre_emphasis_from = 50.0) {
  .check_positive_number(time_step, "time_step")
  .check_positive_number(max_frequency, "max_frequency")
  .check_positive_number(window_length, "window_length")
  formant_ptr <- .formant_from_sound_keepall(
    .self$.xptr, time_step, max_formants, max_frequency, window_length, pre_emphasis_from)
  Formant(.xptr = formant_ptr)
}

.sound_methods$to_formant_willems <- function(.self, time_step = 0.005, number_of_formants = 5.0,
                                               max_frequency = 5500.0, window_length = 0.025,
                                               pre_emphasis_from = 50.0) {
  .check_positive_number(time_step, "time_step")
  .check_positive_count(number_of_formants, "number_of_formants")
  .check_positive_number(max_frequency, "max_frequency")
  .check_positive_number(window_length, "window_length")
  formant_ptr <- .formant_from_sound_willems(
    .self$.xptr, time_step, number_of_formants, max_frequency, window_length, pre_emphasis_from)
  Formant(.xptr = formant_ptr)
}

.sound_methods$to_formant_sl <- function(.self, time_step = 0.005, number_of_poles = 10L,
                                          max_frequency = 5500.0, window_length = 0.025,
                                          pre_emphasis_from = 50.0) {
  .check_positive_number(time_step, "time_step")
  .check_positive_count(number_of_poles, "number_of_poles")
  .check_positive_number(max_frequency, "max_frequency")
  .check_positive_number(window_length, "window_length")
  formant_ptr <- .formant_from_sound_sl(
    .self$.xptr, time_step, as.integer(number_of_poles), max_frequency, window_length, pre_emphasis_from)
  Formant(.xptr = formant_ptr)
}

.sound_methods$to_harmonicity_ac <- function(.self, time_step = 0.01, min_pitch = 75.0,
                                              silence_threshold = 0.1, periods_per_window = 1.0) {
  hnr_ptr <- .sound_to_harmonicity_ac(.self$.xptr, time_step, min_pitch, silence_threshold, periods_per_window)
  Harmonicity(.xptr = hnr_ptr)
}

.sound_methods$to_ltas <- function(.self, bandwidth = 100.0) {
  ltas_ptr <- .sound_to_ltas(.self$.xptr, bandwidth)
  Ltas(.xptr = ltas_ptr)
}

.sound_methods$to_formant_path <- function(.self, time_step = 0.005,
                                            max_num_formants = 5.0,
                                            formant_ceiling = 5500.0,
                                            window_length = 0.025,
                                            preemphasis_from = 50.0,
                                            ceiling_step_fraction = 0.05,
                                            num_steps_up_down = 4L) {
  FormantPath(.self, time_step, max_num_formants, formant_ceiling,
              window_length, preemphasis_from, ceiling_step_fraction, num_steps_up_down)
}

.sound_methods$to_complex_spectrogram <- function(.self, window_length = 0.005, maximum_frequency = 5000.0) {
  ComplexSpectrogram(.self, window_length, maximum_frequency)
}

.sound_methods$to_textgrid_silences <- function(.self, min_pitch = 100.0, time_step = 0.0,
                                                 silence_threshold = -25.0,
                                                 min_silent_duration = 0.1,
                                                 min_sounding_duration = 0.1,
                                                 silent_label = "silent",
                                                 sounding_label = "sounding") {
  tg_ptr <- .sound_to_textgrid_silences(
    .self$.xptr, min_pitch, time_step, silence_threshold,
    min_silent_duration, min_sounding_duration, silent_label, sounding_label)
  TextGrid(.xptr = tg_ptr)
}

.sound_methods$to_cochleagram <- function(.self, dt = 0.01, df = 0.1, window_length = 0.03,
                                           forward_masking_time = 0.03) {
  stopifnot(
    "dt must be a positive number" = is.numeric(dt) && length(dt) == 1 && dt > 0,
    "df must be a positive number" = is.numeric(df) && length(df) == 1 && df > 0,
    "window_length must be a positive number" = is.numeric(window_length) && length(window_length) == 1 && window_length > 0,
    "forward_masking_time must be a non-negative number" = is.numeric(forward_masking_time) && length(forward_masking_time) == 1 && forward_masking_time >= 0)
  cochleagram_ptr <- .sound_to_cochleagram(.self$.xptr, dt, df, window_length, forward_masking_time)
  Cochleagram(.xptr = cochleagram_ptr)
}

.sound_methods$to_cochleagram_edb <- function(.self, dtime = 0.01, dfreq = 0.1, has_synapse = TRUE,
                                               replenishment_rate = 0.01, loss_rate = 0.1,
                                               return_rate = 0.05, reprocessing_rate = 0.01) {
  sampling_rate <- .self$.cpp$get_sampling_frequency()
  if (sampling_rate < 44100) {
    stop("Cochleagram EDB algorithm is unstable with sampling rates < 44.1kHz\n",
         sprintf("  Current rate: %.0f Hz\n", sampling_rate),
         "  Recommendation: Use $to_cochleagram() instead, which is more stable.",
         call. = FALSE)
  }
  cochleagram_ptr <- .sound_to_cochleagram_edb(
    .self$.xptr, dtime, dfreq, has_synapse,
    replenishment_rate, loss_rate, return_rate, reprocessing_rate)
  Cochleagram(.xptr = cochleagram_ptr)
}

.sound_methods$to_powercepstrogram <- function(.self, pitch_floor = 60.0, time_step = 0.002,
                                                maximum_frequency = 5000.0, pre_emphasis_frequency = 50.0) {
  pcep_ptr <- .sound_to_powercepstrogram(.self$.xptr, pitch_floor, time_step, maximum_frequency, pre_emphasis_frequency)
  PowerCepstrogram(.xptr = pcep_ptr)
}

.sound_methods$to_cepstrum <- function(.self) {
  xptr <- .sound_to_cepstrum(.self$.xptr)
  Cepstrum(.xptr = xptr)
}

.sound_methods$to_cepstrum_bw <- function(.self) {
  xptr <- .sound_to_cepstrum_bw(.self$.xptr)
  Cepstrum(.xptr = xptr)
}

.sound_methods$to_manipulation <- function(.self, time_step = 0.01, pitch_floor = 75.0, pitch_ceiling = 600.0) {
  .check_pitch_range(pitch_floor, pitch_ceiling)
  manip_ptr <- .manipulation_from_sound(.self$.xptr, time_step, pitch_floor, pitch_ceiling)
  Manipulation(.xptr = manip_ptr)
}

.sound_methods$to_lpc_burg <- function(.self, prediction_order = 16, analysis_width = 0.025,
                                        time_step = 0.005, pre_emphasis_frequency = 50.0) {
  lpc_ptr <- .sound_to_lpc_burg(
    .self$.xptr, as.integer(prediction_order), analysis_width, time_step, pre_emphasis_frequency)
  LPC(.xptr = lpc_ptr)
}

.sound_methods$to_lpc_auto <- function(.self, prediction_order = 16, analysis_width = 0.025,
                                        time_step = 0.005, pre_emphasis_frequency = 50.0) {
  lpc_ptr <- .sound_to_lpc_auto(
    .self$.xptr, as.integer(prediction_order), analysis_width, time_step, pre_emphasis_frequency)
  LPC(.xptr = lpc_ptr)
}

.sound_methods$to_lpc_covariance <- function(.self, prediction_order = 16, analysis_width = 0.025,
                                              time_step = 0.005, pre_emphasis_frequency = 50.0) {
  lpc_ptr <- .sound_to_lpc_covariance(
    .self$.xptr, as.integer(prediction_order), analysis_width, time_step, pre_emphasis_frequency)
  LPC(.xptr = lpc_ptr)
}

.sound_methods$to_lpc_marple <- function(.self, prediction_order = 16, analysis_width = 0.025,
                                          time_step = 0.005, pre_emphasis_frequency = 50.0,
                                          tol1 = 1e-6, tol2 = 1e-6) {
  lpc_ptr <- .sound_to_lpc_marple(
    .self$.xptr, as.integer(prediction_order), analysis_width,
    time_step, pre_emphasis_frequency, tol1, tol2)
  LPC(.xptr = lpc_ptr)
}

.sound_methods$to_mfcc <- function(.self, num_coefficients = 13, analysis_width = 0.025,
                                    time_step = 0.01, f1_mel = 100.0, fmax_mel = 7800.0,
                                    df_mel = 100.0) {
  mfcc_mod <- get_module("mfcc_module")
  mfcc_ptr <- mfcc_mod$Sound_to_MFCC(
    .self$.xptr, as.integer(num_coefficients), analysis_width, time_step, f1_mel, fmax_mel, df_mel)
  MFCC(.xptr = mfcc_ptr)
}

.sound_methods$to_dtw <- function(.self, reference, analysis_width = 0.015, time_step = 0.005,
                                   band = 0.0, slope = 3) {
  if (!inherits(reference, "Sound")) stop("reference must be a Sound object")
  sounds_to_dtw(reference, .self, analysis_width, time_step, band, slope)
}

.sound_methods$to_point_process_extrema <- function(.self, channel = 1, include_maxima = TRUE,
                                                     include_minima = FALSE,
                                                     interpolation = c("None", "Parabolic", "Cubic", "Sinc70", "Sinc700")) {
  interpolation <- match.arg(interpolation)
  interpolation_int <- switch(interpolation,
    "None" = 0, "Parabolic" = 1, "Cubic" = 2, "Sinc70" = 3, "Sinc700" = 4, 1)
  pp_ptr <- .sound_to_point_process_extrema(
    .self$.xptr, as.integer(channel), as.logical(include_maxima),
    as.logical(include_minima), interpolation_int)
  PointProcess(.xptr = pp_ptr)
}

.sound_methods$to_point_process_zeros <- function(.self, channel = 1, include_raisers = TRUE,
                                                   include_fallers = FALSE) {
  pp_ptr <- .sound_to_point_process_zeros(
    .self$.xptr, as.integer(channel), as.logical(include_raisers), as.logical(include_fallers))
  PointProcess(.xptr = pp_ptr)
}

.sound_methods$to_point_process_periodic_peaks <- function(.self, pitch_floor = 75.0, pitch_ceiling = 600.0,
                                                            include_maxima = TRUE, include_minima = FALSE) {
  .check_pitch_range(pitch_floor, pitch_ceiling)
  pp_ptr <- .sound_to_pointprocess_periodic_peaks(
    .self$.xptr, pitch_floor, pitch_ceiling, include_maxima, include_minima)
  PointProcess(.xptr = pp_ptr)
}

# Backward-compat aliases (delegate to canonical names)
.sound_methods$to_pointprocess_periodic_cc <- function(.self, time_step = 0.0, pitch_floor = 75.0,
                                                        pitch_ceiling = 600.0, max_period_factor = 1.3,
                                                        max_amplitude_factor = 1.6) {
  .self$to_point_process_periodic_cc(pitch_floor = pitch_floor, pitch_ceiling = pitch_ceiling,
    time_step = time_step, max_period_factor = max_period_factor,
    max_amplitude_factor = max_amplitude_factor)
}

.sound_methods$to_pointprocess_periodic_peaks <- function(.self, pitch_floor = 75.0, pitch_ceiling = 600.0,
                                                           include_maxima = TRUE, include_minima = FALSE) {
  .self$to_point_process_periodic_peaks(pitch_floor, pitch_ceiling, include_maxima, include_minima)
}

# --- Modification Methods (in-place, return self) ---
.sound_methods$scale_intensity <- function(.self, new_intensity_db) {
  .sound_scale_intensity(.self$.xptr, new_intensity_db)
  invisible(.self)
}

.sound_methods$scale_peak <- function(.self, new_peak = 0.99) {
  .sound_scale_peak(.self$.xptr, new_peak)
  invisible(.self)
}

.sound_methods$pre_emphasize <- function(.self, from_frequency = 50.0) {
  .sound_pre_emphasize(.self$.xptr, from_frequency)
  invisible(.self)
}

.sound_methods$de_emphasize <- function(.self, from_frequency = 50.0) {
  .sound_de_emphasize(.self$.xptr, from_frequency)
  invisible(.self)
}

.sound_methods$filter_pass_hann_band <- function(.self, fmin, fmax, smooth = 100.0) {
  if (fmin < 0 || fmax <= fmin) stop("Invalid frequency range: fmin must be >= 0 and fmax must be > fmin")
  sound_ptr <- .sound_filter_pass_hann_band(.self$.xptr, fmin, fmax, smooth)
  Sound(.xptr = sound_ptr)
}

.sound_methods$filter_stop_hann_band <- function(.self, fmin, fmax, smooth = 100.0) {
  if (fmin < 0 || fmax <= fmin) stop("Invalid frequency range: fmin must be >= 0 and fmax must be > fmin")
  sound_ptr <- .sound_filter_stop_hann_band(.self$.xptr, fmin, fmax, smooth)
  Sound(.xptr = sound_ptr)
}

.sound_methods$resample <- function(.self, new_frequency, precision = 50) {
  if (new_frequency <= 0) stop("new_frequency must be positive")
  sound_ptr <- .sound_resample(.self$.xptr, new_frequency, as.integer(precision))
  Sound(.xptr = sound_ptr)
}

.sound_methods$convert_to_mono <- function(.self) {
  if (.self$.cpp$get_number_of_channels() == 1) message("Sound is already mono, returning copy")
  sound_ptr <- .sound_convert_to_mono(.self$.xptr)
  Sound(.xptr = sound_ptr)
}

.sound_methods$convert_to_stereo <- function(.self) {
  if (.self$.cpp$get_number_of_channels() > 1) {
    warning("Sound is already multi-channel, returning as-is")
    sound_ptr <- .sound_copy(.self$.xptr)
  } else {
    sound_ptr <- .sound_convert_to_stereo(.self$.xptr)
  }
  Sound(.xptr = sound_ptr)
}

.sound_methods$concatenate <- function(.self, other_sound, overlap = 0) {
  if (!inherits(other_sound, "Sound")) stop("other_sound must be a Sound object")
  if (!other_sound$is_valid()) stop("other_sound is not a valid Sound object")
  sound_ptr <- .sound_concatenate(.self$.xptr, other_sound$.xptr, overlap)
  Sound(.xptr = sound_ptr)
}

.sound_methods$mix <- function(.self, other_sound, balance = 1.0) {
  if (!inherits(other_sound, "Sound")) stop("other_sound must be a Sound object")
  if (!other_sound$is_valid()) stop("other_sound is not a valid Sound object")
  sound_ptr <- .sound_mix(.self$.xptr, other_sound$.xptr, balance)
  Sound(.xptr = sound_ptr)
}

.sound_methods$extract_intervals_where <- function(.self, textgrid, tier_number, criterion = "is equal to",
                                                    text = "", preserve_times = FALSE) {
  if (!inherits(textgrid, "TextGrid")) stop("textgrid must be a TextGrid object")
  textgrid$extract_intervals_where(.self, tier_number, criterion, text, preserve_times)
}

# --- Tier 1: Advanced audio methods ---
.sound_methods$lengthen <- function(.self, fmin = 75, fmax = 600, factor = 1.5) {
  sound_ptr <- .sound_lengthen_ola(.self$.xptr, fmin, fmax, factor)
  Sound(.xptr = sound_ptr)
}

.sound_methods$to_ltas_pitch_corrected <- function(.self, pitch_floor = 75, pitch_ceiling = 600,
                                                    max_frequency = 5000, bandwidth = 100,
                                                    shortest_period = 0.0001, longest_period = 0.02,
                                                    max_period_factor = 1.3) {
  .check_pitch_range(pitch_floor, pitch_ceiling)
  ltas_ptr <- .sound_to_ltas_pitch_corrected(
    .self$.xptr, pitch_floor, pitch_ceiling, max_frequency, bandwidth,
    shortest_period, longest_period, max_period_factor)
  Ltas(.xptr = ltas_ptr)
}

.sound_methods$to_formant_robust <- function(.self, time_step = 0.005, max_formants = 5.0,
                                              max_frequency = 5500.0, window_length = 0.025,
                                              pre_emphasis_from = 50.0,
                                              num_std_dev = 1.5, max_iterations = 5L) {
  formant_ptr <- .sound_to_formant_robust(
    .self$.xptr, time_step, max_formants, max_frequency, window_length, pre_emphasis_from,
    num_std_dev, as.integer(max_iterations))
  Formant(.xptr = formant_ptr)
}

.sound_methods$filter_by_formant <- function(.self, formant) {
  if (!inherits(formant, "Formant")) stop("formant must be a Formant object")
  sound_ptr <- .sound_formant_filter(.self$.xptr, formant$.xptr)
  Sound(.xptr = sound_ptr)
}

.sound_methods$filter_by_formant_noscale <- function(.self, formant) {
  if (!inherits(formant, "Formant")) stop("formant must be a Formant object")
  sound_ptr <- .sound_formant_filter_noscale(.self$.xptr, formant$.xptr)
  Sound(.xptr = sound_ptr)
}

.sound_methods$to_mel_spectrogram <- function(.self, window_length = 0.015, time_step = 0.005,
                                               first_filter_frequency = 100,
                                               max_frequency = 0, frequency_step = 100) {
  mel_ptr <- .sound_to_mel_spectrogram(
    .self$.xptr, window_length, time_step, first_filter_frequency, max_frequency, frequency_step)
  MelSpectrogram(.xptr = mel_ptr)
}

.sound_methods$to_bark_spectrogram <- function(.self, window_length = 0.015, time_step = 0.005,
                                                first_filter_frequency = 1.0,
                                                max_frequency = 0, frequency_step = 1.0) {
  bark_ptr <- .sound_to_bark_spectrogram(
    .self$.xptr, window_length, time_step, first_filter_frequency, max_frequency, frequency_step)
  BarkSpectrogram(.xptr = bark_ptr)
}

.sound_methods$change_speaker <- function(.self, pitch_floor = 75, pitch_ceiling = 600,
                                           formant_multiplier = 1.0, pitch_multiplier = 1.0,
                                           pitch_range_multiplier = 1.0, duration_multiplier = 1.0) {
  .check_pitch_range(pitch_floor, pitch_ceiling)
  sound_ptr <- .sound_change_speaker(.self$.xptr, pitch_floor, pitch_ceiling,
    formant_multiplier, pitch_multiplier, pitch_range_multiplier, duration_multiplier)
  Sound(.xptr = sound_ptr)
}

.sound_methods$change_speaker_with_pitch <- function(.self, pitch, formant_multiplier = 1.0,
                                                      pitch_multiplier = 1.0,
                                                      pitch_range_multiplier = 1.0,
                                                      duration_multiplier = 1.0) {
  if (!inherits(pitch, "Pitch")) stop("pitch must be a Pitch object")
  sound_ptr <- .sound_pitch_change_speaker(.self$.xptr, pitch$.xptr,
    formant_multiplier, pitch_multiplier, pitch_range_multiplier, duration_multiplier)
  Sound(.xptr = sound_ptr)
}

.sound_methods$autocorrelate <- function(.self, scaling = "peak_0.99", signal_outside = "zero") {
  sc <- match.arg(scaling, c("integral", "sum", "normalize", "peak_0.99"))
  so <- match.arg(signal_outside, c("zero", "similar"))
  sc_code <- match(sc, c("integral", "sum", "normalize", "peak_0.99"))
  so_code <- match(so, c("zero", "similar"))
  sound_ptr <- .sound_autocorrelate(.self$.xptr, as.integer(sc_code), as.integer(so_code))
  Sound(.xptr = sound_ptr)
}

.sound_methods$convolve <- function(.self, other_sound, scaling = "peak_0.99", signal_outside = "zero") {
  if (!inherits(other_sound, "Sound")) stop("other_sound must be a Sound object")
  sc <- match.arg(scaling, c("integral", "sum", "normalize", "peak_0.99"))
  so <- match.arg(signal_outside, c("zero", "similar"))
  sc_code <- match(sc, c("integral", "sum", "normalize", "peak_0.99"))
  so_code <- match(so, c("zero", "similar"))
  sound_ptr <- .sounds_convolve_direct(.self$.xptr, other_sound$.xptr, as.integer(sc_code), as.integer(so_code))
  Sound(.xptr = sound_ptr)
}

.sound_methods$cross_correlate <- function(.self, other_sound, scaling = "peak_0.99", signal_outside = "zero") {
  if (!inherits(other_sound, "Sound")) stop("other_sound must be a Sound object")
  sc <- match.arg(scaling, c("integral", "sum", "normalize", "peak_0.99"))
  so <- match.arg(signal_outside, c("zero", "similar"))
  sc_code <- match(sc, c("integral", "sum", "normalize", "peak_0.99"))
  so_code <- match(so, c("zero", "similar"))
  sound_ptr <- .sounds_cross_correlate_direct(.self$.xptr, other_sound$.xptr, as.integer(sc_code), as.integer(so_code))
  Sound(.xptr = sound_ptr)
}

.sound_methods$deepen_band_modulation <- function(.self, enhancement_db = 10, flow = 300, fhigh = 4000,
                                                   slow_modulation = 3, fast_modulation = 30,
                                                   band_smoothing = 100) {
  sound_ptr <- .sound_deepen_band_mod(
    .self$.xptr, enhancement_db, flow, fhigh, slow_modulation, fast_modulation, band_smoothing)
  Sound(.xptr = sound_ptr)
}

# --- Print ---
.sound_methods$print <- function(.self) {
  if (!.self$.cpp$is_valid()) {
    cat("<Sound [invalid]>\n")
    return(invisible(.self))
  }
  cat("<Praat Sound>\n")
  cat(sprintf("  Duration: %.3f s\n", .self$.cpp$get_duration()))
  cat(sprintf("  Sampling frequency: %.0f Hz\n", .self$.cpp$get_sampling_frequency()))
  cat(sprintf("  Number of samples: %d\n", .self$.cpp$get_number_of_samples()))
  cat(sprintf("  Number of channels: %d\n", .self$.cpp$get_number_of_channels()))
  intensity_db <- tryCatch(.self$.cpp$get_intensity_db(), error = function(e) NA)
  if (!is.na(intensity_db)) {
    cat(sprintf("  Intensity: %.1f dB\n", intensity_db))
  }
  invisible(.self)
}

# Lock the method environment to prevent accidental modification
lockEnvironment(.sound_methods, bindings = TRUE)

# ============================================================================
# S3 Dispatch for Sound objects
# ============================================================================
# $.Sound intercepts method calls and dispatches to the shared table.
# Field access (.xptr, .cpp) goes through .subset2 (fast path).
# Method calls create a lightweight closure binding .self.

#' @method $ Sound
#' @export
`$.Sound` <- function(x, name) {
  # Fast path: direct field access (.xptr, .cpp stored in the list)
  val <- .subset2(x, name)
  if (!is.null(val)) return(val)
  # Compatibility alias
  if (name == ".pointer") return(.subset2(x, ".xptr"))
  # Method lookup in shared table
  method <- .sound_methods[[name]]
  if (is.null(method)) return(NULL)
  # Return bound method — creates one lightweight closure per $ access
  function(...) method(x, ...)
}

# ============================================================================
# Constructor
# ============================================================================

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

      # av returns samples x channels matrix, we need channels x samples
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

  # Load Rcpp Module and create C++ wrapper
  snd_mod <- get_module("sound_module")
  cpp_snd <- snd_mod$RSound$new(ptr)

  # Minimal object: just fields, no closures. Methods via $.Sound dispatch.
  structure(list(.xptr = ptr, .cpp = cpp_snd), class = c("Sound", "PraatObject"))
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

#' Create a pure tone with fade in/out
#'
#' Creates a sinusoidal pure tone with optional fade in/out envelopes.
#'
#' @param frequency Frequency in Hz (default: 440)
#' @param duration Duration in seconds (default: 1.0)
#' @param sampling_rate Sampling rate in Hz (default: 44100)
#' @param amplitude Peak amplitude (default: 0.99)
#' @param fade_in_duration Fade-in duration in seconds (default: 0.01)
#' @param fade_out_duration Fade-out duration in seconds (default: 0.01)
#' @param channels Number of channels (default: 1)
#' @return A Sound object
#' @export
#' @examples
#' \dontrun{
#' tone <- sound_create_pure_tone(frequency = 440, duration = 0.5)
#' tone <- Sound$create_pure_tone(frequency = 880, fade_in_duration = 0.05)
#' }
sound_create_pure_tone <- function(frequency = 440.0, duration = 1.0,
                                    sampling_rate = 44100, amplitude = 0.99,
                                    fade_in_duration = 0.01, fade_out_duration = 0.01,
                                    channels = 1L) {
  ptr <- .sound_create_pure_tone(as.integer(channels), 0.0, duration, sampling_rate,
    frequency, amplitude, fade_in_duration, fade_out_duration)
  Sound(.xptr = ptr)
}

#' Create a tone complex (harmonic series)
#'
#' Creates a sound consisting of multiple sinusoids at equal frequency intervals.
#'
#' @param frequency_step Step between harmonics in Hz (default: 100)
#' @param duration Duration in seconds (default: 1.0)
#' @param sampling_rate Sampling rate in Hz (default: 44100)
#' @param phase Phase type: "sine" or "cosine" (default: "sine")
#' @param first_frequency Lowest component frequency in Hz (default: 0, uses frequency_step)
#' @param ceiling Maximum frequency to include in Hz (default: Nyquist)
#' @param number_of_components Number of components (default: 0 = all up to ceiling)
#' @return A Sound object
#' @export
#' @examples
#' \dontrun{
#' # Harmonic tone with 10 components at 100 Hz intervals
#' tone <- sound_create_tone_complex(frequency_step = 100, number_of_components = 10)
#' tone <- Sound$create_tone_complex(frequency_step = 200, phase = "cosine")
#' }
sound_create_tone_complex <- function(frequency_step = 100.0, duration = 1.0,
                                       sampling_rate = 44100,
                                       phase = c("sine", "cosine"),
                                       first_frequency = 0.0,
                                       ceiling = 0.0,
                                       number_of_components = 0L) {
  phase <- match.arg(phase)
  phase_code <- if (phase == "sine") 0L else 1L
  if (ceiling <= 0.0) ceiling <- sampling_rate / 2.0
  if (first_frequency <= 0.0) first_frequency <- frequency_step
  ptr <- .sound_create_tone_complex(0.0, duration, sampling_rate, phase_code,
    frequency_step, first_frequency, ceiling, as.integer(number_of_components))
  Sound(.xptr = ptr)
}

# Make Sound "class" support $ for static methods (backward compatibility)
.sound_static_env <- new.env(parent = emptyenv())
.sound_static_env$from_values <- sound_from_values
.sound_static_env$from_matrix <- sound_from_values  # Alias
.sound_static_env$new_from_values <- sound_from_values  # Alias
.sound_static_env$create_tone <- sound_create_tone
.sound_static_env$create_pure_tone <- sound_create_pure_tone
.sound_static_env$create_tone_complex <- sound_create_tone_complex
.sound_static_env$new <- Sound  # Allow Sound$new() as well as Sound()

#' $ method for Sound constructor (enables Sound$create_tone(), etc.)
#' @param x The Sound constructor function
#' @param name Name of static method to access
#' @return The requested static method function
#' @exportS3Method "$" sound_constructor
`$.sound_constructor` <- function(x, name) {
  val <- .sound_static_env[[name]]
  if (is.null(val)) {
    stop("Sound has no static method '", name, "'. Available: from_values, create_tone, create_pure_tone, create_tone_complex, new")
  }
  val
}

# Assign class to enable $ operator
class(Sound) <- c("sound_constructor", "function")

#' @exportS3Method print Sound
print.Sound <- function(x, ...) x$print()
