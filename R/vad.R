#' Voice Activity Detection Functions
#'
#' @description
#' Functions for detecting voiced and unvoiced segments in audio signals.
#' Used primarily for AVQI implementation to extract voiced segments from
#' continuous speech.
#'
#' @return This page documents a family of functions; see the `@return`
#'   section of each individual function (e.g. [sound_to_textgrid_silences()])
#'   for its specific return value.
#' @examples
#' # See individual functions, e.g. ?sound_to_textgrid_silences
#' @name vad
NULL


# Per-segment zero-crossing-rate keep test (shared by extract_voiced_segments
# and sound_get_zcr). Long segments (>= zcr_window) use the AVQI 0.0025-0.0275s
# analysis window; short segments use the whole segment.
.segment_zcr_keep <- function(all_zeros, seg_start, seg_end, zcr_threshold, zcr_window) {
  segment_zeros <- all_zeros[all_zeros >= seg_start & all_zeros < seg_end]
  if (seg_end - seg_start >= zcr_window) {
    relative_zeros <- segment_zeros - seg_start
    analysis_end <- min(0.0275, (seg_end - seg_start) - 0.0025)
    zc <- relative_zeros[relative_zeros >= 0.0025 & relative_zeros <= analysis_end]
  } else {
    zc <- segment_zeros
  }
  if (length(zc) < 2) return(TRUE)
  afstand <- zc[length(zc)] - zc[1]
  if (afstand <= 0) return(TRUE)
  (length(zc) / afstand) < zcr_threshold
}

.detect_voiced_intervals <- function(sound, minimum_pitch, time_step, silence_threshold,
                                     min_silent_interval, min_sounding_interval) {
  vad_grid <- sound_to_textgrid_silences(
    sound, minimum_pitch = minimum_pitch, time_step = time_step,
    silence_threshold = silence_threshold,
    min_silent_interval = min_silent_interval,
    min_sounding_interval = min_sounding_interval)
  list(
    vad_grid = vad_grid,
    voiced_intervals = textgrid_get_intervals_where(
      vad_grid, tier = 1, condition = "equals", text = "sounding")
  )
}

# Filter voiced segments by zero-crossing rate (all-rejected handled by caller).
.apply_zcr_filter <- function(xmin, xmax, sound, zcr_threshold, zcr_window) {
  pp_zeros <- sound$to_point_process_zeros(
    channel = 1L, include_raisers = TRUE, include_fallers = TRUE)
  all_zeros <- pp_zeros$as_vector()
  keep <- vapply(seq_along(xmin), function(i) {
    .segment_zcr_keep(all_zeros, xmin[i], xmax[i], zcr_threshold, zcr_window)
  }, logical(1))
  list(xmin = xmin[keep], xmax = xmax[keep])
}

# Extract and concatenate voiced segments into a single Sound, optionally
# returning the source TextGrid.
.extract_voiced_sound <- function(sound, xmin, xmax, vad_grid, return_textgrid) {
  voiced_sounds <- sound_extract_parts(
    sound, xmin, xmax, window_shape = "rectangular",
    relative_width = 1.0, preserve_times = FALSE)
  voiced_concatenated <- sound$concatenate_sounds(voiced_sounds)
  if (return_textgrid) list(sound = voiced_concatenated, textgrid = vad_grid)
  else voiced_concatenated
}


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
#' # Synthetic speech-like sound: loud / near-silent / loud
#' sound <- sounds_append(
#'   sounds_append(
#'     Sound$create_tone(frequency = 200, duration = 0.5, amplitude = 0.8),
#'     Sound$create_tone(frequency = 200, duration = 0.3, amplitude = 0.001)
#'   ),
#'   Sound$create_tone(frequency = 200, duration = 0.5, amplitude = 0.8)
#' )
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
#' # Extract voiced parts
#' voiced_sounds <- sound_extract_parts(
#'   sound,
#'   voiced_intervals$xmin,
#'   voiced_intervals$xmax,
#'   window_shape = "rectangular",
#'   relative_width = 1.0,
#'   preserve_times = FALSE
#' )
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
  
  TextGrid(.xptr = xptr)
}

#' @title Extract Intervals from TextGrid Matching Criteria
#'
#' @description
#' Extracts intervals from a TextGrid tier that match a specified criterion.
#' Returns time boundaries and labels of matching intervals.
#'
#' @inheritParams pladdrr_shared_params textgrid
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
#' sound <- sounds_append(
#'   Sound$create_tone(frequency = 200, duration = 0.5, amplitude = 0.8),
#'   Sound$create_tone(frequency = 200, duration = 0.3, amplitude = 0.001)
#' )
#' vad_grid <- sound_to_textgrid_silences(sound)
#'
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

  # Get number of intervals in tier
  n_intervals <- textgrid$get_number_of_intervals(tier)

  if (n_intervals == 0) {
    return(list(xmin = numeric(0), xmax = numeric(0),
                text = character(0), count = 0L))
  }

  # Pre-allocate to max possible size, then trim
  xmin <- numeric(n_intervals)
  xmax <- numeric(n_intervals)
  labels <- character(n_intervals)
  k <- 0L

  for (i in seq_len(n_intervals)) {
    interval_text <- textgrid$get_interval_text(tier, i)

    # Check if interval matches condition
    match <- .interval_condition_matches(condition, interval_text, text)

    if (match) {
      k <- k + 1L
      xmin[k] <- textgrid$get_interval_start_time(tier, i)
      xmax[k] <- textgrid$get_interval_end_time(tier, i)
      labels[k] <- interval_text
    }
  }

  # Trim to actual count
  list(
    xmin = xmin[seq_len(k)],
    xmax = xmax[seq_len(k)],
    text = labels[seq_len(k)],
    count = k
  )
}

#' @title Extract Multiple Parts from a Sound
#'
#' @description
#' Extracts multiple time intervals from a Sound object and returns them as
#' a list of Sound objects. Useful for extracting voiced segments identified
#' by voice activity detection.
#'
#' @inheritParams pladdrr_shared_sound sound
#' @param start_times Numeric vector of interval start times (seconds)
#' @param end_times Numeric vector of interval end times (seconds)
#' @param window_shape Character. Window shape for extraction (default: "rectangular").
#'   See details for all options.
#' @param relative_width Numeric. Relative width of window (default: 1.0).
#'   For gaussian2/kaiser2, use 2.0. For gaussian3-5, use 3.0-5.0 respectively.
#' @param preserve_times Logical. Preserve original time stamps (default: FALSE)
#'
#' @return List of Sound objects, one for each extracted interval
#'
#' @details
#' This function is vectorized to extract multiple intervals efficiently.
#' Each extracted sound can then be concatenated or analyzed separately.
#'
#' Available window shapes (see Praat manual for details):
#' - "rectangular" (default) - No tapering
#' - "triangular" - Triangular (Bartlett) taper
#' - "parabolic" - Parabolic (Welch) taper
#' - "hanning" - Hanning window
#' - "hamming" - Hamming window
#' - "gaussian1" - Gaussian window (sd=0.42466)
#' - "gaussian2" - Narrower Gaussian (sd=0.21233), use relative_width=2.0
#' - "gaussian3" - Even narrower (sd=0.14155), use relative_width=3.0
#' - "gaussian4" - Very narrow (sd=0.10616), use relative_width=4.0
#' - "gaussian5" - Extremely narrow (sd=0.08493), use relative_width=5.0
#' - "kaiser1" - Kaiser-Bessel window (alpha=20.7)
#' - "kaiser2" - Narrower Kaiser-Bessel (alpha=40.5), use relative_width=2.0
#'
#' @references
#' Praat documentation: \url{https://www.fon.hum.uva.nl/praat/manual/Sound__Extract_part___.html}
#'
#' @examples
#' sound <- sounds_append(
#'   Sound$create_tone(frequency = 200, duration = 0.5, amplitude = 0.8),
#'   Sound$create_tone(frequency = 200, duration = 0.3, amplitude = 0.001)
#' )
#' vad_grid <- sound_to_textgrid_silences(sound)
#' voiced_intervals <- textgrid_get_intervals_where(vad_grid, 1, "equals", "sounding")
#'
#' voiced_sounds <- sound_extract_parts(
#'   sound,
#'   voiced_intervals$xmin,
#'   voiced_intervals$xmax
#' )
#'
#' # Analyze each segment separately
#' for (i in seq_along(voiced_sounds)) {
#'   cat("Segment", i, "duration:", voiced_sounds[[i]]$get_total_duration(), "s\n")
#' }
#'
#' @param return_r6 Logical. Return R6 Sound objects (TRUE) or raw xptrs (FALSE).
#'   Using FALSE skips R6 wrapper construction.
#' @export
sound_extract_parts <- function(sound,
                               start_times,
                               end_times,
                               window_shape = "rectangular",
                               relative_width = 1.0,
                               preserve_times = FALSE,
                               return_r6 = TRUE) {

  # Accept both R6 and xptr
  if (inherits(sound, "Sound")) {
    xptr <- sound$.xptr   # dispatch-table wrapper exposes the pointer as $.xptr
  } else if (inherits(sound, "externalptr")) {
    xptr <- sound
  } else {
    stop("sound must be a Sound object or external pointer")
  }

  if (length(start_times) != length(end_times)) {
    stop("start_times and end_times must have the same length")
  }

  # Convert window_shape to integer for C++ function
  window_int <- switch(
    tolower(window_shape),
    rectangular = 0L, triangular = 1L, parabolic = 2L,
    hanning = 3L, hamming = 4L,
    gaussian1 = 5L, gaussian2 = 6L, gaussian3 = 7L,
    gaussian4 = 8L, gaussian5 = 9L,
    kaiser1 = 10L, kaiser2 = 11L,
    0L  # default
  )

  # Use efficient C++ batch function
  xptrs <- .sound_extract_parts_batch(
    xptr,
    as.numeric(start_times),
    as.numeric(end_times),
    window_int,
    as.numeric(relative_width),
    as.logical(preserve_times)
  )

  if (return_r6) {
    # Convert XPtrs to Sound objects
    lapply(xptrs, function(xptr) Sound(.xptr = xptr))
  } else {
    xptrs
  }
}

#' @title Extract Voiced Segments from Speech
#'
#' @description
#' Voice activity detection combining intensity-based detection with optional
#' Zero Crossing Rate (ZCR) filtering. Returns concatenated voiced segments
#' as a Sound object. This matches the AVQI v2.03/v3.01 voiced extraction.
#'
#' @param sound Sound object (continuous speech)
#' @param minimum_pitch Numeric. Minimum pitch for intensity detection (Hz, default: 50)
#' @param time_step Numeric. Time step for intensity analysis (s, default: 0.003)
#' @param silence_threshold Numeric. Silence threshold in dB below max (default: -25)
#' @param min_silent_interval Numeric. Minimum silence duration (s, default: 0.1)
#' @param min_sounding_interval Numeric. Minimum voiced duration (s, default: 0.1)
#' @param zcr_threshold Numeric. Maximum ZCR for voiced speech (Hz, default: 3000)
#' @param zcr_window Numeric. ZCR analysis window duration (s, default: 0.03)
#' @param use_zcr Logical. Apply ZCR filtering (default: TRUE)
#' @param return_textgrid Logical. Also return VAD TextGrid (default: FALSE)
#'
#' @return If `return_textgrid = FALSE`: Sound object with concatenated voiced segments.
#'         If `return_textgrid = TRUE`: List with `sound` and `textgrid` elements.
#'
#' @details
#' The detection pipeline:
#' 1. Intensity-based: Find segments above silence threshold
#' 2. ZCR filtering (if `use_zcr = TRUE`): Reject high-ZCR segments (unvoiced)
#'
#' AVQI uses both intensity AND ZCR filtering. Set `use_zcr = FALSE` for
#' intensity-only detection.
#'
#' @examples
#' \donttest{
#' sound <- Sound$create_tone(frequency = 150, duration = 1, sampling_rate = 16000)
#'
#' # Full AVQI-compatible extraction (default)
#' voiced <- extract_voiced_segments(sound)
#'
#' # Intensity-only (no ZCR filtering)
#' voiced_no_zcr <- extract_voiced_segments(sound, use_zcr = FALSE)
#'
#' # With TextGrid output
#' result <- extract_voiced_segments(sound, return_textgrid = TRUE)
#' cat("Duration:", result$sound$get_duration(), "s\n")
#' }
#'
#' @export
extract_voiced_segments <- function(sound,
                                    minimum_pitch = 50,
                                    time_step = 0.003,
                                    silence_threshold = -25,
                                    min_silent_interval = 0.1,
                                    min_sounding_interval = 0.1,
                                    zcr_threshold = 3000,
                                    zcr_window = 0.03,
                                    use_zcr = TRUE,
                                    return_textgrid = FALSE) {

  if (!inherits(sound, "Sound")) {
    stop("sound must be a Sound object")
  }

  # Steps 1-2: Intensity-based detection of voiced intervals
  det <- .detect_voiced_intervals(sound, minimum_pitch, time_step, silence_threshold,
                                   min_silent_interval, min_sounding_interval)
  vad_grid <- det$vad_grid
  voiced_intervals <- det$voiced_intervals

  if (voiced_intervals$count == 0) {
    warning("No voiced segments detected by intensity")
    if (return_textgrid) {
      return(list(sound = NULL, textgrid = vad_grid))
    }
    return(NULL)
  }

  # Step 3: Apply ZCR filtering if requested
  xmin <- voiced_intervals$xmin
  xmax <- voiced_intervals$xmax

  if (use_zcr && voiced_intervals$count > 0) {
    f <- .apply_zcr_filter(xmin, xmax, sound, zcr_threshold, zcr_window)
    xmin <- f$xmin
    xmax <- f$xmax

    if (length(xmin) == 0) {
      warning("All segments rejected by ZCR filter")
      if (return_textgrid) {
        return(list(sound = NULL, textgrid = vad_grid))
      }
      return(NULL)
    }
  }

  # Step 4: Extract and concatenate
  .extract_voiced_sound(sound, xmin, xmax, vad_grid, return_textgrid)
}

#' @title Calculate Zero Crossing Rate for Sound
#'
#' @description
#' Calculates Zero Crossing Rate (ZCR) per frame using Praat's built-in zero
#' crossing detection. ZCR is the rate at which the signal changes sign,
#' useful for distinguishing voiced (low ZCR) from unvoiced (high ZCR) speech.
#'
#' @inheritParams pladdrr_shared_sound sound
#' @param window_duration Numeric. Window duration in seconds (default: 0.03)
#' @param hop_duration Numeric. Hop between windows in seconds (default: 0.01)
#' @param channel Integer. Channel to analyze for stereo (default: 1)
#' @param avqi_compatible Logical. Use AVQI-compatible analysis window
#'   (0.0025-0.0275s within each frame) instead of full frame (default: TRUE)
#'
#' @return Named list with:
#'   - `times`: Numeric vector of frame center times
#'   - `zcr`: Numeric vector of zero crossing rates (crossings per second)
#'   - `window_duration`: Window duration used
#'   - `hop_duration`: Hop duration used
#'
#' @details
#' Uses Praat's `to_point_process_zeros()` for accurate zero crossing detection
#' with interpolation.
#'
#' When `avqi_compatible = TRUE` (default), uses AVQI203.praat's checkZeros
#' procedure: analyzes zeros within 0.0025-0.0275s of each frame (25ms analysis
#' window within 30ms frame). This matches Praat's AVQI implementation.
#'
#' Typical ZCR values:
#' - Voiced speech: 500-2000 crossings/second
#' - Unvoiced speech: 3000-6000 crossings/second
#' - Silence: variable, depends on noise
#'
#' For AVQI, segments with ZCR > 3000 Hz are typically rejected as unvoiced.
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 1.0)
#' zcr_data <- sound_get_zcr(sound, window_duration = 0.03)
#' str(zcr_data)
#'
#' @export
sound_get_zcr <- function(sound,
                          window_duration = 0.03,
                          hop_duration = 0.01,
                          channel = 1L,
                          avqi_compatible = TRUE) {

  if (!inherits(sound, "Sound")) {
    stop("sound must be a Sound object")
  }

  # Get all zero crossings using Praat's built-in detection (with interpolation)
  pp_zeros <- sound$to_point_process_zeros(
    channel = channel,
    include_raisers = TRUE,
    include_fallers = TRUE
  )

  # Get zero crossing times as vector
  zero_times <- pp_zeros$as_vector()

  # Get sound timing info
  duration <- sound$get_duration()
  start_time <- sound$get_xmin()

  # Calculate frame parameters
  n_frames <- max(1L, as.integer((duration - window_duration) / hop_duration) + 1L)

  times <- numeric(n_frames)
  zcr <- numeric(n_frames)

  # AVQI analysis window offsets (within each frame)
  avqi_start_offset <- 0.0025
  avqi_end_offset <- 0.0275

  fr <- .compute_zcr_frames(zero_times, start_time, n_frames, window_duration,
                            hop_duration, avqi_compatible, avqi_start_offset, avqi_end_offset)
  list(times = fr$times, zcr = fr$zcr,
       window_duration = window_duration, hop_duration = hop_duration)
}


# ZCR for one frame (AVQI 0.0025-0.0275s window or full frame).
.frame_zcr <- function(frame_zeros, frame_start, window_duration,
                       avqi_compatible, avqi_start_offset, avqi_end_offset) {
  if (avqi_compatible && window_duration >= 0.03) {
    relative_zeros <- frame_zeros - frame_start
    zc <- relative_zeros[relative_zeros >= avqi_start_offset & relative_zeros <= avqi_end_offset]
  } else {
    zc <- frame_zeros
  }
  n <- length(zc)
  if (n >= 2) {
    afstand <- zc[n] - zc[1]
    if (afstand > 0) return(n / afstand)
    return(0)
  } else if (n == 1) {
    return(1 / window_duration)
  }
  0
}


# Test whether an interval label matches the requested condition.
.interval_condition_matches <- function(condition, interval_text, text) {
  switch(condition,
    "equals" = interval_text == text,
    "contains" = grepl(text, interval_text, fixed = TRUE),
    "does not contain" = !grepl(text, interval_text, fixed = TRUE),
    "starts with" = startsWith(interval_text, text),
    "ends with" = endsWith(interval_text, text),
    FALSE
  )
}


# Compute per-frame ZCR time series from zero-crossing times.
.compute_zcr_frames <- function(zero_times, start_time, n_frames, window_duration,
                                hop_duration, avqi_compatible, avqi_start_offset, avqi_end_offset) {
  times <- numeric(n_frames)
  zcr <- numeric(n_frames)
  for (i in seq_len(n_frames)) {
    frame_start <- start_time + (i - 1L) * hop_duration
    frame_end <- frame_start + window_duration
    times[i] <- frame_start + window_duration / 2
    frame_zeros <- zero_times[zero_times >= frame_start & zero_times < frame_end]
    zcr[i] <- .frame_zcr(frame_zeros, frame_start, window_duration,
                         avqi_compatible, avqi_start_offset, avqi_end_offset)
  }
  list(times = times, zcr = zcr)
}
