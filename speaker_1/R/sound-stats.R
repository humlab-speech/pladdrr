# sound-stats.R - Statistical functions for sound objects
#
# This file provides functions to compute basic statistics on sound amplitude values.

#' Compute mean amplitude
#'
#' Calculates the mean (average) of all amplitude values in a sound object.
#'
#' @param sound A praat_sound object
#'
#' @return Mean amplitude (numeric scalar)
#'
#' @examples
#' sound <- create_sound(c(-1, 0, 1), sampling_rate = 1000)
#' sound_mean(sound)  # Returns 0
#'
#' @export
sound_mean <- function(sound) {
  validate_sound_object(sound, "sound")
  return(mean(sound$values))
}

#' Compute minimum amplitude
#'
#' Finds the minimum amplitude value in a sound object.
#'
#' @param sound A praat_sound object
#'
#' @return Minimum amplitude (numeric scalar)
#'
#' @examples
#' sound <- create_sound(c(0.5, -0.8, 0.2), sampling_rate = 1000)
#' sound_min(sound)  # Returns -0.8
#'
#' @export
sound_min <- function(sound) {
  validate_sound_object(sound, "sound")
  return(min(sound$values))
}

#' Compute maximum amplitude
#'
#' Finds the maximum amplitude value in a sound object.
#'
#' @param sound A praat_sound object
#'
#' @return Maximum amplitude (numeric scalar)
#'
#' @examples
#' sound <- create_sound(c(0.5, -0.8, 1.0), sampling_rate = 1000)
#' sound_max(sound)  # Returns 1.0
#'
#' @export
sound_max <- function(sound) {
  validate_sound_object(sound, "sound")
  return(max(sound$values))
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
#' For a sine wave with amplitude A, the RMS value is A/sqrt(2) ≈ 0.707*A.
#' RMS is useful for comparing signal levels and measuring acoustic intensity.
#'
#' @examples
#' # RMS of a sine wave
#' sine <- generate_sine_wave(440, 1.0, amplitude = 1.0)
#' sound_rms(sine)  # Approximately 0.707
#'
#' @export
sound_rms <- function(sound) {
  validate_sound_object(sound, "sound")
  return(sqrt(mean(sound$values^2)))
}

#' Compute comprehensive sound statistics
#'
#' Calculates a comprehensive set of statistics for a sound object, including
#' amplitude statistics and metadata.
#'
#' @param sound A praat_sound object
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

  return(stats)
}
