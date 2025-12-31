## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.width = 7,
  fig.height = 5,
  eval = FALSE  # Disable evaluation due to complex dependencies
)

## ----load_data----------------------------------------------------------------
# library(pladdrr)
# 
# # Create synthetic audio (in real research: Sound$new("recording.wav"))
# sound <- Sound$create_tone(
#   duration = 10.0,
#   frequency = 100,
#   sampling_rate = 16000,
#   amplitude = 0.3
# )
# 
# # Create TextGrid with vowel annotations
# # In real research: TextGrid$new("annotation.TextGrid")
# tg <- TextGrid$create(
#   tmin = 0,
#   tmax = 10,
#   tier_names = "vowels context",
#   point_tiers = ""  # Both are interval tiers
# )
# 
# # Define vowel segments (start, end, label, word context)
# vowel_segments <- data.frame(
#   start = c(0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5),
#   end = c(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0),
#   vowel = c("i", "e", "a", "o", "u", "i", "a", "e", "u"),
#   word = c("beet", "bait", "bat", "boat", "boot", "beat", "father", "bet", "boot")
# )
# 
# # Add boundaries and labels
# for (i in 1:nrow(vowel_segments)) {
#   tg$insert_boundary(1, vowel_segments$start[i])
# }
# tg$insert_boundary(1, vowel_segments$end[nrow(vowel_segments)])
# 
# for (i in 1:nrow(vowel_segments)) {
#   tg$set_interval_text(1, i + 1, vowel_segments$vowel[i])
# }
# 
# cat("Prepared", nrow(vowel_segments), "vowel tokens\n")

## ----formant_parameters-------------------------------------------------------
# # Parameter guidelines:
# # Adult male: max_formant = 5000 Hz
# # Adult female: max_formant = 5500 Hz
# # Child: max_formant = 8000 Hz
# 
# # For this example (adult female):
# max_formant <- 5500
# time_step <- 0.01
# window_length <- 0.025
# pre_emphasis <- 50

## ----preemphasis, eval=FALSE--------------------------------------------------
# # Note: pre_emphasize modifies sound in-place, so we skip for demonstration
# # sound$pre_emphasize(from_frequency = pre_emphasis)

## ----extract_formants---------------------------------------------------------
# # Extract formants from the original sound
# formant <- sound$to_formant_burg(
#   time_step = time_step,
#   max_formants = 5,
#   max_frequency = max_formant,
#   window_length = window_length,
#   pre_emphasis_from = pre_emphasis
# )
# 
# cat("Formant object created\n")
# cat("Time step:", time_step, "s\n")
# cat("Maximum formant:", max_formant, "Hz\n")

## ----multipoint_measurement---------------------------------------------------
# # Initialize results data frame
# vowel_features <- data.frame(
#   vowel = character(),
#   word = character(),
#   start = numeric(),
#   end = numeric(),
#   duration = numeric(),
#   f1_20 = numeric(),
#   f2_20 = numeric(),
#   f3_20 = numeric(),
#   f1_50 = numeric(),
#   f2_50 = numeric(),
#   f3_50 = numeric(),
#   f1_80 = numeric(),
#   f2_80 = numeric(),
#   f3_80 = numeric(),
#   stringsAsFactors = FALSE
# )
# 
# # Measure formants for each vowel
# for (i in 1:nrow(vowel_segments)) {
#   start <- vowel_segments$start[i]
#   end <- vowel_segments$end[i]
#   duration <- end - start
# 
#   # Calculate time points
#   t_20 <- start + 0.20 * duration
#   t_50 <- start + 0.50 * duration
#   t_80 <- start + 0.80 * duration
# 
#   # Measure formants at each time point
#   measure_formants <- function(time) {
#     c(
#       f1 = formant$get_value_at_time(1, time, "hertz"),
#       f2 = formant$get_value_at_time(2, time, "hertz"),
#       f3 = formant$get_value_at_time(3, time, "hertz")
#     )
#   }
# 
#   f_20 <- measure_formants(t_20)
#   f_50 <- measure_formants(t_50)
#   f_80 <- measure_formants(t_80)
# 
#   # Add to results
#   vowel_features <- rbind(vowel_features, data.frame(
#     vowel = vowel_segments$vowel[i],
#     word = vowel_segments$word[i],
#     start = start,
#     end = end,
#     duration = duration,
#     f1_20 = f_20["f1"],
#     f2_20 = f_20["f2"],
#     f3_20 = f_20["f3"],
#     f1_50 = f_50["f1"],
#     f2_50 = f_50["f2"],
#     f3_50 = f_50["f3"],
#     f1_80 = f_80["f1"],
#     f2_80 = f_80["f2"],
#     f3_80 = f_80["f3"]
#   ))
# }
# 
# print(vowel_features)

## ----lobanov_normalization----------------------------------------------------
# # Function to compute Lobanov z-scores
# lobanov_normalize <- function(formant_values) {
#   (formant_values - mean(formant_values, na.rm = TRUE)) /
#     sd(formant_values, na.rm = TRUE)
# }
# 
# # Normalize F1 and F2 at midpoint (50%)
# vowel_features$f1_norm <- lobanov_normalize(vowel_features$f1_50)
# vowel_features$f2_norm <- lobanov_normalize(vowel_features$f2_50)
# 
# # Also normalize F3 for completeness
# vowel_features$f3_norm <- lobanov_normalize(vowel_features$f3_50)
# 
# cat("Applied Lobanov normalization\n")
# cat("F1_norm: mean =", round(mean(vowel_features$f1_norm), 2),
#     ", SD =", round(sd(vowel_features$f1_norm), 2), "\n")
# cat("F2_norm: mean =", round(mean(vowel_features$f2_norm), 2),
#     ", SD =", round(sd(vowel_features$f2_norm), 2), "\n")

## ----vowel_statistics---------------------------------------------------------
# # Aggregate by vowel type
# vowel_stats <- aggregate(
#   cbind(f1_50, f2_50, f1_norm, f2_norm) ~ vowel,
#   data = vowel_features,
#   FUN = function(x) c(mean = mean(x, na.rm = TRUE),
#                       sd = sd(x, na.rm = TRUE))
# )
# 
# print(vowel_stats)

## ----vowel_space_area---------------------------------------------------------
# # Use normalized values for comparison across speakers
# f1_coords <- vowel_features$f1_norm
# f2_coords <- vowel_features$f2_norm
# 
# # Compute convex hull
# hull_indices <- chull(f2_coords, f1_coords)
# hull_points <- cbind(f2_coords[hull_indices], f1_coords[hull_indices])
# 
# # Calculate area using shoelace formula
# shoelace_area <- function(x, y) {
#   n <- length(x)
#   area <- 0
#   for (i in 1:(n-1)) {
#     area <- area + (x[i] * y[i+1] - x[i+1] * y[i])
#   }
#   area <- area + (x[n] * y[1] - x[1] * y[n])
#   abs(area) / 2
# }
# 
# vowel_space_area <- shoelace_area(hull_points[,1], hull_points[,2])
# cat("Vowel space area (normalized):", round(vowel_space_area, 2), "square units\n")

## ----trajectory_analysis------------------------------------------------------
# # Calculate formant movement
# vowel_features$f1_movement <- abs(vowel_features$f1_80 - vowel_features$f1_20)
# vowel_features$f2_movement <- abs(vowel_features$f2_80 - vowel_features$f2_20)
# 
# # Euclidean distance in F1-F2 space
# vowel_features$trajectory_length <- sqrt(
#   vowel_features$f1_movement^2 + vowel_features$f2_movement^2
# )
# 
# # Identify potential diphthongs (large trajectory)
# diphthong_threshold <- median(vowel_features$trajectory_length, na.rm = TRUE) * 1.5
# potential_diphthongs <- vowel_features$vowel[
#   vowel_features$trajectory_length > diphthong_threshold
# ]
# 
# cat("Potential diphthongs (large F1-F2 movement):\n")
# cat(paste(unique(potential_diphthongs), collapse = ", "), "\n")

## ----vowel_plot_base, eval=FALSE----------------------------------------------
# # Using base R graphics
# plot(
#   vowel_features$f2_50,
#   vowel_features$f1_50,
#   xlim = rev(range(vowel_features$f2_50, na.rm = TRUE)),  # Reverse F2
#   ylim = rev(range(vowel_features$f1_50, na.rm = TRUE)),  # Reverse F1
#   xlab = "F2 (Hz)",
#   ylab = "F1 (Hz)",
#   main = "Vowel Space (Raw Formants)",
#   pch = 19,
#   col = "blue"
# )
# text(
#   vowel_features$f2_50,
#   vowel_features$f1_50,
#   labels = vowel_features$vowel,
#   pos = 3,
#   cex = 0.8
# )

## ----vowel_plot_ggplot2, eval=FALSE-------------------------------------------
# library(ggplot2)
# 
# # Normalized vowel space
# ggplot(vowel_features, aes(x = f2_norm, y = f1_norm, label = vowel, color = vowel)) +
#   geom_point(size = 3) +
#   geom_text(vjust = -1, size = 4) +
#   scale_x_reverse() +
#   scale_y_reverse() +
#   labs(
#     title = "Normalized Vowel Space (Lobanov)",
#     x = "F2 (z-score)",
#     y = "F1 (z-score)"
#   ) +
#   theme_minimal() +
#   theme(legend.position = "none")
# 
# # With trajectories
# ggplot(vowel_features) +
#   geom_segment(aes(x = f2_20, y = f1_20, xend = f2_80, yend = f1_80, color = vowel),
#                arrow = arrow(length = unit(0.2, "cm")), alpha = 0.5) +
#   geom_point(aes(x = f2_50, y = f1_50, color = vowel), size = 3) +
#   geom_text(aes(x = f2_50, y = f1_50, label = vowel), vjust = -1) +
#   scale_x_reverse() +
#   scale_y_reverse() +
#   labs(
#     title = "Vowel Trajectories (20% → 80%)",
#     x = "F2 (Hz)",
#     y = "F1 (Hz)"
#   ) +
#   theme_minimal()

## ----faceted_plot, eval=FALSE-------------------------------------------------
# # For multi-speaker data:
# # vowel_features$speaker <- ... (add speaker ID)
# 
# ggplot(vowel_features, aes(x = f2_norm, y = f1_norm, label = vowel, color = vowel)) +
#   geom_point(size = 2) +
#   geom_text(vjust = -1, size = 3) +
#   facet_wrap(~ speaker, ncol = 3) +
#   scale_x_reverse() +
#   scale_y_reverse() +
#   labs(
#     title = "Vowel Spaces by Speaker",
#     x = "F2 (normalized)",
#     y = "F1 (normalized)"
#   ) +
#   theme_minimal() +
#   theme(legend.position = "none")

## ----anova_example, eval=FALSE------------------------------------------------
# # Test if vowels differ in F1
# f1_model <- aov(f1_50 ~ vowel, data = vowel_features)
# summary(f1_model)
# 
# # Post-hoc pairwise comparisons
# TukeyHSD(f1_model)

## ----mixed_effects, eval=FALSE------------------------------------------------
# library(lme4)
# 
# # Random intercept for speaker
# model <- lmer(f1_50 ~ vowel + (1 | speaker), data = vowel_features)
# summary(model)

## ----sociophonetics, eval=FALSE-----------------------------------------------
# # Load data from multiple dialect regions
# northeast <- load_vowels("northeast_speakers/*.wav")
# south <- load_vowels("south_speakers/*.wav")
# 
# # Combine and analyze
# all_data <- rbind(
#   transform(northeast, dialect = "Northeast"),
#   transform(south, dialect = "South")
# )
# 
# # Statistical test
# model <- lm(f1_norm ~ vowel * dialect, data = all_data)

## ----l2_acquisition, eval=FALSE-----------------------------------------------
# # Longitudinal data (same learner, multiple sessions)
# learner_data$session <- as.factor(learner_data$session)
# 
# # Test for improvement
# model <- lmer(
#   trajectory_length ~ session * vowel + (1 | learner_id),
#   data = learner_data
# )
# 
# # Expect decreasing trajectory (more monophthongal)

## ----clarity_assessment, eval=FALSE-------------------------------------------
# # Calculate vowel space area for each style
# clear_area <- compute_vowel_space_area(clear_speech_data)
# casual_area <- compute_vowel_space_area(casual_speech_data)
# 
# # Typically: clear_area > casual_area
# cat("Clear speech area:", clear_area, "\n")
# cat("Casual speech area:", casual_area, "\n")
# cat("Expansion ratio:", clear_area / casual_area, "\n")

## ----parameter_testing, eval=FALSE--------------------------------------------
# # Test multiple ceilings
# ceilings <- c(5000, 5500, 6000, 6500)
# for (ceiling in ceilings) {
#   formant <- sound$to_formant_burg(max_frequency = ceiling, ...)
#   # Manually check F1-F2 values for sanity
# }

## ----quality_control, eval=FALSE----------------------------------------------
# # Flag extreme values
# f1_outliers <- vowel_features$f1_50 > 1000 | vowel_features$f1_50 < 200
# f2_outliers <- vowel_features$f2_50 > 3000 | vowel_features$f2_50 < 500
# 
# cat("Potential tracking errors:", sum(f1_outliers | f2_outliers), "\n")
# 
# # Manual review or retrack with different parameters

## ----missing_data, eval=FALSE-------------------------------------------------
# # Remove rows with missing formants
# vowel_features_clean <- vowel_features[
#   complete.cases(vowel_features[, c("f1_50", "f2_50")]),
# ]
# 
# # Or impute using formant tracking refinement
# # (see Praat's "Track formants" for advanced methods)

