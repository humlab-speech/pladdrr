# sound-generate.R - Functions for generating synthetic sounds
#
# This file provides functions to generate test signals and synthetic sounds
# such as sine waves and noise.

#' Generate a sine wave
#'
#' Creates a praat_sound object containing a pure sine wave at a specified
#  frequency.
#' Useful for testing and creating reference signals.
#'
#' @param frequency Frequency in Hz (must be positive)
#' @param duration Duration in seconds (must be positive)
#' @inheritParams pladdrr_shared_params sampling_rate
#' @param amplitude Peak amplitude (default: 1.0, must be positive)
#'
#' @return A praat_sound object containing the sine wave
#'
#' @details
#' The generated sine wave follows the formula: \code{amplitude * sin(2 * pi *
#  frequency * t)}
#' where t is time. The wave starts at phase 0 (value 0 at t=0).
#'
#' @examples
#' # Generate A4 note (440 Hz) for 1 second
#' sine_a4 <- generate_sine_wave(440, 1.0)
#'
#' # Generate lower amplitude sine at 1000 Hz
#' sine_quiet <- generate_sine_wave(1000, 0.5, amplitude = 0.3)
#'
#' @export
generate_sine_wave <- function(frequency, duration,
                               sampling_rate = 44100,
                               amplitude = 1.0) {
  # Validate parameters
  validate_positive(frequency, "frequency")
  validate_positive(duration, "duration")
  validate_positive(sampling_rate, "sampling_rate")
  validate_positive(amplitude, "amplitude")

  # Generate time vector
  n_samples <- round(duration * sampling_rate)
  t <- seq(0, duration - 1/sampling_rate, length.out = n_samples)

  # Generate sine wave: amplitude * sin(2 * pi * frequency * t)
  values <- amplitude * sin(2 * pi * frequency * t)

  # Create sound object
  sound <- Sound$from_values(values, sampling_rate, start_time = 0.0)

  return(sound)
}

#' Generate white noise
#'
#' Creates a praat_sound object containing white noise (random values from
#' a normal distribution). Optionally specify a seed for reproducible noise.
#'
#' @param duration Duration in seconds (must be positive)
#' @inheritParams pladdrr_shared_params sampling_rate
#' @param amplitude Amplitude scaling factor (default: 1.0, must be positive).
#'   Controls the standard deviation of the noise.
#' @param seed Optional random seed for reproducible noise generation. If NULL
#'   (default), noise will be different each time.
#'
#' @return A praat_sound object containing white noise
#'
#' @details
#' White noise is generated using \code{rnorm()} with mean 0 and standard
#' deviation controlled by the amplitude parameter. For reproducible results,
#' specify a seed value.
#'
#' @examples
#' # Generate 1 second of random noise
#' noise <- generate_noise(1.0)
#'
#' # Generate reproducible noise
#' noise1 <- generate_noise(0.5, seed = 42)
#' noise2 <- generate_noise(0.5, seed = 42)
#' identical(noise1$values, noise2$values)  # TRUE
#'
#' # Generate quieter noise
#' quiet_noise <- generate_noise(1.0, amplitude = 0.1)
#'
#' @export
generate_noise <- function(duration, sampling_rate = 44100,
                           amplitude = 1.0, seed = NULL) {
  # Validate parameters
  validate_positive(duration, "duration")
  validate_positive(sampling_rate, "sampling_rate")
  validate_positive(amplitude, "amplitude")

  # Set seed if provided
  if (!is.null(seed)) {
    if (!is.numeric(seed) || length(seed) != 1) {
      stop("'seed' must be a single numeric value or NULL", call. = FALSE)
    }
    set.seed(seed)
  }

  # Generate noise
  n_samples <- round(duration * sampling_rate)
  values <- rnorm(n_samples, mean = 0, sd = amplitude)

  # Create sound object
  sound <- Sound$from_values(values, sampling_rate, start_time = 0.0)

  return(sound)
}
