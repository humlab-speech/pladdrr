# Test periodic PointProcess methods

library(pladdrr)

# Load test audio
audio_file <- system.file("extdata", "test.wav", package = "pladdrr")
cat("Loading audio:", audio_file, "\n")
sound <- Sound$new(audio_file)

cat("Created sound: duration =", sound$get_duration(), "s\n")

# Test periodic_cc method
cat("\n=== Testing to_pointprocess_periodic_cc ===\n")
tryCatch({
  pp_cc <- sound$to_pointprocess_periodic_cc(
    pitch_floor = 75,
    pitch_ceiling = 300
  )
  cat("PointProcess (cc) created successfully\n")
  cat("Number of points:", pp_cc$get_number_of_points(), "\n")
  
  # Get some voice quality metrics
  jitter_local <- pp_cc$get_jitter_local(0, 0, 0.0001, 0.02, 1.3)
  cat("Jitter (local):", jitter_local, "\n")
}, error = function(e) {
  cat("ERROR:", conditionMessage(e), "\n")
})

# Test periodic_peaks method
cat("\n=== Testing to_pointprocess_periodic_peaks ===\n")
tryCatch({
  pp_peaks <- sound$to_pointprocess_periodic_peaks(
    pitch_floor = 75,
    pitch_ceiling = 300,
    include_maxima = TRUE,
    include_minima = FALSE
  )
  cat("PointProcess (peaks) created successfully\n")
  cat("Number of points:", pp_peaks$get_number_of_points(), "\n")
}, error = function(e) {
  cat("ERROR:", conditionMessage(e), "\n")
})

cat("\n✅ Test complete\n")
