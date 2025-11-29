#!/usr/bin/env Rscript
# Test Phase 3 Plotting Functions
# Tests: plot_spectrogram_pitch(), plot_sound_pitch(), plot.Matrix(), plot.PowerCepstrum()

library(pladdrr)
library(ggplot2)

cat("==================================================\n")
cat("Testing Phase 3 Plotting Functions\n")
cat("==================================================\n\n")

# Create test sound
cat("1. Creating test sound...\n")
sound <- Sound$create_tone(duration = 1.0, frequency = 440, sampling_rate = 44100, amplitude = 0.3)
cat("✓ Sound created: 1.0s, 440 Hz\n\n")

# Test plot_spectrogram_pitch()
cat("2. Testing plot_spectrogram_pitch()...\n")
tryCatch({
  spec <- sound$to_spectrogram()
  pitch <- sound$to_pitch()
  
  p <- plot_spectrogram_pitch(spec, pitch, title = "Spectrogram + Pitch Overlay")
  cat("✓ plot_spectrogram_pitch() works!\n")
  cat("  Returns ggplot object:", inherits(p, "ggplot"), "\n\n")
}, error = function(e) {
  cat("✗ plot_spectrogram_pitch() failed:\n")
  cat("  Error:", conditionMessage(e), "\n\n")
})

# Test plot_sound_pitch()
cat("3. Testing plot_sound_pitch()...\n")
tryCatch({
  pitch <- sound$to_pitch()
  
  p <- plot_sound_pitch(sound, pitch, title = "Waveform + Pitch")
  cat("✓ plot_sound_pitch() works!\n")
  cat("  Returns patchwork/grid object:", !is.null(p), "\n\n")
}, error = function(e) {
  cat("✗ plot_sound_pitch() failed:\n")
  cat("  Error:", conditionMessage(e), "\n\n")
})

# Test plot.Matrix()
cat("4. Testing plot.Matrix()...\n")
tryCatch({
  # Create a matrix (spectrogram is a Matrix subclass)
  spec <- sound$to_spectrogram()
  
  p <- plot(spec, title = "Matrix Heatmap", color_scale = "viridis")
  cat("✓ plot.Matrix() works via Spectrogram!\n")
  cat("  Returns ggplot object:", inherits(p, "ggplot"), "\n\n")
}, error = function(e) {
  cat("✗ plot.Matrix() failed:\n")
  cat("  Error:", conditionMessage(e), "\n\n")
})

# Test plot.PowerCepstrum()
cat("5. Testing plot.PowerCepstrum()...\n")
tryCatch({
  pc <- sound$to_powercepstrum(pitch_floor = 60)
  
  p <- plot(pc, title = "Power Cepstrum", from_quefrency = 0.002, to_quefrency = 0.02)
  cat("✓ plot.PowerCepstrum() works!\n")
  cat("  Returns ggplot object:", inherits(p, "ggplot"), "\n\n")
}, error = function(e) {
  cat("✗ plot.PowerCepstrum() failed:\n")
  cat("  Error:", conditionMessage(e), "\n\n")
})

# Test customization
cat("6. Testing ggplot2 customization...\n")
tryCatch({
  pitch <- sound$to_pitch()
  p <- plot(pitch) +
    geom_hline(yintercept = 440, linetype = "dashed", color = "red", alpha = 0.5) +
    annotate("text", x = 0.5, y = 450, label = "Target: 440 Hz") +
    theme_bw()
  
  cat("✓ ggplot2 customization works!\n")
  cat("  Can add layers and themes\n\n")
}, error = function(e) {
  cat("✗ Customization failed:\n")
  cat("  Error:", conditionMessage(e), "\n\n")
})

cat("==================================================\n")
cat("Phase 3 Plotting Tests Complete!\n")
cat("==================================================\n")
