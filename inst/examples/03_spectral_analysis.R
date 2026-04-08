# Spectral Analysis with speaker
# R implementation to replace praat_spectral_moments.py

library(pladdrr)

# NOTE: This example shows the INTENDED API for spectral analysis.
# spectral_moments() function is planned for Phase 2.5 implementation.

# PLANNED FUNCTION: spectral_moments() ========================================
# Will replace: praat_spectral_moments.py (116 lines)

# Python equivalent:
# moments = praat_spectral_moments(sound, windowLength=0.005, 
#                                  time_step=0.005, power=2.0)
# Returns: DataFrame with time, CenterOfGravity, SD, Skewness, Kurtosis

# PLANNED R implementation (Phase 2.5):
if (FALSE) {
  
  spectral_moments <- function(sound,
                              from_time = 0,
                              to_time = 0,
                              window_length = 0.005,
                              time_step = 0.005,
                              maximum_frequency = 0,  # 0 = Nyquist
                              frequency_step = 20,
                              power = 2.0) {
    
    # Validate inputs
    validate_praat_sound(sound)
    
    # Get sampling frequency
    sr <- sound$sampling_frequency
    
    # Set maximum frequency to Nyquist if not specified
    if (maximum_frequency == 0) {
      maximum_frequency <- sr / 2
    }
    
    # NEW: Create spectrogram - TO IMPLEMENT
    spectrogram <- extract_spectrogram(
      sound,
      window_length = window_length,
      maximum_frequency = maximum_frequency,
      time_step = time_step,
      frequency_step = frequency_step,
      window_shape = "Gaussian"
    )
    
    # Get number of frames
    n_frames <- spectrogram$nx
    
    # Initialize output
    times <- numeric(n_frames)
    cog_values <- numeric(n_frames)
    sd_values <- numeric(n_frames)
    skew_values <- numeric(n_frames)
    kurt_values <- numeric(n_frames)
    
    # Process each frame
    for (i in 1:n_frames) {
      # Get time for this frame
      times[i] <- get_time_from_frame(spectrogram, frame = i)
      
      # NEW: Extract spectrum slice - TO IMPLEMENT
      spectrum <- extract_spectrum_slice(spectrogram, time = times[i])
      
      # NEW: Compute spectral moments - TO IMPLEMENT
      cog_values[i] <- get_center_of_gravity(spectrum, power = power)
      sd_values[i] <- get_spectral_standard_deviation(spectrum, power = power)
      skew_values[i] <- get_spectral_skewness(spectrum, power = power)
      kurt_values[i] <- get_spectral_kurtosis(spectrum, power = power)
    }
    
    # Return as data frame
    data.frame(
      time = times,
      center_of_gravity = cog_values,
      standard_deviation = sd_values,
      skewness = skew_values,
      kurtosis = kurt_values
    )
  }
  
  # Usage:
  sound <- read_sound("speech.wav")
  moments <- spectral_moments(sound, 
                             window_length = 0.005,
                             time_step = 0.005,
                             power = 2.0)
  
  # Plot spectral evolution
  plot(moments$time, moments$center_of_gravity,
       type = "l", col = "blue",
       xlab = "Time (s)", ylab = "Center of Gravity (Hz)",
       main = "Spectral Center of Gravity")
}

# CURRENT WORKAROUND: Manual Spectral Analysis ================================
# Using formants as a proxy for spectral characteristics

approximate_spectral_center <- function(audio_file,
                                       max_formant = 5500,
                                       n_formants = 5) {
  
  # Load sound
  sound <- read_sound(audio_file)
  
  # Extract formants (peaks in spectrum)
  formants <- extract_formants(sound, 
                              max_formant = max_formant,
                              n_formants = n_formants)
  
  # Convert to data frame
  formant_df <- as.data.frame(formants)
  
  # Approximate center of gravity as weighted mean of formants
  # (This is a rough approximation - real COG considers full spectrum)
  compute_weighted_mean <- function(row) {
    # Extract formant frequencies and bandwidths
    freqs <- c(row$F1, row$F2, row$F3, row$F4, row$F5)
    bws <- c(row$B1, row$B2, row$B3, row$B4, row$B5)
    
    # Remove NAs
    valid <- !is.na(freqs) & !is.na(bws)
    freqs <- freqs[valid]
    bws <- bws[valid]
    
    if (length(freqs) == 0) return(NA)
    
    # Weight by inverse of bandwidth (narrower = more prominent)
    weights <- 1 / (bws + 1)  # Add 1 to avoid division by zero
    
    weighted.mean(freqs, weights)
  }
  
  # Compute for each time frame
  formant_df$approx_cog <- apply(formant_df, 1, compute_weighted_mean)
  
  # Compute spectral spread (standard deviation)
  compute_spread <- function(row) {
    freqs <- c(row$F1, row$F2, row$F3, row$F4, row$F5)
    freqs <- freqs[!is.na(freqs)]
    if (length(freqs) < 2) return(NA)
    sd(freqs)
  }
  
  formant_df$approx_spread <- apply(formant_df, 1, compute_spread)
  
  formant_df
}

# VISUALIZATION: Spectral Evolution ===========================================

plot_spectral_evolution <- function(audio_file,
                                   max_formant = 5500,
                                   n_formants = 5) {
  
  # Get approximation using formants
  spectral_data <- approximate_spectral_center(audio_file, max_formant, n_formants)
  
  # Create multi-panel plot
  par(mfrow = c(2, 1), mar = c(4, 4, 2, 1))
  
  # Panel 1: Approximate center of gravity
  plot(spectral_data$time, spectral_data$approx_cog,
       type = "l", col = "purple", lwd = 2,
       xlab = "Time (s)", ylab = "Frequency (Hz)",
       main = "Approximate Spectral Center (from formants)")
  grid()
  
  # Panel 2: Spectral spread
  plot(spectral_data$time, spectral_data$approx_spread,
       type = "l", col = "orange", lwd = 2,
       xlab = "Time (s)", ylab = "Spread (Hz)",
       main = "Spectral Spread")
  grid()
  
  par(mfrow = c(1, 1))
  
  invisible(spectral_data)
}

# ACOUSTIC ANALYSIS: Fricative Analysis =======================================
# Spectral moments are particularly useful for fricative consonants

analyze_fricative <- function(audio_file,
                              fricative_start,
                              fricative_end,
                              window_length = 0.005) {
  
  cat("Analyzing fricative from", fricative_start, "to", fricative_end, "seconds\n")
  
  # Load sound
  sound <- read_sound(audio_file)
  
  # Extract just the fricative portion
  duration <- fricative_end - fricative_start
  
  # Get intensity (proxy for frication noise level)
  intensity <- extract_intensity(sound, minimum_pitch = 100)
  intensity_df <- as.data.frame(intensity)
  
  # Filter to fricative region
  fric_intensity <- intensity_df[
    intensity_df$time >= fricative_start & 
      intensity_df$time <= fricative_end, 
  ]
  
  # Get formants in fricative region (will capture spectral peaks)
  formants <- extract_formants(sound, 
                              max_formant = 11000,  # Higher for fricatives
                              n_formants = 5,
                              window_length = window_length)
  formant_df <- as.data.frame(formants)
  
  # Filter to fricative region
  fric_formants <- formant_df[
    formant_df$time >= fricative_start & 
      formant_df$time <= fricative_end,
  ]
  
  # Compute statistics
  mean_intensity <- mean(fric_intensity$intensity, na.rm = TRUE)
  
  # Spectral peak (highest formant with energy)
  mean_f3 <- mean(fric_formants$F3, na.rm = TRUE)
  mean_f4 <- mean(fric_formants$F4, na.rm = TRUE)
  mean_f5 <- mean(fric_formants$F5, na.rm = TRUE)
  
  # Approximate spectral mean
  spectral_peaks <- c(mean_f3, mean_f4, mean_f5)
  spectral_peaks <- spectral_peaks[!is.na(spectral_peaks)]
  spectral_mean <- mean(spectral_peaks)
  
  list(
    duration = duration,
    mean_intensity_db = mean_intensity,
    spectral_mean_hz = spectral_mean,
    f3_mean = mean_f3,
    f4_mean = mean_f4,
    f5_mean = mean_f5,
    data = list(
      intensity = fric_intensity,
      formants = fric_formants
    )
  )
}

# COMPARISON: Sibilant Contrast ===============================================
# Compare /s/ vs /sh/ using spectral characteristics

compare_sibilants <- function(audio_file,
                              s_start, s_end,
                              sh_start, sh_end) {
  
  cat("Comparing sibilants...\n")
  
  # Analyze /s/ (high spectral peak ~8000 Hz)
  s_analysis <- analyze_fricative(audio_file, s_start, s_end)
  
  # Analyze /sh/ (lower spectral peak ~4000 Hz)
  sh_analysis <- analyze_fricative(audio_file, sh_start, sh_end)
  
  # Create comparison
  comparison <- data.frame(
    fricative = c("/s/", "/ʃ/"),
    spectral_mean = c(s_analysis$spectral_mean_hz, sh_analysis$spectral_mean_hz),
    intensity = c(s_analysis$mean_intensity_db, sh_analysis$mean_intensity_db),
    f3 = c(s_analysis$f3_mean, sh_analysis$f3_mean),
    f4 = c(s_analysis$f4_mean, sh_analysis$f4_mean),
    f5 = c(s_analysis$f5_mean, sh_analysis$f5_mean)
  )
  
  print(comparison)
  
  # Visualize
  barplot(comparison$spectral_mean,
          names.arg = comparison$fricative,
          ylab = "Spectral Mean (Hz)",
          main = "Sibilant Contrast",
          col = c("lightblue", "lightgreen"))
  grid()
  
  invisible(list(s = s_analysis, sh = sh_analysis, comparison = comparison))
}

# ADVANCED: Spectral Tilt Analysis ============================================
# Measure spectral slope (energy distribution across frequencies)

estimate_spectral_tilt <- function(audio_file,
                                  from_time = 0,
                                  to_time = 0,
                                  max_formant = 5500) {
  
  # Load sound
  sound <- read_sound(audio_file)
  
  # Extract formants with bandwidths
  formants <- extract_formants(sound, 
                              max_formant = max_formant,
                              n_formants = 5)
  formant_df <- as.data.frame(formants)
  
  # Filter time range if specified
  if (from_time > 0 || to_time > 0) {
    if (to_time == 0) to_time <- max(formant_df$time)
    formant_df <- formant_df[
      formant_df$time >= from_time & formant_df$time <= to_time,
    ]
  }
  
  # Estimate tilt from formant amplitudes (approximation)
  # Lower formants typically have more energy than higher formants
  # Tilt = difference in energy between low and high formants
  
  # Approximate using bandwidth (wider = less energy)
  compute_tilt <- function(row) {
    bws <- c(row$B1, row$B2, row$B3, row$B4, row$B5)
    bws <- bws[!is.na(bws)]
    if (length(bws) < 3) return(NA)
    
    # Lower formants should have narrower bandwidths (more energy)
    # Compute slope of bandwidth increase
    lm_result <- lm(bws ~ seq_along(bws))
    coef(lm_result)[2]  # Slope
  }
  
  formant_df$tilt_estimate <- apply(formant_df, 1, compute_tilt)
  
  # Summary
  mean_tilt <- mean(formant_df$tilt_estimate, na.rm = TRUE)
  sd_tilt <- sd(formant_df$tilt_estimate, na.rm = TRUE)
  
  list(
    mean_tilt = mean_tilt,
    sd_tilt = sd_tilt,
    data = formant_df
  )
}

# Usage Examples ==============================================================

if (FALSE) {  # Don't run automatically
  
  # Approximate spectral analysis using formants
  spectral_data <- approximate_spectral_center("speech.wav", max_formant = 5500)
  
  # Visualize spectral evolution
  plot_spectral_evolution("speech.wav", max_formant = 5500)
  
  # Analyze a fricative
  fricative_analysis <- analyze_fricative("speech.wav", 
                                         fricative_start = 0.5,
                                         fricative_end = 0.65)
  print(fricative_analysis)
  
  # Compare sibilants
  sibilant_comparison <- compare_sibilants("speech.wav",
                                          s_start = 0.5, s_end = 0.65,
                                          sh_start = 1.2, sh_end = 1.35)
  
  # Spectral tilt
  tilt_analysis <- estimate_spectral_tilt("speech.wav", from_time = 0, to_time = 0)
  print(paste("Mean spectral tilt:", round(tilt_analysis$mean_tilt, 2)))
}

# Note: Full spectral_moments() function will be implemented in Phase 2.5
# with proper spectrogram and spectrum extraction.
# The approximations above use formants as a proxy for spectral characteristics.
