# longsound-r6.R
# Function wrapper for Praat LongSound objects (streaming large audio files)
# Converted from R6 to modules for pladdrr 2.0

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
LongSound <- function(.xptr = NULL) {
  if (is.null(.xptr)) {
    stop("Use LongSound$open() to create a LongSound from a file")
  }
  
  ptr <- .xptr
  
  # Get C++ module instance
  mod <- get_module("longsound_module")
  cpp_obj <- mod$RLongSound$new(ptr)
  
  # Create object with methods
  obj <- structure(list(
    .cpp = cpp_obj,
    .xptr = ptr,
    
    # Query methods - duration and timing
    get_duration = function() cpp_obj$get_duration(),
    get_start_time = function() cpp_obj$get_start_time(),
    get_end_time = function() cpp_obj$get_end_time(),
    
    # Query methods - audio properties
    get_sample_rate = function() cpp_obj$get_sample_rate(),
    get_number_of_channels = function() cpp_obj$get_number_of_channels(),
    get_number_of_samples = function() cpp_obj$get_number_of_samples(),
    get_file_path = function() cpp_obj$get_file_path(),
    
    # Streaming methods - extract_part
    extract_part = function(tmin, tmax, preserve_times = FALSE) {
      result_ptr <- cpp_obj$extract_part_ptr(
        as.numeric(tmin), 
        as.numeric(tmax), 
        preserve_times
      )
      Sound(.xptr = result_ptr)
    },
    
    # Streaming methods - have_window
    have_window = function(tmin, tmax) {
      cpp_obj$have_window(as.numeric(tmin), as.numeric(tmax))
    },
    
    # Streaming methods - get_window_extrema
    get_window_extrema = function(tmin, tmax, channel = 1L) {
      cpp_obj$get_window_extrema(
        as.numeric(tmin), 
        as.numeric(tmax), 
        as.integer(channel)
      )
    },
    
    # Save methods (use wrappers - involve file I/O)
    save_part = function(tmin, tmax, path, format = "wav") {
      type_map <- c(wav = 1L, aiff = 2L, aifc = 3L, flac = 6L, wav24 = 1L)
      bits_map <- c(wav = 16L, aiff = 16L, aifc = 16L, flac = 16L, wav24 = 24L)
      if (!format %in% names(type_map)) {
        stop("Unknown format: ", format, ". Use wav, aiff, aifc, flac, or wav24")
      }
      .longsound_save_part(ptr, type_map[[format]], tmin, tmax,
                          path, bits_map[[format]])
      invisible(obj)
    },
    
    save_channel = function(channel, path, format = "wav") {
      type_map <- c(wav = 1L, aiff = 2L, aifc = 3L, flac = 6L)
      if (!format %in% names(type_map)) {
        stop("Unknown format: ", format, ". Use wav, aiff, aifc, or flac")
      }
      .longsound_save_channel(ptr, type_map[[format]], as.integer(channel), path)
      invisible(obj)
    },
    
    # Utility methods
    is_valid = function() cpp_obj$is_valid(),
    get_ptr = function() ptr,
    get_xptr = function() ptr,
    
    # Print method
    print = function() {
      cat("<Praat LongSound>\n")
      if (!cpp_obj$is_valid()) {
        cat("  [Invalid or deleted object]\n")
      } else {
        cat("  File:", cpp_obj$get_file_path(), "\n")
        cat("  Duration:", sprintf("%.3f", cpp_obj$get_duration()), "seconds\n")
        cat("  Sample rate:", cpp_obj$get_sample_rate(), "Hz\n")
        cat("  Channels:", cpp_obj$get_number_of_channels(), "\n")
        cat("  Samples:", cpp_obj$get_number_of_samples(), "\n")
      }
      invisible(obj)
    }
  ), class = c("LongSound", "PraatObject"))
  
  obj
}

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

# Static method environment for LongSound
.longsound_static_env <- new.env(parent = emptyenv())
.longsound_static_env$open <- longsound_open
.longsound_static_env$new <- LongSound

# S3 method for $ on longsound_constructor
`$.longsound_constructor` <- function(x, name) {
  .longsound_static_env[[name]]
}

# Make LongSound a constructor class
class(LongSound) <- c("longsound_constructor", "function")
