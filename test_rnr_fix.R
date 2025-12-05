library(pladdrr)

cat("Testing RNR with enhanced error handling...\n\n")

# Create test sound
sound <- Sound$create_tone(1.0, 44100, 440, 0.2)
spectrum <- sound$to_spectrum()
cep <- spectrum$to_powercepstrum()

cat("PowerCepstrum created successfully\n")
cat("nx =", cep$get_number_of_frames(), "\n")

# Test RNR with error handling
cat("\nTrying get_rnr()...\n")
tryCatch({
  rnr <- cep$get_rnr(75, 300, 0.05)
  cat("✓ SUCCESS! RNR =", rnr, "dB\n")
}, error = function(e) {
  cat("✗ Error:", e$message, "\n")
})
