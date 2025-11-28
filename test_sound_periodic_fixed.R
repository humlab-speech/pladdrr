library(pladdrr)

cat("Testing Sound Periodic PointProcess Methods\n\n")

# Create test sound using create_tone (which exists)
cat("Creating test sound (440 Hz tone)...\n")
sound <- Sound$create_tone(
  duration = 0.5,
  frequency = 440,
  sampling_frequency = 22050,
  amplitude = 0.5
)
cat("Sound created. Duration:", sound$get_total_duration(), "s\n\n")

# Test periodic_cc
cat("=== Test 1: to_pointprocess_periodic_cc ===\n")
tryCatch({
  pp_cc <- sound$to_pointprocess_periodic_cc(
    pitch_floor = 75,
    pitch_ceiling = 600
  )
  cat("✅ Method works!\n")
  cat("PointProcess created. Number of points:", pp_cc$get_number_of_points(), "\n")
  if (pp_cc$get_number_of_points() > 0) {
    cat("First point at:", pp_cc$get_time(1), "s\n")
  }
}, error = function(e) {
  cat("❌ ERROR:", conditionMessage(e), "\n")
})

# Test periodic_peaks
cat("\n=== Test 2: to_pointprocess_periodic_peaks ===\n")
tryCatch({
  pp_peaks <- sound$to_pointprocess_periodic_peaks(
    pitch_floor = 75,
    pitch_ceiling = 600,
    include_maxima = TRUE,
    include_minima = FALSE
  )
  cat("✅ Method works!\n")
  cat("PointProcess created. Number of points:", pp_peaks$get_number_of_points(), "\n")
  if (pp_peaks$get_number_of_points() > 0) {
    cat("First point at:", pp_peaks$get_time(1), "s\n")
  }
}, error = function(e) {
  cat("❌ ERROR:", conditionMessage(e), "\n")
})

cat("\n🎉 All tests completed!\n")
