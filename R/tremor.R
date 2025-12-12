#' Tremor Analysis Implementation
#'
#' @description
#' Compute vocal tremor measures following the protocol by Brückl (2012).
#' Extracts 18 measures of vocal tremor from sustained vowel phonations.
#'
#' @name tremor
NULL

#' @title Analyze Vocal Tremor
#'
#' @description
#' Analyzes vocal tremor from a sustained vowel recording, extracting 18 measures
#' of frequency and amplitude modulation.
#'
#' @param sound Sound object or path to audio file containing sustained vowel /a/
#' @param analysis_time_step Numeric. Time step for pitch analysis (default: 0.015 s)
#' @param min_pitch Numeric. Minimum pitch in Hz (default: 60)
#' @param max_pitch Numeric. Maximum pitch in Hz (default: 350)
#' @param silence_threshold Numeric. Silence threshold (default: 0.03)
#' @param voicing_threshold Numeric. Voicing threshold (default: 0.3)
#' @param octave_cost Numeric. Octave cost (default: 0.01)
#' @param octave_jump_cost Numeric. Octave jump cost (default: 0.35)
#' @param voiced_unvoiced_cost Numeric. Voiced/unvoiced cost (default: 0.14)
#' @param amplitude_method Integer. Amplitude extraction: 1=RMS per period, 2=envelope (default: 2)
#' @param min_tremor_freq Numeric. Minimum tremor frequency in Hz (default: 1.5)
#' @param max_tremor_freq Numeric. Maximum tremor frequency in Hz (default: 15)
#' @param contour_magnitude_threshold Numeric. Contour magnitude threshold (default: 0.01)
#' @param tremor_cyclicality_threshold Numeric. Tremor cyclicality threshold (default: 0.15)
#' @param freq_tremor_octave_cost Numeric. Frequency tremor octave cost (default: 0.01)
#' @param amp_tremor_octave_cost Numeric. Amplitude tremor octave cost (default: 0.01)
#' @param nan_as_zero Logical. Output indeterminate values as 0 (default: TRUE)
#' @param verbose Logical. Print progress messages (default: TRUE)
#'
#' @return List of class "tremor_result" containing:
#'   \item{FCoM}{Frequency contour magnitude (0-1)}
#'   \item{FTrC}{Frequency tremor cyclicality (0-1)}
#'   \item{FMoN}{Number of frequency modulations above thresholds}
#'   \item{FTrF}{Frequency tremor frequency (Hz)}
#'   \item{FTrI}{Frequency tremor intensity index (%)}
#'   \item{FTrP}{Frequency tremor power index}
#'   \item{FTrCIP}{Frequency tremor cyclicality intensity product (%)}
#'   \item{FTrPS}{Frequency tremor product sum}
#'   \item{FCoHNR}{Frequency contour harmonicity-to-noise ratio (dB)}
#'   \item{ACoM}{Amplitude contour magnitude (0-1)}
#'   \item{ATrC}{Amplitude tremor cyclicality (0-1)}
#'   \item{AMoN}{Number of amplitude modulations above thresholds}
#'   \item{ATrF}{Amplitude tremor frequency (Hz)}
#'   \item{ATrI}{Amplitude tremor intensity index (%)}
#'   \item{ATrP}{Amplitude tremor power index}
#'   \item{ATrCIP}{Amplitude tremor cyclicality intensity product (%)}
#'   \item{ATrPS}{Amplitude tremor product sum}
#'   \item{ACoHNR}{Amplitude contour harmonicity-to-noise ratio (dB)}
#'
#' @details
#' The tremor analysis uses autocorrelation-based methods to detect periodic
#' modulations in both frequency (F0) and amplitude contours within the 1.5-15 Hz
#' range characteristic of vocal tremor.
#'
#' **Key measures:**
#' - **Tremor frequency (TrF)**: Dominant modulation frequency in Hz
#' - **Tremor intensity (TrI)**: Percentage of power in tremor frequency
#' - **Tremor cyclicality (TrC)**: Periodicity measure (0-1, higher = more periodic)
#' - **Contour HNR (CoHNR)**: Harmonicity-to-noise ratio of the contour
#'
#' @references
#' Brückl, M. (2012). Vocal Tremor Measurement Based on Autocorrelation of Contours.
#' \emph{Interspeech '12}.
#'
#' Brückl, M., Ghio, A., & Viallet, F. (2015). Measurement of Tremor in the Voices
#' of Speakers with Parkinson's Disease. \emph{ICNLSP 2015}.
#'
#' @examples
#' \dontrun{
#' # Analyze tremor from sustained vowel
#' result <- analyze_tremor("sustained_a.wav")
#' print(result)
#'
#' # Access specific measures
#' cat("Frequency tremor:", result$FTrF, "Hz\n")
#' cat("Amplitude tremor:", result$ATrF, "Hz\n")
#' cat("Tremor intensity:", result$FTrI, "%\n")
#'
#' # Using Sound object
#' sound <- Sound$new("vowel.wav")
#' result <- analyze_tremor(sound, min_pitch = 75, max_pitch = 300)
#' }
#'
#' @export
analyze_tremor <- function(sound,
                          analysis_time_step = 0.015,
                          min_pitch = 60,
                          max_pitch = 350,
                          silence_threshold = 0.03,
                          voicing_threshold = 0.3,
                          octave_cost = 0.01,
                          octave_jump_cost = 0.35,
                          voiced_unvoiced_cost = 0.14,
                          amplitude_method = 2,
                          min_tremor_freq = 1.5,
                          max_tremor_freq = 15,
                          contour_magnitude_threshold = 0.01,
                          tremor_cyclicality_threshold = 0.15,
                          freq_tremor_octave_cost = 0.01,
                          amp_tremor_octave_cost = 0.01,
                          nan_as_zero = TRUE,
                          verbose = TRUE) {

  # Load sound if path provided
  if (is.character(sound)) {
    if (verbose) cat("Loading sound from:", sound, "\n")
    sound <- Sound$new(sound)
  }

  duration <- sound$get_duration()
  if (verbose) cat(sprintf("Duration: %.2f s\n", duration))

  # Analyze frequency tremor
  if (verbose) cat("\n=== Analyzing frequency tremor ===\n")
  ftrem_results <- .analyze_frequency_tremor(
    sound = sound,
    time_step = analysis_time_step,
    min_pitch = min_pitch,
    max_pitch = max_pitch,
    min_tremor_freq = min_tremor_freq,
    max_tremor_freq = max_tremor_freq,
    nan_as_zero = nan_as_zero,
    verbose = verbose
  )

  # Analyze amplitude tremor
  if (verbose) cat("\n=== Analyzing amplitude tremor ===\n")
  atrem_results <- .analyze_amplitude_tremor(
    sound = sound,
    time_step = analysis_time_step,
    min_pitch = min_pitch,
    min_tremor_freq = min_tremor_freq,
    max_tremor_freq = max_tremor_freq,
    nan_as_zero = nan_as_zero,
    verbose = verbose
  )

  # Combine results
  result <- structure(
    c(ftrem_results, atrem_results),
    class = "tremor_result",
    duration = duration,
    metadata = list(
      date = Sys.time(),
      speaker_version = as.character(packageVersion("pladdrr")),
      protocol = "Tremor v3.05 (Brückl, 2012)"
    )
  )

  if (verbose) {
    cat("\n=== Tremor Analysis Complete ===\n")
    cat(sprintf("Frequency tremor: %.2f Hz (intensity: %.2f%%)\n",
                result$FTrF, result$FTrI))
    cat(sprintf("Amplitude tremor: %.2f Hz (intensity: %.2f%%)\n",
                result$ATrF, result$ATrI))
  }

  return(result)
}


#' @keywords internal
.analyze_frequency_tremor <- function(sound, time_step, min_pitch, max_pitch,
                                     min_tremor_freq, max_tremor_freq,
                                     nan_as_zero, verbose) {

  tryCatch({
    # Extract pitch
    if (verbose) cat("Extracting pitch... ")
    pitch <- sound$to_pitch(
      time_step = time_step,
      pitch_floor = min_pitch,
      pitch_ceiling = max_pitch
    )
    if (verbose) cat("done\n")

    # Get number of voiced frames
    n_frames <- pitch$get_number_of_frames()

    # Extract F0 values from voiced frames
    if (verbose) cat("Extracting F0 contour... ")
    f0_values <- numeric(0)
    time_values <- numeric(0)

    for (i in 1:n_frames) {
      t <- pitch$get_time_from_frame(i)
      f0 <- pitch$get_value_at_time(t, unit = "hertz", interpolate = FALSE)
      if (!is.na(f0) && !is.nan(f0) && f0 > 0) {
        f0_values <- c(f0_values, f0)
        time_values <- c(time_values, t)
      }
    }

    if (length(f0_values) < 10) {
      if (verbose) cat("insufficient voiced frames\n")
      return(.undefined_ftrem_results(nan_as_zero))
    }
    if (verbose) cat(sprintf("%d frames\n", length(f0_values)))

    # FCoM will be calculated after creating F0 contour Pitch object
    # (following Brückl protocol: create Pitch from F0 contour, extract intensity)
    fcom <- 0.0  # Placeholder, calculated below after f0_pitch created

    # Calculate statistics
    mean_f0 <- mean(f0_values)

    # Detrend (remove linear trend)
    if (verbose) cat("Detrending... ")
    time_centered <- time_values - mean(time_values)
    trend_coef <- sum(time_centered * f0_values) / sum(time_centered^2)
    trend <- mean_f0 + trend_coef * time_centered
    f0_detrended <- f0_values - trend
    if (verbose) cat("done\n")

    # Normalize to proportion
    f0_normalized <- f0_detrended / mean_f0

    # Create uniformly sampled signal for FFT
    if (verbose) cat("Creating uniform signal... ")
    sample_rate <- 1.0 / time_step
    duration <- time_values[length(time_values)] - time_values[1]
    n_samples <- as.integer(duration * sample_rate)

    time_uniform <- seq(time_values[1], time_values[length(time_values)],
                       length.out = n_samples)
    f0_uniform <- approx(time_values, f0_normalized, xout = time_uniform,
                        method = "linear")$y
    if (verbose) cat("done\n")

    # Create Sound object from F0 contour
    if (verbose) cat("Converting to Sound... ")
    f0_sound <- Sound$from_values(
      values = matrix(f0_uniform, nrow = 1),
      sampling_rate = sample_rate
    )
    if (verbose) cat("done\n")

    # Create Pitch object from F0 contour for FCoM calculation
    # (Following Brückl protocol: pitch object from F0 contour has intensity field)
    if (verbose) cat("Creating Pitch from F0 contour... ")
    f0_pitch <- f0_sound$to_pitch(
      time_step = time_step,
      pitch_floor = min_tremor_freq,
      pitch_ceiling = max_tremor_freq
    )
    if (verbose) cat("done\n")
    
    # Calculate FCoM from F0 contour Pitch intensity
    if (verbose) cat("Computing frequency contour magnitude... ")
    f0_pitch_df <- f0_pitch$as_data_frame(include_intensity = TRUE)
    if (verbose) {
      cat(sprintf("\n  F0 pitch df: %d rows, cols: %s\n", 
                  nrow(f0_pitch_df), paste(names(f0_pitch_df), collapse=", ")))
      cat(sprintf("  Voiced frames: %d/%d\n", sum(f0_pitch_df$voiced), nrow(f0_pitch_df)))
      if ("intensity" %in% names(f0_pitch_df)) {
        cat(sprintf("  Intensity range: [%.4f, %.4f]\n",
                    min(f0_pitch_df$intensity, na.rm=TRUE),
                    max(f0_pitch_df$intensity, na.rm=TRUE)))
      } else {
        cat("  WARNING: No intensity column!\n")
      }
    }
    # Don't filter by voiced - contour signals are not periodic, use all frames
    # Use frame 1 intensity (following Brückl's readPitchOb.praat implementation)
    fcom <- ifelse(nrow(f0_pitch_df) > 0 && "intensity" %in% names(f0_pitch_df) &&
                   !is.na(f0_pitch_df$intensity[1]),
                   f0_pitch_df$intensity[1],
                   0.0)
    if (verbose) cat(sprintf("  FCoM = %.4f\n", fcom))

    # Calculate HNR of F0 contour
    if (verbose) cat("Computing F0 contour HNR... ")
    ftr_hnr <- .calculate_contour_hnr(f0_sound, min_tremor_freq, max_tremor_freq)
    if (verbose) cat(sprintf("%.2f dB\n", ftr_hnr))

    # Detect tremor using Brückl's algorithm
    if (verbose) cat("Detecting frequency tremor... ")
    tremor_stats <- .detect_tremor_from_spectrum(
      f0_sound, min_tremor_freq, max_tremor_freq, f0_pitch
    )
    if (verbose) cat("done\n")

    ftrf <- tremor_stats$frequency
    ftri <- tremor_stats$intensity
    fmon <- tremor_stats$n_modulations

    # Compute FTrC (Frequency Tremor Cyclicality) from autocorrelation
    if (verbose) cat("Computing tremor cyclicality... ")
    ftrc <- .compute_tremor_cyclicality(
      f0_uniform, sample_rate, min_tremor_freq, max_tremor_freq
    )
    if (verbose) cat(sprintf("%.4f\n", ftrc))

    # Calculate derived measures
    ftrp <- ifelse(ftrf > 0, ftri * ftrf / (ftrf + 1), 0.0)
    ftrcip <- ftri * ftrc
    ftrps <- ftrcip  # Simplified

    if (verbose) {
      cat(sprintf("  Frequency: %.2f Hz\n", ftrf))
      cat(sprintf("  Intensity: %.2f%%\n", ftri))
      cat(sprintf("  Cyclicality: %.2f\n", ftrc))
    }

    list(
      FCoM = fcom,  # Max intensity from Pitch created from F0 contour (Brückl protocol)
      FTrC = ftrc,  # Autocorrelation-based cyclicality (tremor periodicity)
      FMoN = as.integer(fmon),
      FTrF = ftrf,
      FTrI = ftri,
      FTrP = ftrp,
      FTrCIP = ftrcip,
      FTrPS = ftrps,
      FCoHNR = ftr_hnr
    )

  }, error = function(e) {
    if (verbose) cat(sprintf("Error: %s\n", e$message))
    return(.undefined_ftrem_results(nan_as_zero))
  })
}


#' @keywords internal
.analyze_amplitude_tremor <- function(sound, time_step, min_pitch,
                                     min_tremor_freq, max_tremor_freq,
                                     nan_as_zero, verbose) {

  tryCatch({
    # Extract intensity
    if (verbose) cat("Extracting intensity... ")
    intensity <- sound$to_intensity(
      minimum_pitch = min_pitch,
      time_step = time_step,
      subtract_mean = FALSE
    )
    if (verbose) cat("done\n")

    # Extract intensity values
    if (verbose) cat("Extracting amplitude contour... ")
    n_frames <- intensity$get_number_of_frames()
    amp_values <- numeric(0)
    time_values <- numeric(0)

    for (i in 1:n_frames) {
      t <- intensity$get_time_from_frame(i)
      amp_db <- intensity$get_value_at_time(t, interpolation = "nearest")
      if (!is.na(amp_db) && !is.nan(amp_db)) {
        # Convert dB to linear
        amp_linear <- 10^(amp_db / 20.0)
        amp_values <- c(amp_values, amp_linear)
        time_values <- c(time_values, t)
      }
    }

    if (length(amp_values) < 10) {
      if (verbose) cat("insufficient frames\n")
      return(.undefined_atrem_results(nan_as_zero))
    }
    if (verbose) cat(sprintf("%d frames\n", length(amp_values)))

    # ACoM will be calculated after creating amplitude contour Pitch object
    # (following Brückl protocol: create Pitch from amplitude contour, extract intensity)
    acom <- 0.0  # Placeholder, calculated below after amp_pitch created

    # Calculate mean amplitude
    mean_amp <- mean(amp_values)

    # Normalize amplitude
    amp_normalized <- (amp_values - mean_amp) / mean_amp

    # Create uniformly sampled signal
    if (verbose) cat("Creating uniform signal... ")
    sample_rate <- 1.0 / time_step
    duration <- time_values[length(time_values)] - time_values[1]
    n_samples <- as.integer(duration * sample_rate)

    time_uniform <- seq(time_values[1], time_values[length(time_values)],
                       length.out = n_samples)
    amp_uniform <- approx(time_values, amp_normalized, xout = time_uniform,
                         method = "linear")$y
    if (verbose) cat("done\n")

    # Create Sound from amplitude contour
    if (verbose) cat("Converting to Sound... ")
    amp_sound <- Sound$from_values(
      values = matrix(amp_uniform, nrow = 1),
      sampling_rate = sample_rate
    )
    if (verbose) cat("done\n")

    # Create Pitch object from amplitude contour for ACoM calculation
    # (Following Brückl protocol: pitch object from amp contour has intensity field)
    if (verbose) cat("Creating Pitch from amplitude contour... ")
    amp_pitch <- amp_sound$to_pitch(
      time_step = time_step,
      pitch_floor = min_tremor_freq,
      pitch_ceiling = max_tremor_freq
    )
    if (verbose) cat("done\n")
    
    # Calculate ACoM from amplitude contour Pitch intensity
    if (verbose) cat("Computing amplitude contour magnitude... ")
    amp_pitch_df <- amp_pitch$as_data_frame(include_intensity = TRUE)
    if (verbose) {
      cat(sprintf("\n  Amp pitch df: %d rows, cols: %s\n",
                  nrow(amp_pitch_df), paste(names(amp_pitch_df), collapse=", ")))
      cat(sprintf("  Voiced frames: %d/%d\n", sum(amp_pitch_df$voiced), nrow(amp_pitch_df)))
      if ("intensity" %in% names(amp_pitch_df)) {
        cat(sprintf("  Intensity range: [%.4f, %.4f]\n",
                    min(amp_pitch_df$intensity, na.rm=TRUE),
                    max(amp_pitch_df$intensity, na.rm=TRUE)))
      } else {
        cat("  WARNING: No intensity column!\n")
      }
    }
    # Don't filter by voiced - contour signals are not periodic, use all frames
    # Use frame 1 intensity (following Brückl's readPitchOb.praat implementation)
    acom <- ifelse(nrow(amp_pitch_df) > 0 && "intensity" %in% names(amp_pitch_df) &&
                   !is.na(amp_pitch_df$intensity[1]),
                   amp_pitch_df$intensity[1],
                   0.0)
    if (verbose) cat(sprintf("  ACoM = %.4f\n", acom))

    # Calculate HNR
    if (verbose) cat("Computing amplitude contour HNR... ")
    atr_hnr <- .calculate_contour_hnr(amp_sound, min_tremor_freq, max_tremor_freq)
    if (verbose) cat(sprintf("%.2f dB\n", atr_hnr))

    # Detect tremor using Brückl's algorithm
    if (verbose) cat("Detecting amplitude tremor... ")
    tremor_stats <- .detect_tremor_from_spectrum(
      amp_sound, min_tremor_freq, max_tremor_freq, amp_pitch
    )
    if (verbose) cat("done\n")

    atrf <- tremor_stats$frequency
    atri <- tremor_stats$intensity
    amon <- tremor_stats$n_modulations

    # Compute ATrC (Amplitude Tremor Cyclicality) from autocorrelation
    if (verbose) cat("Computing amplitude tremor cyclicality... ")
    atrc <- .compute_tremor_cyclicality(
      amp_uniform, sample_rate, min_tremor_freq, max_tremor_freq
    )
    if (verbose) cat(sprintf("%.4f\n", atrc))

    # Calculate derived measures
    atrp <- ifelse(atrf > 0, atri * atrf / (atrf + 1), 0.0)
    atrcip <- atri * atrc
    atrps <- atrcip  # Simplified

    if (verbose) {
      cat(sprintf("  Frequency: %.2f Hz\n", atrf))
      cat(sprintf("  Intensity: %.2f%%\n", atri))
      cat(sprintf("  Cyclicality: %.2f\n", atrc))
    }

    list(
      ACoM = acom,  # Max intensity from Pitch created from amplitude contour (Brückl protocol)
      ATrC = atrc,  # Autocorrelation-based cyclicality
      AMoN = as.integer(amon),
      ATrF = atrf,
      ATrI = atri,
      ATrP = atrp,
      ATrCIP = atrcip,
      ATrPS = atrps,
      ACoHNR = atr_hnr
    )

  }, error = function(e) {
    if (verbose) cat(sprintf("Error: %s\n", e$message))
    return(.undefined_atrem_results(nan_as_zero))
  })
}


#' @keywords internal
.detect_tremor_from_spectrum <- function(sound, min_freq, max_freq, pitch_obj) {
  # Brückl's tremIntIndex algorithm (tremor3.05/procedures/tremIntIndex.praat)
  # Measures amplitude deviation of peaks/valleys in normalized F0 contour
  
  # Step 1: Create PointProcess of maxima (peaks)
  pp_max <- pitch_obj$to_pointprocess_peaks(sound, include_maxima = TRUE, include_minima = FALSE)
  n_max_points <- pp_max$get_number_of_points()
  
  tri_max <- 0.0
  no_f_max <- 0
  
  # Sample amplitude at each maximum time using Sinc70 interpolation
  for (i_point in seq_len(n_max_points)) {
    ti <- pp_max$get_time_from_index(i_point)
    tri_point <- sound$get_value_at_time(time = ti, channel = 1, interpolation = "sinc70")
    
    if (is.na(tri_point)) {
      tri_point <- 0.0
      no_f_max <- no_f_max + 1
    }
    
    tri_max <- tri_max + abs(tri_point)
  }
  
  # tri_max := (mean) percentual deviation of contour maxima from mean contour
  number_of_maxima <- n_max_points - no_f_max
  if (number_of_maxima > 0) {
    tri_max <- 100 * tri_max / number_of_maxima
  } else {
    tri_max <- 0.0
  }
  
  # Step 2: Create PointProcess of minima (valleys)
  pp_min <- pitch_obj$to_pointprocess_peaks(sound, include_maxima = FALSE, include_minima = TRUE)
  n_min_points <- pp_min$get_number_of_points()
  
  tri_min <- 0.0
  no_f_min <- 0
  
  # Sample amplitude at each minimum time using Sinc70 interpolation
  for (i_point in seq_len(n_min_points)) {
    ti <- pp_min$get_time_from_index(i_point)
    tri_point <- sound$get_value_at_time(time = ti, channel = 1, interpolation = "sinc70")
    
    if (is.na(tri_point)) {
      tri_point <- 0.0
      no_f_min <- no_f_min + 1
    }
    
    tri_min <- tri_min + abs(tri_point)
  }
  
  # tri_min := (mean) percentual deviation of contour minima from mean contour
  number_of_minima <- n_min_points - no_f_min
  if (number_of_minima > 0) {
    tri_min <- 100 * tri_min / number_of_minima
  } else {
    tri_min <- 0.0
  }
  
  # Step 3: FTrI = average of peak and valley deviations
  tri <- (tri_max + tri_min) / 2
  
  # For backwards compatibility, also compute frequency from spectrum
  spectrum <- sound$to_spectrum(fast = TRUE)
  n_bins <- spectrum$get_number_of_bins()
  max_power <- 0.0
  max_freq_found <- 0.0
  
  for (i in 1:n_bins) {
    freq <- spectrum$get_frequency_from_bin(i)
    if (freq >= min_freq && freq <= max_freq) {
      real_val <- spectrum$get_real_value_in_bin(i)
      imag_val <- spectrum$get_imaginary_value_in_bin(i)
      power <- real_val^2 + imag_val^2
      
      if (power > max_power) {
        max_power <- power
        max_freq_found <- freq
      }
    }
  }
  
  list(
    frequency = max_freq_found,
    intensity = tri,  # FTrI from Brückl's algorithm
    cyclicality = 0.0,  # Deprecated
    n_modulations = number_of_maxima + number_of_minima
  )
}


#' @keywords internal
.compute_tremor_cyclicality <- function(signal, sample_rate, min_freq, max_freq) {
  # Compute autocorrelation-based cyclicality measure
  # Following Brückl (2012) protocol
  
  n <- length(signal)
  if (n < 10) return(0.0)
  
  # Compute autocorrelation for lags corresponding to tremor frequencies
  min_lag <- max(1, floor(sample_rate / max_freq))
  max_lag <- min(n - 1, ceiling(sample_rate / min_freq))
  
  if (min_lag >= max_lag) return(0.0)
  
  # Compute autocorrelation coefficients
  signal_centered <- signal - mean(signal, na.rm = TRUE)
  var_signal <- sum(signal_centered^2, na.rm = TRUE)
  
  if (var_signal < 1e-10) return(0.0)
  
  acf_values <- numeric(max_lag - min_lag + 1)
  
  for (lag_idx in 1:length(acf_values)) {
    lag <- min_lag + lag_idx - 1
    if (lag < n) {
      acf_values[lag_idx] <- sum(
        signal_centered[1:(n-lag)] * signal_centered[(lag+1):n],
        na.rm = TRUE
      ) / var_signal
    }
  }
  
  # Find maximum autocorrelation in tremor range
  max_acf <- max(acf_values, na.rm = TRUE)
  
  # Normalize to 0-1 range
  cyclicality <- max(0, min(1, max_acf))
  
  return(cyclicality)
}


#' @keywords internal
.calculate_contour_hnr <- function(sound, min_freq, max_freq) {

  tryCatch({
    # Use autocorrelation method
    time_step <- 1.0 / max_freq / 4.0  # Oversample for accuracy

    harmonicity <- sound$to_harmonicity_ac(
      time_step = time_step,
      min_pitch = min_freq,
      silence_threshold = 0.1,
      periods_per_window = 1.0
    )

    hnr <- harmonicity$get_mean(0, 0)

    if (is.na(hnr) || is.nan(hnr) || is.infinite(hnr)) {
      return(0.0)
    }

    return(hnr)

  }, error = function(e) {
    return(0.0)
  })
}


#' @keywords internal
.undefined_ftrem_results <- function(nan_as_zero) {
  val <- ifelse(nan_as_zero, 0.0, NA_real_)
  list(
    FCoM = val, FTrC = val, FMoN = 0L, FTrF = val,
    FTrI = val, FTrP = val, FTrCIP = val, FTrPS = val, FCoHNR = val
  )
}


#' @keywords internal
.undefined_atrem_results <- function(nan_as_zero) {
  val <- ifelse(nan_as_zero, 0.0, NA_real_)
  list(
    ACoM = val, ATrC = val, AMoN = 0L, ATrF = val,
    ATrI = val, ATrP = val, ATrCIP = val, ATrPS = val, ACoHNR = val
  )
}


#' @export
print.tremor_result <- function(x, ...) {
  cat("Tremor Analysis Result\n")
  cat("======================\n\n")

  cat("Frequency Modulations:\n")
  cat(sprintf("  Tremor Frequency: %.2f Hz\n", x$FTrF))
  cat(sprintf("  Intensity Index: %.2f%%\n", x$FTrI))
  cat(sprintf("  Cyclicality: %.2f\n", x$FTrC))
  cat(sprintf("  Power Index: %.2f\n", x$FTrP))
  cat(sprintf("  Contour HNR: %.2f dB\n", x$FCoHNR))
  cat(sprintf("  N Modulations: %d\n\n", x$FMoN))

  cat("Amplitude Modulations:\n")
  cat(sprintf("  Tremor Frequency: %.2f Hz\n", x$ATrF))
  cat(sprintf("  Intensity Index: %.2f%%\n", x$ATrI))
  cat(sprintf("  Cyclicality: %.2f\n", x$ATrC))
  cat(sprintf("  Power Index: %.2f\n", x$ATrP))
  cat(sprintf("  Contour HNR: %.2f dB\n", x$ACoHNR))
  cat(sprintf("  N Modulations: %d\n", x$AMoN))

  cat(sprintf("\nProtocol: %s\n", attr(x, "metadata")$protocol))
  invisible(x)
}
