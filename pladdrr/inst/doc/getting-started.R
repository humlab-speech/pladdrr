## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.width = 7,
  fig.height = 5
)

## ----eval = FALSE-------------------------------------------------------------
# # Install from source
# install.packages("speaker", type = "source")
# 
# # Or install from GitHub
# # devtools::install_github("your-username/speaker")

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
# # Load a WAV file
# speech <- read_sound("path/to/speech.wav")
# 
# # Load specific channel from stereo file
# speech_left <- read_sound("path/to/stereo.wav", channel = 0)
# speech_right <- read_sound("path/to/stereo.wav", channel = 1)

## -----------------------------------------------------------------------------
# Duration in seconds
cat("Duration:", get_duration(sound_a4), "seconds\n")

# Sampling rate
cat("Sampling rate:", get_sampling_rate(sound_a4), "Hz\n")

# Number of samples
cat("Samples:", get_n_samples(sound_a4), "\n")

# Number of channels
cat("Channels:", get_n_channels(sound_a4), "\n")

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
# pitch <- extract_pitch(speech, pitch_floor = 75, pitch_ceiling = 600)

# For our test signal, we need to create a more complex sound
# (pure sine waves may not be detected as voiced)
# In real usage with speech:
# mean_f0 <- get_mean_pitch(pitch)
# min_f0 <- get_min_pitch(pitch)
# max_f0 <- get_max_pitch(pitch)

## ----eval = FALSE-------------------------------------------------------------
# # Male voice
# pitch_male <- extract_pitch(sound, pitch_floor = 50, pitch_ceiling = 300)
# 
# # Female voice
# pitch_female <- extract_pitch(sound, pitch_floor = 100, pitch_ceiling = 600)
# 
# # Child voice
# pitch_child <- extract_pitch(sound, pitch_floor = 150, pitch_ceiling = 800)

## ----eval = FALSE-------------------------------------------------------------
# # Get F0 at specific time point
# f0_at_1s <- get_pitch_at_time(pitch, time = 1.0)
# 
# # Get mean F0 over time range
# mean_f0_range <- get_mean_pitch(pitch, time_range = c(0.5, 1.5))
# 
# # Convert to semitones (re 1 Hz)
# f0_semitones <- get_pitch_at_time(pitch, time = 1.0, unit = "semitones")

## -----------------------------------------------------------------------------
# Extract formants (default settings for adult female)
formants <- extract_formants(sound_a4, max_formant = 5500, n_formants = 5)

summary(formants)

## ----eval = FALSE-------------------------------------------------------------
# # Adult male
# formants_male <- extract_formants(sound, max_formant = 5000, n_formants = 5)
# 
# # Adult female
# formants_female <- extract_formants(sound, max_formant = 5500, n_formants = 5)
# 
# # Child
# formants_child <- extract_formants(sound, max_formant = 8000, n_formants = 5)

## -----------------------------------------------------------------------------
# Get F1 and F2 at specific time (vowel quality)
f1 <- get_formant_at_time(formants, formant_number = 1, time = 0.25)
f2 <- get_formant_at_time(formants, formant_number = 2, time = 0.25)

cat("F1:", round(f1, 1), "Hz\n")
cat("F2:", round(f2, 1), "Hz\n")

## -----------------------------------------------------------------------------
# Get mean formant over time range
mean_f1 <- get_mean_formant(formants, formant_number = 1, 
                           time_range = c(0.1, 0.4))
mean_f2 <- get_mean_formant(formants, formant_number = 2, 
                           time_range = c(0.1, 0.4))

cat("Mean F1:", round(mean_f1, 1), "Hz\n")
cat("Mean F2:", round(mean_f2, 1), "Hz\n")

## -----------------------------------------------------------------------------
# Extract intensity
intensity <- extract_intensity(sound_a4, minimum_pitch = 100)

summary(intensity)

## -----------------------------------------------------------------------------
# Mean intensity
mean_db <- get_mean_intensity(intensity)
cat("Mean intensity:", round(mean_db, 2), "dB\n")

# Intensity range
min_db <- get_min_intensity(intensity)
max_db <- get_max_intensity(intensity)
cat("Intensity range:", round(min_db, 2), "-", round(max_db, 2), "dB\n")

# Standard deviation
sd_db <- get_sd_intensity(intensity)
cat("SD intensity:", round(sd_db, 2), "dB\n")

## -----------------------------------------------------------------------------
# Query intensity at time point
int_at_time <- get_intensity_at_time(intensity, time = 0.25)
cat("Intensity at 0.25s:", round(int_at_time, 2), "dB\n")

# With interpolation
int_interp <- get_intensity_at_time(intensity, time = 0.25, interpolate = TRUE)
cat("Intensity (interpolated):", round(int_interp, 2), "dB\n")

## -----------------------------------------------------------------------------
# Convert to data frame
formant_df <- as.data.frame(formants)
head(formant_df)

## -----------------------------------------------------------------------------
intensity_df <- as.data.frame(intensity)
head(intensity_df)

## ----eval = FALSE-------------------------------------------------------------
# # 1. Load sound
# sound <- read_sound("vowel.wav")
# 
# # 2. Extract all analyses
# pitch <- extract_pitch(sound, pitch_floor = 75, pitch_ceiling = 600)
# formants <- extract_formants(sound, max_formant = 5500, n_formants = 5)
# intensity <- extract_intensity(sound, minimum_pitch = 75)
# 
# # 3. Get measurements at vowel midpoint
# midpoint <- get_duration(sound) / 2
# 
# f0 <- get_pitch_at_time(pitch, time = midpoint)
# f1 <- get_formant_at_time(formants, formant_number = 1, time = midpoint)
# f2 <- get_formant_at_time(formants, formant_number = 2, time = midpoint)
# f3 <- get_formant_at_time(formants, formant_number = 3, time = midpoint)
# int <- get_intensity_at_time(intensity, time = midpoint)
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
# # R with speaker
# sound <- read_sound("sound.wav")
# pitch <- extract_pitch(sound, time_step = 0.01,
#                       pitch_floor = 75, pitch_ceiling = 600)
# f0 <- get_mean_pitch(pitch, unit = "Hz")

## ----eval = FALSE-------------------------------------------------------------
# # Fine-tune formant detection
# formants <- extract_formants(
#   sound,
#   time_step = 0.005,           # 5 ms steps
#   max_formant = 5500,          # Adult female range
#   n_formants = 5,              # Track F1-F5
#   window_length = 0.025,       # 25 ms window
#   pre_emphasis_from = 50       # Pre-emphasis from 50 Hz
# )
# 
# # Fine-tune intensity
# intensity <- extract_intensity(
#   sound,
#   time_step = 0.01,            # 10 ms steps
#   minimum_pitch = 75,          # Affects window length
#   subtract_mean = FALSE        # Absolute intensity in dB SPL
# )

## ----eval = FALSE-------------------------------------------------------------
# # Pitch may be NA for unvoiced segments
# f0 <- get_pitch_at_time(pitch, time = 1.0)
# if (is.na(f0)) {
#   cat("Unvoiced at this time point\n")
# } else {
#   cat("F0:", f0, "Hz\n")
# }
# 
# # Mean functions automatically exclude NA
# mean_f0 <- get_mean_pitch(pitch)  # NA values excluded

## -----------------------------------------------------------------------------
# Package version
packageVersion("speaker")

# Citation information
citation("speaker")

