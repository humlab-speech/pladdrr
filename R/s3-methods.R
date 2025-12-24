# s3-methods.R - S3 methods for praat_sound objects
#
# This file implements S3 generic methods (print, summary, as.data.frame) for
# praat_sound objects to provide user-friendly display and conversion.

#' Print method for praat_sound objects
#'
#' Provides a concise, informative display of a praat_sound object.
#'
#' @param x A praat_sound object
#' @param ... Additional arguments (currently unused)
#'
#' @return The object x, invisibly
#'
#' @examples
#' sound <- create_sound(rep(0, 1000), sampling_rate = 44100)
#' print(sound)
#'
#' @export
print.praat_sound <- function(x, ...) {
  cat("Praat Sound Object\n")
  cat("==================\n")
  cat(sprintf("Duration:      %.6f seconds\n", x$duration))
  cat(sprintf("Sampling rate: %d Hz\n", as.integer(x$sampling_rate)))
  cat(sprintf("Samples:       %d\n", x$n_samples))
  cat(sprintf("Channels:      %d (%s)\n", x$n_channels,
              if (x$n_channels == 1) "mono" else "stereo"))
  cat(sprintf("Time range:    [%.6f, %.6f] seconds\n", x$start_time, x$end_time))

  # Show amplitude range
  amplitude_range <- range(x$values)
  cat(sprintf("Amplitude:     [%.6f, %.6f]\n", amplitude_range[1], amplitude_range[2]))

  invisible(x)
}

#' Summary method for praat_sound objects
#'
#' Provides a statistical summary of a praat_sound object, including amplitude
#' statistics and metadata.
#'
#' @param object A praat_sound object
#' @param ... Additional arguments (currently unused)
#'
#' @return The object, invisibly
#'
#' @examples
#' \dontrun{
#' # DEPRECATED - generate_sine_wave now returns R6 Sound objects
#' # This S3 method is only for legacy praat_sound objects
#' sound <- generate_sine_wave(440, 0.5)
#' summary(sound)
#' }
#'
#' @export
summary.praat_sound <- function(object, ...) {
  cat("Praat Sound Object - Summary\n")
  cat("============================\n\n")

  cat("Metadata:\n")
  cat(sprintf("  Duration:      %.6f seconds\n", object$duration))
  cat(sprintf("  Sampling rate: %d Hz\n", as.integer(object$sampling_rate)))
  cat(sprintf("  Samples:       %d\n", object$n_samples))
  cat(sprintf("  Channels:      %d\n", object$n_channels))
  cat(sprintf("  Time range:    [%.6f, %.6f] seconds\n",
              object$start_time, object$end_time))

  cat("\nAmplitude Statistics:\n")
  cat(sprintf("  Mean:          %.6f\n", mean(object$values)))
  cat(sprintf("  Min:           %.6f\n", min(object$values)))
  cat(sprintf("  Max:           %.6f\n", max(object$values)))
  cat(sprintf("  RMS:           %.6f\n", sqrt(mean(object$values^2))))
  cat(sprintf("  Std Dev:       %.6f\n", sd(object$values)))

  invisible(object)
}

#' Convert praat_sound to data frame
#'
#' Converts a praat_sound object to a data frame with time and amplitude columns.
#' This is useful for plotting and further analysis in R.
#'
#' @param x A praat_sound object
#' @param ... Additional arguments (currently unused)
#'
#' @return A data frame with two columns:
#'   \describe{
#'     \item{time}{Time in seconds}
#'     \item{amplitude}{Amplitude values}
#'   }
#'
#' @examples
#' \dontrun{
#' # DEPRECATED - Use R6 interface instead:
#' sound <- Sound$new("audio.wav")
#' df <- sound$as_data_frame()
#' }
#'
#' @export
as.data.frame.praat_sound <- function(x, ...) {
  .Deprecated(
    "Sound$as_data_frame()",
    package = "pladdrr",
    msg = "as.data.frame.praat_sound() is deprecated. Use Sound$as_data_frame() instead."
  )
  
  validate_sound_object(x, "x")

  df <- data.frame(
    time = x$time,
    amplitude = x$values,
    stringsAsFactors = FALSE
  )

  return(df)
}

#' Convert R6 Sound to data frame
#' 
#' S3 method for converting R6 Sound objects to data frames.
#' Delegates to the R6 `$as_data_frame()` method.
#' 
#' @param x A Sound R6 object
#' @param row.names Ignored
#' @param optional Ignored
#' @param ... Additional arguments (ignored)
#' @return A data frame with time, channel, and value columns
#' @export
as.data.frame.Sound <- function(x, row.names = NULL, optional = FALSE, ...) {
  # R6 Sound object - delegate to R6 method
  x$as_data_frame()
}

# ============================================================================
# S3 methods for praat_pitch objects
# ============================================================================

#' Print method for praat_pitch objects
#'
#' Provides a concise display of a pitch contour.
#'
#' @param x A praat_pitch object
#' @param ... Additional arguments (currently unused)
#'
#' @return The object x, invisibly
#'
#' @export
print.praat_pitch <- function(x, ...) {
  cat("Praat Pitch Object\n")
  cat("==================\n")
  cat(sprintf("Frames:        %d\n", nrow(x)))

  # Count voiced/unvoiced
  voiced <- sum(!is.na(x$frequency) & x$frequency > 0)
  unvoiced <- nrow(x) - voiced
  cat(sprintf("Voiced:        %d (%.1f%%)\n", voiced, 100 * voiced / nrow(x)))
  cat(sprintf("Unvoiced:      %d (%.1f%%)\n", unvoiced, 100 * unvoiced / nrow(x)))

  # Time range
  cat(sprintf("Time range:    [%.3f, %.3f] seconds\n", min(x$time), max(x$time)))

  # Pitch statistics (for voiced frames only)
  if (voiced > 0) {
    voiced_freqs <- x$frequency[!is.na(x$frequency) & x$frequency > 0]
    cat("\nPitch Statistics (Hz):\n")
    cat(sprintf("  Mean:        %.1f\n", mean(voiced_freqs)))
    cat(sprintf("  Median:      %.1f\n", median(voiced_freqs)))
    cat(sprintf("  Min:         %.1f\n", min(voiced_freqs)))
    cat(sprintf("  Max:         %.1f\n", max(voiced_freqs)))
    cat(sprintf("  Std Dev:     %.1f\n", sd(voiced_freqs)))
  }

  invisible(x)
}

#' Summary method for praat_pitch objects
#'
#' Provides a detailed statistical summary of a pitch contour.
#'
#' @param object A praat_pitch object
#' @param ... Additional arguments (currently unused)
#'
#' @return The object, invisibly
#'
#' @export
summary.praat_pitch <- function(object, ...) {
  cat("Praat Pitch Object - Summary\n")
  cat("============================\n\n")

  cat("Frame Information:\n")
  cat(sprintf("  Total frames:  %d\n", nrow(object)))

  # Voiced/unvoiced
  voiced <- sum(!is.na(object$frequency) & object$frequency > 0)
  unvoiced <- nrow(object) - voiced
  cat(sprintf("  Voiced:        %d (%.1f%%)\n", voiced, 100 * voiced / nrow(object)))
  cat(sprintf("  Unvoiced:      %d (%.1f%%)\n", unvoiced, 100 * unvoiced / nrow(object)))

  # Time range
  cat(sprintf("\nTime Range:\n"))
  cat(sprintf("  Start:         %.3f seconds\n", min(object$time)))
  cat(sprintf("  End:           %.3f seconds\n", max(object$time)))
  cat(sprintf("  Duration:      %.3f seconds\n", max(object$time) - min(object$time)))

  # Pitch statistics (for voiced frames only)
  if (voiced > 0) {
    voiced_freqs <- object$frequency[!is.na(object$frequency) & object$frequency > 0]
    cat("\nPitch Statistics (voiced frames, Hz):\n")
    cat(sprintf("  Mean:          %.2f\n", mean(voiced_freqs)))
    cat(sprintf("  Median:        %.2f\n", median(voiced_freqs)))
    cat(sprintf("  Min:           %.2f\n", min(voiced_freqs)))
    cat(sprintf("  Max:           %.2f\n", max(voiced_freqs)))
    cat(sprintf("  Range:         %.2f\n", max(voiced_freqs) - min(voiced_freqs)))
    cat(sprintf("  Std Dev:       %.2f\n", sd(voiced_freqs)))
    cat(sprintf("  Quantiles:\n"))
    quants <- quantile(voiced_freqs, probs = c(0.25, 0.5, 0.75))
    cat(sprintf("    25%%:          %.2f\n", quants[1]))
    cat(sprintf("    50%%:          %.2f\n", quants[2]))
    cat(sprintf("    75%%:          %.2f\n", quants[3]))
  } else {
    cat("\nNo voiced frames detected.\n")
  }

  invisible(object)
}

# ==============================================================================
# Formant Object Methods
# ==============================================================================

#' Print method for praat_formant objects
#'
#' @param x A praat_formant object
#' @param ... Additional arguments (unused)
#' @export
print.praat_formant <- function(x, ...) {
  cat("Praat Formant Object\n")
  cat("====================\n")
  cat(sprintf("Number of frames: %d\n", x$n_frames))
  cat(sprintf("Number of formants tracked: %d\n", x$n_formants))
  cat(sprintf("Time step: %.6f s\n", x$time_step))
  cat(sprintf("Maximum formant: %.0f Hz\n", x$max_formant))
  cat(sprintf("Window length: %.4f s\n", x$window_length))
  cat("\nFirst few measurements:\n")
  print(head(x$values, 10))
  invisible(x)
}

#' Summary method for praat_formant objects
#'
#' @param object A praat_formant object
#' @param ... Additional arguments (unused)
#' @export
summary.praat_formant <- function(object, ...) {
  cat("Praat Formant Object\n")
  cat("====================\n")
  cat(sprintf("Number of frames: %d\n", object$n_frames))
  cat(sprintf("Number of formants tracked: %d\n", object$n_formants))
  cat(sprintf("Time step: %.6f s\n", object$time_step))
  cat(sprintf("Maximum formant: %.0f Hz\n", object$max_formant))
  
  # Calculate statistics for each formant
  for (f in 1:object$n_formants) {
    formant_data <- object$values[object$values$formant_number == f, ]
    valid_freqs <- formant_data$frequency[!is.na(formant_data$frequency)]
    
    cat(sprintf("\nFormant F%d:\n", f))
    if (length(valid_freqs) > 0) {
      cat(sprintf("  Valid frames: %d (%.1f%%)\n",
                  length(valid_freqs),
                  100 * length(valid_freqs) / nrow(formant_data)))
      cat(sprintf("  Mean: %.1f Hz\n", mean(valid_freqs)))
      cat(sprintf("  SD: %.1f Hz\n", sd(valid_freqs)))
      cat(sprintf("  Range: %.1f - %.1f Hz\n", min(valid_freqs), max(valid_freqs)))
    } else {
      cat("  No valid measurements\n")
    }
  }
  
  invisible(object)
}

#' Convert praat_formant to data.frame
#'
#' @param x A praat_formant object
#' @param row.names Not used
#' @param optional Not used
#' @param ... Additional arguments (unused)
#' @return The values data.frame from the formant object
#' @export
as.data.frame.praat_formant <- function(x, row.names = NULL, optional = FALSE, ...) {
  x$values
}

# ==============================================================================
# Intensity Object Methods
# ==============================================================================

#' Print method for praat_intensity objects
#'
#' @param x A praat_intensity object
#' @param ... Additional arguments (unused)
#' @export
print.praat_intensity <- function(x, ...) {
  cat("Praat Intensity Object\n")
  cat("======================\n")
  cat(sprintf("Number of frames: %d\n", x$n_frames))
  cat(sprintf("Time step: %.6f s\n", x$time_step))
  cat(sprintf("Minimum pitch: %.0f Hz\n", x$minimum_pitch))
  cat(sprintf("Window length: %.4f s\n", x$window_length))
  cat(sprintf("Mean subtracted: %s\n", ifelse(x$subtract_mean, "yes", "no")))
  cat("\nFirst few measurements:\n")
  print(head(x$values, 10))
  invisible(x)
}

#' Summary method for praat_intensity objects
#'
#' @param object A praat_intensity object
#' @param ... Additional arguments (unused)
#' @export
summary.praat_intensity <- function(object, ...) {
  cat("Praat Intensity Object\n")
  cat("======================\n")
  cat(sprintf("Number of frames: %d\n", object$n_frames))
  cat(sprintf("Time step: %.6f s\n", object$time_step))
  cat(sprintf("Minimum pitch: %.0f Hz\n", object$minimum_pitch))
  
  valid_intensities <- object$values$intensity_db[!is.na(object$values$intensity_db)]
  
  if (length(valid_intensities) > 0) {
    cat(sprintf("\nIntensity statistics:\n"))
    cat(sprintf("  Valid frames: %d (%.1f%%)\n",
                length(valid_intensities),
                100 * length(valid_intensities) / nrow(object$values)))
    cat(sprintf("  Mean: %.2f dB\n", mean(valid_intensities)))
    cat(sprintf("  SD: %.2f dB\n", sd(valid_intensities)))
    cat(sprintf("  Range: %.2f - %.2f dB\n", min(valid_intensities), max(valid_intensities)))
  } else {
    cat("\nNo valid intensity measurements\n")
  }
  
  invisible(object)
}

#' Convert praat_intensity to data.frame
#'
#' @param x A praat_intensity object
#' @param row.names Not used
#' @param optional Not used
#' @param ... Additional arguments (unused)
#' @return The values data.frame from the intensity object
#' @export
as.data.frame.praat_intensity <- function(x, row.names = NULL, optional = FALSE, ...) {
  x$values
}

# ==============================================================================
# S3 methods for R6 classes (Sound, Formant, Intensity, etc.)
# ==============================================================================

#' Convert R6 Formant to data frame
#' 
#' S3 method for converting R6 Formant objects to data frames.
#' Delegates to the R6 `$as_data_frame()` method.
#' 
#' @param x A Formant R6 object
#' @param row.names Ignored
#' @param optional Ignored
#' @param ... Additional arguments passed to `$as_data_frame()`
#' @return A data frame with formant measurements
#' @export
as.data.frame.Formant <- function(x, row.names = NULL, optional = FALSE, ...) {
  x$as_data_frame(...)
}

#' Convert R6 Intensity to data frame
#' 
#' S3 method for converting R6 Intensity objects to data frames.
#' Delegates to the R6 `$as_data_frame()` method.
#' 
#' @param x An Intensity R6 object
#' @param row.names Ignored
#' @param optional Ignored
#' @param ... Additional arguments (ignored)
#' @return A data frame with time and intensity columns
#' @export
as.data.frame.Intensity <- function(x, row.names = NULL, optional = FALSE, ...) {
  x$as_data_frame()
}

#' Convert R6 Pitch to data frame
#' 
#' S3 method for converting R6 Pitch objects to data frames.
#' Delegates to the R6 `$as_data_frame()` method.
#' 
#' @param x A Pitch R6 object
#' @param row.names Ignored
#' @param optional Ignored
#' @param ... Additional arguments (ignored)
#' @return A data frame with pitch measurements
#' @export
as.data.frame.Pitch <- function(x, row.names = NULL, optional = FALSE, ...) {
  x$as_data_frame()
}
