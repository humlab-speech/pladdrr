library(pladdrr)

s <- Sound$new('inst/signalfiles/AVQI/input/sv1.wav')

# Get F0 contour
pitch <- s$to_pitch()
f0_df <- pitch$as_data_frame()
f0_times <- f0_df$time[f0_df$voiced]
f0_values <- f0_df$frequency[f0_df$voiced]

cat("F0 contour:", length(f0_values), "voiced frames\n")

# Detrend + normalize (like tremor.R does)
linear_fit <- lm(f0_values ~ f0_times)
f0_detrended <- f0_values - predict(linear_fit)
mean_f0 <- mean(f0_values)
f0_normalized <- f0_detrended / mean_f0

cat("Normalized F0 range:", min(f0_normalized), "to", max(f0_normalized), "\n\n")

# Resample to 200 Hz
time_step <- 0.005
sample_rate <- 1 / time_step
n_uniform <- floor((max(f0_times) - min(f0_times)) * sample_rate) + 1
time_uniform <- seq(min(f0_times), by = time_step, length.out = n_uniform)
f0_uniform <- approx(f0_times, f0_normalized, time_uniform)$y

# Create Sound from normalized F0
f0_sound <- Sound$from_values(
  values = matrix(f0_uniform, nrow = 1),
  sampling_rate = sample_rate,
  start_time = min(f0_times)
)

cat("Created F0 Sound, duration:", f0_sound$get_duration(), "s\n")

# Create Pitch from F0 Sound
f0_pitch <- f0_sound$to_pitch(
  time_step = time_step,
  pitch_floor = 1.5,
  pitch_ceiling = 15
)

cat("Created F0 Pitch\n\n")

# Get intensity data
f0_pitch_df <- f0_pitch$as_data_frame(include_intensity = TRUE, include_strength = TRUE)

cat("===== INTENSITY VALUES =====\n")
cat("Frames with data:", nrow(f0_pitch_df), "\n")
cat("intensity[1]:", f0_pitch_df$intensity[1], "\n")
cat("max(intensity):", max(f0_pitch_df$intensity, na.rm=T), "\n")
cat("mean(intensity):", mean(f0_pitch_df$intensity, na.rm=T), "\n")
cat("strength[1]:", f0_pitch_df$strength[1], "\n")
cat("max(strength):", max(f0_pitch_df$strength, na.rm=T), "\n\n")

cat("First 10 frames:\n")
print(head(f0_pitch_df[, c("time", "frequency", "intensity", "strength")], 10))
