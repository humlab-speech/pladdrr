## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.width = 7,
  fig.height = 5
)

## ----eval = FALSE-------------------------------------------------------------
# # Install from source
# install.packages("pladdrr", type = "source")
# 
# # Or install from GitHub
# # devtools::install_github("your-username/pladdrr")

## -----------------------------------------------------------------------------
library(pladdrr)

## -----------------------------------------------------------------------------
# Generate a 440 Hz sine wave (A4 note)
sound_a4 <- generate_sine_wave(frequency = 440, duration = 0.5, 
                               amplitude = 0.7, sampling_rate = 44100)

print(sound_a4)

## -----------------------------------------------------------------------------
# Generate white noise
noise <- generate_noise(duration = 0.2, sampling_rate = 44100, 
                       amplitude = 0.3)

print(noise)

## ----eval = FALSE-------------------------------------------------------------
# # Load a WAV file using R6 interface
# speech <- Sound$new("path/to/speech.wav")
# 
# # Load specific channel from stereo file (1-indexed)
# speech_left <- Sound$new("path/to/stereo.wav", channel = 1)
# speech_right <- Sound$new("path/to/stereo.wav", channel = 2)

## -----------------------------------------------------------------------------
# Duration in seconds
cat("Duration:", sound_a4$get_duration(), "seconds\n")

# Sampling rate
cat("Sampling rate:", sound_a4$get_sampling_frequency(), "Hz\n")

# Number of samples
cat("Samples:", sound_a4$get_number_of_samples(), "\n")

# Number of channels
cat("Channels:", sound_a4$get_number_of_channels(), "\n")

## -----------------------------------------------------------------------------
# Individual statistics
cat("Mean amplitude:", sound_mean(sound_a4), "\n")
cat("RMS amplitude:", sound_rms(sound_a4), "\n")
cat("Min amplitude:", sound_min(sound_a4), "\n")
cat("Max amplitude:", sound_max(sound_a4), "\n")

# All statistics at once
stats <- sound_statistics(sound_a4)
print(stats)

## -----------------------------------------------------------------------------
# For speech, use typical settings
# pitch <- speech$to_pitch(pitch_floor = 75, pitch_ceiling = 600)

# For our test signal, we need to create a more complex sound
# (pure sine waves may not be detected as voiced)
# In real usage with speech:
# mean_f0 <- pitch$get_mean()
# min_f0 <- pitch$get_minimum()
# max_f0 <- pitch$get_maximum()

## ----eval = FALSE-------------------------------------------------------------
# # Male voice
# pitch_male <- sound$to_pitch(pitch_floor = 50, pitch_ceiling = 300)
# 
# # Female voice
# pitch_female <- sound$to_pitch(pitch_floor = 100, pitch_ceiling = 600)
# 
# # Child voice
# pitch_child <- sound$to_pitch(pitch_floor = 150, pitch_ceiling = 800)

## ----eval = FALSE-------------------------------------------------------------
# # Get F0 at specific time point
# f0_at_1s <- pitch$get_value_at_time(time = 1.0)
# 
# # Get mean F0 over time range
# mean_f0_range <- pitch$get_mean(from_time = 0.5, to_time = 1.5)
# 
# # Get minimum and maximum
# min_f0 <- pitch$get_minimum()
# max_f0 <- pitch$get_maximum()

## -----------------------------------------------------------------------------
# Extract formants (default settings for adult female)
formants <- sound_a4$to_formant_burg(max_frequency = 5500, max_formants = 5)

# R6 objects print nicely
formants

## ----eval = FALSE-------------------------------------------------------------
# # Adult male
# formants_male <- sound$to_formant_burg(max_frequency = 5000, max_formants = 5)
# 
# # Adult female
# formants_female <- sound$to_formant_burg(max_frequency = 5500, max_formants = 5)
# 
# # Child
# formants_child <- sound$to_formant_burg(max_frequency = 8000, max_formants = 5)

## -----------------------------------------------------------------------------
# Get F1 and F2 at specific time (vowel quality)
f1 <- formants$get_value_at_time(formant_number = 1, time = 0.25)
f2 <- formants$get_value_at_time(formant_number = 2, time = 0.25)

cat("F1:", round(f1, 1), "Hz\n")
cat("F2:", round(f2, 1), "Hz\n")

## -----------------------------------------------------------------------------
# Get mean formant over time range
mean_f1 <- formants$get_mean(formant_number = 1, 
                             from_time = 0.1, to_time = 0.4)
mean_f2 <- formants$get_mean(formant_number = 2, 
                             from_time = 0.1, to_time = 0.4)

cat("Mean F1:", round(mean_f1, 1), "Hz\n")
cat("Mean F2:", round(mean_f2, 1), "Hz\n")

## -----------------------------------------------------------------------------
# Extract intensity
intensity <- sound_a4$to_intensity(minimum_pitch = 100)

# R6 objects print nicely
intensity

## -----------------------------------------------------------------------------
# Mean intensity
mean_db <- intensity$get_mean()
cat("Mean intensity:", round(mean_db, 2), "dB\n")

# Intensity range
min_db <- intensity$get_minimum()
max_db <- intensity$get_maximum()
cat("Intensity range:", round(min_db, 2), "-", round(max_db, 2), "dB\n")

# Standard deviation
sd_db <- intensity$get_standard_deviation()
cat("SD intensity:", round(sd_db, 2), "dB\n")

## -----------------------------------------------------------------------------
# Query intensity at time point
int_at_time <- intensity$get_value_at_time(time = 0.25)
cat("Intensity at 0.25s:", round(int_at_time, 2), "dB\n")

# With interpolation (cubic)
int_interp <- intensity$get_value_at_time(time = 0.25, interpolation = "cubic")
cat("Intensity (interpolated):", round(int_interp, 2), "dB\n")

## -----------------------------------------------------------------------------
# Convert to data frame using R6 method
formant_df <- formants$as_data_frame()
head(formant_df)

## -----------------------------------------------------------------------------
intensity_df <- intensity$as_data_frame()
head(intensity_df)

## ----eval = FALSE-------------------------------------------------------------
# # 1. Load sound
# sound <- Sound$new("vowel.wav")
# 
# # 2. Extract all analyses
# pitch <- sound$to_pitch(pitch_floor = 75, pitch_ceiling = 600)
# formants <- sound$to_formant_burg(max_frequency = 5500, max_formants = 5)
# intensity <- sound$to_intensity(minimum_pitch = 75)
# 
# # 3. Get measurements at vowel midpoint
# midpoint <- sound$get_duration() / 2
# 
# f0 <- pitch$get_value_at_time(time = midpoint)
# f1 <- formants$get_value_at_time(formant_number = 1, time = midpoint)
# f2 <- formants$get_value_at_time(formant_number = 2, time = midpoint)
# f3 <- formants$get_value_at_time(formant_number = 3, time = midpoint)
# int <- intensity$get_value_at_time(time = midpoint)
# 
# # 4. Create summary
# vowel_data <- data.frame(
#   F0 = f0,
#   F1 = f1,
#   F2 = f2,
#   F3 = f3,
#   Intensity = int
# )
# 
# print(vowel_data)

## ----eval = FALSE-------------------------------------------------------------
# # R with pladdrr (R6 interface)
# sound <- Sound$new("sound.wav")
# pitch <- sound$to_pitch(time_step = 0.01,
#                        pitch_floor = 75, pitch_ceiling = 600)
# f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")

## ----eval = FALSE-------------------------------------------------------------
# # Fine-tune formant detection
# formants <- sound$to_formant_burg(
#   time_step = 0.005,           # 5 ms steps
#   max_frequency = 5500,        # Adult female range
#   max_formants = 5,            # Track F1-F5
#   window_length = 0.025,       # 25 ms window
#   pre_emphasis_from = 50       # Pre-emphasis from 50 Hz
# )
# 
# # Fine-tune intensity
# intensity <- sound$to_intensity(
#   minimum_pitch = 75,          # Affects window length
#   time_step = 0.01,            # 10 ms steps (auto if 0)
#   subtract_mean = FALSE        # Absolute intensity in dB SPL
# )

## ----eval = FALSE-------------------------------------------------------------
# # Pitch may be NA for unvoiced segments
# f0 <- pitch$get_value_at_time(time = 1.0)
# if (is.na(f0)) {
#   cat("Unvoiced at this time point\n")
# } else {
#   cat("F0:", f0, "Hz\n")
# }
# 
# # Mean functions automatically exclude NA
# mean_f0 <- pitch$get_mean()  # NA values excluded

## -----------------------------------------------------------------------------
# Package version
packageVersion("pladdrr")

# Citation information
citation("pladdrr")

