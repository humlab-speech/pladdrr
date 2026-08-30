# longsound-wrapper.R
# Function wrapper for Praat LongSound objects (streaming large audio files)

#' LongSound
#'
#' Represents a Praat LongSound object: an audio file that stays on disk
#' instead of loading into memory.
#'
#' A regular Sound loads the whole recording into RAM, which can exceed
#' available memory on a multi-hour field recording, or just crowd out
#' everything else you're working on. LongSound opens the file, reads its
#' header, and streams samples on demand, so you can check duration,
#' inspect amplitude, or pull out short clips from a file far bigger than
#' memory allows. Use \code{extract_part()} whenever you need actual
#' waveform data for pitch, formant, or intensity analysis: it reads just
#' the requested time window and hands back a normal Sound.
#'
#' @section Usage:
#' \preformatted{
#' ls <- LongSound$open("recording.wav")
#' part <- ls$extract_part(10, 15)   # 5 seconds as a Sound
#' }
#'
#' @section Query methods:
#' \itemize{
#'   \item \code{get_duration()} - total duration in seconds
#'   \item \code{get_start_time()}, \code{get_end_time()} - time domain in seconds
#'   \item \code{get_sample_rate()} - sampling frequency in Hz
#'   \item \code{get_number_of_samples()} - number of samples per channel
#'   \item \code{get_number_of_channels()} - number of channels (1 = mono, 2 = stereo)
#'   \item \code{get_file_path()} - path to the underlying audio file
#'   \item \code{get_dx()} - sampling period in seconds (\code{1 / get_sample_rate()})
#'   \item \code{get_x1()} - time of the first sample
#' }
#'
#' @section Time/sample conversion:
#' \itemize{
#'   \item \code{get_time_from_sample(sample)} - time, in seconds, of a given sample index
#'   \item \code{get_sample_from_time(time)} - index of the sample nearest a given time
#' }
#'
#' @section Streaming:
#' \itemize{
#'   \item \code{extract_part(from, to, preserve_times = FALSE)} - read a
#'     time range from disk and return it as a Sound. Set
#'     \code{preserve_times = TRUE} to keep the extracted Sound's time
#'     domain aligned with the original file instead of starting it at time 0.
#'   \item \code{have_window(from, to)} - TRUE if that time range is already
#'     held in the internal read buffer, so the next \code{extract_part()}
#'     over it will be fast
#'   \item \code{get_window_extrema(from, to, channel = 1)} - minimum and
#'     maximum amplitude in a time range, without building a Sound
#' }
#'
#' @section Save:
#' \itemize{
#'   \item \code{save_part(from, to, path, format = "wav")} - write a time
#'     range straight to an audio file, without holding the whole clip in
#'     memory. \code{format} is one of \code{"wav"}, \code{"aiff"},
#'     \code{"aifc"}, \code{"flac"}, or \code{"wav24"} (24-bit WAV).
#'   \item \code{save_channel(channel, path, format = "wav")} - write a
#'     single channel to an audio file
#' }
#'
#' @section Utility:
#' \itemize{
#'   \item \code{is_valid()} - FALSE if the underlying file handle was closed
#'     or garbage collected
#'   \item \code{print()} - summary of file path, duration, sample rate, and
#'     channel count
#' }
#'
#' Streaming through a very large file repeatedly touches the same disk
#' regions; see \code{\link{longsound_get_buffer_size_pref_seconds}} to tune
#' how much Praat keeps cached between reads.
#'
#' @param .xptr Not for direct use. External pointer to the underlying C++
#'   LongSound object; set internally when a method returns a new LongSound.
#' @return A LongSound object.
#'
#' @examples
#' # LongSound streams from disk, so the example writes a small WAV file first
#' tmp <- tempfile(fileext = ".wav")
#' Sound$create_tone(frequency = 150, duration = 1.0)$save(tmp)
#'
#' ls <- LongSound$open(tmp)
#' print(ls)
#'
#' cat("Duration:", ls$get_duration(), "s\n")
#' cat("Sample rate:", ls$get_sample_rate(), "Hz\n")
#'
#' # Extract first 0.5 seconds as a Sound
#' sound <- ls$extract_part(0, 0.5)
#'
#' # Convert a sample index to a time and back
#' t <- ls$get_time_from_sample(100)
#' ls$get_sample_from_time(t)
#'
#' unlink(tmp)
#'
#' @seealso \code{\link{Sound}}
#' @name LongSound
NULL

# ============================================================================
# Shared Method Dispatch Table
# ============================================================================

.longsound_methods <- new.env(hash = TRUE, parent = emptyenv())

# Query - duration and timing
.longsound_methods$get_duration <- function(.self) .self$.cpp$get_duration()
.longsound_methods$get_start_time <- function(.self) .self$.cpp$get_start_time()
.longsound_methods$get_end_time <- function(.self) .self$.cpp$get_end_time()

# Query - audio properties
.longsound_methods$get_sample_rate <- function(.self) .self$.cpp$get_sample_rate()
.longsound_methods$get_number_of_channels <- function(.self) .self$.cpp$get_number_of_channels()
.longsound_methods$get_number_of_samples <- function(.self) .self$.cpp$get_number_of_samples()
.longsound_methods$get_dx <- function(.self) .self$.cpp$get_dx()
.longsound_methods$get_x1 <- function(.self) .self$.cpp$get_x1()
.longsound_methods$get_file_path <- function(.self) .self$.cpp$get_file_path()

# Query - time/sample conversion
.longsound_methods$get_time_from_sample <- function(.self, sample) {
  .self$.cpp$get_time_from_sample(as.integer(sample))
}
.longsound_methods$get_sample_from_time <- function(.self, time) {
  .self$.cpp$get_sample_from_time(as.numeric(time))
}

# Streaming - extract_part
.longsound_methods$extract_part <- function(.self, tmin, tmax, preserve_times = FALSE) {
  result_ptr <- .self$.cpp$extract_part_ptr(
    as.numeric(tmin), as.numeric(tmax), preserve_times
  )
  Sound(.xptr = result_ptr)
}

# Streaming - have_window
.longsound_methods$have_window <- function(.self, tmin, tmax) {
  .self$.cpp$have_window(as.numeric(tmin), as.numeric(tmax))
}

# Streaming - get_window_extrema
.longsound_methods$get_window_extrema <- function(.self, tmin, tmax, channel = 1L) {
  .self$.cpp$get_window_extrema(as.numeric(tmin), as.numeric(tmax), as.integer(channel))
}

# Save methods
.longsound_methods$save_part <- function(.self, tmin, tmax, path, format = "wav") {
  type_map <- c(wav = 1L, aiff = 2L, aifc = 3L, flac = 6L, wav24 = 1L)
  bits_map <- c(wav = 16L, aiff = 16L, aifc = 16L, flac = 16L, wav24 = 24L)
  if (!format %in% names(type_map)) {
    stop("Unknown format: ", format, ". Use wav, aiff, aifc, flac, or wav24")
  }
  .self$.cpp$save_part(type_map[[format]], as.numeric(tmin), as.numeric(tmax),
                       path, bits_map[[format]])
  invisible(.self)
}

.longsound_methods$save_channel <- function(.self, channel, path, format = "wav") {
  type_map <- c(wav = 1L, aiff = 2L, aifc = 3L, flac = 6L)
  if (!format %in% names(type_map)) {
    stop("Unknown format: ", format, ". Use wav, aiff, aifc, or flac")
  }
  .self$.cpp$save_channel(type_map[[format]], as.integer(channel), path)
  invisible(.self)
}

# Utility
.longsound_methods$is_valid <- function(.self) .self$.cpp$is_valid()
.longsound_methods$get_ptr <- function(.self) .self$.xptr
.longsound_methods$get_xptr <- function(.self) .self$.xptr

# Display
.longsound_methods$print <- function(.self) {
  cat("<Praat LongSound>\n")
  if (.self$.cpp$is_valid()) {
    cat("  File:", .self$.cpp$get_file_path(), "\n")
    cat("  Duration:", sprintf("%.3f", .self$.cpp$get_duration()), "seconds\n")
    cat("  Sample rate:", .self$.cpp$get_sample_rate(), "Hz\n")
    cat("  Channels:", .self$.cpp$get_number_of_channels(), "\n")
    cat("  Samples:", .self$.cpp$get_number_of_samples(), "\n")
  } else {
    cat("  [Invalid or deleted object]\n")
  }
  invisible(.self)
}

lockEnvironment(.longsound_methods, bindings = TRUE)

# ============================================================================
# S3 Dispatch
# ============================================================================

#' @method $ LongSound
#' @export
`$.LongSound` <- function(x, name) {
  val <- .subset2(x, name)
  if (!is.null(val)) return(val)
  method <- .longsound_methods[[name]]
  if (is.null(method)) return(NULL)
  function(...) method(x, ...)
}

# ============================================================================
# Constructor
# ============================================================================

#' @export
LongSound <- function(.xptr = NULL) {
  if (is.null(.xptr)) {
    stop("Use LongSound$open() to create a LongSound from a file")
  }

  mod <- get_module("longsound_module")
  cpp_obj <- mod$RLongSound$new(.xptr)

  structure(list(
    .cpp = cpp_obj,
    .xptr = .xptr
  ), class = c("LongSound", "PraatObject"))
}

# ============================================================================
# Static Methods (backward compatibility: LongSound$open)
# ============================================================================

#' Open a LongSound from file
#' @param path Path to audio file (WAV, AIFF, FLAC, MP3, etc.)
#' @return LongSound object
#' @export
#' @examples
#' wav <- tempfile(fileext = ".wav")
#' Sound$create_tone(frequency = 220, duration = 1, sampling_rate = 16000)$save(wav)
#'
#' ls <- longsound_open(wav)
#' print(ls)
#'
#' # Extract portion
#' sound <- ls$extract_part(0, 0.5)
longsound_open <- function(path) {
  if (!file.exists(path)) {
    stop("File not found: ", path)
  }
  ptr <- .longsound_open(normalizePath(path, mustWork = TRUE))
  LongSound(.xptr = ptr)
}

#' Get the LongSound streaming buffer size preference
#'
#' Controls how much audio Praat keeps resident in memory while streaming
#' from a LongSound. This is a global setting: it applies to every LongSound
#' opened after it is changed, not to one specific object. The default is
#' 60 seconds. Raise it to reduce disk re-reads when repeatedly querying
#' nearby windows of a very large file; lower it to shrink the package's
#' memory footprint when working with many LongSound objects at once.
#'
#' @return Buffer size in seconds.
#' @export
#' @examples
#' longsound_get_buffer_size_pref_seconds()
longsound_get_buffer_size_pref_seconds <- function() {
  .longsound_get_buffer_size_pref_seconds()
}

#' Set the LongSound streaming buffer size preference
#'
#' @param seconds Buffer size in seconds. See
#'   \code{\link{longsound_get_buffer_size_pref_seconds}} for what this
#'   controls.
#' @return Invisibly, the previous buffer size in seconds.
#' @export
#' @examples
#' old <- longsound_set_buffer_size_pref_seconds(120)
#' longsound_get_buffer_size_pref_seconds()
#' longsound_set_buffer_size_pref_seconds(old)
longsound_set_buffer_size_pref_seconds <- function(seconds) {
  old <- .longsound_get_buffer_size_pref_seconds()
  .longsound_set_buffer_size_pref_seconds(as.numeric(seconds))
  invisible(old)
}

.longsound_static_env <- new.env(parent = emptyenv())
.longsound_static_env$open <- longsound_open
.longsound_static_env$new <- LongSound
.longsound_static_env$get_buffer_size_pref_seconds <- longsound_get_buffer_size_pref_seconds
.longsound_static_env$set_buffer_size_pref_seconds <- longsound_set_buffer_size_pref_seconds

#' @exportS3Method "$" longsound_constructor
`$.longsound_constructor` <- function(x, name) {
  .longsound_static_env[[name]]
}

class(LongSound) <- c("longsound_constructor", "function")

# ============================================================================
# S3 Methods
# ============================================================================

