# Voice Quality Analysis with speaker
# R implementation to replace praat_voice_report_memory.py

library(speaker)

# NOTE: This example shows the INTENDED API for voice quality analysis.
# These functions are planned for Phase 2.5 implementation.
# Currently, basic measures can be computed manually as shown below.

# PLANNED FUNCTION: voice_report() ============================================
# Will replace: praat_voice_report_memory.py (305 lines)

# Python equivalent:
# result = praat_voice_report_memory(audio_np, sample_rate, 
#                                    min_f0=75, max_f0=600)
# Returns: dict with jitter, shimmer, HNR, NHR, voice breaks, etc.

# PLANNED R implementation (Phase 2.5):
if (FALSE) {
  
  voice_report <- function(sound,
                          pitch_floor = 75,
                          pitch_ceiling = 600,
                          from_time = 0,
                          to_time = 0,
                          max_period_factor = 1.3,
                          max_amplitude_factor = 1.6,
                          silence_threshold = 0.03,
                          voicing_threshold = 0.45) {
    
    # Extract pitch (already implemented)
    pitch <- extract_pitch(sound, 
                          pitch_floor = pitch_floor,
                          pitch_ceiling = pitch_ceiling,
                          silence_threshold = silence_threshold,
                          voicing_threshold = voicing_threshold)
    
    # NEW: Extract point process (pitch marks) - TO IMPLEMENT
    point_process <- extract_point_process(sound, 
                                          pitch_floor = pitch_floor,
                                          pitch_ceiling = pitch_ceiling)
    
    # NEW: Extract harmonicity (HNR/NHR) - TO IMPLEMENT
    harmonicity <- extract_harmonicity(sound,
                                      time_step = 0.01,
                                      pitch_floor = pitch_floor,
                                      silence_threshold = silence_threshold,
                                      periods_per_window = 1.0)
    
    # Get pitch statistics (already works)
    median_pitch <- get_quantile_pitch(pitch, quantile = 0.5)
    mean_pitch <- get_mean_pitch(pitch)
    sd_pitch <- get_standard_deviation_pitch(pitch)
    min_pitch <- get_minimum_pitch(pitch, interpolate = FALSE)
    max_pitch <- get_maximum_pitch(pitch, interpolate = FALSE)
    
    # NEW: Jitter measures - TO IMPLEMENT
    jitter_local <- get_jitter_local(point_process, 
                                     from_time = from_time,
                                     to_time = to_time,
                                     period_floor = 1/pitch_ceiling,
                                     period_ceiling = 1/pitch_floor,
                                     max_period_factor = max_period_factor)
    
    jitter_local_abs <- get_jitter_local_absolute(point_process,
                                                  from_time = from_time,
                                                  to_time = to_time)
    
    jitter_rap <- get_jitter_rap(point_process,
                                 from_time = from_time,
                                 to_time = to_time)
    
    jitter_ppq5 <- get_jitter_ppq5(point_process,
                                   from_time = from_time,
                                   to_time = to_time)
    
    jitter_ddp <- get_jitter_ddp(point_process,
                                 from_time = from_time,
                                 to_time = to_time)
    
    # NEW: Shimmer measures - TO IMPLEMENT
    shimmer_local <- get_shimmer_local(sound, point_process,
                                       from_time = from_time,
                                       to_time = to_time,
                                       max_amplitude_factor = max_amplitude_factor)
    
    shimmer_local_db <- get_shimmer_local_db(sound, point_process,
                                             from_time = from_time,
                                             to_time = to_time)
    
    shimmer_apq3 <- get_shimmer_apq3(sound, point_process,
                                     from_time = from_time,
                                     to_time = to_time)
    
    shimmer_apq5 <- get_shimmer_apq5(sound, point_process,
                                     from_time = from_time,
                                     to_time = to_time)
    
    shimmer_apq11 <- get_shimmer_apq11(sound, point_process,
                                       from_time = from_time,
                                       to_time = to_time)
    
    shimmer_dda <- get_shimmer_dda(sound, point_process,
                                   from_time = from_time,
                                   to_time = to_time)
    
    # NEW: Harmonicity measures - TO IMPLEMENT
    mean_hnr <- get_mean_harmonicity(harmonicity,
                                     from_time = from_time,
                                     to_time = to_time)
    
    mean_nhr <- hnr_to_nhr(mean_hnr)  # Helper conversion
    mean_autocorr <- hnr_to_autocorrelation(mean_hnr)  # Helper conversion
    
    # NEW: Voice breaks - TO IMPLEMENT  
    num_breaks <- count_voice_breaks(pitch,
                                     from_time = from_time,
                                     to_time = to_time)
    
    degree_breaks <- get_degree_voice_breaks(pitch,
                                             from_time = from_time,
                                             to_time = to_time)
    
    # NEW: Pulses and periods - TO IMPLEMENT
    num_pulses <- get_number_of_pulses(point_process,
                                       from_time = from_time,
                                       to_time = to_time)
    
    num_periods <- get_number_of_periods(point_process,
                                         from_time = from_time,
                                         to_time = to_time)
    
    mean_period <- get_mean_period(point_process,
                                   from_time = from_time,
                                   to_time = to_time)
    
    # NEW: Unvoiced frames - TO IMPLEMENT
    frac_unvoiced <- get_fraction_unvoiced_frames(pitch,
                                                  from_time = from_time,
                                                  to_time = to_time)
    
    # Combine into comprehensive report
    data.frame(
      # Pitch measures
      median_pitch = median_pitch,
      mean_pitch = mean_pitch,
      sd_pitch = sd_pitch,
      min_pitch = min_pitch,
      max_pitch = max_pitch,
      
      # Pulse/period measures
      num_pulses = num_pulses,
      num_periods = num_periods,
      mean_period = mean_period,
      
      # Voicing measures
      frac_unvoiced = frac_unvoiced,
      num_breaks = num_breaks,
      degree_breaks = degree_breaks,
      
      # Jitter measures (%)
      jitter_local = jitter_local,
      jitter_local_abs = jitter_local_abs,
      jitter_rap = jitter_rap,
      jitter_ppq5 = jitter_ppq5,
      jitter_ddp = jitter_ddp,
      
      # Shimmer measures (%)
      shimmer_local = shimmer_local,
      shimmer_local_db = shimmer_local_db,
      shimmer_apq3 = shimmer_apq3,
      shimmer_apq5 = shimmer_apq5,
      shimmer_apq11 = shimmer_apq11,
      shimmer_dda = shimmer_dda,
      
      # Harmonicity measures
      mean_hnr = mean_hnr,
      mean_nhr = mean_nhr,
      mean_autocorr = mean_autocorr
    )
  }
  
  # Usage:
  sound <- read_sound("speech.wav")
  report <- voice_report(sound, pitch_floor = 75, pitch_ceiling = 600)
  print(report)
}

# CURRENT WORKAROUND: Manual Computation ======================================
# Until voice_report() is implemented, you can compute some measures manually

basic_voice_quality <- function(audio_file,
                                pitch_floor = 75,
                                pitch_ceiling = 600) {
  
  # Load sound
  sound <- read_sound(audio_file)
  
  # Extract pitch
  pitch <- extract_pitch(sound, 
                        pitch_floor = pitch_floor,
                        pitch_ceiling = pitch_ceiling)
  
  # Get pitch statistics (already implemented)
  median_f0 <- get_quantile_pitch(pitch, quantile = 0.5, unit = "Hertz")
  mean_f0 <- get_mean_pitch(pitch, unit = "Hertz")
  sd_f0 <- get_standard_deviation_pitch(pitch, unit = "Hertz")
  min_f0 <- get_minimum_pitch(pitch, interpolate = FALSE, unit = "Hertz")
  max_f0 <- get_maximum_pitch(pitch, interpolate = FALSE, unit = "Hertz")
  
  # Pitch range
  pitch_range <- max_f0 - min_f0
  
  # Convert to semitones for perceptual measure
  if (!is.na(max_f0) && !is.na(min_f0) && min_f0 > 0) {
    pitch_range_st <- 12 * log2(max_f0 / min_f0)
  } else {
    pitch_range_st <- NA
  }
  
  # Extract intensity
  intensity <- extract_intensity(sound, minimum_pitch = pitch_floor)
  mean_db <- get_mean_intensity(intensity)
  sd_db <- get_standard_deviation_intensity(intensity)
  
  # Create summary
  data.frame(
    median_f0 = median_f0,
    mean_f0 = mean_f0,
    sd_f0 = sd_f0,
    min_f0 = min_f0,
    max_f0 = max_f0,
    pitch_range_hz = pitch_range,
    pitch_range_st = pitch_range_st,
    mean_intensity_db = mean_db,
    sd_intensity_db = sd_db
  )
}

# ADVANCED: Compare Multiple Speakers =========================================

compare_speakers <- function(audio_files, 
                            speaker_labels = NULL,
                            pitch_floor = 75,
                            pitch_ceiling = 600) {
  
  if (is.null(speaker_labels)) {
    speaker_labels <- basename(audio_files)
  }
  
  # Analyze each file
  results_list <- lapply(audio_files, function(f) {
    basic_voice_quality(f, pitch_floor, pitch_ceiling)
  })
  
  # Combine
  results_df <- do.call(rbind, results_list)
  results_df$speaker <- speaker_labels
  
  # Reorder columns
  results_df <- results_df[, c("speaker", setdiff(names(results_df), "speaker"))]
  
  results_df
}

# VISUALIZATION: Voice Quality Dashboard ======================================

plot_voice_profile <- function(audio_file,
                               pitch_floor = 75,
                               pitch_ceiling = 600,
                               max_formant = 5500) {
  
  # Load sound
  sound <- read_sound(audio_file)
  
  # Extract all measures
  pitch <- extract_pitch(sound, pitch_floor = pitch_floor, pitch_ceiling = pitch_ceiling)
  formants <- extract_formants(sound, max_formant = max_formant, n_formants = 5)
  intensity <- extract_intensity(sound, minimum_pitch = pitch_floor)
  
  # Convert to data frames
  pitch_df <- as.data.frame(pitch)
  formant_df <- as.data.frame(formants)
  intensity_df <- as.data.frame(intensity)
  
  # Create multi-panel plot
  par(mfrow = c(2, 2), mar = c(4, 4, 2, 1))
  
  # Panel 1: Pitch contour
  plot(pitch_df$time, pitch_df$frequency, 
       type = "l", col = "blue", lwd = 2,
       xlab = "Time (s)", ylab = "F0 (Hz)",
       main = "Pitch Contour")
  grid()
  
  # Panel 2: Formants F1-F3
  plot(formant_df$time, formant_df$F1, 
       type = "l", col = "red", lwd = 2,
       xlab = "Time (s)", ylab = "Frequency (Hz)",
       main = "Formant Trajectories",
       ylim = c(0, 3000))
  lines(formant_df$time, formant_df$F2, col = "green", lwd = 2)
  lines(formant_df$time, formant_df$F3, col = "blue", lwd = 2)
  legend("topright", legend = c("F1", "F2", "F3"), 
         col = c("red", "green", "blue"), lty = 1, lwd = 2)
  grid()
  
  # Panel 3: Intensity contour
  plot(intensity_df$time, intensity_df$intensity, 
       type = "l", col = "darkgreen", lwd = 2,
       xlab = "Time (s)", ylab = "Intensity (dB)",
       main = "Intensity Contour")
  grid()
  
  # Panel 4: Pitch histogram
  hist(pitch_df$frequency[!is.na(pitch_df$frequency)], 
       breaks = 30, col = "lightblue",
       xlab = "F0 (Hz)", main = "Pitch Distribution")
  abline(v = mean(pitch_df$frequency, na.rm = TRUE), 
         col = "red", lwd = 2, lty = 2)
  grid()
  
  par(mfrow = c(1, 1))  # Reset
  
  invisible(list(pitch = pitch_df, formants = formant_df, intensity = intensity_df))
}

# Usage Examples ==============================================================

if (FALSE) {  # Don't run automatically
  
  # Basic voice quality
  quality <- basic_voice_quality("speech.wav", pitch_floor = 75, pitch_ceiling = 600)
  print(quality)
  
  # Compare multiple speakers
  files <- c("speaker1.wav", "speaker2.wav", "speaker3.wav")
  labels <- c("Speaker A", "Speaker B", "Speaker C")
  comparison <- compare_speakers(files, labels, pitch_floor = 75, pitch_ceiling = 600)
  print(comparison)
  
  # Voice profile visualization
  profile_data <- plot_voice_profile("speech.wav", 
                                     pitch_floor = 75, 
                                     pitch_ceiling = 600,
                                     max_formant = 5500)
}

# Note: Full voice_report() with jitter, shimmer, and HNR will be implemented
# in Phase 2.5. The functions shown above provide the intended API.
