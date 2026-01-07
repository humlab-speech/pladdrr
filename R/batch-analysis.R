# batch-analysis.R
# High-level R wrappers for batch analysis functions
# Part of Phase 2 Performance Enhancements (v2.0.6)

#' Voice Quality Batch Analysis
#'
#' Efficiently extracts common voice quality measures in a single C++ call,
#' avoiding multiple R<->C++ boundary crossings. This function is optimized
#' for typical voice quality workflows (DSI, AVQI, etc.).
#'
#' @param sound A Sound object
#' @param time_step Time step for pitch and intensity analysis (default 0.0 = auto)
#' @param pitch_floor Minimum pitch in Hz (default 75.0)
#' @param pitch_ceiling Maximum pitch in Hz (default 600.0)
#' @param periods_per_window Periods per window for pitch (default 3.0)
#' @param max_n_candidates Maximum number of pitch candidates (default 15)
#' @param very_accurate Use accurate but slow pitch algorithm (default FALSE)
#' @param silence_threshold Silence threshold (default 0.03)
#' @param voicing_threshold Voicing threshold (default 0.45)
#' @param octave_cost Cost per octave jump (default 0.01)
#' @param octave_jump_cost Cost per octave jump (default 0.35)
#' @param voiced_unvoiced_cost Cost for voiced/unvoiced transition (default 0.14)
#' @param minimum_pitch_intensity Minimum intensity for pitch (default 100.0)
#' @param from_time Start time for statistics (default 0.0 = start)
#' @param to_time End time for statistics (default 0.0 = end)
#'
#' @return List containing:
#'   \describe{
#'     \item{pitch}{List with mean, maximum, minimum, stdev, median (all in Hz)}
#'     \item{intensity}{List with mean, maximum, minimum, stdev, median (all in dB)}
#'   }
#'
#' @details
#' This function reduces 10 R<->C++ boundary crossings to just 1 call:
#' \itemize{
#'   \item sound$to_pitch_cc() -> 1 call
#'   \item pitch$get_mean(), get_maximum(), get_minimum(), get_standard_deviation() -> 4 calls
#'   \item sound$to_intensity() -> 1 call
#'   \item intensity$get_mean(), get_maximum(), get_minimum(), get_standard_deviation() -> 4 calls
#' }
#'
#' Expected speedup: 15-20\% compared to individual method calls
#'
#' @examples
#' \dontrun{
#' sound <- Sound("vowel.wav")
#'
#' # Traditional approach (10 R<->C++ calls)
#' pitch <- sound$to_pitch_cc()
#' pitch_mean <- pitch$get_mean(0, 0, "Hz")
#' pitch_max <- pitch$get_maximum(0, 0, "Hz")
#' # ... etc
#'
#' # Batch approach (1 R<->C++ call)
#' vq <- voice_quality_batch(sound)
#' pitch_mean <- vq$pitch$mean
#' pitch_max <- vq$pitch$maximum
#' }
#'
#' @export
voice_quality_batch <- function(sound,
                                  time_step = 0.0,
                                  pitch_floor = 75.0,
                                  pitch_ceiling = 600.0,
                                  periods_per_window = 3.0,
                                  max_n_candidates = 15L,
                                  very_accurate = FALSE,
                                  silence_threshold = 0.03,
                                  voicing_threshold = 0.45,
                                  octave_cost = 0.01,
                                  octave_jump_cost = 0.35,
                                  voiced_unvoiced_cost = 0.14,
                                  minimum_pitch_intensity = 100.0,
                                  from_time = 0.0,
                                  to_time = 0.0) {
  # Validate sound object
  if (!inherits(sound, "Sound")) {
    stop("First argument must be a Sound object")
  }
  
  # Get external pointer
  xptr <- sound$.xptr
  if (is.null(xptr)) xptr <- sound$get_xptr()
  if (is.null(xptr)) {
    stop("Could not extract external pointer from Sound object")
  }
  
  # TODO: Re-enable once sound_batch_analysis.cpp is fixed for current Praat API
  stop("voice_quality_batch is temporarily disabled - use individual functions instead")
  
  # # Call C++ batch function
  # sound_voice_quality_batch(
  #   xptr,
  #   time_step,
  #   pitch_floor,
  #   pitch_ceiling,
  #   periods_per_window,
  #   max_n_candidates,
  #   very_accurate,
  #   silence_threshold,
  #   voicing_threshold,
  #   octave_cost,
  #   octave_jump_cost,
  #   voiced_unvoiced_cost,
  #   minimum_pitch_intensity,
  #   from_time,
  #   to_time
  # )
}


#' Formant Statistics Batch Analysis
#'
#' Efficiently extracts formant statistics for multiple formants in a single call.
#' Optimized for vowel space analysis workflows.
#'
#' @param sound A Sound object
#' @param time_step Time step for formant analysis (default 0.0 = auto)
#' @param max_n_formants Maximum number of formants to extract (default 5)
#' @param maximum_formant Maximum formant frequency in Hz (default 5500.0)
#' @param window_length Window length in seconds (default 0.025)
#' @param pre_emphasis_from Pre-emphasis frequency in Hz (default 50.0)
#' @param from_time Start time for statistics (default 0.0 = start)
#' @param to_time End time for statistics (default 0.0 = end)
#' @param formant_numbers Which formants to analyze (default c(1,2,3,4) = F1-F4)
#'
#' @return List containing for each formant:
#'   \describe{
#'     \item{F1, F2, F3, F4}{Each with mean, stdev, median, minimum, maximum (all in Hz)}
#'   }
#'
#' @details
#' For 4 formants with 5 statistics each, this reduces 21 R<->C++ calls to just 1.
#' Expected speedup: 20-25\% for vowel space analysis
#'
#' @examples
#' \dontrun{
#' sound <- Sound("vowel.wav")
#'
#' # Batch approach (1 R<->C++ call)
#' formants <- formant_analysis_batch(sound)
#' f1_mean <- formants$F1$mean
#' f2_mean <- formants$F2$mean
#'
#' # Access all F1 statistics
#' formants$F1  # List with mean, stdev, median, minimum, maximum
#' }
#'
#' @export
formant_analysis_batch <- function(sound,
                                    time_step = 0.0,
                                    max_n_formants = 5L,
                                    maximum_formant = 5500.0,
                                    window_length = 0.025,
                                    pre_emphasis_from = 50.0,
                                    from_time = 0.0,
                                    to_time = 0.0,
                                    formant_numbers = c(1L, 2L, 3L, 4L)) {
  # Validate sound object
  if (!inherits(sound, "Sound")) {
    stop("First argument must be a Sound object")
  }
  
  # Get external pointer
  xptr <- sound$.xptr
  if (is.null(xptr)) xptr <- sound$get_xptr()
  if (is.null(xptr)) {
    stop("Could not extract external pointer from Sound object")
  }
  
  # Ensure formant_numbers is integer
  formant_numbers <- as.integer(formant_numbers)
  
  # Call C++ batch function
  sound_formant_analysis_batch(
    xptr,
    time_step,
    max_n_formants,
    maximum_formant,
    window_length,
    pre_emphasis_from,
    from_time,
    to_time,
    formant_numbers
  )
}


#' Pitch and Harmonicity Combined Batch Analysis
#'
#' Efficiently extracts both Pitch and Harmonicity (HNR) statistics by sharing
#' the autocorrelation computation between them.
#'
#' @param sound A Sound object
#' @param time_step Time step for analysis (default 0.01)
#' @param pitch_floor Minimum pitch in Hz (default 75.0)
#' @param pitch_ceiling Maximum pitch in Hz (default 600.0)
#' @param silence_threshold Silence threshold (default 0.1)
#' @param voicing_threshold Voicing threshold (default 0.45)
#' @param from_time Start time for statistics (default 0.0 = start)
#' @param to_time End time for statistics (default 0.0 = end)
#'
#' @return List containing:
#'   \describe{
#'     \item{pitch}{List with mean, maximum, minimum, stdev, median (all in Hz)}
#'     \item{hnr}{List with mean, stdev, median (all in dB)}
#'   }
#'
#' @details
#' This function is more efficient than calling sound$to_pitch() and
#' sound$to_harmonicity() separately, as both use autocorrelation which
#' can be computed once and shared.
#'
#' Expected speedup: 10-15\% compared to separate analyses
#'
#' @examples
#' \dontrun{
#' sound <- Sound("vowel.wav")
#'
#' # Batch approach (1 R<->C++ call)
#' result <- pitch_harmonicity_batch(sound)
#' pitch_mean <- result$pitch$mean
#' hnr_mean <- result$hnr$mean
#' }
#'
#' @export
pitch_harmonicity_batch <- function(sound,
                                     time_step = 0.01,
                                     pitch_floor = 75.0,
                                     pitch_ceiling = 600.0,
                                     silence_threshold = 0.1,
                                     voicing_threshold = 0.45,
                                     from_time = 0.0,
                                     to_time = 0.0) {
  # Validate sound object
  if (!inherits(sound, "Sound")) {
    stop("First argument must be a Sound object")
  }
  
  # Get external pointer
  xptr <- sound$.xptr
  if (is.null(xptr)) xptr <- sound$get_xptr()
  if (is.null(xptr)) {
    stop("Could not extract external pointer from Sound object")
  }
  
  # Call C++ batch function
  sound_pitch_harmonicity_batch(
    xptr,
    time_step,
    pitch_floor,
    pitch_ceiling,
    silence_threshold,
    voicing_threshold,
    from_time,
    to_time
  )
}
