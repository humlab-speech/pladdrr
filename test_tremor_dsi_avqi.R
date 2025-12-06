#!/usr/bin/env Rscript

# Test script for pladdrr 1.1.0 fixes
# Tests: voice_report, TextGrid creation, interval extraction, and tremor support

cat("=================================================================\n")
cat("pladdrr 1.1.0 - Testing Critical Fixes\n")
cat("=================================================================\n\n")

library(pladdrr)

# Create test sound using Sound$from_values (NEW!)
cat("TEST 1: Sound$from_values() - Tremor Support\n")
cat("-----------------------------------------------------------------\n")
tryCatch({
  # Create a 1-second sine wave at 440 Hz
  sample_rate <- 16000
  duration <- 1.0
  n_samples <- as.integer(sample_rate * duration)
  t <- seq(0, duration, length.out = n_samples)
  
  # Generate sine wave
  frequency <- 440
  values <- sin(2 * pi * frequency * t)
  
  # Create Sound from values
  snd <- Sound$from_values(values, sample_rate)
  
  cat("   ✓ Created Sound from values\n")
  cat("   - Duration:", snd$get_duration(), "seconds\n")
  cat("   - Sample rate:", snd$get_sampling_frequency(), "Hz\n")
  cat("   - Samples:", snd$get_number_of_samples(), "\n")
  cat("   - Channels:", snd$get_number_of_channels(), "\n\n")
}, error = function(e) {
  cat("   ✗ FAILED:", conditionMessage(e), "\n\n")
})

# Test 2: Pitch to TextGrid VUV
cat("TEST 2: Pitch$to_textgrid_vuv() - Voiced/Unvoiced Detection\n")
cat("-----------------------------------------------------------------\n")
tryCatch({
  # Use the sound we just created
  sample_rate <- 16000
  duration <- 1.0
  n_samples <- as.integer(sample_rate * duration)
  t <- seq(0, duration, length.out = n_samples)
  values <- sin(2 * pi * 440 * t)
  snd <- Sound$from_values(values, sample_rate)
  
  pitch <- snd$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
  tg_vuv <- pitch$to_textgrid_vuv()
  
  cat("   ✓ Created TextGrid with voiced/unvoiced intervals\n")
  cat("   - Tiers:", tg_vuv$get_number_of_tiers(), "\n")
  cat("   - Tier 1 name:", tg_vuv$get_tier_names()[1], "\n")
  cat("   - Tier 1 intervals:", tg_vuv$get_number_of_intervals(1), "\n")
  
  # Show first few interval labels
  n_intervals <- min(5, tg_vuv$get_number_of_intervals(1))
  cat("   - First", n_intervals, "labels:")
  for (i in 1:n_intervals) {
    cat(" '", tg_vuv$get_interval_text(1, i), "'", sep="")
  }
  cat("\n\n")
}, error = function(e) {
  cat("   ✗ FAILED:", conditionMessage(e), "\n\n")
})

# Test 3: Pitch to TextGrid silences
cat("TEST 3: Pitch$to_textgrid_silences() - Silence Detection\n")
cat("-----------------------------------------------------------------\n")
tryCatch({
  # Create sound with silence (half silent, half tone)
  sample_rate <- 16000
  duration <- 1.0
  n_samples <- as.integer(sample_rate * duration)
  
  # First half silent, second half 440Hz tone
  values <- c(
    rep(0, n_samples / 2),
    sin(2 * pi * 440 * seq(0, duration/2, length.out = n_samples/2))
  )
  
  snd <- Sound$from_values(values, sample_rate)
  pitch <- snd$to_pitch()
  
  tg_sil <- pitch$to_textgrid_silences(
    min_silent_duration = 0.1,
    min_sounding_duration = 0.1
  )
  
  cat("   ✓ Created TextGrid with sounding/silent intervals\n")
  cat("   - Tiers:", tg_sil$get_number_of_tiers(), "\n")
  cat("   - Intervals:", tg_sil$get_number_of_intervals(1), "\n")
  
  # Show interval labels
  for (i in 1:tg_sil$get_number_of_intervals(1)) {
    start_time <- tg_sil$get_interval_start_time(1, i)
    end_time <- tg_sil$get_interval_end_time(1, i)
    label <- tg_sil$get_interval_text(1, i)
    cat(sprintf("   - Interval %d: %.3f-%.3f s = '%s'\n", i, start_time, end_time, label))
  }
  cat("\n")
}, error = function(e) {
  cat("   ✗ FAILED:", conditionMessage(e), "\n\n")
})

# Test 4: TextGrid interval extraction
cat("TEST 4: TextGrid$extract_intervals_where() - Extract Segments\n")
cat("-----------------------------------------------------------------\n")
tryCatch({
  # Create test sound
  sample_rate <- 16000
  duration <- 1.0
  n_samples <- as.integer(sample_rate * duration)
  t <- seq(0, duration, length.out = n_samples)
  values <- sin(2 * pi * 440 * t)
  snd <- Sound$from_values(values, sample_rate)
  
  pitch <- snd$to_pitch()
  tg_vuv <- pitch$to_textgrid_vuv()
  
  # Extract voiced intervals
  voiced_sounds <- tg_vuv$extract_intervals_where(
    snd, 
    tier_number = 1,
    criterion = "is equal to",
    text = "V"
  )
  
  cat("   ✓ Extracted intervals matching 'V'\n")
  cat("   - Total segments:", length(voiced_sounds), "\n")
  
  if (length(voiced_sounds) > 0) {
    cat("   - First segment duration:", voiced_sounds[[1]]$get_duration(), "s\n")
    cat("   - First segment samples:", voiced_sounds[[1]]$get_number_of_samples(), "\n")
  }
  cat("\n")
}, error = function(e) {
  cat("   ✗ FAILED:", conditionMessage(e), "\n\n")
})

# Test 5: Sound interval extraction (alternative API)
cat("TEST 5: Sound$extract_intervals_where() - Alternative API\n")
cat("-----------------------------------------------------------------\n")
tryCatch({
  # Create test sound
  sample_rate <- 16000
  duration <- 1.0
  n_samples <- as.integer(sample_rate * duration)
  t <- seq(0, duration, length.out = n_samples)
  values <- sin(2 * pi * 440 * t)
  snd <- Sound$from_values(values, sample_rate)
  
  pitch <- snd$to_pitch()
  tg_vuv <- pitch$to_textgrid_vuv()
  
  # Extract voiced intervals using Sound method
  voiced_sounds <- snd$extract_intervals_where(
    tg_vuv,
    tier_number = 1,
    criterion = "is equal to",
    text = "V"
  )
  
  cat("   ✓ Extracted intervals using Sound method\n")
  cat("   - Total segments:", length(voiced_sounds), "\n\n")
}, error = function(e) {
  cat("   ✗ FAILED:", conditionMessage(e), "\n\n")
})

# Test 6: PointProcess voice_report (DSI/AVQI critical)
cat("TEST 6: PointProcess$voice_report() - Jitter/Shimmer (DSI/AVQI)\n")
cat("-----------------------------------------------------------------\n")
tryCatch({
  # Create test sound
  sample_rate <- 16000
  duration <- 1.0
  n_samples <- as.integer(sample_rate * duration)
  t <- seq(0, duration, length.out = n_samples)
  values <- sin(2 * pi * 200 * t)  # 200 Hz for male voice
  snd <- Sound$from_values(values, sample_rate)
  
  pitch <- snd$to_pitch(pitch_floor = 75, pitch_ceiling = 600)
  pp <- snd$to_point_process_periodic_cc(pitch)
  
  # Get voice report
  report <- pp$voice_report(snd, pitch, 75, 600, 1.3, 1.6, 0.03)
  
  cat("   ✓ Voice report generated successfully\n")
  cat("   - Jitter (local):", report$jitter_local, "\n")
  cat("   - Jitter (local, absolute):", report$jitter_local_absolute, "s\n")
  cat("   - Jitter (rap):", report$jitter_rap, "\n")
  cat("   - Jitter (ppq5):", report$jitter_ppq5, "\n")
  cat("   - Shimmer (local):", report$shimmer_local, "\n")
  cat("   - Shimmer (local, dB):", report$shimmer_local_db, "dB\n")
  cat("   - Shimmer (apq3):", report$shimmer_apq3, "\n")
  cat("   - Shimmer (apq5):", report$shimmer_apq5, "\n")
  cat("   - Shimmer (apq11):", report$shimmer_apq11, "\n")
  cat("   - Mean autocorrelation:", report$mean_autocorrelation, "\n")
  cat("   - Mean noise-to-harmonics:", report$mean_noise_to_harmonics_ratio, "\n")
  cat("   - Mean harmonics-to-noise:", report$mean_harmonics_to_noise_ratio, "dB\n")
  cat("\n")
}, error = function(e) {
  cat("   ✗ FAILED:", conditionMessage(e), "\n\n")
})

# Test 7: Complete DSI workflow
cat("TEST 7: DSI Workflow - Voiced Segment Analysis\n")
cat("-----------------------------------------------------------------\n")
tryCatch({
  # Create realistic voice signal (200 Hz fundamental)
  sample_rate <- 16000
  duration <- 2.0
  n_samples <- as.integer(sample_rate * duration)
  t <- seq(0, duration, length.out = n_samples)
  
  # Fundamental + harmonics for more realistic voice
  f0 <- 200
  values <- (
    0.6 * sin(2 * pi * f0 * t) +      # Fundamental
    0.3 * sin(2 * pi * 2*f0 * t) +    # 2nd harmonic
    0.1 * sin(2 * pi * 3*f0 * t)      # 3rd harmonic
  )
  
  snd <- Sound$from_values(values, sample_rate)
  pitch <- snd$to_pitch(pitch_floor = 75, pitch_ceiling = 600)
  
  # Get voiced segments
  tg_vuv <- pitch$to_textgrid_vuv()
  voiced_sounds <- snd$extract_intervals_where(tg_vuv, 1, "is equal to", "V")
  
  cat("   ✓ DSI workflow complete\n")
  cat("   - Voiced segments found:", length(voiced_sounds), "\n")
  
  if (length(voiced_sounds) > 0) {
    # Analyze first voiced segment
    v_pitch <- voiced_sounds[[1]]$to_pitch(pitch_floor = 75, pitch_ceiling = 600)
    v_pp <- voiced_sounds[[1]]$to_point_process_periodic_cc(v_pitch)
    v_report <- v_pp$voice_report(voiced_sounds[[1]], v_pitch, 75, 600, 1.3, 1.6, 0.03)
    
    cat("   - First segment jitter:", v_report$jitter_local, "\n")
    cat("   - First segment shimmer:", v_report$shimmer_local, "\n")
    
    # Get F0 statistics for DSI
    f0_median <- v_pitch$get_quantile(0, 0, 0.50, "HERTZ")
    f0_min <- v_pitch$get_minimum(0, 0, "HERTZ", "PARABOLIC")
    f0_max <- v_pitch$get_maximum(0, 0, "HERTZ", "PARABOLIC")
    
    cat("   - F0 median:", f0_median, "Hz\n")
    cat("   - F0 range:", f0_min, "-", f0_max, "Hz\n")
    cat("   → All DSI components available! ✓\n")
  }
  cat("\n")
}, error = function(e) {
  cat("   ✗ FAILED:", conditionMessage(e), "\n\n")
})

# Test 8: Tremor analysis workflow
cat("TEST 8: Tremor Analysis - Create Pseudo-Sound from F0 Contour\n")
cat("-----------------------------------------------------------------\n")
tryCatch({
  # Extract F0 contour
  sample_rate <- 16000
  duration <- 2.0
  n_samples <- as.integer(sample_rate * duration)
  t <- seq(0, duration, length.out = n_samples)
  values <- sin(2 * pi * 200 * t)
  snd <- Sound$from_values(values, sample_rate)
  
  pitch <- snd$to_pitch(time_step = 0.005, pitch_floor = 75, pitch_ceiling = 600)
  
  # Get F0 as data frame
  pitch_df <- pitch$as_data_frame()
  
  # Remove NAs and interpolate
  pitch_df <- pitch_df[!is.na(pitch_df$frequency), ]
  
  if (nrow(pitch_df) > 10) {
    # Create pseudo-sound from F0 values
    # For tremor: resample to regular intervals, then create Sound
    f0_values <- pitch_df$frequency
    
    # Resample to fixed rate (e.g., 200 Hz for tremor analysis)
    tremor_sample_rate <- 200
    n_tremor_samples <- as.integer(duration * tremor_sample_rate)
    
    # Interpolate F0 to regular grid
    f0_interp <- approx(
      pitch_df$time, 
      pitch_df$frequency, 
      xout = seq(0, duration, length.out = n_tremor_samples)
    )$y
    
    # Create pseudo-sound from F0 contour (NEW FUNCTIONALITY!)
    pseudo_sound <- Sound$from_values(f0_interp, tremor_sample_rate)
    
    cat("   ✓ Created pseudo-sound from F0 contour\n")
    cat("   - Original F0 frames:", nrow(pitch_df), "\n")
    cat("   - Pseudo-sound samples:", pseudo_sound$get_number_of_samples(), "\n")
    cat("   - Pseudo-sound rate:", pseudo_sound$get_sampling_frequency(), "Hz\n")
    
    # Can now do FFT for tremor analysis
    spectrum <- pseudo_sound$to_spectrum()
    cat("   - Spectrum created for tremor FFT analysis ✓\n")
    cat("   → Tremor analysis workflow complete! ✓\n")
  }
  cat("\n")
}, error = function(e) {
  cat("   ✗ FAILED:", conditionMessage(e), "\n\n")
})

cat("=================================================================\n")
cat("All tests complete!\n")
cat("=================================================================\n")
