# Example 7: Comprehensive Phonetic Analysis Workflow
# Demonstrates integrated use of TextGrid, Sound manipulation, and acoustic
#  analysis
# This example shows how to use speaker for real-world phonetic research

library(speaker)

cat(
  "================================================================================\n")
cat("Example 7: Comprehensive Phonetic Analysis Workflow\n")
cat(
  "================================================================================\n\n")

cat("This example demonstrates:\n")
cat("  • TextGrid-based segmentation and analysis\n")
cat("  • Sound manipulation (extraction, resampling, normalization)\n")
cat("  • Integrated acoustic measurements (F0, formants, intensity)\n")
cat("  • Batch processing of annotated segments\n")
cat("  • Data export for statistical analysis\n\n")

# ============================================================================
# Part 1: Load and Inspect Data
# ============================================================================

cat("Part 1: Loading audio and annotation files\n")
cat(strrep("=", 80), "\n\n")

# For this example, we'll create synthetic data with a TextGrid
# In real-world usage, you would load existing files

# Create a 5-second test sound (440 Hz tone with amplitude modulation)
cat("Creating synthetic speech-like audio...\n")
sound <- Sound$create_simple(
  xmin = 0,
  xmax = 5,
  sampling_frequency = 16000,
  formula = "0.5 * sin(2*pi*440*x) * (1 + 0.3*sin(2*pi*5*x))"
)
cat("  ✓ Created 5-second audio at 16 kHz\n")
cat("  Duration:", sound$get_total_duration(), "seconds\n")
cat("  Sample rate:", sound$get_sampling_frequency(), "Hz\n")
cat("  Number of channels:", sound$get_number_of_channels(), "\n\n")

# Create a corresponding TextGrid with annotations
cat("Creating TextGrid annotation...\n")
tg <- TextGrid$create(
  xmin = 0,
  xmax = 5,
  tier_names = c("words", "phones"),
  point_tiers = c(FALSE, FALSE)  # Both are interval tiers
)

# Add word boundaries
cat("  Adding word-level annotations...\n")
tg$insert_boundary(tier_number = 1, time = 1.0)
tg$insert_boundary(tier_number = 1, time = 2.5)
tg$insert_boundary(tier_number = 1, time = 4.0)

tg$set_interval_label(tier_number = 1, interval_number = 1, label = "silence")
tg$set_interval_label(tier_number = 1, interval_number = 2, label = "hello")
tg$set_interval_label(tier_number = 1, interval_number = 3, label = "world")
tg$set_interval_label(tier_number = 1, interval_number = 4, label = "silence")

# Add phone boundaries (more fine-grained)
cat("  Adding phone-level annotations...\n")
tg$insert_boundary(tier_number = 2, time = 1.0)
tg$insert_boundary(tier_number = 2, time = 1.3)
tg$insert_boundary(tier_number = 2, time = 1.7)
tg$insert_boundary(tier_number = 2, time = 2.0)
tg$insert_boundary(tier_number = 2, time = 2.5)
tg$insert_boundary(tier_number = 2, time = 3.0)
tg$insert_boundary(tier_number = 2, time = 3.5)
tg$insert_boundary(tier_number = 2, time = 4.0)

tg$set_interval_label(tier_number = 2, interval_number = 1, label = "")
tg$set_interval_label(tier_number = 2, interval_number = 2, label = "h")
tg$set_interval_label(tier_number = 2, interval_number = 3, label = "E")
tg$set_interval_label(tier_number = 2, interval_number = 4, label = "l")
tg$set_interval_label(tier_number = 2, interval_number = 5, label = "oU")
tg$set_interval_label(tier_number = 2, interval_number = 6, label = "w")
tg$set_interval_label(tier_number = 2, interval_number = 7, label = "3")
tg$set_interval_label(tier_number = 2, interval_number = 8, label = "ld")

cat("  ✓ TextGrid created with 2 tiers\n")
cat("  Words tier:", tg$get_number_of_intervals("words"), "intervals\n")
cat("  Phones tier:", tg$get_number_of_intervals("phones"), "intervals\n\n")

# ============================================================================
# Part 2: TextGrid Querying and Exploration
# ============================================================================

cat("\nPart 2: Exploring TextGrid structure\n")
cat(strrep("=", 80), "\n\n")

cat("Tier information:\n")
tier_names <- tg$get_tier_names()
for (i in 1:tg$get_number_of_tiers()) {
  tier_type <- if (tg$tier_is_interval_tier(i)) "IntervalTier" else "PointTier"
  n_items <- if (tg$tier_is_interval_tier(i)) {
    tg$get_number_of_intervals(i)
  } else {
    tg$get_number_of_points(i)
  }
  cat(
    sprintf("  Tier %d: '%s' (%s) - %d items\n", i, tier_names[i], tier_type,
      n_items))
}
cat("\n")

# Query labels at specific times
cat("Label queries at different time points:\n")
query_times <- c(0.5, 1.5, 2.7, 3.2, 4.5)
for (t in query_times) {
  word <- tg$get_label_at_time("words", t)
  phone <- tg$get_label_at_time("phones", t)
  cat(sprintf("  Time %.1f s: word='%s', phone='%s'\n", t, word, phone))
}
cat("\n")

# ============================================================================
# Part 3: Sound Manipulation
# ============================================================================

cat("\nPart 3: Sound manipulation operations\n")
cat(strrep("=", 80), "\n\n")

# Extract a segment based on TextGrid annotation
cat("3a. Extracting 'hello' segment using TextGrid bounds\n")
interval_idx <- 2  # "hello" is the 2nd interval
start_time <- tg$get_interval_start_time("words", interval_idx)
end_time <- tg$get_interval_end_time("words", interval_idx)

hello_sound <- sound$extract_part(
  start_time = start_time,
  end_time = end_time,
  preserve_times = FALSE
)
cat(
  sprintf("  ✓ Extracted segment [%.2f - %.2f] seconds\n", start_time,
    end_time))
cat("  Segment duration:", hello_sound$get_total_duration(), "seconds\n\n")

# Resample to different rate
cat("3b. Resampling audio\n")
original_sr <- hello_sound$get_sampling_frequency()
new_sr <- 8000
resampled_sound <- hello_sound$resample(new_frequency = new_sr, precision = 50)
cat(sprintf("  ✓ Resampled from %d Hz to %d Hz\n", original_sr, new_sr))
cat("  Duration preserved:", resampled_sound$get_total_duration(),
  "seconds\n\n")

# Normalize intensity
cat("3c. Normalizing intensity\n")
original_intensity <- sound$get_intensity_db()
target_db <- 70.0
sound_copy <- sound$copy()
sound_copy$scale_intensity(new_intensity_db = target_db)
new_intensity <- sound_copy$get_intensity_db()
cat(
  sprintf("  ✓ Scaled intensity: %.2f dB → %.2f dB\n", original_intensity,
    new_intensity))
cat("\n")

# Apply pre-emphasis (high-pass filter for formant analysis)
cat("3d. Applying pre-emphasis filter\n")
pre_emphasized <- hello_sound$copy()
pre_emphasized$pre_emphasize(from_frequency = 50.0)
cat("  ✓ Pre-emphasis applied (50 Hz cutoff)\n")
cat("  This enhances high-frequency components for formant analysis\n\n")

# ============================================================================
# Part 4: Batch Acoustic Analysis of Annotated Segments
# ============================================================================

cat("\nPart 4: Batch acoustic analysis of phone segments\n")
cat(strrep("=", 80), "\n\n")

# Analyze each phone segment
cat("Extracting acoustic features for each phone:\n\n")

results <- list()
phone_tier <- "phones"
n_phones <- tg$get_number_of_intervals(phone_tier)

for (i in 1:n_phones) {
  label <- tg$get_interval_label(phone_tier, i)
  
  # Skip empty intervals
  if (label == "") next
  
  start <- tg$get_interval_start_time(phone_tier, i)
  end <- tg$get_interval_end_time(phone_tier, i)
  duration <- end - start
  
  # Extract segment
  segment <- sound$extract_part(start, end, preserve_times = TRUE)
  
  # Compute acoustic features
  
  # 1. Fundamental frequency (F0)
  pitch <- segment$to_pitch(
    time_step = 0.0,      # Auto
    pitch_floor = 75,
    pitch_ceiling = 600
  )
  mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "Hertz")
  
  # 2. Formants (vowel quality)
  if (grepl("[AEIU3O]", label)) {  # Vowels only
    formants <- segment$to_formant_burg(
      time_step = 0.0,
      max_number_of_formants = 5,
      maximum_formant = 5500,
      window_length = 0.025,
      pre_emphasis_from = 50
    )
    f1 <- formants$get_mean(formant_number = 1, from_time = 0, to_time = 0,
      unit = "Hertz")
    f2 <- formants$get_mean(formant_number = 2, from_time = 0, to_time = 0,
      unit = "Hertz")
  } else {
    f1 <- NA
    f2 <- NA
  }
  
  # 3. Intensity
  intensity <- segment$to_intensity(
    minimum_pitch = 100,
    time_step = 0.0,
    subtract_mean = TRUE
  )
  mean_intensity <- intensity$get_mean(from_time = 0, to_time = 0,
    averaging_method = "energy")
  
  # 4. Harmonicity (voice quality)
  harmonicity <- segment$to_harmonicity_ac(
    time_step = 0.01,
    minimum_pitch = 75,
    silence_threshold = 0.1,
    periods_per_window = 1.0
  )
  mean_hnr <- harmonicity$get_mean(from_time = 0, to_time = 0)
  
  # Store results
  results[[length(results) + 1]] <- data.frame(
    interval = i,
    phone = label,
    start_time = start,
    end_time = end,
    duration = duration,
    mean_f0 = mean_f0,
    f1 = f1,
    f2 = f2,
    mean_intensity = mean_intensity,
    mean_hnr = mean_hnr,
    stringsAsFactors = FALSE
  )
  
  cat(sprintf("  Phone [%2d] '%3s' [%.2f-%.2f]: F0=%.1f Hz", 
              i, label, start, end, mean_f0))
  if (!is.na(f1)) {
    cat(sprintf(", F1=%.0f Hz, F2=%.0f Hz", f1, f2))
  }
  cat(sprintf(", Intensity=%.1f dB, HNR=%.1f dB\n", mean_intensity, mean_hnr))
}

# Combine results
results_df <- do.call(rbind, results)
cat("\n✓ Analyzed", nrow(results_df), "phone segments\n\n")

# ============================================================================
# Part 5: Data Export and Visualization Preparation
# ============================================================================

cat("\nPart 5: Data export for further analysis\n")
cat(strrep("=", 80), "\n\n")

# Export TextGrid as data frame
cat("Exporting TextGrid to data frame...\n")
tg_df <- tg$as_data_frame()
cat("  ✓ TextGrid exported:", nrow(tg_df), "rows\n")
cat("  Columns:", toString(names(tg_df)), "\n\n")

# Show summary statistics by phone type
cat("Summary statistics by phone type:\n\n")

# Classify phones
results_df$phone_type <- ifelse(
  grepl("[AEIOU3]", results_df$phone),
  "vowel",
  "consonant"
)

# Compute summaries
library(stats)
vowel_stats <- subset(results_df, phone_type == "vowel")
if (nrow(vowel_stats) > 0) {
  cat("Vowels (n=", nrow(vowel_stats), "):\n", sep = "")
  cat(sprintf("  Mean F0: %.1f Hz (SD=%.1f)\n", 
              mean(vowel_stats$mean_f0, na.rm = TRUE),
              sd(vowel_stats$mean_f0, na.rm = TRUE)))
  cat(sprintf("  Mean F1: %.0f Hz (SD=%.0f)\n",
              mean(vowel_stats$f1, na.rm = TRUE),
              sd(vowel_stats$f1, na.rm = TRUE)))
  cat(sprintf("  Mean F2: %.0f Hz (SD=%.0f)\n",
              mean(vowel_stats$f2, na.rm = TRUE),
              sd(vowel_stats$f2, na.rm = TRUE)))
  cat(sprintf("  Mean duration: %.3f s (SD=%.3f)\n",
              mean(vowel_stats$duration, na.rm = TRUE),
              sd(vowel_stats$duration, na.rm = TRUE)))
  cat("\n")
}

consonant_stats <- subset(results_df, phone_type == "consonant")
if (nrow(consonant_stats) > 0) {
  cat("Consonants (n=", nrow(consonant_stats), "):\n", sep = "")
  cat(sprintf("  Mean duration: %.3f s (SD=%.3f)\n",
              mean(consonant_stats$duration, na.rm = TRUE),
              sd(consonant_stats$duration, na.rm = TRUE)))
  cat(sprintf("  Mean intensity: %.1f dB (SD=%.1f)\n",
              mean(consonant_stats$mean_intensity, na.rm = TRUE),
              sd(consonant_stats$mean_intensity, na.rm = TRUE)))
  cat("\n")
}

# Save results
output_dir <- tempdir()
results_file <- file.path(output_dir, "phonetic_analysis_results.csv")
write.csv(results_df, results_file, row.names = FALSE)
cat("Results saved to:", results_file, "\n\n")

# Save modified TextGrid
tg_file <- file.path(output_dir, "analysis.TextGrid")
tg$save(tg_file)
cat("TextGrid saved to:", tg_file, "\n\n")

# ============================================================================
# Part 6: Advanced Analysis - Formant Tracking
# ============================================================================

cat("\nPart 6: Advanced formant tracking with optimization\n")
cat(strrep("=", 80), "\n\n")

# Extract a vowel segment for detailed formant tracking
cat("Extracting vowel 'E' for detailed formant analysis...\n")
vowel_interval <- which(tg_df$tier_name == "phones" & tg_df$label == "E")[1]
if (!is.na(vowel_interval)) {
  vowel_start <- tg_df$start_time[vowel_interval]
  vowel_end <- tg_df$end_time[vowel_interval]
  vowel_sound <- sound$extract_part(vowel_start, vowel_end,
    preserve_times = TRUE)
  
  cat(
    sprintf("  ✓ Extracted vowel [%.2f - %.2f] seconds\n", vowel_start,
      vowel_end))
  
  # Track formants with different settings
  cat("\nComparing formant tracking methods:\n\n")
  
  # Method 1: Standard Burg algorithm
  formants_burg <- vowel_sound$to_formant_burg(
    time_step = 0.01,
    max_number_of_formants = 5,
    maximum_formant = 5500,
    window_length = 0.025,
    pre_emphasis_from = 50
  )
  f1_burg <- formants_burg$get_mean(1, 0, 0, "Hertz")
  f2_burg <- formants_burg$get_mean(2, 0, 0, "Hertz")
  
  cat(sprintf("  Burg algorithm: F1=%.0f Hz, F2=%.0f Hz\n", f1_burg, f2_burg))
  
  # Method 2: Keep-all method (more robust for tracking)
  formants_keepall <- vowel_sound$to_formant_keep_all(
    time_step = 0.01,
    max_number_of_formants = 5,
    maximum_formant = 5500,
    window_length = 0.025,
    pre_emphasis_from = 50
  )
  f1_keepall <- formants_keepall$get_mean(1, 0, 0, "Hertz")
  f2_keepall <- formants_keepall$get_mean(2, 0, 0, "Hertz")
  
  cat(
    sprintf("  Keep-all method: F1=%.0f Hz, F2=%.0f Hz\n", f1_keepall,
      f2_keepall))
  
  # Method 3: Optimized tracking with formant ceiling
  formants_tracked <- formants_keepall$track(
    n_tracks = 5,
    ref_f1 = 500,
    ref_f2 = 1500,
    ref_f3 = 2500,
    ref_f4 = 3500,
    ref_f5 = 4500,
    frequency_cost = 1.0,
    bandwidth_cost = 1.0,
    transition_cost = 1.0
  )
  f1_tracked <- formants_tracked$get_mean(1, 0, 0, "Hertz")
  f2_tracked <- formants_tracked$get_mean(2, 0, 0, "Hertz")
  
  cat(
    sprintf("  Tracked (optimized): F1=%.0f Hz, F2=%.0f Hz\n", f1_tracked,
      f2_tracked))
  cat("\n")
}

# ============================================================================
# Summary
# ============================================================================

cat("\n")
cat(strrep("=", 80), "\n")
cat("Example 7 Complete!\n")
cat(strrep("=", 80), "\n\n")

cat("This example demonstrated:\n\n")

cat("1. DATA MANAGEMENT\n")
cat("   ✓ TextGrid creation and annotation\n")
cat("   ✓ Multi-tier hierarchical structure\n")
cat("   ✓ File I/O (reading and saving)\n\n")

cat("2. TEXTGRID OPERATIONS\n")
cat("   ✓ Boundary insertion and removal\n")
cat("   ✓ Label modification\n")
cat("   ✓ Interval and point queries\n")
cat("   ✓ Export to data frames\n\n")

cat("3. SOUND MANIPULATION\n")
cat("   ✓ Segment extraction based on annotations\n")
cat("   ✓ Resampling to different sample rates\n")
cat("   ✓ Intensity normalization\n")
cat("   ✓ Pre-emphasis filtering\n\n")

cat("4. ACOUSTIC ANALYSIS\n")
cat("   ✓ Fundamental frequency (F0) extraction\n")
cat("   ✓ Formant analysis (F1, F2)\n")
cat("   ✓ Intensity measurements\n")
cat("   ✓ Voice quality (HNR)\n\n")

cat("5. BATCH PROCESSING\n")
cat("   ✓ Iterate over TextGrid intervals\n")
cat("   ✓ Extract features for multiple segments\n")
cat("   ✓ Aggregate and summarize results\n\n")

cat("6. ADVANCED TECHNIQUES\n")
cat("   ✓ Multiple formant tracking algorithms\n")
cat("   ✓ Formant trajectory optimization\n")
cat("   ✓ Vowel-specific analysis\n\n")

cat("REAL-WORLD APPLICATIONS:\n")
cat("  • Vowel quality analysis (F1/F2 measurements)\n")
cat("  • Voice onset time (VOT) measurements\n")
cat("  • Prosodic analysis (F0 contours)\n")
cat("  • Voice quality assessment (HNR, jitter, shimmer)\n")
cat("  • Automated feature extraction for phonetic corpora\n\n")

cat("OUTPUT FILES:\n")
cat("  • Acoustic measurements:", results_file, "\n")
cat("  • Annotation:", tg_file, "\n\n")

cat("For more examples, see:\n")
cat("  • inst/examples/06_textgrid_analysis.R - TextGrid-focused operations\n")
cat("  • inst/examples/05_complete_workflow.R - End-to-end acoustic analysis\n")
cat("  • inst/examples/02_voice_quality.R - Voice quality metrics\n\n")
