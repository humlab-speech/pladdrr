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
#' class dispatch overhead — no R6 environment lookup, no named parameter
#' matching, no result wrapping. Use them in tight loops where you are
#' comfortable working with external pointers instead of R6 objects.
#'
#' **Output:** Numerically identical to R6 methods.
#'
#' @section When to Use:
#' - Processing many files in a batch loop
#' - Latency-sensitive analysis pipelines
#' - Tight loops with many queries
#' - When profiling shows R6 dispatch overhead as a bottleneck
#'
#' @section When NOT to Use:
#' - Interactive exploration (use R6 for convenience)
#' - Small datasets (overhead is negligible)
#' - When you need method chaining
#'
#' @return This is a documentation-only overview; see the individual
#'   functions (e.g. \code{\link{to_point_process_direct}},
#'   \code{\link{pp_get_mean_period_direct}}) for their return values.
#'
#' @examples
#' # See individual functions, e.g. ?pp_get_mean_period_direct
NULL


# =============================================================================
# Pitch Direct API
# =============================================================================

#' Get Pitch Statistics Directly
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
#' sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
#' pitch <- sound$to_pitch_cc()
#'
#' # Direct call
#' stats <- get_pitch_stats_direct(pitch)
#'
#' # Equivalent R6 calls, one boundary crossing per statistic:
#' min_val <- pitch$get_minimum(0, 0, "hertz")
#' max_val <- pitch$get_maximum(0, 0, "hertz")
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


#' Get Formant F1-F4 at Time Directly
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
#' sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate = 16000)
#' formant <- sound$to_formant_burg()
#'
#' # Get all 4 formants in one call
#' f1_f4 <- get_formants_direct(formant, time = 0.25)
#'
#' # Equivalent R6 calls, one boundary crossing per formant:
#' f1 <- formant$get_value_at_time(1, 0.25, "hertz")
#' f2 <- formant$get_value_at_time(2, 0.25, "hertz")
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

#' Create Pitch from Sound Directly (returns XPtr) - Basic Parameters
#'
#' @description
#' Create Pitch analysis directly, returning raw external pointer.
#' This is a simplified version with basic parameters only.
#'
#' **NOTE:** For full control over voicing parameters (silence_threshold,
#' voicing_threshold, etc.), use `to_pitch_ac_direct()` or `to_pitch_cc_direct()`
#' instead.
#'
#' @param sound Sound object or external pointer
#' @param time_step Time step (0 = auto)
#' @param pitch_floor Minimum pitch (Hz)
#' @param pitch_ceiling Maximum pitch (Hz)
#'
#' @return External pointer to Pitch (NOT R6 object)
#'
#' @seealso \code{\link{to_pitch_ac_direct}}, \code{\link{to_pitch_cc_direct}} for full parameter control
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 200, duration = 0.5)
#'
#' # Returns raw pointer (basic parameters)
#' pitch_ptr <- to_pitch_direct(sound)
#'
#' # Use with other direct query functions
#' stats <- get_pitch_stats_direct(pitch_ptr)
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


#' Create Pitch from Sound Directly (Autocorrelation) - Full Parameters
#'
#' @description
#' Create Pitch analysis using autocorrelation method with full control over
#' all voicing parameters. Returns a raw external pointer instead of an R6 object.
#'
#' **NEW in v4.0.1:** Exposes all voicing parameters that were previously only
#' available in Tier 1 (Standard) API.
#'
#' @param sound Sound object or external pointer
#' @param time_step Time step (0 = auto, typically 0.75/pitch_floor)
#' @param pitch_floor Minimum pitch (Hz, default 75)
#' @param pitch_ceiling Maximum pitch (Hz, default 600)
#' @param max_candidates Maximum number of pitch candidates (default 15)
#' @param very_accurate Use accurate but slower method (default FALSE)
#' @param silence_threshold Frames below this relative intensity are unvoiced (default 0.03)
#' @param voicing_threshold Strength required for voiced decision (default 0.45)
#' @param octave_cost Cost per octave in path finding (default 0.01)
#' @param octave_jump_cost Cost for octave jumps (default 0.35)
#' @param voiced_unvoiced_cost Cost for voicing transitions (default 0.14)
#' @param max_number_of_candidates Maximum number of pitch candidates per frame
#'
#' @return External pointer to Pitch (NOT R6 object)
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 200, duration = 0.5)
#'
#' # With custom voicing threshold (stricter voicing detection)
#' pitch_ptr <- to_pitch_ac_direct(sound, voicing_threshold = 0.6)
#'
#' # Use with query functions
#' f0 <- get_pitch_value_direct(pitch_ptr, 0.25, "hertz", TRUE)
#'
#' @export
to_pitch_ac_direct <- function(sound,
                                time_step = 0,
                                pitch_floor = 75,
                                pitch_ceiling = 600,
                                max_candidates = 15,
                                very_accurate = FALSE,
                                silence_threshold = 0.03,
                                voicing_threshold = 0.45,
                                octave_cost = 0.01,
                                octave_jump_cost = 0.35,
                                voiced_unvoiced_cost = 0.14,
                                # Praat-compatible aliases
                                max_number_of_candidates = NULL) {
  sound_ptr <- if (inherits(sound, "Sound")) {
    sound$.xptr
  } else if (inherits(sound, "externalptr")) {
    sound
  } else {
    stop("sound must be a Sound object or external pointer")
  }

  # Apply aliases (Praat-compatible names take precedence if provided)
  max_candidates <- max_number_of_candidates %||% max_candidates

  .sound_to_pitch_ac(sound_ptr, time_step, pitch_floor, pitch_ceiling,
                     as.integer(max_candidates), very_accurate,
                     silence_threshold, voicing_threshold,
                     octave_cost, octave_jump_cost, voiced_unvoiced_cost)
}


#' Create Pitch from Sound Directly (Cross-Correlation) - Full Parameters
#'
#' @description
#' Create Pitch analysis using cross-correlation method with full control over
#' all voicing parameters. Returns a raw external pointer instead of an R6 object.
#'
#' **NEW in v4.0.1:** Exposes all voicing parameters that were previously only
#' available in Tier 1 (Standard) API.
#'
#' @param sound Sound object or external pointer
#' @param time_step Time step (0 = auto, typically 0.75/pitch_floor)
#' @param pitch_floor Minimum pitch (Hz, default 75)
#' @param pitch_ceiling Maximum pitch (Hz, default 600)
#' @param max_candidates Maximum number of pitch candidates (default 15)
#' @param very_accurate Use accurate but slower method (default FALSE)
#' @param silence_threshold Frames below this relative intensity are unvoiced (default 0.03)
#' @param voicing_threshold Strength required for voiced decision (default 0.45)
#' @param octave_cost Cost per octave in path finding (default 0.01)
#' @param octave_jump_cost Cost for octave jumps (default 0.35)
#' @param voiced_unvoiced_cost Cost for voicing transitions (default 0.14)
#' @param max_number_of_candidates Maximum number of pitch candidates per frame
#'
#' @return External pointer to Pitch (NOT R6 object)
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 200, duration = 0.5)
#'
#' # With custom voicing threshold (stricter voicing detection)
#' pitch_ptr <- to_pitch_cc_direct(sound, voicing_threshold = 0.6)
#'
#' # Use with query functions
#' f0 <- get_pitch_value_direct(pitch_ptr, 0.25, "hertz", TRUE)
#'
#' @export
to_pitch_cc_direct <- function(sound,
                                time_step = 0,
                                pitch_floor = 75,
                                pitch_ceiling = 600,
                                max_candidates = 15,
                                very_accurate = FALSE,
                                silence_threshold = 0.03,
                                voicing_threshold = 0.45,
                                octave_cost = 0.01,
                                octave_jump_cost = 0.35,
                                voiced_unvoiced_cost = 0.14,
                                # Praat-compatible aliases
                                max_number_of_candidates = NULL) {
  sound_ptr <- if (inherits(sound, "Sound")) {
    sound$.xptr
  } else if (inherits(sound, "externalptr")) {
    sound
  } else {
    stop("sound must be a Sound object or external pointer")
  }

  # Apply aliases (Praat-compatible names take precedence if provided)
  max_candidates <- max_number_of_candidates %||% max_candidates

  .sound_to_pitch_cc(sound_ptr, time_step, pitch_floor, pitch_ceiling,
                     as.integer(max_candidates), very_accurate,
                     silence_threshold, voicing_threshold,
                     octave_cost, octave_jump_cost, voiced_unvoiced_cost)
}


#' Create Pitch from Sound using Subharmonic Summation (SHS) Directly (returns XPtr)
#'
#' @param sound Sound object or external pointer
#' @param time_step Time step in seconds (default 0.01)
#' @param pitch_floor Minimum pitch (Hz, default 50)
#' @param max_frequency Maximum frequency for analysis (Hz, default 1250)
#' @param pitch_ceiling Maximum pitch (Hz, default 500)
#' @param max_subharmonics Number of subharmonics to sum (default 15)
#' @param max_candidates Maximum number of pitch candidates per frame (default 15)
#' @param compression_factor Compression factor for subharmonic weighting (default 0.84)
#' @param n_points_per_octave Number of frequency points per octave (default 48)
#'
#' @return External pointer to Pitch (NOT R6 object)
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 200, duration = 0.5)
#' pitch_ptr <- to_pitch_shs_direct(sound)
#' f0 <- get_pitch_value_direct(pitch_ptr, 0.25, "hertz", TRUE)
#'
#' @export
to_pitch_shs_direct <- function(sound,
                                 time_step = 0.01,
                                 pitch_floor = 50,
                                 max_frequency = 1250,
                                 pitch_ceiling = 500,
                                 max_subharmonics = 15L,
                                 max_candidates = 15L,
                                 compression_factor = 0.84,
                                 n_points_per_octave = 48L) {
  sound_ptr <- if (inherits(sound, "Sound")) {
    sound$.xptr
  } else if (inherits(sound, "externalptr")) {
    sound
  } else {
    stop("sound must be a Sound object or external pointer")
  }

  .sound_to_pitch_shs(sound_ptr, time_step, pitch_floor, max_frequency,
                       pitch_ceiling, as.integer(max_subharmonics),
                       as.integer(max_candidates), compression_factor,
                       as.integer(n_points_per_octave))
}


#' Create Pitch from Sound using SPINET Directly (returns XPtr)
#'
#' @param sound Sound object or external pointer
#' @param time_step Time step in seconds (default 0.005)
#' @param window_duration Analysis window duration (default 0.04)
#' @param min_frequency Minimum frequency (Hz, default 70)
#' @param max_frequency Maximum frequency (Hz, default 5000)
#' @param n_filters Number of gamma-tone filters (default 250)
#' @param pitch_ceiling Maximum pitch (Hz, default 500)
#' @param max_candidates Maximum number of pitch candidates per frame (default 15)
#'
#' @return External pointer to Pitch (NOT R6 object)
#'
#' @examples
#' # The vendored Praat SPINET path has a rare, non-deterministic native
#' # flake ("all amplitudes equal to zero") unrelated to the input signal;
#' # tryCatch keeps this example from failing R CMD check when it strikes.
#' sound <- Sound$create_tone(frequency = 200, duration = 0.5)
#' pitch_ptr <- tryCatch(to_pitch_spinet_direct(sound), error = function(e) NULL)
#' if (!is.null(pitch_ptr)) {
#'   f0 <- get_pitch_value_direct(pitch_ptr, 0.25, "hertz", TRUE)
#' }
#'
#' @export
to_pitch_spinet_direct <- function(sound,
                                    time_step = 0.005,
                                    window_duration = 0.04,
                                    min_frequency = 70,
                                    max_frequency = 5000,
                                    n_filters = 250L,
                                    pitch_ceiling = 500,
                                    max_candidates = 15L) {
  sound_ptr <- if (inherits(sound, "Sound")) {
    sound$.xptr
  } else if (inherits(sound, "externalptr")) {
    sound
  } else {
    stop("sound must be a Sound object or external pointer")
  }

  .sound_to_pitch_spinet(sound_ptr, time_step, window_duration,
                          min_frequency, max_frequency,
                          as.integer(n_filters), pitch_ceiling,
                          as.integer(max_candidates))
}


#' Create Formant from Sound Directly (returns XPtr)
#'
#' @param sound Sound object or external pointer
#' @param time_step Time step (0 = auto)
#' @param max_formants Maximum number of formants
#' @param max_formant Maximum formant frequency (Hz)
#' @param window_length Window length (seconds)
#' @param pre_emphasis Pre-emphasis frequency (Hz)
#' @param max_number_of_formants Alias for `max_formants` (maximum number of formants)
#' @param maximum_formant Alias for `max_formant` (maximum formant frequency, Hz)
#' @param pre_emphasis_from Alias for `pre_emphasis` (pre-emphasis frequency, Hz)
#'
#' @return External pointer to Formant
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 200, duration = 0.5)
#' formant_ptr <- to_formant_direct(sound)
#' f1 <- get_formant_value_direct(formant_ptr, 1, 0.25, "hertz")
#'
#' @export
to_formant_direct <- function(sound, time_step = 0, max_formants = 5,
                               max_formant = 5500, window_length = 0.025,
                               pre_emphasis = 50,
                               # Praat-compatible aliases
                               max_number_of_formants = NULL,
                               maximum_formant = NULL,
                               pre_emphasis_from = NULL) {
  sound_ptr <- if (inherits(sound, "Sound")) {
    sound$.xptr
  } else if (inherits(sound, "externalptr")) {
    sound
  } else {
    stop("sound must be a Sound object or external pointer")
  }

  # Apply aliases (Praat-compatible names take precedence if provided)
  max_formants <- max_number_of_formants %||% max_formants
  max_formant <- maximum_formant %||% max_formant
  pre_emphasis <- pre_emphasis_from %||% pre_emphasis

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
#' @examples
#' sound <- Sound$create_tone(frequency = 200, duration = 0.5)
#' intensity_ptr <- to_intensity_direct(sound)
#' db <- get_intensity_value_direct(intensity_ptr, 0.25)
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
#' @examples
#' sound <- Sound$create_tone(frequency = 200, duration = 0.5)
#' hnr_ptr <- to_harmonicity_direct(sound)
#' hnr <- Harmonicity(.xptr = hnr_ptr)
#' hnr$get_mean(0, 0)
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
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
#' pitch_ptr <- to_pitch_cc_direct(sound)
#' get_pitch_value_direct(pitch_ptr, 0.25)
#'
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
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
#' intensity_ptr <- to_intensity_direct(sound)
#' get_intensity_value_direct(intensity_ptr, 0.25)
#'
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
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate = 16000)
#' formant_ptr <- to_formant_direct(sound)
#' get_formant_value_direct(formant_ptr, 1, 0.25)
#'
#' @export
get_formant_value_direct <- function(formant, formant_number, time, unit = "hertz") {
  formant_ptr <- if (inherits(formant, "Formant")) formant$.xptr else formant
  unit_code <- switch(unit, hertz = 0L, bark = 1L, 0L)
  formant_get_value_direct(formant_ptr, formant_number, time, unit_code)
}


#' Get Pitch Quantile Directly (Bypass R6)
#'
#' @description
#' Get a specific quantile of pitch values without R6 wrapper overhead.
#' Useful for VUV analysis workflows where you need Q1, Q3 for adaptive pitch range.
#'
#' @param pitch Pitch object or external pointer
#' @param quantile Quantile value (0.25 for Q1, 0.75 for Q3, 0.5 for median)
#' @param from_time Start time (0 = beginning)
#' @param to_time End time (0 = end)
#' @param unit Pitch unit ("hertz", "semitones", "mel", "erb", "loghertz")
#'
#' @return Quantile value in specified unit
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
#' pitch_ptr <- to_pitch_cc_direct(sound)
#' q1 <- get_pitch_quantile_direct(pitch_ptr, 0.25)
#' q3 <- get_pitch_quantile_direct(pitch_ptr, 0.75)
#'
#' @seealso \code{\link{get_pitch_quantiles_batch}} for getting multiple quantiles at once
#' @export
get_pitch_quantile_direct <- function(pitch, quantile, from_time = 0, to_time = 0,
                                       unit = c("hertz", "semitones", "mel", "erb", "loghertz")) {
  pitch_ptr <- if (inherits(pitch, "Pitch")) pitch$.xptr else pitch
  unit <- match.arg(unit)
  unit_code <- switch(unit,
    hertz = 0L, semitones = 1L, mel = 2L, erb = 3L, loghertz = 4L
  )
  pitch_get_quantile_direct(pitch_ptr, quantile, from_time, to_time, unit_code)
}

#' Get Pitch Mean Directly (Bypass R6)
#'
#' @description
#' Get mean pitch value without R6 wrapper overhead.
#'
#' @param pitch Pitch object or external pointer
#' @param from_time Start time (0 = beginning)
#' @param to_time End time (0 = end)
#' @param unit Pitch unit
#'
#' @return Mean pitch value
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
#' pitch_ptr <- to_pitch_cc_direct(sound)
#' get_pitch_mean_direct(pitch_ptr)
#'
#' @export
get_pitch_mean_direct <- function(pitch, from_time = 0, to_time = 0,
                                   unit = c("hertz", "semitones", "mel", "erb", "loghertz")) {
  pitch_ptr <- if (inherits(pitch, "Pitch")) pitch$.xptr else pitch
  unit <- match.arg(unit)
  unit_code <- switch(unit,
    hertz = 0L, semitones = 1L, mel = 2L, erb = 3L, loghertz = 4L
  )
  pitch_get_mean_direct(pitch_ptr, from_time, to_time, unit_code)
}

#' Get Pitch Standard Deviation Directly (Bypass R6)
#'
#' @description
#' Get standard deviation of pitch values without R6 wrapper overhead.
#'
#' @param pitch Pitch object or external pointer
#' @param from_time Start time (0 = beginning)
#' @param to_time End time (0 = end)
#' @param unit Pitch unit
#'
#' @return Standard deviation
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
#' pitch_ptr <- to_pitch_cc_direct(sound)
#' get_pitch_stdev_direct(pitch_ptr)
#'
#' @export
get_pitch_stdev_direct <- function(pitch, from_time = 0, to_time = 0,
                                    unit = c("hertz", "semitones", "mel", "erb", "loghertz")) {
  pitch_ptr <- if (inherits(pitch, "Pitch")) pitch$.xptr else pitch
  unit <- match.arg(unit)
  unit_code <- switch(unit,
    hertz = 0L, semitones = 1L, mel = 2L, erb = 3L, loghertz = 4L
  )
  pitch_get_stdev_direct(pitch_ptr, from_time, to_time, unit_code)
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
#' sound <- Sound$create_tone(frequency = 200, duration = 0.5)
#' spec_ptr <- to_spectrum_direct(sound)
#' spec <- Spectrum(.xptr = spec_ptr)
#' spec$get_number_of_bins()
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
#' sound <- Sound$create_tone(frequency = 200, duration = 0.5)
#' spg_ptr <- to_spectrogram_direct(sound, window_length = 0.005)
#' spg <- Spectrogram(.xptr = spg_ptr)
#' spg$get_number_of_time_bins()
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
    shape_code <- switch(tolower(window_shape),
      "square" = 0L, "hamming" = 1L, "bartlett" = 2L,
      "welch" = 3L, "hanning" = 4L, "gaussian" = 5L, 5L)
    return(sound$.cpp$to_spectrogram_ptr(
      as.numeric(window_length),
      as.numeric(max_frequency),
      as.numeric(time_step),
      as.numeric(frequency_step),
      shape_code
    ))
  }
  
  # Fallback to wrapper function
  .sound_to_spectrogram(sound_ptr, window_length, max_frequency, 
                        time_step, frequency_step, window_shape)
}


#' Create LTAS from Sound Directly
#'
#' @param sound Sound object or external pointer
#' @param bandwidth Numeric. Bandwidth in Hz (default: 100)
#'
#' @return A wrapped \code{Ltas} object
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 200, duration = 0.5)
#' ltas <- to_ltas_direct(sound, bandwidth = 100)
#' ltas$get_slope(0, 1000, 1000, 10000, "energy")
#'
#' @export
to_ltas_direct <- function(sound, bandwidth = 100.0) {
  sound_ptr <- extract_xptr(sound, "Sound")
  Ltas(.xptr = .sound_to_ltas(sound_ptr, as.numeric(bandwidth)))
}


#' Create PointProcess from Sound Directly (returns XPtr)
#'
#' @param sound Sound object or external pointer
#' @param pitch_floor Numeric. Minimum pitch in Hz (default: 75)
#' @param pitch_ceiling Numeric. Maximum pitch in Hz (default: 600)
#' @param max_period_factor Numeric. Max period factor (default: 1.3)
#' @param max_amplitude_factor Numeric. Max amplitude factor (default: 1.6)
#' @param time_step Numeric. Time step in seconds (0 = auto)
#'
#' @return External pointer to PointProcess
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 200, duration = 0.5)
#' # Extract glottal pulses
#' pp_ptr <- to_point_process_direct(sound, pitch_floor = 75, pitch_ceiling = 300)
#' pp <- PointProcess(.xptr = pp_ptr)
#' pp$get_number_of_points()
#'
#' @export
to_point_process_direct <- function(sound, pitch_floor = 75.0,
                                     pitch_ceiling = 600.0,
                                     time_step = 0.0,
                                     max_period_factor = 1.3,
                                     max_amplitude_factor = 1.6) {
  sound_ptr <- extract_xptr(sound, "Sound")

  # Direct .Call path — bypasses R6 module dispatch
  .sound_to_point_process_periodic_cc(sound_ptr, as.numeric(time_step),
                                       as.numeric(pitch_floor), as.numeric(pitch_ceiling),
                                       as.numeric(max_period_factor), as.numeric(max_amplitude_factor))
}


#' Create PointProcess from Sound and Pitch (Cross-Correlation)
#'
#' @description
#' Creates a PointProcess using BOTH Sound and refined Pitch contour.
#' This matches Praat's "To PointProcess (cc)" command when both Sound and Pitch
#' objects are selected.
#'
#' **IMPORTANT for VUV Analysis:** This function uses the refined pitch contour
#' to guide period detection, which is more accurate than using pitch range
#' parameters alone. This is the correct method for voice quality analysis (jitter,
#' shimmer, VUV detection).
#'
#' **Algorithm Difference:**
#' - `sound$to_point_process_periodic_cc(floor, ceiling)` - Uses only pitch range
#' - `to_point_process_from_sound_and_pitch(sound, pitch)` - Uses refined pitch contour (recommended)
#'
#' @param sound Sound object or external pointer
#' @param pitch Pitch object or external pointer (from to_pitch_ac/cc)
#'
#' @return External pointer to PointProcess
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 200, duration = 0.5)
#'
#' # Create refined pitch analysis
#' pitch <- sound$to_pitch_cc(
#'   time_step = 0,
#'   pitch_floor = 75,
#'   pitch_ceiling = 600,
#'   voicing_threshold = 0.45
#' )
#'
#' # RECOMMENDED: Use both Sound and Pitch for accurate pulse detection
#' pp <- to_point_process_from_sound_and_pitch(sound, pitch)
#'
#' # Now calculate jitter with accurate pulse times
#' pp_r6 <- PointProcess(.xptr = pp)
#' jitter <- pp_r6$get_jitter_local()
#'
#' @seealso \code{\link{to_point_process_direct}} for the single-object Sound method
#' @export
to_point_process_from_sound_and_pitch <- function(sound, pitch) {
  sound_ptr <- extract_xptr(sound, "Sound")
  pitch_ptr <- extract_xptr(pitch, "Pitch")
  
  .sound_pitch_to_pointprocess_cc(sound_ptr, pitch_ptr)
}


# =============================================================================
# PointProcess Direct API Functions (NEW for VUV performance)
# =============================================================================

#' Get PointProcess Mean Period Directly (Bypass R6)
#'
#' @description
#' Get mean period from PointProcess without R6 wrapper overhead.
#' Critical for VUV analysis workflows.
#'
#' @param pointprocess PointProcess object or external pointer
#' @param from_time Start time (0 = beginning)
#' @param to_time End time (0 = end)
#' @param period_floor Minimum period (default: 0.0001)
#' @param period_ceiling Maximum period (default: 0.02)
#' @param max_period_factor Maximum period factor (default: 1.3)
#'
#' @return Mean period in seconds
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 1.0)
#' pitch <- sound$to_pitch()
#' pp_ptr <- to_point_process_from_sound_and_pitch(sound, pitch)
#' mean_period <- pp_get_mean_period_direct(pp_ptr)
#'
#' @export
pp_get_mean_period_direct <- function(pointprocess,
                                       from_time = 0,
                                       to_time = 0,
                                       period_floor = 0.0001,
                                       period_ceiling = 0.02,
                                       max_period_factor = 1.3) {
  pp_ptr <- if (inherits(pointprocess, "PointProcess")) {
    pointprocess$.xptr
  } else {
    pointprocess
  }
  
  .Call("_pladdrr_get_point_process_mean_period_direct",
    pp_ptr,
    as.numeric(from_time),
    as.numeric(to_time),
    as.numeric(period_floor),
    as.numeric(period_ceiling),
    as.numeric(max_period_factor),
    PACKAGE = "pladdrr"
  )
}

#' Get PointProcess Period Standard Deviation Directly (Bypass R6)
#'
#' @description
#' Get standard deviation of periods from PointProcess without R6 wrapper overhead.
#'
#' @param pointprocess PointProcess object or external pointer
#' @param from_time Start time (0 = beginning)
#' @param to_time End time (0 = end)
#' @param period_floor Minimum period
#' @param period_ceiling Maximum period
#' @param max_period_factor Maximum period factor
#'
#' @return Standard deviation of periods
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 1.0)
#' pitch <- sound$to_pitch()
#' pp_ptr <- to_point_process_from_sound_and_pitch(sound, pitch)
#' sd_period <- pp_get_stdev_period_direct(pp_ptr)
#' @export
pp_get_stdev_period_direct <- function(pointprocess,
                                        from_time = 0,
                                        to_time = 0,
                                        period_floor = 0.0001,
                                        period_ceiling = 0.02,
                                        max_period_factor = 1.3) {
  pp_ptr <- if (inherits(pointprocess, "PointProcess")) {
    pointprocess$.xptr
  } else {
    pointprocess
  }

  .Call("_pladdrr_get_point_process_stdev_period_direct",
    pp_ptr,
    as.numeric(from_time),
    as.numeric(to_time),
    as.numeric(period_floor),
    as.numeric(period_ceiling),
    as.numeric(max_period_factor),
    PACKAGE = "pladdrr"
  )
}


# =============================================================================
# Pipeline Operations (Composite Functions)
# =============================================================================

#' Two-Pass Adaptive Pitch Extraction
#'
#' @description
#' Performs a two-pass pitch extraction where the first pass uses a wide range
#' (50-800 Hz by default) to estimate the speaker's pitch distribution, then
#' the second pass uses an adaptive range based on quartiles (Q1*0.75 to Q3*1.5).
#'
#' This is a standard technique for robust pitch extraction across speakers with
#' different voice ranges. Returns both the refined pitch contour and the
#' computed range parameters for transparency.
#'
#' @param sound Sound object or external pointer
#' @param time_step Time step (0 = auto, typically 0.75/pitch_floor)
#' @param initial_floor Initial pitch floor for pass 1 (default 50 Hz)
#' @param initial_ceiling Initial pitch ceiling for pass 1 (default 800 Hz)
#' @param voicing_threshold Voicing threshold (default 0.45)
#' @param silence_threshold Silence threshold (default 0.03)
#' @param octave_cost Octave cost (default 0.01)
#' @param octave_jump_cost Octave jump cost (default 0.35)
#' @param voiced_unvoiced_cost Voiced/unvoiced transition cost (default 0.14)
#' @param q1_factor Factor to multiply Q1 for min_pitch (default 0.75)
#' @param q3_factor Factor to multiply Q3 for max_pitch (default 1.5)
#' @param method Pitch method: "cc" (cross-correlation, default) or "ac" (autocorrelation)
#'
#' @return Named list with:
#'   - `pitch`: External pointer to the refined Pitch object
#'   - `min_pitch`: Computed minimum pitch (Q1 * q1_factor)
#'   - `max_pitch`: Computed maximum pitch (Q3 * q3_factor)
#'   - `q1`: First quartile of pass 1 pitch values
#'   - `q3`: Third quartile of pass 1 pitch values
#'
#' @section Algorithm:
#' 1. Pass 1: Extract pitch with wide range (initial_floor to initial_ceiling)
#' 2. Compute Q1 and Q3 from voiced frames

#' 3. Pass 2: Re-extract with adaptive range (Q1*0.75 to Q3*1.5)
#'
#' @section Performance:
#' This is a pure R wrapper calling existing direct functions. No C++ overhead
#' beyond the two pitch extractions. Suitable for batch processing.
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 1.0)
#'
#' # Basic usage (returns XPtr)
#' result <- two_pass_adaptive_pitch(sound)
#' pitch_refined <- Pitch(.xptr = result$pitch)
#' cat("Adaptive range:", result$min_pitch, "-", result$max_pitch, "Hz\n")
#'
#' # With custom parameters
#' result <- two_pass_adaptive_pitch(sound,
#'   voicing_threshold = 0.6,  # Stricter voicing
#'   q1_factor = 0.7,          # Wider lower bound
#'   q3_factor = 1.6           # Wider upper bound
#' )
#'
#' @seealso
#' [to_pitch_cc_direct()], [to_pitch_ac_direct()] for single-pass extraction
#' [pitch_get_adaptive_range()] for the single-call quartile + range computation
#' [get_pitch_quantiles_batch()] for batch quartile extraction
#'
#' @export
two_pass_adaptive_pitch <- function(sound,
                                     time_step = 0,
                                     initial_floor = 50,
                                     initial_ceiling = 800,
                                     voicing_threshold = 0.45,
                                     silence_threshold = 0.03,
                                     octave_cost = 0.01,
                                     octave_jump_cost = 0.35,
                                     voiced_unvoiced_cost = 0.14,
                                     q1_factor = 0.75,
                                     q3_factor = 1.5,
                                     method = c("cc", "ac")) {
  # Extract pointer from R6 or use directly
  sound_ptr <- if (inherits(sound, "Sound")) sound$.xptr else sound

  method <- match.arg(method)

  # Choose pitch function based on method
  pitch_fn <- if (method == "cc") to_pitch_cc_direct else to_pitch_ac_direct

  # Pass 1: Wide range
  pitch_rough <- pitch_fn(
    sound_ptr,
    time_step = time_step,
    pitch_floor = initial_floor,
    pitch_ceiling = initial_ceiling,
    voicing_threshold = voicing_threshold,
    silence_threshold = silence_threshold,
    octave_cost = octave_cost,
    octave_jump_cost = octave_jump_cost,
    voiced_unvoiced_cost = voiced_unvoiced_cost
  )

  # Get quartiles + adaptive range in single C++ call
  range <- pitch_get_adaptive_range(pitch_rough, q1_factor = q1_factor,
                                     q3_factor = q3_factor, unit = 0L)
  q1 <- range$q1
  q3 <- range$q3

  # Handle case where no voiced frames found
  if (is.na(q1) || is.na(q3) || q1 <= 0 || q3 <= 0) {
    return(list(
      pitch = pitch_rough,
      min_pitch = initial_floor,
      max_pitch = initial_ceiling,
      q1 = NA_real_,
      q3 = NA_real_
    ))
  }

  min_pitch <- range$min_pitch
  max_pitch <- range$max_pitch

  # Pass 2: Refined range
  pitch_refined <- pitch_fn(
    sound_ptr,
    time_step = time_step,
    pitch_floor = min_pitch,
    pitch_ceiling = max_pitch,
    voicing_threshold = voicing_threshold,
    silence_threshold = silence_threshold,
    octave_cost = octave_cost,
    octave_jump_cost = octave_jump_cost,
    voiced_unvoiced_cost = voiced_unvoiced_cost
  )

  list(
    pitch = pitch_refined,
    min_pitch = min_pitch,
    max_pitch = max_pitch,
    q1 = q1,
    q3 = q3
  )
}
