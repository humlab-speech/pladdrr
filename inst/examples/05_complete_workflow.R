# Complete Phonetic Analysis Workflow
# End-to-end example combining all speaker package capabilities

library(speaker)

# WORKFLOW 1: Single Speaker Analysis =========================================

analyze_speaker <- function(audio_file,
                           speaker_gender = "female",
                           output_dir = NULL) {
  
  cat(rep("=", 70), "\n")
  cat("SPEAKER PACKAGE - Complete Phonetic Analysis\n")
  cat(rep("=", 70), "\n\n")
  
  cat("File:", audio_file, "\n")
  cat("Gender:", speaker_gender, "\n\n")
  
  # Set parameters based on gender
  if (speaker_gender == "male") {
    pitch_floor <- 75
    pitch_ceiling <- 300
    max_formant <- 5000
  } else if (speaker_gender == "female") {
    pitch_floor <- 100
    pitch_ceiling <- 600
    max_formant <- 5500
  } else if (speaker_gender == "child") {
    pitch_floor <- 150
    pitch_ceiling <- 800
    max_formant <- 8000
  } else {
    # Default to female
    pitch_floor <- 75
    pitch_ceiling <- 600
    max_formant <- 5500
  }
  
  # Load sound
  cat("Loading audio...\n")
  sound <- read_sound(audio_file)
  duration <- get_duration(sound)
  sr <- sound$sampling_frequency
  
  cat("  Duration:", round(duration, 2), "seconds\n")
  cat("  Sample rate:", sr, "Hz\n\n")
  
  # Extract pitch
  cat("Extracting pitch...\n")
  pitch <- extract_pitch(sound, 
                        pitch_floor = pitch_floor,
                        pitch_ceiling = pitch_ceiling,
                        time_step = 0.01)
  
  # Pitch statistics
  mean_f0 <- get_mean_pitch(pitch, unit = "Hertz")
  median_f0 <- pitch$get_quantile(quantile = 0.5, unit = "hertz")
  sd_f0 <- pitch$get_standard_deviation(unit = "hertz")
  min_f0 <- pitch$get_minimum(interpolate = FALSE, unit = "hertz")
  max_f0 <- pitch$get_maximum(interpolate = FALSE, unit = "hertz")
  
  cat("  Mean F0:", round(mean_f0, 1), "Hz\n")
  cat("  Median F0:", round(median_f0, 1), "Hz\n")
  cat("  SD F0:", round(sd_f0, 1), "Hz\n")
  cat("  Range:", round(min_f0, 1), "-", round(max_f0, 1), "Hz\n\n")
  
  # Extract formants
  cat("Extracting formants...\n")
  formants <- extract_formants(sound,
                               max_formant = max_formant,
                               n_formants = 5,
                               time_step = 0.01,
                               window_length = 0.025)
  
  # Formant statistics
  f1_mean <- get_mean_formant(formants, formant_number = 1)
  f2_mean <- get_mean_formant(formants, formant_number = 2)
  f3_mean <- get_mean_formant(formants, formant_number = 3)
  f4_mean <- get_mean_formant(formants, formant_number = 4)
  
  cat("  Mean F1:", round(f1_mean, 0), "Hz\n")
  cat("  Mean F2:", round(f2_mean, 0), "Hz\n")
  cat("  Mean F3:", round(f3_mean, 0), "Hz\n")
  cat("  Mean F4:", round(f4_mean, 0), "Hz\n\n")
  
  # Extract intensity
  cat("Extracting intensity...\n")
  intensity <- extract_intensity(sound,
                                minimum_pitch = pitch_floor,
                                time_step = 0.01,
                                subtract_mean = TRUE)
  
  # Intensity statistics
  mean_db <- get_mean_intensity(intensity)
  sd_db <- intensity$get_standard_deviation()
  min_db <- intensity$get_minimum(interpolation = "none")
  max_db <- intensity$get_maximum(interpolation = "none")
  
  cat("  Mean intensity:", round(mean_db, 1), "dB\n")
  cat("  SD intensity:", round(sd_db, 1), "dB\n")
  cat("  Range:", round(min_db, 1), "-", round(max_db, 1), "dB\n\n")
  
  # Create summary data frame
  summary_stats <- data.frame(
    file = basename(audio_file),
    duration_s = duration,
    gender = speaker_gender,
    mean_f0 = mean_f0,
    median_f0 = median_f0,
    sd_f0 = sd_f0,
    min_f0 = min_f0,
    max_f0 = max_f0,
    f1_mean = f1_mean,
    f2_mean = f2_mean,
    f3_mean = f3_mean,
    f4_mean = f4_mean,
    mean_intensity = mean_db,
    sd_intensity = sd_db,
    stringsAsFactors = FALSE
  )
  
  # Convert objects to data frames
  pitch_df <- as.data.frame(pitch)
  formant_df <- as.data.frame(formants)
  intensity_df <- as.data.frame(intensity)
  
  # Create visualizations
  cat("Creating visualizations...\n")
  
  if (!is.null(output_dir)) {
    # Save plots to files
    dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
    
    # 4-panel plot
    pdf(file.path(output_dir, paste0(tools::file_path_sans_ext(basename(audio_file)), "_analysis.pdf")),
        width = 10, height = 8)
  } else {
    # Display plots
    dev.new(width = 10, height = 8)
  }
  
  par(mfrow = c(2, 2), mar = c(4, 4, 2, 1))
  
  # Panel 1: Pitch contour
  plot(pitch_df$time, pitch_df$frequency,
       type = "l", col = "blue", lwd = 2,
       xlab = "Time (s)", ylab = "F0 (Hz)",
       main = paste("Pitch Contour -", speaker_gender))
  abline(h = mean_f0, col = "red", lty = 2, lwd = 2)
  grid()
  
  # Panel 2: Formants F1-F3
  plot(formant_df$time, formant_df$F1,
       type = "l", col = "red", lwd = 2,
       xlab = "Time (s)", ylab = "Frequency (Hz)",
       main = "Formant Trajectories (F1-F3)",
       ylim = c(0, max(c(formant_df$F3), na.rm = TRUE) * 1.1))
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
  abline(h = mean_db, col = "red", lty = 2, lwd = 2)
  grid()
  
  # Panel 4: Pitch histogram
  hist(pitch_df$frequency[!is.na(pitch_df$frequency)],
       breaks = 30, col = "lightblue", border = "blue",
       xlab = "F0 (Hz)", main = "Pitch Distribution")
  abline(v = mean_f0, col = "red", lwd = 2, lty = 2)
  abline(v = median_f0, col = "darkred", lwd = 2, lty = 3)
  legend("topright", legend = c("Mean", "Median"),
         col = c("red", "darkred"), lty = c(2, 3), lwd = 2)
  grid()
  
  if (!is.null(output_dir)) {
    dev.off()
    cat("  Saved plot to:", file.path(output_dir, 
                                      paste0(tools::file_path_sans_ext(basename(audio_file)), 
                                             "_analysis.pdf")), "\n")
  }
  
  par(mfrow = c(1, 1))  # Reset
  
  # Save CSV files if output directory specified
  if (!is.null(output_dir)) {
    base_name <- tools::file_path_sans_ext(basename(audio_file))
    
    write.csv(summary_stats, 
              file.path(output_dir, paste0(base_name, "_summary.csv")),
              row.names = FALSE)
    
    write.csv(pitch_df,
              file.path(output_dir, paste0(base_name, "_pitch.csv")),
              row.names = FALSE)
    
    write.csv(formant_df,
              file.path(output_dir, paste0(base_name, "_formants.csv")),
              row.names = FALSE)
    
    write.csv(intensity_df,
              file.path(output_dir, paste0(base_name, "_intensity.csv")),
              row.names = FALSE)
    
    cat("\nSaved CSV files to:", output_dir, "\n")
  }
  
  cat("\nAnalysis complete!\n")
  cat(rep("=", 70), "\n")
  
  # Return all results
  invisible(list(
    summary = summary_stats,
    pitch = list(object = pitch, data = pitch_df),
    formants = list(object = formants, data = formant_df),
    intensity = list(object = intensity, data = intensity_df)
  ))
}

# WORKFLOW 2: Batch Processing ================================================

batch_analyze_speakers <- function(audio_files,
                                  speaker_genders = NULL,
                                  speaker_labels = NULL,
                                  output_dir = "speaker_analysis") {
  
  cat("\n")
  cat(rep("=", 70), "\n")
  cat("BATCH ANALYSIS -", length(audio_files), "files\n")
  cat(rep("=", 70), "\n\n")
  
  # Set defaults
  if (is.null(speaker_genders)) {
    speaker_genders <- rep("female", length(audio_files))
  }
  
  if (is.null(speaker_labels)) {
    speaker_labels <- basename(tools::file_path_sans_ext(audio_files))
  }
  
  # Create output directory
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
  
  # Analyze each file
  all_results <- list()
  all_summaries <- list()
  
  for (i in seq_along(audio_files)) {
    cat("\n[", i, "/", length(audio_files), "] ", audio_files[i], "\n", sep = "")
    
    # Create speaker-specific output directory
    speaker_dir <- file.path(output_dir, speaker_labels[i])
    
    # Analyze
    results <- analyze_speaker(audio_files[i],
                              speaker_gender = speaker_genders[i],
                              output_dir = speaker_dir)
    
    # Store results
    all_results[[speaker_labels[i]]] <- results
    all_summaries[[i]] <- results$summary
  }
  
  # Combine all summaries
  combined_summary <- do.call(rbind, all_summaries)
  combined_summary$speaker_label <- speaker_labels
  
  # Reorder columns
  combined_summary <- combined_summary[, c("speaker_label", 
                                          setdiff(names(combined_summary), "speaker_label"))]
  
  # Save combined summary
  write.csv(combined_summary,
            file.path(output_dir, "combined_summary.csv"),
            row.names = FALSE)
  
  cat("\n")
  cat(rep("=", 70), "\n")
  cat("BATCH ANALYSIS COMPLETE\n")
  cat("Results saved to:", output_dir, "\n")
  cat(rep("=", 70), "\n\n")
  
  # Print summary table
  cat("Summary Statistics:\n\n")
  print(combined_summary[, c("speaker_label", "duration_s", 
                             "mean_f0", "f1_mean", "f2_mean", "mean_intensity")])
  
  invisible(list(
    combined_summary = combined_summary,
    individual_results = all_results
  ))
}

# WORKFLOW 3: Vowel Analysis ==================================================

analyze_vowel_space <- function(audio_files,
                               vowel_times_list,
                               vowel_labels_list = NULL,
                               speaker_labels = NULL,
                               max_formant = 5500,
                               plot_output = NULL) {
  
  cat("\n")
  cat(rep("=", 70), "\n")
  cat("VOWEL SPACE ANALYSIS\n")
  cat(rep("=", 70), "\n\n")
  
  if (is.null(speaker_labels)) {
    speaker_labels <- paste("Speaker", seq_along(audio_files))
  }
  
  # Collect all vowel data
  all_vowel_data <- list()
  
  for (i in seq_along(audio_files)) {
    cat("Processing:", audio_files[i], "\n")
    
    # Load sound
    sound <- read_sound(audio_files[i])
    
    # Extract formants
    formants <- extract_formants(sound, 
                                max_formant = max_formant,
                                n_formants = 5)
    
    # Get F1 and F2 at each vowel timepoint
    vowel_times <- vowel_times_list[[i]]
    vowel_labels <- if (!is.null(vowel_labels_list)) vowel_labels_list[[i]] else NULL
    
    f1_values <- sapply(vowel_times, function(t) {
      get_formant_at_time(formants, formant_number = 1, time = t)
    })
    
    f2_values <- sapply(vowel_times, function(t) {
      get_formant_at_time(formants, formant_number = 2, time = t)
    })
    
    # Create data frame
    vowel_data <- data.frame(
      speaker = speaker_labels[i],
      time = vowel_times,
      F1 = f1_values,
      F2 = f2_values
    )
    
    if (!is.null(vowel_labels)) {
      vowel_data$vowel <- vowel_labels
    }
    
    all_vowel_data[[i]] <- vowel_data
  }
  
  # Combine all vowel data
  combined_vowels <- do.call(rbind, all_vowel_data)
  
  # Plot vowel space
  if (!is.null(plot_output)) {
    pdf(plot_output, width = 8, height = 8)
  } else {
    dev.new(width = 8, height = 8)
  }
  
  # Get plot limits
  f1_range <- range(combined_vowels$F1, na.rm = TRUE)
  f2_range <- range(combined_vowels$F2, na.rm = TRUE)
  
  # Create plot (inverted axes per phonetic convention)
  plot(combined_vowels$F2, combined_vowels$F1,
       xlim = rev(f2_range),
       ylim = rev(f1_range),
       xlab = "F2 (Hz)", ylab = "F1 (Hz)",
       main = "Vowel Space",
       pch = 19, col = as.numeric(factor(combined_vowels$speaker)),
       cex = 1.5)
  
  # Add vowel labels if available
  if ("vowel" %in% names(combined_vowels)) {
    text(combined_vowels$F2, combined_vowels$F1, 
         combined_vowels$vowel, pos = 3, offset = 0.5)
  }
  
  # Add legend
  if (length(unique(combined_vowels$speaker)) > 1) {
    legend("bottomleft", legend = unique(combined_vowels$speaker),
           col = seq_along(unique(combined_vowels$speaker)),
           pch = 19, cex = 1.2)
  }
  
  grid()
  
  if (!is.null(plot_output)) {
    dev.off()
    cat("\nVowel space plot saved to:", plot_output, "\n")
  }
  
  cat("\nVowel analysis complete!\n")
  cat(rep("=", 70), "\n\n")
  
  invisible(combined_vowels)
}

# Usage Examples ==============================================================

if (FALSE) {  # Don't run automatically
  
  # Example 1: Single speaker analysis
  results <- analyze_speaker(
    "speech.wav",
    speaker_gender = "female",
    output_dir = "analysis_output"
  )
  
  # Example 2: Batch analysis
  files <- c("speaker1.wav", "speaker2.wav", "speaker3.wav")
  genders <- c("male", "female", "female")
  labels <- c("John", "Mary", "Susan")
  
  batch_results <- batch_analyze_speakers(
    files,
    speaker_genders = genders,
    speaker_labels = labels,
    output_dir = "batch_analysis"
  )
  
  # Example 3: Vowel space analysis
  vowel_files <- c("vowels_speaker1.wav", "vowels_speaker2.wav")
  vowel_times <- list(
    c(0.5, 1.0, 1.5, 2.0),  # Speaker 1 vowel timepoints
    c(0.6, 1.1, 1.6, 2.1)   # Speaker 2 vowel timepoints
  )
  vowel_labels <- list(
    c("i", "e", "a", "o"),
    c("i", "e", "a", "o")
  )
  speaker_names <- c("Speaker 1", "Speaker 2")
  
  vowel_data <- analyze_vowel_space(
    vowel_files,
    vowel_times,
    vowel_labels,
    speaker_names,
    plot_output = "vowel_space.pdf"
  )
}
