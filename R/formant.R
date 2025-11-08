#' Extract formants from a sound object
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
#' @return A praat_formant object (S3 class) with:
#'   \itemize{
#'     \item \code{values}: data.frame with columns time, formant_number, frequency, bandwidth
#'     \item \code{n_frames}: number of analysis frames
#'     \item \code{time_step}: actual time step used
#'     \item \code{max_formant}: maximum formant frequency setting
#'     \item \code{n_formants}: number of formants tracked
#'   }
#'
#' @export
#' @examples
#' \dontrun{
#' sound <- read_sound("vowel.wav")
#' formants <- extract_formants(sound, max_formant = 5500)
#' 
#' # Get F1 and F2 at specific time
#' f1 <- get_formant_at_time(formants, formant_number = 1, time = 0.5)
#' f2 <- get_formant_at_time(formants, formant_number = 2, time = 0.5)
#' }
extract_formants <- function(sound,
                             time_step = 0.0,
                             max_formant = 5500,
                             n_formants = 5,
                             window_length = 0.025,
                             pre_emphasis_from = 50) {
  
  validate_sound_object(sound)
  validate_positive(max_formant, "max_formant")
  validate_positive_int(n_formants, "n_formants")
  validate_non_negative(time_step, "time_step")
  validate_positive(window_length, "window_length")
  validate_positive(pre_emphasis_from, "pre_emphasis_from")
  
  # Extract signal and metadata
  signal <- sound$values
  sr <- sound$sampling_rate
  duration <- sound$duration
  
  # Auto time step (Praat default: 4 times Nyquist frequency / max_formant)
  if (time_step == 0.0) {
    time_step <- window_length / 4
  }
  
  # Call formant detection algorithm
  formant_data <- .detect_formants_burg(
    signal = signal,
    sr = sr,
    time_step = time_step,
    max_formant = max_formant,
    n_formants = n_formants,
    window_length = window_length,
    pre_emphasis_from = pre_emphasis_from
  )
  
  # Create formant object
  result <- list(
    values = formant_data,
    n_frames = length(unique(formant_data$time)),
    time_step = time_step,
    max_formant = max_formant,
    n_formants = n_formants,
    window_length = window_length
  )
  
  class(result) <- c("praat_formant", "list")
  return(result)
}

#' Internal formant detection using Burg's method
#'
#' @keywords internal
.detect_formants_burg <- function(signal, sr, time_step, max_formant,
                                  n_formants, window_length, pre_emphasis_from) {
  
  # Calculate frame parameters
  n_samples <- length(signal)
  duration <- n_samples / sr
  window_samples <- round(window_length * sr)
  
  # Generate frame times
  n_frames <- floor((duration - window_length) / time_step) + 1
  if (n_frames < 1) n_frames <- 1
  
  # If time_step would be negative (very short signal), just use one frame
  if (duration <= window_length) {
    frame_times <- duration / 2
  } else {
    frame_times <- seq(window_length / 2, 
                       duration - window_length / 2,
                       by = time_step)
    
    if (length(frame_times) == 0 || any(is.na(frame_times))) {
      frame_times <- duration / 2
    }
  }
  
  # Pre-allocate results
  results <- data.frame(
    time = numeric(),
    formant_number = integer(),
    frequency = numeric(),
    bandwidth = numeric(),
    stringsAsFactors = FALSE
  )
  
  # Process each frame
  for (i in seq_along(frame_times)) {
    t <- frame_times[i]
    
    # Extract windowed frame
    center_sample <- round(t * sr)
    start_sample <- max(1, center_sample - window_samples %/% 2)
    end_sample <- min(n_samples, center_sample + window_samples %/% 2)
    
    frame <- signal[start_sample:end_sample]
    
    # Apply Hamming window
    hamming <- 0.54 - 0.46 * cos(2 * pi * seq(0, length(frame) - 1) / (length(frame) - 1))
    frame <- frame * hamming
    
    # Pre-emphasis filter
    if (pre_emphasis_from > 0) {
      alpha <- exp(-2 * pi * pre_emphasis_from / sr)
      frame <- c(frame[1], frame[-1] - alpha * frame[-length(frame)])
    }
    
    # LPC analysis using Burg's method
    lpc_order <- 2 * n_formants + 2
    formants <- .lpc_to_formants(frame, sr, lpc_order, n_formants, max_formant)
    
    # Add to results
    for (f in seq_len(n_formants)) {
      if (f <= nrow(formants)) {
        results <- rbind(results, data.frame(
          time = t,
          formant_number = f,
          frequency = formants$frequency[f],
          bandwidth = formants$bandwidth[f],
          stringsAsFactors = FALSE
        ))
      } else {
        # Undefined formant
        results <- rbind(results, data.frame(
          time = t,
          formant_number = f,
          frequency = NA_real_,
          bandwidth = NA_real_,
          stringsAsFactors = FALSE
        ))
      }
    }
  }
  
  return(results)
}

#' Convert LPC coefficients to formants
#'
#' @keywords internal
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
  
  # Sort by frequency
  ord <- order(freqs)
  freqs <- freqs[ord]
  bandwidths <- bandwidths[ord]
  
  # Filter by max formant
  valid_freqs <- freqs <= max_formant
  freqs <- freqs[valid_freqs]
  bandwidths <- bandwidths[valid_freqs]
  
  # Pad or truncate to n_formants
  if (length(freqs) < n_formants) {
    freqs <- c(freqs, rep(NA_real_, n_formants - length(freqs)))
    bandwidths <- c(bandwidths, rep(NA_real_, n_formants - length(bandwidths)))
  } else if (length(freqs) > n_formants) {
    freqs <- freqs[1:n_formants]
    bandwidths <- bandwidths[1:n_formants]
  }
  
  return(data.frame(
    frequency = freqs,
    bandwidth = bandwidths
  ))
}

#' Burg's algorithm for LPC estimation
#'
#' @keywords internal
.burg_algorithm <- function(x, order) {
  
  n <- length(x)
  
  if (n < order + 1) {
    return(NULL)
  }
  
  # Initialize
  a <- numeric(order + 1)
  a[1] <- 1
  
  f <- x
  b <- x
  
  p <- sum(x^2) / n
  
  # Check if signal has any variation
  if (p == 0 || is.na(p) || !is.finite(p)) {
    return(NULL)
  }
  
  for (k in 1:order) {
    # Calculate reflection coefficient
    num <- sum(f[(k+1):n] * b[k:(n-1)])
    den <- sum(f[(k+1):n]^2) + sum(b[k:(n-1)]^2)
    
    # Check for invalid values
    if (is.na(den) || !is.finite(den) || den == 0) {
      return(NULL)
    }
    
    rc <- -2 * num / den
    
    # Check reflection coefficient validity
    if (is.na(rc) || !is.finite(rc) || abs(rc) >= 1) {
      # Reflection coefficient out of range, stop iteration
      break
    }
    
    # Update coefficients
    a_new <- numeric(k + 1)
    a_new[1] <- 1
    for (i in 1:k) {
      a_new[i + 1] <- a[i + 1] + rc * a[k - i + 1]
    }
    a <- a_new
    
    # Update forward and backward prediction errors
    f_new <- f[(k+1):n] + rc * b[k:(n-1)]
    b_new <- b[k:(n-1)] + rc * f[(k+1):n]
    
    f <- f_new
    b <- b_new
    
    # Update prediction error power
    p <- p * (1 - rc^2)
    
    # Check if error power is valid
    if (is.na(p) || !is.finite(p) || p <= 0) {
      break
    }
  }
  
  # Check if we got valid coefficients
  if (length(a) < 2 || any(is.na(a)) || any(!is.finite(a))) {
    return(NULL)
  }
  
  return(list(
    coefficients = a[-1],
    error = p
  ))
}

#' Get formant frequency at a specific time
#'
#' @param formant A praat_formant object from \code{\link{extract_formants}}
#' @param formant_number Which formant (1 = F1, 2 = F2, etc.)
#' @param time Time in seconds
#' @param interpolate Logical; if TRUE, interpolate between frames
#'
#' @return Formant frequency in Hz, or NA if undefined
#' @export
get_formant_at_time <- function(formant, formant_number, time, interpolate = FALSE) {
  
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

#' Get mean formant frequency
#'
#' @param formant A praat_formant object from \code{\link{extract_formants}}
#' @param formant_number Which formant (1 = F1, 2 = F2, etc.)
#' @param time_range Optional numeric vector c(start, end) in seconds
#'
#' @return Mean formant frequency in Hz, or NA if undefined
#' @export
get_mean_formant <- function(formant, formant_number, time_range = NULL) {
  
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
