#' DSI (Dysphonia Severity Index) Implementation
#'
#' @description
#' Compute the Dysphonia Severity Index (DSI) following the protocol
#' by Wuyts et al. (2000).
#'
#' @name dsi
NULL

#' @title Compute DSI (Dysphonia Severity Index)
#'
#' @description
#' Computes the Dysphonia Severity Index, a multiparametric clinical voice disorder
#' index combining four measurements into a single score.
#'
#' @param sound Sound object or path to audio file containing:
#'   - Sustained vowel /a/ for maximum phonation time
#'   - Pitch glide from lowest to highest frequency
#' @param type Character. Recording type:
#'   - "sustained" - Sustained vowel only (for MPT, F0-high, jitter)
#'   - "glide" - Pitch glide only (for F0-high, I-low)
#'   - "combined" - Both tasks in sequence (optimal)
#' @param gender Character. Speaker gender: "male", "female", or "unknown" (default: "unknown")
#' @param f0_min Numeric. Minimum F0 for analysis (Hz). Default: 50 for males, 75 for females
#' @param f0_max Numeric. Maximum F0 for analysis (Hz). Default: 600 for males, 800 for females
#' @param verbose Logical. Print progress messages (default: TRUE)
#'
#' @return List of class "dsi_result" containing:
#'   \item{dsi}{Numeric. DSI score (-5 to +5 scale, higher = better voice)}
#'   \item{components}{Data frame with all 4 component measures}
#'   \item{mpt}{Numeric. Maximum Phonation Time (seconds)}
#'   \item{i_low}{Numeric. Lowest Intensity (dB SPL)}
#'   \item{f0_high}{Numeric. Highest F0 (Hz)}
#'   \item{jitter_ppq5}{Numeric. Jitter ppq5 (%)}
#'   \item{type}{Character. Recording type used}
#'   \item{metadata}{List with analysis parameters}
#'
#' @details
#' The DSI combines four measurements:
#'
#' 1. **MPT** - Maximum Phonation Time (seconds)
#' 2. **I-low** - Lowest Intensity during soft phonation (dB SPL)
#' 3. **F0-high** - Highest Fundamental Frequency achievable (Hz)
#' 4. **Jitter ppq5** - 5-point Period Perturbation Quotient (%)
#'
#' **Formula** (Wuyts et al., 2000):
#' \deqn{DSI = 1.127 + (0.164 \times MPT) - (0.038 \times I_{low}) +}
#' \deqn{      (0.0053 \times F_{0high}) - (5.30 \times Jitter_{ppq5})}
#'
#' **Interpretation**:
#' - DSI > +5: Excellent voice quality
#' - DSI 1.6 to +5: Normal voice quality
#' - DSI -5 to 1.6: Mild dysphonia
#' - DSI < -5: Severe dysphonia
#'
#' **Recording Protocol**:
#' 1. **MPT**: Sustain /a/ at comfortable pitch and loudness for as long as possible
#' 2. **I-low**: Sustain /a/ at lowest possible intensity (soft voice)
#' 3. **F0-high**: Produce vocal glide from lowest to highest possible pitch
#' 4. **Jitter**: Measured from sustained /a/ at comfortable pitch
#'
#' @references
#' Wuyts, F. L., De Bodt, M. S., Molenberghs, G., Remacle, M., Heylen, L.,
#' Millet, B., ... & Heyning, P. H. (2000). The dysphonia severity index:
#' an objective measure of vocal quality based on a multiparameter approach.
#' \emph{Journal of Speech, Language, and Hearing Research}, 43(3), 796-809.
#'
#' @examples
#' \dontrun{
#' # Sustained vowel only
#' result <- compute_dsi("sustained_a.wav", type = "sustained")
#' print(result$dsi)
#'
#' # With gender specification
#' result <- compute_dsi(
#'   "phonation_tasks.wav",
#'   type = "combined",
#'   gender = "female"
#' )
#'
#' # Access components
#' print(result$components)
#' cat("MPT:", result$mpt, "s\n")
#' cat("I-low:", result$i_low, "dB\n")
#' cat("F0-high:", result$f0_high, "Hz\n")
#' cat("Jitter:", result$jitter_ppq5, "%\n")
#'
#' # Using Sound object
#' sound <- Sound$new("phonation.wav")
#' result <- compute_dsi(sound, type = "sustained")
#' }
#'
#' @export
compute_dsi <- function(sound,
                       type = c("sustained", "glide", "combined"),
                       gender = c("unknown", "male", "female"),
                       f0_min = NULL,
                       f0_max = NULL,
                       verbose = TRUE) {
  
  type <- match.arg(type)
  gender <- match.arg(gender)
  
  # Set default F0 ranges based on gender
  if (is.null(f0_min)) {
    f0_min <- if (gender == "female") 75 else 50
  }
  if (is.null(f0_max)) {
    f0_max <- if (gender == "female") 800 else 600
  }
  
  # Load sound if path provided
  if (is.character(sound)) {
    if (verbose) cat("Loading sound from:", sound, "\n")
    sound <- Sound$new(sound)
  }
  
  duration <- sound$get_total_duration()
  if (verbose) cat(sprintf("Total duration: %.2f s\n\n", duration))
  
  # ============================================================================
  # MEASURE COMPONENTS
  # ============================================================================
  
  if (verbose) cat("=== Computing DSI Components ===\n\n")
  
  # 1. MPT - Maximum Phonation Time
  # For sustained vowel, use total duration
  # For combined, may need manual segmentation or VAD
  if (verbose) cat("1. Maximum Phonation Time (MPT)... ")
  
  if (type == "sustained" || type == "combined") {
    # Use total duration as MPT
    # In clinical setting, this would be timed manually
    mpt <- duration
  } else {
    # For glide only, MPT cannot be measured
    mpt <- NA
    warning("MPT cannot be measured from glide recording alone")
  }
  
  if (verbose) cat(sprintf("%.2f s\n", mpt))
  
  # 2. I-low - Lowest Intensity
  # Compute intensity and find minimum
  if (verbose) cat("2. Lowest Intensity (I-low)... ")
  
  intensity <- sound$to_intensity(
    minimum_pitch = f0_min,
    time_step = 0.0,  # auto
    subtract_mean = FALSE  # We want absolute dB SPL
  )
  
  i_low <- intensity$get_minimum(0, 0, "parabolic")
  
  if (verbose) cat(sprintf("%.2f dB SPL\n", i_low))
  
  # 3. F0-high - Highest Fundamental Frequency
  # For glide or combined, find maximum pitch
  if (verbose) cat("3. Highest F0 (F0-high)... ")
  
  pitch <- sound$to_pitch_cc(
    time_step = 0.0,  # auto
    pitch_floor = f0_min,
    pitch_ceiling = f0_max,
    very_accurate = TRUE
  )
  
  f0_high <- pitch$get_maximum(0, 0, "hertz", "parabolic")
  
  if (verbose) cat(sprintf("%.1f Hz\n", f0_high))
  
  # 4. Jitter ppq5 - 5-point Period Perturbation Quotient
  # Measured from sustained vowel portion
  if (verbose) cat("4. Jitter ppq5... ")
  
  if (type == "sustained" || type == "combined") {
    # For combined recording, extract stable vowel portion
    # Use middle section to avoid onset/offset effects
    if (type == "combined" && duration > 3.0) {
      # Extract middle 3 seconds for jitter measurement
      mid_start <- (duration - 3.0) / 2
      mid_end <- mid_start + 3.0
      if (verbose) cat(sprintf("\n   Extracting stable portion: %.2f - %.2f s\n   ", 
                              mid_start, mid_end))
      sound_jitter <- sound$extract_part(mid_start, mid_end)
      pitch_jitter <- sound_jitter$to_pitch_cc(
        time_step = 0.0,
        pitch_floor = f0_min,
        pitch_ceiling = f0_max
      )
    } else {
      sound_jitter <- sound
      pitch_jitter <- pitch
    }
    
    # Get point process and voice report
    pp <- sound_jitter$to_point_process_cc(pitch_jitter)
    report <- pp$voice_report(sound_jitter, pitch_jitter)
    
    # Jitter ppq5 in proportion, convert to %
    jitter_ppq5 <- report$jitter_ppq5 * 100
    
  } else {
    # For glide only, jitter cannot be reliably measured
    jitter_ppq5 <- NA
    warning("Jitter cannot be measured from glide recording alone")
  }
  
  if (verbose) cat(sprintf("%.3f %%\n", jitter_ppq5))
  
  # ============================================================================
  # COMPUTE DSI SCORE
  # ============================================================================
  
  if (verbose) cat("\n=== DSI Calculation ===\n")
  
  # Check if all components are available
  if (is.na(mpt) || is.na(jitter_ppq5)) {
    if (type == "glide") {
      warning("DSI cannot be fully computed from glide recording alone. ",
              "Use type='sustained' or 'combined' for complete DSI.")
    }
    dsi_score <- NA
  } else {
    # DSI formula (Wuyts et al., 2000)
    # DSI = 1.127 + 0.164*MPT - 0.038*Ilow + 0.0053*Fhigh - 5.30*Jitter
    # Note: Jitter must be in proportion (0-1), not %
    jitter_prop <- jitter_ppq5 / 100
    
    dsi_score <- 1.127 + 
      (0.164 * mpt) -
      (0.038 * i_low) +
      (0.0053 * f0_high) -
      (5.30 * jitter_prop)
    
    if (verbose) {
      cat(sprintf("1.127 + (0.164 × %.2f) - (0.038 × %.2f) +\n", mpt, i_low))
      cat(sprintf("(0.0053 × %.1f) - (5.30 × %.4f)\n", f0_high, jitter_prop))
      cat(sprintf("\nDSI = %.2f\n", dsi_score))
      cat(sprintf("Interpretation: %s\n", .interpret_dsi(dsi_score)))
    }
  }
  
  # ============================================================================
  # PREPARE RESULT OBJECT
  # ============================================================================
  
  components <- data.frame(
    measure = c("MPT", "I-low", "F0-high", "Jitter_ppq5"),
    value = c(mpt, i_low, f0_high, jitter_ppq5),
    unit = c("s", "dB SPL", "Hz", "%")
  )
  
  result <- structure(
    list(
      dsi = dsi_score,
      components = components,
      mpt = mpt,
      i_low = i_low,
      f0_high = f0_high,
      jitter_ppq5 = jitter_ppq5,
      type = type,
      gender = gender,
      f0_range = c(f0_min, f0_max),
      duration = duration,
      metadata = list(
        date = Sys.time(),
        speaker_version = as.character(packageVersion("speaker")),
        protocol = "DSI v2.01 (Wuyts et al., 2000)"
      )
    ),
    class = "dsi_result"
  )
  
  return(result)
}

#' @keywords internal
.interpret_dsi <- function(dsi) {
  if (is.na(dsi)) {
    return("Cannot compute - missing components")
  } else if (dsi > 5.0) {
    return("Excellent voice quality")
  } else if (dsi >= 1.6) {
    return("Normal voice quality")
  } else if (dsi >= -5.0) {
    return("Mild dysphonia")
  } else {
    return("Severe dysphonia")
  }
}

#' @export
print.dsi_result <- function(x, ...) {
  cat("DSI Result\n")
  cat("==========\n\n")
  cat(sprintf("DSI Score: %.2f\n", x$dsi))
  cat(sprintf("Interpretation: %s\n\n", .interpret_dsi(x$dsi)))
  cat(sprintf("Recording Type: %s\n", x$type))
  cat(sprintf("Gender: %s\n", x$gender))
  cat(sprintf("Duration: %.2f s\n", x$duration))
  cat(sprintf("F0 Range: %.0f - %.0f Hz\n\n", x$f0_range[1], x$f0_range[2]))
  
  cat("Components:\n")
  print(x$components)
  
  cat(sprintf("\nProtocol: %s\n", x$metadata$protocol))
  invisible(x)
}
