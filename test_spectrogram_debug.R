library(pladdrr)

# Simple sine wave
sound <- generate_sine_wave(frequency = 440, duration = 0.5, sampling_rate = 16000)

cat("Creating spectrogram...\n")
spec <- sound$to_spectrogram()
cat("Spectrogram class:", class(spec), "\n")

cat("\nTesting methods:\n")
cat("get_start_time():", spec$get_start_time(), "\n")
cat("get_end_time():", spec$get_end_time(), "\n")
cat("get_highest_frequency():", spec$get_highest_frequency(), "\n")

cat("\nTesting as_matrix():\n")
mat <- spec$as_matrix()
cat("Matrix dimensions:", dim(mat), "\n")

cat("\nNow testing plot...\n")
tryCatch({
  p <- plot(spec)
  cat("✓ plot.Spectrogram() SUCCESS\n")
  print(class(p))
}, error = function(e) {
  cat("✗ Error:", conditionMessage(e), "\n")
  print(traceback())
})
