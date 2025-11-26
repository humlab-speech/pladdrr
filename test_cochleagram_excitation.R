# Test script for Cochleagram and Excitation objects
# Version 1.0.0 feature test

library(pladdrr)

cat("Testing Cochleagram and Excitation objects\n")
cat("==========================================\n\n")

# Create a test sound
cat("1. Creating test sound (sine wave)...\n")
sound <- Sound$from_values(
  values = sin(2 * pi * 440 * seq(0, 1, length.out = 44100)),
  sampling_frequency = 44100
)
cat("   Sound created: duration =", sound$get_total_duration(), "seconds\n\n")

# Test Cochleagram creation
cat("2. Creating Cochleagram (standard method)...\n")
tryCatch({
  cochlea <- sound$to_cochleagram(
    dt = 0.01,
    df = 0.1,
    window_length = 0.03,
    forward_masking_time = 0.03
  )
  cat("   Success! Cochleagram object created\n")
  cat("   "); print(cochlea)
  
  # Test cochleagram methods
  cat("\n3. Testing Cochleagram methods...\n")
  info <- cochlea$get_info()
  cat("   - Time domain:", info$xmin, "to", info$xmax, "seconds\n")
  cat("   - Frequency domain:", info$ymin, "to", info$ymax, "Bark\n")
  cat("   - Number of time samples:", info$nx, "\n")
  cat("   - Number of frequency bands:", info$ny, "\n")
  
  # Get value at specific point
  value <- cochlea$get_value_at_time_and_frequency(0.5, 8.0)
  cat("   - Value at t=0.5s, f=8 Bark:", value, "\n")
  
  # Export as matrix
  mat_data <- cochlea$as_matrix()
  cat("   - Matrix export: dimensions", dim(mat_data$values), "\n")
  
}, error = function(e) {
  cat("   ERROR:", conditionMessage(e), "\n")
})

# Test Excitation from cochleagram
cat("\n4. Creating Excitation from Cochleagram...\n")
tryCatch({
  excitation <- cochlea$to_excitation(time = 0.5)
  cat("   Success! Excitation object created\n")
  cat("   "); print(excitation)
  
  # Test excitation methods
  cat("\n5. Testing Excitation methods...\n")
  loudness <- excitation$get_loudness()
  cat("   - Total loudness:", loudness, "sones\n")
  
  exc_value <- excitation$get_value_at_frequency(8.0)
  cat("   - Excitation at 8 Bark:", exc_value, "\n")
  
  # Export as vector
  exc_data <- excitation$as_vector()
  cat("   - Vector export:", nrow(exc_data), "frequency points\n")
  
}, error = function(e) {
  cat("   ERROR:", conditionMessage(e), "\n")
})

# Test Excitation from spectrum
cat("\n6. Creating Excitation from Spectrum...\n")
tryCatch({
  spectrum <- sound$to_spectrum()
  excitation2 <- spectrum$to_excitation(erb_density = 0.1)
  cat("   Success! Excitation from Spectrum created\n")
  cat("   "); print(excitation2)
  
  # Compare two excitations
  if (exists("excitation") && exists("excitation2")) {
    distance <- excitation$get_distance(excitation2)
    cat("   - Perceptual distance:", distance, "\n")
  }
  
}, error = function(e) {
  cat("   ERROR:", conditionMessage(e), "\n")
})

# Test EDB cochleagram method
cat("\n7. Testing Cochleagram EDB method...\n")
tryCatch({
  cochlea_edb <- sound$to_cochleagram_edb(
    dtime = 0.01,
    dfreq = 0.1,
    has_synapse = TRUE,
    replenishment_rate = 0.01,
    loss_rate = 0.1,
    return_rate = 0.05,
    reprocessing_rate = 0.01
  )
  cat("   Success! EDB Cochleagram created\n")
  cat("   "); print(cochlea_edb)
  
  # Compare standard vs EDB
  if (exists("cochlea") && exists("cochlea_edb")) {
    diff <- cochlea$get_difference(cochlea_edb, tmin = 0, tmax = 0)
    cat("   - Difference (standard vs EDB):", diff, "\n")
  }
  
}, error = function(e) {
  cat("   ERROR:", conditionMessage(e), "\n")
})

cat("\n==========================================\n")
cat("All tests completed!\n")
cat("Package version:", packageVersion("pladdrr"), "\n")
