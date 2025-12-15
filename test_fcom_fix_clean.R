library(pladdrr)

cat("=== FCoM/ACoM Typo Fix Test ===\n\n")

s <- Sound$new('inst/signalfiles/AVQI/input/sv1.wav')
t <- suppressMessages(analyze_tremor(s, verbose = FALSE))

cat("===== RESULTS =====\n")
cat("FCoM:", sprintf("%.3f", t$FCoM), "(expected 0.599)\n")
cat("ACoM:", sprintf("%.3f", t$ACoM), "(expected 0.442)\n")
cat("FTrC:", sprintf("%.3f", t$FTrC), "(expected 0.998)\n")
cat("FTrF:", sprintf("%.3f", t$FTrF), "Hz (expected 5.169)\n\n")

fcom_ok <- abs(t$FCoM - 0.599) < 0.01
acom_ok <- abs(t$ACoM - 0.442) < 0.01

if (fcom_ok) cat("✅ FCoM CORRECT!\n") else cat("❌ FCoM WRONG (diff:", abs(t$FCoM - 0.599), ")\n")
if (acom_ok) cat("✅ ACoM CORRECT!\n") else cat("❌ ACoM WRONG (diff:", abs(t$ACoM - 0.442), ")\n")

if (fcom_ok && acom_ok) {
  cat("\n🎉 TYPO FIX SOLVED THE PROBLEM!\n")
} else {
  cat("\n⚠️ Still issues - need deeper investigation\n")
}
