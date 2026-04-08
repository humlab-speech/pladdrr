# Basic Phonetic Analysis with speaker
# R implementation replacing praat_pitch.py, praat_formant_burg.py, praat_intensity.py

library(pladdrr)

# Example 1: Basic Pitch Extraction ==========================================
# Replaces: praat_pitch.py / praat_pitch_from_sound()

# Python equivalent:
# import parselmouth as pm
# sound = pm.Sound("audio.wav")
# pitch = pm.praat.call(sound, "To Pitch (cc)", ...)

# R implementation:
analyze_pitch <- function(audio_file, 
                          pitch_floor = 75, 
                          pitch_ceiling = 600,
                          time_step = 0.005) {
  
  # Load sound
  sound <- read_sound(audio_file)
  
  # Extract pitch (autocorrelation method)
  pitch <- extract_pitch(
    sound,
    time_step = time_step,
    pitch_floor = pitch_floor,
    pitch_ceiling = pitch_ceiling,
    max_candidates = 15,
    very_accurate = TRUE,
    silence_threshold = 0.03,
    voicing_threshold = 0.45,
    octave_cost = 0.01,
    octave_jump_cost = 0.35,
    voiced_unvoiced_cost = 0.14
  )
  
  # Get statistics
  mean_f0 <- get_mean_pitch(pitch, from_time = 0, to_time = 0, unit = "Hertz")
  median_f0 <- get_quantile_pitch(pitch, from_time = 0, to_time = 0, quantile = 0.5, unit = "Hertz")
  sd_f0 <- get_standard_deviation_pitch(pitch, from_time = 0, to_time = 0, unit = "Hertz")
  min_f0 <- get_minimum_pitch(pitch, from_time = 0, to_time = 0, unit = "Hertz", interpolate = FALSE)
  max_f0 <- get_maximum_pitch(pitch, from_time = 0, to_time = 0, unit = "Hertz", interpolate = FALSE)
  
  # Return summary
  list(
    pitch_object = pitch,
    statistics = data.frame(
      mean_f0 = mean_f0,
      median_f0 = median_f0,
      sd_f0 = sd_f0,
      min_f0 = min_f0,
      max_f0 = max_f0
    )
  )
}

# Example 2: Formant Extraction ===============================================
# Replaces: praat_formant_burg.py

# Python equivalent:
# formants = sound.to_formant_burg(...)
# table = pm.praat.call(formants, "Down to Table", ...)

# R implementation:
analyze_formants <- function(audio_file,
                            max_formant = 5500,
                            n_formants = 5,
                            gender = "female") {
  
  # Adjust ceiling by gender
  if (gender == "male") {
    max_formant <- 5000
  } else if (gender == "child") {
    max_formant <- 8000
  }
  
  # Load sound
  sound <- read_sound(audio_file)
  
  # Extract formants
  formants <- extract_formants(
    sound,
    time_step = 0.005,
    max_formant = max_formant,
    n_formants = n_formants,
    window_length = 0.025,
    pre_emphasis_from = 50
  )
  
  # Get formant values at specific times
  # (For continuous values, use as.data.frame)
  get_formant_values <- function(time) {
    f1 <- get_formant_at_time(formants, formant_number = 1, time = time)
    f2 <- get_formant_at_time(formants, formant_number = 2, time = time)
    f3 <- get_formant_at_time(formants, formant_number = 3, time = time)
    f4 <- get_formant_at_time(formants, formant_number = 4, time = time)
    f5 <- get_formant_at_time(formants, formant_number = 5, time = time)
    
    c(F1 = f1, F2 = f2, F3 = f3, F4 = f4, F5 = f5)
  }
  
  # Get statistics across time
  f1_mean <- get_mean_formant(formants, formant_number = 1, from_time = 0, to_time = 0)
  f2_mean <- get_mean_formant(formants, formant_number = 2, from_time = 0, to_time = 0)
  f3_mean <- get_mean_formant(formants, formant_number = 3, from_time = 0, to_time = 0)
  
  # Convert to data frame for time series
  formant_df <- as.data.frame(formants)
  
  list(
    formant_object = formants,
    formant_df = formant_df,
    mean_values = c(F1 = f1_mean, F2 = f2_mean, F3 = f3_mean),
    get_at_time = get_formant_values
  )
}

# Example 3: Intensity Extraction ============================================
# Replaces: praat_intensity.py

# Python equivalent:
# intensity = pm.praat.call(sound, "To Intensity", ...)
# tier = pm.praat.call(intensity, "Down to IntensityTier")

# R implementation:
analyze_intensity <- function(audio_file,
                             minimum_pitch = 100,
                             subtract_mean = TRUE) {
  
  # Load sound
  sound <- read_sound(audio_file)
  
  # Extract intensity
  intensity <- extract_intensity(
    sound,
    minimum_pitch = minimum_pitch,
    time_step = 0.0,  # Automatic
    subtract_mean = subtract_mean
  )
  
  # Get statistics
  mean_db <- get_mean_intensity(intensity, from_time = 0, to_time = 0)
  median_db <- get_quantile_intensity(intensity, from_time = 0, to_time = 0, quantile = 0.5)
  sd_db <- get_standard_deviation_intensity(intensity, from_time = 0, to_time = 0)
  min_db <- get_minimum_intensity(intensity, from_time = 0, to_time = 0, interpolate = FALSE)
  max_db <- get_maximum_intensity(intensity, from_time = 0, to_time = 0, interpolate = FALSE)
  
  # Convert to data frame
  intensity_df <- as.data.frame(intensity)
  
  list(
    intensity_object = intensity,
    intensity_df = intensity_df,
    statistics = data.frame(
      mean_db = mean_db,
      median_db = median_db,
      sd_db = sd_db,
      min_db = min_db,
      max_db = max_db
    )
  )
}

# Example 4: Complete Workflow ===============================================
# Combines all analyses (like Python scripts do)

complete_phonetic_analysis <- function(audio_file, 
                                      pitch_floor = 75,
                                      pitch_ceiling = 600,
                                      max_formant = 5500,
                                      gender = "female") {
  
  cat("Analyzing:", audio_file, "\n")
  
  # All analyses
  pitch_results <- analyze_pitch(audio_file, pitch_floor, pitch_ceiling)
  formant_results <- analyze_formants(audio_file, max_formant, gender = gender)
  intensity_results <- analyze_intensity(audio_file, minimum_pitch = pitch_floor)
  
  # Combine results
  results <- list(
    file = audio_file,
    pitch = pitch_results,
    formants = formant_results,
    intensity = intensity_results
  )
  
  # Print summary
  cat("\nPitch Summary:\n")
  print(pitch_results$statistics)
  
  cat("\nFormant Summary (F1-F3):\n")
  print(formant_results$mean_values[1:3])
  
  cat("\nIntensity Summary:\n")
  print(intensity_results$statistics)
  
  invisible(results)
}

# Example 5: Vowel Triangle Analysis =========================================
# Common phonetic task: plot F1 vs F2

vowel_space_analysis <- function(audio_file, 
                                 vowel_times,
                                 vowel_labels = NULL,
                                 max_formant = 5500) {
  
  # Load and extract formants
  sound <- read_sound(audio_file)
  formants <- extract_formants(sound, 
                               max_formant = max_formant,
                               n_formants = 5)
  
  # Extract F1 and F2 at each vowel timepoint
  f1_values <- sapply(vowel_times, function(t) {
    get_formant_at_time(formants, formant_number = 1, time = t)
  })
  
  f2_values <- sapply(vowel_times, function(t) {
    get_formant_at_time(formants, formant_number = 2, time = t)
  })
  
  # Create data frame
  vowel_data <- data.frame(
    time = vowel_times,
    F1 = f1_values,
    F2 = f2_values
  )
  
  if (!is.null(vowel_labels)) {
    vowel_data$vowel <- vowel_labels
  }
  
  # Plot vowel space (F1 vs F2, inverted axes as per phonetic convention)
  plot(vowel_data$F2, vowel_data$F1,
       xlim = rev(range(vowel_data$F2, na.rm = TRUE)),  # Reverse F2
       ylim = rev(range(vowel_data$F1, na.rm = TRUE)),  # Reverse F1
       xlab = "F2 (Hz)", ylab = "F1 (Hz)",
       main = "Vowel Space",
       pch = 19, col = "blue", cex = 1.5)
  
  if (!is.null(vowel_labels)) {
    text(vowel_data$F2, vowel_data$F1, vowel_labels, pos = 3, offset = 0.5)
  }
  
  grid()
  
  vowel_data
}

# Usage Examples ==============================================================

if (FALSE) {  # Don't run automatically
  
  # Basic pitch analysis
  pitch_results <- analyze_pitch("speech.wav", pitch_floor = 75, pitch_ceiling = 600)
  
  # Formant analysis
  formant_results <- analyze_formants("speech.wav", gender = "female")
  
  # Intensity analysis  
  intensity_results <- analyze_intensity("speech.wav")
  
  # Complete analysis
  all_results <- complete_phonetic_analysis(
    "speech.wav",
    pitch_floor = 75,
    pitch_ceiling = 600,
    max_formant = 5500,
    gender = "female"
  )
  
  # Vowel space
  vowel_times <- c(0.5, 1.0, 1.5, 2.0)  # Times where vowels occur
  vowel_labels <- c("i", "e", "a", "o")
  vowel_data <- vowel_space_analysis("speech.wav", vowel_times, vowel_labels)
  
  # Plot time series
  formant_df <- as.data.frame(all_results$formants$formant_object)
  plot(formant_df$time, formant_df$F1, type = "l", 
       xlab = "Time (s)", ylab = "F1 (Hz)",
       main = "F1 Trajectory")
  lines(formant_df$time, formant_df$F2, col = "red")
  legend("topright", legend = c("F1", "F2"), col = c("black", "red"), lty = 1)
}

# Note: All examples above directly replace Python Parselmouth code
# with pure R implementations using the speaker package.
