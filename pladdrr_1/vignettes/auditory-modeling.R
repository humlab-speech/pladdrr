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

## ----cochleagram-basic--------------------------------------------------------
# Load or create a sound
sound <- Sound$create_tone(frequency = 440, duration = 0.5, sampling_rate = 22050)

# Create cochleagram
cochlea <- sound$to_cochleagram(
  dt = 0.01,                    # Time step (10 ms)
  df = 0.1,                     # Frequency step in Bark
  window_length = 0.025,        # Analysis window (25 ms)
  forward_masking_time = 0.03   # Temporal masking (30 ms)
)

## ----bark-conversion, eval=FALSE----------------------------------------------
# # Common frequency conversions
# # F1 (250 Hz) ≈ 2.5 Bark
# # F2 (2000 Hz) ≈ 15 Bark
# # F3 (3000 Hz) ≈ 19 Bark

## ----cochleagram-query--------------------------------------------------------
# Get excitation at specific time and frequency
# 440 Hz ≈ 4.2 Bark
excitation_440hz <- cochlea$get_value_at_time_and_frequency(
  time = 0.25,      # At 250 ms
  freq_bark = 4.2   # ~440 Hz
)

print(paste("Excitation at 440 Hz:", round(excitation_440hz, 4)))

## ----cochleagram-plot, eval=FALSE---------------------------------------------
# # Export to matrix for plotting
# cochlea_matrix <- cochlea$as_matrix()
# 
# # Convert to long format for ggplot2
# library(reshape2)
# df_long <- melt(as.matrix(cochlea_matrix))
# names(df_long) <- c("Time", "Bark", "Excitation")
# 
# # Plot
# ggplot(df_long, aes(x = Time, y = Bark, fill = Excitation)) +
#   geom_raster() +
#   scale_fill_viridis_c(option = "inferno") +
#   labs(
#     title = "Cochleagram of 440 Hz Tone",
#     x = "Time (s)",
#     y = "Frequency (Bark)",
#     fill = "Excitation"
#   ) +
#   theme_minimal()

## ----cochleagram-edb, eval=FALSE----------------------------------------------
# cochlea_edb <- sound$to_cochleagram_edb(
#   dtime = 0.01,
#   dfreq = 0.1,
#   has_synapse = TRUE,         # Include synaptic adaptation
#   replenishment_rate = 0.01,  # Neurotransmitter replenishment
#   loss_rate = 0.1,            # Synaptic depletion
#   return_rate = 0.05,         # Recovery rate
#   reprocessing_rate = 0.01    # Reprocessing rate
# )

## ----excitation-spectrum------------------------------------------------------
# Create excitation from spectrum
spectrum <- sound$to_spectrum()
excitation <- spectrum$to_excitation(erb_density = 0.1)

# Get perceptual loudness
loudness <- excitation$get_loudness()
print(paste("Loudness:", round(loudness, 2), "sones"))

## ----excitation-cochlea-------------------------------------------------------
# Extract excitation pattern at t = 0.25s
excitation_t <- cochlea$to_excitation(0.25)

# Query excitation at specific frequency
exc_value <- excitation_t$get_value_at_frequency(4.2)  # ~440 Hz
print(paste("Excitation at 440 Hz:", round(exc_value, 4)))

## ----excitation-distance------------------------------------------------------
# Create two different sounds
sound1 <- Sound$create_tone(frequency = 440, duration = 0.2, sampling_rate = 22050)
sound2 <- Sound$create_tone(frequency = 550, duration = 0.2, sampling_rate = 22050)

# Get excitation patterns
exc1 <- sound1$to_spectrum()$to_excitation()
exc2 <- sound2$to_spectrum()$to_excitation()

# Calculate perceptual distance
distance <- exc1$get_distance(exc2)
print(paste("Perceptual distance:", round(distance, 4)))

## ----hearing-loss, eval=FALSE-------------------------------------------------
# # Original speech sound
# sound_original <- Sound$new("speech.wav")
# 
# # Simulate high-frequency hearing loss by filtering
# sound_filtered <- sound_original$clone()
# # Apply low-pass filter to simulate hearing loss
# # (filter implementation would go here)
# 
# # Create cochleagrams
# cochlea_normal <- sound_original$to_cochleagram()
# cochlea_impaired <- sound_filtered$to_cochleagram()
# 
# # Calculate perceptual difference
# difference <- cochlea_normal$get_difference(
#   cochlea_impaired,
#   tmin = 0,
#   tmax = 0  # Full duration
# )
# 
# print(paste("Hearing loss impact (distance):", round(difference, 4)))

## ----intelligibility, eval=FALSE----------------------------------------------
# # Clean speech
# speech_clean <- Sound$new("clean_speech.wav")
# 
# # Noisy speech
# speech_noisy <- Sound$new("noisy_speech.wav")
# 
# # Get excitation patterns
# exc_clean <- speech_clean$to_spectrum()$to_excitation()
# exc_noisy <- speech_noisy$to_spectrum()$to_excitation()
# 
# # Perceptual distance correlates with intelligibility loss
# distance <- exc_clean$get_distance(exc_noisy)
# 
# # Lower distance = better preserved intelligibility

## ----loudness-recruitment, eval=FALSE-----------------------------------------
# # Create sounds at different levels
# intensities <- seq(40, 80, by = 10)  # dB SPL
# loudnesses <- numeric(length(intensities))
# 
# for (i in seq_along(intensities)) {
#   # Create sound at specific level
#   sound <- create_calibrated_sound(intensities[i])
# 
#   # Measure perceptual loudness
#   excitation <- sound$to_spectrum()$to_excitation()
#   loudnesses[i] <- excitation$get_loudness()
# }
# 
# # Plot loudness growth function
# plot(intensities, loudnesses,
#      xlab = "Intensity (dB SPL)",
#      ylab = "Loudness (sones)",
#      main = "Loudness Growth Function",
#      type = "b")

## ----formant-from-excitation--------------------------------------------------
# Create vowel sound
sound_vowel <- Sound$create_tone(duration = 0.2, sampling_rate = 22050)

# Get excitation pattern
excitation <- sound_vowel$to_spectrum()$to_excitation()

# Extract formants from excitation pattern
formant <- excitation$to_formant(max_formants = 5)

# Query formants
f1 <- formant$get_value_at_time(1, 0.1, unit = "hertz")
f2 <- formant$get_value_at_time(2, 0.1, unit = "hertz")

if (!is.na(f1) && !is.na(f2)) {
  print(paste("F1:", round(f1), "Hz"))
  print(paste("F2:", round(f2), "Hz"))
}

## ----performance, eval=FALSE--------------------------------------------------
# # For batch processing, reuse objects when possible
# sounds <- list(sound1, sound2, sound3)
# 
# # Good: vectorized approach
# cochleagrams <- lapply(sounds, function(s) {
#   s$to_cochleagram(dt = 0.01, df = 0.1)
# })
# 
# # Extract loudness from all
# loudnesses <- sapply(cochleagrams, function(c) {
#   c$get_loudness_at_time(0.1)
# })

## ----memory, eval=FALSE-------------------------------------------------------
# # Process and extract only what you need
# cochlea <- sound$to_cochleagram()
# loudness_time_series <- sapply(seq(0, 0.5, by = 0.01), function(t) {
#   cochlea$get_loudness_at_time(t)
# })
# 
# # Remove large object if no longer needed
# rm(cochlea)
# gc()  # Force garbage collection

## ----session------------------------------------------------------------------
sessionInfo()

