#' Voice Activity Detection Functions
#'
#' @description
#' Functions for detecting voiced and unvoiced segments in audio signals.
#' Used primarily for AVQI implementation to extract voiced segments from
#' continuous speech.
#'
#' @name vad
NULL

#' @title Detect Silences in Sound and Create TextGrid
#'
#' @description
#' Detects silent and sounding (voiced) intervals in a Sound object and returns
#' a TextGrid with labeled intervals. This is essential for AVQI calculation,
#' which requires extraction of voiced segments from continuous speech.
#'
#' @param sound Sound object to analyze
#' @param minimum_pitch Numeric. Minimum pitch for intensity calculation (Hz, default: 100)
#' @param time_step Numeric. Time step for intensity calculation (s, default: 0.0 = auto)
#' @param silence_threshold Numeric. Silence threshold in dB below maximum (default: -25)
#' @param min_silent_interval Numeric. Minimum duration of silent interval (s, default: 0.1)
#' @param min_sounding_interval Numeric. Minimum duration of sounding interval (s, default: 0.1)
#' @param silent_label Character. Label for silent intervals (default: "silence")
#' @param sounding_label Character. Label for sounding intervals (default: "sounding")
#'
#' @return TextGrid object with one interval tier containing silent and sounding intervals
#'
#' @details
#' The function works by:
#' 1. Computing the intensity contour of the sound
#' 2. Identifying regions where intensity falls below `silence_threshold` dB
#'    relative to the maximum intensity
#' 3. Merging nearby silent/sounding regions based on minimum duration criteria
#' 4. Creating a TextGrid with labeled intervals
#'
#' For AVQI, use these parameters (matching Praat AVQI script):
#' - `minimum_pitch = 50`
#' - `time_step = 0.003`
#' - `silence_threshold = -25`
#' - `min_silent_interval = 0.1`
#' - `min_sounding_interval = 0.1`
#'
#' @examples
#' \dontrun{
#' # Detect voiced segments for AVQI
#' sound <- Sound$new("continuous_speech.wav")
#' 
#' # Create TextGrid with voice activity detection
#' vad_grid <- sound_to_textgrid_silences(
#'   sound,
#'   minimum_pitch = 50,
#'   time_step = 0.003,
#'   silence_threshold = -25,
#'   min_silent_interval = 0.1,
#'   min_sounding_interval = 0.1
#' )
#' 
#' # Extract voiced intervals
#' voiced_intervals <- textgrid_get_intervals_where(
#'   vad_grid,
#'   tier = 1,
#'   condition = "equals",
#'   text = "sounding"
#' )
#' 
#' # Extract and concatenate voiced parts
#' voiced_sounds <- sound_extract_parts(
#'   sound,
#'   voiced_intervals$xmin,
#'   voiced_intervals$xmax,
#'   window_shape = "rectangular",
#'   relative_width = 1.0,
#'   preserve_times = FALSE
#' )
#' 
#' # Concatenate all voiced segments
#' voiced_concatenated <- Sound$concatenate(voiced_sounds)
#' }
#'
#' @export
sound_to_textgrid_silences <- function(sound,
                                       minimum_pitch = 100,
                                       time_step = 0.0,
                                       silence_threshold = -25,
                                       min_silent_interval = 0.1,
                                       min_sounding_interval = 0.1,
                                       silent_label = "silence",
                                       sounding_label = "sounding") {
  
  if (!inherits(sound, "Sound")) {
    stop("sound must be a Sound object")
  }
  
  xptr <- .sound_to_textgrid_silences(
    sound$.xptr,
    minimum_pitch,
    time_step,
    silence_threshold,
    min_silent_interval,
    min_sounding_interval,
    silent_label,
    sounding_label
  )
  
  TextGrid$new(xptr)
}

#' @title Extract Intervals from TextGrid Matching Criteria
#'
#' @description
#' Extracts intervals from a TextGrid tier that match a specified criterion.
#' Returns time boundaries and labels of matching intervals.
#'
#' @param textgrid TextGrid object
#' @param tier Integer. Tier number (1-indexed)
#' @param condition Character. Matching condition:
#'   - "equals" or "is equal to" - Exact match
#'   - "contains" - Label contains text
#'   - "does not contain" - Label does not contain text
#'   - "starts with" - Label starts with text
#'   - "ends with" - Label ends with text
#' @param text Character. Text to match
#'
#' @return Named list with:
#'   - `xmin`: Numeric vector of interval start times
#'   - `xmax`: Numeric vector of interval end times
#'   - `text`: Character vector of interval labels
#'   - `count`: Integer number of matching intervals
#'
#' @examples
#' \dontrun{
#' # Get all "sounding" intervals
#' voiced <- textgrid_get_intervals_where(
#'   vad_grid,
#'   tier = 1,
#'   condition = "equals",
#'   text = "sounding"
#' )
#' 
#' cat("Found", voiced$count, "voiced segments\n")
#' cat("Total voiced duration:", sum(voiced$xmax - voiced$xmin), "s\n")
#' }
#'
#' @export
textgrid_get_intervals_where <- function(textgrid,
                                        tier = 1,
                                        condition = c("equals", "contains", 
                                                     "does not contain",
                                                     "starts with", "ends with"),
                                        text) {
  
  if (!inherits(textgrid, "TextGrid")) {
    stop("textgrid must be a TextGrid object")
  }
  
  condition <- match.arg(condition)
  
  .textgrid_get_intervals_where(
    textgrid$.xptr,
    as.integer(tier),
    condition,
    as.character(text)
  )
}

#' @title Extract Multiple Parts from a Sound
#'
#' @description
#' Extracts multiple time intervals from a Sound object and returns them as
#' a list of Sound objects. Useful for extracting voiced segments identified
#' by voice activity detection.
#'
#' @param sound Sound object
#' @param start_times Numeric vector of interval start times (seconds)
#' @param end_times Numeric vector of interval end times (seconds)
#' @param window_shape Character. Window shape for extraction (default: "rectangular")
#' @param relative_width Numeric. Relative width of window (default: 1.0)
#' @param preserve_times Logical. Preserve original time stamps (default: FALSE)
#'
#' @return List of Sound objects, one for each extracted interval
#'
#' @details
#' This function is vectorized to extract multiple intervals efficiently.
#' Each extracted sound can then be concatenated or analyzed separately.
#'
#' Available window shapes:
#' - "rectangular" (default)
#' - "triangular"
#' - "parabolic"
#' - "hanning"
#' - "hamming"
#' - "gaussian1", "gaussian2", "gaussian3", "gaussian4", "gaussian5"
#' - "kaiser1", "kaiser2"
#'
#' @examples
#' \dontrun{
#' # Extract voiced segments
#' voiced_intervals <- textgrid_get_intervals_where(vad_grid, 1, "equals", "sounding")
#' 
#' voiced_sounds <- sound_extract_parts(
#'   sound,
#'   voiced_intervals$xmin,
#'   voiced_intervals$xmax
#' )
#' 
#' # Concatenate all voiced segments
#' voiced_concatenated <- Sound$concatenate(voiced_sounds)
#' 
#' # Or analyze each segment separately
#' for (i in seq_along(voiced_sounds)) {
#'   cat("Segment", i, "duration:", voiced_sounds[[i]]$get_total_duration(), "s\n")
#' }
#' }
#'
#' @export
sound_extract_parts <- function(sound,
                               start_times,
                               end_times,
                               window_shape = "rectangular",
                               relative_width = 1.0,
                               preserve_times = FALSE) {
  
  if (!inherits(sound, "Sound")) {
    stop("sound must be a Sound object")
  }
  
  if (length(start_times) != length(end_times)) {
    stop("start_times and end_times must have the same length")
  }
  
  xptrs <- .sound_extract_parts(
    sound$.xptr,
    as.numeric(start_times),
    as.numeric(end_times),
    as.character(window_shape),
    as.numeric(relative_width),
    as.logical(preserve_times)
  )
  
  # Convert XPtrs to Sound objects
  lapply(xptrs, function(xptr) Sound$new(.xptr = xptr))
}

#' @title Complete Voice Activity Detection Workflow
#'
#' @description
#' High-level function that performs complete voice activity detection workflow:
#' detects voiced segments and returns them as a concatenated Sound object.
#' This is the main function used for AVQI continuous speech processing.
#'
#' @param sound Sound object (continuous speech)
#' @param minimum_pitch Numeric. Minimum pitch for detection (Hz, default: 50)
#' @param time_step Numeric. Time step for intensity (s, default: 0.003)
#' @param silence_threshold Numeric. Silence threshold in dB (default: -25)
#' @param min_silent_interval Numeric. Minimum silence duration (s, default: 0.1)
#' @param min_sounding_interval Numeric. Minimum voiced duration (s, default: 0.1)
#' @param return_textgrid Logical. Also return the VAD TextGrid (default: FALSE)
#'
#' @return If `return_textgrid = FALSE`: Sound object with concatenated voiced segments.
#'         If `return_textgrid = TRUE`: List with `sound` and `textgrid` elements.
#'
#' @examples
#' \dontrun{
#' # Simple usage for AVQI
#' continuous_speech <- Sound$new("speech.wav")
#' voiced_only <- extract_voiced_segments(continuous_speech)
#' 
#' cat("Original duration:", continuous_speech$get_total_duration(), "s\n")
#' cat("Voiced duration:", voiced_only$get_total_duration(), "s\n")
#' 
#' # Get TextGrid for inspection
#' result <- extract_voiced_segments(continuous_speech, return_textgrid = TRUE)
#' voiced_sound <- result$sound
#' vad_grid <- result$textgrid
#' }
#'
#' @export
extract_voiced_segments <- function(sound,
                                   minimum_pitch = 50,
                                   time_step = 0.003,
                                   silence_threshold = -25,
                                   min_silent_interval = 0.1,
                                   min_sounding_interval = 0.1,
                                   return_textgrid = FALSE) {
  
  if (!inherits(sound, "Sound")) {
    stop("sound must be a Sound object")
  }
  
  # Step 1: Detect silences
  vad_grid <- sound_to_textgrid_silences(
    sound,
    minimum_pitch = minimum_pitch,
    time_step = time_step,
    silence_threshold = silence_threshold,
    min_silent_interval = min_silent_interval,
    min_sounding_interval = min_sounding_interval
  )
  
  # Step 2: Get voiced intervals
  voiced_intervals <- textgrid_get_intervals_where(
    vad_grid,
    tier = 1,
    condition = "equals",
    text = "sounding"
  )
  
  if (voiced_intervals$count == 0) {
    warning("No voiced segments detected")
    if (return_textgrid) {
      return(list(sound = NULL, textgrid = vad_grid))
    } else {
      return(NULL)
    }
  }
  
  # Step 3: Extract voiced parts
  voiced_sounds <- sound_extract_parts(
    sound,
    voiced_intervals$xmin,
    voiced_intervals$xmax,
    window_shape = "rectangular",
    relative_width = 1.0,
    preserve_times = FALSE
  )
  
  # Step 4: Concatenate
  voiced_concatenated <- Sound$concatenate(voiced_sounds)
  
  if (return_textgrid) {
    list(sound = voiced_concatenated, textgrid = vad_grid)
  } else {
    voiced_concatenated
  }
}
