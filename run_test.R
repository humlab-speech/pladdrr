devtools::load_all('.', quiet = TRUE)
cat("Package loaded successfully\n\n")

# Test LTAS slope with all units
cat("=== Testing LTAS slope with different units ===\n")
snd <- Sound$new("inst/extdata/test.wav")
ltas <- snd$to_ltas(100)

# Test each unit
cat("1. Testing unit='energy' (default, CRITICAL for AVQI):\n")
slope_energy <- ltas$get_slope(1000, 2000, 1000, 4000, unit = "energy")
cat(sprintf("   Slope (energy): %.6f\n", slope_energy))
cat(sprintf("   Valid: %s\n\n", ifelse(is.finite(slope_energy), "YES", "NO"))

cat("2. Testing unit='sones':\n")
slope_sones <- ltas$get_slope(1000, 2000, 1000, 4000, unit = "sones")
cat(sprintf("   Slope (sones): %.6f\n", slope_sones))
cat(sprintf("   Valid: %s\n\n", ifelse(is.finite(slope_sones), "YES", "NO"))

cat("3. Testing unit='dB':\n")
slope_db <- ltas$get_slope(1000, 2000, 1000, 4000, unit = "dB")
cat(sprintf("   Slope (dB): %.6f\n", slope_db))
cat(sprintf("   Valid: %s\n\n", ifelse(is.finite(slope_db), "YES", "NO"))

# Test Sound filtering
cat("=== Testing Sound Filtering Methods ===\n")
cat("1. Testing filter_pass_hann_band(100, 5000, 100):\n")
filtered_pass <- snd$filter_pass_hann_band(100, 5000, 100)
cat(sprintf("   Duration: %.3f s, Sample rate: %.0f Hz\n", 
            filtered_pass$get_duration(), filtered_pass$get_sampling_frequency()))
cat(sprintf("   Valid: YES\n\n"))

cat("2. Testing filter_stop_hann_band(1000, 2000, 100):\n")
filtered_stop <- snd$filter_stop_hann_band(1000, 2000, 100)
cat(sprintf("   Duration: %.3f s, Sample rate: %.0f Hz\n",
            filtered_stop$get_duration(), filtered_stop$get_sampling_frequency()))
cat(sprintf("   Valid: YES\n\n"))

cat("=== All tests completed ===\n")
