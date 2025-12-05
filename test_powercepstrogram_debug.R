library(pladdrr)

cat("Creating test sound...\n")
sound <- Sound$new_tone(440, 0.2, 1.0, 44100)
cat("✓ Sound created: duration =", sound$get_duration(), "s\n")
cat("✓ Sample rate =", sound$get_sampling_frequency(), "Hz\n")

cat("\nAttempting PowerCepstrogram creation...\n")
tryCatch({
  pcep <- sound$to_powercepstrogram(
    pitch_floor = 60,
    time_step = 0.002,
    maximum_frequency = 5000,
    pre_emphasis_frequency = 50
  )
  cat("✓ ✓ ✓ SUCCESS! PowerCepstrogram created\n")
}, error = function(e) {
  cat("✗ ✗ ✗ FAILED\n")
  cat("Error message:", e$message, "\n")
})
