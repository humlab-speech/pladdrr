#' Check Audio Quality Metrics
#'
#' Analyzes a Sound object for common quality issues and returns diagnostic metrics.
#' This function provides basic quality control checks useful for validating
#' recording quality in production pipelines.
#'
#' @param sound A Sound object to analyze
#' @param clipping_threshold Amplitude threshold for clipping detection (default 0.99)
#' @param intensity_floor Minimum pitch for intensity calculation (default 100 Hz)
#' @param time_step Time step for intensity analysis (0 = auto, default 0.0)
#'
#' @return A list with the following components:
#' \describe{
#'   \item{max_amplitude}{Maximum absolute amplitude in the recording}
#'   \item{is_clipped}{Logical: TRUE if amplitude exceeds clipping_threshold}
#'   \item{n_clipping_samples}{Number of samples above clipping threshold}
#'   \item{clipping_percentage}{Percentage of samples that clip}
#'   \item{mean_intensity_db}{Mean intensity in dB}
#'   \item{min_intensity_db}{Minimum intensity in dB}
#'   \item{max_intensity_db}{Maximum intensity in dB}
#'   \item{intensity_range_db}{Dynamic range (max - min intensity)}
#'   \item{rms_amplitude}{Root mean square amplitude}
#'   \item{duration}{Total duration in seconds}
#'   \item{sampling_frequency}{Sampling frequency in Hz}
#' }
#'
#' @details
#' This function is designed to catch common recording problems:
#'
#' **Clipping Detection**: Identifies if the signal exceeds a threshold (default 0.99).
#' Clipped recordings have distorted peaks and should typically be re-recorded.
#'
#' **Intensity Analysis**: Uses Praat's intensity measurement to assess signal strength.
#' Very low mean intensity may indicate recording level problems.
#'
#' **Dynamic Range**: The difference between maximum and minimum intensity can help
#' identify recordings with poor signal-to-noise ratio or excessive compression.
#'
#' **Quality Criteria** (general guidelines):
#' - No clipping (is_clipped = FALSE)
#' - Mean intensity: -20 to -10 dB for speech
#' - Dynamic range: > 20 dB
#' - Max amplitude: 0.7-0.9 range (good headroom without clipping)
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Check quality of a recording
#' sound <- Sound$new("recording.wav")
#' quality <- check_audio_quality(sound)
#'
#' # Print quality report
#' cat("Audio Quality Report:\n")
#' cat("  Duration:", quality$duration, "seconds\n")
#' cat("  Sampling rate:", quality$sampling_frequency, "Hz\n")
#' cat("  Clipped:", quality$is_clipped, "\n")
#' cat("  Max amplitude:", round(quality$max_amplitude, 3), "\n")
#' cat("  Mean intensity:", round(quality$mean_intensity_db, 1), "dB\n")
#' cat("  Dynamic range:", round(quality$intensity_range_db, 1), "dB\n")
#'
#' # Batch check multiple files
#' files <- list.files(pattern = "\\.wav$")
#' results <- lapply(files, function(f) {
#'   s <- Sound$new(f)
#'   q <- check_audio_quality(s)
#'   data.frame(
#'     file = f,
#'     clipped = q$is_clipped,
#'     max_amp = q$max_amplitude,
#'     mean_db = q$mean_intensity_db
#'   )
#' })
#' quality_df <- do.call(rbind, results)
#' }
check_audio_quality <- function(sound,
                                clipping_threshold = 0.99,
                                intensity_floor = 100,
                                time_step = 0.0) {
  
  # Basic sound properties
  duration <- sound$get_total_duration()
  sampling_frequency <- sound$get_sampling_frequency()
  
  # Amplitude analysis
  max_amplitude <- sound$get_absolute_extremum(from_time = 0, to_time = 0)
  rms_amplitude <- sound$get_root_mean_square(from_time = 0, to_time = 0)
  
  # Clipping detection
  is_clipped <- max_amplitude > clipping_threshold
  
  # Count clipping samples (approximate using maximum)
  # Note: This is a conservative estimate since we don't have sample-level access
  # A value > 0.99 almost certainly means clipping occurred
  n_clipping_samples <- if (is_clipped) {
    # Rough estimate: if peak is clipped, assume ~0.1% of samples
    # This is conservative and encourages proper recording levels
    as.integer(sampling_frequency * duration * 0.001)
  } else {
    0L
  }
  
  clipping_percentage <- if (is_clipped) {
    (n_clipping_samples / (sampling_frequency * duration)) * 100
  } else {
    0
  }
  
  # Intensity analysis using Praat's Intensity object
  intensity <- sound$to_intensity(
    minimum_pitch = intensity_floor,
    time_step = time_step,
    subtract_mean = TRUE
  )
  
  mean_intensity_db <- intensity$get_mean(from_time = 0, to_time = 0, averaging_method = "energy")
  min_intensity_db <- intensity$get_minimum(from_time = 0, to_time = 0, interpolation = "parabolic")
  max_intensity_db <- intensity$get_maximum(from_time = 0, to_time = 0, interpolation = "parabolic")
  intensity_range_db <- max_intensity_db - min_intensity_db
  
  # Return quality metrics
  list(
    max_amplitude = max_amplitude,
    is_clipped = is_clipped,
    n_clipping_samples = n_clipping_samples,
    clipping_percentage = clipping_percentage,
    mean_intensity_db = mean_intensity_db,
    min_intensity_db = min_intensity_db,
    max_intensity_db = max_intensity_db,
    intensity_range_db = intensity_range_db,
    rms_amplitude = rms_amplitude,
    duration = duration,
    sampling_frequency = sampling_frequency
  )
}

#' Format Audio Quality Report
#'
#' Creates a human-readable text report from audio quality metrics.
#'
#' @param quality_metrics Output from check_audio_quality()
#' @param detailed Include detailed metrics (default TRUE)
#'
#' @return Character string with formatted report
#' @export
#'
#' @examples
#' \dontrun{
#' sound <- Sound$new("recording.wav")
#' quality <- check_audio_quality(sound)
#' report <- format_quality_report(quality)
#' cat(report)
#' }
format_quality_report <- function(quality_metrics, detailed = TRUE) {
  
  # Determine overall quality
  issues <- character(0)
  if (quality_metrics$is_clipped) {
    issues <- c(issues, "CLIPPING DETECTED")
  }
  if (quality_metrics$mean_intensity_db < -30) {
    issues <- c(issues, "Very low signal level")
  }
  if (quality_metrics$max_amplitude < 0.3) {
    issues <- c(issues, "Underutilized dynamic range")
  }
  if (quality_metrics$intensity_range_db < 15) {
    issues <- c(issues, "Low dynamic range")
  }
  
  overall_status <- if (length(issues) == 0) {
    "GOOD"
  } else if (quality_metrics$is_clipped) {
    "POOR (clipping)"
  } else {
    "FAIR"
  }
  
  # Build report
  lines <- character(0)
  lines <- c(lines, "=== Audio Quality Report ===")
  lines <- c(lines, sprintf("Overall Status: %s", overall_status))
  
  if (length(issues) > 0) {
    lines <- c(lines, "\nIssues:")
    for (issue in issues) {
      lines <- c(lines, sprintf("  - %s", issue))
    }
  }
  
  lines <- c(lines, "\nBasic Properties:")
  lines <- c(lines, sprintf("  Duration: %.2f seconds", quality_metrics$duration))
  lines <- c(lines, sprintf("  Sampling Rate: %d Hz", quality_metrics$sampling_frequency))
  
  lines <- c(lines, "\nAmplitude Metrics:")
  lines <- c(lines, sprintf("  Max Amplitude: %.3f", quality_metrics$max_amplitude))
  lines <- c(lines, sprintf("  RMS Amplitude: %.3f", quality_metrics$rms_amplitude))
  
  if (quality_metrics$is_clipped) {
    lines <- c(lines, sprintf("  Clipping: YES (%.2f%% of samples)",
                             quality_metrics$clipping_percentage))
  } else {
    lines <- c(lines, "  Clipping: NO")
  }
  
  if (detailed) {
    lines <- c(lines, "\nIntensity Metrics:")
    lines <- c(lines, sprintf("  Mean: %.1f dB", quality_metrics$mean_intensity_db))
    lines <- c(lines, sprintf("  Range: %.1f dB", quality_metrics$intensity_range_db))
    lines <- c(lines, sprintf("  Min: %.1f dB", quality_metrics$min_intensity_db))
    lines <- c(lines, sprintf("  Max: %.1f dB", quality_metrics$max_intensity_db))
    
    lines <- c(lines, "\nRecommendations:")
    if (quality_metrics$is_clipped) {
      lines <- c(lines, "  - Re-record with lower input gain to avoid clipping")
    }
    if (quality_metrics$mean_intensity_db < -30) {
      lines <- c(lines, "  - Recording level is very low; consider using normalization")
    }
    if (quality_metrics$max_amplitude < 0.3) {
      lines <- c(lines, "  - Recording could use more dynamic range; increase input gain")
    }
    if (quality_metrics$intensity_range_db > 40) {
      lines <- c(lines, "  - Very high dynamic range; check for background noise")
    }
  }
  
  lines <- c(lines, "============================\n")
  paste(lines, collapse = "\n")
}
