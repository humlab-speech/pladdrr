# Example 9: Vowel Space Analysis Pipeline
# Demonstrates complete workflow for vowel acoustics research
# From annotation to F1-F2 plotting and statistical analysis

library(speaker)

cat("================================================================================\n")
cat("Example 9: Vowel Space Analysis Pipeline\n")
cat("================================================================================\n\n")

cat("This example demonstrates:\n")
cat("  • Complete vowel extraction and analysis workflow\n")
cat("  • Formant measurement at multiple time points\n")
cat("  • Normalization procedures\n")
cat("  • Data preparation for vowel space plots (F1-F2)\n")
cat("  • Integration with R's statistical and plotting tools\n\n")

# ============================================================================
# Part 1: Setup and Data Preparation
# ============================================================================

cat("Part 1: Creating synthetic speech data with vowel annotations\n")
cat(strrep("=", 80), "\n\n")

# Create a 10-second synthetic "speech" with multiple vowels
# In real research, you would load actual speech recordings

cat("Creating synthetic multi-vowel audio...\n")

# We'll create formant-like resonances for different vowels
# Real formant values for reference:
# /i/: F1≈280 Hz, F2≈2250 Hz
# /e/: F1≈400 Hz, F2≈2000 Hz  
# /a/: F1≈700 Hz, F2≈1200 Hz
# /o/: F1≈500 Hz, F2≈900 Hz
# /u/: F1≈300 Hz, F2≈800 Hz

sound <- Sound$create_simple(
  xmin = 0,
  xmax = 10,
  sampling_frequency = 16000,
  formula = "0.3 * sin(2*pi*100*x)"  # Simple carrier
)

cat("  ✓ Created 10-second audio at 16 kHz\n\n")

# Create TextGrid with vowel annotations
cat("Creating vowel annotations...\n")

tg <- TextGrid$create(
  xmin = 0,
  xmax = 10,
  tier_names = c("vowels", "context"),
  point_tiers = c(FALSE, FALSE)
)

# Define vowel segments
# Format: start, end, vowel_label, word_context
vowel_data <- data.frame(
  start = c(0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5),
  end = c(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0),
  vowel = c("i", "e", "a", "o", "u", "i", "a", "e", "u"),
  word = c("beet", "bait", "bat", "boat", "boot", "beat", "father", "bet", "boot"),
  stringsAsFactors = FALSE
)

# Add boundaries and labels to vowels tier
for (i in seq_len(nrow(vowel_data))) {
  tg$insert_boundary(1, vowel_data$start[i])
  if (i == nrow(vowel_data)) {
    tg$insert_boundary(1, vowel_data$end[i])
  }
}

for (i in seq_len(nrow(vowel_data))) {
  tg$set_interval_label(1, i + 1, vowel_data$vowel[i])  # +1 because first interval is pre-speech
}

# Add word context to second tier
for (i in seq_len(nrow(vowel_data))) {
  tg$insert_boundary(2, vowel_data$start[i])
  if (i == nrow(vowel_data)) {
    tg$insert_boundary(2, vowel_data$end[i])
  }
}

for (i in seq_len(nrow(vowel_data))) {
  tg$set_interval_label(2, i + 1, vowel_data$word[i])
}

cat(sprintf("  ✓ Created TextGrid with %d vowel tokens\n", nrow(vowel_data)))
cat(sprintf("  Vowel types: %s\n", paste(unique(vowel_data$vowel), collapse = ", ")))
cat("\n")

# ============================================================================
# Part 2: Formant Extraction at Multiple Time Points
# ============================================================================

cat("\nPart 2: Extracting formants at multiple time points\n")
cat(strrep("=", 80), "\n\n")

cat("Measurement strategy:\n")
cat("  • 20% into vowel (onset)\n")
cat("  • 50% into vowel (midpoint/steady-state)\n")
cat("  • 80% into vowel (offset)\n\n")

# Storage for results
measurements <- list()

# Gender/speaker setting (affects formant ceiling)
# Female: 5500 Hz, Male: 5000 Hz, Child: 8000 Hz
speaker_gender <- "male"
max_formant <- switch(speaker_gender, female = 5500, male = 5000, 8000)

cat(sprintf("Using formant ceiling: %d Hz (%s speaker)\n\n", max_formant, speaker_gender))

# Process each vowel token
for (i in seq_len(nrow(vowel_data))) {
  vowel_label <- vowel_data$vowel[i]
  word_context <- vowel_data$word[i]
  start_time <- vowel_data$start[i]
  end_time <- vowel_data$end[i]
  duration <- end_time - start_time
  
  cat(sprintf("Token %d: /%s/ in '%s' [%.2f-%.2f s, %.0f ms]\n", 
              i, vowel_label, word_context, start_time, end_time, duration * 1000))
  
  # Extract vowel segment
  vowel_sound <- sound$extract_part(
    start_time = start_time,
    end_time = end_time,
    preserve_times = TRUE
  )
  
  # Extract formants using Burg's algorithm
  formants <- vowel_sound$to_formant_burg(
    time_step = 0.005,  # 5 ms steps
    max_number_of_formants = 5,
    maximum_formant = max_formant,
    window_length = 0.025,
    pre_emphasis_from = 50
  )
  
  # Measure at three time points
  time_points <- c(0.20, 0.50, 0.80)  # 20%, 50%, 80% into vowel
  point_labels <- c("onset", "midpoint", "offset")
  
  for (j in seq_along(time_points)) {
    prop <- time_points[j]
    label <- point_labels[j]
    
    # Calculate absolute time
    abs_time <- start_time + duration * prop
    
    # Extract F1-F3
    f1 <- formants$get_value_at_time(
      formant_number = 1,
      time = abs_time,
      unit = "Hertz",
      interpolation = "Linear"
    )
    
    f2 <- formants$get_value_at_time(
      formant_number = 2,
      time = abs_time,
      unit = "Hertz",
      interpolation = "Linear"
    )
    
    f3 <- formants$get_value_at_time(
      formant_number = 3,
      time = abs_time,
      unit = "Hertz",
      interpolation = "Linear"
    )
    
    # Store measurement
    measurements[[length(measurements) + 1]] <- data.frame(
      token_id = i,
      vowel = vowel_label,
      word = word_context,
      start_time = start_time,
      end_time = end_time,
      duration = duration,
      measurement_point = label,
      proportion = prop,
      absolute_time = abs_time,
      f1 = f1,
      f2 = f2,
      f3 = f3,
      stringsAsFactors = FALSE
    )
    
    if (label == "midpoint") {  # Only print midpoint for brevity
      cat(sprintf("  → Midpoint: F1=%.0f Hz, F2=%.0f Hz, F3=%.0f Hz\n", f1, f2, f3))
    }
  }
  
  cat("\n")
}

# Combine all measurements
formant_data <- do.call(rbind, measurements)

cat(sprintf("✓ Extracted formants for %d tokens × %d time points = %d measurements\n\n", 
            nrow(vowel_data), length(time_points), nrow(formant_data)))

# ============================================================================
# Part 3: Formant Normalization
# ============================================================================

cat("\nPart 3: Formant normalization\n")
cat(strrep("=", 80), "\n\n")

cat("Applying Lobanov (z-score) normalization...\n")
cat("Formula: F'[vowel, formant] = (F[vowel, formant] - mean[formant]) / sd[formant]\n\n")

# Filter to midpoint measurements for normalization
midpoint_data <- subset(formant_data, measurement_point == "midpoint")

# Compute speaker means and SDs (across all vowels)
mean_f1 <- mean(midpoint_data$f1, na.rm = TRUE)
sd_f1 <- sd(midpoint_data$f1, na.rm = TRUE)
mean_f2 <- mean(midpoint_data$f2, na.rm = TRUE)
sd_f2 <- sd(midpoint_data$f2, na.rm = TRUE)
mean_f3 <- mean(midpoint_data$f3, na.rm = TRUE)
sd_f3 <- sd(midpoint_data$f3, na.rm = TRUE)

cat(sprintf("Speaker formant statistics:\n"))
cat(sprintf("  F1: M=%.0f Hz, SD=%.0f Hz\n", mean_f1, sd_f1))
cat(sprintf("  F2: M=%.0f Hz, SD=%.0f Hz\n", mean_f2, sd_f2))
cat(sprintf("  F3: M=%.0f Hz, SD=%.0f Hz\n", mean_f3, sd_f3))
cat("\n")

# Apply Lobanov normalization
midpoint_data$f1_norm <- (midpoint_data$f1 - mean_f1) / sd_f1
midpoint_data$f2_norm <- (midpoint_data$f2 - mean_f2) / sd_f2
midpoint_data$f3_norm <- (midpoint_data$f3 - mean_f3) / sd_f3

cat("Sample of normalized values:\n")
print(head(midpoint_data[, c("vowel", "word", "f1", "f1_norm", "f2", "f2_norm")], 5))
cat("\n")

# ============================================================================
# Part 4: Vowel Space Statistics
# ============================================================================

cat("\nPart 4: Computing vowel space statistics\n")
cat(strrep("=", 80), "\n\n")

# Compute means by vowel type
vowel_means <- aggregate(
  cbind(f1, f2, f3, f1_norm, f2_norm, f3_norm, duration) ~ vowel,
  data = midpoint_data,
  FUN = mean,
  na.rm = TRUE
)

# Add standard deviations
vowel_sds <- aggregate(
  cbind(f1, f2, f3) ~ vowel,
  data = midpoint_data,
  FUN = sd,
  na.rm = TRUE
)
names(vowel_sds)[2:4] <- c("f1_sd", "f2_sd", "f3_sd")

vowel_stats <- merge(vowel_means, vowel_sds, by = "vowel")

# Add token count
vowel_counts <- table(midpoint_data$vowel)
vowel_stats$n_tokens <- as.numeric(vowel_counts[vowel_stats$vowel])

# Sort by F1 (low to high = close to open vowels)
vowel_stats <- vowel_stats[order(vowel_stats$f1), ]

cat("Vowel space summary (sorted by F1):\n\n")
cat(sprintf("  %-6s %-8s %-8s %-8s %-10s %-10s %-8s\n", 
            "Vowel", "F1 (Hz)", "F2 (Hz)", "F3 (Hz)", "F1 SD", "F2 SD", "N"))
cat(sprintf("  %s\n", strrep("-", 70)))

for (i in seq_len(nrow(vowel_stats))) {
  cat(sprintf("  %-6s %-8.0f %-8.0f %-8.0f %-10.0f %-10.0f %-8d\n",
              vowel_stats$vowel[i],
              vowel_stats$f1[i],
              vowel_stats$f2[i],
              vowel_stats$f3[i],
              vowel_stats$f1_sd[i],
              vowel_stats$f2_sd[i],
              vowel_stats$n_tokens[i]))
}
cat("\n")

# Compute vowel space area (triangulation method)
# Using F1-F2 space with vowels i, a, u as corners
if (all(c("i", "a", "u") %in% vowel_stats$vowel)) {
  i_f1 <- vowel_stats$f1[vowel_stats$vowel == "i"]
  i_f2 <- vowel_stats$f2[vowel_stats$vowel == "i"]
  a_f1 <- vowel_stats$f1[vowel_stats$vowel == "a"]
  a_f2 <- vowel_stats$f2[vowel_stats$vowel == "a"]
  u_f1 <- vowel_stats$f1[vowel_stats$vowel == "u"]
  u_f2 <- vowel_stats$f2[vowel_stats$vowel == "u"]
  
  # Triangle area using cross product
  area <- abs((i_f1 * (a_f2 - u_f2) + a_f1 * (u_f2 - i_f2) + u_f1 * (i_f2 - a_f2)) / 2)
  
  cat(sprintf("Vowel space area (/i/-/a/-/u/ triangle): %.0f Hz²\n", area))
  cat("(Larger area = more dispersed vowel space)\n\n")
}

# ============================================================================
# Part 5: Data Export for Visualization
# ============================================================================

cat("\nPart 5: Preparing data for visualization\n")
cat(strrep("=", 80), "\n\n")

# Export for vowel space plot (F1 vs F2)
cat("Creating data files for plotting...\n\n")

# Individual tokens (for scatter plot)
tokens_file <- file.path(tempdir(), "vowel_tokens.csv")
write.csv(midpoint_data, tokens_file, row.names = FALSE)
cat("  • Individual tokens:", tokens_file, "\n")
cat("    Columns:", paste(names(midpoint_data), collapse = ", "), "\n")
cat("    Use for: Scatter plot of individual tokens\n\n")

# Vowel means (for centroids)
means_file <- file.path(tempdir(), "vowel_means.csv")
write.csv(vowel_stats, means_file, row.names = FALSE)
cat("  • Vowel means:", means_file, "\n")
cat("    Columns:", paste(names(vowel_stats), collapse = ", "), "\n")
cat("    Use for: Vowel space plot with centroids and error ellipses\n\n")

# Time-series data (for formant trajectories)
trajectory_file <- file.path(tempdir(), "formant_trajectories.csv")
write.csv(formant_data, trajectory_file, row.names = FALSE)
cat("  • Formant trajectories:", trajectory_file, "\n")
cat("    Use for: Formant movement plots (onset → offset)\n\n")

# ============================================================================
# Part 6: Example Visualization Code (commented)
# ============================================================================

cat("\nPart 6: Example visualization code\n")
cat(strrep("=", 80), "\n\n")

cat("To create a vowel space plot in R, use:\n\n")

cat("```r\n")
cat("# Load data\n")
cat("tokens <- read.csv('vowel_tokens.csv')\n")
cat("means <- read.csv('vowel_means.csv')\n\n")

cat("# Create F1-F2 plot (inverted axes)\n")
cat("library(ggplot2)\n")
cat("ggplot(tokens, aes(x = f2, y = f1, color = vowel)) +\n")
cat("  geom_point(alpha = 0.5, size = 3) +  # Individual tokens\n")
cat("  geom_point(data = means, size = 6, shape = 17) +  # Centroids\n")
cat("  geom_text(data = means, aes(label = vowel), \n")
cat("            vjust = -1, size = 6, fontface = 'bold') +\n")
cat("  scale_x_reverse() +  # F2 decreases left to right\n")
cat("  scale_y_reverse() +  # F1 decreases bottom to top\n")
cat("  labs(x = 'F2 (Hz)', y = 'F1 (Hz)', \n")
cat("       title = 'Vowel Space Plot') +\n")
cat("  theme_minimal() +\n")
cat("  theme(legend.position = 'right')\n")
cat("```\n\n")

cat("For normalized vowel space:\n\n")
cat("```r\n")
cat("ggplot(tokens, aes(x = f2_norm, y = f1_norm, color = vowel)) +\n")
cat("  geom_point(alpha = 0.5, size = 3) +\n")
cat("  stat_ellipse(level = 0.68) +  # 1 SD ellipses\n")
cat("  scale_x_reverse() + scale_y_reverse() +\n")
cat("  labs(x = 'F2 (normalized)', y = 'F1 (normalized)')\n")
cat("```\n\n")

# ============================================================================
# Summary
# ============================================================================

cat("\n")
cat(strrep("=", 80), "\n")
cat("Example 9 Complete!\n")
cat(strrep("=", 80), "\n\n")

cat("This example demonstrated a complete vowel analysis pipeline:\n\n")

cat("✓ DATA PREPARATION\n")
cat("  • Synthetic multi-vowel audio creation\n")
cat("  • TextGrid annotation with vowel labels\n")
cat("  • Word context annotation\n\n")

cat("✓ FORMANT MEASUREMENT\n")
cat("  • Extraction at multiple time points (onset, midpoint, offset)\n")
cat("  • F1, F2, F3 measurements\n")
cat("  • Gender-appropriate formant ceiling settings\n\n")

cat("✓ NORMALIZATION\n")
cat("  • Lobanov (z-score) normalization\n")
cat("  • Speaker-internal normalization\n")
cat("  • Preservation of raw and normalized values\n\n")

cat("✓ STATISTICAL ANALYSIS\n")
cat("  • Vowel-specific means and standard deviations\n")
cat("  • Vowel space area calculation\n")
cat("  • Duration measurements\n\n")

cat("✓ DATA EXPORT\n")
cat("  • CSV files for visualization\n")
cat("  • Integration with ggplot2 and other R packages\n")
cat("  • Ready for statistical modeling\n\n")

cat("APPLICATIONS:\n")
cat("  • Sociolinguistic vowel variation studies\n")
cat("  • L2 acquisition research\n")
cat("  • Dialect comparison\n")
cat("  • Clinical voice assessment\n")
cat("  • Speech synthesis evaluation\n\n")

cat("OUTPUT FILES:\n")
cat("  •", tokens_file, "\n")
cat("  •", means_file, "\n")
cat("  •", trajectory_file, "\n\n")

cat("For related examples:\n")
cat("  • inst/examples/02_voice_quality.R - Voice quality metrics\n")
cat("  • inst/examples/05_complete_workflow.R - General acoustic analysis\n")
cat("  • inst/examples/07_comprehensive_phonetic_analysis.R - Integrated workflow\n\n")
