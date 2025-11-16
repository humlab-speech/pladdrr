# End-to-End Pipeline Benchmarks
# Target: 2-4x speedup with SIMD
# Complete phonetic analysis workflows

library(speaker)
library(bench)

cat("\n=== End-to-End Pipeline Benchmarks ===\n")
cat("Target speedup: 2-4x for complete workflows\n\n")

# Test sound: realistic speech-like signal
create_speech_like_sound <- function(duration = 2.0, sample_rate = 16000) {
  n_samples <- duration * sample_rate
  t <- seq(0, duration, length.out = n_samples)
  
  # Varying F0 (100-200 Hz)
  f0 <- 150 + 50 * sin(2 * pi * t / duration)
  
  # Voiced segments with formants
  signal <- sin(2 * pi * cumsum(f0 / sample_rate))  # Fundamental
  signal <- signal + 0.4 * sin(2 * pi * cumsum((f0 * 2) / sample_rate))  # H2
  signal <- signal + 0.2 * sin(2 * pi * cumsum((f0 * 3) / sample_rate))  # H3
  
  # Add formant resonances
  for (formant in c(700, 1220, 2600)) {
    signal <- signal + 0.2 * sin(2 * pi * formant * t) * exp(-abs(t - duration/2) * 2)
  }
  
  # Add noise for voiceless segments
  signal <- signal + 0.1 * rnorm(n_samples)
  
  # Normalize
  signal <- signal / max(abs(signal)) * 0.95
  
  Sound$new_from_values(
    values = matrix(signal, nrow = 1),
    sampling_rate = sample_rate
  )
}

# =============================================================================
# Pipeline 1: Vowel Analysis
# Operations: Formant extraction + Intensity + Duration
# =============================================================================

cat("\n--- Pipeline 1: Vowel Analysis ---\n")

sound_vowel <- create_speech_like_sound(duration = 2.0)

bm_vowel_analysis <- bench::mark(
  vowel_analysis_pipeline = {
    # Extract formants
    formant <- sound_vowel$to_formant_burg(
      time_step = 0.01,
      max_number_of_formants = 5,
      maximum_formant = 5500,
      window_length = 0.025,
      pre_emphasis_from = 50
    )
    
    # Extract intensity
    intensity <- sound_vowel$to_intensity(
      minimum_pitch = 75,
      time_step = 0.01
    )
    
    # Get measurements (would normally be extracted at vowel nuclei)
    f1 <- formant$get_mean(formant_number = 1, from_time = 0.5, to_time = 1.5, unit = "hertz")
    f2 <- formant$get_mean(formant_number = 2, from_time = 0.5, to_time = 1.5, unit = "hertz")
    int_mean <- intensity$get_mean(from_time = 0.5, to_time = 1.5)
    
    # Cleanup
    rm(formant, intensity, f1, f2, int_mean)
    gc(verbose = FALSE)
  },
  iterations = 10,
  check = FALSE
)

cat(sprintf("Vowel analysis: %s\n", format(bm_vowel_analysis$median)))

# =============================================================================
# Pipeline 2: Prosody Analysis
# Operations: F0 + Intensity + Duration + Spectrogram
# =============================================================================

cat("\n--- Pipeline 2: Prosody Analysis ---\n")

sound_prosody <- create_speech_like_sound(duration = 5.0)

bm_prosody_analysis <- bench::mark(
  prosody_pipeline = {
    # Extract pitch
    pitch <- sound_prosody$to_pitch(
      time_step = 0.01,
      pitch_floor = 75,
      pitch_ceiling = 600
    )
    
    # Extract intensity
    intensity <- sound_prosody$to_intensity(
      minimum_pitch = 75,
      time_step = 0.01
    )
    
    # Create spectrogram for visualization
    spectrogram <- sound_prosody$to_spectrogram(
      window_length = 0.005,
      max_frequency = 5000,
      time_step = 0.002,
      frequency_step = 20,
      window_shape = "Gaussian"
    )
    
    # Get measurements
    f0_mean <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")
    f0_std <- pitch$get_standard_deviation(from_time = 0, to_time = 0, unit = "hertz")
    int_mean <- intensity$get_mean(from_time = 0, to_time = 0)
    
    # Cleanup
    rm(pitch, intensity, spectrogram, f0_mean, f0_std, int_mean)
    gc(verbose = FALSE)
  },
  iterations = 5,
  check = FALSE
)

cat(sprintf("Prosody analysis: %s\n", format(bm_prosody_analysis$median)))

# =============================================================================
# Pipeline 3: Voice Quality Analysis
# Operations: Harmonicity + Jitter + Shimmer + PointProcess
# =============================================================================

cat("\n--- Pipeline 3: Voice Quality ---\n")

sound_voice <- create_speech_like_sound(duration = 3.0)

bm_voice_quality <- bench::mark(
  voice_quality_pipeline = {
    # Extract harmonicity (HNR)
    harmonicity <- sound_voice$to_harmonicity_cc(
      time_step = 0.01,
      minimum_pitch = 75,
      silence_threshold = 0.1,
      periods_per_window = 1.0
    )
    
    # Extract point process (for jitter/shimmer)
    point_process <- sound_voice$to_point_process_periodic_cc(
      minimum_pitch = 75,
      maximum_pitch = 600
    )
    
    # Extract pitch for voicing detection
    pitch <- sound_voice$to_pitch(
      time_step = 0.01,
      pitch_floor = 75,
      pitch_ceiling = 600
    )
    
    # Get measurements
    hnr_mean <- harmonicity$get_mean(from_time = 0, to_time = 0)
    n_pulses <- point_process$get_number_of_points()
    
    # Cleanup
    rm(harmonicity, point_process, pitch, hnr_mean, n_pulses)
    gc(verbose = FALSE)
  },
  iterations = 10,
  check = FALSE
)

cat(sprintf("Voice quality: %s\n", format(bm_voice_quality$median)))

# =============================================================================
# Pipeline 4: Complete Phonetic Analysis
# Operations: Everything combined
# =============================================================================

cat("\n--- Pipeline 4: Complete Analysis ---\n")

sound_complete <- create_speech_like_sound(duration = 3.0)

bm_complete_analysis <- bench::mark(
  complete_pipeline = {
    # Acoustic analysis
    pitch <- sound_complete$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
    formant <- sound_complete$to_formant_burg(
      time_step = 0.01, max_number_of_formants = 5, maximum_formant = 5500,
      window_length = 0.025, pre_emphasis_from = 50
    )
    intensity <- sound_complete$to_intensity(minimum_pitch = 75, time_step = 0.01)
    harmonicity <- sound_complete$to_harmonicity_cc(
      time_step = 0.01, minimum_pitch = 75, silence_threshold = 0.1, periods_per_window = 1.0
    )
    
    # Spectral analysis
    spectrum <- sound_complete$to_spectrum(fast = TRUE)
    ltas <- sound_complete$to_ltas(bandwidth = 100)
    
    # Extract measurements
    measurements <- list(
      f0_mean = pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz"),
      f1_mean = formant$get_mean(formant_number = 1, from_time = 0, to_time = 0, unit = "hertz"),
      f2_mean = formant$get_mean(formant_number = 2, from_time = 0, to_time = 0, unit = "hertz"),
      intensity_mean = intensity$get_mean(from_time = 0, to_time = 0),
      hnr_mean = harmonicity$get_mean(from_time = 0, to_time = 0)
    )
    
    # Cleanup
    rm(pitch, formant, intensity, harmonicity, spectrum, ltas, measurements)
    gc(verbose = FALSE)
  },
  iterations = 5,
  check = FALSE
)

cat(sprintf("Complete analysis: %s\n", format(bm_complete_analysis$median)))

# =============================================================================
# Results Summary
# =============================================================================

results <- list(
  vowel_analysis = bm_vowel_analysis,
  prosody_analysis = bm_prosody_analysis,
  voice_quality = bm_voice_quality,
  complete_analysis = bm_complete_analysis
)

summary_df <- data.frame(
  pipeline = c("Vowel", "Prosody", "Voice Quality", "Complete"),
  median_time = c(
    as.numeric(bm_vowel_analysis$median),
    as.numeric(bm_prosody_analysis$median),
    as.numeric(bm_voice_quality$median),
    as.numeric(bm_complete_analysis$median)
  ),
  mem_alloc = c(
    as.numeric(bm_vowel_analysis$mem_alloc),
    as.numeric(bm_prosody_analysis$mem_alloc),
    as.numeric(bm_voice_quality$mem_alloc),
    as.numeric(bm_complete_analysis$mem_alloc)
  ),
  stringsAsFactors = FALSE
)

cat("\n=== Pipeline Summary ===\n")
print(summary_df)

# Save results
timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
output_file <- sprintf("results/baseline/11_end_to_end_pipelines_%s.rds", timestamp)

results_package <- list(
  metadata = list(
    date = Sys.time(),
    package_version = as.character(packageVersion("speaker")),
    r_version = R.version.string,
    platform = R.version$platform,
    simd_enabled = FALSE
  ),
  benchmarks = results,
  summary = summary_df
)

dir.create("results/baseline", showWarnings = FALSE, recursive = TRUE)
saveRDS(results_package, output_file)

cat(sprintf("\nResults saved to: %s\n", output_file))
cat("\nThese pipelines combine multiple SIMD-optimized operations\n")
cat("Expected overall speedup: 2-4x when all Phase 1-3 optimizations are applied\n")
