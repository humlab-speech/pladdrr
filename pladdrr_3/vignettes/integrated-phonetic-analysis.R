## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.width = 7,
  fig.height = 5,
  eval = FALSE  # Disable evaluation due to complex dependencies
)

## ----create_audio-------------------------------------------------------------
# library(pladdrr)
# 
# # Create synthetic audio (440 Hz tone)
# sound <- Sound$create_tone(
#   duration = 5.0,
#   frequency = 440,
#   sampling_rate = 16000,
#   amplitude = 0.5
# )
# 
# # Inspect audio properties
# cat("Duration:", sound$get_duration(), "seconds\n")
# cat("Sample rate:", sound$get_sampling_frequency(), "Hz\n")
# cat("Channels:", sound$get_number_of_channels(), "\n")

## ----create_textgrid----------------------------------------------------------
# # Create TextGrid with 2 interval tiers
# tg <- TextGrid$create(
#   tmin = 0,
#   tmax = 5,
#   tier_names = "words phones",
#   point_tiers = ""  # Both are interval tiers
# )
# 
# # Add word boundaries
# tg$insert_boundary(1, 1.0)
# tg$insert_boundary(1, 2.5)
# tg$insert_boundary(1, 4.0)
# 
# # Label word intervals
# tg$set_interval_text(1, 1, "silence")
# tg$set_interval_text(1, 2, "hello")
# tg$set_interval_text(1, 3, "world")
# tg$set_interval_text(1, 4, "silence")
# 
# # Add phone boundaries (finer granularity)
# phone_times <- c(1.0, 1.3, 1.7, 2.0, 2.5, 3.0, 3.5, 4.0)
# for (t in phone_times) {
#   tg$insert_boundary(2, t)
# }
# 
# # Label phone intervals
# phone_labels <- c("", "h", "E", "l", "oU", "w", "3", "ld", "")
# for (i in seq_along(phone_labels)) {
#   tg$set_interval_text(2, i, phone_labels[i])
# }
# 
# cat("TextGrid created with", tg$get_number_of_tiers(), "tiers\n")

## ----explore_tiers------------------------------------------------------------
# # Get tier information
# tier_names <- tg$get_tier_names()
# for (i in 1:tg$get_number_of_tiers()) {
#   tier_type <- if (tg$tier_is_interval_tier(i)) "IntervalTier" else "PointTier"
#   n_items <- tg$get_number_of_intervals(i)
#   cat(sprintf("Tier %d: %s (%s) - %d items\n",
#               i, tier_names[i], tier_type, n_items))
# }

## ----query_intervals----------------------------------------------------------
# # Get all intervals from the phones tier
# phone_tier <- 2
# n_intervals <- tg$get_number_of_intervals(phone_tier)
# 
# # Create a data frame with interval information
# phone_data <- data.frame(
#   interval = 1:n_intervals,
#   start = numeric(n_intervals),
#   end = numeric(n_intervals),
#   duration = numeric(n_intervals),
#   label = character(n_intervals),
#   stringsAsFactors = FALSE
# )
# 
# for (i in 1:n_intervals) {
#   phone_data$start[i] <- tg$get_interval_start_time(phone_tier, i)
#   phone_data$end[i] <- tg$get_interval_end_time(phone_tier, i)
#   phone_data$duration[i] <- phone_data$end[i] - phone_data$start[i]
#   phone_data$label[i] <- tg$get_interval_text(phone_tier, i)
# }
# 
# print(phone_data)

## ----extract_segments, eval=FALSE---------------------------------------------
# # Extract the "hello" word (interval 2 of word tier)
# hello_start <- tg$get_interval_start_time(1, 2)
# hello_end <- tg$get_interval_end_time(1, 2)
# 
# hello_sound <- sound$extract_part(
#   from_time = hello_start,
#   to_time = hello_end,
#   preserve_times = FALSE
# )
# 
# cat("Extracted 'hello':", hello_sound$get_total_duration(), "seconds\n")

## ----resample-----------------------------------------------------------------
# # Resample to 8 kHz (e.g., for telephony simulations)
# sound_8k <- sound$resample(new_frequency = 8000, precision = 50)
# cat("Resampled to", sound_8k$get_sampling_frequency(), "Hz\n")

## ----normalize----------------------------------------------------------------
# # Scale to 70 dB SPL
# sound_normalized <- sound$scale_intensity(new_intensity = 70)
# cat("Normalized to 70 dB\n")

## ----preemphasis--------------------------------------------------------------
# # Pre-emphasize from 50 Hz
# sound_preemph <- sound$pre_emphasize(from_frequency = 50)
# cat("Applied pre-emphasis from 50 Hz\n")

## ----f0_extraction------------------------------------------------------------
# # Extract pitch contour
# pitch <- sound$to_pitch(
#   time_step = 0.01,
#   pitch_floor = 75,
#   pitch_ceiling = 600
# )
# 
# # Get statistics
# f0_mean <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")
# f0_sd <- pitch$get_standard_deviation(from_time = 0, to_time = 0, unit = "hertz")
# 
# cat(sprintf("F0: Mean = %.1f Hz, SD = %.1f Hz\n", f0_mean, f0_sd))

## ----formant_analysis---------------------------------------------------------
# # Extract formants using Burg's algorithm
# formant <- sound$to_formant_burg(
#   time_step = 0.01,
#   max_formants = 5,
#   max_frequency = 5500,
#   window_length = 0.025,
#   pre_emphasis_from = 50
# )
# 
# # Measure formants at specific time point (e.g., vowel midpoint)
# vowel_time <- 1.5  # Middle of "E" vowel
# f1 <- formant$get_value_at_time(formant_number = 1, time = vowel_time, unit = "hertz")
# f2 <- formant$get_value_at_time(formant_number = 2, time = vowel_time, unit = "hertz")
# f3 <- formant$get_value_at_time(formant_number = 3, time = vowel_time, unit = "hertz")
# 
# cat(sprintf("Formants at %.2f s: F1 = %.0f Hz, F2 = %.0f Hz, F3 = %.0f Hz\n",
#             vowel_time, f1, f2, f3))

## ----intensity----------------------------------------------------------------
# # Extract intensity contour
# intensity <- sound$to_intensity(
#   minimum_pitch = 100,
#   time_step = 0.01
# )
# 
# int_mean <- intensity$get_mean(from_time = 0, to_time = 0)
# cat(sprintf("Mean intensity: %.1f dB\n", int_mean))

## ----hnr----------------------------------------------------------------------
# # Harmonics-to-Noise Ratio
# harmonicity <- sound$to_harmonicity_cc(
#   time_step = 0.01,
#   min_pitch = 75,
#   silence_threshold = 0.1,
#   periods_per_window = 1.0
# )
# 
# hnr_mean <- harmonicity$get_mean(from_time = 0, to_time = 0)
# cat(sprintf("Mean HNR: %.1f dB\n", hnr_mean))

## ----batch_processing---------------------------------------------------------
# # Identify vowel intervals (uppercase labels)
# vowel_intervals <- which(grepl("[AEIOUY3]", phone_data$label, ignore.case = FALSE))
# 
# # Extract acoustic features for each vowel
# vowel_features <- data.frame(
#   phone = character(),
#   start = numeric(),
#   end = numeric(),
#   duration = numeric(),
#   f0_mean = numeric(),
#   f1 = numeric(),
#   f2 = numeric(),
#   f3 = numeric(),
#   intensity = numeric(),
#   hnr = numeric(),
#   stringsAsFactors = FALSE
# )
# 
# for (idx in vowel_intervals) {
#   label <- phone_data$label[idx]
#   start <- phone_data$start[idx]
#   end <- phone_data$end[idx]
#   midpoint <- start + (end - start) / 2
# 
#   # Extract features at vowel midpoint
#   f0 <- pitch$get_value_at_time(time = midpoint, unit = "hertz", interpolate = "linear")
#   f1 <- formant$get_value_at_time(1, midpoint, "hertz")
#   f2 <- formant$get_value_at_time(2, midpoint, "hertz")
#   f3 <- formant$get_value_at_time(3, midpoint, "hertz")
#   int <- intensity$get_value_at_time(midpoint, interpolate = "cubic")
#   hnr <- harmonicity$get_value_at_time(midpoint, interpolate = "linear")
# 
#   vowel_features <- rbind(vowel_features, data.frame(
#     phone = label,
#     start = start,
#     end = end,
#     duration = end - start,
#     f0_mean = if (is.na(f0)) NA else f0,
#     f1 = f1,
#     f2 = f2,
#     f3 = f3,
#     intensity = int,
#     hnr = hnr
#   ))
# }
# 
# print(vowel_features)

## ----export_csv, eval=FALSE---------------------------------------------------
# # Save for statistical analysis
# write.csv(vowel_features, "vowel_acoustic_features.csv", row.names = FALSE)

