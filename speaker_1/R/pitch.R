# pitch.R - Pitch extraction and analysis functions
#
# This file implements pitch (fundamental frequency) analysis for speech signals.
# Uses autocorrelation-based pitch detection.

#' Extract pitch contour from sound
#'
#' Extracts the fundamental frequency (F0) contour from a sound object using
#' autocorrelation-based pitch detection. Returns a praat_pitch object containing
#' time-frequency pairs.
#'
#' @param sound A praat_sound object
#' @param pitch_floor Minimum pitch to detect in Hz (default: 75)
#' @param pitch_ceiling Maximum pitch to detect in Hz (default: 600)
#' @param time_step Time step between frames in seconds (default: 0.01, i.e., 10ms)
#'
#' @return A praat_pitch object (data frame with S3 class) containing:
#'   \describe{
#'     \item{time}{Time points in seconds}
#'     \item{frequency}{Fundamental frequency in Hz (NA for unvoiced)}
#'     \item{strength}{Confidence/strength measure (0-1)}
#'   }
#'
#' @details
#' The algorithm uses autocorrelation to detect periodicity in the signal.
#' Unvoiced segments are returned as NA. Quality warnings are issued if:
#' \itemize{
#'   \item Less than 30\% of frames are voiced
#'   \item Audio quality appears poor
#' }
#'
#' @examples
#' \dontrun{
#' sound <- read_sound("speech.wav")
#' pitch <- extract_pitch(sound, pitch_floor = 75, pitch_ceiling = 300)
#' plot(pitch$time, pitch$frequency, type = "l")
#' }
#'
#' @export
extract_pitch <- function(sound, pitch_floor = 75, pitch_ceiling = 600,
                          time_step = 0.01) {
  # Validate inputs
  validate_sound_object(sound, "sound")
  validate_positive(pitch_floor, "pitch_floor")
  validate_positive(pitch_ceiling, "pitch_ceiling")
  validate_positive(time_step, "time_step")

  if (pitch_floor >= pitch_ceiling) {
    stop("'pitch_floor' must be less than 'pitch_ceiling'", call. = FALSE)
  }

  # Extract signal properties
  signal <- sound$values
  sr <- sound$sampling_rate

  # Generate time frames
  frame_times <- seq(time_step, sound$duration - time_step, by = time_step)
  n_frames <- length(frame_times)

  # Pre-allocate results
  frequencies <- numeric(n_frames)
  strengths <- numeric(n_frames)

  # Window length for analysis (typically 3-4 periods of pitch_floor)
  window_length <- round(3 * sr / pitch_floor)

  # Analyze each frame
  for (i in seq_along(frame_times)) {
    # Get window around current time
    center_sample <- round(frame_times[i] * sr)
    start_sample <- max(1, center_sample - window_length %/% 2)
    end_sample <- min(length(signal), center_sample + window_length %/% 2)

    window <- signal[start_sample:end_sample]

    # Compute pitch for this frame using autocorrelation
    pitch_result <- .detect_pitch_autocorr(window, sr, pitch_floor, pitch_ceiling)

    frequencies[i] <- pitch_result$frequency
    strengths[i] <- pitch_result$strength
  }

  # Create pitch object
  pitch <- data.frame(
    time = frame_times,
    frequency = frequencies,
    strength = strengths,
    stringsAsFactors = FALSE
  )

  class(pitch) <- c("praat_pitch", "data.frame")

  # Quality checks and warnings
  voiced_rate <- sum(!is.na(frequencies) & frequencies > 0) / n_frames

  if (voiced_rate < 0.3) {
    quality_warning(sprintf(
      "Few voiced frames detected (%.1f%%). Audio may be mostly unvoiced or poor quality.",
      voiced_rate * 100
    ))
  }

  # Check for noisy signal (high variability in consecutive frames)
  voiced_freqs <- frequencies[!is.na(frequencies) & frequencies > 0]
  if (length(voiced_freqs) > 2) {
    freq_diff <- diff(voiced_freqs)
    rel_jumps <- abs(freq_diff) / voiced_freqs[-length(voiced_freqs)]
    if (mean(rel_jumps, na.rm = TRUE) > 0.3) {
      quality_warning("High pitch variability detected. Results may be unreliable for noisy audio.")
    }
  }

  return(pitch)
}

#' Detect pitch using autocorrelation
#'
#' Internal function that performs autocorrelation-based pitch detection
#' on a single frame.
#'
#' @param signal Signal window
#' @param sr Sampling rate
#' @param pitch_floor Minimum pitch
#' @param pitch_ceiling Maximum pitch
#' @return List with frequency and strength
#' @keywords internal
.detect_pitch_autocorr <- function(signal, sr, pitch_floor, pitch_ceiling) {
  # Remove DC component
  signal <- signal - mean(signal)

  # Compute autocorrelation
  max_lag <- round(sr / pitch_floor)
  min_lag <- round(sr / pitch_ceiling)

  if (max_lag > length(signal) / 2) {
    return(list(frequency = NA, strength = 0))
  }

  # Autocorrelation using FFT (faster for longer signals)
  n <- length(signal)
  if (n < min_lag + 1) {
    return(list(frequency = NA, strength = 0))
  }

  acf_result <- stats::acf(signal, lag.max = max_lag, plot = FALSE, na.action = na.pass)
  acf_vals <- as.numeric(acf_result$acf)

  # Find peaks in autocorrelation within pitch range
  search_lags <- min_lag:min(max_lag, length(acf_vals) - 1)

  if (length(search_lags) < 2) {
    return(list(frequency = NA, strength = 0))
  }

  # Find maximum in search range
  acf_search <- acf_vals[search_lags + 1]  # +1 because acf includes lag 0
  max_idx <- which.max(acf_search)

  if (length(max_idx) == 0) {
    return(list(frequency = NA, strength = 0))
  }

  peak_lag <- search_lags[max_idx]
  peak_strength <- acf_search[max_idx]

  # Threshold for voicing decision
  if (peak_strength < 0.3) {
    return(list(frequency = NA, strength = 0))
  }

  # Convert lag to frequency
  frequency <- sr / peak_lag

  # Verify frequency is in valid range
  if (frequency < pitch_floor || frequency > pitch_ceiling) {
    return(list(frequency = NA, strength = 0))
  }

  return(list(frequency = frequency, strength = peak_strength))
}

#' Get pitch at specific time point
#'
#' Extracts the fundamental frequency at a specific time point from a pitch object.
#' Can optionally interpolate between frames.
#'
#' @param pitch A praat_pitch object
#' @param time Time point in seconds
#' @param unit Unit for pitch value: "Hz" (default) or "semitones"
#' @param interpolate Logical, whether to interpolate between frames (default: FALSE)
#'
#' @return Pitch value in specified unit, or NA if unvoiced
#'
#' @examples
#' \dontrun{
#' sound <- read_sound("speech.wav")
#' pitch <- extract_pitch(sound)
#' f0 <- get_pitch_at_time(pitch, 0.5)  # Get pitch at 0.5 seconds
#' }
#'
#' @export
get_pitch_at_time <- function(pitch, time, unit = "Hz", interpolate = FALSE) {
  validate_pitch_object(pitch, "pitch")
  validate_non_negative(time, "time")

  # Find closest frame(s)
  if (interpolate && nrow(pitch) > 1) {
    # Linear interpolation between frames
    f0 <- stats::approx(pitch$time, pitch$frequency, xout = time, rule = 1)$y
  } else {
    # Nearest frame
    idx <- which.min(abs(pitch$time - time))
    if (length(idx) == 0) {
      f0 <- NA
    } else {
      f0 <- pitch$frequency[idx]
    }
  }

  # Convert units if requested
  if (!is.na(f0) && unit == "semitones") {
    f0 <- 12 * log2(f0)  # Semitones re: 1 Hz
  }

  return(f0)
}

#' Get mean pitch
#'
#' Computes the mean (average) fundamental frequency across a pitch contour,
#' excluding unvoiced frames.
#'
#' @param pitch A praat_pitch object
#' @param unit Unit for result: "Hz" (default) or "semitones"
#' @param time_range Optional numeric vector c(start, end) to restrict analysis
#'
#' @return Mean pitch value in specified unit
#'
#' @examples
#' \dontrun{
#' sound <- read_sound("speech.wav")
#' pitch <- extract_pitch(sound)
#' mean_f0 <- get_mean_pitch(pitch)
#' }
#'
#' @export
get_mean_pitch <- function(pitch, unit = "Hz", time_range = NULL) {
  validate_pitch_object(pitch, "pitch")

  # Filter by time range if specified
  if (!is.null(time_range)) {
    if (!is.numeric(time_range) || length(time_range) != 2) {
      stop("'time_range' must be a numeric vector of length 2", call. = FALSE)
    }
    pitch <- pitch[pitch$time >= time_range[1] & pitch$time <= time_range[2], ]
  }

  # Get voiced frequencies
  voiced_freqs <- pitch$frequency[!is.na(pitch$frequency) & pitch$frequency > 0]

  if (length(voiced_freqs) == 0) {
    return(NA_real_)
  }

  mean_f0 <- mean(voiced_freqs)

  # Convert units if requested
  if (unit == "semitones") {
    mean_f0 <- 12 * log2(mean_f0)
  }

  return(mean_f0)
}

#' Get minimum pitch
#'
#' Finds the minimum fundamental frequency in a pitch contour,
#' excluding unvoiced frames.
#'
#' @param pitch A praat_pitch object
#' @param unit Unit for result: "Hz" (default) or "semitones"
#' @param time_range Optional numeric vector c(start, end) to restrict analysis
#'
#' @return Minimum pitch value in specified unit
#'
#' @export
get_min_pitch <- function(pitch, unit = "Hz", time_range = NULL) {
  validate_pitch_object(pitch, "pitch")

  # Filter by time range if specified
  if (!is.null(time_range)) {
    if (!is.numeric(time_range) || length(time_range) != 2) {
      stop("'time_range' must be a numeric vector of length 2", call. = FALSE)
    }
    pitch <- pitch[pitch$time >= time_range[1] & pitch$time <= time_range[2], ]
  }

  # Get voiced frequencies
  voiced_freqs <- pitch$frequency[!is.na(pitch$frequency) & pitch$frequency > 0]

  if (length(voiced_freqs) == 0) {
    return(NA_real_)
  }

  min_f0 <- min(voiced_freqs)

  # Convert units if requested
  if (unit == "semitones") {
    min_f0 <- 12 * log2(min_f0)
  }

  return(min_f0)
}

#' Get maximum pitch
#'
#' Finds the maximum fundamental frequency in a pitch contour,
#' excluding unvoiced frames.
#'
#' @param pitch A praat_pitch object
#' @param unit Unit for result: "Hz" (default) or "semitones"
#' @param time_range Optional numeric vector c(start, end) to restrict analysis
#'
#' @return Maximum pitch value in specified unit
#'
#' @export
get_max_pitch <- function(pitch, unit = "Hz", time_range = NULL) {
  validate_pitch_object(pitch, "pitch")

  # Filter by time range if specified
  if (!is.null(time_range)) {
    if (!is.numeric(time_range) || length(time_range) != 2) {
      stop("'time_range' must be a numeric vector of length 2", call. = FALSE)
    }
    pitch <- pitch[pitch$time >= time_range[1] & pitch$time <= time_range[2], ]
  }

  # Get voiced frequencies
  voiced_freqs <- pitch$frequency[!is.na(pitch$frequency) & pitch$frequency > 0]

  if (length(voiced_freqs) == 0) {
    return(NA_real_)
  }

  max_f0 <- max(voiced_freqs)

  # Convert units if requested
  if (unit == "semitones") {
    max_f0 <- 12 * log2(max_f0)
  }

  return(max_f0)
}
