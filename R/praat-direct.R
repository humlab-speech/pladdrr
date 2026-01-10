# praat-direct.R
# Direct function dispatch API - bypasses R6 overhead
# pladdrr v2.2.1 - Phase 2 Performance Enhancement
#
# These functions provide 2-3x speedup over R6 method dispatch.
# Output is numerically identical to R6 methods.

#' @name praat_direct
#' @title Direct Function Dispatch API
#'
#' @description
#' These functions provide direct access to Praat operations without R6
#' class dispatch overhead. Use them in performance-critical code where
#' you need maximum speed and are comfortable working with external pointers.
#'
#' **Performance:** 2-3x faster than R6 method calls due to:
#' - No R6 environment lookup
#' - No named parameter matching
#' - No result wrapping
#'
#' **Output:** Numerically identical to R6 methods.
#'
#' @section When to Use:
#' - Processing >100 files in batch
#' - Real-time analysis
#' - Tight loops with many queries
#' - When profiling shows R6 overhead as bottleneck
#'
#' @section When NOT to Use:
#' - Interactive exploration (use R6 for convenience)
#' - Small datasets (overhead is negligible)
#' - When you need method chaining
NULL


# =============================================================================
# Pitch Direct API
# =============================================================================

#' Get Pitch Statistics Directly (2-3x faster)
#'
#' @description
#' Get all common pitch statistics in a single call, bypassing R6 dispatch.
#'
#' @param pitch Pitch object or external pointer
#' @param from_time Start time (0 = start of signal)
#' @param to_time End time (0 = end of signal)
#' @param unit Character: "hertz", "semitones", "mel", "erb", "loghertz"
#'
#' @return Named list with: min, max, mean, stdev, median, q25, q75, count_voiced
#'
#' @examples
#' \dontrun{
#' sound <- Sound("speech.wav")
#' pitch <- sound$to_pitch_cc()
#'
#' # FAST: Direct call (2-3x faster)
#' stats <- get_pitch_stats_direct(pitch)
#'
#' # Equivalent R6 calls (slower, 8 separate boundary crossings):
#' min_val <- pitch$get_minimum(0, 0, "hertz")
#' max_val <- pitch$get_maximum(0, 0, "hertz")
#' # ... etc
#' }
#'
#' @export
get_pitch_stats_direct <- function(pitch, from_time = 0, to_time = 0,
                                    unit = c("hertz", "semitones", "mel", "erb", "loghertz")) {
  # Extract pointer
  pitch_ptr <- if (inherits(pitch, "Pitch")) {
    pitch$.xptr
  } else if (inherits(pitch, "externalptr")) {
    pitch
  } else {
    stop("pitch must be a Pitch object or external pointer")
  }

  # Convert unit
  unit <- match.arg(unit)
  unit_code <- switch(unit,
    hertz = 0L, semitones = 1L, mel = 2L, erb = 3L, loghertz = 4L
  )

  pitch_get_all_stats_direct(pitch_ptr, from_time, to_time, unit_code)
}


#' Get Formant F1-F4 at Time Directly (2-3x faster)
#'
#' @description
#' Get F1, F2, F3, F4 at a single time point in one call.
#'
#' @param formant Formant object or external pointer
#' @param time Time in seconds
#' @param unit Character: "hertz" or "bark"
#'
#' @return Named numeric vector: F1, F2, F3, F4
#'
#' @examples
#' \dontrun{
#' sound <- Sound("speech.wav")
#' formant <- sound$to_formant_burg()
#'
#' # FAST: Get all 4 formants in one call
#' f1_f4 <- get_formants_direct(formant, time = 0.5)
#'
#' # Equivalent R6 calls (4x slower):
#' f1 <- formant$get_value_at_time(1, 0.5, "hertz")
#' f2 <- formant$get_value_at_time(2, 0.5, "hertz")
#' # ... etc
#' }
#'
#' @export
get_formants_direct <- function(formant, time, unit = c("hertz", "bark")) {
  formant_ptr <- if (inherits(formant, "Formant")) {
    formant$.xptr
  } else if (inherits(formant, "externalptr")) {
    formant
  } else {
    stop("formant must be a Formant object or external pointer")
  }

  unit <- match.arg(unit)
  unit_code <- switch(unit, hertz = 0L, bark = 1L)

  formant_get_f1_f4_direct(formant_ptr, time, unit_code)
}


# =============================================================================
# Conversion Direct API (returns XPtrs, not R6 objects)
# =============================================================================

#' Create Pitch from Sound Directly (returns XPtr)
#'
#' @description
#' Create Pitch analysis directly, returning raw external pointer.
#' Use when you need maximum performance and will pass result to
#' other direct functions.
#'
#' @param sound Sound object or external pointer
#' @param time_step Time step (0 = auto)
#' @param pitch_floor Minimum pitch (Hz)
#' @param pitch_ceiling Maximum pitch (Hz)
#'
#' @return External pointer to Pitch (NOT R6 object)
#'
#' @examples
#' \dontrun{
#' sound <- Sound("speech.wav")
#'
#' # FAST: Returns raw pointer
#' pitch_ptr <- to_pitch_direct(sound)
#'
#' # Use with other direct functions
#' stats <- pitch_get_all_stats_direct(pitch_ptr, 0, 0, 0L)
#'
#' # Or wrap in R6 if needed later
#' pitch <- Pitch$new(.xptr = pitch_ptr)
#' }
#'
#' @export
to_pitch_direct <- function(sound, time_step = 0, pitch_floor = 75, pitch_ceiling = 600) {
  sound_ptr <- if (inherits(sound, "Sound")) {
    sound$.xptr
  } else if (inherits(sound, "externalptr")) {
    sound
  } else {
    stop("sound must be a Sound object or external pointer")
  }

  sound_to_pitch_direct(sound_ptr, time_step, pitch_floor, pitch_ceiling)
}


#' Create Formant from Sound Directly (returns XPtr)
#'
#' @param sound Sound object or external pointer
#' @param time_step Time step (0 = auto)
#' @param max_formants Maximum number of formants
#' @param max_formant Maximum formant frequency (Hz)
#' @param window_length Window length (seconds)
#' @param pre_emphasis Pre-emphasis frequency (Hz)
#'
#' @return External pointer to Formant
#'
#' @export
to_formant_direct <- function(sound, time_step = 0, max_formants = 5,
                               max_formant = 5500, window_length = 0.025,
                               pre_emphasis = 50) {
  sound_ptr <- if (inherits(sound, "Sound")) {
    sound$.xptr
  } else if (inherits(sound, "externalptr")) {
    sound
  } else {
    stop("sound must be a Sound object or external pointer")
  }

  sound_to_formant_direct(sound_ptr, time_step, max_formants, max_formant,
                           window_length, pre_emphasis)
}


#' Create Intensity from Sound Directly (returns XPtr)
#'
#' @param sound Sound object or external pointer
#' @param minimum_pitch Minimum pitch (Hz)
#' @param time_step Time step (0 = auto)
#' @param subtract_mean Whether to subtract mean
#'
#' @return External pointer to Intensity
#'
#' @export
to_intensity_direct <- function(sound, minimum_pitch = 100, time_step = 0,
                                 subtract_mean = TRUE) {
  sound_ptr <- if (inherits(sound, "Sound")) {
    sound$.xptr
  } else if (inherits(sound, "externalptr")) {
    sound
  } else {
    stop("sound must be a Sound object or external pointer")
  }

  sound_to_intensity_direct(sound_ptr, minimum_pitch, time_step, subtract_mean)
}


#' Create Harmonicity from Sound Directly (returns XPtr)
#'
#' @param sound Sound object or external pointer
#' @param time_step Time step
#' @param minimum_pitch Minimum pitch (Hz)
#' @param silence_threshold Silence threshold
#' @param periods_per_window Periods per window
#'
#' @return External pointer to Harmonicity
#'
#' @export
to_harmonicity_direct <- function(sound, time_step = 0.01, minimum_pitch = 75,
                                   silence_threshold = 0.1, periods_per_window = 1.0) {
  sound_ptr <- if (inherits(sound, "Sound")) {
    sound$.xptr
  } else if (inherits(sound, "externalptr")) {
    sound
  } else {
    stop("sound must be a Sound object or external pointer")
  }

  sound_to_harmonicity_direct(sound_ptr, time_step, minimum_pitch,
                               silence_threshold, periods_per_window)
}


# =============================================================================
# Single Value Direct Queries
# =============================================================================

#' Get Single Pitch Value Directly
#'
#' @param pitch Pitch object or external pointer
#' @param time Time in seconds
#' @param unit Unit string
#' @param interpolate Whether to interpolate
#'
#' @return Pitch value
#' @export
get_pitch_value_direct <- function(pitch, time, unit = "hertz", interpolate = TRUE) {
  pitch_ptr <- if (inherits(pitch, "Pitch")) pitch$.xptr else pitch
  unit_code <- switch(unit, hertz = 0L, semitones = 1L, mel = 2L, erb = 3L, loghertz = 4L, 0L)
  pitch_get_value_direct(pitch_ptr, time, unit_code, interpolate)
}

#' Get Single Intensity Value Directly
#'
#' @param intensity Intensity object or external pointer
#' @param time Time in seconds
#' @param interpolation Interpolation method
#'
#' @return Intensity in dB
#' @export
get_intensity_value_direct <- function(intensity, time, interpolation = "cubic") {
  intensity_ptr <- if (inherits(intensity, "Intensity")) intensity$.xptr else intensity
  interp_code <- switch(interpolation, nearest = 0L, linear = 1L, cubic = 2L, sinc70 = 3L, sinc700 = 4L, 2L)
  intensity_get_value_direct(intensity_ptr, time, interp_code)
}

#' Get Single Formant Value Directly
#'
#' @param formant Formant object or external pointer
#' @param formant_number Formant number (1=F1, etc)
#' @param time Time in seconds
#' @param unit Unit string
#'
#' @return Formant frequency
#' @export
get_formant_value_direct <- function(formant, formant_number, time, unit = "hertz") {
  formant_ptr <- if (inherits(formant, "Formant")) formant$.xptr else formant
  unit_code <- switch(unit, hertz = 0L, bark = 1L, 0L)
  formant_get_value_direct(formant_ptr, formant_number, time, unit_code)
}


# =============================================================================
# Additional Conversion Functions (Phase 3)
# =============================================================================

#' Create Spectrum from Sound Directly (returns XPtr)
#'
#' @param sound Sound object or external pointer
#' @param fast Logical. Use fast algorithm (default: TRUE)
#'
#' @return External pointer to Spectrum
#'
#' @examples
#' \dontrun{
#' sound <- Sound("voice.wav")
#' # Fast direct conversion
#' spec_ptr <- to_spectrum_direct(sound)
#' spec <- Spectrum(.xptr = spec_ptr)
#' }
#'
#' @export
to_spectrum_direct <- function(sound, fast = TRUE) {
  sound_ptr <- extract_xptr(sound, "Sound")
  
  # Use module method if available
  if (inherits(sound, "Sound") && !is.null(sound$.cpp)) {
    return(sound$.cpp$to_spectrum_ptr(as.logical(fast)))
  }
  
  # Fallback to wrapper function
  .sound_to_spectrum(sound_ptr, as.logical(fast))
}


#' Create Spectrogram from Sound Directly (returns XPtr)
#'
#' @param sound Sound object or external pointer
#' @param window_length Numeric. Window length in seconds (default: 0.005)
#' @param max_frequency Numeric. Maximum frequency in Hz (default: 5000)
#' @param time_step Numeric. Time step in seconds (default: 0.002)
#' @param frequency_step Numeric. Frequency step in Hz (default: 20)
#' @param window_shape Character. Window shape (default: "Gaussian")
#'
#' @return External pointer to Spectrogram
#'
#' @examples
#' \dontrun{
#' sound <- Sound("voice.wav")
#' # Fast direct conversion
#' spg_ptr <- to_spectrogram_direct(sound, window_length = 0.005)
#' spg <- Spectrogram(.xptr = spg_ptr)
#' }
#'
#' @export
to_spectrogram_direct <- function(sound, window_length = 0.005, 
                                   max_frequency = 5000.0,
                                   time_step = 0.002, 
                                   frequency_step = 20.0,
                                   window_shape = "Gaussian") {
  sound_ptr <- extract_xptr(sound, "Sound")
  
  # Use module method if available
  if (inherits(sound, "Sound") && !is.null(sound$.cpp)) {
    return(sound$.cpp$to_spectrogram_ptr(
      as.numeric(window_length),
      as.numeric(max_frequency),
      as.numeric(time_step),
      as.numeric(frequency_step),
      as.character(window_shape)
    ))
  }
  
  # Fallback to wrapper function
  .sound_to_spectrogram(sound_ptr, window_length, max_frequency, 
                        time_step, frequency_step, window_shape)
}


#' Create LTAS from Sound Directly (returns XPtr)
#'
#' @param sound Sound object or external pointer
#' @param bandwidth Numeric. Bandwidth in Hz (default: 100)
#'
#' @return External pointer to Ltas
#'
#' @examples
#' \dontrun{
#' sound <- Sound("voice.wav")
#' # Fast direct conversion
#' ltas_ptr <- to_ltas_direct(sound, bandwidth = 100)
#' ltas <- Ltas(.xptr = ltas_ptr)
#' }
#'
#' @export
to_ltas_direct <- function(sound, bandwidth = 100.0) {
  sound_ptr <- extract_xptr(sound, "Sound")
  .sound_to_ltas(sound_ptr, as.numeric(bandwidth))
}


#' Create PointProcess from Sound Directly (returns XPtr)
#'
#' @param sound Sound object or external pointer
#' @param pitch_floor Numeric. Minimum pitch in Hz (default: 75)
#' @param pitch_ceiling Numeric. Maximum pitch in Hz (default: 600)
#' @param max_period_factor Numeric. Max period factor (default: 1.3)
#' @param max_amplitude_factor Numeric. Max amplitude factor (default: 1.6)
#'
#' @return External pointer to PointProcess
#'
#' @examples
#' \dontrun{
#' sound <- Sound("voice.wav")
#' # Extract glottal pulses
#' pp_ptr <- to_point_process_direct(sound, pitch_floor = 75, pitch_ceiling = 300)
#' pp <- PointProcess(.xptr = pp_ptr)
#' }
#'
#' @export
to_point_process_direct <- function(sound, pitch_floor = 75.0, 
                                     pitch_ceiling = 600.0,
                                     max_period_factor = 1.3,
                                     max_amplitude_factor = 1.6) {
  sound_ptr <- extract_xptr(sound, "Sound")
  
  # Use module method if available
  if (inherits(sound, "Sound") && !is.null(sound$.cpp)) {
    return(sound$.cpp$to_point_process_periodic_cc_ptr(
      as.numeric(pitch_floor),
      as.numeric(pitch_ceiling),
      as.numeric(max_period_factor),
      as.numeric(max_amplitude_factor)
    ))
  }
  
  # Fallback
  .sound_to_point_process_periodic_cc(sound_ptr, pitch_floor, pitch_ceiling,
                                       max_period_factor, max_amplitude_factor)
}
