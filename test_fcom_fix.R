library(pladdrr)

cat("=== Testing FCoM/ACoM Fix ===\n\n")

s <- Sound$new('inst/signalfiles/AVQI/input/sv1.wav')
cat("Loaded:", s$get_duration(), "sec\n\n")

cat("Running analyze_tremor...\n")
t <- analyze_tremor(s, verbose = TRUE)

cat("\n===== FINAL RESULTS =====\n")
cat("FCoM:", t$FCoM, "(expected 0.599)\n")
cat("ACoM:", t$ACoM, "(expected 0.442)\n")
cat("FTrC:", t$FTrC, "(expected 0.998)\n")
cat("FTrF:", t$FTrF, "(expected 5.169 Hz)\n")

cat("\n")
if (abs(t$FCoM - 0.599) < 0.01) {
  cat("✅ FCoM CORRECT!\n")
} else {
  cat("❌ FCoM still wrong (diff:", abs(t$FCoM - 0.599), ")\n")
}

if (abs(t$ACoM - 0.442) < 0.01) {
  cat("✅ ACoM CORRECT!\n")
} else {
  cat("❌ ACoM still wrong (diff:", abs(t$ACoM - 0.442), ")\n")
}
