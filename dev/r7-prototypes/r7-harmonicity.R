#' @title Praat Harmonicity Object (R7/S7)
#' @description
#' S7 class representing a Praat Harmonicity object (Harmonics-to-Noise Ratio).
#' Wraps a Praat C++ Harmonicity object with automatic memory management.
#'
#' @details
#' A Harmonicity object represents the degree of acoustic periodicity (HNR)
#' in a sound over time, measured in decibels. Higher values indicate more
#' harmonic (periodic) structure, while lower values indicate more noise.
#'
#' ## Creating Harmonicity Objects
#'
#' Harmonicity objects are typically created from Sound objects:
#' - `to_harmonicity_ac(sound, ...)` - Autocorrelation method (recommended)
#' - `to_harmonicity_cc(sound, ...)` - Cross-correlation method
#'
#' ## Querying
#'
#' Query methods return HNR values:
#' - `get_value_at_time(hnr, time)` - HNR at specific time
#' - `get_mean(hnr, from, to)` - Mean HNR
#' - `get_minimum(hnr, from, to)` - Minimum HNR
#' - `get_maximum(hnr, from, to)` - Maximum HNR
#' - `get_standard_deviation(hnr, from, to)` - SD of HNR
#' - `get_time_of_minimum(hnr, from, to)` - When HNR is lowest
#' - `get_time_of_maximum(hnr, from, to)` - When HNR is highest
#'
#' ## Export
#'
#' Export methods convert to R data structures:
#' - `as.data.frame(hnr)` - Data frame with time and HNR columns
#' - `as.matrix(hnr)` - Matrix with 2 rows: time and HNR
#'
#' @section Praat Equivalent:
#' This class wraps Praat's Harmonicity object, created via:
#' - "To Harmonicity (ac)..." - Autocorrelation method
#' - "To Harmonicity (cc)..." - Cross-correlation method
#'
#' @examples
#' \dontrun{
#' # From Sound object (R7)
#' sound <- Sound_S7(path = "recording.wav")
#' hnr <- to_harmonicity_ac(sound, time_step = 0.01, min_pitch = 75)
#'
#' # Query values
#' mean_hnr <- get_mean(hnr)
#' hnr_at_1s <- get_value_at_time(hnr, 1.0)
#' min_hnr <- get_minimum(hnr)
#'
#' # Export to R
#' df <- as.data.frame(hnr)
#' plot(df$time, df$hnr_db, type = "l", xlab = "Time (s)", ylab = "HNR (dB)")
#' 
#' # S3 methods work automatically
#' print(hnr)
#' summary(hnr)
#' }
#'
#' @import S7
#' @export
Harmonicity_S7 <- S7::new_class(
  name = "Harmonicity",
  package = "speaker",
  parent = PraatObject_S7,
  properties = list(
    # Inherits ptr from PraatObject_S7
  ),
  validator = function(self) {
    if (is.null(self@ptr)) {
      "Harmonicity objects should be created from Sound objects using to_harmonicity_ac() or to_harmonicity_cc()"
    }
  },
  constructor = function(ptr) {
    if (is.null(ptr)) {
      stop("Harmonicity objects should be created from Sound objects using to_harmonicity_ac() or to_harmonicity_cc()")
    }
    S7::new_object(
      S7::S7_class(),
      ptr = ptr
    )
  }
)

# ============================================================================
# Query Methods
# ============================================================================

#' @title Get HNR value at specific time
#' @description Get harmonicity (HNR) value at a specific time point
#' @param object Harmonicity object
#' @param time Time in seconds
#' @param interpolation Interpolation method: "nearest", "linear", "cubic", "sinc70", "sinc700"
#' @return HNR in dB (or NA if undefined)
#' @export
S7::method(get_value_at_time, Harmonicity_S7) <- function(object, 
                                                           time, 
                                                           interpolation = "cubic") {
  interpolation_code <- switch(interpolation,
    "nearest" = 0,
    "linear" = 1,
    "cubic" = 2,
    "sinc70" = 3,
    "sinc700" = 4,
    2  # default to cubic
  )
  .harmonicity_get_value_at_time(object@ptr, time, interpolation_code)
}

#' @title Get mean HNR
#' @description Get mean harmonicity over a time range
#' @param object Harmonicity object
#' @param from_time Start time (0 = start of object)
#' @param to_time End time (0 = end of object)
#' @return Mean HNR in dB
#' @export
S7::method(get_mean, Harmonicity_S7) <- function(object, 
                                                  from_time = 0, 
                                                  to_time = 0) {
  .harmonicity_get_mean(object@ptr, from_time, to_time)
}

#' @title Get minimum HNR
#' @description Get minimum harmonicity over a time range
#' @param object Harmonicity object
#' @param from_time Start time (0 = start of object)
#' @param to_time End time (0 = end of object)
#' @param interpolation Interpolation method: "parabolic" (recommended) or "none"
#' @return Minimum HNR in dB
#' @export
S7::method(get_minimum, Harmonicity_S7) <- function(object,
                                                     from_time = 0, 
                                                     to_time = 0, 
                                                     interpolation = "parabolic") {
  interpolation_code <- if (interpolation == "parabolic") 2 else 0
  .harmonicity_get_minimum(object@ptr, from_time, to_time, interpolation_code)
}

#' @title Get maximum HNR
#' @description Get maximum harmonicity over a time range
#' @param object Harmonicity object
#' @param from_time Start time (0 = start of object)
#' @param to_time End time (0 = end of object)
#' @param interpolation Interpolation method: "parabolic" (recommended) or "none"
#' @return Maximum HNR in dB
#' @export
S7::method(get_maximum, Harmonicity_S7) <- function(object,
                                                     from_time = 0, 
                                                     to_time = 0, 
                                                     interpolation = "parabolic") {
  interpolation_code <- if (interpolation == "parabolic") 2 else 0
  .harmonicity_get_maximum(object@ptr, from_time, to_time, interpolation_code)
}

#' @title Get standard deviation of HNR
#' @description Get standard deviation of harmonicity over a time range
#' @param object Harmonicity object
#' @param from_time Start time (0 = start of object)
#' @param to_time End time (0 = end of object)
#' @return Standard deviation of HNR in dB
#' @export
S7::method(get_standard_deviation, Harmonicity_S7) <- function(object,
                                                                from_time = 0, 
                                                                to_time = 0) {
  .harmonicity_get_standard_deviation(object@ptr, from_time, to_time)
}

#' @title Get time of minimum HNR
#' @description Get time where harmonicity is minimum
#' @param object Harmonicity object
#' @param from_time Start time (0 = start of object)
#' @param to_time End time (0 = end of object)
#' @param interpolation Interpolation method: "parabolic" (recommended) or "none"
#' @return Time in seconds where HNR is minimum
#' @export
S7::method(get_time_of_minimum, Harmonicity_S7) <- function(object,
                                                             from_time = 0, 
                                                             to_time = 0, 
                                                             interpolation = "parabolic") {
  interpolation_code <- if (interpolation == "parabolic") 2 else 0
  .harmonicity_get_time_of_minimum(object@ptr, from_time, to_time, interpolation_code)
}

#' @title Get time of maximum HNR
#' @description Get time where harmonicity is maximum
#' @param object Harmonicity object
#' @param from_time Start time (0 = start of object)
#' @param to_time End time (0 = end of object)
#' @param interpolation Interpolation method: "parabolic" (recommended) or "none"
#' @return Time in seconds where HNR is maximum
#' @export
S7::method(get_time_of_maximum, Harmonicity_S7) <- function(object,
                                                             from_time = 0, 
                                                             to_time = 0, 
                                                             interpolation = "parabolic") {
  interpolation_code <- if (interpolation == "parabolic") 2 else 0
  .harmonicity_get_time_of_maximum(object@ptr, from_time, to_time, interpolation_code)
}

#' @title Get number of frames
#' @description Get number of analysis frames in the harmonicity object
#' @param object Harmonicity object
#' @return Integer number of frames
#' @export
S7::method(get_number_of_frames, Harmonicity_S7) <- function(object) {
  .harmonicity_get_number_of_frames(object@ptr)
}

#' @title Get time from frame
#' @description Get time corresponding to a frame number
#' @param object Harmonicity object
#' @param frame_number Frame number (1-indexed)
#' @return Time in seconds
#' @export
S7::method(get_time_from_frame, Harmonicity_S7) <- function(object, frame_number) {
  .harmonicity_get_time_from_frame(object@ptr, frame_number)
}

#' @title Get frame from time
#' @description Get frame number corresponding to a time
#' @param object Harmonicity object
#' @param time Time in seconds
#' @return Frame number (may be fractional)
#' @export
S7::method(get_frame_from_time, Harmonicity_S7) <- function(object, time) {
  .harmonicity_get_frame_from_time(object@ptr, time)
}

# ============================================================================
# Export Methods
# ============================================================================

#' @title Convert Harmonicity to data frame
#' @description Export harmonicity values as a data frame
#' @param x Harmonicity object
#' @param ... Additional arguments (unused)
#' @return Data frame with columns: time, hnr_db
#' @export
S7::method(as.data.frame, Harmonicity_S7) <- function(x, ...) {
  .harmonicity_as_data_frame(x@ptr)
}

#' @title Convert Harmonicity to matrix
#' @description Export harmonicity values as a matrix
#' @param x Harmonicity object
#' @param ... Additional arguments (unused)
#' @return Matrix with 2 rows: time and HNR
#' @export
S7::method(as.matrix, Harmonicity_S7) <- function(x, ...) {
  .harmonicity_as_matrix(x@ptr)
}

# ============================================================================
# S3 Generic Methods (Automatically work with S7!)
# ============================================================================

#' @title Print Harmonicity object
#' @description Print method for Harmonicity objects
#' @param x Harmonicity object
#' @param ... Additional arguments (unused)
#' @return The object x, invisibly
#' @export
S7::method(print, Harmonicity_S7) <- function(x, ...) {
  cat("<Praat Harmonicity object>\n")
  
  # Get statistics
  mean_hnr <- tryCatch(get_mean(x), error = function(e) NA)
  min_hnr <- tryCatch(get_minimum(x), error = function(e) NA)
  max_hnr <- tryCatch(get_maximum(x), error = function(e) NA)
  sd_hnr <- tryCatch(get_standard_deviation(x), error = function(e) NA)
  n_frames <- tryCatch(get_number_of_frames(x), error = function(e) NA)
  
  # Get time range
  time_start <- if (!is.na(n_frames) && n_frames > 0) {
    tryCatch(get_time_from_frame(x, 1), error = function(e) NA)
  } else NA
  
  time_end <- if (!is.na(n_frames) && n_frames > 0) {
    tryCatch(get_time_from_frame(x, n_frames), error = function(e) NA)
  } else NA
  
  # Print info
  if (!is.na(n_frames)) {
    cat("Frames:", n_frames, "\n")
  }
  
  if (!is.na(time_start) && !is.na(time_end)) {
    cat("Time range:", sprintf("%.3f", time_start), "-", 
        sprintf("%.3f", time_end), "s\n")
  }
  
  cat("\nHarmonicity (HNR) statistics:\n")
  if (!is.na(mean_hnr)) {
    cat("  Mean:  ", sprintf("%.2f", mean_hnr), "dB\n")
  }
  if (!is.na(sd_hnr)) {
    cat("  SD:    ", sprintf("%.2f", sd_hnr), "dB\n")
  }
  if (!is.na(min_hnr)) {
    cat("  Min:   ", sprintf("%.2f", min_hnr), "dB\n")
  }
  if (!is.na(max_hnr)) {
    cat("  Max:   ", sprintf("%.2f", max_hnr), "dB\n")
  }
  
  invisible(x)
}

#' @title Summary of Harmonicity object
#' @description Summary method for Harmonicity objects
#' @param object Harmonicity object
#' @param ... Additional arguments (unused)
#' @return Data frame with HNR statistics
#' @export
S7::method(summary, Harmonicity_S7) <- function(object, ...) {
  stats <- data.frame(
    mean_hnr = get_mean(object),
    sd_hnr = get_standard_deviation(object),
    min_hnr = get_minimum(object),
    max_hnr = get_maximum(object),
    n_frames = get_number_of_frames(object)
  )
  
  class(stats) <- c("summary.Harmonicity", "data.frame")
  stats
}

#' @title Plot Harmonicity object
#' @description Plot harmonicity contour
#' @param x Harmonicity object
#' @param ... Additional arguments passed to plot()
#' @return NULL (invisibly)
#' @export
S7::method(plot, Harmonicity_S7) <- function(x, ...) {
  df <- as.data.frame(x)
  
  # Default plot
  plot(df$time, df$hnr_db, 
       type = "l",
       xlab = "Time (s)",
       ylab = "HNR (dB)",
       main = "Harmonicity (Harmonics-to-Noise Ratio)",
       ...)
  
  # Add horizontal line at mean
  mean_hnr <- get_mean(x)
  abline(h = mean_hnr, col = "red", lty = 2)
  
  invisible(NULL)
}
