# longsound-wrapper.R
# Function wrapper for Praat LongSound objects (streaming large audio files)

#' @title LongSound Class
#' @description
#' Function wrapper for Praat LongSound objects representing large audio files.
#' Unlike Sound objects which load entirely into memory, LongSound streams
#' from disk, making it suitable for very long recordings.
#'
#' @details
#' A LongSound keeps the audio file open and reads portions on demand.
#' This allows working with files that would be too large to load into memory.
#' Use `extract_part()` to get a Sound object for a specific time window.
#'
#' @param .xptr External pointer to LongSound (for internal use)
#' @return LongSound object (list with methods)
#'
#' @examples
#' # LongSound streams from disk, so the example writes a small WAV file first
#' tmp <- tempfile(fileext = ".wav")
#' Sound$create_tone(frequency = 150, duration = 1.0)$save(tmp)
#'
#' ls <- LongSound$open(tmp)
#' print(ls)
#'
#' # Extract first 0.5 seconds as Sound
#' sound <- ls$extract_part(0, 0.5)
#'
#' unlink(tmp)
#'
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
.longsound_methods$get_file_path <- function(.self) .self$.cpp$get_file_path()

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
  .longsound_save_part(.self$.xptr, type_map[[format]], tmin, tmax,
                       path, bits_map[[format]])
  invisible(.self)
}

.longsound_methods$save_channel <- function(.self, channel, path, format = "wav") {
  type_map <- c(wav = 1L, aiff = 2L, aifc = 3L, flac = 6L)
  if (!format %in% names(type_map)) {
    stop("Unknown format: ", format, ". Use wav, aiff, aifc, or flac")
  }
  .longsound_save_channel(.self$.xptr, type_map[[format]], as.integer(channel), path)
  invisible(.self)
}

# Utility
.longsound_methods$is_valid <- function(.self) .self$.cpp$is_valid()
.longsound_methods$get_ptr <- function(.self) .self$.xptr
.longsound_methods$get_xptr <- function(.self) .self$.xptr

# Display
.longsound_methods$print <- function(.self) {
  cat("<Praat LongSound>\n")
  if (!.self$.cpp$is_valid()) {
    cat("  [Invalid or deleted object]\n")
  } else {
    cat("  File:", .self$.cpp$get_file_path(), "\n")
    cat("  Duration:", sprintf("%.3f", .self$.cpp$get_duration()), "seconds\n")
    cat("  Sample rate:", .self$.cpp$get_sample_rate(), "Hz\n")
    cat("  Channels:", .self$.cpp$get_number_of_channels(), "\n")
    cat("  Samples:", .self$.cpp$get_number_of_samples(), "\n")
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
#' \dontrun{
#' ls <- LongSound$open("recording.wav")
#' print(ls)
#'
#' # Extract portion
#' sound <- ls$extract_part(0, 10)
#' }
longsound_open <- function(path) {
  if (!file.exists(path)) {
    stop("File not found: ", path)
  }
  ptr <- .longsound_open(normalizePath(path, mustWork = TRUE))
  LongSound(.xptr = ptr)
}

.longsound_static_env <- new.env(parent = emptyenv())
.longsound_static_env$open <- longsound_open
.longsound_static_env$new <- LongSound

#' @exportS3Method "$" longsound_constructor
`$.longsound_constructor` <- function(x, name) {
  .longsound_static_env[[name]]
}

class(LongSound) <- c("longsound_constructor", "function")

# ============================================================================
# S3 Methods
# ============================================================================

#' @export
print.LongSound <- function(x, ...) x$print()
