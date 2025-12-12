#!/usr/bin/env Rscript
# Quick test of FCoM/ACoM frame 1 fix
library(pladdrr)

cat("Testing FCoM/ACoM fix...\n")
result <- analyze_tremor("inst/signalfiles/AVQI/input/sv1.wav", verbose = FALSE)

cat("\n=== RESULTS ===\n")
cat(sprintf("FCoM: %.4f (expected ~0.599)\n", result$frequency$fcom))
cat(sprintf("ACoM: %.4f (expected ~0.442)\n", result$amplitude$acom))
cat(sprintf("FTrC: %.4f (expected ~0.353)\n", result$frequency$ftrc))
cat(sprintf("ATrC: %.4f\n", result$amplitude$atrc))

# Check if fix worked
if (abs(result$frequency$fcom - 0.599) < 0.1 && abs(result$amplitude$acom - 0.442) < 0.1) {
  cat("\n✅ PASS: FCoM/ACoM values in expected range!\n")
} else {
  cat("\n❌ FAIL: Values still too far from expected\n")
}
