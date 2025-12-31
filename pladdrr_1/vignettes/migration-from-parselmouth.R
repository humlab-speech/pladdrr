## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = FALSE
)

## -----------------------------------------------------------------------------
# library(pladdrr)
# 
# sound <- Sound$new("audio.wav")

## -----------------------------------------------------------------------------
# sound <- Sound$new("audio.wav")
# pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
# mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")

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
# mean_int <- intensity$get_mean(from_time = 0, to_time = 0, averaging_method = "energy")

## -----------------------------------------------------------------------------
# sound <- Sound$new("audio.wav")
# spectrum <- sound$to_spectrum(fast = TRUE)
# cog <- spectrum$get_centre_of_gravity(power = 2.0)

## -----------------------------------------------------------------------------
# library(pladdrr)
# 
# files <- list.files(pattern = "\\.wav$", full.names = TRUE)
# 
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
# results_df <- do.call(rbind, results)
# write.csv(results_df, "results.csv", row.names = FALSE)

## -----------------------------------------------------------------------------
# sound <- Sound$new("audio.wav")
# pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
# 
# # Direct conversion to data frame
# pitch_data <- pitch$as_data_frame()
# # Returns data.frame with 'time' and 'frequency' columns

## -----------------------------------------------------------------------------
# library(pladdrr)
# library(ggplot2)
# 
# sound <- Sound$new("audio.wav")
# pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
# pitch_data <- pitch$as_data_frame()
# 
# ggplot(pitch_data, aes(x = time, y = frequency)) +
#   geom_line() +
#   labs(title = "Pitch Contour", x = "Time (s)", y = "Frequency (Hz)") +
#   theme_minimal()

## -----------------------------------------------------------------------------
# analyze_voice <- function(filename) {
#   sound <- Sound$new(filename)
# 
#   pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
#   mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")
# 
#   harmonicity <- sound$to_harmonicity_cc(time_step = 0.01, minimum_pitch = 75,
#                                          silence_threshold = 0.1, periods_per_window = 1.0)
#   mean_hnr <- harmonicity$get_mean(from_time = 0, to_time = 0)
# 
#   pointprocess <- sound$to_pointprocess_periodic_cc(minimum_pitch = 75, maximum_pitch = 600)
#   jitter <- pointprocess$get_jitter_local(from_time = 0, to_time = 0,
#                                           period_floor = 0.0001, period_ceiling = 0.02,
#                                           maximum_period_factor = 1.3)
# 
#   list(
#     mean_f0 = mean_f0,
#     mean_hnr = mean_hnr,
#     jitter = jitter
#   )
# }

## -----------------------------------------------------------------------------
# library(pladdrr)
# library(dplyr)
# library(purrr)
# 
# results <- tibble(
#   file = c('file1.wav', 'file2.wav', 'file3.wav'),
#   speaker = c('A', 'B', 'C')
# ) %>%
#   mutate(
#     analysis = map(file, analyze_voice)
#   ) %>%
#   unnest_wider(analysis)

