library(pladdrr)

# Create vowel-like sound with formants
sound <- generate_sine_wave(frequency = 150, duration = 1.0, sampling_rate = 16000)

# Add formant structure
f1 <- generate_sine_wave(frequency = 700, duration = 1.0, sampling_rate = 16000)
f2 <- generate_sine_wave(frequency = 1200, duration = 1.0, sampling_rate = 16000)

# Combine
combined <- Sound$from_values(
  sound$as_vector() + 0.3 * f1$as_vector() + 0.2 * f2$as_vector(),
  sampling_rate = 16000
)

cat("Testing Formant plot...\n")
formant <- combined$to_formant_burg()
cat("Formant object created\n")
df <- formant$as_data_frame(max_formants = 3)
cat("Data frame rows:", nrow(df), "\n")
cat("Data frame structure:\n")
str(df)

if (nrow(df) > 0) {
  p <- plot(formant)
  cat("✓ plot.Formant() works\n")
} else {
  cat("✗ No formant data\n")
}

cat("\nTesting Spectrogram plot...\n")
spec <- combined$to_spectrogram()
cat("Spectrogram object created\n")
cat("Getting start time...\n")
t_min <- spec$get_start_time()
cat("Start time:", t_min, "\n")

tryCatch({
  p <- plot(spec)
  cat("✓ plot.Spectrogram() works\n")
}, error = function(e) {
  cat("✗ Error:", conditionMessage(e), "\n")
  traceback()
})
