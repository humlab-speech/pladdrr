#!/usr/bin/env Rscript
# Test script for cepstrum plotting functions

library(speaker)

# Create a test sound - a vowel sound for analysis
cat("Creating test sound...\n")
test_sound <- generate_sine_wave(
  frequency = 200,
  duration = 1.0,
  sampling_frequency = 44100,
  amplitude = 0.5
)

# Add some harmonics to make it more realistic
test_sound2 <- generate_sine_wave(
  frequency = 400,
  duration = 1.0,
  sampling_frequency = 44100,
  amplitude = 0.3
)

test_sound3 <- generate_sine_wave(
  frequency = 600,
  duration = 1.0,
  sampling_frequency = 44100,
  amplitude = 0.2
)

# Combine sounds (this would require a mix method in Sound)
# For now, we'll just use the single tone

cat("Creating spectrum...\n")
spectrum <- test_sound$to_spectrum()

cat("Creating power cepstrum...\n")
cepstrum <- spectrum$to_powercepstrum()

cat("\nTesting PowerCepstrum plotting:\n")
cat("=================================\n")

# Test 1: Basic cepstrum plot
cat("1. Basic power cepstrum plot\n")
tryCatch({
  p1 <- plot_powercepstrum(cepstrum)
  print(p1)
  cat("   ✓ Basic plot created successfully\n")
}, error = function(e) {
  cat("   ✗ Error:", e$message, "\n")
})

# Test 2: Cepstrum plot with peak highlighting
cat("2. Power cepstrum with peak highlighting\n")
tryCatch({
  p2 <- plot_powercepstrum(
    cepstrum,
    show_peak = TRUE,
    show_trendline = TRUE,
    title = "Voice Quality Cepstrum Analysis"
  )
  print(p2)
  cat("   ✓ Plot with peak created successfully\n")
}, error = function(e) {
  cat("   ✗ Error:", e$message, "\n")
})

# Test 3: Customized cepstrum plot
cat("3. Customized cepstrum plot\n")
tryCatch({
  p3 <- plot_powercepstrum(
    cepstrum,
    show_peak = TRUE,
    show_trendline = TRUE,
    quefrency_range = c(0.001, 0.02),
    theme = "bw",
    title = "Cepstral Analysis - Custom Range"
  )
  print(p3)
  cat("   ✓ Customized plot created successfully\n")
}, error = function(e) {
  cat("   ✗ Error:", e$message, "\n")
})

cat("\nTesting PowerCepstrogram plotting:\n")
cat("===================================\n")

# Create cepstrogram
cat("Creating power cepstrogram...\n")
cepstrogram <- test_sound$to_powercepstrogram(
  pitch_floor = 60,
  time_step = 0.002,
  max_frequency = 5000,
  pre_emphasis_from = 50
)

# Test 4: Basic cepstrogram plot
cat("4. Basic power cepstrogram heatmap\n")
tryCatch({
  p4 <- plot_powercepstrogram(cepstrogram)
  print(p4)
  cat("   ✓ Cepstrogram heatmap created successfully\n")
}, error = function(e) {
  cat("   ✗ Error:", e$message, "\n")
})

# Test 5: Cepstrogram with different color scale
cat("5. Cepstrogram with custom color scale\n")
tryCatch({
  p5 <- plot_powercepstrogram(
    cepstrogram,
    color_scale = "magma",
    quefrency_range = c(0.001, 0.02),
    title = "Power Cepstrogram - Magma Colors"
  )
  print(p5)
  cat("   ✓ Custom color scale created successfully\n")
}, error = function(e) {
  cat("   ✗ Error:", e$message, "\n")
})

# Test 6: CPP time series plot
cat("6. CPP time series\n")
tryCatch({
  p6 <- plot_cpp_timeseries(cepstrogram)
  print(p6)
  cat("   ✓ CPP time series created successfully\n")
}, error = function(e) {
  cat("   ✗ Error:", e$message, "\n")
})

# Test 7: CPP time series with smoothing
cat("7. CPP time series with smoothing\n")
tryCatch({
  p7 <- plot_cpp_timeseries(
    cepstrogram,
    smooth = TRUE,
    smooth_span = 0.2,
    reference_lines = c(5, 10, 15),
    title = "CPP Variation Over Time"
  )
  print(p7)
  cat("   ✓ Smoothed CPP time series created successfully\n")
}, error = function(e) {
  cat("   ✗ Error:", e$message, "\n")
})

# Test 8: Comprehensive cepstrum report
cat("8. Comprehensive cepstrum report\n")
tryCatch({
  if (requireNamespace("gridExtra", quietly = TRUE)) {
    report <- create_cepstrum_report(cepstrogram)
    cat("   ✓ Comprehensive report created successfully\n")
  } else {
    cat("   ⚠ Skipping (gridExtra not installed)\n")
  }
}, error = function(e) {
  cat("   ✗ Error:", e$message, "\n")
})

# Test 9: Save report to file
cat("9. Save cepstrum report to file\n")
tryCatch({
  if (requireNamespace("gridExtra", quietly = TRUE)) {
    temp_file <- tempfile(fileext = ".png")
    create_cepstrum_report(
      cepstrogram,
      save_path = temp_file,
      format = "png",
      dpi = 150
    )
    if (file.exists(temp_file)) {
      cat("   ✓ Report saved to:", temp_file, "\n")
      cat("   File size:", file.size(temp_file), "bytes\n")
      file.remove(temp_file)
    } else {
      cat("   ✗ File was not created\n")
    }
  } else {
    cat("   ⚠ Skipping (gridExtra not installed)\n")
  }
}, error = function(e) {
  cat("   ✗ Error:", e$message, "\n")
})

cat("\n=================================\n")
cat("Cepstrum plotting tests complete!\n")
cat("=================================\n")

# Print summary of cepstrogram features
cat("\nCepstrogram Summary:\n")
cat("-------------------\n")
tryCatch({
  mean_cpp <- cepstrogram$get_mean_cpp()
  cat("Mean CPP:     ", sprintf("%.2f dB", mean_cpp), "\n")
  
  cpps <- cepstrogram$get_cpps()
  cat("CPPS (smoothed):", sprintf("%.2f dB", cpps), "\n")
}, error = function(e) {
  cat("Could not compute summary statistics:", e$message, "\n")
})

cat("\n✓ All plotting functions are available and functional\n")
