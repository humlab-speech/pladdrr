#!/usr/bin/env Rscript
# Test formant extraction

cat("Loading pladdrr...\n")
library(pladdrr)

cat("Creating test sound...\n")
sound <- Sound$create_tone(duration = 0.5, sampling_rate = 22050)
cat("✓ Sound created\n")
print(sound)

cat("\nAttempting formant extraction...\n")
tryCatch({
  formant_burg <- sound$to_formant_burg(
    time_step = 0.005,
    max_formants = 5,
    max_frequency = 5500,
    window_length = 0.025,
    pre_emphasis_from = 50
  )
  cat("✓ Formant extraction succeeded!\n")
  print(formant_burg)
  
  # Try to get a value
  f1 <- formant_burg$get_value_at_time(1, 0.25, unit = "hertz")
  cat("F1 at 0.25s:", f1, "Hz\n")
  
}, error = function(e) {
  cat("✗ Error:", e$message, "\n")
  cat("Traceback:\n")
  print(traceback())
})
