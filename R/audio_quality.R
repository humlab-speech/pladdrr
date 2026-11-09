#' Check Audio Quality Metrics
#'
#' Analyzes a Sound object for common quality issues and returns diagnostic
#'  metrics.
#' This function provides basic quality control checks useful for validating
#' recording quality in production pipelines.
#'
#' @param sound A Sound object to analyze
#' @param clipping_threshold Amplitude threshold for clipping detection (default
#'  0.99)
#' @param intensity_floor Minimum pitch for intensity calculation (default 100
#'  Hz)
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
#' **Clipping Detection**: Identifies if the signal exceeds a threshold (default
#'  0.99).
#' Clipped recordings have distorted peaks and should typically be re-recorded.
#'
#' **Intensity Analysis**: Uses Praat's intensity measurement to assess signal
#'  strength.
#' Very low mean intensity may indicate recording level problems.
#'
#' **Dynamic Range**: The difference between maximum and minimum intensity can
#'  help
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
#' \donttest{
#' sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate =
#'  16000)
#' quality <- check_audio_quality(sound)
#'
#' cat("Audio Quality Report:\n")
#' cat("  Duration:", quality$duration, "seconds\n")
#' cat("  Sampling rate:", quality$sampling_frequency, "Hz\n")
#' cat("  Clipped:", quality$is_clipped, "\n")
#' cat("  Max amplitude:", round(quality$max_amplitude, 3), "\n")
#' cat("  Mean intensity:", round(quality$mean_intensity_db, 1), "dB\n")
#' cat("  Dynamic range:", round(quality$intensity_range_db, 1), "dB\n")
#' }
check_audio_quality <- function(sound,
                                clipping_threshold = 0.99,
                                intensity_floor = 100,
                                time_step = 0.0) {
  
  # Basic sound properties
  duration <- sound$get_total_duration()
  sampling_frequency <- sound$get_sampling_frequency()
  
  # Amplitude analysis + clipping
  amp <- .analyze_amplitude(sound, clipping_threshold, sampling_frequency,
    duration)
  max_amplitude <- amp$max_amplitude
  rms_amplitude <- amp$rms_amplitude
  is_clipped <- amp$is_clipped
  n_clipping_samples <- amp$n_clipping_samples
  clipping_percentage <- amp$clipping_percentage
  
  # Intensity analysis using Praat's Intensity object
  inten <- .analyze_intensity(sound, intensity_floor, time_step)
  mean_intensity_db <- inten$mean_intensity_db
  min_intensity_db <- inten$min_intensity_db
  max_intensity_db <- inten$max_intensity_db
  intensity_range_db <- inten$intensity_range_db
  
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


# Detect quality issues from metrics; returns character vector of issues.
#' List the quality problems found in the metrics `m` (clipping, very low level,
#' underused dynamic range, low intensity range) as a character vector.
#' @noRd
.assess_quality_issues <- function(m) {
  issues <- character(0)
  if (m$is_clipped) issues <- c(issues, "CLIPPING DETECTED")
  if (m$mean_intensity_db < -30) issues <- c(issues, "Very low signal level")
  if (m$max_amplitude < 0.3) issues <- c(issues, "Underutilized dynamic range")
  if (m$intensity_range_db < 15) issues <- c(issues, "Low dynamic range")
  issues
}

# Summarize issue count into an overall status label.
#' Overall verdict from the issue list: GOOD (none), POOR (clipping) or FAIR.
#' @noRd
.overall_quality_status <- function(issues, is_clipped) {
  if (length(issues) == 0) "GOOD"
  else if (is_clipped) "POOR (clipping)"
  else "FAIR"
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
#' \donttest{
#' sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate =
#'  16000)
#' quality <- check_audio_quality(sound)
#' report <- format_quality_report(quality)
#' cat(report)
#' }
format_quality_report <- function(quality_metrics, detailed = TRUE) {
  
  # Determine overall quality
  issues <- .assess_quality_issues(quality_metrics)
  overall_status <- .overall_quality_status(issues, quality_metrics$is_clipped)
  
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
  lines <- c(lines,
    sprintf("  Duration: %.2f seconds", quality_metrics$duration))
  lines <- c(lines,
    sprintf("  Sampling Rate: %d Hz", quality_metrics$sampling_frequency))
  
  lines <- c(lines, "\nAmplitude Metrics:")
  lines <- c(lines,
    sprintf("  Max Amplitude: %.3f", quality_metrics$max_amplitude))
  lines <- c(lines,
    sprintf("  RMS Amplitude: %.3f", quality_metrics$rms_amplitude))
  
  if (quality_metrics$is_clipped) {
    lines <- c(lines, sprintf("  Clipping: YES (%.2f%% of samples)",
                             quality_metrics$clipping_percentage))
  } else {
    lines <- c(lines, "  Clipping: NO")
  }
  
  if (detailed) {
    lines <- .append_detailed_report(lines, quality_metrics)
  }
  
  lines <- c(lines, "============================\n")
  paste(lines, collapse = "\n")
}


# Intensity statistics via Praat Intensity object.
#' Intensity metrics for the audio-quality report: build an Intensity (mean subtracted)
#' and return its energy-averaged mean, parabolic-interpolated minimum and maximum, and
#' their difference as the range.
#' @noRd
.analyze_intensity <- function(sound, intensity_floor, time_step) {
  intensity <- sound$to_intensity(
    minimum_pitch = intensity_floor, time_step = time_step, subtract_mean =
        TRUE)
  mean_intensity_db <- intensity$get_mean(from_time = 0, to_time = 0,
    averaging_method = "energy")
  min_intensity_db <- intensity$get_minimum(from_time = 0, to_time = 0,
    interpolation = "parabolic")
  max_intensity_db <- intensity$get_maximum(from_time = 0, to_time = 0,
    interpolation = "parabolic")
  list(mean_intensity_db = mean_intensity_db,
    min_intensity_db = min_intensity_db,
       max_intensity_db = max_intensity_db,
       intensity_range_db = max_intensity_db - min_intensity_db)
}


# Amplitude + clipping analysis.
#' Amplitude metrics for the audio-quality report: peak and RMS amplitude, and whether
#' the peak exceeds `clipping_threshold`.
#' @noRd
.analyze_amplitude <- function(sound, clipping_threshold, sampling_frequency,
  duration) {
  max_amplitude <- max(abs(sound$get_minimum(from_time = 0, to_time = 0)),
                        abs(sound$get_maximum(from_time = 0, to_time = 0)))
  rms_amplitude <- sound$get_rms(from_time = 0, to_time = 0)
  is_clipped <- max_amplitude > clipping_threshold
  n_clipping_samples <- if (
    is_clipped) as.integer(sampling_frequency * duration * 0.001) else 0L
  clipping_percentage <- if (
    is_clipped) (n_clipping_samples / (
      sampling_frequency * duration)) * 100 else 0
  list(max_amplitude = max_amplitude, rms_amplitude = rms_amplitude,
       is_clipped = is_clipped, n_clipping_samples = n_clipping_samples,
       clipping_percentage = clipping_percentage)
}


# Append the detailed intensity/recommendation section to a report.
#' Append the intensity and amplitude sections of the detailed text report to `lines`.
#' @noRd
.append_detailed_report <- function(lines, m) {
  lines <- c(lines, "\nIntensity Metrics:",
    sprintf("  Mean: %.1f dB", m$mean_intensity_db),
    sprintf("  Range: %.1f dB", m$intensity_range_db),
    sprintf("  Min: %.1f dB", m$min_intensity_db),
    sprintf("  Max: %.1f dB", m$max_intensity_db),
    "\nRecommendations:")
  if (m$is_clipped) lines <- c(lines,
    "  - Re-record with lower input gain to avoid clipping")
  if (m$mean_intensity_db < -30) lines <- c(lines,
    "  - Recording level is very low; consider using normalization")
  if (m$max_amplitude < 0.3) lines <- c(lines,
    "  - Recording could use more dynamic range; increase input gain")
  if (m$intensity_range_db > 40) lines <- c(lines,
    "  - Very high dynamic range; check for background noise")
  lines
}
