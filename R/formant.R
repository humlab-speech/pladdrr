# ============================================================================
# Frame-processing helpers (shared by .detect_formants_burg / .burg_algorithm)
# ============================================================================

# Extract a Hamming-windowed, pre-emphasised frame centered at time t.
.extract_windowed_frame <- function(signal, sr, t, window_samples, pre_emphasis_from) {
  n_samples <- length(signal)
  center_sample <- round(t * sr)
  start_sample <- max(1, center_sample - window_samples %/% 2)
  end_sample <- min(n_samples, center_sample + window_samples %/% 2)
  frame <- signal[start_sample:end_sample]
  hamming <- 0.54 - 0.46 * cos(2 * pi * seq(0, length(frame) - 1) / (length(frame) - 1))
  frame <- frame * hamming
  if (pre_emphasis_from > 0) {
    alpha <- exp(-2 * pi * pre_emphasis_from / sr)
    frame <- c(frame[1], frame[-1] - alpha * frame[-length(frame)])
  }
  frame
}

# Build the per-frame formant row lists (NA for undefined formants).
.frame_formant_rows <- function(t, formants, n_formants) {
  lapply(seq_len(n_formants), function(f) {
    if (f <= nrow(formants)) {
      list(time = t, formant_number = f,
           frequency = formants$frequency[f], bandwidth = formants$bandwidth[f])
    } else {
      list(time = t, formant_number = f, frequency = NA_real_, bandwidth = NA_real_)
    }
  })
}

#' Extract formants from a sound object (DEPRECATED)
#'
#' **DEPRECATED:** This function is deprecated in favor of the R6 interface.
#' Use `sound$to_formant_burg()` instead.
#'
#' Analyzes formant frequencies (vocal tract resonances) from a sound object
#' using Praat's Burg algorithm.
#'
#' @param sound A praat_sound object created by \code{\link{read_sound}} or
#'   \code{\link{create_sound}}
#' @param time_step Time step in seconds for formant analysis (0 = auto: 4x Nyquist)
#' @param max_formant Maximum formant frequency in Hz (default: 5500 for adult female,
#'   use 5000 for adult male, 8000 for child)
#' @param n_formants Number of formants to track (default: 5)
#' @param window_length Analysis window length in seconds (default: 0.025)
#' @param pre_emphasis_from Pre-emphasis frequency in Hz (default: 50)
#'
#' @return Depends on the class of \code{sound}:
#'   \itemize{
#'     \item If \code{sound} is an R6 \code{Sound} object (the normal case —
#'       \code{Sound()}/\code{Sound$create_tone()} always create one), this
#'       function delegates entirely to \code{sound$to_formant_burg()} and
#'       returns an R6 \code{Formant} object. \emph{This is what
#'       \code{\link{get_formant_at_time}}/\code{\link{get_mean_formant}}
#'       do NOT accept} — those two expect the legacy list below.
#'     \item If \code{sound} is a legacy (pre-R6) \code{praat_sound} list,
#'       returns a plain, \strong{unclassed} list with elements
#'       \code{values} (a data.frame with columns \code{time},
#'       \code{formant_number}, \code{frequency}, \code{bandwidth}),
#'       \code{n_frames}, \code{time_step}, \code{max_formant}, and
#'       \code{n_formants}. This list is no longer given a
#'       \code{"praat_formant"} class (removed when the package's S3 object
#'       system was fully migrated to R6), so it will not satisfy
#'       \code{\link{is_praat_formant}()} / \code{\link{get_formant_at_time}}
#'       / \code{\link{get_mean_formant}} without manually adding
#'       \code{class(x) <- "praat_formant"} first.
#'   }
#'
#' @examples
#' # sound is an R6 Sound object here, so this delegates to to_formant_burg()
#' # and returns an R6 Formant object (see the second value's \\value above).
#' sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate = 16000)
#' formants <- extract_formants(sound, max_formant = 5500)
#' f1_mean <- formants$get_mean(formant_number = 1)
#'
#' # Equivalent, and the recommended way to spell it directly:
#' formants2 <- sound$to_formant_burg(max_frequency = 5500)
#' f1_mean2 <- formants2$get_mean(formant_number = 1)
#' @export

extract_formants <- function(sound,
                             time_step = 0.0,
                             max_formant = 5500,
                             n_formants = 5,
                             window_length = 0.025,
                             pre_emphasis_from = 50) {
  
  .Deprecated(
    "sound$to_formant_burg()",
    package = "pladdrr",
    msg =
      "extract_formants() is deprecated and will be removed in v6.0.0. Use the R6 interface: sound$to_formant_burg()"
  )
  
  # Handle both S3 and R6 objects
  if (inherits(sound, "Sound")) {
    # R6 object - use directly
    return(sound$to_formant_burg(
      time_step = time_step,
      max_frequency = max_formant,
      max_formants = n_formants,
      window_length = window_length,
      pre_emphasis_from = pre_emphasis_from
    ))
  }
  
  # S3 object - old implementation
  .validate_formant_args(sound, max_formant, n_formants, time_step, window_length, pre_emphasis_from)
  
  # Extract signal and metadata
  signal <- sound$values
  sr <- sound$sampling_rate

  # Auto time step (Praat default: 4 times Nyquist frequency / max_formant)
  if (time_step == 0.0) {
    time_step <- window_length / 4
  }
  
  # Call formant detection algorithm
  result <- .burg_formants(signal, sr, time_step, max_formant, n_formants,
                           window_length, pre_emphasis_from)
  
  
  # S3 class assignment removed - this path deprecated
  # Function delegates to R6 for R6 objects
  return(result)
}

#' Internal formant detection using Burg's method
#'
#' @param signal Numeric vector, the audio samples
#' @param sr Sampling rate in Hz
#' @param time_step Time between analysis frames in seconds
#' @inheritParams pladdrr-shared-params max_formant
#' @param n_formants Number of formants to detect per frame
#' @param window_length Analysis window length in seconds
#' @param pre_emphasis_from Pre-emphasis frequency in Hz
#' @return A data.table with columns \code{time}, \code{formant_number},
#'   \code{frequency}, \code{bandwidth} (one row per formant per frame)
#' @keywords internal
#' @examples
#' set.seed(1)
#' signal <- sin(2 * pi * 500 * seq(0, 0.5, by = 1 / 16000)) + rnorm(8001, sd = 0.01)
#' pladdrr:::.detect_formants_burg(signal, sr = 16000, time_step = 0.05,
#'                                  max_formant = 5500, n_formants = 4,
#'                                  window_length = 0.025, pre_emphasis_from = 50)
#' @noRd
.detect_formants_burg <- function(signal, sr, time_step, max_formant,
                                  n_formants, window_length, pre_emphasis_from) {
  
  # Calculate frame parameters
  n_samples <- length(signal)
  duration <- n_samples / sr
  window_samples <- round(window_length * sr)
  
  # Generate frame times
  n_frames <- floor((duration - window_length) / time_step) + 1
  if (n_frames < 1) n_frames <- 1
  
  frame_times <- .frame_times_for_detection(duration, window_length, time_step)
  
  # Pre-allocate results as list for rbindlist
  results_list <- vector("list", length(frame_times) * n_formants)
  idx <- 1L
  
  # Process each frame
  for (i in seq_along(frame_times)) {
    t <- frame_times[i]
    
    # Extract windowed frame (Hamming + pre-emphasis)
    frame <- .extract_windowed_frame(signal, sr, t, window_samples, pre_emphasis_from)

    # LPC analysis using Burg's method
    lpc_order <- 2 * n_formants + 2
    formants <- .lpc_to_formants(frame, sr, lpc_order, n_formants, max_formant)

    # Add to results list
    rows <- .frame_formant_rows(t, formants, n_formants)
    for (r in rows) {
      results_list[[idx]] <- r
      idx <- idx + 1L
    }
  }
  
  # Combine all results efficiently with rbindlist
  results <- data.table::rbindlist(results_list)
  data.table::setkey(results, time, formant_number)
  
  return(results)
}

#' Convert LPC coefficients to formants
#'
#' @param frame Numeric vector, one windowed analysis frame
#' @param sr Sampling rate in Hz
#' @param lpc_order LPC order (number of coefficients)
#' @param n_formants Number of formants to return
#' @inheritParams pladdrr-shared-params max_formant
#' @return A data.frame with columns \code{frequency} and \code{bandwidth},
#'   one row per formant, padded with \code{NA} if fewer roots were found
#'   than \code{n_formants}
#' @keywords internal
#' @examples
#' set.seed(1)
#' frame <- sin(2 * pi * 500 * seq(0, 0.025, length.out = 400)) + rnorm(400, sd = 0.01)
#' pladdrr:::.lpc_to_formants(frame, sr = 16000, lpc_order = 12,
#'                             n_formants = 4, max_formant = 5500)
#' @noRd
.lpc_to_formants <- function(frame, sr, lpc_order, n_formants, max_formant) {
  
  # Burg's method for LPC estimation
  lpc_result <- .burg_algorithm(frame, lpc_order)
  
  if (is.null(lpc_result)) {
    return(data.frame(
      frequency = rep(NA_real_, n_formants),
      bandwidth = rep(NA_real_, n_formants)
    ))
  }
  
  # Find roots of LPC polynomial
  roots <- polyroot(c(1, -lpc_result$coefficients))
  
  # Convert roots to frequencies and bandwidths
  angles <- Arg(roots)
  magnitudes <- Mod(roots)
  
  # Keep only roots with positive frequencies and inside unit circle
  valid <- angles > 0 & magnitudes > 0.7 & magnitudes < 1.0
  
  if (sum(valid) == 0) {
    return(data.frame(
      frequency = rep(NA_real_, n_formants),
      bandwidth = rep(NA_real_, n_formants)
    ))
  }
  
  freqs <- angles[valid] * sr / (2 * pi)
  bandwidths <- -log(magnitudes[valid]) * sr / pi
  
  # Sort, filter, and pad to n_formants
  .sort_filter_formants(freqs, bandwidths, max_formant, n_formants)
}

#' Burg's algorithm for LPC estimation
#'
#' @param x Numeric vector, the input signal frame
#' @param order Integer, the LPC order
#' @return A list with \code{coefficients} (numeric vector of LPC
#'   coefficients) and \code{error} (prediction error power), or \code{NULL}
#'   if \code{x} is too short or has no variation
#' @keywords internal
#' @examples
#' set.seed(1)
#' x <- sin(2 * pi * 5 * seq(0, 1, length.out = 100)) + rnorm(100, sd = 0.01)
#' pladdrr:::.burg_algorithm(x, order = 8)
#' @noRd


# Is the running Burg prediction error still usable?
.burg_error_valid <- function(p) !is.na(p) && is.finite(p) && p > 0

# Are the Burg coefficients a usable filter?
.burg_coefficients_valid <- function(a) length(a) >= 2 && !anyNA(a) && all(is.finite(a))
.burg_algorithm <- function(x, order) {
  
  init <- .burg_initialize(x, order)
  if (is.null(init)) return(NULL)
  n <- init$n
  a <- init$a
  f <- init$f
  b <- init$b
  p <- init$p
  
  for (k in seq_len(order)) {
    # f and b stay full-length (n) throughout: only indices (k+1):n are
    # meaningful at this order, and reassigning them to shorter vectors
    # (as a prior version of this code did) misaligns every subsequent
    # iteration's f[(k+1):n]/b[k:(n-1)] slice, silently pulling in R's
    # NA-padded out-of-bounds values and poisoning every result with NA.
    idx <- (k + 1):n

    rc_info <- .burg_reflection_coefficient(f, b, idx)
    if (rc_info$status == "abort") return(NULL)
    if (rc_info$status == "break") break
    rc <- rc_info$rc

    # Update coefficients. a[i+1] is the order-(k-1) coefficient vector,
    # which has no i = k term yet; pad with a trailing zero so that term
    # contributes 0 instead of reading past the vector's end (NA).
    a <- .update_burg_coefficients(a, k, rc)

    up <- .update_burg_errors(f, b, idx, rc, p)
    f <- up$f
    b <- up$b
    p <- up$p
    if (!.burg_error_valid(p)) break
  }
  
  # Check if we got valid coefficients
  if (!.burg_coefficients_valid(a)) {
    return(NULL)
  }
  
  return(list(
    coefficients = a[-1],
    error = p
  ))
}

#' Get formant frequency at a specific time (DEPRECATED)
#'
#' **DEPRECATED:** Use the R6 interface instead: `formant$get_value_at_time()`
#'
#' @param formant A legacy \code{praat_formant}-shaped list: a plain list
#'   with a \code{values} element (a data.frame with columns \code{time},
#'   \code{formant_number}, \code{frequency}, \code{bandwidth}) and a
#'   \code{class} attribute of \code{"praat_formant"}. \code{\link{extract_formants}()}
#'   no longer produces this (it now returns an R6 \code{Formant} object
#'   instead — see its \code{\link{extract_formants}} documentation); build
#'   one by hand for this legacy function, or use
#'   \code{formant$get_value_at_time()} on an R6 \code{Formant} object
#'   directly instead of this deprecated wrapper.
#' @param formant_number Which formant (1 = F1, 2 = F2, etc.)
#' @inheritParams pladdrr-shared-params time
#' @param interpolate Logical; if TRUE, interpolate between frames
#'
#' @return Formant frequency in Hz, or NA if undefined
#' @examples
#' # A praat_formant-shaped list (see the @param formant description
#' # above); built directly here for a self-contained example.
#' formant <- structure(
#'   list(
#'     values = data.frame(
#'       time = c(0.1, 0.1, 0.2, 0.2),
#'       formant_number = c(1, 2, 1, 2),
#'       frequency = c(500, 1500, 520, 1480),
#'       bandwidth = c(80, 120, 85, 110)
#'     ),
#'     n_frames = 2,
#'     n_formants = 2
#'   ),
#'   class = "praat_formant"
#' )
#' get_formant_at_time(formant, formant_number = 1, time = 0.15)
#' @export
get_formant_at_time <- function(formant, formant_number, time, interpolate = FALSE) {
  
  .Deprecated(
    "formant$get_value_at_time()",
    package = "pladdrr",
    msg =
      paste0("get_formant_at_time() is deprecated and will be removed in v6.0.0. ",
             "Use the R6 interface: formant$get_value_at_time(formant_number, time)")
  )
  
  validate_formant_object(formant)
  validate_positive_int(formant_number, "formant_number")
  
  # Filter to requested formant
  formant_data <- formant$values[formant$values$formant_number == formant_number, ]
  
  if (nrow(formant_data) == 0) {
    return(NA_real_)
  }
  
  if (interpolate) {
    # Linear interpolation
    # Check if we have enough non-NA values
    valid_values <- !is.na(formant_data$frequency)
    if (sum(valid_values) < 2) {
      # Not enough points to interpolate
      idx <- which.min(abs(formant_data$time - time))
      return(formant_data$frequency[idx])
    }
    
    if (time <= min(formant_data$time)) {
      return(formant_data$frequency[1])
    } else if (time >= max(formant_data$time)) {
      return(formant_data$frequency[nrow(formant_data)])
    } else {
      return(approx(formant_data$time, formant_data$frequency, xout = time)$y)
    }
  } else {
    # Nearest frame
    idx <- which.min(abs(formant_data$time - time))
    return(formant_data$frequency[idx])
  }
}

#' Get mean formant frequency (DEPRECATED)
#'
#' **DEPRECATED:** Use the R6 interface instead: `formant$get_mean()`
#'
#' @param formant A legacy \code{praat_formant}-shaped list: a plain list
#'   with a \code{values} element (a data.frame with columns \code{time},
#'   \code{formant_number}, \code{frequency}, \code{bandwidth}) and a
#'   \code{class} attribute of \code{"praat_formant"}. \code{\link{extract_formants}()}
#'   no longer produces this (it now returns an R6 \code{Formant} object
#'   instead — see its \code{\link{extract_formants}} documentation); build
#'   one by hand for this legacy function, or use
#'   \code{formant$get_mean()} on an R6 \code{Formant} object directly
#'   instead of this deprecated wrapper.
#' @param formant_number Which formant (1 = F1, 2 = F2, etc.)
#' @param time_range Optional numeric vector c(start, end) in seconds
#'
#' @return Mean formant frequency in Hz, or NA if undefined
#' @examples
#' # A praat_formant-shaped list (see the @param formant description
#' # above); built directly here for a self-contained example.
#' formant <- structure(
#'   list(
#'     values = data.frame(
#'       time = c(0.1, 0.1, 0.2, 0.2),
#'       formant_number = c(1, 2, 1, 2),
#'       frequency = c(500, 1500, 520, 1480),
#'       bandwidth = c(80, 120, 85, 110)
#'     ),
#'     n_frames = 2,
#'     n_formants = 2
#'   ),
#'   class = "praat_formant"
#' )
#' get_mean_formant(formant, formant_number = 1)
#' @export
get_mean_formant <- function(formant, formant_number, time_range = NULL) {
  
  .Deprecated(
    "formant$get_mean()",
    package = "pladdrr",
    msg =
      paste0("get_mean_formant() is deprecated and will be removed in v6.0.0. ",
             "Use the R6 interface: formant$get_mean(formant_number, from_time, to_time)")
  )
  
  validate_formant_object(formant)
  validate_positive_int(formant_number, "formant_number")
  
  # Filter to requested formant
  formant_data <- formant$values[formant$values$formant_number == formant_number, ]
  
  if (!is.null(time_range)) {
    formant_data <- formant_data[
      formant_data$time >= time_range[1] & formant_data$time <= time_range[2],
    ]
  }
  
  if (nrow(formant_data) == 0) {
    return(NA_real_)
  }
  
  return(mean(formant_data$frequency, na.rm = TRUE))
}


# Compute the frame times for formant detection.
.frame_times_for_detection <- function(duration, window_length, time_step) {
  if (duration <= window_length) return(duration / 2)
  frame_times <- seq(window_length / 2, duration - window_length / 2, by = time_step)
  if (length(frame_times) == 0 || anyNA(frame_times)) return(duration / 2)
  frame_times
}


# Run Burg formant detection and assemble the (deprecated) formant list.
.burg_formants <- function(signal, sr, time_step, max_formant, n_formants,
                           window_length, pre_emphasis_from) {
  formant_data <- .detect_formants_burg(
    signal = signal, sr = sr, time_step = time_step, max_formant = max_formant,
    n_formants = n_formants, window_length = window_length,
    pre_emphasis_from = pre_emphasis_from)
  list(values = formant_data,
       n_frames = length(unique(formant_data$time)),
       time_step = time_step, max_formant = max_formant,
       n_formants = n_formants, window_length = window_length)
}


# Validate the (deprecated) formant-extraction arguments.
.validate_formant_args <- function(sound, max_formant, n_formants, time_step,
                                   window_length, pre_emphasis_from) {
  validate_sound_object(sound)
  validate_positive(max_formant, "max_formant")
  validate_positive_int(n_formants, "n_formants")
  validate_non_negative(time_step, "time_step")
  validate_positive(window_length, "window_length")
  validate_positive(pre_emphasis_from, "pre_emphasis_from")
}


# Sort LPC-derived formant frequencies, filter to max, pad/truncate.
.sort_filter_formants <- function(freqs, bandwidths, max_formant, n_formants) {
  ord <- order(freqs)
  freqs <- freqs[ord]
  bandwidths <- bandwidths[ord]
  valid_freqs <- freqs <= max_formant
  freqs <- freqs[valid_freqs]
  bandwidths <- bandwidths[valid_freqs]
  if (length(freqs) < n_formants) {
    freqs <- c(freqs, rep(NA_real_, n_formants - length(freqs)))
    bandwidths <- c(bandwidths, rep(NA_real_, n_formants - length(bandwidths)))
  } else if (length(freqs) > n_formants) {
    freqs <- freqs[seq_len(n_formants)]
    bandwidths <- bandwidths[seq_len(n_formants)]
  }
  data.frame(frequency = freqs, bandwidth = bandwidths)
}


# Burg reflection coefficient; status abort/break/ok.
.burg_reflection_coefficient <- function(f, b, idx) {
  num <- sum(f[idx] * b[idx - 1])
  den <- sum(f[idx]^2) + sum(b[idx - 1]^2)
  if (is.na(den) || !is.finite(den) || den == 0) return(list(status = "abort"))
  rc <- -2 * num / den
  if (is.na(rc) || !is.finite(rc) || abs(rc) >= 1) return(list(status = "break"))
  list(status = "ok", rc = rc)
}

# Update Burg LPC coefficients for order k with reflection coefficient rc.
.update_burg_coefficients <- function(a, k, rc) {
  a_padded <- c(a, 0)
  a_new <- numeric(k + 1)
  a_new[1] <- 1
  for (i in seq_len(k)) a_new[i + 1] <- a_padded[i + 1] + rc * a[k - i + 1]
  a_new
}


# Update Burg forward/backward errors and prediction error power.
.update_burg_errors <- function(f, b, idx, rc, p) {
  old_f <- f[idx]
  f[idx] <- old_f + rc * b[idx - 1]
  b[idx] <- b[idx - 1] + rc * old_f
  p <- p * (1 - rc^2)
  list(f = f, b = b, p = p)
}


# Initialize the Burg algorithm state; NULL if degenerate.
.burg_initialize <- function(x, order) {
  n <- length(x)
  if (n < order + 1) return(NULL)
  a <- numeric(order + 1)
  a[1] <- 1
  f <- x
  b <- x
  p <- sum(x^2) / n
  if (p == 0 || is.na(p) || !is.finite(p)) return(NULL)
  list(a = a, f = f, b = b, p = p, n = n)
}
