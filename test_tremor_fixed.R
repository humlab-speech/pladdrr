#!/usr/bin/env Rscript
# Test updated tremor implementation with FCoM, FTrC, ACoM

library(pladdrr)

cat("=== Testing Tremor with Fixed FCoM/FTrC/ACoM ===\n\n")

# Test file
audio_file <- "inst/signalfiles/AVQI/input/sv1.wav"

if (!file.exists(audio_file)) {
  stop("Test file not found: ", audio_file)
}

cat("Running tremor analysis...\n\n")

result <- analyze_tremor(
  sound = audio_file,
  voicing_threshold = 0.45,  # Correct value
  verbose = TRUE
)

cat("\n=== Results ===\n")
print(result)

cat("\n=== Key Metrics ===\n")
cat(sprintf("FCoM (frequency contour magnitude): %.4f\n", result$FCoM))
cat(sprintf("FTrC (frequency tremor cyclicality): %.4f\n", result$FTrC))
cat(sprintf("ACoM (amplitude contour magnitude): %.4f\n", result$ACoM))
cat(sprintf("ATrC (amplitude tremor cyclicality): %.4f\n", result$ATrC))

cat("\n=== Validation ===\n")
cat(sprintf("FCoM in [0,1]: %s\n", result$FCoM >= 0 && result$FCoM <= 1))
cat(sprintf("FTrC in [0,1]: %s\n", result$FTrC >= 0 && result$FTrC <= 1))
cat(sprintf("ACoM in [0,1]: %s\n", result$ACoM >= 0 && result$ACoM <= 1))
cat(sprintf("ATrC in [0,1]: %s\n", result$ATrC >= 0 && result$ATrC <= 1))

cat("\nTest complete!\n")
