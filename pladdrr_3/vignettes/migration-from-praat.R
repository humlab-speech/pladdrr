## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = FALSE
)

## -----------------------------------------------------------------------------
# library(pladdrr)
# sound <- Sound$new("audio.wav")

## -----------------------------------------------------------------------------
# pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)

## -----------------------------------------------------------------------------
# sound <- Sound$new("audio.wav")
# pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
# mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")
# std_f0 <- pitch$get_standard_deviation(from_time = 0, to_time = 0, unit = "hertz")

## -----------------------------------------------------------------------------
# sound <- Sound$new("vowel.wav")
# formant <- sound$to_formant_burg(
#   time_step = 0.01,
#   max_number_of_formants = 5,
#   maximum_formant = 5500,
#   window_length = 0.025,
#   pre_emphasis_from = 50
# )
# f1 <- formant$get_value_at_time(formant_number = 1, time = 0.5, unit = "hertz")
# f2 <- formant$get_value_at_time(formant_number = 2, time = 0.5, unit = "hertz")

## -----------------------------------------------------------------------------
# sound <- Sound$new("audio.wav")
# intensity <- sound$to_intensity(minimum_pitch = 100, time_step = 0.01, subtract_mean = TRUE)
# mean_intensity <- intensity$get_mean(from_time = 0, to_time = 0, averaging_method = "energy")
# max_intensity <- intensity$get_maximum(from_time = 0, to_time = 0, interpolation = "parabolic")

## -----------------------------------------------------------------------------
# sound <- Sound$new("audio.wav")
# spectrum <- sound$to_spectrum(fast = TRUE)
# cog <- spectrum$get_centre_of_gravity(power = 2.0)

## -----------------------------------------------------------------------------
# textgrid <- TextGrid$new(xmin = 0, xmax = 1, tier_names = "words phones", point_tiers = "phones")
# textgrid$insert_boundary(tier_number = 1, time = 0.5)
# textgrid$set_interval_text(tier_number = 1, interval_number = 1, text = "hello")

## -----------------------------------------------------------------------------
# library(pladdrr)
# 
# # Get list of WAV files
# files <- list.files(pattern = "\\.wav$", full.names = TRUE)
# 
# # Process each file
# results <- lapply(files, function(filepath) {
#   sound <- Sound$new(filepath)
#   pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
#   mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")
# 
#   data.frame(
#     file = basename(filepath),
#     mean_f0 = mean_f0
#   )
# })
# 
# # Combine results
# results_df <- do.call(rbind, results)
# write.csv(results_df, "results.csv", row.names = FALSE)

## -----------------------------------------------------------------------------
# library(pladdrr)
# library(dplyr)
# library(purrr)
# 
# results <- tibble(file = list.files(pattern = "\\.wav$")) %>%
#   mutate(
#     sound = map(file, Sound$new),
#     pitch = map(sound, ~.$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)),
#     mean_f0 = map_dbl(pitch, ~.$get_mean(from_time = 0, to_time = 0, unit = "hertz")),
#     sd_f0 = map_dbl(pitch, ~.$get_standard_deviation(from_time = 0, to_time = 0, unit = "hertz"))
#   ) %>%
#   select(file, mean_f0, sd_f0)

## -----------------------------------------------------------------------------
# library(ggplot2)
# 
# # Extract pitch contour
# sound <- Sound$new("audio.wav")
# pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
# pitch_data <- pitch$as_data_frame()
# 
# # Plot
# ggplot(pitch_data, aes(x = time, y = frequency)) +
#   geom_line() +
#   labs(title = "Pitch Contour", x = "Time (s)", y = "Frequency (Hz)") +
#   theme_minimal()

## -----------------------------------------------------------------------------
# # Objects are automatically cleaned up when no longer referenced
# sound <- Sound$new("audio.wav")
# # 'sound' is freed when it goes out of scope or is reassigned

## -----------------------------------------------------------------------------
# mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")

## -----------------------------------------------------------------------------
# # Correct
# pitch$get_mean(unit = "hertz")
# 
# # Also works (case-insensitive in many methods)
# pitch$get_mean(unit = "Hertz")

