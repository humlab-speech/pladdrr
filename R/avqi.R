#' AVQI (Acoustic Voice Quality Index) Implementation
#'
#' @description
#' Compute the Acoustic Voice Quality Index (AVQI) following the protocol
#' by Maryn et al. (2010) and Barsties & Maryn (2015).
#'
#' @name avqi
NULL

#' @title Compute AVQI (Acoustic Voice Quality Index)
#'
#' @description
#' Computes the Acoustic Voice Quality Index v3.01, a multiparametric voice quality
#' assessment tool combining six acoustic measures into a single dysphonia severity score.
#'
#' @param sound Sound object or path to audio file. Can be:
#'   - Sustained vowel only (3 seconds)
#'   - Continuous speech only (>3 seconds)
#'   - Combined: vowel + speech files
#' @param type Character. Recording type:
#'   - "vowel" - Sustained vowel only
#'   - "speech" - Continuous speech only
#'   - "combined" - Both vowel and speech (optimal)
#' @param speech_sound Sound object or path for continuous speech (if type = "combined")
#' @param gender Character. Speaker gender: "male", "female", or "unknown" (default: "unknown")
#' @param f0_min Numeric. Minimum F0 for analysis (Hz). Default: 50 for males, 75 for females
#' @param f0_max Numeric. Maximum F0 for analysis (Hz). Default: 300 for males, 500 for females
#' @param verbose Logical. Print progress messages (default: TRUE)
#'
#' @return List of class "avqi_result" containing:
#'   \item{avqi}{Numeric. AVQI score (0-10 scale, higher = more dysphonic)}
#'   \item{components}{Data frame with all 6 component measures}
#'   \item{cpps}{Numeric. Smoothed Cepstral Peak Prominence (dB)}
#'   \item{hnr}{Numeric. Harmonics-to-Noise Ratio (dB)}
#'   \item{shimmer_local}{Numeric. Shimmer Local (%)}
#'   \item{shimmer_local_db}{Numeric. Shimmer Local (dB)}
#'   \item{slope}{Numeric. LTAS Slope (dB)}
#'   \item{tilt}{Numeric. LTAS Tilt / H1-A3 approximation (dB)}
#'   \item{type}{Character. Recording type used}
#'   \item{duration}{Numeric. Total analysis duration (seconds)}
#'   \item{metadata}{List with analysis parameters}
#'
#' @details
#' The AVQI combines six acoustic measures:
#'
#' 1. **CPPS** - Smoothed Cepstral Peak Prominence (cepstral measure of periodicity)
#' 2. **HNR** - Harmonics-to-Noise Ratio (harmonic structure quality)
#' 3. **Shimmer Local** - Short-term amplitude perturbation (%)
#' 4. **Shimmer Local dB** - Shimmer in decibels
#' 5. **Slope** - LTAS slope between 0-1000 Hz and 1000-5000 Hz
#' 6. **Tilt** - Spectral tilt approximating H1-A3
#'
#' **Formula** (Barsties & Maryn, 2015):
#' \deqn{AVQI = 4.152 - 0.177 \times CPPS - 0.006 \times HNR - 0.037 \times SL +}
#' \deqn{      0.941 \times SLdB + 0.010 \times Slope + 0.093 \times Tilt}
#'
#' **Interpretation**:
#' - AVQI < 2.95: Normal voice quality
#' - AVQI >= 2.95: Dysphonic voice
#' - Higher scores indicate more severe dysphonia
#'
#' **Recording Requirements**:
#' - Sustained vowel /a/: 3 seconds minimum
#' - Continuous speech: >3 seconds (read passage recommended)
#' - Sampling rate: 25+ kHz recommended
#' - 16-bit or higher bit depth
#'
#' @references
#' Maryn, Y., Corthals, P., Van Cauwenberge, P., Roy, N., & De Bodt, M. (2010).
#' Toward improved ecological validity in the acoustic measurement of overall
#' voice quality: Combining continuous speech and sustained vowels.
#' \emph{Journal of Voice}, 24(5), 540-555.
#'
#' Barsties, B., & Maryn, Y. (2015). The improvement of internal consistency
#' of the Acoustic Voice Quality Index. \emph{American Journal of Otolaryngology},
#' 36(5), 647-656.
#'
#' @examples
#' \dontrun{
#' # Vowel only
#' result <- compute_avqi("sustained_a.wav", type = "vowel")
#' print(result$avqi)
#'
#' # Speech only
#' result <- compute_avqi("reading_passage.wav", type = "speech")
#'
#' # Combined (optimal)
#' result <- compute_avqi(
#'   "sustained_a.wav",
#'   type = "combined",
#'   speech_sound = "reading_passage.wav",
#'   gender = "female"
#' )
#'
#' # Access components
#' print(result$components)
#' cat("CPPS:", result$cpps, "dB\n")
#' cat("HNR:", result$hnr, "dB\n")
#' cat("Shimmer:", result$shimmer_local, "%\n")
#'
#' # Using Sound objects
#' vowel <- Sound$new("vowel.wav")
#' speech <- Sound$new("speech.wav")
#' result <- compute_avqi(vowel, type = "combined", speech_sound = speech)
#' }
#'
#' @export
compute_avqi <- function(sound,
                        type = c("combined", "vowel", "speech"),
                        speech_sound = NULL,
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
    f0_max <- if (gender == "female") 500 else 300
  }
  
  # Load sounds if paths provided
  if (is.character(sound)) {
    if (verbose) cat("Loading sound from:", sound, "\n")
    sound <- Sound$new(sound)
  }
  
  if (!is.null(speech_sound) && is.character(speech_sound)) {
    if (verbose) cat("Loading speech from:", speech_sound, "\n")
    speech_sound <- Sound$new(speech_sound)
  }
  
  # Validate type and sounds
  if (type == "combined" && is.null(speech_sound)) {
    stop("For type='combined', both sound (vowel) and speech_sound are required")
  }
  
  # Determine which recordings to analyze
  analyze_vowel <- (type == "vowel" || type == "combined")
  analyze_speech <- (type == "speech" || type == "combined")
  
  # Initialize result containers
  results <- list()
  
  # ============================================================================
  # VOWEL ANALYSIS (if applicable)
  # ============================================================================
  
  if (analyze_vowel) {
    if (verbose) cat("\n=== Analyzing sustained vowel ===\n")
    
    vowel_results <- .compute_avqi_vowel(
      sound = sound,
      f0_min = f0_min,
      f0_max = f0_max,
      verbose = verbose
    )
    
    results$vowel <- vowel_results
  }
  
  # ============================================================================
  # SPEECH ANALYSIS (if applicable)
  # ============================================================================
  
  if (analyze_speech) {
    if (verbose) cat("\n=== Analyzing continuous speech ===\n")
    
    speech_input <- if (type == "speech") sound else speech_sound
    
    speech_results <- .compute_avqi_speech(
      sound = speech_input,
      f0_min = f0_min,
      f0_max = f0_max,
      verbose = verbose
    )
    
    results$speech <- speech_results
  }
  
  # ============================================================================
  # COMBINE RESULTS
  # ============================================================================
  
  if (type == "combined") {
    # Average the six components from vowel and speech
    components <- data.frame(
      measure = c("CPPS", "HNR", "Shimmer_Local", "Shimmer_Local_dB", "Slope", "Tilt"),
      vowel = c(
        results$vowel$cpps,
        results$vowel$hnr,
        results$vowel$shimmer_local,
        results$vowel$shimmer_local_db,
        results$vowel$slope,
        results$vowel$tilt
      ),
      speech = c(
        results$speech$cpps,
        results$speech$hnr,
        results$speech$shimmer_local,
        results$speech$shimmer_local_db,
        results$speech$slope,
        results$speech$tilt
      )
    )
    
    components$combined <- rowMeans(components[, c("vowel", "speech")])
    
    cpps <- components$combined[1]
    hnr <- components$combined[2]
    shimmer_local <- components$combined[3]
    shimmer_local_db <- components$combined[4]
    slope <- components$combined[5]
    tilt <- components$combined[6]
    
  } else if (type == "vowel") {
    cpps <- results$vowel$cpps
    hnr <- results$vowel$hnr
    shimmer_local <- results$vowel$shimmer_local
    shimmer_local_db <- results$vowel$shimmer_local_db
    slope <- results$vowel$slope
    tilt <- results$vowel$tilt
    
    components <- data.frame(
      measure = c("CPPS", "HNR", "Shimmer_Local", "Shimmer_Local_dB", "Slope", "Tilt"),
      value = c(cpps, hnr, shimmer_local, shimmer_local_db, slope, tilt)
    )
    
  } else {  # type == "speech"
    cpps <- results$speech$cpps
    hnr <- results$speech$hnr
    shimmer_local <- results$speech$shimmer_local
    shimmer_local_db <- results$speech$shimmer_local_db
    slope <- results$speech$slope
    tilt <- results$speech$tilt
    
    components <- data.frame(
      measure = c("CPPS", "HNR", "Shimmer_Local", "Shimmer_Local_dB", "Slope", "Tilt"),
      value = c(cpps, hnr, shimmer_local, shimmer_local_db, slope, tilt)
    )
  }
  
  # ============================================================================
  # COMPUTE AVQI SCORE
  # ============================================================================
  
  # AVQI formula (Barsties & Maryn, 2015)
  avqi_score <- 4.152 - 
    (0.177 * cpps) -
    (0.006 * hnr) -
    (0.037 * shimmer_local) +
    (0.941 * shimmer_local_db) +
    (0.010 * slope) +
    (0.093 * tilt)
  
  if (verbose) {
    cat("\n=== AVQI Calculation ===\n")
    cat(sprintf("4.152 - (0.177 × %.2f) - (0.006 × %.2f) - (0.037 × %.2f) +\n", 
                cpps, hnr, shimmer_local))
    cat(sprintf("(0.941 × %.2f) + (0.010 × %.2f) + (0.093 × %.2f)\n",
                shimmer_local_db, slope, tilt))
    cat(sprintf("\nAVQI = %.3f\n", avqi_score))
    cat(sprintf("Interpretation: %s\n", 
                if (avqi_score < 2.95) "Normal voice" else "Dysphonic voice"))
  }
  
  # ============================================================================
  # PREPARE RESULT OBJECT
  # ============================================================================
  
  result <- structure(
    list(
      avqi = avqi_score,
      components = components,
      cpps = cpps,
      hnr = hnr,
      shimmer_local = shimmer_local,
      shimmer_local_db = shimmer_local_db,
      slope = slope,
      tilt = tilt,
      type = type,
      gender = gender,
      f0_range = c(f0_min, f0_max),
      vowel_results = if (analyze_vowel) results$vowel else NULL,
      speech_results = if (analyze_speech) results$speech else NULL,
      metadata = list(
        date = Sys.time(),
        speaker_version = as.character(packageVersion("speaker")),
        protocol = "AVQI v3.01 (Barsties & Maryn, 2015)"
      )
    ),
    class = "avqi_result"
  )
  
  return(result)
}

#' @keywords internal
.compute_avqi_vowel <- function(sound, f0_min, f0_max, verbose = TRUE) {
  
  # Get duration
  duration <- sound$get_total_duration()
  if (verbose) cat(sprintf("Duration: %.2f s\n", duration))
  
  if (duration < 2.0) {
    warning("Vowel duration < 2s. AVQI may be unreliable. Recommended: 3+ seconds.")
  }
  
  # Extract middle 3 seconds (or use all if < 3s)
  if (duration > 3.0) {
    mid_start <- (duration - 3.0) / 2
    mid_end <- mid_start + 3.0
    if (verbose) cat(sprintf("Extracting middle 3s: %.2f - %.2f\n", mid_start, mid_end))
    sound_analysis <- sound$extract_part(mid_start, mid_end)
  } else {
    sound_analysis <- sound
  }
  
  # 1. CPPS - Smoothed Cepstral Peak Prominence
  if (verbose) cat("Computing CPPS... ")
  cepstrogram <- sound_analysis$to_power_cepstrogram(
    pitch_floor = f0_min,
    time_step = 0.002,
    max_frequency = 5000,
    pre_emphasis_from = 50
  )
  cpps <- cepstrogram$get_cpps()  # Uses AVQI defaults
  if (verbose) cat(sprintf("%.2f dB\n", cpps))
  
  # 2. HNR - Harmonics-to-Noise Ratio
  if (verbose) cat("Computing HNR... ")
  harmonicity <- sound_analysis$to_harmonicity_cc(
    time_step = 0.01,
    pitch_floor = f0_min,
    silence_threshold = 0.1,
    periods_per_window = 1.0
  )
  hnr <- harmonicity$get_mean(0, 0)
  if (verbose) cat(sprintf("%.2f dB\n", hnr))
  
  # 3-4. Shimmer - Voice Report
  if (verbose) cat("Computing shimmer... ")
  pitch <- sound_analysis$to_pitch_cc(
    time_step = 0.0,  # auto
    pitch_floor = f0_min,
    pitch_ceiling = f0_max
  )
  pp <- sound_analysis$to_point_process_cc(pitch)
  report <- pp$voice_report(sound_analysis, pitch)
  
  shimmer_local <- report$shimmer_local * 100  # Convert to %
  shimmer_local_db <- report$shimmer_local_db
  if (verbose) cat(sprintf("%.2f%%, %.2f dB\n", shimmer_local, shimmer_local_db))
  
  # 5-6. LTAS Slope and Tilt
  if (verbose) cat("Computing LTAS... ")
  ltas <- sound_analysis$to_ltas(bandwidth = 100)
  
  # Slope: regression 0-1000 Hz vs 1000-5000 Hz
  slope <- ltas$get_slope(
    low_band_min = 0,
    low_band_max = 1000,
    high_band_min = 1000,
    high_band_max = 5000,
    method = "energy"
  )
  
  # Tilt: H1-A3 approximation (F0 vs F3)
  # Get F0 for H1 estimation
  f0_mean <- pitch$get_mean(0, 0, "hertz")
  h1_freq <- f0_mean
  
  # Get F3 for A3 estimation
  formant <- sound_analysis$to_formant_burg(
    time_step = 0.005,
    max_number_of_formants = 5,
    maximum_formant = 5500,
    window_length = 0.025,
    pre_emphasis_from = 50
  )
  f3_mean <- formant$get_mean(3, 0, 0)
  a3_freq <- f3_mean
  
  # Tilt = H1 - A3 (in dB)
  h1_db <- ltas$get_value_at_frequency(h1_freq, "nearest")
  a3_db <- ltas$get_value_at_frequency(a3_freq, "nearest")
  tilt <- h1_db - a3_db
  
  if (verbose) cat(sprintf("Slope: %.2f dB, Tilt: %.2f dB\n", slope, tilt))
  
  list(
    cpps = cpps,
    hnr = hnr,
    shimmer_local = shimmer_local,
    shimmer_local_db = shimmer_local_db,
    slope = slope,
    tilt = tilt,
    duration = sound_analysis$get_total_duration(),
    f0_mean = f0_mean
  )
}

#' @keywords internal
.compute_avqi_speech <- function(sound, f0_min, f0_max, verbose = TRUE) {
  
  # Get duration
  duration <- sound$get_total_duration()
  if (verbose) cat(sprintf("Duration: %.2f s\n", duration))
  
  if (duration < 3.0) {
    warning("Speech duration < 3s. AVQI may be unreliable. Recommended: >10 seconds.")
  }
  
  # Voice Activity Detection - extract only voiced segments
  if (verbose) cat("Performing voice activity detection... ")
  voiced_sound <- extract_voiced_segments(
    sound,
    minimum_pitch = f0_min,
    time_step = 0.003,
    silence_threshold = -25,
    min_silent_interval = 0.1,
    min_sounding_interval = 0.1,
    return_textgrid = FALSE
  )
  
  if (is.null(voiced_sound)) {
    stop("No voiced segments detected in speech recording")
  }
  
  voiced_duration <- voiced_sound$get_total_duration()
  if (verbose) cat(sprintf("%.2f s voiced\n", voiced_duration))
  
  # Use voiced segments for analysis
  sound_analysis <- voiced_sound
  
  # Same measurements as vowel
  if (verbose) cat("Computing CPPS... ")
  cepstrogram <- sound_analysis$to_power_cepstrogram(
    pitch_floor = f0_min,
    time_step = 0.002,
    max_frequency = 5000,
    pre_emphasis_from = 50
  )
  cpps <- cepstrogram$get_cpps()
  if (verbose) cat(sprintf("%.2f dB\n", cpps))
  
  if (verbose) cat("Computing HNR... ")
  harmonicity <- sound_analysis$to_harmonicity_cc(
    time_step = 0.01,
    pitch_floor = f0_min,
    silence_threshold = 0.1,
    periods_per_window = 1.0
  )
  hnr <- harmonicity$get_mean(0, 0)
  if (verbose) cat(sprintf("%.2f dB\n", hnr))
  
  if (verbose) cat("Computing shimmer... ")
  pitch <- sound_analysis$to_pitch_cc(
    time_step = 0.0,
    pitch_floor = f0_min,
    pitch_ceiling = f0_max
  )
  pp <- sound_analysis$to_point_process_cc(pitch)
  report <- pp$voice_report(sound_analysis, pitch)
  
  shimmer_local <- report$shimmer_local * 100
  shimmer_local_db <- report$shimmer_local_db
  if (verbose) cat(sprintf("%.2f%%, %.2f dB\n", shimmer_local, shimmer_local_db))
  
  if (verbose) cat("Computing LTAS... ")
  ltas <- sound_analysis$to_ltas(bandwidth = 100)
  
  slope <- ltas$get_slope(
    low_band_min = 0,
    low_band_max = 1000,
    high_band_min = 1000,
    high_band_max = 5000,
    method = "energy"
  )
  
  f0_mean <- pitch$get_mean(0, 0, "hertz")
  formant <- sound_analysis$to_formant_burg(
    time_step = 0.005,
    max_number_of_formants = 5,
    maximum_formant = 5500,
    window_length = 0.025,
    pre_emphasis_from = 50
  )
  f3_mean <- formant$get_mean(3, 0, 0)
  
  h1_db <- ltas$get_value_at_frequency(f0_mean, "nearest")
  a3_db <- ltas$get_value_at_frequency(f3_mean, "nearest")
  tilt <- h1_db - a3_db
  
  if (verbose) cat(sprintf("Slope: %.2f dB, Tilt: %.2f dB\n", slope, tilt))
  
  list(
    cpps = cpps,
    hnr = hnr,
    shimmer_local = shimmer_local,
    shimmer_local_db = shimmer_local_db,
    slope = slope,
    tilt = tilt,
    duration = voiced_duration,
    original_duration = duration,
    f0_mean = f0_mean
  )
}

#' @export
print.avqi_result <- function(x, ...) {
  cat("AVQI Result\n")
  cat("===========\n\n")
  cat(sprintf("AVQI Score: %.3f\n", x$avqi))
  cat(sprintf("Interpretation: %s\n\n", 
              if (x$avqi < 2.95) "Normal voice quality" else "Dysphonic voice"))
  cat(sprintf("Recording Type: %s\n", x$type))
  cat(sprintf("Gender: %s\n", x$gender))
  cat(sprintf("F0 Range: %.0f - %.0f Hz\n\n", x$f0_range[1], x$f0_range[2]))
  
  cat("Components:\n")
  print(x$components)
  
  cat(sprintf("\nProtocol: %s\n", x$metadata$protocol))
  invisible(x)
}
