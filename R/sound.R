# sound.R - Core sound object creation and manipulation functions
#
# This file implements the primary sound object interface for the speaker package.
# Sound objects represent audio data with associated metadata.

#' Create a sound object from numeric values
#'
#' Creates a praat_sound object from a numeric vector of amplitude values.
#' This is the primary constructor for sound objects in R.
#'
#' @param values Numeric vector of amplitude values (typically in range [-1, 1])
#' @param sampling_rate Sampling rate in Hz (default: 44100)
#' @param start_time Start time in seconds (default: 0.0)
#'
#' @return A praat_sound object (S3 class) containing:
#'   \describe{
#'     \item{values}{Numeric vector of amplitude values}
#'     \item{time}{Numeric vector of time points}
#'     \item{sampling_rate}{Sampling rate in Hz}
#'     \item{n_samples}{Number of samples}
#'     \item{n_channels}{Number of channels (1 for mono)}
#'     \item{channel}{Channel index (0 for left/mono)}
#'     \item{duration}{Duration in seconds}
#'     \item{start_time}{Start time in seconds}
#'     \item{end_time}{End time in seconds}
#'   }
#'
#' @examples
#' # Create a simple sound from values
#' sound <- create_sound(c(0.1, 0.2, -0.1, -0.2), sampling_rate = 1000)
#'
#' # Create a sine wave manually
#' t <- seq(0, 1, length.out = 44100)
#' sine <- create_sound(sin(2 * pi * 440 * t), sampling_rate = 44100)
#'
#' @export
create_sound <- function(values, sampling_rate = 44100, start_time = 0.0) {
  # Validate inputs
  if (!is.numeric(values)) {
    stop("'values' must be a numeric vector", call. = FALSE)
  }
  validate_positive(sampling_rate, "sampling_rate")
  validate_non_negative(start_time, "start_time")

  # Use C++ implementation
  sound <- create_sound_from_values(values, sampling_rate, start_time)

  return(sound)
}

#' Read sound from WAV file
#'
#' Reads a WAV audio file and creates a praat_sound object. Supports mono
#' and stereo files. For stereo files, specify which channel to read
#' (default is left channel).
#'
#' @param file_path Path to WAV file
#' @param channel Channel to read for stereo files: 0 for left, 1 for right
#'   (default: 0). Ignored for mono files.
#'
#' @return A praat_sound object containing the audio data
#'
#' @examples
#' \dontrun{
#' # Read a mono WAV file
#' sound <- read_sound("recording.wav")
#'
#' # Read right channel from stereo file
#' sound_right <- read_sound("stereo.wav", channel = 1)
#' }
#'
#' @export
read_sound <- function(file_path, channel = 0) {
  # Validate file path
  validate_string(file_path, "file_path")
  validate_file_exists(file_path, "file_path")
  validate_file_extension(file_path, c("wav", "WAV"), "file_path")

  # Validate channel parameter
  if (!is.numeric(channel) || length(channel) != 1) {
    stop("'channel' must be a single numeric value (0 or 1)", call. = FALSE)
  }
  if (!(channel %in% c(0, 1))) {
    stop("'channel' must be 0 (left) or 1 (right)", call. = FALSE)
  }

  # Read WAV file using tuneR (since Praat integration is not yet complete)
  if (!requireNamespace("tuneR", quietly = TRUE)) {
    stop("Package 'tuneR' is required to read WAV files. ",
         "Install it with: install.packages('tuneR')", call. = FALSE)
  }

  # Read the file
  wave <- tuneR::readWave(file_path)

  # Extract the appropriate channel
  if (wave@stereo) {
    # Stereo file
    if (channel == 0) {
      values <- wave@left
    } else {
      values <- wave@right
    }
    n_channels <- 2
  } else {
    # Mono file
    values <- wave@left
    n_channels <- 1
  }

  # Normalize to [-1, 1] range
  bit_depth <- wave@bit
  max_val <- 2^(bit_depth - 1) - 1
  values <- as.numeric(values) / max_val

  # Get sampling rate
  sampling_rate <- wave@samp.rate

  # Create sound object
  n_samples <- length(values)
  duration <- n_samples / sampling_rate
  time <- seq(0, duration - 1/sampling_rate, length.out = n_samples)

  sound <- list(
    values = values,
    time = time,
    sampling_rate = sampling_rate,
    n_samples = n_samples,
    n_channels = n_channels,
    channel = channel,
    duration = duration,
    start_time = 0.0,
    end_time = duration
  )

  class(sound) <- c("praat_sound", "list")

  return(sound)
}

#' Get duration of sound object
#'
#' Extracts the duration (in seconds) of a praat_sound object.
#'
#' @param sound A praat_sound object
#'
#' @return Duration in seconds (numeric scalar)
#'
#' @examples
#' sound <- create_sound(rep(0, 44100), sampling_rate = 44100)
#' get_duration(sound)  # Returns 1.0
#'
#' @export
get_duration <- function(sound) {
  validate_sound_object(sound, "sound")
  return(sound$duration)
}

#' Get sampling rate of sound object
#'
#' Extracts the sampling rate (in Hz) of a praat_sound object.
#'
#' @param sound A praat_sound object
#'
#' @return Sampling rate in Hz (numeric scalar)
#'
#' @examples
#' sound <- create_sound(c(0.1, 0.2), sampling_rate = 22050)
#' get_sampling_rate(sound)  # Returns 22050
#'
#' @export
get_sampling_rate <- function(sound) {
  validate_sound_object(sound, "sound")
  return(sound$sampling_rate)
}

#' Get number of channels in sound object
#'
#' Extracts the number of channels (1 for mono, 2 for stereo) of a praat_sound object.
#'
#' @param sound A praat_sound object
#'
#' @return Number of channels (integer scalar)
#'
#' @examples
#' sound <- create_sound(c(0.1, 0.2), sampling_rate = 44100)
#' get_n_channels(sound)  # Returns 1 (mono)
#'
#' @export
get_n_channels <- function(sound) {
  validate_sound_object(sound, "sound")
  return(as.integer(sound$n_channels))
}

#' Get number of samples in sound object
#'
#' Extracts the number of samples in a praat_sound object.
#'
#' @param sound A praat_sound object
#'
#' @return Number of samples (integer scalar)
#'
#' @examples
#' sound <- create_sound(rep(0, 1000), sampling_rate = 44100)
#' get_n_samples(sound)  # Returns 1000
#'
#' @export
get_n_samples <- function(sound) {
  validate_sound_object(sound, "sound")
  return(as.integer(sound$n_samples))
}
