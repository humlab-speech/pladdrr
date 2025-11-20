#!/usr/bin/env Rscript
# Test PowerCepstrum implementation

library(speaker)

cat("Testing PowerCepstrum implementation...\n\n")

# Create a test sound
cat("1. Creating test tone...\n")
tone <- Sound$create_tone(duration = 1.0, frequency = 440, sampling_rate = 44100)
cat("   Duration:", tone$get_duration(), "seconds\n")

# Convert to spectrum
cat("\n2. Converting to Spectrum...\n")
spectrum <- tone$to_spectrum()
cat("   Frequency range:", spectrum$get_lowest_frequency(), "-", 
    spectrum$get_highest_frequency(), "Hz\n")

# Convert to PowerCepstrum
cat("\n3. Converting to PowerCepstrum...\n")
tryCatch({
  cepstrum <- spectrum$to_powercepstrum()
  cat("   ✓ PowerCepstrum created successfully\n")
  
  # Test CPP extraction
  cat("\n4. Getting CPP (Cepstral Peak Prominence)...\n")
  cpp <- cepstrum$get_peak_prominence()
  cat("   CPP:", round(cpp, 2), "dB\n")
  
  # Test quefrency of peak
  cat("\n5. Getting quefrency of peak...\n")
  qpeak <- cepstrum$get_quefrency_of_peak()
  cat("   Quefrency:", round(qpeak, 4), "seconds\n")
  
  cat("\n✓ PowerCepstrum tests PASSED\n")
}, error = function(e) {
  cat("   ✗ Error:", e$message, "\n")
})

# Test PowerCepstrogram
cat("\n6. Testing PowerCepstrogram from Sound...\n")
tryCatch({
  cepstrogram <- tone$to_powercepstrogram(pitch_floor = 60)
  cat("   ✓ PowerCepstrogram created successfully\n")
  
  # Get mean CPP
  cat("\n7. Getting mean CPP over time...\n")
  mean_cpp <- cepstrogram$get_mean_cpp()
  cat("   Mean CPP:", round(mean_cpp, 2), "dB\n")
  
  # Get CPP at specific time
  cat("\n8. Getting CPP at 0.5 seconds...\n")
  cpp_at_time <- cepstrogram$get_cpp_at_time(time = 0.5)
  cat("   CPP at 0.5s:", round(cpp_at_time, 2), "dB\n")
  
  cat("\n✓ PowerCepstrogram tests PASSED\n")
}, error = function(e) {
  cat("   ✗ Error:", e$message, "\n")
})

cat("\n=== ALL TESTS COMPLETE ===\n")
