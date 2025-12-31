## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.width = 7,
  fig.height = 5
)

## ----setup--------------------------------------------------------------------
library(pladdrr)
library(ggplot2)

## ----burg-basic---------------------------------------------------------------
# Create or load a sound
sound <- Sound$create_tone(duration = 0.5, sampling_rate = 22050)

# Standard Burg formant extraction
formant_burg <- sound$to_formant_burg(
  time_step = 0.005,                   # 5 ms steps
  max_formants = 5,                    # Track up to F5
  max_frequency = 5500,                # Ceiling (Hz)
  window_length = 0.025,               # 25 ms analysis window
  pre_emphasis_from = 50               # Pre-emphasis from 50 Hz
)

# Query formants
f1 <- formant_burg$get_value_at_time(1, 0.25, unit = "hertz")
f2 <- formant_burg$get_value_at_time(2, 0.25, unit = "hertz")

if (!is.na(f1) && !is.na(f2)) {
  print(paste("F1:", round(f1), "Hz"))
  print(paste("F2:", round(f2), "Hz"))
}

## ----keepall------------------------------------------------------------------
formant_keepall <- sound$to_formant_keepall(
  time_step = 0.005,
  max_formants = 5,                    # Maximum formants to track
  max_frequency = 5500,
  window_length = 0.025,
  pre_emphasis_from = 50
)

## ----compare-keepall-burg-----------------------------------------------------
# Same sound, both methods
formant_b <- sound$to_formant_burg(max_formants = 4)
formant_k <- sound$to_formant_keepall(max_formants = 4)

# Extract F1 and F2
time <- 0.25
f1_burg <- formant_b$get_value_at_time(1, time, unit = "hertz")
f1_keep <- formant_k$get_value_at_time(1, time, unit = "hertz")

f2_burg <- formant_b$get_value_at_time(2, time, unit = "hertz")
f2_keep <- formant_k$get_value_at_time(2, time, unit = "hertz")

# Comparison
if (!any(is.na(c(f1_burg, f1_keep, f2_burg, f2_keep)))) {
  cat("Method Comparison:\n")
  cat(sprintf("  Burg:     F1 = %d Hz, F2 = %d Hz\n", round(f1_burg), round(f2_burg)))
  cat(sprintf("  Keep All: F1 = %d Hz, F2 = %d Hz\n", round(f1_keep), round(f2_keep)))
  cat(sprintf("  Diff:     F1 = %d Hz, F2 = %d Hz\n",
              round(abs(f1_burg - f1_keep)),
              round(abs(f2_burg - f2_keep))))
}

## ----formant-ceiling----------------------------------------------------------
# Adult male
formant_male <- sound$to_formant_burg(
  max_frequency = 5000    # Men: 5000 Hz
)

# Adult female
formant_female <- sound$to_formant_burg(
  max_frequency = 5500    # Women: 5500 Hz
)

# Child
formant_child <- sound$to_formant_burg(
  max_frequency = 8000    # Children: 7000-8000 Hz
)

## ----window-length------------------------------------------------------------
# Short window (better time resolution)
formant_short <- sound$to_formant_burg(window_length = 0.010)  # 10 ms

# Standard window (balanced)
formant_std <- sound$to_formant_burg(window_length = 0.025)    # 25 ms

# Long window (better frequency resolution)
formant_long <- sound$to_formant_burg(window_length = 0.050)   # 50 ms

## ----time-step----------------------------------------------------------------
# Coarse (fast, less detail)
formant_coarse <- sound$to_formant_burg(time_step = 0.010)  # 10 ms

# Standard (good balance)
formant_std <- sound$to_formant_burg(time_step = 0.005)     # 5 ms

# Fine (slow, more detail)
formant_fine <- sound$to_formant_burg(time_step = 0.002)    # 2 ms

## ----num-formants-------------------------------------------------------------
# Track only F1-F2 (faster)
formant_2 <- sound$to_formant_burg(max_formants = 2)

# Standard (F1-F5)
formant_5 <- sound$to_formant_burg(max_formants = 5)

# Extended (up to F7, slower)
formant_7 <- sound$to_formant_burg(
  max_formants = 7,
  max_frequency = 7000
)

## ----no-formants, eval=FALSE--------------------------------------------------
# formant <- sound$to_formant_burg()
# f1 <- formant$get_value_at_time(1, 0.1, unit = "hertz")
# # Returns: NA

## ----lower-ceiling, eval=FALSE------------------------------------------------
# # Try lower maximum frequency
# formant <- sound$to_formant_burg(max_frequency = 4500)

## ----increase-window, eval=FALSE----------------------------------------------
# formant <- sound$to_formant_burg(window_length = 0.050)

## ----check-silent, eval=FALSE-------------------------------------------------
# intensity <- sound$to_intensity()
# mean_intensity <- intensity$get_mean(0, 0, unit = "dB")
# # If < 30 dB, may be too quiet

## ----erratic, eval=FALSE------------------------------------------------------
# # F1 jumps from 500 Hz to 2000 Hz between frames

## ----robust, eval=FALSE-------------------------------------------------------
# formant <- sound$to_formant_robust(
#   smoothing_window = 0.05,      # Smooth over 50 ms
#   max_formant_jump = 200        # Max 200 Hz jump
# )

## ----smooth-window, eval=FALSE------------------------------------------------
# formant <- sound$to_formant_burg(window_length = 0.040)

## ----reduce-step, eval=FALSE--------------------------------------------------
# formant <- sound$to_formant_burg(time_step = 0.002)

## ----wrong-formant, eval=FALSE------------------------------------------------
# # F2 shows values ~3000 Hz (likely F3)

## ----adjust-ceiling, eval=FALSE-----------------------------------------------
# # Lower ceiling may force re-evaluation
# formant <- sound$to_formant_burg(max_frequency = 4800)

## ----try-keepall, eval=FALSE--------------------------------------------------
# formant <- sound$to_formant_keepall(max_formants = 5)

## ----check-bandwidth, eval=FALSE----------------------------------------------
# bandwidth <- formant$get_bandwidth_at_time(2, 0.1, unit = "hertz")
# # Very wide bandwidth may indicate spurious formant

## ----vowel-space, eval=FALSE--------------------------------------------------
# # Analyze multiple vowel tokens
# vowels <- c("vowel_a.wav", "vowel_e.wav", "vowel_i.wav",
#             "vowel_o.wav", "vowel_u.wav")
# 
# vowel_data <- data.frame()
# 
# for (file in vowels) {
#   sound <- Sound$new(file)
#   formant <- sound$to_formant_burg()
# 
#   # Extract at vowel midpoint
#   duration <- sound$get_total_duration()
#   midpoint <- duration / 2
# 
#   f1 <- formant$get_value_at_time(1, midpoint, unit = "hertz")
#   f2 <- formant$get_value_at_time(2, midpoint, unit = "hertz")
# 
#   vowel_data <- rbind(vowel_data, data.frame(
#     vowel = tools::file_path_sans_ext(basename(file)),
#     F1 = f1,
#     F2 = f2
#   ))
# }
# 
# # Plot vowel space
# ggplot(vowel_data, aes(x = F2, y = F1, label = vowel)) +
#   geom_point(size = 3) +
#   geom_text(vjust = -1) +
#   scale_x_reverse() +  # F2 decreases left to right
#   scale_y_reverse() +  # F1 decreases bottom to top
#   labs(title = "Vowel Space",
#        x = "F2 (Hz)", y = "F1 (Hz)") +
#   theme_minimal()

## ----formant-tracking, eval=FALSE---------------------------------------------
# sound <- Sound$new("diphthong.wav")
# formant <- sound$to_formant_burg(time_step = 0.005)
# 
# # Extract F1 and F2 across time
# times <- seq(0, sound$get_total_duration(), by = 0.005)
# f1_values <- sapply(times, function(t) {
#   formant$get_value_at_time(1, t, unit = "hertz")
# })
# f2_values <- sapply(times, function(t) {
#   formant$get_value_at_time(2, t, unit = "hertz")
# })
# 
# # Plot formant tracks
# df <- data.frame(
#   Time = rep(times, 2),
#   Frequency = c(f1_values, f2_values),
#   Formant = rep(c("F1", "F2"), each = length(times))
# )
# 
# ggplot(df, aes(x = Time, y = Frequency, color = Formant)) +
#   geom_line(size = 1) +
#   labs(title = "Formant Tracks",
#        x = "Time (s)", y = "Frequency (Hz)") +
#   theme_minimal()

## ----excitation-formant-------------------------------------------------------
sound <- Sound$create_tone(duration = 0.3, sampling_rate = 22050)

# Method 1: Via Spectrum
spectrum <- sound$to_spectrum()
excitation <- spectrum$to_excitation()
formant_exc <- excitation$to_formant(max_formants = 5)

# Method 2: Via Cochleagram (more complex but robust)
cochlea <- sound$to_cochleagram()
excitation2 <- cochlea$to_excitation(0.15)  # At specific time
formant_exc2 <- excitation2$to_formant(max_formants = 5)

## ----quality-checks, eval=FALSE-----------------------------------------------
# # 1. Check if formants are in expected ranges
# f1 <- formant$get_value_at_time(1, time, unit = "hertz")
# f2 <- formant$get_value_at_time(2, time, unit = "hertz")
# 
# if (!is.na(f1) && !is.na(f2)) {
#   # F1 should be < F2
#   if (f1 >= f2) warning("F1 >= F2, likely error")
# 
#   # Formants should be in typical ranges
#   if (f1 < 200 || f1 > 1200) warning("F1 out of typical range")
#   if (f2 < 700 || f2 > 3500) warning("F2 out of typical range")
# }
# 
# # 2. Check bandwidth (shouldn't be too large)
# b1 <- formant$get_bandwidth_at_time(1, time, unit = "hertz")
# if (!is.na(b1) && b1 > 400) warning("Large F1 bandwidth")
# 
# # 3. Check formant continuity
# f1_prev <- formant$get_value_at_time(1, time - 0.010, unit = "hertz")
# if (!is.na(f1) && !is.na(f1_prev)) {
#   jump <- abs(f1 - f1_prev)
#   if (jump > 300) warning("Large formant jump (>300 Hz)")
# }

## ----session------------------------------------------------------------------
sessionInfo()

