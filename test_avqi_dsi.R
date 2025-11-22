library(speaker)

# Create a simple test sound (sine wave)
sr <- 16000
duration <- 3.0
sound <- Sound$create(
  xmin = 0,
  xmax = duration,
  nx = as.integer(duration * sr),
  dx = 1.0 / sr,
  x1 = 0.5 / sr,
  formula = "0.5 * sin(2*pi*150*x)"
)

cat("Sound created successfully\n")
cat("Duration:", sound$get_total_duration(), "s\n")
cat("Sampling rate:", sound$get_sampling_frequency(), "Hz\n")

# Test AVQI components individually
cat("\n=== Testing AVQI Components ===\n")

# 1. Pitch
pitch <- sound$to_pitch_cc(
  time_step = 0.01,
  pitch_floor = 75,
  pitch_ceiling = 600
)
cat("Pitch mean:", pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz"), "Hz\n")

# 2. Harmonicity
harmonicity <- sound$to_harmonicity_cc(
  time_step = 0.01,
  minimum_pitch = 75,
  silence_threshold = 0.1,
  periods_per_window = 1.0
)
hnr <- harmonicity$get_mean(from_time = 0, to_time = 0)
cat("HNR:", hnr, "dB\n")

# 3. PowerCepstrogram and CPPS
cepstrogram <- sound$to_power_cepstrogram(
  pitch_floor = 60,
  time_step = 0.002,
  max_frequency = 5000,
  pre_emphasis_from = 50
)
cpps <- cepstrogram$get_cpps()
cat("CPPS:", cpps, "dB\n")

# 4. PointProcess and Voice Report
pp <- sound$to_point_process_cc(pitch)
voice_report <- pp$voice_report(sound, pitch)
cat("Shimmer Local:", voice_report$shimmer_local * 100, "%\n")
cat("Shimmer Local dB:", voice_report$shimmer_local_db, "dB\n")
cat("Jitter ppq5:", voice_report$jitter_ppq5 * 100, "%\n")

# 5. LTAS
ltas <- sound$to_ltas(bandwidth = 100)
slope <- ltas$get_slope(
  low_band_min = 0,
  low_band_max = 1000,
  high_band_min = 1000,
  high_band_max = 5000,
  method = "energy"
)
cat("LTAS Slope:", slope, "dB\n")

cat("\n=== All AVQI/DSI components tested successfully! ===\n")

# Now test high-level functions
cat("\n=== Testing compute_avqi() ===\n")
tryCatch({
  result <- compute_avqi(sound, type = "vowel", verbose = TRUE)
  cat("AVQI Score:", result$avqi, "\n")
  cat("Components:\n")
  print(result$components)
}, error = function(e) {
  cat("Error in compute_avqi():", conditionMessage(e), "\n")
})

cat("\n=== Testing compute_dsi() ===\n")
tryCatch({
  result <- compute_dsi(sound, verbose = TRUE)
  cat("DSI Score:", result$dsi, "\n")
  cat("Components:\n")
  print(result$components)
}, error = function(e) {
  cat("Error in compute_dsi():", conditionMessage(e), "\n")
})

cat("\n=== Test Complete ===\n")
