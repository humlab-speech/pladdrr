# s3-methods.R - S3 methods for praat_sound objects
#
# This file implements S3 generic methods (print, summary, as.data.frame) for
# praat_sound objects to provide user-friendly display and conversion.

#' Print method for praat_sound objects
#'
#' Provides a concise, informative display of a praat_sound object.
#'
#' @param x A praat_sound object
#' @inheritParams pladdrr_shared_params ...
#'
#' @return The object x, invisibly
#'
#' @examples
#' sound <- create_sound(rep(0, 1000), sampling_rate = 44100)
#' print(sound)
#'
#' @export
#' @param ... Additional arguments passed to the underlying function or ignored.
print.praat_sound <- function(x, ...) {
  cat("Praat Sound Object\n")
  cat("==================\n")
  cat(sprintf("Duration:      %.6f seconds\n", x$duration))
  cat(sprintf("Sampling rate: %d Hz\n", as.integer(x$sampling_rate)))
  cat(sprintf("Samples:       %d\n", x$n_samples))
  cat(sprintf("Channels:      %d (%s)\n", x$n_channels,
              if (x$n_channels == 1) "mono" else "stereo"))
  cat(
    sprintf("Time range:    [%.6f, %.6f] seconds\n", x$start_time, x$end_time))

  # Show amplitude range
  amplitude_range <- range(x$values)
  cat(
    sprintf("Amplitude:     [%.6f, %.6f]\n", amplitude_range[1],
      amplitude_range[2]))

  invisible(x)
}

#' Summary method for praat_sound objects
#'
#' Provides a statistical summary of a praat_sound object, including amplitude
#' statistics and metadata.
#'
#' @param object A praat_sound object
#' @inheritParams pladdrr_shared_params ...
#'
#' @return The object, invisibly
#'
#' @examples
#' sound <- list(
#'   duration = 0.5, sampling_rate = 8000, n_samples = 4000, n_channels = 1,
#'   start_time = 0, end_time = 0.5,
#'   values = sin(2 * pi * 150 * seq(0, 0.5, length.out = 4000))
#' )
#' class(sound) <- "praat_sound"
#' summary(sound)
#'
#' @export
#' @param ... Additional arguments passed to the underlying function or ignored.
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
#' Converts a praat_sound object to a data frame with time and amplitude
#'  columns.
#' This is useful for plotting and further analysis in R.
#'
#' @param x A praat_sound object
#' @inheritParams pladdrr_shared_params ...
#'
#' @return A data.table (inherits from data.frame) with two columns:
#'   \describe{
#'     \item{time}{Time in seconds}
#'     \item{amplitude}{Amplitude values}
#'   }
#'
#' @examples
#' values <- sin(2 * pi * 220 * seq(0, 0.1, length.out = 1000))
#' snd <- create_sound_from_values(values, sampling_rate = 10000)
#' df <- as.data.frame(snd)
#' head(df)
#'
#' @export
#' @param ... Additional arguments passed to the underlying function or ignored.
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
#' @inheritParams pladdrr_shared_params row.names
#' @inheritParams pladdrr_shared_params optional
#' @inheritParams pladdrr_shared_params ...
#' @return A data.table (inherits from data.frame) with time, channel, and value
#'  columns
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 0.1, sampling_rate =
#'  8000)
#' df <- as.data.frame(sound)
#' head(df)
#' @export
#' @param ... Additional arguments passed to the underlying function or ignored.
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
#' @inheritParams pladdrr_shared_params ...
#'
#' @return The object x, invisibly
#'
#' @examples
#' x <- data.frame(time = c(0.1, 0.2, 0.3), frequency = c(120, 125, NA))
#' class(x) <- c("praat_pitch", "data.frame")
#' print(x)
#'
#' @export
#' @param ... Additional arguments passed to the underlying function or ignored.
print.praat_pitch <- function(x, ...) {
  cat("Praat Pitch Object\n")
  cat("==================\n")
  cat(sprintf("Frames:        %d\n", nrow(x)))

  # Count voiced/unvoiced
  voiced <- sum(!is.na(x$frequency) & x$frequency > 0)
  unvoiced <- nrow(x) - voiced
  cat(sprintf("Voiced:        %d (%.1f%%)\n", voiced, 100 * voiced / nrow(x)))
  cat(
    sprintf("Unvoiced:      %d (%.1f%%)\n", unvoiced, 100 * unvoiced / nrow(x)))

  # Time range
  cat(
    sprintf("Time range:    [%.3f, %.3f] seconds\n", min(x$time), max(x$time)))

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
#' @inheritParams pladdrr_shared_params ...
#'
#' @return The object, invisibly
#'
#' @examples
#' x <- data.frame(time = c(0.1, 0.2, 0.3), frequency = c(120, 125, NA))
#' class(x) <- c("praat_pitch", "data.frame")
#' summary(x)
#'
#' @export
#' @param ... Additional arguments passed to the underlying function or ignored.
summary.praat_pitch <- function(object, ...) {
  cat("Praat Pitch Object - Summary\n")
  cat("============================\n\n")

  cat("Frame Information:\n")
  cat(sprintf("  Total frames:  %d\n", nrow(object)))

  # Voiced/unvoiced
  voiced <- sum(!is.na(object$frequency) & object$frequency > 0)
  unvoiced <- nrow(object) - voiced
  cat(
    sprintf("  Voiced:        %d (%.1f%%)\n", voiced,
      100 * voiced / nrow(object)))
  cat(
    sprintf("  Unvoiced:      %d (%.1f%%)\n", unvoiced,
      100 * unvoiced / nrow(object)))

  # Time range
  cat(sprintf("\nTime Range:\n"))
  cat(sprintf("  Start:         %.3f seconds\n", min(object$time)))
  cat(sprintf("  End:           %.3f seconds\n", max(object$time)))
  cat(
    sprintf("  Duration:      %.3f seconds\n",
      max(object$time) - min(object$time)))

  # Pitch statistics (for voiced frames only)
  if (voiced > 0) {
    voiced_freqs <- object$frequency[!is.na(
      object$frequency) & object$frequency > 0]
    cat("\nPitch Statistics (voiced frames, Hz):\n")
    cat(sprintf("  Mean:          %.2f\n", mean(voiced_freqs)))
    cat(sprintf("  Median:        %.2f\n", median(voiced_freqs)))
    cat(sprintf("  Min:           %.2f\n", min(voiced_freqs)))
    cat(sprintf("  Max:           %.2f\n", max(voiced_freqs)))
    cat(
      sprintf("  Range:         %.2f\n", max(voiced_freqs) - min(voiced_freqs)))
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
#' @return \code{x}, invisibly.
#' @examples
#' x <- list(
#'   n_frames = 2, n_formants = 1, time_step = 0.01,
#'   max_formant = 5000, window_length = 0.025,
#'   values = data.frame(
#'     time = c(0.1, 0.2), formant_number = c(1, 1),
#'     frequency = c(500, 520), bandwidth = c(80, 82)
#'   )
#' )
#' class(x) <- "praat_formant"
#' print(x)
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
#' @return \code{object}, invisibly.
#' @examples
#' x <- list(
#'   n_frames = 2, n_formants = 1, time_step = 0.01,
#'   max_formant = 5000, window_length = 0.025,
#'   values = data.frame(
#'     time = c(0.1, 0.2), formant_number = c(1, 1),
#'     frequency = c(500, 520), bandwidth = c(80, 82)
#'   )
#' )
#' class(x) <- "praat_formant"
#' summary(x)
#' @export
summary.praat_formant <- function(object, ...) {
  cat("Praat Formant Object\n")
  cat("====================\n")
  cat(sprintf("Number of frames: %d\n", object$n_frames))
  cat(sprintf("Number of formants tracked: %d\n", object$n_formants))
  cat(sprintf("Time step: %.6f s\n", object$time_step))
  cat(sprintf("Maximum formant: %.0f Hz\n", object$max_formant))
  
  # Calculate statistics for each formant
  for (f in seq_len(object$n_formants)) {
    formant_data <- object$values[object$values$formant_number == f, ]
    valid_freqs <- formant_data$frequency[!is.na(formant_data$frequency)]
    
    cat(sprintf("\nFormant F%d:\n", f))
    if (length(valid_freqs) > 0) {
      cat(sprintf("  Valid frames: %d (%.1f%%)\n",
                  length(valid_freqs),
                  100 * length(valid_freqs) / nrow(formant_data)))
      cat(sprintf("  Mean: %.1f Hz\n", mean(valid_freqs)))
      cat(sprintf("  SD: %.1f Hz\n", sd(valid_freqs)))
      cat(
        sprintf("  Range: %.1f - %.1f Hz\n", min(valid_freqs),
          max(valid_freqs)))
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
#' @return The values data.table (inherits from data.frame) from the formant
#'  object
#' @examples
#' x <- list(values = data.frame(
#'   time = c(0.1, 0.2), formant_number = c(1, 1),
#'   frequency = c(500, 520), bandwidth = c(80, 82)
#' ))
#' class(x) <- "praat_formant"
#' as.data.frame(x)
#' @export
as.data.frame.praat_formant <- function(x, row.names = NULL, optional = FALSE,
  ...) {
  x$values
}

# ==============================================================================
# Intensity Object Methods
# ==============================================================================

#' Print method for praat_intensity objects
#'
#' @param x A praat_intensity object
#' @param ... Additional arguments (unused)
#' @return \code{x}, invisibly.
#' @examples
#' x <- list(
#'   n_frames = 2, time_step = 0.01, minimum_pitch = 100,
#'   window_length = 0.032, subtract_mean = TRUE,
#'   values = data.frame(time = c(0.1, 0.2), intensity_db = c(65.2, 66.1))
#' )
#' class(x) <- "praat_intensity"
#' print(x)
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
#' @return \code{object}, invisibly.
#' @examples
#' x <- list(
#'   n_frames = 2, time_step = 0.01, minimum_pitch = 100,
#'   values = data.frame(time = c(0.1, 0.2), intensity_db = c(65.2, 66.1))
#' )
#' class(x) <- "praat_intensity"
#' summary(x)
#' @export
summary.praat_intensity <- function(object, ...) {
  cat("Praat Intensity Object\n")
  cat("======================\n")
  cat(sprintf("Number of frames: %d\n", object$n_frames))
  cat(sprintf("Time step: %.6f s\n", object$time_step))
  cat(sprintf("Minimum pitch: %.0f Hz\n", object$minimum_pitch))
  
  valid_intensities <- object$values$intensity_db[!is.na(
    object$values$intensity_db)]
  
  if (length(valid_intensities) > 0) {
    cat(sprintf("\nIntensity statistics:\n"))
    cat(sprintf("  Valid frames: %d (%.1f%%)\n",
                length(valid_intensities),
                100 * length(valid_intensities) / nrow(object$values)))
    cat(sprintf("  Mean: %.2f dB\n", mean(valid_intensities)))
    cat(sprintf("  SD: %.2f dB\n", sd(valid_intensities)))
    cat(
      sprintf("  Range: %.2f - %.2f dB\n", min(valid_intensities),
        max(valid_intensities)))
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
#' @return The values data.table (inherits from data.frame) from the intensity
#'  object
#' @examples
#' x <- list(values = data.frame(time = c(0.1, 0.2), intensity_db = c(65.2,
#'  66.1)))
#' class(x) <- "praat_intensity"
#' as.data.frame(x)
#' @export
as.data.frame.praat_intensity <- function(x, row.names = NULL,
  optional = FALSE, ...) {
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
#' @inheritParams pladdrr_shared_params row.names
#' @inheritParams pladdrr_shared_params optional
#' @param ... Additional arguments passed to `$as_data_frame()`
#'   (e.g. `max_formants`)
#' @return A data.table (inherits from data.frame) in long format, one row per
#'   (frame, formant number): columns `time`, `formant` (1-based formant
#'   number), `frequency` (Hz), `bandwidth` (Hz). Matches
#'   `as.data.frame.FormantPath()`.
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate =
#'  16000)
#' formant <- sound$to_formant_burg()
#' df <- as.data.frame(formant)
#' head(df)
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
#' @inheritParams pladdrr_shared_params row.names
#' @inheritParams pladdrr_shared_params optional
#' @inheritParams pladdrr_shared_params ...
#' @return A data.table (inherits from data.frame) with time and intensity
#'  columns
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate =
#'  16000)
#' intensity <- sound$to_intensity()
#' df <- as.data.frame(intensity)
#' head(df)
#' @export
#' @param ... Additional arguments passed to the underlying function or ignored.
as.data.frame.Intensity <- function(x, row.names = NULL, optional = FALSE,
  ...) {
  x$as_data_frame()
}

#' Convert R6 Pitch to data frame
#' 
#' S3 method for converting R6 Pitch objects to data frames.
#' Delegates to the R6 `$as_data_frame()` method.
#' 
#' @param x A Pitch R6 object
#' @inheritParams pladdrr_shared_params row.names
#' @inheritParams pladdrr_shared_params optional
#' @inheritParams pladdrr_shared_params ...
#' @return A data.table (inherits from data.frame) with pitch measurements
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 0.3, sampling_rate =
#'  16000)
#' pitch <- sound$to_pitch()
#' df <- as.data.frame(pitch)
#' head(df)
#' @export
#' @param ... Additional arguments passed to the underlying function or ignored.
as.data.frame.Pitch <- function(x, row.names = NULL, optional = FALSE, ...) {
  x$as_data_frame()
}

#' @describeIn as.data.frame.Pitch Convert PointProcess to data.frame
#' @param x A PointProcess R6 object
#' @export
as.data.frame.PointProcess <- function(x, row.names = NULL, optional = FALSE,
  ...) {
  x$as_data_frame()
}

#' @describeIn as.data.frame.Pitch Convert TextGrid to data.frame
#' @param x A TextGrid R6 object
#' @export
as.data.frame.TextGrid <- function(x, row.names = NULL, optional = FALSE, ...) {
  x$as_data_frame()
}

#' @describeIn as.data.frame.Pitch Convert MFCC to data.frame
#' @param x An MFCC R6 object
#' @export
as.data.frame.MFCC <- function(x, row.names = NULL, optional = FALSE, ...) {
  x$as_data_frame()
}

#' @describeIn as.data.frame.Pitch Convert LFCC to data.frame
#' @param x An LFCC R6 object
#' @export
as.data.frame.LFCC <- function(x, row.names = NULL, optional = FALSE, ...) {
  x$as_data_frame()
}
# ============================================================================
# Consolidated S3 methods (print.* / as.data.frame.*)
# Moved here from per-class wrapper files so identical bodies share one file
# (cross-file duplicate-body lint). Each delegates to the R6 object's
# $print() / $as_data_frame() method.
# ============================================================================
#' @export
print.AmplitudeTier <- function(x, ...) {
  x$print()
  invisible(x)
}
#' @exportS3Method print BarkSpectrogram
print.BarkSpectrogram <- function(x, ...) {
  x$print()
  invisible(x)
}
#' @export
print.Cepstrum <- function(x, ...) {
  x$print()
  invisible(x)
}
#' @export
print.Cochleagram <- function(x, ...) {
  x$print()
  invisible(x)
}
#' @export
print.Discriminant <- function(x, ...) {
  x$print()
  invisible(x)
}
#' @export
print.DTW <- function(x, ...) {
  x$print()
  invisible(x)
}
#' @export
print.DurationTier <- function(x, ...) {
  x$print()
  invisible(x)
}
#' @export
print.Electroglottogram <- function(x, ...) {
  x$print()
  invisible(x)
}
#' @export
print.Excitation <- function(x, ...) {
  x$print()
  invisible(x)
}
#' @export
print.Formant <- function(x, ...) {
  x$print()
  invisible(x)
}
#' @export
print.FormantGrid <- function(x, ...) {
  x$print()
  invisible(x)
}
#' @export
print.FormantModeler <- function(x, ...) {
  x$print()
  invisible(x)
}
#' @export
print.FormantPath <- function(x, ...) {
  x$print()
  invisible(x)
}
#' @export
print.FormantTier <- function(x, ...) {
  x$print()
  invisible(x)
}
#' @export
as.data.frame.FormantTier <- function(x, ...) {
  x$as_data_frame()
}
#' @export
print.Harmonicity <- function(x, ...) {
  x$print(...)
  invisible(x)
}
#' @export
as.data.frame.Harmonicity <- function(x, ...) {
  x$as_data_frame()
}
#' @export
print.Intensity <- function(x, ...) {
  x$print(...)
  invisible(x)
}
#' @export
print.IntensityTier <- function(x, ...) {
  x$print()
  invisible(x)
}
#' @export
print.KlattGrid <- function(x, ...) {
  x$print()
  invisible(x)
}
#' @export
print.LongSound <- function(x, ...) {
  x$print()
  invisible(x)
}
#' @export
print.LPC <- function(x, ...) {
  x$print()
  invisible(x)
}
#' @export
print.Ltas <- function(x, ...) {
  x$print()
  invisible(x)
}
#' @export
as.data.frame.Ltas <- function(x, ...) {
  x$as_data_frame()
}
#' @export
print.Manipulation <- function(x, ...) {
  x$print()
  invisible(x)
}
#' @export
print.Matrix <- function(x, ...) {
  x$print()
  invisible(x)
}
#' @exportS3Method print MelSpectrogram
print.MelSpectrogram <- function(x, ...) {
  x$print()
  invisible(x)
}
#' @export
print.MFCC <- function(x, ...) {
  x$print()
  invisible(x)
}
#' @export
print.LFCC <- function(x, ...) {
  x$print()
  invisible(x)
}
#' @export
print.PCA <- function(x, ...) {
  x$print()
  invisible(x)
}
#' @export
print.Pitch <- function(x, ...) {
  x$print()
  invisible(x)
}
#' @export
print.PitchTier <- function(x, ...) {
  x$print()
  invisible(x)
}
#' @export
as.data.frame.PitchTier <- function(x, ...) {
  x$as_data_frame()
}
#' @export
print.PointProcess <- function(x, ...) {
  x$print()
  invisible(x)
}
#' @export
print.Polygon <- function(x, ...) {
  x$print()
  invisible(x)
}
#' @export
as.data.frame.Polygon <- function(x, row.names = NULL, optional = FALSE, ...) {
  x$as_data_frame()
}
#' @export
print.PowerCepstrum <- function(x, ...) {
  x$print()
  invisible(x)
}
#' @export
print.PowerCepstrogram <- function(x, ...) {
  x$print()
  invisible(x)
}
#' @exportS3Method print Sound
print.Sound <- function(x, ...) {
  x$print()
  invisible(x)
}
#' @export
print.Spectrogram <- function(x, ...) {
  x$print()
  invisible(x)
}
#' @export
as.data.frame.Spectrogram <- function(x, ...) {
  x$as_data_frame()
}
#' @export
print.Spectrum <- function(x, ...) {
  x$print()
  invisible(x)
}
#' @export
as.data.frame.Spectrum <- function(x, ...) {
  x$as_data_frame()
}
#' @export
print.SpectrumTier <- function(x, ...) {
  x$print()
  invisible(x)
}
#' @export
as.data.frame.SpectrumTier <- function(x, ...) {
  x$as_data_frame()
}
#' @export
print.Table <- function(x, ...) {
  x$print()
  invisible(x)
}
#' @export
print.TextGrid <- function(x, ...) {
  x$print()
  invisible(x)
}
#' @export
print.VocalTract <- function(x, ...) {
  x$print()
  invisible(x)
}
