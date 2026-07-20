# sound-stats.R - Statistical functions for sound objects
#
# This file provides functions to compute basic statistics on sound amplitude values.

#' Compute mean amplitude
#'
#' Calculates the mean (average) of all amplitude values in a sound object.
#' Works with both S3 praat_sound objects and R6 Sound objects.
#'
#' @param sound A praat_sound (S3) or Sound (R6) object
#'
#' @return Mean amplitude (numeric scalar)
#'
#' @examples
#' sound <- Sound$from_values(c(-1, 0, 1), sampling_rate = 1000)
#' sound_mean(sound)  # Returns 0
#'
#' @export
sound_mean <- function(sound) {
  # Handle R6 objects
  if (inherits(sound, "Sound")) {
    mat <- sound$as_matrix()
    # For mono, get first channel; for stereo, average all channels
    values <- as.numeric(mat[1, ])
  } else {
    # Handle S3 objects
    validate_sound_object(sound, "sound")
    values <- sound$values
  }
  return(mean(values))
}

#' Compute minimum amplitude
#'
#' Finds the minimum amplitude value in a sound object.
#' Works with both S3 praat_sound objects and R6 Sound objects.
#'
#' @param sound A praat_sound (S3) or Sound (R6) object
#'
#' @return Minimum amplitude (numeric scalar)
#'
#' @examples
#' sound <- Sound$from_values(c(0.5, -0.8, 0.2), sampling_rate = 1000)
#' sound_min(sound)  # Returns -0.8
#'
#' @export
sound_min <- function(sound) {
  # Handle R6 objects
  if (inherits(sound, "Sound")) {
    mat <- sound$as_matrix()
    values <- as.numeric(mat[1, ])
  } else {
    # Handle S3 objects
    validate_sound_object(sound, "sound")
    values <- sound$values
  }
  return(min(values))
}

#' Compute maximum amplitude
#'
#' Finds the maximum amplitude value in a sound object.
#' Works with both S3 praat_sound objects and R6 Sound objects.
#'
#' @param sound A praat_sound (S3) or Sound (R6) object
#'
#' @return Maximum amplitude (numeric scalar)
#'
#' @examples
#' sound <- Sound$from_values(c(0.5, -0.8, 1.0), sampling_rate = 1000)
#' sound_max(sound)  # Returns 1.0
#'
#' @export
sound_max <- function(sound) {
  # Handle R6 objects
  if (inherits(sound, "Sound")) {
    mat <- sound$as_matrix()
    values <- as.numeric(mat[1, ])
  } else {
    # Handle S3 objects
    validate_sound_object(sound, "sound")
    values <- sound$values
  }
  return(max(values))
}

#' Compute RMS (root mean square) amplitude
#'
#' Calculates the RMS amplitude of a sound object. RMS is a measure of the
#' signal's power and is computed as sqrt(mean(x^2)).
#'
#' @param sound A praat_sound object
#'
#' @return RMS amplitude (numeric scalar)
#'
#' @details
#' For a sine wave with amplitude A, the RMS value is A/sqrt(2) ~ 0.707*A.
#' RMS is useful for comparing signal levels and measuring acoustic intensity.
#'
#' @examples
#' # RMS of a sine wave
#' sine <- generate_sine_wave(440, 1.0, amplitude = 1.0)
#' sound_rms(sine)  # Approximately 0.707
#'
#' @export
sound_rms <- function(sound) {
  # Handle R6 objects
  if (inherits(sound, "Sound")) {
    mat <- sound$as_matrix()
    values <- as.numeric(mat[1, ])
  } else {
    # Handle S3 objects
    validate_sound_object(sound, "sound")
    values <- sound$values
  }
  return(sqrt(mean(values^2)))
}

#' Compute comprehensive sound statistics
#'
#' Calculates a comprehensive set of statistics for a sound object, including
#' amplitude statistics and metadata.
#' Works with both S3 praat_sound objects and R6 Sound objects.
#'
#' @param sound A praat_sound (S3) or Sound (R6) object
#'
#' @return A named list containing:
#'   \describe{
#'     \item{mean}{Mean amplitude}
#'     \item{min}{Minimum amplitude}
#'     \item{max}{Maximum amplitude}
#'     \item{rms}{RMS amplitude}
#'     \item{duration}{Duration in seconds}
#'     \item{n_samples}{Number of samples}
#'     \item{sampling_rate}{Sampling rate in Hz}
#'   }
#'
#' @examples
#' sound <- generate_sine_wave(440, 0.5)
#' stats <- sound_statistics(sound)
#' print(stats)
#'
#' @export
sound_statistics <- function(sound) {
  # Handle R6 objects
  if (inherits(sound, "Sound")) {
    mat <- sound$as_matrix()
    values <- as.numeric(mat[1, ])
    stats <- list(
      mean = mean(values),
      min = min(values),
      max = max(values),
      rms = sqrt(mean(values^2)),
      duration = sound$get_duration(),
      n_samples = sound$get_number_of_samples(),
      sampling_rate = sound$get_sampling_frequency()
    )
  } else {
    # Handle S3 objects
    validate_sound_object(sound, "sound")
    stats <- list(
      mean = mean(sound$values),
      min = min(sound$values),
      max = max(sound$values),
      rms = sqrt(mean(sound$values^2)),
      duration = sound$duration,
      n_samples = sound$n_samples,
      sampling_rate = sound$sampling_rate
    )
  }

  return(stats)
}
