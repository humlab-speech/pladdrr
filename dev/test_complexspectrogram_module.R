#!/usr/bin/env Rscript
# Test script for ComplexSpectrogram module

library(pladdrr)

cat("Testing ComplexSpectrogram module...\n\n")

# Create test sound
cat("1. Creating test Sound (1000 Hz tone)...\n")
sound <- sound_create_formula("tone", 0, 1, 44100, "0.5 * sin(2*pi*1000*x)")

cat("   Sound duration:", sound$get_total_duration(), "s\n\n")

# Create ComplexSpectrogram
cat("2. Creating ComplexSpectrogram...\n")
cs <- sound$to_complex_spectrogram(window_length = 0.005, maximum_frequency = 5000)

cat("   Time domain: [", cs$xmin(), ", ", cs$xmax(), "] s\n", sep="")
cat("   Freq domain: [", cs$ymin(), ", ", cs$ymax(), "] Hz\n", sep="")
cat("   Time frames:", cs$nx(), "\n")
cat("   Freq bins:", cs$ny(), "\n\n")

# Query amplitude and phase
cat("3. Testing query methods...\n")
amp <- cs$get_amplitude(0.5, 1000)
phase <- cs$get_phase(0.5, 1000)
cat("   Amplitude at t=0.5s, f=1000Hz:", amp, "\n")
cat("   Phase at t=0.5s, f=1000Hz:", phase, "\n\n")

# Convert to Spectrogram
cat("4. Converting to Spectrogram...\n")
spec <- cs$to_spectrogram()
cat("   Spectrogram created: nx =", spec$get_nx(), "\n\n")

# Convert to Spectrum at a time
cat("5. Converting to Spectrum at t=0.5s...\n")
spectrum <- cs$to_spectrum(0.5)
cat("   Spectrum created: nx =", spectrum$get_number_of_bins(), "\n\n")

# Resynthesize to Sound
cat("6. Resynthesizing to Sound (stretch=1.0)...\n")
resynthesized <- cs$to_sound(stretch_factor = 1.0)
cat("   Resynthesized duration:", resynthesized$get_total_duration(), "s\n\n")

# Export to data.frame
cat("7. Exporting to data.frame...\n")
df <- as.data.frame(cs)
cat("   Data frame dimensions:", nrow(df), "rows x", ncol(df), "cols\n")
cat("   Columns:", paste(names(df), collapse=", "), "\n")
cat("   First few rows:\n")
print(head(df, 3))

cat("\nAll tests completed successfully!\n")
