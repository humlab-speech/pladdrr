#' Extract intensity from a sound object
#'
#' Analyzes intensity (sound power) from a sound object over time.
#' Intensity is measured in dB relative to the auditory threshold.
#'
#' @param sound A praat_sound object created by \code{\link{read_sound}} or
#'   \code{\link{create_sound}}
#' @param time_step Time step in seconds for intensity analysis (0 = auto: 0.8 / minimum_pitch)
#' @param minimum_pitch Minimum pitch for analysis in Hz (default: 100). Used to
#'   determine window length
#' @param subtract_mean Logical; subtract mean intensity to get relative values (default: TRUE)
#'
#' @return A praat_intensity object (S3 class) with:
#'   \itemize{
#'     \item \code{values}: data.frame with columns time, intensity_db
#'     \item \code{n_frames}: number of analysis frames
#'     \item \code{time_step}: actual time step used
#'     \item \code{minimum_pitch}: minimum pitch setting
#'   }
#'
#' @export
#' @examples
#' \dontrun{
#' sound <- read_sound("speech.wav")
#' intensity <- extract_intensity(sound, minimum_pitch = 100)
#' 
#' # Get intensity at specific time
#' int_at_time <- get_intensity_at_time(intensity, time = 0.5)
#' 
#' # Get mean intensity
#' mean_int <- get_mean_intensity(intensity)
#' }
extract_intensity <- function(sound,
                              time_step = 0.0,
                              minimum_pitch = 100,
                              subtract_mean = TRUE) {
  
  validate_sound_object(sound)
  validate_non_negative(time_step, "time_step")
  validate_positive(minimum_pitch, "minimum_pitch")
  validate_logical(subtract_mean, "subtract_mean")
  
  # Extract signal and metadata
  signal <- sound$values
  sr <- sound$sampling_rate
  duration <- sound$duration
  
  # Auto time step (Praat default: 0.8 / minimum_pitch)
  if (time_step == 0.0) {
    time_step <- 0.8 / minimum_pitch
  }
  
  # Window length is 3.2 / minimum_pitch (Praat default)
  window_length <- 3.2 / minimum_pitch
  
  # Call intensity calculation
  intensity_data <- .calculate_intensity(
    signal = signal,
    sr = sr,
    time_step = time_step,
    window_length = window_length,
    subtract_mean = subtract_mean
  )
  
  # Create intensity object
  result <- list(
    values = intensity_data,
    n_frames = nrow(intensity_data),
    time_step = time_step,
    minimum_pitch = minimum_pitch,
    window_length = window_length,
    subtract_mean = subtract_mean
  )
  
  class(result) <- c("praat_intensity", "list")
  return(result)
}

#' Internal intensity calculation
#'
#' @keywords internal
.calculate_intensity <- function(signal, sr, time_step, window_length,
                                subtract_mean) {
  
  # Calculate frame parameters
  n_samples <- length(signal)
  duration <- n_samples / sr
  window_samples <- round(window_length * sr)
  
  # Ensure window is odd for symmetry
  if (window_samples %% 2 == 0) {
    window_samples <- window_samples + 1
  }
  
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
  intensities <- numeric(length(frame_times))
  
  # Reference pressure for dB calculation (20 micropascals)
  # This gives intensity in dB SPL
  reference_power <- 4e-10  # (2e-5)^2
  
  # Process each frame
  for (i in seq_along(frame_times)) {
    t <- frame_times[i]
    
    # Extract windowed frame
    center_sample <- round(t * sr)
    start_sample <- max(1, center_sample - window_samples %/% 2)
    end_sample <- min(n_samples, center_sample + window_samples %/% 2)
    
    frame <- signal[start_sample:end_sample]
    
    # Apply Gaussian window (Praat uses this for intensity)
    window_size <- length(frame)
    gaussian <- exp(-12 * ((seq_len(window_size) - (window_size + 1) / 2) / window_size)^2)
    frame <- frame * gaussian
    
    # Calculate RMS power
    power <- mean(frame^2)
    
    # Convert to dB
    if (power > 0) {
      intensities[i] <- 10 * log10(power / reference_power)
    } else {
      intensities[i] <- NA_real_
    }
  }
  
  # Subtract mean if requested (gives relative intensity)
  if (subtract_mean) {
    mean_intensity <- mean(intensities, na.rm = TRUE)
    if (!is.na(mean_intensity)) {
      intensities <- intensities - mean_intensity
    }
  }
  
  # Create data.frame
  result <- data.frame(
    time = frame_times,
    intensity_db = intensities,
    stringsAsFactors = FALSE
  )
  
  return(result)
}

#' Get intensity at a specific time
#'
#' @param intensity A praat_intensity object from \code{\link{extract_intensity}}
#' @param time Time in seconds
#' @param interpolate Logical; if TRUE, interpolate between frames
#'
#' @return Intensity in dB, or NA if undefined
#' @export
get_intensity_at_time <- function(intensity, time, interpolate = FALSE) {
  
  validate_intensity_object(intensity)
  
  intensity_data <- intensity$values
  
  if (nrow(intensity_data) == 0) {
    return(NA_real_)
  }
  
  if (interpolate) {
    # Linear interpolation
    if (time <= min(intensity_data$time)) {
      return(intensity_data$intensity_db[1])
    } else if (time >= max(intensity_data$time)) {
      return(intensity_data$intensity_db[nrow(intensity_data)])
    } else {
      return(approx(intensity_data$time, intensity_data$intensity_db, xout = time)$y)
    }
  } else {
    # Nearest frame
    idx <- which.min(abs(intensity_data$time - time))
    return(intensity_data$intensity_db[idx])
  }
}

#' Get mean intensity
#'
#' @param intensity A praat_intensity object from \code{\link{extract_intensity}}
#' @param time_range Optional numeric vector c(start, end) in seconds
#'
#' @return Mean intensity in dB, or NA if undefined
#' @export
get_mean_intensity <- function(intensity, time_range = NULL) {
  
  validate_intensity_object(intensity)
  
  intensity_data <- intensity$values
  
  if (!is.null(time_range)) {
    intensity_data <- intensity_data[
      intensity_data$time >= time_range[1] & intensity_data$time <= time_range[2],
    ]
  }
  
  if (nrow(intensity_data) == 0) {
    return(NA_real_)
  }
  
  return(mean(intensity_data$intensity_db, na.rm = TRUE))
}

#' Get minimum intensity
#'
#' @param intensity A praat_intensity object from \code{\link{extract_intensity}}
#' @param time_range Optional numeric vector c(start, end) in seconds
#'
#' @return Minimum intensity in dB, or NA if undefined
#' @export
get_min_intensity <- function(intensity, time_range = NULL) {
  
  validate_intensity_object(intensity)
  
  intensity_data <- intensity$values
  
  if (!is.null(time_range)) {
    intensity_data <- intensity_data[
      intensity_data$time >= time_range[1] & intensity_data$time <= time_range[2],
    ]
  }
  
  if (nrow(intensity_data) == 0) {
    return(NA_real_)
  }
  
  return(min(intensity_data$intensity_db, na.rm = TRUE))
}

#' Get maximum intensity
#'
#' @param intensity A praat_intensity object from \code{\link{extract_intensity}}
#' @param time_range Optional numeric vector c(start, end) in seconds
#'
#' @return Maximum intensity in dB, or NA if undefined
#' @export
get_max_intensity <- function(intensity, time_range = NULL) {
  
  validate_intensity_object(intensity)
  
  intensity_data <- intensity$values
  
  if (!is.null(time_range)) {
    intensity_data <- intensity_data[
      intensity_data$time >= time_range[1] & intensity_data$time <= time_range[2],
    ]
  }
  
  if (nrow(intensity_data) == 0) {
    return(NA_real_)
  }
  
  return(max(intensity_data$intensity_db, na.rm = TRUE))
}

#' Get standard deviation of intensity
#'
#' @param intensity A praat_intensity object from \code{\link{extract_intensity}}
#' @param time_range Optional numeric vector c(start, end) in seconds
#'
#' @return Standard deviation of intensity in dB, or NA if undefined
#' @export
get_sd_intensity <- function(intensity, time_range = NULL) {
  
  validate_intensity_object(intensity)
  
  intensity_data <- intensity$values
  
  if (!is.null(time_range)) {
    intensity_data <- intensity_data[
      intensity_data$time >= time_range[1] & intensity_data$time <= time_range[2],
    ]
  }
  
  if (nrow(intensity_data) == 0) {
    return(NA_real_)
  }
  
  return(sd(intensity_data$intensity_db, na.rm = TRUE))
}
