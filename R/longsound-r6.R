# longsound-r6.R
# R6 class for Praat LongSound objects (streaming large audio files)

#' @title LongSound Class
#' @description
#' R6 class for Praat LongSound objects representing large audio files.
#' Unlike Sound objects which load entirely into memory, LongSound streams
#' from disk, making it suitable for very long recordings.
#'
#' @details
#' A LongSound keeps the audio file open and reads portions on demand.
#' This allows working with files that would be too large to load into memory.
#' Use `extract_part()` to get a Sound object for a specific time window.
#'
#' @examples
#' \dontrun{
#' # Open a large audio file
#' ls <- LongSound$open("recording.wav")
#' print(ls)
#'
#' # Extract first 10 seconds as Sound
#' sound <- ls$extract_part(0, 10)
#'
#' # Save a portion to a new file
#' ls$save_part(60, 120, "minute_two.wav")
#' }
#'
#' @export
LongSound <- R6::R6Class(
  "LongSound",
  inherit = PraatObject,

  public = list(
    #' @description Create LongSound from external pointer
    #' @param .xptr External pointer (for internal use)
    initialize = function(.xptr = NULL) {
      if (!is.null(.xptr)) {
        super$initialize(.xptr)
      } else {
        stop("Use LongSound$open() to create a LongSound from a file")
      }
    },

    #' @description Get total duration
    #' @return Duration in seconds
    get_duration = function() {
      private$check_valid()
      .longsound_get_duration(private$ptr)
    },

    #' @description Get start time
    #' @return Start time in seconds
    get_start_time = function() {
      private$check_valid()
      .longsound_get_start_time(private$ptr)
    },

    #' @description Get end time
    #' @return End time in seconds
    get_end_time = function() {
      private$check_valid()
      .longsound_get_end_time(private$ptr)
    },

    #' @description Get sample rate
    #' @return Sample rate in Hz
    get_sample_rate = function() {
      private$check_valid()
      .longsound_get_sample_rate(private$ptr)
    },

    #' @description Get number of channels
    #' @return Number of channels
    get_number_of_channels = function() {
      private$check_valid()
      .longsound_get_number_of_channels(private$ptr)
    },

    #' @description Get number of samples
    #' @return Number of samples
    get_number_of_samples = function() {
      private$check_valid()
      .longsound_get_number_of_samples(private$ptr)
    },

    #' @description Get source file path
    #' @return File path
    get_file_path = function() {
      private$check_valid()
      .longsound_get_file_path(private$ptr)
    },

    #' @description Extract part as Sound object
    #' @param tmin Start time in seconds
    #' @param tmax End time in seconds
    #' @param preserve_times If TRUE, keep original time domain (default FALSE)
    #' @return Sound object
    extract_part = function(tmin, tmax, preserve_times = FALSE) {
      private$check_valid()
      ptr <- .longsound_extract_part(private$ptr, tmin, tmax, preserve_times)
      Sound$new(.xptr = ptr)
    },

    #' @description Check if time window is in buffer
    #' @param tmin Start time
    #' @param tmax End time
    #' @return TRUE if window is available in buffer
    have_window = function(tmin, tmax) {
      private$check_valid()
      .longsound_have_window(private$ptr, tmin, tmax)
    },

    #' @description Get extrema in time window
    #' @param tmin Start time
    #' @param tmax End time
    #' @param channel Channel number (1-based, default 1)
    #' @return Named vector with minimum and maximum
    get_window_extrema = function(tmin, tmax, channel = 1L) {
      private$check_valid()
      .longsound_get_window_extrema(private$ptr, tmin, tmax, as.integer(channel))
    },

    #' @description Save part to audio file
    #' @param tmin Start time
    #' @param tmax End time
    #' @param path Output file path
    #' @param format Audio format: "wav" (default), "aiff", "aifc", "flac", "wav24"
    #' @return Self (invisibly)
    save_part = function(tmin, tmax, path, format = "wav") {
      private$check_valid()
      type_map <- c(wav = 1L, aiff = 2L, aifc = 3L, flac = 6L, wav24 = 1L)
      bits_map <- c(wav = 16L, aiff = 16L, aifc = 16L, flac = 16L, wav24 = 24L)
      if (!format %in% names(type_map)) {
        stop("Unknown format: ", format, ". Use wav, aiff, aifc, flac, or wav24")
      }
      .longsound_save_part(private$ptr, type_map[[format]], tmin, tmax,
                           path, bits_map[[format]])
      invisible(self)
    },

    #' @description Save single channel to audio file
    #' @param channel Channel number (1-based)
    #' @param path Output file path
    #' @param format Audio format: "wav" (default), "aiff", "aifc", "flac"
    #' @return Self (invisibly)
    save_channel = function(channel, path, format = "wav") {
      private$check_valid()
      type_map <- c(wav = 1L, aiff = 2L, aifc = 3L, flac = 6L)
      if (!format %in% names(type_map)) {
        stop("Unknown format: ", format, ". Use wav, aiff, aifc, or flac")
      }
      .longsound_save_channel(private$ptr, type_map[[format]], as.integer(channel), path)
      invisible(self)
    },

    #' @description Print method
    print = function() {
      cat("<Praat LongSound>\n")
      if (!self$is_valid()) {
        cat("  [Invalid or deleted object]\n")
      } else {
        cat("  File:", self$get_file_path(), "\n")
        cat("  Duration:", sprintf("%.3f", self$get_duration()), "seconds\n")
        cat("  Sample rate:", self$get_sample_rate(), "Hz\n")
        cat("  Channels:", self$get_number_of_channels(), "\n")
        cat("  Samples:", self$get_number_of_samples(), "\n")
      }
      invisible(self)
    }
  )
)

#' Open a LongSound from file
#' @param path Path to audio file (WAV, AIFF, FLAC, MP3, etc.)
#' @return LongSound object
#' @export
#' @examples
#' \dontrun{
#' ls <- LongSound$open("recording.wav")
#' print(ls)
#'
#' # Extract portion
#' sound <- ls$extract_part(0, 10)
#' }
LongSound$open <- function(path) {
  if (!file.exists(path)) {
    stop("File not found: ", path)
  }
  ptr <- .longsound_open(normalizePath(path, mustWork = TRUE))
  LongSound$new(.xptr = ptr)
}
