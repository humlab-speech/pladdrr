# sound.R - Legacy S3 interface (DEPRECATED - use R6 Sound class)
#
# All S3 functions have been replaced by the R6 Sound class.
# Use Sound$new(), Sound$from_values(), etc. instead.

#' Create a sound object from numeric values (DEPRECATED)
#'
#' **DEPRECATED:** This S3 function is deprecated. Use the R6 interface instead:
#' \code{Sound$from_values(values, sampling_rate)}
#'
#' @param values Numeric vector of amplitude values
#' @inheritParams pladdrr_shared_params sampling_rate
#' @param start_time Start time in seconds (default: 0.0)
#'
#' @return Sound R6 object
#'
#' @examples
#' # Old S3 approach (DEPRECATED, shown for reference)
#' sound <- create_sound(c(0.1, 0.2), sampling_rate = 1000)
#'
#' # New R6 approach (RECOMMENDED)
#' sound2 <- Sound$from_values(c(0.1, 0.2), sampling_rate = 1000)
#'
#' @export
create_sound <- function(values, sampling_rate = 44100, start_time = 0.0) {
  .Deprecated(
    "Sound$from_values()",
    package = "pladdrr",
    msg = paste(
      "create_sound() is deprecated and will be removed in v6.0.0.",
      "Use Sound$from_values(values, sampling_rate) instead.",
      "The R6 interface provides better performance and more features."
    )
  )
  
  Sound$from_values(values, sampling_rate, start_time)
}

#' Read sound from audio file (DEPRECATED)
#'
#' **DEPRECATED:** This S3 function is deprecated. Use the R6 interface instead:
#' \code{Sound$new(file_path)}
#'
#' @param file_path Path to audio file (WAV/AIFF/FLAC/MP3 via Praat, others via
#'  av fallback)
#' @param channel Channel to read (0 = left, 1 = right) - ignored in R6
#'
#' @return Sound R6 object
#'
#' @examples
#' tmp <- tempfile(fileext = ".wav")
#' Sound$create_tone(frequency = 440, duration = 0.2)$save(tmp)
#'
#' # Old S3 approach (DEPRECATED)
#' sound <- read_sound(tmp)
#'
#' # New R6 approach (RECOMMENDED)
#' sound <- Sound$new(tmp)
#' unlink(tmp)
#'
#' @export
read_sound <- function(file_path, channel = 0) {
  .Deprecated(
    "Sound$new()",
    package = "pladdrr",
    msg = paste(
      "read_sound() is deprecated and will be removed in v6.0.0.",
      "Use Sound$new(file_path) instead.",
      "For channel extraction, use sound$extract_channel(channel)."
    )
  )
  
  sound <- Sound$new(file_path)
  
  # If specific channel requested and multi-channel
  if (channel > 0 && sound$get_number_of_channels() > 1) {
    sound <- sound$extract_channel(channel + 1)  # R6 uses 1-based indexing
  }
  
  sound
}

#' Get duration of sound object (DEPRECATED)
#'
#' **DEPRECATED:** Use \code{sound$get_duration()} instead.
#'
#' @inheritParams pladdrr_shared_sound_r6 sound
#' @return Duration in seconds
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate =
#'  16000)
#' suppressWarnings(get_duration(sound))
#' @export
get_duration <- function(sound) {
  .Deprecated("sound$get_duration()", package = "pladdrr")
  sound$get_duration()
}

#' Get sampling rate of sound object (DEPRECATED)
#'
#' **DEPRECATED:** Use \code{sound$get_sampling_frequency()} instead.
#'
#' @inheritParams pladdrr_shared_sound_r6 sound
#' @return Sampling rate in Hz
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate =
#'  16000)
#' get_sampling_rate(sound)
#' @export
get_sampling_rate <- function(sound) {
  .Deprecated("sound$get_sampling_frequency()", package = "pladdrr")
  sound$get_sampling_frequency()
}

#' Get number of channels in sound object (DEPRECATED)
#'
#' **DEPRECATED:** Use \code{sound$get_number_of_channels()} instead.
#'
#' @inheritParams pladdrr_shared_sound_r6 sound
#' @return Number of channels
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate =
#'  16000)
#' suppressWarnings(get_n_channels(sound))
#' @export
get_n_channels <- function(sound) {
  .Deprecated("sound$get_number_of_channels()", package = "pladdrr")
  sound$get_number_of_channels()
}

#' Get number of samples in sound object (DEPRECATED)
#'
#' **DEPRECATED:** Use \code{sound$get_number_of_samples()} instead.
#'
#' @inheritParams pladdrr_shared_sound_r6 sound
#' @return Number of samples
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate =
#'  16000)
#' suppressWarnings(get_n_samples(sound))
#' @export
get_n_samples <- function(sound) {
  .Deprecated("sound$get_number_of_samples()", package = "pladdrr")
  sound$get_number_of_samples()
}
