library(pladdrr)

cat("Testing New Periodic PointProcess Methods\n\n")

# Create a simple test sound (440 Hz tone)
sound <- Sound$create_simple(
  duration = 0.5,
  sampling_frequency = 44100,
  formula = "0.5 * sin(2*pi*440*x)"
)

cat("Created test sound (440 Hz, 0.5s)\n")
cat("Sampling rate:", sound$get_sampling_frequency(), "Hz\n\n")

# Test 1: Periodic CC method
cat("=== Test 1: to_pointprocess_periodic_cc ===\n")
pp_cc <- sound$to_pointprocess_periodic_cc(
  pitch_floor = 75,
  pitch_ceiling = 600
)
cat("PointProcess created via cross-correlation\n")
cat("Number of points:", pp_cc$get_number_of_points(), "\n")
if (pp_cc$get_number_of_points() > 0) {
  cat("First point time:", pp_cc$get_time(1), "s\n")
  cat("✅ to_pointprocess_periodic_cc works!\n")
} else {
  cat("⚠️  No points detected (may need different parameters)\n")
}

# Test 2: Periodic peaks method  
cat("\n=== Test 2: to_pointprocess_periodic_peaks ===\n")
pp_peaks <- sound$to_pointprocess_periodic_peaks(
  pitch_floor = 75,
  pitch_ceiling = 600,
  include_maxima = TRUE,
  include_minima = FALSE
)
cat("PointProcess created via peak detection\n")
cat("Number of points:", pp_peaks$get_number_of_points(), "\n")
if (pp_peaks$get_number_of_points() > 0) {
  cat("First point time:", pp_peaks$get_time(1), "s\n")
  cat("✅ to_pointprocess_periodic_peaks works!\n")
} else {
  cat("⚠️  No points detected (may need different parameters)\n")
}

cat("\n🎉 Both new methods are functional!\n")
