#!/usr/bin/env Rscript
# Test script for new plot() S3 methods - Phase 1 Plotting

library(pladdrr)

# Create test audio
cat("Creating test sound...\n")
sound <- generate_sine_wave(frequency = 440, duration = 1.0, sampling_rate = 44100)

# Test 1: Plot Sound
cat("\n=== Test 1: plot.Sound() ===\n")
tryCatch({
  p <- plot(sound)
  print("✓ plot.Sound() works")
  print(class(p))
}, error = function(e) {
  cat("✗ plot.Sound() failed:", conditionMessage(e), "\n")
})

# Test 2: Plot Pitch
cat("\n=== Test 2: plot.Pitch() ===\n")
tryCatch({
  pitch <- sound$to_pitch()
  p <- plot(pitch)
  print("✓ plot.Pitch() works")
  print(class(p))
}, error = function(e) {
  cat("✗ plot.Pitch() failed:", conditionMessage(e), "\n")
})

# Test 3: Plot Formant
cat("\n=== Test 3: plot.Formant() ===\n")
tryCatch({
  formant <- sound$to_formant_burg()
  p <- plot(formant, max_formant = 3)
  print("✓ plot.Formant() works")
  print(class(p))
}, error = function(e) {
  cat("✗ plot.Formant() failed:", conditionMessage(e), "\n")
})

# Test 4: Plot Intensity
cat("\n=== Test 4: plot.Intensity() ===\n")
tryCatch({
  intensity <- sound$to_intensity()
  p <- plot(intensity)
  print("✓ plot.Intensity() works")
  print(class(p))
}, error = function(e) {
  cat("✗ plot.Intensity() failed:", conditionMessage(e), "\n")
})

# Test 5: Plot Spectrogram
cat("\n=== Test 5: plot.Spectrogram() ===\n")
tryCatch({
  spectrogram <- sound$to_spectrogram()
  p <- plot(spectrogram, to_freq = 5000)
  print("✓ plot.Spectrogram() works")
  print(class(p))
}, error = function(e) {
  cat("✗ plot.Spectrogram() failed:", conditionMessage(e), "\n")
})

# Test 6: Plot Spectrum
cat("\n=== Test 6: plot.Spectrum() ===\n")
tryCatch({
  spectrum <- sound$to_spectrum()
  p <- plot(spectrum)
  print("✓ plot.Spectrum() works")
  print(class(p))
}, error = function(e) {
  cat("✗ plot.Spectrum() failed:", conditionMessage(e), "\n")
})

# Test 7: Plot Ltas
cat("\n=== Test 7: plot.Ltas() ===\n")
tryCatch({
  ltas <- sound$to_ltas(bandwidth = 100)
  p <- plot(ltas)
  print("✓ plot.Ltas() works")
  print(class(p))
}, error = function(e) {
  cat("✗ plot.Ltas() failed:", conditionMessage(e), "\n")
})

# Test 8: Plot Harmonicity
cat("\n=== Test 8: plot.Harmonicity() ===\n")
tryCatch({
  harmonicity <- sound$to_harmonicity_cc()
  p <- plot(harmonicity)
  print("✓ plot.Harmonicity() works")
  print(class(p))
}, error = function(e) {
  cat("✗ plot.Harmonicity() failed:", conditionMessage(e), "\n")
})

# Test 9: Plot PointProcess
cat("\n=== Test 9: plot.PointProcess() ===\n")
tryCatch({
  pulses <- sound$to_pointprocess_periodic_cc()
  p <- plot(pulses)
  print("✓ plot.PointProcess() works")
  print(class(p))
}, error = function(e) {
  cat("✗ plot.PointProcess() failed:", conditionMessage(e), "\n")
})

cat("\n=== All tests completed ===\n")
